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

# This function should find and validate the checkpoint required by the user in the betas file
#  INPUT: simulation ID
#  OUTPUT: set variables nameOfLastConfiguration, nameOfLastPRNG
#  Local variables from the caller: runBetaDirectory
#
# Exit codes: 0 if fine
#             1 if runId is problematic -> Added to BHMAS_problematicBetaValues array
function HandleEnvironmentForContinueForGivenSimulation_CL2QCD()
{
    local runId; runId="$1"
    CheckIfVariablesAreDeclared nameOfLastConfiguration nameOfLastPRNG runBetaDirectory

    if KeyInArray ${runId} BHMAS_trajectoriesToBeResumedFrom; then
        #NOTE: If the user wishes to resume from the last avialable checkpoint, then we have to find here which is
        #      the "last" valid one. Valid means that both the conf and the prng file are present with the same number
        if [[ ${BHMAS_trajectoriesToBeResumedFrom[${runId}]} = "last" ]]; then
            #comm expects alphabetically sorted input, then we sort numerically the output and we take the last number
            BHMAS_trajectoriesToBeResumedFrom[${runId}]=$(comm -12  <(ls -1 ${runBetaDirectory} | sed -n 's/^'"${BHMAS_configurationPrefix}"'0*\([1-9][0-9]*\)$/\1/p' | sort)\
                                                               <(ls -1 ${runBetaDirectory} | sed -n 's/^'"${BHMAS_prngPrefix}"'0*\([1-9][0-9]*\)$/\1/p' | sort) | sort -n | tail -n1)
            if [[ ! ${BHMAS_trajectoriesToBeResumedFrom[${runId}]} =~ ^[0-9]+$ ]]; then
                Error "Unable to find " emph "last valid checkpoint" " to resume from!\n" "The value " emph "beta = ${runId}" " will be skipped!"
                BHMAS_problematicBetaValues+=( ${runId} )
                return 1
            fi
        fi
        cecho lm B U "ATTENTION" uU ":" uB " The simulation for " B emph "beta = ${runId%_*}"\
              uB " will be resumed from trajectory " B emph "${BHMAS_trajectoriesToBeResumedFrom[${runId}]}" uB "."
        # TODO: Previously here was put an AskUser directive to prevent to mess up the folder moving files in Trash in case the user
        #       forgot some resumefrom label in betas file. It is however annoying when the user really wants to resume many simulations.
        #       Implement mechanism to undo file move/modification maybe trapping CTRL-C or acting in case of UserSaidNo at the end of this
        #       function (ideally asking the user again if he wants to restore everything as it was).

        nameOfLastConfiguration=$(printf "${BHMAS_configurationPrefix//\\/}%0${BHMAS_checkpointMinimumNumberOfDigits}d" "${BHMAS_trajectoriesToBeResumedFrom[${runId}]}")
        if [[ ! -f "${runBetaDirectory}/${nameOfLastConfiguration}" ]];then
            Error "Configuration " emph "${nameOfLastConfiguration}" " not found in "\
                  dir "${runBetaDirectory}" " folder.\n" "The value " emph "beta = ${runId}" " will be skipped!"
            BHMAS_problematicBetaValues+=( ${runId} )
            return 1
        fi
        nameOfLastPRNG=$(printf "${BHMAS_prngPrefix//\\/}%0${BHMAS_checkpointMinimumNumberOfDigits}d" "${BHMAS_trajectoriesToBeResumedFrom[${runId}]}")
        if [[ ! -f "${runBetaDirectory}/${nameOfLastPRNG}" ]]; then
            nameOfLastPRNG="" #If the prng.xxxxx is not found, use random seed
        fi
    elif [[ -f "${runBetaDirectory}/${BHMAS_configurationPrefix//\\/}${BHMAS_standardCheckpointPostfix}" ]]; then #If resumefrom has not been given use conf.save if present, otherwise use the last checkpoint
        nameOfLastConfiguration="${BHMAS_configurationPrefix//\\/}${BHMAS_standardCheckpointPostfix}"
        if [[ -f "${runBetaDirectory}/${BHMAS_prngPrefix//\\/}${BHMAS_standardCheckpointPostfix}" ]]; then
            nameOfLastPRNG="${BHMAS_prngPrefix//\\/}${BHMAS_standardCheckpointPostfix}"
        else
            nameOfLastPRNG=""
        fi
    else
        nameOfLastConfiguration=$(ls -1 ${runBetaDirectory} | sed -n '/^'"${BHMAS_configurationRegex}"'$/p' | sort -V | tail -n1)
        nameOfLastPRNG=$(ls -1 ${runBetaDirectory} | sed -n '/^'"${BHMAS_prngRegex}"'$/p' | sort -V | tail -n1)
    fi
    #The variable nameOfLastConfiguration should be set here, if not it means no conf was available!
    if [[ "${nameOfLastConfiguration}" == "" ]]; then
        Error "No configuration found in " dir "${runBetaDirectory}" ".\n" "The value " emph "beta = ${runId}" " will be skipped!"
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi
    if [[ "${nameOfLastPRNG}" = "" ]]; then
        Warning "No valid PRNG file for configuration " file "${BHMAS_betaPrefix}${runId}/${nameOfLastConfiguration}" " was found! Using a random seed."
    fi
    #Check that, in case the continue is done from a "numeric" configuration, the number of conf and prng is the same
    if [[ "${nameOfLastConfiguration}" =~ [.][0-9]+$ ]] && [[ "${nameOfLastPRNG}" =~ [.][0-9]+$ ]]; then
        if [[ $(sed 's/^0*//g' <<< "${nameOfLastConfiguration#*.}") -ne $(sed 's/^0*//g' <<< "${nameOfLastPRNG#*.}") ]]; then
            Error "The numbers of " emph "${BHMAS_configurationPrefix//\\/}xxxxx" " and "\
                  emph "${BHMAS_prngPrefix//\\/}xxxxx" " are different! Check the respective folder!\n"\
                  "The value " emph "beta = ${runId}" " will be skipped!"
            BHMAS_problematicBetaValues+=( ${runId} )
            return 1
        fi
    fi
    return 0
}

