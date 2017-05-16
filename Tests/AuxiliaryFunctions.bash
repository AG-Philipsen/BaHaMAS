#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function CreateTestsFolderStructure()
{
    cd $BaHaMAS_testsFolder || exit -2
    mkdir -p "${testFolder}${testParametersPath}"
    mkdir -p "${testFolder}/Rational_Approximations"
    cp "${BaHaMAS_testsFolderAuxFiles}/fakeApprox" "${testFolder}/Rational_Approximations"
    mkdir -p "${testFolder}/SimulationsOverview"
    cp "${BaHaMAS_testsFolderAuxFiles}/fakeOverviewDatabase" "${testFolder}/SimulationsOverview"
    mkdir -p "${testFolder}/Thermalized_Configurations"
}

function MakeTestPreliminaryOperations()
{
    #Always use completed file and then in case overwrite
    cp "${BaHaMAS_testsFolderAuxFiles}/fakeBetas" "${testFolder}${testParametersPath}/betas"
    #Always go at betafolder level and then in case cd elsewhere
    cd "${testFolder}${testParametersPath}"

    case "$1" in
        completeBetasFile* )
            cp "${BaHaMAS_testsFolderAuxFiles}/fakeBetasToBeCompleted" "${testFolder}${testParametersPath}/betas"
            ;;
        * )
            ;;
    esac
}

function RunBaHaMASInTestMode()
{
    printf "\n\n$(date)\n  Running:\n    ${BaHaMAS_command} $@\n\n" >> $logFile
    #In subshell to exclude any potential variables conflict and in test mode!
    ( BaHaMAS_testModeOn='TRUE' ${BaHaMAS_command} "$@" >> $logFile )
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

function RunTest()
{
    local testName stringTest
    testName=$1; shift
    (( testsRun++ ))
    if [ $reportLevel -eq 3 ]; then
        printf -v stringTest "%-38s" "__${testName}$(cecho -d bb)_"
        stringTest="${stringTest// /.}"
        cecho -n bb "  $(printf '%+2s' ${testsRun})/$(printf '%-2s' ${#availableTests[@]})" emph "${stringTest//_/ }"
    fi
    RunBaHaMASInTestMode "$@"
    if [ $? -eq 0 ]; then
        (( testsPassed++ ))
        if [ $reportLevel -eq 3 ]; then
            cecho lg "  passed"
        fi
    else
        (( testsFailed++ ))
        whichFailed+=( "$testName" )
        if [ $reportLevel -eq 3 ]; then
            cecho lr "  failed"
        fi
    fi
}

function PrintTestsReport()
{
    local indentation name
    indentation='    '
    if [ $reportLevel -ge 1 ]; then
        cecho bb "\n${indentation}==============================\n"\
              lp "${indentation}   Run " emph "$(printf '%2d' $testsRun)" " tests: "\
              lg "$(printf '%2d' $testsPassed) passed\n"\
              lr "${indentation}                 $(printf '%2d' $testsFailed) failed\n"\
              bb "${indentation}=============================="
    fi
    if [ $reportLevel -ge 2 ]; then
        if [ $testsFailed -ne 0 ]; then
            cecho lr "${indentation}  The following tests failed:"
            for name in "${whichFailed[@]}"; do
                cecho lr "${indentation}   - " emph "$name"
            done
        else
            cecho wg "${indentation}       No test failed!"
        fi
        cecho bb "${indentation}=============================="
    fi
    cecho ''
    if [ $testsFailed -ne 0 ]; then
        cecho lr B " Failures were detected! Not deleting log file!\n"
    else
        cecho lg B " All tests passed!\n"
    fi
}

function CleanTestsEnvironment()
{
    local name
    cd $BaHaMAS_testsFolder || exit -2
    [ $reportLevel -eq 3 ] && cecho bb "\n In $(pwd):"
    for name in "${listOfAuxiliaryFilesAndFolders[@]}"; do
        if [ $testsFailed -ne 0 ] && [ $name = $logFile ]; then
            continue
        fi
        if [ -d "$name" ]; then
            [ $reportLevel -eq 3 ] && cecho p " - Removing " dir "$name"
        elif [ -f "$name" ]; then
            [ $reportLevel -eq 3 ] && cecho p " - Removing " file "$name"
        elif ls "$name" 1>/dev/null 2>&1; then
            cecho lr "   Error in $FUNCNAME: " emph "$name" " neither file or directory, leaving it!"; continue
        fi
        rm -rf "$name"
    done
    cecho ''
}
