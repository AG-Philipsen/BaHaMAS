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
#      all the equal signs by spaces. We then iterate over the command
#      line arguments and
#       1) If the argument starts with '-' we remove only the first equal
#          sign, if present
#       2) If the argument does not start with '-' then we remove an equal
#          sign, only if it is present as first character of the argument
#
#NOTE: The following two functions will be used with readarray and therefore
#      the printf in the end uses '\n' as separator (this preserves spaces
#      in options)
function PrepareGivenOptionToBeProcessed()
{
    local newOptions value tmp
    newOptions=()
    for value in "$@"; do
        [ "$value" = '=' ] && continue
        if [[ $value =~ ^-.*=.* ]]; then
            tmp="$(sed 's/=/ /' <<< "$value")"
            newOptions+=( ${tmp%% *} )  #Part before '=' without spaces (option name)
            newOptions+=( "${tmp#* }" ) #Part after '=' potentially with spaces
        else
            newOptions+=( "$(sed 's/^=//' <<< "$value")" )
        fi
    done
    printf "%s\n" "${newOptions[@]}"
}

function SplitCombinedShortOptionsInSingleOptions()
{
    local newOptions value option splittedOptions
    newOptions=()
    for value in "$@"; do
        if [[ $value =~ ^-[[:alpha:]]+$ ]]; then
            splittedOptions=( $(grep -o "." <<< "${value:1}") )
            for option in "${splittedOptions[@]}"; do
                newOptions+=( "-$option" )
            done
        else
            newOptions+=( "$value" )
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
    for option in "${commandLineOptions[@]}"; do
        #Replace short options if they are NOT for dabase!
        if [ $databaseOption = 'FALSE' ]; then
           KeyInArray $option mapOptions && option=${mapOptions[$option]}
           #More logic for repeated short options with different long one
           if [ $option = '-l' ]; then
               if ElementInArray '--jobstatus' "${arrayNameWhereToStoreTheProcessedOptions[@]:-}"; then
                   option='--local'
               else
                   option='--liststatus'
               fi
           elif [ $option = '-u' ]; then
               if ElementInArray '--jobstatus' "${arrayNameWhereToStoreTheProcessedOptions[@]:-}"; then
                   option='--user'
               else
                   option='--commentBetas'
               fi
           elif [ $option = '-h' ]; then
               option='--help'
           fi
        else
           if [ $option = '-h' ]; then
               option='--helpDatabase'
           fi
        fi
        arrayNameWhereToStoreTheProcessedOptions[${#arrayNameWhereToStoreTheProcessedOptions[@]}]="$option"
        if ElementInArray '--database' "${arrayNameWhereToStoreTheProcessedOptions[@]}"; then
            databaseOption='TRUE'
        fi
    done
}

function PrepareGivenOptionToBeParsedAndFillGlobalArrayContainingThem()
{
    local arrayNameWhereToStoreTheProcessedOptions commandLineOptions
    declare -ga $1=\(\)
    declare -n arrayNameWhereToStoreTheProcessedOptions=$1; shift #Reference to variable
    #The following two lines are not combined to respect potential spaces in options
    readarray -t commandLineOptions <<< "$(PrepareGivenOptionToBeProcessed "$@")"
    readarray -t commandLineOptions <<< "$(SplitCombinedShortOptionsInSingleOptions "${commandLineOptions[@]}")"
    __static__ReplaceShortOptionsWithLongOnesAndFillGlobalArray
}


function PrintHelperAndExitIfUserAskedForIt()
{
    if ElementInArray '--help' "$@"; then
        PrintMainHelper; exit $BHMAS_successExitCode
    elif ElementInArray '--helpDatabase' "$@"; then
        PrintDatabaseHelper; exit $BHMAS_successExitCode
    else
        return 0
    fi
}

function PrintInvalidOptionErrorAndExit()
{
    Fatal $BHMAS_fatalCommandLine "Invalid option " emph "$1" " specified! Use the " emph "--help" " option to get further information."
}

function PrintOptionSpecificationErrorAndExit()
{
    Fatal $BHMAS_fatalCommandLine "The value of the option " emph "$1" " was not correctly specified (either " emph "forgotten" " or " emph "invalid" ")!"
}


MakeFunctionsDefinedInThisFileReadonly
