#
#  Copyright (c) 2017-2018,2020 Alessandro Sciarra
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

function GetJobScriptFilename()
{
    local stringWithBetaValues; stringWithBetaValues="$1"

    if [[ ${BHMAS_executionMode} = 'mode:measure' ]]; then
        printf "${BHMAS_jobScriptPrefix}_${BHMAS_parametersString}__${stringWithBetaValues}_INV"
    else
        if [[ "${BHMAS_betaPostfix}" == "_thermalizeFromConf" ]]; then
            printf "${BHMAS_jobScriptPrefix}_${BHMAS_parametersString}__${stringWithBetaValues}_TC"
        elif [[ "${BHMAS_betaPostfix}" == "_thermalizeFromHot" ]]; then
            printf "${BHMAS_jobScriptPrefix}_${BHMAS_parametersString}__${stringWithBetaValues}_TH"
        else
            printf "${BHMAS_jobScriptPrefix}_${BHMAS_parametersString}__${stringWithBetaValues}"
        fi
    fi
}

function __static__GetJobBetasStringUsing()
{
    local beta betaValuesToBeUsed betasStringToBeReturned
    betaValuesToBeUsed=( $@ ); betasStringToBeReturned=""
    declare -A seedsOfSameBeta=()
    for beta in "${betaValuesToBeUsed[@]}"; do
        seedsOfSameBeta[${beta%%_*}]+="_$(awk '{split($0, res, "_"); print res[2]}' <<< "${beta}")"
    done
    #Here I iterate again on betaValuesToBeUsed and not on ${!seedsOfSameBeta[@]} in order to guarantee an order
    #in betasStringToBeReturned (remember that associative arrays keys are not sorted in general). Note that now
    #I have to use the same 'beta' only once and this is easily achieved unsetting the seedsOfSameBeta array
    #entry once used it
    for beta in "${betaValuesToBeUsed[@]}"; do
        beta=${beta%%_*}
        if KeyInArray ${beta} seedsOfSameBeta; then
            betasStringToBeReturned="${betasStringToBeReturned}__${BHMAS_betaPrefix}${beta}${seedsOfSameBeta[${beta}]}"
            unset 'seedsOfSameBeta[${beta}]'
        fi
    done
    if [[ ${BHMAS_useMultipleChains} == "FALSE" ]]; then
        betasStringToBeReturned="$(sed -e 's/___/_/g' -e 's/_$//' <<< "${betasStringToBeReturned}")"
    fi
    printf "${betasStringToBeReturned:2}" #I cut here the two initial underscores
}

function __static__ExtractNumberOfTrajectoriesToBeDoneFromFile()
{
    local filename numberOfTrajectories
    filename="$1"
    numberOfTrajectories=$(sed -n 's/^n\(H\|Rh\)mcSteps=\([0-9]\+\)/\2/p' "${filename}") #Option is either nHmcSteps or nRhmcSteps
    if [[ "${numberOfTrajectories}" = '' ]]; then
        Fatal ${BHMAS_fatalLogicError} "Number of trajectories to be done not present in input file " file "${filename}" "!"
    else
        printf "${numberOfTrajectories}"
    fi
}

