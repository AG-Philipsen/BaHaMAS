#
#  Copyright (c) 2017,2020 Alessandro Sciarra
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

function __static__ExtractParametersFromJobInformation()
{
    local jobIdNumber parameterNames scontrolOutput string
    jobIdNumber="$1"; shift
    parameterNames=("$@")
    scontrolOutput="$(scontrol show job ${jobIdNumber})"
    for string in "${parameterNames[@]}"; do
        extractedJobInformation["${string}"]=$(sed -n 's@.*'${string}'=\([^[:space:]]*\).*@\1@p' <<< "${scontrolOutput}")
    done
}

# This function has to set the variable "jobsInformation" with a long
# string which reports information for all jobs on different lines:
#   "<job1>\n<job2>\n<job3>\n"
#
# The information for each job is a @-separated list with the following fields:
#   JobId number
#   Name of the job
#   Job state
#   Node list
#   Submit time
#   Time limit
#   Start time
#   Run time
#   End time
#   Working directory
#   Number of nodes used
function GatherJobsInformation_SLURM()
{
    local squeueFormatCodeString squeueFormatCodeOrder label\
          slurmOkVersion slurmVersion partitionDirective\
          jobId jobSubmissionTime jobSubmissionFolder
    declare -A squeueFormatCode=()
    squeueFormatCodeString=''; slurmOkVersion='slurm 14.03.0'; slurmVersion="$(squeue --version)"
    if [[ "${BHMAS_clusterPartition}" != '' ]]; then
        partitionDirective='-p ${BHMAS_clusterPartition}'
    fi
    #Format codes for squeue command in order to get specific information
    squeueFormatCode=(
        ["JobId"]="%i"
        ["Name"]="%j"
        ["JobState"]="%T"
        ["[[:space:]]NodeList"]="%N"
        ["SubmitTime"]="%V"
        ["TimeLimit"]="%l"
        ["StartTime"]="%S"
        ["RunTime"]="%M"
        ["EndTime"]="%e"
        ["WorkDir"]="%Z"
        ["NumNodes"]="%D"
    )
    #Space before NodeList is crucial if one wants to parse the output of scontrol show job because there are also ReqNodeList and ExcNodeList
    squeueFormatCodeOrder=("JobId" "Name" "JobState" "[[:space:]]NodeList" "SubmitTime" "TimeLimit" "StartTime" "RunTime" "EndTime" "WorkDir" "NumNodes")
    for label in "${squeueFormatCodeOrder[@]}"; do
        squeueFormatCodeString+="@${squeueFormatCode[${label}]}"
    done
    #Get information via squeue and in case filter jobs -> ATTENTION: Double quoting here is CRUCIAL (to respect endlines)!!
    #NOTE: It seems that the sacct command can give a similar result, but at the moment there is no analog to the %Z field.
    if [[ ${BHMAS_jobstatusAll} = 'TRUE' ]]; then
        jobsInformation="$(squeue --noheader ${partitionDirective:-} -o ${squeueFormatCodeString:1} 2>/dev/null)"
    else
        jobsInformation="$(squeue --noheader -u ${BHMAS_jobstatusUser} -o "${squeueFormatCodeString:1}" 2>/dev/null)"
    fi
    if [[ "${jobsInformation}" = '' ]]; then
        return 0
    fi
    #------------------------------------------------------------------------------------------------------------------------------#
    #The following is a workaround for slurm versions before 14.03.0 (when squeue formats %Z and %V were not available)
    if [[ "$(printf "%s\n" "${slurmVersion}" "${slurmOkVersion}" | sort -V | tail -n1)" = "${slurmOkVersion}" ]]; then
        jobSubmissionFolder=""
        jobSubmissionTime=""
        for jobId in $(cut -d'@' -f1  <<< "${jobsInformation}"); do
            declare -A extractedJobInformation=()
            __static__ExtractParametersFromJobInformation "${jobId}" "WorkDir" "SubmitTime"
            jobSubmissionFolder="${jobSubmissionFolder}|${jobId}@${extractedJobInformation[WorkDir]}"
            jobSubmissionTime="${jobSubmissionTime}|${jobId}@${extractedJobInformation[SubmitTime]}"
            unset -v 'extractedJobInformation'
        done
        jobsInformation=$(awk --posix -v subFolder="${jobSubmissionFolder:1}" \
                            -v subTime="${jobSubmissionTime:1}" '
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
                                }' <<< "${jobsInformation}")
    fi
    #------------------------------------------------------------------------------------------------------------------------------#
    if [[ ${BHMAS_jobstatusLocal} = 'TRUE' ]]; then
        jobsInformation="$(grep --color=never "${PWD}" <<< "${jobsInformation}")"
    fi
}

# This function has to set the array "jobsInformation" with each element being
# the information for each job as a @-separated list with the following fields:
#   Job name
#   Job running status
function GatherJobsInformationForSimulationStatusMode_SLURM()
{
    # In the following line we assume that no newline are contained
    # neither in the job name nor in the job status, it seems so in SLURM
    local line
    jobsInformation=()
    while IFS= read -r line; do
        jobsInformation+=( "${line}" )
    done < <(squeue --noheader -u "$(whoami)" -o "%j@%T")
}

# This function has to set the array "jobsInformation" with each element being
# the information for each job as a @-separated list with the following fields:
#   Job ID
#   Job name
#   Job running status
function GatherJobsInformationForContinueMode_SLURM()
{
    # In the following line we assume that no newline are contained
    # neither in the job name nor in the job status, it seems so in SLURM
    local line
    jobsInformation=()
    while IFS= read -r line; do
        jobsInformation+=( "${line}" )
    done < <(squeue --noheader -u "$(whoami)" -o "%i@%j@%T")
}


MakeFunctionsDefinedInThisFileReadonly
