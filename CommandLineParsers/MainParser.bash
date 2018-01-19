#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENSE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

source ${BHMAS_repositoryTopLevelPath}/CommandLineParsers/MainHelper.bash || exit $BHMAS_fatalBuiltin

function __static__PrintSecondaryOptionSpecificationErrorAndExit()
{
    Fatal $BHMAS_fatalCommandLine "The option " emph "$2" " is a secondary option of " emph "$1" " and it has to be given after it!"
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
    while [ $# -gt 0 ]; do
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
                    BHMAS_parameterPrefixes[$BHMAS_nflavourPosition]=$BHMAS_nflavourPrefix
                fi
                shift 2 ;;

            --chempot_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    readonly BHMAS_chempotPrefix="$2"
                    BHMAS_parameterPrefixes[$BHMAS_chempotPosition]=$BHMAS_chempotPrefix
                fi
                shift 2 ;;

            --mass_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    readonly BHMAS_massPrefix="$2"
                    BHMAS_parameterPrefixes[$BHMAS_massPosition]=$BHMAS_massPrefix
                fi
                shift 2 ;;

            --ntime_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    readonly BHMAS_ntimePrefix="$2"
                    BHMAS_parameterPrefixes[$BHMAS_ntimePosition]=$BHMAS_ntimePrefix
                fi
                shift 2 ;;

            --nspace_prefix )
                if [[ ${2:-} =~ ^(-|$) ]]; then
                    PrintOptionSpecificationErrorAndExit "$1"
                else
                    readonly BHMAS_nspacePrefix="$2"
                    BHMAS_parameterPrefixes[$BHMAS_nspacePosition]=$BHMAS_nspacePrefix
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
                    readonly BHMAS_betaFolderShortRegex=$BHMAS_betaRegex'_'$BHMAS_seedPrefix'[0-9]\{4\}_[[:alpha:]]\+'
                    readonly BHMAS_betaFolderRegex=$BHMAS_betaPrefix$BHMAS_betaFolderShortRegex
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
                if [[ ! $BHMAS_walltime =~ ^([0-9]+-)?[0-9]{1,2}:[0-9]{2}:[0-9]{2}$ ]]; then
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
                if [ $BHMAS_thermalizeOption = "FALSE" ]; then
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
                BHMAS_submitOption="TRUE"
                shift;;

            --submitonly )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_submitonlyOption="TRUE"
                shift;;

            --thermalize )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_thermalizeOption="TRUE"
                shift;;

            --continue )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_continueOption="TRUE"
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
                BHMAS_continueThermalizationOption="TRUE"
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
                BHMAS_jobstatusOption="TRUE"
                shift;;

            --user )
                if [ $BHMAS_jobstatusOption = "FALSE" ]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "-j | --jobstatus" "$1"
                else
                    BHMAS_jobstatusUser="$2"
                    shift
                fi
                shift ;;

            --local )
                if [ $BHMAS_jobstatusOption = "FALSE" ]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "-j | --jobstatus" "$1"
                else
                    BHMAS_jobstatusLocal='TRUE'
                fi
                shift ;;

            --liststatus )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_liststatusOption="TRUE"
                shift;;

            --doNotMeasureTime )
                if [ $BHMAS_liststatusOption = "FALSE" ]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "-l | --liststatus" "$1"
                else
                    BHMAS_liststatusMeasureTimeOption="FALSE"
                fi
                shift ;;

            --showOnlyQueued )
                if [ $BHMAS_liststatusOption = "FALSE" ]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "-l | --liststatus" "$1"
                else
                    BHMAS_liststatusShowOnlyQueuedOption="TRUE"
                fi
                shift ;;

            --accRateReport )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_accRateReportOption="TRUE"
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
                BHMAS_cleanOutputFilesOption="TRUE"
                shift ;;

            --all )
                if [ $BHMAS_cleanOutputFilesOption = "FALSE" ] && [ $BHMAS_jobstatusOption = "FALSE" ]; then
                    __static__PrintSecondaryOptionSpecificationErrorAndExit "--cleanOutputFiles" "$1"
                elif [ $BHMAS_cleanOutputFilesOption = "TRUE" ]; then
                    BHMAS_cleanAllOutputFiles="TRUE"
                elif [ $BHMAS_jobstatusOption = "TRUE" ]; then
                    BHMAS_jobstatusAll='TRUE'
                fi
                shift ;;

            --completeBetasFile )
                mutuallyExclusiveOptionsPassed+=( $1 )
                BHMAS_completeBetasFileOption="TRUE"
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
                if [ $1 = '--uncommentBetas' ]; then
                    BHMAS_commentBetasOption="FALSE"; BHMAS_uncommentBetasOption="TRUE"
                elif [ $1 = '--commentBetas' ]; then
                    BHMAS_uncommentBetasOption="FALSE"; BHMAS_commentBetasOption="TRUE"
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
                BHMAS_invertConfigurationsOption="TRUE"
                shift ;;

            --database)
                BHMAS_databaseOption="TRUE"
                mutuallyExclusiveOptionsPassed+=( $1 )
                shift
                BHMAS_optionsToBePassedToDatabase=( $@ )
                shift $# ;;

            * )
                PrintInvalidOptionErrorAndExit "$1" ;;
        esac
    done

    if [ ${#mutuallyExclusiveOptionsPassed[@]} -gt 1 ]; then
        listOfOptionsAsString=''
        for option in "${mutuallyExclusiveOptions[@]}"; do
            listOfOptionsAsString+="\n$(cecho -d lo "  ") $option"
        done
        Fatal $BHMAS_fatalCommandLine "The following options are mutually exclusive and cannot be combined: $listOfOptionsAsString"
    fi

    #Mark as readonly the BHMAS_parameterPrefixes array, since from now on prefixes cannot change any more!
    declare -rga BHMAS_parameterPrefixes
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         __static__PrintSecondaryOptionSpecificationErrorAndExit\
         ParseCommandLineOption
