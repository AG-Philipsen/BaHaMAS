# Load auxiliary bash files that will be used.
source $HOME/Script/UtilityFunctions.sh || exit -2
#------------------------------------------------------------------------------------#

function __static__ExtractParameterFromJOBNAME(){
    local PREFIX=$1
    #Here it is supposed that the name of the job is ${PARAMETERS_STRING}_(...)
    if [ "$(echo $JOBNAME | grep -o "_\?${PREFIX}[^_]*_" | wc -l)" -gt 1 ]; then
        printf "\n \e[0;31m Parameter \"$PREFIX\" appears more than once in one queued jobname (\"$JOBNAME\")! Aborting...\n\n\e[0m\n"
        exit -1
    fi
    PARAMETERS=$(echo $JOBNAME | grep -o "_\?${PREFIX}[^_]*_" | sed -e 's/_//g' | sed 's/'$PREFIX'//g')
    echo "$PARAMETERS"
}

function __static__ExtractBetasFromJOBNAME(){
    #Here it is supposed that the name of the job is ${PARAMETERS_STRING}_(...)
    #The goal of this function is to get an array whose elements are bx.xxxx_syyyy and since we use involved bash lines it is better to say that:
    #  1) from JOBNAME we take everything after the BETA_PREFIX
    local BETAS_STRING=$(echo $JOBNAME | awk -v pref="$BETA_PREFIX" '{print substr($0, index($0, pref))}')
    #  2) we split on the BETA_PREFIX in order to get all the seeds referred to the same beta
    local TEMPORAL_ARRAY=( $(echo $BETAS_STRING | awk -v pref="$BETA_PREFIX" '{split($1, res, pref); for (i in res) print res[i]}') )
    #  3) we take the value of the beta and of the seeds building up the final array
    local BETAVALUES_ARRAY=()
    for ELEMENT in "${TEMPORAL_ARRAY[@]}"; do
        local BETAVALUE=${ELEMENT%%_*}
        local SEEDS_ARRAY=( $(echo ${ELEMENT#*_} | grep -o "${SEED_PREFIX}[[:alnum:]]\{4\}") )
        if [ ${#SEEDS_ARRAY[@]} -gt 0 ]; then
            for SEED in "${SEEDS_ARRAY[@]}"; do
                BETAVALUES_ARRAY+=( "${BETA_PREFIX}${BETAVALUE}_${SEED}" )
            done
        else
            BETAVALUES_ARRAY+=( "${BETA_PREFIX}${BETAVALUE}" )
        fi
    done
    echo "${BETAVALUES_ARRAY[@]}"
}

function __static__ExtractPostfixFromJOBNAME(){
    local POSTFIX=${JOBNAME##*_}
    if [ "$POSTFIX" == "TC" ]; then
        echo "thermalizeFromConf"
    elif [ "$POSTFIX" == "TH" ]; then
        echo "thermalizeFromHot"
    elif [ "$POSTFIX" == "Thermalize" ]; then
        echo "thermalize_old"
    elif [ "$POSTFIX" == "Tuning" ]; then
        echo "tuning"
        #Also in the "TC" and "TH" cases we have seeds in the name, but such a cases are exluded from the elif
    elif [ $(echo $JOBNAME | grep -o "_${SEED_PREFIX}[[:alnum:]]\{4\}" | wc -l) -ne 0 ]; then 
        echo "continueWithNewChain"
    else
        echo ""
    fi
}

function __static__ExtractMetaInformationFromJOBNAME(){
    local METAINFORMATION_ARRAY=()
    local JOBINFO_STRING="$(squeue --noheader -u $(whoami) -o "%j@%T")" #here JOBINFO_STRING contains spaces at the end of the line
    
    for VALUE in $JOBINFO_STRING; do #here I use the fact that JOBINFO_STRING has spaces to split it (IMPORTANT missing quotes)
        local JOBNAME=${VALUE%@*}
        local JOB_STATUS=${VALUE#*@}
        local JOBNAME_BETAS=( $(__static__ExtractBetasFromJOBNAME) )
        local JOBNAME_POSTFIX=$(__static__ExtractPostfixFromJOBNAME)
        local JOB_PARAMETERS_STRING="${JOBNAME%%__*}"
        #If JOB_PARAMETERS_STRING is not at the beginning of the jobname, skip job
        [ $(echo "$JOBNAME" | grep "^${JOB_PARAMETERS_STRING}" | wc -l) -eq 0 ] && continue
        #If the status is COMPLETING, skip job
        [ $JOB_STATUS == "COMPLETING" ] && continue
        METAINFORMATION_ARRAY+=( $(echo "${JOB_PARAMETERS_STRING} | $( echo "${JOBNAME_BETAS[@]}" | sed 's/ /_/g') | postfix=${JOBNAME_POSTFIX} | ${JOB_STATUS}" | sed 's/ //g') )
    done && unset -v 'VALUE'

    echo "${METAINFORMATION_ARRAY[@]}"
}

function ListJobStatus_Loewe(){

    # This function can be called by the JobHandler either in the LISTSTATUS setup or in the DATABASE setup.
    # The crucial difference is that in the first case the PARAMETERS_STRING and PARAMETERS_PATH variable
    # must be the global ones, otherwise they have to be built on the basis of some given information.
    # Then we make this function accept one and ONLY ONE argument (given only in the DATABASE setup)
    # containing the PARAMETERS_PATH (e.g. /muiPiT/k1550/nt6/ns12) and we will define local
    # PARAMETERS_STRING and PARAMETERS_PATH variables filled differently in the two cases.
    # In the DATABASE setup the PARAMETERS_STRING is built using the argument given.
    if [ $# -eq 0 ]; then
        local LOCAL_PARAMETERS_STRING="$PARAMETERS_STRING"
        local LOCAL_PARAMETERS_PATH="$PARAMETERS_PATH"
    elif [ $# -eq 1 ]; then
        local LOCAL_PARAMETERS_PATH="$1"
        local LOCAL_PARAMETERS_STRING=$(sed 's@/@_@g' <<< "$LOCAL_PARAMETERS_PATH")
        LOCAL_PARAMETERS_STRING=${LOCAL_PARAMETERS_STRING:1}
	else 
		echo "\e[31m Wrong invocation of ListJobStatus_Loewe: Invalid number of arguments. Please investigate...exiting."
		return
	fi
    

    local JOBS_STATUS_FILE="jobs_status_$LOCAL_PARAMETERS_STRING.txt"
    rm -f $JOBS_STATUS_FILE
    
    printf "\n\e[0;36m===============================================================================================================================================\n\e[0m"
    printf "\e[0;35m%s\t\t  %s\t  %s\t   %s\t  %s\t%s\n\e[0m"   "Beta"   "Traj. Done (Acc.) [Last 1000] int0-1-2-kmp"   "Status"   "Max DS" "Last tr. finished" " Tr: # (time last|av.)"
    printf "%s\t\t\t  %s\t  %s\t%s\t  %s\t%s\n"   "Beta"   "Traj. Done (Acc.) [Last 1000] int0-1-2-kmp"   "Status"   "Max DS" >> $JOBS_STATUS_FILE

    JOB_METAINFORMATION_ARRAY=( $(__static__ExtractMetaInformationFromJOBNAME) )
    
    for BETA in ${BETA_PREFIX}[[:digit:]]*; do

	    #Select only folders with old or new names
	    BETA=${BETA#$BETA_PREFIX}
	    if [[ ! $BETA =~ ^[[:digit:]][.][[:digit:]]{4}$ ]] &&
	           [[ ! $BETA =~ ^[[:digit:]][.][[:digit:]]{4}_"$SEED_PREFIX"[[:alnum:]]{4}_continueWithNewChain$ ]] &&
	           [[ ! $BETA =~ ^[[:digit:]][.][[:digit:]]{4}_"$SEED_PREFIX"[[:alnum:]]{4}_thermalizeFromHot$ ]] &&
	           [[ ! $BETA =~ ^[[:digit:]][.][[:digit:]]{4}_"$SEED_PREFIX"[[:alnum:]]{4}_thermalizeFromCold$ ]] &&
	           [[ ! $BETA =~ ^[[:digit:]][.][[:digit:]]{4}_"$SEED_PREFIX"[[:alnum:]]{4}_thermalizeFromConf$ ]]; then continue; fi

	    local POSTFIX_FROM_FOLDER=$(echo ${BETA##*_} | grep -o "[[:alpha:]]\+\$")

        local STATUS=( $(sed 's/ /\n/g' <<< "${JOB_METAINFORMATION_ARRAY[@]}" | grep "${LOCAL_PARAMETERS_STRING}" | grep "${BETA_PREFIX}${BETA%_*}" | grep "postfix=${POSTFIX_FROM_FOLDER}|" | cut -d'|' -f4) )

	    if [ ${#STATUS[@]} -eq 0 ]; then
	        [ $LISTSTATUS_SHOW_ONLY_QUEUED = "TRUE" ] && continue
	        STATUS="notQueued"
        elif [ ${#STATUS[@]} -eq 1 ]; then
            STATUS=${STATUS[0]}
	    else
	        printf "\n \e[1;37;41mWARNING:\e[0;31m \e[1mThere are more than one job with ${LOCAL_PARAMETERS_STRING} and BETA=$BETA as parameters! CHECK!!! Aborting...\n\n\e[0m\n"
	        exit -1
	    fi
	    
	    #----Constructing WORK_BETADIRECTORY, HOME_BETADIRECTORY, JOBSCRIPT_NAME, JOBSCRIPT_GLOBALPATH and INPUTFILE_GLOBALPATH---#
	    local OUTPUTFILE_GLOBALPATH="$WORK_DIR/$SIMULATION_PATH$LOCAL_PARAMETERS_PATH/$BETA_PREFIX$BETA/$OUTPUTFILE_NAME"
	    local INPUTFILE_GLOBALPATH="$HOME_DIR/$SIMULATION_PATH$LOCAL_PARAMETERS_PATH/$BETA_PREFIX$BETA/$INPUTFILE_NAME"
	    local STDOUTPUT_FILE=`ls -t1 $BETA_PREFIX$BETA 2>/dev/null | awk -v filename="$HMC_FILENAME" 'BEGIN{regexp="^"filename".[[:digit:]]+.out$"}{if($1 ~ regexp){print $1}}' | head -n1`
	    local STDOUTPUT_GLOBALPATH="$HOME_DIR/$SIMULATION_PATH$LOCAL_PARAMETERS_PATH/$BETA_PREFIX$BETA/$STDOUTPUT_FILE"
	    #-------------------------------------------------------------------------------------------------------------------------#
	    if [ $LISTSTATUS_MEASURE_TIME = "TRUE" ]; then
	        if [ -f $STDOUTPUT_GLOBALPATH ] && [[ $STATUS == "RUNNING" ]]; then
    	        #Since in CL2QCD std. output there is only the time of saving and not the day, I have to go through the std. output and count the
	            #number of days (done looking at the hours). One could sum up all the tr. times as done in the TimeTrajectoryCL2QCD.sh but it is
	            #not really efficient!
		        local TIMES_ARRAY=( $(grep "finished trajectory" $STDOUTPUT_GLOBALPATH | awk '{print substr($1,2,8)}') )
		        local UNIQUE_HOURS_ARRAY=( $(grep "finished trajectory" $STDOUTPUT_GLOBALPATH | awk '{print substr($1,2,2)}' | uniq -d) )
	            #local =( $(echo ${TIMES_ARRAY[@]} | awk 'BEGIN{RS=" "}{print substr($1,1,2)}' | uniq -d) )
	            #I use the number of occurences of the second hours in order to get the almost correct number of days,
	            #then I correct in the case the last hour is equal to the first.
		        if [ ${#UNIQUE_HOURS_ARRAY[@]} -lt 2 ]; then
		            local NUMBER_OF_DAYS=0
		        else
		            local NUMBER_OF_DAYS=$(echo ${UNIQUE_HOURS_ARRAY[@]} | awk 'BEGIN{RS=" "}NR==2{secondHour=$1}{hours[$1]++}END{print hours[secondHour]-1}')
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
	        local ACCEPTANCE=$(awk '{ sum+=$11} END {printf "%5.2f", 100*sum/(NR)}' $OUTPUTFILE_GLOBALPATH)
	        
	        if [ $TRAJECTORIES_DONE -ge 1000 ]; then
		        local ACCEPTANCE_LAST=$(tail -n1000 $OUTPUTFILE_GLOBALPATH | awk '{ sum+=$11} END {printf "%5.2f", 100*sum/(NR)}')
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
	        #printf "\n \e[0;31m File $INPUTFILE_GLOBALPATH not found. Integration stpes will not be printed!\n\n\e[0m\n"
	        local INT0="--"
	        local INT1="--"
	        local INT2="--"
	        local K_MP="-----"
	    fi
	    
	    printf \
            "$(ColorBeta)%-15s\t  \
$(ColorClean $TO_BE_CLEANED)%8s\e[0;36m \
($(GoodAcc $ACCEPTANCE)%s %%\e[0;36m) \
[$(GoodAcc $ACCEPTANCE_LAST)%s %%\e[0;36m] \
%s-%s%s%s\t\
$(ColorStatus $STATUS)%9s\e[0;36m\
\t%9s\t   \
$(ColorTime $TIME_FROM_LAST_MODIFICATION)%s\e[0;36m      \
%6s \
( %s ) \
\n\e[0m" \
	        "$(GetShortenedBetaString)" \
	        "$TRAJECTORIES_DONE" \
	        "$ACCEPTANCE" \
	        "$ACCEPTANCE_LAST" \
            "$INT0" "$INT1" "$INT2" "$K_MP" \
            "$STATUS"   "$MAX_DELTAS" \
	        "$(echo $TIME_FROM_LAST_MODIFICATION | awk '{if($1 ~ /^[[:digit:]]+$/){printf "%6d", $1}else{print $1}}') sec. ago" \
	        "$NUMBER_LAST_TRAJECTORY" \
	        "$(echo "$TIME_LAST_TRAJECTORY $AVERAGE_TIME_PER_TRAJECTORY" | awk '{if($1 ~ /^[[:digit:]]+$/ && $2 ~ /^[[:digit:]]+$/){printf "%3ds | %3ds", $1, $2}else if($1 == "ERR" || $2 == "ERR"){print "_errorMeas_"}else{print "notMeasured"}}')" 
	    
	    if [ $TO_BE_CLEANED -eq 0 ]; then
	        printf "%s\t\t%8s (%s %%) [%s %%]  %s-%s%s%s\t%9s\t%s\n"   "$(GetShortenedBetaString)"   "$TRAJECTORIES_DONE"   "$ACCEPTANCE"   "$ACCEPTANCE_LAST"   "$INT0" "$INT1" "$INT2" "$K_MP"   "$STATUS"   "$MAX_DELTAS" >> $JOBS_STATUS_FILE
	    else
	        printf "%s\t\t%8s (%s %%) [%s %%]  %s-%s%s%s\t%9s\t%s\t ---> File to be cleaned!\n"   "$(GetShortenedBetaString)"   "$TRAJECTORIES_DONE"   "$ACCEPTANCE"   "$ACCEPTANCE_LAST"   "$INT0" "$INT1" "$INT2" "$K_MP"   "$STATUS"   "$MAX_DELTAS" >> $JOBS_STATUS_FILE
	    fi
	    
    done #Loop on BETA
    printf "\e[0;36m===============================================================================================================================================\n\e[0m"
}

function GetShortenedBetaString(){
    if [ "$POSTFIX_FROM_FOLDER" == "continueWithNewChain" ]; then
	    echo "${BETA%_*}_NC"
    elif [ "$POSTFIX_FROM_FOLDER" == "thermalizeFromHot" ]; then
	    echo "${BETA%_*}_fH"
    elif [ "$POSTFIX_FROM_FOLDER" == "thermalizeFromConf" ]; then
	    echo "${BETA%_*}_fC"
    else 
	    echo "${BETA%_*}"
    fi
}

function GoodAcc(){
    echo "$1" | awk -v tl="${TOO_LOW_ACCEPTANCE_LISTSTATUS_COLOR/\\/\\\\}" \
                    -v l="${LOW_ACCEPTANCE_LISTSTATUS_COLOR/\\/\\\\}" \
                    -v op="${OPTIMAL_ACCEPTANCE_LISTSTATUS_COLOR/\\/\\\\}" \
                    -v h="${HIGH_ACCEPTANCE_LISTSTATUS_COLOR/\\/\\\\}" \
                    -v th="${TOO_HIGH_ACCEPTANCE_LISTSTATUS_COLOR/\\/\\\\}" \
                    -v tlt="$TOO_LOW_ACCEPTANCE_THRESHOLD" \
                    -v lt="$LOW_ACCEPTANCE_THRESHOLD" \
                    -v ht="$HIGH_ACCEPTANCE_THRESHOLD" \
                    -v tht="$TOO_HIGH_ACCEPTANCE_THRESHOLD" '{if($1<tlt){print tl}else if($1<lt){print l}else if($1>tht){print th}else if($1>ht){print h}else{print op}}'
}

function ColorStatus(){
    if [[ $1 == "RUNNING" ]]; then
	    echo $RUNNING_LISTSTATUS_COLOR
    elif [[ $1 == "PENDING" ]]; then
	    echo $PENDING_LISTSTATUS_COLOR
    else
	    echo $DEFAULT_LISTSTATUS_COLOR
    fi
}

function ColorTime(){
    if [[ ! $1 =~ ^[[:digit:]]+$ ]]; then
	    echo $DEFAULT_LISTSTATUS_COLOR
    else
        [ $1 -gt 450 ] && echo "$STUCK_SIMULATION_LISTSTATUS_COLOR" || echo "$FINE_SIMULATION_LISTSTATUS_COLOR"
    fi
}

function ColorClean(){
    [ $1 -eq 0 ] && echo "$DEFAULT_LISTSTATUS_COLOR" || echo "$CLEANING_LISTSTATUS_COLOR"
}

function ColorBeta(){
    #Columns here below ranges from 1 on, since they are used in awk
    declare -A OBSERVABLES_COLUMNS
    OBSERVABLES_COLUMNS["TrajectoryNr"]=1
    OBSERVABLES_COLUMNS["Plaquette"]=2
    OBSERVABLES_COLUMNS["PlaquetteSpatial"]=3
    OBSERVABLES_COLUMNS["PlaquetteTemporal"]=4
    OBSERVABLES_COLUMNS["PolyakovLoopRe"]=5
    OBSERVABLES_COLUMNS["PolyakovLoopIm"]=6
    OBSERVABLES_COLUMNS["PolyakovLoopSq"]=7
    OBSERVABLES_COLUMNS["Accepted"]=11
    local AUX1=$(printf "%s," "${OBSERVABLES_COLUMNS[@]}")
    local AUX2=$(printf "%s," "${!OBSERVABLES_COLUMNS[@]}")
    if [ ! -f $OUTPUTFILE_GLOBALPATH ]; then
        echo $DEFAULT_LISTSTATUS_COLOR
        return
    fi
    
    awk -v obsColumns="${AUX1%?}" -v obsNames="${AUX2%?}" -f ${HOME}/Script/JobScriptAutomation/CheckCorrectnessCl2qcdOutputFile.awk $OUTPUTFILE_GLOBALPATH
    local ERROR_CODE=$?
    
    if [ $ERROR_CODE -eq 0 ]; then
        echo $DEFAULT_LISTSTATUS_COLOR
    elif [ $ERROR_CODE -eq 1 ]; then
        echo $WRONG_BETA_LISTSTATUS_COLOR
    else
        echo $SUSPICIOUS_BETA_LISTSTATUS_COLOR
    fi
    
}


