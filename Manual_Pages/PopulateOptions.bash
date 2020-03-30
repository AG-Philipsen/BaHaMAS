#!/bin/bash
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

function GetAllowedOptionsAndPutThemInManualSection()
{
    local classesOfOption class arrayOfOptions extractedOptions
    classesOfOption=( "$@" )
    extractedOptions=''

    # Look for options to be put in manual
    #
    # In the following array assignment, word splitting will split the options and
    # do not assign anything if entry of the associative array is empty
    for class in "$@"; do
        arrayOfOptions=( ${allowedOptionsPerModeOrSoftware["${class}"]} )
        if [[ ${#arrayOfOptions[@]} -eq 0 ]]; then
            continue
        fi
        cecho bb '\n The follwing options where found for ' emph "${class#mode:}" ':'
        for option in "${arrayOfOptions[@]}"; do
            cecho wg "   ${option}"
        done | columns -W $(tput cols | awk '{printf "%d", $1*0.7}')

        #Add particular section if needed
        case "${class}" in
            CL2QCD )
                extractedOptions+=$'# CL2QCD OPTIONS\n\n'
                ;;
            OpenQCD-FASTSUM )
                extractedOptions+=$'# OpenQCD-FASTSUM OPTIONS\n\n'
                ;;
            mode:* )
                ;;
        esac
        # Extracting options from pool
        for option in "${arrayOfOptions[@]}"; do
            case $(grep -cE "^\\${option//-/\\-}[^@]*@${BHMAS_executionMode}@[[:space:]]*$" "${BHMAS_optionPool}") in
                0 )
                    case $(grep -c "^\\${option//-/\\-}[^@]*$" "${BHMAS_optionPool}") in
                        0 )
                            Error 'Option ' emph "${option}"\
                                  ' not found in pool of options (needed for '\
                                  emph "${BHMAS_executionMode#mode:}" ' execution mode).'
                            ;;
                        1 )
                            ;;
                        * )
                            Fatal ${BHMAS_fatalLogicError} 'Option '\
                                  emph "${option}" ' found ' emph 'several times'\
                                  ' in pool of options.'
                            ;;
                    esac
                    ;;
                1 )
                    ;;
                * )
                    Fatal ${BHMAS_fatalLogicError} 'Option '\
                          emph "${option}" ' found ' emph 'several times'\
                          ' for ' emph "${BHMAS_executionMode#mode:}"\
                          ' execution mode in pool of options.'
                    ;;
            esac
            # Command substitution removes trailing newlines -> https://stackoverflow.com/a/15184414
            # Second sed command: remove specific option label, which should not go into the manual
            IFS= read -rd '' tmpString < <( sed -n '/^\'"${option//-/\\-}"'/,/^$/p' "${BHMAS_optionPool}" | sed '1 s/@.*$//')
            extractedOptions+="${tmpString}"
        done
    done

    # Remove 'OPTIONS' section and put in the pool extracted options
    cecho -n bb ' Populating options for ' emph "${BHMAS_executionMode#mode:}" ' execution mode manual...'
    extractedOptions="${extractedOptions//\\/\\\\}" # <- for awk which interpret \- as - otherwise
    awk -i inplace -v newOptions="${extractedOptions%?}"\
        'BEGIN{out=1}
        /^# [-[:alnum:]]+ OPTIONS[[:space:]]*$/ { next }
        /^# OPTIONS[[:space:]]*$/{
            printf "%s\n\n", $0
            print newOptions
            out=0
            next
        }
        /^#/ { out=1 }
        {
            if(out){
                print $0
            }
        }' "${BHMAS_manualFile}"

    cecho bb ' done!\n'
}

#-----------------------------------------------------------------------------------------------------------------#

#This is to have cecho functionality active here
readonly BHMAS_coloredOutput='TRUE'

#Retrieve information from git
readonly BHMAS_repositoryTopLevelPath="$(git -C $(dirname "${BASH_SOURCE[0]}") rev-parse --show-toplevel)"

#Load needed files
readonly BHMAS_filesToBeSourced=(
    "${BHMAS_repositoryTopLevelPath}/Generic_Code/UtilityFunctions.bash"
    "${BHMAS_repositoryTopLevelPath}/Generic_Code/OutputFunctionality.bash"
    "${BHMAS_repositoryTopLevelPath}/Generic_Code/CommandLineParsers/MainParser.bash"
)
#Source error codes and fail with error hard coded since variable defined in file which is sourced!
source ${BHMAS_repositoryTopLevelPath}/Generic_Code/ErrorCodes.bash || exit 64
for fileToBeSourced in "${BHMAS_filesToBeSourced[@]}"; do
    source "${fileToBeSourced}" || exit ${BHMAS_fatalBuiltin}
done

#Take from BaHaMAS all options per mode or software
readonly BHMAS_MANUALMODE='TRUE'
declare -A allowedOptionsPerModeOrSoftware
DeclareAllowedOptionsPerModeOrSoftware

#Take from command line option the manual file and parse its name
if [[ $# -ne 1 ]]; then
    Fatal ${BHMAS_fatalCommandLine} "Use this script giving a single command-line option: The markdown manual filename!"
else
    readonly BHMAS_manualFile="$1"
    if [[ ! -f "${BHMAS_manualFile}" ]]; then
        Fatal ${BHMAS_fatalFileNotFound} 'File ' emph "${BHMAS_manualFile}" " not found in \"$(pwd)\"."
    fi
    if [[ ${BHMAS_manualFile} =~ ^BaHaMAS-([-a-zA-Z]+).md$ ]]; then
        BHMAS_executionMode="mode:${BASH_REMATCH[1]}"
    else
        Fatal ${BHMAS_fatalValueError} 'File ' emph "${BHMAS_manualFile}" ' existing but not a valid manual filename!'
    fi
fi

#Check that option pool file exists
readonly BHMAS_optionPool='OptionsPool.md'
if [[ ! -f "${BHMAS_optionPool}" ]]; then
    Fatal ${BHMAS_fatalFileNotFound} 'File ' emph "${BHMAS_optionPool}" ' not found!'
fi

#Check if OPTIONS section is present in markdown file
if [[ $(grep -c '^# OPTIONS[[:space:]]*$' "${BHMAS_manualFile}") -ne 1 ]]; then
    Fatal ${BHMAS_fatalLogicError} 'Option section not found in ' emph "${BHMAS_manualFile}" ' manual file!'
fi

# Make backup of manual file
BHMAS_backupFile="${BHMAS_manualFile}_backup"
cp "${BHMAS_manualFile}" "${BHMAS_backupFile}"

GetAllowedOptionsAndPutThemInManualSection "${BHMAS_executionMode}" 'CL2QCD' 'OpenQCD-FASTSUM'

if [[ $? -eq 0 ]]; then
    rm "${BHMAS_backupFile}"
fi
