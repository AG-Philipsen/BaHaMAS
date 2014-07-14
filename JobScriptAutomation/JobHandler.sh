#!/bin/bash

#Some more or less important comments:
#The scripts ProduceJobScript.sh and ProduceInputFile.sh are called via . (source) builtin, see e.g.
#https://developer.apple.com/library/mac/documentation/OpenSource/Conceptual/ShellScripting/SubroutinesandScoping/SubroutinesandScoping.html
#Important: Unlike executing a script as a normal shell command, executing a script with the source builtin results in the second script executing within the same 
#overall context as the first script. Any variables that are modified by the second script will be seen by the calling script.

#COMMENT about --submit and --submitonly: ...############### INSERT COMMENT HERE ###################

# NOTE: Usually in this script, if an error occurs, a short description is given to the user.
#       Nevertheless, it is annoying and not really necessary to check every single operation.
#       As compromise, we chose the return code -2 (=> 254) to be returned for standard operations
#       like source, mkdir, cd, ecc.

#-----------------------------------------------------------------------------------------------------------------#
# Load auxiliary bash files that will be used.
source $HOME/Script/PathManagement.sh || exit -2
source $HOME/Script/JobScriptAutomation/AuxiliaryFunction.sh || exit -2
#-----------------------------------------------------------------------------------------------------------------#

#-----------------------------------------------------------------------------------------------------------------#
# Global variables declared in other scripts
#   CHEMPOT_PREFIX="mui"
#   NTIME_PREFIX="nt"
#   NSPACE_PREFIX="ns"
#   KAPPA_PREFIX="k"
#   CHEMPOT_POSITION=0
#   KAPPA_POSITION=1
#   NTIME_POSITION=2
#   NSPACE_POSITION=3
#   CHEMPOT
#   KAPPA
#   NSPACE
#   NTIME
#   PARAMETERS_PATH    <---This is the string in the path with the 4 parameters with slash in front, e.g. /muiPiT/k1550/nt6/ns12
#   PARAMETERS_STRING  <---This is the string in the path with the 4 parameters with underscores, e.g. muiPiT_k1550_nt6_ns12

#-----------------------------------------------------------------------------------------------------------------#
# Set default values for the command line parameters

JOBSCRIPT_PREFIX="job.submit.script.imagMu"
#CHEMPOT_PREFIX="mui"
#KAPPA_PREFIX="k"
#NTIME_PREFIX="nt"
#NSPACE_PREFIX="ns"
BETA_PREFIX="b"
BETASFILE="betas"
#CHEMPOT="PiT"
KAPPA="1000"
WALLTIME="00:30:00"
BGSIZE="32"
MEASUREMENTS="20000"
NRXPROCS="4"
NRYPROCS="2"
NRZPROCS="2"
OMPNUMTHREADS="64"
NSAVE="50"
INTSTEPS0="7"
INTSTEPS1="5"
INTSTEPS2="5"
SUBMIT="FALSE"
SUBMITONLY="FALSE"
CONTINUE="FALSE"
CONTINUE_NUMBER="0"
LISTSTATUS="FALSE"

#-----------------------------------------------------------------------------------------------------------------#
# Set default values for the non-modifyable variables ---> Modify this file to change them!
source ./UserSpecificVariablesSciarra.sh || exit -2
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Extract options and their arguments into variables.
source ./CommandLineParser.sh || exit -2
ParseCommandLineOption $@
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Check if the necessary scripts exist.
if [ ! -f $PRODUCEJOBSCRIPTSH ] || [ ! -f $PRODUCEINPUTFILESH ] || [ ! -f $HMC_TM_GLOBALPATH ]; then
	printf "\n\e[0;31m One or more of the following scripts are missing:\n\e[0m"
	printf "\n\e[0;31m   - $PRODUCEJOBSCRIPTSH\e[0m"
	printf "\n\e[0;31m   - $PRODUCEINPUTFILESH\e[0m"
	printf "\n\e[0;31m   - $HMC_TM_GLOBALPATH\e[0m"
	printf "\n\n\e[0;31m Aborting...\n\n\e[0m"
	exit -1
