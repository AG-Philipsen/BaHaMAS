# Load auxiliary bash files that will be used.
source ${BaHaMAS_repositoryTopLevelPath}/ProduceInputFile_SLURM.bash               || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/ProduceJobScript_SLURM.bash               || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/ProduceSrunCommandsFileForInversions.bash || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/ProduceInverterJobScript_SLURM.bash       || exit -2
#------------------------------------------------------------------------------------#

# Collection of function needed in the job handler script (mostly in AuxiliaryFunctions).

function ProduceInputFileAndJobScriptForEachBeta_SLURM()
{
    #---------------------------------------------------------------------------------------------------------------------#
    #NOTE: Since this function has to iterate over the betas either doing something and putting the value into
    #      SUBMIT_BETA_ARRAY or putting the beta value into PROBLEM_BETA_ARRAY, it is better to make a local copy
    #      of BETAVALUES in order not to alter the original global array. Actually on the LOEWE the jobs are packed
    #      and this implies that whenever a problematic beta is encoutered it MUST be removed from the betavalues array
    #      (otherwise the authomatic packing would fail in the sense that it would include a problematic beta).
    local BETAVALUES_COPY=(${BETAVALUES[@]})
    #---------------------------------------------------------------------------------------------------------------------#
    for INDEX in "${!BETAVALUES_COPY[@]}"; do
        local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BHMAS_betaPrefix${BETAVALUES_COPY[$INDEX]}"
        if [ -d "$HOME_BETADIRECTORY" ]; then
            if [ $(ls $HOME_BETADIRECTORY | wc -l) -gt 0 ]; then
                cecho lr "\n There are already files in " dir "$HOME_BETADIRECTORY" ".\n The value " emph "beta = ${BETAVALUES_COPY[$INDEX]}" " will be skipped!\n"
                PROBLEM_BETA_ARRAY+=( ${BETAVALUES_COPY[$INDEX]} )
                unset BETAVALUES_COPY[$INDEX] #Here BETAVALUES_COPY becomes sparse
                continue
            fi
        fi
    done
    #Make BETAVALUES_COPY not sparse
    BETAVALUES_COPY=(${BETAVALUES_COPY[@]})
    #If the previous for loop went through, we create the beta folders (just to avoid to create some folders and then abort)
    for INDEX in "${!BETAVALUES_COPY[@]}"; do
        local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BHMAS_betaPrefix${BETAVALUES_COPY[$INDEX]}"
        cecho -n lb " Creating directory " dir "$BHMAS_betaPrefix${BETAVALUES_COPY[$INDEX]}" "..."
        mkdir $HOME_BETADIRECTORY || exit -2
        cecho lg " done!"
        cecho lc "   Configuration used: " file "${STARTCONFIGURATION_GLOBALPATH[${BETAVALUES_COPY[$INDEX]}]}"
        #Call the file to produce the input file
        local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$BHMAS_inputFilename"
        ProduceInputFile_SLURM
    done
    # Partition the BETAVALUES_COPY array into group of BHMAS_GPUsPerNode and create the JobScript files inside the JOBSCRIPT_FOLDER
    mkdir -p ${HOME_DIR_WITH_BETAFOLDERS}/$BHMAS_jobScriptFolderName || exit -2
    __static__PackBetaValuesPerGpuAndCreateJobScriptFiles "${BETAVALUES_COPY[@]}"
}

#=======================================================================================================================#

function ProcessBetaValuesForSubmitOnly_SLURM()
{
    #-----------------------------------------#
    local BETAVALUES_COPY=(${BETAVALUES[@]})
    #-----------------------------------------#
    for BETA in "${!BETAVALUES_COPY[@]}"; do
        local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BHMAS_betaPrefix${BETAVALUES_COPY[$BETA]}"
        local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$BHMAS_inputFilename"
        if [ ! -d $HOME_BETADIRECTORY ]; then
            cecho lr "\n The directory " dir "$HOME_BETADIRECTORY" " does not exist! \n The value " emph "beta = ${BETAVALUES_COPY[$BETA]}" " will be skipped!\n"
            PROBLEM_BETA_ARRAY+=( ${BETAVALUES_COPY[$BETA]} )
            unset BETAVALUES_COPY[$BETA] #Here BETAVALUES_COPY becomes sparse
            continue
        else
            #$HOME_BETADIRECTORY already exists. Check if there are files in $HOME_BETADIRECTORY.
            if [ -f "$INPUTFILE_GLOBALPATH" ]; then
                # In the home betadirectory there should be ONLY the inputfile
                if [ $(ls $HOME_BETADIRECTORY | wc -l) -ne 1 ]; then
                    cecho lr "\n There are already files in " dir "$HOME_BETADIRECTORY" " beyond the input file.\n"\
                          " The value " emph "beta = ${BETAVALUES_COPY[$BETA]}" " will be skipped!\n"
                    PROBLEM_BETA_ARRAY+=( ${BETAVALUES_COPY[$BETA]} )
                    unset BETAVALUES_COPY[$BETA] #Here BETAVALUES_COPY becomes sparse
                    continue
                fi
            else
                cecho lr "\n The file " file "$INPUTFILE_GLOBALPATH" " does not exist!\n The value " emph "beta = ${BETAVALUES_COPY[$BETA]}" " will be skipped!\n"
                PROBLEM_BETA_ARRAY+=( ${BETAVALUES_COPY[$BETA]} )
                unset BETAVALUES_COPY[$BETA] #Here BETAVALUES_COPY becomes sparse
                continue
            fi
        fi
    done
    __static__PackBetaValuesPerGpuAndCreateJobScriptFiles "${BETAVALUES_COPY[@]}"
}

