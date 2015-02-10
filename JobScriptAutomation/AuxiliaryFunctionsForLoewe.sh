# Collection of function needed in the job handler script (mostly in AuxiliaryFunctions).

function ProduceInputFileAndJobScriptForEachBeta_Loewe(){
    #---------------------------------------------------------------------------------------------------------------------#
    #NOTE: Since this function has to iterate over the betas either doing something and putting the value into
    #      SUBMIT_BETA_ARRAY or putting the beta value into PROBLEM_BETA_ARRAY, it is better to make a local copy
    #      of BETAVALUES in order not to alter the original global array. Actually on the LOEWE the jobs are packed
    #      and this implies that whenever a problematic beta is encoutered it MUST be removed from the betavalues array
    #      (otherwise the authomatic packing would fail in the sense that it would include a problematic beta).
    local BETAVALUES_COPY=(${BETAVALUES[@]})
    #---------------------------------------------------------------------------------------------------------------------#
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
    BETAVALUES_COPY=(${BETAVALUES_COPY[@]}) #If sparse, make it not sparse 
    #If the previous for loop went through, we create the beta folders (just to avoid to create some folders and then abort)
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
	    printf "\e[0;36m    No thermalized configuration to be copied for beta = ${BETAVALUES_COPY[$BETA]}, HOT start!\n\e[0m"
	fi
	    #Call the file to produce the input file
	local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$INPUTFILE_NAME"
	. $PRODUCEINPUTFILESH	    
    done
    # Partition the BETAVALUES_COPY array into group of GPU_PER_NODE and create the JobScript files inside the JOBSCRIPT_FOLDER
    mkdir -p ${HOME_DIR_WITH_BETAFOLDERS}/$JOBSCRIPT_LOCALFOLDER || exit -2
    BETAVALUES_COPY=(${BETAVALUES_COPY[@]}) #If sparse, make it not sparse otherwise the following while doesn't work!!
    printf "\n\e[0;36m=================================================\n\e[0m"
    printf "\e[0;36m  The following beta values have been grouped:\e[0m\n"
    while [[ "${!BETAVALUES_COPY[@]}" != "" ]]; do # ${!array[@]} gives the list of the valid indeces in the array
	local BETA_FOR_JOBSCRIPT=(${BETAVALUES_COPY[@]:0:$GPU_PER_NODE})
	BETAVALUES_COPY=(${BETAVALUES_COPY[@]:$GPU_PER_NODE})
	local BETAS_STRING=""
	for BETA in "${!BETA_FOR_JOBSCRIPT[@]}"; do
	    printf "     ${BETA_FOR_JOBSCRIPT[BETA]}"
	    BETAS_STRING="${BETAS_STRING}_$BETA_PREFIX${BETA_FOR_JOBSCRIPT[BETA]}"
	done
	echo ""
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
	    printf "\n\e[0;31m Jobscript \"$JOBSCRIPT_NAME\" failed to be created!\n\n\e[0m"
	    PROBLEM_BETA_ARRAY+=( "${BETAS_STRING:1}" )
	fi
    done
    printf "\e[0;36m=================================================\n\e[0m"	
}

#=======================================================================================================================#

function ProcessBetaValuesForSubmitOnly_Loewe() {
    #-----------------------------------------#
    local BETAVALUES_COPY=(${BETAVALUES[@]})
    #-----------------------------------------#
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
    printf "\n\e[0;36m=================================================\n\e[0m"
    printf "\e[0;36m  The following beta values have been grouped:\e[0m\n"
    while [[ "${!BETAVALUES_COPY[@]}" != "" ]]; do # ${!array[@]} gives the list of the valid indeces in the array
	local BETA_FOR_JOBSCRIPT=(${BETAVALUES_COPY[@]:0:$GPU_PER_NODE})
	BETAVALUES_COPY=(${BETAVALUES_COPY[@]:$GPU_PER_NODE})
	local BETAS_STRING=""
	for BETA in "${!BETA_FOR_JOBSCRIPT[@]}"; do
	    printf "     ${BETA_FOR_JOBSCRIPT[BETA]}"
	    BETAS_STRING="${BETAS_STRING}_$BETA_PREFIX${BETA_FOR_JOBSCRIPT[BETA]}"
	done
	echo ""
	local JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_${BETAS_STRING:1}"
	local JOBSCRIPT_GLOBALPATH="${HOME_DIR_WITH_BETAFOLDERS}/$JOBSCRIPT_LOCALFOLDER/$JOBSCRIPT_NAME"
	if [ ! -e $JOBSCRIPT_GLOBALPATH ]; then
	    printf "\n\e[0;31m Jobscript \"$JOBSCRIPT_NAME\" not found! It will be not submitted!!!\n\n\e[0m"
	    PROBLEM_BETA_ARRAY+=( "${BETAS_STRING:1}" )
	else
	    SUBMIT_BETA_ARRAY+=( "${BETAS_STRING:1}" )
	fi
    done
    printf "\e[0;36m=================================================\n\e[0m"
}

