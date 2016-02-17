# Paths on LOEWE using CL2QCD
#
# Note, this is only a template, you MUST copy it to another file called UserSpecificVariables.sh
# and complete it setting all the variables to proper values. Remove also the "echo lines" in the
# formulations you are going to use.
#
# ATTENTION: Do not put slashes "/" at the end of the paths variables!!


USER_MAIL=""
HMC_BUILD_PATH=""
HOME_DIR="" 
WORK_DIR="" 
GPU_PER_NODE=
JOBSCRIPT_LOCALFOLDER=""

if [ $WILSON = "TRUE" ]; then
    
    echo -e "\e[0;31m Parameters for Wilson case unset in \"UserSpecificVariables.sh\" file! Aborting...\e[0m" && exit -1;
    
    SIMULATION_PATH=""
    HMC_FILENAME=""
    INVERTER_FILENAME=""
    INPUTFILE_NAME=""
    JOBSCRIPT_PREFIX=""
    OUTPUTFILE_NAME=""
    SRUN_COMMANDSFILE_FOR_INVERSION=""
	PROJECT_DATABASE_FILENAME=""
	PROJECT_DATABASE_DIRECTORY=""
fi

if [ $STAGGERED = "TRUE" ]; then

    echo -e "\e[0;31m Parameters for Staggered case unset in \"UserSpecificVariables.sh\" file! Aborting...\e[0m" && exit -1;

    SIMULATION_PATH=""
    HMC_FILENAME=""
    INPUTFILE_NAME=""
    JOBSCRIPT_PREFIX=""
    OUTPUTFILE_NAME=""
    RATIONAL_APPROXIMATIONS_PATH=""
    APPROX_HEATBATH_NAME=""
    APPROX_MD_NAME=""
    APPROX_METROPOLIS_NAME=""
	PROJECT_DATABASE_FILENAME="projectStatistics_$(date +%d_%m_%y).dat"
	PROJECT_DATABASE_DIRECTORY=""
fi

HMC_GLOBALPATH="${HOME}/$HMC_BUILD_PATH/$HMC_FILENAME"
INVERTER_GLOBALPATH="${HOME}/$HMC_BUILD_PATH/$INVERTER_FILENAME"
THERMALIZED_CONFIGURATIONS_PATH=""


# Documentation:
#
#     USER_MAIL                             mail to which job information (e.g. failures) is sent to
#     HMC_BUILD_PATH                        path to the folder where the executable is (from user's HOME directory)
#     HOME_DIR                              path to the disk from which the jobs are submitted (see further informations below)
#     WORK_DIR                              path to the disk from which the jobs are run (see further informations below)
#     GPU_PER_NODE                          number of GPUs per node
#     JOBSCRIPT_LOCALFOLDER                 name of the folder where the job scripts are collected
#     SIMULATION_PATH                       path to the folder containing the parameters folders structure (see further informations below)
#     HMC_FILENAME                          name of the executable
#     INPUTFILE_NAME                        name of the inputfile
#     JOBSCRIPT_PREFIX                      prefix of the jobscript name
#     OUTPUTFILE_NAME                       name of the outputfile
#     RATIONAL_APPROXIMATIONS_PATH          global path to the folder containing the rational approximations
#     APPROX_HEATBATH_NAME                  rational approximation used for the pseudofermion fields
#     APPROX_MD_NAME                        rational approximation used for the molecular dynamis
#     APPROX_METROPOLIS_NAME                rational approximation used for the metropolis test
#     HMC_GLOBALPATH                        executable global path
#     THERMALIZED_CONFIGURATIONS_PATH       global path to the folder containing the thermalized configurations
#     SRUN_COMMANDSFILE_FOR_INVERSION       name of the file where the execution commands for the inversions are being stored
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

