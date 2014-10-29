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

	if [ "$CLUSTER_NAME" = "LOEWE" ]; then
	    if [ $(echo "${#BETAVALUES[@]}" | awk '{print $1 % '"$GPU_PER_NODE"'}') -ne 0 ]; then
		printf "\n\e[0;33m \e[1m\e[4mWARNING\e[24m:\e[0;33m Number of beta values provided not multiple of $GPU_PER_NODE. WASTING computing time...\n\n\e[0m"
	    fi
	fi

    else	

	printf "\n\e[0;31m  No beta values in betas file. Aborting...\n\n\e[0m"

	exit -1
    fi
}


function ProduceInputFileAndJobScriptForEachBeta(){

    if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
	
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
	    cp $HMC_GLOBALPATH $HOME_BETADIRECTORY || exit -2
	    
	    if [ -f "$INPUTFILE_GLOBALPATH" ] && [ -f "$JOBSCRIPT_GLOBALPATH" ]; then
		printf "\e[0;34m ...files built successfully!\n\n\e[0m"
	    else
		printf "\n\e[0;31m One or more of the following files has not been successfully created:\n\e[0m"
		printf "\n\e[0;31m  - $INPUTFILE_GLOBALPATH\e[0m"
		printf "\n\e[0;31m  - $JOBSCRIPT_GLOBALPATH\n\e[0m"
		printf "\n\e[0;31m Aborting...\n\n\e[0m"
		exit -1
	    fi
	    
	    # Create a File in each new beta dir with the name format bx.xxx_created_d_m_y
	    # From this file one can tell when a directory was created the first time
	    touch $HOME_BETADIRECTORY"/b"$BETA"_created_$(date +"%d_%m_%y")"
	    
	done #loop on BETA
	
    else #on LOEWE
	
	#-------------------------------------------------------------------------------------------------------------------------#
	local BETAVALUES_COPY=(${BETAVALUES[@]})
	#-------------------------------------------------------------------------------------------------------------------------#
	for BETA in "${!BETAVALUES_COPY[@]}"; do
	    local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX${BETAVALUES_COPY[$BETA]}"
	    if [ -d "$HOME_BETADIRECTORY" ]; then
		if [ $(ls $HOME_BETADIRECTORY | wc -l) -gt 0 ]; then
		    printf "\n\e[0;31m There are already files in $HOME_BETADIRECTORY. The value beta = ${BETAVALUES_COPY[$BETA]} will be skipped!\n\n\e[0m"
		    PROBLEM_BETA_ARRAY+=( ${BETAVALUES_COPY[$BETA]} )
		    unset BETAVALUES_COPY[$BETA] #Here BETAVALUES_COPY becomes sparse
		    continue
		fi
	    fi
	done
	#Make BETAVALUES_COPY not sparse
	BETAVALUES_COPY=(${BETAVALUES_COPY[@]})
	#Let's try to start from a thermalized configuration is existing
	local STARTCONDITION=()
	local CONFIGURATION_SOURCEFILE=()
	for BETA in "${!BETAVALUES_COPY[@]}"; do
	    local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX${BETAVALUES_COPY[$BETA]}"
	    local STARTCONFIGURATION_NAME="conf.${PARAMETERS_STRING}_$BETA_PREFIX${BETAVALUES_COPY[$BETA]}"
	    local NUMBER_OF_THERMALIZED_CONFIGURATIONS=$(ls $THERMALIZED_CONFIGURATIONS_PATH | grep "$STARTCONFIGURATION_NAME" | wc -l)
	    if [ $NUMBER_OF_THERMALIZED_CONFIGURATIONS -eq 0 ]; then
		STARTCONDITION+=( "hot" )
		CONFIGURATION_SOURCEFILE+=( "---" )
	    elif [ $NUMBER_OF_THERMALIZED_CONFIGURATIONS -eq 1 ]; then
		STARTCONDITION+=( "continue" )
		CONFIGURATION_SOURCEFILE+=( "$(ls $THERMALIZED_CONFIGURATIONS_PATH | grep "$STARTCONFIGURATION_NAME")" )
	    elif [ $NUMBER_OF_THERMALIZED_CONFIGURATIONS -gt 1 ]; then
		echo "NUMBER_OF_THERMALIZED_CONFIGURATIONS=$NUMBER_OF_THERMALIZED_CONFIGURATIONS"
		printf "\n\e[0;31m There are more than one thermalized configuration for these parameters. The value beta = ${BETAVALUES_COPY[$BETA]}  will be skipped!\n\e[0m"
		PROBLEM_BETA_ARRAY+=( ${BETAVALUES_COPY[$BETA]} )
		unset BETAVALUES_COPY[$BETA] #Here BETAVALUES_COPY becomes sparse
		continue
	    fi
	done
        #If the previous for loop went through, we create the beta folders (just to avoid to create some folders and then abort)
	BETAVALUES_COPY=(${BETAVALUES_COPY[@]}) #If sparse, make it not sparse otherwise the following while doesn't work!!
	for BETA in "${!BETAVALUES_COPY[@]}"; do
	    local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX${BETAVALUES_COPY[$BETA]}"
	    printf "\e[0;34m Creating directory for beta = ${BETAVALUES_COPY[$BETA]}...\e[0m"
            mkdir $HOME_BETADIRECTORY || exit -2
            printf "\e[0;34m done!\n\e[0m"
	    if [[ "${STARTCONDITION[$BETA]}" == "continue" ]]; then
		printf "\e[0;36m    Copying Thermalized configuration in directory for beta = ${BETAVALUES_COPY[$BETA]}...\e[0m"
		cp $THERMALIZED_CONFIGURATIONS_PATH/${CONFIGURATION_SOURCEFILE[$BETA]} $HOME_BETADIRECTORY
		printf "\e[0;36m done!\n\e[0m"
	    else
		printf "\e[0;36m    No thermalized configuration to be copied for beta = ${BETAVALUES_COPY[$BETA]}, HOT start!\e[0m"
	    fi
	    #Call the file to produce the input file
	    local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$INPUTFILE_NAME"
	    . $PRODUCEINPUTFILESH	    
	done
        # Partition the BETAVALUES_COPY array into group of GPU_PER_NODE and create the JobScript files inside the JOBSCRIPT_FOLDER
	mkdir -p ${HOME_DIR_WITH_BETAFOLDERS}/$JOBSCRIPT_LOCALFOLDER || exit -2
	BETAVALUES_COPY=(${BETAVALUES_COPY[@]}) #If sparse, make it not sparse otherwise the following while doesn't work!!
	STARTCONDITION=(${STARTCONDITION[@]})   #If sparse, make it not sparse otherwise the following while doesn't work!!
	CONFIGURATION_SOURCEFILE=(${CONFIGURATION_SOURCEFILE[@]})  #If sparse, make it not sparse otherwise the following while doesn't work!!
	while [[ "${!BETAVALUES_COPY[@]}" != "" ]]; do # ${!array[@]} gives the list of the valid indeces in the array
	    local BETA_FOR_JOBSCRIPT=(${BETAVALUES_COPY[@]:0:$GPU_PER_NODE})
	    BETAVALUES_COPY=(${BETAVALUES_COPY[@]:$GPU_PER_NODE})
	    local BETAS_STRING=""
	    local STARTCONDITION_FOR_JOBSCRIPT=(${STARTCONDITION[@]:0:$GPU_PER_NODE})
	    STARTCONDITION=(${STARTCONDITION[@]:$GPU_PER_NODE})
	    local CONFIG_FOR_JOBSCRIPT=(${CONFIGURATION_SOURCEFILE[@]:0:$GPU_PER_NODE})
	    CONFIGURATION_SOURCEFILE=(${CONFIGURATION_SOURCEFILE[@]:$GPU_PER_NODE})
	    printf "\n\e[0;36m=================================================\n\e[0m"
	    printf "\e[0;36m  The following beta values have been grouped:\e[0m\n    "
	    for BETA in "${!BETA_FOR_JOBSCRIPT[@]}"; do
		printf "${BETA_FOR_JOBSCRIPT[BETA]}     "
		BETAS_STRING="${BETAS_STRING}_$BETA_PREFIX${BETA_FOR_JOBSCRIPT[BETA]}"
	    done
	    printf "\n\e[0;36m=================================================\n\e[0m"
	    local JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_${BETAS_STRING:1}"
	    local JOBSCRIPT_GLOBALPATH="${HOME_DIR_WITH_BETAFOLDERS}/$JOBSCRIPT_LOCALFOLDER/$JOBSCRIPT_NAME"
	    if [ -e $JOBSCRIPT_GLOBALPATH ]; then
		mv $JOBSCRIPT_GLOBALPATH ${JOBSCRIPT_GLOBALPATH}_$(date +'%F_%H%M') || exit -2
	    fi
	    #Call the file to produce the jobscript file
	    . $PRODUCEJOBSCRIPTSH
	    if [ -e $JOBSCRIPT_GLOBALPATH ]; then
		SUBMIT_BETA_ARRAY+=( "${BETAS_STRING:1}" )
	    else
		printf "\n\e[0;31m Jobscript \"$JOBSCRIPT_NAME\" failed to be created! It will be not submitted!!!\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( "${BETAS_STRING:1}" )
	    fi
	done
    fi
}


