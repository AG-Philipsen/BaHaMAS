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

#Collections of common operations
#TODO: Implement checks on parameters to functions

function TimeToSeconds()
{
    local T=$1; shift
    printf $((10#${T:0:2} * 3600 + 10#${T:3:2} * 60 + 10#${T:6:2}))
}

function SecondsToTime()
{
    local T=$1; shift
    local hours=$(( $T/3600 ))
    local minutes=$(( ($T - ${hours}*3600)/60 ))
    local seconds=$(awk 'END{print $1 % 60}' <<< "$T")
    printf "%02d:%02d:%02d" "${hours}" "${minutes}" "${seconds}"
}

function SecondsToTimeString()
{
    local T=$1; shift
    local hours=$(( $T/3600 ))
    local minutes=$(( ($T - ${hours}*3600)/60 ))
    local seconds=$(awk 'END{print $1 % 60}' <<< "$T")
    printf "%02dh %02dm %02ds"  "${hours}" "${minutes}" "${seconds}"
}

function TimeStringToSecond()
{
    #The string can contain s,m,h,d preceded by digits, NO SPACES
    local STRING_SEPARATED=( $(sed 's/\([smhd]\)/\1 /g' <<< "$1") )
    local TOTAL_TIME_IN_SECONDS=0
    for ELEMENT in ${STRING_SEPARATED[@]}; do
        case ${ELEMENT} in
            *d) TOTAL_TIME_IN_SECONDS=$(( ${TOTAL_TIME_IN_SECONDS} + 86400*${ELEMENT%?} )) ;;
            *h) TOTAL_TIME_IN_SECONDS=$(( ${TOTAL_TIME_IN_SECONDS} +  3600*${ELEMENT%?} )) ;;
            *m) TOTAL_TIME_IN_SECONDS=$(( ${TOTAL_TIME_IN_SECONDS} +    60*${ELEMENT%?} )) ;;
            *s) TOTAL_TIME_IN_SECONDS=$(( ${TOTAL_TIME_IN_SECONDS} +       ${ELEMENT%?} )) ;;
        esac
    done && unset -v 'ELEMENT'
    printf "${TOTAL_TIME_IN_SECONDS}"
}

function SecondsToTimeStringWithDays()
{
    local T=$1; shift
    local days=$(( $T/86400))
    local hours=$(( ($T - ${days}*86400)/3600 ))
    local minutes=$(( ($T - ${days}*86400 - ${hours}*3600)/60 ))
    local seconds=$(awk 'END{print $1 % 60}' <<< "$T")
    printf "%d-%02d:%02d:%02d" "${days}" "${hours}" "${minutes}" "${seconds}"
}

