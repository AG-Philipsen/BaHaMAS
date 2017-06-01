function __static__ExtractBetasFromJOBNAME()
{
    #Here it is supposed that the name of the job is ${BHMAS_parametersString}_(...)
    #The goal of this function is to get an array whose elements are bx.xxxx_syyyy and since we use involved bash lines it is better to say that:
    #  1) from JOBNAME we take everything after the BHMAS_betaPrefix
    local BETAS_STRING=$(awk -v pref="$BHMAS_betaPrefix" '{print substr($0, index($0, pref))}' <<< "$JOBNAME")
    #  2) we split on the BHMAS_betaPrefix in order to get all the seeds referred to the same beta
    local TEMPORAL_ARRAY=( $(awk -v pref="$BHMAS_betaPrefix" '{split($1, res, pref); for (i in res) print res[i]}' <<< "$BETAS_STRING") )
    #  3) we take the value of the beta and of the seeds building up the final array
    local BETAVALUES_ARRAY=()
    for ELEMENT in "${TEMPORAL_ARRAY[@]}"; do
        local BETAVALUE=${ELEMENT%%_*}
        local SEEDS_ARRAY=( $(grep -o "${BHMAS_seedPrefix}[[:alnum:]]\{4\}" <<< "${ELEMENT#*_}") )
        if [ ${#SEEDS_ARRAY[@]} -gt 0 ]; then
            for SEED in "${SEEDS_ARRAY[@]}"; do
                BETAVALUES_ARRAY+=( "${BHMAS_betaPrefix}${BETAVALUE}_${SEED}" )
            done
        else
            BETAVALUES_ARRAY+=( "${BHMAS_betaPrefix}${BETAVALUE}" )
        fi
    done
    printf "%s " "${BETAVALUES_ARRAY[@]}"
}

function __static__ExtractPostfixFromJOBNAME()
{
    local POSTFIX=${JOBNAME##*_}
    if [ "$POSTFIX" == "TC" ]; then
        printf "thermalizeFromConf"
    elif [ "$POSTFIX" == "TH" ]; then
        printf "thermalizeFromHot"
    elif [ "$POSTFIX" == "Thermalize" ]; then
        printf "thermalize_old"
    elif [ "$POSTFIX" == "Tuning" ]; then
        printf "tuning"
        #Also in the "TC" and "TH" cases we have seeds in the name, but such a cases are exluded from the elif
    elif [ $(grep -o "_${BHMAS_seedPrefix}[[:alnum:]]\{4\}" <<< "$JOBNAME" | wc -l) -ne 0 ]; then
        printf "continueWithNewChain"
    else
        printf ""
    fi
}

function __static__ExtractMetaInformationFromJOBNAME()
{
    local METAINFORMATION_ARRAY=()
    local JOBINFO_STRING="$(squeue --noheader -u $(whoami) -o "%j@%T")" #here JOBINFO_STRING contains spaces at the end of the line

    for VALUE in $JOBINFO_STRING; do #here I use the fact that JOBINFO_STRING has spaces to split it (IMPORTANT missing quotes)
        local JOBNAME=${VALUE%@*}
        local JOB_STATUS=${VALUE#*@}
        local JOBNAME_BETAS=( $(__static__ExtractBetasFromJOBNAME) )
        local JOBNAME_POSTFIX=$(__static__ExtractPostfixFromJOBNAME)
        local JOB_PARAMETERS_STRING="${JOBNAME%%__*}"
        #If JOB_PARAMETERS_STRING is not at the beginning of the jobname, skip job
        [ $(grep "^${JOB_PARAMETERS_STRING}" <<< "$JOBNAME" | wc -l) -eq 0 ] && continue
        #If the status is COMPLETING, skip job
        [ $JOB_STATUS == "COMPLETING" ] && continue
        METAINFORMATION_ARRAY+=( $(sed 's/ //g' <<< "${JOB_PARAMETERS_STRING} | $(sed 's/ /_/g' <<< "${JOBNAME_BETAS[@]}") | postfix=${JOBNAME_POSTFIX} | ${JOB_STATUS}") )
    done && unset -v 'VALUE'

    printf "%s " "${METAINFORMATION_ARRAY[@]:-}"
}

function ListSimulationsStatus_SLURM()
{

    # This function can be called by the JobHandler either in the BHMAS_liststatusOption setup or in the DATABASE setup.
    # The crucial difference is that in the first case the BHMAS_parametersString and BHMAS_parametersPath variable
    # must be the global ones, otherwise they have to be built on the basis of some given information.
    # Then we make this function accept one and ONLY ONE argument (given only in the DATABASE setup)
    # containing the BHMAS_parametersPath (e.g. /muiPiT/k1550/nt6/ns12) and we will define local
    # BHMAS_parametersString and BHMAS_parametersPath variables filled differently in the two cases.
    # In the DATABASE setup the BHMAS_parametersString is built using the argument given.
    if [ $# -eq 0 ]; then
        local LOCAL_PARAMETERS_PATH="$BHMAS_parametersPath"
        local LOCAL_PARAMETERS_STRING="$BHMAS_parametersString"
    elif [ $# -eq 1 ]; then
        local LOCAL_PARAMETERS_PATH="$1"
        local LOCAL_PARAMETERS_STRING=${LOCAL_PARAMETERS_PATH//\//_}
        LOCAL_PARAMETERS_STRING=${LOCAL_PARAMETERS_STRING:1}
    else
        cecho "\e[31m Wrong invocation of ListSimulationsStatus_SLURM: Invalid number of arguments. Please investigate...exiting."
        return
    fi


    local JOBS_STATUS_FILE="jobs_status_$LOCAL_PARAMETERS_STRING.txt"
    rm -f $JOBS_STATUS_FILE

    cecho -d "\n${BHMAS_defaultListstatusColor}==============================================================================================================================================="
    cecho -n -d lm "$(printf "%s\t\t  %s\t  %s\t   %s\t  %s\t%s\n\e[0m"   "Beta"   "Traj. Done (Acc.) [Last 1000] int0-1-2-kmp"   "Status"   "Max DS" "Last tr. finished" " Tr: # (time last|av.)")"
    printf "%s\t\t\t  %s\t  %s\t%s\t  %s\t%s\n"   "Beta"   "Traj. Done (Acc.) [Last 1000] int0-1-2-kmp"   "Status"   "Max DS" >> $JOBS_STATUS_FILE

    JOB_METAINFORMATION_ARRAY=( $(__static__ExtractMetaInformationFromJOBNAME) )

    for BETA in ${BHMAS_betaPrefix}[[:digit:]]*; do

        #Select only folders with old or new names
        BETA=${BETA#$BHMAS_betaPrefix}
        if [[ ! $BETA =~ ^[[:digit:]][.][[:digit:]]{4}$ ]] &&
               [[ ! $BETA =~ ^[[:digit:]][.][[:digit:]]{4}_"$BHMAS_seedPrefix"[[:alnum:]]{4}_continueWithNewChain$ ]] &&
               [[ ! $BETA =~ ^[[:digit:]][.][[:digit:]]{4}_"$BHMAS_seedPrefix"[[:alnum:]]{4}_thermalizeFromHot$ ]] &&
               [[ ! $BETA =~ ^[[:digit:]][.][[:digit:]]{4}_"$BHMAS_seedPrefix"[[:alnum:]]{4}_thermalizeFromCold$ ]] &&
               [[ ! $BETA =~ ^[[:digit:]][.][[:digit:]]{4}_"$BHMAS_seedPrefix"[[:alnum:]]{4}_thermalizeFromConf$ ]]; then continue; fi

        local POSTFIX_FROM_FOLDER=$(grep -o "[[:alpha:]]\+\$" <<< "${BETA##*_}")

        local STATUS=( $(sed 's/ /\n/g' <<< "${JOB_METAINFORMATION_ARRAY[@]:-}" | grep "${LOCAL_PARAMETERS_STRING}" | grep "${BHMAS_betaPrefix}${BETA%_*}" | grep "postfix=${POSTFIX_FROM_FOLDER}|" | cut -d'|' -f4) )

        if [ ${#STATUS[@]} -eq 0 ]; then
            [ $BHMAS_liststatusShowOnlyQueuedOption = "TRUE" ] && continue
            STATUS="notQueued"
        elif [ ${#STATUS[@]} -eq 1 ]; then
            STATUS=${STATUS[0]}
        else
            cecho lr B "\n " U "WARNING" uU ":" uB " There are more than one job with " emph "${LOCAL_PARAMETERS_STRING}" " and " emph "BETA=$BETA" " as parameters! This should not happen! Aborting...\n"
            exit -1
        fi

        #----Constructing WORK_BETADIRECTORY, HOME_BETADIRECTORY, JOBSCRIPT_NAME, JOBSCRIPT_GLOBALPATH and INPUTFILE_GLOBALPATH---#
        local OUTPUTFILE_GLOBALPATH="$BHMAS_runDiskGlobalPath/$BHMAS_projectSubpath$LOCAL_PARAMETERS_PATH/$BHMAS_betaPrefix$BETA/$BHMAS_outputFilename"
        local INPUTFILE_GLOBALPATH="$BHMAS_submitDiskGlobalPath/$BHMAS_projectSubpath$LOCAL_PARAMETERS_PATH/$BHMAS_betaPrefix$BETA/$BHMAS_inputFilename"
        local STDOUTPUT_FILE=`ls -t1 $BHMAS_betaPrefix$BETA 2>/dev/null | awk -v filename="$BHMAS_hmcFilename" 'BEGIN{regexp="^"filename".[[:digit:]]+.out$"}{if($1 ~ regexp){print $1}}' | head -n1`
        local STDOUTPUT_GLOBALPATH="$BHMAS_submitDiskGlobalPath/$BHMAS_projectSubpath$LOCAL_PARAMETERS_PATH/$BHMAS_betaPrefix$BETA/$STDOUTPUT_FILE"
        #-------------------------------------------------------------------------------------------------------------------------#
        if [ $BHMAS_liststatusMeasureTimeOption = "TRUE" ]; then
            if [ -f $STDOUTPUT_GLOBALPATH ] && [[ $STATUS == "RUNNING" ]]; then
                #Since in CL2QCD std. output there is only the time of saving and not the day, I have to go through the std. output and count the
                #number of days (done looking at the hours). One could sum up all the tr. times but it is not really efficient!
                local TIMES_ARRAY=( $(grep "finished trajectory" $STDOUTPUT_GLOBALPATH | awk '{print substr($1,2,8)}') )
                local UNIQUE_HOURS_ARRAY=( $(grep "finished trajectory" $STDOUTPUT_GLOBALPATH | awk '{print substr($1,2,2)}' | uniq -d) )
                #I use the number of occurences of the second hours in order to get the almost correct number of days,
                #then I correct in the case the last hour is equal to the first.
                if [ ${#UNIQUE_HOURS_ARRAY[@]} -lt 2 ]; then
                    local NUMBER_OF_DAYS=0
                else
                    local NUMBER_OF_DAYS=$(awk 'BEGIN{RS=" "}NR==2{secondHour=$1}{hours[$1]++}END{print hours[secondHour]-1}' <<< "${UNIQUE_HOURS_ARRAY[@]}")
                    if [ ${UNIQUE_HOURS_ARRAY[0]} -eq ${UNIQUE_HOURS_ARRAY[@]:(-1)} ]; then
                        [ $(TimeToSeconds ${TIMES_ARRAY[0]}) -le $(TimeToSeconds ${TIMES_ARRAY[@]:(-1)}) ] && NUMBER_OF_DAYS=$(($NUMBER_OF_DAYS + 1))
                    fi
                fi
                #Now we can calculate the total time and then the average time if we have done more than one trajectory!
                if [ ${#TIMES_ARRAY[@]} -gt 1 ]; then
                    local TOTAL_TIME_OF_SIMULATION=$(( $(date -d "${TIMES_ARRAY[@]:(-1)}" +%s) - $(date -d "${TIMES_ARRAY[0]}" +%s) ))
                    [ $TOTAL_TIME_OF_SIMULATION -lt 0 ] && TOTAL_TIME_OF_SIMULATION=$(( $TOTAL_TIME_OF_SIMULATION + 86400 ))
                    TOTAL_TIME_OF_SIMULATION=$(( $TOTAL_TIME_OF_SIMULATION + $NUMBER_OF_DAYS*86400 ))
                    local AVERAGE_TIME_PER_TRAJECTORY=$(( $TOTAL_TIME_OF_SIMULATION / (${#TIMES_ARRAY[@]}-1) +1)) #The +1 is to round to the following integer
                    #Calculate also last trajectory time
                    local TIME_LAST_TRAJECTORY=$(( $(date -d "${TIMES_ARRAY[@]:(-1)}" +%s) - $(date -d "${TIMES_ARRAY[$((${#TIMES_ARRAY[@]}-2))]}" +%s) ))
                    [ $TIME_LAST_TRAJECTORY -lt 0 ] && TIME_LAST_TRAJECTORY=$(( $TIME_LAST_TRAJECTORY + 86400 ))
                    #The following line is to avoid that the time is 0s because the last two lines found in the file are for the saving to prng.save and prng.xxxx
                    [ $TIME_LAST_TRAJECTORY -lt 1 ] && TIME_LAST_TRAJECTORY=$(( $(date -d "${TIMES_ARRAY[@]:(-1)}" +%s) - $(date -d "${TIMES_ARRAY[$((${#TIMES_ARRAY[@]}-3))]}" +%s) ))
                else
                    local AVERAGE_TIME_PER_TRAJECTORY="ERR"
                    local TIME_LAST_TRAJECTORY="ERR"
                fi
            else
                if [ ! -f $STDOUTPUT_GLOBALPATH ]; then
                    local AVERAGE_TIME_PER_TRAJECTORY="ERR"
                    local TIME_LAST_TRAJECTORY="ERR"
                else
                    local AVERAGE_TIME_PER_TRAJECTORY="----"
                    local TIME_LAST_TRAJECTORY="----"
                fi
            fi
        else
            local AVERAGE_TIME_PER_TRAJECTORY="OFF"
            local TIME_LAST_TRAJECTORY="OFF"
        fi

        if [ -f $OUTPUTFILE_GLOBALPATH ] && [ $(wc -l < $OUTPUTFILE_GLOBALPATH) -gt 0 ]; then

            local TO_BE_CLEANED=$(awk 'BEGIN{traj_num = -1; file_to_be_cleaned=0}{if($1>traj_num){traj_num = $1} else {file_to_be_cleaned=1; exit;}}END{print file_to_be_cleaned}' $OUTPUTFILE_GLOBALPATH)

            if [ $TO_BE_CLEANED -eq 0 ]; then
                local TRAJECTORIES_DONE=$(wc -l < $OUTPUTFILE_GLOBALPATH)
            else
                local TRAJECTORIES_DONE=$(awk 'NR==1{startTr=$1}END{print $1 - startTr + 1}' $OUTPUTFILE_GLOBALPATH)
            fi
            local NUMBER_LAST_TRAJECTORY=$(awk 'END{print $1}' $OUTPUTFILE_GLOBALPATH)
            local ACCEPTANCE=$(awk '{ sum+=$'$BHMAS_acceptanceColumn'} END {printf "%5.2f", 100*sum/(NR)}' $OUTPUTFILE_GLOBALPATH)

            if [ $TRAJECTORIES_DONE -ge 1000 ]; then
                local ACCEPTANCE_LAST=$(tail -n1000 $OUTPUTFILE_GLOBALPATH | awk '{ sum+=$'$BHMAS_acceptanceColumn'} END {printf "%5.2f", 100*sum/(NR)}')
            else
                local ACCEPTANCE_LAST=" --- "
            fi
            local MAX_DELTAS=$(awk 'BEGIN {max=0} {if(sqrt($8^2)>max){max=sqrt($8^2)}} END {printf "%6g", max}' $OUTPUTFILE_GLOBALPATH)
            if [[ $STATUS == "RUNNING" ]]; then
                local TIME_FROM_LAST_MODIFICATION=`expr $(date +%s) - $(stat -c %Y $OUTPUTFILE_GLOBALPATH)`
            else
                local TIME_FROM_LAST_MODIFICATION="------"
            fi

        else

            local TO_BE_CLEANED=0
            local TRAJECTORIES_DONE="-----"
            local NUMBER_LAST_TRAJECTORY="----"
            local ACCEPTANCE=" ----"
            local ACCEPTANCE_LAST=" ----"
            local MAX_DELTAS=" ----"
            local TIME_FROM_LAST_MODIFICATION="------"

        fi

        if [ -f $INPUTFILE_GLOBALPATH ]; then
            local INT0=$( grep -o "integrationsteps0=[[:digit:]]\+"  $INPUTFILE_GLOBALPATH | sed 's/integrationsteps0=\([[:digit:]]\+\)/\1/' )
            local INT1=$( grep -o "integrationsteps1=[[:digit:]]\+"  $INPUTFILE_GLOBALPATH | sed 's/integrationsteps1=\([[:digit:]]\+\)/\1/' )
            if [[ ! $INT0 =~ ^[[:digit:]]+$ ]] || [[ ! $INT1 =~ ^[[:digit:]]+$ ]]; then
                INT0="--"
                INT1="--"
            fi
            if [ $(grep -o "use_mp=1" $INPUTFILE_GLOBALPATH | wc -l) -eq 1 ]; then
                local INT2="-$( grep -o "integrationsteps2=[[:digit:]]\+"  $INPUTFILE_GLOBALPATH | sed 's/integrationsteps2=\([[:digit:]]\+\)/\1/' )"
                local K_MP="-$( grep -o "kappa_mp=[[:digit:]]\+[.][[:digit:]]\+"  $INPUTFILE_GLOBALPATH | sed 's/kappa_mp=\(.*\)/\1/' )"
                if [[ ! $INT2 =~ ^-[[:digit:]]+$ ]] || [[ ! $K_MP =~ ^-[[:digit:]]+[.][[:digit:]]+$ ]]; then
                    INT2="--"
                    K_MP="--"
                fi
            else
                local INT2="  "
                local K_MP="      "
            fi
        else
            local INT0="--"
            local INT1="--"
            local INT2="--"
            local K_MP="-----"
        fi

        printf \
            "$(ColorBeta)%-15s\t  \
$(ColorClean $TO_BE_CLEANED)%8s${BHMAS_defaultListstatusColor} \
($(GoodAcc $ACCEPTANCE)%s %%${BHMAS_defaultListstatusColor}) \
[$(GoodAcc $ACCEPTANCE_LAST)%s %%${BHMAS_defaultListstatusColor}] \
%s-%s%s%s\t\
$(ColorStatus $STATUS)%9s${BHMAS_defaultListstatusColor}\t\
$(ColorDeltaS $MAX_DELTAS)%9s${BHMAS_defaultListstatusColor}\t   \
$(ColorTime $TIME_FROM_LAST_MODIFICATION)%s${BHMAS_defaultListstatusColor}      \
%6s \
( %s ) \
\n\e[0m" \
            "$(GetShortenedBetaString)" \
            "$TRAJECTORIES_DONE" \
            "$ACCEPTANCE" \
            "$ACCEPTANCE_LAST" \
            "$INT0" "$INT1" "$INT2" "$K_MP" \
            "$STATUS"   "$MAX_DELTAS" \
            "$(awk '{if($1 ~ /^[[:digit:]]+$/){printf "%6d", $1}else{print $1}}' <<< "$TIME_FROM_LAST_MODIFICATION") sec. ago" \
            "$NUMBER_LAST_TRAJECTORY" \
            "$(awk '{if($1 ~ /^[[:digit:]]+$/ && $2 ~ /^[[:digit:]]+$/){printf "%3ds | %3ds", $1, $2}else if($1 == "ERR" || $2 == "ERR"){print "_errorMeas_"}else{print "notMeasured"}}' <<< "$TIME_LAST_TRAJECTORY $AVERAGE_TIME_PER_TRAJECTORY")"

        if [ $TO_BE_CLEANED -eq 0 ]; then
            printf "%s\t\t%8s (%s %%) [%s %%]  %s-%s%s%s\t%9s\t%s\n"   "$(GetShortenedBetaString)"   "$TRAJECTORIES_DONE"   "$ACCEPTANCE"   "$ACCEPTANCE_LAST"   "$INT0" "$INT1" "$INT2" "$K_MP"   "$STATUS"   "$MAX_DELTAS" >> $JOBS_STATUS_FILE
        else
            printf "%s\t\t%8s (%s %%) [%s %%]  %s-%s%s%s\t%9s\t%s\t ---> File to be cleaned!\n"   "$(GetShortenedBetaString)"   "$TRAJECTORIES_DONE"   "$ACCEPTANCE"   "$ACCEPTANCE_LAST"   "$INT0" "$INT1" "$INT2" "$K_MP"   "$STATUS"   "$MAX_DELTAS" >> $JOBS_STATUS_FILE
        fi

    done #Loop on BETA
    cecho -d "${BHMAS_defaultListstatusColor}==============================================================================================================================================="
}

function GetShortenedBetaString()
{
    if [ "$POSTFIX_FROM_FOLDER" == "continueWithNewChain" ]; then
        printf "${BETA%_*}_NC"
    elif [ "$POSTFIX_FROM_FOLDER" == "thermalizeFromHot" ]; then
        printf "${BETA%_*}_fH"
    elif [ "$POSTFIX_FROM_FOLDER" == "thermalizeFromConf" ]; then
        printf "${BETA%_*}_fC"
    else
        printf "${BETA%_*}"
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

function ColorStatus()
{
    if [[ $1 == "RUNNING" ]]; then
        printf $BHMAS_runningListstatusColor
    elif [[ $1 == "PENDING" ]]; then
        printf $BHMAS_pendingListstatusColor
    else
        printf $BHMAS_defaultListstatusColor
    fi
}

function ColorTime()
{
    if [[ ! $1 =~ ^[[:digit:]]+$ ]]; then
        printf $BHMAS_defaultListstatusColor
    else
        [ $1 -gt 450 ] && printf $BHMAS_stuckSimulationListstatusColor || printf $BHMAS_fineSimulationListstatusColor
    fi
}

function ColorClean()
{
    [ $1 -eq 0 ] && printf $BHMAS_defaultListstatusColor || printf $BHMAS_toBeCleanedListstatusColor
}

function ColorBeta()
{
    #Columns here below ranges from 1 on, since they are used in awk
    declare -A OBSERVABLES_COLUMNS=( ["TrajectoryNr"]=1
                                     ["Plaquette"]=2
                                     ["PlaquetteSpatial"]=3
                                     ["PlaquetteTemporal"]=4
                                     ["PolyakovLoopRe"]=5
                                     ["PolyakovLoopIm"]=6
                                     ["PolyakovLoopSq"]=7
                                     ["Accepted"]=11 )
    local AUX1=$(printf "%s," "${OBSERVABLES_COLUMNS[@]}")
    local AUX2=$(printf "%s," "${!OBSERVABLES_COLUMNS[@]}")
    if [ ! -f $OUTPUTFILE_GLOBALPATH ]; then
        printf $BHMAS_defaultListstatusColor
        return
    fi

    awk -v obsColumns="${AUX1%?}" -v obsNames="${AUX2%?}" -f ${BaHaMAS_repositoryTopLevelPath}/SLURM_Implementation/CheckCorrectnessCl2qcdOutputFile.awk $OUTPUTFILE_GLOBALPATH
    local ERROR_CODE=$?

    if [ $ERROR_CODE -eq 0 ]; then
        printf $BHMAS_defaultListstatusColor
    elif [ $ERROR_CODE -eq 1 ]; then
        printf $BHMAS_wrongBetaListstatusColor
    else
        printf $BHMAS_suspiciousBetaListstatusColor
    fi

}


function ColorDeltaS()
{
    if [[ ! $1 =~ [+-]?[[:digit:]]+[.]?[[:digit:]]* ]]; then
        printf $BHMAS_defaultListstatusColor
    else
        if [ "$POSTFIX_FROM_FOLDER" == "continueWithNewChain" ] && [ $(awk -v threshold=$BHMAS_deltaSThreshold -v value=$1 'BEGIN{if(value >= threshold)print 1; else print 0;}') -eq 1 ]; then
            printf $BHMAS_tooHighDeltaSListstatusColor
        else
            printf $BHMAS_defaultListstatusColor
        fi
    fi
}
