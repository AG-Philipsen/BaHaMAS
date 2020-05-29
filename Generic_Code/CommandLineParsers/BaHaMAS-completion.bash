#!/usr/bin/env bash
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

# This script will be sourced in the user shell login file and
# it needs to know the BaHaMAS codebase position in order to
# source the information about command line options. The path
# to the top-level of BaHaMAS should be given as first argument.
# Warn and provide only completion for execution mode if this
# is not the case.
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
    printf "\n ERROR: File \"${BASH_SOURCE[0]}\" cannot be executed!\n\n"
    exit 1
else
    fileWithOptions="$(dirname "${BASH_SOURCE[0]}")/AllowedOptions.bash"
    if ! source "${fileWithOptions}"  >> /dev/null 2>&1; then
        printf '\n'
        printf "%s\n"\
               " WARNING: File \"${fileWithOptions}\""\
               '          has not been found! Providing only basic autocompletion for BaHaMAS.'
        printf '\n'
    fi
    unset -v 'fileWithOptions'
    # The following line turns on shopt for the shell, what is usually anyway
    # done underneath by bash autocompletion itself e.g. in
    # /usr/share/bash-completion/bash_completion
    shopt -s extglob
fi

function _BaHaMAS_completions()
{
    # This function is called by "complete -F" command, hence:
    #   $1 is the name of the command whose arguments are being completed
    #   $2 is the word being completed, and
    #   $3 is the word preceding the word being completed
    local availableLqcdSoftware generalOptions availableModes\
          softwareCaseString modeCaseString BHMAS_AUTOCOMPLETION\
          listOfOptionsToProposeAsString option
    declare -A allowedOptionsPerModeOrSoftware
    BHMAS_AUTOCOMPLETION='TRUE' # to gather all allowed options!
    availableLqcdSoftware=(
        'CL2QCD'
        'openQCD-FASTSUM'
    )
    generalOptions=(
        'help'          '--help'
        'version'       '--version'
        'setup'         '--setup'
    )
    availableModes=(
        'prepare-only'  'continue'  'continue-thermalization'
        'submit-only'   'new-chain' 'thermalize'
        'job-status'    'simulation-status'
        'measure'       'acceptance-rate-report'
        'database'      'clean-output-files'
        'comment-betas' 'uncomment-betas'
        'complete-betas-file'
    )
    # We need extglob to match as we wish in case pattern through a variable,
    # and we assume it is on, which is ensured at the beginning of this script
    softwareCaseString=$(IFS='|'; printf "+(${availableLqcdSoftware[*]})")
    if [[ "$(type -t _BaHaMAS_DeclareAllowedOptionsPerModeOrSoftware)" = 'function' ]]; then
        _BaHaMAS_DeclareAllowedOptionsPerModeOrSoftware
    fi

    # If a mode with or without a software has been given, we need
    # to handle options in a way that the user can continue using
    # autocompletion on new ones, getting only the unused ones proposed
    #
    # NOTE: We check if elements are in an array assuming that no spaces
    #       are contained in the arrays above, which is indeed the case!
    if [[ " ${availableModes[@]} " =~ \ (${COMP_WORDS[1]}|${COMP_WORDS[2]})\  ]]; then
        if [[ " ${availableLqcdSoftware[@]} " =~ \ ${COMP_WORDS[1]}\  ]]; then
            selectedMode=${COMP_WORDS[2]}
            listOfOptionsToProposeAsString="${allowedOptionsPerModeOrSoftware[mode:${selectedMode}_${COMP_WORDS[1]}]}"
        else
            selectedMode=${COMP_WORDS[1]}
            listOfOptionsToProposeAsString=''
        fi
        listOfOptionsToProposeAsString+="${allowedOptionsPerModeOrSoftware[mode:${selectedMode}]}"
        #Ensure spaces at the edges of the string to allow following mechanism to work
        listOfOptionsToProposeAsString=" ${listOfOptionsToProposeAsString} "
        for option in "${COMP_WORDS[@]:2}"; do
            if [[ ! ${option} =~ ^-- ]]; then
                continue
            fi
            # In the following command, the spaces around ${option} ensure a full option match
            listOfOptionsToProposeAsString="${listOfOptionsToProposeAsString/ ${option} / }"
            if [[ "${option}" = "$3" ]]; then
                break
            fi
        done
    else
        case "$3" in
            BaHaMAS )
                listOfOptionsToProposeAsString="${availableLqcdSoftware[*]} ${generalOptions[*]} ${availableModes[*]}"
                ;;
            ${softwareCaseString} )
                listOfOptionsToProposeAsString="${availableModes[*]}"
                ;;
            * )
                # Here either the user gave an unknown option or
                ;;
        esac
    fi
    COMPREPLY=( $(compgen -W "${listOfOptionsToProposeAsString}" -- "$2") )
}


complete -F _BaHaMAS_completions BaHaMAS
