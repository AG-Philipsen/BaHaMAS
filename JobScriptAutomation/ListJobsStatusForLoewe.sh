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

function ListJobStatus_Loewe(){
    	 
	 local JOBS_STATUS_FILE="jobs_status_$PARAMETERS_STRING.txt"
	 rm -f $JOBS_STATUS_FILE
	 
	 printf "\n\e[0;36m=====================================================================================================================\n\e[0m"
	 printf "\e[0;35m%s\t\t%s\t  %s\t%s\t  %s\t%s\n\e[0m"   "Beta"   "Num. Traj. (Acc.) [Last 1000] int0-1"   "Status"   "Max DS" "Last tr. finished" "Last tr. in"
	 printf "%s\t\t%s\t\t%s\t\t%s\n"   "Beta"   "Num. Traj. (Acc.) [Last 1000] int0-1"   "Status"   "Max DS" >> $JOBS_STATUS_FILE

	 for BETA in b[[:digit:]]*; do

	     BETA=$(echo $BETA | grep -o "[[:digit:]].[[:digit:]]\{4\}")
	     if [[ ! $BETA =~ ^[[:digit:]].[[:digit:]]{4}$ ]]; then continue; fi
	     
	     local JOBID_ARRAY=( $(squeue | awk 'NR>1{print $1}') )
	     local STATUS=( )
	     for JOBID in ${JOBID_ARRAY[@]}; do

		 local JOBNAME=$(scontrol show job $JOBID | grep "Name=" | sed "s/^.*Name=\(.*$\)/\1/")
		 local JOBNAME_CHEMPOT=$(__static__ExtractParameterFromJOBNAME $CHEMPOT_PREFIX)
		 local JOBNAME_NTIME=$(__static__ExtractParameterFromJOBNAME $NTIME_PREFIX)
		 local JOBNAME_NSPACE=$(__static__ExtractParameterFromJOBNAME $NSPACE_PREFIX)
		 local JOBNAME_KAPPA=$(__static__ExtractParameterFromJOBNAME $KAPPA_PREFIX)

		 local JOBNAME_BETAS=$(echo $JOBNAME | awk -v pref=$BETA_PREFIX -v pref_len=${#BETA_PREFIX} '{print substr($0, index($0, pref))}')
		 if [[ ! $JOBNAME_BETAS =~ b[[:digit:]]{1}[.]{1}[[:digit:]]{4}$ ]]; then
                     continue
		 fi
		 JOBNAME_BETAS=( `echo $JOBNAME_BETAS | sed 's/_/ /g' | sed "s/$BETA_PREFIX//g"` )
		 
		 if ElementInArray "$BETA" "${JOBNAME_BETAS[@]}" && [ "$JOBNAME_KAPPA" = $KAPPA ] && [ "$JOBNAME_NTIME" = $NTIME ] \
                                                                 && [ "$JOBNAME_NSPACE" = $NSPACE ] && [ "$JOBNAME_CHEMPOT" = $CHEMPOT ]; then
		     local TMP_STATUS=$(scontrol show job $JOBID | grep "^[[:blank:]]*JobState=" | sed "s/^.*JobState=\([[:alpha:]]*\).*$/\1/")
		     if [ "$TMP_STATUS" == "RUNNING" ] || [ "$TMP_STATUS" == "PENDING" ]; then
			 STATUS+=( "$TMP_STATUS" )
		     fi
		 fi
		 
	     done
	     if [ ${#STATUS[@]} -eq 0 ]; then
		 STATUS="notQueued"
	     elif [ ${#STATUS[@]} -ne 1 ]; then
		 printf "\n \e[1;37;41mWARNING:\e[0;31m \e[1mThere are more than one job with ${PARAMETERS_STRING} and BETA=$BETA as parameters! CHECK!!! Aborting...\n\n\e[0m\n"
		 exit -1
	     fi

	     #----Constructing WORK_BETADIRECTORY, HOME_BETADIRECTORY, JOBSCRIPT_NAME, JOBSCRIPT_GLOBALPATH and INPUTFILE_GLOBALPATH---#
	     local OUTPUTFILE_GLOBALPATH="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA/$OUTPUTFILE_NAME"
	     local INPUTFILE_GLOBALPATH="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA/$INPUTFILE_NAME"
	     local STDOUTPUT_FILE=`ls -lt $BETA_PREFIX$BETA | awk '{if($9 ~ /^hmc.[[:digit:]]+.out$/){print $9}}' | head -n1`
	     local STDOUTPUT_GLOBALPATH="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA/$STDOUTPUT_FILE"
	     #-------------------------------------------------------------------------------------------------------------------------#
	     if [ -f $STDOUTPUT_GLOBALPATH ]; then
		 if [[ $STATUS == "RUNNING" ]]; then
		     local START_TIME_SEC=$(TimeToSeconds `grep "saving current prng state to file" $STDOUTPUT_GLOBALPATH | tail -n2 | awk '{print substr($1,2,8)}' | head -n1`)
		     local END_TIME_SEC=$(TimeToSeconds `grep "saving current prng state to file" $STDOUTPUT_GLOBALPATH | tail -n2 | awk '{print substr($1,2,8)}' | tail -n1`)
		     if [ $START_TIME_SEC -gt $END_TIME_SEC ]; then
			 END_TIME_SEC=$(( $END_TIME_SEC + 24*3600 ))
		     fi
		     local DURATION_LAST_TR=$(( $END_TIME_SEC - $START_TIME_SEC ))
		     if [[ ! $DURATION_LAST_TR =~ [[:digit:]]+ ]]; then
			 DURATION_LAST_TR="---"
			 local AV_DURATION_LAST_TR=0
		     elif [ "$DURATION_LAST_TR" -lt 840 ]; then #If the last traj. took less than 14min, then in one day probably 100 traj. can be done
			 local NUMBER_DONE_TR_STDOUTPUT=`grep "saving current prng state to file" $STDOUTPUT_GLOBALPATH | wc -l`
			 if [ "$NUMBER_DONE_TR_STDOUTPUT" -ge 101 ]; then
			     START_TIME_SEC=$(TimeToSeconds `grep "saving current prng state to fil" $STDOUTPUT_GLOBALPATH | tail -n101 | awk '{print substr($1,2,8)}' | head -n1`)
			     END_TIME_SEC=$(TimeToSeconds `grep "saving current prng state to fil" $STDOUTPUT_GLOBALPATH | tail -n101 | awk '{print substr($1,2,8)}' | tail -n1`)
			     if [ $START_TIME_SEC -gt $END_TIME_SEC ]; then
				 END_TIME_SEC=$(( $END_TIME_SEC + 24*3600 ))
			     fi
			     DURATION_LAST_TR=$(( ($END_TIME_SEC - $START_TIME_SEC)/100 ))
			     local AV_DURATION_LAST_TR=1
			 elif [ "$NUMBER_DONE_TR_STDOUTPUT" -lt 100 ]; then
			     START_TIME_SEC=$(TimeToSeconds `grep "saving current prng state to fil" $STDOUTPUT_GLOBALPATH | head -n1 | awk '{print substr($1,2,8)}'`)
			     END_TIME_SEC=$(TimeToSeconds `grep "saving current prng state to fil" $STDOUTPUT_GLOBALPATH | tail -n1 | awk '{print substr($1,2,8)}'`)
			     if [ $START_TIME_SEC -gt $END_TIME_SEC ]; then
				 END_TIME_SEC=$(( $END_TIME_SEC + 24*3600 ))
			     fi
			     if [ "$NUMBER_DONE_TR_STDOUTPUT" -gt 2 ]; then
				 DURATION_LAST_TR=$(( ($END_TIME_SEC - $START_TIME_SEC)/($NUMBER_DONE_TR_STDOUTPUT-1) ))
			     else
				 DURATION_LAST_TR="..."
			     fi
			     local AV_DURATION_LAST_TR=1
			 else
			     printf "\n \e[0;31m Error recovering the number of trajectories done from std output file! Aborting...\n\n\e[0m\n"
			     exit -1
			 fi
		     else
			 local AV_DURATION_LAST_TR=0
		     fi
		 else
		     DURATION_LAST_TR="---"
		     local AV_DURATION_LAST_TR="0"
		 fi
	     else
		 local DURATION_LAST_TR="nan"
		 local AV_DURATION_LAST_TR=0
	     fi

	     if [ -f $OUTPUTFILE_GLOBALPATH ]; then
		 
		 local TO_BE_CLEANED=$(awk 'BEGIN{traj_num = -1; file_to_be_cleaned=0}{if($1>traj_num){traj_num = $1} else {file_to_be_cleaned=1; exit;}}END{print file_to_be_cleaned}' $OUTPUTFILE_GLOBALPATH)

		 if [ $TO_BE_CLEANED -eq 0 ]; then
		     local TRAJECTORIES_DONE=$(wc -l $OUTPUTFILE_GLOBALPATH | awk '{print $1}')
		 else
		     local TRAJECTORIES_DONE=$(awk 'NR==1{startTr=$1}END{print $1 - startTr + 1}' $OUTPUTFILE_GLOBALPATH)
		 fi
		 local ACCEPTANCE=$(awk '{ sum+=$11} END {printf "%5.2f", 100*sum/(NR)}' $OUTPUTFILE_GLOBALPATH)

		 if [ $TRAJECTORIES_DONE -ge 1000 ]; then
		     local ACCEPTANCE_LAST=$(tail -n1000 $OUTPUTFILE_GLOBALPATH | awk '{ sum+=$11} END {printf "%5.2f", 100*sum/(NR)}')
		 else
		     local ACCEPTANCE_LAST=0
		 fi
		 local MAX_DELTAS=$(awk 'BEGIN {max=0} {if(sqrt($8^2)>max){max=sqrt($8^2)}} END {printf "%6g", max}' $OUTPUTFILE_GLOBALPATH)
		 if [[ $STATUS == "RUNNING" ]]; then
		     local TIME_FROM_LAST_MODIFICATION=`expr $(date +%s) - $(date +%s -r $OUTPUTFILE_GLOBALPATH)`
		 else
		     local TIME_FROM_LAST_MODIFICATION="------"
		 fi
		 
	     else
		 
		 local TO_BE_CLEANED=0
		 local TRAJECTORIES_DONE="nan"
		 local ACCEPTANCE="nan"
		 local ACCEPTANCE_LAST="nan"
		 local MAX_DELTAS="nan"
		 local TIME_FROM_LAST_MODIFICATION="nan"
		 
	     fi

	     if [ -f $INPUTFILE_GLOBALPATH ]; then
		 local INT0=$( grep -o "integrationsteps0=[[:digit:]]\+"  $INPUTFILE_GLOBALPATH | sed 's/integrationsteps0=\([[:digit:]]\+\)/\1/' )
		 local INT1=$( grep -o "integrationsteps1=[[:digit:]]\+"  $INPUTFILE_GLOBALPATH | sed 's/integrationsteps1=\([[:digit:]]\+\)/\1/' )
		 if [[ ! $INT0 =~ ^[[:digit:]]+$ ]] || [[ ! $INT1 =~ ^[[:digit:]]+$ ]]; then
		     INT0="--"
		     INT1="--"
		 fi
	     else
		 printf "\n \e[0;31m File $INPUTFILE_GLOBALPATH not found. Integration stpes will not be printed!\n\n\e[0m\n"
	     fi
	     
#	     printf "\e[0;36m%s\t\t\e[0;$((36-$TO_BE_CLEANED*5))m%8s\e[0;36m (\e[0;$(GoodAcc $ACCEPTANCE)m%s %%\e[0;36m) [%s %%] %s-%s\t \e[0;$(ColorStatus $STATUS)m%9s\e[0;36m\t%s\t   \e[0;$(ColorTime $TIME_FROM_LAST_MODIFICATION)m%s\e[0;36m\t   \e[0;$(( $AV_DURATION_LAST_TR==0 ? 33 : 32 ))m%s\n\e[0m" \
	     printf \
"\e[0;36m%s\t\t\
\e[0;$((36-$TO_BE_CLEANED*5))m%8s\e[0;36m \
(\e[0;$(GoodAcc $ACCEPTANCE)m%s %%\e[0;36m) \
[%s %%] \
%s-%s\t \
\e[0;$(ColorStatus $STATUS)m%9s\e[0;36m\
\t%s\t   \
\e[0;$(ColorTime $TIME_FROM_LAST_MODIFICATION)m%s\e[0;36m\t   \
\e[0;$(( $AV_DURATION_LAST_TR==0 ? 33 : 32 ))m%s\n\e[0m" \
		 "$BETA" \
		 "$TRAJECTORIES_DONE" \
		 "$ACCEPTANCE" \
		 "$ACCEPTANCE_LAST" \
                 "$INT0" "$INT1" \
                 "$STATUS"   "$MAX_DELTAS"\
	         "$(echo $TIME_FROM_LAST_MODIFICATION | awk '{if($1 ~ /^[[:digit:]]+$/){printf "%6d", $1}else{print $1}}') sec. ago" \
	         "$(echo $DURATION_LAST_TR | awk '{if($1 ~ /^[[:digit:]]+$/){printf "%3d", $1}else{print $1}}') sec."

	     if [ $TO_BE_CLEANED -eq 0 ]; then
		 printf "%s\t\t%s (%s %%) [%s %%] %s-%s\t\t\t%9s\t%s\n"   "$BETA"   "$TRAJECTORIES_DONE"   "$ACCEPTANCE"   "$ACCEPTANCE_LAST"   "$INT0" "$INT1"   "$STATUS"   "$MAX_DELTAS" >> $JOBS_STATUS_FILE
	     else
		 printf "%s\t\t%s (%s %%) [%s %%]%s-%s\t\t\t%9s\t%s  ---> File to be cleaned!\n"   "$BETA"   "$TRAJECTORIES_DONE"   "$ACCEPTANCE"   "$ACCEPTANCE_LAST"   "$INT0" "$INT1"   "$STATUS"   "$MAX_DELTAS" >> $JOBS_STATUS_FILE
	     fi
	     
	     
	 done
	 printf "\e[0;36m=====================================================================================================================\n\e[0m"
}

function GoodAcc(){
    echo "$1" | awk '{if($1<65){print 31}else if($1>75){print 33}else{print 32}}'
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