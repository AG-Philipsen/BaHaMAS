#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function CreateTestsFolderStructure()
{
    cd "$BaHaMAS_testsFolder" || exit -2
    mkdir -p "${testFolder}${testParametersPath}"
    mkdir -p "${testFolder}/Rational_Approximations"
    cp "${BaHaMAS_testsFolderAuxFiles}/fakeApprox" "${testFolder}/Rational_Approximations"
    mkdir -p "${testFolder}/Thermalized_Configurations"
}

function __static__CreateBetaFolder()
{
    mkdir "${testFolder}${testParametersPath}/${betaFolder}" || exit -2
}
function __static__CreateFilesInBetaFolder()
{
    local file
    for file in "$@"; do
        touch "${testFolder}${testParametersPath}/${betaFolder}/${file}"
    done
}
function __static__AddStringToFirstLineBetasFile()
{
    local line
    line="$(head -n 1 "${testFolder}${testParametersPath}/betas")"
    cecho -n -d "$line   $1" > "${testFolder}${testParametersPath}/betas"
}
function __static__CopyAuxiliaryFileAtBetaFolderLevel()
{
    cp "${BaHaMAS_testsFolderAuxFiles}/$1" "${testFolder}${testParametersPath}/$2"
}
function __static__CopyAuxiliaryFilesToBetaFolder()
{
    local file
    for file in "$@"; do
        cp "${BaHaMAS_testsFolderAuxFiles}/${file}" "${testFolder}${testParametersPath}/${betaFolder}"
    done
}
function __static__CreateThermalizedConfiguration()
{
    touch "${testFolder}/Thermalized_Configurations/conf.${testParametersString}_${betaFolder%_*}_$1"
}

function MakeTestPreliminaryOperations()
{
    local trashFolderName file folder
    #Always go at betafolder level and then in case cd elsewhere
    cd "${testFolder}${testParametersPath}" || exit -2
    #Always move everything inside a Trash folder if not empty
    if [ "$(ls -A)" ]; then
        trashFolderName="Trash_$(date +%H%M%S-%3N)"
        mkdir "$trashFolderName" || exit -2
        mv !("$trashFolderName") "$trashFolderName" || exit -2
    fi
    #Always use completed file and then in case overwrite
    cp "${BaHaMAS_testsFolderAuxFiles}/fakeBetas" "${testFolder}${testParametersPath}/betas"

    case "$1" in
        default | submit )
            __static__CreateThermalizedConfiguration "fromConf4000"
            ;;
        submitonly )
            __static__CreateThermalizedConfiguration "fromConf4000"
            __static__CreateBetaFolder
            __static__CopyAuxiliaryFilesToBetaFolder "fakeInput"
            mkdir "Jobscripts_TEST" || exit -2
            echo "NOT EMPTY" > "${testFolder}${testParametersPath}/Jobscripts_TEST/fakePrefix_${testParametersString}__${betaFolder%_*}"
            ;;
        thermalize-conf )
            __static__CreateThermalizedConfiguration "fromHot1000"
            ;;
        continue-* )
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
            __static__CopyAuxiliaryFilesToBetaFolder "fakeOutput?(|_pbp.dat)"
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
            cp "${BaHaMAS_testsFolderAuxFiles}/fakeOverviewDatabase" "${testFolder}/SimulationsOverview"
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
        cecho -n bb "  $(printf '%+2s' ${testsRun})/$(printf '%-2s' ${#testsToBeRun[@]})" emph "${stringTest//_/ }"
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

function CleanTestsEnvironment()
{
    local name
    cd "$BaHaMAS_testsFolder" || exit -2
    [ $reportLevel -eq 3 ] && cecho bb " In $(pwd):"
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
        [ $(pwd) = "$BaHaMAS_testsFolder" ] && rm -rf "$name"
    done
    cecho ''
}
