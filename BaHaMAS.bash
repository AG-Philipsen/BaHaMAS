#!/bin/bash

#-------------------------------------------------------------------------#
#         ____              __  __            __  ___   ___     _____     #
#        / __ )   ____ _   / / / /  ____ _   /  |/  /  /   |   / ___/     #
#       / __  |  / __ `/  / /_/ /  / __ `/  / /|_/ /  / /| |   \__ \      #
#      / /_/ /  / /_/ /  / __  /  / /_/ /  / /  / /  / ___ |  ___/ /      #
#     /_____/   \__,_/  /_/ /_/   \__,_/  /_/  /_/  /_/  |_| /____/       #
#                                                                         #
#-------------------------------------------------------------------------#
#                                                                         #
#      Copyright (c)  2014  Alessandro Sciarra, Christopher Czaban        #
#                     2015  Alessandro Sciarra, Christopher Czaban        #
#                     2016  Alessandro Sciarra, Christopher Czaban        #
#                     2017  Alessandro Sciarra, Christopher Czaban        #
#                                                                         #
#-------------------------------------------------------------------------#

#------------------------------------------------------------------------------------------------------#
# Load auxiliary bash files that will be used.
BaHaMAS_repositoryTopLevelPath="$(git -C $(dirname "${BASH_SOURCE[0]}") rev-parse --show-toplevel)"
source ${BaHaMAS_repositoryTopLevelPath}/UtilityFunctions.bash            || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/GlobalVariables.bash             || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/UserSpecificVariables.bash       || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/CheckGlobalVariables.bash        || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/OutputFunctionality.bash         || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/PathManagementFunctionality.bash || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/FindClusterScheduler.bash        || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/CommandLineParser.bash           || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/AuxiliaryFunctions.bash          || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/AcceptanceRateReport.bash        || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/BuildRegexPath.bash              || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/ProjectStatisticsDatabase.bash   || exit -2
#------------------------------------------------------------------------------------------------------#

#Declare all variables
DeclarePathRelatedGlobalVariables
DeclareUserDefinedGlobalVariables
DeclareBaHaMASGlobalVariables

#If the help is asked, it doesn't matter which other options are given to the script
if ElementInArray '-h' "$@" || ElementInArray '--help' "$@"; then
    ParseCommandLineOption '--help'
elif ElementInArray '--helpDatabase' "$@"; then
    ParseCommandLineOption '-d' '-h'
else
    SPECIFIED_COMMAND_LINE_OPTIONS=( $@ )
fi

#Make checks on all variables
CheckWilsonStaggeredVariables
CheckUserDefinedVariables

exit

#####################################CREATE OPTIONS FOR COMMAND-LINE-PARSER######################################
#Inverter Options
CORRELATOR_DIRECTION="0"
NUMBER_SOURCES_FOR_CORRELATORS="8"


#Important arrays for uncomment functionality. PUT THEM ELSEWHERE?
UNCOMMENT_BETAS_SEED_ARRAY=()
UNCOMMENT_BETAS_ARRAY=()

#Array for the options string
DATABASE_OPTIONS=()


#-----------------------------------------------------------------------------------------------------------------#
# Extract options and their arguments into variables, saving a copy of the specified options in an array for later use.
# NOTE: The CLUSTER_NAME variable has not been so far put in the parser since
#       it can be either LOEWE or LCSC or JUQUEEN. It is set using whoami/hostname. Change this in future if needed!
if [[ $(whoami) =~ ^hkf[[:digit:]]{3} ]]; then
    CLUSTER_NAME="JUQUEEN"
    WALLTIME="00:30:00"
elif [ "$(hostname)" = "lxlcsc0001" ]; then
    CLUSTER_NAME="LCSC"
fi


ParseCommandLineOption "${SPECIFIED_COMMAND_LINE_OPTIONS[@]}"


if [ "$CALL_DATABASE" = "TRUE" ]; then
    projectStatisticsDatabase ${DATABASE_OPTIONS[@]}
    exit