function ProcessBetaValuesForSubmitOnly() {

    if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then

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
		if [ -f "$INPUTFILE_GLOBALPATH" ] && [ -f "$JOBSCRIPT_GLOBALPATH" ] && [ -f "$HOME_BETADIRECTORY/$HMC_FILENAME" ]; then
		   #Check if there are more than 3 files, this means that there are more files than
		   #jobscript, input file and hmc_tm which should not be the case
		   #The number of allowed files in the $HOME_BETADIRECTORY directory are no increased to 4 due to the new file
		   #that is created at creation of the beta directory. The name of the new file shows when the beta directory
		   #was created the first time
		    if [ $(ls $HOME_BETADIRECTORY | wc -l) -gt 4 ]; then
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
		    printf "\n\e[0;31m  - $HOME_BETADIRECTORY/$HMC_FILENAME\n\e[0m"
		    printf "\n\e[0;31m The value beta = $BETA will be skipped!\n\n\e[0m"
		    PROBLEM_BETA_ARRAY+=( $BETA )
		    continue
		fi
	    fi
	done
	
    else # on LOEWE
	
	#-------------------------------------------------------------------------------------------------------------------------#
	local BETAVALUES_COPY=(${BETAVALUES[@]})
	#-------------------------------------------------------------------------------------------------------------------------#
	for BETA in "${!BETAVALUES_COPY[@]}"; do
	    local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX${BETAVALUES_COPY[$BETA]}"
	    local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$INPUTFILE_NAME"
	    if [ ! -d $HOME_BETADIRECTORY ]; then
		printf "\n\e[0;31m Directory $HOME_BETADIRECTORY not existing. The value beta = ${BETAVALUES_COPY[$BETA]} will be skipped!\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( ${BETAVALUES_COPY[$BETA]} )
		unset BETAVALUES_COPY[$BETA] #Here BETAVALUES_COPY becomes sparse
		continue
	    else
	        #$HOME_BETADIRECTORY already exists. Check if there are files in $HOME_BETADIRECTORY. 
		if [ -f "$INPUTFILE_GLOBALPATH" ]; then
		    # In the home betadirectory there should be the inputfile and sometimes
		    # the thermalized configuration whose name start with "conf.". 
		    if [ $(ls $HOME_BETADIRECTORY | wc -l) -eq 1 ]; then
			printf "\n\e[0;32m The simulation with beta = ${BETAVALUES_COPY[$BETA]} start from a HOT configuration!\n\e[0m"
		    elif [ $(ls $HOME_BETADIRECTORY | wc -l) -eq 2 ] && [ $(ls $HOME_BETADIRECTORY | grep "conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETAVALUES_COPY[$BETA]}*" | wc -l) -eq 1 ]; then
			printf "\n\e[0;32m The simulation with beta = ${BETAVALUES_COPY[$BETA]} start from a thermalized configuration!\n\e[0m"
		    else
			printf "\n\e[0;31m There are already files in $HOME_BETADIRECTORY. The value beta = ${BETAVALUES_COPY[$BETA]} will be skipped!\n\n\e[0m"
			PROBLEM_BETA_ARRAY+=( ${BETAVALUES_COPY[$BETA]} )
			unset BETAVALUES_COPY[$BETA] #Here BETAVALUES_COPY becomes sparse
			continue
		    fi		 
		else
		    printf "\n\e[0;31m The following intput-file is missing:\n\e[0m"
		    printf "\n\e[0;31m    $INPUTFILE_GLOBALPATH\e[0m"
		    printf "\n\e[0;31m The value beta = ${BETAVALUES_COPY[$BETA]} will be skipped!\n\n\e[0m"
		    PROBLEM_BETA_ARRAY+=( ${BETAVALUES_COPY[$BETA]} )
		    unset BETAVALUES_COPY[$BETA] #Here BETAVALUES_COPY becomes sparse
		    continue
		fi
	    fi
	done
	#Make BETAVALUES_COPY not sparse
        BETAVALUES_COPY=(${BETAVALUES_COPY[@]})
	#Here partition beta and check for jobscript existing!
	while [[ "${!BETAVALUES_COPY[@]}" != "" ]]; do # ${!array[@]} gives the list of the valid indeces in the array
	    local BETA_FOR_JOBSCRIPT=(${BETAVALUES_COPY[@]:0:$GPU_PER_NODE})
	    BETAVALUES_COPY=(${BETAVALUES_COPY[@]:$GPU_PER_NODE})
	    local BETAS_STRING=""
	    printf "\n\e[0;36m=================================================\n\e[0m"
	    printf "\e[0;36m  The following beta values have been grouped:\e[0m\n    "
	    for BETA in "${!BETA_FOR_JOBSCRIPT[@]}"; do
		printf "${BETA_FOR_JOBSCRIPT[BETA]}     "
		BETAS_STRING="${BETAS_STRING}_$BETA_PREFIX${BETA_FOR_JOBSCRIPT[BETA]}"
	    done
	    printf "\n\e[0;36m=================================================\n\e[0m"
	    local JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_${BETAS_STRING:1}"
	    local JOBSCRIPT_GLOBALPATH="${HOME_DIR_WITH_BETAFOLDERS}/$JOBSCRIPT_LOCALFOLDER/$JOBSCRIPT_NAME"
	    if [ ! -e $JOBSCRIPT_GLOBALPATH ]; then
		printf "\n\e[0;31m Jobscript \"$JOBSCRIPT_NAME\" not found! It will be not submitted!!!\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( "${BETAS_STRING:1}" )
	    else
		SUBMIT_BETA_ARRAY+=( "${BETAS_STRING:1}" )
	    fi
	done
    fi
}

