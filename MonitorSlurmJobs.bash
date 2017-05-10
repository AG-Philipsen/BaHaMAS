#!/bin/bash

# This script is intended to parse the result of the command
# squeue on the LOEWE and or L-CSC together to scontrol show job, in order
# to give to the user a more readable status of the submitted jobs.

BaHaMAS_repositoryTopLevelPath="$(git -C $(dirname "${BASH_SOURCE[0]}") rev-parse --show-toplevel)" #To be removed!
source ${BaHaMAS_repositoryTopLevelPath}/UtilityFunctions.bash || exit -2

function ParseCommandLineOptions()
{

    while [ "$1" != "" ]; do
        case $1 in
            -h | --help )
                printf "\n\e[0;32m"
                printf "Call the script $0 with the following optional arguments:\n"
                printf "  -h | --help\n"
                printf "  -u | --user       ->    user for which jobs should be displayed (DEFAULT = $(whoami))\n"
                printf "  -a | --allUsers   ->    display jobs information for all users (on $CLUSTER_PARTITION partition)\n"
                printf "  -l | --local      ->    display information for jobs submitted from a folder whose path match the present directory\n"
                if [ $CLUSTER_NAME = "LCSC" ]; then
                    printf "  -n | --nodeUsage  ->    display information ONLY about which nodes are used\n"
                    printf "  -g | --groupBetas ->    display partial information grouping betas used\n"
                    printf "                          WARNING: it is useful when a single simulation per job is run,\n"
                    printf "                                   otherwise the output is incomplete!\n"
                fi
                printf "\n\e[0;35mNOTE: If the option -a is given, then the -u one is ignored!\e[0m\n"
                printf "\n\e[0m"
                exit
                shift;;
            -u=* | --user=* )    SELECTED_USER=${1#*=}; shift ;;
            -a | --allUsers )    DISPLAY_ALL_JOBS="TRUE"; shift ;;
            -l | --local )       LOCAL_JOBS="TRUE"; shift;;
            -n | --nodeUsage )   MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--nodeUsage" ); NODE_USAGE="TRUE"; DISPLAY_STANDARD_LIST='FALSE'; shift;;
            -g | --groupBetas )  MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--groupBetas" ); GROUP_BETAS="TRUE"; DISPLAY_STANDARD_LIST='FALSE'; shift;;
            * ) printf "\n\e[0;31mError parsing the options! Aborting...\n\n\e[0m" ; exit -1 ;;
        esac
    done

    if { [ $NODE_USAGE = 'TRUE' ] || [ $GROUP_BETAS = 'TRUE' ]; } && [ $CLUSTER_NAME != "LCSC" ]; then
        printf "\n\e[0;31mError parsing the options (see --help)! Aborting...\n\n\e[0m"
        exit -1
    fi

    if [ ${#MUTUALLYEXCLUSIVEOPTS_PASSED[@]} -gt 1 ]; then
        printf "\n\e[0;31m The options\n\n\e[1m"
        for OPT in "${MUTUALLYEXCLUSIVEOPTS[@]}"; do
            printf "  %s\n" "$OPT"
        done
        printf "\n\e[0;31m are mutually exclusive and must not be combined! Aborting...\n\n\e[0m"
        exit -1
    fi

}

#Unused function left here in case in future some more information is needed (for which squeue has not a format option)
function ExtractParametersFromJobInformation()
{
    local JOB_ID_NUMBER="$1"; shift
    local PARAMETERS_NAME=("$@")
    local SCONTROL_OUTPUT="$(scontrol show job $JOB_ID_NUMBER)"
    for PARAM in "${PARAMETERS_NAME[@]}"; do
        EXTRACTED_JOB_INFORMATION["$PARAM"]=$(sed -n 's@.*'${PARAM}'=\([^[:space:]]*\).*@\1@p' <<< "$SCONTROL_OUTPUT")
    done && unset -v 'PARAM'
}

#-----------------------------------------------------------------------------------------------#
#Variable for the script
CLUSTER_NAME="LOEWE"
CLUSTER_PARTITION="gpu"
if [ "$(hostname)" = "lxlcsc0001" ]; then
    CLUSTER_NAME="LCSC"
    CLUSTER_PARTITION="lcsc"
fi
MUTUALLYEXCLUSIVEOPTS=( "-n | --nodeUsage" "-g | --groupBetas" "-l | --local" )
MUTUALLYEXCLUSIVEOPTS_PASSED=( )
SELECTED_USER="$(whoami)"
DISPLAY_ALL_JOBS="FALSE"
NODE_USAGE="FALSE"
GROUP_BETAS="FALSE"
LOCAL_JOBS="FALSE"
DISPLAY_STANDARD_LIST='TRUE'

#Format codes for squeue command in order to get specific information
declare -A SQUEUE_FORMAT_CODE
SQUEUE_FORMAT_CODE["JobId"]="%i"
SQUEUE_FORMAT_CODE["Name"]="%j"
SQUEUE_FORMAT_CODE["JobState"]="%T"
SQUEUE_FORMAT_CODE["[[:space:]]NodeList"]="%N"
SQUEUE_FORMAT_CODE["SubmitTime"]="%V"
SQUEUE_FORMAT_CODE["TimeLimit"]="%l"
SQUEUE_FORMAT_CODE["StartTime"]="%S"
SQUEUE_FORMAT_CODE["RunTime"]="%M"
SQUEUE_FORMAT_CODE["EndTime"]="%e"
SQUEUE_FORMAT_CODE["WorkDir"]="%Z"
SQUEUE_FORMAT_CODE["NumNodes"]="%D"
#Space before NodeList is crucial if one wants to parse the output of scontrol show job because there are also ReqNodeList and ExcNodeList
SQUEUE_FORMAT_CODE_ORDER=("JobId" "Name" "JobState" "[[:space:]]NodeList" "SubmitTime" "TimeLimit" "StartTime" "RunTime" "EndTime" "WorkDir" "NumNodes")
for LABEL in "${SQUEUE_FORMAT_CODE_ORDER[@]}"; do
    SQUEUE_FORMAT_CODE_STRING="${SQUEUE_FORMAT_CODE_STRING}@${SQUEUE_FORMAT_CODE[$LABEL]}"
done

#-----------------------------------------------------------------------------------------------#
#Common part of script options
ParseCommandLineOptions $@

#Get information via squeue and in case filter jobs -> ATTENTION: Double quoting here is CRUCIAL (to respect endlines)!!
#NOTE: It seems that the sacct command can give a similar result, but at the moment there is no analog to the %Z field.
if [ $DISPLAY_ALL_JOBS = 'TRUE' ]; then
    SQUEUE_OUTPUT="$(squeue --noheader -p $CLUSTER_PARTITION -o ${SQUEUE_FORMAT_CODE_STRING:1} 2>/dev/null)"
else
    SQUEUE_OUTPUT="$(squeue --noheader -u $SELECTED_USER -o "${SQUEUE_FORMAT_CODE_STRING:1}" 2>/dev/null)"
fi

#The following if is a workaround for Loewe where squeue is old and %Z and %V are not available in the format! TODO: Remove as soon as possible.
if [ $CLUSTER_NAME = 'LOEWE' ] && [ "$SQUEUE_OUTPUT" != "" ]; then
    JOB_SUBMISSION_FOLDER=""
    JOB_SUBMISSION_TIME=""
    for ID in $(cut -d'@' -f1  <<< "$SQUEUE_OUTPUT"); do
        declare -A EXTRACTED_JOB_INFORMATION
        ExtractParametersFromJobInformation "$ID" "WorkDir" "SubmitTime"
        JOB_SUBMISSION_FOLDER="${JOB_SUBMISSION_FOLDER}|${ID}@${EXTRACTED_JOB_INFORMATION[WorkDir]}"
        JOB_SUBMISSION_TIME="${JOB_SUBMISSION_TIME}|${ID}@${EXTRACTED_JOB_INFORMATION[SubmitTime]}"
        unset -v 'EXTRACTED_JOB_INFORMATION'
    done && unset 'ID'
    SQUEUE_OUTPUT=$(awk --posix -v subFolder="${JOB_SUBMISSION_FOLDER:1}" \
                        -v subTime="${JOB_SUBMISSION_TIME:1}" '
                                BEGIN{
                                    split(subFolder, tmpSubFold, "|")
                                    split(subTime, tmpSubTime, "|")
                                    for(i in tmpSubFold){
                                        split(tmpSubFold[i], resultFold, "@")
                                        jobSubmissionFolder[resultFold[1]]=resultFold[2]
                                        split(tmpSubTime[i], resultTime, "@")
                                        jobSubmissionTime[resultTime[1]]=resultTime[2]
                                    }
                                    FS="@"
                                    OFS="@"
                                }
                                {
                                    $5=jobSubmissionTime[$1]
                                    $10=jobSubmissionFolder[$1]
                                    print $0
                                }
    ' <<< "$SQUEUE_OUTPUT")
    unset -v 'JOB_SUBMISSION_FOLDER' 'JOB_SUBMISSION_TIME'
fi

if [ $LOCAL_JOBS = 'TRUE' ]; then
    SQUEUE_OUTPUT="$(grep --color=never "${PWD}" <<< "$SQUEUE_OUTPUT")"
fi

#If any field is empty, fill it with empty word in order to have later all arrays with same number of elements
SQUEUE_OUTPUT=$(sed "s/@@/@empty@/g" <<< "$SQUEUE_OUTPUT")

#Split squeue output and prepare table layout
JOB_ID=(                $(cut -d'@' -f1  <<< "$SQUEUE_OUTPUT") )
JOB_NAME=(              $(cut -d'@' -f2  <<< "$SQUEUE_OUTPUT") )
JOB_STATUS=(            $(cut -d'@' -f3  <<< "$SQUEUE_OUTPUT") )
JOB_NODELIST=(          $(cut -d'@' -f4  <<< "$SQUEUE_OUTPUT") )
JOB_SUBMISSION_TIME=(   $(cut -d'@' -f5  <<< "$SQUEUE_OUTPUT") )
JOB_WALLTIME=(          $(cut -d'@' -f6  <<< "$SQUEUE_OUTPUT") )
JOB_START_TIME=(        $(cut -d'@' -f7  <<< "$SQUEUE_OUTPUT") )
JOB_RUNTIME=(           $(cut -d'@' -f8  <<< "$SQUEUE_OUTPUT") )
JOB_END_TIME=(          $(cut -d'@' -f9  <<< "$SQUEUE_OUTPUT") )
JOB_SUBMISSION_FOLDER=( $(cut -d'@' -f10 <<< "$SQUEUE_OUTPUT") )
JOB_NUM_NODES=(         $(cut -d'@' -f11 <<< "$SQUEUE_OUTPUT") )

if [ $CLUSTER_NAME = 'LOEWE' ]; then
    HOME_DIR=${HOME}
    WORK_DIR="/home/hfftheo/$SELECTED_USER"
    DATA1_DIR="/data01/hfftheo/$SELECTED_USER"
    DATA2_DIR="/data02/hfftheo/$SELECTED_USER"
else
    HOME_DIR=${HOME}
    WORK_DIR="/lustre/nyx/lcsc/$SELECTED_USER"
fi

for ((j=0; j<${#JOB_SUBMISSION_FOLDER[@]}; j++)); do
    JOB_SUBMISSION_FOLDER[$j]=${JOB_SUBMISSION_FOLDER[$j]/$HOME_DIR/HOME}
    JOB_SUBMISSION_FOLDER[$j]=${JOB_SUBMISSION_FOLDER[$j]/$WORK_DIR/SCRATCH}
    JOB_SUBMISSION_FOLDER[$j]=${JOB_SUBMISSION_FOLDER[$j]/$DATA1_DIR/DATA01}
    JOB_SUBMISSION_FOLDER[$j]=${JOB_SUBMISSION_FOLDER[$j]/$DATA2_DIR/DATA02}
done && unset -v 'HOME_DIR' 'WORK_DIR' 'DATA1_DIR' 'DATA2_DIR'

#Some counting for the table
LONGEST_NAME=${JOB_NAME[0]}
for NAME in ${JOB_NAME[@]}; do
    if [ ${#NAME} -gt ${#LONGEST_NAME} ]; then
        LONGEST_NAME=$NAME
    fi
done
RUNNING_JOBS=0
PENDING_JOBS=0
TOTAL_JOBS=${#JOB_ID[@]}
for ((j=0; j<${#JOB_STATUS[@]}; j++)); do
    if [[ ${JOB_STATUS[$j]} == "RUNNING" ]]; then
        RUNNING_JOBS=$(($RUNNING_JOBS + 1))
    elif [[ ${JOB_STATUS[$j]} == "PENDING" ]]; then
        PENDING_JOBS=$(($PENDING_JOBS + 1))
    fi
done && unset -v 'j'
OTHER_JOBS=$(($TOTAL_JOBS-$RUNNING_JOBS-$PENDING_JOBS))


#------------------------------------------------------------------------------------------------------------------------------------------------#
# If node usage is required just execute this code and exit
if [ $NODE_USAGE = "TRUE" ]; then
    declare -A USED_NODES
    #Counting
    for NODE in ${JOB_NODELIST[@]}; do
        USED_NODES[$NODE]="${USED_NODES[$NODE]}+"
    done
    #Printing
    printf "\n\e[1;36m"
    for (( c=1; c<=85; c++ )); do printf "="; done && unset -v 'c'
    printf "\e[0m\n"

    printf "\e[38;5;13m%-15s%-10s\n\e[0m" "NODE" "RUNNING_JOBS"
    for NODE in ${!USED_NODES[@]}; do
        printf "\e[38;5;39m%-15s\e[38;5;10m%-10s\e[38;5;49m%d\e[0m\n" "${NODE}" "${USED_NODES[$NODE]}" "$(grep -o '+' <<< "${USED_NODES[$NODE]}" | wc -l)"
    done | sort -h

    printf "\n\e[38;5;202m  Total number of submitted jobs: $TOTAL_JOBS"
    printf " (\e[1;32mRunning: $RUNNING_JOBS  \e[0m - \e[1;31m  Pending: $PENDING_JOBS  \e[0m - \e[1;35m  Others: $OTHER_JOBS\e[38;5;202m)\n"
    printf "\e[1;36m"
    for (( c=1; c<=85; c++ )); do printf "="; done && unset -v 'c'
    printf "\e[0m\n\n"
    exit 0
fi

#------------------------------------------------------------------------------------------------------------------------------------------------#

#------------------------------------------------------------------------------------------------------------------------------------------------#
# If group betas is required just execute this code and exit
if [ $GROUP_BETAS = "TRUE" ]; then
    declare -A JOB_PARAMETERS
    declare -A SEEDS_STATUS
    #Counting
    for INDEX in ${!JOB_NAME[@]}; do
        NAME=${JOB_NAME[$INDEX]}
        JOB_PARAMETERS[${NAME%%_s*}]="${JOB_PARAMETERS[${NAME%%_s*}]} ${NAME##*_s}"
        if [ ${JOB_STATUS[$INDEX]} = "RUNNING" ]; then
            SEEDS_STATUS[${NAME%%_s*}]="${SEEDS_STATUS[${NAME%%_s*}]} \e[38;5;10m${JOB_STATUS[$INDEX]:0:1}\e[0m"
        elif [ ${JOB_STATUS[$INDEX]} = "PENDING" ]; then
            if [ ${JOB_START_TIME[$i]} != "Unknown" ]; then
                SEEDS_STATUS[${NAME%%_s*}]="${SEEDS_STATUS[${NAME%%_s*}]} \e[38;5;11m${JOB_STATUS[$INDEX]:0:1}\e[0m"
            else
                SEEDS_STATUS[${NAME%%_s*}]="${SEEDS_STATUS[${NAME%%_s*}]} \e[38;5;9m${JOB_STATUS[$INDEX]:0:1}\e[0m"
            fi
        else
            SEEDS_STATUS[${NAME%%_s*}]="${SEEDS_STATUS[${NAME%%_s*}]} \e[38;5;13m${JOB_STATUS[$INDEX]:0:1}\e[0m"
        fi
    done
    #Printing
    printf "\n\e[1;36m"
    for (( c=1; c<=85; c++ )); do printf "="; done && unset -v 'c'
    printf "\e[0m\n"

    printf "\e[38;5;4m%-40s%-30s%s\n\e[0m" "JOB_PARAMETERS" "QUEUED_SEEDS" "STATUS"
    for NAME in ${!JOB_PARAMETERS[@]}; do
        printf "\e[38;5;14m%-40s\e[38;5;13m%-30s${SEEDS_STATUS[$NAME]:1}\e[0m\n" "${NAME}" "${JOB_PARAMETERS[$NAME]:1}"
    done | sort -h

    printf "\n\e[38;5;202m  Total number of submitted jobs: $TOTAL_JOBS"
    printf " (\e[1;32mRunning: $RUNNING_JOBS  \e[0m - \e[1;31m  Pending: $PENDING_JOBS  \e[0m - \e[1;35m  Others: $OTHER_JOBS\e[38;5;202m)\n"
    printf "\e[1;36m"
    for (( c=1; c<=85; c++ )); do printf "="; done && unset -v 'c'
    printf "\e[0m\n\n"
    exit 0
fi

#------------------------------------------------------------------------------------------------------------------------------------------------#
#Stabdard display
if [ $DISPLAY_STANDARD_LIST = "TRUE" ]; then

    #Table header
    COLUMNS_OF_THE_SHELL=$(tput cols)
    TABLE_FORMAT="%-8s%-5s%-$((2+${#LONGEST_NAME}))s%-5s%-25s%-5s%-19s%-5s%+14s%-5s%-s"
    printf "\n\e[1;36m"
    for (( c=1; c<=$(($COLUMNS_OF_THE_SHELL-3)); c++ )); do printf "="; done && unset -v 'c'
    printf "\e[0m\n"
    printf "\e[38;5;202m$TABLE_FORMAT\e[0m\n"   "JOB_ID:" ""   "  JOB NAME:" ""   "STATUS:" ""   "START/END TIME:" ""   "WALL/RUNTIME:" ""   "SUBMITTED FROM:"

    #Print table sorting according jobname
    while [ ${#JOB_NAME[@]} -gt 0 ]; do
        i=$(FindPositionOfFirstMinimumOfArray "${JOB_NAME[@]}")

        if [[ ${JOB_STATUS[$i]} == "RUNNING" ]]; then
            printf "\e[0;32m"
        elif [[ ${JOB_STATUS[$i]} == "PENDING" ]]; then
            if [[ ${JOB_START_TIME[$i]} != "N/A" ]]; then
                printf "\e[0;33m"
            else
                printf "\e[0;31m"
            fi
        else
            printf "\e[0;35m"
        fi

        if [[ ${JOB_STATUS[$i]} == "RUNNING" ]]; then
            printf "$TABLE_FORMAT\e[0m\n"   "${JOB_ID[$i]}" ""\
                   "  ${JOB_NAME[$i]}" ""\
                   "${JOB_STATUS[$i]} on ${JOB_NODELIST[$i]}" ""\
                   "${JOB_END_TIME[$i]}" ""\
                   "${JOB_RUNTIME[$i]}" ""\
                   "${JOB_SUBMISSION_FOLDER[$i]}"
        else
            printf "$TABLE_FORMAT\e[0m\n"   "${JOB_ID[$i]}" ""\
                   "  ${JOB_NAME[$i]}" ""\
                   "${JOB_STATUS[$i]}" ""\
                   "${JOB_START_TIME[$i]}" ""\
                   "${JOB_WALLTIME[$i]}" ""\
                   "${JOB_SUBMISSION_FOLDER[$i]} on ${JOB_SUBMISSION_TIME[$i]}"
        fi

        unset JOB_ID[$i]; JOB_ID=( "${JOB_ID[@]}" )
        unset JOB_NAME[$i]; JOB_NAME=( "${JOB_NAME[@]}" )
        unset JOB_STATUS[$i]; JOB_STATUS=( "${JOB_STATUS[@]}" )
        unset JOB_START_TIME[$i]; JOB_START_TIME=( "${JOB_START_TIME[@]}" )
        unset JOB_END_TIME[$i]; JOB_END_TIME=( "${JOB_END_TIME[@]}" )
        unset JOB_SUBMISSION_TIME[$i]; JOB_SUBMISSION_TIME=( "${JOB_SUBMISSION_TIME[@]}" )
        unset JOB_SUBMISSION_FOLDER[$i]; JOB_SUBMISSION_FOLDER=( "${JOB_SUBMISSION_FOLDER[@]}" )
        unset JOB_NUM_NODES[$i]; JOB_NUM_NODES=( "${JOB_NUM_NODES[@]}" )
        unset JOB_NODELIST[$i]; JOB_NODELIST=( "${JOB_NODELIST[@]}" )
        unset JOB_WALLTIME[$i]; JOB_WALLTIME=( "${JOB_WALLTIME[@]}" )
        unset JOB_RUNTIME[$i]; JOB_RUNTIME=( "${JOB_RUNTIME[@]}" )

    done


    printf "\n\e[38;5;202m  Total number of submitted jobs: $TOTAL_JOBS"
    printf " (\e[1;32mRunning: $RUNNING_JOBS  \e[0m - \e[1;31m  Pending: $PENDING_JOBS  \e[0m - \e[1;35m  Others: $OTHER_JOBS\e[38;5;202m)\n"
    printf "\e[1;36m"
    for (( c=1; c<=$(($COLUMNS_OF_THE_SHELL-3)); c++ )); do printf "="; done && unset -v 'c'
    printf "\e[0m\n\n"

fi
