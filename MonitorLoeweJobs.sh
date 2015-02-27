#!/bin/bash

# This script is intended to parse the result of the command
# squeue on the LOEWE together to scontrol show job, in order
# to give to the user a more readable status of the submitted
# jobs.

source $HOME/Script/UtilityFunctions.sh || exit -2

JOBID_ARRAY=( $(squeue | awk 'NR>1{print $1}') )
JOBNAME=()
JOBSTATUS=()
JOBSTARTTIME=()
JOBSUBTIME=()
JOBSUBFROM=()
JOBNUMNODES=()
JOBFIRSTNODE=()
JOBWALLTIME=()

for JOBID in ${JOBID_ARRAY[@]}; do
	
    JOBNAME+=( $(scontrol show job $JOBID | grep "Name=" | sed "s/^.*Name=\(.*$\)/\1/") )
    JOBSTATUS+=( $(scontrol show job $JOBID | grep "^[[:blank:]]*JobState=" | sed "s/^.*JobState=\([[:alpha:]]*[[:blank:]]\).*$/\1/") )
    JOBSTARTTIME+=( $(scontrol show job $JOBID | grep "^[[:blank:]]*StartTime=" | sed "s/^.*StartTime=\(.*[[:blank:]]\).*$/\1/") )
    JOBSUBTIME+=( $(scontrol show job $JOBID | grep "^[[:blank:]]*SubmitTime=" | sed "s/^.*SubmitTime=\(.*[[:blank:]]\).*$/\1/") )
    JOBSUBFROM+=( $(scontrol show job $JOBID | grep "WorkDir=" | sed "s/^.*WorkDir=\(.*$\)/\1/") )
    JOBNUMNODES+=( $(scontrol show job $JOBID | grep "NumNodes=" | sed "s/^.*NumNodes=\([[:digit:]]*\).*$/\1/") )
    JOBWALLTIME+=( $(scontrol show job $JOBID | grep "TimeLimit=" | sed "s/^.*TimeLimit=\([[:digit:]]*-\?\([[:digit:]]\{2\}[:]\)\{2\}[[:digit:]]\{2\}\).*$/\1/") )
    #I do not know if this work for jobs on several nodes
    JOBFIRSTNODE+=( $(scontrol show job $JOBID | grep "[[:blank:]]\+NodeList=" | sed "s/^.*NodeList=\(.*[[:blank:]]*\).*$/\1/") ) 
   
done

for ((j=0; j<${#JOBSUBFROM[@]}; j++)); do
    if [ $(echo "${JOBSUBFROM[$j]}" | grep "$HOME" | wc -l) -eq 1 ]; then
	JOBSUBFROM[$j]="HOME"${JOBSUBFROM[$j]#$HOME}
    elif [ $(echo "${JOBSUBFROM[$j]}" | grep "/scratch/hfftheo/sciarra" | wc -l) -eq 1 ]; then
	JOBSUBFROM[$j]="WORK"${JOBSUBFROM[$j]#"/scratch/hfftheo/sciarra"}
    elif [ $(echo "${JOBSUBFROM[$j]}" | grep "/data01/hfftheo/sciarra" | wc -l) -eq 1 ]; then
	JOBSUBFROM[$j]="DATA01"${JOBSUBFROM[$j]#"/data01/hfftheo/sciarra"}
    fi
done


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
done

TABLE_FORMAT="%-8s%-5s%-$((2+${#LONGEST_NAME}))s%-5s%-20s%-5s%-19s%-5s%+12s%-5s%-s"

printf "\n\e[0;36m"
for (( c=1; c<=$(($(tput cols)-3)); c++ )); do printf "="; done
printf "\e[0m\n"
printf "\e[0;34m\e[2m$TABLE_FORMAT\e[0m\n"   "JOBID:" ""   "  JOB NAME:" ""   "STATUS:" ""   "START TIME:" ""   "WALLTIME:" ""   "SUBMITTED FROM:"

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
                                    "${JOBSTARTTIME[$i]}" ""\
                                    "${JOBWALLTIME[$i]}" ""\
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
    unset JOBSUBTIME[$i]; JOBSUBTIME=( "${JOBSUBTIME[@]}" )
    unset JOBSUBFROM[$i]; JOBSUBFROM=( "${JOBSUBFROM[@]}" )
    unset JOBNUMNODES[$i]; JOBNUMNODES=( "${JOBNUMNODES[@]}" )
    unset JOBFIRSTNODE[$i]; JOBFIRSTNODE=( "${JOBFIRSTNODE[@]}" )
    unset JOBWALLTIME[$i]; JOBWALLTIME=( "${JOBWALLTIME[@]}" )
    
done

printf "\n\e[2;34m  Total number of submitted jobs: $TOTAL_JOBS"
printf " (\e[2;32m\e[2mRunning: $RUNNING_JOBS  \e[0m - \e[2;31m\e[1m  Pending: $PENDING_JOBS  \e[0m - \e[0;35m\e[2m"
printf "  Others: $(($TOTAL_JOBS-$RUNNING_JOBS-$PENDING_JOBS))\e[2;34m)\n"
printf "\e[0;36m"
for (( c=1; c<=$(($(tput cols)-3)); c++ )); do printf "="; done
printf "\e[0m\n\n"
