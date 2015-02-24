# Paths on LOEWE using CL2QCD
USER_MAIL="sciarra@th.physik.uni-frankfurt.de"
HMC_BUILD_PATH="clhmc/build/RefExec"
SIMULATION_PATH="WilsonProject"
HOME_DIR="/data01/hfftheo/sciarra" 
WORK_DIR="/scratch/hfftheo/sciarra" 
HMC_FILENAME="hmc_ref"
HMC_GLOBALPATH="${HOME}/$HMC_BUILD_PATH/$HMC_FILENAME"
INPUTFILE_NAME="hmc.input"
JOBSCRIPT_PREFIX="job.hmc.cl2qcd.loewe"
OUTPUTFILE_NAME="hmc_output"
THERMALIZED_CONFIGURATIONS_PATH="$HOME_DIR/$SIMULATION_PATH/Thermalized_Configurations"
GPU_PER_NODE=4
JOBSCRIPT_LOCALFOLDER="JobScripts"