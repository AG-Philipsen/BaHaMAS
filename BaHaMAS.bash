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
#                     2017  Alessandro Sciarra                            #
#                                                                         #
#-------------------------------------------------------------------------#

#------------------------------------------------------------------------------------------------------#
# Load auxiliary bash files that will be used.
BaHaMAS_repositoryTopLevelPath="$(git -C $(dirname "${BASH_SOURCE[0]}") rev-parse --show-toplevel)"
source ${BaHaMAS_repositoryTopLevelPath}/SystemRequirements.bash          || exit -2
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

#Set stricter shell mode. This implies for the developer to be aware of what is going on,
#but it is worth so. Good reference http://redsymbol.net/articles/unofficial-bash-strict-mode
#set -euo pipefail

#Declare all variables (color user decisions for output needed from very beginning)
DeclarePathRelatedGlobalVariables
DeclareUserDefinedGlobalVariables
DeclareBaHaMASGlobalVariables

#If the help is asked, it doesn't matter which other options are given to the script
if ElementInArray '-h' "$@" || ElementInArray '--help' "$@"; then
    ParseCommandLineOption '--help'
elif ElementInArray '--helpDatabase' "$@"; then
    ParseCommandLineOption '-d' '-h'
else
    SPECIFIED_COMMAND_LINE_OPTIONS=( "$@" )
fi

#Do some checks on system and variables, parse user option and do some more checks
CheckSystemRequirements
CheckWilsonStaggeredVariables
CheckUserDefinedVariablesAndDefineDependentAdditionalVariables
ParseCommandLineOption "${SPECIFIED_COMMAND_LINE_OPTIONS[@]}"
CheckBaHaMASVariablesAndExistenceOfFilesAndFoldersDependingOnUserCase

if [ $CALL_DATABASE = 'FALSE' ]; then
    #Perform all the checks on the path, reading out parameters and testing additional paths
    CheckSingleOccurrenceInPath $(sed 's/\// /g' <<< "$HOME_DIR")\
                                "${NFLAVOUR_PREFIX}${NFLAVOUR_REGEX}"\
                                "${CHEMPOT_PREFIX}${CHEMPOT_REGEX}"\
                                "${MASS_PREFIX}${MASS_REGEX}"\
                                "${NTIME_PREFIX}${NTIME_REGEX}"\
                                "${NSPACE_PREFIX}${NSPACE_REGEX}"
    ReadParametersFromPath $(pwd)
    DeclareBetaFoldersPathsAsGlobalVariables
    CheckBetaFoldersPathsVariables
fi

#-----------------------------------------------------------------------------------------------------------------#
#  Treat each mutually exclusive option separately, even if some steps are in common. This improves readability!  #
#-----------------------------------------------------------------------------------------------------------------#

if [ $CALL_DATABASE = 'TRUE' ]; then

    projectStatisticsDatabase ${DATABASE_OPTIONS[@]}

elif [ $SUBMITONLY = 'TRUE' ]; then

    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES
    ProcessBetaValuesForSubmitOnly
    SubmitJobsForValidBetaValues #TODO: Declare all possible local variable in this function as local!

elif [ $SUBMIT = 'TRUE' ]; then

    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES
    ProduceInputFileAndJobScriptForEachBeta
    SubmitJobsForValidBetaValues #TODO: Declare all possible local variable in this function as local!

elif [ $THERMALIZE = 'TRUE' ] || [ $CONTINUE_THERMALIZATION = 'TRUE' ]; then

    if [ $USE_MULTIPLE_CHAINS = 'FALSE' ]; then
        [ $THERMALIZE = 'TRUE' ] && printf "\n\e[0;31m Option -t | --thermalize implemented ONLY combined not with --doNotUseMultipleChains option! Aborting...\n\n\e[0m"
        [ $CONTINUE_THERMALIZATION = 'TRUE' ] && printf "\n\e[0;31m Option -C | --continueThermalization implemented ONLY combined not with --doNotUseMultipleChains option! Aborting...\n\n\e[0m"
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
    if [ $MEASURE_PBP = 'TRUE' ]; then
        printf "\n \e[1;33;4mMeasurement of PBP switched off during thermalization!!\n\e[0m"
        MEASURE_PBP='FALSE'
    fi

    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES

    if [ $THERMALIZE = 'TRUE' ]; then
        ProduceInputFileAndJobScriptForEachBeta
        printf "\n\e[0;33m Check if everything is fine. Would you like to submit the jobs (Y/N)? \e[0m"
        if UserSaidNo; then
            printf "\n\e[1;37;41mNo jobs will be submitted.\e[0m\n"
            exit 0
        fi
    elif [ $CONTINUE_THERMALIZATION = 'TRUE' ]; then
        ProcessBetaValuesForContinue
    fi
    SubmitJobsForValidBetaValues #TODO: Declare all possible local variable in this function as local!

elif [ $CONTINUE = 'TRUE' ]; then

    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES
    ProcessBetaValuesForContinue #TODO: Declare all possible local variable in this function as local! Use also only capital letters!
    SubmitJobsForValidBetaValues #TODO: Declare all possible local variable in this function as local!

elif [ $LISTSTATUS = 'TRUE' ]; then

    ListJobStatus

elif [ $ACCRATE_REPORT = 'TRUE' ]; then

    ReadBetaValuesFromFile
    AcceptanceRateReport

elif [ $CLEAN_OUTPUT_FILES = 'TRUE' ]; then

    if [ $SECONDARY_OPTION_ALL = 'TRUE' ]; then
        BETAVALUES=( $( ls $WORK_DIR_WITH_BETAFOLDERS | grep "^${BETA_PREFIX}${BETA_REGEX}" | awk '{print substr($1,2)}') )
    else
        ReadBetaValuesFromFile
    fi
    CleanOutputFiles

elif [ $COMPLETE_BETAS_FILE = 'TRUE' ]; then

    CompleteBetasFile

elif [ $UNCOMMENT_BETAS = 'TRUE' ]; then

    UncommentEntriesInBetasFile
    less "$BETASFILE"

elif [ $COMMENT_BETAS = 'TRUE' ]; then

    CommentEntriesInBetasFile
    less "$BETASFILE"

elif [ $INVERT_CONFIGURATIONS = 'TRUE' ]; then

    ReadBetaValuesFromFile
    ProcessBetaValuesForInversion
    SubmitJobsForValidBetaValues

else

    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES
    ProduceInputFileAndJobScriptForEachBeta

fi



#------------------------------------------------------------------------------------------------------------------------------#
# Report on eventual problems
PrintReportForProblematicBeta
#------------------------------------------------------------------------------------------------------------------------------#

printf "\e[0;32m \n ...done!\n\n\e[0m"

exit 0
