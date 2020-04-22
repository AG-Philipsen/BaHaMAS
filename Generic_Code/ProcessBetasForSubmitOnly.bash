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

function ProcessBetaValuesForSubmitOnly()
{
    trap "$(shopt -p)" RETURN
    local betaValuesCopy index submitBetaDirectory runBetaDirectory\
          foldersThatMustExist filesThatMustExist object existingFiles
    betaValuesCopy=(${BHMAS_betaValues[@]})
    for index in "${!betaValuesCopy[@]}"; do
        submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValuesCopy[${index}]}"
        foldersThatMustExist=( "${submitBetaDirectory}" )
        filesThatMustExist=(
            "${submitBetaDirectory}/${BHMAS_inputFilename}"
            "${submitBetaDirectory}/${BHMAS_productionExecutableFilename}"
        )
        if [[ "${BHMAS_submitDiskGlobalPath}" != "${BHMAS_runDiskGlobalPath}" ]]; then
            runBetaDirectory="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValuesCopy[${index}]}"
            foldersThatMustExist+=( "${runBetaDirectory}" )
            filesThatMustExist+=(
                "${runBetaDirectory}/${BHMAS_inputFilename}"
                "${runBetaDirectory}/${BHMAS_productionExecutableFilename}"
            )
        fi
        for object in "${foldersThatMustExist[@]}"; do
            if [[ ! -d ${object} ]]; then
                Error "The directory\n" dir "${object}" '\ndoes not exist! '\
                      'The value ' emph "beta = ${betaValuesCopy[${index}]}" ' will be skipped!'
                BHMAS_problematicBetaValues+=( ${betaValuesCopy[${index}]} )
                unset -v 'betaValuesCopy[${index}]'
                continue 2
            fi
        done
        for object in "${filesThatMustExist[@]}"; do
            if [[ ! -f "${object}" ]]; then
                Error 'The file ' file "${object}" '\ndoes not exist! '\
                      'The value ' emph "beta = ${betaValuesCopy[${index}]}" ' will be skipped!'
                BHMAS_problematicBetaValues+=( ${betaValuesCopy[${index}]} )
                unset -v 'betaValuesCopy[${index}]'
                continue 2
            fi
        done
        #Now that we are sure that needed files and folders exist, look for extra files!
        shopt -s dotglob nullglob;  existingFiles=( "${submitBetaDirectory}"/* )
        if [[ "${BHMAS_submitDiskGlobalPath}" != "${BHMAS_runDiskGlobalPath}" ]]; then
            existingFiles+=( "${runBetaDirectory}"/* )
        fi
        for object in "${existingFiles[@]}"; do
            if ! ElementInArray "${object}" "${filesThatMustExist[@]}"; then
                Error -N 'There are files or folders in the following folder(s)\n'\
                      dir "${submitBetaDirectory}"
                if [[ "${BHMAS_submitDiskGlobalPath}" != "${BHMAS_runDiskGlobalPath}" ]]; then
                    Error -n -N -e dir "${runBetaDirectory}"
                fi
                Error -n -e 'beyond the input and executable files. The value ' emph\
                      "beta = ${betaValuesCopy[${index}]}" ' will be skipped!'
                BHMAS_problematicBetaValues+=( ${betaValuesCopy[${index}]} )
                unset -v 'betaValuesCopy[${index}]'
                continue 2
            fi
        done
    done
    if [[ ${#betaValuesCopy[@]} -gt 0 ]]; then
        PackBetaValuesPerGpuAndCreateOrLookForJobScriptFiles "${betaValuesCopy[@]}"
    fi
}


MakeFunctionsDefinedInThisFileReadonly
