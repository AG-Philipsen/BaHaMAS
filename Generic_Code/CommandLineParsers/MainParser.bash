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

source ${BHMAS_repositoryTopLevelPath}/Generic_Code/CommandLineParsers/MainHelper.bash || exit ${BHMAS_fatalBuiltin}

function __static__PrintSecondaryOptionSpecificationErrorAndExit()
{
    Fatal ${BHMAS_fatalCommandLine} "The option " emph "$2" " is a secondary option of " emph "$1" " and it has to be given after it!"
}

function ParseCommandLineOptionsTillMode()
{
    if [[ ${#BHMAS_commandLineOptionsToBeParsed[@]} -eq 0 ]]; then
        BHMAS_executionMode='mode:help'
        return 0
    fi
    #Locally set function arguments to take advantage of shift
    set -- "${BHMAS_commandLineOptionsToBeParsed[@]}"
    #The first option can be a LQCD software
    if [[ $1 =~ ^(CL2QCD|OpenQCD-FASTSUM)$ ]]; then
        BHMAS_lqcdSoftware="$1"
        shift
    fi
    case "$1" in
        help | --help )
            BHMAS_executionMode='mode:help'
            ;;
        version | --version )
            BHMAS_executionMode='mode:version'
            ;;
        setup | --setup )
            BHMAS_executionMode='mode:setup'
            ;;
        prepare-only )
            BHMAS_executionMode='mode:prepare-only'
            ;;
        submit-only )
            BHMAS_executionMode='mode:submit-only'
            ;;
        submit )
            BHMAS_executionMode='mode:submit'
            ;;
        thermalize )
            BHMAS_executionMode='mode:thermalize'
            ;;
        continue )
            BHMAS_executionMode='mode:continue'
            ;;
        continue-thermalization )
            BHMAS_executionMode='mode:continue-thermalization'
            ;;
        job-status )
            BHMAS_executionMode='mode:job-status'
            ;;
        simulation-status )
            BHMAS_executionMode='mode:simulation-status'
            ;;
        acceptance-rate-report )
            BHMAS_executionMode='mode:acceptance-rate-report'
            ;;
        clean-output-files )
            BHMAS_executionMode='mode:clean-output-files'
            ;;
        complete-betas-file )
            BHMAS_executionMode='mode:complete-betas-file'
            ;;
        comment-betas )
            BHMAS_executionMode='mode:comment-betas'
            ;;
        uncomment-betas )
            BHMAS_executionMode='mode:uncomment-betas'
            ;;
        invert-configurations )
            BHMAS_executionMode='mode:invert-configurations'
            ;;
        database )
            BHMAS_executionMode='mode:database'
            BHMAS_optionsToBePassedToDatabase=( "${@:2}" )
            shift $(( $# - 1 )) #The shift after esac
            ;;
        * )
            Fatal ${BHMAS_fatalCommandLine} "No valid mode specified! Run " emph "BaHaMAS --help" " to get further information."
    esac
    shift
    #Update the global array with remaining options to be parsed
    BHMAS_commandLineOptionsToBeParsed=( "$@" )
    #If user specified --help in a given mode, act accrdingly
    if [[ ${BHMAS_executionMode} != 'mode:help' ]]; then
        if  ElementInArray '--help' "${BHMAS_commandLineOptionsToBeParsed[@]}" "${BHMAS_optionsToBePassedToDatabase[@]}"; then
            BHMAS_executionMode+='-help'
        fi
    fi
}

function ParseRemainingCommandLineOptions()
{
    __static__ParseFirstOfRemainingOptions

    #Locally set function arguments to take advantage of shift
    set -- "${BHMAS_commandLineOptionsToBeParsed[@]}"
    #Here it is fine to assume that option names and values are separated by spaces
    while [[ $# -gt 0 ]]; do
        case $1 in

            --jobscript_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    readonly BHMAS_jobScriptPrefix="$2"
                fi
                shift 2 ;;


            --betasfile )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_betasFilename="$2"
                fi
                shift 2 ;;

            --walltime )
                if [[ ${2:-} =~ ^([0-9]+[dhms])+$ ]]; then
                    BHMAS_walltime=$(SecondsToTimeStringWithDays $(TimeStringToSecond $2) )
                else
                    BHMAS_walltime="${2:-}"
                fi
                if [[ ! ${BHMAS_walltime} =~ ^([0-9]+-)?[0-9]{1,2}:[0-9]{2}:[0-9]{2}$ ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                fi
                shift 2 ;;

            --measurements )
                if [[ ! ${2:-} =~ ^[0-9]+$ ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_numberOfTrajectories=$2
                fi
                shift 2 ;;

            --confSaveFrequency )
                if [[ ! ${2:-} =~ ^[0-9]+$ ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_checkpointFrequency=$2
                fi
                shift 2 ;;

            --confSavePointFrequency )
                if [[ ! ${2:-} =~ ^[0-9]+$ ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_savepointFrequency=$2
                fi
                shift 2 ;;

            --cgbs )
                if [[ ! ${2:-} =~ ^[0-9]+$ ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_inverterBlockSize=$2
                fi
                shift 2 ;;

            --pf )
                if [[ ! ${2:-} =~ ^[1-9][0-9]*$ ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_numberOfPseudofermions=$2
                fi
                shift 2 ;;

            --doNotMeasurePbp )
                BHMAS_measurePbp="FALSE"; shift ;;

            --partition )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_clusterPartition="$2"
                fi
                shift 2 ;;

            --node )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_clusterNode="$2"
                fi
                shift 2 ;;

            --constraint )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_clusterConstraint="$2"
                fi
                shift 2 ;;

            --resource )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_clusterGenericResource="$2"
                fi
                shift 2 ;;

            --user )
                if [[ ${BHMAS_executionMode} != 'mode:job-status' ]]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "-j | --jobstatus" "$1"
                else
                    BHMAS_jobstatusUser="$2"
                    shift
                fi
                shift ;;

            --local )
                if [[ ${BHMAS_executionMode} != 'mode:job-status' ]]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "-j | --jobstatus" "$1"
                else
                    BHMAS_jobstatusLocal='TRUE'
                fi
                shift ;;

            --doNotMeasureTime )
                if [[ ${BHMAS_executionMode} != 'mode:simulation-status' ]]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "-l | --liststatus" "$1"
                else
                    BHMAS_liststatusMeasureTimeOption="FALSE"
                fi
                shift ;;

            --showOnlyQueued )
                if [[ ${BHMAS_executionMode} != 'mode:simulation-status' ]]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "-l | --liststatus" "$1"
                else
                    BHMAS_liststatusShowOnlyQueuedOption="TRUE"
                fi
                shift ;;

            --all )
                if [[ ${BHMAS_executionMode} != 'mode:clean-output-files' ]] && [[ ${BHMAS_executionMode} != 'mode:job-status' ]]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "--cleanOutputFiles" "$1"
                elif [[ ${BHMAS_executionMode} = 'mode:clean-output-files' ]]; then
                    BHMAS_cleanAllOutputFiles="TRUE"
                elif [[ ${BHMAS_executionMode} = 'mode:job-status' ]]; then
                    BHMAS_jobstatusAll='TRUE'
                fi
                shift ;;

            * )
                PrintInvalidOptionErrorAndExit "$1" ;;
        esac
    done

    #Mark as readonly the BHMAS_parameterPrefixes array, since from now on prefixes cannot change any more!
    declare -rga BHMAS_parameterPrefixes
}

