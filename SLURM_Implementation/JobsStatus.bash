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
    scontrolOutput="$(scontrol show job $jobIdNumber)"
    for string in "${parameterNames[@]}"; do
        extractedJobInformation["$string"]=$(sed -n 's@.*'${string}'=\([^[:space:]]*\).*@\1@p' <<< "$scontrolOutput")
    done
}

function ListJobsStatus_SLURM()
{
    local squeueFormatCodeString squeueFormatCodeOrder label\
          squeueOutput slurmOkVersion slurmVersion partitionDirective\
          jobId jobName jobStatus jobNodeList jobSubmissionTime jobWalltime\
          jobStartTime jobRunTime jobEndTime jobSubmissionFolder jobNumberOfNodes\
          lengthOfLongestEntry numberOfJobs numberOfRunningJobs numberOfPendingJobs numberOfOtherJobs\
          lineOfEquals tableFormat index
    declare -A squeueFormatCode=()
    squeueFormatCodeString=''; slurmOkVersion='slurm 14.03.0'; slurmVersion="$(squeue --version)"
    if [[ "$BHMAS_clusterPartition" != '' ]]; then
        partitionDirective='-p $BHMAS_clusterPartition'
    fi
    #Format codes for squeue command in order to get specific information
    squeueFormatCode["JobId"]="%i"
    squeueFormatCode["Name"]="%j"
    squeueFormatCode["JobState"]="%T"
    squeueFormatCode["[[:space:]]NodeList"]="%N"
    squeueFormatCode["SubmitTime"]="%V"
    squeueFormatCode["TimeLimit"]="%l"
    squeueFormatCode["StartTime"]="%S"
    squeueFormatCode["RunTime"]="%M"
    squeueFormatCode["EndTime"]="%e"
    squeueFormatCode["WorkDir"]="%Z"
    squeueFormatCode["NumNodes"]="%D"
    #Space before NodeList is crucial if one wants to parse the output of scontrol show job because there are also ReqNodeList and ExcNodeList
    squeueFormatCodeOrder=("JobId" "Name" "JobState" "[[:space:]]NodeList" "SubmitTime" "TimeLimit" "StartTime" "RunTime" "EndTime" "WorkDir" "NumNodes")
    for label in "${squeueFormatCodeOrder[@]}"; do
        squeueFormatCodeString+="@${squeueFormatCode[$label]}"
    done
    #Get information via squeue and in case filter jobs -> ATTENTION: Double quoting here is CRUCIAL (to respect endlines)!!
    #NOTE: It seems that the sacct command can give a similar result, but at the moment there is no analog to the %Z field.
    if [[ $BHMAS_jobstatusAll = 'TRUE' ]]; then
        squeueOutput="$(squeue --noheader ${partitionDirective:-} -o ${squeueFormatCodeString:1} 2>/dev/null)"
    else
        squeueOutput="$(squeue --noheader -u $BHMAS_jobstatusUser -o "${squeueFormatCodeString:1}" 2>/dev/null)"
    fi
    if [[ "$squeueOutput" = '' ]]; then
        cecho lc "\n No job found according to given options!"
        return 0
    fi
    #------------------------------------------------------------------------------------------------------------------------------#
    #The following is a workaround for slurm versions before 14.03.0 (when squeue formats %Z and %V were not available)
    if [[ "$(printf "%s\n" "$slurmVersion" "$slurmOkVersion" | sort -V | tail -n1)" = "$slurmOkVersion" ]]; then
        jobSubmissionFolder=""
        jobSubmissionTime=""
        for jobId in $(cut -d'@' -f1  <<< "$squeueOutput"); do
            declare -A extractedJobInformation=()
            __static__ExtractParametersFromJobInformation "$jobId" "WorkDir" "SubmitTime"
            jobSubmissionFolder="${jobSubmissionFolder}|${jobId}@${extractedJobInformation[WorkDir]}"
            jobSubmissionTime="${jobSubmissionTime}|${jobId}@${extractedJobInformation[SubmitTime]}"
            unset -v 'extractedJobInformation'
        done
        squeueOutput=$(awk --posix -v subFolder="${jobSubmissionFolder:1}" \
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
                                }' <<< "$squeueOutput")
    fi
    #------------------------------------------------------------------------------------------------------------------------------#
    if [[ $BHMAS_jobstatusLocal = 'TRUE' ]]; then
        squeueOutput="$(grep --color=never "${PWD}" <<< "$squeueOutput")"
    fi
    #If any field is empty, fill it with empty word in order to have later all arrays with same number of elements
    squeueOutput=$(sed "s/@@/@empty@/g" <<< "$squeueOutput")
    #Split squeue output and prepare table layout
    jobId=(               $(cut -d'@' -f1  <<< "$squeueOutput") )
    jobName=(             $(cut -d'@' -f2  <<< "$squeueOutput") )
    jobStatus=(           $(cut -d'@' -f3  <<< "$squeueOutput") )
    jobNodeList=(         $(cut -d'@' -f4  <<< "$squeueOutput") )
    jobSubmissionTime=(   $(cut -d'@' -f5  <<< "$squeueOutput") )
    jobWalltime=(         $(cut -d'@' -f6  <<< "$squeueOutput") )
    jobStartTime=(        $(cut -d'@' -f7  <<< "$squeueOutput") )
    jobRunTime=(          $(cut -d'@' -f8  <<< "$squeueOutput") )
    jobEndTime=(          $(cut -d'@' -f9  <<< "$squeueOutput") )
    jobSubmissionFolder=( $(cut -d'@' -f10 <<< "$squeueOutput") )
    jobNumberOfNodes=(    $(cut -d'@' -f11 <<< "$squeueOutput") )
    #Shorten path (it works only if the user is 'whoami'
    jobSubmissionFolder=( ${jobSubmissionFolder[@]/$BHMAS_submitDiskGlobalPath/SUBMIT} )
    jobSubmissionFolder=( ${jobSubmissionFolder[@]/$BHMAS_runDiskGlobalPath/WORK} )
    #Some counting for the table
    lengthOfLongestEntry=$(LengthOfLongestEntryInArray ${jobName[@]})
    numberOfJobs=${#jobId[@]}
    set +e
    numberOfRunningJobs=$(grep -o "RUNNING" <<< "${jobStatus[@]}" | wc -l)
    numberOfPendingJobs=$(grep -o "PENDING" <<< "${jobStatus[@]}" | wc -l)
    set -e
    numberOfOtherJobs=$(( numberOfJobs - numberOfRunningJobs - numberOfPendingJobs ))
    #------------------------------------------------------------------------------------------------------------------------------#
    #Table header
    printf -v lineOfEquals '%*s' $(( $(tput cols) - 3 )) ''
    lineOfEquals=${lineOfEquals// /=}
    tableFormat="%-8s%-5s%-$((2+${lengthOfLongestEntry}))s%-5s%-25s%-5s%-19s%-5s%+14s%-5s%-s"
    cecho lc "\n" B "$lineOfEquals\n"\
          o "$(printf "$tableFormat" "jobId:" ""   "  JOB NAME:" ""   "STATUS:" ""   "START/END TIME:" ""   "WALL/RUNTIME:" ""   "SUBMITTED FROM:")"
    #Print table sorting according jobname
    while [[ ${#jobName[@]} -gt 0 ]]; do
        index=$(FindPositionOfFirstMinimumOfArray "${jobName[@]}")

        if [[ ${jobStatus[$index]} = "RUNNING" ]]; then
            cecho -d -n lg
        elif [[ ${jobStatus[$index]} == "PENDING" ]]; then
            if [[ ${jobStartTime[$index]} != "N/A" ]]; then
                cecho -d -n  ly
            else
                cecho -d -n lo
            fi
        else
            cecho -d -n lm
        fi

        if [[ ${jobStatus[$index]} == "RUNNING" ]]; then
            cecho "$(printf "$tableFormat\e[0m\n"   "${jobId[$index]}" "" "  ${jobName[$index]}" "" "${jobStatus[$index]} on ${jobNodeList[$index]}" "" "${jobEndTime[$index]}" "" "${jobRunTime[$index]}" "" "${jobSubmissionFolder[$index]}")"
        else
            cecho "$(printf "$tableFormat\e[0m\n"   "${jobId[$index]}" "" "  ${jobName[$index]}" "" "${jobStatus[$index]}" "" "${jobStartTime[$index]}" "" "${jobWalltime[$index]}" "" "${jobSubmissionFolder[$index]} on ${jobSubmissionTime[$index]}")"
        fi

        unset jobId[$index];               jobId=(               ${jobId[@]+"${jobId[@]}"} )
        unset jobName[$index];             jobName=(             ${jobName[@]+"${jobName[@]}"} )
        unset jobStatus[$index];           jobStatus=(           ${jobStatus[@]+"${jobStatus[@]}"} )
        unset jobStartTime[$index];        jobStartTime=(        ${jobStartTime[@]+"${jobStartTime[@]}"} )
        unset jobEndTime[$index];          jobEndTime=(          ${jobEndTime[@]+"${jobEndTime[@]}"} )
        unset jobSubmissionTime[$index];   jobSubmissionTime=(   ${jobSubmissionTime[@]+"${jobSubmissionTime[@]}"} )
        unset jobSubmissionFolder[$index]; jobSubmissionFolder=( ${jobSubmissionFolder[@]+"${jobSubmissionFolder[@]}"} )
        unset jobNumberOfNodes[$index];    jobNumberOfNodes=(    ${jobNumberOfNodes[@]+"${jobNumberOfNodes[@]}"} )
        unset jobNodeList[$index];         jobNodeList=(         ${jobNodeList[@]+"${jobNodeList[@]}"} )
        unset jobWalltime[$index];         jobWalltime=(         ${jobWalltime[@]+"${jobWalltime[@]}"} )
        unset jobRunTime[$index];          jobRunTime=(          ${jobRunTime[@]+"${jobRunTime[@]}"} )
    done
    cecho o "\n  Total number of submitted jobs: " B "$numberOfJobs" uB " (" B lg "Running: $numberOfRunningJobs" ly "     Pending: $numberOfPendingJobs" lm "     Others: $numberOfOtherJobs" uB o ")"
    cecho lc B "$lineOfEquals\n"
}


MakeFunctionsDefinedInThisFileReadonly
