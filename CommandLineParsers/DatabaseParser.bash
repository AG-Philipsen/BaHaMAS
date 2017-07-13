#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

source ${BaHaMAS_repositoryTopLevelPath}/CommandLineParsers/DatabaseHelper.bash || exit $BHMAS_fatalBuiltin

function __static__CheckMutuallyExclusiveOptions()
{
    local reportShow
    if [ $REPORT = 'TRUE' ] || [ $SHOW = 'TRUE' ]; then
        reportShow='TRUE'
    else
        reportShow='FALSE'
    fi
    if [ $(grep -o 'TRUE' <<< "$DISPLAY $UPDATE $reportShow" | wc -l) -eq 0 ]; then
        DISPLAY='TRUE'
    elif [ $(grep -o 'TRUE' <<< "$DISPLAY $UPDATE $reportShow" | wc -l) -gt 1 ]; then
        Fatal $BHMAS_fatalCommandLine "Options for " emph "UPDATE" ", " emph "DISPLAY/FILTERING" " and " emph "REPORT" " scenarios cannot be mixed!"
    fi
}

function ParseDatabaseCommandLineOption()
{
    #If the option -l | --local is given, then the option -l is replaced by mu,mass,nt,ns options with local values
    if ElementInArray "-l" $@ || ElementInArray "--local" $@;  then
        if ElementInArray "--$MASS_PARAMETER" $@ || ElementInArray "--mu" $@ || ElementInArray "--nt" $@ || ElementInArray "--ns" $@; then
            Fatal $BHMAS_fatalCommandLine "Option " emph "-l | --local" " not compatible with any of " emph "--mu" ", " emph "--$MASS_PARAMETER" ", " emph "--nt" ", " emph "--ns" "!"
        fi
        local option newOptions
        newOptions=()
        for option in "$@"; do
            [[ $option != "-l" ]] && [[ $option != "--local" ]] && newOptions+=($option)
        done && unset -v 'option'
        ReadParametersFromPathAndSetRelatedVariables $(pwd)
        set -- ${newOptions[@]:-} "--mu" "$BHMAS_chempot" "--$MASS_PARAMETER" "$BHMAS_mass" "--nt" "$BHMAS_ntime" "--ns" "$BHMAS_nspace"
    fi
    #Here it is fine to assume that option names and values are separated by spaces
    while [ $# -gt 0 ]; do
        case $1 in

            -c | --columns)
                DISPLAY="TRUE"
                CUSTOMIZE_COLUMNS="TRUE"
                while [[ ! ${2:-} =~ ^- ]]; do
                    case $2 in
                        nf)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( nfC ); shift ;;
                        mu)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( muC ); shift ;;
                        $MASS_PARAMETER)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( kC ); shift ;;
                        nt)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( ntC ); shift ;;
                        ns)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( nsC ); shift ;;
                        beta_chain_type)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( betaC ); shift ;;
                        trajNo)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( trajNoC ); shift ;;
                        acc)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( accRateC ); shift ;;
                        accLast1k)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( accRateLast1KC ); shift ;;
                        maxDS)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( maxDsC ); shift ;;
                        status)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( statusC ); shift ;;
                        lastTraj)
                            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( lastTrajC ); shift ;;
                        *)
                            PrintInvalidOptionErrorAndExit "$1"
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
                while [[ ${2:-} =~ ^[0-9](\.[0-9]+)?$ ]]; do
                    NF_ARRAY+=( $2 )
                    shift
                done
                [ ${#NF_ARRAY[@]} -eq 0 ] && PrintOptionSpecificationErrorAndExit "$1"
                ;;

            --mu)
                DISPLAY="TRUE"
                FILTER_MU="TRUE"
                while [[ ! ${2:-} =~ ^(-|$) ]];do
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
                            cecho ly "\n Value " emph "$2" " for option " emph "$1" " is invalid! Skipping it!"
                            shift
                    esac
                done
                [ ${#MU_ARRAY[@]} -eq 0 ] && PrintOptionSpecificationErrorAndExit "$1"
                ;;

            --$MASS_PARAMETER)
                DISPLAY="TRUE"
                FILTER_MASS="TRUE"
                while [[ ${2:-} =~ ^[0-9]{4}$ ]]; do
                    MASS_ARRAY+=( $2 )
                    shift
                done
                [ ${#MASS_ARRAY[@]} -eq 0 ] && PrintOptionSpecificationErrorAndExit "$1"
                ;;

            --nt)
                DISPLAY="TRUE"
                FILTER_NT="TRUE"
                while [[ ${2:-} =~ ^[0-9]{1,2}$ ]]; do
                    NT_ARRAY+=( $2 )
                    shift
                done
                [ ${#NT_ARRAY[@]} -eq 0 ] && PrintOptionSpecificationErrorAndExit "$1"
                ;;

            --ns)
                DISPLAY="TRUE"
                FILTER_NS="TRUE"
                while [[ ${2:-} =~ ^[0-9]{1,2}$ ]]; do
                    NS_ARRAY+=( $2 )
                    shift
                done
                [ ${#NS_ARRAY[@]} -eq 0 ] && PrintOptionSpecificationErrorAndExit "$1"
                ;;

            --beta)
                DISPLAY="TRUE"
                FILTER_BETA="TRUE"
                while [[ ${2:-} =~ ^[0-9]\.[0-9]{4}$ ]]; do
                    BETA_ARRAY+=( $2 )
                    shift
                done
                [ ${#BETA_ARRAY[@]} -eq 0 ] && PrintOptionSpecificationErrorAndExit "$1"
                ;;

            --type)
                DISPLAY="TRUE"
                FILTER_TYPE="TRUE"
                while [[ ! ${2:-} =~ ^(-|$) ]]; do
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
                            Warning "Value " emph "$2" " for option " emph "$1" " is invalid! Skipping it!\e[1A"
                            shift
                    esac
                done
                [ ${#TYPE_ARRAY[@]} -eq 0 ] && PrintOptionSpecificationErrorAndExit "$1"
                ;;

            --traj)
                DISPLAY="TRUE"
                FILTER_TRAJNO="TRUE"
                while [[ ${2:-} =~ ^[\>|\<][0-9]+ ]];do
                    [[ ${2:-} =~ ^\>[0-9]+ ]] && TRAJ_LOW_VALUE=${2#\>*}
                    [[ ${2:-} =~ ^\<[0-9]+ ]] && TRAJ_HIGH_VALUE=${2#\<*}
                    shift
                done
                [ "$TRAJ_LOW_VALUE" = "" ] && [ "$TRAJ_HIGH_VALUE" = "" ] && PrintOptionSpecificationErrorAndExit "$1"
                ;;

            --acc)
                DISPLAY="TRUE"
                FILTER_ACCRATE="TRUE"
                while [[ ${2:-} =~ ^[\>|\<][0-9]+\.[0-9]+ ]];do
                    [[ ${2:-} =~ ^\>[0-9]+ ]] && ACCRATE_LOW_VALUE=${2#\>*}
                    [[ ${2:-} =~ ^\<[0-9]+ ]] && ACCRATE_HIGH_VALUE=${2#\<*}
                    shift
                done
                [ "$ACCRATE_LOW_VALUE" = "" ] && [ "$ACCRATE_HIGH_VALUE" = "" ] && PrintOptionSpecificationErrorAndExit "$1"
                ;;

            --accLast1K)
                DISPLAY="TRUE"
                FILTER_ACCRATE_LAST1K="TRUE"
                while [[ ${2:-} =~ ^[\>|\<][0-9]+\.[0-9]+ ]];do
                    [[ ${2:-} =~ ^\>[0-9]+ ]] && ACCRATE_LAST1K_LOW_VALUE=${2#\>*}
                    [[ ${2:-} =~ ^\<[0-9]+ ]] && ACCRATE_LAST1K_HIGH_VALUE=${2#\<*}
                    shift
                done
                [ "$ACCRATE_LAST1K_LOW_VALUE" = "" ] && [ "$ACCRATE_LAST1K_HIGH_VALUE" = "" ] && PrintOptionSpecificationErrorAndExit "$1"
                ;;

            --maxDS)
                DISPLAY="TRUE"
                FILTER_MAX_ACTION="TRUE"
                ;;

            --status)
                DISPLAY="TRUE"
                FILTER_STATUS="TRUE"
                while [[ ! ${2:-} =~ ^(-|$) ]];do
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
                            Warning "Value " emph "$2" " for option " emph "$1" " is invalid! Skipping it!\e[1A"
                            shift
                    esac
                done
                [ ${#STATUS_ARRAY[@]} -eq 0 ] && PrintOptionSpecificationErrorAndExit "$1"
                ;;

            --lastTraj)
                DISPLAY="TRUE"
                FILTER_LASTTRAJ="TRUE"
                if [[ ${2:-} =~ ^[0-9]+ ]]; then
                    LAST_TRAJ_TIME=$2
                    shift
                fi
                [ "$LAST_TRAJ_TIME" = "" ] && PrintOptionSpecificationErrorAndExit "$1"
                ;;

            -u | --update)
                if [[ ${2:-} =~ ^[0-9]+[smhd]$ ]]; then
                    SLEEP_TIME=$2
                    shift
                elif [[ ${2:-} =~ ^[0-9]{1,2}(:[0-9]{2}){0,2}$ ]]; then
                    if ! date -d "$2" 1>/dev/null 2>&1; then
                        PrintOptionSpecificationErrorAndExit "$1"
                    fi
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
                case ${2:-} in
                    -*) PrintOptionSpecificationErrorAndExit "$1" ;;
                    *)  FILENAME_GIVEN_AS_INPUT=$2 ;;
                esac
                shift
                ;;

            *)
                PrintInvalidOptionErrorAndExit "$1" ;;
        esac
        shift
    done
    __static__CheckMutuallyExclusiveOptions
}
