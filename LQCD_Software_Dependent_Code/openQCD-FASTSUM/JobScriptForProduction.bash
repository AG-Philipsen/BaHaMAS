#
#  Copyright (c) 2015-2016 Christopher Czaban
#  Copyright (c) 2015-2018,2020 Alessandro Sciarra
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

function AddSoftwareSpecificPartToProductionJobScript_openQCD-FASTSUM()
{
    local jobScriptGlobalPath runId mpirunCommandOptions startingConfigurationFilename
    jobScriptGlobalPath="$1"; shift
    betaValues=( "$@" )

    # openQCD handles one beta per job!
    if [[ ${#betaValues[@]} -ne 1 ]]; then
        Internal 'More than one run ID given to function\n' emph "${FUNCNAME}"
    else
        runId="${betaValues[0]}"
    fi

    #Set additional command line options for openQCD executable
    mpirunCommandOptions=''
    case ${BHMAS_executionMode} in
        mode:thermalize | mode:new-chain | mode:prepare-only )
            # openQCD does not accept a global path as configuration filename and requires
            # that the configuration file is in one of the specified paths in the input
            # file. BaHaMAS creates then a symlink in the folder where the executable is
            # and it should then be safe to use here just the basename.
            if KeyInArray ${runId} BHMAS_startConfigurationGlobalPath; then
                startingConfigurationFilename="$(basename "${BHMAS_startConfigurationGlobalPath[${runId}]}")"
            else
                Internal 'Start configuration information was found unset for run ID\n'\
                         emph "${runId}" ' but needs to be specified to prepare the job\n'\
                         'script! Failure in function ' emph "${FUNCNAME}"
            fi
            if [[ "${startingConfigurationFilename}" != 'notFoundHenceStartFromHot' ]]; then
                mpirunCommandOptions+="-c ${startingConfigurationFilename}"
            fi
            ;;
        mode:continue* )
            # openQCD-FASTSUM takes care of using the last checkpoint which has
            # previously been prepared in the processing operations for continue
            mpirunCommandOptions+="-c -a"
            if [[ ! -f "${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}/${BHMAS_outputFilename}.rng" ]]; then
                mpirunCommandOptions+=" -seed ${RANDOM}"
            fi
            ;;
        * )
            Internal 'Unexpected execution mode in ' emph "${FUNCNAME}" '.'
            ;;
    esac

    # Determine needed information for checkpoint renaming mechanism
    # To be on the safe side, extract delta from the input file
    local deltaConfs initialConf index shiftConfs
    deltaConfs=$(ExtractGapBetweenCheckpointsFromInputFile "${runId}")
    # Extract initial tr. number either from initial configuration file
    # or from symbolic link to it. Note that the symbolic link is created
    # AFTER the job script and it cannot be always used.
    case ${BHMAS_executionMode} in
        mode:thermalize | mode:prepare-only | mode:new-chain )
            # Here the startingConfigurationFilename variable set above contains
            # a configuration filename from the thermalized pool -> use it
            if [[ "${startingConfigurationFilename}" = 'notFoundHenceStartFromHot' ]]; then
                shiftConfs=0
            else
                shiftConfs=${startingConfigurationFilename[0]##*_trNr}
            fi
            ;;
        mode:continue* )
            # Here we must use the symbolic link that must exist
            if ! shiftConfs=$(ExtractTrajectoryNumberFromConfigurationSymlink "${runId}"); then
                Fatal ${BHMAS_fatalLogicError}\
                      'Unable to find unique symbolic link to starting configuration in\n'\
                      dir "${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}"\
                      '\nto extract initial number for rename mechanism of checkpoints.'
            fi
            ;;
    esac

    # If in thermalization mode we want to add a function to copy the
    # last configuration to the pool together with its call
    local thermalizeFunction thermalizeFunctionCall thermalizeType
    if [[ ${BHMAS_executionMode} = 'mode:thermalize' ]] || [[ ${BHMAS_executionMode} = "mode:continue-thermalization" ]]; then
        if [[ ${BHMAS_betaPostfix} == "_thermalizeFromHot" ]]; then
            thermalizeType='fromHot'
        elif [[ ${BHMAS_betaPostfix} == "_thermalizeFromConf" ]]; then
            thermalizeType='fromConf'
        fi
        thermalizeFunction="function $(declare -f __static__BackupLastConfiguration)"
        thermalizeFunctionCall="__static__BackupLastConfiguration"
        thermalizeFunctionCall+=" \${runDir}"
        thermalizeFunctionCall+=" \"${BHMAS_thermConfsGlobalPath}\""
        thermalizeFunctionCall+=" \"${BHMAS_configurationPrefix//\\/}\""
        thermalizeFunctionCall+=" \"${BHMAS_configurationPrefix//\\/}${BHMAS_parametersString}_${BHMAS_betaPrefix}${runId%_*}_${thermalizeType}_trNr\""
    else
        thermalizeFunction=''
        thermalizeFunctionCall=''
    fi

    exec 5>&1 1>> "${jobScriptGlobalPath}"
    cat <<END_OF_JOBSCRIPT_FILE
