# Collection of function needed in the job handler script (mostly in AuxiliaryFunctions).

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

#=======================================================================================================================#

function ProduceInputFileAndJobScriptForEachBeta_Juqueen(){
    for BETA in ${BETAVALUES[@]}; do
	#-----------------------------------------------------------------------------------#
	local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	local JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA_PREFIX$BETA"
	local JOBSCRIPT_GLOBALPATH="${HOME_BETADIRECTORY}/$JOBSCRIPT_NAME"
	local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$INPUTFILE_NAME"
	#-----------------------------------------------------------------------------------#
	
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
}

#=======================================================================================================================#

function ProcessBetaValuesForSubmitOnly_Juqueen() {
    for BETA in ${BETAVALUES[@]}; do	
	#-----------------------------------------------------------------------------------#
	local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	local JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA_PREFIX$BETA"
	local JOBSCRIPT_GLOBALPATH="${HOME_BETADIRECTORY}/$JOBSCRIPT_NAME"
	local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$INPUTFILE_NAME"
	#-----------------------------------------------------------------------------------#
	
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
}

#=======================================================================================================================#

function __static__CheckIfJobIsInQueue_Juqueen(){
    local JOBNAME=$PARAMETERS_STRING'_'$BETA_PREFIX$BETA
    local JOBID_ARRAY=( $(llq -u $(whoami) | grep -o "juqueen[[:alnum:]]\{3\}\.[[:digit:]]\+\.[[:digit:]]") )
    for JOBID in ${JOBID_ARRAY[@]}; do
	local GREPPED_JOBNAME=$(llq -l $JOBID | grep "Job Name:" | sed "s/^.*Job Name: \(muiPiT.*$\)/\1/")
	if [ $GREPPED_JOBNAME = $JOBNAME ]; then
	    printf "\e[0;31m Job with name $JOBNAME seems to be already running with id $JOBID.\n"
	    printf " Job cannot be continued...\n\n\e[0m"
	    return 0
	fi
    done
    return 1
}

function ProcessBetaValuesForContinue_Juqueen() {
    for BETA in ${BETAVALUES[@]}; do
     	#------------------------------------------------------------------------#
	local WORK_BETADIRECTORY="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$INPUTFILE_NAME"
	local OUTPUTFILE_GLOBALPATH="${WORK_BETADIRECTORY}/$OUTPUTFILE_NAME"
	#------------------------------------------------------------------------#
	
	if [ ! -f $INPUTFILE_GLOBALPATH ]; then
	    printf "\n\e[0;31m $INPUTFILE_GLOBALPATH does not exist.\n\e[0m"
	    printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
	    PROBLEM_BETA_ARRAY+=( $BETA )
	    continue
	fi
	
	echo ""
	__static__CheckIfJobIsInQueue_Juqueen
	if [ $? == 0 ]; then
	    PROBLEM_BETA_ARRAY+=( $BETA )
	    continue
	fi

        #----------------------------------------------------------------------------------#
	local JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA_PREFIX$BETA"
	local JOBSCRIPT_GLOBALPATH="${HOME_BETADIRECTORY}/$JOBSCRIPT_NAME"
        #----------------------------------------------------------------------------------#

	if [ ! -f $OUTPUTFILE_GLOBALPATH ]; then
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
	
	grep -q "^StartCondition = continue" $INPUTFILE_GLOBALPATH
	if [ $(echo $?) = 0 ]
	then 
	    StartCondition="continue" 
	else 
	    StartCondition="undefined" 
	fi
	
	grep -q "^InitialStoreCounter = readin" $INPUTFILE_GLOBALPATH
	
	if [ $(echo $?) = 0 ]
	then 
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
	
	if [ $CONTINUE_NUMBER -eq 0 ]
	then
	    TOTAL_NR_TRAJECTORIES=$(grep "^#[[:blank:]]\+Total[[:blank:]]\+number[[:blank:]]\+of[[:blank:]]\+trajectories" $INPUTFILE_GLOBALPATH | grep -o "=[[:blank:]]*[[:digit:]]\+[[:blank:]]*#*" | grep -o "[[:digit:]]\+")	
	else
	    TOTAL_NR_TRAJECTORIES=$CONTINUE_NUMBER
 	    sed -i "s/\(^#[[:blank:]]\+Total[[:blank:]]\+number[[:blank:]]\+of[[:blank:]]\+trajectories[[:blank:]]\+=[[:blank:]]*\)[[:digit:]]\+[[:blank:]]*#*.*/\1$TOTAL_NR_TRAJECTORIES/" $INPUTFILE_GLOBALPATH
	fi
	
	TRAJECTORIES_DONE=$(tail -n1 $OUTPUTFILE_GLOBALPATH | grep -o "^[[:digit:]]\+")
	TRAJECTORIES_DONE=$(expr $TRAJECTORIES_DONE + 1)
	MEASUREMENTS_REMAINING=$(expr $TOTAL_NR_TRAJECTORIES - $TRAJECTORIES_DONE)
	
	if [ $MEASUREMENTS_REMAINING -gt 0 ]
	then
	    sed -i "s/\(^Measurements.*$\)/#\1\nMeasurements = $MEASUREMENTS_REMAINING/" $INPUTFILE_GLOBALPATH
	    SUBMIT_BETA_ARRAY+=( $BETA )
	else
	    printf "\n\e[0;31m For beta = $BETA the difference between the total nr of trajectories and the trajectories already done\n\e[0m"
	    printf "\e[0;31m is smaller or equal to zero.\n\e[0m"
	    printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\e[0m"
	    PROBLEM_BETA_ARRAY+=( $BETA )
	    continue	
	fi
    done #loop on BETA
}

#=======================================================================================================================#

function ShowQueuedJobsLocal_Juqueen(){
    #TODO: Generalize user name
    printf "\n\e[0;36m==================================================================================================\n\e[0m"
    llq -W -f %id %jn %st %c %dq %dd %gl %h -u $(whoami) | awk --posix '$2 ~ /^muiPiT_'$KAPPA_PREFIX$KAPPA'_'$NTIME_PREFIX$NTIME'_'$NSPACE_PREFIX$NSPACE'_'$BETA_PREFIX'[[:digit:]]\.[[:digit:]]{4}$/ || NR <= 2 {print}'
    printf "\e[0;36m==================================================================================================\n\e[0m"
}

#=======================================================================================================================#

function SubmitJobsForValidBetaValues_Juqueen() {
    if [ ${#SUBMIT_BETA_ARRAY[@]} -gt "0" ]; then
	printf "\n\e[0;36m===================================================================================\n\e[0m"
	printf "\e[0;34m Jobs will be submitted for the following beta values:\n\e[0m"
	for BETA in ${SUBMIT_BETA_ARRAY[@]}; do
	    echo "  - $BETA"
	done
	
	for BETA in ${SUBMIT_BETA_ARRAY[@]}; do
	    local SUBMITTING_DIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	    local JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA_PREFIX$BETA"
	    cd $SUBMITTING_DIRECTORY
	    printf "\n\e[0;34m Actual location: \e[0;35m$(pwd) \n\e[0m"
	    printf "\e[0;34m      Submitting:\e[0m"
	    printf "\e[0;32m \e[4mllsubmit $JOBSCRIPT_NAME\n\e[0m"
	    llsubmit $JOBSCRIPT_NAME
	done
	printf "\n\e[0;36m===================================================================================\n\e[0m"
    else
	printf " \e[1;37;41mNo jobs will be submitted.\e[0m\n"
    fi
}

#=======================================================================================================================#