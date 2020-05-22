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
    # Source all files for the scheduler. It is better than giving a fixed list, because
    # then implementation for different scheduler might differ, e.g. a feature may be
    # implemented for one scheduler only.
    __static__SourceFollowingFiles "${BHMAS_repositoryTopLevelPath}"/Scheduler_Dependent_Code/"${BHMAS_clusterScheduler}"/*.bash
}

function SourceLqcdSoftwareSpecificCode()
{
    # Here we do not know which software is going to be used, since source happens
    # before declaring global variables, including those of the user setup, among
    # which BHMAS_lqcdSoftware is. Hence, source here all implementations. It should
    # not hurt since each function name has the LQCD software in the name.
    __static__SourceFollowingFiles "${BHMAS_repositoryTopLevelPath}"/LQCD_Software_Dependent_Code/*/*.bash
}

# In this function we do manual error handling because the source
# command might fail and we do not get its output in such a case
# in case we let the -e shell option exit. Just to be on the safe
# side we manually check the exit code, too (I am not sure that it
# is really needed, though).
function __static__SourceFollowingFiles()
{
    local fileToBeSourced
    for fileToBeSourced in "$@"; do
        set +e
        source "${fileToBeSourced}"
        if [[ $? -ne 0 ]]; then
            Internal 'Error sourcing\n' file "${fileToBeSourced}"
        fi
        set -e
    done
}

#-------------------------------------------------------------------------------------------------------------------------#

function __static__CheckExistenceOfFunctionAndCallIt()
{
    local nameOfTheFunction
    nameOfTheFunction=$1; shift
    if [[ "$(type -t ${nameOfTheFunction})" = 'function' ]]; then
        ${nameOfTheFunction} "$@"
        # Return value propagates automatically since a function returns the last exit code!
    else
        Fatal ${BHMAS_fatalMissingFeature} "Function " emph "${nameOfTheFunction}" " not found!\n"\
              "Please provide an implementation following the " B "BaHaMAS" uB " documentation."
    fi
}

#-------------------------------------------------------------------------------------------------------------------------#

function AddSchedulerSpecificPartToJobScript()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_clusterScheduler} "$@"
}

function ExtractWalltimeFromJobScript()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_clusterScheduler} "$@"
}

function SubmitJob()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_clusterScheduler} "$@"
}

function GatherJobsInformationForJobStatusMode()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_clusterScheduler} "$@"
}

function GatherJobsInformationForSimulationStatusMode()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_clusterScheduler} "$@"
}

function GatherJobsInformationForContinueMode()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_clusterScheduler} "$@"
}

#-------------------------------------------------------------------------------------------------------------------------#

function PrepareSoftwareSpecificGlobalVariableValidation()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function PerformParametersSanityChecks()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function ProduceInputFile()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function ProduceExecutableFileInGivenBetaDirectories()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function ExtractNumberOfTrajectoriesToBeDoneFromInputFile()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function AddSoftwareSpecificPartToProductionJobScript()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function AddSoftwareSpecificPartToMeasurementJobScript()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function ProduceMeasurementCommandsPerBeta()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function HandleEnvironmentForContinueForGivenSimulation()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function RestoreRunBetaDirectoryBeforeSkippingBeta()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function HandleOutputFilesForContinueForGivenSimulation()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function HandleInputFileForContinueForGivenSimulation()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function ModifyOptionsInInputFile()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function FindAndSetNumberOfTrajectoriesAlreadyProduced()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function ExtractSimulationInformationFromInputFile()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}

function CheckCorrectnessOutputFile()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_${BHMAS_lqcdSoftware} "$@"
}



MakeFunctionsDefinedInThisFileReadonly
