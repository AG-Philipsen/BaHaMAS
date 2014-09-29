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
	
	#If we are on LOEWE, let us try to use a thermalized configuration
	if [ "$CLUSTER_NAME" = "LOEWE" ]; then
	    local STARTCONFIGURATION_NAME="conf.${PARAMETERS_STRING}_$BETA_PREFIX$BETA"
	    local NUMBER_OF_THERMALIZED_CONFIGURATIONS=$(ls $THERMALIZED_CONFIGURATIONS_PATH | grep "$STARTCONFIGURATION_NAME" | wc -l)
	    if [ $NUMBER_OF_THERMALIZED_CONFIGURATIONS -eq 0 ]; then
		local STARTCONDITION="hot"
	    elif [ $NUMBER_OF_THERMALIZED_CONFIGURATIONS -eq 1 ]; then
		local STARTCONDITION="continue"
		local CONFIGURATION_SOURCEFILE="$(ls $THERMALIZED_CONFIGURATIONS_PATH | grep "$STARTCONFIGURATION_NAME")"
		cp $THERMALIZED_CONFIGURATIONS_PATH/$CONFIGURATION_SOURCEFILE $HOME_BETADIRECTORY
	    elif [ $NUMBER_OF_THERMALIZED_CONFIGURATIONS -gt 1 ]; then
		printf "\n\e[0;31m There are more than one thermalized configuration for these parameters. The value beta = $BETA will be skipped!\n\e[0m"
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

	# Create a File in each new beta dir with the name format bx.xxx_created_d_m_y
	# From this file one can tell when a directory was created the first time
	if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then

		touch $HOME_BETADIRECTORY"/b"$BETA"/b"$BETA"_created_$(date +"%d_%m_%y")"
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
			if [ $(ls $HOME_BETADIRECTORY | wc -l) -eq 3 ] && [ $(ls $HOME_BETADIRECTORY | grep "conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA}*" | wc -l) -eq 1 ]; then
			    printf "\n\e[0;32m The simulation with beta = $BETA start from a thermalized configuration!\n\e[0m"
			else
			    printf "\n\e[0;31m There are already files in $HOME_BETADIRECTORY. The value beta = $BETA will be skipped!\n\n\e[0m"
			    PROBLEM_BETA_ARRAY+=( $BETA )
			    continue
			fi
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


function ListJobsStatus_local(){

	printf "\n\e[0;36m==================================================================================================\n\e[0m"

	printf "\n\e[0;34m%s  %s  %s\n" $KAPPA_PREFIX$KAPPA $NTIME_PREFIX$NTIME $NSPACE_PREFIX$NSPACE 
	printf "\n      %s  %s  %s\n" $KAPPA_PREFIX$KAPPA $NTIME_PREFIX$NTIME $NSPACE_PREFIX$NSPACE >> $JOBS_STATUS_FILE
	printf "\n  Beta     Traj. total / done     Status\n\e[0m"
	printf "  	Beta     Traj. total / done     Status\n" >> $JOBS_STATUS_FILE

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

			JOBS_STATUS_FILE="jobs_status_"$CHEMPOT_PREFIX$CHEMPOT"_"$KAPPA_PREFIX$KAPPA"_"$NTIME_PREFIX$NTIME"_"$NSPACE_PREFIX$NSPACE"_"$DATE".txt"
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
		echo "cat $LOCAL_FILE >> $JOBS_STATUS_FILE_GLOBAL"
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
