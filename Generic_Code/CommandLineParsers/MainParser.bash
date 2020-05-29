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

#Load needed files
for fileToBeSourced in 'AllowedOptions.bash' 'DatabaseHelper.bash' 'DatabaseParser.bash' 'Helper.bash' 'ParserUtilities.bash' 'SubParsers.bash'; do
    source "${BHMAS_repositoryTopLevelPath}/Generic_Code/CommandLineParsers/${fileToBeSourced}" || exit ${BHMAS_fatalBuiltin}
done && unset -v 'fileToBeSourced'

function ParseCommandLineOptionsTillMode()
{
    if [[ ${#BHMAS_commandLineOptionsToBeParsed[@]} -eq 0 ]]; then
        BHMAS_executionMode='mode:help'
        return 0
    fi
    #Locally set function arguments to take advantage of shift
    set -- "${BHMAS_commandLineOptionsToBeParsed[@]}"
    #The first option can be a LQCD software
    if [[ $1 =~ ^(CL2QCD|openQCD-FASTSUM)$ ]]; then
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
        update-manuals )
            BHMAS_executionMode='mode:update-manuals'
            ;;
        prepare-only )
            BHMAS_executionMode='mode:prepare-only'
            ;;
        submit-only )
            BHMAS_executionMode='mode:submit-only'
            ;;
        new-chain )
            BHMAS_executionMode='mode:new-chain'
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
        measure )
            BHMAS_executionMode='mode:measure'
            ;;
        database )
            BHMAS_executionMode='mode:database'
            BHMAS_optionsToBePassedToDatabase=( "${@:2}" )
            shift $(( $# - 1 )) #The shift after esac
            ;;
        * )
            Fatal ${BHMAS_fatalCommandLine}\
                  'Specified mode ' emph "$1" ' not valid! Run ' emph 'BaHaMAS --help' ' to get further information.'
    esac
    shift
    #Update the global array with remaining options to be parsed
    BHMAS_commandLineOptionsToBeParsed=( "$@" )

    # Make software variable readonly but not in simulation-status related modes
    if [[ ! ${BHMAS_executionMode} =~ ^mode:(simulation-status|database)$ ]]; then
        readonly BHMAS_lqcdSoftware
    fi
    #If user specified --help in a given mode, act accrdingly
    if [[ ! ${BHMAS_executionMode} =~ ^mode:(help|version|setup)$ ]]; then
        if  ElementInArray '--help' "${BHMAS_commandLineOptionsToBeParsed[@]}" "${BHMAS_optionsToBePassedToDatabase[@]}"; then
            BHMAS_executionMode+='-help'
        fi
    fi
    #Deactivate measure mode for openQCD-FASTSUM
    if [[ ${BHMAS_executionMode} = 'mode:measure' && ${BHMAS_lqcdSoftware} = 'openQCD-FASTSUM' ]]; then
        Error 'BaHaMAS does not support the ' emph "${BHMAS_executionMode}"\
              ' mode with ' emph "${BHMAS_lqcdSoftware}" '.'
        exit ${BHMAS_successExitCode} # To let test pass
    fi
}

function ParseRemainingCommandLineOptions()
{
    # In general we have options that can be
    #   1) mode-specific && software-specific options;
    #   2) mode-specific && for-all-software  options;
    #   3) for-all-modes && software-specific options;
    #   4) mode-specific && multiple-software options;
    #   5) multiple-mode && software-specific options;
    #   6) multiple-mode && multiple-software options.
    # Then,
    #  - for categories 1,2,3 we implement sub-parsers;
    #  - for categories 4,5,6 we have a pool of options which are
    #    parsed all together but preliminary checked if allowed.
    #
    # https://gitlab.itp.uni-frankfurt.de/lattice-qcd/ag-philipsen/BaHaMAS/issues/27
    local modeSpecificAllSoftwareParser
    modeSpecificAllSoftwareParser=(
        'mode:continue'
        'mode:continue-thermalization'
        'mode:job-status'
        'mode:simulation-status'
        'mode:acceptance-rate-report'
        'mode:clean-output-files'
        'mode:complete-betas-file'
        'mode:comment-betas'
        'mode:uncomment-betas'
    )
    if ElementInArray "${BHMAS_executionMode}" ${modeSpecificAllSoftwareParser[@]}; then
        __static__CallSubParserIfExisting "${BHMAS_executionMode#mode:}"
    fi

    local modeSpecificSoftwareSpecificParser
    modeSpecificSoftwareSpecificParser=()
    if ElementInArray "${BHMAS_executionMode}_${BHMAS_lqcdSoftware}" ${modeSpecificSoftwareSpecificParser[@]}; then
        __static__CallSubParserIfExisting "${BHMAS_executionMode}_${BHMAS_lqcdSoftware}"
    fi

    local softwareSpecificAllModesParser
    softwareSpecificAllModesParser=()
    if ElementInArray "${BHMAS_lqcdSoftware}" ${softwareSpecificAllModesParser[@]}; then
        __static__CallSubParserIfExisting "${BHMAS_lqcdSoftware}"
    fi

    declare -A allowedOptionsPerModeOrSoftware
    _BaHaMAS_DeclareAllowedOptionsPerModeOrSoftware
    __static__CheckIfOnlyValidOptionsWereGiven\
        ${allowedOptionsPerModeOrSoftware["${BHMAS_executionMode}"]:-}\
        ${allowedOptionsPerModeOrSoftware["${BHMAS_executionMode}_${BHMAS_lqcdSoftware}"]:-}\
        ${allowedOptionsPerModeOrSoftware["${BHMAS_lqcdSoftware}"]:-} # <- let word splitting split options
    __static__ParseRemainingGeneralOptions
}

function __static__CallSubParserIfExisting()
{
    local functionName
    functionName="ParseSpecificModeOptions_"
    if [[ "${1-}" != '' ]]; then
        functionName+="$1"
    else
        Internal 'Function ' emph "${FUNCNAME}" ' wrongly called!'
    fi
    if [[ "$(type -t ${functionName})" = 'function' ]]; then
        ${functionName}
    else
        Internal 'Parser for ' emph "$1" ' not implemented but tried to be called!'
    fi
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
           --checkpointEvery )
                if [[ ! ${2:-} =~ ^[0-9]+$ ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    BHMAS_checkpointFrequency=$2
                fi
                shift 2
                ;;
            --confSaveEvery )
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
            --togglePbp )
                if [[ BHMAS_measurePbp='FALSE' ]]; then
                    BHMAS_measurePbp='TRUE'
                    cecho lg ' Measurement of the ' B 'pbp' uB ' has been switched ' B 'ON'
                else
                    BHMAS_measurePbp='FALSE'
                    cecho lg ' Measurement of the ' B 'pbp' uB ' has been switched ' B 'OFF'
                fi
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
            --processorsGrid )
                local specifiedOption="$1"
                BHMAS_processorsGrid=()
                while [[ ${2:-} =~ ^[1-9][0-9]*$ ]]; do
                    BHMAS_processorsGrid+=( $2 )
                    shift
                done
                if [[ ${#BHMAS_processorsGrid[@]} -ne 4 ]]; then
                     PrintOptionSpecificationErrorAndExit "${specifiedOption}"
                fi
                shift
                ;;
            * )
                PrintInvalidOptionErrorAndExit "$1" ;;
        esac
    done
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
    if WasAnyOfTheseOptionsGivenToBaHaMAS 'setup' '--setup'; then
        return 0
    else
        return 1
    fi
}

MakeFunctionsDefinedInThisFileReadonly