function CheckIfJobIsInQueue(){

    local JOBNAME=$PARAMETERS_STRING'_'$BETA_PREFIX$BETA

    if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
	local JOBID_ARRAY=( $(llq -u $(whoami) | grep -o "juqueen[[:alnum:]]\{3\}\.[[:digit:]]\+\.[[:digit:]]") )
    else #LOEWE
	local JOBID_ARRAY=( $(squeue | awk 'NR>1{print $1}') )
    fi
    
    for JOBID in ${JOBID_ARRAY[@]}; do
	
	if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
	    local GREPPED_JOBNAME=$(llq -l $JOBID | grep "Job Name:" | sed "s/^.*Job Name: \(muiPiT.*$\)/\1/")
	else #LOEWE
	    local GREPPED_JOBNAME=$(scontrol show job  $JOBID | grep "Name=" | sed "s/^.*Name=\(.*$\)/\1/")
	    local JOBSTATUS=$(scontrol show job $JOBID | grep "^[[:blank:]]*JobState=" | sed "s/^.*JobState=\([[:alpha:]]*\)[[:blank:]].*$/\1/") 
	fi
	
	if [ $GREPPED_JOBNAME = $JOBNAME ]; then
	    
	    if [ "$CLUSTER_NAME" = "LOEWE" ] && [ "$JOBSTATUS" != "RUNNING" -a "$JOBSTATUS" != "PENDING" ]; then
		break;
	    fi
	    printf "\e[0;31m Job with name $JOBNAME seems to be already running with id $JOBID.\n"
	    printf " Job cannot be continued...\n\n\e[0m"
	    
	    return 0
	fi
	
    done
    
    return 1

}

