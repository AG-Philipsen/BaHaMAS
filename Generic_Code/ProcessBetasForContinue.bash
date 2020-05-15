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

#-----------------------------------------------------------------------------------#
# The following functions are called within the different software implementations  #
# of the continue mode, but they are general and are then collected here. Functions #
# called from within them are declared in the interface and need then a software    #
# specific implementation. Their interface is weak in the sense that they make      #
# use of local variables defined in the caller, e.g. the files globalpath defined   #
# in the ProcessBetaValuesForContinue function above.                               #
#-----------------------------------------------------------------------------------#
# NOTE: All following functions are designed to "skip a faulty beta" in the sense   #
#       of adding a run ID to the array BHMAS_problematicBetaValues and returning a #
#       non-zero value. Hence they are meant to be called with a || action to react #
#       on a failure and a skipped beta.                                            #
#-----------------------------------------------------------------------------------#

function HandleMeasurementsInInputFile()
{
    # There are different possibilities to set the number of measurements in the input file
    # and we have to decide a list of priorities:
    #   1) if the '--measurements' option is given, then it will be used. Otherwise,
    #   2) if the '--till=[number]' option is given, then it will be used. Otherwise,
    #   3) if the 'g[number]' field is present in the betas file, then it will be used. Otherwise,
    #   4) the measurement option in the input file is not modified!
    #
    CheckIfVariablesAreDeclared runId inputFileGlobalPath
    local optionsToBeAddedOrModified numberOfTrajectoriesAlreadyProduced
    if WasAnyOfTheseOptionsGivenToBaHaMAS '-m' '--measurements'; then
        optionsToBeAddedOrModified="measurements=${BHMAS_numberOfTrajectories}"
    elif [[ ${BHMAS_trajectoryNumberUpToWhichToContinue} -ne 0 ]]; then
        FindAndSetNumberOfTrajectoriesAlreadyProduced || return 1
        IsSimulationNotFinished ${numberOfTrajectoriesAlreadyProduced} ${BHMAS_trajectoryNumberUpToWhichToContinue} || return 1
        optionsToBeAddedOrModified="measurements=$(( BHMAS_trajectoryNumberUpToWhichToContinue - numberOfTrajectoriesAlreadyProduced ))"
    elif KeyInArray ${runId} BHMAS_goalStatistics; then
        FindAndSetNumberOfTrajectoriesAlreadyProduced || return 1
        IsSimulationNotFinished ${numberOfTrajectoriesAlreadyProduced} ${BHMAS_goalStatistics[${runId}]} || return 1
        optionsToBeAddedOrModified="measurements=$(( BHMAS_goalStatistics[${runId}] - numberOfTrajectoriesAlreadyProduced ))"
    else
        return 0
    fi
    ModifyOptionsInInputFile ${optionsToBeAddedOrModified} || return 1
    PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified}
    return 0
}

function IsSimulationNotFinished()
{
    CheckIfVariablesAreDeclared runId
    local startingStatistics goalStatistics
    startingStatistics=$1; goalStatistics=$2
    if [[ ${startingStatistics} -gt ${goalStatistics} ]]; then
        Error 'It was found that the number of trajectories done is ' emph "${startingStatistics} > ${goalStatistics} = goal trajectory"\
              '\nThe simulation cannot be continued. The value ' emph "beta = ${runId}" ' will be skipped!'
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    elif [[ ${startingStatistics} -eq ${goalStatistics} ]]; then
        if KeyInArray ${runId} BHMAS_trajectoriesToBeResumedFrom; then
            #If we resume from and simulation is finished, delete from std output the 'ATTENTION' line
            cecho -d -n "\e[1A\e[K"
        fi
        cecho lg " The simulation for " lo "beta = ${runId}" lg " seems to be finished, it will not be continued!"
        return 1
    fi
    return 0
}

function AddOptionsToInputFile()
{
    printf "%s\n" "$@" >> "${inputFileGlobalPath}" #One per line!
}

