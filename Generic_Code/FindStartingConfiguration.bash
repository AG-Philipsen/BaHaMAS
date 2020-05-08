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

function SetBetaPostfixDependingOnExistingThermalizedConfigurations()
{
    local confGlobalPathPrefix foundConfigurations
    #Here we fix the beta postfix just looking for thermalized conf from hot at the actual parameters (no matter at which beta);
    #if at least one configuration thermalized from hot is present, it means the thermalization has to be done from conf (the
    #correct beta to be used is selected then later in the script ---> see where the array BHMAS_startConfigurationGlobalPath is filled
    #
    # TODO: If a thermalization from hot is finished but one other crashed and one wishes to resume it, the postfix should be
    #       from Hot but it is from conf since in ${BHMAS_thermConfsGlobalPath} a conf from hot is found. Think about how to fix this.
    confGlobalPathPrefix="${BHMAS_thermConfsGlobalPath}/conf.${BHMAS_parametersString}"
    foundConfigurations=( "${confGlobalPathPrefix}_${BHMAS_betaPrefix}"${BHMAS_betaGlob}"_${BHMAS_seedPrefix}"${BHMAS_seedGlob}"_fromHot_trNr"+([0-9]) )
    if [[ ${#foundConfigurations[@]} -eq 0 ]]; then
        BHMAS_betaPostfix="_thermalizeFromHot"
    else
        BHMAS_betaPostfix="_thermalizeFromConf"
    fi
}

function FindConfigurationGlobalPathFromWhichToStartTheSimulation()
{
    local runId foundConfigurations confGlobalPathPrefix
    confGlobalPathPrefix="${BHMAS_thermConfsGlobalPath}/conf.${BHMAS_parametersString}"
    for runId in "${BHMAS_betaValues[@]}"; do
        case ${BHMAS_betaPostfix} in
            _continueWithNewChain )
                foundConfigurations=( "${confGlobalPathPrefix}_${BHMAS_betaPrefix}${runId%_*}_fromConf_trNr"+([0-9]) )
                case ${#foundConfigurations[@]} in
                    0)
                        Warning "No valid starting configuration found for " emph "beta = ${runId%_*}" "\n"\
                                "in " dir "${BHMAS_thermConfsGlobalPath}" ".\n"\
                                "Looking for configuration with not exactely the same seed."
                        foundConfigurations=( "${confGlobalPathPrefix}_${BHMAS_betaPrefix}${runId%%_*}_${BHMAS_seedPrefix}"${BHMAS_seedGlob}"_fromConf_trNr"+([0-9]) )
                        case ${#foundConfigurations[@]} in
                            0)
                                Fatal ${BHMAS_fatalFileNotFound} " none found!"
                                ;;
                            1)
                                cecho lg " Found a valid one!"
                                BHMAS_startConfigurationGlobalPath[${runId}]="${foundConfigurations[0]}"
                                ;;
                            *)
                                cecho -d o " More than one configuration were found! Which should be used?\n" lp
                                __static__PickUpStartingConfigurationAmongAvailableOnes
                                ;;
                        esac
                        ;;
                    1)
                        BHMAS_startConfigurationGlobalPath[${runId}]="${foundConfigurations[0]}"
                        ;;
                    *)
                        Warning "More than one valid starting configuration found for " emph "beta = ${runId%%_*}" " in \n"\
                                dir "${BHMAS_thermConfsGlobalPath}" ".\nWhich should be used?"
                        cecho -d -n lp; __static__PickUpStartingConfigurationAmongAvailableOnes
                        ;;
                esac
                ;;

            _thermalizeFromConf )
                foundConfigurations=( "${confGlobalPathPrefix}_${BHMAS_betaPrefix}${runId%_*}_fromConf_trNr"+([0-9]) )
                if [[ ${#foundConfigurations[@]} -ne 0 ]]; then
                    Fatal ${BHMAS_fatalFileExists}\
                          "It seems that there is already a thermalized configuration \"fromConf\" for " emph "beta = ${runId%_*}" " in\n"\
                          dir "${BHMAS_thermConfsGlobalPath}" "!"
                fi
                foundConfigurations=( "${confGlobalPathPrefix}_${BHMAS_betaPrefix}"${BHMAS_betaGlob}"_${BHMAS_seedPrefix}"${BHMAS_seedGlob}"_fromHot_trNr"+([0-9]) )
                case ${#foundConfigurations[@]} in
                    0)
                        Internal 'No starting configuration found in ' emph "${FUNCNAME}"\
                                 '\nalthough the beta postfix is set to ' emph "${BHMAS_betaPostfix}" "."
                        ;;
                    1)
                        BHMAS_startConfigurationGlobalPath[${runId}]="${foundConfigurations[0]}"
                        ;;
                    *)
                        local confName betaValue closestBeta
                        declare -A foundConfigurationsWithBetaAsKey=()
                        for confName in "${foundConfigurations[@]}"; do
                            betaValue="${confName#${confGlobalPathPrefix}_${BHMAS_betaPrefix}}"
                            betaValue="${betaValue%%_*}"
                            foundConfigurationsWithBetaAsKey["${betaValue}"]="${confName}"
                        done
                        local closestBeta=$(FindValueOfClosestElementInArrayToGivenValue ${runId%%_*} "${!foundConfigurationsWithBetaAsKey[@]}")
                        if [[ "${closestBeta}" = "" ]]; then
                            Internal "Something went wrong determinig the closest beta value\n"\
                                     "to the actual one to pick up the correct thermalized configuration from hot!"
                        fi
                        BHMAS_startConfigurationGlobalPath[${runId}]="${foundConfigurationsWithBetaAsKey[${closestBeta}]}"
                        ;;
                esac
                ;;

            _thermalizeFromHot )
                BHMAS_startConfigurationGlobalPath[${runId}]="notFoundHenceStartFromHot"
                ;;

            * )
                Internal "BHMAS_betaPostfix set to unknown value " emph "\"${BHMAS_betaPostfix}\"" " in ${FUNCNAME} function!"
                ;;
        esac
    done
}

function __static__PickUpStartingConfigurationAmongAvailableOnes()
{
    CheckIfVariablesAreDeclared foundConfigurations runId
    local selectedConfiguration
    PS3=$(cecho -d "\n" yg "Enter the number corresponding to the desired configuration: " lp)
    select selectedConfiguration in "${foundConfigurations[@]}"; do
        if ! ElementInArray "${selectedConfiguration}" "${foundConfigurations[@]}"; then
            continue
        else
            break
        fi
    done
    cecho "" #Restore default color
    BHMAS_startConfigurationGlobalPath[${runId}]="${selectedConfiguration}"
}


MakeFunctionsDefinedInThisFileReadonly