# This function should clean the simulation measurement files, depending on the
# checkpoint required by the user in the betas file
#  INPUT: simulation ID
#  OUTPUT: -
#  Local variables from the caller: runBetaDirectory outputFileGlobalPath
#                                   outputPbpFileGlobalPath trashFolderGlobalPath
#
# Exit codes: 0 if fine
#             1 if runId is problematic -> Added to BHMAS_problematicBetaValues array
function HandleOutputFilesForContinueForGivenSimulation_CL2QCD()
{
    local runId; runId="$1"
    CheckIfVariablesAreDeclared runBetaDirectory outputFileGlobalPath outputPbpFileGlobalPath trashFolderGlobalPath

    #If the option resumefrom is given in the betasfile we have to clean the ${runBetaDirectory}, otherwise just set the name of conf and prng
    if KeyInArray ${runId} BHMAS_trajectoriesToBeResumedFrom; then
        #If the BHMAS_outputFilename is not in the runBetaDirectory stop and not do anything else for this runId
        if [[ ! -f ${outputFileGlobalPath} ]]; then
            Error "File " file "${BHMAS_outputFilename}" " not found in " dir "${runBetaDirectory}" " folder.\n" "The value " emph "beta = ${runId}" " will be skipped!"
            BHMAS_problematicBetaValues+=( ${runId} )
            return 1
        fi
        #Now it should be feasable to resume simulation ---> clean runBetaDirectory
        #Create in runBetaDirectory a folder named Trash_$(date) where to mv all
        #the file produced after the traj. ${BHMAS_trajectoriesToBeResumedFrom[${runId}]}
        local filename numberFromFile prefix
        mkdir ${trashFolderGlobalPath} || exit ${BHMAS_fatalBuiltin}
        for filename in $(ls -1 ${runBetaDirectory} | sed -n -e '/^'"${BHMAS_configurationRegex}"'.*$/p' -e '/^'"${BHMAS_prngRegex}"'.*$/p'); do
            #Move to trash only 'conf.xxxxx(whatever)' or 'prng.xxxxx(whatever)' files with xxxxx larger than the resume from trajectory
            numberFromFile=$(sed -n 's/^\('"${BHMAS_configurationPrefix}"'\|'"${BHMAS_prngPrefix}"'\)0*\([1-9][0-9]*\).*$/\2/p' <<< "${filename}")
            if [[ ${numberFromFile} -gt ${BHMAS_trajectoriesToBeResumedFrom[${runId}]} ]]; then
                mv ${runBetaDirectory}/${filename} ${trashFolderGlobalPath}
            fi
        done
        #Move to trash conf.save(whatever) and prng.save(whatever) files if existing
        for prefix in ${BHMAS_configurationPrefix} ${BHMAS_prngPrefix}; do
            for filename in $(compgen -G "${runBetaDirectory}/${prefix}${BHMAS_standardCheckpointPostfix}*"); do
                mv ${filename} ${trashFolderGlobalPath}
            done
        done
        #Move the output file to Trash, and duplicate it parsing it in awk deleting all the trajectories after the resume-from one, included (if found)
        mv ${outputFileGlobalPath} ${trashFolderGlobalPath} || exit ${BHMAS_fatalBuiltin}
        if ! awk -v tr="${BHMAS_trajectoriesToBeResumedFrom[${runId}]}"\
             'BEGIN{found=1} $1<tr{print $0} $1==(tr-1){found=0} END{exit found}'\
             ${trashFolderGlobalPath}/$(basename ${outputFileGlobalPath}) > ${outputFileGlobalPath}; then
            Error "Measurement for trajectory " emph "$(( BHMAS_trajectoriesToBeResumedFrom[${runId}] - 1 ))" " not found in outputfile "\
                  emph "${outputFileGlobalPath}\n" "The value " emph "beta = ${runId}" " will be skipped!"
            RestoreRunBetaDirectoryBeforeSkippingBeta_CL2QCD
            BHMAS_problematicBetaValues+=( ${runId} )
            return 1
        fi
        #Make same operations on pbp file, if existing
        if [[ -f ${outputPbpFileGlobalPath} ]]; then
            mv ${outputPbpFileGlobalPath} ${trashFolderGlobalPath} || exit ${BHMAS_fatalBuiltin}
            if ! awk -v tr="${BHMAS_trajectoriesToBeResumedFrom[${runId}]}"\
                 'BEGIN{found=1} $1<tr{print $0} $1==(tr-1){found=0} END{exit found}'\
                 ${trashFolderGlobalPath}/$(basename ${outputPbpFileGlobalPath}) > ${outputPbpFileGlobalPath}; then
                Error "Measurement for trajectory " emph "$(( BHMAS_trajectoriesToBeResumedFrom[${runId}] - 1 ))" " not found in pbp outputfile "\
                      emph "${outputPbpFileGlobalPath}\n" "The value " emph "beta = ${runId}" " will be skipped!"
                RestoreRunBetaDirectoryBeforeSkippingBeta_CL2QCD
                BHMAS_problematicBetaValues+=( ${runId} )
                return 1
            fi
            #If the pbp file is non empty, add end of line to it to be sure the prompt is at the beginning of a new line
            if [[ $(wc -l < ${outputPbpFileGlobalPath}) -ne 0 ]]; then
                sed -i '$a\' ${outputPbpFileGlobalPath}
            fi
        fi
    fi
    return 0
}

