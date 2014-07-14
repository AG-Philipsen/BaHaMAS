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
	printf "\e[0;34m No beta values in betas file. Aborting...:\n\e[0m"
	exit -1
    fi
}


function ProduceInputFileAndJobScriptForEachBeta(){
    for BETA in ${BETAVALUES[@]}; do
	
	#-------------------------------------------------------------------------------------------------------------------------#
	HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA_PREFIX$BETA"
	JOBSCRIPT_GLOBALPATH="${HOME_BETADIRECTORY}/$JOBSCRIPT_NAME"
	INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$INPUTFILE_NAME"
	#-------------------------------------------------------------------------------------------------------------------------#

	if [ ! -d $HOME_BETADIRECTORY ]; then
	    printf "\e[0;34m Creating directory for beta = $BETA...\n\e[0m"
	    mkdir $HOME_BETADIRECTORY || exit -2
	    SUBMIT_BETA_ARRAY+=( $BETA )
	else
	    #$HOME_BETADIRECTORY already exists. Check if there are files in $HOME_BETADIRECTORY. 
	    if [ $(ls $HOME_BETADIRECTORY | wc -l) -gt 0 ]; then
		printf "\n\e[0;31m There are already files in $HOME_BETADIRECTORY...\n\e[0m"
		printf "\e[0;31m Leaving out $BETA ...\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
		continue
	    fi
	fi
       
        # Build jobscript and input file and put them together with hmc_tm into the $HOME_BETADIRECTORY	
	printf "\e[0;34m Producing files inside $HOME_BETADIRECTORY/... \n\e[0m"
	. $PRODUCEJOBSCRIPTSH	
	. $PRODUCEINPUTFILESH	
	cp $HMC_TM_GLOBALPATH $HOME_BETADIRECTORY 
	
	if [ -f "$INPUTFILE_GLOBALPATH" ] && [ -f "$JOBSCRIPT_GLOBALPATH" ] && [ -f "$HOME_BETADIRECTORY/$HMC_TM_FILENAME" ]; then
	    printf "\e[0;34m Built files successfully...\n\n\e[0m"
	else
	    printf "\n\e[0;31m One or more of the following files are missing:\n\e[0m"
	    printf "\n\e[0;31m $INPUTFILE_GLOBALPATH\e[0m"
	    printf "\n\e[0;31m $JOBSCRIPT_GLOBALPATH\e[0m"
	    printf "\n\e[0;31m $HOME_BETADIRECTORY/$HMC_TM_FILENAME\e[0m"
	    printf "\n\e[0;31m Aborting...\n\e[0m"
	    exit -1
	fi
    done
}


function ProcessBetaValuesForSubmitOnly() {
    for BETA in ${BETAVALUES[@]}; do
	
	#-------------------------------------------------------------------------------------------------------------------------#
	HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA_PREFIX$BETA"
	JOBSCRIPT_GLOBALPATH="${HOME_BETADIRECTORY}/$JOBSCRIPT_NAME"
	INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$INPUTFILE_NAME"
	#-------------------------------------------------------------------------------------------------------------------------#

	if [ ! -d $HOME_BETADIRECTORY ]; then
	    printf "\e[0;31m Directory for beta = $BETA does not exist.\n\e[0m"
	    printf "\e[0;31m Going to next beta...\n\e[0m"
	    PROBLEM_BETA_ARRAY+=( $BETA )
	    continue
	else
	    #$HOME_BETADIRECTORY already exists. Check if there are files in $HOME_BETADIRECTORY. 
	    if [ -f "$INPUTFILE_GLOBALPATH" ] && [ -f "$JOBSCRIPT_GLOBALPATH" ] && [ -f "$HOME_BETADIRECTORY/$HMC_TM_FILENAME" ]; then
		#Check if there are more than 3 files, this means that there are more files than
		#jobscript, input file and hmc_tm which should not be the case
		if [ $(ls $HOME_BETADIRECTORY | wc -l) -gt 3 ]; then
		    printf "\n\e[0;31m There are already files in $HOME_BETADIRECTORY...\n\e[0m"
		    printf "\e[0;31m Leaving out $BETA ...\n\n\e[0m"
		    PROBLEM_BETA_ARRAY+=( $BETA )
		    continue
		fi
    	        #The following will not happen if the previous if-case applied
		#Adding beta value to SUBMIT_BETA_ARRAY
		SUBMIT_BETA_ARRAY+=( $BETA )
	    else
		printf "\n\e[0;31m One or more of the following files are missing:\n\e[0m"
		printf "\n\e[0;31m $INPUTFILE_GLOBALPATH\e[0m"
		printf "\n\e[0;31m $JOBSCRIPT_GLOBALPATH\e[0m"
		printf "\n\e[0;31m $HOME_BETADIRECTORY/$HMC_TM_FILENAME\e[0m"
		printf "\e[0;31m Leaving out $BETA ...\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
		continue
	    fi
	fi
    done
}


