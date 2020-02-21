#!/bin/bash
#
#  Copyright (c) 2014-2016 Christopher Czaban
#  Copyright (c) 2014-2017,2020 Alessandro Sciarra
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


#-------------------------------------------------------------------------------#
#            ____              __  __            __  ___   ___     _____        #
#           / __ )   ____ _   / / / /  ____ _   /  |/  /  /   |   / ___/        #
#          / __  |  / __ `/  / /_/ /  / __ `/  / /|_/ /  / /| |   \__ \         #
#         / /_/ /  / /_/ /  / __  /  / /_/ /  / /  / /  / ___ |  ___/ /         #
#        /_____/   \__,_/  /_/ /_/   \__,_/  /_/  /_/  /_/  |_| /____/          #
#                                                                               #
#-------------------------------------------------------------------------------#
#                                                                               #
#         Copyright (c)  2014  Alessandro Sciarra, Christopher Czaban           #
#                        2015  Alessandro Sciarra, Christopher Czaban           #
#                        2016  Alessandro Sciarra, Christopher Czaban           #
#                        2017  Alessandro Sciarra                               #
#                                                                               #
#-------------------------------------------------------------------------------#

#-----------------------------------------------------------------------------------------------#
# Set stricter shell mode. This implies for the developer to be aware of what is going on,      #
# but it is worth so. Good reference http://redsymbol.net/articles/unofficial-bash-strict-mode  #
set -euo pipefail                                                                               #
#-----------------------------------------------------------------------------------------------#

#Load auxiliary bash files that will be used
readonly BHMAS_repositoryTopLevelPath="$(git -C $(dirname "${BASH_SOURCE[0]}") rev-parse --show-toplevel)"
source "${BHMAS_repositoryTopLevelPath}/SchedulerIndependentCode/SourceCodebaseFiles.bash" "$@"

DeclareAllGlobalVariables

#If the user asked for the Setup, it has to be done immediately and that's it
if IsBaHaMASRunInSetupMode; then
    MakeInteractiveSetupAndCreateUserDefinedVariablesFile
    exit $BHMAS_successExitCode
fi

