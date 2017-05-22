#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function CheckTestEnvironment()
{
    local name postfix
    postfix="$(date +%H%M%S)"
    for name in "${listOfAuxiliaryFilesAndFolders[@]}"; do
        if [ "$(basename $name)" = 'Tests.log' ]; then
            continue
        fi
        if [ "$(find $(pwd) -path "$name")" = "$name" ]; then
            cecho ly "\n " B U "WARNING" uU ": " uB "Found " emph "$name" ", renaming it!"
            mv "$name" "${name}_${postfix}"
        fi
    done
}


function __static__CreateParametersFolders()
{
    mkdir -p "${testFolder}${testParametersPath}" || exit -2
}
function __static__CreateRationalApproxFolderWithFiles()
{
    mkdir -p "${testFolder}/Rational_Approximations"
    cp "${BaHaMAS_testsFolderAuxFiles}/fakeApprox" "${testFolder}/Rational_Approximations"
}
function __static__CreateBetaFolder()
{
    mkdir "${testFolder}${testParametersPath}/${betaFolder}" || exit -2
}
function __static__CreateFilesInBetaFolder()
{
    local file
    for file in "$@"; do
        touch "${testFolder}${testParametersPath}/${betaFolder}/${file}" || exit -2
    done
}
function __static__AddStringToFirstLineBetasFile()
{
    local line
    line="$(head -n 1 "${testFolder}${testParametersPath}/betas")"
    cecho -n -d "$line   $1" > "${testFolder}${testParametersPath}/betas" || exit -2
}
function __static__CopyAuxiliaryFileAtBetaFolderLevel()
{
    cp "${BaHaMAS_testsFolderAuxFiles}/$1" "${testFolder}${testParametersPath}/$2" || exit -2
}
function __static__CopyAuxiliaryFilesToBetaFolder()
{
    local file
    for file in "$@"; do
        cp "${BaHaMAS_testsFolderAuxFiles}/${file}" "${testFolder}${testParametersPath}/${betaFolder}" || exit -2
    done
}
function __static__CreateThermalizedConfigurationFolder()
{
    mkdir "${testFolder}/Thermalized_Configurations" || exit -2
}
function __static__CreateThermalizedConfiguration()
{
    touch "${testFolder}/Thermalized_Configurations/conf.${testParametersString}_${betaFolder%_*}_$1" || exit -2
}

function MakeTestPreliminaryOperations()
{
    local trashFolderName file folder
    #Always create params folders and go at betafolder level
    __static__CreateParametersFolders
    cd "${testFolder}${testParametersPath}" || exit -2
    #Always use completed file and then in case overwrite
    cp "${BaHaMAS_testsFolderAuxFiles}/fakeBetas" "${testFolder}${testParametersPath}/betas"

    case "$1" in
        default | submit )
            __static__CreateRationalApproxFolderWithFiles
            __static__CreateThermalizedConfigurationFolder
            __static__CreateThermalizedConfiguration "fromConf4000"
            ;;
        submitonly )
            __static__CreateRationalApproxFolderWithFiles
            __static__CreateThermalizedConfigurationFolder
            __static__CreateThermalizedConfiguration "fromConf4000"
            __static__CreateBetaFolder
            __static__CopyAuxiliaryFilesToBetaFolder "fakeInput"
            mkdir "Jobscripts_TEST" || exit -2
            echo "NOT EMPTY" > "${testFolder}${testParametersPath}/Jobscripts_TEST/fakePrefix_${testParametersString}__${betaFolder%_*}"
            ;;
        thermalize* )
            __static__CreateRationalApproxFolderWithFiles
            __static__CreateThermalizedConfigurationFolder
            if [[ $1 =~ conf$ ]]; then
                __static__CreateThermalizedConfiguration "fromHot1000"
            fi
            ;;
        continue-* )
            __static__CreateRationalApproxFolderWithFiles
            __static__CreateBetaFolder
            __static__CopyAuxiliaryFilesToBetaFolder "fakeInput" "fakeOutput"
            __static__CreateFilesInBetaFolder "conf.save" "prng.save"
            case "${1##*-}" in
                last )
                    __static__CreateFilesInBetaFolder "conf.00800" "prng.00800"
                    __static__AddStringToFirstLineBetasFile "resumefrom=last"
                    ;;
                resume )
                    __static__CreateFilesInBetaFolder "conf.00100" "prng.00100" "conf.00200" "prng.00200"
                    __static__AddStringToFirstLineBetasFile "resumefrom=100"
                    ;;
            esac
            if [[ $1 =~ therm ]]; then
                __static__CreateThermalizedConfigurationFolder
                mv "$betaFolder" "${betaFolder/continueWithNewChain/thermalizeFromHot}"
            fi
            ;;
        liststatus* )
            __static__CreateBetaFolder
            __static__CopyAuxiliaryFilesToBetaFolder "fakeExecutable.123456.out" "fakeInput" "fakeOutput"
            ;;
        accRateReport* )
            __static__CreateBetaFolder
            __static__CopyAuxiliaryFilesToBetaFolder "fakeOutput"
            ;;
        cleanOutputFiles* )
            __static__CreateBetaFolder
            __static__CopyAuxiliaryFilesToBetaFolder "fakeOutput" "fakeOutput_pbp.dat"
            ;;
        completeBetasFile* )
            __static__CopyAuxiliaryFileAtBetaFolderLevel "fakeBetasToBeCompleted" "betas"
            ;;
        commentBetas* | uncommentBetas* )
            __static__CopyAuxiliaryFileAtBetaFolderLevel "fakeBetasToBeCommented" "betas"
            ;;
        invertConfs* )
            __static__CreateBetaFolder
            __static__CreateFilesInBetaFolder "conf.00100" "conf.00200" "conf.00300" "conf.00400"
            if [[ $1 =~ some$ ]]; then
                __static__CreateFilesInBetaFolder "conf.00100_2_3_7_1_corr" "conf.00100_1_2_3_1_corr"
            fi
            ;;
        database* )
            mkdir -p "${testFolder}/SimulationsOverview"
            cp "${BaHaMAS_testsFolderAuxFiles}/fakeOverviewDatabase" "${testFolder}/SimulationsOverview/2222_01_01_OverviewDatabase"
            if [[ $1 =~ update ]]; then
                __static__CreateBetaFolder
                __static__CopyAuxiliaryFilesToBetaFolder "fakeExecutable.123456.out" "fakeInput" "fakeOutput"
                cecho -d "${testFolder}${testParametersPath}" > "fakeDatabasePath"
            fi
            ;;
        * )
            ;;
    esac
}

