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

function AddSchedulerSpecificPartToJobScript_SLURM()
{
    local jobScriptGlobalPath walltime jobScriptFilename excludeNodesDirective\
          hardwareDirective partitionDirective nodelistDirective gresDirective\
          constraintDirective outputAndErrorFilename
    jobScriptGlobalPath="$1"; walltime="$2"; excludeNodesDirective="$3"; shift 3
    jobScriptFilename="$(basename "${jobScriptGlobalPath}")"
    if [[ ${BHMAS_GPUsPerNode} != '' ]]; then
        hardwareDirective="#SBATCH --ntasks=${BHMAS_simulationsPerJob}"
    else
        local numberOfNodes numberOfProcessors
        numberOfProcessors=$(CalculateProductOfIntegers ${BHMAS_processorsGrid[@]})
        numberOfNodes=$(( numberOfProcessors / BHMAS_coresPerNode ))
        hardwareDirective="#SBATCH --nodes=${numberOfNodes}
#SBATCH --ntasks=${numberOfProcessors}
#SBATCH --ntasks-per-node=${BHMAS_coresPerNode}
#SBATCH --cpus-per-task=1"
    fi
    if [[ "${excludeNodesDirective}" =~ ^(|--exclude=)$ ]]; then
        excludeNodesDirective=''
    else
        excludeNodesDirective="#SBATCH ${excludeNodesDirective}"
    fi
    if [[ "${BHMAS_clusterPartition}" != '' ]]; then
        partitionDirective="#SBATCH --partition=${BHMAS_clusterPartition}"
    fi
    if [[ "${BHMAS_clusterNode}" != '' ]]; then
        nodelistDirective="#SBATCH --nodelist=${BHMAS_clusterNode}"
    fi
    if [[ "${BHMAS_clusterGenericResource}" != '' ]]; then
        gresDirective="#SBATCH --gres=${BHMAS_clusterGenericResource}"
    fi
    if [[ "${BHMAS_clusterConstraint}" != '' ]]; then
        constraintDirective="#SBATCH --constraint=${BHMAS_clusterConstraint}"
    fi
    if [[ "${BHMAS_lqcdSoftware}" = 'mode:measure' ]]; then
        outputAndErrorFilename="${BHMAS_measurementExecutableFilename}"
    else
        outputAndErrorFilename="${BHMAS_productionExecutableFilename}"
    fi

    exec 5>&1 1> "${jobScriptGlobalPath}"
    cat <<END_OF_INPUTFILE
#!/bin/bash

#SBATCH --job-name=${jobScriptFilename#${BHMAS_jobScriptPrefix}_}
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=${BHMAS_userEmail}
#SBATCH --time=${walltime}
#SBATCH --output=${outputAndErrorFilename}.%j.out
#SBATCH --error=${outputAndErrorFilename}.%j.err
#SBATCH --no-requeue
${hardwareDirective}
${excludeNodesDirective}
${partitionDirective:-}
${nodelistDirective:-}
${gresDirective:-}
${constraintDirective:-}

END_OF_INPUTFILE
    exec 1>&5-
}
