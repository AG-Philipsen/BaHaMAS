#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

function SourceClusterSpecificCode()
{
    readonly BHMAS_clusterScheduler="$(SelectClusterSchedulerName)"
    local listOfFilesToBeSourced
    listOfFilesToBeSourced=( 'ProduceJobScript.bash'
                             'ProduceInverterJobScript.bash'
                             'CommonFunctionality.bash'
                             'ProduceInputFile.bash'
                             'ProduceFilesForEachBeta.bash'
                             'ProcessBetasForSubmitOnly.bash'
                             'ProcessBetasForContinue.bash'
                             'ProcessBetasForInversion.bash'
                             'JobsSubmission.bash'
                             'JobsStatus.bash'
                             'SimulationsStatus.bash' )

    #The following source commands could fail since the file for the cluster scheduler could not be there,
    #then suppress the error and continue to avoid that the script exits due to 'set -e'
    for fileToBeSourced in "${listOfFilesToBeSourced[@]}"; do
        source "${BHMAS_repositoryTopLevelPath}/${BHMAS_clusterScheduler}_Implementation/${fileToBeSourced}" 2>/dev/null || continue
    done
}

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
