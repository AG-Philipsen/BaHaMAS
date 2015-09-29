# Load auxiliary bash files that will be used.
source $HOME/Script/JobScriptAutomation/ProduceInputFileForLoewe.sh || exit -2
source $HOME/Script/JobScriptAutomation/ProduceJobScriptForLoewe.sh || exit -2
#------------------------------------------------------------------------------------#

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
		printf "\n\e[0;31m There are already files in $HOME_BETADIRECTORY.\n The value beta = ${BETAVALUES_COPY[$BETA]} will be skipped!\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( ${BETAVALUES_COPY[$BETA]} )
		unset BETAVALUES_COPY[$BETA] #Here BETAVALUES_COPY becomes sparse
		continue
	    fi
	fi
    done
    #Make BETAVALUES_COPY not sparse
    BETAVALUES_COPY=(${BETAVALUES_COPY[@]})
    #If the previous for loop went through, we create the beta folders (just to avoid to create some folders and then abort)
    for INDEX in "${!BETAVALUES_COPY[@]}"; do
	local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX${BETAVALUES_COPY[$INDEX]}"
	printf "\e[0;34m Creating directory \e[1m$BETA_PREFIX${BETAVALUES_COPY[$INDEX]}\e[0;34m..."
        mkdir $HOME_BETADIRECTORY || exit -2
        printf "\e[0;34m done!\n\e[0m"
	printf "\e[0;36m   Configuration used: \"${STARTCONFIGURATION_GLOBALPATH[${BETAVALUES_COPY[$INDEX]}]}\"\n\e[0m"
	#Call the file to produce the input file
	local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$INPUTFILE_NAME"
	ProduceInputFile_Loewe
    done
    # Partition the BETAVALUES_COPY array into group of GPU_PER_NODE and create the JobScript files inside the JOBSCRIPT_FOLDER
    mkdir -p ${HOME_DIR_WITH_BETAFOLDERS}/$JOBSCRIPT_LOCALFOLDER || exit -2
    __static__PackBetaValuesPerGpuAndCreateJobScriptFiles "${BETAVALUES_COPY[@]}"
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
		# In the home betadirectory there should be ONLY the inputfile
		if [ $(ls $HOME_BETADIRECTORY | wc -l) -ne 1 ]; then
		    printf "\n\e[0;31m There are already files in $HOME_BETADIRECTORY beyond the input file."
		    printf " The value beta = ${BETAVALUES_COPY[$BETA]} will be skipped!\n\n\e[0m"
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
    __static__PackBetaValuesPerGpuAndCreateJobScriptFiles "${BETAVALUES_COPY[@]}"
}

#=======================================================================================================================#

