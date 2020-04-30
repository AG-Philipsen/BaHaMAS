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

function ExtractNumberOfTrajectoriesToBeDoneFromInputFile_openQCD-FASTSUM()
{
    local filename numberOfTrajectories
    filename="$1"
    numberOfTrajectories=$(sed -n 's/^ntr[[:space:]]\+\([1-9][0-9]\+\)/\1/p' "${filename}") #Option is either nHmcSteps or nRhmcSteps
    if [[ "${numberOfTrajectories}" = '' ]]; then
        Error 'Error occurred extracting number of trajectories from the input file\n'\
              file "${filename}"
        Fatal ${BHMAS_fatalLogicError} 'Unable to determine job walltime.'
    else
        printf "${numberOfTrajectories}"
    fi
}


MakeFunctionsDefinedInThisFileReadonly