# This function should do needed operations to restore the beta folder state
# for a followiung run of BaHaMAS so that no artificial error is later triggered
#
#  INPUT: runId
#  OUTPUT: -
#  Local variables from the caller used: runBetaDirectory trashFolderGlobalPath
#
# Exit codes: 0 if fine
#             1 if runId is problematic -> Added to BHMAS_problematicBetaValues array
function RestoreRunBetaDirectoryBeforeSkippingBeta_CL2QCD()
{
    local runId; runId="$1"
    CheckIfVariablesAreDeclared runBetaDirectory trashFolderGlobalPath
    # Not always the trash folder is created, only in case of 'r' in betas file
    if KeyInArray "${runId}" BHMAS_trajectoriesToBeResumedFrom; then
        mv "${trashFolderGlobalPath}/"* "${runBetaDirectory}" || exit ${BHMAS_fatalBuiltin}
        rmdir "${trashFolderGlobalPath}"                      || exit ${BHMAS_fatalBuiltin}
    fi
}

# This function should make the needed adjustments to the input file
#  INPUT: simulation ID
#  OUTPUT: -
#  Local variables from the caller: inputFileGlobalPath outputFileGlobalPath runBetaDirectory
#
# Exit codes: 0 if fine
#             1 if runId is problematic -> Added to BHMAS_problematicBetaValues array
function HandleInputFileForContinueForGivenSimulation_CL2QCD()
{
    local runId; runId="$1"
    CheckIfVariablesAreDeclared inputFileGlobalPath outputFileGlobalPath runBetaDirectory

    cecho lg '\n Adjusting input file ' emph "$(basename "${inputFileGlobalPath}")" ' for simulation at ' emph "beta = ${runId}" ':'
    HandleMeasurementsInInputFile                             || return 1
    __static__HandlePbpInInputFile_CL2QCD                     || return 1
    __static__HandleMultiplePseudofermionsInInputFile_CL2QCD  || return 1
    __static__HandleMassPreconditioningInInputFile_CL2QCD     || return 1
    __static__HandleStartConditionInInputFile_CL2QCD          || return 1
    __static__HandleStartConfigurationInInputFile_CL2QCD      || return 1
    __static__HandlePRNGStateInInputFile_CL2QCD               || return 1
    __static__HandleIntegrationStepsInInputFile_CL2QCD        || return 1
    __static__HandleFurtherOptionsInInputFile_CL2QCD          || return 1
}

