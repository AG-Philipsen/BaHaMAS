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

function ProduceInputFile_openQCD-FASTSUM()
{
    Warning "Function $FUNCNAME not yet implemented!"
    local betaValue inputFileGlobalPath numberOfTrajectoriesToBeDone massAsNumber
    betaValue="$1"
    inputFileGlobalPath="$2"
    numberOfTrajectoriesToBeDone=$3
    rm -f ${inputFileGlobalPath} || exit ${BHMAS_fatalBuiltin}
    touch ${inputFileGlobalPath} || exit ${BHMAS_fatalBuiltin}
    if [[ $(grep -c "[.]" <<< "${BHMAS_mass}") -eq 0 ]]; then
        massAsNumber="0.${BHMAS_mass}"
    else
        massAsNumber="${BHMAS_mass}"
    fi

}
