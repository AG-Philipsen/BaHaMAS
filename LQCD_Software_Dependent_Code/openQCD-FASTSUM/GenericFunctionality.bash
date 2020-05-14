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

function ExtractGapBetweenCheckpointsFromInputFile()
{
    local runId inputFileGlobalPath deltaConfs
    runId="$1"
    inputFileGlobalPath="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}/${BHMAS_inputFilename}"
    deltaConfs=( $(sed -rn 's/^dtr_cnfg[[:space:]]+([1-9][0-9]*)/\1/p' "${inputFileGlobalPath}") )
    if [[ ${#deltaConfs[@]} -ne 1 && ! ${deltaConfs[0]} =~ ^[1-9][0-9]*$ ]]; then
        Fatal ${BHMAS_fatalLogicError}\
              'Unable to extract gap between checkpoints from\n' file\
              "${inputFileGlobalPath}" '\nin job script preparation for run ID ' emph "${runId}" '.'
    else
        printf '%s' ${deltaConfs[0]}
    fi
}


MakeFunctionsDefinedInThisFileReadonly
