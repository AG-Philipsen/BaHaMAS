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
source ${BHMAS_repositoryTopLevelPath}/Generic_Code/CommandLineParsers/SpecificModeParser.bash || exit ${BHMAS_fatalBuiltin}

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

    # Each execution mode does not accept the same options and it makes
    # sense to be stricter and to allow only the used ones instead of
    # just ignoring them if not used. An associative array allows to have
    # here an overview, we will use one entry of it later in the sub-parsers
    #
    # Possible options:
    #  --betasfile --doNotMeasurePbp
    #  --measurements --confSaveFrequency --confSavePointFrequency --pf
    #  --jobscript_prefix --walltime  --partition  --node  --constraint  --resource
    local productionOptions clusterOptions
    productionOptions='--measurements --confSaveFrequency --confSavePointFrequency --pf'
    clusterOptions='--walltime  --partition  --node  --constraint  --resource'
    declare -A allowedGeneralOptions=(
        ['mode:prepare-only']='--betasfile --jobscript_prefix'
        ['mode:submit-only']='--betasfile --jobscript_prefix'
        ['mode:submit']="--betasfile ${productionOptions} --jobscript_prefix ${clusterOptions}"
        ['mode:thermalize']="--betasfile ${productionOptions} --jobscript_prefix ${clusterOptions}"
        ['mode:continue']="--betasfile ${productionOptions} --jobscript_prefix ${clusterOptions}"
        ['mode:continue-thermalization']="--betasfile ${productionOptions} --jobscript_prefix ${clusterOptions}"
        ['mode:job-status']=''
        ['mode:simulation-status']=''
        ['mode:acceptance-rate-report']='--betasfile'
        ['mode:clean-output-files']='--betasfile'
        ['mode:complete-betas-file']='--betasfile'
        ['mode:comment-betas']='--betasfile'
        ['mode:uncomment-betas']='--betasfile'
        ['mode:invert-configurations']='--betasfile --jobscript_prefix ${clusterOptions}'
        ['mode:database']=''
    )

    if [[ ${BHMAS_executionMode} =~ ^mode:((job|simulation)-status|clean-output-files)$ ]]; then
        if [[ "$(type -t ParseSpecificModeOptions_${BHMAS_executionMode#mode:})" = 'function' ]]; then
            ParseSpecificModeOptions_${BHMAS_executionMode#mode:}
        else
            Internal 'Parser for ' emph "${BHMAS_executionMode#mode:}" ' mode not implemented but tried to be called!'
        fi
    fi

    __static__CheckIfOnlyValidOptionsWereGiven ${allowedGeneralOptions[@]} # <- let word splitting split options
    __static__ParseRemainingGeneralOptions

    #Mark as readonly the BHMAS_parameterPrefixes array, since from now on prefixes cannot change any more!
    declare -rga BHMAS_parameterPrefixes
}

function __static__CheckIfOnlyValidOptionsWereGiven()
{
    local validOptions option
    validOptions=( "$@" )
    for option in "${BHMAS_commandLineOptionsToBeParsed[@]}"; do
        [[ ! ${option} =~ ^- ]] && continue
        if ! ElementInArray "${option}" "${validOptions[@]}"; then
            Fatal ${BHMAS_fatalCommandLine} 'Option ' emph "${option}" ' non accepted in ' emph "${BHMAS_executionMode#mode:}" ' mode.'
        fi
    done
}

function __static__ParseRemainingGeneralOptions()
{
    set -- "${BHMAS_commandLineOptionsToBeParsed[@]}"
    #Here it is fine to assume that option names and values are separated by spaces
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --jobscript_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    readonly BHMAS_jobScriptPrefix="$2"
                fi
                shift 2
                ;;
            --betasfile )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_betasFilename="$2"
                fi
                shift 2
                ;;
            --walltime )
                if [[ ${2:-} =~ ^([0-9]+[dhms])+$ ]]; then
                    BHMAS_walltime=$(SecondsToTimeStringWithDays $(TimeStringToSecond $2) )
                else
                    BHMAS_walltime="${2:-}"
                fi
                if [[ ! ${BHMAS_walltime} =~ ^([0-9]+-)?[0-9]{1,2}:[0-9]{2}:[0-9]{2}$ ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                fi
                shift 2
                ;;
            --measurements )
                if [[ ! ${2:-} =~ ^[0-9]+$ ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_numberOfTrajectories=$2
                fi
                shift 2
                ;;
            --confSaveFrequency )
                if [[ ! ${2:-} =~ ^[0-9]+$ ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_checkpointFrequency=$2
                fi
                shift 2
                ;;
            --confSavePointFrequency )
                if [[ ! ${2:-} =~ ^[0-9]+$ ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_savepointFrequency=$2
                fi
                shift 2
                ;;
            --cgbs )
                if [[ ! ${2:-} =~ ^[0-9]+$ ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_inverterBlockSize=$2
                fi
                shift 2
                ;;
            --pf )
                if [[ ! ${2:-} =~ ^[1-9][0-9]*$ ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_numberOfPseudofermions=$2
                fi
                shift 2
                ;;
            --doNotMeasurePbp )
                BHMAS_measurePbp="FALSE"
                shift
                ;;
            --partition )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_clusterPartition="$2"
                fi
                shift 2
                ;;
            --node )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_clusterNode="$2"
                fi
                shift 2
                ;;
            --constraint )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_clusterConstraint="$2"
                fi
                shift 2
                ;;
            --resource )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_clusterGenericResource="$2"
                fi
                shift 2
                ;;
            * )
                PrintInvalidOptionErrorAndExit "$1" ;;
        esac
    done
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
