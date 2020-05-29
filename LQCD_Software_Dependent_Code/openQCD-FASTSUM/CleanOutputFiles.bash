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

function CleanOutputFilesForGivenSimulation_openQCD-FASTSUM()
{
    local runId outputFileGlobalPath outputFilePbpGlobalPath
    runId="$1"
    outputFileGlobalPath="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}/${BHMAS_outputFilename}.log"

    if [[ ! -f "${outputFileGlobalPath}" ]]; then
        Error 'File ' file "${outputFileGlobalPath}"\
              '\ndoes not exist! The simulation with ' emph "run ID = ${runId}" " will be skipped!"
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi
    cecho lc "\n ${BHMAS_betaPrefix}${runId}"

    if grep '^Trajectory no' "${outputFileGlobalPath}" | sort --numeric-sort --unique --check=silent --key 3,3 ; then
        cecho lm "   The file " file "$(basename "${outputFileGlobalPath}")" " has not to be cleaned!"
    else
        __static__CleanFile_openQCD-FASTSUM "${runId}" "${outputFileGlobalPath}" || return 1
    fi
}

function __static__CleanFile_openQCD-FASTSUM()
{
    local runId fileToBeCleaned backupGlobalPath
    runId="$1"
    fileToBeCleaned="$2"
    #Do a backup of the file
    backupGlobalPath="${fileToBeCleaned}_$(date +'%F_%H%M')"
    cp "${fileToBeCleaned}" "${backupGlobalPath}" || exit ${BHMAS_fatalBuiltin}

    awk -i inplace\
        'BEGIN{
            skip=0
        }
        {
            if( $0 ~ /^$/ )
            {
                # An empty line means trajectory finished, stop skipping
                # if it was skipping and next to avoid printing empty line
                if(skip==1)
                {
                    skip=0
                    next
                }
            }
            if( $0 ~ /^Trajectory no [1-9][0-9]*$/ )
            {
                trArray[$3]++
                if(trArray[$3] > 1)
                {
                    skip=1
                }
                else
                {
                    skip=0
                }
            }
            if(skip == 0)
            {
                print $0
            }
        }
    ' "${fileToBeCleaned}"

    if [[ $? -ne 0 ]]; then
        Error 'Problem occurred cleaning file ' file "$(basename "${fileToBeCleaned}")" '. Nothing will be changed.'
        mv "${backupGlobalPath}" "${fileToBeCleaned}" || exit ${BHMAS_fatalBuiltin}
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi
    cecho lg '   The file ' file "$(basename "${fileToBeCleaned}")" ' has been successfully cleaned!'\
          " [removed " B "$(($(wc -l < ${backupGlobalPath}) - $(wc -l < ${fileToBeCleaned})))" uB " line(s)]!"
}


MakeFunctionsDefinedInThisFileReadonly
