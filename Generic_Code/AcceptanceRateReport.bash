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

function AcceptanceRateReport()
{
    local runId betaValuesCopy index
    betaValuesCopy=(${BHMAS_betaValues[@]})
    BHMAS_simulationStatusVerbose='TRUE' #Patch to activate error messages in CreateOutputFileInTheStandardFormat function
    for INDEX in "${!betaValuesCopy[@]}"; do
        runId="${betaValuesCopy[${INDEX}]}"
        local outputFileGlobalPath="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}/${BHMAS_outputStandardizedFilename}"
        if ! CreateOutputFileInTheStandardFormat "${runId}"; then
            Error 'File ' file "${BHMAS_outputStandardizedFilename}" " failed to be created in\n"\
                  dir "$(dirname "${outputFileGlobalPath}")"\
                  "\n folder! The " emph "run ID = ${betaValuesCopy[${INDEX}]}" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( ${betaValuesCopy[${INDEX}]} )
            unset betaValuesCopy[${INDEX}] #Here betaValuesCopy becomes sparse
        fi
    done
    #Make betaValuesCopy not sparse if not empty
    if [[ ${#betaValuesCopy[@]} -eq 0 ]]; then
        cecho '' && return
    else
        betaValuesCopy=( ${betaValuesCopy[@]} )
    fi

    #Implementation of the report
    local columnsNumberOfLines dataArray betaStringPositionInDataArray\
          numberOfLines counter positionIndex lengthOfLongestColumn\
          emptySeparator spaceAtTheBeginningOfEachLine\
          spaceAfterAcceptanceField acceptanceFieldLength lineOfEquals\
          position dataIndex
    columnsNumberOfLines=()
    dataArray=()
    betaStringPositionInDataArray=()
    #Loop on betas and calculate acceptance concatenating data in single array
    for runId in ${betaValuesCopy[@]}; do
        outputFileGlobalPath="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${runId}/${BHMAS_outputStandardizedFilename}"
        columnsNumberOfLines+=( $(awk '{if(NR%'${BHMAS_accRateReportInterval}'==0){counter++;}}END{print counter}' ${outputFileGlobalPath}) )
        betaStringPositionInDataArray+=( ${#dataArray[@]} )
        dataArray+=( "b${runId%_*}" )
        dataArray+=( $(awk '{if(NR%'${BHMAS_accRateReportInterval}'==0){printf("%.2f \n", sum/'${BHMAS_accRateReportInterval}'*100);sum=0}}{sum+=$'${BHMAS_acceptanceColumn}'}' ${outputFileGlobalPath}) )
    done
    #Find largest number of intervals to print table properly
    lengthOfLongestColumn=0
    for numberOfLines in ${columnsNumberOfLines[@]}; do
        [[ ${numberOfLines} -gt ${lengthOfLongestColumn} ]] && lengthOfLongestColumn=${numberOfLines}
    done
    #Print table in proper form
    printf -v spaceAtTheBeginningOfEachLine '%*s' 10 ''
    emptySeparator="   "
    #Here we evaluate the numbers to center the acceptance under the beta header:
    #
    #     |----beta_header----|
    #             xx.yy
    #      <----------------->    this is ${#dataArray[0]}
    #             <--->           this is 5 (for the moment hard coded)
    #                  <----->    this is (${#dataArray[0]} - 5 + 1)/2 where the +1 is to put one more in case of odd result of the subtraction
    #      <---------->           this is ${#dataArray[0]} - (${#dataArray[0]} - 5 + 1)/2
    #
    spaceAfterAcceptanceField=$(( (${#dataArray[0]} - 5 + 1)/2 )) #The first entry in dataArray is a beta that is print in the header
    acceptanceFieldLength=$(( ${#dataArray[0]} - ${spaceAfterAcceptanceField} ))

    # Print Header
    printf -v lineOfEquals '%*s' $((9 + (${#betaValuesCopy[@]} + 1) * (2 *  ${#emptySeparator}) + ${#betaValuesCopy[@]} * ${#dataArray[0]} )) ''
    cecho lc "\n${spaceAtTheBeginningOfEachLine}${lineOfEquals// /=}"
    counter=0
    cecho lp -n "${spaceAtTheBeginningOfEachLine}${emptySeparator}Intervals${emptySeparator}"
    while [[ ${counter} -lt ${#betaValuesCopy[@]} ]]; do
        cecho lp -n "$(printf "${emptySeparator}%s${emptySeparator}" ${dataArray[${betaStringPositionInDataArray[${counter}]}]})"
        (( counter++ )) || true #'|| true' because of set -e option
    done
    cecho lc "\n${spaceAtTheBeginningOfEachLine}${lineOfEquals// /=}"

    # Print Body
    counter=1
    while [[ ${counter} -le ${lengthOfLongestColumn} ]];do
        cecho -n "$(printf "${spaceAtTheBeginningOfEachLine}${emptySeparator}%6d   ${emptySeparator}" ${counter})"
        local positionIndex=1
        for position in ${betaStringPositionInDataArray[@]}; do
            dataIndex=$(expr ${position} + ${counter})
            if [[ ${positionIndex} -eq ${#betaStringPositionInDataArray[@]} ]]; then                  # "If I am printing the last column"
                if [[ ${dataIndex} -lt ${#dataArray[@]} ]]; then                                     # "If there are still data to print, print"
                    cecho -n "$(printf "$(GoodAcc ${dataArray[${dataIndex}]})${emptySeparator}%${acceptanceFieldLength}s%${spaceAfterAcceptanceField}s${emptySeparator}\e[0m" ${dataArray[${dataIndex}]} "")"
                else                                                                               # "otherwise print blank space"
                    cecho -n "{${emptySeparator}}${emptySeparator}"
                fi
            elif [[ ${positionIndex} -lt ${#betaStringPositionInDataArray[@]} ]]; then                # "If I am printing not the last column"
                if [[ ${dataIndex} -lt ${betaStringPositionInDataArray[${positionIndex}]} ]]; then     # "If there are still data to print, print"
                    cecho -n "$(printf "$(GoodAcc ${dataArray[${dataIndex}]})${emptySeparator}%${acceptanceFieldLength}s%${spaceAfterAcceptanceField}s${emptySeparator}\e[0m" ${dataArray[${dataIndex}]} "")"
                else                                                                               # "otherwise print blank space"
                    cecho -n "${emptySeparator}${emptySeparator}"
                fi
            fi
            (( positionIndex++ ))
        done
        cecho ''
        (( counter++ ))
    done
    cecho lc "${spaceAtTheBeginningOfEachLine}${lineOfEquals// /=}"

}


MakeFunctionsDefinedInThisFileReadonly
