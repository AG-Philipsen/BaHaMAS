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

function ProduceInputFileAndJobScriptForEachBeta()
{
    trap "$(shopt -p)" RETURN
    local betaValuesCopy index beta submitBetaDirectory existingFiles temporaryNumberOfTrajectories
    betaValuesCopy=(${BHMAS_betaValues[@]})
    for index in "${!betaValuesCopy[@]}"; do
        submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValuesCopy[${index}]}"
        if [[ -d "${submitBetaDirectory}" ]]; then
            shopt -s dotglob nullglob;  existingFiles=( "${submitBetaDirectory}"/* )
            if [[ ${#existingFiles[@]} -gt 0 ]]; then
                Error 'There are already files in\n' dir "${submitBetaDirectory}"\
                      '.\nThe value ' emph "beta = ${betaValuesCopy[${index}]}" ' will be skipped!'
                BHMAS_problematicBetaValues+=( ${betaValuesCopy[${index}]} )
                unset -v 'betaValuesCopy[${index}]' #Here betaValuesCopy becomes sparse
                continue
            fi
        fi
    done
    if [[ ${#betaValuesCopy[@]} -eq 0 ]]; then
        return
    fi
    betaValuesCopy=(${betaValuesCopy[@]}) #Make betaValuesCopy not sparse
    for beta in "${betaValuesCopy[@]}"; do
        submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${beta}"
        cecho -n b " Creating directory " dir "${submitBetaDirectory}" "..."
        mkdir -p "${submitBetaDirectory}" || exit ${BHMAS_fatalBuiltin}
        cecho lg " done!"
        cecho lc "   Configuration used: " file "${BHMAS_startConfigurationGlobalPath[${beta}]}"
        if KeyInArray "${beta}" BHMAS_goalStatistics; then
            temporaryNumberOfTrajectories=${BHMAS_goalStatistics["${beta}"]}
        else
            temporaryNumberOfTrajectories=${BHMAS_numberOfTrajectories}
        fi
        ProduceInputFile "${beta}" "${submitBetaDirectory}/${BHMAS_inputFilename}" ${temporaryNumberOfTrajectories}
    done
    mkdir -p ${BHMAS_submitDirWithBetaFolders}/${BHMAS_jobScriptFolderName} || exit ${BHMAS_fatalBuiltin}
    PackBetaValuesPerGpuAndCreateOrLookForJobScriptFiles "${betaValuesCopy[@]}"
}

function ProduceExecutableFileForEachBeta()
{
    local index beta submitBetaDirectory
    for index in "${!BHMAS_betaValues[@]}"; do
        submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${BHMAS_betaValues[${index}]}"
        if [[ ! -d "${submitBetaDirectory}" ]]; then
            Internal 'The directory ' dir "${submitBetaDirectory}"\
                     '\ndoes not exist but it should in function ' emph "${FUNCNAME}" '!'
        fi
    done
    for beta in "${BHMAS_betaValues[@]}"; do
        submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${beta}"
        ProduceExecutableFileInGivenBetaDirectory "${submitBetaDirectory}"
    done
}

function EnsureThatNeededFilesAreOnRunDiskForEachBeta()
{
    if [[ "${BHMAS_submitDiskGlobalPath}" != "${BHMAS_runDiskGlobalPath}" ]]; then
        local submitBetaDirectory runBetaDirectory inputFileGlobalPath\
              executableGlobalPath beta file
        for beta in "${BHMAS_betaValues[@]}"; do
            submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${beta}"
            runBetaDirectory="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${beta}"
            inputFileGlobalPath="${submitBetaDirectory}/${BHMAS_inputFilename}"
            if [[ ${BHMAS_executionMode} != 'mode:measure' ]]; then
                executableGlobalPath="${submitBetaDirectory}/${BHMAS_productionExecutableFilename}"
            else
                executableGlobalPath="${submitBetaDirectory}/${BHMAS_measurementExecutableFilename}"
            fi
            if [[ ! -d "${runBetaDirectory}" ]]; then
                cecho -n lg ' Creating directory ' dir "${runBetaDirectory}" '...'
                mkdir -p "${runBetaDirectory}" || exit ${BHMAS_fatalBuiltin}
                cecho lg ' done!'
            fi
            if [[ ${BHMAS_executionMode} != 'mode:measure' ]]; then
                __static__CheckExistenceOfFileAndCopyIt 'input' "${inputFileGlobalPath}" "${runBetaDirectory}"
            fi
            if [[ ${BHMAS_executionMode} != mode:continue* ]]; then
                __static__CheckExistenceOfFileAndCopyIt 'executable' "${executableGlobalPath}" "${runBetaDirectory}"
            else
                executableGlobalPath="${runBetaDirectory}/${BHMAS_productionExecutableFilename}"
                if [[ ! -f "${executableGlobalPath}" ]]; then
                    Fatal ${BHMAS_fatalFileNotFound} 'Executable file\n' file "${executableGlobalPath}"\
                          '\nwas not found but it is suppose to exist in ' emph "${BHMAS_executionMode#mode:}"\
                          ' execution mode!'
                fi
            fi
        done
    fi
}

function __static__CheckExistenceOfFileAndCopyIt()
{
    local label file destination
    label="$1"; file="$2"; destination="$3"
    if [[ ! -f "${file}" ]]; then
        Internal 'File ' file "${file}"\
                 '\ndoes not exist but it should in function ' emph "${FUNCNAME}" '!'
    fi
    cecho -n lg ' Copying ' emph "${label}" ' file to ' dir "${destination}" "..."
    cp "${file}" "${destination}" || exit ${BHMAS_fatalBuiltin}
    cecho lg " done!"
}



MakeFunctionsDefinedInThisFileReadonly
