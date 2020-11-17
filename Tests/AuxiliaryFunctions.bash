#
#  Copyright (c) 2017,2020 Alessandro Sciarra
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

function CheckTestEnvironment()
{
    local name postfix
    postfix="$(date +%H%M%S)"
    if [[ -d "${testFolder}" ]]; then
        Warning "Found " emph "${testFolder}" ", renaming it!"
        mv "${testFolder}" "${testFolder}_${postfix}" || exit ${BHMAS_fatalBuiltin}
    fi
    if [[ -f "${userVariablesFile}" ]]; then
        if [[ ! -L "${userVariablesFile}" ]]; then
            Fatal ${BHMAS_fatalLogicError} 'File ' file "${userVariablesFile}" ' existing and not a symlink!'
        else
            rm "${userVariablesFile}"
        fi
    fi
}

function __static__CreateParametersFolders()
{
    mkdir -p "${submitDirWithBetaFolders}" || exit ${BHMAS_fatalBuiltin}
    mkdir -p "${runDirWithBetaFolders}" || exit ${BHMAS_fatalBuiltin}
}

function __static__SetBetaFoldersAndPrepareJobVariables()
{
    betaFolders=( $(awk '/^[[:space:]]*#/{next} {printf "b%s_%s_continueWithNewChain\n", $1, $2}' "${submitDirWithBetaFolders}/betas") )
    # Here assume that beta values in the fakeBetas file are all the same, only seeds change!
    case "${software}" in
        CL2QCD )
            jobBetaSeedsStrings[0]="$(awk '/^[[:space:]]*#/{next} {if(betaPrinted==0){printf "b%s_%s", $1, $2; betaPrinted=1}else{printf "_%s", $2}}' "${submitDirWithBetaFolders}/betas")"
            ;;
        openQCD-FASTSUM )
            jobBetaSeedsStrings=( $(awk '/^[[:space:]]*#/{next} {printf "b%s_%s ", $1, $2}' "${submitDirWithBetaFolders}/betas") ) #Word split on spaces
            ;;
        * )
            Fatal ${BHMAS_fatalLogicError} "Unknown software in \"${FUNCNAME}\" function!"
            ;;
    esac
}

function __static__CreateRationalApproxFolderWithFiles()
{
    local filename approxFolder
    approxFolder="${submitTestFolder}/${projectFolder}/Rational_Approximations"
    mkdir -p "${approxFolder}"
    for filename in 'Approx_Heatbath' 'Approx_MD' 'Approx_Metropolis'; do
        cp "${BHMAS_testsFolderAuxFiles}/${software}/fakeApprox" "${approxFolder}/Nf2_${filename}"
    done
}

function __static__CreateBetaFolders()
{
    local folder
    for folder in "${betaFolders[@]}"; do
        mkdir "${submitDirWithBetaFolders}/${folder}" || exit ${BHMAS_fatalBuiltin}
        mkdir "${runDirWithBetaFolders}/${folder}" || exit ${BHMAS_fatalBuiltin}
    done
}

function __static__CreateFilesInSubmitBetaFolders()
{
    local folder file
    for folder in "${betaFolders[@]}"; do
        for file in "$@"; do
            touch "${submitDirWithBetaFolders}/${folder}/${file}" || exit ${BHMAS_fatalBuiltin}
        done
    done
}

function __static__CreateFilesInRunBetaFolders()
{
    local folder file
    for folder in "${betaFolders[@]}"; do
        for file in "$@"; do
            printf "Not empty\n" > "${runDirWithBetaFolders}/${folder}/${file}" || exit ${BHMAS_fatalBuiltin}
        done
    done
}

function __static__CreatenfiguratiornSymlinkInRunBetaFolder()
{
    local folder
    for folder in "${betaFolders[@]}"; do
        ln -s "${submitTestFolder}/${projectFolder}/Thermalized_Configurations/conf.${testParametersString}_${folder%_*}_$1"\
           "${runDirWithBetaFolders}/${folder}/conf.${testParametersString}_${folder%_*}_$1" || exit ${BHMAS_fatalBuiltin}
    done
}

function __static__AddStringToAllLinesOfBetasFile()
{
    awk -i inplace -v new="$1" '/^[[:space:]]*#/{next} {printf "%s   %s\n", $0, new}' "${submitDirWithBetaFolders}/betas" || exit ${BHMAS_fatalBuiltin}
}

