#Collections of common operations
#
# TODO: Implement checks on parameters to functions

function TimeToSeconds()
{
    local T=$1; shift
    printf $((10#${T:0:2} * 3600 + 10#${T:3:2} * 60 + 10#${T:6:2}))
}

function SecondsToTime()
{
    local T=$1; shift
    local hours=$(( $T/3600 ))
    local minutes=$(( ($T - $hours*3600)/60 ))
    local seconds=$(awk 'END{print $1 % 60}' <<< "$T")
    printf "%02d:%02d:%02d" "${hours}" "${minutes}" "${seconds}"
}

function SecondsToTimeString()
{
    local T=$1; shift
    local hours=$(( $T/3600 ))
    local minutes=$(( ($T - $hours*3600)/60 ))
    local seconds=$(awk 'END{print $1 % 60}' <<< "$T")
    printf "%02dh %02dm %02ds"  "${hours}" "${minutes}" "${seconds}"
}

function TimeStringToSecond()
{
    #The string can contain s,m,h,d preceded by digits, NO SPACES
    local STRING_SEPARATED=( $(sed 's/\([smhd]\)/\1 /g' <<< "$1") )
    local TOTAL_TIME_IN_SECONDS=0
    for ELEMENT in ${STRING_SEPARATED[@]}; do
        case $ELEMENT in
            *d) TOTAL_TIME_IN_SECONDS=$(( $TOTAL_TIME_IN_SECONDS + 86400*${ELEMENT%?} )) ;;
            *h) TOTAL_TIME_IN_SECONDS=$(( $TOTAL_TIME_IN_SECONDS +  3600*${ELEMENT%?} )) ;;
            *m) TOTAL_TIME_IN_SECONDS=$(( $TOTAL_TIME_IN_SECONDS +    60*${ELEMENT%?} )) ;;
            *s) TOTAL_TIME_IN_SECONDS=$(( $TOTAL_TIME_IN_SECONDS +       ${ELEMENT%?} )) ;;
        esac
    done && unset -v 'ELEMENT'
    printf "$TOTAL_TIME_IN_SECONDS"
}

function SecondsToTimeStringWithDays()
{
    local T=$1; shift
    local days=$(( $T/86400))
    local hours=$(( ($T - $days*86400)/3600 ))
    local minutes=$(( ($T - $days*86400 - $hours*3600)/60 ))
    local seconds=$(awk 'END{print $1 % 60}' <<< "$T")
    printf "%d-%02d:%02d:%02d" "${days}" "${hours}" "${minutes}" "${seconds}"
}

