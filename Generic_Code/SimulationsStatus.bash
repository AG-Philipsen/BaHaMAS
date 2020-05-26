#
#  Copyright (c) 2017-2018,2020 Alessandro Sciarra
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

# This function can be called by the JobHandler either in mode:job-status or in mode:database.
# The crucial difference is that in the first case the BHMAS_parametersString and BHMAS_parametersPath variable
# must be the global ones, otherwise they have to be built on the basis of some given information.
# Then we make this function accept one and ONLY ONE argument (given only in the DATABASE setup)
# containing the BHMAS_parametersPath (e.g. /muiPiT/k1550/nt6/ns12) and we will define local
# BHMAS_parametersString and BHMAS_parametersPath variables filled differently in the two cases.
# In the DATABASE setup the BHMAS_parametersString is built using the argument given.
function ListSimulationsStatus()
{
    local localParametersPath localParametersString jobsMetainformationArray runId betaFolderName\
          postfixFromFolder jobStatus outputFileGlobalPath inputFileGlobalPath\
          averageTimePerTrajectory timeLastTrajectory toBeCleaned trajectoriesDone\
          numberLastTrajectory acceptanceAllRun acceptanceLastBunchOfTrajectories\
          maxSpikeToMeanAsNSigma maxSpikePlaquetteAsNSigma meanPlaquetteLastBunchOfTrajectories deltaMaxPlaquette\
          timeFromLastTrajectory integrationSteps0 integrationSteps1 integrationSteps2 kappaMassPreconditioning
    if [[ $# -eq 0 ]]; then
        localParametersPath="${BHMAS_parametersPath}"
        localParametersString="${BHMAS_parametersString}"
    elif [[ $# -eq 1 ]]; then
        localParametersPath="$1"
        localParametersString=${localParametersPath//\//_}
        localParametersString=${localParametersString:1}
    else
        Internal "Wrong invocation of " emph "${FUNCNAME}" ", invalid number of arguments!"
    fi

    __static__PrintSimulationStatusHeader
    GatherJobsInformationForSimulationStatusMode

    for betaFolderName in "${BHMAS_betaPrefix}"${BHMAS_betaGlob}"_${BHMAS_seedPrefix}"${BHMAS_seedGlob}'_'{continueWithNewChain,thermalizeFrom{Hot,Cold,Conf}}; do
        runId=${betaFolderName#${BHMAS_betaPrefix}}
        if ! SetLqcdSoftwareFromMetadata "${runId}"; then
            Error -N 'Unable to find the LQCD software in the metadata file\n'\
                  file "${BHMAS_metadataFilename}" ' for ' emph "run ID = ${runId}" '.'
            continue
        fi
        postfixFromFolder=$(grep -o "[[:alpha:]]\+\$" <<< "${runId##*_}")
        jobStatus=$(__static__GetJobStatus "${runId}" "${localParametersString}")
        if [[ "${jobStatus}" = 'notQueued' ]] && [[ ${BHMAS_liststatusShowOnlyQueuedOption} = "TRUE" ]]; then
            continue
        fi
        # NOTE: Do not use BHMAS_runDirWithBetaFolders because it would break database
        #       which needs to change the ${localParametersPath} variable needed here.
        outputFileGlobalPath="${BHMAS_runDiskGlobalPath}/${BHMAS_projectSubpath}${localParametersPath}/${BHMAS_betaPrefix}${runId}/${BHMAS_outputFilename}.BaHaMAS"
        CreateOutputFileInTheStandardFormat "${runId}"
        toBeCleaned=0
        trajectoriesDone='-----'
        numberLastTrajectory='----'
        acceptanceAllRun=' ----'
        acceptanceLastBunchOfTrajectories=' ----'
        meanPlaquetteLastBunchOfTrajectories='---'
        maxSpikeToMeanAsNSigma=' ----'
        maxSpikePlaquetteAsNSigma='----'
        deltaMaxPlaquette='---'
        timeFromLastTrajectory='------'
        averageTimePerTrajectory='----'
        timeLastTrajectory='----'
        if [[ -s "${outputFileGlobalPath}" ]]; then
            __static__CheckIfOutputFileShouldBeCleaned
            __static__ExtractTrajectoryNumbers
            __static__ExtractAcceptanceInformation
            __static__ExtractActionAndPlaquetteInformation
            if [[ ${jobStatus} = 'RUNNING' ]]; then
                __static__ExtractTimeFromLastTrajectory
            fi
            if [[ ${BHMAS_liststatusMeasureTimeOption} = 'TRUE' ]]; then
                __static__ExtractTrajectoryTimes
            fi
        fi
        inputFileGlobalPath="${BHMAS_submitDiskGlobalPath}/${BHMAS_projectSubpath}${localParametersPath}/${BHMAS_betaPrefix}${runId}/${BHMAS_inputFilename}"
        integrationSteps0='--'
        integrationSteps1='--'
        integrationSteps2='--'
        kappaMassPreconditioning='-----'
        if [[ -f "${inputFileGlobalPath}" ]]; then
            ExtractSimulationInformationFromInputFile
        fi
        __static__PrintSimulationStatusLine "${runId}"
    done #Loop on BETA
    __static__PrintSimulationStatusFooter
}

#----------------------------------------------------------------------------------#
# The following functions implement the extraction of information of the runs      #
# in order to print then a new line to the report. They have the responsibility    #
# of setting on or more variables defined in the caller. The outputFileGlobalPath  #
# is set in the caller and it is assumed both to exist and to be in the standard   #
# format used by BaHaMAS, which for historical reasons matches CL2QCD format. For  #
# other software this file should be produced before extracting information.       #
#----------------------------------------------------------------------------------#

function __static__GetJobStatus()
{
    local runId parametersString betaValue seedPart postfix jobNameRegex value counter jobStatus
    runId="$1"
    parametersString="$2"
    #Assume runId format is fixed, as often done
    betaValue=( ${runId//_/ } ) #Let word splitting act
    seedPart="${betaValue[1]}"
    postfix="${betaValue[2]}"
    betaValue="${betaValue[0]}"
    case "${postfix}" in
        continueWithNewChain )
            postfix="NC"
            ;;
        thermalizeFromConf )
            postfix="TC"
            ;;
       thermalizeFromHot )
            postfix="TH"
            ;;
    esac
    jobNameRegex="${parametersString}_${BHMAS_betaPrefix}${betaValue}(_${BHMAS_seedPrefix}${BHMAS_seedRegex//\\/})*_${seedPart}(_${BHMAS_seedPrefix}${BHMAS_seedRegex//\\/})*_${postfix}"
    CheckIfVariablesAreDeclared jobsInformation
    #Assume each element of jobsInformation is of the form "jobName@jobStatus"
    counter=0
    for value in "${jobsInformation[@]}"; do
        if [[ ${value} =~ ^${jobNameRegex}@ ]]; then
            (( counter++ )) || true
            jobStatus="${value#*@}"
        fi
    done
    case ${counter} in
        0)
            jobStatus='notQueued'
            ;;
        1)
            ;;
        *)
            Fatal ${BHMAS_fatalLogicError}\
                  'There are more than one job with ' emph "${localParametersString}" ' and '\
                  emph "runId = ${runId}" ' as parameters! This should not happen!'
            ;;
    esac
    printf "%s" "${jobStatus}"
}

# OUTPUT: toBeCleaned
function __static__CheckIfOutputFileShouldBeCleaned()
{
    toBeCleaned=$(awk 'BEGIN{tr=-1; to_be_cleaned=0}{if($1>tr){tr=$1}else{to_be_cleaned=1; exit;}}END{print to_be_cleaned}' "${outputFileGlobalPath}")
}

# OUTPUT: trajectoriesDone, numberLastTrajectory
function __static__ExtractTrajectoryNumbers()
{
    trajectoriesDone=$(awk 'NR==1{startTr=$1}END{print $1 - startTr + 1}' "${outputFileGlobalPath}")
    numberLastTrajectory=$(awk 'END{print $1}' "${outputFileGlobalPath}")
}

# OUTPUT: acceptanceAllRun, acceptanceLastBunchOfTrajectories
function __static__ExtractAcceptanceInformation()
{
    acceptanceAllRun=$(awk '{ sum+=$'${BHMAS_acceptanceColumn}'} END {printf "%5.2f", 100*sum/(NR)}' "${outputFileGlobalPath}")
    if [[ ${trajectoriesDone} =~ ^[1-9][0-9]*$ ]] && [[ ${trajectoriesDone} -ge 1000 ]]; then
        acceptanceLastBunchOfTrajectories=$(tail -n1000 "${outputFileGlobalPath}" | awk '{ sum+=$'${BHMAS_acceptanceColumn}'} END {printf "%5.2f", 100*sum/(NR)}')
    fi
}

#OUTPUT: meanPlaquetteLastBunchOfTrajectories, maxSpikeToMeanAsNSigma,
#        maxSpikePlaquetteAsNSigma deltaMaxPlaquette
function __static__ExtractActionAndPlaquetteInformation()
{
    local temporaryArray
    if [[ ${trajectoriesDone} =~ ^[1-9][0-9]*$ ]] && [[ ${trajectoriesDone} -ge 1000 ]]; then
        meanPlaquetteLastBunchOfTrajectories=$(tail -n1000 "${outputFileGlobalPath}" | awk '{ sum+=$'${BHMAS_plaquetteColumn}'} END {printf "%.6f", sum/(NR)}')
    fi
    temporaryArray=(
        $(awk '
              BEGIN{
                  meanS=0; sigmaS=0; maxSpikeS=0; meanP=0; sigmaP=0; maxSpikeP=0; firstFile=1; secondFile=1
              }
              NR==1{
                  plaqMin=$'${BHMAS_plaquetteColumn}'
                  plaqMax=$'${BHMAS_plaquetteColumn}'
              }
              NR==FNR{
                  meanS+=$'${BHMAS_deltaHColumn}'
                  meanP+=$'${BHMAS_plaquetteColumn}'
                  plaqValue=$'${BHMAS_plaquetteColumn}'
                  if(plaqValue<plaqMin){plaqMin=plaqValue}
                  if(plaqValue>plaqMax){plaqMax=plaqValue}
                  next
              }
              firstFile==1{
                  nDat=NR-1
                  meanS/=nDat
                  meanP/=nDat
                  firstFile=0
              }
              NR-nDat==FNR{
                  deltaS=($'${BHMAS_deltaHColumn}'-meanS)
                  sigmaS+=deltaS^2
                  if(sqrt(deltaS^2)>maxSpikeS){maxSpikeS=sqrt(deltaS^2)}
                  deltaP=($'${BHMAS_plaquetteColumn}'-meanP)
                  sigmaP+=deltaP^2
                  if(sqrt(deltaP^2)>maxSpikeP){maxSpikeP=sqrt(deltaP^2)}
                  next
              }
              END{
                  sigmaS=sqrt(sigmaS/nDat)
                  sigmaP=sqrt(sigmaP/nDat)
                  secondFile=0
                  if(sigmaS!=0) {printf "%.3f ", maxSpikeS/sigmaS} else {print "---- "}
                  if(sigmaP!=0) {printf "%.3f",  maxSpikeP/sigmaP} else {print "---- "};
                  printf "% .6f", plaqMax-plaqMin
              }
              ' "${outputFileGlobalPath}" "${outputFileGlobalPath}" )
    )
    maxSpikeToMeanAsNSigma=${temporaryArray[0]}
    maxSpikePlaquetteAsNSigma=${temporaryArray[1]}
    deltaMaxPlaquette=${temporaryArray[2]}
}

# OUTPUT: timeFromLastTrajectory
function __static__ExtractTimeFromLastTrajectory()
{
    timeFromLastTrajectory=$(( $(date +%s) - $(stat -c %Y "${outputFileGlobalPath}") ))
}

# OUTPUT: averageTimePerTrajectory timeLastTrajectory
function __static__ExtractTrajectoryTimes()
{
    averageTimePerTrajectory=$(awk '{
                                        time=$'${BHMAS_trajectoryTimeColumn}'
                                        if(time!=0){sum+=time; counter+=1}
                                    }
                                    END{
                                        if(counter!=0){printf "%d", sum/counter}else{printf "%d", 0}
                                    }' "${outputFileGlobalPath}"
                            )
    timeLastTrajectory=$(awk 'END{printf "%d", $'${BHMAS_trajectoryTimeColumn}'}' "${outputFileGlobalPath}")
}


#----------------------------------------------------------------------------------#
# The following functions deal with the report printing to the screen. Many are    #
# simply deducing the color to use based on some information which is passed as    #
# input. Their task is then to simply print a color code.                          #
#----------------------------------------------------------------------------------#


function __static__PrintSimulationStatusHeader()
{
    local terminalWidth separator index header1 header2
    terminalWidth=$(tput cols)
    separator=''
    for((index=0; index<terminalWidth-1; index++)); do
        separator+='='
    done
    printf -v header1 "%-18s%45s%12s%16s%38s%30s%20s\e[0m"\
           "Run ID"\
           "Trajectories done, acceptance, MD steps   "\
           ""\
           "Metropolis "\
           "Plaquette average and monitoring "\
           "Last trajectory information"\
           "Time/trajectory"
    printf -v header2 "%-18s%45s%12s%16s%38s%30s%20s\e[0m"\
           "Beta_seed_type"\
           "Statistics (Accept.) [Last 1000] int0-1-2-kmp"\
           "Status"\
           "MaxSpikeDH/s"\
           "<Last1000>  Pmax-Pmin  MaxSpikeDP/s"\
           "Number   Time from last"\
           "Last    Mean"
    cecho -d "\n${BHMAS_defaultListstatusColor}${separator}" wg "\n${header1}" lm "\n${header2}"
    #cecho -n -d lm "${header}"
    #cecho -n -d lm "$(printf "%s\t\t  %s\t   %s    %s    %s\t  %s\t     %s\n\e[0m"   "Beta"   "Traj. Done (Acc.) [Last 1000] int0-1-2-kmp"   "Status"   "MaxSpikeDS/s"   "Plaq: <Last1000>  Pmax-Pmin  MaxSpikeDP/s"   "Last tr. finished" "Tr: # (time last|av.)")"
}

function __static__PrintSimulationStatusLine()
{
    local runId formattingString
    runId="$1"
    formattingString="$(__static__ColorBeta)%-18s"
    formattingString+="$(__static__ColorClean ${toBeCleaned})%10s${BHMAS_defaultListstatusColor} "
    formattingString+="($(GoodAcc ${acceptanceAllRun})%s %%${BHMAS_defaultListstatusColor}) "
    formattingString+="[$(GoodAcc ${acceptanceLastBunchOfTrajectories})%7s %%${BHMAS_defaultListstatusColor}] "
    formattingString+="%s-%s%s%s"
    formattingString+="$(__static__ColorStatus ${jobStatus})%12s${BHMAS_defaultListstatusColor}"
    formattingString+="$(__static__ColorDelta S ${maxSpikeToMeanAsNSigma})%13s${BHMAS_defaultListstatusColor}   "
    formattingString+="%12s%12s  $(__static__ColorDelta P ${maxSpikePlaquetteAsNSigma})%9s${BHMAS_defaultListstatusColor}   "
    formattingString+="%13s$(__static__ColorTime ${timeFromLastTrajectory})%12s${BHMAS_defaultListstatusColor} sec."
    formattingString+="%20s"
    formattingString+="\e[0m\n"

    printf "${formattingString}"\
           "$(__static__GetShortenedBetaString "${runId}")" \
           "${trajectoriesDone}" \
           "${acceptanceAllRun}" \
           "${acceptanceLastBunchOfTrajectories}" \
           "${integrationSteps0}" "${integrationSteps1}" "${integrationSteps2}" "${kappaMassPreconditioning}" \
           "${jobStatus}"\
           "${maxSpikeToMeanAsNSigma}"\
           "${meanPlaquetteLastBunchOfTrajectories}"   "${deltaMaxPlaquette}"   "${maxSpikePlaquetteAsNSigma}"\
           "${numberLastTrajectory}" \
           "${timeFromLastTrajectory}" \
           "$(awk '{if($1 ~ /^[[:digit:]]+$/ && $2 ~ /^[[:digit:]]+$/){printf "%ds%7ds", $1, $2}else{print "notMeasured"}}' <<< "${timeLastTrajectory} ${averageTimePerTrajectory}")"
}

function __static__PrintSimulationStatusFooter()
{
    local terminalWidth separator index
    terminalWidth=$(tput cols)
    separator=''
    for((index=0; index<terminalWidth-1; index++)); do
        separator+='='
    done
    cecho "${BHMAS_defaultListstatusColor}${separator}"
}

function __static__GetShortenedBetaString()
{
    local runId; runId="$1"
    declare -A shortPostfix=(
        ['continueWithNewChain']='NC'
        ['thermalizeFromHot']='fH'
        ['thermalizeFromConf']='fC'
    )
    printf "${runId%_*}_${shortPostfix[${runId##*_}]}"
}

function GoodAcc()
{
    awk -v tl="${BHMAS_tooLowAcceptanceListstatusColor/\\/\\\\}" \
        -v l="${BHMAS_lowAcceptanceListstatusColor/\\/\\\\}" \
        -v op="${BHMAS_optimalAcceptanceListstatusColor/\\/\\\\}" \
        -v h="${BHMAS_highAcceptanceListstatusColor/\\/\\\\}" \
        -v th="${BHMAS_tooHighAcceptanceListstatusColor/\\/\\\\}" \
        -v tlt="${BHMAS_tooLowAcceptanceThreshold}" \
        -v lt="${BHMAS_lowAcceptanceThreshold}" \
        -v ht="${BHMAS_highAcceptanceThreshold}" \
        -v tht="${BHMAS_tooHighAcceptanceThreshold}" '{if($1<tlt){print tl}else if($1<lt){print l}else if($1>tht){print th}else if($1>ht){print h}else{print op}}' <<< "$1"
}

function __static__ColorStatus()
{
    if [[ $1 == "RUNNING" ]]; then
        printf ${BHMAS_runningListstatusColor}
    elif [[ $1 == "PENDING" ]]; then
        printf ${BHMAS_pendingListstatusColor}
    else
        printf ${BHMAS_defaultListstatusColor}
    fi
}

function __static__ColorTime()
{
    if [[ ! $1 =~ ^[[:digit:]]+$ ]]; then
        printf ${BHMAS_defaultListstatusColor}
    else
        [[ $1 -gt 450 ]] && printf ${BHMAS_stuckSimulationListstatusColor} || printf ${BHMAS_fineSimulationListstatusColor}
    fi
}

function __static__ColorClean()
{
    [[ $1 -eq 0 ]] && printf ${BHMAS_defaultListstatusColor} || printf ${BHMAS_toBeCleanedListstatusColor}
}

function __static__ColorBeta()
{
    if [[ ! -f ${outputFileGlobalPath} ]]; then
        printf ${BHMAS_defaultListstatusColor}
        return
    fi
    local errorCode
    set +e
    __static__CheckCorrectnessOutputFile "${outputFileGlobalPath}"
    errorCode=$?
    set -e
    if [[ ${errorCode} -eq ${BHMAS_successExitCode} ]]; then
        printf ${BHMAS_defaultListstatusColor}
    elif [[ ${errorCode} -eq ${BHMAS_fatalLogicError} ]]; then
        printf ${BHMAS_wrongBetaListstatusColor}
    else
        printf ${BHMAS_suspiciousBetaListstatusColor}
    fi
}

# This function has to invoke correctly the awk script to check the correctness of the output file
# and return 0 if it is fine and 1 if not. The arguments in input are the following:
#
#  $1 -> outputFileGlobalPath
#
function __static__CheckCorrectnessOutputFile()
{
    #Columns here below ranges from 1 on, since they are used in awk
    declare -A observablesColumns=( ["TrajectoryNr"]=1
                                    ["Plaquette"]=${BHMAS_plaquetteColumn}
                                    ["PlaquetteSpatial"]=3
                                    ["PlaquetteTemporal"]=4
                                    ["PolyakovLoopRe"]=5
                                    ["PolyakovLoopIm"]=6
                                    ["PolyakovLoopSq"]=7
                                    ["Accepted"]=${BHMAS_acceptanceColumn} )
    local auxiliaryVariable1 auxiliaryVariable2 errorCode
    auxiliaryVariable1=$(printf "%s," "${observablesColumns[@]}")
    auxiliaryVariable2=$(printf "%s," "${!observablesColumns[@]}")

    awk -v obsColumns="${auxiliaryVariable1%?}" \
        -v obsNames="${auxiliaryVariable2%?}" \
        -v wrongVariable="${BHMAS_fatalVariableUnset}" \
        -v success="${BHMAS_successExitCode}" \
        -v failure="${BHMAS_fatalLogicError}" \
        -f ${BHMAS_repositoryTopLevelPath}/Generic_Code/CheckCorrectnessOutputFile.awk "$1"
}

function __static__ColorDelta()
{
    if [[ ! $1 =~ ^[PS]$ ]] || [[ ! $2 =~ [+-]?[[:digit:]]+[.]?[[:digit:]]* ]]; then
        printf ${BHMAS_defaultListstatusColor}
    else
        local thresholdVariableName tooHighColorVariableName
        thresholdVariableName="BHMAS_delta${1}Threshold"
        tooHighColorVariableName="BHMAS_tooHighDelta${1}ListstatusColor"
        if [[ "${postfixFromFolder}" == "continueWithNewChain" ]] && [[ $(awk -v threshold=${!thresholdVariableName} -v value=$2 'BEGIN{if(value >= threshold)print 1; else print 0;}') -eq 1 ]]; then
            printf ${!tooHighColorVariableName}
        else
            printf ${BHMAS_defaultListstatusColor}
        fi
    fi
}


MakeFunctionsDefinedInThisFileReadonly
