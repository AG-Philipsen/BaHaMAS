#Comment:
#Pattern used for  functions __static__DetermineCreationDateAndSubmits and function __static__CreateSubmitsFile:
#date -d @$(date +"%s") +"%d.%m.%y %H:%M"
#A string %s is passed to date which has the format of seconds and is converted into date and time.
#see manual page for a detailed description of the options.

source $HOME/Script/UtilityFunctions.sh || exit -2

function __static__DetermineCreationDateAndSubmits(){

	if [[ $(ls $HOME_BETADIRECTORY"/" | egrep -o "b[[:digit:]]\.[[:digit:]]{4}_created_[[:digit:]]{2}_[[:digit:]]{2}_[[:digit:]]{2}" | wc -l) = 1 ]]; then

		CREATION_DATE=$(ls $HOME_BETADIRECTORY"/" | egrep -o "b[[:digit:]]\.[[:digit:]]{4}_created_[[:digit:]]{2}_[[:digit:]]{2}_[[:digit:]]{2}" | egrep -o "[[:digit:]]{2}_[[:digit:]]{2}_[[:digit:]]{2}" | sed "s/_/\./g")
		#CREATION_DATE=$(ls $HOME_BETADIRECTORY"/" | egrep -o "b[[:digit:]]\.[[:digit:]]{4}_created_[[:digit:]]{2}igit:]]{2}_[[:digit:]]{2}" | egrep -o "[[:digit:]]{2}_[[:digit:]]{2}_[[:digit:]]{2}" | sed "s/_/\./g") 
	else
		CREATION_DATE="NN.NN.NN"
	fi

	if [ -f "$WORK_BETADIRECTORY/history_hmc_tm" ]; then	

		NRSUBMITS=$(grep "Timestamp" "$WORK_BETADIRECTORY/history_hmc_tm" | wc -l)	
		SUBMITFIRST=$(date -d @$(date +"$(grep "Timestamp" $WORK_BETADIRECTORY/history_hmc_tm | egrep -o "[[:digit:]]{10}" | head -n1)") +"%d.%m.%y")
		SUBMITLAST=$(date -d @$(date +"$(grep "Timestamp" $WORK_BETADIRECTORY/history_hmc_tm | egrep -o "[[:digit:]]{10}" | tail -n1)") +"%d.%m.%y")

#$(date -d @$(date +"$(grep "Timestamp" $WORK_BETADIRECTORY/history_hmc_tm | egrep -o "[[:digit:]]{10}" | tail -n1)") +"%d.%m.%y")
	else
		NRSUBMITS="NNN"
		SUBMITFIRST="NN.NN.NN"
		SUBMITLAST="NN.NN.NN"
	fi
}