#---------------------------------------------------------------------------------#
# All the following "static" funtions are supporting the above function. They use #
# non global variables defined as local outside them, e.g. runId from the caller. #
# Those that are not "static" are then in common to other software and called via #
# the interface in some generic function in the ProcessBetasForContinue.bash file.#
#---------------------------------------------------------------------------------#

function __static__HandlePbpInInputFile_CL2QCD()
{
    local measurePbpValueForInputFile string pbpStrings optionsToBeAddedOrModified
    if [[ ${BHMAS_measurePbp} = "FALSE" ]]; then
        measurePbpValueForInputFile=0
    elif [[ ${BHMAS_measurePbp} = "TRUE" ]]; then
        measurePbpValueForInputFile=1
    fi
    optionsToBeAddedOrModified=("measurePbp=${measurePbpValueForInputFile}")
    if [[ $(grep -c "measurePbp" ${inputFileGlobalPath}) -eq 0 ]]; then
        pbpStrings=( 'sourceType' 'sourceContent' 'nSources' 'pbpMeasurements' 'fermObsInSingleFile' 'fermObsPbpPrefix' )
        for string in "${pbpStrings[@]}"; do
            if [[ $(grep -c "${string}" ${inputFileGlobalPath}) -ne 0 ]]; then
                Error "The option " emph "measurePbp" " is not present in the input file but one or more specification about how to calculate\n"\
                      "the chiral condensate are present. Suspicious situation, investigate! The value " emph "beta = ${runId}" " will be skipped!"
                BHMAS_problematicBetaValues+=( ${runId} )
                return 1
            fi
        done
        optionsToBeAddedOrModified+=( "sourceType=volume" "sourceContent=gaussian" )
        if [[ ${BHMAS_wilson} = "TRUE" ]]; then
            optionsToBeAddedOrModified+=( "nSources=16" )
        elif [[ ${BHMAS_staggered} = "TRUE" ]]; then
            optionsToBeAddedOrModified+=( "nSources=1" "pbpMeasurements=8" "fermObsInSingleFile=1" "fermObsPbpPrefix=${BHMAS_outputFilename}" )
        fi
        AddOptionsToInputFile ${optionsToBeAddedOrModified[@]}
        PrintAddedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
    else
        #If measurePbp is in input file we assume that relative options are there and fine
        ModifyOptionsInInputFile_CL2QCD ${optionsToBeAddedOrModified[@]} || return 1
        PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
    fi
    return 0
}