function __static__CopyAuxiliaryFileAtBetaFolderLevel()
{
    cp "${BHMAS_testsFolderAuxFiles}/$1" "${submitDirWithBetaFolders}/$2" || exit ${BHMAS_fatalBuiltin}
}

function __static__CopyAuxiliaryFilesToSubmitBetaFolders()
{
    local folder file
    for folder in "${betaFolders[@]}"; do
        for file in "$@"; do
            cp "${BHMAS_testsFolderAuxFiles}/${software}/${file}" "${submitDirWithBetaFolders}/${folder}" || exit ${BHMAS_fatalBuiltin}
        done
    done
}

function __static__SetNumberOfIntegratorScalesInInputFile()
{
    local folder file numScales
    folder="$1"
    file="$2"
    numScales="$3"
    if [[ ${software} == 'CL2QCD' ]]; then
        sed -E -i 's@nTimeScales=[0-9]+@'"nTimeScales=${numScales}"'@g'   "${submitDirWithBetaFolders}/${folder}/${file}" || exit ${BHMAS_fatalBuiltin}
    elif [[ ${software} == 'openQCD-FASTSUM' ]]; then
        sed -E -i 's@nlv[[:space:]]+[0-9]+@'"$(printf "%-13s%s" "nlv" "${numScales}")"'@g'   "${submitDirWithBetaFolders}/${folder}/${file}" || exit ${BHMAS_fatalBuiltin}
    fi
}

function __static__CopyAuxiliaryFilesToRunBetaFolders()
{
    local folder file
    for folder in "${betaFolders[@]}"; do
        for file in "$@"; do
            cp "${BHMAS_testsFolderAuxFiles}/${software}/${file}" "${runDirWithBetaFolders}/${folder}" || exit ${BHMAS_fatalBuiltin}
        done
    done
}

function __static__CompleteInputFilesWithCorrectPaths()
{
    local folder filename approxFolder
    approxFolder="${submitTestFolder}/${projectFolder}/Rational_Approximations"
    for folder in "${betaFolders[@]}"; do
        printf '%s\n'\
               "rationalApproxFileHB=${approxFolder}/Nf2_Approx_Heatbath"\
               "rationalApproxFileMD=${approxFolder}/Nf2_Approx_MD"\
               "rationalApproxFileMetropolis=${approxFolder}/Nf2_Approx_Metropolis"\
               >> "${submitDirWithBetaFolders}/${folder}/fakeInput" || exit ${BHMAS_fatalBuiltin}
    done
}

function __static__CreateThermalizedConfigurationFolder()
{
    mkdir "${submitTestFolder}/${projectFolder}/Thermalized_Configurations" || exit ${BHMAS_fatalBuiltin}
}

function __static__CreateThermalizedConfigurations()
{
    local folder
    for folder in "${betaFolders[@]}"; do
        touch "${submitTestFolder}/${projectFolder}/Thermalized_Configurations/conf.${testParametersString}_${folder%_*}_$1" || exit ${BHMAS_fatalBuiltin}
    done
}

