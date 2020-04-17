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

function ValidateParsedBetaValues()
{
    local modesThatRequireEntryInMetadataFile\
          modesThatRequireNoEntryInMetadata\
          runId software occurencesInFile\
          idAbsent idNotAbsent idToBeAdded\
          idMoreThanOnce
    declare -A wrongSoftware
    modesThatRequireEntryInMetadataFile=(
        'continue'
        'continue-thermalization'
        'measure'
        'submit-only'
        'acceptance-rate-report'
        'clean-output-files'
    )
    modesThatRequireNoEntryInMetadata=(
        'new-chain'
        'prepare-only'
        'thermalize'
    )

    #Perform checks on metadata file existence
    if ElementInArray ${BHMAS_executionMode#mode:} "${modesThatRequireEntryInMetadataFile[@]}"; then
        if [[ ! -f "${BHMAS_metadataFilename}" ]]; then
            Fatal ${BHMAS_fatalFileNotFound} 'Metadata file ' emph "${BHMAS_metadataFilename}" ' was not found but needed!'
        fi
    elif ElementInArray ${BHMAS_executionMode#mode:} "${modesThatRequireNoEntryInMetadata[@]}"; then
        if [[ ! -f "${BHMAS_metadataFilename}" ]]; then
            touch "${BHMAS_metadataFilename}"
        fi
    else
        Internal 'Function ' emph "${FUNCNAME}" ' called in wrong execution mode!'
    fi

    #Validate beta values: runId must appear at beginning of line!
    idMoreThanOnce=()
    idAbsent=()
    wrongSoftware=()
    idToBeAdded=()
    idNotAbsent=()
    for runId in "${BHMAS_betaValues[@]}"; do
        software=''
        occurencesInFile=$(grep -c "^${runId}" "${BHMAS_metadataFilename}" || true)
        if [[ ${occurencesInFile} -gt 1 ]]; then
            idMoreThanOnce+=( "${runId} (${occurencesInFile} occurrences)" )
            continue
        fi
        if ElementInArray ${BHMAS_executionMode#mode:} "${modesThatRequireEntryInMetadataFile[@]}"; then
            if [[ ${occurencesInFile} -eq 1 ]]; then
                software=$(awk -v id="${runId}" '$1 == id {print $2}' "${BHMAS_metadataFilename}")
                if [[ "${software}" != "${BHMAS_lqcdSoftware}" ]]; then
                    wrongSoftware+=( ["${runId}"]="${software}" )
                fi
            else
                idAbsent+=( "${runId}" )
            fi
        else # here no occurence should be in file
            idToBeAdded=()
            if [[ ${occurencesInFile} -eq 0 ]]; then
                idToBeAdded+=( "${runId}" )
                printf "%-40s%-25s# %s\n"\
                       "${runId}"\
                       "${BHMAS_lqcdSoftware}"\
                       "$(date +'%d.%m.%Y at %H:%M:%S')" >> "${BHMAS_metadataFilename}"
            else
                idNotAbsent+=( "${runId}" )
            fi
        fi
    done

    #Make report and terminate if wrong metadata were found
    if [[ ${#idMoreThanOnce[@]} -ne 0 ]]; then
        Error -N 'The following run ID(s) was/were found in ' emph "${BHMAS_metadataFilename}" ' file\n'\
              'several times and this should never happen (please adjust the file manually):'
        for runId in "${idMoreThanOnce[@]}"; do
            Error -n -N -e lo "   ${runId}"
        done
    fi
    if [[ ${#idAbsent[@]} -ne 0 ]]; then
        Error -N 'The following run ID(s) was/were not found in ' emph "${BHMAS_metadataFilename}" ' file,\n'\
              'but exactly one occurrence should exist in ' emph "${BHMAS_executionMode#mode:}" ' execution mode:'
        for runId in "${idAbsent[@]}"; do
            Error -n -N -e lo "   ${runId}"
        done
    fi
    if [[ ${#wrongSoftware[@]} -ne 0 ]]; then
        Error -N 'The following simulation(s) was/were found in ' emph "${BHMAS_metadataFilename}" ' file, but\n'\
              'was/were previously run with a different LQCD sofware than ' emph "${BHMAS_lqcdSoftware}" ':'
        for runId in "${!wrongSoftware[@]}"; do
            Error -n -N -e lo "   ${runId} (${wrongSoftware[${runId}]})"
        done
    fi
    if [[ ${#idNotAbsent[@]} -ne 0 ]]; then
        Error -N 'The following run ID(s) was/were found in ' emph "${BHMAS_metadataFilename}" ' file,\n'\
              'but no occurrence should exist in ' emph "${BHMAS_executionMode#mode:}" ' execution mode:'
        for runId in "${idNotAbsent[@]}"; do
            Error -n -N -e lo "   ${runId}"
        done
        Error -N -e 'If you previously run BaHaMAS in this mode and it failed or got interrupted, adjust\n'\
              'by hand the metadata file removing the line(s) reported above and run the script again.'
    fi
    if(( ${#idMoreThanOnce[@]} + ${#idAbsent[@]} + ${#wrongSoftware[@]} + ${#idNotAbsent[@]} > 0 )); then
        Fatal ${BHMAS_fatalLogicError} 'Incorrect metadata were found.'
    fi

    if [[ ${#idToBeAdded[@]} -ne 0 ]]; then
        for runId in "${idToBeAdded[@]}"; do
            printf "%-40s%-25s# %s\n"\
                   "${runId}"\
                   "${BHMAS_lqcdSoftware}"\
                   "$(date +'%d.%m.%Y at %H:%M:%S')" >> "${BHMAS_metadataFilename}"
        done
    fi
}
