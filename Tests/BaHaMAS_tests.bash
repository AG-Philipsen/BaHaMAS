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

#This is to have cecho functionality active here
readonly BaHaMAS_colouredOutput='TRUE'

#Retrieve information from git
readonly BaHaMAS_repositoryTopLevelPath="$(git -C $(dirname "${BASH_SOURCE[0]}") rev-parse --show-toplevel)"
readonly BaHaMAS_command=${BaHaMAS_repositoryTopLevelPath}/BaHaMAS.bash
readonly BaHaMAS_testsFolder=${BaHaMAS_repositoryTopLevelPath}/Tests
readonly BaHaMAS_testsFolderAuxFiles=${BaHaMAS_testsFolder}/AuxiliaryFiles

#Load needed files
source ${BaHaMAS_repositoryTopLevelPath}/OutputFunctionality.bash  || exit -2
source ${BaHaMAS_testsFolder}/AuxiliaryFunctions.bash              || exit -2
source ${BaHaMAS_testsFolder}/CommandLineParser.bash               || exit -2

#BaHaMAS tests global variables
cleanTestFolder='TRUE'
reportLevel=1 #Report level: 0 = binary, 1 = summary, 2 = short, 3 = detailed
testsRun=0
testsPassed=0
testsFailed=0
whichFailed=()
declare -A availableTests
declare -a testsToBeRun #To keep tests in order and make user decide which to run


#Possible Tests
availableTests['help']="--help"
availableTests['completeBetasFile']="--completeBetasFile"
availableTests['completeBetasFile-eq']="--completeBetasFile=3"
testsToBeRun=( 'help'
               'completeBetasFile' 'completeBetasFile-eq'
             )

#Get user setup
ParseCommandLineOption "$@"

#Set up folder structure to run tests
readonly testFolder="${BaHaMAS_testsFolder}/StaggeredFakeProject"
readonly logFile="${BaHaMAS_testsFolder}/Tests.log"
readonly testParametersPath='/Nf2/muiPiT/mass0050/nt6/ns18'
readonly listOfAuxiliaryFilesAndFolders=( "$testFolder" "$logFile" )
CreateTestsFolderStructure

#Run tests
if [ $reportLevel -eq 3 ]; then
    cecho bb "\n " U "Running " emph "${#testsToBeRun[@]}" " tests" uU ":\n"
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
