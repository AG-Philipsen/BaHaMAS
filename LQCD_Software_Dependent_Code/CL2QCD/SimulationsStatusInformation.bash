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

# This function has to extract from the files ${outputFileGlobalPath} and ${inputFileGlobalPath}
# the needed information and set the following variables:
#
#  -  toBeCleaned
#  -  trajectoriesDone
#  -  numberLastTrajectory
#  -  acceptanceAllRun
#  -  acceptanceLastBunchOfTrajectories
#  -  meanPlaquetteLastBunchOfTrajectories
#  -  maxSpikeToMeanAsNSigma
#  -  maxSpikePlaquetteAsNSigma
#  -  deltaMaxPlaquette
#  -  timeFromLastTrajectory
#  -  averageTimePerTrajectory
#  -  timeLastTrajectory
#  -  integrationSteps0
#  -  integrationSteps1
#  -  integrationSteps2
#  -  kappaMassPreconditioning
#
function ExtractSimulationInformationFromFiles_CL2QCD()
{
    CheckVariablesToBeSetInSimulationStatusFromSpecificCode
    #---------------------------------------------------------------------------------------------------------------------------------------#
    if [[ -f ${outputFileGlobalPath} ]] && [[ $(wc -l < ${outputFileGlobalPath}) -gt 0 ]]; then
        toBeCleaned=$(awk 'BEGIN{traj_num = -1; file_to_be_cleaned=0}{if($1>traj_num){traj_num = $1} else {file_to_be_cleaned=1; exit;}}END{print file_to_be_cleaned}' ${outputFileGlobalPath})
        if [[ ${toBeCleaned} -eq 0 ]]; then
            trajectoriesDone=$(wc -l < ${outputFileGlobalPath})
        else
            trajectoriesDone=$(awk 'NR==1{startTr=$1}END{print $1 - startTr + 1}' ${outputFileGlobalPath})
        fi
        numberLastTrajectory=$(awk 'END{print $1}' ${outputFileGlobalPath})
        acceptanceAllRun=$(awk '{ sum+=$'${BHMAS_acceptanceColumn}'} END {printf "%5.2f", 100*sum/(NR)}' ${outputFileGlobalPath})

        if [[ ${trajectoriesDone} -ge 1000 ]]; then
            acceptanceLastBunchOfTrajectories=$(tail -n1000 ${outputFileGlobalPath} | awk '{ sum+=$'${BHMAS_acceptanceColumn}'} END {printf "%5.2f", 100*sum/(NR)}')
            meanPlaquetteLastBunchOfTrajectories=$(tail -n1000 ${outputFileGlobalPath} | awk '{ sum+=$'${BHMAS_plaquetteColumn}'} END {printf "% .6f", sum/(NR)}')
        else
            acceptanceLastBunchOfTrajectories=" --- "
            meanPlaquetteLastBunchOfTrajectories=" ----- "
        fi

        local temporaryArray
        temporaryArray=( $(awk 'BEGIN{meanS=0; sigmaS=0; maxSpikeS=0; meanP=0; sigmaP=0; maxSpikeP=0; firstFile=1; secondFile=1}
                                    NR==1 {plaqMin=$'${BHMAS_plaquetteColumn}'; plaqMax=$'${BHMAS_plaquetteColumn}'}
                                    NR==FNR {meanS+=$'${BHMAS_deltaHColumn}'; meanP+=$'${BHMAS_plaquetteColumn}'; plaqValue=$'${BHMAS_plaquetteColumn}';
                                             if(plaqValue<plaqMin){plaqMin=plaqValue}; if(plaqValue>plaqMax){plaqMax=plaqValue}; next}
                                    firstFile==1 {nDat=NR-1; meanS/=nDat; meanP/=nDat; firstFile=0}
                                    NR-nDat==FNR {deltaS=($'${BHMAS_deltaHColumn}'-meanS); sigmaS+=deltaS^2; if(sqrt(deltaS^2)>maxSpikeS){maxSpikeS=sqrt(deltaS^2)};
                                                  deltaP=($'${BHMAS_plaquetteColumn}'-meanP); sigmaP+=deltaP^2; if(sqrt(deltaP^2)>maxSpikeP){maxSpikeP=sqrt(deltaP^2)}; next}
                                    END{sigmaS=sqrt(sigmaS/nDat); sigmaP=sqrt(sigmaP/nDat); secondFile=0;
                                        if(sigmaS!=0) {printf "%.3f ", maxSpikeS/sigmaS} else {print "---- "};
                                        if(sigmaP!=0) {printf "%.3f",  maxSpikeP/sigmaP} else {print "---- "};
                                        printf "% .6f", plaqMax-plaqMin;
                                       }' ${outputFileGlobalPath} ${outputFileGlobalPath} ) )
        maxSpikeToMeanAsNSigma=${temporaryArray[0]}
        maxSpikePlaquetteAsNSigma=${temporaryArray[1]}
        deltaMaxPlaquette=${temporaryArray[2]}
        if [[ ${jobStatus} == "RUNNING" ]]; then
            timeFromLastTrajectory=$(( $(date +%s) - $(stat -c %Y ${outputFileGlobalPath}) ))
        else
            timeFromLastTrajectory="------"
        fi

        if [[ ${BHMAS_liststatusMeasureTimeOption} = "TRUE" ]]; then
            averageTimePerTrajectory=$(awk '{ time=$'${BHMAS_trajectoryTimeColumn}'; if(time!=0){sum+=time; counter+=1}} END {if(counter!=0){printf "%d", sum/counter}else{printf "%d", 0}}' ${outputFileGlobalPath})
            timeLastTrajectory=$(awk 'END{printf "%d", $'${BHMAS_trajectoryTimeColumn}'}' ${outputFileGlobalPath})
        else
            averageTimePerTrajectory="----"
            timeLastTrajectory="----"
        fi
    fi

    if [[ -f ${inputFileGlobalPath} ]]; then
        integrationSteps0=$( sed -n '/integrationSteps0=[[:digit:]]\+/p'  ${inputFileGlobalPath} | sed 's/integrationSteps0=\([[:digit:]]\+\)/\1/' )
        integrationSteps1=$( sed -n '/integrationSteps1=[[:digit:]]\+/p'  ${inputFileGlobalPath} | sed 's/integrationSteps1=\([[:digit:]]\+\)/\1/' )
        if [[ ! ${integrationSteps0} =~ ^[[:digit:]]+$ ]] || [[ ! ${integrationSteps1} =~ ^[[:digit:]]+$ ]]; then
            integrationSteps0="--"
            integrationSteps1="--"
        fi
        if [[ $(grep -o "useMP=1" ${inputFileGlobalPath} | wc -l) -eq 1 ]]; then
            integrationSteps2="-$( sed -n '/integrationSteps2=[[:digit:]]\+/p'  ${inputFileGlobalPath} | sed 's/integrationSteps2=\([[:digit:]]\+\)/\1/' )"
            kappaMassPreconditioning="-$( sed -n '/kappaMP=[[:digit:]]\+[.][[:digit:]]\+/p'  ${inputFileGlobalPath} | sed 's/kappaMP=\(.*\)/\1/' )"
            if [[ ! ${integrationSteps2} =~ ^-[[:digit:]]+$ ]] || [[ ! ${kappaMassPreconditioning} =~ ^-[[:digit:]]+[.][[:digit:]]+$ ]]; then
                integrationSteps2="--"
                kappaMassPreconditioning="--"
            fi
        else
            integrationSteps2="  "
            kappaMassPreconditioning="      "
        fi
    fi
}


MakeFunctionsDefinedInThisFileReadonly
