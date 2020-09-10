#!/usr/bin/env bash
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

#This is to have cecho functionality active here
readonly BHMAS_coloredOutput='TRUE'

#Retrieve information from git
readonly BHMAS_repositoryTopLevelPath="$(git -C $(dirname "${BASH_SOURCE[0]}") rev-parse --show-toplevel)"

#Load needed files
readonly BHMAS_filesToBeSourced=(
    "${BHMAS_repositoryTopLevelPath}/Generic_Code/UtilityFunctions.bash"
    "${BHMAS_repositoryTopLevelPath}/Generic_Code/OutputFunctionality.bash"
)
#Source error codes and fail with error hard coded since variable defined in file which is sourced!
source ${BHMAS_repositoryTopLevelPath}/Generic_Code/ErrorCodes.bash || exit 64
for fileToBeSourced in "${BHMAS_filesToBeSourced[@]}"; do
    source "${fileToBeSourced}" || exit ${BHMAS_fatalBuiltin}
done

#Check if being on a release branch -> https://stackoverflow.com/a/6245587
actualBranch="$(git rev-parse --abbrev-ref HEAD)"
if [[ ! ${actualBranch} =~ ^release/BaHaMAS-[0-9]+.[0-9]+.[0-9]+$ ]]; then
    Fatal ${BHMAS_fatalLogicError}\
          'You cannot bump version on the present branch ' emph "${actualBranch}"\
          ', because\nit is not a release branch with correct name, e.g. ' emph "release/BaHaMAS-1.0.0" '.'
fi

releaseDate="$(date +'%d %B %Y')"
newVersion="${actualBranch/#release\/BaHaMAS-/}"

#Parse command line options
if [[ $# -gt 1 ]]; then
    Fatal ${BHMAS_fatalCommandLine} 'Use this script giving optionally a release date as command line option (default: ' emph "${releaseDate}" ').'
elif [[ $# -eq 1  &&  "1" != '' ]]; then
    releaseDate="$1"
fi

# Information in manuals is in the first three lines, e.g.
#
#    % BaHaMAS(1) Version 0.2.0 | General User Manual
#    % Alessandro Sciarra
#    % 29 May 2020
#
# and we can act on them with sed.
cd "${BHMAS_repositoryTopLevelPath}/Manual_Pages/"
for manualPage in "BaHaMAS"*'.md'; do
    sed -i -e '1s/Version [0-9]\+.[0-9]\+.[0-9]\+/Version '"${newVersion}"'/' -e '3s/.*/% '"${releaseDate}"'/'  "${manualPage}"
done
if [[ -f 'Makefile' ]]; then
    make -j
fi
