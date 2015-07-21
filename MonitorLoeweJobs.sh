#!/bin/bash

# This script is intended to parse the result of the command
# squeue on the LOEWE and or L-CSC together to scontrol show job, in order
# to give to the user a more readable status of the submitted jobs.

source $HOME/Script/UtilityFunctions.sh || exit -2

function ParseCommandLineOptions(){

    while [ "$1" != "" ]; do
        case $1 in
        -h | --help )
            printf "\n\e[0;32m"
            echo "Call the script $0 with the following optional arguments:"
            echo "  -h | --help"
            echo "  -u | --user      ->    user for which jobs should be displayed (DEFAULT = $(whoami))"
            echo "  -a | --allUsers  ->    display jobs information for all users"
            echo -e "\n\e[0;35mNOTE: If the option -a is given, then the -u one is ignored!\e[0m"
            printf "\n\e[0m"
            exit
            shift;;
        -u=* | --user=* )         SELECTED_USER=${1#*=}; shift ;;
        -a | --allUsers )         DISPLAY_ALL_JOBS="TRUE"; shift ;;
        * ) printf "\n\e[0;31mError parsing the options! Aborting...\n\n\e[0m" ; exit -1 ;;
        esac
    done

}

function ExtractParameterFromJobInformations(){
    local JOB_ID_NUMBER="$1"
    local PARAMETER_NAME="$2"
    PARAMETER_VALUE=$(scontrol show job $JOBID | sed -n 's@.*'${PARAMETER_NAME}'=\([^[:space:]]*\).*@\1@p')
    echo "$PARAMETER_VALUE"
}


#-----------------------------------------------------------------------------------------------#

SELECTED_USER="$(whoami)"
DISPLAY_ALL_JOBS="FALSE"

ParseCommandLineOptions $@

if [ $DISPLAY_ALL_JOBS = "FALSE" ]; then
    JOBID_ARRAY=( $(squeue | awk -v username="$SELECTED_USER" 'NR>1{if($4 == username){print $1}}') )
else
    JOBID_ARRAY=( $(squeue | awk 'NR>1{print $1}') )
fi
JOBNAME=()
JOBSTATUS=()
JOBSTARTTIME=()
JOBENDTIME=()
JOBSUBTIME=()
JOBSUBFROM=()
JOBNUMNODES=()
JOBFIRSTNODE=()
JOBWALLTIME=()
JOBRUNTIME=()

for JOBID in ${JOBID_ARRAY[@]}; do

    JOBNAME+=( $(ExtractParameterFromJobInformations $JOBID "Name") )
    JOBSTATUS+=( $(ExtractParameterFromJobInformations $JOBID "JobState") )
    JOBSTARTTIME+=( $(ExtractParameterFromJobInformations $JOBID "StartTime") )
    JOBSUBTIME+=( $(ExtractParameterFromJobInformations $JOBID "SubmitTime") )
    JOBENDTIME+=( $(ExtractParameterFromJobInformations $JOBID "EndTime") )
    JOBSUBFROM+=( $(ExtractParameterFromJobInformations $JOBID "WorkDir") )
    JOBNUMNODES+=( $(ExtractParameterFromJobInformations $JOBID "NumNodes") )
    JOBWALLTIME+=( $(ExtractParameterFromJobInformations $JOBID "TimeLimit") )
    JOBRUNTIME+=( $(ExtractParameterFromJobInformations $JOBID "RunTime") )
    #I do not know if this work for jobs on several nodes
    JOBFIRSTNODE+=( $(ExtractParameterFromJobInformations $JOBID "[[:space:]]NodeList") ) #Space before NodeList is crucial because there are also ReqNodeList and ExcNodeList

done

