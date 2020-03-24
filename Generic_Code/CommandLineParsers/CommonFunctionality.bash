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

#NOTE: We want to discard a potential equal sign between option name
#      and option value, but still we want to allow a potential equal
#      sign in the option value. Hence it is wrong to blindly replace
#      all the equal signs by spaces. Execution modes do not accept
#      a value and, then, we can iterate over the command line
#      options and if we encounter an option (string starting with'-')
#      we act as following:
#         i) the part before an equal sign if present
#            is the option name and it is saved
#        ii) a value is given to the option if
#             - the option contains an '=' sign
#             - the following argument is a '='
#             - the following argument contains a '='
#            the value is processed ('=' removed if needed) and stored
#
#       This of course rely on the rule that no equal sign can be part
#       neither of an execution mode name nor of an option.
#
#NOTE: The following two functions will be used with readarray and therefore
#      the printf in the end uses '\n' as separator (this preserves spaces
#      in options)
function PrepareGivenOptionToBeProcessed()
{
    local newOptions value index
    newOptions=()
    while [[ $# -ne 0 ]]; do
        case "$1" in
            -* )
                newOptions+=( "${1%%=*}" )
                if [[ "$1" = *=* ]]; then # Otherwise value gets set to option value
                    value="${1#*=}"
                else
                    value=''
                fi
                if [[ "${value}" != '' ]]; then
                    newOptions+=( "${value}" )
                elif [[ "${2-}" != -* ]]; then # Another option follows
                    if [[ "$1" =~ = ]]; then # equal was in $1, do not remove it in $2
                        # If $2 was not given but '=' is in $1 then add empty value
                        newOptions+=( "${2-}" )
                        shift
                    elif [[ "${2-}" = '=' ]]; then # Single equal sign following
                        # If $3 was not given but $2 is '=' then add empty value
                        newOptions+=( "$3" )
                        shift 2
                    elif [[ "${2-}" =~ = ]]; then # fill value if required
                        newOptions+=( "${2#=}" )
                        shift
                    fi
                fi
                ;;
            * )
                newOptions+=( "$1" )
        esac
        shift
    done
    printf "%s\n" "${newOptions[@]}"
}

function SplitCombinedShortOptionsInSingleOptions()
{
    local newOptions value option splittedOptions
    newOptions=()
    for value in "$@"; do
        if [[ ${value} =~ ^-[[:alpha:]]+$ ]]; then
            splittedOptions=( $(grep -o "." <<< "${value:1}") )
            for option in "${splittedOptions[@]}"; do
                newOptions+=( "-${option}" )
            done
        else
            newOptions+=( "${value}" )
        fi
    done
    printf "%s\n" "${newOptions[@]}"
}

function __static__ReplaceShortOptionsWithLongOnesAndFillGlobalArray()
{
    declare -A mapOptions=(['-a']='--all'
                           ['-c']='--continue'
                           ['-C']='--continueThermalization'
                           ['-d']='--database'
                           ['-f']='--confSaveFrequency'
                           ['-F']='--confSavePointFrequency'
                           ['-i']='--invertConfigurations'
                           ['-j']='--jobstatus'
                           ['-m']='--measurements'
                           ['-p']='--doNotMeasurePbp'
                           ['-s']='--submit'
                           ['-t']='--thermalize'
                           ['-U']='--uncommentBetas'
                           ['-w']='--walltime' )
    local option databaseOption
    databaseOption='FALSE'
    BHMAS_specifiedCommandLineOptions=() # Empty it to fill it again with only long options
    for option in "$@"; do
        #Replace short options if they are NOT for dabase!
        if [[ ${databaseOption} = 'FALSE' ]]; then
           KeyInArray ${option} mapOptions && option=${mapOptions[${option}]}
           #More logic for repeated short options with different long one
           if [[ ${option} = '-l' ]]; then
               if ElementInArray '--jobstatus' "${BHMAS_specifiedCommandLineOptions[@]}"; then
                   option='--local'
               else
                   option='--liststatus'
               fi
           elif [[ ${option} = '-u' ]]; then
               if ElementInArray '--jobstatus' "${BHMAS_specifiedCommandLineOptions[@]}"; then
                   option='--user'
               else
                   option='--commentBetas'
               fi
           elif [[ ${option} = '-h' ]]; then
               option='--help'
           fi
        else
           if [[ ${option} = '-h' ]]; then
               option='--helpDatabase'
           fi
        fi
        BHMAS_specifiedCommandLineOptions[${#BHMAS_specifiedCommandLineOptions[@]}]="${option}"
        if ElementInArray '--database' "${BHMAS_specifiedCommandLineOptions[@]}"; then
            databaseOption='TRUE'
        fi
    done
}

function PrepareGivenOptionToBeParsedAndFillGlobalArrayContainingThem()
{
    local partiallyProcessedCommandLineOptions
    if [[ ${#BHMAS_specifiedCommandLineOptions[@]} -ne 0 ]]; then
        #The following two lines are not combined to respect potential spaces in options
        readarray -t partiallyProcessedCommandLineOptions <<< "$(PrepareGivenOptionToBeProcessed "${BHMAS_specifiedCommandLineOptions[@]}")"
        readarray -t partiallyProcessedCommandLineOptions <<< "$(SplitCombinedShortOptionsInSingleOptions "${partiallyProcessedCommandLineOptions[@]}")"
        __static__ReplaceShortOptionsWithLongOnesAndFillGlobalArray "${partiallyProcessedCommandLineOptions[@]}"
        readonly BHMAS_specifiedCommandLineOptions
    fi
    #Create a to-be-modified array with options to be parsed
    BHMAS_commandLineOptionsToBeParsed=( "${BHMAS_specifiedCommandLineOptions[@]}" )
}

function PrintInvalidOptionErrorAndExit()
{
    Fatal ${BHMAS_fatalCommandLine} "Invalid option " emph "$1" " specified! Use the " emph "--help" " option to get further information."
}

function PrintOptionSpecificationErrorAndExit()
{
    Fatal ${BHMAS_fatalCommandLine} "The value of the option " emph "$1" " was not correctly specified (either " emph "forgotten" " or " emph "invalid" ")!"
}


MakeFunctionsDefinedInThisFileReadonly