function MakeTestPreliminaryOperations()
{
    local software projectFolder trashFolderName file folder\
          submitDirWithBetaFolders runDirWithBetaFolders
    #Link user variable file depending on test case
    if [[ "$1" =~ (^|)openQCD-FASTSUM(|$) ]]; then
        readonly software='openQCD-FASTSUM'
        readonly projectFolder='WilsonFakeProject'
        testParametersString='Nf2_mui0_k1150_nt8_ns48'
        testParametersPath="/${testParametersString//_/\/}"
    else
        readonly software='CL2QCD'
        readonly projectFolder='StaggeredFakeProject'
        testParametersString='Nf2_mui0_mass0050_nt6_ns18'
        testParametersPath="/${testParametersString//_/\/}"
    fi
    ln -s "${BHMAS_testsFolder}/UserVariables_${software}.bash" "${userVariablesFile}" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        Fatal ${BHMAS_fatalBuiltin} 'Unable to create symlink for user variables file!'
    fi

    #Always create params folders and go at beta folders level
    readonly submitDirWithBetaFolders="${submitTestFolder}/${projectFolder}${testParametersPath}"
    readonly runDirWithBetaFolders="${runTestFolder}/${projectFolder}${testParametersPath}"
    __static__CreateParametersFolders
    cd "${submitDirWithBetaFolders}" || exit ${BHMAS_fatalBuiltin}
    #Always use completed file and then in case overwrite
    cp "${BHMAS_testsFolderAuxFiles}/${software}/fakeBetas" "${submitDirWithBetaFolders}/betas"
    __static__SetBetaFoldersAndPrepareJobVariables

    case "$1" in
        CL2QCD-prepare-only | CL2QCD-new-chain* )
            __static__CreateRationalApproxFolderWithFiles
            __static__CreateThermalizedConfigurationFolder
            __static__CreateThermalizedConfigurations "fromConf_trNr5000"
            __static__AddStringToAllLinesOfBetasFile "t120"
            if [[ $1 =~ goal ]]; then
                __static__AddStringToAllLinesOfBetasFile "g15000"
            fi
            ;;

        CL2QCD-submit-only )
            __static__CreateRationalApproxFolderWithFiles
            __static__CreateThermalizedConfigurationFolder
            __static__CreateThermalizedConfigurations "fromConf_trNr5000"
            __static__CreateBetaFolders
            __static__CopyAuxiliaryFileAtBetaFolderLevel "${software}/fakeMetadata" ".BaHaMAS_metadata"
            __static__CopyAuxiliaryFilesToSubmitBetaFolders "fakeInput" "fakeExecutable"
            __static__CopyAuxiliaryFilesToRunBetaFolders "fakeInput" "fakeExecutable"
            __static__CreatenfiguratiornSymlinkInRunBetaFolder "fromConf_trNr5000"
            mkdir "Jobscripts_TEST" || exit ${BHMAS_fatalBuiltin}
            printf "#SBATCH --time=2:45:00\n" > "${submitDirWithBetaFolders}/Jobscripts_TEST/fakePrefix_${testParametersString}__${jobBetaSeedsStrings[0]}"
            ;;

        CL2QCD-thermalize* )
            __static__CreateRationalApproxFolderWithFiles
            __static__CreateThermalizedConfigurationFolder
            if [[ $1 =~ conf$ ]]; then
                __static__CreateThermalizedConfigurations "fromHot_trNr1000"
            fi
            ;;

        CL2QCD-continue-* )
            if [[ $1 =~ therm ]]; then
                betaFolders=( "${betaFolders[@]/continueWithNewChain/thermalizeFromHot}" )
                __static__CreateThermalizedConfigurationFolder
            fi
            __static__CreateRationalApproxFolderWithFiles
            __static__CreateBetaFolders
            __static__CopyAuxiliaryFilesToSubmitBetaFolders "fakeInput"
            __static__SetNumberOfIntegratorScalesInInputFile "${betaFolders[0]}" "fakeInput" 1
            __static__CopyAuxiliaryFilesToRunBetaFolders "fakeExecutable" "fakeOutput" "fakeOutput_pbp.dat"
            __static__CopyAuxiliaryFileAtBetaFolderLevel "${software}/fakeMetadata" ".BaHaMAS_metadata"
            __static__CompleteInputFilesWithCorrectPaths
            __static__CreateFilesInRunBetaFolders "conf.save" "prng.save"
            if [[ ! $1 =~ therm ]]; then
                # This is not needed for thermalization from hot
                __static__CreatenfiguratiornSymlinkInRunBetaFolder "fromConf_trNr5000"
            fi
            case "${1##*-}" in
                last )
                    __static__CreateFilesInRunBetaFolders "conf.00800" "prng.00800"
                    __static__AddStringToAllLinesOfBetasFile "rlast"
                    ;;
                resume )
                    __static__CreateFilesInRunBetaFolders "conf.00100" "prng.00100" "conf.00200" "prng.00200" "conf.00200_backup" "conf.save_backup" "prng.save_backup"
                    __static__AddStringToAllLinesOfBetasFile "r100"
                    ;;
                goal )
                    __static__AddStringToAllLinesOfBetasFile "g15000"
                    ;;
            esac
            #It is important to restore the betaFolders variable to continueWithNewChain
            #postfix which is used for potential following tests (betaFolders is global)
            if [[ $1 =~ therm ]]; then
                betaFolders=( "${betaFolders[@]/thermalizeFromHot/continueWithNewChain}" )
            fi
            ;;

        CL2QCD-simulation-status* )
            __static__CreateBetaFolders
            __static__CopyAuxiliaryFileAtBetaFolderLevel "${software}/fakeMetadata" ".BaHaMAS_metadata"
            __static__CopyAuxiliaryFilesToSubmitBetaFolders "fakeExecutable.123456.out" "fakeInput"
            __static__SetNumberOfIntegratorScalesInInputFile "${betaFolders[-1]}" "fakeInput" 1
            __static__CopyAuxiliaryFilesToRunBetaFolders "fakeOutput"
            ;;

        CL2QCD-accRateReport* )
            __static__CreateBetaFolders
            __static__CopyAuxiliaryFileAtBetaFolderLevel "${software}/fakeMetadata" ".BaHaMAS_metadata"
            __static__CopyAuxiliaryFilesToRunBetaFolders "fakeOutput"
            ;;

        CL2QCD-cleanOutputFiles* )
            __static__CreateBetaFolders
            __static__CopyAuxiliaryFileAtBetaFolderLevel "${software}/fakeMetadata" ".BaHaMAS_metadata"
            __static__CopyAuxiliaryFilesToRunBetaFolders "fakeOutput" "fakeOutput_pbp.dat"
            ;;

        CL2QCD-measure* )
            __static__CreateBetaFolders
            __static__CopyAuxiliaryFileAtBetaFolderLevel "${software}/fakeMetadata" ".BaHaMAS_metadata"
            __static__CreateFilesInRunBetaFolders "conf.00100" "conf.00200" "conf.00300" "conf.00400"
            if [[ $1 =~ some$ ]]; then
                __static__CreateFilesInRunBetaFolders "conf.00100_2_3_7_1_corr" "conf.00100_1_2_3_1_corr"
            fi
            ;;

        openQCD-FASTSUM-prepare-only | openQCD-FASTSUM-new-chain* )
            __static__CreateThermalizedConfigurationFolder
            __static__CreateThermalizedConfigurations "fromConf_trNr5000"
            if [[ $1 =~ goal ]]; then
                __static__AddStringToAllLinesOfBetasFile "g15000"
            fi
            ;;

        openQCD-FASTSUM-submit-only )
            __static__CreateThermalizedConfigurationFolder
            __static__CreateThermalizedConfigurations "fromConf_trNr5000"
            __static__CreateBetaFolders
            __static__CopyAuxiliaryFileAtBetaFolderLevel "${software}/fakeMetadata" ".BaHaMAS_metadata"
            __static__CopyAuxiliaryFilesToSubmitBetaFolders "fakeInput"
            __static__CopyAuxiliaryFilesToRunBetaFolders "fakeInput"
            __static__CreateFilesInSubmitBetaFolders "qcd1_1_2_4_6"
            __static__CreateFilesInRunBetaFolders "qcd1_1_2_4_6"
            __static__CreatenfiguratiornSymlinkInRunBetaFolder "fromConf_trNr5000"
            mkdir "Jobscripts_TEST" || exit ${BHMAS_fatalBuiltin}
            local string
            for string in "${jobBetaSeedsStrings[@]}"; do
                printf "#SBATCH --time=2:45:00\n" > "${submitDirWithBetaFolders}/Jobscripts_TEST/fakePrefix_${testParametersString}__${string}"
            done
            ;;

        openQCD-FASTSUM-thermalize* )
            __static__CreateThermalizedConfigurationFolder
            if [[ $1 =~ conf$ ]]; then
                __static__CreateThermalizedConfigurations "fromHot_trNr1000"
            fi
            ;;

        openQCD-FASTSUM-continue* )
            local digitConf resumeConf
            if [[ $1 =~ therm ]]; then
                betaFolders=( "${betaFolders[@]/continueWithNewChain/thermalizeFromHot}" )
                __static__CreateThermalizedConfigurationFolder
                digitConf=0
                resumeConf=60
            else
                digitConf=5
                resumeConf=5060
            fi
            __static__CreateBetaFolders
            __static__CopyAuxiliaryFilesToSubmitBetaFolders "fakeInput"
            __static__SetNumberOfIntegratorScalesInInputFile "${betaFolders[0]}" "fakeInput" 1
            __static__CopyAuxiliaryFilesToRunBetaFolders "fakeOutput.log"
            __static__CreateFilesInSubmitBetaFolders "qcd1_1_2_4_6"
            __static__CreateFilesInRunBetaFolders "qcd1_1_2_4_6"
            __static__CopyAuxiliaryFileAtBetaFolderLevel "${software}/fakeMetadata" ".BaHaMAS_metadata"
            __static__CreateFilesInRunBetaFolders {conf,prng,data}.0${digitConf}0{2..8..2}0 {conf,prng}.06020 conf.07040
            if [[ ! $1 =~ therm ]]; then
                # This is not needed for thermalization from hot
                __static__CreatenfiguratiornSymlinkInRunBetaFolder "fromConf_trNr5000"
            fi
            case "${1##*-}" in
                last )
                    __static__AddStringToAllLinesOfBetasFile "rlast"
                    ;;
                resume )
                    __static__AddStringToAllLinesOfBetasFile "r${resumeConf}"
                    ;;
                goal )
                    __static__AddStringToAllLinesOfBetasFile "g15000"
                    ;;
            esac
            #It is important to restore the betaFolders variable to continueWithNewChain
            #postfix which is used for potential following tests (betaFolders is global)
            if [[ $1 =~ therm ]]; then
                betaFolders=( "${betaFolders[@]/thermalizeFromHot/continueWithNewChain}" )
            fi
            ;;

        openQCD-FASTSUM-simulation-status* )
            __static__CreateBetaFolders
            __static__CopyAuxiliaryFileAtBetaFolderLevel "${software}/fakeMetadata" ".BaHaMAS_metadata"
            __static__CopyAuxiliaryFilesToSubmitBetaFolders "fakeInput"
            __static__SetNumberOfIntegratorScalesInInputFile "${betaFolders[-1]}" "fakeInput" 1
            __static__CopyAuxiliaryFilesToRunBetaFolders "fakeOutput.log"
            __static__CreatenfiguratiornSymlinkInRunBetaFolder "fromConf_trNr5000"
            ;;

        openQCD-FASTSUM-accRateReport* )
            __static__CreateBetaFolders
            __static__CopyAuxiliaryFileAtBetaFolderLevel "${software}/fakeMetadata" ".BaHaMAS_metadata"
            __static__CopyAuxiliaryFilesToRunBetaFolders "fakeOutput.log"
            __static__CreatenfiguratiornSymlinkInRunBetaFolder "fromConf_trNr5000"
            ;;

        openQCD-FASTSUM-cleanOutputFiles* )
            __static__CreateBetaFolders
            __static__CopyAuxiliaryFileAtBetaFolderLevel "${software}/fakeMetadata" ".BaHaMAS_metadata"
            __static__CopyAuxiliaryFilesToRunBetaFolders "fakeOutput.log"
            ;;

        completeBetasFile* )
            __static__CopyAuxiliaryFileAtBetaFolderLevel "fakeBetasToBeCompleted" "betas"
            ;;

        commentBetas* | uncommentBetas* )
            __static__CopyAuxiliaryFileAtBetaFolderLevel "fakeBetasToBeCommented" "betas"
            ;;

        database* )
            local databaseFolder; databaseFolder="${submitTestFolder}/${projectFolder}/SimulationsOverview"
            mkdir -p "${databaseFolder}"
            cp "${BHMAS_testsFolderAuxFiles}/fakeOverviewDatabase" "${databaseFolder}/2022_01_01_OverviewDatabase_$(whoami)"
            if [[ $1 =~ update ]]; then
                __static__CreateBetaFolders
                __static__CopyAuxiliaryFileAtBetaFolderLevel "${software}/fakeMetadata" ".BaHaMAS_metadata"
                __static__CopyAuxiliaryFilesToSubmitBetaFolders "fakeInput"
                if [[ ${software} = CL2QCD ]]; then
                    __static__CopyAuxiliaryFilesToRunBetaFolders "fakeOutput"
                else
                    __static__CreatenfiguratiornSymlinkInRunBetaFolder "fromConf_trNr5000"
                    __static__CopyAuxiliaryFilesToRunBetaFolders "fakeOutput.log"
                fi
                cecho -d "${submitDirWithBetaFolders}" > "fakeDatabasePath"
            fi
            ;;

        * )
            ;;
    esac
}

