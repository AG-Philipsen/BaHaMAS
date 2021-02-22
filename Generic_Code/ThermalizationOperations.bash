#
#  Copyright (c) 2020-2021 Alessandro Sciarra
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
    # Here we fix the beta postfix just looking for thermalized conf from hot at the actual parameters (no matter at which beta).
    # If at least one thermalized configuration from hot is present, it means the thermalization has to be done from conf (the
    # correct beta to be used is selected then later in the script -> see where the array BHMAS_startConfigurationGlobalPath is filled).
    #
    # NOTE: In the GlobalVariables.bash file, the BHMAS_betaPostfix is declared and initialized to '_continueWithNewChain'.
    #       Here it is supposed to be overwritten according to configurations pool state. However, if the user wishes to do
    #       a thermalization from hot and some is already existing, then a fromConf one would be done. Hence the --fromHot
    #       command line option. This has to be considered here. Hence the if-clause to understand if the postfix was changed
    #       in the parser or not.
    if [[ ${BHMAS_betaPostfix} = '_continueWithNewChain' ]]; then
       confGlobalPathPrefix="${BHMAS_thermConfsGlobalPath}/conf.${BHMAS_parametersString}"
       foundConfigurations=( "${confGlobalPathPrefix}_${BHMAS_betaPrefix}"${BHMAS_betaGlob}"_${BHMAS_seedPrefix}"${BHMAS_seedGlob}"_fromHot_trNr"+([0-9]) )
       if [[ ${#foundConfigurations[@]} -eq 0 ]]; then
           BHMAS_betaPostfix="_thermalizeFromHot"
       else
           BHMAS_betaPostfix="_thermalizeFromConf"
       fi
       readonly BHMAS_betaPostfix
    fi
}

function DeactivatePbpMeasurementIfNotExplicitlyRequiredByTheUser()
{
    if [[ ${BHMAS_thermalizeForcePbpMeasurement} = 'TRUE' ]]; then
        Warning -N "Measurement of PBP asked to be switched ON during thermalization!"
        readonly BHMAS_measurePbp='TRUE'
    elif [[ ${BHMAS_lqcdSoftware} != 'openQCD-FASTSUM' ]] && [[ ${BHMAS_measurePbp} = 'TRUE' ]]; then
        Warning -N "Measurement of PBP switched off during thermalization!"
        readonly BHMAS_measurePbp='FALSE'
    fi
}


MakeFunctionsDefinedInThisFileReadonly
