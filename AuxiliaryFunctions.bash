# Load auxiliary bash files that will be used.
source ${BaHaMAS_repositoryTopLevelPath}/AuxiliaryFunctions_SLURM.bash || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/ListJobsStatus_SLURM.bash     || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/CleanOutputFiles.bash         || exit -2
#------------------------------------------------------------------------------------#

function UncommentEntriesInBetasFile()
{
    #at first comment all lines
    sed -i "s/^\([^#].*\)/#\1/" $BHMAS_betasFilename

    local IFS=' '
    local OLD_IFS=$IFS
    for i in ${BHMAS_betasWithSeedToBeToggled[@]+"BHMAS_betasWithSeedToBeToggled[@]"}; do
        IFS='_'
        local U_ARRAY=( $i )
        local U_BETA=${U_ARRAY[0]}
        local U_SEED=${U_ARRAY[1]}
        local U_SEED=${U_SEED#s}
        sed -i "s/^#\(.*$U_BETA.*$U_SEED.*\)$/\1/" $BHMAS_betasFilename #If there is a "#" in front of the line, remove it
    done
    IFS=$OLD_IFS

    for i in ${BHMAS_betasToBeToggled[@]+"BHMAS_betasToBeToggled[@]"}; do
        U_BETA=$i
        sed -i "s/^#\(.*$U_BETA.*\)$/\1/" $BHMAS_betasFilename #If there is a "#" in front of the line, remove it
    done
}

function CommentEntriesInBetasFile()
{
    #at first uncomment all lines
    sed -i "s/^#\(.*\)/\1/" $BHMAS_betasFilename

    local IFS=' '
    local OLD_IFS=$IFS
    for i in ${BHMAS_betasWithSeedToBeToggled[@]+"BHMAS_betasWithSeedToBeToggled"}; do
        IFS='_'
        local U_ARRAY=( $i )
        local U_BETA=${U_ARRAY[0]}
        local U_SEED=${U_ARRAY[1]}
        local U_SEED=${U_SEED#s}
        sed -i "s/^\($U_BETA.*$U_SEED.*\)$/#\1/" $BHMAS_betasFilename #If there is no "#" in front of the line, put one
    done
    IFS=$OLD_IFS

    for i in ${BHMAS_betasToBeToggled[@]+"BHMAS_betasToBeToggled"}; do
        U_BETA=$i
        sed -i "s/^\($U_BETA.*\)$/#\1/" $BHMAS_betasFilename #If there is no "#" in front of the line, put one
    done
}


function PrintReportForProblematicBeta()
{
    if [ ${#BHMAS_problematicBetaValues[@]} -gt "0" ]; then
        cecho lr "\n===================================================================================\n"\
              " For the following beta values something went wrong and hence\n"\
              " they were left out during file creation and/or job submission:"
        for BETA in ${BHMAS_problematicBetaValues[@]}; do
            cecho lr "  - " B "$BETA"
        done
        cecho lr "===================================================================================\n"
        exit -1
    fi
}

#------------------------------------------------------------------------------------------------------------------------------#

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
