# User provided variables necessary in order to use BaHaMAS
#
# NOTE: This is only a template file and it MUST be copied into another file
#       called "UserSpecificVariables.bash" and completed, setting all the
#       variables to proper values. Feel free to customize your checks, but
#       consider that this function is called at the beginning of BaHaMAS.
#
# ATTENTION: Do not put slashes "/" at the end of the paths variables!!

function DeclareUserDefinedGlobalVariables()
{

    BaHaMAS_colouredOutput='TRUE'
    USER_MAIL=""
    SUBMIT_DISK_GLOBALPATH=""
    RUN_DISK_GLOBALPATH=""
    GPU_PER_NODE=
    JOBSCRIPT_FOLDERNAME=""
    EXCLUDE_NODES_GLOBALPATH=""

    if [ $WILSON = "TRUE" ]; then
        PROJECT_SUBPATH=""
        HMC_GLOBALPATH=""
        INPUT_FILENAME=""
        JOBSCRIPT_PREFIX=""
        OUTPUT_FILENAME=""
        ACCEPTANCE_COLUMN=
        USE_RATIONAL_APPROXIMATION_FILE='FALSE'
        RATIONAL_APPROX_GLOBALPATH=""
        APPROX_HEATBATH_FILENAME=""
        APPROX_MD_FILENAME=""
        APPROX_METROPOLIS_FILENAME=""
        DATABASE_FILENAME=""
        DATABASE_GLOBALPATH=""
        INVERTER_GLOBALPATH=""
        THERM_CONFS_GLOBALPATH=""
    fi

    if [ $STAGGERED = "TRUE" ]; then
        PROJECT_SUBPATH=""
        HMC_GLOBALPATH=""
        INPUT_FILENAME=""
        JOBSCRIPT_PREFIX=""
        OUTPUT_FILENAME=""
        ACCEPTANCE_COLUMN=
        USE_RATIONAL_APPROXIMATION_FILE='FALSE'
        RATIONAL_APPROX_GLOBALPATH=""
        APPROX_HEATBATH_FILENAME=""
        APPROX_MD_FILENAME=""
        APPROX_METROPOLIS_FILENAME=""
        DATABASE_FILENAME=""
        DATABASE_GLOBALPATH=""
        INVERTER_GLOBALPATH=""
        THERM_CONFS_GLOBALPATH=""
    fi

    #Possible default value for options which can then not be given via command line
    WALLTIME=""
    CLUSTER_PARTITION=""
    CLUSTER_NODE=""
    CLUSTER_CONSTRAINT=""
    CLUSTER_GENERIC_RESOURCE=""

}

# Documentation:
#
#     BaHaMAS_colouredOutput        -->  it can be 'TRUE' or 'FALSE' and can be used to disable coloured output
#     USER_MAIL                     -->  mail to which job information (e.g. failures) is sent to
#     SUBMIT_DISK_GLOBALPATH        -->  global path to the disk from which the jobs are submitted (see further informations below)
#     RUN_DISK_GLOBALPATH           -->  global path to the disk from which the jobs are run (see further informations below)
#     GPU_PER_NODE                  -->  number of GPUs per node
#     JOBSCRIPT_FOLDERNAME          -->  name of the folder where the job scripts are collected
#     EXCLUDE_NODES_GLOBALPATH      -->  local or remote global path to file containing the directive to exclude nodes
#     PROJECT_SUBPATH               -->  path from HOME and WORK to the folder containing the parameters folders structure (see further informations below)
#     HMC_GLOBALPATH                -->  production executable global path
#     INPUT_FILENAME                -->  name of the inputfile
#     JOBSCRIPT_PREFIX              -->  prefix of the jobscript name
#     OUTPUT_FILENAME               -->  name of the outputfile
#     ACCEPTANCE_COLUMN             -->  number of column containing outcomes (zeros or ones) of Metropolis test [first column is column number 1].
#     RATIONAL_APPROX_GLOBALPATH    -->  global path to the folder containing the rational approximations
#     APPROX_HEATBATH_FILENAME      -->  rational approximation used for the pseudofermion fields
#     APPROX_MD_FILENAME            -->  rational approximation used for the molecular dynamis
#     APPROX_METROPOLIS_FILENAME    -->  rational approximation used for the metropolis test
#     INVERTER_GLOBALPATH           -->  inverter executable global path
#     THERM_CONFS_GLOBALPATH        -->  global path to the folder containing the thermalized configurations
#     DATABASE_GLOBALPATH           -->  directory where the the simulation status files are stored (it MUST be a GLOBALPATH)
#     DATABASE_FILENAME             -->  name of the file containing the database
#     WALLTIME                      -->  jobs walltime in the format 'days-hours:min:sec'
#     CLUSTER_PARTITION             -->  name of the partition of the cluster that has to be used
#     CLUSTER_NODE                  -->  list of nodes that have to be used
#     CLUSTER_CONSTRAINT            -->  constraint on hardware of the cluster
#     CLUSTER_GENERIC_RESOURCE      -->  cluster resource selection
#
# Some further information:
#
#   The SUBMIT_DISK_GLOBALPATH, RUN_DISK_GLOBALPATH, PROJECT_SUBPATH variables above could be a bit confusing. Basically, they are used to build the global
#   path of the folders from which the jobs are submitted and run. In particular:
#
#       - folder global path from which jobs are submitted:  $SUBMIT_DISK_GLOBALPATH/$PROJECT_SUBPATH/$PARAMETERS_PATH
#       -       folder global path from which jobs are run:  $RUN_DISK_GLOBALPATH/$PROJECT_SUBPATH/$PARAMETERS_PATH
#
#   where $PARAMETERS_PATH is the folder structure like 'Nf2/muiPiT/k1550/nt6/ns12' or like 'Nf3/mui0/mass0250/nt4/ns8'.
#
