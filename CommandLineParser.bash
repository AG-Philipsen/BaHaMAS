# NOTE: If at some points for some reason one would decide to allow as options
#       --startcondition and/or --host_seed (CL2QCD) one should think whether
#       the continue part should be modified or not.

source ${BaHaMAS_repositoryTopLevelPath}/CommandLineParser_aux.bash

__static__PrintInvalidOptionErrorAndExit() {
    cecho lr "\n Invalid option " ly "$1" lr " specified! Run " B "BaHaMAS" uB " with " ly "--help" lr " to get further information. Aborting...\n"; exit -1
}
__static__PrintOptionSpecificationErrorAndExit() {
    cecho lr "\n The value of the option " ly "$1" lr " was not correctly specified! Aborting...\n"; exit -1
}
__static__PrintSecondaryOptionSpecificationErrorAndExit() {
    cecho lr "\n The option " ly "$2" lr " is a secondary option of " ly "$1" lr " and it has to be given after it! Aborting...\n"; exit -1
}

function ParseCommandLineOption(){

    local commandLineOptions mutuallyExclusiveOptions mutuallyExclusiveOptionsPassed option

    #The following two lines are not combined to respect potential spaces in options
    readarray -t commandLineOptions <<< "$(PrepareGivenOptionToBeProcessed "$@")"
    readarray -t commandLineOptions <<< "$(SplitCombinedShortOptionsInSingleOptions "${commandLineOptions[@]}")"

    #Reset argument function to be able to parse them
    set -- "${commandLineOptions[@]}"

    mutuallyExclusiveOptions=( "-s | --submit"        "-c | --continue"    "-C | --continueThermalization"
                               "-t | --thermalize"    "-l | --liststatus"  "-U | --uncommentBetas"
                               "-u | --commentBetas"  "-d | --dataBase"    "-i | --invertConfigurations"
                               "--submitonly"  "--accRateReport"  "--cleanOutputFiles"  "--completeBetasFile")
    mutuallyExclusiveOptionsPassed=()

    while [ "$1" != "" ]; do
        case $1 in
            -h | --help )
                PrintHelper
                exit 0
                shift;;

            --jobscript_prefix )
                if [[ $2 =~ ^- ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    JOBSCRIPT_PREFIX="$2"
                fi
                shift 2 ;;

            --chempot_prefix )
                if [[ $2 =~ ^- ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    CHEMPOT_PREFIX="$2"
                fi
                shift 2 ;;

            --mass_prefix )
                if [[ $2 =~ ^- ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    MASS_PREFIX="$2"
                fi
                shift 2 ;;

            --ntime_prefix )
                if [[ $2 =~ ^- ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    NTIME_PREFIX="$2"
                fi
                shift 2 ;;

            --nspace_prefix )
                if [[ $2 =~ ^- ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    NSPACE_PREFIX="$2"
                fi
                shift 2 ;;

            --beta_prefix )
                if [[ $2 =~ ^- ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    BETA_PREFIX"$2"
                fi
                shift 2 ;;

            --betasfile )
                if [[ $2 =~ ^- ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    BETASFILE="$2"
                fi
                shift 2 ;;

            -w | --walltime )
                if [[ $2 =~ ^([0-9]+[dhms])+$ ]]; then
                    WALLTIME=$(SecondsToTimeStringWithDays $(TimeStringToSecond $2) )
                else
                    WALLTIME="$2"
                fi
                if [[ ! $WALLTIME =~ ^([0-9]+-)?[0-9]{1,2}:[0-9]{2}:[0-9]{2}$ ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                fi
                shift 2 ;;

            -m | --measurements )
                if [[ ! $2 =~ ^[0-9]+$ ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    MEASUREMENTS=$2
                fi
                shift 2 ;;

            -f | --confSaveFrequency )
                if [[ ! $2 =~ ^[0-9]+$ ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    NSAVE=$2
                fi
                shift 2 ;;

            -F | --confSavePointFrequency )
                if [[ ! $2 =~ ^[0-9]+$ ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    NSAVEPOINT=$2
                fi
                shift 2 ;;

            --intsteps0 )
                if [[ ! $2 =~ ^[0-9]+$ ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    INTSTEPS0=$2
                fi
                shift 2 ;;

            --intsteps1 )
                if [[ ! $2 =~ ^[0-9]+$ ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    INTSTEPS1=$2
                fi
                shift 2 ;;

            --cgbs )
                if [[ ! $2 =~ ^[0-9]+$ ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    CGBS=$2
                fi
                shift 2 ;;

            -p | --doNotMeasurePbp )
                MEASURE_PBP="FALSE"; shift ;;

            --doNotUseMultipleChains )
                USE_MULTIPLE_CHAINS="FALSE"
                if [ $THERMALIZE = "FALSE" ]; then
                    BETA_POSTFIX=""
                fi
                shift ;;

            --partition )
                if [[ $2 =~ ^- ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    CLUSTER_PARTITION="$2"
                fi
                shift 2 ;;

            --constraint )
                if [[ $2 =~ ^- ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    CLUSTER_CONSTRAINT="$2"
                fi
                shift 2 ;;

            --node )
                if [[ $2 =~ ^- ]]; then
                    __static__PrintOptionSpecificationErrorAndExit $1
                else
                    CLUSTER_NODE="$2"
                fi
                shift 2 ;;

            -s | --submit )
                mutuallyExclusiveOptionsPassed+=( $1 )
                SUBMIT="TRUE"
                shift;;

            --submitonly )
                mutuallyExclusiveOptionsPassed+=( $1 )
                SUBMITONLY="TRUE"
                shift;;

            -t | --thermalize )
                mutuallyExclusiveOptionsPassed+=( $1 )
                THERMALIZE="TRUE"
                shift;;

            -c | --continue )
                mutuallyExclusiveOptionsPassed+=( $1 )
                CONTINUE="TRUE"
                if [[ ! $2 =~ ^- ]]; then
                    if [[ ! $2 =~ ^[0-9]+$ ]];then
                        __static__PrintOptionSpecificationErrorAndExit $1
                    else
                        CONTINUE_NUMBER=$2
                        shift
                    fi
                fi
                shift ;;

            -C | --continueThermalization )
                mutuallyExclusiveOptionsPassed+=( $1 )
                CONTINUE_THERMALIZATION="TRUE"
                if [[ ! $2 =~ ^- ]]; then
                    if [[ ! $2 =~ ^[0-9]+$ ]];then
                        __static__PrintOptionSpecificationErrorAndExit $1
                    else
                        CONTINUE_NUMBER=$2
                        shift
                    fi
                fi
                shift ;;

            -l | --liststatus )
                mutuallyExclusiveOptionsPassed+=( $1 )
                LISTSTATUS="TRUE"
                shift;;

            --measureTime )
                if [ $LISTSTATUS = "FALSE" ]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "-l | --liststatus" $1
                else
                    LISTSTATUS_MEASURE_TIME="TRUE"
                fi
                shift ;;

            --showOnlyQueued )
                if [ $LISTSTATUS = "FALSE" ]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "-l | --liststatus" $1
                else
                    LISTSTATUS_SHOW_ONLY_QUEUED="TRUE"
                fi
                shift ;;

            --accRateReport )
                mutuallyExclusiveOptionsPassed+=( $1 )
                ACCRATE_REPORT="TRUE"
                if [[ ! $2 =~ ^- ]]; then
                    if [[ ! $2 =~ ^[0-9]+$ ]];then
                        __static__PrintOptionSpecificationErrorAndExit $1
                    else
                        INTERVAL=$2
                        shift
                    fi
                fi
                shift ;;

            --cleanOutputFiles )
                mutuallyExclusiveOptionsPassed+=( $1 )
                CLEAN_OUTPUT_FILES="TRUE"
                shift ;;

            --all )
                if [ $CLEAN_OUTPUT_FILES = "FALSE" ]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "--cleanOutputFiles" $1
                else
                    SECONDARY_OPTION_ALL="TRUE"
                fi
                shift ;;

            --completeBetasFile )
                mutuallyExclusiveOptionsPassed+=( $1 )
                COMPLETE_BETAS_FILE="TRUE"
                if [[ ! $2 =~ ^- ]]; then
                    if [[ ! $2 =~ ^[0-9]+$ ]];then
                        __static__PrintOptionSpecificationErrorAndExit $1
                    else
                        NUMBER_OF_CHAINS_TO_BE_IN_THE_BETAS_FILE=$2
                        shift
                    fi
                fi
                shift ;;

            -U | --uncommentBetas | -u | --commentBetas )
                mutuallyExclusiveOptionsPassed+=( $1 )
                if [ $1 = '-U' ] || [ $1 = '--uncommentBetas' ]; then
                    COMMENT_BETAS="FALSE"
                    UNCOMMENT_BETAS="TRUE"
                elif [ $1 = '-u' ] || [ $1 = '--commentBetas' ]; then
                    UNCOMMENT_BETAS="FALSE"
                    COMMENT_BETAS="TRUE"
                fi

                while [[ "$2" =~ ^[[:digit:]]\.[[:digit:]]{4}_s[[:digit:]]{4}_(NC|fC|fH)$ ]] || [[ "$2" =~ ^[[:digit:]]\.[[:digit:]]*$ ]]
                do
                    if [[ "$2" =~ ^[[:digit:]]\.[[:digit:]]{4}_s[[:digit:]]{4}_(NC|fC|fH)$ ]]
                    then
                        UNCOMMENT_BETAS_SEED_ARRAY+=( $2 )
                    elif [[ "$2" =~ ^[[:digit:]]\.[[:digit:]]*$ ]]
                    then
                        UNCOMMENT_BETAS_ARRAY+=( $(awk '{printf "%1.4f", $1}' <<< "$2") )
                    fi
                    shift
                done
                shift ;;

            -i | --invertConfigurations)
                mutuallyExclusiveOptionsPassed+=( $1 )
                INVERT_CONFIGURATIONS="TRUE"
                shift ;;

            -d | --dataBase)
                CALL_DATABASE="TRUE"
                mutuallyExclusiveOptionsPassed+=( $1 )
                shift
                DATABASE_OPTIONS=( $@ )
                shift $# ;;

            * )
                __static__PrintInvalidOptionErrorAndExit $1
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
