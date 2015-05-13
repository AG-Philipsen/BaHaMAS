# Paths on LOEWE using CL2QCD
USER_MAIL="sciarra@th.physik.uni-frankfurt.de"
HMC_BUILD_PATH="clhmc/build/RefExec"
HOME_DIR="/data01/hfftheo/sciarra" 
WORK_DIR="/scratch/hfftheo/sciarra" 
GPU_PER_NODE=4
JOBSCRIPT_LOCALFOLDER="JobScripts"

if [ $WILSON = "TRUE" ]; then
    SIMULATION_PATH="WilsonProject"
    HMC_FILENAME="hmc_ref"
    INPUTFILE_NAME="hmc.input"
    JOBSCRIPT_PREFIX="job.hmc.cl2qcd."
    OUTPUTFILE_NAME="hmc_output"
fi

if [ $STAGGERED = "TRUE" ]; then
    SIMULATION_PATH="StaggeredNf3Test"
    HMC_FILENAME="rhmc_ref"
    INPUTFILE_NAME="rhmc.input"
    JOBSCRIPT_PREFIX="job.rhmc.cl2qcd."
    OUTPUTFILE_NAME="rhmc_output"
    RATIONAL_APPROXIMATIONS_PATH="$HOME_DIR/$SIMULATION_PATH/Rational_Approximations"
    APPROX_HEATBATH_NAME="Approx_Heatbath"
    APPROX_MD_NAME="Approx_MD"
    APPROX_METROPOLIS_NAME="Approx_Metropolis"
fi

HMC_GLOBALPATH="${HOME}/$HMC_BUILD_PATH/$HMC_FILENAME"
THERMALIZED_CONFIGURATIONS_PATH="$HOME_DIR/$SIMULATION_PATH/Thermalized_Configurations"