#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function DeclareUserDefinedGlobalVariablesForTests()
{
    BaHaMAS_colouredOutput='TRUE'
    USER_MAIL="user@test.com"
    HOME_DIR="${BaHaMAS_repositoryTopLevelPath}/Tests"
    WORK_DIR="${BaHaMAS_repositoryTopLevelPath}/Tests"
    # NOTE: Here we put GPU_PER_NODE to a high number in order to make BaHaMAS ask the
    #       user about conifrmation that a node will not be fully used. It is just a trick
    #       to avoid that jobs are sumbitted in test phase!
    # TODO: Avoid this hack.
    GPU_PER_NODE=999
    JOBSCRIPT_LOCALFOLDER="Jobscripts_TEST"
    FILE_WITH_WHICH_NODES_TO_EXCLUDE="${HOME_DIR}/ExcludeNodes_TEST"

    SIMULATION_PATH="StaggeredFakeProject"
    HMC_GLOBALPATH="${HOME_DIR}/AuxiliaryFiles/fakeExecutable"
    INPUTFILE_NAME="fakeInput"
    JOBSCRIPT_PREFIX="fakePrefix"
    OUTPUTFILE_NAME="fakeOutput"
    ACCEPTANCE_COLUMN=11
    USE_RATIONAL_APPROXIMATION_FILE='FALSE'
    RATIONAL_APPROXIMATIONS_PATH="${HOME_DIR}/${SIMULATION_PATH}/Rational_Approximations"
    APPROX_HEATBATH_NAME="fakeApprox"
    APPROX_MD_NAME="fakeApprox"
    APPROX_METROPOLIS_NAME="fakeApprox"
    PROJECT_DATABASE_FILENAME="OverviewDatabaseWilson"
    PROJECT_DATABASE_DIRECTORY="${HOME_DIR}/${SIMULATION_PATH}/SimulationsOverview"
    INVERTER_GLOBALPATH="${HOME_DIR}/AuxiliaryFiles/fakeExecutable"
    THERMALIZED_CONFIGURATIONS_PATH="${HOME_DIR}/${SIMULATION_PATH}/Thermalized_Configurations"

    #Possible default value for options which can then not be given via command line
    WALLTIME=""
    CLUSTER_PARTITION=""
    CLUSTER_NODE=""
    CLUSTER_CONSTRAINT=""
    CLUSTER_GENERIC_RESOURCE=""

}
