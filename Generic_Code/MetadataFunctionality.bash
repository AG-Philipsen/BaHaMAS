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
    __static__ValidateMetadata
    if [[ ${BHMAS_useMPI} = 'TRUE' ]]; then
        if [[ ${#BHMAS_processorsGrid[@]} -ne 4 ]]; then
            case ${BHMAS_executionMode} in
                mode:continue* | mode:submit-only )
                    __static__SetProcessorGridFromExecutableName
                    ;;
                mode:new-chain | mode:prepare-only | mode:thermalize )
                    Internal 'A processor grid is required, but not available and not in continue* mode.'
                    ;;
            esac
        fi
        # Now we are sure the processor grid is set, we can complete executable name
        for index in "${BHMAS_processorsGrid[@]}"; do
            BHMAS_productionExecutableFilename+="_${index}"
        done
        readonly BHMAS_productionExecutableFilename
        readonly BHMAS_processorsGrid
    fi
}

function SetLqcdSoftwareFromMetadata()
{
    local runId occurencesInFile
    runId="$1"
    if [[ ! -f "${BHMAS_metadataFilename}" ]]; then
        return 1
    else
        occurencesInFile=$(grep -c "^${runId}" "${BHMAS_metadataFilename}" || true)
    fi
    if [[ ${occurencesInFile} -ne 1 ]]; then
        return 1
    else
        BHMAS_lqcdSoftware=$(awk -v id="${runId}" '$1 == id {print $2}' "${BHMAS_metadataFilename}")
    fi
}

function __static__ValidateMetadata()
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

function __static__SetProcessorGridFromExecutableName()
{
    local runId listOfGrids submitBetaDirectory executableGlobalPath grid
    listOfGrids=()
    for runId in "${BHMAS_betaValues[@]}"; do
        submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}"
        executableGlobalPath=( "${submitBetaDirectory}/${BHMAS_productionExecutableFilename}"* )
        if [[ ${#executableGlobalPath[@]} -ne 1 ]]; then
            Fatal ${BHMAS_fatalLogicError} 'Zero or more executable files were found in\n' dir "${submitBetaDirectory}"
        fi
        listOfGrids+=( "${executableGlobalPath/${submitBetaDirectory}\/${BHMAS_productionExecutableFilename}/}" )
    done
    for grid in "${listOfGrids[@]}"; do
        if [[ "${grid}" != "${listOfGrids[0]}" ]]; then
            Fatal 'Executable with different processors grid in executable names found\n'\
                  'in the betas folders that were selected. Impossible to continue.'
        fi
    done
    BHMAS_processorsGrid=( ${listOfGrids[0]//_/ } ) #Word splitting splits here the eleemnts
}


MakeFunctionsDefinedInThisFileReadonly
