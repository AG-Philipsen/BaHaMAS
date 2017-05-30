#!/bin/awk -f

# This awk script needs two input variables, namely the
# observable columns (from 1 on) in a variable named "obsColumns" and
# the observables names in a variable named "obsNames".
# These variablse must be two strings with elements separated
# by commas (,) and without any space inside.
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
        exit 2
    }
    if(wrongLines==0){
        if(printReport==1){printf "\033[38;5;10m No wrong lines have been detected! The file seems to be correct!\033[0m\n\n"}
        exit 0
    }else{
        if(printReport==1){printf "\n\033[38;5;9m In total \033[38;5;11m%d\033[38;5;9m wrong lines!\033[0m\n\n", wrongLines}
        exit 1
    }
}
