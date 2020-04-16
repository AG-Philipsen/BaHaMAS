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
    local modesThatRequireEntryInMetadataFile modesThatRequireNoEntryInMetadata\
          runId software occurencesInFile
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
    for runId in "${BHMAS_betaValues[@]}"; do
        occurencesInFile=$(grep -c "^${runId}" "${BHMAS_metadataFilename}" || true)
        if ElementInArray ${BHMAS_executionMode#mode:} "${modesThatRequireEntryInMetadataFile[@]}"; then
            if [[ ${occurencesInFile} -eq 1 ]]; then
                software=$(awk -v id="${runId}" '$1 == id {print $2}' "${BHMAS_metadataFilename}")
            else
                Fatal ${BHMAS_fatalLogicError}\
                      'Run ID ' emph "${runId}" ' was found zero or several times in metadata file,\n'\
                      'but it is needed to occur exactly one in ' emph "${BHMAS_executionMode#mode:}" 'mode.'
            fi
            if [[ "${software}" != "${BHMAS_lqcdSoftware}" ]]; then
                Fatal ${BHMAS_fatalLogicError}\
                      'Simulation with ID ' emph "${runId}" ' was run with ' emph "${software}"\
                      '\nbut BaHaMAS has been asked to use ' emph "${BHMAS_lqcdSoftware}" ' as LQCD software!'
            fi
        else # here no occurence should be in file
            if [[ ${occurencesInFile} -eq 0 ]]; then
                printf "%-40s%-25s# %s\n"\
                       "${runId}"\
                       "${BHMAS_lqcdSoftware}"\
                       "$(date +'%d.%m.%Y at %H:%M:%S')" >> "${BHMAS_metadataFilename}"
            else
                Fatal ${BHMAS_fatalLogicError}\
                      'Run ID ' emph "${runId}" ' was found in metadata file, but it should\n'\
                      'not occure in ' emph "${BHMAS_executionMode#mode:}" 'mode.'
            fi
        fi
    done
    cat $BHMAS_metadataFilename
}
