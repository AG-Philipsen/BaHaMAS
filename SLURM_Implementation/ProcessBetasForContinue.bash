#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function __static__GetStatusOfJobsContainingBetavalues()
{
    local beta jobsInformation
    jobsInformation="$(squeue --noheader -u $(whoami) -o "%i@%j@%T")"
    for beta in ${BHMAS_betaValues[@]}; do
        #In sed !d deletes the non matching entries -> here we keep jobs with desired beta, seed and parameters
        statusOfJobsContainingGivenBeta["$beta"]=$(sed '/'$BHMAS_betaPrefix${beta%%_*}'/!d; /'$(cut -d'_' -f2 <<< "$beta")'/!d; /'$BHMAS_parametersString'/!d' <<< "$jobsInformation")
    done
}

function __static__IsJobInQueueForGivenBeta()
{
    local jobStatus; jobStatus="${statusOfJobsContainingGivenBeta[$1]}"
    if [ "$jobStatus" = "" ]; then
        return 1
    else
        if [ $(grep -c "\(RUNNING\|PENDING\)" <<< "$jobStatus") -gt 0 ]; then
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
              file "$1" "! The value " emph "beta = $betaValue" " will be skipped!\n"
        BHMAS_problematicBetaValues+=( $betaValue )
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
        startcondition=* )                  __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "startcondition=[[:alpha:]]\+" "startcondition=${1#*=}" ;;
        sourcefile=* )                      __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "sourcefile=[[:alnum:][:punct:]]*" "sourcefile=${1#*=}" ;;
        initial_prng_state=* )              __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "initial_prng_state=[[:alnum:][:punct:]]*" "initial_prng_state=${1#*=}" ;;
        host_seed=* )                       __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "host_seed=[[:digit:]]\+" "host_seed=${1#*=}" ;;
        intsteps0=* )                       __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "integrationsteps0=[[:digit:]]\+" "integrationsteps0=${1#*=}" ;;
        intsteps1=* )                       __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "integrationsteps1=[[:digit:]]\+" "integrationsteps1=${1#*=}" ;;
        f=* | confSaveFrequency=* )         __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "savefrequency=[[:digit:]]\+" "savefrequency=${1#*=}" ;;
        F=* | confSavePointFrequency=* )    __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "savepointfrequency=[[:digit:]]\+" "savepointfrequency=${1#*=}" ;;
        m=* | measurements=* )              __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "hmcsteps=[[:digit:]]\+" "hmcsteps=${1#*=}" ;;
        measure_pbp=* )                     __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "measure_pbp=[[:digit:]]\+" "measure_pbp=${1#*=}" ;;
        use_mp=* )                          __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "use_mp=[[:digit:]]\+" "use_mp=${1#*=}" ;;
        kappa_mp=* )                        __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "kappa_mp=[[:digit:]]\+[.][[:digit:]]\+" "kappa_mp=${1#*=}" ;;
        intsteps2=* )                       __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "integrationsteps2=[[:digit:]]\+" "integrationsteps2=${1#*=}" ;;
        cg_iteration_block_size=* )         __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "cg_iteration_block_size=[[:digit:]]\+" "cg_iteration_block_size=${1#*=}" ;;
        num_timescales=* )                  __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "num_timescales=[[:digit:]]\+" "num_timescales=${1#*=}" ;;

        * )
            cecho lr "\n The option " emph "$1" " cannot be handled in the continue scenario.\n Simulation cannot be continued. The value " emph "beta = $betaValue" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( $betaValue )
            return 1 ;;
    esac

    return $?
}

function __static__SetBetaRelatedPathVariables()
{
    runBetaDirectory="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValue}"
    submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValue}"
    inputFileGlobalPath="${submitBetaDirectory}/${BHMAS_inputFilename}"
    outputFileGlobalPath="${runBetaDirectory}/${BHMAS_outputFilename}"
}