function __static__CheckIfJobIsInQueue_Loewe(){
    local JOBID_ARRAY=( $(squeue | awk -v username="$(whoami)" 'NR>1{if($4 == username){print $1}}') )
    for JOBID in ${JOBID_ARRAY[@]}; do
        local GREPPED_JOBNAME=$(scontrol show job  $JOBID | grep "Name=" | sed "s/^.*Name=\(.*$\)/\1/") 
        local JOBSTATUS=$(scontrol show job $JOBID | grep "^[[:blank:]]*JobState=" | sed "s/^.*JobState=\([[:alpha:]]*\)[[:blank:]].*$/\1/")

        #if [[ ! $GREPPED_JOBNAME =~ b[[:digit:]]{1}[.]{1}[[:digit:]]{4}$ ]]; then
        #    continue
        #fi

        if [ $(echo $GREPPED_JOBNAME | grep -o "$BETA_PREFIX${BETA%%_*}" | wc -l) -ne 0 ] && 
           [ $(echo $GREPPED_JOBNAME | grep -o "$(echo $BETA | awk '{split($1, res, "_"); print res[2]}')" | wc -l) -ne 0 ] && 
           [ $(echo $GREPPED_JOBNAME | grep -o "$PARAMETERS_STRING" | wc -l) -ne 0 ]; then

            if [ "$JOBSTATUS" != "RUNNING" ] && [ "$JOBSTATUS" != "PENDING" ]; then
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
        printf "\n\e[0;31m Error occurred in __static__FindAndReplaceSingleOccurenceInFile(): string $2 occurs 0 times or more than 1 time in file\n $1! Skipping beta = $BETA .\n\n\e[0m"
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
        startcondition=* )                  __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "startcondition=[[:alpha:]]\+" "startcondition=${1#*=}" ;;
        sourcefile=* )                      __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "sourcefile=[[:alnum:][:punct:]]*" "sourcefile=${1#*=}" ;;
        initial_prng_state=* )              __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "initial_prng_state=[[:alnum:][:punct:]]*" "initial_prng_state=${1#*=}" ;;
        host_seed=* )                       __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "host_seed=[[:digit:]]\+" "host_seed=${1#*=}" ;;
        intsteps0=* )                       __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "integrationsteps0=[[:digit:]]\+" "integrationsteps0=${1#*=}" ;;
        intsteps1=* )                       __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "integrationsteps1=[[:digit:]]\+" "integrationsteps1=${1#*=}" ;;
        f=* | confSaveFrequency=* )         __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "savefrequency=[[:digit:]]\+" "savefrequency=${1#*=}" ;;
        F=* | confSavePointFrequency=* )    __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "savepointfrequency=[[:digit:]]\+" "savepointfrequency=${1#*=}" ;;
        m=* | measurements=* )              __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "hmcsteps=[[:digit:]]\+" "hmcsteps=${1#*=}" ;;
        measure_pbp=* )                     __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "measure_pbp=[[:digit:]]\+" "measure_pbp=${1#*=}" ;;
        use_mp=* )                          __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "use_mp=[[:digit:]]\+" "use_mp=${1#*=}" ;;
        kappa_mp=* )                        __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "kappa_mp=[[:digit:]]\+[.][[:digit:]]\+" "kappa_mp=${1#*=}" ;;
        intsteps2=* )                       __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "integrationsteps2=[[:digit:]]\+" "integrationsteps2=${1#*=}" ;;
        cg_iteration_block_size=* )         __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "cg_iteration_block_size=[[:digit:]]\+" "cg_iteration_block_size=${1#*=}" ;;
        num_timescales=* )                  __static__FindAndReplaceSingleOccurenceInFile $INPUTFILE_GLOBALPATH "num_timescales=[[:digit:]]\+" "num_timescales=${1#*=}" ;;

        * ) printf "\n\e[0;31m The option \"$1\" cannot be handled in the continue scenario.\n\e[0m"
            printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
            PROBLEM_BETA_ARRAY+=( $BETA )
            return 1
    esac

    return $?
}



