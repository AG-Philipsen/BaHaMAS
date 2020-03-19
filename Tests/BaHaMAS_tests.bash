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

#-------------------------------------------------------------------#
# This files contains a set of functional tests for the main code.  #
#                                                                   #
# The only aim is to run BaHaMAS with in all its possible modes and #
# check that no unexpected failure occures. Clearly, these are not  #
# exhaustive tests, but they help refactoring the code.             #
#-------------------------------------------------------------------#

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
readonly BHMAS_filesToBeSourced=( "${BHMAS_repositoryTopLevelPath}/Generic_Code/UtilityFunctions.bash"
                                  "${BHMAS_repositoryTopLevelPath}/Generic_Code/OutputFunctionality.bash"
                                  "${BHMAS_testsFolder}/AuxiliaryFunctions.bash"
                                  "${BHMAS_testsFolder}/CommandLineParser.bash" )
#Source error codes and fail with error hard coded since variable defined in file which is sourced!
source ${BHMAS_repositoryTopLevelPath}/Generic_Code/ErrorCodes.bash || exit 64
for fileToBeSourced in "${BHMAS_filesToBeSourced[@]}"; do
    source "${fileToBeSourced}" || exit ${BHMAS_fatalBuiltin}
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
readonly listOfAuxiliaryFilesAndFolders=( "${testFolder}" "${logFile}" )


#Possible Tests
availableTests=(
    ['help-1']=''
    ['help-2']='help'
    ['help-3']='--help'
    ['version-1']='--version'
    ['version-2']='version'
    ['default']='default -w=1d'
    ['submit']='submit --walltime 1d'
    ['submit-goal']='submit --walltime 1d'
    ['submitonly']='submit-only'
    ['thermalize-hot']='thermalize --walltime 1d'
    ['thermalize-conf']='thermalize --walltime 1d'
    ['continue-save']='continue --walltime 1d -F 80 -f 140 -m=1234'
    ['continue-last']='continue --walltime 1d'
    ['continue-resume']='continue --walltime 1d'
    ['continue-num']='continue 10000 --walltime 1d'
    ['continue-goal']='continue --walltime 1d'
    ['continue-therm-save']='continue-thermalization --walltime 1d -F 80 -f 140 -m=1234'
    ['continue-therm-last']='continue-thermalization --walltime 1d'
    ['continue-therm-resume']='continue-thermalization --walltime 1d'
    ['continue-therm-num']='continue-thermalization 5000 --walltime 1d'
    ['continue-therm-goal']='continue-thermalization --walltime 1d'
    ['completeBetasFile']='complete-betas-file'
    ['completeBetasFile-num']='complete-betas-file=3'
    ['liststatus']='simulation-status'
    ['liststatus-time']='simulation-status --doNotMeasureTime'
    ['liststatus-queued']='simulation-status --showOnlyQueued'
    ['accRateReport']='acceptance-rate-report'
    ['accRateReport-num']='acceptance-rate-report 300'
    ['cleanOutputFiles']='clean-output-files'
    ['cleanOutputFiles-all']='clean-output-files --all'
    ['commentBetas']='comment-betas'
    ['commentBetas-num']='comment-betas 6.1111'
    ['commentBetas-nums']='comment-betas 6.1111 7.1111'
    ['commentBetas-num-seed']='comment-betas 6.1111_s2222_fH'
    ['uncommentBetas']='uncomment-betas'
    ['uncommentBetas-num']='uncomment-betas 5.1111'
    ['uncommentBetas-nums']='uncomment-betas 5.1111 6.1111'
    ['uncommentBetas-num-seed']='uncomment-betas 5.1111_s3333_NC'
    ['invertConfs']='invert-configurations --walltime 1d'
    ['invertConfs-some']='invert-configurations --walltime 1d'
    ['database-help']='database --help'
    ['database-display']='database --sum'
    ['database-local']='database --local'
    ['database-filter1']='database --type NC --ns 18 --beta 5.4360'
    ['database-filter2']='database --status RUNNING --lastTraj 115'
    ['database-report']='database --report'
    ['database-update']='database --update'
    ['database-update-file']='database --update --file fakeDatabasePath'
)

#Declare array with indeces of availableTests array sorted
readarray -d $'\0' -t testsToBeRun < <(printf '%s\0' "${!availableTests[@]}" | sort -z)

#Get user setup
ParseCommandLineOption "$@"

#If auxiliary folder/files present, rename them
CheckTestEnvironment

#Run tests
if [[ ${reportLevel} -eq 3 ]]; then
    cecho wg "\n " U "Running " emph "${#testsToBeRun[@]}" " test(s)" uU ":\n"
fi
for testName in "${testsToBeRun[@]}"; do
    if [[ -n "${availableTests[${testName}]+x}" ]]; then
        MakeTestPreliminaryOperations "${testName}"
        RunTest "${testName}" "${availableTests[${testName}]}"
    else
        Fatal ${BHMAS_fatalLogicError} "Test " emph "${testName}" " not found among availableTests!"
    fi
    CleanTestsEnvironmentForFollowingTest "${testName}"
done && unset -v 'testName'

#Print report and clean test folder
PrintTestsReport
if [[ ${cleanTestFolder} = 'TRUE' ]] && [[ ${testsFailed} -eq 0 ]]; then
    DeleteAuxiliaryFilesAndFolders
fi

exit ${testsFailed}