HOME_DIR=${HOME}
WORK_DIR="/home/hfftheo/$(whoami)"
DATA1_DIR="/data01/hfftheo/$(whoami)"
DATA2_DIR="/data02/hfftheo/$(whoami)"
for ((j=0; j<${#JOBSUBFROM[@]}; j++)); do
    JOBSUBFROM[$j]=${JOBSUBFROM[$j]/$HOME_DIR/HOME}
    JOBSUBFROM[$j]=${JOBSUBFROM[$j]/$WORK_DIR/WORK}
    JOBSUBFROM[$j]=${JOBSUBFROM[$j]/$DATA1_DIR/DATA01}
    JOBSUBFROM[$j]=${JOBSUBFROM[$j]/$DATA2_DIR/DATA02}
done
unset -v 'HOME_DIR' 'WORK_DIR' 'DATA1_DIR' 'DATA2_DIR'

#Some counting for the table 
LONGEST_NAME=${JOBNAME[0]}
for NAME in ${JOBNAME[@]}; do
    if [ ${#NAME} -gt ${#LONGEST_NAME} ]; then
        LONGEST_NAME=$NAME
    fi
done
RUNNING_JOBS=0
PENDING_JOBS=0
TOTAL_JOBS=${#JOBID_ARRAY[@]}
for ((j=0; j<${#JOBSTATUS[@]}; j++)); do
    if [[ ${JOBSTATUS[$j]} == "RUNNING" ]]; then
        RUNNING_JOBS=$(($RUNNING_JOBS + 1))
    elif [[ ${JOBSTATUS[$j]} == "PENDING" ]]; then
        PENDING_JOBS=$(($PENDING_JOBS + 1))
    fi
done && unset -v 'j'
OTHER_JOBS=$(($TOTAL_JOBS-$RUNNING_JOBS-$PENDING_JOBS))

#Table header
COLUMNS_OF_THE_SHELL=$(tput cols)
TABLE_FORMAT="%-8s%-5s%-$((2+${#LONGEST_NAME}))s%-5s%-25s%-5s%-19s%-5s%+14s%-5s%-s"
printf "\n\e[1;36m"
for (( c=1; c<=$(($COLUMNS_OF_THE_SHELL-3)); c++ )); do printf "="; done && unset -v 'c'
printf "\e[0m\n"
printf "\e[38;5;202m$TABLE_FORMAT\e[0m\n"   "JOBID:" ""   "  JOB NAME:" ""   "STATUS:" ""   "START/END TIME:" ""   "WALL/RUNTIME:" ""   "SUBMITTED FROM:"

#Print table sorting according jobname
while [ ${#JOBNAME[@]} -gt 0 ]; do
    i=$(FindPositionOfFirstMinimumOfArray "${JOBNAME[@]}")

    if [[ ${JOBSTATUS[$i]} == "RUNNING" ]]; then
        printf "\e[0;32m"
    elif [[ ${JOBSTATUS[$i]} == "PENDING" ]]; then
        if [[ ${JOBSTARTTIME[$i]} != "Unknown" ]]; then
            printf "\e[0;33m"
        else
            printf "\e[0;31m"
        fi
    else
        printf "\e[0;35m"
    fi

    if [[ ${JOBSTATUS[$i]} == "RUNNING" ]]; then
        printf "$TABLE_FORMAT\e[0m\n"   "${JOBID_ARRAY[$i]}" ""\
                                        "  ${JOBNAME[$i]}" ""\
                                        "${JOBSTATUS[$i]} on ${JOBFIRSTNODE[$i]}" ""\
                                        "${JOBENDTIME[$i]}" ""\
                                        "${JOBRUNTIME[$i]}" ""\
                                        "${JOBSUBFROM[$i]}"
    else
        printf "$TABLE_FORMAT\e[0m\n"   "${JOBID_ARRAY[$i]}" ""\
                                        "  ${JOBNAME[$i]}" ""\
                                        "${JOBSTATUS[$i]}" ""\
                                        "${JOBSTARTTIME[$i]}" ""\
                                        "${JOBWALLTIME[$i]}" ""\
                                        "${JOBSUBFROM[$i]} on ${JOBSUBTIME[$i]}"
    fi

    unset JOBID_ARRAY[$i]; JOBID_ARRAY=( "${JOBID_ARRAY[@]}" )
    unset JOBNAME[$i]; JOBNAME=( "${JOBNAME[@]}" )
    unset JOBSTATUS[$i]; JOBSTATUS=( "${JOBSTATUS[@]}" )
    unset JOBSTARTTIME[$i]; JOBSTARTTIME=( "${JOBSTARTTIME[@]}" )
    unset JOBENDTIME[$i]; JOBENDTIME=( "${JOBENDTIME[@]}" )
    unset JOBSUBTIME[$i]; JOBSUBTIME=( "${JOBSUBTIME[@]}" )
    unset JOBSUBFROM[$i]; JOBSUBFROM=( "${JOBSUBFROM[@]}" )
    unset JOBNUMNODES[$i]; JOBNUMNODES=( "${JOBNUMNODES[@]}" )
    unset JOBFIRSTNODE[$i]; JOBFIRSTNODE=( "${JOBFIRSTNODE[@]}" )
    unset JOBWALLTIME[$i]; JOBWALLTIME=( "${JOBWALLTIME[@]}" )
    unset JOBRUNTIME[$i]; JOBRUNTIME=( "${JOBRUNTIME[@]}" )
    
done

printf "\n\e[38;5;202m  Total number of submitted jobs: $TOTAL_JOBS"
printf " (\e[1;32mRunning: $RUNNING_JOBS  \e[0m - \e[1;31m  Pending: $PENDING_JOBS  \e[0m - \e[1;35m  Others: $OTHER_JOBS\e[38;5;202m)\n"
printf "\e[1;36m"
for (( c=1; c<=$(($COLUMNS_OF_THE_SHELL-3)); c++ )); do printf "="; done && unset -v 'c'
printf "\e[0m\n\n"