function __static__HandleMultiplePseudofermionsInInputFile_CL2QCD()
{
    if [[ ${BHMAS_staggered} = "TRUE" ]]; then #Multiple pseudofermions simply ignored if not staggered
        local oldOption newOption optionsToBeAddedOrModified
        optionsToBeAddedOrModified=("nPseudoFermions=${BHMAS_numberOfPseudofermions}")
        if [[ $(grep -c "nPseudoFermions" ${inputFileGlobalPath}) -eq 0 ]]; then
            AddOptionsToInputFile ${optionsToBeAddedOrModified[@]}
            PrintAddedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
        else
            ModifyOptionsInInputFile_CL2QCD ${optionsToBeAddedOrModified[@]} || return 1
            PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
        fi
        #Always replace approx files with correct ones (maybe unnecessary, but easy to be done always)
        if [[ ${BHMAS_numberOfPseudofermions} -eq 1 ]]; then
            optionsToBeAddedOrModified=(
                "rationalApproxFileHB=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_Approx_Heatbath"
                "rationalApproxFileMD=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_Approx_MD"
                "rationalApproxFileMetropolis=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_Approx_Metropolis"
            )
        else
            optionsToBeAddedOrModified=(
                "rationalApproxFileHB=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_pf${BHMAS_numberOfPseudofermions}_Approx_Heatbath"
                "rationalApproxFileMD=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_pf${BHMAS_numberOfPseudofermions}_Approx_MD"
                "rationalApproxFileMetropolis=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_pf${BHMAS_numberOfPseudofermions}_Approx_Metropolis"
            )
        fi
        ModifyOptionsInInputFile_CL2QCD ${optionsToBeAddedOrModified[@]}
        PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
    fi
    return 0
}

function __static__HandleMassPreconditioningInInputFile_CL2QCD()
{
    if [[ ${BHMAS_wilson} = "TRUE" ]]; then #Mass preconditioning simply ignored if not Wilson
        local string massPreconditioningStrings optionsToBeAddedOrModified
        if KeyInArray ${runId} BHMAS_massPreconditioningValues; then
            optionsToBeAddedOrModified=("useMP=1")
            if [[ $(grep -c "useMP" ${inputFileGlobalPath}) -eq 0 ]]; then
                massPreconditioningStrings=(solverMP kappaMP integrator2 integrationSteps2)
                for string in "${massPreconditioningStrings[@]}"; do
                    if [[ $(grep -c "${string}" ${inputFileGlobalPath}) -ne 0 ]]; then
                        Error "The option " emph "useMP" " is not present in the input file but one or more specification about how to use\n"\
                              "mass preconditioning are present. Suspicious situation, investigate! The value " emph "beta = ${runId}" " will be skipped!"
                        BHMAS_problematicBetaValues+=( ${runId} )
                        return 1
                    fi
                done
                optionsToBeAddedOrModified+=("solverMP=cg" "kappaMP=0.${BHMAS_massPreconditioningValues[${runId}]#*,}"
                                             "integrator2=twomn" "integrationSteps2=${BHMAS_massPreconditioningValues[${runId}]%,*}")
                AddOptionsToInputFile ${optionsToBeAddedOrModified[@]}
                PrintAddedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
                optionsToBeAddedOrModified=("nTimeScales=3" "solverResiduumCheckEvery=10")
                ModifyOptionsInInputFile_CL2QCD ${optionsToBeAddedOrModified[@]} || return 1
                PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
            else
                #Here I assume that the specifications for mass preconditioning are already in the input file and I just modify them!
                #In any case, the function 'ModifyOptionsInInputFile_CL2QCD' will catch any missing option and the beta will be skipped
                optionsToBeAddedOrModified+=("kappaMP=0.${BHMAS_massPreconditioningValues[${runId}]#*,}" "nTimeScales=3"
                                             "intsteps2=${BHMAS_massPreconditioningValues[${runId}]%,*}" "solverResiduumCheckEvery=10")
                ModifyOptionsInInputFile_CL2QCD ${optionsToBeAddedOrModified[@]} || return 1
                PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
            fi
        else
            #Here check if mass preconditioning is in the input file and if so switch it off
            if [[ $(grep -c "useMP" ${inputFileGlobalPath}) -gt 0 ]]; then #Use '-gt 0' instead of '-eq 1' so that we also check multiple occurences
                optionsToBeAddedOrModified=("useMP=0" "solverResiduumCheckEvery=50" "nTimeScales=2")
                ModifyOptionsInInputFile_CL2QCD ${optionsToBeAddedOrModified[@]} || return 1
                PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
            fi
        fi
    fi
    return 0
}

