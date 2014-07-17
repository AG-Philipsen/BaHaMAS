#!/bin/bash

# This script is intended to parse the result of the command
# squeue on the LOEWE together to scontrol show job, in order
# to give to the user a more readable status of the submitted
# jobs.

JOBID_ARRAY=( $(squeue | awk 'NR>1{print $1}') )
JOBNAME=()
JOBSTATUS=()
JOBSTARTTIME=()
JOBSUBTIME=()
JOBSUBFROM=()
for JOBID in ${JOBID_ARRAY[@]}; do
	
    JOBNAME+=( $(scontrol show job $JOBID | grep "Name=" | sed "s/^.*Name=\(.*$\)/\1/") )
    JOBSTATUS+=( $(scontrol show job $JOBID | grep "^[[:blank:]]*JobState=" | sed "s/^.*JobState=\([[:alpha:]]*[[:blank:]]\).*$/\1/") )
    JOBSTARTTIME+=( $(scontrol show job $JOBID | grep "^[[:blank:]]*StartTime=" | sed "s/^.*StartTime=\(.*[[:blank:]]\).*$/\1/") )
    JOBSUBTIME+=( $(scontrol show job $JOBID | grep "^[[:blank:]]*SubmitTime=" | sed "s/^.*SubmitTime=\(.*[[:blank:]]\).*$/\1/") )
    JOBSUBFROM+=( $(scontrol show job $JOBID | grep "WorkDir=" | sed "s/^.*WorkDir=\(.*$\)/\1/") )
    
done

LONGEST_NAME=${JOBNAME[0]}
RUNNING_JOBS=0
PENDING_JOBS=0
for NAME in ${JOBNAME[@]}; do
    if [ ${#NAME} -gt ${#LONGEST_NAME} ]; then
	LONGEST_NAME=$NAME
    fi
    if [[ $JOBSTATUS == "RUNNING" ]]; then
	RUNNING_JOBS=$(($RUNNING_JOBS + 1))
    elif [[ $JOBSTATUS == "PENDING" ]]; then
	PENDING_JOBS=$(($PENDING_JOBS + 1))
    fi
done

TABLE_FORMAT="%-$((2+${#LONGEST_NAME}))s%-5s%-7s%-5s%-19s%-5s%-19s%-5s%-s"

printf "\n\e[0;36m"
for (( c=1; c<=$(($(tput cols)-3)); c++ )); do printf "="; done
printf "\e[0m\n"
printf "\e[0;34m\e[2m$TABLE_FORMAT\e[0m\n"   "  JOB NAME:" ""   "STATUS:" ""   "START TIME:" ""   "SUBMITTED ON:" ""   "SUBMITTED FROM:"

for((i=0; i<${#JOBNAME[@]}; i++)) do

    if [[ ${JOBSTATUS[$i]} == "RUNNING" ]]; then
	printf "\e[0;32m"
    elif [[ ${JOBSTARTTIME[$i]} != "Unknown" ]]; then
	printf "\e[0;33m"
    else
	printf "\e[0;31m"
    fi
    
    printf "$TABLE_FORMAT\e[0m\n"   "  ${JOBNAME[$i]}" ""   "${JOBSTATUS[$i]}" ""   "${JOBSTARTTIME[$i]}" ""   "${JOBSUBTIME[$i]}" ""   "${JOBSUBFROM[$i]}"
    
done

printf "\n\e[2;34m  Total number of submitted jobs: ${#JOBNAME[@]}"
printf " (\e[2;32m\e[2mRunning: $RUNNING_JOBS  \e[0m - \e[2;31m\e[1m  Pending: $PENDING_JOBS  \e[0m - \e[0;35m\e[2m"
printf "  Others: $((${#JOBNAME[@]}-$RUNNING_JOBS-$PENDING_JOBS))\e[2;34m)\n"
printf "\e[0;36m"
for (( c=1; c<=$(($(tput cols)-3)); c++ )); do printf "="; done
printf "\e[0m\n\n"
