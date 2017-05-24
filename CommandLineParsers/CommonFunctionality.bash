#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

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
