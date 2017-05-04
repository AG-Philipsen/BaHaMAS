# User provided variables necessary in order to use BaHaMAS
#
# NOTE: This is only a template file and it MUST be copied into another file
#       called "UserSpecificVariables.bash" and completed, setting all the
#       variables to proper values. Feel free to customize your checks, but
#       consider that this function is called at the beginning of BaHaMAS.
#
# ATTENTION: Do not put slashes "/" at the end of the paths variables!!

function DeclareUserDefinedGlobalVariables() {

    BaHaMAS_colouredOutput='TRUE'
    USER_MAIL=""
    HMC_BUILD_PATH=""
    HOME_DIR=""
    WORK_DIR=""
    GPU_PER_NODE=
    JOBSCRIPT_LOCALFOLDER=""
    FILE_WITH_WHICH_NODES_TO_EXCLUDE=""

    if [ $WILSON = "TRUE" ]; then

        cecho lr " Parameters for Wilson case unset in \"UserSpecificVariables.bash\" file! Aborting..." && exit -1;

        SIMULATION_PATH=""
        HMC_FILENAME=""
        INPUTFILE_NAME=""
        JOBSCRIPT_PREFIX=""
        OUTPUTFILE_NAME=""
        ACCEPTANCE_COLUMN=""
        PROJECT_DATABASE_FILENAME=""
        PROJECT_DATABASE_DIRECTORY=""
        SRUN_COMMANDSFILE_FOR_INVERSION=""
        INVERTER_FILENAME=""
        THERMALIZED_CONFIGURATIONS_PATH=""
    fi

    if [ $STAGGERED = "TRUE" ]; then

        cecho lr " Parameters for Staggered case unset in \"UserSpecificVariables.bash\" file! Aborting..." && exit -1;

        SIMULATION_PATH=""
        HMC_FILENAME=""
        INPUTFILE_NAME=""
        JOBSCRIPT_PREFIX=""
        OUTPUTFILE_NAME=""
        ACCEPTANCE_COLUMN=""
        RATIONAL_APPROXIMATIONS_PATH=""
        APPROX_HEATBATH_NAME=""
        APPROX_MD_NAME=""
        APPROX_METROPOLIS_NAME=""
        PROJECT_DATABASE_FILENAME=""
        PROJECT_DATABASE_DIRECTORY=""
        SRUN_COMMANDSFILE_FOR_INVERSION=""
        INVERTER_FILENAME=""
        THERMALIZED_CONFIGURATIONS_PATH=""
    fi

    HMC_GLOBALPATH="${HOME}/$HMC_BUILD_PATH/$HMC_FILENAME"
    INVERTER_GLOBALPATH="${HOME}/$HMC_BUILD_PATH/$INVERTER_FILENAME"

    #Possible default value for options which can then not be given via command line
    WALLTIME=""
    CLUSTER_PARTITION=""
    CLUSTER_NODE=""
    CLUSTER_CONSTRAINT=""
    CLUSTER_GENERIC_RESOURCE=""

}

# Documentation:
#
#     BaHaMAS_colouredOutput                it can be 'TRUE' or 'FALSE' and can be used to disable coloured output
#     USER_MAIL                             mail to which job information (e.g. failures) is sent to
#     HMC_BUILD_PATH                        path to the folder where the executable is (from user's HOME directory)
#     HOME_DIR                              path to the disk from which the jobs are submitted (see further informations below)
#     WORK_DIR                              path to the disk from which the jobs are run (see further informations below)
#     GPU_PER_NODE                          number of GPUs per node
#     JOBSCRIPT_LOCALFOLDER                 name of the folder where the job scripts are collected
#     FILE_WITH_WHICH_NODES_TO_EXCLUDE      local or remote global path to file containing the sbatch directive to exclude nodes (--exclude=...)
#     SIMULATION_PATH                       path to the folder containing the parameters folders structure (see further informations below)
#     HMC_FILENAME                          name of the executable
#     INPUTFILE_NAME                        name of the inputfile
#     JOBSCRIPT_PREFIX                      prefix of the jobscript name
#     OUTPUTFILE_NAME                       name of the outputfile
#     ACCEPTANCE_COLUMN                     number of column containing outcomes (zeros or ones) of Metropolis test [first column is column number 1].
#     RATIONAL_APPROXIMATIONS_PATH          global path to the folder containing the rational approximations
#     APPROX_HEATBATH_NAME                  rational approximation used for the pseudofermion fields
#     APPROX_MD_NAME                        rational approximation used for the molecular dynamis
#     APPROX_METROPOLIS_NAME                rational approximation used for the metropolis test
#     HMC_GLOBALPATH                        executable global path
#     THERMALIZED_CONFIGURATIONS_PATH       global path to the folder containing the thermalized configurations
#     INVERTER_FILENAME                     name of the inverter executable that comes with the cl2qcd code
#     SRUN_COMMANDSFILE_FOR_INVERSION       name of the file where the execution commands for the inversions are being stored
#     PROJECT_DATABASE_DIRECTORY            directory where the the simulation status files are stored (it MUST be a GLOBALPATH)
#     PROJECT_DATABASE_FILENAME             name of the file containing the database
#     WALLTIME                              jobs walltime in the format 'days-hours:min:sec'
#     CLUSTER_PARTITION                     name of the partition of the cluster that has to be used
#     CLUSTER_NODE                          list of nodes that have to be used
#     CLUSTER_CONSTRAINT                    constraint on hardware of the cluster
#     CLUSTER_GENERIC_RESOURCE              cluster resource selection
#
# Some further information:
#
#   The HOME_DIR, WORK_DIR, SIMULATION_PATH variables above could be a bit confusing. Basically, they are used to build the global
#   path of the folders from which the jobs are submitted and run. In particular:
#
#       - folder global path from which jobs are submitted:  $HOME_DIR/$SIMULATION_PATH/$PARAMETERS_PATH
#       -       folder global path from which jobs are run:  $WORK_DIR/$SIMULATION_PATH/$PARAMETERS_PATH
#
#   where $PARAMETERS_PATH is the folder structure like 'muiPiT/k1550/nt6/ns12' or like 'mui0/mass0250/nt4/ns8'.
#