function ProcessBetaValuesForContinue_Loewe() {
    local LOCAL_SUBMIT_BETA_ARRAY=()
    #Remove -c | --continue option from command line
    for INDEX in "${!SPECIFIED_COMMAND_LINE_OPTIONS[@]}"; do
        if [[ "${SPECIFIED_COMMAND_LINE_OPTIONS[$INDEX]}" == --continue* ]] || [[ "${SPECIFIED_COMMAND_LINE_OPTIONS[$INDEX]}" == -c* ]] ||
           [[ "${SPECIFIED_COMMAND_LINE_OPTIONS[$INDEX]}" == --continueThermalization* ]] || [[ "${SPECIFIED_COMMAND_LINE_OPTIONS[$INDEX]}" == -C* ]]; then
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
        #-------------------------------------------------------------------------#

        if [ ! -d $WORK_BETADIRECTORY ]; then
            printf "\n\e[0;31m Directory $WORK_BETADIRECTORY does not exist.\n\e[0m"
            printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
            PROBLEM_BETA_ARRAY+=( $BETA )
            continue
        fi

        if [ ! -d $HOME_BETADIRECTORY ]; then
            printf "\n\e[0;31m Directory $HOME_BETADIRECTORY does not exist.\n\e[0m"
            printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
            PROBLEM_BETA_ARRAY+=( $BETA )
            continue
        fi

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
            #If the user wishes to resume from the last avialable trajectory, then find here which number is "last"
            if [ ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]} = "last" ]; then
                CONTINUE_RESUMETRAJ_ARRAY[$BETA]=$(ls $WORK_BETADIRECTORY/conf.* | grep -o "/conf.[[:digit:]]\+$" | grep -o "[[:digit:]]\+" | sort -n | tail -n1 | sed 's/^0*//')
                if [[ ! ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]} =~ ^[[:digit:]]+$ ]]; then
                    printf "\e[0;31m Unable to find last configuration for resumefrom! Leaving out beta = $BETA .\n\n\e[0m"
                    PROBLEM_BETA_ARRAY+=( $BETA )
                    continue
                fi
            fi
            printf "\e[0;35m\e[1m\e[4mATTENTION\e[24m: The simulation for beta = ${BETA%_*} will be resumed from trajectory"
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
                printf "\e[0;31m Configuration \"$(printf "conf.%05d" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}") not found in $WORK_BETADIRECTORY folder.\n"
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
                local NUMBER_FROM_FILE=$(echo "$FILE" | grep -o "\(\(conf.\)\|\(prng.\)\)[[:digit:]]\+\(_pbp.dat\)\?$" | sed 's/\(\(conf.\)\|\(prng.\)\)\([[:digit:]]\+\).*/\4/' | sed 's/^0*//')
                if [ "$NUMBER_FROM_FILE" != "" ]; then
                    if [ $NUMBER_FROM_FILE -gt ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]} ]; then
                        mv $FILE $TRASH_NAME
                    elif [ $NUMBER_FROM_FILE -eq ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]} ] && [ $(echo "$FILE" | grep -o "conf[.][[:digit:]]\+_pbp[.]dat$" | wc -l) -eq 1 ]; then
                        mv $FILE $TRASH_NAME
                    fi
                fi
            done
            #Move to trash conf.save(_backup) and prng.save(_backup) files if existing
            if [ -f $WORK_BETADIRECTORY/conf.save ]; then mv $WORK_BETADIRECTORY/conf.save $TRASH_NAME; fi
            if [ -f $WORK_BETADIRECTORY/prng.save ]; then mv $WORK_BETADIRECTORY/prng.save $TRASH_NAME; fi
            if [ -f $WORK_BETADIRECTORY/conf.save_backup ]; then mv $WORK_BETADIRECTORY/conf.save_backup $TRASH_NAME; fi
            if [ -f $WORK_BETADIRECTORY/prng.save_backup ]; then mv $WORK_BETADIRECTORY/prng.save_backup $TRASH_NAME; fi
            #Copy the output file to Trash, edit it leaving out all the trajectories after ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}, including ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}
            cp $OUTPUTFILE_GLOBALPATH $TRASH_NAME || exit -2 
            local LINES_TO_BE_CANCELED_IN_OUTPUTFILE=$(tac $OUTPUTFILE_GLOBALPATH | awk -v resumeFrom=${CONTINUE_RESUMETRAJ_ARRAY[$BETA]} 'BEGIN{found=0}{if($1==(resumeFrom-1)){found=1; print NR-1; exit}}END{if(found==0){print -1}}')
            if [ $LINES_TO_BE_CANCELED_IN_OUTPUTFILE -eq -1 ]; then
                printf "\n\e[0;31m Measurement for trajectory ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]} not found in outputfile.\n\e[0m"
                printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\n\e[0m"
                PROBLEM_BETA_ARRAY+=( $BETA )
                continue
            fi
            #By doing head -n -$LINES_TO_BE_CANCELED_IN_OUTPUTFILE also the line with the number ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]} is deleted
            head -n -$LINES_TO_BE_CANCELED_IN_OUTPUTFILE $OUTPUTFILE_GLOBALPATH > ${OUTPUTFILE_GLOBALPATH}.temporaryCopyThatHopefullyDoesNotExist || exit -2
            mv ${OUTPUTFILE_GLOBALPATH}.temporaryCopyThatHopefullyDoesNotExist $OUTPUTFILE_GLOBALPATH || exit -2
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
            local NAME_LAST_CONFIGURATION=$(ls $WORK_BETADIRECTORY | grep -o "conf.[[:digit:]]\{5,6\}$" | sort -t '.' -k2n | tail -n1)
            local NAME_LAST_PRNG=$(ls $WORK_BETADIRECTORY | grep -o "prng.[[:digit:]]\{5,6\}$" | sort -t '.' -k2n | tail -n1)
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
        #Make a temporary copy of the input file that will be used to restore in case the original input file.
        #This is to avoid to modify some parameters and then skip beta because of some error leaving the input file modified!
        #If the beta is skipped this temporary file is used to restore the original input file, otherwise it is deleted.
        ORIGINAL_INPUTFILE_GLOBALPATH="${INPUTFILE_GLOBALPATH}_original"
        cp $INPUTFILE_GLOBALPATH $ORIGINAL_INPUTFILE_GLOBALPATH || exit -2
        #If the option -p | --doNotMeasurePbp has not been given, check the input file and in case act accordingly
        if [ $MEASURE_PBP = "FALSE" ]; then
            local MEASURE_PBP_VALUE_FOR_INPUTFILE=0
        elif [ $MEASURE_PBP = "TRUE" ]; then
            local MEASURE_PBP_VALUE_FOR_INPUTFILE=1
            #If the pbp file already exists non empty, append a line to it to be sure the prompt is at the beginning of a new line
            if [ -f ${OUTPUTFILE_GLOBALPATH}_pbp.dat ] && [ $(wc -l < ${OUTPUTFILE_GLOBALPATH}_pbp.dat) -ne 0 ]; then
                echo "" >> ${OUTPUTFILE_GLOBALPATH}_pbp.dat
            fi
        fi
        if [ $(grep -o "measure_pbp" $INPUTFILE_GLOBALPATH | wc -l) -eq 0 ]; then
            if  [ $(grep -o "sourcetype" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] ||
                [ $(grep -o "sourcecontent" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] ||
                [ $(grep -o "num_sources" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] ||
                [ $(grep -o "pbp_measurements" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] ||
                [ $(grep -o "ferm_obs_to_single_file" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] ||
                [ $(grep -o "ferm_obs_pbp_prefix" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ]; then
                printf "\e[0;31m The option \"measure_pbp\" is not present in the input file but one or more specification about how to calculate\n"
                printf " the chiral condensate are present. Suspicious situation, investigate! Skipping beta = $BETA .\n\n\e[0m"
                PROBLEM_BETA_ARRAY+=( $BETA )
                mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue 2
            fi
            echo "measure_pbp=$MEASURE_PBP_VALUE_FOR_INPUTFILE" >> $INPUTFILE_GLOBALPATH
            echo "sourcetype=volume" >> $INPUTFILE_GLOBALPATH
            echo "sourcecontent=gaussian" >> $INPUTFILE_GLOBALPATH
            if [ $WILSON = "TRUE" ]; then
                echo "num_sources=16" >> $INPUTFILE_GLOBALPATH
            elif [ $STAGGERED = "TRUE" ]; then
                echo "num_sources=1" >> $INPUTFILE_GLOBALPATH
                echo "pbp_measurements=16" >> $INPUTFILE_GLOBALPATH
                echo "ferm_obs_to_single_file=1" >> $INPUTFILE_GLOBALPATH
                echo "ferm_obs_pbp_prefix=${OUTPUTFILE_NAME}" >> $INPUTFILE_GLOBALPATH
            fi
            printf "\e[0;32m Added options \e[0;35mmeasure_pbp=$MEASURE_PBP_VALUE_FOR_INPUTFILE\n"
            printf "\e[0;32m               \e[0;35msourcetype=volume\n"
            printf "\e[0;32m               \e[0;35msourcecontent=gaussian\n"
            if [ $WILSON = "TRUE" ]; then
                printf "\e[0;32m               \e[0;35mnum_sources=16"
            else
                printf "\e[0;32m               \e[0;35mnum_sources=1\n"
                printf "\e[0;32m               \e[0;35mpbp_measurements=16\n"
                printf "\e[0;32m               \e[0;35mferm_obs_to_single_file=1\n"
                printf "\e[0;32m               \e[0;35mferm_obs_pbp_prefix=${OUTPUTFILE_NAME}"
            fi
            printf "\e[0;32m to the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
        else
            __static__ModifyOptionInInputFile "measure_pbp=$MEASURE_PBP_VALUE_FOR_INPUTFILE"
            [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
            printf "\e[0;32m Set option \e[0;35mmeasure_pbp=$MEASURE_PBP_VALUE_FOR_INPUTFILE"
            printf "\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
        fi
        
        if [ $WILSON = "TRUE" ]; then
            #If the option MP=() is given in the betasfile we have to do some work on the INPUTFILE to check if it was already given or not and act accordingly
            if KeyInArray $BETA MASS_PRECONDITIONING_ARRAY; then	
                case $(grep -o "use_mp" $INPUTFILE_GLOBALPATH | wc -l) in
                    0 ) 
                        if [ $(grep -o "solver_mp" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] || [ $(grep -o "kappa_mp" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] || 
                        [ $(grep -o "integrator2" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] || [ $(grep -o "integrationsteps2" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ]; then
                        printf "\e[0;31m The option \"use_mp\" is not present in the input file but one or more specification about how to use\n"
                        printf " mass preconditioning are present. Suspicious situation, investigate! Skipping beta = $BETA .\n\n\e[0m"
                        PROBLEM_BETA_ARRAY+=( $BETA )
                        mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        else
                        echo "use_mp=1" >> $INPUTFILE_GLOBALPATH
                        echo "solver_mp=cg" >> $INPUTFILE_GLOBALPATH
                        echo "kappa_mp=0.${MASS_PRECONDITIONING_ARRAY[$BETA]#*,}" >> $INPUTFILE_GLOBALPATH
                        echo "integrator2=twomn" >> $INPUTFILE_GLOBALPATH
                        echo "integrationsteps2=${MASS_PRECONDITIONING_ARRAY[$BETA]%,*}" >> $INPUTFILE_GLOBALPATH
                        printf "\e[0;32m Added options \e[0;35muse_mp=1\n"
                        printf "\e[0;32m               \e[0;35msolver_mp=cg\n"
                        printf "\e[0;32m               \e[0;35mkappa_mp=0.${MASS_PRECONDITIONING_ARRAY[$BETA]#*,}\n"
                        printf "\e[0;32m               \e[0;35mintegrator2=twomn\n"
                        printf "\e[0;32m               \e[0;35mintegrationsteps2=${MASS_PRECONDITIONING_ARRAY[$BETA]%,*}"
                        printf "\e[0;32m to the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
                        __static__ModifyOptionInInputFile "num_timescales=3"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        printf "\e[0;32m Set option \e[0;35mnum_timescales=3\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
                        __static__ModifyOptionInInputFile "cg_iteration_block_size=10"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        printf "\e[0;32m Set option \e[0;35mcg_iteration_block_size=10\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
                        fi
                        ;;
                    1 )
                        #Here I assume that the specifications for mass preconditioning are already in the input file and I just modify them!
                        __static__ModifyOptionInInputFile "use_mp=1"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        printf "\e[0;32m Set option \e[0;35muse_mp=1\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
                        __static__ModifyOptionInInputFile "kappa_mp=0.${MASS_PRECONDITIONING_ARRAY[$BETA]#*,}"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        printf "\e[0;32m Set option \e[0;35mkappa_mp=0.${MASS_PRECONDITIONING_ARRAY[$BETA]#*,}"
                        printf "\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
                        __static__ModifyOptionInInputFile "num_timescales=3"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        printf "\e[0;32m Set option \e[0;35mnum_timescales=3\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
                        __static__ModifyOptionInInputFile "intsteps2=${MASS_PRECONDITIONING_ARRAY[$BETA]%,*}"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        printf "\e[0;32m Set option \e[0;35mintsteps2=${MASS_PRECONDITIONING_ARRAY[$BETA]%,*}"
                        printf "\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
                        __static__ModifyOptionInInputFile "cg_iteration_block_size=10"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        printf "\e[0;32m Set option \e[0;35mcg_iteration_block_size=10\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
                        ;;
                    * ) 
                        printf "\n\e[0;31m String use_mp occurs more than 1 time in file $INPUTFILE_GLOBALPATH! Skipping beta = $BETA .\n\n\e[0m"
                        PROBLEM_BETA_ARRAY+=( $BETA )
                        mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        ;;
                esac
            else
                case $(grep -o "use_mp" $INPUTFILE_GLOBALPATH | wc -l) in
                    0 )
                        #Assume that no other option regarding mass preconditioning is in the file (it should be the case) and just continue
                        ;;
                    1 )
                        #Switch off the mass preconditioning and set timescales to 2, as well as the cg_iteration_block_size to 50
                        __static__ModifyOptionInInputFile "use_mp=0"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        printf "\e[0;32m Set option \e[0;35muse_mp=0\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
                        __static__ModifyOptionInInputFile "cg_iteration_block_size=50"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        printf "\e[0;32m Set option \e[0;35mcg_iteration_block_size=50\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
                        __static__ModifyOptionInInputFile "num_timescales=2"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        printf "\e[0;32m Set option \e[0;35mnum_timescales=2\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
                        ;;
                    * )
                        printf "\n\e[0;31m String use_mp occurs more than 1 time in file $INPUTFILE_GLOBALPATH! Skipping beta = $BETA .\n\n\e[0m"
                        PROBLEM_BETA_ARRAY+=( $BETA )
                        mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        ;;
                esac
            fi
        fi
        #For each command line option, modify it in the inputfile.
        #
        #If CONTINUE_NUMBER is given, set automatically the number of remaining measurements.
        # NOTE: If --measurements=... is (also) given, then --measurements will be used!
        #
        # ATTENTION: The ideal case is to recover the number of measurements done from the std. output of CL2QCD, and in particular
        #            from the trajectory stored in the last configuration saved. This is better than to use the output file since it
        #            could happen that the simulation is interrupted after having updated the output file but before having stored the
        #            actual configuration. In this case setting the number of measurements to be done using the output file would mean
        #            to do one trajectory less since the configuration from which the run would be resumed would be the last but one!!
        #            Nevertheless, doing so could lead to wrong number of measurements as well in the case in which the last standard
        #            output is wrong (for example: a simulation runs for 20k trajectories, it is stopped and by accident it is restarted
        #            from the beginning for 5k trajectorie; then the last standard output will give a wrong number of measurements).
        #            This case is left out here and it should be the user to avoid it.
        # 
        # NOTE: If the configuration from which we are starting, i.e. NAME_LAST_CONFIGURATION, contains digits then it is
        #       better to deduce the number of measurements to be done from there.
        #
        if [ $CONTINUE_NUMBER -ne 0 ]; then
            if [ $(grep -o "[[:digit:]]\+" <<< "$NAME_LAST_CONFIGURATION" | wc -l) -ne 0 ]; then
                local NUMBER_DONE_TRAJECTORIES=$(grep -o "[[:digit:]]\+" <<< "$NAME_LAST_CONFIGURATION" | sed 's/^0*//g')
            else
                local STDOUTPUT_FILE=`ls -lt $BETA_PREFIX$BETA | awk -v filename="$HMC_FILENAME" 'BEGIN{regexp="^"filename".[[:digit:]]+.out$"}{if($9 ~ regexp){print $9}}' | head -n1`
                local STDOUTPUT_GLOBALPATH="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA/$STDOUTPUT_FILE"
                if [ -f $STDOUTPUT_GLOBALPATH ] && [ $(grep "writing gaugefield at tr. [[:digit:]]\+" $STDOUTPUT_GLOBALPATH | wc -l) -ne 0 ]; then
                    local NUMBER_DONE_TRAJECTORIES=$(grep -o "writing gaugefield at tr. [[:digit:]]\+" $STDOUTPUT_GLOBALPATH | grep -o "[[:digit:]]\+" | tail -n1)
                    #If the simulation was resumed from a previous configuration, here NUMBER_DONE_TRAJECTORIES is wrong, correct it.
                    #Note than it is better to correct it with the following check rather than see if the simulation is beeing resumed,
                    #because sometimes a simulation is resumed but not submitted, and just continued later
                    if [ $NUMBER_DONE_TRAJECTORIES -gt $(awk 'END{print $1 + 1}' $OUTPUTFILE_GLOBALPATH) ]; then
                        NUMBER_DONE_TRAJECTORIES=$(awk 'END{print $1 + 1}' $OUTPUTFILE_GLOBALPATH)
                    fi
                elif [ -f $OUTPUTFILE_GLOBALPATH ]; then
                    local NUMBER_DONE_TRAJECTORIES=$(awk 'END{print $1 + 1}' $OUTPUTFILE_GLOBALPATH) #The +1 is here necessary because the first tr. is supposed to be the number 0.
                else
                    local NUMBER_DONE_TRAJECTORIES=0
                fi
            fi
            if [ $NUMBER_DONE_TRAJECTORIES -ge $CONTINUE_NUMBER ]; then
                printf "\e[0;31m We got that the number of done measurements is $NUMBER_DONE_TRAJECTORIES >= $CONTINUE_NUMBER = CONTINUE_NUMBER."
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
            echo "sourcefile=$WORK_BETADIRECTORY/${NAME_LAST_CONFIGURATION}" >> $INPUTFILE_GLOBALPATH
            printf "\e[0;32m Added option \e[0;35msourcefile=$WORK_BETADIRECTORY/${NAME_LAST_CONFIGURATION}"
            printf "\e[0;32m to the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
        elif [ $NUMBER_OCCURENCE_SOURCEFILE -eq 1 ]; then #In order to use __static__ModifyOptionInInputFile I have to escape the slashes in the path (for sed)
            __static__ModifyOptionInInputFile "sourcefile=$(echo $WORK_BETADIRECTORY | sed 's/\//\\\//g')\/$NAME_LAST_CONFIGURATION"
            [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
            printf "\e[0;32m Set option \e[0;35msourcefile=$WORK_BETADIRECTORY/${NAME_LAST_CONFIGURATION}"
            printf "\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
        else
            printf "\n\e[0;31m String sourcefile=[[:alnum:][:punct:]]* occurs more than 1 time in file $INPUTFILE_GLOBALPATH! Skipping beta = $BETA .\n\n\e[0m"
            PROBLEM_BETA_ARRAY+=( $BETA )
            mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
        fi
        #If we have a prng_state put it in the file, otherwise set a random host seed (using shuf, see shuf --help for info)
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
                echo "initial_prng_state=$WORK_BETADIRECTORY/${NAME_LAST_PRNG}" >> $INPUTFILE_GLOBALPATH
                printf "\e[0;32m Added option \e[0;35minitial_prng_state=$WORK_BETADIRECTORY/${NAME_LAST_PRNG}"
                printf "\e[0;32m to the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
            elif [ $NUMBER_OCCURENCE_PRNG_STATE -eq 1 ]; then #In order to use __static__ModifyOptionInInputFile I have to escape the slashes in the path (for sed)
                __static__ModifyOptionInInputFile "initial_prng_state=$(echo $WORK_BETADIRECTORY | sed 's/\//\\\//g')\/${NAME_LAST_PRNG}"
                [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                printf "\e[0;32m Set option \e[0;35minitial_prng_state=$WORK_BETADIRECTORY/${NAME_LAST_PRNG}"
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
        local EXCLUDE_COMMAND_LINE_OPTIONS=( "-u" "--useMultipleChains" "-w" "--walltime" "-p" "--doNotMeasurePbp" "--intsteps0" "--intsteps1" )
        for OPT in ${SPECIFIED_COMMAND_LINE_OPTIONS[@]}; do
            if ElementInArray ${OPT%"="*} ${EXCLUDE_COMMAND_LINE_OPTIONS[@]}; then
                continue
            fi
            __static__ModifyOptionInInputFile ${OPT##*"-"}
            [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue 2
            printf "\e[0;32m Set option \e[0;35m${OPT##*"-"}\e[0;32m into the \e[0;35m${INPUTFILE_GLOBALPATH#$(pwd)/}\e[0;32m file.\n\e[0m"
        done

        #If the script runs fine and it arrives here, it means no bash continue command was done --> we can add BETA to the jobs to be submitted
        rm $ORIGINAL_INPUTFILE_GLOBALPATH
        LOCAL_SUBMIT_BETA_ARRAY+=( $BETA )

    done #loop on BETA

    #Partition of the LOCAL_SUBMIT_BETA_ARRAY into group of GPU_PER_NODE and create the JobScript files inside the JOBSCRIPT_FOLDER
    mkdir -p ${HOME_DIR_WITH_BETAFOLDERS}/$JOBSCRIPT_LOCALFOLDER || exit -2
    __static__PackBetaValuesPerGpuAndCreateJobScriptFiles "${LOCAL_SUBMIT_BETA_ARRAY[@]}"

    #Ask the user if he want to continue submitting job
    printf "\n\e[0;33m Check if the continue option did its job correctly. Would you like to submit the jobs (Y/N)? \e[0m"
    local CONFIRM="";
    while read CONFIRM; do
        if [ "$CONFIRM" = "Y" ]; then
            break;
        elif [ "$CONFIRM" = "N" ]; then
            printf "\n\e[1;37;41mNo jobs will be submitted.\e[0m\n\n"
            exit 0;
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
	    if [ $USE_MULTIPLE_CHAINS == "FALSE" ]; then
		local PREFIX_TO_BE_GREPPED_FOR="$BETA_PREFIX"
	    else
		local PREFIX_TO_BE_GREPPED_FOR="$SEED_PREFIX"
	    fi
	    local TEMP_ARRAY=( $(echo $BETA | sed 's/_/ /g') )
	    if [ $(echo $BETA | grep -o "${PREFIX_TO_BE_GREPPED_FOR}\([[:digit:]][.]\)\?[[:alnum:]]\{4\}" | wc -l) -ne $GPU_PER_NODE ]; then
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
	done

	for BETA in ${SUBMIT_BETA_ARRAY[@]}; do
	    local SUBMITTING_DIRECTORY="${HOME_DIR_WITH_BETAFOLDERS}/$JOBSCRIPT_LOCALFOLDER"
	    local JOBSCRIPT_NAME="$(__static__GetJobScriptName ${BETA})"
	    cd $SUBMITTING_DIRECTORY
	    printf "\n\e[0;34m Actual location: \e[0;35m$(pwd) \n\e[0m"
	    printf "\e[1;34m      Submitting:\e[0m"
		printf "\e[0;32m \e[4msbatch $JOBSCRIPT_NAME\n\e[0m"
		sbatch $JOBSCRIPT_NAME
	done
	printf "\n\e[0;36m===================================================================================\n\e[0m"
    else
	printf " \e[1;37;41mNo jobs will be submitted.\e[0m\n"
    fi
}

#=======================================================================================================================#











#=======================================================================================================================#
#============================ STATIC FUNCTIONS USED MORE THAN IN ONE OTHER FUNCTION ====================================#
#=======================================================================================================================#

function __static__PackBetaValuesPerGpuAndCreateJobScriptFiles(){
    local BETAVALUES_ARRAY_TO_BE_SPLIT=( $@ )
    printf "\n\e[0;36m=================================================================================\n\e[0m"
    printf "\e[0;36m  The following beta values have been grouped (together with the seed if used):\e[0m\n"
    while [[ "${!BETAVALUES_ARRAY_TO_BE_SPLIT[@]}" != "" ]]; do # ${!array[@]} gives the list of the valid indeces in the array
	local BETA_FOR_JOBSCRIPT=(${BETAVALUES_ARRAY_TO_BE_SPLIT[@]:0:$GPU_PER_NODE})
	BETAVALUES_ARRAY_TO_BE_SPLIT=(${BETAVALUES_ARRAY_TO_BE_SPLIT[@]:$GPU_PER_NODE})
	printf "   ->"
	for BETA in "${BETA_FOR_JOBSCRIPT[@]}"; do
	    printf "    ${BETA_PREFIX}${BETA%_*}"
	done
	echo ""
	local BETAS_STRING="$(__static__GetJobBetasStringUsing ${BETA_FOR_JOBSCRIPT[@]})"
	local JOBSCRIPT_NAME="$(__static__GetJobScriptName ${BETAS_STRING})"
	local JOBSCRIPT_GLOBALPATH="${HOME_DIR_WITH_BETAFOLDERS}/$JOBSCRIPT_LOCALFOLDER/$JOBSCRIPT_NAME"
	if [ $SUBMITONLY = "FALSE" ]; then
	    if [ -e $JOBSCRIPT_GLOBALPATH ]; then
		mv $JOBSCRIPT_GLOBALPATH ${JOBSCRIPT_GLOBALPATH}_$(date +'%F_%H%M') || exit -2
	    fi
	    #Call the file to produce the jobscript file
	    ProduceJobscript_Loewe
	    if [ -e $JOBSCRIPT_GLOBALPATH ]; then
		SUBMIT_BETA_ARRAY+=( "${BETAS_STRING}" )
	    else
		printf "\n\e[0;31m Jobscript \"$JOBSCRIPT_NAME\" failed to be created!\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( "${BETAS_STRING}" )
		continue
	    fi
	else
	    if [ -e $JOBSCRIPT_GLOBALPATH ]; then
		SUBMIT_BETA_ARRAY+=( "${BETAS_STRING}" )
	    else
		printf "\n\e[0;31m Jobscript \"$JOBSCRIPT_NAME\" not existing with --submitonly option given!! Situation to be checked...\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( "${BETAS_STRING}" )
		continue
	    fi
	fi
    done
    printf "\e[0;36m=================================================================================\n\e[0m"
}


function __static__GetJobBetasStringUsing(){
    local BETAVALUES_TO_BE_USED=( $@ )
    declare -A BETAS_WITH_SEED
    for INDEX in "${BETAVALUES_TO_BE_USED[@]}"; do
	BETAS_WITH_SEED[${INDEX%%_*}]="${BETAS_WITH_SEED[${INDEX%%_*}]}_$(echo $INDEX | awk '{split($0, res, "_"); print res[2]}')"
    done
    local BETAS_STRING_TO_BE_RETURNED=""
    #Here I iterate again on BETAVALUES_TO_BE_USED and not on ${!BETAS_WITH_SEED[@]} in order to guarantee an order in BETAS_STRING
    #(remember that associative arrays keys are not sorted in general, if it is, it is by coincidence). Note that now I have to use
    #the same BETA only once and this is easily achieved unsetting the BETAS_WITH_SEED array entry once used it
    for BETA in "${BETAVALUES_TO_BE_USED[@]}"; do
	BETA=${BETA%%_*}
	if KeyInArray $BETA BETAS_WITH_SEED; then
	    BETAS_STRING_TO_BE_RETURNED="${BETAS_STRING_TO_BE_RETURNED}__${BETA_PREFIX}${BETA}${BETAS_WITH_SEED[${BETA}]}"
     	    unset 'BETAS_WITH_SEED[${BETA}]'
	fi
    done
    if [ $USE_MULTIPLE_CHAINS == "FALSE" ]; then
	BETAS_STRING_TO_BE_RETURNED="$( echo ${BETAS_STRING_TO_BE_RETURNED} | sed -e 's/___/_/g' -e 's/_$//')"
    fi

    echo "${BETAS_STRING_TO_BE_RETURNED:2}" #I cut here the two initial underscores
}


function __static__GetJobScriptName(){
    local STRING_WITH_BETAVALUES="$1"
    if [ "$BETA_POSTFIX" == "_thermalizeFromConf" ]; then
	echo "${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}__${STRING_WITH_BETAVALUES}_TC"
    elif [ "$BETA_POSTFIX" == "_thermalizeFromHot" ]; then
	echo "${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}__${STRING_WITH_BETAVALUES}_TH"
    else
	echo "${JOBSCRIPT_PREFIX}_${PARAMETERS_STRING}__${STRING_WITH_BETAVALUES}"
    fi
}
