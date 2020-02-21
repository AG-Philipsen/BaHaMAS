#!/bin/bash
#
#  Copyright (c) 2017-2018,2020 Alessandro Sciarra
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



#---------------------------------------------------------------------------#
# This files contains a set of tests for the main code.                     #
#                                                                           #
# The only aim is to run BaHaMAS with all its possible mutually exclusive   #
# options and check that no unexpected failure occures. Clearly, these      #
# are not exhaustive tests, but they help refactoring the code.             #
#---------------------------------------------------------------------------#

#Use extglob to facilitate some operations
#NOTE: To be done here and not where used (see http://mywiki.wooledge.org/glob)
shopt -s extglob

#This is to have cecho functionality active here
readonly BHMAS_coloredOutput='TRUE'

#Retrieve information from git
readonly BHMAS_repositoryTopLevelPath="$(git -C $(dirname "${BASH_SOURCE[0]}") rev-parse --show-toplevel)"
readonly BHMAS_command=${BHMAS_repositoryTopLevelPath}/BaHaMAS.bash
readonly BHMAS_testsFolder=${BHMAS_repositoryTopLevelPath}/Tests
readonly BHMAS_testsFolderAuxFiles=${BHMAS_testsFolder}/AuxiliaryFiles

#Load needed files
readonly BHMAS_filesToBeSourced=( "${BHMAS_repositoryTopLevelPath}/SchedulerIndependentCode/UtilityFunctions.bash"
                                  "${BHMAS_repositoryTopLevelPath}/SchedulerIndependentCode/OutputFunctionality.bash"
                                  "${BHMAS_testsFolder}/AuxiliaryFunctions.bash"
                                  "${BHMAS_testsFolder}/CommandLineParser.bash" )
#Source error codes and fail with error hard coded since variable defined in file which is sourced!
source ${BHMAS_repositoryTopLevelPath}/SchedulerIndependentCode/ErrorCodes.bash || exit 64
for fileToBeSourced in "${BHMAS_filesToBeSourced[@]}"; do
    source "${fileToBeSourced}" || exit $BHMAS_fatalBuiltin
done

#Helper has priority
if ElementInArray '-h' "$@" || ElementInArray '--help' "$@"; then
    ParseCommandLineOption '--help'
fi

#BaHaMAS tests global variables
cleanTestFolder='TRUE'
reportLevel=3 #Report level: 0 = binary, 1 = summary, 2 = short, 3 = detailed
testsRun=0
testsPassed=0
testsFailed=0
whichFailed=()
declare -A availableTests=()
declare -a testsToBeRun=() #To keep tests in order and make user decide which to run
readonly testFolder="${BHMAS_testsFolder}/StaggeredFakeProject"
readonly logFile="${BHMAS_testsFolder}/Tests.log"
readonly testParametersString='Nf2_mui0_mass0050_nt6_ns18'
readonly testParametersPath="/${testParametersString//_/\/}"
readonly betaFolder='b5.1111_s3333_continueWithNewChain'
readonly listOfAuxiliaryFilesAndFolders=( "$testFolder" "$logFile" )