#=======================================================================================================================#

function __static__GetStatusOfJobsContainingBetavalues_SLURM()
{
    local JOBINFO_STRING="$(squeue --noheader -u $(whoami) -o "%i@%j@%T")"
    for BETA in ${BETAVALUES[@]}; do
        # in sed !d deletes the non matching entries -> here we keep jobs with desired beta, seed and parameters
        STATUS_OF_JOBS_CONTAINING_BETA_VALUES["$BETA"]="$(sed '/'$BHMAS_betaPrefix${BETA%%_*}'/!d; /'$(cut -d'_' -f2 <<< "$BETA")'/!d; /'$BHMAS_parametersString'/!d' <<< "$JOBINFO_STRING")"
    done
}

function __static__IsJobInQueueForGivenBeta_SLURM()
{
    if [ "${STATUS_OF_JOBS_CONTAINING_BETA_VALUES[$1]}" = "" ]; then
        return 1
    else
        if [ $(grep -c "\(RUNNING\|PENDING\)" <<< "${STATUS_OF_JOBS_CONTAINING_BETA_VALUES[$1]}") -gt 0 ]; then
            cecho lr  " The simulation seems to be already running with " emph "job-id $JOBID" " and it cannot be continued!\n"
            return 0
        else
            return 1
        fi
    fi
}

