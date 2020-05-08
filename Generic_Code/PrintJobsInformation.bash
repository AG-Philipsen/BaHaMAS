#
#  Copyright (c) 2020 Alessandro Sciarra
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
    local jobsInformation\
          jobId jobName jobStatus jobNodeList jobSubmissionTime jobWalltime\
          jobStartTime jobRunTime jobEndTime jobSubmissionFolder jobNumberOfNodes\
          lengthOfLongestEntry\
          numberOfJobs numberOfRunningJobs numberOfPendingJobs numberOfOtherJobs\
          lineOfEquals tableFormat index
    #Call function scheduler specific: It will fill jobsInformation
    GatherJobsInformationForJobStatusMode
    if [[ "${#jobsInformation[@]}" -eq 0 ]]; then
        cecho lc "\n No job found according to given options!"
        return 0
    fi
    #Split job information in different arrays using '@' as separator
    # NOTE: it might be done with builtins only, but less compact and less readable!
    jobId=(               $(cut -d'@' -f1  <<< "$(printf '%s\n' ${jobsInformation[@]})") )
    jobName=(             $(cut -d'@' -f2  <<< "$(printf '%s\n' ${jobsInformation[@]})") )
    jobStatus=(           $(cut -d'@' -f3  <<< "$(printf '%s\n' ${jobsInformation[@]})") )
    jobNodeList=(         $(cut -d'@' -f4  <<< "$(printf '%s\n' ${jobsInformation[@]})") )
    jobSubmissionTime=(   $(cut -d'@' -f5  <<< "$(printf '%s\n' ${jobsInformation[@]})") )
    jobWalltime=(         $(cut -d'@' -f6  <<< "$(printf '%s\n' ${jobsInformation[@]})") )
    jobStartTime=(        $(cut -d'@' -f7  <<< "$(printf '%s\n' ${jobsInformation[@]})") )
    jobRunTime=(          $(cut -d'@' -f8  <<< "$(printf '%s\n' ${jobsInformation[@]})") )
    jobEndTime=(          $(cut -d'@' -f9  <<< "$(printf '%s\n' ${jobsInformation[@]})") )
    jobSubmissionFolder=( $(cut -d'@' -f10 <<< "$(printf '%s\n' ${jobsInformation[@]})") )
    jobNumberOfNodes=(    $(cut -d'@' -f11 <<< "$(printf '%s\n' ${jobsInformation[@]})") )
    #Shorten path (it works only if the user is 'whoami'
    jobSubmissionFolder=( ${jobSubmissionFolder[@]/${BHMAS_submitDiskGlobalPath}/SUBMIT} )
    jobSubmissionFolder=( ${jobSubmissionFolder[@]/${BHMAS_runDiskGlobalPath}/WORK} )
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
    cecho lc "\n" B "${lineOfEquals}\n"\
          o "$(printf "${tableFormat}" "jobId:" ""   "  JOB NAME:" ""   "STATUS:" ""   "START/END TIME:" ""   "WALL/RUNTIME:" ""   "SUBMITTED FROM:")"
    #Print table sorting according jobname
    while [[ ${#jobName[@]} -gt 0 ]]; do
        index=$(FindPositionOfFirstMinimumOfArray "${jobName[@]}")

        if [[ ${jobStatus[${index}]} = "RUNNING" ]]; then
            cecho -d -n lg
        elif [[ ${jobStatus[${index}]} == "PENDING" ]]; then
            if [[ ${jobStartTime[${index}]} != "N/A" ]]; then
                cecho -d -n  ly
            else
                cecho -d -n lo
            fi
        else
            cecho -d -n lm
        fi

        if [[ ${jobStatus[${index}]} == "RUNNING" ]]; then
            cecho "$(printf "${tableFormat}\e[0m\n"   "${jobId[${index}]}" "" "  ${jobName[${index}]}" "" "${jobStatus[${index}]} on ${jobNodeList[${index}]}" "" "${jobEndTime[${index}]}" "" "${jobRunTime[${index}]}" "" "${jobSubmissionFolder[${index}]}")"
        else
            cecho "$(printf "${tableFormat}\e[0m\n"   "${jobId[${index}]}" "" "  ${jobName[${index}]}" "" "${jobStatus[${index}]}" "" "${jobStartTime[${index}]}" "" "${jobWalltime[${index}]}" "" "${jobSubmissionFolder[${index}]} on ${jobSubmissionTime[${index}]}")"
        fi

        unset -v 'jobId[${index}]';               jobId=(               ${jobId[@]+"${jobId[@]}"} )
        unset -v 'jobName[${index}]';             jobName=(             ${jobName[@]+"${jobName[@]}"} )
        unset -v 'jobStatus[${index}]';           jobStatus=(           ${jobStatus[@]+"${jobStatus[@]}"} )
        unset -v 'jobStartTime[${index}]';        jobStartTime=(        ${jobStartTime[@]+"${jobStartTime[@]}"} )
        unset -v 'jobEndTime[${index}]';          jobEndTime=(          ${jobEndTime[@]+"${jobEndTime[@]}"} )
        unset -v 'jobSubmissionTime[${index}]';   jobSubmissionTime=(   ${jobSubmissionTime[@]+"${jobSubmissionTime[@]}"} )
        unset -v 'jobSubmissionFolder[${index}]'; jobSubmissionFolder=( ${jobSubmissionFolder[@]+"${jobSubmissionFolder[@]}"} )
        unset -v 'jobNumberOfNodes[${index}]';    jobNumberOfNodes=(    ${jobNumberOfNodes[@]+"${jobNumberOfNodes[@]}"} )
        unset -v 'jobNodeList[${index}]';         jobNodeList=(         ${jobNodeList[@]+"${jobNodeList[@]}"} )
        unset -v 'jobWalltime[${index}]';         jobWalltime=(         ${jobWalltime[@]+"${jobWalltime[@]}"} )
        unset -v 'jobRunTime[${index}]';          jobRunTime=(          ${jobRunTime[@]+"${jobRunTime[@]}"} )
    done
    cecho o "\n  Total number of submitted jobs: " B "${numberOfJobs}" uB " (" B lg "Running: ${numberOfRunningJobs}" ly "     Pending: ${numberOfPendingJobs}" lm "     Others: ${numberOfOtherJobs}" uB o ")"
    cecho lc B "${lineOfEquals}\n"
}


MakeFunctionsDefinedInThisFileReadonly