#------------------------------------------------------------------------
shopt -s extglob nullglob
#------------------------------------------------------------------------
function $(declare -f __static__MonitorAndRenameCheckpointFiles)

# This function makes use of variables from the caller
#   - runPrefix
#   - checkpointGap
#   - checkpointShift
#   - processPid
#   - confPrefix
#   - prngPrefix
#   - dataPrefix
#   - digitsInCheckpoint
#   - timeLastCheckpoint
#   - sleepTime
# and changes the last two to adjust the monitoring times!
function $(declare -f __static__RenameCheckpointFiles)
#------------------------------------------------------------------------
function $(declare -f __static__BackupFile)
#------------------------------------------------------------------------
${thermalizeFunction}
#------------------------------------------------------------------------
export OMP_NUM_THREADS=\${SLURM_CPUS_PER_TASK}

submitDir="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}"
runDir="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}"
cd \${runDir}

printf "Running openQCD-FASTSUM from '\$(pwd)':\n"
printf '  mpirun \${submitDir}/${BHMAS_productionExecutableFilename} -i \${submitDir}/${BHMAS_inputFilename} -noms -noloc ${mpirunCommandOptions}\n\n'

mpirun \${submitDir}/${BHMAS_productionExecutableFilename} -i \${submitDir}/${BHMAS_inputFilename} -noms -noloc ${mpirunCommandOptions} &
pidRun=\${!}

__static__MonitorAndRenameCheckpointFiles "\${pidRun}" 10 "${BHMAS_outputFilename}" ${deltaConfs} ${shiftConfs} "${BHMAS_configurationPrefix//\\/}" "${BHMAS_prngPrefix//\\/}" "${BHMAS_dataPrefix//\\/}" ${BHMAS_checkpointMinimumNumberOfDigits} &
pidRename=\${!}

wait -n #Wait for the first process to finish
errorCodeFirst=\${?}

if kill -0 "\${pidRun}" 2>/dev/null && kill -0 "\${pidRename}" 2>/dev/null; then
    printf 'FATAL: Some child process finished, but neither openQCD-FASTSUM nor renaming mechanism!\n'
    exit 1
elif kill -0 "\${pidRun}" 2>/dev/null; then
    printf '\nFATAL: Renaming mechanism failed, terminating openQCD-FASTSUM and exiting job...\n'
    kill "\${pidRun}"
    exit 113
elif kill -0 "\${pidRename}" 2>/dev/null; then
    printf 'openQCD-FASTSUM exited, wait for renaming mechanism to finish...\n\n'
    wait "\${pidRename}"
    errorCodeSecond=\${?}
    printf "Renaming exit code: \${errorCodeSecond}\n"
    printf "open-QCD exit code: \${errorCodeFirst}\n"
    if [[ \${errorCodeFirst} -ne 0 ]] || [[ \${errorCodeSecond} -ne 0 ]]; then
        exit \$(( errorCodeFirst + errorCodeSecond ))
    fi
    __static__BackupFile "\${runDir}/${BHMAS_outputFilename}.log" "\${submitDir}"
    ${thermalizeFunctionCall}
fi

END_OF_JOBSCRIPT_FILE
    exec 1>&5-
}

function __static__MonitorAndRenameCheckpointFiles()
{
    local processPid sleepTime runPrefix checkpointGap checkpointShift\
          timeLastCheckpoint confPrefix prngPrefix dataPrefix digitsInCheckpoint
    processPid="$1"
    sleepTime="$2"
    runPrefix="$3"
    checkpointGap="$4"
    checkpointShift="$5"
    confPrefix="$6"
    prngPrefix="$7"
    dataPrefix="$8"
    digitsInCheckpoint="$9"
    timeLastCheckpoint="$(date +'%s')"
    printf "Starting monitoring and rename mechanism ($(date +'%d.%m.%Y %H:%M:%S')), sleep time = ${sleepTime}s\n"
    while kill -0 "${processPid}" 2>/dev/null; do
        sleep ${sleepTime}
        __static__RenameCheckpointFiles
    done
    __static__RenameCheckpointFiles
}

