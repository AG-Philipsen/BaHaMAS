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

function GiveRequiredHelp()
{
    local modeName manualFile
    modeName=${BHMAS_executionMode#mode:}
    case ${modeName} in
        help )
            PrintMainHelper
            ;;
        database-help )
            PrintDatabaseHelper
            ;;
        * )
            manualFile="${BHMAS_repositoryTopLevelPath}/Manual_Pages/man1/BaHaMAS-${modeName%-help}.1"
            __static__CheckIfManualIsUpToDate "${manualFile}"
            if [[ -f "${manualFile}" ]]; then
                man -l "${manualFile}"
            else
                Error "Manual for " emph "${modeName%-help}" " mode has not yet been written."
            fi
            ;;
    esac
}

function UpdateManualPages()
(
    # This function body is a sub-shell because of the cd
    if command -v pandoc >> /dev/null 2>&1; then
        cd "${BHMAS_repositoryTopLevelPath}/Manual_Pages"
        if ! make >> /dev/null 2>&1; then
            Internal "Error occurred producing manual pages!"
        else
            cecho lg '\n Manual pages successfully created!\n'
        fi
    else
        Fatal ${BHMAS_failureExitCode} "Command pandoc not found! Manual pages cannot be produced."
    fi
)

function PrintMainHelper()
{
    declare -A runSimulationsModesDescription monitorModesDescription\
            betasfileModesDescription sectionHeaders
    sectionHeaders=(
        ['runSimulationsModesDescription']='Prepare needed files and folders and/or submit new simulation(s)'
        ['monitorModesDescription']='Monitor queued jobs or get report about existing simulation(s)'
        ['betasfileModesDescription']='Perform some automatized operations on the betas file'
    )
    runSimulationsModesDescription=(
        ['prepare-only']='Prepare needed files and folders to submit new-chain simulation(s)'
        ['submit-only']='Submit new-chain simulation(s) after needed consistency checks'
        ['submit']='Prepare what is needed and submit new-chain simulation(s)'
        ['thermalize']='Prepare what is needed and submit thermalization simulation(s)'
        ['continue']='Adjust input file(s) and resume new-chain simulation(s)'
        ['continue-thermalization']='Adjust input file(s) and resume thermalization simulation(s)'
        ['invert-configurations']='Prepare what is needed and submit measurement simulation(s)'
    )
    monitorModesDescription=(
        ['job-status']='Give overview of submitted jobs getting information from scheduler'
        ['simulation-status']='Produce report of folder simulation(s)'
        ['acceptance-rate-report']='Produce a table with acceptance rates in subsequent intervals'
        ['clean-output-files']='Check and if needed clean the measurement file'
        ['database']='Access to database functionality'
    )
    betasfileModesDescription=(
        ['complete-betas-file']='Complete the betas file adding new chains to it'
        ['comment-betas']='Comment lines in the betas file'
        ['uncomment-betas']='Uncomment lines in the betas file'
    )
    __static__PrintHelperHeaderAndUsage
    __static__PrintModesDescription
}

function __static__PrintHelperHeaderAndUsage()
{
    cecho lc '\n'\
          ' #-------------------------------------------------------------------------#\n'\
          ' #         ____              __  __            __  ___   ___     _____     #\n'\
          ' #        / __ )   ____ _   / / / /  ____ _   /  |/  /  /   |   / ___/     #\n'\
          ' #       / __  |  / __ `/  / /_/ /  / __ `/  / /|_/ /  / /| |   \__ \      #\n'\
          ' #      / /_/ /  / /_/ /  / __  /  / /_/ /  / /  / /  / ___ |  ___/ /      #\n'\
          ' #     /_____/   \__,_/  /_/ /_/   \__,_/  /_/  /_/  /_/  |_| /____/       #\n'\
          ' #                                                                         #\n'\
          ' #-------------------------------------------------------------------------#\n'\
          '\n'\
          '            Usage:   BaHaMAS [--help] [--version] [--setup]\n'\
          '                             <execution-mode> [<options>...]'
}

function __static__PrintModesDescription()
{
    CheckIfVariablesAreSet sectionHeaders "${!sectionHeaders[@]}"
    local section mode reference
    cecho bb '\n  Here in the following you find an overview of the existing execution modes.'
    for section in "${!sectionHeaders[@]}"; do
        cecho ly "\n  ${sectionHeaders[${section}]}"
        declare -n reference="${section}"
        for mode in "${!reference[@]}"; do
            printf '%45s%3s%s\n'\
                   "$(cecho lc emph "${mode}")"\
                   ''\
                   "$(cecho lc "${reference[${mode}]}")"
        done | sort --ignore-leading-blanks
        unset -v 'reference'
    done
    cecho bb '\n  Use ' wg '--help' bb ' after each mode to get more information about a given mode.\n'
}

function __static__CheckIfManualIsUpToDate()
{
    local manualFile
    manualFile="$1"
    if [[ ! -s "${manualFile/%.1/.md}" ]]; then
        return
    fi
    if [[ "${manualFile/%.1/.md}" -nt "${manualFile}" ]]; then
        Warning 'The required file page is not up-to-date! Try to run\n'\
                emph '   BaHaMAS update-manuals'\
                '\nand see if it is possible to fix the problem.'
        AskUser -n "Do you want to anyway open the file?"
        if UserSaidNo; then
            cecho ''; exit ${BHMAS_failureExitCode}
        fi
    fi
}


MakeFunctionsDefinedInThisFileReadonly
