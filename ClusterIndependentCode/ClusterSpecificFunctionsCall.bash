#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

#------------------------------------------------------------------------------------------------------------------------------#
# The following source commands could fail since the file for the cluster scheduler could not be there, then suppress errors   #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProduceJobScript.bash           2>/dev/null  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProduceInverterJobScript.bash   2>/dev/null  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/CommonFunctionality.bash        2>/dev/null  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProduceInputFile.bash           2>/dev/null  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProduceFilesForEachBeta.bash    2>/dev/null  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProcessBetasForSubmitOnly.bash  2>/dev/null  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProcessBetasForContinue.bash    2>/dev/null  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProcessBetasForInversion.bash   2>/dev/null  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/JobsSubmission.bash             2>/dev/null  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/SimulationsStatus.bash          2>/dev/null  #
#------------------------------------------------------------------------------------------------------------------------------#

function __static__CheckExistenceOfFunctionAndCallIt()
{
    local nameOfTheFunction
    nameOfTheFunction=$1
    if [ "$(type -t $nameOfTheFunction)" = 'function' ]; then
        $nameOfTheFunction
    else
        cecho "\n " lr "Function " emph "$nameOfTheFunction" " for " emph "$BHMAS_clusterScheduler" " scheduler not found!"
        cecho "\n " lr "Please provide an implementation following the " B "BaHaMAS" uB " documentation and source the file. Aborting...\n"
        exit -1
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


function ListSimulationsStatus()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}