function GetLargestWalltimeBetweenTwo()
{
    [[ ! $1 =~ ^([0-9]+-)?[0-9]{1,2}:[0-9]{2}:[0-9]{2}$ ]] && return 1
    [[ ! $2 =~ ^([0-9]+-)?[0-9]{1,2}:[0-9]{2}:[0-9]{2}$ ]] && return 1
    local first second
    first="$1"; second="$2"
    [[ ! $first =~ ^[0-9]+- ]] && first="0-$first"
    [[ ! $second =~ ^[0-9]+- ]] && second="0-$second"
    if [ ${first%%-*} -gt ${second%%-*} ]; then
        printf "$1"; return 0
    elif [ ${first%%-*} -lt ${second%%-*} ]; then
        printf "$2"; return 0
    else
        first=${first##*-}; second=${second##*-}
        if [ $(cut -d':' -f1 <<< "$first") -gt $(cut -d':' -f1 <<< "$second") ]; then
            printf "$1"; return 0
        elif [ $(cut -d':' -f1 <<< "$first") -lt $(cut -d':' -f1 <<< "$second") ]; then
            printf "$2"; return 0
        else
            if [ $(cut -d':' -f2 <<< "$first") -gt $(cut -d':' -f2 <<< "$second") ]; then
                printf "$1"; return 0
            elif [ $(cut -d':' -f2 <<< "$first") -lt $(cut -d':' -f2 <<< "$second") ]; then
                printf "$2"; return 0
            else
                if [ $(cut -d':' -f3 <<< "$first") -gt $(cut -d':' -f3 <<< "$second") ]; then
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
    [ "$largest" = '' ] && return 1
    [ "$1" = "$largest" ] && printf "$2" || printf "$1"
    return 0
}

function MinimumOfArray()
{
    local MIN=$1; shift
    while [ $# -gt 0 ]; do
        if [ $(awk '{print ($1<$2)}' <<< "$1 $MIN") -eq 1 ]; then
            MIN=$1
        fi
        shift
    done
    printf "$MIN"
}

function KeyOfMinimumOfArray()
{
    local COUNTER=0
    local KEY_AT_MIN=0
    local MIN=$1; shift
    while [ $# -ne 0 ]; do
        (( COUNTER++ ))
        if [ $(awk '{print ($1<$2)}' <<< "$1 $MIN") -eq 1 ]; then
            MIN=$1
            KEY_AT_MIN=$COUNTER
        fi
        shift
    done
    printf "$KEY_AT_MIN"
}

function MaximumOfArray()
{
    local MAX=$1; shift
    while [ $# -gt 0 ]; do
        if [ $(awk '{print ($1>$2)}' <<< "$1 $MAX") -eq 1 ]; then
            MAX=$1
        fi
        shift
    done
    printf "$MAX"
}

function KeyOfMaximumOfArray()
{
    local COUNTER=0
    local KEY_AT_MAX=0
    local MAX=$1; shift
    while [ $# -gt 0 ]; do
        (( COUNTER++ ))
        if [ $(awk '{print ($1>$2)}' <<< "$1 $MAX") -eq 1 ]; then
            MAX=$1
            KEY_AT_MAX=$COUNTER
        fi
        shift
    done
    printf "$KEY_AT_MAX"
}

function FindPositionOfFirstMinimumOfArray()
{
    local ARRAY_TMP=("$@")
    local ARRAY=("$@")
    local MIN=$(MinimumOfArray "${ARRAY_TMP[@]}")
    for (( i=0; i<${#ARRAY[@]}; i++ )); do
        if [ "${ARRAY[$i]}" = "${MIN}" ]; then
            printf "$i";
            break
        fi
    done
}

function LengthOfLongestEntryInArray()
{
    local LENGTH_MAX=${#1}; shift
    while [ $# -gt 0 ]; do
        if [ ${#1} -gt $LENGTH_MAX ]; then
            LENGTH_MAX=${#1}
        fi
        shift
    done
    printf "$LENGTH_MAX"
}


function ElementInArray()
{
    #Remember in BASH 0 means true and >0 means false
    local ELEMENT
    for ELEMENT in "${@:2}"; do [[ "$ELEMENT" == "$1" ]] && return 0; done
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
    if eval '[ ${'$ARRAY'[$KEY]+isSet} ]'; then
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
    awk -v value="$VALUE" 'BEGIN{RS=" "} \
                           NR==1{result=$1; difference=sqrt(($1-value)^2)} \
                           NR>1{if(sqrt(($1-value)^2)<difference){result=$1; difference=sqrt(($1-value)^2)}} \
                           END{print result}' <<< "${ARRAY[@]}"
}

function PrintArray()
{
    local NAME_OF_THE_ARRAY="$1[@]"
    local ARRAY_CONTENT=( "${!NAME_OF_THE_ARRAY}" )
    [ ${#ARRAY_CONTENT[@]} -eq 0 ] && printf "Array $1 is empty or undeclared!\n" && return 1
    local ARRAY_DECLARATION=$(declare -p "$1")
    if [[ $ARRAY_DECLARATION =~ ^declare\ -a ]]; then # normal array
        for INDEX in "${!ARRAY_CONTENT[@]}"; do
            printf "$1[$INDEX]=${ARRAY_CONTENT[$INDEX]}\n"
        done
        return 0
    elif [[ $ARRAY_DECLARATION =~ ^declare\ -A ]]; then # associative array
        eval "declare -A ARRAY=${ARRAY_DECLARATION#*=}"
        for INDEX in "${!ARRAY[@]}"; do
            printf "%s\n" "$1[\"$INDEX\"]=${ARRAY[$INDEX]}"
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
        {print human($1)}' <<< "$BYTES"
}