function __static__CreateSubmitsFile(){

	local SUBMITS_FILE="Submits"

	local TIMESTAMP_ARRAY=( )

	local SUBMITS_ARRAY=( )

	if [ -f "$WORK_BETADIRECTORY/history_hmc_tm" ]; then	

		TIMESTAMP_ARRAY=( $(grep "Timestamp" $WORK_BETADIRECTORY/history_hmc_tm | egrep -o "[[:digit:]]{10}") )

		for i in ${TIMESTAMP_ARRAY[@]}; do

			SUBMITS_ARRAY+=( $(date -d @$(date +"$i") +"%d.%m.%y_%H:%M") )
		done
	fi

	if [ -d $HOME_BETADIRECTORY ] && [ ${#SUBMITS_ARRAY[@]} -gt 0 ]; then

		rm -f $HOME_BETADIRECTORY/$SUBMITS_FILE

		for i in ${SUBMITS_ARRAY[@]}; do

			echo $i >> $HOME_BETADIRECTORY/$SUBMITS_FILE
		done	
	fi
}

function __static__ListJobsStatus_local(){

	printf "\n\e[0;36m==================================================================================================\n\e[0m"

	printf "\n\e[0;34m%s  %s  %s\n" $KAPPA_PREFIX$KAPPA $NTIME_PREFIX$NTIME $NSPACE_PREFIX$NSPACE 
	printf "\n      %s  %s  %s\n" $KAPPA_PREFIX$KAPPA $NTIME_PREFIX$NTIME $NSPACE_PREFIX$NSPACE >> $JOBS_STATUS_FILE
	printf "\n  Beta Total /  Done  Acc int0/1    Status Sub. Nr /    First /     Last\n\e[0m"
	printf "  	Beta Total /  Done  Acc int0/1    Status Sub. Nr /    First /     Last\n" >> $JOBS_STATUS_FILE

	for i in b*; do

		#Assigning beta value to BETA variable for readability
		BETA=$(echo $i | grep -o "[[:digit:]].[[:digit:]]\{4\}")

		if [[ ! $BETA =~ [[:digit:]].[[:digit:]]{4} ]]; then
				
			continue;
		fi

		STATUS=$(llq -W -f %jn %st -u $(whoami) | awk '$1 ~ /^muiPiT_'$KAPPA_PREFIX$KAPPA'_'$NTIME_PREFIX$NTIME'_'$NSPACE_PREFIX$NSPACE'_'$i'$/ {print $2}') 

		if [ ${#STATUS} -eq 0 ]; then
			STATUS="notQueued"	
		elif [ $STATUS = R ]; then
			STATUS="running"
		elif [ $STATUS = I ]; then
			STATUS="idling"
		fi
		
		#----------Constructing WORK_BETADIRECTORY, HOME_BETADIRECTORY, JOBSCRIPT_GLOBALPATH and INPUTFILE_GLOBALPATH---------#
		WORK_BETADIRECTORY="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
		HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
		INPUTFILE_GLOBALPATH="$HOME_BETADIRECTORY/$INPUTFILE_NAME"
		OUTPUTFILE_GLOBALPATH="$WORK_BETADIRECTORY/$OUTPUTFILE_NAME"
		#---------------------------------------------------------------------------------------------------------------------#

		local WORKDIRS_EXIST="TBD" #TBD = To be determined
		local ACCEPTANCE="TBD"
		local INT0="N"
		local INT1="N"

		if [ -d $WORK_BETADIRECTORY ] && [ -f $OUTPUTFILE_GLOBALPATH ]; then

			WORKDIRS_EXIST="true"
			ACCEPTANCE=$(awk '{ sum+=$7} END {if(NR != 0){acc=sum/(NR); printf "%.2f", acc} else {acc="N.NN";printf "%s", acc} }' $OUTPUTFILE_GLOBALPATH)
		else 
			WORKDIRS_EXIST="false"
		 	ACCEPTANCE="N.NN"
		fi

		if [ -d $HOME_BETADIRECTORY ] && [ -f $INPUTFILE_GLOBALPATH ]; then

			INT0=$(awk '{if (($1 ~ /Integrationsteps0/) || ($1 ~ /IntegrationSteps0/)){print $3}}' $INPUTFILE_GLOBALPATH)
			INT1=$(awk '{if ($1 ~ /IntegrationSteps1/){print $3}}' $INPUTFILE_GLOBALPATH)

			TOTAL_NR_TRAJECTORIES=$(grep "Total number of trajectories" $INPUTFILE_GLOBALPATH | grep -o "[[:digit:]]\+")	
			#TOTAL_NR_TRAJECTORIES=$(expr $TOTAL_NR_TRAJECTORIES - 0)

			if [ $WORKDIRS_EXIST = "true" ]; then

				TRAJECTORIES_DONE=$(tail -n1 $OUTPUTFILE_GLOBALPATH | grep -o "^[[:digit:]]\{8\}")
				TRAJECTORIES_DONE=$(expr $TRAJECTORIES_DONE + 1)
			else

				TRAJECTORIES_DONE=0
			fi
			MEASUREMENTS_REMAINING=$(expr $TOTAL_NR_TRAJECTORIES - $TRAJECTORIES_DONE)

			if [ $STATUS = "notQueued" ] && [ $MEASUREMENTS_REMAINING -eq "0" ]; then

				STATUS="finished"

			elif [ $STATUS = "notQueued" ] && [ $MEASUREMENTS_REMAINING -ne "0" ] && [ $WORKDIRS_EXIST = "true" ]; then

				STATUS="canceled"

			elif [ $STATUS = "notQueued" ] && [ $MEASUREMENTS_REMAINING -ne "0" ] && [ $WORKDIRS_EXIST = "false" ]; then

				STATUS="unknown"
			fi

			__static__DetermineCreationDateAndSubmits

				printf "\e[0;34m%s %5d / %5d $ACCEPTANCE    $INT0/$INT1  %8s     %3s / $SUBMITFIRST / $SUBMITLAST\n\e[0m" $BETA $TOTAL_NR_TRAJECTORIES $TRAJECTORIES_DONE $STATUS $NRSUBMITS
				printf "      %s %5d / %5d $ACCEPTANCE    $INT0/$INT1  %8s     %3s / $SUBMITFIRST / $SUBMITLAST\n" $BETA $TOTAL_NR_TRAJECTORIES $TRAJECTORIES_DONE $STATUS $NRSUBMITS >> $JOBS_STATUS_FILE

			__static__CreateSubmitsFile
		fi
		
	done
}

function __static__ListJobsStatus_global(){

		ORIGINAL_HOME_DIR_WITH_BETAFOLDERS=$HOME_DIR_WITH_BETAFOLDERS
		ORIGINAL_WORK_DIR_WITH_BETAFOLDERS=$WORK_DIR_WITH_BETAFOLDERS

		PARAMETER_REGEX_ARRAY=()
		DIRECTORY_ARRAY=()
		#Filling PARAMETER_REGEX_ARRAY and DIRECTORY_ARRAY:
		BuildRegexPath


		for i in ${DIRECTORY_ARRAY[@]}; do
			
			cd $i	

			PARAMETERS_PATH=""
			PARAMETERS_STRING=""

			ReadParametersFromPath $(pwd)

			HOME_DIR_WITH_BETAFOLDERS="$HOME_DIR/$SIMULATION_PATH$PARAMETERS_PATH"

			if [ "$HOME_DIR_WITH_BETAFOLDERS" != "$(pwd)" ]; then
				printf "\n\e[0;31m Constructed path to directory containing beta folders does not match the actual position! Aborting...\n\n\e[0m"
				exit -1
			fi
			#echo $HOME_DIR_WITH_BETAFOLDERS
			WORK_DIR_WITH_BETAFOLDERS="$WORK_DIR/$SIMULATION_PATH$PARAMETERS_PATH"
			#echo $WORK_DIR_WITH_BETAFOLDERS

			JOBS_STATUS_FILE="jobs_status_"$CHEMPOT_PREFIX$CHEMPOT"_"$KAPPA_PREFIX$KAPPA"_"$NTIME_PREFIX$NTIME"_"$NSPACE_PREFIX$NSPACE".txt"
			#echo $JOBS_STATUS_FILE
			rm -f $JOBS_STATUS_FILE

			__static__ListJobsStatus_local
		done

		cd $ORIGINAL_HOME_DIR_WITH_BETAFOLDERS
}

function __static__BuildGlobalJobStatusFile(){

	DATE='D_'$(date +"%d_%m_%Y")'_T_'$(date +"%H_%M")
	JOBS_STATUS_FILE_GLOBAL=$HOME_DIR'/'$SIMULATION_PATH'/global_'$JOBS_STATUS_PREFIX$DATE'.txt'

	rm -f $JOBS_STATUS_FILE_GLOBAL

	REGEX_PATH=$JOBS_STATUS_PREFIX'[^~]*$'
	REGEX_PATH='.*'$REGEX_PATH

	for i in ${DIRECTORY_ARRAY[@]}; do

		LOCAL_FILE=$(find $i -regextype grep -regex $REGEX_PATH)

		KAPPA_TMP=`echo $LOCAL_FILE | grep -o "$JOBS_STATUS_PREFIX.*" | grep -o "$KAPPA_PREFIX$KAPPA_REGEX"`
		NTIME_TMP=`echo $LOCAL_FILE | grep -o "$JOBS_STATUS_PREFIX.*" | grep -o "$NTIME_PREFIX$NTIME_REGEX"`
		NSPACE_TMP=`echo $LOCAL_FILE | grep -o "$JOBS_STATUS_PREFIX.*" | grep -o "$NSPACE_PREFIX$NSPACE_REGEX"`

		#echo "$KAPPA_TMP $NTIME_TMP $NSPACE_TMP" >> "$JOBS_STATUS_FILE_GLOBAL"
		#echo "cat $LOCAL_FILE >> $JOBS_STATUS_FILE_GLOBAL"
		cat $LOCAL_FILE >> "$JOBS_STATUS_FILE_GLOBAL"
		echo "" >> "$JOBS_STATUS_FILE_GLOBAL"
	done

	printf "\n\e[0;34m A global jobs status file has been created: %s\n\e[0m" $JOBS_STATUS_FILE_GLOBAL
}

function ListJobStatus_Main(){
     if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then

	DATE='D_'$(date +"%d_%m_%Y")'_T_'$(date +"%H_%M")

	#-----------Prepare array with directories for which a job status file shall be produced---------------#
	
	if [ $LISTSTATUS = "TRUE" ]; then

		JOBS_STATUS_FILE="jobs_status_"$CHEMPOT_PREFIX$CHEMPOT"_"$KAPPA_PREFIX$KAPPA"_"$NTIME_PREFIX$NTIME"_"$NSPACE_PREFIX$NSPACE".txt"
		echo "NSPACE:$NSPACE"
		echo "JOBS_STATUS_FILE: $JOBS_STATUS_FILE"
		rm -f $JOBS_STATUS_FILE

		printf "\n\e[0;36m==================================================================================================\n\e[0m"
		printf "\e[0;34m Listing current local measurements status...\n\e[0m"

		__static__ListJobsStatus_local

	elif [ $LISTSTATUSALL = "TRUE" ]; then

		printf "\n\e[0;36m==================================================================================================\n\e[0m"
		printf "\e[0;34m Listing current global measurements status...\n\e[0m"

		__static__ListJobsStatus_global

		printf "\n\e[0;36m==================================================================================================\n\e[0m"
		__static__BuildGlobalJobStatusFile
	fi

	printf "\e[0;36m==================================================================================================\n\e[0m"
    else # On LOEWE
	 
	 local JOBS_STATUS_FILE="jobs_status_$PARAMETERS_STRING.txt"
	 rm -f $JOBS_STATUS_FILE
	 
	 printf "\n\e[0;36m=====================================================================================================================\n\e[0m"
	 printf "\e[0;35m%s\t\t%s\t  %s\t%s\t  %s\t%s\n\e[0m"   "Beta"   "Num. Traj. (Acc.) [Last 1000] int0-1"   "Status"   "Max DS" "Last tr. finished" "Last tr. in"
	 printf "%s\t\t%s\t\t%s\t\t%s\n"   "Beta"   "Num. Traj. (Acc.) [Last 1000] int0-1"   "Status"   "Max DS" >> $JOBS_STATUS_FILE

	 for BETA in b[[:digit:]]*; do

	     BETA=$(echo $BETA | grep -o "[[:digit:]].[[:digit:]]\{4\}")
	     if [[ ! $BETA =~ [[:digit:]].[[:digit:]]{4} ]]; then continue; fi
	     
	     local JOBID_ARRAY=( $(squeue | awk 'NR>1{print $1}') )
	     local STATUS=( )
	     for JOBID in ${JOBID_ARRAY[@]}; do
		 
		 local JOBNAME=$(scontrol show job $JOBID | grep "Name=" | sed "s/^.*Name=\(.*$\)/\1/")
		 local JOBNAME_CHEMPOT=$(echo $JOBNAME | awk -v pref=$CHEMPOT_PREFIX -v pref_len=${#CHEMPOT_PREFIX} '{print substr($0, index($0, pref)+pref_len)}' \
                                                       | awk '{if(index($0, "_")) {print substr($0, 1, index($0, "_")-1)} else {print $0}}')
 		 local JOBNAME_NTIME=$(echo $JOBNAME | awk -v pref=$NTIME_PREFIX -v pref_len=${#NTIME_PREFIX} '{print substr($0, index($0, pref)+pref_len)}' \
                                                     | awk '{if(index($0, "_")) {print substr($0, 1, index($0, "_")-1)} else {print $0}}')
		 local JOBNAME_NSPACE=$(echo $JOBNAME | awk -v pref=$NSPACE_PREFIX -v pref_len=${#NSPACE_PREFIX} '{print substr($0, index($0, pref)+pref_len)}' \
                                                      | awk '{if(index($0, "_")) {print substr($0, 1, index($0, "_")-1)} else {print $0}}')
		 local JOBNAME_KAPPA=$(echo $JOBNAME | awk -v pref=$KAPPA_PREFIX -v pref_len=${#KAPPA_PREFIX} '{print substr($0, index($0, pref)+pref_len)}' \
                                                     | awk '{if(index($0, "_")) {print substr($0, 1, index($0, "_")-1)} else {print $0}}')
		 local JOBNAME_BETAS=$(echo $JOBNAME | awk -v pref=$BETA_PREFIX -v pref_len=${#BETA_PREFIX} '{print substr($0, index($0, pref))}')
		 if [[ ! $JOBNAME_BETAS =~ b[[:digit:]]{1}[.]{1}[[:digit:]]{4}$ ]]; then
                     continue
		 fi
		 JOBNAME_BETAS=( `echo $JOBNAME_BETAS | sed 's/_/ /g' | sed "s/$BETA_PREFIX//g"` )
		 
		 if ElementInArray "$BETA" "${JOBNAME_BETAS[@]}" && [ $JOBNAME_KAPPA = $KAPPA ] && [ $JOBNAME_NTIME = $NTIME ] \
                                                                 && [ $JOBNAME_NSPACE = $NSPACE ] && [ $JOBNAME_CHEMPOT = $CHEMPOT ]; then
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
		 if [[ $STATUS == "RUNNING" ]] || [[ $STATUS == "PENDING" ]]; then
		     local START_TIME_SEC=$(TimeToSeconds `grep "saving current prng state to file" $STDOUTPUT_GLOBALPATH | tail -n2 | awk '{print substr($1,2,8)}' | head -n1`)
		     local END_TIME_SEC=$(TimeToSeconds `grep "saving current prng state to file" $STDOUTPUT_GLOBALPATH | tail -n2 | awk '{print substr($1,2,8)}' | tail -n1`)
		     local DURATION_LAST_TR=$(( $END_TIME_SEC - $START_TIME_SEC ))
		     if [[ ! $DURATION_LAST_TR =~ [[:digit:]]+ ]]; then
			 DURATION_LAST_TR="---"
		     fi
		 else
		     DURATION_LAST_TR="---"
		 fi
	     else
		 local DURATION_LAST_TR="nan"
	     fi

	     if [ -f $OUTPUTFILE_GLOBALPATH ]; then
		 
		 local TO_BE_CLEANED=$(awk 'BEGIN{traj_num = -1; file_to_be_cleaned=0}{if($1>traj_num){traj_num = $1} else {file_to_be_cleaned=1; exit;}}END{print file_to_be_cleaned}' $OUTPUTFILE_GLOBALPATH)
		 if [ $TO_BE_CLEANED -eq 0 ]; then
		     local TRAJECTORIES_DONE=$(wc -l $OUTPUTFILE_GLOBALPATH | awk '{print $1}')
		 else
		     local TRAJECTORIES_DONE=$(( $(awk 'END{print $1}' $OUTPUTFILE_GLOBALPATH) +1 ))
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
		 local TRAJECTORIES_DONE='nan'
		 local ACCEPTANCE=nan
		 local ACCEPTANCE_LAST=nan
		 local MAX_DELTAS=nan
		 local TIME_FROM_LAST_MODIFICATION=nan
		 
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
	     
	     printf "\e[0;36m%s\t\t\e[0;$((36-$TO_BE_CLEANED*5))m%8s\e[0;36m (\e[0;$(GoodAcc $ACCEPTANCE)m%s %%\e[0;36m) [%s %%] %s-%s\t \e[0;$(ColorStatus $STATUS)m%9s\e[0;36m\t%s\t   \e[0;$(ColorTime $TIME_FROM_LAST_MODIFICATION)m%s\e[0;36m\t    %s\n\e[0m" \
		 "$BETA" \
		 "$TRAJECTORIES_DONE" \
		 "$ACCEPTANCE" \
		 "$ACCEPTANCE_LAST" \
                 "$INT0" "$INT1" \
                 "$STATUS"   "$MAX_DELTAS"\
	         "$(echo $TIME_FROM_LAST_MODIFICATION | awk '{if($1 ~ /^[[:digit:]]+$/){printf "%6d", $1}else{print $1}}') sec. ago" \
	         "$DURATION_LAST_TR sec."

	     if [ $TO_BE_CLEANED -eq 0 ]; then
		 printf "%s\t\t%s (%s %%) [%s %%] %s-%s\t\t\t%9s\t%s\n"   "$BETA"   "$TRAJECTORIES_DONE"   "$ACCEPTANCE"   "$ACCEPTANCE_LAST"   "$INT0" "$INT1"   "$STATUS"   "$MAX_DELTAS" >> $JOBS_STATUS_FILE
	     else
		 printf "%s\t\t%s (%s %%) [%s %%]%s-%s\t\t\t%9s\t%s  ---> File to be cleaned!\n"   "$BETA"   "$TRAJECTORIES_DONE"   "$ACCEPTANCE"   "$ACCEPTANCE_LAST"   "$INT0" "$INT1"   "$STATUS"   "$MAX_DELTAS" >> $JOBS_STATUS_FILE
	     fi
	     
	     
	 done
	 printf "\e[0;36m=====================================================================================================================\n\e[0m"
	 
     fi
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
	echo $(($1 > 300 ? 31 : 32 ))
    fi
}