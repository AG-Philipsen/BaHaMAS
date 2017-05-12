function CheckWilsonStaggeredVariables()
{
    if [ "$WILSON" == "$STAGGERED" ]; then
        cecho lr "\n The variables " emph "WILSON" " and " emph "STAGGERED" " are both set to the same value (please check the position from where the script was run)! Aborting...\n"
        exit -1
    fi
}

#Function that returns true if any parameters corresponding to the given prefixes is unset
function IsAnyParameterUnsetAmong()
{
    for PREFIX in $@; do
        if [[ -z ${PARAMETER_VARIABLE_NAMES[$PREFIX]:+x} ]]; then
            cecho lr "\n Accessing " emph "PARAMETER_VARIABLE_NAMES" " array with not existing prefix in funciton " emph "$FUNCNAME" "! Aborting...\n"
            exit -1
        fi
        if [ "${!PARAMETER_VARIABLE_NAMES[$PREFIX]}" = "" ]; then
            return 0
        fi
    done && unset -v 'PREFIX'
    return 1
}

#This function get the prefixes of parameters with which the string has to be built (order as given) -> e.g. Nf2_mui0_ns8
function GetParametersString()
{
    if IsAnyParameterUnsetAmong $@; then
        cecho lr "\n Function " emph "$FUNCNAME" " called before extracting parameters! Aborting...\n"
        exit -1
    fi
    local RESULTING_STRING=""
    for PREFIX in $@; do
        RESULTING_STRING="$RESULTING_STRING${PREFIX}${!PARAMETER_VARIABLE_NAMES[$PREFIX]}_"
    done && unset -v 'PREFIX'
    printf "${RESULTING_STRING%?}" #Remove last underscore
}