fi
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Check if the necessary scripts exist.
if [ ! -f $HMC_GLOBALPATH ]; then
    printf "\n\e[0;31m The following file has not been found:\n\e[0m"
    printf "\n\e[0;31m   - $HMC_GLOBALPATH\e[0m"
    printf "\n\n\e[0;31m Aborting...\n\n\e[0m"
    exit -1
fi
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Perform all the checks on the path, reading out some variables
if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
    CheckSingleOccurrenceInPath "homeb" "hkf8/" "hkf8[[:digit:]]\+" "${NFLAVOUR_PREFIX}${NFLAVOUR_REGEX}" "${CHEMPOT_PREFIX}${CHEMPOT_REGEX}" "${MASS_PREFIX}${MASS_REGEX}" "${NTIME_PREFIX}${NTIME_REGEX}" "${NSPACE_PREFIX}${NSPACE_REGEX}"
else
    CheckSingleOccurrenceInPath $(echo $HOME_DIR | sed 's/\// /g') "${NFLAVOUR_PREFIX}${NFLAVOUR_REGEX}" "${CHEMPOT_PREFIX}${CHEMPOT_REGEX}" "${MASS_PREFIX}${MASS_REGEX}" "${NTIME_PREFIX}${NTIME_REGEX}" "${NSPACE_PREFIX}${NSPACE_REGEX}"
fi

ReadParametersFromPath $(pwd)

HOME_DIR_WITH_BETAFOLDERS="$HOME_DIR/$SIMULATION_PATH$PARAMETERS_PATH"
WORK_DIR_WITH_BETAFOLDERS="$WORK_DIR/$SIMULATION_PATH$PARAMETERS_PATH"

if [ "$HOME_DIR_WITH_BETAFOLDERS" != "$(pwd)" ]; then
    printf "\n\e[0;31m HOME_DIR_WITH_BETAFOLDERS=$HOME_DIR_WITH_BETAFOLDERS\n"
    printf "\e[0;31m Constructed path to directory containing beta folders does not match the actual position! Aborting...\n\n\e[0m"
    exit -1
fi
if [ ! -d $WORK_DIR_WITH_BETAFOLDERS ]; then
    printf "\n\e[0;31m WORK_DIR_WITH_BETAFOLDERS=$WORK_DIR_WITH_BETAFOLDERS\n"
    printf "\e[0;31m seems not to be an existing folder! Aborting...\n\n\e[0m"
    exit -1
fi

#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Treat each mutually exclusive option separately, even if some steps are in common. This improves readability!
# It is also evident what the script does in the various options!

SUBMIT_BETA_ARRAY=()
PROBLEM_BETA_ARRAY=() #Arrays that will contain the beta values that actually will be processed
declare -A INTSTEPS0_ARRAY
declare -A INTSTEPS1_ARRAY
declare -A CONTINUE_RESUMETRAJ_ARRAY
declare -A MASS_PRECONDITIONING_ARRAY
declare -A STARTCONFIGURATION_GLOBALPATH #NOTE: Before bash 4.2 associative array are LOCAL by default (from bash 4.2 one can do "declare -g ARRAY" to make it global).
                                         #      This is the reason why they are declared here and not in ReadBetaValuesFromFile where it would be natural!!

