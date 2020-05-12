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

#------------------------------------------------------------------------
# In this file BaHaMAS related functionality are collected.
# "BaHaMAS related" means that they make use of BaHaMAS
# global variable and they are then aware of BaHaMAS structure
# and conventions. If this is not the case, then the function
# should be moved to the "UtilityFunctions.bash" file.
#------------------------------------------------------------------------

function ExtractTrajectoryNumberFromConfigurationSymlink()
{
    local runId initialConfiguration index trNumber
    runId="$1"
    initialConfiguration=( "${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}/conf.${BHMAS_parametersString}_${BHMAS_betaPrefix}${runId%_*}"* )
    for index in "${#initialConfiguration[@]}"; do
        if [[ ! -L "${initialConfiguration[index]:-}" ]]; then
            unset -v 'initialConfiguration[index]'
        fi
    done
    if [[ ${#initialConfiguration[@]} -ne 1 ]]; then
        return 1
    else
        trNumber=${initialConfiguration[0]##*_trNr}
    fi
    printf '%d' ${trNumber}
}


MakeFunctionsDefinedInThisFileReadonly
