#
#  Copyright (c) 2017,2020 Alessandro Sciarra
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

function SourceClusterSpecificCode()
{
    readonly BHMAS_clusterScheduler="$(SelectClusterSchedulerName)"
    local fileToBeSourced
    # Source all files for the scheduler. It is better than giving a fixed list, because
    # then implementation for different scheduler might differ, e.g. a feature may be
    # implemented for one scheduler only.
    for fileToBeSourced in "${BHMAS_repositoryTopLevelPath}"/Scheduler_Dependent_Code/"${BHMAS_clusterScheduler}"/*.bash; do
        if [[ -f "${fileToBeSourced}" ]]; then
            source "${fileToBeSourced}" # The if is due to avoid nullglob
        fi
    done
}

function SourceLqcdSoftwareSpecificCode()
{
    # Here we do not know which software is going to be used, since source happens
    # before declaring global variables, including those of the user setup, among
    # which BHMAS_lqcdSoftware is. Hence, source here all implementations. It should
    # not hurt since each function name has the LQCD software in the name.
    local fileToBeSourced
    for fileToBeSourced in "${BHMAS_repositoryTopLevelPath}"/LQCD_Software_Dependent_Code/*/*.bash; do
        if [[ -f "${fileToBeSourced}" ]]; then
            source "${fileToBeSourced}" # The if is due to avoid nullglob
        fi
    done
}

function __static__CheckExistenceOfFunctionAndCallIt()
{
    local nameOfTheFunction
    nameOfTheFunction=$1
    if [[ "$(type -t ${nameOfTheFunction})" = 'function' ]]; then
        ${nameOfTheFunction}
    else
        Fatal ${BHMAS_fatalMissingFeature} "Function " emph "${nameOfTheFunction}" " for " emph "${BHMAS_clusterScheduler}" " scheduler not found!\n"\
              "Please provide an implementation following the " B "BaHaMAS" uB " documentation and source the file."
    fi
}


function SubmitJob()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_clusterScheduler}
}

function GatherJobsInformationForJobStatusMode()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_clusterScheduler}
}

function GatherJobsInformationForSimulationStatusMode()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_clusterScheduler}
}

function GatherJobsInformationForContinueMode()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_clusterScheduler}
}


MakeFunctionsDefinedInThisFileReadonly