function ProcessBetaValuesForContinue() {
    
    for BETA in ${BETAVALUES[@]}; do
	
     	#-------------------------------------------------------------------------------------------------------------------------#
	local WORK_BETADIRECTORY="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	local JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA_PREFIX$BETA"
	local JOBSCRIPT_GLOBALPATH="${HOME_BETADIRECTORY}/$JOBSCRIPT_NAME"
	local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$INPUTFILE_NAME"
	local OUTPUTFILE_GLOBALPATH="${WORK_BETADIRECTORY}/$OUTPUTFILE_NAME"
	#-------------------------------------------------------------------------------------------------------------------------#

	if [ ! -f $INPUTFILE_GLOBALPATH ]; then
	    
	    printf "\n\e[0;31m $INPUTFILE_GLOBALPATH does not exist.\n\e[0m"
	    printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
	    PROBLEM_BETA_ARRAY+=( $BETA )
	    continue
	    
	elif [ ! -f $OUTPUTFILE_GLOBALPATH ]; then
	    
	    printf "\n\e[0;31m $OUTPUTFILE_GLOBALPATH does not exist.\n\e[0m"
	    printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
	    PROBLEM_BETA_ARRAY+=( $BETA )
	    continue

        elif [ ! -f $JOBSCRIPT_GLOBALPATH ]; then
	
	    printf "\n\e[0;31m $JOBSCRIPT_GLOBALPATH does not exist.\n\e[0m"
	    printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
	    PROBLEM_BETA_ARRAY+=( $BETA )
	    continue

	fi
	
	echo ""
	CheckIfJobIsInQueue
	if [ $? == 0 ]; then
	    
	    PROBLEM_BETA_ARRAY+=( $BETA )
	    continue
	fi
	
	if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
	    
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


	else # LOEWE
	    exit

	    #At the moment we do not allow to continue more than one job --> ONLY one beta per time
	    if [ ${#BETAVALUES[@]} -gt 1 ]; then
		printf "\e[0;31m At the moment we do not allow to continue more than one job --> ONLY one beta in $BETASFILE file! Aborting...\n\n\e[0m"	
		exit -1
	    fi

	    #If the option --resumefrom is given we have to clean the $WORK_BETADIRECTORY
	    for(( INDEX=0; INDEX<${#SPECIFIED_COMMAND_LINE_OPTIONS[@]}; INDEX++)); do
		if [[ "${SPECIFIED_COMMAND_LINE_OPTIONS[$INDEX]}" == --resumefrom=* ]]; then
		    #If the user wants to resume from CONTINUE_RESUMETRAJ, first check that the conf is available
		    if [ -f $WORK_BETADIRECTORY/$(printf "conf.%05d" "$CONTINUE_RESUMETRAJ") ]; then
			local NAME_LAST_CONFIGURATION=$(printf "conf.%05d" "$CONTINUE_RESUMETRAJ")
		    else
			printf "\e[0;31m Configuration \"$(printf "conf.%05d" "$CONTINUE_RESUMETRAJ")\" not found in $WORK_BETADIRECTORY folder.\n"
			printf " Unable to continue the simulation. Leaving out beta = $BETA .\n\n\e[0m" 
			PROBLEM_BETA_ARRAY+=( $BETA ) 
			continue 2                                                                                         
		    fi
		    #If the OUTPUTFILE_NAME is not in the WORK_BETADIRECTORY stop and not do anything
		    if [ ! -f $OUTPUTFILE_GLOBALPATH ]; then 
			printf "\e[0;31m File \"$OUTPUTFILE_NAME\" not found in $WORK_BETADIRECTORY folder.\n"
			printf " Unable to continue the simulation from trajectory. Leaving out beta = $BETA .\n\n\e[0m"
			PROBLEM_BETA_ARRAY+=( $BETA )
			continue 2
		    fi
		    #Now it should be feasable to resume simulation ---> clean WORK_BETADIRECTORY
		    #Create in WORK_BETADIRECTORY a folder named Trash_$(date) where to mv all the file produced after the traj. CONTINUE_RESUMETRAJ
		    local TRASH_NAME="$WORK_BETADIRECTORY/Trash_$(date +'%F_%H%M')"
		    mkdir $TRASH_NAME || exit 2
		    for FILE in $WORK_BETADIRECTORY/conf.* $WORK_BETADIRECTORY/prng.*; do
			#Move to trash only conf.xxxxx files or conf.xxxxx_pbp.dat files
			local NUMBER_FROM_FILE=$(echo "$FILE" | grep -o "\(\(conf.\)\|\(prng.\)\)[[:digit:]]\{5\}\(_pbp.dat\)\?$" | sed 's/\(\(conf.\)\|\(prng.\)\)\([[:digit:]]\+\).*/\4/' | sed 's/^0*//')
			if [ "$NUMBER_FROM_FILE" != "" ] && [ $NUMBER_FROM_FILE -gt $CONTINUE_RESUMETRAJ ]; then
			    mv $FILE $TRASH_NAME
			fi
		    done
		    #Move to trash conf.save and prng.save files if existing
		    if [ -f $WORK_BETADIRECTORY/conf.save ]; then mv $WORK_BETADIRECTORY/conf.save $TRASH_NAME; fi
		    if [ -f $WORK_BETADIRECTORY/prng.save ]; then mv $WORK_BETADIRECTORY/prng.save $TRASH_NAME; fi
		    #Copy the hmc_output file to Trash and edit it leaving out all the trajectories after CONTINUE_RESUMETRAJ
		    cp $OUTPUTFILE_GLOBALPATH $TRASH_NAME || exit 2 
		    local LINES_TO_BE_CANCELED_IN_OUTPUTFILE=$(tac $OUTPUTFILE_GLOBALPATH | awk -v resumeFrom=$CONTINUE_RESUMETRAJ 'BEGIN{found=0}{if($1==resumeFrom){found=1; print NR; exit}}END{if(found==0){print -1}}')
		    if [ $LINES_TO_BE_CANCELED_IN_OUTPUTFILE -eq -1 ]; then
			printf "\n\e[0;31m The number of lines to be removedMeasurement for trajectory $CONTINUE_RESUMETRAJ not found in outputfile.\n\e[0m"
			printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
			PROBLEM_BETA_ARRAY+=( $BETA )
			continue 2
		    fi
		    #The -1 in the following line is not a typo, it has to be -1 since the number was recovered with tac backwards
		    head -n -$(($LINES_TO_BE_CANCELED_IN_OUTPUTFILE-1)) $OUTPUTFILE_GLOBALPATH > ${OUTPUTFILE_GLOBALPATH}.temporaryCopyThatHopefullyDoesNotExist || exit 2
		    mv ${OUTPUTFILE_GLOBALPATH}.temporaryCopyThatHopefullyDoesNotExist $OUTPUTFILE_GLOBALPATH || exit 2
		    
                    #Once the WORK_BETADIRECTORY has been prepared for resuming, delete from the array SPECIFIED_COMMAND_LINE_OPTIONS the --resumefrom option
		    unset SPECIFIED_COMMAND_LINE_OPTIONS[$INDEX]
		    SPECIFIED_COMMAND_LINE_OPTIONS=( "${SPECIFIED_COMMAND_LINE_OPTIONS[@]}" )
		    break
		
	        #If --resumfrom option has not been given check in the WORK_BETADIRECTORY if conf.save is present: if yes, use it, otherwise use the last checkpoint
		elif [ -f $WORK_BETADIRECTORY/conf.save ]; then
		    local NAME_LAST_CONFIGURATION="conf.save"
		else
		    local NAME_LAST_CONFIGURATION=$(ls $WORK_BETADIRECTORY | grep -o "conf.[[:digit:]]\{5\}$" | tail -n1)
		fi
	    done


	    #The variable NAME_LAST_CONFIGURATION should have been set above, if not it means no conf was available!
	    if [ "$NAME_LAST_CONFIGURATION" == "" ]; then
		printf "\n\e[0;31m No configuration found in $WORK_BETADIRECTORY.\n\e[0m"
		printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
                continue
	    fi

	    if [ -f $HOME_BETADIRECTORY/$NAME_LAST_CONFIGURATION ]; then
		mv $HOME_BETADIRECTORY/$NAME_LAST_CONFIGURATION $HOME_BETADIRECTORY/${NAME_LAST_CONFIGURATION}_$(date +'%F_%H.%M') || exit 2
	    fi
	    cp $WORK_BETADIRECTORY/$NAME_LAST_CONFIGURATION $HOME_BETADIRECTORY || exit 2
	    cp $JOBSCRIPT_GLOBALPATH ${JOBSCRIPT_GLOBALPATH}_$(date +'%F_%H.%M') || exit 2

	    #For each command line option, modify it in the jobscript (remove first --continue option(s) from command line)
	    for(( INDEX=0; INDEX<${#SPECIFIED_COMMAND_LINE_OPTIONS[@]}; INDEX++)); do
		if [[ "${SPECIFIED_COMMAND_LINE_OPTIONS[$INDEX]}" == --continue* ]]; then
		    unset SPECIFIED_COMMAND_LINE_OPTIONS[$INDEX]
		    SPECIFIED_COMMAND_LINE_OPTIONS=( "${SPECIFIED_COMMAND_LINE_OPTIONS[@]}" )
		fi
	    done
	    #If CONTINUE_NUMBER is given, set automatically the number of remaining measurements.
	    # NOTE: If --measurements=... is (also) given, then --measurements will be used!
	    #       Note also that we count the number of the output file as number of "clean"
	    #       trajectories, i.e. the output file is here read and count the tr. whose number
	    #       is bigger than the trajectory before.
	    if [ $CONTINUE_NUMBER -ne 0 ]; then
		local NUMBER_DONE_TRAJECTORIES=$(awk 'BEGIN{traj_num = -1; count=0}{if($1>traj_num){traj_num = $1; count++}}END{print count}' $OUTPUTFILE_GLOBALPATH)
		if [ $NUMBER_DONE_TRAJECTORIES -gt $CONTINUE_NUMBER ]; then
		    printf "\e[0;31m From the output file $OUTPUTFILE_GLOBALPATH"
		    printf "\n we got that the number of done measurements is $NUMBER_DONE_TRAJECTORIES > $CONTINUE_NUMBER = CONTINUE_NUMBER."
		    printf "\n The option \"--continue=$CONTINUE_NUMBER\" cannot be applied. Skipping beta = $BETA .\n\n\e[0m"
                    PROBLEM_BETA_ARRAY+=( $BETA )
                    continue
		fi
		ModifyOptionInJobScript "--measurements=$(($CONTINUE_NUMBER - $NUMBER_DONE_TRAJECTORIES))"
		[ $? == 1 ] && continue 2
		printf "\e[0;32m Set option \e[0;35m--measurements=$(($CONTINUE_NUMBER - $NUMBER_DONE_TRAJECTORIES))"
		printf "\e[0;32m into the \e[0;35m${JOBSCRIPT_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"		
	    fi
	    #Always convert startcondition in continue
	    ModifyOptionInJobScript "--startcondition=continue"
	    #If --host_seed not present in the job script file, add it, otherwise modify it
	    local NUMBER_OCCURENCE_HOST_SEED=$(grep -o "\-\-host_seed=[[:digit:]]\{4\}" $JOBSCRIPT_GLOBALPATH | wc -l)
	    if [ $NUMBER_OCCURENCE_HOST_SEED -eq 0 ]; then
		ModifyOptionInJobScript "--host_seed=${BETA#*.} --beta=$BETA"
		[ $? == 1 ] && continue
		printf "\e[0;32m Added option \e[0;35m--host_seed=${BETA#*.}\e[0;32m to the \e[0;35m${JOBSCRIPT_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
	    elif [ $NUMBER_OCCURENCE_HOST_SEED -eq 1 ]; then
		local VALUE_HOST_SEED=$(grep -o "\-\-host_seed=[[:digit:]]\{4\}" $JOBSCRIPT_GLOBALPATH | sed "s/^--host_seed=\(.*$\)/\1/" | sed 's/^0*//')
		ModifyOptionInJobScript "--host_seed=$( printf "%04d" $(($VALUE_HOST_SEED + 1)) )"
		[ $? == 1 ] && continue
		printf "\e[0;32m Set option \e[0;35m--host_seed=$( printf "%04d" $(($VALUE_HOST_SEED + 1)) )"
		printf "\e[0;32m into the \e[0;35m${JOBSCRIPT_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
	    else
		printf "\n\e[0;31m String --host_seed=[[:digit:]]{4} occurs more than 1 time in file $JOBSCRIPT_GLOBALPATH! Skipping beta = $BETA .\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
		continue
	    fi
	    #If --sourcefile not present in the job script file, add it, otherwise modify it
	    local NUMBER_OCCURENCE_SOURCEFILE=$(grep -o "\-\-sourcefile=[[:alnum:][:punct:]]*" $JOBSCRIPT_GLOBALPATH | wc -l)
	    if [ $NUMBER_OCCURENCE_SOURCEFILE -eq 0 ]; then
		ModifyOptionInJobScript "--sourcefile=\$SLURM_SUBMIT_DIR\/${NAME_LAST_CONFIGURATION} --host_seed"
		[ $? == 1 ] && continue
		printf "\e[0;32m Added option \e[0;35m--sourcefile=\$SLURM_SUBMIT_DIR/${NAME_LAST_CONFIGURATION}"
		printf "\e[0;32m to the \e[0;35m${JOBSCRIPT_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
	    elif [ $NUMBER_OCCURENCE_SOURCEFILE -eq 1 ]; then
		ModifyOptionInJobScript "--sourcefile=\$SLURM_SUBMIT_DIR\/${NAME_LAST_CONFIGURATION}"
		[ $? == 1 ] && continue
		printf "\e[0;32m Set option \e[0;35m--sourcefile=\$SLURM_SUBMIT_DIR/${NAME_LAST_CONFIGURATION}"
		printf "\e[0;32m into the \e[0;35m${JOBSCRIPT_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
	    else
		printf "\n\e[0;31m String --sourcefile=[[:alnum:][:punct:]]* occurs more than 1 time in file $JOBSCRIPT_GLOBALPATH! Skipping beta = $BETA .\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
		continue
	    fi
	    #Modify remaining command line specified options
	    for OPT in ${SPECIFIED_COMMAND_LINE_OPTIONS[@]}; do
		ModifyOptionInJobScript $OPT
		[ $? == 1 ] && continue 2
		printf "\e[0;32m Set option \e[0;35m$OPT\e[0;32m into the \e[0;35m${JOBSCRIPT_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"		
	    done

	    #If the script runs fine and it arrives here, it means no continue was done --> we can add BETA to the jobs to be submitted
	    SUBMIT_BETA_ARRAY+=( $BETA )

	fi # cluster name

    done # loop on BETA


}

function ModifyOptionInJobScript(){
    if [ $# -ne 1 ]; then
	printf "\n\e[0;31m The function ModifyOptionInJobScript() has been wrongly called! Aborting...\n\n\e[0m"
	exit -1
    fi
    
    case $1 in
	--startcondition=* )        FindAndReplaceSingleOccurenceInFile $JOBSCRIPT_GLOBALPATH "\-\-startcondition=[[:alpha:]]\+" "--startcondition=${1#*=}" ;;
	--sourcefile=*--host_seed ) FindAndReplaceSingleOccurenceInFile $JOBSCRIPT_GLOBALPATH "\-\-host_seed" \
                                                                                           "--sourcefile=$(echo $1 | sed 's/\-\-sourcefile=\(.*\) --host_seed/\1/') --host_seed" ;;
	--sourcefile=* )            FindAndReplaceSingleOccurenceInFile $JOBSCRIPT_GLOBALPATH "\-\-sourcefile=[[:alnum:][:punct:]]*" "--sourcefile=${1#*=}" ;;
	--host_seed=*--beta=* )     FindAndReplaceSingleOccurenceInFile $JOBSCRIPT_GLOBALPATH "\-\-beta=$BETA" \
	                                                                                      "--host_seed=$(echo $1 | sed 's/\-\-host_seed=\(.*\) --beta.*$/\1/') --beta=$BETA" ;;
	--host_seed=* )             FindAndReplaceSingleOccurenceInFile $JOBSCRIPT_GLOBALPATH "\-\-host_seed=[[:digit:]]\+" "--host_seed=${1#*=}" ;;
	--intsteps0=* )             FindAndReplaceSingleOccurenceInFile $JOBSCRIPT_GLOBALPATH "\-\-integrationsteps0=[[:digit:]]\+" "--integrationsteps0=${1#*=}" ;;
	--intsteps1=* )             FindAndReplaceSingleOccurenceInFile $JOBSCRIPT_GLOBALPATH "\-\-integrationsteps1=[[:digit:]]\+" "--integrationsteps1=${1#*=}" ;;
	--nsave=* )                 FindAndReplaceSingleOccurenceInFile $JOBSCRIPT_GLOBALPATH "\-\-savefrequency=[[:digit:]]\+" "--savefrequency=${1#*=}" ;;
	--measurements=* )          FindAndReplaceSingleOccurenceInFile $JOBSCRIPT_GLOBALPATH "\-\-hmcsteps=[[:digit:]]\+" "--hmcsteps=${1#*=}" ;;
        --walltime=* )              FindAndReplaceSingleOccurenceInFile $JOBSCRIPT_GLOBALPATH "\-\-time=[[:digit:]]*-\{0,1\}\([[:digit:]]\{2\}:\)\{2\}[[:digit:]]\{2\}"\
                                                                                           "--time=${1#*=}" ;;
        * ) printf "\n\e[0;31m The option \"$1\" cannot be handled in the continue scenario.\n\e[0m"
        printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
        PROBLEM_BETA_ARRAY+=( $BETA )
	return 1
    esac

    return $?
}

