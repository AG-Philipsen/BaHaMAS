#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function DeclareUserDefinedGlobalVariablesForTests()
{
    BaHaMAS_colouredOutput='TRUE'
    USER_MAIL="user@test.com"
    SUBMIT_DISK_GLOBALPATH="${BaHaMAS_repositoryTopLevelPath}/Tests"
    RUN_DISK_GLOBALPATH="${BaHaMAS_repositoryTopLevelPath}/Tests"
    # NOTE: Here we put GPU_PER_NODE to a high number in order to make BaHaMAS ask the
    #       user about conifrmation that a node will not be fully used. It is just a trick
    #       to avoid that jobs are sumbitted in test phase!
    # TODO: Avoid this hack.
    GPU_PER_NODE=999
    JOBSCRIPT_FOLDERNAME="Jobscripts_TEST"
    EXCLUDE_NODES_GLOBALPATH="${SUBMIT_DISK_GLOBALPATH}/ExcludeNodes_TEST"

    PROJECT_SUBPATH="StaggeredFakeProject"
    HMC_GLOBALPATH="${SUBMIT_DISK_GLOBALPATH}/AuxiliaryFiles/fakeExecutable"
    INPUT_FILENAME="fakeInput"
    JOBSCRIPT_PREFIX="fakePrefix"
    OUTPUT_FILENAME="fakeOutput"
    ACCEPTANCE_COLUMN=11
    USE_RATIONAL_APPROXIMATION_FILE='TRUE'
    RATIONAL_APPROX_GLOBALPATH="${SUBMIT_DISK_GLOBALPATH}/${PROJECT_SUBPATH}/Rational_Approximations"
    APPROX_HEATBATH_FILENAME="fakeApprox"
    APPROX_MD_FILENAME="fakeApprox"
    APPROX_METROPOLIS_FILENAME="fakeApprox"
    DATABASE_FILENAME="OverviewDatabase"
    DATABASE_GLOBALPATH="${SUBMIT_DISK_GLOBALPATH}/${PROJECT_SUBPATH}/SimulationsOverview"
    INVERTER_GLOBALPATH="${SUBMIT_DISK_GLOBALPATH}/AuxiliaryFiles/fakeExecutable"
    THERM_CONFS_GLOBALPATH="${SUBMIT_DISK_GLOBALPATH}/${PROJECT_SUBPATH}/Thermalized_Configurations"

    #Possible default value for options which can then not be given via command line
    WALLTIME=""
    CLUSTER_PARTITION=""
    CLUSTER_NODE=""
    CLUSTER_CONSTRAINT=""
    CLUSTER_GENERIC_RESOURCE=""

}