function __static__CalculateWalltimeExtractingNumberOfTrajectoriesPerBetaAndUsingTimesPerTrajectoryIfGiven()
{
    #This function is called in a subshell and we want to be sure that exit on failure is valid also for one level further down
    set -euo pipefail

    local betaValues beta inputFileGlobalPath walltimesInSeconds finalWalltime
    betaValues=( "$@" ); walltimesInSeconds=()
    declare -A trajectoriesToBeDone=()
    if [[ "${BHMAS_walltime}" != '' ]]; then
        finalWalltime="${BHMAS_walltime}"
    elif [[ ${#BHMAS_timesPerTrajectory[@]} -eq 0 ]]; then
        Internal "Variable " emph "BHMAS_walltime" " empty and no time per trajectory from betas file!"\
                 "\nThis should have been avoided before in betas file parser!"
    else
        for beta in "${betaValues[@]}"; do
            inputFileGlobalPath="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${beta}/${BHMAS_inputFilename}"
            trajectoriesToBeDone["${beta}"]=$(__static__ExtractNumberOfTrajectoriesToBeDoneFromFile "${inputFileGlobalPath}")
            walltimesInSeconds+=( $(awk '{print $1*$2}' <<< "${trajectoriesToBeDone[${beta}]} ${BHMAS_timesPerTrajectory[${beta}]}") )
        done
        finalWalltime="$(SecondsToTimeStringWithDays $(MaximumOfArray ${walltimesInSeconds[@]}) )"
    fi
    GetSmallestWalltimeBetweenTwo "${finalWalltime}" "${BHMAS_maximumWalltime}"
}

function __static__CalculateWalltimeForInverter()
{
    if [[ "${BHMAS_walltime}" = '' ]]; then
        Warning "No walltime was specified for the inverter executable, using maximum walltime: " emph "${BHMAS_maximumWalltime}"
        printf "${BHMAS_maximumWalltime}"
    else
        printf "${BHMAS_walltime}"
    fi
}

function __static__SetExcludedNodesString()
{
    CheckIfVariablesAreSet excludeNodesString
    #Trying to retrieve information about the list of nodes to be excluded if user gave file
    if [[ "${BHMAS_excludeNodesGlobalPath}" != '' ]]; then
        set +e #Here we want to "allow" grep or ssh to fail, since there could e.g. be connection problems. Afterwards we check excludeString.
        if [[ -f "${BHMAS_excludeNodesGlobalPath}" ]]; then
            excludeString=$(grep -oE '\-\-exclude=.*\[.*\]' ${BHMAS_excludeNodesGlobalPath} 2>/dev/null)
            if [[ $? -eq 2 ]]; then
                Error "It was not possible to recover the exclude nodes list from " file "${BHMAS_excludeNodesGlobalPath}" " file!"
            fi
        elif [[ ${BHMAS_excludeNodesGlobalPath} =~ : ]]; then
            excludeString=$(ssh ${BHMAS_excludeNodesGlobalPath%%:*} "grep -oE '\-\-exclude=.*\[.*\]' ${BHMAS_excludeNodesGlobalPath#*:} 2>/dev/null")
            if [[ $? -eq 2 ]]; then
                Error "It was not possible to recover the exclude nodes list over ssh connection!"
            fi
        fi
        set -e
    fi
    if [[ "${excludeNodesString:-}" = "" ]]; then
        Warning -n "No string to exclude nodes in jobscript is available!"
        AskUser -n "         Do you still want to continue the jobscript creation?"
        if UserSaidNo; then
            cecho "\n" B lr "No job will be created. Exiting...\n"
            exit ${BHMAS_failureExitCode}
        fi
    fi
}

function __static__ProduceJobScript()
{
    local jobScriptGlobalPath walltime betaValues betaValue excludeNodesString
    jobScriptGlobalPath="$1"; walltime="$2"; shift 2
    betaValues=( "$@" )
    excludeNodesString=''
    __static__SetExcludedNodesString
    #Print to the screen the set of betas together with the excluded nodes if available
    cecho -n "  -"
    for betaValue in "${betaValues[@]}"; do
        cecho -n "    ${BHMAS_betaPrefix}${betaValue%_*}"
    done
    cecho "     ${excludeNodesString}"
    #Produce job script
    AddSchedulerSpecificPartToJobScript "${jobScriptGlobalPath}" "${walltime}" "${excludeNodesString}"
    if [[ ${BHMAS_executionMode} = 'mode:measure' ]]; then
        AddSoftwareSpecificPartToMeasurementJobScript "${jobScriptGlobalPath}" "${betaValues[@]}"
    else
        AddSoftwareSpecificPartToProductionJobScript "${jobScriptGlobalPath}" "${betaValues[@]}"
    fi
}

function PackBetaValuesPerGpuAndCreateOrLookForJobScriptFiles()
{
    local betaValuesToBeSplit betasForJobScript betasString jobScriptFilename jobScriptGlobalPath walltime
    betaValuesToBeSplit=( $@ )
    cecho lc "\n================================================================================="
    cecho bb " The following beta values have been grouped (together with the seed if used):"
    while [[ "${!betaValuesToBeSplit[@]}" != "" ]]; do
        betasForJobScript=(${betaValuesToBeSplit[@]:0:${BHMAS_GPUsPerNode}})
        betaValuesToBeSplit=(${betaValuesToBeSplit[@]:${BHMAS_GPUsPerNode}})
        betasString="$(__static__GetJobBetasStringUsing ${betasForJobScript[@]})"
        jobScriptFilename="$(GetJobScriptFilename ${betasString})"
        jobScriptGlobalPath="${BHMAS_submitDirWithBetaFolders}/${BHMAS_jobScriptFolderName}/${jobScriptFilename}"
        if [[ ${BHMAS_executionMode} != 'mode:submit-only' ]]; then
            if [[ -e ${jobScriptGlobalPath} ]]; then
                mv ${jobScriptGlobalPath} ${jobScriptGlobalPath}_$(date +'%F_%H%M') || exit ${BHMAS_fatalBuiltin}
            fi
            #Call the function to produce the jobscript file
            if [[ ${BHMAS_executionMode} = 'mode:measure' ]]; then
                walltime="$(__static__CalculateWalltimeForInverter)"
            else
                walltime="$(__static__CalculateWalltimeExtractingNumberOfTrajectoriesPerBetaAndUsingTimesPerTrajectoryIfGiven "${betasForJobScript[@]}")"
            fi
            __static__ProduceJobScript "${jobScriptGlobalPath}" "${walltime}" "${betasForJobScript[@]}"
            if [[ -e ${jobScriptGlobalPath} ]]; then
                BHMAS_betaValuesToBeSubmitted+=( "${betasString}" )
            else
                cecho lr "\n Jobscript " file "${jobScriptFilename}" " failed to be created! Skipping this job submission!\n"
                BHMAS_problematicBetaValues+=( "${betasString}" )
                continue
            fi
        else
            if [[ -e ${jobScriptGlobalPath} ]]; then
                BHMAS_betaValuesToBeSubmitted+=( "${betasString}" )
                cecho "  - ${betasString}"
            else
                cecho lr "\n Jobscript " file "${jobScriptFilename}" " not found! Option " emph "--submitonly" " cannot be applied! Skipping this job submission!\n"
                BHMAS_problematicBetaValues+=( "${betasString}" )
                continue
            fi
        fi
    done
    cecho lc "================================================================================="
}


MakeFunctionsDefinedInThisFileReadonly
