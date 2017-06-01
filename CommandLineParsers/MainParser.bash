# NOTE: If at some points for some reason one would decide to allow as options
#       --startcondition and/or --host_seed (CL2QCD) one should think whether
#       the continue part should be modified or not.

source ${BaHaMAS_repositoryTopLevelPath}/CommandLineParsers/CommonFunctionality.bash || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/CommandLineParsers/MainHelper.bash          || exit -2

function __static__PrintInvalidOptionErrorAndExit()
{
    cecho lr "\n Invalid option " emph "$1" " specified! Run " B "BaHaMAS" uB " with " emph "--help" " to get further information. Aborting...\n"; exit -1
}
function __static__PrintOptionSpecificationErrorAndExit()
{
    cecho lr "\n The value of the option " emph "$1" " was not correctly specified! Aborting...\n"; exit -1
}
function __static__PrintSecondaryOptionSpecificationErrorAndExit()
{
    cecho lr "\n The option " emph "$2" " is a secondary option of " emph "$1" " and it has to be given after it! Aborting...\n"; exit -1
}

function ParseCommandLineOption()
{

    local commandLineOptions mutuallyExclusiveOptions mutuallyExclusiveOptionsPassed option

    #The following two lines are not combined to respect potential spaces in options
    readarray -t commandLineOptions <<< "$(PrepareGivenOptionToBeProcessed "$@")"
    readarray -t commandLineOptions <<< "$(SplitCombinedShortOptionsInSingleOptions "${commandLineOptions[@]}")"

    #Reset argument function to be able to parse them as well as global given option
    set -- "${commandLineOptions[@]}"
    BHMAS_specifiedCommandLineOptions=( "${commandLineOptions[@]}" )

    mutuallyExclusiveOptions=( "-s | --submit"        "-c | --continue"    "-C | --continueThermalization"
                               "-t | --thermalize"    "-j | --jobstatus"   "-l | --liststatus"  "-U | --uncommentBetas"
                               "-u | --commentBetas"  "-d | --database"    "-i | --invertConfigurations"
                               "--submitonly"  "--accRateReport"  "--cleanOutputFiles"  "--completeBetasFile")
    mutuallyExclusiveOptionsPassed=()

    #Here it is fine to assume that option names and values are separated by spaces
    while [ $# -gt 0 ]; do
        case $1 in
            -h | --help )
                PrintMainHelper
                exit 0
                shift;;

            --jobscript_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_jobScriptPrefix="$2"
                fi
                shift 2 ;;

            --chempot_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_chempotPrefix="$2"
                fi
                shift 2 ;;

            --mass_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_massPrefix="$2"
                fi
                shift 2 ;;

            --ntime_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_ntimePrefix="$2"
                fi
                shift 2 ;;

            --nspace_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_nspacePrefix="$2"
                fi
                shift 2 ;;

            --beta_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_betaPrefix="$2"
                fi
                shift 2 ;;

            --betasfile )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_betasFilename="$2"
                fi
                shift 2 ;;

            -w | --walltime )
                if [[ ${2:-} =~ ^([0-9]+[dhms])+$ ]]; then
                    BHMAS_walltime=$(SecondsToTimeStringWithDays $(TimeStringToSecond $2) )
                else
                    BHMAS_walltime="${2:-}"
                fi
                if [[ ! $BHMAS_walltime =~ ^([0-9]+-)?[0-9]{1,2}:[0-9]{2}:[0-9]{2}$ ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                fi
                shift 2 ;;

            -m | --measurements )
                if [[ ! ${2:-} =~ ^[0-9]+$ ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_numberOfTrajectories=$2
                fi
                shift 2 ;;

            -f | --confSaveFrequency )
                if [[ ! ${2:-} =~ ^[0-9]+$ ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_checkpointFrequency=$2
                fi
                shift 2 ;;

            -F | --confSavePointFrequency )
                if [[ ! ${2:-} =~ ^[0-9]+$ ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_savepointFrequency=$2
                fi
                shift 2 ;;

            --cgbs )
                if [[ ! ${2:-} =~ ^[0-9]+$ ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_inverterBlockSize=$2
                fi
                shift 2 ;;

            -p | --doNotMeasurePbp )
                BHMAS_measurePbp="FALSE"; shift ;;

            --doNotUseMultipleChains )
                BHMAS_useMultipleChains="FALSE"
                if [ $BHMAS_thermalizeOption = "FALSE" ]; then
                    BHMAS_betaPostfix=""
                fi
                shift ;;

            --partition )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_clusterPartition="$2"
                fi
                shift 2 ;;

            --constraint )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_clusterConstraint="$2"
                fi
                shift 2 ;;

            --node )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    __static__PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_clusterNode="$2"
                fi
                shift 2 ;;

            -s | --submit )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_submitOption="TRUE"
                shift;;

            --submitonly )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_submitonlyOption="TRUE"
                shift;;

            -t | --thermalize )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_thermalizeOption="TRUE"
                shift;;

            -c | --continue )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_continueOption="TRUE"
                if [[ ! ${2:-} =~ ^(-|$) ]]; then
                    if [[ ! $2 =~ ^[0-9]+$ ]];then
                        __static__PrintOptionSpecificationErrorAndExit "$1"
                    else
                        BHMAS_trajectoryNumberUpToWhichToContinue=$2
                        shift
                    fi
                fi
                shift ;;

            -C | --continueThermalization )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_continueThermalizationOption="TRUE"
                if [[ ! ${2:-} =~ ^(-|$) ]]; then
                    if [[ ! $2 =~ ^[0-9]+$ ]];then
                        __static__PrintOptionSpecificationErrorAndExit "$1"
                    else
                        BHMAS_trajectoryNumberUpToWhichToContinue=$2
                        shift
                    fi
                fi
                shift ;;

            -j | --jobstatus )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_jobstatusOption="TRUE"
                shift;;

            --user )
                if [ $BHMAS_jobstatusOption = "FALSE" ]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "-j | --jobstatus" "$1"
                else
                    BHMAS_jobstatusUser="$2"
                    shift
                fi
                shift ;;

            --local )
                if [ $BHMAS_jobstatusOption = "FALSE" ]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "-j | --jobstatus" "$1"
                else
                    BHMAS_jobstatusLocal='TRUE'
                fi
                shift ;;

            -l )
                if [ $BHMAS_jobstatusOption = 'TRUE' ]; then
                    BHMAS_jobstatusLocal='TRUE'
                else
                    mutuallyExclusiveOptionsPassed+=( $1 )
                    BHMAS_liststatusOption="TRUE"
                fi
                shift;;

            --liststatus )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_liststatusOption="TRUE"
                shift;;

            --measureTime )
                if [ $BHMAS_liststatusOption = "FALSE" ]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "-l | --liststatus" "$1"
                else
                    BHMAS_liststatusMeasureTimeOption="TRUE"
                fi
                shift ;;

            --showOnlyQueued )
                if [ $BHMAS_liststatusOption = "FALSE" ]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "-l | --liststatus" "$1"
                else
                    BHMAS_liststatusShowOnlyQueuedOption="TRUE"
                fi
                shift ;;

            --accRateReport )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_accRateReportOption="TRUE"
                if [[ ! ${2:-} =~ ^(-|$) ]]; then
                    if [[ ! $2 =~ ^[0-9]+$ ]];then
                        __static__PrintOptionSpecificationErrorAndExit "$1"
                    else
                        BHMAS_accRateReportInterval=$2
                        shift
                    fi
                fi
                shift ;;

            --cleanOutputFiles )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_cleanOutputFilesOption="TRUE"
                shift ;;

            -a | --all )
                if [ $BHMAS_cleanOutputFilesOption = "FALSE" ] && [ $BHMAS_jobstatusOption = "FALSE" ]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "--cleanOutputFiles" "$1"
                elif [ $BHMAS_cleanOutputFilesOption = "TRUE" ]; then
                    BHMAS_cleanAllOutputFiles="TRUE"
                elif [ $BHMAS_jobstatusOption = "TRUE" ]; then
                    BHMAS_jobstatusAll='TRUE'
                fi
                shift ;;

            --completeBetasFile )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_completeBetasFileOption="TRUE"
                if [[ ! ${2:-} =~ ^(-|$) ]]; then
                    if [[ ! $2 =~ ^[0-9]+$ ]];then
                        __static__PrintOptionSpecificationErrorAndExit "$1"
                    else
                        BHMAS_numberOfChainsToBeInTheBetasFile=$2
                        shift
                    fi
                fi
                shift ;;

            -U | --uncommentBetas | -u | --commentBetas )
                if [ $BHMAS_jobstatusOption = "TRUE" ] && [ $1 = '-u' ]; then
                    BHMAS_jobstatusUser="$2"
                    shift
                else
                    mutuallyExclusiveOptionsPassed+=( $1 )
                    if [ $1 = '-U' ] || [ $1 = '--uncommentBetas' ]; then
                        BHMAS_commentBetasOption="FALSE"
                        BHMAS_uncommentBetasOption="TRUE"
                    elif [ $1 = '-u' ] || [ $1 = '--commentBetas' ]; then
                        BHMAS_uncommentBetasOption="FALSE"
                        BHMAS_commentBetasOption="TRUE"
                    fi
                    while [[ ! ${2:-} =~ ^(-|$) ]]; do
                        if [[ $2 =~ ^[0-9]\.[0-9]{4}_${BHMAS_seedPrefix}[0-9]{4}(_(NC|fC|fH))*$ ]]; then
                            BHMAS_betasToBeToggled+=( $2 )
                        elif [[ $2 =~ ^[0-9]\.[0-9]*$ ]]; then
                            BHMAS_betasToBeToggled+=( $(awk '{printf "%1.4f", $1}' <<< "$2") )
                        else
                            __static__PrintOptionSpecificationErrorAndExit "${mutuallyExclusiveOptionsPassed[-1]}"
                        fi
                        shift
                    done
                fi
                shift ;;

            -i | --invertConfigurations)
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_invertConfigurationsOption="TRUE"
                shift ;;

            -d | --database)
                BHMAS_databaseOption="TRUE"
                mutuallyExclusiveOptionsPassed+=( $1 )
                shift
                BHMAS_optionsToBePassedToDatabase=( $@ )
                shift $# ;;

            * )
                __static__PrintInvalidOptionErrorAndExit "$1" ;;
        esac
    done

    if [ ${#mutuallyExclusiveOptionsPassed[@]} -gt 1 ]; then
        cecho lr "\n The options"
        for option in "${mutuallyExclusiveOptions[@]}"; do
            cecho ly "   $option"
        done
        cecho lr " are mutually exclusive and cannot be combined! Aborting...\n"
        exit -1
    fi
}
