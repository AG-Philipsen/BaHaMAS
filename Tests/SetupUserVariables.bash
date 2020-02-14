
function DeclareOutputRelatedGlobalVariables()
{
    readonly BHMAS_coloredOutput='TRUE'
}

function DeclareUserDefinedGlobalVariablesForTests()
{
    readonly BHMAS_userEmail="user@test.com"
    readonly BHMAS_submitDiskGlobalPath="${BHMAS_repositoryTopLevelPath}/Tests"
    readonly BHMAS_runDiskGlobalPath="${BHMAS_repositoryTopLevelPath}/Tests"
    readonly BHMAS_GPUsPerNode=999
    readonly BHMAS_jobScriptFolderName="Jobscripts_TEST"
    readonly BHMAS_excludeNodesGlobalPath="${BHMAS_submitDiskGlobalPath}/ExcludeNodes_TEST"

    readonly BHMAS_projectSubpath="StaggeredFakeProject"
    readonly BHMAS_hmcGlobalPath="${BHMAS_submitDiskGlobalPath}/AuxiliaryFiles/fakeExecutable"
    readonly BHMAS_inputFilename="fakeInput"
    readonly BHMAS_jobScriptPrefix="fakePrefix"
    readonly BHMAS_outputFilename="fakeOutput"
    readonly BHMAS_plaquetteColumn=2
    readonly BHMAS_deltaHColumn=8
    readonly BHMAS_acceptanceColumn=9
    readonly BHMAS_trajectoryTimeColumn=10
    readonly BHMAS_useRationalApproxFiles='TRUE'
    readonly BHMAS_rationalApproxGlobalPath="${BHMAS_submitDiskGlobalPath}/${BHMAS_projectSubpath}/Rational_Approximations"
    readonly BHMAS_approxHeatbathFilename="fakeApprox"
    readonly BHMAS_approxMDFilename="fakeApprox"
    readonly BHMAS_approxMetropolisFilename="fakeApprox"
    readonly BHMAS_databaseFilename="OverviewDatabase"
    readonly BHMAS_databaseGlobalPath="${BHMAS_submitDiskGlobalPath}/${BHMAS_projectSubpath}/SimulationsOverview"
    readonly BHMAS_inverterGlobalPath="${BHMAS_submitDiskGlobalPath}/AuxiliaryFiles/fakeExecutable"
    readonly BHMAS_thermConfsGlobalPath="${BHMAS_submitDiskGlobalPath}/${BHMAS_projectSubpath}/Thermalized_Configurations"

    #Possible default value for options which can then not be given via command line
    BHMAS_walltime=""
    BHMAS_clusterPartition=""
    BHMAS_clusterNode=""
    BHMAS_clusterConstraint=""
    BHMAS_clusterGenericResource=""
    BHMAS_maximumWalltime="1-00:00:00"

}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         DeclareOutputRelatedGlobalVariables\
         DeclareUserDefinedGlobalVariablesForTests
