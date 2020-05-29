#
#  Copyright (c) 2014-2017,2020 Alessandro Sciarra
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

function CheckWilsonStaggeredVariables()
{
    if [[ "${BHMAS_wilson}" == "${BHMAS_staggered}" ]]; then
        Fatal ${BHMAS_fatalPathError} "The variables " emph "BHMAS_wilson" " and " emph "BHMAS_staggered"\
              " are both set to the same value (please check the position from where the script was run)!"
    fi
}

function __static__CheckPrefixExistence()
{
    if [[ -z "${BHMAS_parameterVariableNames[$1]:+x}" ]]; then
        Internal "Accessing " emph "BHMAS_parameterVariableNames" " array with not existing prefix " emph "$1" "!"
    fi
}

#Function that returns true if any parameters corresponding to the given prefixes is unset
function __static__IsAnyParameterUnsetAmong()
{
    local prefix
    for prefix in "$@"; do
        __static__CheckPrefixExistence "${prefix}"
        if [[ -z "${!BHMAS_parameterVariableNames[${prefix}]:+x}" ]]; then
            return 0
        fi
    done
    return 1
}

function __static__CheckNoArguments()
{
    if [[ $2 -eq 0 ]]; then
        Internal "Function " emph "$1" " called without needed arguments!"
    fi
}

function __static__CheckUnsetParameters()
{
    local functionName; functionName="$1"; shift
    if __static__IsAnyParameterUnsetAmong "$@"; then
        Internal "Function " emph "${functionName}" " called before extracting parameters!"
    fi
}

#This function get the prefixes of parameters with which the string has to be built (order as given) -> e.g. Nf2_mui0_ns8
function __static__GetParametersString()
{
    __static__CheckNoArguments "${FUNCNAME}" $#
    __static__CheckUnsetParameters "${FUNCNAME}" "$@"
    local prefix resultingString
    resultingString=''
    for prefix in "$@"; do
        resultingString+="${prefix}${!BHMAS_parameterVariableNames[${prefix}]}_"
    done
    printf "${resultingString%?}" #Remove last underscore
}

#This function get the prefixes of parameters with which the path has to be built (order as given) -> e,g, /Nf2/nt4/ns8
function __static__GetParametersPath()
{
    __static__CheckNoArguments "${FUNCNAME}" $#
    __static__CheckUnsetParameters "${FUNCNAME}" "$@"
    local prefix resultingPath
    resultingPath=$(__static__GetParametersString "${BHMAS_parameterPrefixes[@]}")
    printf "/${resultingPath//_/\/}"
}

#This function set the global variables BHMAS_parametersPath and BHMAS_parametersString after having checked that the parameters have been extracted
function __static__SetParametersPathAndString()
{
    __static__CheckUnsetParameters "${FUNCNAME}" "$@"
    readonly BHMAS_parametersString="$(__static__GetParametersString "${BHMAS_parameterPrefixes[@]}")"
    readonly BHMAS_parametersPath="$(__static__GetParametersPath "${BHMAS_parameterPrefixes[@]}")"
}

#This function takes the path to be used as first argument and the prefix of the parameters to be extracted as second argument
#NOTE: The prefix must appear after a slash in the path!
function __static__ReadSingleParameterFromPath()
{
    if [[ $# -ne 2 ]]; then
        Internal "Function " emph "${FUNCNAME}" " called with wrong number of parameters!"
    fi
    local pathToBeSearchedIn prefixToBeUsed pieceOfPathWithParameter
    pathToBeSearchedIn="/$1/" #Add in front and back a "/" just to be general in the search
    prefixToBeUsed="$2"
    __static__CheckPrefixExistence "${prefixToBeUsed}"
    case $(grep -o "/${prefixToBeUsed}" <<< "${pathToBeSearchedIn}" | wc -l) in
        0)
            Fatal ${BHMAS_fatalPathError} "Unable to recover " emph "${prefixToBeUsed}" " from the path " dir "$1" "." ;;
        1)
            pieceOfPathWithParameter="$(grep -o "/${prefixToBeUsed}[^/]*" <<< "${pathToBeSearchedIn}")"
            declare -gr ${BHMAS_parameterVariableNames["${prefixToBeUsed}"]}="${pieceOfPathWithParameter##*${prefixToBeUsed}}"
            ;;
        *)
            Fatal ${BHMAS_fatalPathError} "Prefix " emph "${prefixToBeUsed}" " found several times in path " dir "$1" "." ;;
    esac
}

# This function get a bunch of prefixes and checks that the corresponding variable has a value that makes sense
# NOTE: Here we check any variable content as if it could contain several values. This should not hurt, since
#       ${var[@]} should coincide with ${var} in case of a simple variable.
function __static__CheckParametersExtractedFromPath()
{
    __static__CheckNoArguments "${FUNCNAME}" $#
    __static__CheckUnsetParameters "${FUNCNAME}" "$@"
    local prefix value variableName variableRegex
    for prefix in "$@"; do
        variableName="${BHMAS_parameterVariableNames[${prefix}]}"
        variableRegex="${variableName}Regex"
        variableName+="[@]" #See NOTE above
        for value in ${!variableName}; do
            if [[ ! ${value} =~ ^${!variableRegex//\\/}$ ]]; then
                Fatal ${BHMAS_fatalPathError} "Parameter " emph "${prefix}" " extracted from the path not matching "\
                      emph "${!variableRegex//\\/}" "!"
            fi
        done
    done
}

function ReadParametersFromPathAndSetRelatedVariables()
{
    __static__CheckNoArguments "${FUNCNAME}" $#
    for prefix in "${BHMAS_parameterPrefixes[@]}"; do
        __static__ReadSingleParameterFromPath "$1" "${prefix}"
    done
    __static__CheckParametersExtractedFromPath "${BHMAS_parameterPrefixes[@]}"
    __static__SetParametersPathAndString
    if [[ -z "${BHMAS_parametersString:+x}" ]] || [[ -z "${BHMAS_parametersPath:+x}" ]]; then
        Internal "Either " emph "BHMAS_parametersString" " or " emph "BHMAS_parametersPath" " unset or empty!"
    fi
    declare -rga BHMAS_latticeSize=( ${BHMAS_ntime} ${BHMAS_nspace} ${BHMAS_nspace} ${BHMAS_nspace} )
}

function CheckSingleOccurrenceInPath()
{
    local variable
    for variable in $@; do
        if [[ $(grep -o "${variable}" <<< "$(pwd)" | wc -l) -ne 1 ]] ; then
            Fatal ${BHMAS_fatalPathError} "The string " emph "${variable}" " must occur " B "once and only once" uB " in the path!"
        fi
    done
}


MakeFunctionsDefinedInThisFileReadonly