#This function must be called with 3 parameters: filename (global path), string to be found, replace string
function __static__FindAndReplaceSingleOccurenceInFile()
{
    if [ $# -ne 3 ]; then
        cecho lr "\n The function " emph "$FUNCNAME" " has been wrongly called (" emph "3 arguments needed" ")! Aborting...\n"
        exit -1
    elif [ ! -f $1 ]; then
        cecho lr "\n Error occurred in " emph "$FUNCNAME" ": file " file "$1" " has not been found! Aborting...\n"
        exit -1
    elif [ $(grep -o "$2" $1 | wc -l) -ne 1 ]; then
        cecho lr "\n Error occurred in " emph "$FUNCNAME" ": string " emph "$2" " occurs 0 times or more than 1 time in file\n "\
              file "$1" "! The value " emph "beta = $BETA" " will be skipped!\n"
        PROBLEM_BETA_ARRAY+=( $BETA )
        return 1
    fi

    sed -i "s/$2/$3/g" $1 || exit 2

    return 0
}

function __static__ModifyOptionInInputFile()
{
    if [ $# -ne 1 ]; then
        cecho lr "\n The function " emph "$FUNCNAME" " has been wrongly called (" emph "1 argument needed" ")! Aborting...\n"
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

        * )
            cecho lr "\n The option " emph "$1" " cannot be handled in the continue scenario.\n Simulation cannot be continued. The value " emph "beta = $BETA" " will be skipped!\n"
            PROBLEM_BETA_ARRAY+=( $BETA )
            return 1 ;;
    esac

    return $?
}



function ProcessBetaValuesForContinue_SLURM()
{
    local LOCAL_SUBMIT_BETA_ARRAY=()
    #Remove -c | --continue option from command line
    for INDEX in "${!SPECIFIED_COMMAND_LINE_OPTIONS[@]}"; do
        if [[ ${SPECIFIED_COMMAND_LINE_OPTIONS[$INDEX]} =~ ^--continue ]] || [[ ${SPECIFIED_COMMAND_LINE_OPTIONS[$INDEX]} =~ ^-[cC][^[:alpha:]] ]]; then
            unset -v 'SPECIFIED_COMMAND_LINE_OPTIONS[$INDEX]'
        fi
    done
    SPECIFIED_COMMAND_LINE_OPTIONS=( "${SPECIFIED_COMMAND_LINE_OPTIONS[@]}" )

    #Associative array filled in the function called immediately after
    declare -A STATUS_OF_JOBS_CONTAINING_BETA_VALUES
    __static__GetStatusOfJobsContainingBetavalues_SLURM

    for BETA in ${BETAVALUES[@]}; do
        #-------------------------------------------------------------------------#
        local WORK_BETADIRECTORY="$WORK_DIR_WITH_BETAFOLDERS/$BHMAS_betaPrefix$BETA"
        local HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BHMAS_betaPrefix$BETA"
        local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$BHMAS_inputFilename"
        local OUTPUTFILE_GLOBALPATH="${WORK_BETADIRECTORY}/$BHMAS_outputFilename"
        #-------------------------------------------------------------------------#

        if [ ! -d $WORK_BETADIRECTORY ]; then
            cecho lr "\n The directory " dir "$WORK_BETADIRECTORY" " does not exist! \n The value " emph "beta = $BETA" " will be skipped!\n"
            PROBLEM_BETA_ARRAY+=( $BETA )
            continue
        fi

        if [ ! -d $HOME_BETADIRECTORY ]; then
            cecho lr "\n The directory " dir "$HOME_BETADIRECTORY" " does not exist! \n The value " emph "beta = $BETA" " will be skipped!\n"
            PROBLEM_BETA_ARRAY+=( $BETA )
            continue
        fi

        if [ ! -f $INPUTFILE_GLOBALPATH ]; then
            cecho lr "\n The file " file "$INPUTFILE_GLOBALPATH" " does not exist!\n The value " emph "beta = $BETA" " will be skipped!\n"
            PROBLEM_BETA_ARRAY+=( $BETA )
            continue
        fi

        cecho ""
        if __static__IsJobInQueueForGivenBeta_SLURM $BETA; then
            PROBLEM_BETA_ARRAY+=( $BETA )
            continue
        fi

        #If the option resumefrom is given in the betasfile we have to clean the $WORK_BETADIRECTORY, otherwise just set the name of conf and prng
        if KeyInArray $BETA CONTINUE_RESUMETRAJ_ARRAY; then
            #If the user wishes to resume from the last avialable trajectory, then find here which number is "last"
            if [ ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]} = "last" ]; then
                CONTINUE_RESUMETRAJ_ARRAY[$BETA]=$(ls $WORK_BETADIRECTORY/conf.* | grep -o "[[:digit:]]\+$" | sort -n | tail -n1 | sed 's/^0*//')
                if [[ ! ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]} =~ ^[[:digit:]]+$ ]]; then
                    cecho lr "\n Unable to find " emph "last configuration" " to resume from!\n The value " emph "beta = $BETA" " will be skipped!\n"
                    PROBLEM_BETA_ARRAY+=( $BETA )
                    continue
                fi
            fi
            cecho o B U "ATTENTION" uU ":" bc uB " The simulation for " emph "beta = ${BETA%_*}" " will be resumed from trajectory " emph "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}" "."
            # TODO: Previously here was put an AskUser directive to prevent to mess up the folder moving files in Trash in case the user
            #       forgot some resumefrom label in betas file. It is however annoying when the user really wants to resume many simulations.
            #       Implement mechanism to undo file move/modification maybe trapping CTRL-C or acting in case of UserSaidNo at the end of this
            #       function (ideally asking the user again if he wants to restore everything as it was).
            if [ -f $WORK_BETADIRECTORY/$(printf "conf.%05d" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}") ];then
                local NAME_LAST_CONFIGURATION=$(printf "conf.%05d" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}")
            else
                cecho lr " Configuration " emph "$(printf "conf.%05d" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}")" " not found in "\
                      dir "$WORK_BETADIRECTORY" " folder.\n The value " emph "beta = $BETA" " will be skipped!\n"
                PROBLEM_BETA_ARRAY+=( $BETA )
                continue
            fi
            if [ -f $WORK_BETADIRECTORY/$(printf "prng.%05d" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}") ]; then
                local NAME_LAST_PRNG=$(printf "prng.%05d" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}")
            else
                local NAME_LAST_PRNG="" #If the prng.xxxxx is not found, use random seed
            fi
            #If the BHMAS_outputFilename is not in the WORK_BETADIRECTORY stop and not do anything
            if [ ! -f $OUTPUTFILE_GLOBALPATH ]; then
                cecho lr " File " file "$BHMAS_outputFilename" " not found in " dir "$WORK_BETADIRECTORY" " folder.\n The value " emph "beta = $BETA" " will be skipped!\n"
                PROBLEM_BETA_ARRAY+=( $BETA )
                continue
            fi
            #Now it should be feasable to resume simulation ---> clean WORK_BETADIRECTORY
            #Create in WORK_BETADIRECTORY a folder named Trash_$(date) where to mv all the file produced after the traj. ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}
            local TRASH_NAME="$WORK_BETADIRECTORY/Trash_$(date +'%F_%H%M%S')"
            mkdir $TRASH_NAME || exit 2
            for FILE in $WORK_BETADIRECTORY/conf.* $WORK_BETADIRECTORY/prng.*; do
                #Move to trash only conf.xxxxx prng.xxxxx files or conf.xxxxx_pbp.dat files where xxxxx are digits
                local NUMBER_FROM_FILE=$(grep -o "\(\(conf.\)\|\(prng.\)\)[[:digit:]]\+\(_pbp.dat\)\?$" <<< "$FILE" | sed 's/\(\(conf.\)\|\(prng.\)\)\([[:digit:]]\+\).*/\4/' | sed 's/^0*//')
                if [ "$NUMBER_FROM_FILE" != "" ]; then
                    if [ $NUMBER_FROM_FILE -gt ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]} ]; then
                        mv $FILE $TRASH_NAME
                    elif [ $NUMBER_FROM_FILE -eq ${CONTINUE_RESUMETRAJ_ARRAY[$BETA]} ] && [ $(grep -o "conf[.][[:digit:]]\+_pbp[.]dat$" <<< "$FILE" | wc -l) -eq 1 ]; then
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
                cecho lr "\n Measurement for trajectory " emph "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}" " not found in outputfile.\n The value " emph "beta = $BETA" " will be skipped!\n"
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
            local NAME_LAST_CONFIGURATION=$(ls $WORK_BETADIRECTORY | grep -o "conf.[[:digit:]]\+$" | sort -t '.' -k2n | tail -n1)
            local NAME_LAST_PRNG=$(ls $WORK_BETADIRECTORY | grep -o "prng.[[:digit:]]\+$" | sort -t '.' -k2n | tail -n1)
        fi

        #The variable NAME_LAST_CONFIGURATION should have been set above, if not it means no conf was available!
        if [ "$NAME_LAST_CONFIGURATION" == "" ]; then
            cecho lr "\n No configuration found in " dir "$WORK_BETADIRECTORY.\n The value " emph "beta = $BETA" " will be skipped!\n"
            PROBLEM_BETA_ARRAY+=( $BETA )
            continue
        fi
        if [ "$NAME_LAST_PRNG" == "" ]; then
            cecho ly B "\n " U "WARNING" uU ":" uB " No prng state found in " dir "$WORK_BETADIRECTORY" ", using a random host_seed...\n"
        fi
        #Check that, in case the continue is done from a "numeric" configuration, the number of conf and prng is the same
        if [ "$NAME_LAST_CONFIGURATION" != "conf.save" ] && [ "$NAME_LAST_PRNG" != "prng.save" ] && [ "$NAME_LAST_PRNG" != "" ]; then
            if [ `sed 's/^0*//g' <<< "${NAME_LAST_CONFIGURATION#*.}"` -ne `sed 's/^0*//g' <<< "${NAME_LAST_PRNG#*.}"` ]; then
                cecho lr "\n The numbers of " emph "conf.xxxxx" " and " emph "prng.xxxxx" " are different! Check the respective folder!\n The value " emph "beta = $BETA" " will be skipped!\n"
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
                cecho "" >> ${OUTPUTFILE_GLOBALPATH}_pbp.dat
            fi
        fi
        if [ $(grep -o "measure_pbp" $INPUTFILE_GLOBALPATH | wc -l) -eq 0 ]; then
            if  [ $(grep -o "sourcetype" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] ||
                    [ $(grep -o "sourcecontent" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] ||
                    [ $(grep -o "num_sources" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] ||
                    [ $(grep -o "pbp_measurements" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] ||
                    [ $(grep -o "ferm_obs_to_single_file" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] ||
                    [ $(grep -o "ferm_obs_pbp_prefix" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ]; then
                cecho lr " The option " emph "measure_pbp" " is not present in the input file but one or more specification about how to calculate\n"\
                      " the chiral condensate are present. Suspicious situation, investigate! The value " emph "beta = $BETA" " will be skipped!\n"
                PROBLEM_BETA_ARRAY+=( $BETA )
                mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue 2
            fi
            cecho "measure_pbp=$MEASURE_PBP_VALUE_FOR_INPUTFILE\n"\
                  "sourcetype=volume\n"\
                  "sourcecontent=gaussian" >> $INPUTFILE_GLOBALPATH
            if [ $BHMAS_wilson = "TRUE" ]; then
                cecho "num_sources=16" >> $INPUTFILE_GLOBALPATH
            elif [ $BHMAS_staggered = "TRUE" ]; then
                cecho "num_sources=1\n"\
                      "pbp_measurements=8\n"\
                      "ferm_obs_to_single_file=1\n"\
                      "ferm_obs_pbp_prefix=${BHMAS_outputFilename}" >> $INPUTFILE_GLOBALPATH
            fi
            cecho wg " Added options " emph "measure_pbp=$MEASURE_PBP_VALUE_FOR_INPUTFILE" "\n"\
                  emph "               sourcetype=volume" "\n"\
                  emph "               sourcecontent=gaussian"
            if [ $BHMAS_wilson = "TRUE" ]; then
                cecho -n wg emph "               num_sources=16"
            else
                cecho -n wg emph "               num_sources=1\n"\
                      emph "               pbp_measurements=8\n"\
                      emph "               ferm_obs_to_single_file=1\n"\
                      emph "               ferm_obs_pbp_prefix=${BHMAS_outputFilename}"
            fi
            cecho wg " to the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
        else
            __static__ModifyOptionInInputFile "measure_pbp=$MEASURE_PBP_VALUE_FOR_INPUTFILE"
            [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
            cecho wg " Set option " emph "measure_pbp=$MEASURE_PBP_VALUE_FOR_INPUTFILE" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
        fi

        if [ $BHMAS_wilson = "TRUE" ]; then
            #If the option MP=() is given in the betasfile we have to do some work on the INPUTFILE to check if it was already given or not and act accordingly
            if KeyInArray $BETA MASS_PRECONDITIONING_ARRAY; then
                case $(grep -o "use_mp" $INPUTFILE_GLOBALPATH | wc -l) in
                    0 )
                        if [ $(grep -o "solver_mp" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] || [ $(grep -o "kappa_mp" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] ||
                               [ $(grep -o "integrator2" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ] || [ $(grep -o "integrationsteps2" $INPUTFILE_GLOBALPATH | wc -l) -ne 0 ]; then
                            cecho lr " The option " emph "use_mp" " is not present in the input file but one or more specification about how to use\n"\
                                  " mass preconditioning are present. Suspicious situation, investigate! The value " emph "beta = $BETA" " will be skipped!\n"
                            PROBLEM_BETA_ARRAY+=( $BETA )
                            mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        else
                            cecho "use_mp=1\n"\
                                  "solver_mp=cg\n"\
                                  "kappa_mp=0.${MASS_PRECONDITIONING_ARRAY[$BETA]#*,}\n"\
                                  "integrator2=twomn\n"\
                                  "integrationsteps2=${MASS_PRECONDITIONING_ARRAY[$BETA]%,*}" >> $INPUTFILE_GLOBALPATH
                            cecho -wg " Added options " emph "use_mp=1" "\n"\
                                  emph "               solver_mp=cg" "\n"\
                                  emph "               kappa_mp=0.${MASS_PRECONDITIONING_ARRAY[$BETA]#*,}" "\n"\
                                  emph "               integrator2=twomn" "\n"\
                                  emph "               integrationsteps2=${MASS_PRECONDITIONING_ARRAY[$BETA]%,*}"\
                                  " to the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
                            __static__ModifyOptionInInputFile "num_timescales=3"
                            [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                            cecho wg " Set option " emph "num_timescales=3" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
                            __static__ModifyOptionInInputFile "cg_iteration_block_size=10"
                            [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                            cecho wg " Set option " emph "cg_iteration_block_size=10" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
                        fi
                        ;;
                    1 )
                        #Here I assume that the specifications for mass preconditioning are already in the input file and I just modify them!
                        __static__ModifyOptionInInputFile "use_mp=1"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        cecho wg " Set option " emph "use_mp=1" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
                        __static__ModifyOptionInInputFile "kappa_mp=0.${MASS_PRECONDITIONING_ARRAY[$BETA]#*,}"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        cecho wg " Set option " emph "kappa_mp=0.${MASS_PRECONDITIONING_ARRAY[$BETA]#*,}" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
                        __static__ModifyOptionInInputFile "num_timescales=3"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        cecho wg " Set option " emph "num_timescales=3" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
                        __static__ModifyOptionInInputFile "intsteps2=${MASS_PRECONDITIONING_ARRAY[$BETA]%,*}"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        cecho wg " Set option " emph "intsteps2=${MASS_PRECONDITIONING_ARRAY[$BETA]%,*}" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
                        __static__ModifyOptionInInputFile "cg_iteration_block_size=10"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        cecho wg " Set option " emph "cg_iteration_block_size=10" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
                        ;;
                    * )
                        cecho lr "\n String " emph "use_mp" " occurs more than once in file " file "$INPUTFILE_GLOBALPATH" "! The value " emph "beta = $BETA" " will be skipped!\n"
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
                        cecho wg " Set option " emph "muse_mp=0" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
                        __static__ModifyOptionInInputFile "cg_iteration_block_size=50"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        cecho wg " Set option " emph "cg_iteration_block_size=50" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
                        __static__ModifyOptionInInputFile "num_timescales=2"
                        [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                        cecho wg " Set option " emph "num_timescales=2" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
                        ;;
                    * )
                        cecho lr "\n String " emph "use_mp" " occurs more than once in file " file "$INPUTFILE_GLOBALPATH" "! The value " emph "beta = $BETA" " will be skipped!\n"
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
        #            from the beginning for 5k trajectories; then the last standard output will give a wrong number of measurements).
        #            This case is left out here and it should be the user to avoid it.
        #
        # NOTE: If the configuration from which we are starting, i.e. NAME_LAST_CONFIGURATION, contains digits then it is
        #       better to deduce the number of measurements to be done from there.
        #
        if [ $CONTINUE_NUMBER -ne 0 ]; then
            if [ $(grep -o "[[:digit:]]\+" <<< "$NAME_LAST_CONFIGURATION" | wc -l) -ne 0 ]; then
                local NUMBER_DONE_TRAJECTORIES=$(grep -o "[[:digit:]]\+" <<< "$NAME_LAST_CONFIGURATION" | sed 's/^0*//g')
            else
                local STDOUTPUT_FILE=`ls -lt $BHMAS_betaPrefix$BETA | awk -v filename="$HMC_FILENAME" 'BEGIN{regexp="^"filename".[[:digit:]]+.out$"}{if($9 ~ regexp){print $9}}' | head -n1`
                local STDOUTPUT_GLOBALPATH="$HOME_DIR_WITH_BETAFOLDERS/$BHMAS_betaPrefix$BETA/$STDOUTPUT_FILE"
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
                cecho lr " It was found that the number of done measurements is " emph "$NUMBER_DONE_TRAJECTORIES >= $CONTINUE_NUMBER = CONTINUE_NUMBER" ".\n"\
                      "The option " emph "--continue=$CONTINUE_NUMBER" " cannot be applied. The value " emph "beta = $BETA" " will be skipped!\n"
                PROBLEM_BETA_ARRAY+=( $BETA )
                mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
            fi
            __static__ModifyOptionInInputFile "measurements=$(($CONTINUE_NUMBER - $NUMBER_DONE_TRAJECTORIES))"
            [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
            cecho wg " Set option " emph "measurements=$(($CONTINUE_NUMBER - $NUMBER_DONE_TRAJECTORIES))" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
        fi
        #Always convert startcondition in continue
        __static__ModifyOptionInInputFile "startcondition=continue"
        #If sourcefile not present in the input file, add it, otherwise modify it
        local NUMBER_OCCURENCE_SOURCEFILE=$(grep -o "sourcefile=[[:alnum:][:punct:]]*" $INPUTFILE_GLOBALPATH | wc -l)
        if [ $NUMBER_OCCURENCE_SOURCEFILE -eq 0 ]; then
            cecho "sourcefile=$WORK_BETADIRECTORY/${NAME_LAST_CONFIGURATION}" >> $INPUTFILE_GLOBALPATH
            cecho wg " Added option " emph "sourcefile=$WORK_BETADIRECTORY/${NAME_LAST_CONFIGURATION}" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
        elif [ $NUMBER_OCCURENCE_SOURCEFILE -eq 1 ]; then #In order to use __static__ModifyOptionInInputFile I have to escape the slashes in the path (for sed)
            __static__ModifyOptionInInputFile "sourcefile=$(sed 's/\//\\\//g' <<< "$WORK_BETADIRECTORY")\/$NAME_LAST_CONFIGURATION"
            [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
            cecho wg " Set option " emph "sourcefile=$WORK_BETADIRECTORY/${NAME_LAST_CONFIGURATION}" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
        else
            cecho lr "\n String " emph "sourcefile=[[:alnum:][:punct:]]*" " occurs more than once in file " file "$INPUTFILE_GLOBALPATH" "! The value " emph "beta = $BETA" " will be skipped!\n"
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
                cecho "host_seed=$HOST_SEED\n" >> $INPUTFILE_GLOBALPATH
                cecho wg " Added option " emph "host_seed=$HOST_SEED" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
            elif [ $NUMBER_OCCURENCE_HOST_SEED -eq 1 ]; then
                local HOST_SEED=`shuf -i 1000-9999 -n1`
                __static__ModifyOptionInInputFile "host_seed=$HOST_SEED"
                [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                cecho wg " Set option " emph "host_seed=$HOST_SEED" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
            else
                cecho lr "\n String " emph "host_seed=[[:digit:]]{4}" " occurs more than once in file " file "$INPUTFILE_GLOBALPATH" "! The value " emph "beta = $BETA" " will be skipped!\n"
                PROBLEM_BETA_ARRAY+=( $BETA )
                mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
            fi
        else
            if [ $NUMBER_OCCURENCE_HOST_SEED -ne 0 ]; then
                sed -i '/host_seed/d' $INPUTFILE_GLOBALPATH #If a prng valid state has been found, delete eventual line from input file with host_seed
            fi
            if [ $NUMBER_OCCURENCE_PRNG_STATE -eq 0 ]; then
                cecho "initial_prng_state=$WORK_BETADIRECTORY/${NAME_LAST_PRNG}\n" >> $INPUTFILE_GLOBALPATH
                cecho wg " Added option " emph "initial_prng_state=$WORK_BETADIRECTORY/${NAME_LAST_PRNG}" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
            elif [ $NUMBER_OCCURENCE_PRNG_STATE -eq 1 ]; then #In order to use __static__ModifyOptionInInputFile I have to escape the slashes in the path (for sed)
                __static__ModifyOptionInInputFile "initial_prng_state=$(sed 's/\//\\\//g' <<< "$WORK_BETADIRECTORY")\/${NAME_LAST_PRNG}"
                [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
                cecho wg " Set option " emph "initial_prng_state=$WORK_BETADIRECTORY/${NAME_LAST_PRNG}" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
            else
                cecho lr "\n String " emph "initial_prng_state=[[:alnum:][:punct:]]*" " occurs more than once in file " file "$INPUTFILE_GLOBALPATH" "! The value " emph "beta = $BETA" " will be skipped!\n"
                PROBLEM_BETA_ARRAY+=( $BETA )
                mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue
            fi
        fi
        #Always set the integrator steps, that could have been given or not
        __static__ModifyOptionInInputFile "intsteps0=${INTSTEPS0_ARRAY[$BETA]}"
        cecho wg " Set option " emph "intsteps0=${INTSTEPS0_ARRAY[$BETA]}" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
        __static__ModifyOptionInInputFile "intsteps1=${INTSTEPS1_ARRAY[$BETA]}"
        cecho wg " Set option " emph "intsteps1=${INTSTEPS1_ARRAY[$BETA]}" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
        #Modify input file according to remaining command line specified options (only -F, -f, -m)
        local COMMAND_LINE_OPTIONS_TO_BE_CONSIDERED=( "-m" "--measurements" "-f" "--confSaveFrequency" "-F" "--confSavePointFrequency" )
        local index option
        for index in ${!SPECIFIED_COMMAND_LINE_OPTIONS[@]}; do #Here assume option value follows option name after a space
            option=${SPECIFIED_COMMAND_LINE_OPTIONS[$index]}
            if ! ElementInArray ${option} ${COMMAND_LINE_OPTIONS_TO_BE_CONSIDERED[@]}; then
                continue
            fi
            __static__ModifyOptionInInputFile "${option##*-}=${SPECIFIED_COMMAND_LINE_OPTIONS[$((index+1))]}"
            [ $? == 1 ] && mv $ORIGINAL_INPUTFILE_GLOBALPATH $INPUTFILE_GLOBALPATH && continue 2
            cecho wg " Set option " emph "${option##*-}=${SPECIFIED_COMMAND_LINE_OPTIONS[$((index+1))]}" " into the " file "${INPUTFILE_GLOBALPATH#$(pwd)/}" " file."
        done

        #If the script runs fine and it arrives here, it means no bash continue command was done --> we can add BETA to the jobs to be submitted
        rm $ORIGINAL_INPUTFILE_GLOBALPATH
        LOCAL_SUBMIT_BETA_ARRAY+=( $BETA )

    done #loop on BETA

    #Partition of the LOCAL_SUBMIT_BETA_ARRAY into group of BHMAS_GPUsPerNode and create the JobScript files inside the JOBSCRIPT_FOLDER
    mkdir -p ${HOME_DIR_WITH_BETAFOLDERS}/$BHMAS_jobScriptFolderName || exit -2
    __static__PackBetaValuesPerGpuAndCreateJobScriptFiles "${LOCAL_SUBMIT_BETA_ARRAY[@]}"

    #Ask the user if he want to continue submitting job
    AskUser "Check if the continue option did its job correctly. Would you like to submit the jobs?"
    if UserSaidNo; then
        cecho lr B "\n No jobs will be submitted.\n"
        exit 0;
    fi
}

#=======================================================================================================================#

function ProcessBetaValuesForInversion_SLURM()
{

    local LOCAL_SUBMIT_BETA_ARRAY=()

    for BETA in ${BETAVALUES[@]}; do
        #-------------------------------------------------------------------------#
        local WORK_BETADIRECTORY="$WORK_DIR_WITH_BETAFOLDERS/$BHMAS_betaPrefix$BETA"
        local NUMBER_OF_CONF_IN_BETADIRECTORY=$(find $WORK_BETADIRECTORY -regex "$WORK_BETADIRECTORY/conf[.][0-9]*" | wc -l)
        local NUMBER_OF_TOTAL_CORRELATORS=$(($NUMBER_OF_CONF_IN_BETADIRECTORY * $NUMBER_SOURCES_FOR_CORRELATORS))
        local NUMBER_OF_EXISTING_CORRELATORS=$(find $WORK_BETADIRECTORY -regextype posix-extended -regex "$WORK_BETADIRECTORY/conf[.][0-9]*(_[0-9]+){4}_corr" | wc -l)
        local NUMBER_OF_MISSING_CORRELATORS=$(($NUMBER_OF_TOTAL_CORRELATORS - $NUMBER_OF_EXISTING_CORRELATORS))
        #-------------------------------------------------------------------------#
        ProduceSrunCommandsFileForInversionsPerBeta
        local NUMBER_OF_INVERSION_COMMANDS=$(wc -l < $WORK_BETADIRECTORY/$SRUN_COMMANDSFILE_FOR_INVERSION)
        if [ $NUMBER_OF_MISSING_CORRELATORS -ne $NUMBER_OF_INVERSION_COMMANDS ]; then
            cecho lr "\n File with commands for inversion expected to contain " emph "$NUMBER_OF_MISSING_CORRELATORS"\
                  " lines, but having " emph "$NUMBER_OF_INVERSION_COMMANDS" ". The value " emph "beta = $BETA" " will be skipped!\n"
            PROBLEM_BETA_ARRAY+=( $BETA )
            continue
        fi
        if [ ! -s $WORK_BETADIRECTORY/$SRUN_COMMANDSFILE_FOR_INVERSION ] && [ $NUMBER_OF_MISSING_CORRELATORS -ne 0 ]; then
            cecho lr "\n File with commands for inversion found to be " emph "empty" ", but expected to contain "\
                  emph "$NUMBER_OF_MISSING_CORRELATORS" " lines! The value " emph "beta = $BETA" " will be skipped!\n"
            PROBLEM_BETA_ARRAY+=( $BETA )
            continue
        fi
        #If file seems fine put it to submit list
        LOCAL_SUBMIT_BETA_ARRAY+=( $BETA )
    done

    #Partition of the LOCAL_SUBMIT_BETA_ARRAY into group of BHMAS_GPUsPerNode and create the JobScript files inside the JOBSCRIPT_FOLDER
    mkdir -p ${HOME_DIR_WITH_BETAFOLDERS}/$BHMAS_jobScriptFolderName || exit -2
    __static__PackBetaValuesPerGpuAndCreateJobScriptFiles "${LOCAL_SUBMIT_BETA_ARRAY[@]}"
}

#=======================================================================================================================#

function SubmitJobsForValidBetaValues_SLURM()
{
    if [ ${#SUBMIT_BETA_ARRAY[@]} -gt "0" ]; then
        cecho lc "\n==================================================================================="
        cecho bb " Jobs will be submitted for the following beta values:"
        for BETA in ${SUBMIT_BETA_ARRAY[@]}; do
            cecho "  - $BETA"
        done

        for BETA in ${SUBMIT_BETA_ARRAY[@]}; do
            if [ $USE_MULTIPLE_CHAINS == "FALSE" ]; then
                local PREFIX_TO_BE_GREPPED_FOR="$BHMAS_betaPrefix"
            else
                local PREFIX_TO_BE_GREPPED_FOR="$BHMAS_seedPrefix"
            fi
            local TEMP_ARRAY=( $(sed 's/_/ /g' <<< "$BETA") )
            if [ $(grep -o "${PREFIX_TO_BE_GREPPED_FOR}\([[:digit:]][.]\)\?[[:alnum:]]\{4\}" <<< "$BETA" | wc -l) -ne $BHMAS_GPUsPerNode ]; then
                cecho -n ly B "\n " U "WARNING" uU ":" uB " At least one job is being submitted with less than " emph "$BHMAS_GPUsPerNode" " runs inside."
                AskUser "         Would you like to submit in any case?"
                if UserSaidNo; then
                    cecho lr B "\n No jobs will be submitted."
                    return
                fi
            fi
        done

        for BETA in ${SUBMIT_BETA_ARRAY[@]}; do
            local SUBMITTING_DIRECTORY="${HOME_DIR_WITH_BETAFOLDERS}/$BHMAS_jobScriptFolderName"
            local JOBSCRIPT_NAME="$(__static__GetJobScriptName ${BETA})"
            cd $SUBMITTING_DIRECTORY
            cecho bb "\n Actual location: " dir "$(pwd)"\
                  B "\n      Submitting: " uB emph "sbatch $JOBSCRIPT_NAME"
            sbatch $JOBSCRIPT_NAME
        done
        cecho lc "\n==================================================================================="
    else
        cecho lr B " No jobs will be submitted."
    fi
}

#=======================================================================================================================#










#=======================================================================================================================#
#============================ STATIC FUNCTIONS USED MORE THAN IN ONE OTHER FUNCTION ====================================#
#=======================================================================================================================#

function __static__PackBetaValuesPerGpuAndCreateJobScriptFiles()
{
    local BETAVALUES_ARRAY_TO_BE_SPLIT=( $@ )
    cecho lc "\n================================================================================="
    cecho bb "  The following beta values have been grouped (together with the seed if used):"
    while [[ "${!BETAVALUES_ARRAY_TO_BE_SPLIT[@]}" != "" ]]; do # ${!array[@]} gives the list of the valid indices in the array
        local BETA_FOR_JOBSCRIPT=(${BETAVALUES_ARRAY_TO_BE_SPLIT[@]:0:$BHMAS_GPUsPerNode})
        BETAVALUES_ARRAY_TO_BE_SPLIT=(${BETAVALUES_ARRAY_TO_BE_SPLIT[@]:$BHMAS_GPUsPerNode})
        cecho -n "   ->"
        for BETA in "${BETA_FOR_JOBSCRIPT[@]}"; do
            cecho -n "    ${BHMAS_betaPrefix}${BETA%_*}"
        done
        cecho ""
        local BETAS_STRING="$(__static__GetJobBetasStringUsing ${BETA_FOR_JOBSCRIPT[@]})"
        local JOBSCRIPT_NAME="$(__static__GetJobScriptName ${BETAS_STRING})"
        local JOBSCRIPT_GLOBALPATH="${HOME_DIR_WITH_BETAFOLDERS}/$BHMAS_jobScriptFolderName/$JOBSCRIPT_NAME"
        if [ $SUBMITONLY = "FALSE" ]; then
            if [ -e $JOBSCRIPT_GLOBALPATH ]; then
                mv $JOBSCRIPT_GLOBALPATH ${JOBSCRIPT_GLOBALPATH}_$(date +'%F_%H%M') || exit -2
            fi
            #Call the file to produce the jobscript file
            if [ $INVERT_CONFIGURATIONS = "TRUE" ]; then
                ProduceInverterJobscript_SLURM
            else
                ProduceJobscript_SLURM
            fi
            if [ -e $JOBSCRIPT_GLOBALPATH ]; then
                SUBMIT_BETA_ARRAY+=( "${BETAS_STRING}" )
            else
                cecho lr "\n Jobscript " file "$JOBSCRIPT_NAME" " failed to be created! Skipping this job submission!\n"
                PROBLEM_BETA_ARRAY+=( "${BETAS_STRING}" )
                continue
            fi
        else
            if [ -e $JOBSCRIPT_GLOBALPATH ]; then
                SUBMIT_BETA_ARRAY+=( "${BETAS_STRING}" )
            else
                cecho lr "\n Jobscript " file "$JOBSCRIPT_NAME" " not found! Option " emph "--submitonly" " cannot be applied! Skipping this job submission!\n"
                PROBLEM_BETA_ARRAY+=( "${BETAS_STRING}" )
                continue
            fi
        fi
    done
    cecho lc "================================================================================="
}


function __static__GetJobBetasStringUsing()
{
    local BETAVALUES_TO_BE_USED=( $@ )
    declare -A BETAS_WITH_SEED
    for INDEX in "${BETAVALUES_TO_BE_USED[@]}"; do
        BETAS_WITH_SEED[${INDEX%%_*}]="${BETAS_WITH_SEED[${INDEX%%_*}]:-}_$(awk '{split($0, res, "_"); print res[2]}' <<< "$INDEX")"
    done
    local BETAS_STRING_TO_BE_RETURNED=""
    #Here I iterate again on BETAVALUES_TO_BE_USED and not on ${!BETAS_WITH_SEED[@]} in order to guarantee an order in BETAS_STRING
    #(remember that associative arrays keys are not sorted in general, if it is, it is by coincidence). Note that now I have to use
    #the same BETA only once and this is easily achieved unsetting the BETAS_WITH_SEED array entry once used it
    for BETA in "${BETAVALUES_TO_BE_USED[@]}"; do
        BETA=${BETA%%_*}
        if KeyInArray $BETA BETAS_WITH_SEED; then
            BETAS_STRING_TO_BE_RETURNED="${BETAS_STRING_TO_BE_RETURNED}__${BHMAS_betaPrefix}${BETA}${BETAS_WITH_SEED[${BETA}]}"
            unset 'BETAS_WITH_SEED[${BETA}]'
        fi
    done
    if [ $USE_MULTIPLE_CHAINS == "FALSE" ]; then
        BETAS_STRING_TO_BE_RETURNED="$(sed -e 's/___/_/g' -e 's/_$//' <<< "$BETAS_STRING_TO_BE_RETURNED")"
    fi

    printf "${BETAS_STRING_TO_BE_RETURNED:2}" #I cut here the two initial underscores
}


function __static__GetJobScriptName()
{
    local STRING_WITH_BETAVALUES="$1"

    if [ $INVERT_CONFIGURATIONS = "TRUE" ]; then
        printf "${BHMAS_jobScriptPrefix}_${BHMAS_parametersString}__${STRING_WITH_BETAVALUES}_INV"
    else
        if [ "$BHMAS_betaPostfix" == "_thermalizeFromConf" ]; then
            printf "${BHMAS_jobScriptPrefix}_${BHMAS_parametersString}__${STRING_WITH_BETAVALUES}_TC"
        elif [ "$BHMAS_betaPostfix" == "_thermalizeFromHot" ]; then
            printf "${BHMAS_jobScriptPrefix}_${BHMAS_parametersString}__${STRING_WITH_BETAVALUES}_TH"
        else
            printf "${BHMAS_jobScriptPrefix}_${BHMAS_parametersString}__${STRING_WITH_BETAVALUES}"
        fi
    fi
}