#=======================================================================================================================#

function __static__CheckIfJobIsInQueue_Loewe(){
    local JOBID_ARRAY=( $(squeue | awk 'NR>1{print $1}') )
    for JOBID in ${JOBID_ARRAY[@]}; do
	local GREPPED_JOBNAME=$(scontrol show job  $JOBID | grep "Name=" | sed "s/^.*Name=\(.*$\)/\1/") 
	local JOBSTATUS=$(scontrol show job $JOBID | grep "^[[:blank:]]*JobState=" | sed "s/^.*JobState=\([[:alpha:]]*\)[[:blank:]].*$/\1/")
	
	if [[ ! $GREPPED_JOBNAME =~ b[[:digit:]]{1}[.]{1}[[:digit:]]{4}$ ]]; then
	    continue
	fi
	
	if [ $(echo $GREPPED_JOBNAME | grep -o "$BETA_PREFIX$BETA" | wc -l) -ne 0 ] && [ $(echo $GREPPED_JOBNAME | grep -o "$PARAMETERS_STRING" | wc -l) -ne 0 ]; then
	    
	    if [ "$JOBSTATUS" != "RUNNING" -a "$JOBSTATUS" != "PENDING" ]; then
		continue;
	    fi
	    
	    printf "\e[0;31m Job with name $JOBNAME seems to be already running with id $JOBID.\n"
	    printf " Job cannot be continued...\n\n\e[0m"
	    return 0
	fi
    done
    return 1
}

#This function must be called with 3 parameters: filename (global path), string to be found, replace string
function __static__FindAndReplaceSingleOccurenceInFile(){
    if [ $# -ne 3 ]; then
	printf "\n\e[0;31m The function __static__FindAndReplaceSingleOccurenceInFile() has been wrongly called! Aborting...\n\n\e[0m"
	exit -1
    elif [ ! -f $1 ]; then
	printf "\n\e[0;31m Error occurred in __static__FindAndReplaceSingleOccurenceInFile(): file $1 has not been found! Aborting...\n\n\e[0m"
	exit -1
    elif [ $(grep -o "$2" $1 | wc -l) -ne 1 ]; then
	printf "\n\e[0;31m Error occurred in __static__FindAndReplaceSingleOccurenceInFile(): string $2 occurs 0 times or more than 1 time in file $1! Skipping beta = $BETA .\n\n\e[0m"
	PROBLEM_BETA_ARRAY+=( $BETA )
	return 1
    fi

    sed -i "s/$2/$3/g" $1 || exit 2

    return 0
    
}

function __static__ModifyOptionInInputFile(){
    if [ $# -ne 1 ]; then
	printf "\n\e[0;31m The function __static__ModifyOptionInInputFile() has been wrongly called! Aborting...\n\n\e[0m"
	exit -1
    fi
    
    case $1 in

	startcondition=* )        __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "startcondition=[[:alpha:]]\+" "startcondition=${1#*=}" ;;
	sourcefile=* )            __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "sourcefile=[[:alnum:][:punct:]]*" "sourcefile=${1#*=}" ;;
	initial_prng_state=* )    __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "initial_prng_state=[[:alnum:][:punct:]]*" "initial_prng_state=${1#*=}" ;;
	host_seed=* )             __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "host_seed=[[:digit:]]\+" "host_seed=${1#*=}" ;;
	intsteps0=* )             __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "integrationsteps0=[[:digit:]]\+" "integrationsteps0=${1#*=}" ;;
	intsteps1=* )             __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "integrationsteps1=[[:digit:]]\+" "integrationsteps1=${1#*=}" ;;
	nsave=* )                 __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "savefrequency=[[:digit:]]\+" "savefrequency=${1#*=}" ;;
	measurements=* )          __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "hmcsteps=[[:digit:]]\+" "hmcsteps=${1#*=}" ;;
        measure_pbp=* )           __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "measure_pbp=[[:digit:]]\+" "measure_pbp=${1#*=}" ;;

        * ) printf "\n\e[0;31m The option \"$1\" cannot be handled in the continue scenario.\n\e[0m"
        printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
        PROBLEM_BETA_ARRAY+=( $BETA )
	return 1
    esac

    return $?
}