#This function get the prefixes of parameters with which the path has to be built (order as given) -> e,g, /Nf2/nt4/ns8
function GetParametersPath()
{
    if IsAnyParameterUnsetAmong $@; then
        cecho lr "\n Function " emph "$FUNCNAME" " called before extracting parameters! Aborting...\n"
        exit -1
    fi
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
    if IsAnyParameterUnsetAmong $@; then
        cecho lr "\n Function " emph "$FUNCNAME" " called before extracting parameters! Aborting...\n"
        exit -1
    fi
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
    if [ $# -ne 2 ]; then
        cecho lr "\n Function " emph "$FUNCNAME" " called with wrong number of parameters! Aborting...\n"
        exit -1
    fi
    if [ -z ${PARAMETER_VARIABLE_NAMES[$2]:+x} ]; then
        cecho lr  "\n Function " emph "$FUNCNAME" " called with unknown prefix! Aborting...\n"
        exit -1
    fi
    local PATH_TO_SEARCH_IN="/$1/" #Add in front and back a "/" just to be general in the search
    local PREFIX_TO_BE_USED="$2"
    if [ $(grep -oc "/$PREFIX_TO_BE_USED" <<< "$PATH_TO_SEARCH_IN") -ne 1 ]; then
        cecho lr "\n Unable to recover " emph "$PREFIX_TO_BE_USED" " from the path " dir "$1" ". Aborting...\n"
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
    if [ $# -ne 2 ]; then
        cecho lr "\n Function " emph "$FUNCNAME" " called with wrong number of parameters! Aborting...\n"
        exit -1
    fi
    if [ -z ${PARAMETER_VARIABLE_NAMES[$2]:+x} ]; then
        cecho lr "\n Function " emph "$FUNCNAME" " called with unknown prefix! Aborting...\n"
        exit -1
    fi
    local PATH_TO_SEARCH_IN="$1"
    local PREFIX_TO_BE_USED="$2"
    if [ $(grep -oc "$PREFIX_TO_BE_USED" <<< "$PATH_TO_SEARCH_IN") -lt 1 ]; then
        cecho lr "\n Prefix " emph "$PREFIX_TO_BE_USED" " not found in the path " dir "$PATH_TO_SEARCH_IN" ". Aborting...\n"
        exit -1
    fi
    #TODO: At the moment this works only for numbers. The parameter regex should be used here but it implies to have access to it through the prefix!
    eval "declare -gra ${PARAMETER_VARIABLE_NAMES[$2]}=( $(grep -o "${PREFIX_TO_BE_USED}[[:digit:]]*" <<< "$PATH_TO_SEARCH_IN" | grep -o "[[:digit:]]*") )"
}


# This function get a bunch of prefixes and checks that the corresponding variable has a value that makes sense
# NOTE: Here we check any variable content as if it could contain several values. This should not hurt, since
#       ${var[@]} should coincide with $var in case of a simple variable.
function CheckParametersExtractedFromPath()
{
    if IsAnyParameterUnsetAmong $@; then
        cecho lr "\n Function" emph "$FUNCNAME" " called before extracting parameters! Aborting...\n"
        exit -1
    fi
    for PREFIX in $@; do
        case "${PARAMETER_VARIABLE_NAMES[$PREFIX]}" in
            MASS)
                for VALUE in ${MASS[@]}; do
                    if [[ ! $VALUE =~ ^${MASS_REGEX//\\/}$ ]]; then
                        cecho lr "\n Parameter " emph "$MASS_PREFIX" " extracted from the path not allowed! Aborting...\n"; exit -1
                    fi
                done && unset -v 'VALUE' ;;
            NTIME)
                for VALUE in ${NTIME[@]}; do
                    if [[ ! $VALUE =~ ^${NTIME_REGEX//\\/}$ ]]; then
                        cecho lr "\n Parameter " emph "$NTIME_PREFIX" " extracted from the path not allowed! Aborting...\n"; exit -1
                    fi
                done && unset -v 'VALUE' ;;
            NSPACE)
                for VALUE in ${NSPACE[@]}; do
                    if [[ ! $VALUE =~ ^${NSPACE_REGEX//\\/}$ ]]; then
                        cecho lr "\n Parameter " emph "$NSPACE_PREFIX" " extracted from the path not allowed! Aborting...\n"; exit -1
                    fi
                done && unset -v 'VALUE' ;;
            NFLAVOUR)
                for VALUE in ${NFLAVOUR[@]}; do
                    if [[ ! $VALUE =~ ^${NFLAVOUR_REGEX//\\/}$ ]]; then
                        cecho lr "\n Parameter " emph "$NFLAVOUR_PREFIX" " extracted from the path not allowed! Aborting...\n"; exit -1
                    fi
                done && unset -v 'VALUE' ;;
            CHEMPOT)
                for VALUE in ${CHEMPOT[@]}; do
                    if [[ ! $VALUE =~ ^${CHEMPOT_REGEX//\\/}$ ]]; then
                        cecho lr "\n Parameter " emph "$CHEMPOT_PREFIX" " extracted from the path not allowed! Aborting...\n"; exit -1
                    fi
                done && unset -v 'VALUE' ;;
            *)
                cecho lr "\n Unknown prefix given to function " emph "$FUNCNAME" "! Aborting...\n" ; exit -1 ;;
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
            cecho lr "\n Unable to recover " emph "${PARAMETER_PREFIXES[$i]}" " from the path " dir "$1" ". Aborting...\n"
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
        cecho lr "\n Parameter " emph "$MASS_PREFIX" " extracted from the path not allowed! Aborting...\n"; exit -1
        exit -1
    elif [[ ! $NTIME =~ ^${NTIME_REGEX//\\/}$ ]]; then
        cecho lr "\n Parameter " emph "$NTIME_PREFIX" " extracted from the path not allowed! Aborting...\n"; exit -1
        exit -1
    elif [[ ! $NSPACE =~ ^${NSPACE_REGEX//\\/}$ ]]; then
        cecho lr "\n Parameter " emph "$NSPACE_PREFIX" " extracted from the path not allowed! Aborting...\n"; exit -1
        exit -1
    elif [[ ! $NFLAVOUR =~ ^${NFLAVOUR_REGEX//\\/}$ ]]; then
        cecho lr "\n Parameter " emph "$NFLAVOUR_PREFIX" " extracted from the path not allowed! Aborting...\n"; exit -1
        exit -1
    elif [[ ! $CHEMPOT =~ ^${CHEMPOT_REGEX//\\/}$ ]]; then
        cecho lr "\n Parameter " emph "$CHEMPOT_PREFIX" " extracted from the path not allowed! Aborting...\n"; exit -1
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
            cecho lr "\n The string " emph "$var" " must occur " B "once and only once" uB " in the path! Aborting...\n"
            exit 1
        fi
    done
}
