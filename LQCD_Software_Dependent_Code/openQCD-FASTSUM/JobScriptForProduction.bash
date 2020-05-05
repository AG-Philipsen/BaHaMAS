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
    local jobScriptGlobalPath runId srunCommandOptions startingConfigurationGlobalPath
    jobScriptGlobalPath="$1"; shift
    betaValues=( "$@" )

    # openQCD handles one beta per job!
    if [[ ${#betaValues[@]} -ne 1 ]]; then
        Internal 'More than one run ID given to function\n' emph "${FUNCNAME}"
    else
        runId="${betaValues[0]}"
    fi
    # NOTE: Here we rely on the fact that the associative array BHMAS_startConfigurationGlobalPath
    #       has been filled at some stage before, either looking in the pool of configurations or
    #       handling the environment in case of being in continue mode -> check to be sure anyway!
    if ! KeyInArray ${runId} BHMAS_startConfigurationGlobalPath; then
        Internal\
            'Start configuration information was found unset for run ID\n'\
            emph "${runId}" ' but needs to be specified to prepare the job\n'\
            'script! Failure in function ' emph "${FUNCNAME}"
    else
        # openQCD does not accept a global path as configuration filename and requires
        # that the configuration file is in one of the specified paths in the input
        # file. BaHaMAS creates then a symlink in the folder where the executable is
        # and it should then be safe to use here just the basename.
        startingConfigurationGlobalPath="$(basename "${BHMAS_startConfigurationGlobalPath[${runId}]}")"
    fi
    srunCommandOptions=''
    case ${BHMAS_executionMode} in
        mode:thermalize | mode:new-chain | mode:prepare-only )
            if [[ "${startingConfigurationGlobalPath}" != 'notFoundHenceStartFromHot' ]]; then
                srunCommandOptions+="-c ${startingConfigurationGlobalPath}"
            fi
            ;;
        mode:continue* )
            if [[ "${startingConfigurationGlobalPath}" == 'resumeFromLast' ]]; then
                srunCommandOptions+="-c -a" # openQCD-FASTSUM takes care of using the last checkpoint
            else
                srunCommandOptions+="-c ${startingConfigurationGlobalPath} -a"
            fi
            ;;
        * )
            Internal 'Unexpected execution mode in ' emph "${FUNCNAME}" '.'
            ;;
    esac

    exec 5>&1 1>> "${jobScriptGlobalPath}"

    cat <<END_OF_JOBSCRIPT_FILE

export OMP_NUM_THREADS=\${SLURM_CPUS_PER_TASK}

submitDir="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}"
runDir="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}"
cd \${runDir}

echo "Running openQCD-FASTSUM from '\$(pwd)':"
echo '  mpirun \${submitDir}/${BHMAS_productionExecutableFilename} -i \${submitDir}/${BHMAS_inputFilename} -noms -noloc ${srunCommandOptions}'

mpirun \${submitDir}/${BHMAS_productionExecutableFilename} -i \${submitDir}/${BHMAS_inputFilename} -noms -noloc ${srunCommandOptions}
ERROR_CODE=\$?

if [ \${ERROR_CODE} -ne 0 ]; then
  echo "openQCD-FASTSUM failed with error code \${ERROR_CODE}. Exiting!"
  exit 112
fi

END_OF_JOBSCRIPT_FILE

    exec 1>&5-
}
