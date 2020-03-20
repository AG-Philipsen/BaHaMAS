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

# NOTE: Function names in bash accepts many symbols in them.
#       Here we use only the '-' so that we can call the
#       following functions using ${BHMAS_executionMode#mode:}.
#       In principle, also ':' is allowed, but it makes names
#       a bit shorter. -> https://stackoverflow.com/a/44041384
#
# NOTE: In the following functions we locally set the function
#       arguments to the options to parse to take advantage of
#       the 'shift' builtin and we reset global array to populate
#       it only with general options that are going to be parsed
#       later (general in the sense of common to more than one
#       execution mode). These are parsed in the main parser.

function ParseSpecificModeOptions_job-status()
{
    set -- "${BHMAS_commandLineOptionsToBeParsed[@]}"
    BHMAS_commandLineOptionsToBeParsed=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_jobstatusUser="$2"
                fi
                shift 2 ;;
            --local )
                BHMAS_jobstatusLocal='TRUE'
                shift ;;
            --all )
                BHMAS_jobstatusAll='TRUE'
                shift ;;
            * )
                BHMAS_commandLineOptionsToBeParsed+=( "$1" )
                shift ;;
        esac
    done
}

function ParseSpecificModeOptions_simulation-status()
{
    set -- "${BHMAS_commandLineOptionsToBeParsed[@]}"
    BHMAS_commandLineOptionsToBeParsed=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --doNotMeasureTime )
                BHMAS_liststatusMeasureTimeOption="FALSE"
                shift ;;
            --showOnlyQueued )
                BHMAS_liststatusShowOnlyQueuedOption="TRUE"
                shift ;;
            * )
                BHMAS_commandLineOptionsToBeParsed+=( "$1" )
                shift ;;
        esac
    done
}

function ParseSpecificModeOptions_clean-output-files()
{
    set -- "${BHMAS_commandLineOptionsToBeParsed[@]}"
    BHMAS_commandLineOptionsToBeParsed=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all )
                BHMAS_cleanAllOutputFiles="TRUE"
                shift ;;
            * )
                BHMAS_commandLineOptionsToBeParsed+=( "$1" )
                shift ;;
        esac
    done
}
