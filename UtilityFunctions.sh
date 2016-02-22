#Collections of common operations
#
# TODO: Implement checks on parameters to functions

function TimeToSeconds(){
    local T=$1; shift
    echo $((10#${T:0:2} * 3600 + 10#${T:3:2} * 60 + 10#${T:6:2})) 
}

function SecondsToTime(){
    local T=$1; shift
    local hours=$(( $T/3600 ))
    local minutes=$(( ($T - $hours*3600)/60 ))
    local seconds=$( echo $T | awk 'END{print $1 % 60}')
    printf "%02d:%02d:%02d" "${hours}" "${minutes}" "${seconds}"
}

function SecondsToTimeString(){
    local T=$1; shift
    local hours=$(( $T/3600 ))
    local minutes=$(( ($T - $hours*3600)/60 ))
    local seconds=$( echo $T | awk 'END{print $1 % 60}')
    printf "%02dh %02dm %02ds"  "${hours}" "${minutes}" "${seconds}"
}

function TimeStringToSecond(){ 
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
    echo "$TOTAL_TIME_IN_SECONDS"
}

function SecondsToTimeStringWithDays(){
    local T=$1; shift
    local days=$(( $T/86400))
    local hours=$(( ($T - $days*86400)/3600 ))
    local minutes=$(( ($T - $days*86400 - $hours*3600)/60 ))
    local seconds=$( echo $T | awk 'END{print $1 % 60}')
    printf "%d-%02d:%02d:%02d" "${days}" "${hours}" "${minutes}" "${seconds}"
}

function MinimumOfArray(){
    local MIN=$1; shift
    while [ "$1" != "" ]; do
	if [ $(echo "$1 $MIN" | awk '{if($1<$2){print 1}else{print 0}}') -eq 1 ]; then
	    MIN=$1
	fi
	shift
    done
    echo "$MIN"
}

function FindPositionOfFirstMinimumOfArray(){
    local ARRAY_TMP=("$@")
    local ARRAY=("$@")
    local MIN=$(MinimumOfArray "${ARRAY_TMP[@]}")
    for (( i=0; i<${#ARRAY[@]}; i++ )); do
	if [ "${ARRAY[$i]}" = "${MIN}" ]; then
	    echo $i;
	    break
	fi
    done
}

function LengthOfLongestEntryInArray(){
    local LENGTH_MAX=${#1}; shift
    while [ "$1" != "" ]; do
	if [ ${#1} -gt $LENGTH_MAX ]; then
	    LENGTH_MAX=${#1}
	fi
	shift
    done
    echo "$LENGTH_MAX"
}


function ElementInArray() {
    #Remember in BASH 0 means true and >0 means false
    local ELEMENT
    for ELEMENT in "${@:2}"; do [[ "$ELEMENT" == "$1" ]] && return 0; done
    return 1
}

function KeyInArray() {
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

function FindValueOfClosestElementInArrayToGivenValue(){
    local VALUE=$1
    shift
    local ARRAY=( $@ )
    echo ${ARRAY[@]} | awk -v value="$VALUE" 'BEGIN{RS=" "} \
                                              NR==1{result=$1; difference=sqrt(($1-value)^2)} \
                                              NR>1{if(sqrt(($1-value)^2)<difference){result=$1; difference=sqrt(($1-value)^2)}} \
                                              END{print result}'
}

function PrintArray(){
    local NAME_OF_THE_ARRAY=$1
    local INDEX=""
    [ $(eval echo "\${#$NAME_OF_THE_ARRAY[@]}") -eq 0 ] && echo "Array $NAME_OF_THE_ARRAY is empty!" && return
    for INDEX in $(eval echo "\${!$NAME_OF_THE_ARRAY[@]}"); do
	echo "$NAME_OF_THE_ARRAY[$INDEX]=$(eval echo "\${$NAME_OF_THE_ARRAY[$INDEX]}")"
    done
}

