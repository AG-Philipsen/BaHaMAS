#!/bin/bash

#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

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
readonly BaHaMAS_colouredOutput='TRUE'

#Retrieve information from git
readonly BaHaMAS_repositoryTopLevelPath="$(git -C $(dirname "${BASH_SOURCE[0]}") rev-parse --show-toplevel)"
readonly BaHaMAS_command=${BaHaMAS_repositoryTopLevelPath}/BaHaMAS.bash
readonly BaHaMAS_testsFolder=${BaHaMAS_repositoryTopLevelPath}/Tests
readonly BaHaMAS_testsFolderAuxFiles=${BaHaMAS_testsFolder}/AuxiliaryFiles

#Load needed files
source ${BaHaMAS_repositoryTopLevelPath}/OutputFunctionality.bash  || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/UtilityFunctions.bash     || exit -2
source ${BaHaMAS_testsFolder}/AuxiliaryFunctions.bash              || exit -2
source ${BaHaMAS_testsFolder}/CommandLineParser.bash               || exit -2

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
declare -A availableTests
declare -a testsToBeRun #To keep tests in order and make user decide which to run


#Possible Tests
availableTests['help']='--help'
availableTests['completeBetasFile']='--completeBetasFile'
availableTests['completeBetasFile-eq']='--completeBetasFile=3'
availableTests['commentBetas']='--commentBetas'
availableTests['liststatus']='--liststatus'
availableTests['liststatus-time']='--liststatus --measureTime'
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
testsToBeRun=( 'help'
               'liststatus' 'liststatus-time' 'liststatus-queued'
               'accRateReport' 'accRateReport-num'
               'cleanOutputFiles' 'cleanOutputFiles-all'
               'completeBetasFile' 'completeBetasFile-eq'
               'commentBetas' 'commentBetas-num' 'commentBetas-nums' 'commentBetas-num-seed'
               'uncommentBetas' 'uncommentBetas-num' 'uncommentBetas-nums' 'uncommentBetas-num-seed'
             )


#Get user setup
ParseCommandLineOption "$@"

#Set up folder structure to run tests
readonly testFolder="${BaHaMAS_testsFolder}/StaggeredFakeProject"
readonly logFile="${BaHaMAS_testsFolder}/Tests.log"
readonly testParametersPath='/Nf2/muiPiT/mass0050/nt6/ns18'
readonly betaFolder='b5.1111_s3333_continueWithNewChain'
readonly listOfAuxiliaryFilesAndFolders=( "$testFolder" "$logFile" )
CreateTestsFolderStructure

#Run tests
if [ $reportLevel -eq 3 ]; then
    cecho bb "\n " U "Running " emph "${#testsToBeRun[@]}" " test(s)" uU ":\n"
fi
for testName in "${testsToBeRun[@]}"; do
    MakeTestPreliminaryOperations "$testName"
    RunTest "$testName" "${availableTests[$testName]}"
done && unset -v 'testName'

#Print report and clean test folder
PrintTestsReport
if [ $cleanTestFolder = 'TRUE' ]; then
    CleanTestsEnvironment
fi
