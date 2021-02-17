#
#  Copyright (c) 2020-2021 Alessandro Sciarra
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

function GatherAndPrintJobsInformation()
{
    local jobsInformation string\
          jobId jobName jobStatus jobNodeList jobSubmissionTime jobWalltime\
          jobStartTime jobRunTime jobEndTime jobSubmissionFolder jobNumberOfNodes\
          jobPartition lengthOfLongestJobName lengthOfLongestJobId\
          numberOfJobs numberOfRunningJobs numberOfPendingJobs numberOfOtherJobs\
          numberOfRunningNodes numberOfPendingNodes numberOfOtherNodes\
          lineOfEquals tableFormat index\
          nodesPendingTimeString startEndTime runWallTime submissionTimeString
    #Call function scheduler specific: It will fill jobsInformation
    GatherJobsInformationForJobStatusMode
    #Sort job information according to jobname to be able to easily printlater
    if [[ ${#jobsInformation[@]} -ne 0 ]]; then
        readarray -d $'\0' -t jobsInformation < <(printf '%s\0' "${jobsInformation[@]}" | sort -z -t'@' -k2)
    fi
    #Split job information in different arrays using '@' as separator
    #
    # NOTE: Here the strings could contain glob patterns (e.g. NodeList)
    #       and it is important to quote them, since nullglob is set.
    jobId=();                jobName=();             jobStatus=()
    jobNodeList=();          jobSubmissionTime=();   jobWalltime=()
    jobStartTime=();         jobRunTime=();          jobEndTime=()
    jobSubmissionFolder=();  jobNumberOfNodes=();    jobPartition=()
    for string in "${jobsInformation[@]}"; do
        jobId+=(               "${string%%@*}" ); string="${string#*@}"
        jobName+=(             "${string%%@*}" ); string="${string#*@}"
        jobStatus+=(           "${string%%@*}" ); string="${string#*@}"
        jobNodeList+=(         "${string%%@*}" ); string="${string#*@}"
        jobSubmissionTime+=(   "${string%%@*}" ); string="${string#*@}"
        jobWalltime+=(         "${string%%@*}" ); string="${string#*@}"
        jobStartTime+=(        "${string%%@*}" ); string="${string#*@}"
        jobRunTime+=(          "${string%%@*}" ); string="${string#*@}"
        jobEndTime+=(          "${string%%@*}" ); string="${string#*@}"
        jobSubmissionFolder+=( "${string%%@*}" ); string="${string#*@}"
        jobNumberOfNodes+=(    "${string%%@*}" ); string="${string#*@}"
        jobPartition+=(        "${string%%@*}" )
        if [[ ${BHMAS_jobstatusLocal} = 'TRUE' ]]; then
            if [[ ! ${jobSubmissionFolder[-1]} =~ ^$(pwd) ]]; then
                unset -v\
                      'jobId[-1]' 'jobName[-1]' 'jobStatus[-1]' 'jobNodeList[-1]'\
                      'jobSubmissionTime[-1]' 'jobWalltime[-1]' 'jobStartTime[-1]'\
                      'jobRunTime[-1]' 'jobEndTime[-1]' 'jobSubmissionFolder[-1]'\
                      'jobNumberOfNodes[-1]'
            fi
        fi
    done
    # The if here below considers both no queued jobs or no "--local" jobs in a non empty queue
    if [[ ${#jobId[@]} -eq 0 ]]; then
        cecho lc "\n No job found according to given options!"
        return 0
    fi
    #Shorten path (it works only if the user is 'whoami'
    jobSubmissionFolder=( ${jobSubmissionFolder[@]/${BHMAS_submitDiskGlobalPath}/SUBMIT} )
    jobSubmissionFolder=( ${jobSubmissionFolder[@]/${BHMAS_runDiskGlobalPath}/WORK} )
    #Some counting for the table
    numberOfJobs=${#jobId[@]}
    numberOfPendingJobs=0
    numberOfRunningJobs=0
    numberOfOtherJobs=0
    numberOfPendingNodes=0
    numberOfRunningNodes=0
    numberOfOtherNodes=0
    for((index=0; index<numberOfJobs; index++)); do
        if [[ ${jobStatus[index]} = 'RUNNING' ]]; then
            (( numberOfRunningJobs+=1 )) || true
            (( numberOfRunningNodes+=jobNumberOfNodes[index] )) || true
        elif [[ ${jobStatus[index]} = 'PENDING' ]]; then
            (( numberOfPendingJobs+=1 )) || true
            (( numberOfPendingNodes+=jobNumberOfNodes[index] )) || true
        else
            (( numberOfOtherJobs+=1 )) || true
            (( numberOfOtherNodes+=jobNumberOfNodes[index] )) || true
        fi
    done
    #Table header
    printf -v lineOfEquals '%*s' $(( $(tput cols) - 3 )) ''
    lineOfEquals=${lineOfEquals// /=}
    lengthOfLongestJobId=$(LengthOfLongestEntryInArray "${jobId[@]}")
    lengthOfLongestJobName=$(LengthOfLongestEntryInArray "${jobName[@]}")
    tableFormat="%-$((5+lengthOfLongestJobId))s%-$((5+lengthOfLongestJobName))s%-26s%-15s%-24s%+12s     %-s"
    cecho lc "\n" B "${lineOfEquals}\n"\
          bb "$(printf "${tableFormat}" "JOB ID" "JOB NAME" "STATUS" "PARTITION" "START/END TIME" "WALL/RUNTIME" "SUBMITTED FROM")"

    #Print table (sorting according jobname already done, just iterate)
    for index in "${!jobName[@]}"; do
        __static__ChangeOutputColor "${jobStatus[${index}]}" "${jobStartTime[${index}]}"

        if [[ ${jobStatus[${index}]} == "RUNNING" ]]; then
            if [[ ${jobNumberOfNodes[${index}]} -eq 1 ]]; then
                nodesPendingTimeString=" on ${jobNodeList[${index}]}"
            else
                nodesPendingTimeString=" on ${jobNumberOfNodes[${index}]} nodes"
            fi
            startEndTime="${jobEndTime[${index}]}"
            runWallTime="${jobRunTime[${index}]}"
            submissionTimeString=''
        else
            if [[ ${jobStatus[${index}]} == "PENDING" ]]; then
                nodesPendingTimeString=" for $(__static__GetQueuingTime ${jobSubmissionTime[${index}]})"
            else
                nodesPendingTimeString=''
            fi
            startEndTime="${jobStartTime[${index}]}"
            runWallTime="${jobWalltime[${index}]}"
            submissionTimeString=" on ${jobSubmissionTime[${index}]}"
        fi

        printf "${tableFormat}\e[0m\n"\
               "${jobId[index]}"\
               "${jobName[index]}"\
               "${jobStatus[index]}${nodesPendingTimeString}"\
               "${jobPartition[index]}"\
               "${startEndTime}"\
               "${runWallTime}"\
               "${jobSubmissionFolder[index]}${submissionTimeString}"
    done
    cecho\
        o B "\n  Total number of submitted jobs: ${numberOfJobs} ("\
        lg "Running: ${numberOfRunningJobs}"\
        ly "     Pending: ${numberOfPendingJobs}"\
        lm "     Others: ${numberOfOtherJobs}" o ")\n" uB \
        lo "    Node usage of submitted jobs: $((numberOfRunningNodes+numberOfPendingNodes+numberOfOtherNodes)) ("\
        lg "Running: ${numberOfRunningNodes}"\
        ly "     Pending: ${numberOfPendingNodes}"\
        lm "     Others: ${numberOfOtherNodes}" lo ")"\
        lc " <-- NOTE: Depending on the cluster, different jobs might use the same node(s).\n"\
        lc B "${lineOfEquals}"
}


function __static__ChangeOutputColor()
{
    local status startingTime color
    status="$1"
    startingTime="$2"
    if [[ "${status}" = 'RUNNING' ]]; then
        color='lg'
    elif [[ "${status}" = 'PENDING' ]]; then
        if [[ "${startingTime}" != 'N/A' ]]; then
            color='ly'
        else
            color='lo'
        fi
    else
        color='lm'
    fi
    cecho -d -n "${color}"
}

function __static__GetQueuingTime()
{
    local submissionTime queuingTime
    submissionTime="$1"
    queuingTime=$(( $(date +'%s') - $(date -d "${submissionTime}" +'%s') ))
    printf "%d-%s" $((queuingTime/86400)) $(date -d@${queuingTime} -u +'%H:%M:%S')
}


MakeFunctionsDefinedInThisFileReadonly