function __static__HandleStartConditionInInputFile_CL2QCD()
{
    #Always convert startcondition in continue (and do not notify user, it is understood)
    ModifyOptionsInInputFile_CL2QCD "startCondition=continue" || return 1
    return 0
}

function __static__HandleStartConfigurationInInputFile_CL2QCD()
{
    local optionsToBeAddedOrModified
    optionsToBeAddedOrModified="initialConf=${runBetaDirectory}/${nameOfLastConfiguration}"
    if [[ $(grep -c "initialConf=[[:alnum:][:punct:]]*" ${inputFileGlobalPath}) -eq 0 ]]; then
        AddOptionsToInputFile ${optionsToBeAddedOrModified}
        PrintAddedOptionsToStandardOutput ${optionsToBeAddedOrModified}
    else
        #In order to use ModifyOptionsInInputFile_CL2QCD I have to escape the slashes in the path (for sed)
        ModifyOptionsInInputFile_CL2QCD ${optionsToBeAddedOrModified//\//\\\/} || return 1
        PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified}
    fi
    return 0
}

function __static__HandlePRNGStateInInputFile_CL2QCD()
{
    local optionsToBeAddedOrModified
    if [[ "${nameOfLastPRNG}" == "" ]]; then
        #Delete eventual line from input file with initialPRNG (here we must use a random seed)
        sed -i '/initialPRNG/d' ${inputFileGlobalPath}
        optionsToBeAddedOrModified="hostSeed=$(printf "%04d" $(( (RANDOM+1000)%10000 )) )"
        if [[ $(grep -c "hostSeed=[0-9]\{4\}" ${inputFileGlobalPath}) -eq 0 ]]; then
            AddOptionsToInputFile ${optionsToBeAddedOrModified}
            PrintAddedOptionsToStandardOutput ${optionsToBeAddedOrModified}
        else
            ModifyOptionsInInputFile_CL2QCD ${optionsToBeAddedOrModified} || return 1
            PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified}
        fi
    else
        #Delete eventual line from input file with hostSeed (here we use an initialPRNG)
        sed -i '/hostSeed/d' ${inputFileGlobalPath}
        optionsToBeAddedOrModified="initialPRNG=${runBetaDirectory}/${nameOfLastPRNG}"
        if [[ $(grep -c "initialPRNG=[[:alnum:][:punct:]]*" ${inputFileGlobalPath}) -eq 0 ]]; then
            AddOptionsToInputFile ${optionsToBeAddedOrModified}
            PrintAddedOptionsToStandardOutput ${optionsToBeAddedOrModified}
        else
            #In order to use ModifyOptionsInInputFile_CL2QCD I have to escape the slashes in the path (for sed)
            ModifyOptionsInInputFile_CL2QCD ${optionsToBeAddedOrModified//\//\\\/} || return 1
            PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified}
        fi
    fi
    return 0
}

