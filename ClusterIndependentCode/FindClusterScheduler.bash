#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENSE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

# NOTE: At the moment I do not have a smarter idea about
#       how to understand which scheduler is installed
#       on the cluster, so I check for the existence of
#       the command to get the cluster jobs queue information.

function SelectClusterSchedulerName()
{
    local availableScheduler scheduler
    availableScheduler=()
    #Queue commands of some well known job schedulers
    declare -A schedulerMap=( ['LOADLEVELER']='llq'
                              ['LSF']='bjobs'
                              ['PBS']='qstat'
                              ['SLURM']='squeue' )

    for scheduler in "${!schedulerMap[@]}"; do
        if hash "${schedulerMap[$scheduler]}" 2>/dev/null; then
            availableScheduler+=( "$scheduler" )
        fi
    done

    if [ ${#availableScheduler[@]} -eq 0 ]; then
        Fatal $BHMAS_fatalMissingFeature "No known scheduler was found!"
    elif [ ${#availableScheduler[@]} -gt 1 ]; then
        Warning "More than one scheduler was found! Using " o B "${availableScheduler[0]}" uB ly "."
    fi

    printf "${availableScheduler[0]}"
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         SelectClusterSchedulerName