fi
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Perform all the checks on the path, reading out some variables 
CheckSingleOccurrenceInPath "homeb" "hkf8[[:digit:]]" "hkf80[[:digit:]]" "mui" "k[[:digit:]]" "nt[[:digit:]]" "ns[[:digit:]]"
ReadParametersFromPath $(pwd)
HOME_DIR_WITH_BETAFOLDERS="$HOME_DIR/$SIMULATION_PATH$PARAMETERS_PATH"
if [ "$HOME_DIR_WITH_BETAFOLDERS" != "$(pwd)" ]; then
	printf "\n\e[0;31m Constructed path to directory containing beta folders does not match the actual position! Aborting...\n\n\e[0m"
	exit -1
fi
WORK_DIR_WITH_BETAFOLDERS="$WORK_DIR/$SIMULATION_PATH$PARAMETERS_PATH"
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Check for correct specification of parallelization parameters
if [ $LISTSTATUS = "FALSE" ]; then

    CheckParallelizationTmlqcdForJuqueen

fi
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Read beta values from BETASFILE and write them into BETAVALUES array
if [ $LISTSTATUS = "FALSE" ]; then

    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES

fi
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Produce input file and jobscript for each beta and place it in the corresponding directory
SUBMIT_BETA_ARRAY=()
PROBLEM_BETA_ARRAY=() #Arrays that will contain the beta values that actually will be processed

if [ $SUBMITONLY = "FALSE" ] && [ $CONTINUE = "FALSE" ] && [ $LISTSTATUS = "FALSE" ]; then  

    ProduceInputFileAndJobScriptForEachBeta #TODO: Declare all possible local variable in this function as local!

elif [ $SUBMITONLY = "TRUE" ] && [ $CONTINUE = "FALSE" ] && [ $LISTSTATUS = "FALSE" ]; then  

    ProcessBetaValuesForSubmitOnly #TODO: Declare all possible local variable in this function as local!

elif [ $CONTINUE = "TRUE" ]; then 

    ProcessBetaValuesForContinue #TODO: Declare all possible local variable in this function as local! Use also only capital letters!

fi


#-----------------------------------------------------------------------------------------------------------------#
if [ $LISTSTATUS = "TRUE" ]; then #TODO: This option should be reconsidered and improved

    ProduceJobStatusFile #TODO: Declare all possible local variable in this function as local! Use PARAMETERS_STRING/PATH where needed!

fi
#------------------------------------------------------------------------------------------------------------------------------#


#------------------------------------------------------------------------------------------------------------------------------#
# Submitting jobs
if [ $SUBMIT = "TRUE" ] || [ $SUBMITONLY = "TRUE" ] || [ $CONTINUE = "TRUE" ] || [[ $CONTINUE =~ [[:digit:]]+ ]]; then #TODO: Check if this condition can be left out

    SubmitJobsForValidBetaValues #TODO: Declare all possible local variable in this function as local!

fi
#------------------------------------------------------------------------------------------------------------------------------#


#------------------------------------------------------------------------------------------------------------------------------#
# Printing report for problem betas
if [ ${#PROBLEM_BETA_ARRAY[@]} -gt "0" ]; then	
printf "\e[0;31m \n For the following beta values something went wrong \n\e[0m"
printf "\e[0;31m and hence these were left out during file creation and/or job submission:\n\e[0m"

	printf "\n\e[0;31m===================================================================================\n\e[0m"
	printf "\e[0;31m problematic beta values:\n"
	for i in ${PROBLEM_BETA_ARRAY[@]}; do
		echo "  - $i"
	done
	printf "\e[0;31m===================================================================================\n\e[0m"
fi
#------------------------------------------------------------------------------------------------------------------------------#

printf "\e[0;34m \n done!\n\e[0m"

exit 0
