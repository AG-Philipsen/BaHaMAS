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

function ProduceInputFileAndJobScriptForEachBeta_SLURM()
{
    local betaValuesCopy index beta submitBetaDirectory temporaryNumberOfTrajectories
    betaValuesCopy=(${BHMAS_betaValues[@]})
    for index in "${!betaValuesCopy[@]}"; do
        local submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValuesCopy[${index}]}"
        if [[ -d "${submitBetaDirectory}" ]]; then
            if [[ $(ls ${submitBetaDirectory} | wc -l) -gt 0 ]]; then
                cecho lr "\n There are already files in " dir "${submitBetaDirectory}" ".\n The value " emph "beta = ${betaValuesCopy[${index}]}" " will be skipped!\n"
                BHMAS_problematicBetaValues+=( ${betaValuesCopy[${index}]} )
                unset -v 'betaValuesCopy[${index}]' #Here betaValuesCopy becomes sparse
                continue
            fi
        fi
    done
    if [[ ${#betaValuesCopy[@]} -eq 0 ]]; then
        return
    fi
    #Make betaValuesCopy not sparse
    betaValuesCopy=(${betaValuesCopy[@]})
    for beta in "${betaValuesCopy[@]}"; do
        submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${beta}"
        cecho -n b " Creating directory " dir "${submitBetaDirectory}" "..."
        mkdir -p ${submitBetaDirectory} || exit ${BHMAS_fatalBuiltin}
        cecho lg " done!"
        cecho lc "   Configuration used: " file "${BHMAS_startConfigurationGlobalPath[${beta}]}"
        if KeyInArray "${beta}" BHMAS_goalStatistics; then
            temporaryNumberOfTrajectories=${BHMAS_goalStatistics["${beta}"]}
        else
            temporaryNumberOfTrajectories=${BHMAS_numberOfTrajectories}
        fi
        ProduceInputFile_${BHMAS_lqcdSoftware} "${beta}" "${submitBetaDirectory}/${BHMAS_inputFilename}" ${temporaryNumberOfTrajectories}
    done
    mkdir -p ${BHMAS_submitDirWithBetaFolders}/${BHMAS_jobScriptFolderName} || exit ${BHMAS_fatalBuiltin}
    PackBetaValuesPerGpuAndCreateOrLookForJobScriptFiles "${betaValuesCopy[@]}"
}


MakeFunctionsDefinedInThisFileReadonly