function ProcessBetaValuesForContinue() {
    for i in ${BETAVALUES[@]}; do

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
}


function ProduceJobStatusFile(){

	JOBS_STATUS_FILE="jobs_status_""$CHEMPOT_PREFIX$CHEMPOT"_"$KAPPA_PREFIX$KAPPA"_"$NTIME_PREFIX$NTIME"_"$NSPACE_PREFIX$NSPACE"".txt"

	if [ -f $JOBS_STATUS_FILE ]; then
		
		rm $JOBS_STATUS_FILE
	fi

	printf "\n\e[0;36m==================================================================================================\n\e[0m"
	printf "\e[0;34m Listing current measurements status...\n\e[0m"

	#printf "\n\e[0;34mBeta \t Total nr of trajectories \t Trajectories done \t trajectories remaining\n\e[0m"
	printf "\n\e[0;34m%s  %s  %s  %s %s %s\n\e[0m" "  Beta" "Total nr of trajectories" "Trajectories done" "Trajectories remaining" "Status"
	printf "%s  %s  %s  %s %s\n" "  Beta" "Total nr of trajectories" "Trajectories done" "Trajectories remaining" "Status" >> $JOBS_STATUS_FILE
	for i in b*; do

		#Assigning beta value to BETA variable for readability
		BETA=$(echo $i | grep -o "[[:digit:]].[[:digit:]]\{4\}")

		if [[ ! $BETA =~ [[:digit:]].[[:digit:]]{4} ]]; then
				
			continue;
		fi

		#JOBID_ARRAY=( $(llq -u hkf806 | grep -o "juqueen[[:alnum:]]\{3\}\.[[:digit:]]\+\.[[:digit:]]") )
		JOBID_ARRAY=( $(llq -u hkf806 | awk -v lines=$(llq -u hkf806 | wc -l) 'NR>2 && NR<lines-1{print $1}') )
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

			STATUS="notQueued"	

			if [ $JOBNAME_BETA = $BETA ] && [ $JOBNAME_KAPPA = $KAPPA ] && [ $JOBNAME_NTIME = $NTIME ] && [ $JOBNAME_NSPACE = $NSPACE ]; then

				STATUS=$(llq -l $JOBID | grep "^[[:blank:]]*Status:" | sed "s/^.*Status: \([[:alpha:]].*$\)/\1/")
				#if [ $i = "b5.7500" ]; then echo "break" 
				#fi
				break;
			fi

		done

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
			fi

			#printf "\e[0;34m$BETA \t $TOTAL_NR_TRAJECTORIES \t $TRAJECTORIES_DONE \t $MEASUREMENTS_REMAINING\n\e[0m"
			#26
			printf "\e[0;34m%.4f  %24d  %17d  %22d %s\n\e[0m" "$BETA" "$TOTAL_NR_TRAJECTORIES" "$TRAJECTORIES_DONE" "$MEASUREMENTS_REMAINING" "$STATUS"
			printf "%.4f  %24d  %17d  %22d %s\n" "$BETA" "$TOTAL_NR_TRAJECTORIES" "$TRAJECTORIES_DONE" "$MEASUREMENTS_REMAINING" "$STATUS" >> $JOBS_STATUS_FILE
		fi
		
	done
	printf "\e[0;36m==================================================================================================\n\e[0m"
}


function SubmitJobsForValidBetaValues() {
    if [ ${#SUBMIT_BETA_ARRAY[@]} -gt "0" ]; then
	
	printf "\n\e[0;36m===================================================================================\n\e[0m"
	printf "\e[0;34m Jobs will be submitted for the following beta values:\n\e[0m"
	for i in ${SUBMIT_BETA_ARRAY[@]}; do
	    echo "  - $i"
	done
	printf "\e[0;36m===================================================================================\n\e[0m"
	
	for BETA in ${SUBMIT_BETA_ARRAY[@]}; do
	    
	    #-------------------------------------------------------------------------------------------------------------------------#
	    HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	    JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA_PREFIX$BETA"
	    JOBSCRIPT_GLOBALPATH="${HOME_BETADIRECTORY}/$JOBSCRIPT_NAME"
   	    #-------------------------------------------------------------------------------------------------------------------------#
	    
	    cd $HOME_BETADIRECTORY
	    printf "\n\e[0;34m actual location: $(pwd) \n\e[0m"
	    printf "\e[0;34m Submitting:\n\e[0m"
	    printf "\e[0;34m llsubmit $JOBSCRIPT_GLOBALPATH\n\e[0m"
	    llsubmit $JOBSCRIPT_GLOBALPATH
	    cd ..
	done
    else
	printf " \e[1;37;41mNo jobs will be submitted.\e[0m\n"
    fi
}

