function __static__ListJobsStatus_local(){

	printf "\n\e[0;36m==================================================================================================\n\e[0m"

	printf "\n\e[0;34m%s  %s  %s\n" $KAPPA_PREFIX$KAPPA $NTIME_PREFIX$NTIME $NSPACE_PREFIX$NSPACE 
	printf "\n      %s  %s  %s\n" $KAPPA_PREFIX$KAPPA $NTIME_PREFIX$NTIME $NSPACE_PREFIX$NSPACE >> $JOBS_STATUS_FILE
	printf "\n  Beta Total /  Done  Acc int0/1    Status\n\e[0m"
	printf "  	Beta Total /  Done  Acc int0/1    Status\n" >> $JOBS_STATUS_FILE

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

				#printf "\e[0;34m%.4f %5d / %5d %.2f    %s/%s  %s\n\e[0m" "$BETA" "$TOTAL_NR_TRAJECTORIES" "$TRAJECTORIES_DONE" $ACCEPTANCE $INT0 $INT1 "$STATUS"
				printf "\e[0;34m%.4f %5d / %5d $ACCEPTANCE    $INT0/$INT1  %s\n\e[0m" $BETA $TOTAL_NR_TRAJECTORIES $TRAJECTORIES_DONE $STATUS
				#printf "      %.4f %5d / %5d %.2f    %s/%s  %s\n\e[0m" "$BETA" "$TOTAL_NR_TRAJECTORIES" "$TRAJECTORIES_DONE" $INT0 $INT1 "$STATUS" >> $JOBS_STATUS_FILE
				printf "      %.4f %5d / %5d $ACCEPTANCE    $INT0/$INT1  %s\n\e[0m" $BETA $TOTAL_NR_TRAJECTORIES $TRAJECTORIES_DONE $STATUS >> $JOBS_STATUS_FILE
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
	
	if [ $LISTSTATUS = "TRUE" ] && [ $LISTSTATUSALL = "FALSE" ]; then

		#JOBS_STATUS_FILE="jobs_status_"$CHEMPOT_PREFIX$CHEMPOT"_"$KAPPA_PREFIX$KAPPA"_"$NTIME_PREFIX$NTIME"_"$NSPACE_PREFIX$NSPACE"_"$DATE".txt"
		JOBS_STATUS_FILE="jobs_status_"$CHEMPOT_PREFIX$CHEMPOT"_"$KAPPA_PREFIX$KAPPA"_"$NTIME_PREFIX$NTIME"_"$NSPACE_PREFIX$NSPACE".txt"
		echo "NSPACE:$NSPACE"
		echo "JOBS_STATUS_FILE: $JOBS_STATUS_FILE"
		rm -f $JOBS_STATUS_FILE

		printf "\n\e[0;36m==================================================================================================\n\e[0m"
		printf "\e[0;34m Listing current local measurements status...\n\e[0m"

		__static__ListJobsStatus_local

	elif [ $LISTSTATUS = "TRUE" ] && [ $LISTSTATUSALL = "TRUE" ]; then

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
	 
	 printf "\n\e[0;36m==================================================================================================\n\e[0m"
	 printf "\e[0;35m%s\t\t%s\t\t%s\t\t%s\n\e[0m"   "Beta"   "Num. Traj. (Acc.) [Last 1000] int0-1"   "Status"   "Max DS"
	 printf "%s\t\t%s\t\t%s\t\t%s\n"   "Beta"   "Num. Traj. (Acc.) [Last 1000] int0-1"   "Status"   "Max DS" >> $JOBS_STATUS_FILE
	 for BETA in b*; do

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
		 local JOBNAME_BETA=$(echo $JOBNAME | awk -v pref=$BETA_PREFIX -v pref_len=${#BETA_PREFIX} '{print substr($0, index($0, pref)+pref_len)}' \
                                                    | awk '{if(index($0, "_")) {print substr($0, 1, index($0, "_")-1)} else {print $0}}')
		 
		 if [ $JOBNAME_BETA = $BETA ] && [ $JOBNAME_KAPPA = $KAPPA ] && [ $JOBNAME_NTIME = $NTIME ] \
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
		 printf "\n \e[1;37;41mWARNING:\e[0;31m \e[4mThere are more than one job with $PARAMETERS_STRING as parameters! Serious problem! Aborting...\n\n\e[0m\n"
		 exit -1
	     fi

	     #----Constructing WORK_BETADIRECTORY, HOME_BETADIRECTORY, JOBSCRIPT_NAME, JOBSCRIPT_GLOBALPATH and INPUTFILE_GLOBALPATH---#
	     local OUTPUTFILE_GLOBALPATH="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA/$OUTPUTFILE_NAME"
	     #Here we assume the prefix of the job is the default on --> TODO: avoid this assumption
	     local JOBSCRIPT_GLOBALPATH="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA/${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA_PREFIX$BETA" 
	     #-------------------------------------------------------------------------------------------------------------------------#

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
		 
	     else
		 
		 local TO_BE_CLEANED=0
		 local TRAJECTORIES_DONE='nan'
		 local ACCEPTANCE=nan
		 local ACCEPTANCE_LAST=nan
		 local MAX_DELTAS=nan
		 
	     fi

	     if [ -f $JOBSCRIPT_GLOBALPATH ]; then
		 local INT0=$( grep -o "\-\-integrationsteps0=[[:digit:]]\+"  $JOBSCRIPT_GLOBALPATH | sed 's/\-\-integrationsteps0=\([[:digit:]]\+\)/\1/' )
		 local INT1=$( grep -o "\-\-integrationsteps1=[[:digit:]]\+"  $JOBSCRIPT_GLOBALPATH | sed 's/\-\-integrationsteps1=\([[:digit:]]\+\)/\1/' )
	     else
		 printf "\n \e[0;31m File $JOBSCRIPT_GLOBALPATH not found. Integration stpes will not be printed!\n\n\e[0m\n"
		 local INT0=""
		 local INT1=""		 
	     fi


	     if [ $TO_BE_CLEANED -eq 0 ]; then
		 printf "\e[0;36m%s\t\t%8s (%s %%) [%s %%] %s-%s\t\t%9s\t%s\n\e[0m"   "$BETA"   "$TRAJECTORIES_DONE"   "$ACCEPTANCE"   "$ACCEPTANCE_LAST"   "$INT0" "$INT1"   "$STATUS"   "$MAX_DELTAS"
		 printf "%s\t\t%s (%s %%) [%s %%] %s-%s\t\t\t%9s\t%s\n"   "$BETA"   "$TRAJECTORIES_DONE"   "$ACCEPTANCE"   "$ACCEPTANCE_LAST"   "$INT0" "$INT1"   "$STATUS"   "$MAX_DELTAS" >> $JOBS_STATUS_FILE
	     else
		 printf "\e[0m%s\t\t\e[0;31m%8s (%s %%) [%s %%] %s-%s\e[0m\t\t%9s\t%s\n\e[0m"   "$BETA"   "$TRAJECTORIES_DONE"   "$ACCEPTANCE"   "$ACCEPTANCE_LAST"   "$INT0" "$INT1"   "$STATUS"   "$MAX_DELTAS"
		 printf "%s\t\t%s (%s %%) [%s %%]%s-%s\t\t\t%9s\t%s  ---> File to be cleaned!\n"   "$BETA"   "$TRAJECTORIES_DONE"   "$ACCEPTANCE"   "$ACCEPTANCE_LAST"   "$INT0" "$INT1"   "$STATUS"   "$MAX_DELTAS" >> $JOBS_STATUS_FILE
	     fi
	     
	     
	 done
	 printf "\e[0;36m==================================================================================================\n\e[0m"
	 
     fi
}
