#
#  Copyright (c) 2015 Christopher Czaban
#  Copyright (c) 2015-2018,2020 Alessandro Sciarra
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

function __static__CheckWhetherAnySimulationForGivenBetaValuesIsAlreadyEnqueued()
{
    local jobsInformation runId jobString betaString seedString regex abort
    #Fill jobsInformation array with jobID@jobName@jobStatus
    GatherJobsInformationForContinueMode
    for runId in ${BHMAS_betaValues[@]}; do
        betaString="${BHMAS_betaPrefix}${runId%%_*}"
        seedString="$(cut -d'_' -f2 <<< "${runId}")"
        regex="^.*${BHMAS_parametersString}.*${betaString}.*${seedString}.*(RUNNING|PENDING)\$"
        abort=1
        for jobString in "${jobsInformation[@]}"; do
            if [[ ${jobString} =~ ${regex} ]]; then
                Error "The simulation " emph "${BHMAS_betaPrefix}${runId}" " seems to be " emph "${jobString##*@}" " with " emph "job-id = ${jobString%%@*}" "."
                abort=0
            fi
        done
    done
    if [[ ${abort} -eq 0 ]]; then
        Fatal ${BHMAS_fatalLogicError}\
              "Some simulation to be continued are either running or pending.\n"\
              "BaHaMAS cannot procede in contiue mode with the given betas."
    else
        return 0
    fi
}

function __static__SetBetaRelatedPathVariables()
{
    local runId; runId="$1"
    runBetaDirectory="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}"
    submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}"
    inputFileGlobalPath="${submitBetaDirectory}/${BHMAS_inputFilename}"
    outputFileGlobalPath="${runBetaDirectory}/${BHMAS_outputFilename}"
    outputPbpFileGlobalPath="${outputFileGlobalPath}_pbp.dat"
    return 0
}

function __static__CheckWhetherAnyRequiredFileOrFolderIsMissing()
{
    CheckIfVariablesAreDeclared runBetaDirectory submitBetaDirectory inputFileGlobalPath
    local runId; runId="$1"
    if [[ ! -d ${runBetaDirectory} ]]; then
        Error "The directory " dir "${runBetaDirectory}" " does not exist!\n" "The value " emph "beta = ${runId}" " will be skipped!"
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    elif [[ ! -d ${submitBetaDirectory} ]]; then
        Error "The directory " dir "${submitBetaDirectory}" " does not exist!\n" "The value " emph "beta = ${runId}" " will be skipped!"
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    elif [[ ! -f ${inputFileGlobalPath} ]]; then
        Error "The file " file "${inputFileGlobalPath}" " does not exist!\n" "The value " emph "beta = ${runId}" " will be skipped!"
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi
    return 0
}

function __static__MakeTemporaryCopyOfOriginalInputFile()
{
    #Make a temporary copy of the input file that will be used to restore in case the original input file.
    #This is to avoid to modify some parameters and then skip beta because of some error leaving the input file modified!
    #If the beta is skipped this temporary file is used to restore the original input file, otherwise it is deleted.
    originalInputFileGlobalPath="${inputFileGlobalPath}_original"
    cp ${inputFileGlobalPath} ${originalInputFileGlobalPath} || exit ${BHMAS_fatalBuiltin}
}

function __static__RestoreOriginalInputFile()
{
    mv ${originalInputFileGlobalPath} ${inputFileGlobalPath} || exit ${BHMAS_fatalBuiltin}
}

function __static__RemoveOriginalInputFile()
{
    rm ${originalInputFileGlobalPath} || exit ${BHMAS_fatalBuiltin}
}


function ProcessBetaValuesForContinue()
{
    local runId runBetaDirectory submitBetaDirectory inputFileGlobalPath outputFileGlobalPath outputPbpFileGlobalPath\
          betaValuesToBeSubmitted nameOfLastConfiguration nameOfLastPRNG originalInputFileGlobalPath
    betaValuesToBeSubmitted=()
    nameOfLastConfiguration=''
    nameOfLastPRNG=''
    __static__CheckWhetherAnySimulationForGivenBetaValuesIsAlreadyEnqueued
    for runId in ${BHMAS_betaValues[@]}; do
        cecho ''
        # Preliminary general checks
        __static__SetBetaRelatedPathVariables                  ${runId} || continue
        __static__CheckWhetherAnyRequiredFileOrFolderIsMissing ${runId} || continue
        # LQCD software specific operations
        HandleEnvironmentForContinueForGivenSimulation ${runId} || continue
        HandleOutputFilesForContinueForGivenSimulation ${runId} || continue
        __static__MakeTemporaryCopyOfOriginalInputFile
        if ! HandleInputFileForContinueForGivenSimulation ${runId}; then
            __static__RestoreOriginalInputFile
            continue
        fi
        __static__RemoveOriginalInputFile
        betaValuesToBeSubmitted+=( ${runId} )
    done
    if [[ ${#betaValuesToBeSubmitted[@]} -ne 0 ]]; then
       mkdir -p ${BHMAS_submitDirWithBetaFolders}/${BHMAS_jobScriptFolderName} || exit ${BHMAS_fatalBuiltin}
       PackBetaValuesPerGpuAndCreateOrLookForJobScriptFiles "${betaValuesToBeSubmitted[@]}"
       #Ask the user if he want to continue submitting job
       AskUser "Check if the continue option did its job correctly. Would you like to submit the jobs?"
       if UserSaidNo; then
           cecho lr B "\n No jobs will be submitted.\n"
           exit ${BHMAS_successExitCode}
       fi
    fi
}


MakeFunctionsDefinedInThisFileReadonly
