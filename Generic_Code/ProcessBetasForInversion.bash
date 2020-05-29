#
#  Copyright (c) 2015 Christopher Czaban
#  Copyright (c) 2016-2020 Alessandro Sciarra
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

function ProcessBetaValuesForInversion()
{
    local betaValuesToBeSubmitted beta runBetaDirectory numberOfConfigurationsInBetaDirectory\
          numberOfTotalCorrelators numberOfExistingCorrelators numberOfMissingCorrelators numberOfInversionCommands
    betaValuesToBeSubmitted=()
    for beta in ${BHMAS_betaValues[@]}; do
        runBetaDirectory="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${beta}"
        numberOfConfigurationsInBetaDirectory=$(find ${runBetaDirectory} -regex "${runBetaDirectory}/conf[.][0-9]*" | wc -l)
        numberOfTotalCorrelators=$((${numberOfConfigurationsInBetaDirectory} * ${BHMAS_numberOfSourcesForCorrelators}))
        numberOfExistingCorrelators=$(find ${runBetaDirectory} -regextype posix-extended -regex "${runBetaDirectory}/conf[.][0-9]*(_[0-9]+){4}_corr" | wc -l)
        numberOfMissingCorrelators=$((${numberOfTotalCorrelators} - ${numberOfExistingCorrelators}))
        ProduceMeasurementCommandsPerBeta "${runBetaDirectory}" "${beta}" "${runBetaDirectory}/${BHMAS_inversionSrunCommandsFilename}"
        numberOfInversionCommands=$(wc -l < ${runBetaDirectory}/${BHMAS_inversionSrunCommandsFilename})
        if [[ ${numberOfMissingCorrelators} -ne ${numberOfInversionCommands} ]]; then
            cecho lr "\n File with commands for inversion expected to contain " emph "${numberOfMissingCorrelators}"\
                  " lines, but having " emph "${numberOfInversionCommands}" ". The value " emph "beta = ${beta}" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( ${beta} )
            continue
        fi
        if [[ ! -s ${runBetaDirectory}/${BHMAS_inversionSrunCommandsFilename} ]] && [[ ${numberOfMissingCorrelators} -ne 0 ]]; then
            cecho lr "\n File with commands for inversion found to be " emph "empty" ", but expected to contain "\
                  emph "${numberOfMissingCorrelators}" " lines! The value " emph "beta = ${beta}" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( ${beta} )
            continue
        fi
        #If file seems fine put it to submit list
        betaValuesToBeSubmitted+=( ${beta} )
    done
    if [[ ${#betaValuesToBeSubmitted[@]} -ne 0 ]]; then
        mkdir -p ${BHMAS_submitDirWithBetaFolders}/${BHMAS_jobScriptFolderName} || exit ${BHMAS_fatalBuiltin}
        PackBetaValuesPerGpuAndCreateOrLookForJobScriptFiles "${betaValuesToBeSubmitted[@]}"
    fi
}


MakeFunctionsDefinedInThisFileReadonly