function InhibitBaHaMASCommands()
{
    function less(){ cecho -d "less $@"; }
    function sbatch(){ cecho -d "sbatch $@"; }
    #To make liststatus find running job and then test measure time
    if [[ $1 =~ ^liststatus ]]; then
        export jobnameForSqueue="${testParametersString}__${betaFolder%_*}@RUNNING"
    fi
    function squeue(){ cecho -d -n "$jobnameForSqueue"; }
    export -f less sbatch squeue
}

function RunBaHaMASInTestMode()
{
    local testName
    testName=$1; shift
    printf "\n===============================\n" >> $logFile
    printf " $(date)\n" >> $logFile
    printf "===============================\n" >> $logFile
    printf "Running:\n    ${BaHaMAS_command} $@\n\n" >> $logFile
    # NOTE: Here we run BaHaMAS in subshell to exclude any potential variables conflict.
    #       Moreover we activate the test mode defining a variable before running it and
    #       we inhibit some commands in order to avoid job summission. Observe also that
    #       at the moment there are no options or options value which have a space in them
    #       and, hence, we can pass $@ to BaHaMAS instead of "$@" in order to word split
    #       the string passed to this function. This will break also spaces inside options
    #       and it has to be taken in mind in future! Observe also that we want to avoid
    #       any interactve Y/N question of BaHaMAS and we do it answering always Y.
    (
        InhibitBaHaMASCommands "$testName"
        BaHaMAS_testModeOn='TRUE' ${BaHaMAS_command} $@ < <(yes 'Y') >> $logFile 2>&1
    )
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
        cecho -n lp "  $(printf '%+2s' ${testsRun})/$(printf '%-2s' ${#testsToBeRun[@]})" lc "${stringTest//_/ }"
    fi
    RunBaHaMASInTestMode "$testName" "$@"
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

function CleanTestsEnvironmentForFollowingTest()
{
    local bigTrash trashFolderName
    bigTrash="Trash"
    #Always go to simulation path level and move everything inside a Trash folder
    #which contains in the name also the test name (easy debug in case of failure)
    cd "$testFolder" || exit -2
    mkdir -p "$bigTrash" || exit -2
    if [ "$(ls -A)" ]; then
        trashFolderName="Trash_$(date +%H%M%S-%3N)_$1"
        mkdir "${bigTrash}/${trashFolderName}" || exit -2
        mv !("$bigTrash") "${bigTrash}/${trashFolderName}/." || exit -2
    else
        cecho lr "Folder " dir "$(pwd)" " empty but it should not be the case! Aborting...\n"
        exit -1
    fi
}

function PrintTestsReport()
{
    local indentation name percentage
    indentation='          '
    if [ $reportLevel -ge 1 ]; then
        cecho bb "\n${indentation}===============================\n"\
              lp "${indentation}   Run " emph "$(printf '%2d' $testsRun)" " test(s): "\
              lg "$(printf '%2d' $testsPassed) passed\n"\
              lr "${indentation}                   $(printf '%2d' $testsFailed) failed\n"\
              bb "${indentation}==============================="
    fi
    if [ $reportLevel -ge 2 ]; then
        percentage=$(awk '{printf "%3.0f%%%%", 100*$1/$2}' <<< "$testsPassed $testsRun")
        cecho wg "${indentation}     $percentage of tests passed!"
        cecho bb "${indentation}==============================="
        if [ $testsFailed -ne 0 ]; then
            cecho lr "${indentation}  The following tests failed:"
            for name in "${whichFailed[@]}"; do
                cecho lr "${indentation}   - " emph "$name"
            done
            cecho bb "${indentation}==============================="
        fi
    fi
    cecho ''
    if [ $testsFailed -ne 0 ]; then
        cecho lr B " Failures were detected! Not deleting log file!\n"
    else
        cecho lg B " All tests passed!\n"
    fi
}

function DeleteAuxiliaryFilesAndFolders()
{
    local name
    cd "$BaHaMAS_testsFolder" || exit -2
    [ $reportLevel -eq 3 ] && cecho bb " In $(pwd):"
    for name in "${listOfAuxiliaryFilesAndFolders[@]}"; do
        if [ -d "$name" ]; then
            [ $reportLevel -eq 3 ] && cecho p " - Removing " dir "$name"
        elif [ -f "$name" ]; then
            [ $reportLevel -eq 3 ] && cecho p " - Removing " file "$name"
        elif ls "$name" 1>/dev/null 2>&1; then
            cecho lr "   Error in $FUNCNAME: " emph "$name" " neither file or directory, leaving it!"; continue
        fi
        [ $(pwd) = "$BaHaMAS_testsFolder" ] && rm -rf "$name"
    done
    cecho ''
}