if [ ${#MUTUALLYEXCLUSIVEOPTS_PASSED[@]} = 0 ]; then

    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES
    ProduceInputFileAndJobScriptForEachBeta

elif [ $SUBMITONLY = "TRUE" ]; then

    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES
    ProcessBetaValuesForSubmitOnly
    SubmitJobsForValidBetaValues #TODO: Declare all possible local variable in this function as local!

elif [ $SUBMIT = "TRUE" ]; then

    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES
    ProduceInputFileAndJobScriptForEachBeta
    SubmitJobsForValidBetaValues #TODO: Declare all possible local variable in this function as local!

elif [ $THERMALIZE = "TRUE" ] || [ $CONTINUE_THERMALIZATION = "TRUE" ]; then

    if [ $USE_MULTIPLE_CHAINS = "FALSE" ]; then
        [ $THERMALIZE = "TRUE" ] && printf "\n\e[0;31m Option -t | --thermalize implemented ONLY combined not with --doNotUseMultipleChains option! Aborting...\n\n\e[0m"
        [ $CONTINUE_THERMALIZATION = "TRUE" ] && printf "\n\e[0;31m Option -C | --continueThermalization implemented ONLY combined not with --doNotUseMultipleChains option! Aborting...\n\n\e[0m"
        exit -1
    fi
    #Here we fix the beta postfix just looking for thermalized conf from hot at the actual parameters (no matter at which beta);
    #if at least one configuration thermalized from hot is present, it means the thermalization has to be done from conf (the
    #correct beta to be used is selected then later in the script ---> see where the array STARTCONFIGURATION_GLOBALPATH is filled
    #
    # TODO: If a thermalization from hot is finished but one other crashed and one wishes to resume it, the postfix should be
    #       from Hot but it is from conf since in $THERMALIZED_CONFIGURATIONS_PATH a conf from hot is found. Think about how to fix this.
    if [ $(ls $THERMALIZED_CONFIGURATIONS_PATH | grep "conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA_REGEX}_${SEED_PREFIX}${SEED_REGEX}_fromHot[[:digit:]]\+.*" | wc -l) -eq 0 ]; then
        BETA_POSTFIX="_thermalizeFromHot"
    else
        BETA_POSTFIX="_thermalizeFromConf"
    fi
    if [ $MEASURE_PBP = "TRUE" ]; then
        printf "\n \e[1;33;4mMeasurement of PBP switched off during thermalization!!\n\e[0m"
        MEASURE_PBP="FALSE"
    fi

    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES

    if [ $THERMALIZE = "TRUE" ]; then
        ProduceInputFileAndJobScriptForEachBeta
        CONFIRM="";
        printf "\n\e[0;33m Check if everything is fine. Would you like to submit the jobs (Y/N)? \e[0m"
        while read CONFIRM; do
            if [ "$CONFIRM" = "Y" ]; then
                break;
            elif [ "$CONFIRM" = "N" ]; then
                printf "\n\e[1;37;41mNo jobs will be submitted.\e[0m\n"
                exit
            else
                printf "\n\e[0;33m Please enter Y (yes) or N (no): \e[0m"
            fi
        done
        unset -v 'CONFIRM'
    elif [ $CONTINUE_THERMALIZATION = "TRUE" ]; then
        ProcessBetaValuesForContinue
    fi
    SubmitJobsForValidBetaValues #TODO: Declare all possible local variable in this function as local!

elif [ $CONTINUE = "TRUE" ]; then

    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES
    ProcessBetaValuesForContinue #TODO: Declare all possible local variable in this function as local! Use also only capital letters!
    SubmitJobsForValidBetaValues #TODO: Declare all possible local variable in this function as local!

elif [ $LISTSTATUS = "TRUE" ]; then

    ListJobStatus

elif [ $ACCRATE_REPORT = "TRUE" ]; then

    ReadBetaValuesFromFile
    AcceptanceRateReport

elif [ $CLEAN_OUTPUT_FILES = "TRUE" ]; then

    if [ $SECONDARY_OPTION_ALL = "TRUE" ]; then
        BETAVALUES=( $( ls $WORK_DIR_WITH_BETAFOLDERS | grep "^${BETA_PREFIX}${BETA_REGEX}" | awk '{print substr($1,2)}') )
    else
        ReadBetaValuesFromFile
    fi
    CleanOutputFiles

elif [ $COMPLETE_BETAS_FILE = "TRUE" ]; then

    CompleteBetasFile

elif [ $UNCOMMENT_BETAS = "TRUE" ] || [ $COMMENT_BETAS = "TRUE" ]; then

    UncommentEntriesInBetasFile

elif [ $INVERT_CONFIGURATIONS = "TRUE" ]; then

    ReadBetaValuesFromFile
    ProcessBetaValuesForInversion
    SubmitJobsForValidBetaValues
fi



#------------------------------------------------------------------------------------------------------------------------------#
# Report on eventual problems
PrintReportForProblematicBeta
#------------------------------------------------------------------------------------------------------------------------------#

printf "\e[0;32m \n ...done!\n\n\e[0m"

exit 0
