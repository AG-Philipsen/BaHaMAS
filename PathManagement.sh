#!/bin/bash

# This script is supposed to be the ONLY place where to store the path
# convention used in all the other scripts. Basically this is the best
# way to work in a general way without to much effort. Even if in our
# project we agree on a common scheme to save data, it is far better
# to be able to adapt to other schemes without any problem. This of
# course would imply some adjustment of the scripts that, nevertheless,
# are ALL here in this file collected.
#
# NOTE: Since we have 4 parameters (kappa, mu, ns, nt), in principle there
#       are 4!=24 possible orders. Here we fix the order using an array.
#
# NOTE: Variables are written with capital letters and underscores, name
#       of functions with only capital initial letter of each word and no
#       underscores.
# 
# ATTENTION: The path management should be such that both Wilson and Staggered
#            code can be handled at the same time. This is achieved anywhere
#            according to the variables WILSON and STAGGERED set respectively
#            to "TRUE" or "FALSE". It can be thought that this is an overhead
#            since in principle a single variable would be enough, but actually
#            it increases readability of the code and this approach is open to
#            future new cases.

#Setting of the correct case based on the path.
STAGGERED="FALSE"
WILSON="FALSE"
[ $(grep "[sS]taggered" <<< "$PWD" | wc -l) -gt 0 ] && STAGGERED="TRUE"
[ $(grep "[wW]ilson" <<< "$PWD" | wc -l) -gt 0 ] && WILSON="TRUE"

# Global variables:
CHEMPOT_PREFIX="mui"
[ $WILSON = "TRUE" ] && KAPPA_PREFIX="k" || KAPPA_PREFIX="mass"
NTIME_PREFIX="nt"
NSPACE_PREFIX="ns"
CHEMPOT_POSITION=0
KAPPA_POSITION=1
NTIME_POSITION=2
NSPACE_POSITION=3
CHEMPOT=""
KAPPA=0
NSPACE=0
NTIME=0
PARAMETERS_PATH=""
PARAMETERS_STRING=""
BETA_PREFIX="b"
SEED_PREFIX="s"
BETA_POSTFIX=""

#----------ADDED BY CHRIS FOR LISTSTATUS FUNCTIONALITY--------
#TODO: Discuss with Alessandro about leaving it here or not!

BETA_POSITION=4
KAPPA_REGEX='[[:digit:]]\{4\}'
NTIME_REGEX='[[:digit:]]'
NSPACE_REGEX='[[:digit:]]\{2\}'
BETA_REGEX='[[:digit:]]\.[[:digit:]]\{4\}'
#-------------------------------------------------------------


# Global functions

function CheckWilsonStaggeredVariables(){
    if [ "$WILSON" == "$STAGGERED" ]; then
        printf "\n\e[0;31m Variables WILSON and STAGGERED both set to the same value (please check the position from where the script was run)! Aborting...\n\n\e[0m"
        exit -1
    fi
}


function SetParametersPathAndString(){
    if [ $NSPACE -eq 0 ] || [ $NTIME -eq 0 ] || [[ $CHEMPOT == "" ]] || { [ $KAPPA -eq 0 ] && [ $WILSON = "FALSE" ]; }; then
	    echo "Unable to SetParametersPath! Aborting..."
        exit -1
    fi
    local PREFIXES=([$CHEMPOT_POSITION]=$CHEMPOT_PREFIX [$KAPPA_POSITION]=$KAPPA_PREFIX [$NTIME_POSITION]=$NTIME_PREFIX [$NSPACE_POSITION]=$NSPACE_PREFIX)
    local PARAMETERS_VALUE=([$CHEMPOT_POSITION]=$CHEMPOT [$KAPPA_POSITION]=$KAPPA [$NTIME_POSITION]=$NTIME [$NSPACE_POSITION]=$NSPACE)
    for ((i=0; i<${#PREFIXES[@]}; i++)); do    
	PARAMETERS_PATH="$PARAMETERS_PATH/${PREFIXES[$i]}${PARAMETERS_VALUE[$i]}"
	PARAMETERS_STRING="$PARAMETERS_STRING${PREFIXES[$i]}${PARAMETERS_VALUE[$i]}_"
    done
    PARAMETERS_STRING=${PARAMETERS_STRING%?} #Remove last underscore
}

function ReadParametersFromPath(){
    local PREFIXES=([$CHEMPOT_POSITION]=$CHEMPOT_PREFIX [$KAPPA_POSITION]=$KAPPA_PREFIX [$NTIME_POSITION]=$NTIME_PREFIX [$NSPACE_POSITION]=$NSPACE_PREFIX)
    local PARAMETERS_VALUE=()
    #Path given as first argument to this function
    local PATH_TO_BE_USED="/$1/" #Add in front and back a "/" just to be general in the search
    for ((i=0; i<${#PREFIXES[@]}; i++)); do
	if [ $(echo $PATH_TO_BE_USED | grep -o "/${PREFIXES[$i]}" | wc -l) -ne 1 ]; then
	    printf "\e[0;31m Unable to recover \"${PREFIXES[$i]}\" from the path \"$1\". Aborting...\n\n\e[0m"
            exit -1
	fi
	PARAMETERS_VALUE[$i]=$(echo "$PATH_TO_BE_USED" | awk -v expr="${PREFIXES[$i]}" \
                                                            -v expr_len=${#PREFIXES[$i]} \
                                                           '{print substr($0, index($0, "/"expr) + expr_len + 1, index(substr($0, index($0, "/"expr) + expr_len+1), "/") - 1)}')
    done
    CHEMPOT=${PARAMETERS_VALUE[$CHEMPOT_POSITION]}
    KAPPA=${PARAMETERS_VALUE[$KAPPA_POSITION]}
    NTIME=${PARAMETERS_VALUE[$NTIME_POSITION]}
    NSPACE=${PARAMETERS_VALUE[$NSPACE_POSITION]}
    #Check that the recovered parameter makes sense
    if [[ ! $KAPPA =~ ^[[:digit:]]{4}$ ]]; then
	printf "\n\e[0;31m Parameter \"$KAPPA_PREFIX\" from the path \"$1\" not allowed! Aborting...\n\n\e[0m"
	exit -1
    elif [[ ! $NTIME =~ ^[[:digit:]]{1,2}$ ]]; then
	printf "\n\e[0;31m Parameter \"$NTIME_PREFIX\" from the path \"$1\" not allowed! Aborting...\n\n\e[0m"
	exit -1
    elif [[ ! $NSPACE =~ ^[[:digit:]]{1,2}$ ]]; then
	printf "\n\e[0;31m Parameter \"$NSPACE_PREFIX\" from the path \"$1\" not allowed! Aborting...\n\n\e[0m"
	exit -1
    fi
    #Set parameters path
    SetParametersPathAndString
}

function CheckSingleOccurrenceInPath(){
    for var in $@; do
	Var=$(echo $(pwd) | grep -o "$var" | wc -l)
	if [ $Var -ne 1 ] ; then
	    printf "\n\e[0;31m The string \"$var\" must occur once and only once in the path! Aborting...\n\n\e[0m" 
	    exit 1
	fi
    done
}