function __static__HandleIntegrationStepsInInputFile_CL2QCD()
{
    local optionsToBeAddedOrModified
    #Always set the integrator steps, that could have changed or not
    optionsToBeAddedOrModified=("intsteps0=${BHMAS_scaleZeroIntegrationSteps[${runId}]}" "intsteps1=${BHMAS_scaleOneIntegrationSteps[${runId}]}")
    ModifyOptionsInInputFile_CL2QCD ${optionsToBeAddedOrModified[@]} || return 1
    PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
}

function __static__HandleFurtherOptionsInInputFile_CL2QCD()
{
    local commandLineOptionsToBeConsidered option optionsToBeAddedOrModified
    optionsToBeAddedOrModified=()
    #Here it is fine to assume option is the long one since short ones have been replaced
    # -> see Generic_Code/CommandLineParsers/ParserUtilities.bash file
    if ElementInArray '--checkpointEvery' "${BHMAS_specifiedCommandLineOptions[@]}"; then
        optionsToBeAddedOrModified+=( "checkpointEvery=${BHMAS_checkpointFrequency}" )
    fi
    if ElementInArray '--confSaveEvery' "${BHMAS_specifiedCommandLineOptions[@]}"; then
        optionsToBeAddedOrModified+=( "confSaveEvery=${BHMAS_savepointFrequency}" )
    fi
    if [[ ${#optionsToBeAddedOrModified[@]} -ne 0 ]]; then
        ModifyOptionsInInputFile_CL2QCD ${optionsToBeAddedOrModified[@]} || return 1
        PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
    fi
    return 0
}

function FindAndSetNumberOfTrajectoriesAlreadyProduced_CL2QCD()
{
    CheckIfVariablesAreDeclared runId nameOfLastConfiguration
    # OUTPUT: Set variable 'numberOfTrajectoriesAlreadyProduced'
    #
    # Strategy to recover the number of done trajectories in THIS coninueWithNewChain run (net of thermalization):
    #   1) Use the name of the last configuration to deduce the number of the last trajectory
    #      and use the symbolic link to the starting configuration to read off the number of the
    #      trajectories done in previous thermalization run(s). Otherwise,
    #   2) Try to extract the last trajectory number from within the configuration file
    #      (specific CL2QCD) and always the symbolic link for the starting trajectory. Otherwise,
    #   3) if the output file exists, use it (consider that it might be to be cleaned). Otherwise,
    #   4) print an error and skip beta.
    local initialConfiguration index initialTrNumber lastTrNumber
    initialTrNumber=''; lastTrNumber=''
    if initialTrNumber=$(ExtractTrajectoryNumberFromConfigurationSymlink "${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}"); then
        lastTrNumber="${nameOfLastConfiguration#${BHMAS_configurationPrefix//\\/}*(0)}" #extract number from the end without leading zeros
        if [[ ! "${lastTrNumber}" =~ ^[1-9][0-9]*$ ]]; then
            lastTrNumber="$(sed -n "s/^trajectory nr = \([1-9][0-9]*\)$/\1/p" ${runBetaDirectory}/${nameOfLastConfiguration} || true)"
        fi
    fi
    if [[ "${initialTrNumber}" =~ ^(0|[1-9][0-9]*)$ ]] && [[ "${lastTrNumber}" =~ ^[1-9][0-9]*$ ]]; then
        numberOfTrajectoriesAlreadyProduced=$(( lastTrNumber - initialTrNumber ))
        return 0
    fi
    # Fall back to case 3)
    if [[ -f "${outputFileGlobalPath}" ]]; then
        initialTrNumber=$(awk 'NR==1{print $1; exit}' "${outputFileGlobalPath}")
        lastTrNumber=$(awk 'END{print $1 + 1}' "${outputFileGlobalPath}") #The +1 is here necessary because the first tr. is supposed to be the number 0.
    fi
    if [[ "${initialTrNumber}" =~ ^(0|[1-9][0-9]*)$ ]] && [[ "${lastTrNumber}" =~ ^[1-9][0-9]*$ ]]; then
        numberOfTrajectoriesAlreadyProduced=$(( lastTrNumber - initialTrNumber ))
        return 0
    fi
    # Fall back to case 4)
    Error "It was not possible to deduce the number of already produced trajectories!\n" "The value " emph "beta = ${runId}" " will be skipped!"
    BHMAS_problematicBetaValues+=( ${runId} )
    return 1
}

function ModifyOptionsInInputFile_CL2QCD()
{
    # ATTENTION: Use Extended Regular Expression (ERE) here
    #            which are later enabled invoking grep/sed,
    #            while awk uses them by default.
    local oldString newString
    while [[ $# -gt 0 ]]; do
        case $1 in
            startCondition=* )
                oldString="startCondition=[[:alpha:]]+"
                newString="startCondition=${1#*=}"
                ;;
            initialConf=* )
                oldString="initialConf=[[:alnum:][:punct:]]*"
                newString="initialConf=${1#*=}"
                ;;
            initialPRNG=* )
                oldString="initialPRNG=[[:alnum:][:punct:]]*"
                newString="initialPRNG=${1#*=}"
                ;;
            hostSeed=* )
                oldString="hostSeed=[0-9]+"
                newString="hostSeed=${1#*=}"
                ;;
            intsteps0=* )
                oldString="integrationSteps0=[0-9]+"
                newString="integrationSteps0=${1#*=}"
                ;;
            intsteps1=* )
                oldString="integrationSteps1=[0-9]+"
                newString="integrationSteps1=${1#*=}"
                ;;
            f=* | checkpointEvery=* )
                oldString="createCheckpointEvery=[0-9]+"
                newString="createCheckpointEvery=${1#*=}"
                ;;
            F=* | confSaveEvery=* )
                oldString="overwriteTemporaryCheckpointEvery=[0-9]+"
                newString="overwriteTemporaryCheckpointEvery=${1#*=}"
                ;;
            m=* | measurements=* )
                oldString="mcSteps=[0-9]+"
                newString="mcSteps=${1#*=}"
                ;;  # This replacement works both with nHmcSteps and nRhmcSteps
            measurePbp=* )
                oldString="measurePbp=[0-9]+"
                newString="measurePbp=${1#*=}"
                ;;
            useMP=* )
                oldString="useMP=[0-9]+"
                newString="useMP=${1#*=}"
                ;;
            kappaMP=* )
                oldString="kappaMP=[0-9]+[.][0-9]+"
                newString="kappaMP=${1#*=}"
                ;;
            intsteps2=* )
                oldString="integrationSteps2=[0-9]+"
                newString="integrationSteps2=${1#*=}"
                ;;
            solverResiduumCheckEvery=* )
                oldString="solverResiduumCheckEvery=[0-9]+"
                newString="solverResiduumCheckEvery=${1#*=}"
                ;;
            nTimeScales=* )
                oldString="nTimeScales=[0-9]+"
                newString="nTimeScales=${1#*=}"
                ;;
            nPseudoFermions=* )
                oldString="nPseudoFermions=[0-9]+"
                newString="nPseudoFermions=${1#*=}"
                ;;
            rationalApproxFileHB=* )
                oldString="rationalApproxFileHB=[[:alnum:][:punct:]]*"
                newString="rationalApproxFileHB=${1#*=}"
                ;;
            rationalApproxFileMD=* )
                oldString="rationalApproxFileMD=[[:alnum:][:punct:]]*"
                newString="rationalApproxFileMD=${1#*=}"
                ;;
            rationalApproxFileMetropolis=* )
                oldString="rationalApproxFileMetropolis=[[:alnum:][:punct:]]*"
                newString="rationalApproxFileMetropolis=${1#*=}"
                ;;
            * )
                Error 'An unknown string ' emph "${1%%=*}" ' was asked to be modified in the input file.\n'\
                      "Simulation cannot be continued. The value " emph "beta = ${runId}" " will be skipped!"
                BHMAS_problematicBetaValues+=( ${runId} )
                return 1 ;;
        esac
        FindAndReplaceSingleOccurenceInInputFile "${oldString}" "${newString}" || return 1
        shift
    done
    return 0
}


MakeFunctionsDefinedInThisFileReadonly