function PrintAddedOptionsToStandardOutput()
{
    __static__PrintAboutOptionsToStandardOutput "Added" "$@"
}

function PrintModifiedOptionsToStandardOutput()
{
    __static__PrintAboutOptionsToStandardOutput "Set" "$@"
}

function __static__PrintAboutOptionsToStandardOutput()
{
    local addedOrSet toInto label
    addedOrSet="${1:?Argument not properly passed to function ${FUNCNAME}}"; shift
    [[ ${addedOrSet} = 'Added' ]] && toInto='to' || toInto='into'
    if [[ $# -eq 1 ]]; then
        cecho wg "   ${addedOrSet} option " emph "$1" " ${toInto} the input file."
    else
        label="   ${addedOrSet} options "
        cecho wg "${label}" emph "$1"; shift
        while [[ $# -gt 1 ]]; do
            cecho wg "${label//?/ }" emph "$1"; shift
        done
        cecho wg "${label//?/ }" emph "$1" " ${toInto} the input file."
    fi
}

function FindAndReplaceSingleOccurenceInInputFile()
{
    if [[ $# -ne 2 ]]; then
        Internal "The function " emph "${FUNCNAME}" " has been wrongly called (" emph "3 arguments needed" ")!"
    fi
    local stringToBeFound replaceString filename
    stringToBeFound="$1"; replaceString="$2"
    filename="${inputFileGlobalPath}"
    if [[ $(grep -c "${stringToBeFound}" "${filename}") -eq 0 ]]; then
        Error 'The string ' emph "${stringToBeFound}" ' has ' emph 'not been found' ' in the input file.\n'\
              'The value ' emph "beta = ${runId}" ' will be skipped!'
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    elif [[ $(grep -c "${stringToBeFound}" ${filename}) -gt 1 ]]; then
        Error 'The string ' emph "${stringToBeFound}" ' occurs ' emph 'more than once' ' in the input file.\n'\
              'The value ' emph "beta = ${runId}" ' will be skipped!'
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi
    sed -i "s@${stringToBeFound}@${replaceString}@g" "${filename}" #function's return code is that of sed
}

function FindAndReplaceFirstOccurenceInInputFileAfterLabel()
{
    if [[ $# -ne 3 ]]; then
        Internal "The function " emph "${FUNCNAME}" " has been wrongly called (" emph "3 arguments needed" ")!"
    fi
    local label stringToBeFound replaceString filename
    label="$1"; stringToBeFound="$2"; replaceString="$3"
    filename="${inputFileGlobalPath}"
    if [[ $(grep -cE "${stringToBeFound}" "${filename}") -eq 0 ]]; then
        Error 'The string ' emph "${stringToBeFound}" ' has ' emph 'not been found' ' in the input file.\n'\
              'The value ' emph "beta = ${runId}" ' will be skipped!'
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    elif [[ $(grep -cE "${label}" "${filename}") -ne 1 ]]; then
        Error 'The label ' emph "${label}" ' has ' emph 'not been found exactly once' ' in the input file.\n'\
              'The value ' emph "beta = ${runId}" ' will be skipped!'
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi
    awk -i inplace\
        -v sectionRegex="${label}"\
        -v oldRegex="${stringToBeFound}"\
        -v newString="${replaceString}"\
        'BEGIN{sectionFound=0; replaced=0}
        {
            if(sectionFound==0)
            {
                print $0;
                if($0 ~ sectionRegex){sectionFound=1};
                next
            }
        }
        {
            if(sectionFound==1 && replaced==0)
            {
                if($0 ~ oldRegex)
                {
                    replaced=1;
                    printf "%s\n", newString
                } else {print $0};
                next
            }
        }
        replaced==1 {print $0}' "${inputFileGlobalPath}" #function's return code is that of awk
}


MakeFunctionsDefinedInThisFileReadonly
