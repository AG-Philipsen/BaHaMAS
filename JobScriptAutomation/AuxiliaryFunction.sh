# Collection of function needed in the job handler script.

function CheckParallelizationTmlqcdForJuqueen(){
    printf "\n\e[0;36m===================================================================================\n\e[0m"
    printf "\e[0;34m Checking parameters for parallelization using:\n\e[0m"
    printf "   BGSIZE  = $BGSIZE\n"
    printf "   NRXPROC = $NRXPROCS\n"
    printf "   NRZPROC = $NRZPROCS\n"
    printf "   NRYPROC = $NRYPROCS\n"
    
    if [ $(echo $BGSIZE | awk '{print log($1/32)/log(2)-int(log($1/32)/log(2))}') != "0" ]; then
	
	printf "\n\e[0;31m BGSIZE=$BGSIZE cannot be used with tmLQCD on Juqueeen! Aborting...\n\n\e[0m"
	exit -1
	
    elif [ $(echo $BGSIZE $NRXPROCS $NRYPROCS $NRZPROCS | awk '{print $1/($2*$3*$4)-int($1/($2*$3*$4))}') != "0" ]; then
	
	printf "\n\e[0;31m The number of processes in time direction has to be integer! Aborting...\n\n\e[0m"
	exit -1
	
    elif [ $(echo $NSPACE $NRXPROCS | awk '{print ($1/$2)-int($1/$2)}') != "0" ]; then
	
	printf "\n\e[0;31m The local lattice size in x-direction has to be integer! Aborting...\n\n\e[0m"
	exit -1
	
    elif [ $(echo $NSPACE $NRYPROCS | awk '{print ($1/$2)-int($1/$2)}') != "0" ]; then
	
	printf "\n\e[0;31m The local lattice size in y-direction has to be integer! Aborting...\n\n\e[0m"
	exit -1
	
    elif [ $(echo $NSPACE $NRZPROCS | awk '{print ($1/$2)-int($1/$2)}') != "0" ]; then
	
	printf "\n\e[0;31m The local lattice size in z-direction has to be integer! Aborting...\n\n\e[0m"
	exit -1
	
    elif [ $((($NSPACE/$NRZPROCS)%2)) != "0" ]; then
	
	printf "\n\e[0;31m The local lattice size in z-direction has to be even! Aborting...\n\n\e[0m"
	exit -1
	
    elif [ $((($NSPACE*$NSPACE*$NSPACE/($NRXPROCS*$NRYPROCS*$NRZPROCS))%2)) != "0" ]; then
	
	printf "\n\e[0;31m The product of the lattice sizes in spatial direction has to be even! Aborting...\n\n\e[0m"
	exit -1
	
    elif [ $(echo $BGSIZE $NRXPROCS $NRYPROCS $NRZPROCS $NTIME | awk '{print $5/($1/($2*$3*$4))-int($5/($1/($2*$3*$4)))}') != "0" ]; then
	
	printf "\n\e[0;31m The local lattice size in t-direction has to be integer! Aborting...\n\n\e[0m"
	exit -1
	
    elif [ $(($NSPACE/$NRXPROCS)) -le 1 ] || [ $(($NSPACE/$NRYPROCS)) -le 1 ] || 
	 [ $(($NSPACE/$NRZPROCS)) -le 1 ] || [ $(($NTIME/($BGSIZE/($NRXPROCS*$NRYPROCS*$NRZPROCS)))) -lt 1 ]; then
	
	printf "\n\e[0;31m No local lattice size is allowed to be 1! Aborting...\n\n\e[0m"
	exit -1
	
    elif [ $(($NSPACE/$NRXPROCS)) -ge $NSPACE ] || [ $(($NSPACE/$NRYPROCS)) -ge $NSPACE ] || 
	 [ $(($NSPACE/$NRZPROCS)) -ge $NSPACE ] || [ $(($NTIME/($BGSIZE/($NRXPROCS*$NRYPROCS*$NRZPROCS)))) -ge $NTIME ]; then
	
	printf "\n\e[0;31m No local lattice size is allowed to be equal to or bigger than the total lattice size! Aborting...\n\n\e[0m"
	exit -1
	
    fi
    
    printf "\e[0;32m The parallelization is fine!\n"
    printf "\e[0;36m===================================================================================\n\e[0m"
}


