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
shopt -s extglob # <- To be done here and not where used (see http://mywiki.wooledge.org/glob)
shopt -s nullglob
shopt -s dotglob

#This is to have cecho functionality active here
readonly BHMAS_coloredOutput='TRUE'

#Retrieve information from git
readonly BHMAS_repositoryTopLevelPath="$(git -C $(dirname "${BASH_SOURCE[0]}") rev-parse --show-toplevel)"
readonly BHMAS_command=${BHMAS_repositoryTopLevelPath}/BaHaMAS
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
readonly testFolder="${BHMAS_testsFolder}/RunTestFolder"
readonly submitTestFolder="${testFolder}/SubmitDisk"
readonly runTestFolder="${testFolder}/RunDisk"
readonly logFile="${BHMAS_testsFolder}/Tests.log"
readonly userVariablesFile="${BHMAS_testsFolder}/SetupUserVariables.bash"
testParametersString='' # Global but to be filled in each
testParametersPath=''   # test to change formulation
betaFolder='b5.1111_s3333_continueWithNewChain' # To be changed in thermalization
readonly listOfAuxiliaryFilesAndFolders=( "${testFolder}" "${logFile}" "${userVariablesFile}" )


#Possible Tests
availableTests=(
    ['help-1']=''
    ['help-2']='help'
    ['help-3']='--help'
    ['version-1']='--version'
    ['version-2']='version'
    ['CL2QCD-prepare-only']='CL2QCD prepare-only -w=1d --togglePbp'
    ['CL2QCD-submit-only']='CL2QCD submit-only --betasfile betas'
    ['CL2QCD-new-chain']='CL2QCD new-chain --walltime = 1d'
    ['CL2QCD-new-chain-goal']='CL2QCD new-chain --walltime= 1d'
    ['CL2QCD-thermalize-hot']='CL2QCD thermalize --walltime 1d'
    ['CL2QCD-thermalize-conf']='CL2QCD thermalize --walltime 1d'
    ['CL2QCD-continue-save']='CL2QCD continue --walltime 1d -F 80 -f 140 -m=1234'
    ['CL2QCD-continue-last']='CL2QCD continue --walltime 1d --pf 3'
    ['CL2QCD-continue-resume']='CL2QCD continue --walltime 1d'
    ['CL2QCD-continue-num']='CL2QCD continue --till 10000 --walltime 1d'
    ['CL2QCD-continue-goal']='CL2QCD continue --walltime 1d'
    ['CL2QCD-continue-therm-save']='CL2QCD continue-thermalization --walltime 1d -F 80 -f 140 -m=1234'
    ['CL2QCD-continue-therm-last']='CL2QCD continue-thermalization --walltime 1d'
    ['CL2QCD-continue-therm-resume']='CL2QCD continue-thermalization --walltime 1d'
    ['CL2QCD-continue-therm-num']='CL2QCD continue-thermalization --till 5000 --walltime 1d'
    ['CL2QCD-continue-therm-goal']='CL2QCD continue-thermalization --walltime 1d'
    ['CL2QCD-simulation-status']='CL2QCD simulation-status'
    ['CL2QCD-simulation-status-time']='CL2QCD simulation-status --doNotMeasureTime'
    ['CL2QCD-simulation-status-queued']='CL2QCD simulation-status --showOnlyQueued'
    ['CL2QCD-measure']='CL2QCD measure --walltime 1d'
    ['CL2QCD-measure-some']='CL2QCD measure --walltime 1d'
    ['CL2QCD-accRateReport']='CL2QCD acceptance-rate-report'
    ['CL2QCD-accRateReport-num']='CL2QCD acceptance-rate-report --interval 300'
    ['CL2QCD-cleanOutputFiles']='CL2QCD clean-output-files'
    ['CL2QCD-cleanOutputFiles-all']='CL2QCD clean-output-files --all'
    ['openQCD-FASTSUM-prepare-only']='openQCD-FASTSUM prepare-only -w=1d --processorsGrid 1 2 4 6'
    ['openQCD-FASTSUM-submit-only']='openQCD-FASTSUM submit-only --betasfile betas'
    ['openQCD-FASTSUM-new-chain']='openQCD-FASTSUM new-chain --walltime = 1d --processorsGrid 1 2 4 6'
    ['openQCD-FASTSUM-new-chain-goal']='openQCD-FASTSUM new-chain --walltime= 1d --processorsGrid 1 2 4 6'
    ['openQCD-FASTSUM-thermalize-hot']='openQCD-FASTSUM thermalize --walltime 1d --processorsGrid 1 2 4 6'
    ['openQCD-FASTSUM-thermalize-conf']='openQCD-FASTSUM thermalize --walltime 1d --processorsGrid 1 2 4 6'
    ['openQCD-FASTSUM-continue']='openQCD-FASTSUM continue --walltime 1d -m=1400'
    ['openQCD-FASTSUM-continue-last']='openQCD-FASTSUM continue --walltime 1d'
    ['openQCD-FASTSUM-continue-resume']='openQCD-FASTSUM continue --walltime 1d'
    ['openQCD-FASTSUM-continue-num']='openQCD-FASTSUM continue --till 10000 --walltime 1d'
    ['openQCD-FASTSUM-continue-goal']='openQCD-FASTSUM continue --walltime 1d'
    ['openQCD-FASTSUM-continue-therm-save']='openQCD-FASTSUM continue-thermalization --walltime 1d -m=1234'
    ['openQCD-FASTSUM-continue-therm-last']='openQCD-FASTSUM continue-thermalization --walltime 1d'
    ['openQCD-FASTSUM-continue-therm-resume']='openQCD-FASTSUM continue-thermalization --walltime 1d'
    ['openQCD-FASTSUM-continue-therm-num']='openQCD-FASTSUM continue-thermalization --till 5000 --walltime 1d'
    ['openQCD-FASTSUM-continue-therm-goal']='openQCD-FASTSUM continue-thermalization --walltime 1d'
    ['openQCD-FASTSUM-simulation-status']='openQCD-FASTSUM simulation-status'
    ['openQCD-FASTSUM-simulation-status-time']='openQCD-FASTSUM simulation-status --doNotMeasureTime'
    ['openQCD-FASTSUM-simulation-status-queued']='openQCD-FASTSUM simulation-status --showOnlyQueued'
    ['openQCD-FASTSUM-accRateReport']='openQCD-FASTSUM acceptance-rate-report'
    ['openQCD-FASTSUM-accRateReport-num']='openQCD-FASTSUM acceptance-rate-report --interval 30'
    ['openQCD-FASTSUM-cleanOutputFiles']='openQCD-FASTSUM clean-output-files'
    ['openQCD-FASTSUM-cleanOutputFiles-all']='openQCD-FASTSUM clean-output-files --all'
    ['commentBetas']='comment-betas'
    ['commentBetas-num']='comment-betas --betas 6.1111'
    ['commentBetas-nums']='comment-betas --betas 6.1111 7.1111'
    ['commentBetas-num-seed']='comment-betas --betas 6.1111_s2222_fH'
    ['uncommentBetas']='uncomment-betas'
    ['uncommentBetas-num']='uncomment-betas --betas 5.1111'
    ['uncommentBetas-nums']='uncomment-betas --betas 5.1111 6.1111'
    ['uncommentBetas-num-seed']='uncomment-betas --betas 5.1111_s3333_NC'
    ['completeBetasFile']='complete-betas-file'
    ['completeBetasFile-num']='complete-betas-file --chains 3'
    ['database-help']='database --help'
    ['database-display']='database --sum'
    ['database-local']='database --local'
    ['database-filter1']='database --type NC --ns 18 --beta 5.4360'
    ['database-filter2']='database --status RUNNING --lastTraj 115'
    ['database-report']='database --report'
    ['database-update-CL2QCD']='database --update'
    ['database-update-file-CL2QCD']='database --update --file fakeDatabasePath'
    ['database-update-openQCD-FASTSUM']='database --update'
    ['database-update-file-openQCD-FASTSUM']='database --update --file fakeDatabasePath'
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
