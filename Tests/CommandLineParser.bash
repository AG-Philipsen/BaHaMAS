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

source ${BHMAS_repositoryTopLevelPath}/CommandLineParsers/CommonFunctionality.bash || exit $BHMAS_fatalBuiltin

function __static__AddOptionToHelper()
{
    local name description color lengthOption indentation
    lengthOption=28; indentation='    '
    color="$normalColor"
    name="$1"; description="$2"; shift 2
    cecho $color "$(printf "%s%-${lengthOption}s" "$indentation" "$name")" d "  ->  " $helperColor "$description"
    while [ "$1" != '' ]; do
        cecho "$(printf "%s%${lengthOption}s" "$indentation" "")      " $helperColor "$1"
        shift
    done
}
function __static__PrintHelper()
{
    local helperColor normalColor
    helperColor='g'; normalColor='m'
    cecho -d $helperColor
    cecho -d " Call " B "BaHaMAS tests" uB " with the following optional arguments:" "\n"
    __static__AddOptionToHelper "-h | --help"        "Print this help"
    __static__AddOptionToHelper "-r | --reportLevel" "Verbosity of test report. To be chosen among"\
                                "0 = binary, 1 = summary, 2 = short, 3 = detailed"\
                                "(default value 1)."
    __static__AddOptionToHelper "-t | --runTests"    "Specify which tests have to be run."\
                                "Comma-separated numbers or intervals (e.g. 1,3-5)"\
                                "have to be specified. If no number is specified,"\
                                "the available tests list is printed."
    __static__AddOptionToHelper "-l | --doNotCleanTestFolder" "Leave all the created folders and"\
                                "files in the BaHaMAS test folder."
    cecho ''
}
function __static__PrintListOfTests()
{
    local index list termCols longestString colsWidth maxNumCols formatString
    cecho B lm "\n " U "List of available tests" uU ":\n"
    list=( "${testsToBeRun[@]}" )
    for index in "${!list[@]}" ; do  list[$index]="$(cecho -d -n bb "$(printf "%2d)" "$((index+1))") " lp "${list[$index]}")"; done
    termCols=$(tput cols)
    longestString=$(printf "%s\n" "${list[@]}" | awk '{print length}' | sort -n | tail -n1)
    colsWidth=$((longestString+3))
    maxNumCols=$((termCols/colsWidth))
    formatString=""; for((index=0; index<maxNumCols; index++)); do formatString+="%-${colsWidth}s"; done
    printf "$formatString\n" "${list[@]}"
    cecho ''
    #TODO: Print list going vertically and not horizontally!
}


function ParseCommandLineOption()
{
    local commandLineOptions testsNumericList testsNameList number

    #The following two lines are not combined to respect potential spaces in options
    readarray -t commandLineOptions <<< "$(PrepareGivenOptionToBeProcessed "$@")"
    readarray -t commandLineOptions <<< "$(SplitCombinedShortOptionsInSingleOptions "${commandLineOptions[@]}")"
    #Reset argument function to be able to parse them
    set -- "${commandLineOptions[@]}"

    while [ "$1" != "" ]; do
        case $1 in
            -h | --help )
                __static__PrintHelper
                exit $BHMAS_successExitCode
                shift ;;

            -r | --reportLevel )
                if [[ $2 =~ ^[0-3]$ ]]; then
                    reportLevel=$2
                else
                    PrintOptionSpecificationErrorAndExit $1
                fi
                shift 2 ;;
            -t | --runTests )
                if [[ ! $2 =~ ^- ]] && [ "$2" != '' ]; then
                    if [[ $2 =~ ^[1-9][0-9]*([,\-][1-9][0-9]*)*$ ]]; then
                        testsNumericList=( $(awk 'BEGIN{RS=","}/\-/{split($0, res, "-"); for(i=res[1]; i<=res[2]; i++){printf "%d\n", i}; next}{printf "%d\n", $0}' <<< $2) )
                        testsNameList=()
                        for number in "${testsNumericList[@]}"; do
                            (( number-- ))
                            if [ $number -ge ${#testsToBeRun[@]} ]; then
                                Fatal $BHMAS_fatalCommandLine "Specified tests numbers " emph "$2" " not available!"
                            fi
                            testsNameList+=( "${testsToBeRun[$number]}" )
                        done
                        testsToBeRun=( "${testsNameList[@]}" )
                    else
                        PrintOptionSpecificationErrorAndExit $2
                    fi
                else
                    __static__PrintListOfTests
                    exit $BHMAS_successExitCode
                fi
                shift 2 ;;
            -l | --doNotCleanTestFolder )
                cleanTestFolder='FALSE'
                shift ;;
            * )
                PrintInvalidOptionErrorAndExit $1 ;;
        esac
    done
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         __static__AddOptionToHelper\
         __static__PrintHelper\
         __static__PrintListOfTests\
         ParseCommandLineOption
