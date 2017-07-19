#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

#------------------------------------------------------------------------------------------------------------------------------#
# The following source commands could fail since the file for the cluster scheduler could not be there, then suppress errors   #
source ${BHMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProduceJobScript.bash           2>/dev/null  #
source ${BHMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProduceInverterJobScript.bash   2>/dev/null  #
source ${BHMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/CommonFunctionality.bash        2>/dev/null  #
source ${BHMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProduceInputFile.bash           2>/dev/null  #
source ${BHMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProduceFilesForEachBeta.bash    2>/dev/null  #
source ${BHMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProcessBetasForSubmitOnly.bash  2>/dev/null  #
source ${BHMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProcessBetasForContinue.bash    2>/dev/null  #
source ${BHMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProcessBetasForInversion.bash   2>/dev/null  #
source ${BHMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/JobsSubmission.bash             2>/dev/null  #
source ${BHMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/JobsStatus.bash                 2>/dev/null  #
source ${BHMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/SimulationsStatus.bash          2>/dev/null  #
#------------------------------------------------------------------------------------------------------------------------------#

function __static__CheckExistenceOfFunctionAndCallIt()
{
    local nameOfTheFunction
    nameOfTheFunction=$1
    if [ "$(type -t $nameOfTheFunction)" = 'function' ]; then
        $nameOfTheFunction
    else
        Fatal $BHMAS_fatalMissingFeature "Function " emph "$nameOfTheFunction" " for " emph "$BHMAS_clusterScheduler" " scheduler not found!\n"\
              "Please provide an implementation following the " B "BaHaMAS" uB " documentation and source the file."
    fi
}


function ProduceInputFileAndJobScriptForEachBeta()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}


function ProcessBetaValuesForSubmitOnly()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}


function ProcessBetaValuesForContinue()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}


function ProcessBetaValuesForInversion()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}


function SubmitJobsForValidBetaValues()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}


function ListJobsStatus()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}

function ListSimulationsStatus()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         __static__CheckExistenceOfFunctionAndCallIt\
         ProduceInputFileAndJobScriptForEachBeta\
         ProcessBetaValuesForSubmitOnly\
         ProcessBetaValuesForContinue\
         ProcessBetaValuesForInversion\
         SubmitJobsForValidBetaValues\
         ListJobsStatus\
         ListSimulationsStatus
