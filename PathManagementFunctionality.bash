function CheckWilsonStaggeredVariables()
{
    if [ "$WILSON" == "$STAGGERED" ]; then
        printf "\n\e[0;31m Variables WILSON and STAGGERED both set to the same value (please check the position from where the script was run)! Aborting...\n\n\e[0m"
        exit -1
    fi
}

#Function that returns true if any parameters corresponding to the given prefixes is unset
function IsAnyParameterUnsetAmong()
{
    for PREFIX in $@; do
        [[ -z ${PARAMETER_VARIABLE_NAMES[$PREFIX]:+x} ]] &&  printf "\n\e[0;31m Accessing PARAMETER_VARIABLE_NAMES array with not existing prefix! Aborting...\n\n\e[0m" && exit -1
        if [ "${!PARAMETER_VARIABLE_NAMES[$PREFIX]}" = "" ]; then
            return 0
        fi
    done && unset -v 'PREFIX'
    return 1
}

#This function get the prefixes of parameters with which the string has to be built (order as given) -> e.g. Nf2_mui0_ns8
function GetParametersString()
{
    IsAnyParameterUnsetAmong $@ &&  printf "\n\e[0;31m Function \"$FUNCNAME\" called before extracting parameters! Aborting...\n\n\e[0m" && exit -1
    local RESULTING_STRING=""
    for PREFIX in $@; do
        RESULTING_STRING="$RESULTING_STRING${PREFIX}${!PARAMETER_VARIABLE_NAMES[$PREFIX]}_"
    done && unset -v 'PREFIX'
    printf "${RESULTING_STRING%?}" #Remove last underscore
}

#This function get the prefixes of parameters with which the path has to be built (order as given) -> e,g, /Nf2/nt4/ns8
function GetParametersPath()
{
    IsAnyParameterUnsetAmong $@ &&  printf "\n\e[0;31m Function \"$FUNCNAME\" called before extracting parameters! Aborting...\n\n\e[0m" && exit -1
    local RESULTING_PATH=""
    for PREFIX in $@; do
        RESULTING_PATH="$RESULTING_PATH/${PREFIX}${!PARAMETER_VARIABLE_NAMES[$PREFIX]}"
    done && unset -v 'PREFIX'
    printf "$RESULTING_PATH"
}