function InhibitBaHaMASCommands()
{
    function less(){ cecho -d "less $*"; }
    function sbatch(){ cecho -d "sbatch $*"; }
    function make(){ cecho -d "make $*"; touch "${@: -1}"; }
    #To make liststatus find running job and then test measure time
    #NOTE: jobBetaSeedsStrings is an array because with openQCD each run handle one seed only!
    #      Here we fake mark the first entry as running to have something running for all codes.
    if [[ $1 =~ (simulation-status|database) ]]; then
        export jobnameForSqueue="${testParametersString}__${jobBetaSeedsStrings[0]}@RUNNING"
    fi
    function squeue(){ cecho -d "${jobnameForSqueue:-}"; }
    export -f less sbatch make squeue
}

function RunBaHaMASInTestMode()
{
    local testName
    testName=$1; shift
    printf "\n===============================\n" >> ${logFile}
    printf " $(date)\n" >> ${logFile}
    printf "===============================\n" >> ${logFile}
    printf "Running test \"${testName}\":\n    ${BHMAS_command} $@\n\n" >> ${logFile}
    # NOTE: Here we run BaHaMAS in subshell to exclude any potential variables conflict.
    #       Moreover we activate the test mode defining a variable before running it and
    #       we inhibit some commands in order to avoid job summission. Observe also that
    #       at the moment there are no options or options value which have a space in them
    #       and, hence, we can pass $@ to BaHaMAS instead of "$@" in order to word split
    #       the string passed to this function. This will break also spaces inside options
    #       and it has to be taken in mind in future! Observe also that we want to avoid
    #       any interactve Y/N question of BaHaMAS and we do it answering always Y.
    (
        InhibitBaHaMASCommands "${testName}"
        BHMAS_TESTMODE='TRUE' ${BHMAS_command} $@ < <(yes 'Y') >> ${logFile} 2>&1
    )
    if [[ $? -eq 0 ]]; then
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
    if [[ ${reportLevel} -eq 3 ]]; then
        printf -v stringTest "%-60s" "__${testName}$(cecho -d bb)_"
        stringTest="${stringTest// /.}"
        cecho -n lp "  $(printf '%+2s' ${testsRun})/$(printf '%-2s' ${#testsToBeRun[@]})" lc "${stringTest//_/ }"
    fi
    RunBaHaMASInTestMode "${testName}" "$@"
    if [[ $? -eq 0 ]]; then
        (( testsPassed++ ))
        if [[ ${reportLevel} -eq 3 ]]; then
            cecho lg "  passed"
        fi
    else
        (( testsFailed++ ))
        whichFailed+=( "${testName}" )
        if [[ ${reportLevel} -eq 3 ]]; then
            cecho lr "  failed"
        fi
    fi
}

