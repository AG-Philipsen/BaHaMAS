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
