#!/bin/awk -f
#
#  Copyright (c) 2016-2018,2020 Alessandro Sciarra
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



# This awk script needs 5 input variables:
#  - the observable columns (from 1 on) in a variable named "obsColumns"
#  - the observables names in a variable named "obsNames"
#     [These variables must be strings with elements separated
#      by commas (,) and without any space inside. Two names are
#      fixed and must be present: 'TrajectoryNr' and 'Accepted']
#  - three variables named "wrongVariable", "success", "failure" which
#    are the error codes to be returned.
#
# Pass another variable named "printReport" set to 1 if you want
# to get a report.

BEGIN{
    split(obsNames, namesArray, ",");
    split(obsColumns, columnsArray, ",");
    for(i in namesArray){
        observables[namesArray[i]]=columnsArray[i]
        if(namesArray[i]=="Accepted"){acceptedFound=1}
        if(namesArray[i]=="TrajectoryNr"){trajectoryNumberFound=1}
    }
    if(acceptedFound!=1 || trajectoryNumberFound!=1){skipEnd=1; exit}
}
NR>1{
    if($(observables["Accepted"]) == 0){
        for(obs in observables){
            if(obs=="TrajectoryNr" || obs=="Accepted"){continue};
            if($(observables[obs]) != oldObservables[obs]){
                if(changedObs == ""){changedObs=obs}
                else{changedObs=(changedObs ", " obs)}
            }
        }
        if(changedObs != ""){
            if(printReport==1){print "\033[38;5;9m Trajectory\033[38;5;11m", $(observables["TrajectoryNr"]) "\033[38;5;9m -> configuration rejected but\033[38;5;11m", changedObs, "\033[38;5;9mchanged!\033[0m"}
            changedObs=""
            wrongLines++
        }
    }
}
{
    for(obs in observables){
        oldObservables[obs]=$(observables[obs])
    }
}
END{
    if(skipEnd==1){
        if(printReport==1){printf "\n\033[38;5;9mCheck variables given to awk script, \"Accepted\" and/or \"TrajectoryNr\" label(s) not found in obsNames!!\033[0m\n\n"}
        exit wrongVariable
    }
    if(wrongLines==0){
        if(printReport==1){printf "\033[38;5;10m No wrong lines have been detected! The file seems to be correct!\033[0m\n\n"}
        exit success
    }else{
        if(printReport==1){printf "\n\033[38;5;9m In total \033[38;5;11m%d\033[38;5;9m wrong lines!\033[0m\n\n", wrongLines}
        exit failure
    }
}
