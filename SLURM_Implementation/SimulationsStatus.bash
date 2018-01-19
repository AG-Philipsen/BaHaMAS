#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENSE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

function __static__ExtractBetasFrom()
{
    local jobName betasString temporaryArray betaValuesArray element betaValue seedsArray seed
    jobName="$1"
    #Here it is supposed that the name of the job is ${BHMAS_parametersString}_(...)
    #The goal of this function is to get an array whose elements are bx.xxxx_syyyy and since we use involved bash lines it is better to say that:
    #  1) from jobName we take everything after the BHMAS_betaPrefix
    betasString=$(awk -v pref="$BHMAS_betaPrefix" '{print substr($0, index($0, pref))}' <<< "$jobName")
    #  2) we split on the BHMAS_betaPrefix in order to get all the seeds referred to the same beta
    temporaryArray=( $(awk -v pref="$BHMAS_betaPrefix" '{split($1, res, pref); for (i in res) print res[i]}' <<< "$betasString") )
    #  3) we take the value of the beta and of the seeds building up the final array
    betaValuesArray=()
    for element in "${temporaryArray[@]}"; do
        betaValue=${element%%_*}
        seedsArray=( $(grep -o "${BHMAS_seedPrefix}[[:alnum:]]\{4\}" <<< "${element#*_}") )
        if [ ${#seedsArray[@]} -gt 0 ]; then
            for seed in "${seedsArray[@]}"; do
                betaValuesArray+=( "${BHMAS_betaPrefix}${betaValue}_${seed}" )
            done
        else
            betaValuesArray+=( "${BHMAS_betaPrefix}${betaValue}" )
        fi
    done
    printf "%s " "${betaValuesArray[@]}"
}

function __static__ExtractPostfixFrom()
{
    local jobName postfix
    jobName="$1"
    postfix=${jobName##*_}
    if [ "$postfix" == "TC" ]; then
        printf "thermalizeFromConf"
    elif [ "$postfix" == "TH" ]; then
        printf "thermalizeFromHot"
    elif [ "$postfix" == "Thermalize" ]; then
        printf "thermalize_old"
    elif [ "$postfix" == "Tuning" ]; then
        printf "tuning"
        #Also in the "TC" and "TH" cases we have seeds in the name, but such a cases are exluded from the elif
    elif [ $(grep -o "_${BHMAS_seedPrefix}[[:alnum:]]\{4\}" <<< "$jobName" | wc -l) -ne 0 ]; then
        printf "continueWithNewChain"
    else
        printf ""
    fi
}

function __static__ExtractMetaInformationFromQueuedJobs()
{
    local jobName metaInformationArray jobInfoString value jobStatus jobNameBetas jobNamePostfix jobParametersString
    metaInformationArray=()
    jobInfoString="$(squeue --noheader -u $(whoami) -o "%j@%T")" #here jobInfoString contains spaces at the end of the line
    for value in $jobInfoString; do #here I use the fact that jobInfoString has spaces to split it (IMPORTANT missing quotes)
        jobName=${value%@*}
        jobStatus=${value#*@}
        jobNameBetas=( $(__static__ExtractBetasFrom $jobName) )
        jobNamePostfix=$(__static__ExtractPostfixFrom $jobName)
        jobParametersString="${jobName%%__*}"
        #If jobParametersString is not at the beginning of the jobname, skip job
        [ $(grep "^${jobParametersString}" <<< "$jobName" | wc -l) -eq 0 ] && continue
        #If the status is COMPLETING, skip job
        [ $jobStatus == "COMPLETING" ] && continue
        metaInformationArray+=( $(sed 's/ //g' <<< "${jobParametersString} | $(sed 's/ /_/g' <<< "${jobNameBetas[@]}") | postfix=${jobNamePostfix} | ${jobStatus}") )
    done
    printf "%s " "${metaInformationArray[@]:-}"
}

function ListSimulationsStatus_SLURM()
{
    local localParametersPath localParametersString jobsStatusFile jobsMetainformationArray beta\
          postfixFromFolder jobStatus outputFileGlobalPath inputFileGlobalPath\
          averageTimePerTrajectory timeLastTrajectory toBeCleaned trajectoriesDone\
          numberLastTrajectory acceptanceAllRun acceptanceLastBunchOfTrajectories\
          maxSpikeToMeanAsNSigma spikesBeyondFourSigma spikesBeyondFiveSigma timeFromLastTrajectory \
          integrationSteps0 integrationSteps1 integrationSteps2 kappaMassPreconditioning
    # This function can be called by the JobHandler either in the BHMAS_liststatusOption setup or in the DATABASE setup.
    # The crucial difference is that in the first case the BHMAS_parametersString and BHMAS_parametersPath variable
    # must be the global ones, otherwise they have to be built on the basis of some given information.
    # Then we make this function accept one and ONLY ONE argument (given only in the DATABASE setup)
    # containing the BHMAS_parametersPath (e.g. /muiPiT/k1550/nt6/ns12) and we will define local
    # BHMAS_parametersString and BHMAS_parametersPath variables filled differently in the two cases.
    # In the DATABASE setup the BHMAS_parametersString is built using the argument given.
    if [ $# -eq 0 ]; then
        localParametersPath="$BHMAS_parametersPath"
        localParametersString="$BHMAS_parametersString"
    elif [ $# -eq 1 ]; then
        localParametersPath="$1"
        localParametersString=${localParametersPath//\//_}
        localParametersString=${localParametersString:1}
    else
        Internal "Wrong invocation of " emph "$FUNCNAME" ", invalid number of arguments!"
    fi


    jobsStatusFile="jobs_status_$localParametersString.txt"
    rm -f $jobsStatusFile

    cecho -d "\n${BHMAS_defaultListstatusColor}========================================================================================================================================================="
    cecho -n -d lm "$(printf "%s\t\t  %s\t   %s     %s  %s\t  %s\n\e[0m"   "Beta"   "Traj. Done (Acc.) [Last 1000] int0-1-2-kmp"   "Status"   "MaxSpikeDS/s [>4s,>5s #|th.]" "Last tr. finished" "Tr: # (time last|av.)")"
    printf "%s\t\t\t  %s\t  %s\t%s\t  %s\t%s\n"   "Beta"   "Traj. Done (Acc.) [Last 1000] int0-1-2-kmp"   "Status"   "Max DS" >> $jobsStatusFile

    jobsMetainformationArray=( $(__static__ExtractMetaInformationFromQueuedJobs) )

    for beta in ${BHMAS_betaPrefix}[[:digit:]]*; do
        #Select only folders with old or new names
        beta=${beta#$BHMAS_betaPrefix}
        if [[ ! $beta =~ ^[[:digit:]][.][[:digit:]]{4}$ ]] &&
               [[ ! $beta =~ ^[[:digit:]][.][[:digit:]]{4}_"$BHMAS_seedPrefix"[[:alnum:]]{4}_continueWithNewChain$ ]] &&
               [[ ! $beta =~ ^[[:digit:]][.][[:digit:]]{4}_"$BHMAS_seedPrefix"[[:alnum:]]{4}_thermalizeFromHot$ ]] &&
               [[ ! $beta =~ ^[[:digit:]][.][[:digit:]]{4}_"$BHMAS_seedPrefix"[[:alnum:]]{4}_thermalizeFromCold$ ]] &&
               [[ ! $beta =~ ^[[:digit:]][.][[:digit:]]{4}_"$BHMAS_seedPrefix"[[:alnum:]]{4}_thermalizeFromConf$ ]]; then continue; fi

        postfixFromFolder=$(grep -o "[[:alpha:]]\+\$" <<< "${beta##*_}")

        set +e #Here grep could find no matching job in the queued ones
        jobStatus=( $(sed 's/ /\n/g' <<< "${jobsMetainformationArray[@]:-}" | grep "${localParametersString}" | grep "${BHMAS_betaPrefix}${beta%_*}" | grep "postfix=${postfixFromFolder}|" | cut -d'|' -f4) )
        set -e

        if [ ${#jobStatus[@]} -eq 0 ]; then
            [ $BHMAS_liststatusShowOnlyQueuedOption = "TRUE" ] && continue
            jobStatus="notQueued"
        elif [ ${#jobStatus[@]} -eq 1 ]; then
            jobStatus=${jobStatus[0]}
        else
            Fatal $BHMAS_fatalLogicError "There are more than one job with " emph "${localParametersString}" " and " emph "beta = $beta" " as parameters! This should not happen!"
        fi

        #---------------------------------------------------------------------------------------------------------------------------------------#
        outputFileGlobalPath="$BHMAS_runDiskGlobalPath/$BHMAS_projectSubpath$localParametersPath/$BHMAS_betaPrefix$beta/$BHMAS_outputFilename"
        inputFileGlobalPath="$BHMAS_submitDiskGlobalPath/$BHMAS_projectSubpath$localParametersPath/$BHMAS_betaPrefix$beta/$BHMAS_inputFilename"
        #---------------------------------------------------------------------------------------------------------------------------------------#
        if [ -f $outputFileGlobalPath ] && [ $(wc -l < $outputFileGlobalPath) -gt 0 ]; then
            toBeCleaned=$(awk 'BEGIN{traj_num = -1; file_to_be_cleaned=0}{if($1>traj_num){traj_num = $1} else {file_to_be_cleaned=1; exit;}}END{print file_to_be_cleaned}' $outputFileGlobalPath)
            if [ $toBeCleaned -eq 0 ]; then
                trajectoriesDone=$(wc -l < $outputFileGlobalPath)
            else
                trajectoriesDone=$(awk 'NR==1{startTr=$1}END{print $1 - startTr + 1}' $outputFileGlobalPath)
            fi
            numberLastTrajectory=$(awk 'END{print $1}' $outputFileGlobalPath)
            acceptanceAllRun=$(awk '{ sum+=$'$BHMAS_acceptanceColumn'} END {printf "%5.2f", 100*sum/(NR)}' $outputFileGlobalPath)

            if [ $trajectoriesDone -ge 1000 ]; then
                acceptanceLastBunchOfTrajectories=$(tail -n1000 $outputFileGlobalPath | awk '{ sum+=$'$BHMAS_acceptanceColumn'} END {printf "%5.2f", 100*sum/(NR)}')
            else
                acceptanceLastBunchOfTrajectories=" --- "
            fi

            if [ $(wc -l < $outputFileGlobalPath) -gt 0 ]; then
                local temporaryArray
                temporaryArray=( $(awk 'BEGIN{mean=0; sigma=0; maxSpike=0; firstFile=1; secondFile=1; beyondIVsigma=0; beyondVsigma=0}
                                        NR==FNR {mean+=$8; next}
                                        firstFile==1 {nDat=NR-1; mean/=nDat; firstFile=0}
                                        NR-nDat==FNR {delta=($8-mean); sigma+=delta^2; if(sqrt(delta^2)>maxSpike){maxSpike=sqrt(delta^2)}; next}
                                        secondFile==1 {sigma=sqrt(sigma/nDat); secondFile=0}
                                        FILENAME==ARGV[3] {if(sqrt($8^2)>mean+4*sigma){beyondIVsigma+=1}; if(sqrt($8^2)>mean+5*sigma){beyondVsigma+=1}}
                                        END{expectedBeyondIVsigma=2*3.16712e-5*nDat; expectedBeyondVsigma=2*2.86652e-7*nDat;
                                            printf "%.3f %d %d %d %d", maxSpike/sigma, beyondIVsigma, expectedBeyondIVsigma, beyondVsigma, expectedBeyondVsigma}' $outputFileGlobalPath $outputFileGlobalPath $outputFileGlobalPath ) )
                maxSpikeToMeanAsNSigma=${temporaryArray[0]}
                spikesBeyondFourSigma="${temporaryArray[1]}|${temporaryArray[2]}" # In awk we rounded the expected values with %d, not with %.0f since this
                spikesBeyondFiveSigma="${temporaryArray[3]}|${temporaryArray[4]}" # could be a not so smart idea -> https://www.gnu.org/software/gawk/manual/html_node/Round-Function.html
            else
                maxSpikeToMeanAsNSigma=" ----"
                spikesBeyondFourSigma="---"
                spikesBeyondFiveSigma="---"
            fi

            if [[ $jobStatus == "RUNNING" ]]; then
                timeFromLastTrajectory=$(( $(date +%s) - $(stat -c %Y $outputFileGlobalPath) ))
            else
                timeFromLastTrajectory="------"
            fi

            if [ $BHMAS_liststatusMeasureTimeOption = "TRUE" ]; then
                averageTimePerTrajectory=$(awk '{ time=$'$BHMAS_trajectoryTimeColumn'; if(time!=0){sum+=time; counter+=1}} END {if(counter!=0){printf "%d", sum/counter}else{printf "%d", 0}}' $outputFileGlobalPath)
                timeLastTrajectory=$(awk 'END{printf "%d", $'$BHMAS_trajectoryTimeColumn'}' $outputFileGlobalPath)
            fi
        else
            toBeCleaned=0
            trajectoriesDone="-----"
            numberLastTrajectory="----"
            acceptanceAllRun=" ----"
            acceptanceLastBunchOfTrajectories=" ----"
            maxSpikeToMeanAsNSigma=" ----"
            spikesBeyondFourSigma="---"
            spikesBeyondFiveSigma="---"
            timeFromLastTrajectory="------"
            averageTimePerTrajectory="----"
            timeLastTrajectory="----"
        fi

        if [ -f $inputFileGlobalPath ]; then
            integrationSteps0=$( grep -o "integrationsteps0=[[:digit:]]\+"  $inputFileGlobalPath | sed 's/integrationsteps0=\([[:digit:]]\+\)/\1/' )
            integrationSteps1=$( grep -o "integrationsteps1=[[:digit:]]\+"  $inputFileGlobalPath | sed 's/integrationsteps1=\([[:digit:]]\+\)/\1/' )
            if [[ ! $integrationSteps0 =~ ^[[:digit:]]+$ ]] || [[ ! $integrationSteps1 =~ ^[[:digit:]]+$ ]]; then
                integrationSteps0="--"
                integrationSteps1="--"
            fi
            if [ $(grep -o "use_mp=1" $inputFileGlobalPath | wc -l) -eq 1 ]; then
                integrationSteps2="-$( grep -o "integrationsteps2=[[:digit:]]\+"  $inputFileGlobalPath | sed 's/integrationsteps2=\([[:digit:]]\+\)/\1/' )"
                kappaMassPreconditioning="-$( grep -o "kappa_mp=[[:digit:]]\+[.][[:digit:]]\+"  $inputFileGlobalPath | sed 's/kappa_mp=\(.*\)/\1/' )"
                if [[ ! $integrationSteps2 =~ ^-[[:digit:]]+$ ]] || [[ ! $kappaMassPreconditioning =~ ^-[[:digit:]]+[.][[:digit:]]+$ ]]; then
                    integrationSteps2="--"
                    kappaMassPreconditioning="--"
                fi
            else
                integrationSteps2="  "
                kappaMassPreconditioning="      "
            fi
        else
            integrationSteps0="--"
            integrationSteps1="--"
            integrationSteps2="--"
            kappaMassPreconditioning="-----"
        fi

        printf \
            "$(__static__ColorBeta)%-15s\t  \
$(__static__ColorClean $toBeCleaned)%8s${BHMAS_defaultListstatusColor} \
($(GoodAcc $acceptanceAllRun)%s %%${BHMAS_defaultListstatusColor}) \
[$(GoodAcc $acceptanceLastBunchOfTrajectories)%s %%${BHMAS_defaultListstatusColor}] \
%s-%s%s%s\t\
$(__static__ColorStatus $jobStatus)%9s${BHMAS_defaultListstatusColor}\t\
$(__static__ColorDeltaS $maxSpikeToMeanAsNSigma)%7s${BHMAS_defaultListstatusColor}    %8s %-8s  \
$(__static__ColorTime $timeFromLastTrajectory)%s${BHMAS_defaultListstatusColor}   \
%7s \
( %s ) \
\n\e[0m" \
            "$(__static__GetShortenedBetaString)" \
            "$trajectoriesDone" \
            "$acceptanceAllRun" \
            "$acceptanceLastBunchOfTrajectories" \
            "$integrationSteps0" "$integrationSteps1" "$integrationSteps2" "$kappaMassPreconditioning" \
            "$jobStatus"   "$maxSpikeToMeanAsNSigma"   "[${spikesBeyondFourSigma}]"   "[${spikesBeyondFiveSigma}]"\
            "$(awk '{if($1 ~ /^[[:digit:]]+$/){printf "%6d", $1}else{print $1}}' <<< "$timeFromLastTrajectory") sec. ago" \
            "$numberLastTrajectory" \
            "$(awk '{if($1 ~ /^[[:digit:]]+$/ && $2 ~ /^[[:digit:]]+$/){printf "%3ds | %3ds", $1, $2}else{print "notMeasured"}}' <<< "$timeLastTrajectory $averageTimePerTrajectory")"

        if [ $toBeCleaned -eq 0 ]; then
            printf "%s\t\t%8s (%s %%) [%s %%]  %s-%s%s%s\t%9s\t%s\n"   "$(__static__GetShortenedBetaString)"   "$trajectoriesDone"   "$acceptanceAllRun"   "$acceptanceLastBunchOfTrajectories"   "$integrationSteps0" "$integrationSteps1" "$integrationSteps2" "$kappaMassPreconditioning"   "$jobStatus"   "$maxSpikeToMeanAsNSigma" >> $jobsStatusFile
        else
            printf "%s\t\t%8s (%s %%) [%s %%]  %s-%s%s%s\t%9s\t%s\t ---> File to be cleaned!\n"   "$(__static__GetShortenedBetaString)"   "$trajectoriesDone"   "$acceptanceAllRun"   "$acceptanceLastBunchOfTrajectories"   "$integrationSteps0" "$integrationSteps1" "$integrationSteps2" "$kappaMassPreconditioning"   "$jobStatus"   "$maxSpikeToMeanAsNSigma" >> $jobsStatusFile
        fi

    done #Loop on BETA

    cecho -d "${BHMAS_defaultListstatusColor}========================================================================================================================================================="
}

function __static__GetShortenedBetaString()
{
    if [ "$postfixFromFolder" == "continueWithNewChain" ]; then
        printf "${beta%_*}_NC"
    elif [ "$postfixFromFolder" == "thermalizeFromHot" ]; then
        printf "${beta%_*}_fH"
    elif [ "$postfixFromFolder" == "thermalizeFromConf" ]; then
        printf "${beta%_*}_fC"
    else
        printf "${beta%_*}"
    fi
}

function GoodAcc()
{
    awk -v tl="${BHMAS_tooLowAcceptanceListstatusColor/\\/\\\\}" \
        -v l="${BHMAS_lowAcceptanceListstatusColor/\\/\\\\}" \
        -v op="${BHMAS_optimalAcceptanceListstatusColor/\\/\\\\}" \
        -v h="${BHMAS_highAcceptanceListstatusColor/\\/\\\\}" \
        -v th="${BHMAS_tooHighAcceptanceListstatusColor/\\/\\\\}" \
        -v tlt="$BHMAS_tooLowAcceptanceThreshold" \
        -v lt="$BHMAS_lowAcceptanceThreshold" \
        -v ht="$BHMAS_highAcceptanceThreshold" \
        -v tht="$BHMAS_tooHighAcceptanceThreshold" '{if($1<tlt){print tl}else if($1<lt){print l}else if($1>tht){print th}else if($1>ht){print h}else{print op}}' <<< "$1"
}

function __static__ColorStatus()
{
    if [[ $1 == "RUNNING" ]]; then
        printf $BHMAS_runningListstatusColor
    elif [[ $1 == "PENDING" ]]; then
        printf $BHMAS_pendingListstatusColor
    else
        printf $BHMAS_defaultListstatusColor
    fi
}

function __static__ColorTime()
{
    if [[ ! $1 =~ ^[[:digit:]]+$ ]]; then
        printf $BHMAS_defaultListstatusColor
    else
        [ $1 -gt 450 ] && printf $BHMAS_stuckSimulationListstatusColor || printf $BHMAS_fineSimulationListstatusColor
    fi
}

function __static__ColorClean()
{
    [ $1 -eq 0 ] && printf $BHMAS_defaultListstatusColor || printf $BHMAS_toBeCleanedListstatusColor
}

function __static__ColorBeta()
{
    #Columns here below ranges from 1 on, since they are used in awk
    declare -A observablesColumns=( ["TrajectoryNr"]=1
                                     ["Plaquette"]=2
                                     ["PlaquetteSpatial"]=3
                                     ["PlaquetteTemporal"]=4
                                     ["PolyakovLoopRe"]=5
                                     ["PolyakovLoopIm"]=6
                                     ["PolyakovLoopSq"]=7
                                     ["Accepted"]=11 )
    local auxiliaryVariable1 auxiliaryVariable2 errorCode
    auxiliaryVariable1=$(printf "%s," "${observablesColumns[@]}")
    auxiliaryVariable2=$(printf "%s," "${!observablesColumns[@]}")
    if [ ! -f $outputFileGlobalPath ]; then
        printf $BHMAS_defaultListstatusColor
        return
    fi

    awk -v obsColumns="${auxiliaryVariable1%?}" -v obsNames="${auxiliaryVariable2%?}" -f ${BHMAS_repositoryTopLevelPath}/SLURM_Implementation/CheckCorrectnessCl2qcdOutputFile.awk $outputFileGlobalPath
    errorCode=$?

    if [ $errorCode -eq 0 ]; then
        printf $BHMAS_defaultListstatusColor
    elif [ $errorCode -eq 1 ]; then
        printf $BHMAS_wrongBetaListstatusColor
    else
        printf $BHMAS_suspiciousBetaListstatusColor
    fi

}


function __static__ColorDeltaS()
{
    if [[ ! $1 =~ [+-]?[[:digit:]]+[.]?[[:digit:]]* ]]; then
        printf $BHMAS_defaultListstatusColor
    else
        if [ "$postfixFromFolder" == "continueWithNewChain" ] && [ $(awk -v threshold=$BHMAS_deltaSThreshold -v value=$1 'BEGIN{if(value >= threshold)print 1; else print 0;}') -eq 1 ]; then
            printf $BHMAS_tooHighDeltaSListstatusColor
        else
            printf $BHMAS_defaultListstatusColor
        fi
    fi
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         __static__ExtractBetasFrom\
         __static__ExtractPostfixFrom\
         __static__ExtractMetaInformationFromQueuedJobs\
         ListSimulationsStatus_SLURM\
         __static__GetShortenedBetaString\
         GoodAcc\
         __static__ColorStatus\
         __static__ColorTime\
         __static__ColorClean\
         __static__ColorBeta\
         __static__ColorDeltaS
