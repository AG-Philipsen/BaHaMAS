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

#----------------------------------------------------------------------------------------------------------------#
# Load auxiliary bash files that will be used.                                                                   #
readonly BaHaMAS_repositoryTopLevelPath="$(git -C $(dirname "${BASH_SOURCE[0]}") rev-parse --show-toplevel)"     #
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/SystemRequirements.bash           || exit -2     #
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/FindClusterScheduler.bash         || exit -2     #
readonly BHMAS_clusterScheduler="$(SelectClusterSchedulerName)" #It is needed to source cluster specific files!  #
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/UtilityFunctions.bash             || exit -2     #
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/GlobalVariables.bash              || exit -2     #
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/CheckGlobalVariables.bash         || exit -2     #
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/OutputFunctionality.bash          || exit -2     #
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/PathManagementFunctionality.bash  || exit -2     #
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/OperationsOnBetasFile.bash        || exit -2     #
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/FindStartingConfiguration.bash    || exit -2     #
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/AcceptanceRateReport.bash         || exit -2     #
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/CleanOutputFiles.bash             || exit -2     #
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/ClusterSpecificFunctionsCall.bash || exit -2     #
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/ReportOnProblematicBetas.bash     || exit -2     #
source ${BaHaMAS_repositoryTopLevelPath}/CommandLineParsers/MainParser.bash                       || exit -2     #
source ${BaHaMAS_repositoryTopLevelPath}/Database/ProjectStatisticsDatabase.bash                  || exit -2     #
# User file to be sourced depending on test mode                                                                 #
if [ -n "${BaHaMAS_testModeOn:+x}" ] && [ ${BaHaMAS_testModeOn} = 'TRUE' ]; then                                 #
    source ${BaHaMAS_repositoryTopLevelPath}/Tests/SetupUserVariables.bash || exit -2                            #
else                                                                                                             #
    source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/UserSpecificVariables.bash || exit -2        #
fi                                                                                                               #
#----------------------------------------------------------------------------------------------------------------#

#Set stricter shell mode. This implies for the developer to be aware of what is going on,
#but it is worth so. Good reference http://redsymbol.net/articles/unofficial-bash-strict-mode
set -euo pipefail

#Declare all variables (color user decisions for output needed from very beginning)
DeclareOutputRelatedGlobalVariables
DeclarePathRelatedGlobalVariables
if [ -n "${BaHaMAS_testModeOn:+x}" ] && [ ${BaHaMAS_testModeOn} = 'TRUE' ]; then
    DeclareUserDefinedGlobalVariablesForTests
else
    #Here be more friendly with user (no unbound errors, she/he could type wrong)
    set +u; DeclareUserDefinedGlobalVariables; set -u
fi
DeclareBaHaMASGlobalVariables

#If the help is asked, it doesn't matter which other options are given to the script
if ElementInArray '-h' "$@" || ElementInArray '--help' "$@"; then
    ParseCommandLineOption '--help'
elif ElementInArray '--helpDatabase' "$@"; then
    ParseCommandLineOption '-d' '-h'
else
    BHMAS_specifiedCommandLineOptions=( "$@" )
fi