#This function must be called with 3 parameters: filename (global path), string to be found, replace string
function FindAndReplaceSingleOccurenceInFile(){
    if [ $# -ne 3 ]; then
	printf "\n\e[0;31m The function FindAndReplaceSingleOccurenceInFile() has been wrongly called! Aborting...\n\n\e[0m"
	exit -1
    elif [ ! -f $1 ]; then
	printf "\n\e[0;31m Error occurred in FindAndReplaceSingleOccurenceInFile(): file $1 has not been found! Aborting...\n\n\e[0m"
	exit -1
    elif [ $(grep -o "$2" $1 | wc -l) -ne 1 ]; then
	printf "\n\e[0;31m Error occurred in FindAndReplaceSingleOccurenceInFile(): string $2 occurs 0 times or more than 1 time in file $1! Skipping beta = $BETA .\n\n\e[0m"
	PROBLEM_BETA_ARRAY+=( $BETA )
	return 1
    fi

    sed -i "s/$2/$3/g" $1 || exit 2

    return 0
    
}

function ShowQueuedJobsLocal(){
#TODO: Generalize user name

	if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then

	printf "\n\e[0;36m==================================================================================================\n\e[0m"
		llq -W -f %id %jn %st %c %dq %dd %gl %h -u $(whoami) | awk --posix '$2 ~ /^muiPiT_'$KAPPA_PREFIX$KAPPA'_'$NTIME_PREFIX$NTIME'_'$NSPACE_PREFIX$NSPACE'_'$BETA_PREFIX'[[:digit:]]\.[[:digit:]]{4}$/ || NR <= 2 {print}'
	printf "\e[0;36m==================================================================================================\n\e[0m"

	else
		echo "Fuctionality only implemented for the Juqueen cluster at the moment...terminating"
		exit -1
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
	    if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
		local SUBMITTING_DIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
		local JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA_PREFIX$BETA"
	    else
		local SUBMITTING_DIRECTORY="${HOME_DIR_WITH_BETAFOLDERS}/$JOBSCRIPT_LOCALFOLDER"
		local JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA"
	    fi
	    #-------------------------------------------------------------------------------------------------------------------------#
	    
	    cd $SUBMITTING_DIRECTORY
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