function ConvertWalltimeToSeconds()
{
    local walltime walltimeSplit result
    walltime="$1"
    if [[ ! ${walltime} =~ ^([0-9]+-)?[0-9]{1,2}:[0-9]{2}:[0-9]{2}$ ]]; then
        Internal "Walltime in wrong format passed to ${FUNCNAME}."
    elif [[ ${walltime} != *-* ]]; then
        walltime="0-${walltime}"
    fi
    walltimeSplit=( ${walltime//[-:]/ } )
    result=0
    (( result += 86400*${walltimeSplit[0]} ))
    (( result +=  3600*${walltimeSplit[1]} ))
    (( result +=    60*${walltimeSplit[2]} ))
    (( result +=       ${walltimeSplit[3]} ))
    printf '%d' ${result}
}

function GetLargestWalltimeBetweenTwo()
{
    [[ ! $1 =~ ^([0-9]+-)?[0-9]{1,2}:[0-9]{2}:[0-9]{2}$ ]] && return 1
    [[ ! $2 =~ ^([0-9]+-)?[0-9]{1,2}:[0-9]{2}:[0-9]{2}$ ]] && return 1
    local first second
    first="$1"; second="$2"
    [[ ! ${first} =~ ^[0-9]+- ]] && first="0-${first}"
    [[ ! ${second} =~ ^[0-9]+- ]] && second="0-${second}"
    if [[ ${first%%-*} -gt ${second%%-*} ]]; then
        printf "$1"; return 0
    elif [[ ${first%%-*} -lt ${second%%-*} ]]; then
        printf "$2"; return 0
    else
        first=${first##*-}; second=${second##*-}
        if [[ $(cut -d':' -f1 <<< "${first}") -gt $(cut -d':' -f1 <<< "${second}") ]]; then
            printf "$1"; return 0
        elif [[ $(cut -d':' -f1 <<< "${first}") -lt $(cut -d':' -f1 <<< "${second}") ]]; then
            printf "$2"; return 0
        else
            if [[ $(cut -d':' -f2 <<< "${first}") -gt $(cut -d':' -f2 <<< "${second}") ]]; then
                printf "$1"; return 0
            elif [[ $(cut -d':' -f2 <<< "${first}") -lt $(cut -d':' -f2 <<< "${second}") ]]; then
                printf "$2"; return 0
            else
                if [[ $(cut -d':' -f3 <<< "${first}") -gt $(cut -d':' -f3 <<< "${second}") ]]; then
                    printf "$1"; return 0
                else
                    printf "$2"; return 0
                fi
            fi
        fi
    fi
}

function GetSmallestWalltimeBetweenTwo()
{
    local largest; largest=$(GetLargestWalltimeBetweenTwo "$1" "$2")
    [[ "${largest}" = '' ]] && return 1
    [[ "$1" = "${largest}" ]] && printf "$2" || printf "$1"
    return 0
}

function MinimumOfArray()
{
    local MIN=$1; shift
    while [[ $# -gt 0 ]]; do
        if [[ $(awk '{print ($1<$2)}' <<< "$1 ${MIN}") -eq 1 ]]; then
            MIN=$1
        fi
        shift
    done
    printf "${MIN}"
}

function KeyOfMinimumOfArray()
{
    local COUNTER=0
    local KEY_AT_MIN=0
    local MIN=$1; shift
    while [[ $# -ne 0 ]]; do
        (( COUNTER++ ))
        if [[ $(awk '{print ($1<$2)}' <<< "$1 ${MIN}") -eq 1 ]]; then
            MIN=$1
            KEY_AT_MIN=${COUNTER}
        fi
        shift
    done
    printf "${KEY_AT_MIN}"
}

function MaximumOfArray()
{
    local MAX=$1; shift
    while [[ $# -gt 0 ]]; do
        if [[ $(awk '{print ($1>$2)}' <<< "$1 ${MAX}") -eq 1 ]]; then
            MAX=$1
        fi
        shift
    done
    printf "${MAX}"
}

function KeyOfMaximumOfArray()
{
    local COUNTER=0
    local KEY_AT_MAX=0
    local MAX=$1; shift
    while [[ $# -gt 0 ]]; do
        (( COUNTER++ ))
        if [[ $(awk '{print ($1>$2)}' <<< "$1 ${MAX}") -eq 1 ]]; then
            MAX=$1
            KEY_AT_MAX=${COUNTER}
        fi
        shift
    done
    printf "${KEY_AT_MAX}"
}

function FindPositionOfFirstMinimumOfArray()
{
    local ARRAY_TMP=("$@")
    local ARRAY=("$@")
    local MIN=$(MinimumOfArray "${ARRAY_TMP[@]}")
    for (( i=0; i<${#ARRAY[@]}; i++ )); do
        if [[ "${ARRAY[$i]}" = "${MIN}" ]]; then
            printf "$i";
            break
        fi
    done
}

function LengthOfLongestEntryInArray()
{
    local LENGTH_MAX=${#1}; shift
    while [[ $# -gt 0 ]]; do
        if [[ ${#1} -gt ${LENGTH_MAX} ]]; then
            LENGTH_MAX=${#1}
        fi
        shift
    done
    printf "${LENGTH_MAX}"
}


function ElementInArray()
{
    #Remember in BASH 0 means true and >0 means false
    local ELEMENT
    for ELEMENT in "${@:2}"; do [[ "${ELEMENT}" == "$1" ]] && return 0; done
    return 1
}

function KeyInArray()
{
    #ATTENTION: the array has to be passed as name, not as ${name[@]};
    #           the following function does not work if there are spaces in KEY;
    #           the following function does not work if there are spaces in ARRAY
    #           but it would be really strange.....
    #Remember in BASH 0 means true and >0 means false
    local ARRAY=$2
    local KEY=$1
    if eval '[ ${'${ARRAY}'[${KEY}]+isSet} ]'; then
        return 0;
    else
        return 1;
    fi
}

function FindValueOfClosestElementInArrayToGivenValue()
{
    local VALUE=$1
    shift
    local ARRAY=( $@ )
    awk -v value="${VALUE}" 'BEGIN{RS=" "} \
                           NR==1{result=$1; difference=sqrt(($1-value)^2)} \
                           NR>1{if(sqrt(($1-value)^2)<difference){result=$1; difference=sqrt(($1-value)^2)}} \
                           END{print result}' <<< "${ARRAY[@]}"
}

function PrintArray()
{
    local NAME_OF_THE_ARRAY="$1[@]"
    local ARRAY_CONTENT=( "${!NAME_OF_THE_ARRAY+x}" )
    [[ ${#ARRAY_CONTENT[@]} -eq 0 ]] && printf "Array $1 is empty or undeclared!\n" && return 0
    ARRAY_CONTENT=( "${!NAME_OF_THE_ARRAY}" )
    local ARRAY_DECLARATION=$(declare -p "$1")
    if [[ ${ARRAY_DECLARATION} =~ ^declare\ -a ]]; then # normal array
        for INDEX in "${!ARRAY_CONTENT[@]}"; do
            printf "$1[${INDEX}]=${ARRAY_CONTENT[${INDEX}]}\n"
        done
        return 0
    elif [[ ${ARRAY_DECLARATION} =~ ^declare\ -A ]]; then # associative array
        eval "declare -A ARRAY=${ARRAY_DECLARATION#*=}"
        for INDEX in "${!ARRAY[@]}"; do
            printf "%s\n" "$1[\"${INDEX}\"]=${ARRAY[${INDEX}]}"
        done
        return 0
    else
        printf "\"$1\" does not seem to be an array!\n"
        return 1
    fi
}

function ConvertFromBytesToHumanReadable()
{
    local BYTES=$1
    awk '
        function human(x) {
            if (x<1000) {return sprintf("%7.3f", x)} else {x/=1024}
            s="kMGTPEYZ";
            while (x>=1000 && length(s)>1)
                {x/=1024; s=substr(s,2)}
            return sprintf("%7.3f", x) substr(s,1,1) "iB"
        }
        {print human($1)}' <<< "${BYTES}"
}

function CalculateProductOfIntegers()
{
    local result number
    result=1
    for number in "$@"; do
        (( result *= number ))
    done
    printf '%d' ${result}
}

function CheckIfVariablesAreDeclared()
{
    local variableName
    for variableName in "$@"; do
        if ! declare -p "${variableName}" >/dev/null 2>&1; then
            Internal "Variable " emph "${variableName/%\[@\]/}" " not set but needed to be set in function " emph "${FUNCNAME[1]}" "."
        fi
    done
}

function CheckNumberOfFunctionArguments()
{
    if [[ $1 -ne $2 ]]; then
        Internal "Function " emph "${FUNCNAME[1]}" " called with " emph "$2" " argument(s) but " emph "$1" " needed!"
    fi
}


function MakeFunctionsDefinedInThisFileReadonly()
{
    # Here we assume all BaHaMAS functions are defined with the same stile,
    # including empty parenteses and the braces on new lines! I.e.
    #    function nameOfTheFunction()
    #
    # Accepted symbols in function name: letters, '_', ':' and '-'
    #
    # NOTE: The file from which this function is called is ${BASH_SOURCE[1]}
    local declaredFunctions functionName
    declaredFunctions=( # Here word splitting can split names, no space allowed in function name!
        $(grep -E '^[[:space:]]*function[[:space:]]+[-[:alnum:]_:]+\(\)[[:space:]]*$' "${BASH_SOURCE[1]}" |\
           sed -E 's/^[[:space:]]*function[[:space:]]+([^(]+)\(\)[[:space:]]*$/\1/')
    )
    if [[ ${#declaredFunctions[@]} -eq 0 ]]; then
        if [[ ! ${BHMAS_coloredOutput-} =~ ^(TRUE|FALSE)$ ]]; then
            BHMAS_coloredOutput='TRUE' #It might be unset whe error occurs!
        fi
        Internal 'Function ' emph "${FUNCNAME}" ' called, but no function found in file\n'\
                 file "${BASH_SOURCE[1]}" '.'
    else
        readonly -f "${declaredFunctions[@]}"
    fi
}


MakeFunctionsDefinedInThisFileReadonly
