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

function __static__DeclareSystemRequirements()
{
    declare -grA BHMAS_systemRequirments=(
        ['awk']='4.1.0'
        ['bash']='4.4.0'
        ['git']='1.8.5'
        ['sed']='4.2.1'
    )
}

function CheckSystemRequirements()
{
    local program returnValue
    declare -A systemProgramVersions
    returnValue=0
    __static__DeclareSystemRequirements
    for program in "${!BHMAS_systemRequirments[@]}"; do
        if ! __static__CheckAvailabilityOfProgram "${program}"; then
            Error 'Program ' emph "${program}" ' was not found, but it is required with minimum version ' emph "${BHMAS_systemRequirments[${program}]}" ' to run ' B 'BaHaMAS' uB '.'
            returnValue=1
            continue
        fi
        if ! __static__FindVersionOfProgram "${program}"; then
            Warning -N 'Unable to recover ' emph "${program}" '-version, skipping check on minimum requirement!\n'\
                    'Ensure that version ' emph "${BHMAS_systemRequirments[${program}]}" ' is available.'
            continue
        fi
        if ! __static__CheckAboutProgram "${program}"; then
            Error 'Version ' emph "${systemProgramVersions[${program}]}" ' of ' emph "${program}"\
                  ' was found but version ' emph "${BHMAS_systemRequirments[${program}]}" ' is required!'
            returnValue=1
        fi
    done
    if [[ ${returnValue} -ne 0 ]]; then
        Fatal ${BHMAS_fatalRequirement} -n\
              'Please install (maybe locally) the required versions of the above programs and run ' B 'BaHaMAS' uB ' again.'
    fi
}

function CheckSystemRequirementsAndMakeReport()
{
    local program labelProgram labelRequiredVersion
    declare -A systemProgramVersions
    returnValue=0
    __static__DeclareSystemRequirements
    for program in "${!BHMAS_systemRequirments[@]}"; do
        printf -v labelProgram '%10s' "${program}"
        printf -v labelRequiredVersion '%8s' "${BHMAS_systemRequirments[${program}]}"
        cecho -n lb '   Program ' lc "${labelProgram}" ': '
        if ! __static__CheckAvailabilityOfProgram "${program}"; then
            cecho lr "$(printf '%10s' 'NOT found')" lb '    Required version: ' lc "${labelRequiredVersion}"
            continue
        else
            cecho -n lg "$(printf '%10s' 'found')"
        fi
        cecho -n lb '    Required version: ' lc "${labelRequiredVersion}" lb '    System version: '
        if ! __static__FindVersionOfProgram "${program}"; then
            cecho ly 'unable to be recovered!'
            continue
        fi
        if ! __static__CheckAboutProgram "${program}"; then
            cecho lr "${systemProgramVersions[${program}]}"
        else
            cecho lg "${systemProgramVersions[${program}]}"
        fi
    done
}

function __static__CheckAvailabilityOfProgram()
{
    if hash "$1" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

function __static__FindVersionOfProgram()
{
    local foundVersion
    case "$1" in
        bash )
            requiredVersion='4.4.0'
            foundVersion="$(sed 's/ /./g' <<< "${BASH_VERSINFO[@]:0:3}")"
            ;;
        awk )
            requiredVersion='4.1.0' # The first supporting '-i inplace'
            if awk --version >/dev/null 2>&1; then
                foundVersion=$(awk --version | head -n1 | grep -o "[0-9.]\+" | head -n1)
            fi
            ;;
        sed )
            requiredVersion='4.2.1'
            if sed --version >/dev/null 2>&1; then
                foundVersion=$(sed --version | head -n1 | grep -o "[0-9.]\+" | head -n1)
            fi
            ;;
        git )
            requiredVersion='1.8.5'
            if git --version >/dev/null 2>&1; then
                foundVersion=$(git --version | head -n1 | grep -o "[0-9.]\+" | head -n1)
            fi
            ;;
        *)
            return 1
    esac
    if [[ ${foundVersion} =~ ^[0-9]([.0-9])*$ ]]; then
        systemProgramVersions["$1"]="${foundVersion}"
    else
        return 1
    fi
}

function __static__CheckAboutProgram()
{
    if __static__IsFoundVersionOlderThanRequired "${BHMAS_systemRequirments[$1]}" "${systemProgramVersions[$1]}"; then
        return 1
    else
        return 0
    fi
}

function __static__IsFoundVersionOlderThanRequired()
{
    [[ "$1" = "$2" ]] && return 1
    #Here I suppose 'sort -V' is available, even though it is part
    #of Linux coreutils. In any case we use coreutils functionalities
    #around in BaHaMAS and at the moment we do not make further checks.
    local foundVersion requiredVersion newerVersion
    requiredVersion=$1; foundVersion=$2
    newerVersion=$(printf '%s\n%s' ${requiredVersion} ${foundVersion} | sort -V | tail -n1)
    if [[ ${newerVersion} = ${requiredVersion} ]]; then
        return 0
    else
        return 2
    fi
}


MakeFunctionsDefinedInThisFileReadonly