#Do some checks on system and variables, parse user option and do some more checks
CheckSystemRequirements
CheckWilsonStaggeredVariables
CheckUserDefinedVariablesAndDefineDependentAdditionalVariables
[ $# -ne 0 ] && ParseCommandLineOption "${BHMAS_specifiedCommandLineOptions[@]}"
CheckBaHaMASVariablesAndExistenceOfFilesAndFoldersDependingOnUserCase

if [ $BHMAS_databaseOption = 'FALSE' ]; then
    #Perform all the checks on the path, reading out parameters and testing additional paths
    CheckSingleOccurrenceInPath $(sed 's/\// /g' <<< "$BHMAS_submitDiskGlobalPath")\
                                "${BHMAS_nflavourPrefix}${BHMAS_nflavourRegex}"\
                                "${BHMAS_chempotPrefix}${BHMAS_chempotRegex}"\
                                "${BHMAS_massPrefix}${BHMAS_massRegex}"\
                                "${BHMAS_ntimePrefix}${BHMAS_ntimeRegex}"\
                                "${BHMAS_nspacePrefix}${BHMAS_nspaceRegex}"
    ReadParametersFromPathAndSetRelatedVariables $(pwd)
    DeclareBetaFoldersPathsAsGlobalVariables
    CheckBetaFoldersPathsVariables
fi

#-----------------------------------------------------------------------------------------------------------------#
#  Treat each mutually exclusive option separately, even if some steps are in common. This improves readability!  #
#-----------------------------------------------------------------------------------------------------------------#

if [ $BHMAS_databaseOption = 'TRUE' ]; then

    projectStatisticsDatabase ${BHMAS_optionsToBePassedToDatabase[@]}

elif [ $BHMAS_submitonlyOption = 'TRUE' ]; then

    ParseBetasFile
    FindConfigurationGlobalPathFromWhichToStartTheSimulation #TODO: This should not be needed! Check if it is true!
    ProcessBetaValuesForSubmitOnly
    SubmitJobsForValidBetaValues

elif [ $BHMAS_submitOption = 'TRUE' ]; then

    ParseBetasFile
    FindConfigurationGlobalPathFromWhichToStartTheSimulation
    ProduceInputFileAndJobScriptForEachBeta
    SubmitJobsForValidBetaValues

elif [ $BHMAS_thermalizeOption = 'TRUE' ] || [ $BHMAS_continueThermalizationOption = 'TRUE' ]; then

    if [ $BHMAS_useMultipleChains = 'FALSE' ]; then
        [ $BHMAS_thermalizeOption = 'TRUE' ] && cecho lr "\n Option -t | --thermalize implemented ONLY combined not with --doNotUseMultipleChains option! Aborting...\n"
        [ $BHMAS_continueThermalizationOption = 'TRUE' ] && cecho lr "\n Option -C | --continueThermalization implemented ONLY combined not with --doNotUseMultipleChains option! Aborting...\n"
        exit -1
    fi
    #Here we fix the beta postfix just looking for thermalized conf from hot at the actual parameters (no matter at which beta);
    #if at least one configuration thermalized from hot is present, it means the thermalization has to be done from conf (the
    #correct beta to be used is selected then later in the script ---> see where the array BHMAS_startConfigurationGlobalPath is filled
    #
    # TODO: If a thermalization from hot is finished but one other crashed and one wishes to resume it, the postfix should be
    #       from Hot but it is from conf since in $BHMAS_thermConfsGlobalPath a conf from hot is found. Think about how to fix this.
    if [ $(ls $BHMAS_thermConfsGlobalPath | grep "conf.${BHMAS_parametersString}_${BHMAS_betaPrefix}${BHMAS_betaRegex}_${BHMAS_seedPrefix}${BHMAS_seedRegex}_fromHot[[:digit:]]\+.*" | wc -l) -eq 0 ]; then
        BHMAS_betaPostfix="_thermalizeFromHot"
    else
        BHMAS_betaPostfix="_thermalizeFromConf"
    fi
    if [ $BHMAS_measurePbp = 'TRUE' ]; then
        cecho ly B "\n Measurement of PBP switched off during thermalization!"
        BHMAS_measurePbp='FALSE'
    fi
    ParseBetasFile
    FindConfigurationGlobalPathFromWhichToStartTheSimulation
    if [ $BHMAS_thermalizeOption = 'TRUE' ]; then
        ProduceInputFileAndJobScriptForEachBeta
        AskUser "Check if everything is fine. Would you like to submit the jobs?"
        if UserSaidNo; then
            cecho lr "\n No job will be submitted!\n"
            exit 0
        fi
    elif [ $BHMAS_continueThermalizationOption = 'TRUE' ]; then
        ProcessBetaValuesForContinue
    fi
    SubmitJobsForValidBetaValues

elif [ $BHMAS_continueOption = 'TRUE' ]; then

    ParseBetasFile
    ProcessBetaValuesForContinue
    SubmitJobsForValidBetaValues

elif [ $BHMAS_liststatusOption = 'TRUE' ]; then

    ListSimulationsStatus

elif [ $BHMAS_accRateReportOption = 'TRUE' ]; then

    ParseBetasFile
    AcceptanceRateReport

elif [ $BHMAS_cleanOutputFilesOption = 'TRUE' ]; then

    if [ $BHMAS_cleanAllOutputFiles = 'TRUE' ]; then
        BHMAS_betaValues=( $( ls $BHMAS_runDirWithBetaFolders | grep "^${BHMAS_betaPrefix}${BHMAS_betaRegex}" | awk '{print substr($1,2)}') )
    else
        ParseBetasFile
    fi
    CleanOutputFiles

elif [ $BHMAS_completeBetasFileOption = 'TRUE' ]; then

    CompleteBetasFile
    less "$BHMAS_betasFilename"

elif [ $BHMAS_uncommentBetasOption = 'TRUE' ]; then

    UncommentEntriesInBetasFile
    less "$BHMAS_betasFilename"

elif [ $BHMAS_commentBetasOption = 'TRUE' ]; then

    CommentEntriesInBetasFile
    less "$BHMAS_betasFilename"

elif [ $BHMAS_invertConfigurationsOption = 'TRUE' ]; then

    ParseBetasFile
    ProcessBetaValuesForInversion
    SubmitJobsForValidBetaValues

else

    ParseBetasFile
    FindConfigurationGlobalPathFromWhichToStartTheSimulation
    ProduceInputFileAndJobScriptForEachBeta

fi

#------------------------------------------------------------------------------------------------------------------------------#
# Report on eventual problems
PrintReportForProblematicBeta
#------------------------------------------------------------------------------------------------------------------------------#

cecho lg "\n ...done!\n"

exit 0
