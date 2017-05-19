function CheckWilsonStaggeredVariables()
{
    if [ "$WILSON" == "$STAGGERED" ]; then
        cecho lr "\n The variables " emph "WILSON" " and " emph "STAGGERED"\
              " are both set to the same value (please check the position from where the script was run)! Aborting...\n"
        exit -1
    fi
}

function __static__CheckPrefixExistence()
{
    if [[ -z "${PARAMETER_VARIABLE_NAMES[$1]:+x}" ]]; then
        cecho lr "\n Accessing " emph "PARAMETER_VARIABLE_NAMES" " array with not existing prefix " emph "$1" "! Aborting...\n"
        exit -1
    fi
}

#Function that returns true if any parameters corresponding to the given prefixes is unset
function __static__IsAnyParameterUnsetAmong()
{
    local prefix
    for prefix in "$@"; do
        __static__CheckPrefixExistence "$prefix"
        if [ -z "${!PARAMETER_VARIABLE_NAMES[$prefix]:+x}" ]; then
            return 0
        fi
    done
    return 1
}

function __static__CheckNoArguments()
{
    if [ $2 -eq 0 ]; then
        cecho lr "\n Function " emph "$1" " called without needed arguments! Aborting...\n"
        exit -1
    fi
}

function __static__CheckUnsetParameters()
{
    local functionName; functionName="$1"; shift
    if __static__IsAnyParameterUnsetAmong "$@"; then
        cecho lr "\n Function " emph "$functionName" " called before extracting parameters! Aborting...\n"
        exit -1
    fi
}

#This function get the prefixes of parameters with which the string has to be built (order as given) -> e.g. Nf2_mui0_ns8
function __static__GetParametersString()
{
    __static__CheckNoArguments "$FUNCNAME" $#
    __static__CheckUnsetParameters "$FUNCNAME" "$@"
    local prefix resultingString
    resultingString=''
    for prefix in "$@"; do
        resultingString+="${prefix}${!PARAMETER_VARIABLE_NAMES[$prefix]}_"
    done
    printf "${resultingString%?}" #Remove last underscore
}

#This function get the prefixes of parameters with which the path has to be built (order as given) -> e,g, /Nf2/nt4/ns8
function __static__GetParametersPath()
{
    __static__CheckNoArguments "$FUNCNAME" $#
    __static__CheckUnsetParameters "$FUNCNAME" "$@"
    local prefix resultingPath
    resultingPath=$(__static__GetParametersString "${PARAMETER_PREFIXES[@]}")
    printf "/${resultingPath//_/\/}"
}

#This function set the global variables PARAMETERS_PATH and PARAMETERS_STRING after having checked that the parameters have been extracted
function __static__SetParametersPathAndString()
{
    __static__CheckUnsetParameters "$FUNCNAME" "$@"
    readonly PARAMETERS_STRING="$(__static__GetParametersString "${PARAMETER_PREFIXES[@]}")"
    readonly PARAMETERS_PATH="$(__static__GetParametersPath "${PARAMETER_PREFIXES[@]}")"
}

#This function takes the path to be used as first argument and the prefix of the parameters to be extracted as second argument
#NOTE: The prefix must appear after a slash in the path!
function __static__ReadSingleParameterFromPath()
{
    if [ $# -ne 2 ]; then
        cecho lr "\n Function " emph "$FUNCNAME" " called with wrong number of parameters! Aborting...\n"
        exit -1
    fi
    local pathToBeSearchedIn prefixToBeUsed pieceOfPathWithParameter
    pathToBeSearchedIn="/$1/" #Add in front and back a "/" just to be general in the search
    prefixToBeUsed="$2"
    __static__CheckPrefixExistence "$prefixToBeUsed"
    case $(grep -o "/$prefixToBeUsed" <<< "$pathToBeSearchedIn" | wc -l) in
        0)
            cecho lr "\n Unable to recover " emph "$prefixToBeUsed" " from the path " dir "$1" ". Aborting...\n"
            exit -1 ;;
        1)
            pieceOfPathWithParameter="$(grep -o "/${prefixToBeUsed}[^/]*" <<< "$pathToBeSearchedIn")"
            declare -gr ${PARAMETER_VARIABLE_NAMES["$prefixToBeUsed"]}="${pieceOfPathWithParameter##*$prefixToBeUsed}"
            ;;
        *)
            cecho lr "\n Prefix " emph "$prefixToBeUsed" " found several times in path " dir "$1" ". Aborting...\n"
            exit -1 ;;
    esac
}

# This function get a bunch of prefixes and checks that the corresponding variable has a value that makes sense
# NOTE: Here we check any variable content as if it could contain several values. This should not hurt, since
#       ${var[@]} should coincide with $var in case of a simple variable.
function __static__CheckParametersExtractedFromPath()
{
    __static__CheckNoArguments "$FUNCNAME" $#
    __static__CheckUnsetParameters "$FUNCNAME" "$@"
    local prefix value variableName variableRegex
    for prefix in "$@"; do
        variableName="${PARAMETER_VARIABLE_NAMES[$prefix]}"
        variableRegex="${variableName}_REGEX"
        variableName+="[@]" #See NOTE above
        for value in ${!variableName}; do
            if [[ ! $value =~ ^${!variableRegex//\\/}$ ]]; then
                cecho lr "\n Parameter " emph "$prefix" " extracted from the path not matching "\
                      emph "${!variableRegex//\\/}" "! Aborting...\n"; exit -1
            fi
        done
    done
}

function ReadParametersFromPathAndSetRelatedVariables()
{
    __static__CheckNoArguments "$FUNCNAME" $#
    for prefix in "${PARAMETER_PREFIXES[@]}"; do
        __static__ReadSingleParameterFromPath "$1" "$prefix"
    done
    __static__CheckParametersExtractedFromPath "${PARAMETER_PREFIXES[@]}"
    __static__SetParametersPathAndString
    if [ -z "${PARAMETERS_STRING:+x}" ] || [ -z "${PARAMETERS_PATH:+x}" ]; then
        cecho lr "\n Either " emph "PARAMETERS_STRING" " or " emph "PARAMETERS_PATH" " unset or empty! Aborting...\n"
        exit -1
    fi
}

function CheckSingleOccurrenceInPath()
{
    local variable
    for variable in $@; do
        if [ $(grep -o "$variable" <<< "$(pwd)" | wc -l) -ne 1 ] ; then
            cecho lr "\n The string " emph "$variable" " must occur " B "once and only once" uB " in the path! Aborting...\n"
            exit 1
        fi
    done
}
