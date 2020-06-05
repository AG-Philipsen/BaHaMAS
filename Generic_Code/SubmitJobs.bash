#
#  Copyright (c) 2017,2020 Alessandro Sciarra
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

function SubmitJobsForValidBetaValues()
{
    if [[ ${#BHMAS_betaValuesToBeSubmitted[@]} -gt 0 ]]; then
        if [[ ${BHMAS_executionMode} = 'mode:thermalize' ]]; then
            AskUser "Check if everything is fine. Would you like to submit the jobs?"
            if UserSaidNo; then
                cecho lr "\n No job will be submitted!\n"
                exit ${BHMAS_successExitCode}
            fi
        fi
        local betaString stringToBeGreppedFor submittingDirectory jobScriptFilename usedCoresHours
        cecho lc "\n==================================================================================="
        cecho bb " Jobs will be submitted for the following beta values:"
        for betaString in ${BHMAS_betaValuesToBeSubmitted[@]}; do
            cecho "  - ${betaString}"
        done
        for betaString in ${BHMAS_betaValuesToBeSubmitted[@]}; do
            if [[ ${BHMAS_useMultipleChains} == "FALSE" ]]; then
                stringToBeGreppedFor="${BHMAS_betaPrefix}${BHMAS_betaRegex}"
            else
                stringToBeGreppedFor="${BHMAS_seedPrefix}${BHMAS_seedRegex}"
            fi
            if [[ $(grep -o "${stringToBeGreppedFor}" <<< "${betaString}" | wc -l) -ne ${BHMAS_simulationsPerJob} ]]; then
                cecho -n ly B "\n " U "WARNING" uU ":" uB " At least one job is being submitted with less than " emph "${BHMAS_simulationsPerJob}" " runs inside."
                AskUser "         Would you like to submit in any case?"
                if UserSaidNo; then
                    cecho lr B "\n No jobs will be submitted."
                    return
                fi
            fi
        done
        for betaString in ${BHMAS_betaValuesToBeSubmitted[@]}; do
            submittingDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_jobScriptFolderName}"
            jobScriptFilename="$(GetJobScriptFilename ${betaString})"
            cd ${submittingDirectory}
            if [[ -f "${jobScriptFilename}" ]]; then
                cecho ''
                if [[ ${BHMAS_useMPI} = 'TRUE' ]]; then
                    cecho wg ' To-be-used cores-h: '\
                          emph "$(__static__CalculateUsedCoreH "${submittingDirectory}/${jobScriptFilename}")"
                fi
                cecho bb '    Actual location: ' dir "$(pwd)"\
                      B '\n     Submitting job: ' uB emph "${jobScriptFilename}"
                SubmitJob "${jobScriptFilename}"
            else
                Internal "Jobscript " file "${jobScriptFilename}" " not found in\n"\
                         dir "${submittingDirectory}" " folder, but it should be there!"
            fi
        done
        cecho lc "==================================================================================="
    else
        cecho lr B "\n No jobs will be submitted.\n"
    fi
}

function __static__CalculateUsedCoreH()
{
    local jobScriptGlobalPath walltime usedNodes coreH unit index
    jobScriptGlobalPath="$1"
    walltime=$(ExtractWalltimeFromJobScript "${jobScriptGlobalPath}")
    if [[ "${walltime}" = '' ]]; then
        Internal 'Error extracting walltime in ' emph "${FUNCNAME}"
    fi
    usedNodes=$(CalculateProductOfIntegers ${BHMAS_processorsGrid[@]})
    if(( usedNodes % BHMAS_coresPerNode != 0 )); then
        (( usedNodes = (usedNodes + BHMAS_coresPerNode) / BHMAS_coresPerNode ))
    fi
    walltime=$(ConvertWalltimeToSeconds "${walltime}")
    coreH=$((  BHMAS_coresPerNode * usedNodes * walltime / 3600 ))
    unit=( '' 'k' 'M' 'G' 'P' 'T')
    index=0
    while [[ $(bc -l <<< "${coreH}>999") -eq 1 ]]; do
        coreH=$(awk '{printf "%.3f", $1/1000}' <<< "${coreH}")
        (( index++ ))
        [[ ${index} -eq 5 ]] && break
    done
    printf "%s ${unit[index]}core-h" ${coreH}
}


MakeFunctionsDefinedInThisFileReadonly