function ProcessBetaValuesForContinue_Loewe() {
    local LOCAL_SUBMIT_BETA_ARRAY=()
    #Remove --continue option from command line
    for INDEX in "${!SPECIFIED_COMMAND_LINE_OPTIONS[@]}"; do
	if [[ "${SPECIFIED_COMMAND_LINE_OPTIONS[$INDEX]}" == --continue* ]]; then
	    unset SPECIFIED_COMMAND_LINE_OPTIONS[$INDEX]
	    SPECIFIED_COMMAND_LINE_OPTIONS=( "${SPECIFIED_COMMAND_LINE_OPTIONS[@]}" )
	fi
    done

    for BETA in ${BETAVALUES[@]}; do
     	#-------------------------------------------------------------------------#
	local WORK_BETADIRECTORY="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$INPUTFILE_NAME"
	local OUTPUTFILE_GLOBALPATH="${WORK_BETADIRECTORY}/$OUTPUTFILE_NAME"
        local BETAVALUES_COPY=(${BETAVALUES[@]})
	#-------------------------------------------------------------------------#
	
	if [ ! -f $INPUTFILE_GLOBALPATH ]; then
	    printf "\n\e[0;31m $INPUTFILE_GLOBALPATH does not exist.\n\e[0m"
	    printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
	    PROBLEM_BETA_ARRAY+=( $BETA )
	    continue
	fi
	
	echo ""
	__static__CheckIfJobIsInQueue_Loewe
	if [ $? == 0 ]; then
	    PROBLEM_BETA_ARRAY+=( $BETA )
	    continue
	fi

	#If the option resumefrom is given in the betasfile we have to clean the $WORK_BETADIRECTORY, otherwise just set the name of conf and prng
	if KeyInArray $BETA CONTINUE_RESUMETRAJ_ARRAY; then
	    printf "\e[0;35m\e[1m\e[4mATTENTION\e[24m: The simulation for beta = $BETA will be resumed from trajectory"
	    printf " ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}. Is it what you would like to do (Y/N)? \e[0m"
	    local CONFIRM="";
	    while read CONFIRM; do
		if [ "$CONFIRM" = "Y" ]; then
		    break;
		elif [ "$CONFIRM" = "N" ]; then
		    printf "\n\e[1;31m Leaving out beta = $BETA\e[0m\n\n"
		    continue 2
		else
		    printf "\e[0;36m\e[1m Please enter Y (yes) or N (no): \e[0m"
		fi
	    done
	    #If the user wants to resume from a given trajectory, first check that the conf is available
	    if [ -f $WORK_BETADIRECTORY/$(printf "conf.%05d" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}") ];then
		local NAME_LAST_CONFIGURATION=$(printf "conf.%05d" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}")
	    else
		printf "\e[0;31m Configuration \"$(printf "conf.%05d" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}")\""
		printf " or prng status \"$(printf "prng.%05d" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}")\" not found in $WORK_BETADIRECTORY folder.\n"
		printf " Unable to continue the simulation. Leaving out beta = $BETA .\n\n\e[0m" 
		PROBLEM_BETA_ARRAY+=( $BETA ) 
		continue
	    fi
	    if [ -f $WORK_BETADIRECTORY/$(printf "prng.%05d" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}") ]; then
		local NAME_LAST_PRNG=$(printf "prng.%05d" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}")
	    else
		local NAME_LAST_PRNG="" #If the prng.xxxxx is not found, use random seed
	    fi
	    #If the OUTPUTFILE_NAME is not in the WORK_BETADIRECTORY stop and not do anything
	    if [ ! -f $OUTPUTFILE_GLOBALPATH ]; then 
		printf "\e[0;31m File \"$OUTPUTFILE_NAME\" not found in $WORK_BETADIRECTORY folder.\n"
		printf " Unable to continue the simulation from trajectory. Leaving out beta = $BETA .\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
		continue
	    fi
	    #Now it should be feasable to resume simulation ---> clean WORK_BETADIRECTORY
	    #Create in WORK_BETADIRECTORY a folder named Trash_$(date) where to mv all the file produced after the traj. ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}
	    local TRASH_NAME="$WORK_BETADIRECTORY/Trash_$(date +'%F_%H%M')"
	    mkdir $TRASH_NAME || exit 2
	    for FILE in $WORK_BETADIRECTORY/conf.* $WORK_BETADIRECTORY/prng.*; do
		#Move to trash only conf.xxxxx prng.xxxxx files or conf.xxxxx_pbp.dat files where xxxxx are digits
		local NUMBER_FROM_FILE=$(echo "$FILE" | grep -o "\(\(conf.\)\|\(prng.\)\)[[:digit:]]\{5\}\(_pbp.dat\)\?$" | sed 's/\(\(conf.\)\|\(prng.\)\)\([[:digit:]]\+\).*/\4/' | sed 's/^0*//')
		if [ "$NUMBER_FROM_FILE" != "" ] && [ $NUMBER_FROM_FILE -gt ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]} ]; then
		    mv $FILE $TRASH_NAME
		fi
	    done
	    #Move to trash conf.save and prng.save files if existing
	    if [ -f $WORK_BETADIRECTORY/conf.save ]; then mv $WORK_BETADIRECTORY/conf.save $TRASH_NAME; fi
	    if [ -f $WORK_BETADIRECTORY/prng.save ]; then mv $WORK_BETADIRECTORY/prng.save $TRASH_NAME; fi
	    #Copy the hmc_output file to Trash and edit it leaving out all the trajectories after ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}
	    cp $OUTPUTFILE_GLOBALPATH $TRASH_NAME || exit 2 
	    local LINES_TO_BE_CANCELED_IN_OUTPUTFILE=$(tac $OUTPUTFILE_GLOBALPATH | awk -v resumeFrom=${CONTINUE_RESUMETRAJ_ARRAY[$BETA]} 'BEGIN{found=0}{if($1==resumeFrom){found=1; print NR; exit}}END{if(found==0){print -1}}')
	    if [ $LINES_TO_BE_CANCELED_IN_OUTPUTFILE -eq -1 ]; then
		printf "\n\e[0;31m Measurement for trajectory ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]} not found in outputfile.\n\e[0m"
		printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
		continue
	    fi
	    #The -1 in the following line is not a typo, it has to be -1 since the number was recovered with tac backwards
	    head -n -$(($LINES_TO_BE_CANCELED_IN_OUTPUTFILE-1)) $OUTPUTFILE_GLOBALPATH > ${OUTPUTFILE_GLOBALPATH}.temporaryCopyThatHopefullyDoesNotExist || exit 2
	    mv ${OUTPUTFILE_GLOBALPATH}.temporaryCopyThatHopefullyDoesNotExist $OUTPUTFILE_GLOBALPATH || exit 2
	#If resumefrom has not been given in the betasfile check in the WORK_BETADIRECTORY if conf.save is present: if yes, use it, otherwise use the last checkpoint
	elif [ -f $WORK_BETADIRECTORY/conf.save ]; then
	    local NAME_LAST_CONFIGURATION="conf.save"
	    #If conf.save is found then prng.save should be there, if not I will use a random seed
	    if [ -f $WORK_BETADIRECTORY/prng.save ]; then
		local NAME_LAST_PRNG="prng.save"
	    else
		local NAME_LAST_PRNG=""
	    fi
	else
	    local NAME_LAST_CONFIGURATION=$(ls $WORK_BETADIRECTORY | grep -o "conf.[[:digit:]]\{5\}$" | tail -n1)
	    local NAME_LAST_PRNG=$(ls $WORK_BETADIRECTORY | grep -o "prng.[[:digit:]]\{5\}$" | tail -n1)
	fi
	
	#The variable NAME_LAST_CONFIGURATION should have been set above, if not it means no conf was available!
	if [ "$NAME_LAST_CONFIGURATION" == "" ]; then
	    printf "\n\e[0;31m No configuration found in $WORK_BETADIRECTORY.\n\e[0m"
	    printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
	    PROBLEM_BETA_ARRAY+=( $BETA )
            continue
	fi
	if [ "$NAME_LAST_PRNG" == "" ]; then
	    printf "\n\e[0;33m \e[1m\e[4mWARNING\e[24m:\e[0;33m No prng state found in $WORK_BETADIRECTORY, using a random host_seed...\n\n\e[0m"
	fi
	#Check that, in case the continue is done from a "numeric" configuration, the number of conf and prng is the same
	if [ "$NAME_LAST_CONFIGURATION" != "conf.save" ] && [ "$NAME_LAST_PRNG" != "prng.save" ] && [ "$NAME_LAST_PRNG" != "" ]; then
	    if [ `echo ${NAME_LAST_CONFIGURATION#*.} | sed 's/^0*//g'` -ne `echo ${NAME_LAST_PRNG#*.} | sed 's/^0*//g'` ]; then
		printf "\n\e[0;31m The numbers of conf.xxxxx and prng.xxxxx are different! Check the respective folder!!\n\e[0m"
                printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
                PROBLEM_BETA_ARRAY+=( $BETA )
                continue
	    fi
	fi
	
	if [ -f $HOME_BETADIRECTORY/$NAME_LAST_CONFIGURATION ]; then
	    mv $HOME_BETADIRECTORY/$NAME_LAST_CONFIGURATION $HOME_BETADIRECTORY/${NAME_LAST_CONFIGURATION}_$(date +'%F_%H.%M') || exit 2
	fi
	if [ -f $HOME_BETADIRECTORY/$NAME_LAST_PRNG ]; then
	    mv $HOME_BETADIRECTORY/$NAME_LAST_PRNG $HOME_BETADIRECTORY/${NAME_LAST_PRNG}_$(date +'%F_%H.%M') || exit 2
	fi
	cp $WORK_BETADIRECTORY/$NAME_LAST_CONFIGURATION $HOME_BETADIRECTORY || exit 2
	if [ "$NAME_LAST_PRNG" != "" ]; then
	    cp $WORK_BETADIRECTORY/$NAME_LAST_PRNG $HOME_BETADIRECTORY || exit 2
	fi
	
	#Make a temporary copy of the input file that will be used to restore in case the original input file.
	#This is to avoid to modify some parameters and then skip beta because of some error leaving the input file modified!
	#If the beta is skipped this temporary file is used to restore the original input file, otherwise it is deleted.
	ORIGINAL_INPUTFILE_GLOBALPATH="${INPUTFILE_GLOBALPATH}_original"
	cp $INPUTFILE_GLOBALPATH $ORIGINAL_INPUTFILE_GLOBALPATH || exit 2
	#If the option --pbp=1 has been given, check and in case add to input file relative piece
	for INDEX in "${!SPECIFIED_COMMAND_LINE_OPTIONS[@]}"; do
	    if [[ "${SPECIFIED_COMMAND_LINE_OPTIONS[$INDEX]}" == --pbp* ]]; then
		if [ $(grep -o "measure_pbp" $INPUTFILE_GLOBALPATH | wc -l) -eq 0 ]; then
		    echo "measure_pbp=$MEASURE_PBP" >> $INPUTFILE_GLOBALPATH
		    if  [ $(grep -o "sourcetype" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] || [ $(grep -o "sourcecontent" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] ||
			[ $(grep -o "num_sources" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ]; then
			printf "\e[0;31m The option \"measure_pbp\" is not present in the input file but one or more specification about how to calculate\n"
			printf " the chiral condensate are present. Suspicious situation, investigate! Skipping beta = $BETA .\n\n\e[0m"
			PROBLEM_BETA_ARRAY+=( $BETA )
			mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue 2
		    else
			echo "sourcetype=volume" >> $INPUTFILE_GLOBALPATH
			echo "sourcecontent=gaussian" >> $INPUTFILE_GLOBALPATH
			echo "num_sources=16" >> $INPUTFILE_GLOBALPATH
		    fi
		    printf "\e[0;32m Added options \e[0;35mmeasure_pbp=$MEASURE_PBP\n"
		    printf "\e[0;32m               \e[0;35msourcetype=volume\n"
		    printf "\e[0;32m               \e[0;35msourcecontent=gaussian\n"
		    printf "\e[0;32m               \e[0;35mnum_sources=16"
		    printf "\e[0;32m to the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
		else
		    __static__ModifyOptionInInputFile "measure_pbp=$MEASURE_PBP"
		    printf "\e[0;32m Set option \e[0;35mmeasure_pbp=$MEASURE_PBP"
		    printf "\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
		fi
	    fi
	done
	#For each command line option, modify it in the inputfile.
	#
	#If CONTINUE_NUMBER is given, set automatically the number of remaining measurements.
	# NOTE: If --measurements=... is (also) given, then --measurements will be used!
	if [ $CONTINUE_NUMBER -ne 0 ]; then
	    if [ -f $OUTPUTFILE_GLOBALPATH ]; then
		local NUMBER_DONE_TRAJECTORIES=$(awk 'END{print $1}' $OUTPUTFILE_GLOBALPATH)
	    else
		local NUMBER_DONE_TRAJECTORIES=0
	    fi
	    if [ $NUMBER_DONE_TRAJECTORIES -gt $CONTINUE_NUMBER ]; then
		printf "\e[0;31m From the output file $OUTPUTFILE_GLOBALPATH"
		printf "\n we got that the number of done measurements is $NUMBER_DONE_TRAJECTORIES > $CONTINUE_NUMBER = CONTINUE_NUMBER."
		printf "\n The option \"--continue=$CONTINUE_NUMBER\" cannot be applied. Skipping beta = $BETA .\n\n\e[0m"
                PROBLEM_BETA_ARRAY+=( $BETA )
                mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
	    fi
	    __static__ModifyOptionInInputFile "measurements=$(($CONTINUE_NUMBER - $NUMBER_DONE_TRAJECTORIES))"
	    [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
	    printf "\e[0;32m Set option \e[0;35mmeasurements=$(($CONTINUE_NUMBER - $NUMBER_DONE_TRAJECTORIES))"
	    printf "\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"		
	fi
	#Always convert startcondition in continue
	__static__ModifyOptionInInputFile "startcondition=continue"
	#If sourcefile not present in the input file, add it, otherwise modify it
	local NUMBER_OCCURENCE_SOURCEFILE=$(grep -o "sourcefile=[[:alnum:][:punct:]]*" $INPUTFILE_GLOBALPATH | wc -l)
	if [ $NUMBER_OCCURENCE_SOURCEFILE -eq 0 ]; then
	    echo "sourcefile=$HOME_BETADIRECTORY/${NAME_LAST_CONFIGURATION}" >> $INPUTFILE_GLOBALPATH
	    printf "\e[0;32m Added option \e[0;35msourcefile=$HOME_BETADIRECTORY/${NAME_LAST_CONFIGURATION}"
	    printf "\e[0;32m to the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
	elif [ $NUMBER_OCCURENCE_SOURCEFILE -eq 1 ]; then
	    __static__ModifyOptionInInputFile "sourcefile=$(echo $HOME_BETADIRECTORY | sed 's/\//\\\//g')\/$NAME_LAST_CONFIGURATION"
	    [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
	    printf "\e[0;32m Set option \e[0;35msourcefile=$HOME_BETADIRECTORY/${NAME_LAST_CONFIGURATION}"
	    printf "\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
	else
	    printf "\n\e[0;31m String sourcefile=[[:alnum:][:punct:]]* occurs more than 1 time in file $INPUTFILE_GLOBALPATH! Skipping beta = $BETA .\n\n\e[0m"
	    PROBLEM_BETA_ARRAY+=( $BETA )
	    mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
	fi
	#If we have a prng_state put it in the file, otherwise set a random host seed (using shuf, see shuf --hellp for info)
	local NUMBER_OCCURENCE_HOST_SEED=$(grep -o "host_seed=[[:digit:]]\{4\}" $INPUTFILE_GLOBALPATH | wc -l)
	local NUMBER_OCCURENCE_PRNG_STATE=$(grep -o "initial_prng_state=[[:alnum:][:punct:]]*" $INPUTFILE_GLOBALPATH | wc -l)
	if [ "$NAME_LAST_PRNG" == "" ]; then
	    if [ $NUMBER_OCCURENCE_PRNG_STATE -ne 0 ]; then
		sed -i '/initial_prng_state/d' $INPUTFILE_GLOBALPATH #If no prng valid state has been found, delete eventual line from input file with initial_prng_state
	    fi
	    if [ $NUMBER_OCCURENCE_HOST_SEED -eq 0 ]; then
		local HOST_SEED=`shuf -i 1000-9999 -n1`
		echo "host_seed=$HOST_SEED" >> $INPUTFILE_GLOBALPATH
		printf "\e[0;32m Added option \e[0;35mhost_seed=$HOST_SEED\e[0;32m to the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
	    elif [ $NUMBER_OCCURENCE_HOST_SEED -eq 1 ]; then
		local HOST_SEED=`shuf -i 1000-9999 -n1`
		__static__ModifyOptionInInputFile "host_seed=$HOST_SEED"
		[ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
		printf "\e[0;32m Set option \e[0;35mhost_seed=$HOST_SEED"
		printf "\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
	    else
		printf "\n\e[0;31m String host_seed=[[:digit:]]{4} occurs more than 1 time in file $INPUTFILE_GLOBALPATH! Skipping beta = $BETA .\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
		mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
	    fi
	else
	    if [ $NUMBER_OCCURENCE_HOST_SEED -ne 0 ]; then
                sed -i '/host_seed/d' $INPUTFILE_GLOBALPATH #If a prng valid state has been found, delete eventual line from input file with host_seed
            fi
	    if [ $NUMBER_OCCURENCE_PRNG_STATE -eq 0 ]; then
		echo "initial_prng_state=$HOME_BETADIRECTORY/${NAME_LAST_PRNG}" >> $INPUTFILE_GLOBALPATH
		printf "\e[0;32m Added option \e[0;35minitial_prng_state=$HOME_BETADIRECTORY/${NAME_LAST_PRNG}"
		printf "\e[0;32m to the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
	    elif [ $NUMBER_OCCURENCE_PRNG_STATE -eq 1 ]; then
		__static__ModifyOptionInInputFile "initial_prng_state=$(echo $HOME_BETADIRECTORY | sed 's/\//\\\//g')\/${NAME_LAST_PRNG}"
		[ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
		printf "\e[0;32m Set option \e[0;35minitial_prng_state=$HOME_BETADIRECTORY/${NAME_LAST_PRNG}"
		printf "\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
	    else
		printf "\n\e[0;31m String initial_prng_state=[[:alnum:][:punct:]]* occurs more than 1 time in file $INPUTFILE_GLOBALPATH! Skipping beta = $BETA .\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
		mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
	    fi
	fi
	#Always set the integrator steps, that could have been given or not
	__static__ModifyOptionInInputFile "intsteps0=${INTSTEPS0_ARRAY[$BETA]}"
	printf "\e[0;32m Set option \e[0;35mintsteps0=${INTSTEPS0_ARRAY[$BETA]}"
        printf "\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
	__static__ModifyOptionInInputFile "intsteps1=${INTSTEPS1_ARRAY[$BETA]}"
	printf "\e[0;32m Set option \e[0;35mintsteps1=${INTSTEPS1_ARRAY[$BETA]}"
        printf "\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
	#Modify remaining command line specified options
	for OPT in ${SPECIFIED_COMMAND_LINE_OPTIONS[@]}; do
	    if [[ "$OPT" != --walltime* ]] && [[ "$OPT" != --pbp* ]] && [[ "$OPT" != --intsteps0* ]] && [[ "$OPT" != --intsteps1* ]]; then
		__static__ModifyOptionInInputFile ${OPT#"--"*}
		[ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue 2
		printf "\e[0;32m Set option \e[0;35m$OPT\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
	    fi
	done
	
	#If the script runs fine and it arrives here, it means no bash continue command was done --> we can add BETA to the jobs to be submitted
	rm $ORIGINAL_INPUTFILE_GLOBALPATH
	LOCAL_SUBMIT_BETA_ARRAY+=( $BETA )
	
    done #loop on BETA

    #Partition of the LOCAL_SUBMIT_BETA_ARRAY into group of GPU_PER_NODE and create the JobScript files inside the JOBSCRIPT_FOLDER
    mkdir -p ${HOME_DIR_WITH_BETAFOLDERS}/$JOBSCRIPT_LOCALFOLDER || exit -2
    LOCAL_SUBMIT_BETA_ARRAY=(${LOCAL_SUBMIT_BETA_ARRAY[@]}) #If sparse, make it not sparse otherwise the following while doesn't work!!
    printf "\n\e[0;36m=================================================\n\e[0m"
    printf "\e[0;36m  The following beta values have been grouped:\e[0m\n"
    while [[ "${!LOCAL_SUBMIT_BETA_ARRAY[@]}" != "" ]]; do # ${!array[@]} gives the list of the valid indeces in the array
	local BETA_FOR_JOBSCRIPT=(${LOCAL_SUBMIT_BETA_ARRAY[@]:0:$GPU_PER_NODE})
	LOCAL_SUBMIT_BETA_ARRAY=(${LOCAL_SUBMIT_BETA_ARRAY[@]:$GPU_PER_NODE})
	local BETAS_STRING=""
	for BETA in "${!BETA_FOR_JOBSCRIPT[@]}"; do
	    printf "     ${BETA_FOR_JOBSCRIPT[BETA]}"
	    BETAS_STRING="${BETAS_STRING}_$BETA_PREFIX${BETA_FOR_JOBSCRIPT[BETA]}"
	done
	echo ""
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
	    printf "\n\e[0;31m Jobscript \"$JOBSCRIPT_NAME\" failed to be created!\n\n\e[0m"
	    PROBLEM_BETA_ARRAY+=( "${BETAS_STRING:1}" )
	fi
    done
    printf "\e[0;36m=================================================\n\e[0m"
    
    #Ask the user if he want to continue submitting job
    printf "\n\e[0;33m Check if the continue option did its job correctly. Would you like to submit the jobs (Y/N)? \e[0m"
    local CONFIRM="";
    while read CONFIRM; do
	if [ "$CONFIRM" = "Y" ]; then
	    break;
	elif [ "$CONFIRM" = "N" ]; then
	    printf "\n\e[1;37;41mNo jobs will be submitted.\e[0m\n\n"
	    exit
	else
	    printf "\n\e[0;33m Please enter Y (yes) or N (no): \e[0m"
	fi
    done
}

#=======================================================================================================================#

function SubmitJobsForValidBetaValues_Loewe() {
    if [ ${#SUBMIT_BETA_ARRAY[@]} -gt "0" ]; then
	printf "\n\e[0;36m===================================================================================\n\e[0m"
	printf "\e[0;34m Jobs will be submitted for the following beta values:\n\e[0m"
	for BETA in ${SUBMIT_BETA_ARRAY[@]}; do
	    echo "  - $BETA"
	done
	
	for BETA in ${SUBMIT_BETA_ARRAY[@]}; do
	    if [ "$CLUSTER_NAME" = "LOEWE" ]; then
		local TEMP_ARRAY=( $(echo $BETA | sed 's/_/ /g') )
		if [ ${#TEMP_ARRAY[@]} -ne $GPU_PER_NODE ]; then
		    printf "\n\e[0;33m \e[1m\e[4mWARNING\e[24m:\e[0;33m At least one job is being submitted with less than\n"
		    printf "          $GPU_PER_NODE runs inside. Would you like to submit in any case (Y/N)? \e[0m"
		    local CONFIRM="";
		    while read CONFIRM; do
			if [ "$CONFIRM" = "Y" ]; then
			    break;
			elif [ "$CONFIRM" = "N" ]; then
			    printf "\n\e[1;37;41mNo jobs will be submitted.\e[0m\n"
			    return
			else
			    printf "\n\e[0;33m Please enter Y (yes) or N (no): \e[0m"
			fi
		    done
		fi
	    fi
	done

	for BETA in ${SUBMIT_BETA_ARRAY[@]}; do
	    local SUBMITTING_DIRECTORY="${HOME_DIR_WITH_BETAFOLDERS}/$JOBSCRIPT_LOCALFOLDER"
	    local JOBSCRIPT_NAME="${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}_$BETA"
	    cd $SUBMITTING_DIRECTORY
	    printf "\n\e[0;34m Actual location: \e[0;35m$(pwd) \n\e[0m"
	    printf "\e[0;34m      Submitting:\e[0m"
		printf "\e[0;32m \e[4msbatch $JOBSCRIPT_NAME\n\e[0m"
		sbatch $JOBSCRIPT_NAME
	done
	printf "\n\e[0;36m===================================================================================\n\e[0m"
    else
	printf " \e[1;37;41mNo jobs will be submitted.\e[0m\n"
    fi
}

#=======================================================================================================================#

