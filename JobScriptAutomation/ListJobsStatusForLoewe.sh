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
    local JOBID_ARRAY=( $(squeue | awk -v username="$(whoami)" 'NR>1{if($4 == username){print $1}}') )
    for JOBID in ${JOBID_ARRAY[@]}; do
        local JOBNAME=$(scontrol show job $JOBID | grep "Name=" | sed "s/^.*Name=\(.*$\)/\1/")
        local JOBNAME_CHEMPOT=$(__static__ExtractParameterFromJOBNAME $CHEMPOT_PREFIX)
        local JOBNAME_NTIME=$(__static__ExtractParameterFromJOBNAME $NTIME_PREFIX)
        local JOBNAME_NSPACE=$(__static__ExtractParameterFromJOBNAME $NSPACE_PREFIX)
        local JOBNAME_KAPPA=$(__static__ExtractParameterFromJOBNAME $KAPPA_PREFIX)
        local JOBNAME_BETAS=( $(__static__ExtractBetasFromJOBNAME) )
        local JOBNAME_POSTFIX=$(__static__ExtractPostfixFromJOBNAME)
        local JOB_STATUS=$(scontrol show job $JOBID | grep "^[[:blank:]]*JobState=" | sed "s/^.*JobState=\([[:alpha:]]*\).*$/\1/")
        #Retrieved the information add an unique string to array of meta information
        local PREFIXES=([$CHEMPOT_POSITION]=$CHEMPOT_PREFIX [$KAPPA_POSITION]=$KAPPA_PREFIX [$NTIME_POSITION]=$NTIME_PREFIX [$NSPACE_POSITION]=$NSPACE_PREFIX)
        local JOB_PARAMETERS_VALUE=([$CHEMPOT_POSITION]=$JOBNAME_CHEMPOT [$KAPPA_POSITION]=$JOBNAME_KAPPA [$NTIME_POSITION]=$JOBNAME_NTIME [$NSPACE_POSITION]=$JOBNAME_NSPACE)
        local JOB_PARAMETERS_STRING=""
        for ((i=0; i<${#PREFIXES[@]}; i++)); do
            JOB_PARAMETERS_STRING="$JOB_PARAMETERS_STRING${PREFIXES[$i]}${JOB_PARAMETERS_VALUE[$i]}_"
        done
        JOB_PARAMETERS_STRING=${JOB_PARAMETERS_STRING%?} #Remove last underscore
        #If JOB_PARAMETERS_STRING is not at the beginning of the jobname, skip job
        [ $(echo "$JOBNAME" | grep "^${JOB_PARAMETERS_STRING}" | wc -l) -eq 0 ] && continue
        #If the status is COMPLETING, skip job
        [ $JOB_STATUS == "COMPLETING" ] && continue
        METAINFORMATION_ARRAY+=( $(echo "${JOB_PARAMETERS_STRING} | $( echo "${JOBNAME_BETAS[@]}" | sed 's/ /_/g') | postfix=${JOBNAME_POSTFIX} | ${JOB_STATUS}" | sed 's/ //g') )
    done
    echo "${METAINFORMATION_ARRAY[@]}"
}

function ListJobStatus_Loewe(){

    local JOBS_STATUS_FILE="jobs_status_$PARAMETERS_STRING.txt"
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
	   [[ ! $BETA =~ ^[[:digit:]][.][[:digit:]]{4}_"$SEED_PREFIX"[[:alnum:]]{4}_thermalizeFromConf$ ]]; then continue; fi

	local POSTFIX_FROM_FOLDER=$(echo ${BETA##*_} | grep -o "[[:alpha:]]\+\$")

	local STATUS=( )
	for JOB_MATCHING in $(echo ${JOB_METAINFORMATION_ARRAY[@]} | sed 's/ /\n/g' | grep "${PARAMETERS_STRING}" | grep "${BETA_PREFIX}${BETA%_*}" | grep "postfix=${POSTFIX_FROM_FOLDER}|"); do
	    STATUS+=( "${JOB_MATCHING##*|}" )
	done
	if [ ${#STATUS[@]} -eq 0 ]; then
	    [ $LISTSTATUS_SHOW_ONLY_QUEUED = "TRUE" ] && continue
	    STATUS="notQueued"
	elif [ ${#STATUS[@]} -ne 1 ]; then
	    printf "\n \e[1;37;41mWARNING:\e[0;31m \e[1mThere are more than one job with ${PARAMETERS_STRING} and BETA=$BETA as parameters! CHECK!!! Aborting...\n\n\e[0m\n"
	    exit -1
	fi
	
	#----Constructing WORK_BETADIRECTORY, HOME_BETADIRECTORY, JOBSCRIPT_NAME, JOBSCRIPT_GLOBALPATH and INPUTFILE_GLOBALPATH---#
	local OUTPUTFILE_GLOBALPATH="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA/$OUTPUTFILE_NAME"
	local INPUTFILE_GLOBALPATH="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA/$INPUTFILE_NAME"
	local STDOUTPUT_FILE=`ls -lt $BETA_PREFIX$BETA | awk -v filename="$HMC_FILENAME" 'BEGIN{regexp="^"filename".[[:digit:]]+.out$"}{if($9 ~ regexp){print $9}}' | head -n1`
	local STDOUTPUT_GLOBALPATH="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA/$STDOUTPUT_FILE"
	#-------------------------------------------------------------------------------------------------------------------------#
	if [ $LISTSTATUS_MEASURE_TIME = "TRUE" ]; then
	    if [ -f $STDOUTPUT_GLOBALPATH ] && [[ $STATUS == "RUNNING" ]]; then
    	        #Since in CL2QCD std. output there is only the time of saving and not the day, I have to go through the std. output and count the
	        #number of days (done looking at the hours). One could sum up all the tr. times as done in the TimeTrajectoryCL2QCD.sh but it is
	        #not really efficient!
		local TIMES_ARRAY=( $(grep "saving current prng state to file" $STDOUTPUT_GLOBALPATH | awk '{print substr($1,2,8)}') )
		local UNIQUE_HOURS_ARRAY=( $(grep "saving current prng state to file" $STDOUTPUT_GLOBALPATH | awk '{print substr($1,2,2)}' | uniq -d) )
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
		    #The following line is to avoid that the time is 0s because the last two lines found in the file are for the daving to prng.save and prng.xxxx
		    [ $TIME_LAST_TRAJECTORY -lt 1 ] && TIME_LAST_TRAJECTORY=$(( $(date -d "${TIMES_ARRAY[@]:(-1)}" +%s) - $(date -d "${TIMES_ARRAY[$((${#TIMES_ARRAY[@]}-3))]}" +%s) ))
		else
		    local AVERAGE_TIME_PER_TRAJECTORY="----"
		    local TIME_LAST_TRAJECTORY="----"
		fi
	    else
		local AVERAGE_TIME_PER_TRAJECTORY="----"
		local TIME_LAST_TRAJECTORY="----"
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
		local TIME_FROM_LAST_MODIFICATION=`expr $(date +%s) - $(date +%s -r $OUTPUTFILE_GLOBALPATH)`
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
"\e[0;36m%-15s\t  \
\e[0;$((36-$TO_BE_CLEANED*5))m%8s\e[0;36m \
(\e[38;5;$(GoodAcc $ACCEPTANCE)m%s %%\e[0;36m) \
[\e[38;5;$(GoodAcc $ACCEPTANCE_LAST)m%s %%\e[0;36m]  \
%s-%s%s%s\t \
\e[0;$(ColorStatus $STATUS)m%9s\e[0;36m\
\t%9s\t   \
\e[0;$(ColorTime $TIME_FROM_LAST_MODIFICATION)m%s\e[0;36m      \
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
	    "$(echo "$TIME_LAST_TRAJECTORY $AVERAGE_TIME_PER_TRAJECTORY" | awk '{if($1 ~ /^[[:digit:]]+$/ && $2 ~ /^[[:digit:]]+$/){printf "%3ds | %3ds", $1, $2}else{print "notMeasured"}}')" 
	
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
    echo "$1" | awk '{if($1<68){print 9}else if($1<70){print 208}else if($1>78){print 11}else if($1>90){print 202}else{print 10}}'
}

function ColorStatus(){
    if [[ $1 == "RUNNING" ]]; then
	echo "32"
    elif [[ $1 == "PENDING" ]]; then
	echo "33"
    else
	echo "36"
    fi
}

function ColorTime(){
    if [[ ! $1 =~ ^[[:digit:]]+$ ]]; then
	echo "36"
    else
	echo $(($1 > 450 ? 31 : 32 ))
    fi
}

function ColorDuration(){
    if [[ $AV_DURATION_LAST_TR = "" ]]; then
	echo "33"
    else
	echo "32"
    fi
}
