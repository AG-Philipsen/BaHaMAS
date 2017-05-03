# NOTE: If at some points for some reason one would decide to allow as options
#       --startcondition and/or --host_seed (CL2QCD) one should think whether
#       the continue part should be modified or not.

source ${BaHaMAS_repositoryTopLevelPath}/JobScriptAutomation/CommandLineParser_aux.bash

function ParseCommandLineOption(){

    local commandLineOptions, mutuallyExclusiveOptions
    commandLineOptions=( $(SplitCombinedShortOptionsInSingleOptions $@) )
    mutuallyExclusiveOptions=( "-s | --submit"        "-c | --continue"    "-C | --continueThermalization"
                               "-t | --thermalize"    "-l | --liststatus"  "-U | --uncommentBetas"
                               "-u | --commentBetas"  "-d | --dataBase"    "-i | --invertConfigurations"
                               "--submitonly"  "--accRateReport"  "--cleanOutputFiles"  "--completeBetasFile")
    MUTUALLYEXCLUSIVEOPTS_PASSED=()

    while [ "$1" != "" ]; do
        case $1 in
            -h | --help )
                PrintHelper
                exit 0
                shift;;

            --jobscript_prefix=* )
                JOBSCRIPT_PREFIX=${1#*=}; shift ;;

            --chempot_prefix=* )
                CHEMPOT_PREFIX=${1#*=}; shift ;;

            --kappa_prefix=* )
                [ $STAGGERED = "TRUE" ] && printf "\n\e[0;31m The option --kappa_prefix can be used only in WILSON simulations! Aborting...\n\n\e[0m" && exit -1
                MASS_PREFIX=${1#*=}; shift ;;

            --mass_prefix=* )
                [ $WILSON = "TRUE" ] && printf "\n\e[0;31m The option --mass_prefix can be used only in STAGGERED simulations! Aborting...\n\n\e[0m" && exit -1
                MASS_PREFIX=${1#*=}; shift ;;

            --ntime_prefix=* )
                NTIME_PREFIX=${1#*=}; shift ;;

            --nspace_prefix=* )
                NSPACE_PREFIX=${1#*=}; shift ;;

            --beta_prefix=* )
                BETA_PREFIX=${1#*=}; shift ;;

            --betasfile=* )
                BETASFILE=${1#*=}; shift ;;

            --chempot=* )
                CHEMPOT=${1#*=}; shift ;;

            --kappa=* )
                MASS=${1#*=}; shift ;;

            -w=* | --walltime=* )
                WALLTIME=${1#*=}
                if [[ $WALLTIME =~ ^([[:digit:]]+[dhms])+$ ]]; then
                    WALLTIME=$(TimeStringToSecond $WALLTIME)
                    WALLTIME=$(SecondsToTimeStringWithDays $WALLTIME)
                fi
                if [[ ! $WALLTIME =~ ^([0-9]+-)?[0-9]{1,2}:[0-9]{2}:[0-9]{2}$ ]]; then
                    printf "\n\e[0;31m Specified walltime format invalid! Aborting...\n\n\e[0m" && exit -1
                fi
                shift ;;

            -m=* | --measurements=* )
                MEASUREMENTS=${1#*=}; shift ;;

            -f=* | --confSaveFrequency=* )
                NSAVE=${1#*=}; shift ;;

            -F=* | --confSavePointFrequency=* )
                NSAVEPOINT=${1#*=}; shift ;;

            --intsteps0=* )
                INTSTEPS0=${1#*=}; shift ;;

            --intsteps1=* )
                INTSTEPS1=${1#*=}; shift ;;

            --cgbs=* )
                CGBS=${1#*=}; shift ;;

            -p | --doNotMeasurePbp )
                MEASURE_PBP="FALSE"; shift ;;

            --doNotUseRAfiles )
                [ $WILSON = "TRUE" ] && printf "\n\e[0;31m The option --doNotUseRAfiles can be used only in STAGGERED simulations! Aborting...\n\n\e[0m" && exit -1
                USE_RATIONAL_APPROXIMATION_FILE="FALSE"; shift ;;

            --doNotUseMultipleChains )
                USE_MULTIPLE_CHAINS="FALSE"
                if [ $THERMALIZE = "FALSE" ]; then
                    BETA_POSTFIX=""
                fi
                shift ;;

            --partition=* )
                LOEWE_PARTITION=${1#*=};
                if [[ $CLUSTER_NAME != "LOEWE" ]]; then
                    printf "\n\e[0;31m The options --partition can be used only on the LOEWE! Aborting...\n\n\e[0m"
                    exit -1
                fi
                shift ;;

            --constraint=* )
                LOEWE_CONSTRAINT=${1#*=};
                if [[ $CLUSTER_NAME != "LOEWE" ]]; then
                    printf "\n\e[0;31m The options --constraint can be used only on the LOEWE! Aborting...\n\n\e[0m"
                    exit -1
                fi
                shift ;;

            --node=* )
                LOEWE_NODE=${1#*=};
                if [[ $CLUSTER_NAME != "LOEWE" ]]; then
                    printf "\n\e[0;31m The options --node can be used only on the LOEWE! Aborting...\n\n\e[0m"
                    exit -1
                fi
                shift ;;

            -s | --submit )
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
                SUBMIT="TRUE"
                shift;;

            --submitonly )
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
                SUBMITONLY="TRUE"
                shift;;

            -t | --thermalize )
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
                THERMALIZE="TRUE"
                shift;;

            -c | --continue )
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
                CONTINUE="TRUE"
                shift;;

            -c=* | --continue=* )
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
                CONTINUE="TRUE"
                CONTINUE_NUMBER=${1#*=};
                if [[ ! $CONTINUE_NUMBER =~ ^[[:digit:]]+$ ]];then
                    printf "\n\e[0;31m The specified number for --continue=[number] must be an integer containing at least one or more digits! Aborting...\n\n\e[0m"
                    exit -1
                fi
                shift;;

            -C | --continueThermalization )
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
                CONTINUE_THERMALIZATION="TRUE"
                shift;;

            -C=* | --continueThermalization=* )
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
                CONTINUE_THERMALIZATION="TRUE"
                CONTINUE_NUMBER=${1#*=};
                if [[ ! $CONTINUE_NUMBER =~ ^[[:digit:]]+$ ]];then
                    printf "\n\e[0;31m The specified number for --continueThermalization=[number] must be an integer containing at least one or more digits! Aborting...\n\n\e[0m"
                    exit -1
                fi
                shift;;

            -l | --liststatus )
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
                LISTSTATUS="TRUE"
                shift;;

            --measureTime )
                [ $LISTSTATUS = "FALSE" ] && printf "\n\e[0;31mSecondary option --measureTime must be given after the primary one \"-l | --liststatus\"! Aborting...\n\n\e[0m" && exit -1
                LISTSTATUS_MEASURE_TIME="TRUE"
                shift;;

            --showOnlyQueued )
                [ $LISTSTATUS = "FALSE" ] && printf "\n\e[0;31mSecondary option --showOnlyQueued must be given after the primary one \"-l | --liststatus\"! Aborting...\n\n\e[0m" && exit -1
                LISTSTATUS_SHOW_ONLY_QUEUED="TRUE"
                shift;;

            --accRateReport=* )
                INTERVAL=${1#*=}
                [[ ! $INTERVAL =~ [[:digit:]]+ ]] && printf "\n\e[0;31m Interval for --accRateReport option must be an integer number! Aborting...\n\n\e[0m" && exit -1
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--accRateReport" )
                ACCRATE_REPORT="TRUE"
                shift ;;

            --cleanOutputFiles )
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
                CLEAN_OUTPUT_FILES="TRUE"
                shift ;;

            --all )
                [ $CLEAN_OUTPUT_FILES = "FALSE" ] && printf "\n\e[0;31mSecondary option --all must be given after the primary one! Aborting...\n\n\e[0m" && exit -1
                SECONDARY_OPTION_ALL="TRUE"
                shift;;

            --completeBetasFile* )
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--completeBetasFile" )
                COMPLETE_BETAS_FILE="TRUE"
                local TMP_STRING=${1#*File}
                if [ "$TMP_STRING" != "" ]; then
                    if [ ${TMP_STRING:0:1} == "=" ]; then
                        NUMBER_OF_CHAINS_TO_BE_IN_THE_BETAS_FILE=${1#*=}
                    else
                        printf "\n\e[0;31m Invalid option \e[1m$1\e[0;31m (see help for further information)! Aborting...\n\n\e[0m"
                    fi
                fi
                shift ;;

            -U | --uncommentBetas | -u | --commentBetas )
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
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
                shift
                ;;

            -i | --invertConfigurations)
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--invertConfigurations" )
                INVERT_CONFIGURATIONS="TRUE"
                shift
                ;;

            -d | --database)
                CALL_DATABASE="TRUE"
                MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--database" )
                shift
                DATABASE_OPTIONS=( $@ )
                shift $#
                ;;

            * ) printf "\n\e[0;31m Invalid option \e[1m$1\e[0;31m (see help for further information)! Aborting...\n\n\e[0m" ; exit -1 ;;
        esac
    done

    if [ ${#MUTUALLYEXCLUSIVEOPTS_PASSED[@]} -gt 1 ]; then
        printf "\n\e[0;31m The options\n\n\e[1m"
        for OPT in "${MUTUALLYEXCLUSIVEOPTS[@]}"; do
            printf "  %s\n" "$OPT"
        done
        printf "\n\e[0;31m are mutually exclusive and must not be combined! Aborting...\n\n\e[0m"
        exit -1
    fi
}
