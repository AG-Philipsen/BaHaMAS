#TODO:
#*If a filtering option is specified wrongly, should the program exit or not? If not, should the error message rather be printed in the end?
#*Is it necessary to implement the functionality where the script uses find the update the database?
#*Coloured output?
#*Other options?
#*User specific variables?
#*Putting the command line parser into another file in order to remove the cluttering - right now the parser makes up ~50% of the script.
#*Everytime the database is updated, actually create a new file with the date and time in the name? This way it possible to track how the statistics
# grow over longer periods.

function join { local IFS="$1"; shift; printf "$*"; } # "$*" expands to a single argument with all the elements delimited by the first character of $IFS

function projectStatisticsDatabase(){

    local FILENAME_GIVEN_AS_INPUT=""
    local CURRENT_DIRECTORY=$(pwd)

    NF_C=$((2*1))
    MU_C=$((2*2))
    K_C=$((2*3))
    NT_C=$((2*4))
    NS_C=$((2*5))
    BETA_C=$((2*6))
    TRAJNO_C=$((2*7))
    ACCRATE_C=$((2*8))
    ACCRATE_LAST1K_C=$((2*9))
    MAX_ACTION_C=$((2*10))
    STATUS_C=$((2*11))
    LASTTRAJ_C=$((2*12))

    declare -A COLUMNS=( [nfC]=$NF_C [muC]=$MU_C [kC]=$K_C [ntC]=$NT_C [nsC]=$NS_C [betaC]=$BETA_C [trajNoC]=$TRAJNO_C [accRateC]=$ACCRATE_C [accRateLast1KC]=$ACCRATE_LAST1K_C \
                              [maxDsC]=$MAX_ACTION_C [statusC]=$STATUS_C [lastTrajC]=$LASTTRAJ_C )

    #FSNA = FORMAT_SPECIFIER_NUMBER_ARRAY
    declare -A FSNA=( [nfC]="6" [muC]="7" [kC]="8" [ntC]="6" [nsC]="6" [betaC]="19" [trajNoC]="11" [accRateC]="8" [accRateLast1KC]="12" [maxDsC]="12" [statusC]="13" [lastTrajC]="11" )

    declare -A PRINTF_FORMAT_SPECIFIER_ARRAY=( [nfC]="%+${FSNA[nfC]}s" [muC]="%+${FSNA[muC]}s" [kC]="%+${FSNA[kC]}s" [ntC]="%${FSNA[ntC]}d" [nsC]="%${FSNA[nsC]}d" [betaC]="%+${FSNA[betaC]}s" \
                                                    [trajNoC]="%${FSNA[trajNoC]}d" [accRateC]="%+${FSNA[accRateC]}s" [accRateLast1KC]="%+${FSNA[accRateLast1KC]}s" [maxDsC]="%+${FSNA[maxDsC]}s" \
                                                    [statusC]="%+${FSNA[statusC]}s" [lastTrajC]="%+${FSNA[lastTrajC]}s" )

    declare -A HEADER_PRINTF_FORMAT_SPECIFIER_ARRAY=( [nfC]="%+$((${FSNA[nfC]}+1))s" [muC]="%+$((${FSNA[muC]}+1))s" [kC]="%+$((${FSNA[kC]}+1))s" [ntC]="%+$((${FSNA[ntC]}+1))s" [nsC]="%+$((${FSNA[nsC]}+1))s" [betaC]="%+$((${FSNA[betaC]}+1))s" \
                                                           [trajNoC]="%+$((${FSNA[trajNoC]}+1))s" [accRateC]="%+$((${FSNA[accRateC]}+1))s" [accRateLast1KC]="%+$((${FSNA[accRateLast1KC]}+1))s" [maxDsC]="%+$((${FSNA[maxDsC]}+1))s" [statusC]="%+$((${FSNA[statusC]}+1))s" [lastTrajC]="%+$((${FSNA[lastTrajC]}+1))s" )

    [ $WILSON = "TRUE" ] && MASS_PARAMETER="kappa"
    [ $STAGGERED = "TRUE" ] && MASS_PARAMETER="mass"

    declare -A HEADER_PRINTF_PARAMETER_ARRAY=( [nfC]="nf" [muC]=$CHEMPOT_PREFIX [kC]=$MASS_PARAMETER [ntC]=$NTIME_PREFIX [nsC]=$NSPACE_PREFIX [betaC]="beta_chain_type" [trajNoC]="trajNo" \
                                                    [accRateC]="acc" [accRateLast1KC]="accLast1K" [maxDsC]="maxDS" [statusC]="status" [lastTrajC]="l.T.[s]" )

    declare -a NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER=()

    local NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL=""
    local NAME_OF_COLUMN_NR_OF_COLUMN_STRING=""
    local NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING=""
    local NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING=""
    local NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING=""
    local LENGTH_OF_HEADER_SEPERATOR=""
    local STATISTICS_PRINTF_FORMAT_SPECIFIER_STRING=""
    local NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN=""

    local CUSTOMIZE_COLUMNS="FALSE"

    local STATISTICS_SUMMARY="FALSE"

    local UPDATE="FALSE"
    local DISPLAY="FALSE"
    local REPORT="FALSE"
    local SHOW="FALSE"

    local READ_DIRECTORIES_FROM_FILE="FALSE"
    local FILTER_SPECIFIC_DATABASE_FILE="FALSE"

    local FILTER_MU="FALSE"
    local FILTER_MASS="FALSE"
    local FILTER_NT="FALSE"
    local FILTER_NS="FALSE"
    local FILTER_BETA="FALSE"
    local FILTER_TYPE="FALSE"
    local FILTER_TRAJNO="FALSE"
    local FILTER_ACCRATE="FALSE"
    local FILTER_ACCRATE_LAST1K="FALSE"
    local FILTER_MAX_ACTION="FALSE"
    local FILTER_STATUS="FALSE"
    local FILTER_LASTTRAJ="FALSE"

    local UPDATE_WITH_FREQUENCY="FALSE"

    declare -a local NF_ARRAY
    declare -a local MU_ARRAY
    declare -a local MASS_ARRAY
    declare -a local NS_ARRAY
    declare -a local NT_ARRAY
    declare -a local BETA_ARRAY
    declare -a local TYPE_ARRAY
    declare -a local STATUS_ARRAY

    local TRAJ_LOW_VALUE=""
    local TRAJ_HIGH_VALUE=""

    local ACCRATE_LOW_VALUE=""
    local ACCRATE_HIGH_VALUE=""

    local ACCRATE_LAST1K_LOW_VALUE=""
    local ACCRATE_LAST1K_HIGH_VALUE=""

    local LAST_TRAJ_TIME=""

    local SLEEP_TIME=""
    local UPDATE_TIME=""


    #If the option -l | --local is given, then the option -l is replaced by mu,mass,nt,ns options with local values
    if ElementInArray "-l" $@ || ElementInArray "--local" $@;  then
        if ElementInArray "--$MASS_PARAMETER" $@ || ElementInArray "--mu" $@ || ElementInArray "--nt" $@ || ElementInArray "--ns" $@; then
            printf "\n\e[91m Option \e[1m-l | --local\e[21m not compatible with any of \e[1m--mu\e[21m, \e[1m--$MASS_PARAMETER\e[21m, \e[1m--nt\e[21m, \e[1m--ns\e[21m! Exiting...\e[0m\n\n"
            return
        fi
        local NEW_OPTIONS=()
        for VALUE in "$@"; do
            [[ $VALUE != "-l" ]] && [[ $VALUE != "--local" ]] && NEW_OPTIONS+=($VALUE)
        done && unset -v 'VALUE'
        ReadParametersFromPath $(pwd)
        set -- ${NEW_OPTIONS[@]} "--mu" "$CHEMPOT" "--$MASS_PARAMETER" "$MASS" "--nt" "$NTIME" "--ns" "$NSPACE"
    fi

    while [ $# -gt 0 ]; do
        case $1 in
            -c | --columns)
                OPTION=$1
                DISPLAY="TRUE"
                CUSTOMIZE_COLUMNS="TRUE"
                while [[ "$2" =~ ^[^-] ]]; do
                    case $2 in
                        nf)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( nfC )
                            shift
                            ;;
                        mu)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( muC )
                            shift
                            ;;
                        $MASS_PARAMETER)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( kC )
                            shift
                            ;;
                        nt)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( ntC )
                            shift
                            ;;
                        ns)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( nsC )
                            shift
                            ;;
                        beta_chain_type)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( betaC )
                            shift
                            ;;
                        trajNo)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( trajNoC )
                            shift
                            ;;
                        acc)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( accRateC )
                            shift
                            ;;
                        accLast1k)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( accRateLast1KC )
                            shift
                            ;;
                        maxDS)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( maxDsC )
                            shift
                            ;;
                        status)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( statusC )
                            shift
                            ;;
                        lastTraj)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( lastTrajC )
                            shift
                            ;;
                        *)
                            printf "\n\e[91m Option \e[1m$2\e[21m unrecognized! Exiting...\e[0m\n\n"
                            return
                            ;;
                    esac
                done
                ;;
            --sum)
                DISPLAY="TRUE"
                STATISTICS_SUMMARY="TRUE"
                ;;
            --nf)
                DISPLAY="TRUE"
                FILTER_NF="TRUE"
                while [[ $2 =~ ^[[:digit:]](\.[[:digit:]][[:digit:]]?)?$ ]]; do
                    NF_ARRAY+=( $2 )
                    shift
                done
                [ ${#NF_ARRAY[@]} -eq 0 ] && printf "\n\e[91m You did not correctly specify filtering values for \e[1m$1\e[21m option! Exiting...\e[0m\n\n" && return
                ;;
            --mu)
                DISPLAY="TRUE"
                FILTER_MU="TRUE"
                while [[ $2 =~ ^[^-] ]];do
                    case $2 in
                        0)
                            MU_ARRAY+=( 0 )
                            shift
                            ;;
                        PiT)
                            MU_ARRAY+=( PiT )
                            shift
                            ;;
                        *)
                            printf "\n\e[33m Value \e[1m$2\e[21m for option \e[1m$1\e[21m is invalid! Skipping it!\e[0m\n"
                            shift
                    esac
                done
                [ ${#MU_ARRAY[@]} -eq 0 ] && printf "\n\e[91m You did not correctly specify filtering values for \e[1m$1\e[21m option! Exiting...\e[0m\n\n" && return
                ;;
            --$MASS_PARAMETER)
                DISPLAY="TRUE"
                FILTER_MASS="TRUE"
                while [[ $2 =~ ^[[:digit:]]{4}$ ]]; do
                    MASS_ARRAY+=( $2 )
                    shift
                done
                [ ${#MASS_ARRAY[@]} -eq 0 ] && printf "\n\e[91m You did not correctly specify filtering values for \e[1m$1\e[21m option! Exiting...\e[0m\n\n" && return
                ;;
            --nt)
                DISPLAY="TRUE"
                FILTER_NT="TRUE"
                while [[ $2 =~ ^[[:digit:]]{1,2}$ ]]; do
                    NT_ARRAY+=( $2 )
                    shift
                done
                [ ${#NT_ARRAY[@]} -eq 0 ] && printf "\n\e[91m You did not correctly specify filtering values for \e[1m$1\e[21m option! Exiting...\e[0m\n\n" && return
                ;;
            --ns)
                DISPLAY="TRUE"
                FILTER_NS="TRUE"
                while [[ $2 =~ ^[[:digit:]]{1,2}$ ]]; do
                    NS_ARRAY+=( $2 )
                    shift
                done
                [ ${#NS_ARRAY[@]} -eq 0 ] && printf "\n\e[91m You did not correctly specify filtering values for \e[1m$1\e[21m option! Exiting...\e[0m\n\n" && return
                ;;
            --beta)
                DISPLAY="TRUE"
                FILTER_BETA="TRUE"
                while [[ $2 =~ ^[[:digit:]]\.[[:digit:]]{4}$ ]]; do
                    BETA_ARRAY+=( $2 )
                    shift
                done
                [ ${#BETA_ARRAY[@]} -eq 0 ] && printf "\n\e[91m You did not correctly specify filtering values for \e[1m$1\e[21m option! Exiting...\e[0m\n\n" && return
                ;;
            --type)
                DISPLAY="TRUE"
                FILTER_TYPE="TRUE"
                while [[ $2 =~ ^[^-] ]];do
                    case $2 in
                        fC)
                            TYPE_ARRAY+=( fC )
                            shift
                            ;;
                        fH)
                            TYPE_ARRAY+=( fH )
                            shift
                            ;;
                        NC)
                            TYPE_ARRAY+=( NC )
                            shift
                            ;;
                        *)
                            printf "\n\e[33m Value \e[1m$2\e[21m for option \e[1m$1\e[21m is invalid! Skipping it!\e[0m\n"
                            shift
                    esac
                done
                [ ${#TYPE_ARRAY[@]} -eq 0 ] && printf "\n\e[91m You did not correctly specify filtering values for \e[1m$1\e[21m option! Exiting...\e[0m\n\n" && return
                ;;
            --traj)
                DISPLAY="TRUE"
                FILTER_TRAJNO="TRUE"
                while [[ $2 =~ ^[\>|\<][[:digit:]]+ ]];do
                    [[ $2 =~ ^\>[[:digit:]]+ ]] && TRAJ_LOW_VALUE=${2#\>*}
                    [[ $2 =~ ^\<[[:digit:]]+ ]] && TRAJ_HIGH_VALUE=${2#\<*}
                    shift
                done
                [ "$TRAJ_LOW_VALUE" = "" ] && [ "$TRAJ_HIGH_VALUE" = "" ] && printf "\n\e[91m You did not correctly specify filtering values for \e[1m$1\e[21m option! Exiting...\e[0m\n\n" && return
                ;;
            --acc)
                DISPLAY="TRUE"
                FILTER_ACCRATE="TRUE"
                while [[ $2 =~ ^[\>|\<][[:digit:]]+\.[[:digit:]]+ ]];do
                    [[ $2 =~ ^\>[[:digit:]]+ ]] && ACCRATE_LOW_VALUE=${2#\>*}
                    [[ $2 =~ ^\<[[:digit:]]+ ]] && ACCRATE_HIGH_VALUE=${2#\<*}
                    shift
                done
                [ "$ACCRATE_LOW_VALUE" = "" ] && [ "$ACCRATE_HIGH_VALUE" = "" ] && printf "\n\e[91m You did not correctly specify filtering values for \e[1m$1\e[21m option! Exiting...\e[0m\n\n" && return
                ;;
            --accLast1K)
                DISPLAY="TRUE"
                FILTER_ACCRATE_LAST1K="TRUE"
                while [[ $2 =~ ^[\>|\<][[:digit:]]+\.[[:digit:]]+ ]];do
                    [[ $2 =~ ^\>[[:digit:]]+ ]] && ACCRATE_LAST1K_LOW_VALUE=${2#\>*}
                    [[ $2 =~ ^\<[[:digit:]]+ ]] && ACCRATE_LAST1K_HIGH_VALUE=${2#\<*}
                    shift
                done
                [ "$ACCRATE_LAST1K_LOW_VALUE" = "" ] && [ "$ACCRATE_LAST1K_HIGH_VALUE" = "" ] && printf "\n\e[91m You did not correctly specify filtering values for \e[1m$1\e[21m option! Exiting...\e[0m\n\n" && return
                ;;
            --maxDS)
                DISPLAY="TRUE"
                FILTER_MAX_ACTION="TRUE"
                ;;
            --status)
                DISPLAY="TRUE"
                FILTER_STATUS="TRUE"
                while [[ $2 =~ ^[^-] ]];do
                    case $2 in
                        RUNNING)
                            STATUS_ARRAY+=( RUNNING )
                            shift
                            ;;
                        PENDING)
                            STATUS_ARRAY+=( PENDING )
                            shift
                            ;;
                        notQueued)
                            STATUS_ARRAY+=( notQueued )
                            shift
                            ;;
                        *)
                            printf "\n\e[33m Value \e[1m$2\e[21m for option \e[1m$1\e[21m is invalid! Skipping it!\e[0m\n"
                            shift
                    esac
                done
                [ ${#STATUS_ARRAY[@]} -eq 0 ] && printf "\n\e[91m You did not correctly specify filtering values for \e[1m$1\e[21m option! Exiting...\e[0m\n\n" && return
                ;;
            --lastTraj)
                DISPLAY="TRUE"
                FILTER_LASTTRAJ="TRUE"
                if [[ "$2" =~ ^[[:digit:]]+ ]]; then
                    LAST_TRAJ_TIME=$2
                    shift
                fi
                [ "$LAST_TRAJ_TIME" = "" ] && printf "\n\e[91m You did not correctly specify filtering values for \e[1m$1\e[21m option! Exiting...\e[0m\n\n" && return
                ;;
            -u | --update)
                if [[ $2 =~ ^[[:digit:]]+[s|m|h|d]$ ]]; then
                    SLEEP_TIME=$2
                    shift
                fi
                if [[ $2 =~ ^[[:digit:]]{1,2}(:[[:digit:]]{1,2}(:[[:digit:]]{1,2})?)?$ ]]; then
                    [ "$(awk '{split($0,hms,":"); print hms[1]}' <<< "$2")" -ge 24 ] &&     printf "\n\e[91m For the update at a specific time option only hours < 24, minutes < 60 and seconds < 60 are allowed! Exiting...\e[0m\n\n" && return
                    [ "$(awk '{split($0,hms,":"); print hms[2]}' <<< "$2")" != "" ] && [ "$(awk '{split($0,hms,":"); print hms[2]}' <<< "$2")" -ge 60 ] &&     printf "\n\e[91m For the update at a specific time option only hours < 24, minutes < 60 and seconds < 60 are allowed! Exiting...\e[0m\n\n" && return
                    [ "$(awk '{split($0,hms,":"); print hms[3]}' <<< "$2")" != "" ] && [ "$(awk '{split($0,hms,":"); print hms[3]}' <<< "$2")" -ge 60 ] &&     printf "\n\e[91m For the update at a specific time option only hours < 24, minutes < 60 and seconds < 60 are allowed! Exiting...\e[0m\n\n" && return
                    UPDATE_TIME=$2
                    shift
                fi
                UPDATE="TRUE"
                ;;
            -r | --report)
                REPORT="TRUE"
                ;;
            -s | --show)
                SHOW="TRUE"
                ;;
            -f | --file)
                case $2 in
                    -*)
                        printf "\n\e[91m Filename \e[1m$1\e[21m invalid! Filenames starting with - are not allowed! Exiting...\e[0m\n\n"
                        return
                        ;;
                    *) FILENAME_GIVEN_AS_INPUT=$2 ;;
                esac
                shift
                ;;
            -h | --help)
                printf "\e[38;5;34m\n"
                echo -e "  \e[4m\e[1mDisplaying options\e[24m:\e[21m"
                echo -e "  \e[38;5;69m"
                echo -e "     -c | --columns -->  Specify the columns to be displayed."
                echo -e "                         Possible columns are: mu, $MASS_PARAMETER, nt, ns, beta_chain_type, trajNo, acc, accLast1k, status, lastTraj."
                echo -e "                         Example: -c $MASS_PARAMETER nt ns beta_chain_type trajNo."
                echo -e "                         If no columns are specified, all of the above columns will be printed by default."
                echo -e "     --color        -->  Specifiy this option for displaying coloured output.(NOT YET IMPLEMENTED)"
                echo -e "     --sum          -->  Summing up the trajectory numbers of each parameter set."
                echo -e "  \e[38;5;48m"
                echo -e "    \e[4m\e[1mFiltering\e[24m:\e[21m"
                echo -e "  \e[38;5;69m" #When --nt, --ns, --mu, --kappa will be compatible with update, substitute this line with ---> echo -e "\e[38;5;202m"
                echo -e "     --mu           -->  Specify filtering values for mu."
                printf  "     %-15s%s\n" "--$MASS_PARAMETER" "-->  Specify filtering values for $MASS_PARAMETER."
                echo -e "     --nt           -->  Specify filtering values for nt."
                echo -e "     --ns           -->  Specify filtering values for ns.\e[38;5;69m"
                echo -e "     --beta         -->  Specify filtering values for beta."
                echo -e "     --type         -->  Specify filtering values for the type of the simulation, i.e whether it is NC, fC or fH"
                echo -e "     --traj         -->  Specify either a minimal or a maximal value or both for the trajectory number to be filtered for."
                echo -e "                         E.g. --traj \">10000\" \"<50000\" (DON'T FORGET THE QUOTES.)"
                echo -e "     --acc          -->  Specify either a minimal or a maximal value or both for the acceptance rate to be filtered for."
                echo -e "                         E.g. --acc \">50.23\" \"<80.1\" (The value is in percentage. DON'T FORGET THE QUOTES.)"
                echo -e "     --maxDS        -->  (NOT YET IMPLEMENTED) Specify either a minimal or a maximal value or both for the acceptance rate to be filtered for."
                echo -e "     --status       -->  Specify status value for the corresponding simulation."
                echo -e "                         Possible values are: RUNNING, PENDING, notQueued."
                echo -e "     --lastTraj     -->  Specify a value in seconds. If the specified value exceeds the value of the field, the record is not printed."
                echo -e "                         Use this when you want to scan for crashed simulations."
                echo -e "  \e[38;5;34m"
                echo -e "  \e[4m\e[1mUpdating database\e[24m:\e[21m"
                echo -e "  \e[38;5;198m"
                echo -e "     -u | --update  -->  Specify this option to (re)create the database file."
                echo -e "                         Optionally"
                echo -e "                         1) a sleep time can be specified after which the script repeatedly performs a database update."
                echo -e "                            The sleep time is a number followed by s = seconds, m = minutes, h = hours, d = days, e.g. --update 2h."
                echo -e "                         2) an update time can be specified at which the  script repeatedly performs a database update."
                echo -e "                            The update time is a time in the format hh:mm:ss (24h format for hours). Seconds or minutes and seconds can be omitted."
                echo -e "                            E.g. --update 09:15 will cause the script to perform a database update every day at 09:15:00."
                echo -e "                         In both cases it is best to start the script in a screen session and to let it run in background."
                echo -e "  \e[38;5;202m"
                echo -e "  \e[4m\e[1mGeneral options\e[24m:\e[21m"
                echo -e "     "
                echo -e "     -f | --file    -->  This option can be specified for both the updating of the database and the displaying and filtering of the data."
                echo -e "     "
                echo -e  "               \e[38;5;34m\e[4m\e[1mUpdating\e[24m:\e[21m\e[38;5;202m If you don't wish the script to simply search for all directories containing data, use this option to specify "
                echo -e "                         a file with directories (abosulte paths) in which the script looks for data."
                echo -e "     "
                echo -e "             \e[38;5;34m\e[4m\e[1mDisplaying\e[24m:\e[21m\e[38;5;202m If you don't wish the script to use the latest database file, use this option to specify a file to display and filter."
                echo -e "     "
                echo -e "     -l | --local   -->  To use this option, the script should be called from a position such that mu, $MASS_PARAMETER, nt and ns can be extracted from the path."
                echo -e "                         This option will add to the given option the --mu, --$MASS_PARAMETER, --nt and --ns options with the values extracted from the path."
                echo -e "                         At the moment it is not compatible with any of such an option."
                echo -e "   "
                echo -e "  \e[38;5;34m"
                echo -e "  \e[4m\e[1mReport from database\e[24m:\e[21m"
                echo -e "  \e[38;5;123m"
                echo -e "     -r | --report  -->  Specify this option to get a colorful report of the simulations using the last updated database."
                echo -e "   "
                echo -e "  \e[38;5;34m"
                echo -e "  \e[4m\e[1mShow from database\e[24m:\e[21m"
                echo -e "  \e[38;5;123m"
                echo -e "     -s | --show    -->  Specify this option to show a particular set of simulations using the last updated database."
                echo -e "                         Which set to be displayed will be asked and can be choosen interactively."
                echo -e "   "
                echo -e "   "
                echo -e "    \e[4m\e[1m\e[91mNOTE\e[24m:\e[21m\e[38;5;34m The \e[38;5;69mblue\e[38;5;34m, the \e[38;5;123mcyan\e[38;5;34m and the \e[38;5;198mpink\e[38;5;34m options are not compatible!"
                printf "\e[0m\n"
                return
                ;;
            -*)
                printf "\n\e[91m Option \e[1m$1\e[21m unrecognized! Exiting...\e[0m\n\n"
                return
                ;;
            *)
                printf "\n\e[91m Option \e[1m$1\e[21m invalid! Exiting...\e[0m\n\n"
                return
                ;;
        esac
        shift
    done


    [ $UPDATE = "FALSE" ] && [ $REPORT = "FALSE" ] && [ $SHOW = "FALSE" ] && DISPLAY="TRUE"

    local MUTUALLY_EXCLUSIVE_OPTIONS_PASSED=0
    [ $UPDATE = "TRUE" ] && (( MUTUALLY_EXCLUSIVE_OPTIONS_PASSED++ ))
    [ $DISPLAY = "TRUE" ] && (( MUTUALLY_EXCLUSIVE_OPTIONS_PASSED++ ))
    [ $REPORT = "TRUE" ] || [ $SHOW = "TRUE" ] && (( MUTUALLY_EXCLUSIVE_OPTIONS_PASSED++ ))

    if [ $MUTUALLY_EXCLUSIVE_OPTIONS_PASSED -gt 1 ]; then
        printf "\n\e[91m Option for UPDATE,  DISPLAY/FILTERING and REPORT scenarios cannot be mixed!\e[0m\n\n"
        return
    fi

    cecho ''
    # The PROJECT_DATABASE_FILE variable refers to a file which is an input in the filtering/displaying scenario and which is an output in the update scenario.
    # Then it has to be initialized accordingly!
    if [ "$UPDATE" = "FALSE" ]; then
        if [ "$FILENAME_GIVEN_AS_INPUT" = "" ]; then
            LATEST_DATABASE_FILE=$(ls $PROJECT_DATABASE_DIRECTORY | grep -E [[:digit:]]{2}_[[:digit:]]{2}_[[:digit:]]{2}_$PROJECT_DATABASE_FILENAME | sort -t "_" -k 1,1 -k 2,2 -k 3,3 | tail -n1)
            [ "$LATEST_DATABASE_FILE" = "" ] && printf "\n\e[91m No older database versions found! Exiting...\e[0m\n\n" && return
            local PROJECT_DATABASE_FILE=$PROJECT_DATABASE_DIRECTORY/$LATEST_DATABASE_FILE
        else
            if [ ! f $FILENAME_GIVEN_AS_INPUT ]; then
                printf "\n\e[91m File \"$FILENAME_GIVEN_AS_INPUT\" does not exist! Exiting...\e[0m\n\n"
                return
            fi
            local PROJECT_DATABASE_FILE=$FILENAME_GIVEN_AS_INPUT
        fi
    else
        if [ "$FILENAME_GIVEN_AS_INPUT" != "" ] ; then
            if [ ! -f $FILENAME_GIVEN_AS_INPUT ]; then
                printf "\n\e[91m File \"$FILENAME_GIVEN_AS_INPUT\" does not exist! Exiting...\e[0m\n\n"
                return
            fi
            local FILE_WITH_DIRECTORIES=$FILENAME_GIVEN_AS_INPUT
        fi
        local PROJECT_DATABASE_FILE=$PROJECT_DATABASE_DIRECTORY/$(date +%Y_%m_%d)_$PROJECT_DATABASE_FILENAME
    fi



    if [ $DISPLAY = "TRUE" ]; then

        NF_STRING=$(join "|" "${NF_ARRAY[@]}")
        MU_STRING=$(join "|" "${MU_ARRAY[@]}")
        MASS_STRING=$(join "|" "${MASS_ARRAY[@]}")
        NS_STRING=$(join "|" "${NS_ARRAY[@]}")
        NT_STRING=$(join "|" "${NT_ARRAY[@]}")
        BETA_STRING=$(join "|" "${BETA_ARRAY[@]}")
        TYPE_STRING=$(join "|" "${TYPE_ARRAY[@]}")
        STATUS_STRING=$(join "|" "${STATUS_ARRAY[@]}")

        [ "$FILTER_TRAJNO" = "TRUE" ] && [ "$TRAJ_LOW_VALUE" = "" ]  && TRAJ_LOW_VALUE=0
        [ "$FILTER_TRAJNO" = "TRUE" ] && [ "$TRAJ_HIGH_VALUE" = "" ]  && TRAJ_HIGH_VALUE=9999999

        [ "$FILTER_ACCRATE" = "TRUE" ] && [ "$ACCRATE_LOW_VALUE" = "" ]  && ACCRATE_LOW_VALUE=0.0
        [ "$FILTER_ACCRATE" = "TRUE" ] && [ "$ACCRATE_HIGH_VALUE" = "" ]  && ACCRATE_HIGH_VALUE=100.00

        [ "$FILTER_ACCRATE_LAST1K" = "TRUE" ] && [ "$ACCRATE_LAST1K_LOW_VALUE" = "" ]  && ACCRATE_LAST1K_LOW_VALUE=0.0
        [ "$FILTER_ACCRATE_LAST1K" = "TRUE" ] && [ "$ACCRATE__LAST1KHIGH_VALUE" = "" ]  && ACCRATE_LAST1K_HIGH_VALUE=100.00


        if [ "$CUSTOMIZE_COLUMNS" = "FALSE" ]; then
            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER=( nfC muC kC ntC nsC betaC trajNoC accRateC accRateLast1KC maxDsC statusC lastTrajC )
        fi

        for NAME_OF_COLUMN in ${!COLUMNS[@]}; do
            NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL$NAME_OF_COLUMN-${COLUMNS[$NAME_OF_COLUMN]}"|"
        done

        for NAME_OF_COLUMN in ${NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER[@]}; do
            NAME_OF_COLUMN_NR_OF_COLUMN_STRING=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING$NAME_OF_COLUMN-${COLUMNS[$NAME_OF_COLUMN]}"|"
            NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING=$NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING$NAME_OF_COLUMN--${PRINTF_FORMAT_SPECIFIER_ARRAY[$NAME_OF_COLUMN]}"|"
            NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING=$NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING$NAME_OF_COLUMN-${HEADER_PRINTF_PARAMETER_ARRAY[$NAME_OF_COLUMN]}"|"
            NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING=$NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING$NAME_OF_COLUMN--${HEADER_PRINTF_FORMAT_SPECIFIER_ARRAY[$NAME_OF_COLUMN]}"|"
            LENGTH_OF_HEADER_SEPERATOR=$(($LENGTH_OF_HEADER_SEPERATOR+${FSNA[$NAME_OF_COLUMN]}+1))
        done

        for NAME_OF_COLUMN in ${NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER[@]}; do
            [ "$NAME_OF_COLUMN" = "trajNoC" ] && break
            NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN=$(($NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN+${FSNA[$NAME_OF_COLUMN]}+1))
        done
        NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN=$((NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN+${FSNA[trajNoC]}+1))
        STATISTICS_PRINTF_FORMAT_SPECIFIER_STRING="%${NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN}s\n"
        LENGTH_OF_HEADER_SEPERATOR=$(($LENGTH_OF_HEADER_SEPERATOR+${FSNA[nfC]}+1-${#NFLAVOUR_PREFIX})) #Add dynamicly to symmetrize the line under the header (the +1 is the space that is at the beginning of the line)
        #STRIPPING OF THE LAST | SYMBOL FROM THE STRING
        NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL="${NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL%|}"
        NAME_OF_COLUMN_NR_OF_COLUMN_STRING="${NAME_OF_COLUMN_NR_OF_COLUMN_STRING%|})"
        NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING="${NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING%|}"
        NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING="${NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING%|}"
        NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING="${NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING%|}"

        awk --posix -v filterNf=$FILTER_NF -v filterMu=$FILTER_MU -v filterKappa=$FILTER_MASS -v filterNt=$FILTER_NT -v filterNs=$FILTER_NS \
            -v filterBeta=$FILTER_BETA -v filterType=$FILTER_TYPE \
            -v filterTrajNo=$FILTER_TRAJNO -v filterAccRate=$FILTER_ACCRATE -v filterAccRateLast1K=$FILTER_ACCRATE_LAST1K -v filterMaxDs=$FILTER_MAX_ACTION \
            -v filterStatus=$FILTER_STATUS -v filterLastTrajTime=$FILTER_LASTTRAJ -v statisticsSummary=$STATISTICS_SUMMARY \
            -v nfString="$NF_STRING" -v muString="$MU_STRING" -v kappaString="$MASS_STRING" -v nsString="$NS_STRING" -v ntString="$NT_STRING" -v betaString="$BETA_STRING" \
            -v typeString=$TYPE_STRING -v statusString="$STATUS_STRING" \
            -v trajLowValue=$TRAJ_LOW_VALUE -v trajHighValue=$TRAJ_HIGH_VALUE -v accRateLowValue=$ACCRATE_LOW_VALUE -v accRateHighValue=$ACCRATE_HIGH_VALUE \
            -v accRateLast1KLowValue=$ACCRATE_LAST1K_LOW_VALUE -v accRateLast1KHighValue=$ACCRATE_LAST1K_HIGH_VALUE -v lastTrajTime=$LAST_TRAJ_TIME \
            -v nameOfColumnsAndNumberOfColumnsString=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL \
            -v nameOfDisplayedColumnsAndnrOfDisplayedColumnsString=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING \
            -v nameOfDisplayedColumnsAndSpecOfColumnsString=$NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING \
            -v nameOfColumnsAndHeaderOfColumnsString=$NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING \
            -v nameOfColumnsAndHeaderSpecOfColumnsString=$NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING \
            -v statisticsFormatSpecString=$STATISTICS_PRINTF_FORMAT_SPECIFIER_STRING \
            -v lengthOfHeaderSeperator=$LENGTH_OF_HEADER_SEPERATOR '

                     BEGIN{
                         nrOfTotalColumns=split(nameOfColumnsAndNumberOfColumnsString,columnNamesAndNumbersArray,"|");

                        for(i=1;i<=nrOfTotalColumns;i++){
                            split(columnNamesAndNumbersArray[i],columnNameAndNumber,"-");
                            columnName=columnNameAndNumber[1];
                            columnNumber=columnNameAndNumber[2];
                            columnNameColumnNumber[columnName]=columnNumber;
                        }
                        nrOfDisplayedColumns=split(nameOfDisplayedColumnsAndnrOfDisplayedColumnsString,columnNamesAndNumbersArray,"|");
                        split(nameOfDisplayedColumnsAndSpecOfColumnsString,columnNamesAndSpecsArray,"|");

                        for(i=1;i<=nrOfDisplayedColumns;i++){
                            split(columnNamesAndNumbersArray[i],columnNameAndNumber,"-");
                            columnName=columnNameAndNumber[1];
                            columnNumber=columnNameAndNumber[2];
                            columnNamesInOrder[i]=columnName;
                            split(columnNamesAndSpecsArray[i],columnNameAndSpec,"--");
                            columnSpec=columnNameAndSpec[2];
                            specForColorCode="%-s";
                            columnNameColumnSpec[columnName]=specForColorCode " " columnSpec;
                        }
                        split(nameOfColumnsAndHeaderOfColumnsString,columnNamesAndHeaderArray,"|");
                        split(nameOfColumnsAndHeaderSpecOfColumnsString,columnNamesAndHeaderSpecArray,"|");

                        printf(" \033[38;5;26m");
                        for(i=1;i<=lengthOfHeaderSeperator;i++){
                            printf("=");
                        }
                        printf("\033[0m\n");
                        printf(" "); #THIS PRINTF IS IMPORTANT TO GET THE HEADER IN TO THE RIGHT PLACE
                        for(i=1;i<=nrOfDisplayedColumns;i++){
                            split(columnNamesAndHeaderArray[i],columnAndHeader,"-");
                            split(columnNamesAndHeaderSpecArray[i],columnAndHeaderSpec,"--");
                            specifierString=columnAndHeaderSpec[2];
                            printf(specifierString,columnAndHeader[2]);
                        }
                        printf("  \033[0m\n \033[0;38;5;26m");
                        for(i=1;i<=lengthOfHeaderSeperator;i++){
                            printf("=");
                        }
                        printf("\033[0m\n");
                     }
                     {critFailedCounter=0}

                     ######################################################################## FILTERING PART BEGIN ############################################################################
                     filterNF == "TRUE" {if($(columnNameColumnNumber["nfC"]) !~ nfString) {critFailedCounter--;}}
                     filterMu == "TRUE" {if($(columnNameColumnNumber["muC"]) !~ muString) {critFailedCounter--;}}
                     filterKappa == "TRUE" {if($(columnNameColumnNumber["kC"]) !~ kappaString) {critFailedCounter--;}}
                     filterNs == "TRUE" {if($(columnNameColumnNumber["nsC"]) !~ nsString) {critFailedCounter--;}}
                     filterNt == "TRUE" {if($(columnNameColumnNumber["ntC"]) !~ ntString) {critFailedCounter--;}}
                     filterBeta == "TRUE" {if($(columnNameColumnNumber["betaC"]) !~ betaString) {critFailedCounter--;}}
                     filterType == "TRUE" {if($(columnNameColumnNumber["betaC"]) !~ typeString) {critFailedCounter--;}}
                     filterStatus == "TRUE" {if($(columnNameColumnNumber["statusC"]) !~ statusString) {critFailedCounter--;}}

                     filterTrajNo == "TRUE" {if(length(trajLowValue) == 0 ? "0" : trajLowValue > $(columnNameColumnNumber["trajNoC"])){critFailedCounter--;}}
                     filterTrajNo == "TRUE" {if(length(trajHighValue) == 0 ? "999999" : trajHighValue < $(columnNameColumnNumber["trajNoC"])){critFailedCounter--;}}

                     filterAccRate == "TRUE" {if(length(accRateLowValue) == 0 ? "0" : accRateLowValue > $(columnNameColumnNumber["accRateC"])){critFailedCounter--;}}
                     filterAccRate == "TRUE" {if(length(accRateHighValue) == 0 ? "100.00" : accRateHighValue < $(columnNameColumnNumber["accRateC"])){critFailedCounter--;}}

                     filterAccRateLast1K == "TRUE" {if(length(accRateLast1KLowValue) == 0 ? "0" : accRateLast1KLowValue > $(columnNameColumnNumber["accRateLast1KC"])){critFailedCounter--;}}
                     filterAccRateLast1K == "TRUE" {if(length(accRateLast1KHighValue) == 0 ? "100.00" : accRateLast1KHighValue < $(columnNameColumnNumber["accRateLast1KC"])){critFailedCounter--;}}

                     filterLastTrajTime == "TRUE" {if(lastTrajTime > $(columnNameColumnNumber["lastTrajC"]) || $(columnNameColumnNumber["lastTrajC"]) == "------"){critFailedCounter--;}}

                     statisticsSummary == "FALSE" && critFailedCounter == 0 {
                        printf(" "); #Aesthetics
                        for(i=1;i<=nrOfDisplayedColumns;i++){
                            nameOfColumn=columnNamesInOrder[i];
                            specifierString=columnNameColumnSpec[nameOfColumn];
                            columnOfColorCode=columnNameColumnNumber[nameOfColumn]-1;
                            columnOfColumnName=columnNameColumnNumber[nameOfColumn];
                            printf(specifierString,$(columnOfColorCode),$(columnOfColumnName));
                        }
                        printf("\n");
                     }
                     statisticsSummary == "TRUE" && critFailedCounter == 0 {lineCounter++;dataRow=sprintf("%s",$0);dataRowArray[lineCounter]=dataRow}
                     ######################################################################### FILTERING PART END #############################################################################


                     ######################################################################### SUMMARY OF STATISTICS ##########################################################################
                     statisticsSummary == "TRUE" {
                        split($(columnNameColumnNumber["betaC"]),betaChainType,"_");
                        if(betaChainType[3] == "NC"){
                            statisticsSummaryArray[$(columnNameColumnNumber["nfC"]) "_" $(columnNameColumnNumber["muC"]) "_" $(columnNameColumnNumber["kC"]) "_" $(columnNameColumnNumber["ntC"]) "_" \
                            $(columnNameColumnNumber["nsC"]) "_" betaChainType[1] "_" betaChainType[3]]+=$(columnNameColumnNumber["trajNoC"]);
                        }
                    }

                    END{
                        if(statisticsSummary == "TRUE"){
                            split(dataRowArray[1],fieldsArray," ");
                            split(fieldsArray[columnNameColumnNumber["betaC"]],betaChainType,"_");

                            if(betaChainType[3] == "NC"){
                                oldKey = fieldsArray[columnNameColumnNumber["nfC"]] "_" fieldsArray[columnNameColumnNumber["muC"]] "_" fieldsArray[columnNameColumnNumber["kC"]] "_" fieldsArray[columnNameColumnNumber["ntC"]] "_" \
                                fieldsArray[columnNameColumnNumber["nsC"]] "_" betaChainType[1] "_" betaChainType[3];
                            }

                            for(i=1;i<=lineCounter;i++){
                                split(dataRowArray[i],fieldsArray," ");
                                split(fieldsArray[columnNameColumnNumber["betaC"]],betaChainType,"_");
                                if(betaChainType[3] == "NC"){
                                    newKey = fieldsArray[columnNameColumnNumber["nfC"]] "_" fieldsArray[columnNameColumnNumber["muC"]] "_" fieldsArray[columnNameColumnNumber["kC"]] "_" \
                                    fieldsArray[columnNameColumnNumber["ntC"]] "_" fieldsArray[columnNameColumnNumber["nsC"]] "_" betaChainType[1] "_" betaChainType[3]
                                }

                                if(betaChainType[3] == "NC"){
                                    if(newKey != oldKey){
                                        printf(" "); #Aesthetics
                                        printf(statisticsFormatSpecString,statisticsSummaryArray[oldKey]);
                                        oldKey=newKey;
                                    }
                                }

                                split(dataRowArray[i],columnsArray," ")
                                printf(" "); #Aesthetics
                                for(columnEntry=1;columnEntry<=nrOfDisplayedColumns;columnEntry++){
                                    nameOfColumn=columnNamesInOrder[columnEntry];
                                    specifierString=columnNameColumnSpec[nameOfColumn];
                                    columnOfColorCode=columnNameColumnNumber[nameOfColumn]-1;
                                    columnOfColumnName=columnNameColumnNumber[nameOfColumn];
                                    printf(specifierString,columnsArray[columnOfColorCode],columnsArray[columnOfColumnName]);
                                }
                                printf(" \033[0;m")
                                printf("\n");
                            }
                            printf(" "); #Aesthetics
                            printf(statisticsFormatSpecString,statisticsSummaryArray[newKey]);
                        }
                        printf(" \033[0m\033[0;38;5;26m");
                        for(i=1;i<=lengthOfHeaderSeperator;i++){
                            printf("=");
                        }
                        printf("\033[0m\n");
                    }
        ' $PROJECT_DATABASE_FILE

        printf "\n Last update ended on \e[1m$(date -r $PROJECT_DATABASE_FILE +"%d.%m.%Y\e[21m at \e[1m%H:%M")\e[21m  \e[38;5;202m--->\e[38;5;207m  $PROJECT_DATABASE_FILE\n\n\e[0m"
    fi

    #==========================================================================================================================================================================================#

    if [ $UPDATE = "TRUE" ]; then

        if [ "$SLEEP_TIME" != "" ] && [ "$UPDATE_TIME" != "" ]; then
            printf "\n\e[91m  Values for both, sleep time and update time are specified but are mutually exclusive. Please investigate! Exiting...\e[0m\n\n" && return
        fi

        local TEMPORARY_FILE_WITH_DIRECTORIES="${PROJECT_DATABASE_DIRECTORY}/temporaryFileWithDirectoriesForDatabaseUpdate.dat"
        rm -f $TEMPORARY_FILE_WITH_DIRECTORIES
        local TEMPORARY_DATABASE_FILE="${PROJECT_DATABASE_DIRECTORY}/temporaryDatabaseForUpdate.dat"
        rm -f $TEMPORARY_DATABASE_FILE

        REGEX_STRING=".*/"
        for i in ${!PARAMETER_PREFIXES[@]}; do
            REGEX_STRING=$REGEX_STRING${PARAMETER_PREFIXES[$i]}${PARAMETER_REGEXES[$i]}/
        done
        REGEX_STRING=${REGEX_STRING%/}

        while :
        do
            if [ "$UPDATE_TIME" != "" ]; then
                CURRENT_EPOCH=$(date +%s)
                if [ $CURRENT_EPOCH -gt $(date -d "$UPDATE_TIME" +%s) ]; then
                    TARGET_EPOCH=$(date -d "$UPDATE_TIME tomorrow" +%s)
                    printf "\n\t\e[1m\e[38;5;147mEntering sleeping mode. Performing next update on \e[38;5;86m$(date -d "$UPDATE_TIME tomorrow" +"%d.%m.%Y \e[38;5;147mat\e[38;5;86m %H:%M")\e[0m\n\n"
                else
                    TARGET_EPOCH=$(date -d "$UPDATE_TIME" +%s)
                    printf "\n\t\e[1m\e[38;5;147mEntering sleeping mode. Performing next update today at \e[38;5;86m$(date -d "$UPDATE_TIME" +"%H:%M")\e[0m\n\n"
                fi
                SLEEP_SECONDS=$(( $TARGET_EPOCH - $CURRENT_EPOCH ))
                sleep $SLEEP_SECONDS
            fi

            [ "$FILE_WITH_DIRECTORIES" = "" ] && find $HOME_DIR/$SIMULATION_PATH -regextype grep -regex "$REGEX_STRING" -type d > $TEMPORARY_FILE_WITH_DIRECTORIES
            [ "$FILE_WITH_DIRECTORIES" != "" ] && cat $FILE_WITH_DIRECTORIES > $TEMPORARY_FILE_WITH_DIRECTORIES

            while read line
            do
                #printf "%+15s: %s\n" "line" "$line"
                if [[ "$line" =~ ^[^#] ]]; then
                    PARAMS=( $(awk 'BEGIN{FS="/"}{print $(NF-4) " " $(NF-3) " " $(NF-2) " " $(NF-1) " " $(NF)}' <<< "$line") )
                else
                    continue
                fi

                if [ -d $line ]; then
                    printf "\t\e[38;5;208m\e[48;5;16mUpdating:\e[38;5;49m $line "
                    cd $line
                else
                    printf "\n\e[91m Directory \"$line\" skipped!\n\e[0m"
                    continue
                fi

                PARAMETER_DIRECTORY_STRUCTURE=${line##*$SIMULATION_PATH}

                ListJobStatus_SLURM $PARAMETER_DIRECTORY_STRUCTURE | \
                    sed -r 's/[^(\x1b)]\[|\]|\(|\)|%//g' | \
                    sed -r 's/(\x1B\[[[:digit:]]{1,2};[[:digit:]]{0,2};[[:digit:]]{0,3}m)(.)/\1 \2/g' | \
                    sed -r 's/(.)(\x1B\[.{1,2};.{1,2}m)/\1 \2/g' | \
                    sed -r 's/(\x1B\[.{1,2};.{1,2}m)(.)/\1 \2/g' |
                    awk --posix -v nf=${PARAMS[0]#$NFLAVOUR_PREFIX*} -v mu=${PARAMS[1]#$CHEMPOT_PREFIX*} -v k=${PARAMS[2]#$MASS_PREFIX*} -v nt=${PARAMS[3]#$NTIME_PREFIX*} -v ns=${PARAMS[4]#*$NSPACE_PREFIX} '
                            $3 ~ /^[[:digit:]]\.[[:digit:]]{4}/{
                            print "\033[36m " nf " \033[36m " mu " \033[36m " k " \033[36m " nt " \033[36m " ns " " $(3-1) " " $3 " " $(5-1) " " $5 " " $(8-1) " " $8 " " $(11-1) " " $(11) " " $(18-1) " " $(18) " " $(15-1) " " $15 " " $(21-1) " " $21 " " "\033[0m"
                            }
                        ' >> $TEMPORARY_DATABASE_FILE

                cd $CURRENT_DIRECTORY
                printf "\e[38;5;10m...done!\e[0m\n"
            done < <(cat $TEMPORARY_FILE_WITH_DIRECTORIES)

            if [ ! -f $TEMPORARY_DATABASE_FILE ] || [ "$(wc -l < $TEMPORARY_DATABASE_FILE)" -eq 0 ]; then
                printf "\n\e[91m After the database procedure, the database seems to be empty! Temporary files\n"
                printf "   $TEMPORARY_DATABASE_FILE\n   $TEMPORARY_FILE_WITH_DIRECTORIES\n"
                printf " have been left for further investigation! Aborting...\e[0m\n\n"
                return
            fi

            #Updating the content of PROJECT_DATABASE_FILE
            local PROJECT_DATABASE_FILE=$PROJECT_DATABASE_DIRECTORY/$(date +%Y_%m_%d)_$PROJECT_DATABASE_FILENAME
            cp $TEMPORARY_DATABASE_FILE $PROJECT_DATABASE_FILE

            #Clean up
            rm $TEMPORARY_DATABASE_FILE
            rm $TEMPORARY_FILE_WITH_DIRECTORIES

            if [ "$SLEEP_TIME" != "" ]; then
                printf "\n\t\e[1m\e[38;5;147mSleeping \e[38;5;86m$SLEEP_TIME\e[38;5;147m starting on $(date +"%d.%m.%Y at %H:%M:%S")\e[0m\n\n"
                sleep $SLEEP_TIME
            fi

            if [ "$SLEEP_TIME" = "" ] && [ "$UPDATE_TIME" = "" ]; then
                break
            fi
        done
        cecho ''
    fi

    #==========================================================================================================================================================================================#

    if [ $REPORT = "TRUE" ]; then

        printf "\t\t\t  \e[95m\e[4mAUTOMATIC REPORT FROM DATABASE (status on \e[1m$(date -r $PROJECT_DATABASE_FILE +"%d.%m.%Y\e[21m at \e[1m%H:%M")\e[21m)\n\n\e[0m"

        awk --posix -v betaColorColumn="$((${COLUMNS[betaC]} -1 ))" \
            -v trajNoColorColumn="$((${COLUMNS[trajNoC]} -1 ))" \
            -v accRateColorColumn="$((${COLUMNS[accRateC]} -1 ))" \
            -v accRateLast1KColorColumn="$((${COLUMNS[accRateLast1KC]} -1 ))" \
            -v maxDsColorColumn="$((${COLUMNS[maxDsC]} -1 ))" \
            -v statusColorColumn="$((${COLUMNS[statusC]} -1 ))" \
            -v lastTrajColorColumn="$((${COLUMNS[lastTrajC]} -1 ))" \
            -v defaultColor="${DEFAULT_LISTSTATUS_COLOR/e/033}" \
            -v suspiciousBetaColor="${SUSPICIOUS_BETA_LISTSTATUS_COLOR/e/033}" \
            -v wrongBetaColor="${WRONG_BETA_LISTSTATUS_COLOR/e/033}" \
            -v tooLowAccColor="${TOO_LOW_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" \
            -v lowAccColor="${LOW_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" \
            -v optimalAccColor="${OPTIMAL_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" \
            -v highAccColor="${HIGH_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" \
            -v tooHighAccColor="${TOO_HIGH_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" \
            -v tooHighMaxDsColor="${TOO_HIGH_DELTA_S_LISTSTATUS_COLOR/e/033}" \
            -v runningColor="${RUNNING_LISTSTATUS_COLOR/e/033}" \
            -v pendingColor="${PENDING_LISTSTATUS_COLOR/e/033}" \
            -v toBeCleanedColor="${CLEANING_LISTSTATUS_COLOR/e/033}" \
            -v stuckColor="${STUCK_SIMULATION_LISTSTATUS_COLOR/e/033}" \
            -v fineColor="${FINE_SIMULATION_LISTSTATUS_COLOR/e/033}" \
            -v tooLowAccThreshold="${TOO_LOW_ACCEPTANCE_THRESHOLD}" \
            -v lowAccThreshold="${LOW_ACCEPTANCE_THRESHOLD}" \
            -v highAccThreshold="${HIGH_ACCEPTANCE_THRESHOLD}" \
            -v tooHighAccThreshold="${TOO_HIGH_ACCEPTANCE_THRESHOLD}" \
            -v tooHighMaxDsThreshold="${DELTA_S_THRESHOLD}" '
BEGIN{
filesToBeCleaned = 0
simTooLowAcc = 0
simLowAcc = 0
simOptimalAcc = 0
simHighAcc = 0
simTooHighAcc = 0
simTooLowAcc1K = 0
simLowAcc1K = 0
simOptimalAcc1K = 0
simHighAcc1K = 0
simTooHighAcc1K = 0
simRunning = 0
simPending = 0
simStuck = 0
simFine = 0
simOnBrokenGPU = 0
criticalSituation = 0
}
{
if($betaColorColumn == wrongBetaColor || $maxDsColorColumn == tooHighMaxDsColor){simOnBrokenGPU+=1; criticalSituation=1}
if($trajNoColorColumn == toBeCleanedColor){filesToBeCleaned+=1}
if($accRateColorColumn == tooLowAccColor){simTooLowAcc+=1; criticalSituation=1}
if($accRateColorColumn == lowAccColor){simLowAcc+=1}
if($accRateColorColumn == optimalAccColor){simOptimalAcc+=1}
if($accRateColorColumn == highAccColor){simHighAcc+=1}
if($accRateColorColumn == tooHighAccColor){simTooHighAcc+=1}
if($accRateLast1KColorColumn == tooLowAccColor){simTooLowAcc1K+=1; criticalSituation=1}
if($accRateLast1KColorColumn == lowAccColor){simLowAcc1K+=1}
if($accRateLast1KColorColumn == optimalAccColor){simOptimalAcc1K+=1}
if($accRateLast1KColorColumn == highAccColor){simHighAcc1K+=1}
if($accRateLast1KColorColumn == tooHighAccColor){simTooHighAcc1K+=1}
if($statusColorColumn == runningColor){simRunning+=1}
if($statusColorColumn == pendingColor){simPending+=1}
if($lastTrajColorColumn == stuckColor){simStuck+=1; criticalSituation=1}
if($lastTrajColorColumn == fineColor){simFine+=1}
}
END{
def="\033[0m"
red="\033[91m"
darkOrange="\033[38;5;202m"
lightOrange="\033[38;5;208m"
yellow="\033[93m"
green="\033[32m"
blue="\033[38;5;45m"
pink="\033[38;5;171m"
bold="\033[1m"

string[0]= "\t\t" pink "                     Simulations on " bold " broken GPU"def pink": %s%s%4d " def "\n"
string[1]= "\t\t" blue "  Simulations with" bold " too low acceptance" def blue " - " bold "last 1k" def blue ": %s%s%4d" def blue "  - %s%s%4d" def blue "  [  0%%,  %2d%% )  " def "\n"
string[2]= "\t\t" blue "      Simulations with" bold " low acceptance" def blue " - " bold "last 1k" def blue ": %s%s%4d" def blue "  - %s%s%4d" def blue "  [ %2d%%,  %2d%% ) " def "\n"
string[3]= "\t\t" blue "  Simulations with" bold " optimal acceptance" def blue " - " bold "last 1k" def blue ": %s%s%4d" def blue "  - %s%s%4d" def blue "  [ %2d%%,  %2d%% ] " def "\n"
string[4]= "\t\t" blue "     Simulations with" bold " high acceptance" def blue " - " bold "last 1k" def blue ": %s%s%4d" def blue "  - %s%s%4d" def blue "  ( %2d%%,  %2d%% ] " def "\n"
string[5]= "\t\t" blue " Simulations with" bold " too high acceptance" def blue " - " bold "last 1k" def blue ": %s%s%4d" def blue "  - %s%s%4d" def blue "  ( %2d%%, 100%% ]  " def "\n"
string[6]= "\t\t" pink "                           Simulations " bold " running" def pink ": %s%s%4d " def "\n"
string[7]= "\t\t" pink "                           Simulations " bold " pending" def pink ": %s%s%4d " def "\n"
string[8]= "\t\t" blue "               Simulations " bold " stuck" def blue " (or finished): %s%s%4d " def "\n"
string[9]= "\t\t" blue "                      Simulations " bold " running fine" def blue ": %s%s%4d " def "\n"
string[10]="\t\t" pink "                    Output files " bold " to be cleaned" def pink ": %s%s%4d " def "\n"

printf string[0] , (simOnBrokenGPU>0 ? red : green)          , bold, simOnBrokenGPU
printf string[1] , (simTooLowAcc>0   ? red : green)          , bold, simTooLowAcc    , (simTooLowAcc1K>0   ? red : green)        , bold, simTooLowAcc1K,  tooLowAccThreshold
printf string[2] , (simLowAcc>0      ? darkOrange : green)   , bold, simLowAcc       , (simLowAcc1K>0      ? darkOrange : green) , bold, simLowAcc1K,     tooLowAccThreshold, lowAccThreshold
printf string[3] , (simOptimalAcc==0  ? green : green)       , bold, simOptimalAcc   , (simOptimalAcc1K==0  ? green : green)     , bold, simOptimalAcc1K, lowAccThreshold, highAccThreshold
printf string[4] , (simHighAcc>0     ? yellow : green)       , bold, simHighAcc      , (simHighAcc1K>0     ? yellow : green)     , bold, simHighAcc1K,    highAccThreshold, tooHighAccThreshold
printf string[5] , (simTooHighAcc>0  ? lightOrange : green)  , bold, simTooHighAcc   , (simTooHighAcc1K>0  ? lightOrange : green), bold, simTooHighAcc1K, tooHighAccThreshold
printf string[6] , green                                     , bold, simRunning
printf string[7] , (simPending>0     ? yellow : green)       , bold, simPending
printf string[8] , (simStuck>0     ? red : green)            , bold, simStuck
printf string[9] , green                                     , bold, simFine
printf string[10], (filesToBeCleaned>0 ? lightOrange : green), bold, filesToBeCleaned

if(criticalSituation ==1){exit 1}else{exit 0}
        }' $PROJECT_DATABASE_FILE

        if [ $? -ne 0 ]; then
            printf "\n\t\t\t\e[38;5;9m"
        else
            printf "\n\t\t\t\e[38;5;83m"
        fi
        printf "Use \e[1m-\e[4mds\e[24m\e[21m | \e[1m--\e[4mdataBase\e[24m\e[21m \e[1m--\e[4mshow\e[24m\e[21m option to display set of simulations.\n\n"
    fi

    #==========================================================================================================================================================================================#

    if [ $SHOW = "TRUE" ]; then

        local TEMPORARY_DATABASE_FILE="tmpDatabaseForShowing.dat"
        rm -f $PROJECT_DATABASE_DIRECTORY/$TEMPORARY_DATABASE_FILE

        local POSSIBLE_SIMULATIONS_TO_SHOW=( "Simulations on broken GPU"
                                             "Simulations stuck (or finished)"
                                             "Simulations with output file to be cleaned"
                                             "Simulations with too low acceptance rate"
                                             "Simulations with low acceptance rate"
                                             "Simulations with optimal acceptance rate"
                                             "Simulations with high acceptance rate"
                                             "Simulations with too high acceptance rate"
                                             "Simulations with too low acceptance rate in last 1k trajectories"
                                             "Simulations with low acceptance rate in last 1k trajectories"
                                             "Simulations with optimal acceptance rate in last 1k trajectories"
                                             "Simulations with high acceptance rate in last 1k trajectories"
                                             "Simulations with too high acceptance rate in last 1k trajectories"
                                             "Running simulations"
                                             "Pending simulations" )

        printf "\e[38;5;118mWhich simulations would you like to show?\n\e[38;5;135m"
        PS3=$'\n\e[38;5;118mEnter the number corresponding to the desired set: \e[38;5;135m'
        select SIMULATION in "${POSSIBLE_SIMULATIONS_TO_SHOW[@]}"; do
            if ! ElementInArray "$SIMULATION" "${POSSIBLE_SIMULATIONS_TO_SHOW[@]}"; then
                continue
            else
                case $SIMULATION in
                    "Simulations on broken GPU")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[betaC]} -1 ))" )
                        COLUMNS_TO_FILTER+=( "$((${COLUMNS[maxDsC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${WRONG_BETA_LISTSTATUS_COLOR/e/033}" )
                        VALUES_TO_MATCH+=( "${TOO_HIGH_DELTA_S_LISTSTATUS_COLOR/e/033}" )
                        ;;
                    "Simulations stuck (or finished)")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[lastTrajC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${STUCK_SIMULATION_LISTSTATUS_COLOR/e/033}" )
                        ;;
                    "Simulations with output file to be cleaned")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[trajNoC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${CLEANING_LISTSTATUS_COLOR/e/033}" )
                        ;;
                    "Simulations with too low acceptance rate")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${TOO_LOW_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" )
                        ;;
                    "Simulations with low acceptance rate")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${LOW_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" )
                        ;;
                    "Simulations with optimal acceptance rate")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${OPTIMAL_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" )
                        ;;
                    "Simulations with high acceptance rate")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${HIGH_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" )
                        ;;
                    "Simulations with too high acceptance rate")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${TOO_HIGH_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" )
                        ;;
                    "Simulations with too low acceptance rate in last 1k trajectories")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateLast1KC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${TOO_LOW_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" )
                        ;;
                    "Simulations with low acceptance rate in last 1k trajectories")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateLast1KC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${LOW_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" )
                        ;;
                    "Simulations with optimal acceptance rate in last 1k trajectories")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateLast1KC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${OPTIMAL_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" )
                        ;;
                    "Simulations with high acceptance rate in last 1k trajectories")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateLast1KC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${HIGH_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" )
                        ;;
                    "Simulations with too high acceptance rate in last 1k trajectories")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateLast1KC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${TOO_HIGH_ACCEPTANCE_LISTSTATUS_COLOR/e/033}" )
                        ;;
                    "Running simulations")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[statusC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${RUNNING_LISTSTATUS_COLOR/e/033}" )
                        ;;
                    "Pending simulations")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[statusC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${PENDING_LISTSTATUS_COLOR/e/033}" )
                        ;;
                esac
                break
            fi
        done
        printf "\n\e[0m"

        for i in ${!COLUMNS_TO_FILTER[@]}
        do
            awk --posix -v columnToFilter="${COLUMNS_TO_FILTER[$i]}" -v valueToMatch="${VALUES_TO_MATCH[$i]}" '$columnToFilter == valueToMatch{print $0}' $PROJECT_DATABASE_FILE >> $PROJECT_DATABASE_DIRECTORY/$TEMPORARY_DATABASE_FILE
        done

        if [ $(wc -l < $PROJECT_DATABASE_DIRECTORY/$TEMPORARY_DATABASE_FILE) -eq 0 ]; then
            printf " \e[38;5;202m $SIMULATION not found in database (last update ended on \e[1m$(date -r $PROJECT_DATABASE_FILE +"%d.%m.%Y\e[21m at \e[1m%H:%M")\e[21m).\n\n\e[0m"
        else
            __static__DisplayDatabaseFile <(sort $PROJECT_DATABASE_DIRECTORY/$TEMPORARY_DATABASE_FILE | uniq)
            printf "\n Last update ended on \e[1m$(date -r $PROJECT_DATABASE_FILE +"%d.%m.%Y\e[21m at \e[1m%H:%M")\e[21m  \e[38;5;202m--->\e[38;5;207m  $PROJECT_DATABASE_FILE\n\n\e[0m"
        fi

        rm $PROJECT_DATABASE_DIRECTORY/$TEMPORARY_DATABASE_FILE

    fi

}



function __static__DisplayDatabaseFile() {

    if [ "$CUSTOMIZE_COLUMNS" = "FALSE" ]; then
        NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER=( nfC muC kC ntC nsC betaC trajNoC accRateC accRateLast1KC maxDsC statusC lastTrajC )
    fi

    for NAME_OF_COLUMN in ${!COLUMNS[@]}; do
        NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL$NAME_OF_COLUMN-${COLUMNS[$NAME_OF_COLUMN]}"|"
    done

    for NAME_OF_COLUMN in ${NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER[@]}; do
        NAME_OF_COLUMN_NR_OF_COLUMN_STRING=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING$NAME_OF_COLUMN-${COLUMNS[$NAME_OF_COLUMN]}"|"
        NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING=$NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING$NAME_OF_COLUMN--${PRINTF_FORMAT_SPECIFIER_ARRAY[$NAME_OF_COLUMN]}"|"
        NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING=$NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING$NAME_OF_COLUMN-${HEADER_PRINTF_PARAMETER_ARRAY[$NAME_OF_COLUMN]}"|"
        NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING=$NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING$NAME_OF_COLUMN--${HEADER_PRINTF_FORMAT_SPECIFIER_ARRAY[$NAME_OF_COLUMN]}"|"
        LENGTH_OF_HEADER_SEPERATOR=$(($LENGTH_OF_HEADER_SEPERATOR+${FSNA[$NAME_OF_COLUMN]}+1))
    done

    LENGTH_OF_HEADER_SEPERATOR=$(($LENGTH_OF_HEADER_SEPERATOR+${FSNA[muC]}+1-${#CHEMPOT_PREFIX})) #Add dynamicly to simmetrize the line under the header (the +1 is the space that is at the beginning of the line)
    #STRIPPING OF THE LAST | SYMBOL FROM THE STRING
    NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL="${NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL%|}"
    NAME_OF_COLUMN_NR_OF_COLUMN_STRING="${NAME_OF_COLUMN_NR_OF_COLUMN_STRING%|}"
    NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING="${NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING%|})"
    NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING="${NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING%|}"
    NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING="${NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING%|}"

    awk --posix -v nameOfColumnsAndNumberOfColumnsString=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL \
        -v nameOfDisplayedColumnsAndnrOfDisplayedColumnsString=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING \
        -v nameOfDisplayedColumnsAndSpecOfColumnsString=$NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING \
        -v nameOfColumnsAndHeaderOfColumnsString=$NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING \
        -v nameOfColumnsAndHeaderSpecOfColumnsString=$NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING \
        -v lengthOfHeaderSeperator=$LENGTH_OF_HEADER_SEPERATOR '
                     BEGIN{
                         nrOfTotalColumns=split(nameOfColumnsAndNumberOfColumnsString,columnNamesAndNumbersArray,"|");

                        for(i=1;i<=nrOfTotalColumns;i++){
                            split(columnNamesAndNumbersArray[i],columnNameAndNumber,"-");
                            columnName=columnNameAndNumber[1];
                            columnNumber=columnNameAndNumber[2];
                            columnNameColumnNumber[columnName]=columnNumber;
                        }
                        nrOfDisplayedColumns=split(nameOfDisplayedColumnsAndnrOfDisplayedColumnsString,columnNamesAndNumbersArray,"|");
                        split(nameOfDisplayedColumnsAndSpecOfColumnsString,columnNamesAndSpecsArray,"|");

                        for(i=1;i<=nrOfDisplayedColumns;i++){
                            split(columnNamesAndNumbersArray[i],columnNameAndNumber,"-");
                            columnName=columnNameAndNumber[1];
                            columnNumber=columnNameAndNumber[2];
                            columnNamesInOrder[i]=columnName;
                            split(columnNamesAndSpecsArray[i],columnNameAndSpec,"--");
                            columnSpec=columnNameAndSpec[2];
                            specForColorCode="%-s";
                            columnNameColumnSpec[columnName]=specForColorCode " " columnSpec;
                        }
                        split(nameOfColumnsAndHeaderOfColumnsString,columnNamesAndHeaderArray,"|");
                        split(nameOfColumnsAndHeaderSpecOfColumnsString,columnNamesAndHeaderSpecArray,"|");

                        printf(" \033[38;5;26m");
                        for(i=1;i<=lengthOfHeaderSeperator;i++){
                            printf("=");
                        }
                        printf("\033[0m\n");
                        printf(" "); #THIS PRINTF IS IMPORTANT TO GET THE HEADER IN TO THE RIGHT PLACE
                        for(i=1;i<=nrOfDisplayedColumns;i++){
                            split(columnNamesAndHeaderArray[i],columnAndHeader,"-");
                            split(columnNamesAndHeaderSpecArray[i],columnAndHeaderSpec,"--");
                            specifierString=columnAndHeaderSpec[2];
                            printf(specifierString,columnAndHeader[2]);
                        }
                        printf("  \033[0m\n \033[0;38;5;26m");
                        for(i=1;i<=lengthOfHeaderSeperator;i++){
                            printf("=");
                        }
                        printf("\033[0m\n");
                     }
{
                        printf(" "); #Aesthetics
                        for(i=1;i<=nrOfDisplayedColumns;i++){
                            nameOfColumn=columnNamesInOrder[i];
                            specifierString=columnNameColumnSpec[nameOfColumn];
                            columnOfColorCode=columnNameColumnNumber[nameOfColumn]-1;
                            columnOfColumnName=columnNameColumnNumber[nameOfColumn];
                            printf(specifierString,$(columnOfColorCode),$(columnOfColumnName));
                        }
                        printf("\n");
}
                    END{
                        printf(" \033[0m\033[0;38;5;26m");
                        for(i=1;i<=lengthOfHeaderSeperator;i++){
                            printf("=");
                        }
                        printf("\033[0m\n");
                    }'     $1

}