#Possible Tests
availableTests['help']='--help'
availableTests['default']='-w=1d'
availableTests['submit']='--submit --walltime 1d'
availableTests['submit-goal']='--submit --walltime 1d'
availableTests['submitonly']='--submitonly'
availableTests['thermalize-hot']='--thermalize --walltime 1d'
availableTests['thermalize-conf']='--thermalize --walltime 1d'
availableTests['continue-save']='--continue --walltime 1d -F 80 -f 140 -m=1234'
availableTests['continue-last']='--continue --walltime 1d'
availableTests['continue-resume']='--continue --walltime 1d'
availableTests['continue-num']='--continue 10000 --walltime 1d'
availableTests['continue-goal']='--continue --walltime 1d'
availableTests['continue-therm-save']='--continueThermalization --walltime 1d -F 80 -f 140 -m=1234'
availableTests['continue-therm-last']='--continueThermalization --walltime 1d'
availableTests['continue-therm-resume']='--continueThermalization --walltime 1d'
availableTests['continue-therm-num']='--continueThermalization 5000 --walltime 1d'
availableTests['continue-therm-goal']='--continueThermalization --walltime 1d'
availableTests['completeBetasFile']='--completeBetasFile'
availableTests['completeBetasFile-num']='--completeBetasFile=3'
availableTests['commentBetas']='--commentBetas'
availableTests['liststatus']='--liststatus'
availableTests['liststatus-time']='--liststatus --doNotMeasureTime'
availableTests['liststatus-queued']='--liststatus --showOnlyQueued'
availableTests['accRateReport']='--accRateReport'
availableTests['accRateReport-num']='--accRateReport 300'
availableTests['cleanOutputFiles']='--cleanOutputFiles'
availableTests['cleanOutputFiles-all']='--cleanOutputFiles --all'
availableTests['commentBetas-num']='--commentBetas 6.1111'
availableTests['commentBetas-nums']='--commentBetas 6.1111 7.1111'
availableTests['commentBetas-num-seed']='--commentBetas 6.1111_s2222_fH'
availableTests['uncommentBetas']='--uncommentBetas'
availableTests['uncommentBetas-num']='--uncommentBetas 5.1111'
availableTests['uncommentBetas-nums']='--uncommentBetas 5.1111 6.1111'
availableTests['uncommentBetas-num-seed']='--uncommentBetas 5.1111_s3333_NC'
availableTests['invertConfs']='--invertConfigurations --walltime 1d'
availableTests['invertConfs-some']='--invertConfigurations --walltime 1d'
availableTests['database-help']='--helpDatabase'
availableTests['database-display']='--database --sum'
availableTests['database-local']='--database --local'
availableTests['database-filter1']='--database --type NC --ns 18 --beta 5.4360'
availableTests['database-filter2']='--database --status RUNNING --lastTraj 115'
availableTests['database-report']='--database --report'
availableTests['database-update']='--database --update'
availableTests['database-update-file']='--database --update --file fakeDatabasePath'
testsToBeRun=( 'help' 'default'
               'submit' 'submit-goal' 'submitonly'
               'thermalize-hot' 'thermalize-conf'
               'continue-save' 'continue-last' 'continue-resume' 'continue-num' 'continue-goal'
               'continue-therm-save' 'continue-therm-last' 'continue-therm-resume' 'continue-therm-num' 'continue-therm-goal'
               'liststatus' 'liststatus-time' 'liststatus-queued'
               'accRateReport' 'accRateReport-num'
               'cleanOutputFiles' 'cleanOutputFiles-all'
               'completeBetasFile' 'completeBetasFile-num'
               'commentBetas' 'commentBetas-num' 'commentBetas-nums' 'commentBetas-num-seed'
               'uncommentBetas' 'uncommentBetas-num' 'uncommentBetas-nums' 'uncommentBetas-num-seed'
               'invertConfs' 'invertConfs-some'
               'database-help' 'database-display' 'database-local'
               'database-filter1' 'database-filter2' 'database-report'
               'database-update' 'database-update-file'
             )

#Get user setup
ParseCommandLineOption "$@"

#If auxiliary folder/files present, rename them
CheckTestEnvironment

#Run tests
if [ $reportLevel -eq 3 ]; then
    cecho wg "\n " U "Running " emph "${#testsToBeRun[@]}" " test(s)" uU ":\n"
fi
for testName in "${testsToBeRun[@]}"; do
    if [ -n "${availableTests[$testName]:+x}" ]; then
        MakeTestPreliminaryOperations "$testName"
        RunTest "$testName" "${availableTests[$testName]}"
    else
        Fatal $BHMAS_fatalLogicError "Test " emph "$testName" " not found among availableTests!"
    fi
    CleanTestsEnvironmentForFollowingTest "$testName"
done && unset -v 'testName'

#Print report and clean test folder
PrintTestsReport
if [ $cleanTestFolder = 'TRUE' ] && [ $testsFailed -eq 0 ]; then
    DeleteAuxiliaryFilesAndFolders
fi

exit ${testsFailed}