if [ $# -ne 0 ]; then
    PrepareGivenOptionToBeParsedAndFillGlobalArrayContainingThem
    PrintHelperAndExitIfUserAskedForIt
fi

if ! WasAnyOfTheseOptionsGivenToBaHaMAS '--jobstatus'; then
    CheckSystemRequirements
    CheckWilsonStaggeredVariables
    CheckUserDefinedVariablesAndDefineDependentAdditionalVariables
fi

if [ $# -ne 0 ]; then
    ParseCommandLineOption "${BHMAS_specifiedCommandLineOptions[@]}"
fi

if ! WasAnyOfTheseOptionsGivenToBaHaMAS '--jobstatus'; then
    CheckBaHaMASVariablesAndExistenceOfFilesAndFoldersDependingOnUserCase
fi

if [ ${BHMAS_executionMode} != 'mode:database' ] && [ ${BHMAS_executionMode} != 'mode:job-status' ]; then
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

if [ ${BHMAS_executionMode} = 'mode:database' ]; then

    projectStatisticsDatabase ${BHMAS_optionsToBePassedToDatabase[@]+"${BHMAS_optionsToBePassedToDatabase[@]}"}

elif [ ${BHMAS_executionMode} = 'mode:submit-only' ]; then

    ParseBetasFile
    FindConfigurationGlobalPathFromWhichToStartTheSimulation #TODO: This should not be needed! Check if it is true!
    ProcessBetaValuesForSubmitOnly
    SubmitJobsForValidBetaValues

elif [ ${BHMAS_executionMode} = 'mode:submit' ]; then

    ParseBetasFile
    FindConfigurationGlobalPathFromWhichToStartTheSimulation
    ProduceInputFileAndJobScriptForEachBeta
    SubmitJobsForValidBetaValues

elif [ ${BHMAS_executionMode} = 'mode:thermalize' ] || [ ${BHMAS_executionMode} = 'mode:continue-thermalization' ]; then

    if [ $BHMAS_useMultipleChains = 'FALSE' ]; then
        if [ $BHMAS_thermalizeOption = 'TRUE' ] || [ $BHMAS_continueThermalizationOption = 'TRUE' ]; then
            Fatal $BHMAS_fatalCommandLine "Options " emph "--thermalize" " and " emph "--continueThermalization"\
                  " implemented " emph "only not" " combined not with " emph "--doNotUseMultipleChains" " option!"
        fi
    fi
    #Here we fix the beta postfix just looking for thermalized conf from hot at the actual parameters (no matter at which beta);
    #if at least one configuration thermalized from hot is present, it means the thermalization has to be done from conf (the
    #correct beta to be used is selected then later in the script ---> see where the array BHMAS_startConfigurationGlobalPath is filled
    #
    # TODO: If a thermalization from hot is finished but one other crashed and one wishes to resume it, the postfix should be
    #       from Hot but it is from conf since in $BHMAS_thermConfsGlobalPath a conf from hot is found. Think about how to fix this.
    if [ $(ls $BHMAS_thermConfsGlobalPath | grep "${BHMAS_configurationPrefix}${BHMAS_parametersString}_${BHMAS_betaPrefix}${BHMAS_betaRegex}_${BHMAS_seedPrefix}${BHMAS_seedRegex}_fromHot[[:digit:]]\+.*" | wc -l) -eq 0 ]; then
        BHMAS_betaPostfix="_thermalizeFromHot"
    else
        BHMAS_betaPostfix="_thermalizeFromConf"
    fi
    if [ $BHMAS_measurePbp = 'TRUE' ]; then
        cecho ly B "\n Measurement of PBP switched off during thermalization!"
        BHMAS_measurePbp='FALSE'
    fi
    ParseBetasFile
    if [ ${BHMAS_executionMode} = 'mode:thermalize' ]; then
        FindConfigurationGlobalPathFromWhichToStartTheSimulation
        ProduceInputFileAndJobScriptForEachBeta
        AskUser "Check if everything is fine. Would you like to submit the jobs?"
        if UserSaidNo; then
            cecho lr "\n No job will be submitted!\n"
            exit $BHMAS_successExitCode
        fi
    elif [ ${BHMAS_executionMode} = 'mode:continue-thermalization' ]; then
        ProcessBetaValuesForContinue
    fi
    SubmitJobsForValidBetaValues

elif [ ${BHMAS_executionMode} = 'mode:continue' ]; then

    ParseBetasFile
    ProcessBetaValuesForContinue
    SubmitJobsForValidBetaValues

elif [ ${BHMAS_executionMode} = 'mode:job-status' ]; then

    ListJobsStatus

elif [ ${BHMAS_executionMode} = 'mode:simulation-status' ]; then

    ListSimulationsStatus

elif [ ${BHMAS_executionMode} = 'mode:acceptance-rate-report' ]; then

    ParseBetasFile
    AcceptanceRateReport

elif [ ${BHMAS_executionMode} = 'mode:clean-output-files' ]; then

    if [ $BHMAS_cleanAllOutputFiles = 'TRUE' ]; then
        BHMAS_betaValues=( $( ls $BHMAS_runDirWithBetaFolders | grep "^${BHMAS_betaPrefix}${BHMAS_betaRegex}" | awk '{print substr($1,2)}') )
    else
        ParseBetasFile
    fi
    CleanOutputFiles

elif [ ${BHMAS_executionMode} = 'mode:complete-betas-file' ]; then

    CompleteBetasFile
    less "$BHMAS_betasFilename"

elif [ ${BHMAS_executionMode} = 'mode:uncomment-betas' ]; then

    UncommentEntriesInBetasFile
    less "$BHMAS_betasFilename"

elif [ ${BHMAS_executionMode} = 'mode:comment-betas' ]; then

    CommentEntriesInBetasFile
    less "$BHMAS_betasFilename"

elif [ ${BHMAS_executionMode} = 'mode:invert-configurations' ]; then

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

cecho ''

exit $BHMAS_successExitCode
