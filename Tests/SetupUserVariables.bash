#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function DeclareOutputRelatedGlobalVariables()
{
    readonly BaHaMAS_colouredOutput='TRUE'
}

function DeclareUserDefinedGlobalVariablesForTests()
{
    readonly USER_MAIL="user@test.com"
    readonly SUBMIT_DISK_GLOBALPATH="${BaHaMAS_repositoryTopLevelPath}/Tests"
    readonly RUN_DISK_GLOBALPATH="${BaHaMAS_repositoryTopLevelPath}/Tests"
    readonly GPU_PER_NODE=999
    readonly JOBSCRIPT_FOLDERNAME="Jobscripts_TEST"
    readonly EXCLUDE_NODES_GLOBALPATH="${SUBMIT_DISK_GLOBALPATH}/ExcludeNodes_TEST"

    readonly PROJECT_SUBPATH="StaggeredFakeProject"
    readonly HMC_GLOBALPATH="${SUBMIT_DISK_GLOBALPATH}/AuxiliaryFiles/fakeExecutable"
    readonly INPUT_FILENAME="fakeInput"
    readonly JOBSCRIPT_PREFIX="fakePrefix"
    readonly OUTPUT_FILENAME="fakeOutput"
    readonly ACCEPTANCE_COLUMN=11
    readonly USE_RATIONAL_APPROXIMATION_FILE='TRUE'
    readonly RATIONAL_APPROX_GLOBALPATH="${SUBMIT_DISK_GLOBALPATH}/${PROJECT_SUBPATH}/Rational_Approximations"
    readonly APPROX_HEATBATH_FILENAME="fakeApprox"
    readonly APPROX_MD_FILENAME="fakeApprox"
    readonly APPROX_METROPOLIS_FILENAME="fakeApprox"
    readonly DATABASE_FILENAME="OverviewDatabase"
    readonly DATABASE_GLOBALPATH="${SUBMIT_DISK_GLOBALPATH}/${PROJECT_SUBPATH}/SimulationsOverview"
    readonly INVERTER_GLOBALPATH="${SUBMIT_DISK_GLOBALPATH}/AuxiliaryFiles/fakeExecutable"
    readonly THERM_CONFS_GLOBALPATH="${SUBMIT_DISK_GLOBALPATH}/${PROJECT_SUBPATH}/Thermalized_Configurations"

    #Possible default value for options which can then not be given via command line
    WALLTIME=""
    CLUSTER_PARTITION=""
    CLUSTER_NODE=""
    CLUSTER_CONSTRAINT=""
    CLUSTER_GENERIC_RESOURCE=""

}