#This function set the global variables PARAMETERS_PATH and PARAMETERS_STRING after having checked that the parameters have been extracted
function SetParametersPathAndString()
{

    #TODO: Use function GetParametersString giving ${PARAMETER_PREFIXES[@]} to it and build PARAMETERS_PATH as "/${PARAMETERS_STRING[@]//_/\/}"
    IsAnyParameterUnsetAmong $@ &&  printf "\n\e[0;31m Function \"$FUNCNAME\" called before extracting parameters! Aborting...\n\n\e[0m" && exit -1
    local PARAMETERS_VALUE=([$NFLAVOUR_POSITION]=$NFLAVOUR [$CHEMPOT_POSITION]=$CHEMPOT [$MASS_POSITION]=$MASS [$NTIME_POSITION]=$NTIME [$NSPACE_POSITION]=$NSPACE)
    for ((i=0; i<${#PARAMETER_PREFIXES[@]}; i++)); do
        PARAMETERS_PATH="$PARAMETERS_PATH/${PARAMETER_PREFIXES[$i]}${PARAMETERS_VALUE[$i]}"
        PARAMETERS_STRING="$PARAMETERS_STRING${PARAMETER_PREFIXES[$i]}${PARAMETERS_VALUE[$i]}_"
    done
    PARAMETERS_STRING=${PARAMETERS_STRING%?} #Remove last underscore
}

#This function takes the path to be used as first argument and the prefix of the parameters to be extracted as second argument
#NOTE: The prefix must appear after a slash in the path!
function ReadSingleParameterFromPath()
{
    [ $# -ne 2 ] &&  printf "\n\e[0;31m Function \"$FUNCNAME\" called with wrong number of parameters! Aborting...\n\n\e[0m" && exit -1
    [ -z ${PARAMETER_VARIABLE_NAMES[$2]:+x} ] &&  printf "\n\e[0;31m Function \"$FUNCNAME\" called with unknown prefix! Aborting...\n\n\e[0m" && exit -1
    local PATH_TO_SEARCH_IN="/$1/" #Add in front and back a "/" just to be general in the search
    local PREFIX_TO_BE_USED="$2"
    if [ $(grep -oc "/$PREFIX_TO_BE_USED" <<< "$PATH_TO_SEARCH_IN") -ne 1 ]; then
        printf "\n\e[0;31m Unable to recover \"$PREFIX_TO_BE_USED\" from the path \"$1\". Aborting...\n\n\e[0m"
        exit -1
    fi
    local PIECE_OF_PATH_WITH_PARAMETER="$(grep -o "/${PREFIX_TO_BE_USED}[^/]*" <<< "$PATH_TO_SEARCH_IN")"
    declare -gr ${PARAMETER_VARIABLE_NAMES[$2]}="${PIECE_OF_PATH_WITH_PARAMETER##*$PREFIX_TO_BE_USED}"
}

# This function takes the path to be used as first argument and the prefix of the parameters to be extracted as second argument
# but it considers that the prefix is present multiple times in the path, so the slash before the prefix is not considered.
# At the moment the global variable is set to a readonly array value.
function ReadSingleParameterFromPathWithMultipleOccurence()
{
    [ $# -ne 2 ] &&  printf "\n\e[0;31m Function \"$FUNCNAME\" called with wrong number of parameters! Aborting...\n\n\e[0m" && exit -1
    [ -z ${PARAMETER_VARIABLE_NAMES[$2]:+x} ] &&  printf "\n\e[0;31m Function \"$FUNCNAME\" called with unknown prefix! Aborting...\n\n\e[0m" && exit -1
    local PATH_TO_SEARCH_IN="$1"
    local PREFIX_TO_BE_USED="$2"
    if [ $(grep -oc "$PREFIX_TO_BE_USED" <<< "$PATH_TO_SEARCH_IN") -lt 1 ]; then
        printf "\n\e[0;31m \"$PREFIX_TO_BE_USED\" not found in the path \"$PATH_TO_SEARCH_IN\". Aborting...\n\n\e[0m"
        exit -1
    fi
    #TODO: At the moment this works only for numbers. The parameter regex should be used here but it implies to have access to it through the prefix!
    eval "declare -gra ${PARAMETER_VARIABLE_NAMES[$2]}=( $(grep -o "${PREFIX_TO_BE_USED}[[:digit:]]*" <<< "$PATH_TO_SEARCH_IN" | grep -o "[[:digit:]]*") )"
}


#This function get a bunch of prefixes and checks that the corresponding variable has a value that makes sense
function CheckParametersExtractedFromPath()
{
    IsAnyParameterUnsetAmong $@ &&  printf "\n\e[0;31m Function \"$FUNCNAME\" called before extracting parameters! Aborting...\n\n\e[0m" && exit -1
    for PREFIX in $@; do
        case "${PARAMETER_VARIABLE_NAMES[$PREFIX]}" in
            MASS)
                for VALUE in ${MASS[@]}; do
                    if [[ ! $VALUE =~ ^${MASS_REGEX//\\/}$ ]]; then
                        printf "\n\e[0;31m Parameter \"$MASS_PREFIX\" extracted from the path not allowed! Aborting...\n\n\e[0m"; exit -1
                    fi
                done && unset -v 'VALUE' ;;
            NTIME)
                for VALUE in ${NTIME[@]}; do
                    if [[ ! $VALUE =~ ^${NTIME_REGEX//\\/}$ ]]; then
                        printf "\n\e[0;31m Parameter \"$NTIME_PREFIX\" extracted from the path not allowed! Aborting...\n\n\e[0m"; exit -1
                    fi
                done && unset -v 'VALUE' ;;
            NSPACE)
                for VALUE in ${NSPACE[@]}; do
                    if [[ ! $VALUE =~ ^${NSPACE_REGEX//\\/}$ ]]; then
                        printf "\n\e[0;31m Parameter \"$NSPACE_PREFIX\" extracted from the path not allowed! Aborting...\n\n\e[0m"; exit -1
                    fi
                done && unset -v 'VALUE' ;;
            NFLAVOUR)
                for VALUE in ${NFLAVOUR[@]}; do
                    if [[ ! $VALUE =~ ^${NFLAVOUR_REGEX//\\/}$ ]]; then
                        printf "\n\e[0;31m Parameter \"$NFLAVOUR_PREFIX\" extracted from the path not allowed! Aborting...\n\n\e[0m"; exit -1
                    fi
                done && unset -v 'VALUE' ;;
            CHEMPOT)
                for VALUE in ${CHEMPOT[@]}; do
                    if [[ ! $VALUE =~ ^${CHEMPOT_REGEX//\\/}$ ]]; then
                        printf "\n\e[0;31m Parameter \"$CHEMPOT_PREFIX\" extracted from the path not allowed! Aborting...\n\n\e[0m"; exit -1
                    fi
                done && unset -v 'VALUE' ;;
            *)
                printf "\n\e[0;31m Unknown prefix given to function \"$FUNCNAME\"! Aborting...\n\n\e[0m" ; exit -1 ;;
        esac
    done && unset -v 'PREFIX'
}

function ReadParametersFromPath()
{

    # TODO: This function should become something like (Bash >= 4.2 otherwise declare -g not supported!)
    #
    #   for PREFIX in $@; do
    #       ReadSingleParameterFromPath $1 $PREFIX
    #       CheckParametersExtractedFromPath $PREFIX
    #   done && unset -v 'PREFIX'
    #
    # but it should be tested! This would make parameters readonly through ReadSingleParameterFromPath and it is good.

    local PARAMETERS_VALUE=()
    #Path given as first argument to this function
    local PATH_TO_BE_USED="/$1/"
    for ((i=0; i<${#PARAMETER_PREFIXES[@]}; i++)); do
        if [ $(grep -o "/${PARAMETER_PREFIXES[$i]}" <<< "$PATH_TO_BE_USED" | wc -l) -ne 1 ]; then
            printf "\n\e[0;31m Unable to recover \"${PARAMETER_PREFIXES[$i]}\" from the path \"$1\". Aborting...\n\n\e[0m"
            exit -1
        fi
        PARAMETERS_VALUE[$i]=$(awk -v expr="${PARAMETER_PREFIXES[$i]}" \
                                   -v expr_len=${#PARAMETER_PREFIXES[$i]} \
                                   '{print substr($0, index($0, "/"expr) + expr_len + 1, index(substr($0, index($0, "/"expr) + expr_len+1), "/") - 1)}' <<< "$PATH_TO_BE_USED")
    done
    NFLAVOUR=${PARAMETERS_VALUE[$NFLAVOUR_POSITION]}
    CHEMPOT=${PARAMETERS_VALUE[$CHEMPOT_POSITION]}
    MASS=${PARAMETERS_VALUE[$MASS_POSITION]}
    NTIME=${PARAMETERS_VALUE[$NTIME_POSITION]}
    NSPACE=${PARAMETERS_VALUE[$NSPACE_POSITION]}

    #Check that the recovered parameters make sense (remove escape characters from regex)
    if [[ ! $MASS =~ ^${MASS_REGEX//\\/}$ ]]; then
        printf "\n\e[0;31m Parameter \"$MASS_PREFIX\" from the path \"$1\" not allowed! Aborting...\n\n\e[0m"
        exit -1
    elif [[ ! $NTIME =~ ^${NTIME_REGEX//\\/}$ ]]; then
        printf "\n\e[0;31m Parameter \"$NTIME_PREFIX\" from the path \"$1\" not allowed! Aborting...\n\n\e[0m"
        exit -1
    elif [[ ! $NSPACE =~ ^${NSPACE_REGEX//\\/}$ ]]; then
        printf "\n\e[0;31m Parameter \"$NSPACE_PREFIX\" from the path \"$1\" not allowed! Aborting...\n\n\e[0m"
        exit -1
    elif [[ ! $NFLAVOUR =~ ^${NFLAVOUR_REGEX//\\/}$ ]]; then
        printf "\n\e[0;31m Parameter \"$NFLAVOUR_PREFIX\" from the path \"$1\" not allowed! Aborting...\n\n\e[0m"
        exit -1
    elif [[ ! $CHEMPOT =~ ^${CHEMPOT_REGEX//\\/}$ ]]; then
        printf "\n\e[0;31m Parameter \"$CHEMPOT_PREFIX\" from the path \"$1\" not allowed! Aborting...\n\n\e[0m"
        exit -1
    fi
    #Set parameters path
    SetParametersPathAndString
}

function CheckSingleOccurrenceInPath()
{
    for var in $@; do
        Var=$(grep -o "$var" <<< "$(pwd)" | wc -l)
        if [ $Var -ne 1 ] ; then
            printf "\n\e[0;31m The string \"$var\" must occur once and only once in the path! Aborting...\n\n\e[0m"
            exit 1
        fi
    done
}