function CleanTestsEnvironmentForFollowingTest()
{
    local bigTrash trashFolderName listOfFiles
    bigTrash="Trash"
    #Always go to simulation path level and move everything inside a Trash folder
    #which contains in the name also the test name (easy debug in case of failure)
    cd "${testFolder}" || exit ${BHMAS_fatalBuiltin}
    mkdir -p "${bigTrash}" || exit ${BHMAS_fatalBuiltin}
    listOfFiles=( * )
    if [[ ${#listOfFiles[@]} -eq 1 ]] && [[ "${listOfFiles[0]}" != "${bigTrash}" ]]; then
        Internal 'Folder ' dir "$(pwd)"\
                 '\ncontaining only ' emph "${bigTrash}" ' but it should not be the case!'
    else
        trashFolderName="Trash_$(date +%H%M%S-%3N)_$1"
        mkdir "${bigTrash}/${trashFolderName}" || exit ${BHMAS_fatalBuiltin}
        mv !("${bigTrash}") "${bigTrash}/${trashFolderName}/." || exit ${BHMAS_fatalBuiltin}
    fi
    if [[ -f "${userVariablesFile}" ]]; then
        if [[ ! -L "${userVariablesFile}" ]]; then
            Fatal ${BHMAS_fatalLogicError} 'File ' file "${userVariablesFile}" ' existing and not a symlink!'
        else
            rm "${userVariablesFile}"
        fi
    fi
}

function __static__PrintCenteredString()
{
    local tmpString stringTotalWidth indentation tmpStringLength padding
    tmpString="$1"
    if [[ $# -gt 1 ]]; then
        stringTotalWidth="$2"
    else
        stringTotalWidth="$(tput cols)"
    fi
    indentation="${3-}"
    tmpStringLength=$(printf '%s' "${tmpString}" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[mGK]//g" | wc -c)
    padding="$(printf '%0.1s' ' '{1..500})"
    printf "${indentation}%0.*s %s %0.*s\n"\
           "$(( (stringTotalWidth - 2 - tmpStringLength)/2 ))"\
           "${padding}"\
           "${tmpString}"\
           "$(( (stringTotalWidth - 2 - tmpStringLength)/2 ))"\
           "${padding}"
}

function PrintTestsReport()
{
    local indentation leftMargin testNameStringLength index lineOfEquals name percentage
    indentation='          '
    leftMargin='   '
    testNameStringLength=$(printf '%s\n' "${testsToBeRun[@]}" | wc -L)
    if [[ ${testNameStringLength} -lt 25 ]]; then # Minimum length
        testNameStringLength=25
    fi
    if (( testNameStringLength % 2 == 1 )); then # Aesthetics
        (( testNameStringLength+=1 ))
    fi
    for((index=0; index<testNameStringLength+3+2*${#leftMargin}; index++)); do
        lineOfEquals+='='
    done
    if [[ ${reportLevel} -ge 1 ]]; then
        local passedString failedString
        passedString="$(cecho lp "Run " emph "$(printf '%2d' ${testsRun})" " test(s): " lg "$(printf '%2d' ${testsPassed}) passed")"
        failedString="$(cecho lr "                $(printf '%2d' ${testsFailed}) failed")"
        cecho bb "\n${indentation}${lineOfEquals}"
        __static__PrintCenteredString "${passedString}" ${#lineOfEquals} "${indentation}"
        __static__PrintCenteredString "${failedString}" ${#lineOfEquals} "${indentation}"
        cecho bb "${indentation}${lineOfEquals}"
    fi
    if [[ ${reportLevel} -ge 2 ]]; then
        percentage=$(awk '{printf "%.0f%%", 100*$1/$2}' <<< "${testsPassed} ${testsRun}")
        __static__PrintCenteredString "${percentage} $(cecho wg "of tests passed!")" ${#lineOfEquals} "${indentation}"
        cecho bb "${indentation}${lineOfEquals}"
        if [[ ${testsFailed} -ne 0 ]]; then
            cecho lr "${indentation}${leftMargin}The following tests failed:"
            for name in "${whichFailed[@]}"; do
                cecho lr "${indentation}${leftMargin} - " emph "${name}"
            done
            cecho bb "${indentation}${lineOfEquals}"
        fi
    fi
    cecho ''
    if [[ ${testsFailed} -ne 0 ]]; then
        cecho lr B " Failures were detected! Not deleting log file!\n"
    else
        cecho lg B " All tests passed!\n"
    fi
}

function DeleteAuxiliaryFilesAndFolders()
{
    local name
    cd "${BHMAS_testsFolder}" || exit ${BHMAS_fatalBuiltin}
    [[ ${reportLevel} -eq 3 ]] && cecho bb " In $(pwd):"
    for name in "${listOfAuxiliaryFilesAndFolders[@]}"; do
        if [[ -d "${name}" ]]; then
            [[ ${reportLevel} -eq 3 ]] && cecho p " - Removing " dir "${name}"
        elif [[ -L "${name}" ]]; then
            [[ ${reportLevel} -eq 3 ]] && cecho p " - Removing " emph "${name}"
        elif [[ -f "${name}" ]]; then
            [[ ${reportLevel} -eq 3 ]] && cecho p " - Removing " file "${name}"
        elif ls "${name}" 1>/dev/null 2>&1; then
            cecho lr "   Error in ${FUNCNAME}: " emph "${name}" " neither file or directory, leaving it!"; continue
        fi
        [[ $(pwd) = "${BHMAS_testsFolder}" ]] && rm -rf "${name}"
    done
    cecho ''
}


MakeFunctionsDefinedInThisFileReadonly
