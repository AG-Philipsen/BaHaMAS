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
    local betaFolderGlobalPath folderName parametersGlob initialConfiguration index trNumber
    betaFolderGlobalPath="$1"
    folderName="$(basename "${betaFolderGlobalPath}")"
    # NOTE: Leave glob match the seed (since it might be different in continue mode)
    #       and the parameters which might be different when this function is
    #       called in database mode through the ListSimulationsStatus function.
    IFS='*'; parametersGlob="${BHMAS_parameterPrefixes[*]}"; unset -v 'IFS'
    parametersGlob="${parametersGlob[@]//[*]/*_}*"
    initialConfiguration=( "${betaFolderGlobalPath}/conf."${parametersGlob}"_${folderName%%_*}"* )
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
