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

function ParseCommandLineOption()
{
    local commandLineOptions testsNumericList testsNameList number testName
    while [[ "$1" != "" ]]; do
        case $1 in
            -h | --help )
                __static__PrintHelper
                exit ${BHMAS_successExitCode}
                shift ;;
            -r | --reportLevel )
                if [[ $2 =~ ^[0-3]$ ]]; then
                    reportLevel=$2
                else
                    __static__PrintOptionSpecificationErrorAndExit $1
                fi
                shift 2 ;;
            -t | --runTests )
                if [[ ! $2 =~ ^- ]] && [[ "$2" != '' ]]; then
                    if [[ $2 =~ ^[1-9][0-9]*([,\-][1-9][0-9]*)*$ ]]; then
                        testsNumericList=( $(awk 'BEGIN{RS=","}/\-/{split($0, res, "-"); for(i=res[1]; i<=res[2]; i++){printf "%d\n", i}; next}{printf "%d\n", $0}' <<< $2) )
                        testsNameList=()
                        for number in "${testsNumericList[@]}"; do
                            (( number-- ))
                            if [[ ${number} -ge ${#testsToBeRun[@]} ]]; then
                                Fatal ${BHMAS_fatalCommandLine} "Specified tests numbers " emph "$2" " not available!"
                            fi
                            testsNameList+=( "${testsToBeRun[${number}]}" )
                        done
                        testsToBeRun=( "${testsNameList[@]}" )
                    elif [[ $2 =~ ^[[:alpha:]*] ]]; then
                        testsNameList=()
                        for testName in "${testsToBeRun[@]}"; do
                            if [[ ${testName} = $2 ]]; then
                                testsNameList+=( "${testName}" )
                            fi
                        done
                        testsToBeRun=( "${testsNameList[@]}" )
                        if [[ ${#testsToBeRun[@]} -eq 0 ]]; then
                            Fatal ${BHMAS_fatalCommandLine} 'No test name found matching ' emph "$2" ' globbing pattern!'
                        fi
                    else
                        __static__PrintOptionSpecificationErrorAndExit $2
                    fi
                else
                    __static__PrintListOfTests
                    exit ${BHMAS_successExitCode}
                fi
                shift 2 ;;
            -l | --doNotCleanTestFolder )
                cleanTestFolder='FALSE'
                shift ;;
            * )
                Fatal ${BHMAS_fatalCommandLine} "Invalid option " emph "$1" " specified! Use the " emph "--help" " option to get further information." ;;
        esac
    done
}

function __static__AddOptionToHelper()
{
    local name description color lengthOption indentation
    lengthOption=28; indentation='    '
    color="${normalColor}"
    name="$1"; description="$2"; shift 2
    cecho ${color} "$(printf "%s%-${lengthOption}s" "${indentation}" "${name}")" d "  ->  " ${helperColor} "${description}"
    while [[ "$1" != '' ]]; do
        cecho "$(printf "%s%${lengthOption}s" "${indentation}" "")      " ${helperColor} "$1"
        shift
    done
}

function __static__PrintHelper()
{
    local helperColor normalColor
    helperColor='g'; normalColor='lc'
    cecho -d ${helperColor}
    cecho -d " Call " B "BaHaMAS tests" uB " with the following optional arguments:" "\n"
    __static__AddOptionToHelper "-h | --help"        "Print this help"
    __static__AddOptionToHelper "-r | --reportLevel" "Verbosity of test report. To be chosen among"\
                                "0 = binary, 1 = summary, 2 = short, 3 = detailed"\
                                "(default value 1)."
    __static__AddOptionToHelper "-t | --runTests"    "Specify which tests have to be run."\
                                "Comma-separated numbers or intervals (e.g. 1,3-5)"\
                                "or a string (e.g. CL2QCD*) have to be specified."\
                                "The string is matched against test names using"\
                                "shell regular globbing. If no value is specified"\
                                "the available tests list is printed."
    __static__AddOptionToHelper "-l | --doNotCleanTestFolder" "Leave all the created folders and"\
                                "files in the BaHaMAS test folder."
    cecho ''
    cecho ly " Values from options must be separated by space and short options cannot be combined.\n"
}

function __static__PrintListOfTests()
{
    local index list termCols longestString colsWidth maxNumCols formatString
    cecho B lm "\n " U "List of available tests" uU ":\n"
    list=( "${testsToBeRun[@]}" )
    for index in "${!list[@]}" ; do  list[${index}]="$(cecho -d -n bb "$(printf "%2d)" "$((index+1))") " lp "${list[${index}]}")"; done
    termCols=$(tput cols)
    longestString=$(printf "%s\n" "${list[@]}" | awk '{print length}' | sort -n | tail -n1)
    colsWidth=$((longestString+3))
    maxNumCols=$((termCols/colsWidth))
    formatString=""; for((index=0; index<maxNumCols; index++)); do formatString+="%-${colsWidth}s"; done
    printf "${formatString}\n" "${list[@]}"
    cecho ''
    #TODO: Print list going vertically and not horizontally!
}

function __static__PrintOptionSpecificationErrorAndExit()
{
    Fatal ${BHMAS_fatalCommandLine} "The value of the option " emph "$1" " was not correctly specified (either " emph "forgotten" " or " emph "invalid" ")!"
}


MakeFunctionsDefinedInThisFileReadonly
