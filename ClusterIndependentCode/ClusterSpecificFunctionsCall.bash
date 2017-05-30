#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

#-----------------------------------------------------------------------------------------------------------------------------#
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProduceJobScript.bash           || exit -2  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProduceInverterJobScript.bash   || exit -2  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/CommonFunctionality.bash        || exit -2  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProduceInputFile.bash           || exit -2  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProduceFilesForEachBeta.bash    || exit -2  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProcessBetasForSubmitOnly.bash  || exit -2  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProcessBetasForContinue.bash    || exit -2  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ProcessBetasForInversion.bash   || exit -2  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/JobsSubmission.bash             || exit -2  #
source ${BaHaMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/ListJobsStatus.bash             || exit -2  #
#-----------------------------------------------------------------------------------------------------------------------------#

function __static__CheckExistenceOfFunctionAndCallIt()
{
    local nameOfTheFunction
    nameOfTheFunction=$1
    if [ "$(type -t $nameOfTheFunction)" = 'function' ]; then
        $nameOfTheFunction
    else
        cecho "\n" lr "Function " emph "$nameOfTheFunction" " for " emph "$BHMAS_clusterScheduler" " scheduler not found!"
        cecho "\n" lr "Please provide an implementation following the " B "BaHaMAS" uB " documentation and source the file. Aborting...\n"
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


function ListJobStatus()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}
