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

function CleanOutputFilesForGivenSimulation_CL2QCD()
{
    local runId outputFileGlobalPath outputFilePbpGlobalPath
    runId="$1"
    outputFileGlobalPath="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}/${BHMAS_outputFilename}"
    outputFilePbpGlobalPath="${outputFileGlobalPath}_pbp.dat"

    if [[ ! -f "${outputFileGlobalPath}" ]]; then
        Error 'File ' file "${outputFileGlobalPath}"\
              '\ndoes not exist! The simulation with ' emph "run ID = ${runId}" " will be skipped!"
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi
    cecho lc "\n ${BHMAS_betaPrefix}${runId}"

    if sort --numeric-sort --unique --check=silent --key 1,1 "${outputFileGlobalPath}"; then
        cecho lm "   The file " file "$(basename "${outputFileGlobalPath}")" " has not to be cleaned!"
    else
        __static__CleanFile "${runId}" "${outputFileGlobalPath}" "TRUE" || return 1
    fi

    if [[ -f "${outputFilePbpGlobalPath}" ]]; then
        if sort --numeric-sort --unique --check=silent --key 1,1 "${outputFilePbpGlobalPath}"; then
            cecho lm "   The file " file "$(basename "${outputFilePbpGlobalPath}")" " has not to be cleaned!"
        else
            __static__CleanFile "${runId}" "${outputFilePbpGlobalPath}" "FALSE" || return 1
        fi
    fi
}

function __static__CleanFile_CL2QCD()
{
    local runId fileToBeCleaned checkForSuspiciousTrajectories backupGlobalPath
    runId="$1"
    fileToBeCleaned="$2"
    checkForSuspiciousTrajectories="$3"
    #Do a backup of the file
    backupGlobalPath="${fileToBeCleaned}_$(date +'%F_%H%M')"
    cp "${fileToBeCleaned}" "${backupGlobalPath}" || exit ${BHMAS_fatalBuiltin}

    if [[ "${checkForSuspiciousTrajectories}" = 'TRUE' ]]; then
        __static__CheckFileForSuspiciousTrajectory "${fileToBeCleaned}" "${backupGlobalPath}"
    fi
    #Use sort command to clean the file: note that it is safe to give same input and output since the input file is read and THEN overwritten
    sort --numeric-sort --unique --key 1,1 --output="${fileToBeCleaned}" "${fileToBeCleaned}"
    if [[ $? -ne 0 ]]; then
        Error 'Problem occurred cleaning file ' file "$(basename "${fileToBeCleaned}")" '. Nothing will be changed.'
        mv "${backupGlobalPath}" "${fileToBeCleaned}" || exit ${BHMAS_fatalBuiltin}
        BHMAS_problematicBetaValues+=( ${runId} )
        return 1
    fi
    cecho lg '   The file ' file "$(basename "${fileToBeCleaned}")" ' has been successfully cleaned!'\
          " [removed " B "$(($(wc -l < ${backupGlobalPath}) - $(wc -l < ${fileToBeCleaned})))" uB " line(s)]!"
}

function __static__CheckFileForSuspiciousTrajectory()
{
    local fileToBeCleaned backupGlobalPath suspiciousTrajectory
    fileToBeCleaned="$1"
    backupGlobalPath="$2"
    #Check whether there is any trajectory repeated but with different observables
    # -> For CL2QCD the check is on columns 2,3,4 (plaquette) and 5,6,7 (Polyakov loop).
    suspiciousTrajectory=$(awk '
                               {
                                   val=$1
                                   array[val]++
                                   lineString=$2" "$3" "$4" "$5" "$6" "$7
                                   if(array[val]>1 && lineString != lineRest[val])
                                   {
                                       print val
                                       exit
                                   }
                                   lineRest[val]=lineString}' "${fileToBeCleaned}")
    if [[ "${suspiciousTrajectory}" != "" ]]; then
        Warning 'Found different observables for the same trajectory number in file '\
                file "$(basename "${fileToBeCleaned}")" ', first occurence at trajectory '\
                emph "${suspiciousTrajectory}" '.\nThe file will be cleaned anyway, use the backup file '\
                file "$(basename "${backupGlobalPath}")" ' in case of need.'
    fi
}


MakeFunctionsDefinedInThisFileReadonly