function __static__IsAnyRequiredFileOrFolderMissing()
{
    if [ ! -d $runBetaDirectory ]; then
        cecho lr "\n The directory " dir "$runBetaDirectory" " does not exist! \n The value " emph "beta = $betaValue" " will be skipped!\n"
        return 0
    elif [ ! -d $submitBetaDirectory ]; then
        cecho lr "\n The directory " dir "$submitBetaDirectory" " does not exist! \n The value " emph "beta = $betaValue" " will be skipped!\n"
        return 0
    elif [ ! -f $inputFileGlobalPath ]; then
        cecho lr "\n The file " file "$inputFileGlobalPath" " does not exist!\n The value " emph "beta = $betaValue" " will be skipped!\n"
        return 0
    fi
    return 1
}

function ProcessBetaValuesForContinue_SLURM()
{
    local index betaValue betaValuesToBeSubmitted commandLineOptionsToBeUsed
    betaValuesToBeSubmitted=()
    commandLineOptionsToBeUsed=()
    for index in "${!BHMAS_specifiedCommandLineOptions[@]}"; do
        if [[ ! ${BHMAS_specifiedCommandLineOptions[$index]} =~ ^--continue ]] && [[ ! ${BHMAS_specifiedCommandLineOptions[$index]} =~ ^-[cC][^[:alpha:]] ]]; then
            commandLineOptionsToBeUsed+=( "${BHMAS_specifiedCommandLineOptions[$index]}" )
        fi
    done
    #Associative array filled in the function called immediately after
    declare -A statusOfJobsContainingGivenBeta=()
    __static__GetStatusOfJobsContainingBetavalues

    for betaValue in ${BHMAS_betaValues[@]}; do

        __static__SetBetaRelatedPathVariables

        if __static__IsAnyRequiredFileOrFolderMissing; then
            BHMAS_problematicBetaValues+=( $betaValue )
            continue
        fi
        cecho ""
        if __static__IsJobInQueueForGivenBeta $betaValue; then
            BHMAS_problematicBetaValues+=( $betaValue )
            continue
        fi

        #If the option resumefrom is given in the betasfile we have to clean the $runBetaDirectory, otherwise just set the name of conf and prng
        if KeyInArray $betaValue BHMAS_trajectoriesToBeResumedFrom; then
            #If the user wishes to resume from the last avialable trajectory, then find here which number is "last"
            if [ ${BHMAS_trajectoriesToBeResumedFrom[$betaValue]} = "last" ]; then
                BHMAS_trajectoriesToBeResumedFrom[$betaValue]=$(ls $runBetaDirectory/conf.* | grep -o "[[:digit:]]\+$" | sort -n | tail -n1 | sed 's/^0*//')
                if [[ ! ${BHMAS_trajectoriesToBeResumedFrom[$betaValue]} =~ ^[[:digit:]]+$ ]]; then
                    cecho lr "\n Unable to find " emph "last configuration" " to resume from!\n The value " emph "beta = $betaValue" " will be skipped!\n"
                    BHMAS_problematicBetaValues+=( $betaValue )
                    continue
                fi
            fi
            cecho o B U "ATTENTION" uU ":" bc uB " The simulation for " emph "beta = ${betaValue%_*}" " will be resumed from trajectory " emph "${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}" "."
            # TODO: Previously here was put an AskUser directive to prevent to mess up the folder moving files in Trash in case the user
            #       forgot some resumefrom label in betas file. It is however annoying when the user really wants to resume many simulations.
            #       Implement mechanism to undo file move/modification maybe trapping CTRL-C or acting in case of UserSaidNo at the end of this
            #       function (ideally asking the user again if he wants to restore everything as it was).
            if [ -f $runBetaDirectory/$(printf "conf.%05d" "${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}") ];then
                local NAME_LAST_CONFIGURATION=$(printf "conf.%05d" "${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}")
            else
                cecho lr " Configuration " emph "$(printf "conf.%05d" "${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}")" " not found in "\
                      dir "$runBetaDirectory" " folder.\n The value " emph "beta = $betaValue" " will be skipped!\n"
                BHMAS_problematicBetaValues+=( $betaValue )
                continue
            fi
            if [ -f $runBetaDirectory/$(printf "prng.%05d" "${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}") ]; then
                local NAME_LAST_PRNG=$(printf "prng.%05d" "${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}")
            else
                local NAME_LAST_PRNG="" #If the prng.xxxxx is not found, use random seed
            fi
            #If the BHMAS_outputFilename is not in the runBetaDirectory stop and not do anything
            if [ ! -f $outputFileGlobalPath ]; then
                cecho lr " File " file "$BHMAS_outputFilename" " not found in " dir "$runBetaDirectory" " folder.\n The value " emph "beta = $betaValue" " will be skipped!\n"
                BHMAS_problematicBetaValues+=( $betaValue )
                continue
            fi
            #Now it should be feasable to resume simulation ---> clean runBetaDirectory
            #Create in runBetaDirectory a folder named Trash_$(date) where to mv all the file produced after the traj. ${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}
            local TRASH_NAME="$runBetaDirectory/Trash_$(date +'%F_%H%M%S')"
            mkdir $TRASH_NAME || exit 2
            for FILE in $runBetaDirectory/conf.* $runBetaDirectory/prng.*; do
                #Move to trash only conf.xxxxx prng.xxxxx files or conf.xxxxx_pbp.dat files where xxxxx are digits
                local NUMBER_FROM_FILE=$(grep -o "\(\(conf.\)\|\(prng.\)\)[[:digit:]]\+\(_pbp.dat\)\?$" <<< "$FILE" | sed 's/\(\(conf.\)\|\(prng.\)\)\([[:digit:]]\+\).*/\4/' | sed 's/^0*//')
                if [ "$NUMBER_FROM_FILE" != "" ]; then
                    if [ $NUMBER_FROM_FILE -gt ${BHMAS_trajectoriesToBeResumedFrom[$betaValue]} ]; then
                        mv $FILE $TRASH_NAME
                    elif [ $NUMBER_FROM_FILE -eq ${BHMAS_trajectoriesToBeResumedFrom[$betaValue]} ] && [ $(grep -o "conf[.][[:digit:]]\+_pbp[.]dat$" <<< "$FILE" | wc -l) -eq 1 ]; then
                        mv $FILE $TRASH_NAME
                    fi
                fi
            done
            #Move to trash conf.save(_backup) and prng.save(_backup) files if existing
            if [ -f $runBetaDirectory/conf.save ]; then mv $runBetaDirectory/conf.save $TRASH_NAME; fi
            if [ -f $runBetaDirectory/prng.save ]; then mv $runBetaDirectory/prng.save $TRASH_NAME; fi
            if [ -f $runBetaDirectory/conf.save_backup ]; then mv $runBetaDirectory/conf.save_backup $TRASH_NAME; fi
            if [ -f $runBetaDirectory/prng.save_backup ]; then mv $runBetaDirectory/prng.save_backup $TRASH_NAME; fi
            #Copy the output file to Trash, edit it leaving out all the trajectories after ${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}, including ${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}
            cp $outputFileGlobalPath $TRASH_NAME || exit -2
            local LINES_TO_BE_CANCELED_IN_OUTPUTFILE=$(tac $outputFileGlobalPath | awk -v resumeFrom=${BHMAS_trajectoriesToBeResumedFrom[$betaValue]} 'BEGIN{found=0}{if($1==(resumeFrom-1)){found=1; print NR-1; exit}}END{if(found==0){print -1}}')
            if [ $LINES_TO_BE_CANCELED_IN_OUTPUTFILE -eq -1 ]; then
                cecho lr "\n Measurement for trajectory " emph "${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}" " not found in outputfile.\n The value " emph "beta = $betaValue" " will be skipped!\n"
                BHMAS_problematicBetaValues+=( $betaValue )
                continue
            fi
            #By doing head -n -$LINES_TO_BE_CANCELED_IN_OUTPUTFILE also the line with the number ${BHMAS_trajectoriesToBeResumedFrom[$betaValue]} is deleted
            head -n -$LINES_TO_BE_CANCELED_IN_OUTPUTFILE $outputFileGlobalPath > ${outputFileGlobalPath}.temporaryCopyThatHopefullyDoesNotExist || exit -2
            mv ${outputFileGlobalPath}.temporaryCopyThatHopefullyDoesNotExist $outputFileGlobalPath || exit -2
            #If resumefrom has not been given in the betasfile check in the runBetaDirectory if conf.save is present: if yes, use it, otherwise use the last checkpoint
        elif [ -f $runBetaDirectory/conf.save ]; then
            local NAME_LAST_CONFIGURATION="conf.save"
            #If conf.save is found then prng.save should be there, if not I will use a random seed
            if [ -f $runBetaDirectory/prng.save ]; then
                local NAME_LAST_PRNG="prng.save"
            else
                local NAME_LAST_PRNG=""
            fi
        else
            local NAME_LAST_CONFIGURATION=$(ls $runBetaDirectory | grep -o "conf.[[:digit:]]\+$" | sort -t '.' -k2n | tail -n1)
            local NAME_LAST_PRNG=$(ls $runBetaDirectory | grep -o "prng.[[:digit:]]\+$" | sort -t '.' -k2n | tail -n1)
        fi

        #The variable NAME_LAST_CONFIGURATION should have been set above, if not it means no conf was available!
        if [ "$NAME_LAST_CONFIGURATION" == "" ]; then
            cecho lr "\n No configuration found in " dir "$runBetaDirectory.\n The value " emph "beta = $betaValue" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( $betaValue )
            continue
        fi
        if [ "$NAME_LAST_PRNG" == "" ]; then
            cecho ly B "\n " U "WARNING" uU ":" uB " No prng state found in " dir "$runBetaDirectory" ", using a random host_seed...\n"
        fi
        #Check that, in case the continue is done from a "numeric" configuration, the number of conf and prng is the same
        if [ "$NAME_LAST_CONFIGURATION" != "conf.save" ] && [ "$NAME_LAST_PRNG" != "prng.save" ] && [ "$NAME_LAST_PRNG" != "" ]; then
            if [ `sed 's/^0*//g' <<< "${NAME_LAST_CONFIGURATION#*.}"` -ne `sed 's/^0*//g' <<< "${NAME_LAST_PRNG#*.}"` ]; then
                cecho lr "\n The numbers of " emph "conf.xxxxx" " and " emph "prng.xxxxx" " are different! Check the respective folder!\n The value " emph "beta = $betaValue" " will be skipped!\n"
                BHMAS_problematicBetaValues+=( $betaValue )
                continue
            fi
        fi
        #Make a temporary copy of the input file that will be used to restore in case the original input file.
        #This is to avoid to modify some parameters and then skip beta because of some error leaving the input file modified!
        #If the beta is skipped this temporary file is used to restore the original input file, otherwise it is deleted.
        ORIGINAL_inputFileGlobalPath="${inputFileGlobalPath}_original"
        cp $inputFileGlobalPath $ORIGINAL_inputFileGlobalPath || exit -2
        #If the option -p | --doNotMeasurePbp has not been given, check the input file and in case act accordingly
        if [ $BHMAS_measurePbp = "FALSE" ]; then
            local BHMAS_measurePbp_VALUE_FOR_INPUTFILE=0
        elif [ $BHMAS_measurePbp = "TRUE" ]; then
            local BHMAS_measurePbp_VALUE_FOR_INPUTFILE=1
            #If the pbp file already exists non empty, append a line to it to be sure the prompt is at the beginning of a new line
            if [ -f ${outputFileGlobalPath}_pbp.dat ] && [ $(wc -l < ${outputFileGlobalPath}_pbp.dat) -ne 0 ]; then
                printf "" >> ${outputFileGlobalPath}_pbp.dat
            fi
        fi
        if [ $(grep -o "measure_pbp" $inputFileGlobalPath | wc -l) -eq 0 ]; then
            if  [ $(grep -o "sourcetype" $inputFileGlobalPath | wc -l) -ne 0 ] ||
                    [ $(grep -o "sourcecontent" $inputFileGlobalPath | wc -l) -ne 0 ] ||
                    [ $(grep -o "num_sources" $inputFileGlobalPath | wc -l) -ne 0 ] ||
                    [ $(grep -o "pbp_measurements" $inputFileGlobalPath | wc -l) -ne 0 ] ||
                    [ $(grep -o "ferm_obs_to_single_file" $inputFileGlobalPath | wc -l) -ne 0 ] ||
                    [ $(grep -o "ferm_obs_pbp_prefix" $inputFileGlobalPath | wc -l) -ne 0 ]; then
                cecho lr " The option " emph "measure_pbp" " is not present in the input file but one or more specification about how to calculate\n"\
                      " the chiral condensate are present. Suspicious situation, investigate! The value " emph "beta = $betaValue" " will be skipped!\n"
                BHMAS_problematicBetaValues+=( $betaValue )
                mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue 2
            fi
            printf "measure_pbp=$BHMAS_measurePbp_VALUE_FOR_INPUTFILE\n"\
                   "sourcetype=volume\n"\
                   "sourcecontent=gaussian" >> $inputFileGlobalPath
            if [ $BHMAS_wilson = "TRUE" ]; then
                printf "num_sources=16" >> $inputFileGlobalPath
            elif [ $BHMAS_staggered = "TRUE" ]; then
                printf "num_sources=1\n"\
                       "pbp_measurements=8\n"\
                       "ferm_obs_to_single_file=1\n"\
                       "ferm_obs_pbp_prefix=${BHMAS_outputFilename}" >> $inputFileGlobalPath
            fi
            cecho wg " Added options " emph "measure_pbp=$BHMAS_measurePbp_VALUE_FOR_INPUTFILE" "\n"\
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
            cecho wg " to the " file "${inputFileGlobalPath#$(pwd)/}" " file."
        else
            __static__ModifyOptionInInputFile "measure_pbp=$BHMAS_measurePbp_VALUE_FOR_INPUTFILE"
            [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
            cecho wg " Set option " emph "measure_pbp=$BHMAS_measurePbp_VALUE_FOR_INPUTFILE" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
        fi

        if [ $BHMAS_wilson = "TRUE" ]; then
            #If the option MP=() is given in the betasfile we have to do some work on the INPUTFILE to check if it was already given or not and act accordingly
            if KeyInArray $betaValue BHMAS_massPreconditioningValues; then
                case $(grep -o "use_mp" $inputFileGlobalPath | wc -l) in
                    0 )
                        if [ $(grep -o "solver_mp" $inputFileGlobalPath | wc -l) -ne 0 ] || [ $(grep -o "kappa_mp" $inputFileGlobalPath | wc -l) -ne 0 ] ||
                               [ $(grep -o "integrator2" $inputFileGlobalPath | wc -l) -ne 0 ] || [ $(grep -o "integrationsteps2" $inputFileGlobalPath | wc -l) -ne 0 ]; then
                            cecho lr " The option " emph "use_mp" " is not present in the input file but one or more specification about how to use\n"\
                                  " mass preconditioning are present. Suspicious situation, investigate! The value " emph "beta = $betaValue" " will be skipped!\n"
                            BHMAS_problematicBetaValues+=( $betaValue )
                            mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                        else
                            printf "use_mp=1\n"\
                                   "solver_mp=cg\n"\
                                   "kappa_mp=0.${BHMAS_massPreconditioningValues[$betaValue]#*,}\n"\
                                   "integrator2=twomn\n"\
                                   "integrationsteps2=${BHMAS_massPreconditioningValues[$betaValue]%,*}" >> $inputFileGlobalPath
                            cecho -wg " Added options " emph "use_mp=1" "\n"\
                                  emph "               solver_mp=cg" "\n"\
                                  emph "               kappa_mp=0.${BHMAS_massPreconditioningValues[$betaValue]#*,}" "\n"\
                                  emph "               integrator2=twomn" "\n"\
                                  emph "               integrationsteps2=${BHMAS_massPreconditioningValues[$betaValue]%,*}"\
                                  " to the " file "${inputFileGlobalPath#$(pwd)/}" " file."
                            __static__ModifyOptionInInputFile "num_timescales=3"
                            [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                            cecho wg " Set option " emph "num_timescales=3" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
                            __static__ModifyOptionInInputFile "cg_iteration_block_size=10"
                            [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                            cecho wg " Set option " emph "cg_iteration_block_size=10" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
                        fi
                        ;;
                    1 )
                        #Here I assume that the specifications for mass preconditioning are already in the input file and I just modify them!
                        __static__ModifyOptionInInputFile "use_mp=1"
                        [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                        cecho wg " Set option " emph "use_mp=1" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
                        __static__ModifyOptionInInputFile "kappa_mp=0.${BHMAS_massPreconditioningValues[$betaValue]#*,}"
                        [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                        cecho wg " Set option " emph "kappa_mp=0.${BHMAS_massPreconditioningValues[$betaValue]#*,}" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
                        __static__ModifyOptionInInputFile "num_timescales=3"
                        [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                        cecho wg " Set option " emph "num_timescales=3" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
                        __static__ModifyOptionInInputFile "intsteps2=${BHMAS_massPreconditioningValues[$betaValue]%,*}"
                        [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                        cecho wg " Set option " emph "intsteps2=${BHMAS_massPreconditioningValues[$betaValue]%,*}" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
                        __static__ModifyOptionInInputFile "cg_iteration_block_size=10"
                        [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                        cecho wg " Set option " emph "cg_iteration_block_size=10" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
                        ;;
                    * )
                        cecho lr "\n String " emph "use_mp" " occurs more than once in file " file "$inputFileGlobalPath" "! The value " emph "beta = $betaValue" " will be skipped!\n"
                        BHMAS_problematicBetaValues+=( $betaValue )
                        mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                        ;;
                esac
            else
                case $(grep -o "use_mp" $inputFileGlobalPath | wc -l) in
                    0 )
                    #Assume that no other option regarding mass preconditioning is in the file (it should be the case) and just continue
                    ;;
                    1 )
                        #Switch off the mass preconditioning and set timescales to 2, as well as the cg_iteration_block_size to 50
                        __static__ModifyOptionInInputFile "use_mp=0"
                        [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                        cecho wg " Set option " emph "muse_mp=0" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
                        __static__ModifyOptionInInputFile "cg_iteration_block_size=50"
                        [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                        cecho wg " Set option " emph "cg_iteration_block_size=50" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
                        __static__ModifyOptionInInputFile "num_timescales=2"
                        [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                        cecho wg " Set option " emph "num_timescales=2" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
                        ;;
                    * )
                        cecho lr "\n String " emph "use_mp" " occurs more than once in file " file "$inputFileGlobalPath" "! The value " emph "beta = $betaValue" " will be skipped!\n"
                        BHMAS_problematicBetaValues+=( $betaValue )
                        mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                        ;;
                esac
            fi
        fi
        #For each command line option, modify it in the inputfile.
        #
        #If BHMAS_trajectoryNumberUpToWhichToContinue is given, set automatically the number of remaining measurements.
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
        if [ $BHMAS_trajectoryNumberUpToWhichToContinue -ne 0 ]; then
            if [ $(grep -o "[[:digit:]]\+" <<< "$NAME_LAST_CONFIGURATION" | wc -l) -ne 0 ]; then
                local NUMBER_DONE_TRAJECTORIES=$(grep -o "[[:digit:]]\+" <<< "$NAME_LAST_CONFIGURATION" | sed 's/^0*//g')
            else
                local STDOUTPUT_FILE=`ls -lt $BHMAS_betaPrefix$betaValue | awk -v filename="$HMC_FILENAME" 'BEGIN{regexp="^"filename".[[:digit:]]+.out$"}{if($9 ~ regexp){print $9}}' | head -n1`
                local STDOUTPUT_GLOBALPATH="$BHMAS_submitDirWithBetaFolders/$BHMAS_betaPrefix$betaValue/$STDOUTPUT_FILE"
                if [ -f $STDOUTPUT_GLOBALPATH ] && [ $(grep "writing gaugefield at tr. [[:digit:]]\+" $STDOUTPUT_GLOBALPATH | wc -l) -ne 0 ]; then
                    local NUMBER_DONE_TRAJECTORIES=$(grep -o "writing gaugefield at tr. [[:digit:]]\+" $STDOUTPUT_GLOBALPATH | grep -o "[[:digit:]]\+" | tail -n1)
                    #If the simulation was resumed from a previous configuration, here NUMBER_DONE_TRAJECTORIES is wrong, correct it.
                    #Note than it is better to correct it with the following check rather than see if the simulation is beeing resumed,
                    #because sometimes a simulation is resumed but not submitted, and just continued later
                    if [ $NUMBER_DONE_TRAJECTORIES -gt $(awk 'END{print $1 + 1}' $outputFileGlobalPath) ]; then
                        NUMBER_DONE_TRAJECTORIES=$(awk 'END{print $1 + 1}' $outputFileGlobalPath)
                    fi
                elif [ -f $outputFileGlobalPath ]; then
                    local NUMBER_DONE_TRAJECTORIES=$(awk 'END{print $1 + 1}' $outputFileGlobalPath) #The +1 is here necessary because the first tr. is supposed to be the number 0.
                else
                    local NUMBER_DONE_TRAJECTORIES=0
                fi
            fi
            if [ $NUMBER_DONE_TRAJECTORIES -ge $BHMAS_trajectoryNumberUpToWhichToContinue ]; then
                cecho lr " It was found that the number of done measurements is " emph "$NUMBER_DONE_TRAJECTORIES >= $BHMAS_trajectoryNumberUpToWhichToContinue = BHMAS_trajectoryNumberUpToWhichToContinue" ".\n"\
                      "The option " emph "--continue=$BHMAS_trajectoryNumberUpToWhichToContinue" " cannot be applied. The value " emph "beta = $betaValue" " will be skipped!\n"
                BHMAS_problematicBetaValues+=( $betaValue )
                mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
            fi
            __static__ModifyOptionInInputFile "measurements=$(($BHMAS_trajectoryNumberUpToWhichToContinue - $NUMBER_DONE_TRAJECTORIES))"
            [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
            cecho wg " Set option " emph "measurements=$(($BHMAS_trajectoryNumberUpToWhichToContinue - $NUMBER_DONE_TRAJECTORIES))" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
        fi
        #Always convert startcondition in continue
        __static__ModifyOptionInInputFile "startcondition=continue"
        #If sourcefile not present in the input file, add it, otherwise modify it
        local NUMBER_OCCURENCE_SOURCEFILE=$(grep -o "sourcefile=[[:alnum:][:punct:]]*" $inputFileGlobalPath | wc -l)
        if [ $NUMBER_OCCURENCE_SOURCEFILE -eq 0 ]; then
            printf "sourcefile=$runBetaDirectory/${NAME_LAST_CONFIGURATION}" >> $inputFileGlobalPath
            cecho wg " Added option " emph "sourcefile=$runBetaDirectory/${NAME_LAST_CONFIGURATION}" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
        elif [ $NUMBER_OCCURENCE_SOURCEFILE -eq 1 ]; then #In order to use __static__ModifyOptionInInputFile I have to escape the slashes in the path (for sed)
            __static__ModifyOptionInInputFile "sourcefile=$(sed 's/\//\\\//g' <<< "$runBetaDirectory")\/$NAME_LAST_CONFIGURATION"
            [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
            cecho wg " Set option " emph "sourcefile=$runBetaDirectory/${NAME_LAST_CONFIGURATION}" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
        else
            cecho lr "\n String " emph "sourcefile=[[:alnum:][:punct:]]*" " occurs more than once in file " file "$inputFileGlobalPath" "! The value " emph "beta = $betaValue" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( $betaValue )
            mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
        fi
        #If we have a prng_state put it in the file, otherwise set a random host seed (using shuf, see shuf --help for info)
        local NUMBER_OCCURENCE_HOST_SEED=$(grep -o "host_seed=[[:digit:]]\{4\}" $inputFileGlobalPath | wc -l)
        local NUMBER_OCCURENCE_PRNG_STATE=$(grep -o "initial_prng_state=[[:alnum:][:punct:]]*" $inputFileGlobalPath | wc -l)
        if [ "$NAME_LAST_PRNG" == "" ]; then
            if [ $NUMBER_OCCURENCE_PRNG_STATE -ne 0 ]; then
                sed -i '/initial_prng_state/d' $inputFileGlobalPath #If no prng valid state has been found, delete eventual line from input file with initial_prng_state
            fi
            if [ $NUMBER_OCCURENCE_HOST_SEED -eq 0 ]; then
                local HOST_SEED=`shuf -i 1000-9999 -n1`
                printf "host_seed=$HOST_SEED\n" >> $inputFileGlobalPath
                cecho wg " Added option " emph "host_seed=$HOST_SEED" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
            elif [ $NUMBER_OCCURENCE_HOST_SEED -eq 1 ]; then
                local HOST_SEED=`shuf -i 1000-9999 -n1`
                __static__ModifyOptionInInputFile "host_seed=$HOST_SEED"
                [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                cecho wg " Set option " emph "host_seed=$HOST_SEED" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
            else
                cecho lr "\n String " emph "host_seed=[[:digit:]]{4}" " occurs more than once in file " file "$inputFileGlobalPath" "! The value " emph "beta = $betaValue" " will be skipped!\n"
                BHMAS_problematicBetaValues+=( $betaValue )
                mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
            fi
        else
            if [ $NUMBER_OCCURENCE_HOST_SEED -ne 0 ]; then
                sed -i '/host_seed/d' $inputFileGlobalPath #If a prng valid state has been found, delete eventual line from input file with host_seed
            fi
            if [ $NUMBER_OCCURENCE_PRNG_STATE -eq 0 ]; then
                printf "initial_prng_state=$runBetaDirectory/${NAME_LAST_PRNG}\n" >> $inputFileGlobalPath
                cecho wg " Added option " emph "initial_prng_state=$runBetaDirectory/${NAME_LAST_PRNG}" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
            elif [ $NUMBER_OCCURENCE_PRNG_STATE -eq 1 ]; then #In order to use __static__ModifyOptionInInputFile I have to escape the slashes in the path (for sed)
                __static__ModifyOptionInInputFile "initial_prng_state=$(sed 's/\//\\\//g' <<< "$runBetaDirectory")\/${NAME_LAST_PRNG}"
                [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
                cecho wg " Set option " emph "initial_prng_state=$runBetaDirectory/${NAME_LAST_PRNG}" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
            else
                cecho lr "\n String " emph "initial_prng_state=[[:alnum:][:punct:]]*" " occurs more than once in file " file "$inputFileGlobalPath" "! The value " emph "beta = $betaValue" " will be skipped!\n"
                BHMAS_problematicBetaValues+=( $betaValue )
                mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue
            fi
        fi
        #Always set the integrator steps, that could have been given or not
        __static__ModifyOptionInInputFile "intsteps0=${BHMAS_scaleZeroIntegrationSteps[$betaValue]}"
        cecho wg " Set option " emph "intsteps0=${BHMAS_scaleZeroIntegrationSteps[$betaValue]}" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
        __static__ModifyOptionInInputFile "intsteps1=${BHMAS_scaleOneIntegrationSteps[$betaValue]}"
        cecho wg " Set option " emph "intsteps1=${BHMAS_scaleOneIntegrationSteps[$betaValue]}" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
        #Modify input file according to remaining command line specified options (only -F, -f, -m)
        local COMMAND_LINE_OPTIONS_TO_BE_CONSIDERED=( "-m" "--measurements" "-f" "--confSaveFrequency" "-F" "--confSavePointFrequency" )
        local index option
        for index in ${!commandLineOptionsToBeUsed[@]}; do #Here assume option value follows option name after a space
            option=${commandLineOptionsToBeUsed[$index]}
            if ! ElementInArray ${option} ${COMMAND_LINE_OPTIONS_TO_BE_CONSIDERED[@]}; then
                continue
            fi
            __static__ModifyOptionInInputFile "${option##*-}=${commandLineOptionsToBeUsed[$((index+1))]}"
            [ $? == 1 ] && mv $ORIGINAL_inputFileGlobalPath $inputFileGlobalPath && continue 2
            cecho wg " Set option " emph "${option##*-}=${commandLineOptionsToBeUsed[$((index+1))]}" " into the " file "${inputFileGlobalPath#$(pwd)/}" " file."
        done

        #If the script runs fine and it arrives here, it means no bash continue command was done --> we can add betaValue to the jobs to be submitted
        rm $ORIGINAL_inputFileGlobalPath
        betaValuesToBeSubmitted+=( $betaValue )

    done #loop on betaValue

    #Partition of the betaValuesToBeSubmitted into group of BHMAS_GPUsPerNode and create the JobScript files inside the JOBSCRIPT_FOLDER
    mkdir -p ${BHMAS_submitDirWithBetaFolders}/$BHMAS_jobScriptFolderName || exit -2
    PackBetaValuesPerGpuAndCreateJobScriptFiles "${betaValuesToBeSubmitted[@]}"

    #Ask the user if he want to continue submitting job
    AskUser "Check if the continue option did its job correctly. Would you like to submit the jobs?"
    if UserSaidNo; then
        cecho lr B "\n No jobs will be submitted.\n"
        exit 0;
    fi
}