function __static__ParseFirstOfRemainingOptions()
{
    #Locally set function arguments to take advantage of shift
    set -- "${BHMAS_commandLineOptionsToBeParsed[@]}"
    case ${BHMAS_executionMode} in
        mode:continue )
            if [[ ! ${1:-} =~ ^(-|$) ]]; then
                if [[ ! $1 =~ ^[0-9]+$ ]];then
                    PrintOptionSpecificationErrorAndExit "continue"
                else
                    BHMAS_trajectoryNumberUpToWhichToContinue=$1
                    shift
                fi
            fi
            ;;
        mode:continue-thermalization )
            if [[ ! ${1:-} =~ ^(-|$) ]]; then
                if [[ ! $1 =~ ^[0-9]+$ ]];then
                    PrintOptionSpecificationErrorAndExit "continue-thermalization"
                else
                    BHMAS_trajectoryNumberUpToWhichToContinue=$1
                    shift
                fi
            fi
            ;;
        mode:acceptance-rate-report )
            if [[ ! ${1:-} =~ ^(-|$) ]]; then
                if [[ ! $1 =~ ^[0-9]+$ ]];then
                    PrintOptionSpecificationErrorAndExit "acceptance-rate-report"
                else
                    BHMAS_accRateReportInterval=$1
                    shift
                fi
            fi
            ;;
        mode:complete-betas-file )
            if [[ ! ${1:-} =~ ^(-|$) ]]; then
                if [[ ! $1 =~ ^[0-9]+$ ]];then
                    PrintOptionSpecificationErrorAndExit "complete-betas-file"
                else
                    BHMAS_numberOfChainsToBeInTheBetasFile=$1
                    shift
                fi
            fi
            ;;
        mode:comment-betas | mode:uncomment-betas )
            while [[ ! ${1:-} =~ ^(-|$) ]]; do
                if [[ $1 =~ ^[0-9]\.[0-9]{4}_${BHMAS_seedPrefix}[0-9]{4}(_(NC|fC|fH))*$ ]]; then
                    BHMAS_betasToBeToggled+=( $1 )
                elif [[ $1 =~ ^[0-9]\.[0-9]*$ ]]; then
                    BHMAS_betasToBeToggled+=( $(awk '{printf "%1.4f", $1}' <<< "$1") )
                else
                    PrintOptionSpecificationErrorAndExit "${BHMAS_executionMode#mode:}"
                fi
                shift
            done
            ;;
        * )
            ;;
    esac
    #Update the global array with remaining options to be parsed
    BHMAS_commandLineOptionsToBeParsed=( "$@" )
}


function GiveRequiredHelp()
{
    local modeName; modeName=${BHMAS_executionMode#mode:}
    case ${modeName} in
        help )
            PrintMainHelper
            ;;
        database-help )
            PrintDatabaseHelper
            ;;
        * )
            Error "Manual for " emph "${modeName%-help}" " mode has not yet been written."
            ;;
    esac
}

function WasAnyOfTheseOptionsGivenToBaHaMAS()
{
    # It would be nice to use here "${BASH_ARGV[@]: -${BASH_ARGC}}"
    # to retrieve the script command line options but the bash
    # manual v5.0 says is not reliable if the extended debug mode is
    # not activated, which we do not want => global array.
    #   https://unix.stackexchange.com/q/568747/370049
    local option
    for option in "$@"; do
        if ElementInArray "${option}" "${BHMAS_specifiedCommandLineOptions[@]}"; then
            return 0
        fi
    done
    return 1
}

# This function is needed before the variable
# BHMAS_executionMode is available and set!
function IsBaHaMASRunInSetupMode()
{
    if WasAnyOfTheseOptionsGivenToBaHaMAS '--setup'; then
        return 0
    else
        return 1
    fi
}

MakeFunctionsDefinedInThisFileReadonly