function ReadBetaValuesFromFile(){
    if [ ! -e $BETASFILE ]; then
	printf "\n\e[0;31m  File \"$BETASFILE\" not found in $(pwd). Aborting...\n\n\e[0m"
	exit -1
    fi
    #Write beta values from BETASFILE into BETAVALUES array
    BETAVALUES=( $(grep -o "^[[:blank:]]*[[:digit:]]\.[[:digit:]]\{4\}" $BETASFILE) )
    if [ ${#BETAVALUES[@]} -gt "0" ]; then	
	printf "\n\e[0;36m===================================================================================\n\e[0m"
	printf "\e[0;34m Read beta values:\n\e[0m"
	for i in ${BETAVALUES[@]}; do
	    echo "  - $i"
	done
	printf "\e[0;36m===================================================================================\n\e[0m"
    else	
	printf "\n\e[0;31m  No beta values in betas file. Aborting...\n\n\e[0m"
	exit -1
    fi
}


function ProduceInputFileAndJobScriptForEachBeta(){
    for BETA in ${BETAVALUES[@]}; do
	
	#-------------------------------------------------------------------------------------------------------------------------#
	local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	local JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA_PREFIX$BETA"
	local JOBSCRIPT_GLOBALPATH="${HOME_BETADIRECTORY}/$JOBSCRIPT_NAME"
	local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$INPUTFILE_NAME"
	#-------------------------------------------------------------------------------------------------------------------------#

	if [ ! -d $HOME_BETADIRECTORY ]; then
	    printf "\e[0;34m Creating directory for beta = $BETA...\e[0m"
	    mkdir $HOME_BETADIRECTORY || exit -2
	    printf "\e[0;34m done!\n\e[0m"
	    SUBMIT_BETA_ARRAY+=( $BETA )
	else
	    #$HOME_BETADIRECTORY already exists. Check if there are files in $HOME_BETADIRECTORY. 
	    if [ $(ls $HOME_BETADIRECTORY | wc -l) -gt 0 ]; then
		printf "\n\e[0;31m There are already files in $HOME_BETADIRECTORY. The value beta = $BETA will be skipped!\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
		continue
	    fi
	fi
       
        # Build jobscript and input file and put them together with hmc_tm into the $HOME_BETADIRECTORY	
	printf "\e[0;34m Producing files inside $HOME_BETADIRECTORY/... \n\e[0m"
	. $PRODUCEJOBSCRIPTSH	
	. $PRODUCEINPUTFILESH	
	if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
	    cp $HMC_TM_GLOBALPATH $HOME_BETADIRECTORY || exit -2
	fi
	
	if [ -f "$INPUTFILE_GLOBALPATH" ] && [ -f "$JOBSCRIPT_GLOBALPATH" ]; then
	    printf "\e[0;34m ...files built successfully!\n\n\e[0m"
	else
	    printf "\n\e[0;31m One or more of the following files has not been successfully created:\n\e[0m"
	    printf "\n\e[0;31m  - $INPUTFILE_GLOBALPATH\e[0m"
	    printf "\n\e[0;31m  - $JOBSCRIPT_GLOBALPATH\n\e[0m"
	    printf "\n\e[0;31m Aborting...\n\n\e[0m"
	    exit -1
	fi
    done
}


function ProcessBetaValuesForSubmitOnly() {
    for BETA in ${BETAVALUES[@]}; do
	
	#-------------------------------------------------------------------------------------------------------------------------#
	local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	local JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA_PREFIX$BETA"
	local JOBSCRIPT_GLOBALPATH="${HOME_BETADIRECTORY}/$JOBSCRIPT_NAME"
	local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$INPUTFILE_NAME"
	#-------------------------------------------------------------------------------------------------------------------------#

	if [ ! -d $HOME_BETADIRECTORY ]; then
	    printf "\e[0;31m Directory $HOME_BETADIRECTORY not existing. The value beta = $BETA will be skipped!\n\e[0m"
	    PROBLEM_BETA_ARRAY+=( $BETA )
	    continue
	else
	    #$HOME_BETADIRECTORY already exists. Check if there are files in $HOME_BETADIRECTORY. 
	    if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
		if [ -f "$INPUTFILE_GLOBALPATH" ] && [ -f "$JOBSCRIPT_GLOBALPATH" ] && [ -f "$HOME_BETADIRECTORY/$HMC_TM_FILENAME" ]; then
		    #Check if there are more than 3 files, this means that there are more files than
		    #jobscript, input file and hmc_tm which should not be the case
		    if [ $(ls $HOME_BETADIRECTORY | wc -l) -gt 3 ]; then
			printf "\n\e[0;31m There are already files in $HOME_BETADIRECTORY. The value beta = $BETA will be skipped!\n\n\e[0m"
			PROBLEM_BETA_ARRAY+=( $BETA )
			continue
		    fi
    	            #The following will not happen if the previous if-case applied
		    SUBMIT_BETA_ARRAY+=( $BETA )
		else
		    printf "\n\e[0;31m One or more of the following files are missing:\n\e[0m"
		    printf "\n\e[0;31m  - $INPUTFILE_GLOBALPATH\e[0m"
		    printf "\n\e[0;31m  - $JOBSCRIPT_GLOBALPATH\e[0m"
		    printf "\n\e[0;31m  - $HOME_BETADIRECTORY/$HMC_TM_FILENAME\n\e[0m"
		    printf "\n\e[0;31m The value beta = $BETA will be skipped!\n\n\e[0m"
		    PROBLEM_BETA_ARRAY+=( $BETA )
		    continue
		fi
	    else # On LOEWE
		if [ -f "$INPUTFILE_GLOBALPATH" ] && [ -f "$JOBSCRIPT_GLOBALPATH" ]; then
		    #Check if there are more than 3 files, this means that there are more files than
		    #jobscript, input file and hmc_tm which should not be the case
		    if [ $(ls $HOME_BETADIRECTORY | wc -l) -gt 2 ]; then
			printf "\n\e[0;31m There are already files in $HOME_BETADIRECTORY. The value beta = $BETA will be skipped!\n\n\e[0m"
			PROBLEM_BETA_ARRAY+=( $BETA )
			continue
		    fi
    	            #The following will not happen if the previous if-case applied
		    SUBMIT_BETA_ARRAY+=( $BETA )
		else
		    printf "\n\e[0;31m One or more of the following files are missing:\n\e[0m"
		    printf "\n\e[0;31m  - $INPUTFILE_GLOBALPATH\e[0m"
		    printf "\n\e[0;31m  - $JOBSCRIPT_GLOBALPATH\n\e[0m"
		    printf "\n\e[0;31m The value beta = $BETA will be skipped!\n\n\e[0m"
		    PROBLEM_BETA_ARRAY+=( $BETA )
		    continue
		fi
	    fi
	fi
    done
}

function ConstructJobName(){

	local JOBNAME=$CHEMPOT_PREFIX$CHEMPOT'_'$KAPPA_PREFIX$KAPPA'_'$NTIME_PREFIX$NTIME'_'$NSPACE_PREFIX$NSPACE'_'$BETA_PREFIX$BETA 

	echo $JOBNAME
}

function CheckIfJobIsInQueue(){

	#echo "In function: CheckIfJobIsInQueue"

	local JOBNAME=$( ConstructJobName )	

	local JOBID_ARRAY=( $(llq -u hkf806 | grep -o "juqueen[[:alnum:]]\{3\}\.[[:digit:]]\+\.[[:digit:]]") )

	for JOBID in ${JOBID_ARRAY[@]}; do

		GREPPED_JOBNAME=$(llq -l $JOBID | grep "Job Name:" | sed "s/^.*Job Name: \(muiPiT.*$\)/\1/")

		#echo 'GREPPED_JOBNAME:'$GREPPED_JOBNAME', JOBNAME: '$JOBNAME

		if [ $GREPPED_JOBNAME = $JOBNAME ]; then
			
			echo "Job with name $GREPPED_JOBNAME and id $JOBID seems to be already running."
			echo "Job cannot be continued..."

			return 0
		fi

	done

	return 1
}

function ProcessBetaValuesForContinue() {
    if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then

	for BETA in ${BETAVALUES[@]}; do
	    
     	    #-------------------------------------------------------------------------------------------------------------------------#
	    WORK_BETADIRECTORY="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	    HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	    JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA_PREFIX$BETA"
	    INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$INPUTFILE_NAME"
	    OUTPUTFILE_GLOBALPATH="${WORK_BETADIRECTORY}/$OUTPUTFILE_NAME"
	    #-------------------------------------------------------------------------------------------------------------------------#

	    if [ ! -f $INPUTFILE_GLOBALPATH ]; then
		
		printf "\n\e[0;31m $INPUTFILE_GLOBALPATH does not exist.\n\e[0m"
		printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
		continue
		
	    elif [ ! -f $OUTPUTFILE_GLOBALPATH ]; then
		
		printf "\n\e[0;31m $OUTPUTFILE_GLOBALPATH does not exist.\n\e[0m"
		printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
		continue
	    fi

	    CheckIfJobIsInQueue
	    if [ $? == 0 ]; then

		    PROBLEM_BETA_ARRAY+=( $BETA )
		    continue
	    fi
	    
	    grep -q "^StartCondition = continue" $INPUTFILE_GLOBALPATH
	    if [ $(echo $?) = 0 ]; then 
		
		StartCondition="continue" 
	    else 
		
		StartCondition="undefined" 
	    fi
	    
	    grep -q "^InitialStoreCounter = readin" $INPUTFILE_GLOBALPATH
	    
	    if [ $(echo $?) = 0 ]; then 
		
		InitialStoreCounter="readin" 
	    else 
		
		InitialStoreCounter="undefined" 
	    fi
	    
	    if [  $StartCondition != "continue" ]; then
		
		printf "\n\e[0;31m StartCondition for beta = $BETA is not set to continue.\n\e[0m"
		printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
		continue
		
	    elif [ $InitialStoreCounter != "readin" ]; then
		
		printf "\n\e[0;31m InitialStoreCounter for beta = $BETA is not set to readin.\n\e[0m"
		printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
		continue
	    fi
	    
	    if [ $CONTINUE_NUMBER -eq 0 ]; then
		
		TOTAL_NR_TRAJECTORIES=$(grep "^#[[:blank:]]\+Total[[:blank:]]\+number[[:blank:]]\+of[[:blank:]]\+trajectories" $INPUTFILE_GLOBALPATH | grep -o "=[[:blank:]]*[[:digit:]]\+[[:blank:]]*#*" | grep -o "[[:digit:]]\+")	
		
	    else
		
		TOTAL_NR_TRAJECTORIES=$CONTINUE_NUMBER
 		sed -i "s/\(^#[[:blank:]]\+Total[[:blank:]]\+number[[:blank:]]\+of[[:blank:]]\+trajectories[[:blank:]]\+=[[:blank:]]*\)[[:digit:]]\+[[:blank:]]*#*.*/\1$TOTAL_NR_TRAJECTORIES/" $INPUTFILE_GLOBALPATH
		
	    fi
	    
	    TRAJECTORIES_DONE=$(tail -n1 $OUTPUTFILE_GLOBALPATH | grep -o "^[[:digit:]]\+")
	    TRAJECTORIES_DONE=$(expr $TRAJECTORIES_DONE + 1)
	    
	    MEASUREMENTS_REMAINING=$(expr $TOTAL_NR_TRAJECTORIES - $TRAJECTORIES_DONE)
	    
	    if [ $MEASUREMENTS_REMAINING -gt 0 ]; then
		
		sed -i "s/\(^Measurements.*$\)/#\1\nMeasurements = $MEASUREMENTS_REMAINING/" $INPUTFILE_GLOBALPATH
		SUBMIT_BETA_ARRAY+=( $BETA )
	    else
		
		printf "\n\e[0;31m For beta = $BETA the difference between the total nr of trajectories and the trajectories already done\n\e[0m"
		printf "\e[0;31m is smaller or equal to zero.\n\e[0m"
		printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
		continue	
	    fi
	done

    else # On LOEWE
	
	printf "\n\e[0;31m CONTINUE option not yet implemented on $CLUSTER_NAME!\n\n\e[0m"

    fi
}

function ShowQueuedJobsLocal(){
#TODO: Generalize user name

	if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then

		local JOBID_ARRAY=( $(llq -u hkf806 | grep -o "juqueen[[:alnum:]]\{3\}\.[[:digit:]]\+\.[[:digit:]]") )

		printf "\n================================================================\n\n"

		for JOBID in ${JOBID_ARRAY[@]}; do

			local JOBNAME=$(llq -l $JOBID | grep "Job Name:" | sed "s/^.*Job Name: \(muiPiT.*$\)/\1/")
			local STATUS=$(llq -l $JOBID | grep "^[[:blank:]]*Status:" | sed "s/^.*Status: \([[:alpha:]].*$\)/\1/")

			local JOBNAME_KAPPA=$(echo $JOBNAME | sed "s/^.*_k\([[:digit:]]\{4\}\)_.*$/\1/")

			local JOBNAME_NTIME=$(echo $JOBNAME | sed "s/^.*$NTIME_PREFIX\($NTIME_REGEX\)_.*$/\1/")

			local JOBNAME_NSPACE=$(echo $JOBNAME | sed "s/^.*_$NSPACE_PREFIX\($NSPACE_REGEX\)_.*$/\1/")

			if [ $JOBNAME_KAPPA = $KAPPA ] && [ $JOBNAME_NSPACE = $NSPACE ] && [ $JOBNAME_NTIME = $NTIME ]; then

				JOBID_ARRAY_LOCAL+=($JOBID)	
			fi

		done

		if [ ${#JOBID_ARRAY_LOCAL[@]} -eq 0 ]; then

			echo "No jobs queued for the current directory..."
			printf "================================================================\n\n"
			exit 0
		else	
			for JOBID_LOCAL in ${JOBID_ARRAY_LOCAL[@]}; do

				local JOBNAME_LOCAL=$(llq -l $JOBID_LOCAL | grep "Job Name:" | sed "s/^.*Job Name: \(muiPiT.*$\)/\1/")
				local STATUS_LOCAL=$(llq -l $JOBID_LOCAL | grep "^[[:blank:]]*Status:" | sed "s/^.*Status: \([[:alpha:]].*$\)/\1/")

				printf "$JOBNAME_LOCAL \t $JOBID_LOCAL \t $STATUS_LOCAL \n"
			done
		fi
			
		printf "================================================================\n\n"
	else
		echo "Fuctionality only implemented for the Juqueen cluster at the moment...terminating"
		exit -1
	fi
}

function ShowQueuedJobsGlobal(){
#TODO: Generalize user name

	if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then

		local JOBID_ARRAY=( $(llq -u hkf806 | grep -o "juqueen[[:alnum:]]\{3\}\.[[:digit:]]\+\.[[:digit:]]") )

		printf "\n================================================================\n\n"
		if [ ${#JOBID_ARRAY[@]} -eq 0 ]; then

			echo "No jobs queued for the current directory..."
			printf "================================================================\n\n"
			exit 0
		else
			for i in ${JOBID_ARRAY[@]}; do

				local JOBID=$i
				local JOBNAME=$(llq -l $JOBID | grep "Job Name:" | sed "s/^.*Job Name: \(muiPiT.*$\)/\1/")
				local STATUS=$(llq -l $JOBID | grep "^[[:blank:]]*Status:" | sed "s/^.*Status: \([[:alpha:]].*$\)/\1/")
				
					printf "$JOBNAME \t $JOBID \t $STATUS \n\n"
			done
			printf "================================================================\n\n"
		fi
	else
		echo "Fuctionality only implemented for the Juqueen cluster at the moment...terminating"
		exit -1
	fi
}

function ListJobsStatus_JobIdLoop(){

	local JOBNAME=""

	for k in ${JOBID_ARRAY[@]}; do

	
		JOBID=$k
		#if [ $i = "b5.7500" ]; then 
		#	echo $JOBID 
		#fi
		JOBNAME=$(llq -l $JOBID | grep "Job Name:" | sed "s/^.*Job Name: \(muiPiT.*$\)/\1/")
		#if [ $i = "b.57500" ]; then echo $JOBNAME 
		#fi
		JOBNAME_NTIME=$(echo $JOBNAME | sed "s/^.*_nt\([[:digit:]]\)_.*$/\1/")
		JOBNAME_NSPACE=$(echo $JOBNAME | sed "s/^.*_n[[:alpha:]]\([[:digit:]]\{2\}\)_.*$/\1/")
		JOBNAME_KAPPA=$(echo $JOBNAME | sed "s/^.*_k\([[:digit:]]\{4\}\)_.*$/\1/")
		JOBNAME_BETA=$(echo $JOBNAME | sed "s/^.*\([[:digit:]]\.[[:digit:]]\{4\}$\)/\1/")


		if [ $JOBNAME_BETA = $BETA ] && [ $JOBNAME_KAPPA = $KAPPA ] && [ $JOBNAME_NTIME = $NTIME ] && [ $JOBNAME_NSPACE = $NSPACE ]; then

			STATUS=$(llq -l $JOBID | grep "^[[:blank:]]*Status:" | sed "s/^.*Status: \([[:alpha:]].*$\)/\1/")
			#if [ $i = "b5.7500" ]; then echo "break" 
			#fi
			break;
		fi

	done
}

function ListJobsStatus_local(){

	printf "\n\e[0;36m==================================================================================================\n\e[0m"

	printf "\n\e[0;34m%s  %s  %s\n" $KAPPA_PREFIX$KAPPA $NTIME_PREFIX$NTIME $NSPACE_PREFIX$NSPACE 
	printf "\n      %s  %s  %s\n" $KAPPA_PREFIX$KAPPA $NTIME_PREFIX$NTIME $NSPACE_PREFIX$NSPACE >> $JOBS_STATUS_FILE
	printf "\n  Beta     Traj. total / done     Status\n\e[0m"
	printf "  	Beta     Traj. total / done     Status\n" >> $JOBS_STATUS_FILE

	for i in b*; do

		STATUS="notQueued"	

		#Assigning beta value to BETA variable for readability
		BETA=$(echo $i | grep -o "[[:digit:]].[[:digit:]]\{4\}")

		if [[ ! $BETA =~ [[:digit:]].[[:digit:]]{4} ]]; then
				
			continue;
		fi

		#JOBID_ARRAY=( $(llq -u hkf806 | grep -o "juqueen[[:alnum:]]\{3\}\.[[:digit:]]\+\.[[:digit:]]") )
		JOBID_ARRAY=( $(llq -u hkf806 | awk -v lines=$(llq -u hkf806 | wc -l) 'NR>2 && NR<lines-1{print $1}') )

		ListJobsStatus_JobIdLoop

		#if [ $i = "b5.7500" ]; then echo "after break" 
		#fi

		#----Constructing WORK_BETADIRECTORY, HOME_BETADIRECTORY, JOBSCRIPT_NAME, JOBSCRIPT_GLOBALPATH and INPUTFILE_GLOBALPATH---#
		WORK_BETADIRECTORY="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
		HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
		INPUTFILE_GLOBALPATH="$HOME_BETADIRECTORY/$INPUTFILE_NAME"
		OUTPUTFILE_GLOBALPATH="$WORK_BETADIRECTORY/$OUTPUTFILE_NAME"
		#-------------------------------------------------------------------------------------------------------------------------#

		if [ -d $WORK_BETADIRECTORY ] && [ -f $OUTPUTFILE_GLOBALPATH ]; then

			WORKDIRS_EXIST="true"
		else 

			WORKDIRS_EXIST="false"
		fi

		if [ -d $HOME_BETADIRECTORY ] && [ -f $INPUTFILE_GLOBALPATH ]; then
						
			#if [ $i = "b5.7500" ]; then echo "after break in if" 
			#fi

			TOTAL_NR_TRAJECTORIES=$(grep "Total number of trajectories" $INPUTFILE_GLOBALPATH | grep -o "[[:digit:]]\+")	
			TOTAL_NR_TRAJECTORIES=$(expr $TOTAL_NR_TRAJECTORIES - 0)

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

			#printf "\e[0;34m$BETA \t $TOTAL_NR_TRAJECTORIES \t $TRAJECTORIES_DONE \t $MEASUREMENTS_REMAINING\n\e[0m"
			#26
			#printf "\e[0;34m%.4f  %24d  %17d  %22d %s\n\e[0m" "$BETA" "$TOTAL_NR_TRAJECTORIES" "$TRAJECTORIES_DONE" "$MEASUREMENTS_REMAINING" "$STATUS"
			printf "\e[0;34m%.4f  %14d / %5d    %s\n\e[0m" "$BETA" "$TOTAL_NR_TRAJECTORIES" "$TRAJECTORIES_DONE" "$STATUS"
			printf "      %.4f  %14d / %5d    %s\n" "$BETA" "$TOTAL_NR_TRAJECTORIES" "$TRAJECTORIES_DONE" "$STATUS" >> $JOBS_STATUS_FILE
		fi
		
	done
}

function ListJobsStatus_global(){

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

			JOBS_STATUS_FILE="jobs_status_""$CHEMPOT_PREFIX$CHEMPOT"_"$KAPPA_PREFIX$KAPPA"_"$NTIME_PREFIX$NTIME"_"$NSPACE_PREFIX$NSPACE"".txt"
			#echo $JOBS_STATUS_FILE
			rm -f $JOBS_STATUS_FILE

			ListJobsStatus_local
		done

		cd $ORIGINAL_HOME_DIR_WITH_BETAFOLDERS
}

function BuildRegexPath(){

	PARAMETER_REGEX_ARRAY=([$KAPPA_POSITION]=$KAPPA_PREFIX$KAPPA_REGEX [$NTIME_POSITION]=$NTIME_PREFIX$NTIME_REGEX [$NSPACE_POSITION]=$NSPACE_PREFIX$NSPACE_REGEX)

	for i in ${PARAMETER_REGEX_ARRAY[@]}; do

		REGEX_PATH=$REGEX_PATH"/$i"
	done

	local REGEX_PATH='.*'$REGEX_PATH

	FIND_LOCATION_PATH=$HOME_DIR'/'$SIMULATION_PATH'/'$CHEMPOT_PREFIX$CHEMPOT'/'

	DIRECTORY_ARRAY=( $(find $FIND_LOCATION_PATH -regextype grep -regex $REGEX_PATH) )
}

function BuildGlobalJobStatusFile(){

	DATE='D_'$(date +"%d_%m_%Y")'_T_'$(date +"%H_%M")
	JOBS_STATUS_FILE_GLOBAL=$HOME_DIR'/'$SIMULATION_PATH'/global_'$JOBS_STATUS_PREFIX$DATE'.txt'

	rm -f $JOBS_STATUS_FILE_GLOBAL

	local REGEX_PATH=$JOBS_STATUS_PREFIX'[^~]*$'
	REGEX_PATH='.*'$REGEX_PATH

	for i in ${DIRECTORY_ARRAY[@]}; do

		LOCAL_FILE=$(find $i -regextype grep -regex $REGEX_PATH)

		KAPPA_TMP=`echo $LOCAL_FILE | grep -o "$JOBS_STATUS_PREFIX.*" | grep -o "$KAPPA_PREFIX$KAPPA_REGEX"`
		NTIME_TMP=`echo $LOCAL_FILE | grep -o "$JOBS_STATUS_PREFIX.*" | grep -o "$NTIME_PREFIX$NTIME_REGEX"`
		NSPACE_TMP=`echo $LOCAL_FILE | grep -o "$JOBS_STATUS_PREFIX.*" | grep -o "$NSPACE_PREFIX$NSPACE_REGEX"`

		#echo "$KAPPA_TMP $NTIME_TMP $NSPACE_TMP" >> "$JOBS_STATUS_FILE_GLOBAL"
		cat $LOCAL_FILE >> "$JOBS_STATUS_FILE_GLOBAL"
		echo "" >> "$JOBS_STATUS_FILE_GLOBAL"
	done

	printf "\n\e[0;34m A global jobs status file has been created: %s\n\e[0m" $JOBS_STATUS_FILE_GLOBAL
}

function ListJobStatus_Main(){
     if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then



	#-----------Prepare array with directories for which a job status file shall be produced---------------#
	
	if [ $LISTSTATUS = "TRUE" ] && [ $LISTSTATUSALL = "FALSE" ]; then

		JOBS_STATUS_FILE="jobs_status_""$CHEMPOT_PREFIX$CHEMPOT"_"$KAPPA_PREFIX$KAPPA"_"$NTIME_PREFIX$NTIME"_"$NSPACE_PREFIX$NSPACE"".txt"
		rm -f $JOBS_STATUS_FILE

		printf "\n\e[0;36m==================================================================================================\n\e[0m"
		printf "\e[0;34m Listing current local measurements status...\n\e[0m"

		ListJobsStatus_local

	elif [ $LISTSTATUS = "TRUE" ] && [ $LISTSTATUSALL = "TRUE" ]; then

		printf "\n\e[0;36m==================================================================================================\n\e[0m"
		printf "\e[0;34m Listing current global measurements status...\n\e[0m"

		ListJobsStatus_global

		printf "\n\e[0;36m==================================================================================================\n\e[0m"
		BuildGlobalJobStatusFile
	fi

	printf "\e[0;36m==================================================================================================\n\e[0m"
    else # On LOEWE
	 
	 local JOBS_STATUS_FILE="jobs_status_$PARAMETERS_STRING.txt"
	 rm -f $JOBS_STATUS_FILE
	 
	 printf "\n\e[0;36m==================================================================================================\n\e[0m"
	 printf "\e[0;34m%s\t\t%s\t\t%s\n\e[0m"   "Beta"   "Trajectories done"   "Status"
	 printf "%s\t\t%s\t\t%s\n"   "Beta"   "Trajectories done"   "Status" >> $JOBS_STATUS_FILE
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
		     STATUS+=( $(scontrol show job $JOBID | grep "^[[:blank:]]*JobState=" | sed "s/^.*JobState=\([[:alpha:]]*[[:blank:]]\).*$/\1/"))
		 fi
		 
	     done
	     
	     if [ ${#STATUS[@]} -eq 0 ]; then
		 STATUS="notQueued"
	     elif [ ${#STATUS[@]} -ne 1 ]; then
		 printf " \e[1;37;41mWARNING:\e[0;31m \e[4mThere are more than one job with $PARAMETERS_STRING as parameters! Serious problem! Aborting...\e[0m\n"
		 exit -1
	     fi

	     #----Constructing WORK_BETADIRECTORY, HOME_BETADIRECTORY, JOBSCRIPT_NAME, JOBSCRIPT_GLOBALPATH and INPUTFILE_GLOBALPATH---#
	     local OUTPUTFILE_GLOBALPATH="$WORK_BETADIRECTORY/$OUTPUTFILE_NAME"
	     #-------------------------------------------------------------------------------------------------------------------------#

	     if [ -f $OUTPUTFILE_GLOBALPATH ]; then
		 
		 local TRAJECTORIES_DONE=$(( $(awk 'END{print $1}' $OUTPUTFILE_GLOBALPATH) +1 ))
		 
	     else
		 
		 local TRAJECTORIES_DONE=0
		 
	     fi
	     printf "\e[0;34m%s\t\t%17d\t\t%s\n\e[0m"   "$BETA"   "$TRAJECTORIES_DONE"   "$STATUS"
	     printf "%s\t%d\t\t%s\n\e[0m"   "$BETA"   "$TRAJECTORIES_DONE"   "$STATUS" >> $JOBS_STATUS_FILE
	     
	 done
	 printf "\e[0;36m==================================================================================================\n\e[0m"
	 
     fi
}


function SubmitJobsForValidBetaValues() {
    if [ ${#SUBMIT_BETA_ARRAY[@]} -gt "0" ]; then
	
	printf "\n\e[0;36m===================================================================================\n\e[0m"
	printf "\e[0;34m Jobs will be submitted for the following beta values:\n\e[0m"
	for BETA in ${SUBMIT_BETA_ARRAY[@]}; do
	    echo "  - $BETA"
	done
	
	for BETA in ${SUBMIT_BETA_ARRAY[@]}; do
	    
	    #-------------------------------------------------------------------------------------------------------------------------#
	    local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	    local JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA_PREFIX$BETA"
	    #-------------------------------------------------------------------------------------------------------------------------#
	    
	    cd $HOME_BETADIRECTORY
	    printf "\n\e[0;34m Actual location: \e[0;35m$(pwd) \n\e[0m"
	    printf "\e[0;34m      Submitting:\e[0m"
	    if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
		printf "\e[0;32m \e[4mllsubmit $JOBSCRIPT_NAME\n\e[0m"
		llsubmit $JOBSCRIPT_NAME
	    else
		printf "\e[0;32m \e[4msbatch $JOBSCRIPT_NAME\n\e[0m"
		sbatch $JOBSCRIPT_NAME
	    fi
	    cd ..
	done
	printf "\n\e[0;36m===================================================================================\n\e[0m"
    else
	printf " \e[1;37;41mNo jobs will be submitted.\e[0m\n"
    fi
}


function PrintReportForProblematicBeta() {

    if [ ${#PROBLEM_BETA_ARRAY[@]} -gt "0" ]; then	
	printf "\n\e[0;31m===================================================================================\n\e[0m"
	printf "\e[0;31m For the following beta values something went wrong and hence\n\e[0m"
	printf "\e[0;31m they were left out during file creation and/or job submission:\n"
	for BETA in ${PROBLEM_BETA_ARRAY[@]}; do
	    printf "  - \e[1m$BETA\e[0;31m\n"
	done
	printf "\e[0;31m===================================================================================\n\e[0m"
    fi
}
