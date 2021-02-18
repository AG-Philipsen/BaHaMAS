#
#  Copyright (c) 2017,2020-2021 Alessandro Sciarra
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

function AcceptanceRateReport()
{
    local runId betaValuesCopy index outputFileGlobalPath
    betaValuesCopy=( "${BHMAS_betaValues[@]}" )
    BHMAS_simulationStatusVerbose='TRUE' #Patch to activate error messages in CreateOutputFileInTheStandardFormat function
    for index in "${!betaValuesCopy[@]}"; do
        runId="${betaValuesCopy[${index}]}"
        outputFileGlobalPath="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}/${BHMAS_outputStandardizedFilename}"
        if ! CreateOutputFileInTheStandardFormat "${runId}"; then
            Error 'File ' file "${BHMAS_outputStandardizedFilename}" " failed to be created in\n"\
                  dir "$(dirname "${outputFileGlobalPath}")"\
                  "\n folder! The " emph "run ID = ${betaValuesCopy[${index}]}" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( ${betaValuesCopy[${index}]} )
            unset 'betaValuesCopy[${index}]' #Here betaValuesCopy becomes sparse
        fi
    done
    if [[ ${#betaValuesCopy[@]} -eq 0 ]]; then
        cecho '' && return
    else
        betaValuesCopy=( ${betaValuesCopy[@]} )
    fi

    # Implementation of the report
    #
    # NOTE: Calculate acceptance rates concatenating data in single array
    #       In dataArray also the ID for the table header are included!
    local dataArray runIdPositionInDataArray lengthOfLongestColumn intervalsPerRunId\
          headerSeparator fieldSeparator indentation lineOfEquals
    dataArray=()
    runIdPositionInDataArray=()
    intervalsPerRunId=()
    for runId in ${betaValuesCopy[@]}; do
        outputFileGlobalPath="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}/${BHMAS_outputStandardizedFilename}"
        runIdPositionInDataArray+=( ${#dataArray[@]} )
        dataArray+=( "${BHMAS_betaPrefix}${runId%_*}" )
        dataArray+=( $(__static__GetAcceptanceRatesOnFile "${outputFileGlobalPath}") ) # Let word splitting split entries
        intervalsPerRunId+=( $(( ${#dataArray[@]} - runIdPositionInDataArray[-1] - 1 )) )
    done
    lengthOfLongestColumn=$(MaximumOfArray "${intervalsPerRunId[@]}")
    __static__SetSpacingVariables
    __static__PrintHeader
    __static__PrintBody
}

#----------------------------------------------------------------#
# The following functions rely on the local variable of the main #
# function above and they are not checked again for existence.   #
#----------------------------------------------------------------#

function __static__GetAcceptanceRatesOnFile()
{
    awk -v width="${BHMAS_accRateReportInterval}"\
        -v column="${BHMAS_acceptanceColumn}"\
        '{
            if(NR%width==0){
                printf("%.2f \n", sum/width*100);
                sum=0
            }
        }
        { sum+=$column }' "$1"
}

function __static__SetSpacingVariables()
{
    printf -v indentation '%*s' 4 ''
    printf -v headerSeparator '%*s' 4 ''
    printf -v fieldSeparator  '%*s' $(( 7 + ${#headerSeparator} )) ''
    printf -v lineOfEquals '%*s' $(( 9 + 2 * ${#headerSeparator} + ${#intervalsPerRunId[@]} * (${#dataArray[0]} + ${#headerSeparator}) )) ''
    lineOfEquals="${lineOfEquals// /=}"
}

function __static__PrintHeader()
{
    local index
    cecho lc "\n${indentation}${lineOfEquals}"
    cecho lp -n "${indentation}${headerSeparator}Intervals"
    for index in ${runIdPositionInDataArray[@]}; do
        cecho lp -n "$(printf "${headerSeparator}%s" ${dataArray[index]})"
    done
    cecho lc "\n${indentation}${lineOfEquals}"
}

function __static__PrintBody()
{
    local index
    for((index=0; index<lengthOfLongestColumn; index++)); do
        cecho "$(__static__GetFormattedLine ${index})"
    done
    cecho lc "${indentation}${lineOfEquals}"
}

function __static__GetFormattedLine()
{
    CheckIfVariablesAreDeclared indentation dataArray runIdPositionInDataArray intervalsPerRunId
    local interval resultingLine index dataIndex tmpData colorData
    interval=$1
    printf -v resultingLine "${indentation}${headerSeparator}%5d" $((interval+1))
    for index in ${!runIdPositionInDataArray[@]}; do
        if [[ ${interval} -ge ${intervalsPerRunId[index]} ]]; then
            tmpData=""
            colorData=""
        else
            (( dataIndex=runIdPositionInDataArray[index]+1+interval ))
            tmpData="${dataArray[${dataIndex}]}"
            colorData="$(GetAcceptanceColor ${dataArray[${dataIndex}]})"
        fi
        printf -v resultingLine "%s${fieldSeparator}${colorData}%6s\e[0m"  "${resultingLine}"  "${tmpData}"
    done
    printf "%s" "${resultingLine}"
}



MakeFunctionsDefinedInThisFileReadonly
