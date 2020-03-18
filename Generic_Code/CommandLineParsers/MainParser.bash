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

function ParseCommandLineOption()
{

    local mutuallyExclusiveOptions mutuallyExclusiveOptionsPassed option listOfOptionsAsString

    mutuallyExclusiveOptions=( "-s | --submit"        "-c | --continue"    "-C | --continueThermalization"
                               "-t | --thermalize"    "-j | --jobstatus"   "-l | --liststatus"  "-U | --uncommentBetas"
                               "-u | --commentBetas"  "-d | --database"    "-i | --invertConfigurations"
                               "--submitonly"  "--accRateReport"  "--cleanOutputFiles"  "--completeBetasFile")
    mutuallyExclusiveOptionsPassed=()

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

            --nflavor_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    readonly BHMAS_nflavourPrefix="$2"
                    BHMAS_parameterPrefixes[${BHMAS_nflavourPosition}]=${BHMAS_nflavourPrefix}
                fi
                shift 2 ;;

            --chempot_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    readonly BHMAS_chempotPrefix="$2"
                    BHMAS_parameterPrefixes[${BHMAS_chempotPosition}]=${BHMAS_chempotPrefix}
                fi
                shift 2 ;;

            --mass_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    readonly BHMAS_massPrefix="$2"
                    BHMAS_parameterPrefixes[${BHMAS_massPosition}]=${BHMAS_massPrefix}
                fi
                shift 2 ;;

            --ntime_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    readonly BHMAS_ntimePrefix="$2"
                    BHMAS_parameterPrefixes[${BHMAS_ntimePosition}]=${BHMAS_ntimePrefix}
                fi
                shift 2 ;;

            --nspace_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    readonly BHMAS_nspacePrefix="$2"
                    BHMAS_parameterPrefixes[${BHMAS_nspacePosition}]=${BHMAS_nspacePrefix}
                fi
                shift 2 ;;

            --beta_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    readonly BHMAS_betaPrefix="$2"
                fi
                shift 2 ;;

            --seed_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    readonly BHMAS_seedPrefix="$2"
                    readonly BHMAS_betaFolderShortRegex=${BHMAS_betaRegex}'_'${BHMAS_seedPrefix}'[0-9]\{4\}_[[:alpha:]]\+'
                    readonly BHMAS_betaFolderRegex=${BHMAS_betaPrefix}${BHMAS_betaFolderShortRegex}
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

            --doNotUseMultipleChains )
                BHMAS_useMultipleChains="FALSE"
                if [[ ${BHMAS_executionMode} != 'mode:thermalize' ]]; then
                    BHMAS_betaPostfix=""
                fi
                shift ;;

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

            --submit )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_executionMode='mode:submit'
                shift;;

            --submitonly )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_executionMode='mode:submit-only'
                shift;;

            --thermalize )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_executionMode='mode:thermalize'
                shift;;

            --continue )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_executionMode='mode:continue'
                if [[ ! ${2:-} =~ ^(-|$) ]]; then
                    if [[ ! $2 =~ ^[0-9]+$ ]];then
                        PrintOptionSpecificationErrorAndExit "$1"
                    else
                        BHMAS_trajectoryNumberUpToWhichToContinue=$2
                        shift
                    fi
                fi
                shift ;;

            --continueThermalization )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_executionMode='mode:continue-thermalization'
                if [[ ! ${2:-} =~ ^(-|$) ]]; then
                    if [[ ! $2 =~ ^[0-9]+$ ]];then
                        PrintOptionSpecificationErrorAndExit "$1"
                    else
                        BHMAS_trajectoryNumberUpToWhichToContinue=$2
                        shift
                    fi
                fi
                shift ;;

            --jobstatus )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_executionMode='mode:job-status'
                shift;;

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

            --liststatus )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_executionMode='mode:simulation-status'
                shift;;

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

            --accRateReport )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_executionMode='mode:acceptance-rate-report'
                if [[ ! ${2:-} =~ ^(-|$) ]]; then
                    if [[ ! $2 =~ ^[0-9]+$ ]];then
                        PrintOptionSpecificationErrorAndExit "$1"
                    else
                        BHMAS_accRateReportInterval=$2
                        shift
                    fi
                fi
                shift ;;

            --cleanOutputFiles )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_executionMode='mode:clean-output-files'
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

            --completeBetasFile )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_executionMode='mode:complete-betas-file'
                if [[ ! ${2:-} =~ ^(-|$) ]]; then
                    if [[ ! $2 =~ ^[0-9]+$ ]];then
                        PrintOptionSpecificationErrorAndExit "$1"
                    else
                        BHMAS_numberOfChainsToBeInTheBetasFile=$2
                        shift
                    fi
                fi
                shift ;;

            --uncommentBetas | --commentBetas )
                mutuallyExclusiveOptionsPassed+=( $1 )
                if [[ $1 = '--uncommentBetas' ]]; then
                    BHMAS_executionMode='mode:uncomment-betas'
                elif [[ $1 = '--commentBetas' ]]; then
                    BHMAS_executionMode='mode:comment-betas'
                fi
                while [[ ! ${2:-} =~ ^(-|$) ]]; do
                    if [[ $2 =~ ^[0-9]\.[0-9]{4}_${BHMAS_seedPrefix}[0-9]{4}(_(NC|fC|fH))*$ ]]; then
                        BHMAS_betasToBeToggled+=( $2 )
                    elif [[ $2 =~ ^[0-9]\.[0-9]*$ ]]; then
                        BHMAS_betasToBeToggled+=( $(awk '{printf "%1.4f", $1}' <<< "$2") )
                    else
                        PrintOptionSpecificationErrorAndExit "${mutuallyExclusiveOptionsPassed[-1]}"
                    fi
                    shift
                done
                shift ;;

            --invertConfigurations)
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_executionMode='mode:invert-configurations'
                shift ;;

            --database)
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_executionMode='mode:database'
                shift
                BHMAS_optionsToBePassedToDatabase=( "$@" )
                shift $# ;;

            * )
                PrintInvalidOptionErrorAndExit "$1" ;;
        esac
    done

    if [[ ${#mutuallyExclusiveOptionsPassed[@]} -gt 1 ]]; then
        listOfOptionsAsString=''
        for option in "${mutuallyExclusiveOptions[@]}"; do
            listOfOptionsAsString+="\n$(cecho -d lo "  ") ${option}"
        done
        Fatal ${BHMAS_fatalCommandLine} "The following options are mutually exclusive and cannot be combined: ${listOfOptionsAsString}"
    fi

    #Mark as readonly the BHMAS_parameterPrefixes array, since from now on prefixes cannot change any more!
    declare -rga BHMAS_parameterPrefixes
}

function IsTestModeOn()
{
    if [[ -n "${BHMAS_testModeOn:+x}" ]] && [[ ${BHMAS_testModeOn} = 'TRUE' ]]; then
        return 0
    else
        return 1
    fi
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

function IsBaHaMASRunInSetupMode()
{
    if WasAnyOfTheseOptionsGivenToBaHaMAS '--setup'; then
        return 0
    else
        return 1
    fi
}

MakeFunctionsDefinedInThisFileReadonly
