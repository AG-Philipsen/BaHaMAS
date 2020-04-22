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
    local betaValuesCopy index submitBetaDirectory inputFileGlobalPath existingFiles oldShopt
    #-----------------------------------------#
    betaValuesCopy=(${BHMAS_betaValues[@]})
    for index in "${!betaValuesCopy[@]}"; do
        submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValuesCopy[${index}]}"
        inputFileGlobalPath="${submitBetaDirectory}/${BHMAS_inputFilename}"
        if [[ ! -d ${submitBetaDirectory} ]]; then
            Error "The directory\n" dir "${submitBetaDirectory}" '\ndoes not exist! '\
                  'The value ' emph "beta = ${betaValuesCopy[${index}]}" ' will be skipped!'
            BHMAS_problematicBetaValues+=( ${betaValuesCopy[${index}]} )
            unset -v 'betaValuesCopy[${index}]'
            continue
        else
            shopt -s dotglob nullglob;  existingFiles=( "${submitBetaDirectory}"/* )
            if [[ -f "${inputFileGlobalPath}" ]]; then
                # In the 'submitBetaDirectory' there should be ONLY the inputfile
                if [[ ${#existingFiles[@]} -gt 1 ]]; then
                    Error 'There are already files in\n' dir "${submitBetaDirectory}"\
                          '\nbeyond the input file. The value ' emph\
                          "beta = ${betaValuesCopy[${index}]}" ' will be skipped!'
                    BHMAS_problematicBetaValues+=( ${betaValuesCopy[${index}]} )
                    unset -v 'betaValuesCopy[${index}]'
                    continue
                fi
            else
                Error 'The file ' file "${inputFileGlobalPath}"\
                      '\ndoes not exist! The value ' emph\
                      "beta = ${betaValuesCopy[${index}]}" ' will be skipped!'
                BHMAS_problematicBetaValues+=( ${betaValuesCopy[${index}]} )
                unset -v 'betaValuesCopy[${index}]'
                continue
            fi
        fi
    done
    if [[ ${#betaValuesCopy[@]} -gt 0 ]]; then
        PackBetaValuesPerGpuAndCreateOrLookForJobScriptFiles "${betaValuesCopy[@]}"
    fi
}


MakeFunctionsDefinedInThisFileReadonly
