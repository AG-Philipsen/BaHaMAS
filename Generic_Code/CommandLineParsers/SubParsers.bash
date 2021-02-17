#
#  Copyright (c) 2017-2018,2020-2021 Alessandro Sciarra
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

function ParseSpecificModeOptions_thermalize()
{
    set -- "${BHMAS_commandLineOptionsToBeParsed[@]}"
    BHMAS_commandLineOptionsToBeParsed=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fromHot )
                readonly BHMAS_betaPostfix='_thermalizeFromHot'
                shift ;;
            * )
                BHMAS_commandLineOptionsToBeParsed+=( "$1" )
                shift ;;
        esac
    done
}

function ParseSpecificModeOptions_continue()
{
    set -- "${BHMAS_commandLineOptionsToBeParsed[@]}"
    BHMAS_commandLineOptionsToBeParsed=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --till )
                if [[ ! ${2:-} =~ ^(-|$) ]]; then
                    if [[ ! $2 =~ ^[0-9]+$ ]];then
                        PrintOptionSpecificationErrorAndExit "$1"
                    else
                        BHMAS_trajectoryNumberUpToWhichToContinue=$2
                    fi
                fi
                shift 2 ;;
            --updateExecutable )
                readonly BHMAS_reproduceExecutable='TRUE'
                shift ;;
            * )
                BHMAS_commandLineOptionsToBeParsed+=( "$1" )
                shift ;;
        esac
    done
}

function ParseSpecificModeOptions_continue-thermalization()
{
    ParseSpecificModeOptions_thermalize
    ParseSpecificModeOptions_continue
}

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
            --allUsers )
                BHMAS_jobstatusAll='TRUE'
                shift ;;
            --local )
                BHMAS_jobstatusLocal='TRUE'
                shift ;;
            --onlyGivenPartition )
                BHMAS_jobstatusOnlyPartition='TRUE'
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
                BHMAS_simulationStatusMeasureTimeOption="FALSE"
                shift ;;
            --showOnlyQueued )
                BHMAS_simulationStatusShowOnlyQueuedOption="TRUE"
                shift ;;
            --verbose )
                BHMAS_simulationStatusVerbose="TRUE"
                shift ;;
            * )
                BHMAS_commandLineOptionsToBeParsed+=( "$1" )
                shift ;;
        esac
    done
}

function ParseSpecificModeOptions_acceptance-rate-report()
{
    set -- "${BHMAS_commandLineOptionsToBeParsed[@]}"
    BHMAS_commandLineOptionsToBeParsed=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --interval )
                if [[ ! ${2:-} =~ ^(-|$) ]]; then
                    if [[ ! $2 =~ ^[1-9][0-9]*$ ]];then
                        PrintOptionSpecificationErrorAndExit "$1"
                    else
                        BHMAS_accRateReportInterval=$2
                    fi
                fi
                shift 2 ;;
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

function ParseSpecificModeOptions_complete-betas-file()
{
    set -- "${BHMAS_commandLineOptionsToBeParsed[@]}"
    BHMAS_commandLineOptionsToBeParsed=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --chains )
                if [[ ! ${2:-} =~ ^(-|$) ]]; then
                    if [[ ! $2 =~ ^[0-9]+$ ]];then
                        PrintOptionSpecificationErrorAndExit "complete-betas-file"
                    else
                        BHMAS_numberOfChainsToBeInTheBetasFile=$2
                    fi
                fi
                shift 2 ;;
            * )
                BHMAS_commandLineOptionsToBeParsed+=( "$1" )
                shift ;;
        esac
    done
}

function ParseSpecificModeOptions_comment-betas()
{
    set -- "${BHMAS_commandLineOptionsToBeParsed[@]}"
    BHMAS_commandLineOptionsToBeParsed=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --betas )
                while [[ ! ${2:-} =~ ^(-|$) ]]; do
                    if [[ $2 =~ ^[0-9]\.[0-9]{4}_${BHMAS_seedPrefix}[0-9]{4}(_(NC|fC|fH))*$ ]]; then
                        BHMAS_betasToBeToggled+=( $2 )
                    elif [[ $2 =~ ^[0-9]\.[0-9]*$ ]]; then
                        BHMAS_betasToBeToggled+=( $(awk '{printf "%1.4f", $1}' <<< "$2") )
                    else
                        PrintOptionSpecificationErrorAndExit "$1"
                    fi
                    shift
                done
                shift ;;
            * )
                BHMAS_commandLineOptionsToBeParsed+=( "$1" )
                shift ;;
        esac
    done
}

function ParseSpecificModeOptions_uncomment-betas()
{
    ParseSpecificModeOptions_comment-betas
}
