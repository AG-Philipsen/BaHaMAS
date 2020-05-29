#
#  Copyright (c) 2020 Alessandro Sciarra
#
#  This file is part of BaHaMAS.
#
#  BaHaMAS is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  BaHaMAS is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with BaHaMAS. If not, see <http://www.gnu.org/licenses/>.
#

# This function should find and validate the checkpoint required by the user in the
# betas file
#
#  INPUT: simulation ID
#  OUTPUT: set variables nameOfLastConfiguration, nameOfLastPRNG, nameOfLastData
#  Local variables from the caller used: runBetaDirectory outputFileGlobalPath
#
# Exit codes: 0 if fine
#             1 if runId is problematic -> Added to BHMAS_problematicBetaValues array
#
# For openQCD-FASTSUM the following tasks are performed:
#  1) Check if run-time renaming mechanism of previous run did not
#     rename all checkpoints. A checkpoint in openQCD is a bunch of files:
#     the configuration, the rng state and the binary data file.
#  2) Find checkpoint to continue the simulation.
#
# NOTE: The variable "nameOfLastPRNG" is set here and some work on prng files is done,
#       but esclusively to do some checks on their availability and warn the user if
#       needed. Outside this file, this variable is not used, because openQCD handles
#       the rng reusage strategy on the command line only and not in the input file
#       as CL2QCD. Hence we will check in the job script file whether the .rng file
#       exists in the beta folder and give -seed $RANDOM option if not.
function HandleEnvironmentForContinueForGivenSimulation_openQCD-FASTSUM()
{
    local runId listOfFiles deltaConfs shiftConfs numberOfCheckpoint\
          listConf listPrng listData indexC indexP indexD
    runId="$1"
    CheckIfVariablesAreDeclared runBetaDirectory outputFileGlobalPath\
                                nameOfLastConfiguration nameOfLastPRNG\
                                nameOfLastData

    #Check if checkpoints were all renamed in previous run
    listOfFiles=()
    for file in "${outputFileGlobalPath}"{.rng,.dat}'~'; do
        if [[ -f "${file}" ]]; then
            listOfFiles+=( "${file}" )
        fi
    done
    listOfFiles+=(
        "${outputFileGlobalPath}n"+([0-9])
    )
    if [[ ${#listOfFiles[@]} -ne 0 ]]; then
        Error -N 'The rename mechanism in a previous run left the following files not renamed:'
        for file in "${listOfFiles[@]}"; do
            Error -e -N -n '  - ' emph "$(basename "${file}")"
        done
        Error -e "The value " emph "beta = ${runId}" " will be skipped!"
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi

    # NOTE: For openQCD 'rlast' is equivalent to no 'r' field in the betas file,
    #       because no temporary checkpoint mechanism is there offered.
    if ! KeyInArray ${runId} BHMAS_trajectoriesToBeResumedFrom; then
        BHMAS_trajectoriesToBeResumedFrom[${runId}]='last'
    fi
    if [[ ${BHMAS_trajectoriesToBeResumedFrom[${runId}]} = 'last' ]]; then
        #Constructs sorted lists of checkpoint files
        listConf=( "${runBetaDirectory}/"${BHMAS_configurationGlob} )
        listPrng=( "${runBetaDirectory}/"${BHMAS_prngGlob} )
        listData=( "${runBetaDirectory}/"${BHMAS_dataGlob} )
        listConf=( "${listConf[@]##*/${BHMAS_configurationPrefix//\\/}*(0)}" ) # take numbers without
        listPrng=( "${listPrng[@]##*/${BHMAS_prngPrefix//\\/}*(0)}" )          # leading 0 if any
        listData=( "${listData[@]##*/${BHMAS_dataPrefix//\\/}*(0)}" )
        readarray -d $'\0' -t listConf < <(printf '%s\0' "${listConf[@]}" | sort -zV)
        readarray -d $'\0' -t listPrng < <(printf '%s\0' "${listPrng[@]}" | sort -zV)
        readarray -d $'\0' -t listData < <(printf '%s\0' "${listData[@]}" | sort -zV)
        #Find last valid checkpoint iterating arrays from bottom (they are sorted!)
        for((indexC=1; indexC<=${#listConf[@]}; indexC++)); do
            for((indexP=1; indexP<=${#listPrng[@]}; indexP++)); do
                if [[ ${listConf[-indexC]} -eq ${listPrng[-indexP]} ]]; then
                    for((indexD=1; indexD<=${#listData[@]}; indexD++)); do
                        if [[ ${listConf[-indexC]} -eq ${listData[-indexD]} ]]; then
                            BHMAS_trajectoriesToBeResumedFrom[${runId}]=${listConf[-indexC]}
                            break 3
                        fi
                    done
                    Warning -n 'No valid data file found for ' emph "tr. ${listConf[-indexC]}" ' for which a valid configuration/rng pair exists!'
                    continue 2
                fi
            done
            Warning -n 'No valid prng file found for ' emph "tr. ${listConf[-indexC]}" ' for which a configuration exists!'
        done
        if [[ ! ${BHMAS_trajectoriesToBeResumedFrom[${runId}]} =~ ^[1-9][0-9]*$ ]]; then
            Error "Unable to find " emph "last valid checkpoint" " to resume from!\n" "The value " emph "beta = ${runId}" " will be skipped!"
            BHMAS_problematicBetaValues+=( ${runId} )
            return 1
        fi
    fi

    #Construct filenames
    nameOfLastConfiguration=$(printf "${BHMAS_configurationPrefix//\\/}%0${BHMAS_checkpointMinimumNumberOfDigits}d"\
                                     "${BHMAS_trajectoriesToBeResumedFrom[${runId}]}")
    nameOfLastPRNG=$(printf "${BHMAS_prngPrefix//\\/}%0${BHMAS_checkpointMinimumNumberOfDigits}d"\
                            "${BHMAS_trajectoriesToBeResumedFrom[${runId}]}")
    nameOfLastData=$(printf "${BHMAS_dataPrefix//\\/}%0${BHMAS_checkpointMinimumNumberOfDigits}d"\
                            "${BHMAS_trajectoriesToBeResumedFrom[${runId}]}")
    #Check existence of files
    if [[ ! -f "${runBetaDirectory}/${nameOfLastConfiguration}" ]];then
        Error 'Configuration to be resumed from ' emph "${nameOfLastConfiguration}" ' not found in\n'\
              dir "${runBetaDirectory}" '\nfolder. The value ' emph "beta = ${runId}" ' will be skipped!'
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi
    if [[ ! -f "${runBetaDirectory}/${nameOfLastData}" ]];then
        Error 'Binary data file ' emph "${nameOfLastData}" ' not found in\n'\
              dir "${runBetaDirectory}" '\nfolder. The value ' emph "beta = ${runId}" ' will be skipped!'
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi
    if [[ ! -f "${runBetaDirectory}/${nameOfLastPRNG}" ]]; then
        Warning "No valid PRNG file for configuration " file "${BHMAS_betaPrefix}${runId}/${nameOfLastConfiguration}" " was found! Using a random seed."
        nameOfLastPRNG="" #If the prng.xxxxx is not found, use random seed in input file
    elif [[ ! -s "${runBetaDirectory}/${nameOfLastPRNG}" ]]; then
        Error 'Last PRNG file ' emph "${nameOfLastPRNG}" ' found in\n'\
              dir "${runBetaDirectory}" '\nfolder is empty! The value ' emph "beta = ${runId}" ' will be skipped!'
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi

    cecho lm B U "ATTENTION" uU ":" uB " The simulation for " emph "beta = ${runId%_*}"\
          " will be resumed from trajectory " B emph "${BHMAS_trajectoriesToBeResumedFrom[${runId}]}" uB "."
}

# This function should clean the simulation measurement files, depending on the
# checkpoint to resume from. ALL output files handling is done here as e.g.
# create a Trash folder and move into it the files referring to a trajectory
# larger than that to be resumed from.
#
#  INPUT: simulation ID
#  OUTPUT: -
#  Local variables from the caller used: runBetaDirectory outputFileGlobalPath trashFolderGlobalPath
#                                        nameOfLastConfiguration nameOfLastPRNG nameOfLastData
#
# Exit codes: 0 if fine
#             1 if runId is problematic -> Added to BHMAS_problematicBetaValues array
function HandleOutputFilesForContinueForGivenSimulation_openQCD-FASTSUM()
{
    local runId; runId="$1"
    CheckIfVariablesAreDeclared runBetaDirectory outputFileGlobalPath trashFolderGlobalPath\
                                nameOfLastConfiguration nameOfLastPRNG nameOfLastData

    # Preliminry checks
    if ! KeyInArray ${runId} BHMAS_trajectoriesToBeResumedFrom; then
        Internal 'Error in function ' emph "${FUNCNAME}"\
                 ':\nrun ID not found in BHMAS_trajectoryNumberUpToWhichToContinue array.'
    fi
    if [[ ! -f "${outputFileGlobalPath}.log" ]]; then
        Error 'File ' file "${BHMAS_outputFilename}.log" ' not found in folder\n'\
              dir "${runBetaDirectory}" '\nThe value ' emph "beta = ${runId}" ' will be skipped!'
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi

    # Copy the checkpoint files to be used back to openQCD-FASTSUM checkpoint files, so that
    # the simulation can then be resumed. OpenQCD will then find this checkpoint as "last" one,
    # provided that names are correct and that the .log file is correctly cleaned.
    numberOfCheckpoint=$(__static__GetNumberOfCheckpointCorrespondingToTrajectoryToResumeFrom) || return 1
    mv "${runBetaDirectory}/${nameOfLastConfiguration}" "${outputFileGlobalPath}n${numberOfCheckpoint}" || exit ${BHMAS_fatalBuiltin}
    if [[ "${nameOfLastPRNG}" != '' ]]; then
        mv "${runBetaDirectory}/${nameOfLastPRNG}"      "${outputFileGlobalPath}.rng"                   || exit ${BHMAS_fatalBuiltin}
    fi
    mv "${runBetaDirectory}/${nameOfLastData}"          "${outputFileGlobalPath}.dat"                   || exit ${BHMAS_fatalBuiltin}
    # It is crucial to create also the '~' files so that the rename mechanism can immediately
    # find this checkpoint and rename it to the standard naming scheme. Otherwise an error would occur!
    if [[ "${nameOfLastPRNG}" != '' ]]; then
        cp "${runBetaDirectory}/${BHMAS_outputFilename}.rng"  "${runBetaDirectory}/${BHMAS_outputFilename}.rng~" || exit ${BHMAS_fatalBuiltin}
    else
        touch  "${runBetaDirectory}/${BHMAS_outputFilename}.rng~"                                                || exit ${BHMAS_fatalBuiltin}
    fi
    cp "${runBetaDirectory}/${BHMAS_outputFilename}.dat"  "${runBetaDirectory}/${BHMAS_outputFilename}.dat~"     || exit ${BHMAS_fatalBuiltin}

    # Create in runBetaDirectory a folder named Trash_$(date) where to mv all the file produced
    # after the traj. ${BHMAS_trajectoriesToBeResumedFrom[${runId}]} and then also the log file
    # that must be cleaned before the resume (the 'trashFolderGlobalPath' is declared in the caller)
    local listOfNumbers prefix index
    mkdir "${trashFolderGlobalPath}" || exit ${BHMAS_fatalBuiltin}
    for prefix in "${BHMAS_configurationPrefix}" "${BHMAS_prngPrefix}" "${BHMAS_dataPrefix}"; do
        listOfNumbers=( "${runBetaDirectory}/${prefix//\\/}"+([0-9]) )
        listOfNumbers=( "${listOfNumbers[@]##*/${prefix//\\/}*(0)}" ) # take numbers without leading 0
        readarray -d $'\0' -t listOfNumbers < <(printf '%s\0' "${listOfNumbers[@]}" | sort -zV)
        #Take advantage we sorted the numbers in the array iterating on it from bottom
        for((index=1; index<=${#listOfNumbers[@]}; index++)); do
            if [[ ${listOfNumbers[-index]} -le ${BHMAS_trajectoriesToBeResumedFrom[${runId}]} ]]; then
                break
            fi
            mv "${runBetaDirectory}/${prefix//\\/}$(printf "%0${BHMAS_checkpointMinimumNumberOfDigits}d" ${listOfNumbers[-index]})"\
               "${trashFolderGlobalPath}" || exit ${BHMAS_fatalBuiltin}
        done
    done

    #Move the log file to Trash, and duplicate it parsing it in awk deleting all the trajectories after the resume-checkpoint
    local numberOfCheckpoint lineToMatch
    mv "${outputFileGlobalPath}.log" "${trashFolderGlobalPath}" || exit ${BHMAS_fatalBuiltin}
    numberOfCheckpoint=$(__static__GetNumberOfCheckpointCorrespondingToTrajectoryToResumeFrom) || return 1
    lineToMatch="Configuration no ${numberOfCheckpoint} exported"
    if ! awk -v regex="^${lineToMatch}$"\
         'BEGIN{found=1} {print $0} {if($0 ~ regex){found=0; exit}} END{exit found}'\
         "${trashFolderGlobalPath}/$(basename "${outputFileGlobalPath}.log")" > "${outputFileGlobalPath}.log"; then
        Error 'Line ' emph "${lineToMatch}" ' not found in outputfile\n'\
              file "${outputFileGlobalPath}.log\n"\
              'The value ' emph "beta = ${runId}" ' will be skipped!'
        RestoreRunBetaDirectoryBeforeSkippingBeta_openQCD-FASTSUM
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi
}

# This function should do needed operations to restore the beta folder state
# for a followiung run of BaHaMAS so that no artificial error is later triggered
#
#  INPUT: runId
#  OUTPUT: -
#  Local variables from the caller used: runBetaDirectory outputFileGlobalPath trashFolderGlobalPath
#                                        nameOfLastConfiguration nameOfLastPRNG nameOfLastData
#
# Exit codes: 0 if fine
#             1 if runId is problematic -> Added to BHMAS_problematicBetaValues array
function RestoreRunBetaDirectoryBeforeSkippingBeta_openQCD-FASTSUM()
{
    #We ignore runId here, it is not needed for openQCD!
    CheckIfVariablesAreDeclared runBetaDirectory outputFileGlobalPath\
                                nameOfLastConfiguration nameOfLastPRNG\
                                nameOfLastData trashFolderGlobalPath
    # Use glob instead of deducing number, it should be safe, since only one conf should exist!
    mv "${outputFileGlobalPath}n"* "${runBetaDirectory}/${nameOfLastConfiguration}" || exit ${BHMAS_fatalBuiltin}
    if [[ "${nameOfLastPRNG}" != '' ]]; then
        mv "${outputFileGlobalPath}.rng"               "${runBetaDirectory}/${nameOfLastPRNG}"          || exit ${BHMAS_fatalBuiltin}
    fi
    mv "${outputFileGlobalPath}.dat"                   "${runBetaDirectory}/${nameOfLastData}"          || exit ${BHMAS_fatalBuiltin}
    rm "${runBetaDirectory}/${BHMAS_outputFilename}.rng~" || exit ${BHMAS_fatalBuiltin}
    rm "${runBetaDirectory}/${BHMAS_outputFilename}.dat~" || exit ${BHMAS_fatalBuiltin}
    #Empty trash folder and delete it
    mv "${trashFolderGlobalPath}/"* "${runBetaDirectory}" || exit ${BHMAS_fatalBuiltin}
    rmdir "${trashFolderGlobalPath}"                      || exit ${BHMAS_fatalBuiltin}
}

# This function should make the needed adjustments to the input file
#  INPUT: simulation ID
#  OUTPUT: -
#  Local variables from the caller used: inputFileGlobalPath outputFileGlobalPath runBetaDirectory
#
# Exit codes: 0 if fine
#             1 if runId is problematic -> Added to BHMAS_problematicBetaValues array
function HandleInputFileForContinueForGivenSimulation_openQCD-FASTSUM()
{
    local runId; runId="$1"
    CheckIfVariablesAreDeclared inputFileGlobalPath outputFileGlobalPath runBetaDirectory

    cecho lg '\n Adjusting input file ' emph "$(basename "${inputFileGlobalPath}")" ' for simulation at ' emph "beta = ${runId}" ':'
    HandleMeasurementsInInputFile                                      || return 1
    #__static__HandleMultiplePseudofermionsInInputFile_openQCD-FASTSUM  || return 1
    __static__HandleIntegrationStepsInInputFile_openQCD-FASTSUM        || return 1
    __static__HandleFurtherOptionsInInputFile_openQCD-FASTSUM          || return 1
}

#---------------------------------------------------------------------------------#
# All the following "static" funtions are supporting the above function. They use #
# non global variables defined as local outside them, e.g. runId from the caller. #
#---------------------------------------------------------------------------------#

function __static__GetNumberOfCheckpointCorrespondingToTrajectoryToResumeFrom()
{
    local trNumber deltaConfs shiftConfs
    trNumber=${BHMAS_trajectoriesToBeResumedFrom[${runId}]}
    deltaConfs=$(ExtractGapBetweenCheckpointsFromInputFile "${runId}")
    if ! shiftConfs=$(ExtractTrajectoryNumberFromConfigurationSymlink "${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}"); then
        Error 'Unable to find unique symbolic link to starting configuration in\n'\
              dir "${runBetaDirectory}"\
              '\nto extract initial number for rename mechanism of checkpoints.\n'\
              'The value ' emph "beta = ${runId}" ' will be skipped!'
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi
    printf '%d' $(( (trNumber - shiftConfs) / deltaConfs ))
}

function FindAndSetNumberOfTrajectoriesAlreadyProduced_openQCD-FASTSUM()
{
    CheckIfVariablesAreDeclared runId nameOfLastConfiguration
    # OUTPUT: Set variable 'numberOfTrajectoriesAlreadyProduced'
    #
    # Strategy to recover the number of done trajectories in THIS coninueWithNewChain run (net of thermalization):
    #   1) Use the name of the last configuration to deduce the number of the last trajectory
    #      and use the symbolic link to the starting configuration to read off the number of the
    #      trajectories done in previous thermalization run(s). Otherwise,
    #   2) if the output file exists, use it (consider that it might be to be cleaned). Otherwise,
    #   3) print an error and skip beta.
    local initialConfiguration index initialTrNumber lastTrNumber
    initialTrNumber=''; lastTrNumber=''
    if initialTrNumber=$(ExtractTrajectoryNumberFromConfigurationSymlink "${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}"); then
        lastTrNumber="${nameOfLastConfiguration##${BHMAS_configurationPrefix//\\/}*(0)}" #extract number from the end without leading zeros
    fi
    if [[ "${initialTrNumber}" =~ ^(0|[1-9][0-9]*)$ ]] && [[ "${lastTrNumber}" =~ ^[1-9][0-9]*$ ]]; then
        numberOfTrajectoriesAlreadyProduced=$(( lastTrNumber - initialTrNumber ))
        return 0
    fi
    # Fall back to case 2)
    if [[ -f "${outputFileGlobalPath}.log" ]]; then
        # openQCD-FASTSUM always starts from 1 in the output log file
        lastTrNumber=$(grep '^Trajectory no [1-9][0-9]*' "${outputFileGlobalPath}.log" | tail -n1 | grep -o '[1-9][0-9]*')
    fi
    if [[ "${lastTrNumber}" =~ ^[1-9][0-9]*$ ]]; then
        numberOfTrajectoriesAlreadyProduced=${lastTrNumber}
        return 0
    fi
    # Fall back to case 4)
    Error "It was not possible to deduce the number of already produced trajectories!\n" "The value " emph "beta = ${runId}" " will be skipped!"
    BHMAS_problematicBetaValues+=( ${runId} )
    return 1
}

function __static__HandleIntegrationStepsInInputFile_openQCD-FASTSUM()
{
    local optionsToBeAddedOrModified
    #Always set the integrator steps, that could have changed or not
    optionsToBeAddedOrModified=(
        "intsteps0=${BHMAS_scaleZeroIntegrationSteps[${runId}]}"
        "intsteps1=${BHMAS_scaleOneIntegrationSteps[${runId}]}"
    )
    ModifyOptionsInInputFile_openQCD-FASTSUM ${optionsToBeAddedOrModified[@]} || return 1
    PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
}

function __static__HandleFurtherOptionsInInputFile_openQCD-FASTSUM()
{
    local commandLineOptionsToBeConsidered optionsToBeAddedOrModified
    optionsToBeAddedOrModified=()
    # No options should be handled at the moment!
    if [[ ${#optionsToBeAddedOrModified[@]} -ne 0 ]]; then
        ModifyOptionsInInputFile_openQCD-FASTSUM ${optionsToBeAddedOrModified[@]} || return 1
        PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
    fi
    return 0
}

function ModifyOptionsInInputFile_openQCD-FASTSUM()
{
    # ATTENTION: Use Extended Regular Expression (ERE) here
    #            which are later enabled invoking grep/sed,
    #            while awk uses them by default.
    #
    # NOTE: The printf is just aesthetics to keep inputfile layout
    #       where the options are in a 13-characters wide field
    local label oldString newString
    while [[ $# -gt 0 ]]; do
        label=''
        case $1 in
            measurements=* )
                oldString="ntr[[:space:]]+[0-9]+"
                newString="$(printf "%-13s%s" "ntr" "${1#*=}")"
                ;;
            intsteps0=* )
                # Need FindAndReplaceFirstOccurenceInInputFileAfterLabel
                # hence use awk => extended regex (also for grep)
                label='[[]Level 0[]]'
                oldString="nstep[[:space:]]+[0-9]+"
                newString="$(printf "%-13s%s" "nstep" "${1#*=}")"
                ;;
            intsteps1=* )
                # Need FindAndReplaceFirstOccurenceInInputFileAfterLabel
                # hence use awk => extended regex (also for grep)
                label='[[]Level 1[]]'
                oldString="nstep[[:space:]]+[0-9]+"
                newString="$(printf "%-13s%s" "nstep" "${1#*=}")"
                ;;
            #nPseudoFermions=* )
            #    oldString="nPseudoFermions=[0-9]+"
            #    newString="nPseudoFermions=${1#*=}"
            #    ;;
            * )
                Error 'An unknown string ' emph "${1%%=*}" ' was asked to be modified in the input file.\n'\
                      "Simulation cannot be continued. The value " emph "beta = ${runId}" " will be skipped!"
                BHMAS_problematicBetaValues+=( ${runId} )
                return 1 ;;
        esac
        if [[ "${label}" = '' ]]; then
            FindAndReplaceSingleOccurenceInInputFile "${oldString}" "${newString}" || return 1
        else
            FindAndReplaceFirstOccurenceInInputFileAfterLabel "${label}" "${oldString}" "${newString}" || return 1
        fi
        shift
    done
    return 0
}




MakeFunctionsDefinedInThisFileReadonly
