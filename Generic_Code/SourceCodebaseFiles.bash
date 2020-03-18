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

function __static__SourceCodebaseGeneralFiles()
{
    readonly BHMAS_userSetupFile="${BHMAS_repositoryTopLevelPath}/Generic_Code/UserSpecificVariables.bash"
    local schedulerIndependentFiles fileToBeSourced
    #Source error codes and fail with error hard coded since variable defined in file which is sourced!
    source "${BHMAS_repositoryTopLevelPath}/Generic_Code/ErrorCodes.bash" || exit 64
    schedulerIndependentFiles=(
        'UtilityFunctions.bash'
        'AcceptanceRateReport.bash'
        'CheckGlobalVariables.bash'
        'CleanOutputFiles.bash'
        'CommandLineParsers/CommonFunctionality.bash'
        'CommandLineParsers/MainParser.bash'
        'CommandLineParsers/DatabaseParser.bash'
        'Database/ProjectStatisticsDatabase.bash'
        'FindSchedulerInUse.bash'
        'FindStartingConfiguration.bash'
        'JobScriptFunctionality.bash'
        'GlobalVariables.bash'
        'InterfaceToSpecificCode.bash'
        'OperationsOnBetasFile.bash'
        'OutputFunctionality.bash'
        'PathManagementFunctionality.bash'
        'PrintJobsInformation.bash'
        'ProcessBetasForContinue.bash'
        'ProcessBetasForSubmitOnly.bash'
        'ProcessBetasForInversion.bash'
        'ProduceFilesForEachBeta.bash'
        'ReportOnProblematicBetas.bash'
        'SimulationsStatus.bash'
        'SubmitJobs.bash'
        'Setup/Setup.bash'
        'SystemRequirements.bash'
        'Version.bash'
    )
    for fileToBeSourced in "${schedulerIndependentFiles[@]}"; do
        source "${BHMAS_repositoryTopLevelPath}/Generic_Code/${fileToBeSourced}" || exit ${BHMAS_fatalBuiltin}
    done
    SourceClusterSpecificCode
    SourceLqcdSoftwareSpecificCode

    #User file to be sourced depending on test mode
    if IsBaHaMASRunInSetupMode; then
        return 0
    elif IsTestModeOn; then
        source ${BHMAS_repositoryTopLevelPath}/Tests/SetupUserVariables.bash || exit ${BHMAS_fatalBuiltin}
    else
        if [[ ! -f "${BHMAS_userSetupFile}" ]]; then
            declare -g BHMAS_coloredOutput='FALSE' #This is needed in cecho but is a user variable! Declare it here manually
            if WasAnyOfTheseOptionsGivenToBaHaMAS '-h' '--help'; then
                Warning -N "BaHaMAS was not set up yet, but help was asked, some default values might not be displayed."
            else
                Fatal ${BHMAS_fatalFileNotFound} "BaHaMAS has not been configured, yet! Please, run BaHaMAS with the --setup option to configure it!"
            fi
        else
            source "${BHMAS_userSetupFile}" || exit ${BHMAS_fatalBuiltin}
        fi
    fi
}

#Call the function above and source the codebase files when this script is sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    BHMAS_specifiedCommandLineOptions=( "$@" )
    __static__SourceCodebaseGeneralFiles
fi

MakeFunctionsDefinedInThisFileReadonly
