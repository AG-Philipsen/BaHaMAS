#
#  Copyright (c)
#
#  This file is part of BaHaMAS.
#
#  BaHaMAS is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  BaHaMAS is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with BaHaMAS. If not, see <http://www.gnu.org/licenses/>.
#

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
          maxSpikeToMeanAsNSigma maxSpikePlaquetteAsNSigma meanPlaquetteLastBunchOfTrajectories deltaMaxPlaquette\
          timeFromLastTrajectory integrationSteps0 integrationSteps1 integrationSteps2 kappaMassPreconditioning
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

    cecho -d "\n${BHMAS_defaultListstatusColor}=============================================================================================================================================================================================="
    cecho -n -d lm "$(printf "%s\t\t  %s\t   %s    %s    %s\t  %s\t     %s\n\e[0m"   "Beta"   "Traj. Done (Acc.) [Last 1000] int0-1-2-kmp"   "Status"   "MaxSpikeDS/s"   "Plaq: <Last1000>  Pmax-Pmin  MaxSpikeDP/s"   "Last tr. finished" "Tr: # (time last|av.)")"
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
                meanPlaquetteLastBunchOfTrajectories=$(tail -n1000 $outputFileGlobalPath | awk '{ sum+=$'$BHMAS_plaquetteColumn'} END {printf "% .6f", sum/(NR)}')
            else
                acceptanceLastBunchOfTrajectories=" --- "
                meanPlaquetteLastBunchOfTrajectories=" ----- "
            fi

            local temporaryArray
            temporaryArray=( $(awk 'BEGIN{meanS=0; sigmaS=0; maxSpikeS=0; meanP=0; sigmaP=0; maxSpikeP=0; firstFile=1; secondFile=1}
                                    NR==1 {plaqMin=$'${BHMAS_plaquetteColumn}'; plaqMax=$'${BHMAS_plaquetteColumn}'}
                                    NR==FNR {meanS+=$'${BHMAS_deltaHColumn}'; meanP+=$'${BHMAS_plaquetteColumn}'; plaqValue=$'${BHMAS_plaquetteColumn}';
                                             if(plaqValue<plaqMin){plaqMin=plaqValue}; if(plaqValue>plaqMax){plaqMax=plaqValue}; next}
                                    firstFile==1 {nDat=NR-1; meanS/=nDat; meanP/=nDat; firstFile=0}
                                    NR-nDat==FNR {deltaS=($'${BHMAS_deltaHColumn}'-meanS); sigmaS+=deltaS^2; if(sqrt(deltaS^2)>maxSpikeS){maxSpikeS=sqrt(deltaS^2)};
                                                  deltaP=($'${BHMAS_plaquetteColumn}'-meanP); sigmaP+=deltaP^2; if(sqrt(deltaP^2)>maxSpikeP){maxSpikeP=sqrt(deltaP^2)}; next}
                                    END{sigmaS=sqrt(sigmaS/nDat); sigmaP=sqrt(sigmaP/nDat); secondFile=0;
                                        if(sigmaS!=0) {printf "%.3f ", maxSpikeS/sigmaS} else {print "---- "};
                                        if(sigmaP!=0) {printf "%.3f",  maxSpikeP/sigmaP} else {print "---- "};
                                        printf "% .6f", plaqMax-plaqMin;
                                       }' $outputFileGlobalPath $outputFileGlobalPath ) )
            maxSpikeToMeanAsNSigma=${temporaryArray[0]}
            maxSpikePlaquetteAsNSigma=${temporaryArray[1]}
            deltaMaxPlaquette=${temporaryArray[2]}
            if [[ $jobStatus == "RUNNING" ]]; then
                timeFromLastTrajectory=$(( $(date +%s) - $(stat -c %Y $outputFileGlobalPath) ))
            else
                timeFromLastTrajectory="------"
            fi

            if [ $BHMAS_liststatusMeasureTimeOption = "TRUE" ]; then
                averageTimePerTrajectory=$(awk '{ time=$'$BHMAS_trajectoryTimeColumn'; if(time!=0){sum+=time; counter+=1}} END {if(counter!=0){printf "%d", sum/counter}else{printf "%d", 0}}' $outputFileGlobalPath)
                timeLastTrajectory=$(awk 'END{printf "%d", $'$BHMAS_trajectoryTimeColumn'}' $outputFileGlobalPath)
            else
                averageTimePerTrajectory="----"
                timeLastTrajectory="----"
            fi
        else
            toBeCleaned=0
            trajectoriesDone="-----"
            numberLastTrajectory="----"
            acceptanceAllRun=" ----"
            acceptanceLastBunchOfTrajectories=" ----"
            meanPlaquetteLastBunchOfTrajectories="---"
            maxSpikeToMeanAsNSigma=" ----"
            maxSpikePlaquetteAsNSigma="----"
            deltaMaxPlaquette="---"
            timeFromLastTrajectory="------"
            averageTimePerTrajectory="----"
            timeLastTrajectory="----"
        fi

        if [ -f $inputFileGlobalPath ]; then
            integrationSteps0=$( sed -n '/integrationSteps0=[[:digit:]]\+/p'  $inputFileGlobalPath | sed 's/integrationSteps0=\([[:digit:]]\+\)/\1/' )
            integrationSteps1=$( sed -n '/integrationSteps1=[[:digit:]]\+/p'  $inputFileGlobalPath | sed 's/integrationSteps1=\([[:digit:]]\+\)/\1/' )
            if [[ ! $integrationSteps0 =~ ^[[:digit:]]+$ ]] || [[ ! $integrationSteps1 =~ ^[[:digit:]]+$ ]]; then
                integrationSteps0="--"
                integrationSteps1="--"
            fi
            if [ $(grep -o "useMP=1" $inputFileGlobalPath | wc -l) -eq 1 ]; then
                integrationSteps2="-$( sed -n '/integrationSteps2=[[:digit:]]\+/p'  $inputFileGlobalPath | sed 's/integrationSteps2=\([[:digit:]]\+\)/\1/' )"
                kappaMassPreconditioning="-$( sed -n '/kappaMP=[[:digit:]]\+[.][[:digit:]]\+/p'  $inputFileGlobalPath | sed 's/kappaMP=\(.*\)/\1/' )"
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
$(__static__ColorDelta S $maxSpikeToMeanAsNSigma)%7s${BHMAS_defaultListstatusColor}\t\
%20s  %10s  $(__static__ColorDelta P $maxSpikePlaquetteAsNSigma)%9s${BHMAS_defaultListstatusColor}\t  \
$(__static__ColorTime $timeFromLastTrajectory)%s${BHMAS_defaultListstatusColor}\t\
%10s \
( %s ) \
\n\e[0m" \
            "$(__static__GetShortenedBetaString)" \
            "$trajectoriesDone" \
            "$acceptanceAllRun" \
            "$acceptanceLastBunchOfTrajectories" \
            "$integrationSteps0" "$integrationSteps1" "$integrationSteps2" "$kappaMassPreconditioning" \
            "$jobStatus"   "$maxSpikeToMeanAsNSigma"   "${meanPlaquetteLastBunchOfTrajectories}"   "${deltaMaxPlaquette}"   "${maxSpikePlaquetteAsNSigma}"\
            "$(awk '{if($1 ~ /^[[:digit:]]+$/){printf "%6d", $1}else{print $1}}' <<< "$timeFromLastTrajectory") sec. ago" \
            "$numberLastTrajectory" \
            "$(awk '{if($1 ~ /^[[:digit:]]+$/ && $2 ~ /^[[:digit:]]+$/){printf "%3ds | %3ds", $1, $2}else{print "notMeasured"}}' <<< "$timeLastTrajectory $averageTimePerTrajectory")"

        if [ $toBeCleaned -eq 0 ]; then
            printf "%s\t\t%8s (%s %%) [%s %%]  %s-%s%s%s\t%9s\t%s\n"   "$(__static__GetShortenedBetaString)"   "$trajectoriesDone"   "$acceptanceAllRun"   "$acceptanceLastBunchOfTrajectories"   "$integrationSteps0" "$integrationSteps1" "$integrationSteps2" "$kappaMassPreconditioning"   "$jobStatus"   "$maxSpikeToMeanAsNSigma" >> $jobsStatusFile
        else
            printf "%s\t\t%8s (%s %%) [%s %%]  %s-%s%s%s\t%9s\t%s\t ---> File to be cleaned!\n"   "$(__static__GetShortenedBetaString)"   "$trajectoriesDone"   "$acceptanceAllRun"   "$acceptanceLastBunchOfTrajectories"   "$integrationSteps0" "$integrationSteps1" "$integrationSteps2" "$kappaMassPreconditioning"   "$jobStatus"   "$maxSpikeToMeanAsNSigma" >> $jobsStatusFile
        fi

    done #Loop on BETA

    cecho -d "${BHMAS_defaultListstatusColor}================================================================================================================================================================================================="
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
                                    ["Plaquette"]=${BHMAS_plaquetteColumn}
                                    ["PlaquetteSpatial"]=3
                                    ["PlaquetteTemporal"]=4
                                    ["PolyakovLoopRe"]=5
                                    ["PolyakovLoopIm"]=6
                                    ["PolyakovLoopSq"]=7
                                    ["Accepted"]=${BHMAS_acceptanceColumn} )
    local auxiliaryVariable1 auxiliaryVariable2 errorCode
    auxiliaryVariable1=$(printf "%s," "${observablesColumns[@]}")
    auxiliaryVariable2=$(printf "%s," "${!observablesColumns[@]}")
    if [ ! -f $outputFileGlobalPath ]; then
        printf $BHMAS_defaultListstatusColor
        return
    fi

    awk -v obsColumns="${auxiliaryVariable1%?}" \
        -v obsNames="${auxiliaryVariable2%?}" \
        -v wrongVariable="${BHMAS_fatalVariableUnset}" \
        -v success="${BHMAS_successExitCode}" \
        -v failure="${BHMAS_fatalLogicError}" \
        -f ${BHMAS_repositoryTopLevelPath}/SLURM_Implementation/CheckCorrectnessCl2qcdOutputFile.awk $outputFileGlobalPath
    errorCode=$?

    if [ $errorCode -eq ${BHMAS_successExitCode} ]; then
        printf $BHMAS_defaultListstatusColor
    elif [ $errorCode -eq ${BHMAS_fatalLogicError} ]; then
        printf $BHMAS_wrongBetaListstatusColor
    else
        printf $BHMAS_suspiciousBetaListstatusColor
    fi

}


function __static__ColorDelta()
{
    if [[ ! $1 =~ ^[PS]$ ]] || [[ ! $2 =~ [+-]?[[:digit:]]+[.]?[[:digit:]]* ]]; then
        printf $BHMAS_defaultListstatusColor
    else
        local thresholdVariableName tooHighColorVariableName
        thresholdVariableName="BHMAS_delta${1}Threshold"
        tooHighColorVariableName="BHMAS_tooHighDelta${1}ListstatusColor"
        if [ "$postfixFromFolder" == "continueWithNewChain" ] && [ $(awk -v threshold=${!thresholdVariableName} -v value=$2 'BEGIN{if(value >= threshold)print 1; else print 0;}') -eq 1 ]; then
            printf ${!tooHighColorVariableName}
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
         __static__ColorDelta
