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

function ProcessBetaValuesForSubmitOnly_SLURM()
{
    local betaValuesCopy index submitBetaDirectory inputFileGlobalPath
    #-----------------------------------------#
    betaValuesCopy=(${BHMAS_betaValues[@]})
    for index in "${!betaValuesCopy[@]}"; do
        submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValuesCopy[${index}]}"
        inputFileGlobalPath="${submitBetaDirectory}/${BHMAS_inputFilename}"
        if [[ ! -d ${submitBetaDirectory} ]]; then
            cecho lr "\n The directory " dir "${submitBetaDirectory}" " does not exist! \n The value " emph "beta = ${betaValuesCopy[${index}]}" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( ${betaValuesCopy[${index}]} )
            unset -v 'betaValuesCopy[${index}]'
            continue
        else
            if [[ -f "${inputFileGlobalPath}" ]]; then
                # In the 'submitBetaDirectory' there should be ONLY the inputfile
                if [[ $(ls ${submitBetaDirectory} | wc -l) -gt 1 ]]; then
                    cecho lr "\n There are already files in " dir "${submitBetaDirectory}" " beyond the input file.\n"\
                          " The value " emph "beta = ${betaValuesCopy[${index}]}" " will be skipped!\n"
                    BHMAS_problematicBetaValues+=( ${betaValuesCopy[${index}]} )
                    unset -v 'betaValuesCopy[${index}]'
                    continue
                fi
            else
                cecho lr "\n The file " file "${inputFileGlobalPath}" " does not exist!\n The value " emph "beta = ${betaValuesCopy[${index}]}" " will be skipped!\n"
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
