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

function SourceCodebaseGeneralFiles()
{
    local schedulerIndependentFiles fileToBeSourced
    #Source error codes and fail with error hard coded since variable defined in file which is sourced!
    source "${BHMAS_repositoryTopLevelPath}/SchedulerIndependentCode/ErrorCodes.bash" || exit 64
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
        'GlobalVariables.bash'
        'OperationsOnBetasFile.bash'
        'OutputFunctionality.bash'
        'PathManagementFunctionality.bash'
        'ReportOnProblematicBetas.bash'
        'SchedulerSpecificFunctionsCall.bash'
        'Setup/Setup.bash'
        'SystemRequirements.bash'
    )
    for fileToBeSourced in "${schedulerIndependentFiles[@]}"; do
        source "${BHMAS_repositoryTopLevelPath}/SchedulerIndependentCode/${fileToBeSourced}" || exit $BHMAS_fatalBuiltin
    done
    SourceClusterSpecificCode
}

#Call the function above and source the codebase files when this script is sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SourceCodebaseGeneralFiles
fi

#----------------------------------------------------------------#
#Set functions readonly
readonly -f SourceCodebaseGeneralFiles