# This function makes use of variables from the caller
#   - runPrefix
#   - checkpointGap
#   - checkpointShift
#   - processPid
#   - confPrefix
#   - prngPrefix
#   - dataPrefix
#   - digitsInCheckpoint
#   - timeLastCheckpoint
#   - sleepTime
# and changes the last two to adjust the monitoring times!
function __static__RenameCheckpointFiles()
{
    local prngFile dataFile arrayOfConfs trajectoryNumber
    prngFile="${runPrefix}.rng~"
    dataFile="${runPrefix}.dat~"
    arrayOfConfs=( "${runPrefix}n"* )
    case ${#arrayOfConfs[@]} in
        0)
            return 0 ;;
        1)
            if [[ ! -f "${prngFile}" ]]; then
                printf "WARNING [${FUNCNAME}]: Found new configuration \"${arrayOfConfs[0]}\" but not the RNG state.\n"
                return 0
            fi
            if [[ ! -f "${dataFile}" ]]; then
                printf "WARNING [${FUNCNAME}]: Found new configuration \"${arrayOfConfs[0]}\" and correspondent RNG state but not the data file.\n"
                return 0
            fi
            sleepTime=$(( ($(date +'%s') - timeLastCheckpoint) / 5 ))
            [[ ${sleepTime} -lt 10 ]] && sleepTime=10 #Avoid to short sleep (e.g. in continue where a checkpoint is immediately there)
            timeLastCheckpoint=$(date +'%s')
            printf "Found new checkpoint to rename ($(date +'%d.%m.%Y %H:%M:%S')), new sleep time = ${sleepTime}s\n"
            trajectoryNumber=$(printf "%0${digitsInCheckpoint}d" $(( checkpointShift + checkpointGap * ${arrayOfConfs[0]#${runPrefix}n} )) )
            mv "${prngFile}"         "${prngPrefix}${trajectoryNumber}"  ||  exit 112
            mv "${dataFile}"         "${dataPrefix}${trajectoryNumber}"  ||  exit 112
            mv "${arrayOfConfs[0]}"  "${confPrefix}${trajectoryNumber}"  ||  exit 112
            ;;
        *)
            printf "ERROR [${FUNCNAME}]: Too many configurations created from the last check!\n"
            exit 113
            ;;
    esac
}

function __static__BackupFile()
{
    local sourceGlobalPath destinationFolderGlobalPath
    sourceGlobalPath="$1"
    destinationFolderGlobalPath="$2"
    if [[ ! -f "${sourceGlobalPath}" ]]; then
        printf 'ERROR [${FUNCNAME}]: No output file to be copied found!\n'
        exit 111
    fi
    cp "${sourceGlobalPath}" "${destinationFolderGlobalPath}/." || exit 111
}

function __static__BackupLastConfiguration()
{
    local sourceFolderGlobalPath destinationFolderGlobalPath\
          sourcePrefix destinationPrefix trNumber\
          sourceGlobalPath destinationGlobalPath
    sourceFolderGlobalPath="$1"
    destinationFolderGlobalPath="$2"
    sourcePrefix="$3"
    destinationPrefix="$4"
    sourceGlobalPath=$(printf '%s\n' "${sourceFolderGlobalPath}/${sourcePrefix}"+([0-9]) | sort -V | tail -n1)
    if [[ ! -f "${sourceGlobalPath}" ]]; then
        printf 'ERROR [${FUNCNAME}]: No configuration to be copied found!\n'
        exit 110
    fi
    trNumber="$(grep -o '[1-9][0-9]*$' <<< ${sourceGlobalPath})"
    destinationGlobalPath="${destinationFolderGlobalPath}/${destinationPrefix}${trNumber}"
    if [[ -f "${destinationGlobalPath}" ]]; then
        printf "ERROR [${FUNCNAME}]: Destination thermalized configuration already existing!\n"
        exit 110
    else
        cp "${sourceGlobalPath}" "${destinationGlobalPath}" || exit 111
    fi
}


MakeFunctionsDefinedInThisFileReadonly
