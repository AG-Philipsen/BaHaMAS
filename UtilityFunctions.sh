#Collections of common operations

function TimeToSeconds(){
    local T=$1; shift
    echo $((10#${T:0:2} * 3600 + 10#${T:3:2} * 60 + 10#${T:6:2})) 
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

function ElementInArray() {
    #Remember in BASH 0 means true and >0 means false
    local ELEMENT
    for ELEMENT in "${@:2}"; do [[ "$ELEMENT" == "$1" ]] && return 0; done
    return 1
}