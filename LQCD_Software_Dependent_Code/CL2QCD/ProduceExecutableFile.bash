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

function ProduceExecutableFileInGivenBetaDirectories_CL2QCD()
{
    local betaDirectoryGlobalPath destinationGlobalPath
    for betaDirectoryGlobalPath in "$@"; do
        if [[ ${BHMAS_executionMode} != 'mode:measure' ]]; then
            destinationGlobalPath="${betaDirectoryGlobalPath}/${BHMAS_productionExecutableFilename}"
            #In production the executable must not be there
            if [[ -f "${destinationGlobalPath}" ]]; then
                Internal 'Production executable file\n' file "${destinationGlobalPath}"\
                         '\nis already present in the directory\n' dir "${betaDirectoryGlobalPath}"\
                         'but it should not be the case in the function ' emph "${FUNCNAME}" '.'
            else
                cp "${BHMAS_productionExecutableGlobalPath}" "${destinationGlobalPath}" || exit ${BHMAS_fatalBuiltin}
            fi
        else
            destinationGlobalPath="${betaDirectoryGlobalPath}/${BHMAS_measurementExecutableFilename}"
            #In measurement the executable can be there because of possible job continuation
            cp "${BHMAS_measurementExecutableGlobalPath}" "${destinationGlobalPath}" || exit ${BHMAS_fatalBuiltin}
        fi
    done
}


MakeFunctionsDefinedInThisFileReadonly
