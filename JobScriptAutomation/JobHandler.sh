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
source $HOME/Script/JobScriptAutomation/AcceptanceRateReport.sh || exit -2
source $HOME/Script/JobScriptAutomation/ListJobsStatus.sh || exit -2
source $HOME/Script/JobScriptAutomation/BuildRegexPath.sh || exit -2
source $HOME/Script/JobScriptAutomation/EmptyBetaDirectories.sh || exit -2
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

BETA_PREFIX="b"
BETASFILE="betas"
KAPPA="1000"
WALLTIME="7-00:00:00"
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
MEASURE_PBP="1"
INTERVAL="1000"
SUBMIT="FALSE"
SUBMITONLY="FALSE"
CONTINUE="FALSE"
CONTINUE_NUMBER="0"
LISTSTATUS="FALSE"
LISTSTATUSALL="FALSE"
CLUSTER_NAME="LOEWE"
LOEWE_PARTITION="parallel"
LOEWE_CONSTRAINT="gpu"
LOEWE_NODE="unset"
JOBS_STATUS_PREFIX="jobs_status_"
SHOWJOBS="FALSE"
ACCRATE_REPORT="FALSE"
ACCRATE_REPORT_GLOBAL="FALSE"
EMPTY_BETA_DIRS="FALSE"

#-----------------------------------------------------------------------------------------------------------------#
# Set default values for the non-modifyable variables ---> Modify this file to change them!
source $HOME/Script/JobScriptAutomation/UserSpecificVariables_$(whoami).sh || exit -2
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Extract options and their arguments into variables, saving a copy of the specified options in an array for later use.
source $HOME/Script/JobScriptAutomation/CommandLineParser.sh || exit -2
# NOTE: The CLUSTER_NAME variable has not been so far put in the parser since
#       it can be either LOEWE or JUQUEEN. It is set using whoami. Change this in future if needed!
if [[ $(whoami) =~ ^hkf[[:digit:]]{3} ]]; then
    CLUSTER_NAME="JUQUEEN"
    WALLTIME="00:30:00"
fi

SPECIFIED_COMMAND_LINE_OPTIONS=( $@ )

ParseCommandLineOption $@

#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Check if the necessary scripts exist.
if [ ! -f $PRODUCEJOBSCRIPTSH ] || [ ! -f $PRODUCEINPUTFILESH ] || [ ! -f $HMC_GLOBALPATH ]; then
	printf "\n\e[0;31m One or more of the following files are missing:\n\e[0m"
	printf "\n\e[0;31m   - $PRODUCEJOBSCRIPTSH\e[0m"
	printf "\n\e[0;31m   - $PRODUCEINPUTFILESH\e[0m"
	printf "\n\e[0;31m   - $HMC_GLOBALPATH\e[0m"
	printf "\n\n\e[0;31m Aborting...\n\n\e[0m"
	exit -1
fi
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Perform all the checks on the path, reading out some variables 
if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
    CheckSingleOccurrenceInPath "homeb" "hkf8[^[:digit:]]" "hkf8[[:digit:]]{2}" "mui" "k[[:digit:]]\+" "nt[[:digit:]]\+" "ns[[:digit:]]\+"
else
    CheckSingleOccurrenceInPath "home" "hfftheo" "$(whoami)" "mui" "k[[:digit:]]\+" "nt[[:digit:]]\+" "ns[[:digit:]]\+"
fi
ReadParametersFromPath $(pwd)
HOME_DIR_WITH_BETAFOLDERS="$HOME_DIR/$SIMULATION_PATH$PARAMETERS_PATH"

if [ "$HOME_DIR_WITH_BETAFOLDERS" != "$(pwd)" ]; then
        printf "\n\e[0;31m HOME_DIR_WITH_BETAFOLDERS=$HOME_DIR_WITH_BETAFOLDERS\n"
	printf "\e[0;31m Constructed path to directory containing beta folders does not match the actual position! Aborting...\n\n\e[0m"
	exit -1
fi
WORK_DIR_WITH_BETAFOLDERS="$WORK_DIR/$SIMULATION_PATH$PARAMETERS_PATH"
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Check for correct specification of parallelization parameters, only on JUQUEEN
#if [ $LISTSTATUS = "FALSE" ] && [ $SHOWJOBS = "FALSE" ] && [ $ACCRATE_REPORT = "FALSE" ]; then
if [ ${#MUTUALLYEXCLUSIVEOPTS_PASSED[@]} = 0 ] || [ $CONTINUE = "TRUE" ] || [ $SUBMIT = "TRUE" ] || [ $SUBMITONLY = "TRUE" ]; then	

    if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then CheckParallelizationTmlqcdForJuqueen; fi

fi
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Read beta values from BETASFILE and write them into BETAVALUES array
if [ ${#MUTUALLYEXCLUSIVEOPTS_PASSED[@]} = 0 ] || [ $SUBMIT = "TRUE" ] || [ $SUBMITONLY = "TRUE" ] || [ $CONTINUE = "TRUE" ]; then

    declare -A INTSTEPS0_ARRAY
    declare -A INTSTEPS1_ARRAY
    declare -A CONTINUE_RESUMETRAJ_ARRAY
    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES

fi
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Produce input file and jobscript for each beta and place it in the corresponding directory
SUBMIT_BETA_ARRAY=()
PROBLEM_BETA_ARRAY=() #Arrays that will contain the beta values that actually will be processed

if [ ${#MUTUALLYEXCLUSIVEOPTS_PASSED[@]} = 0 ] || [ $SUBMIT = "TRUE" ]; then  
	
    ProduceInputFileAndJobScriptForEachBeta

elif [ $SUBMITONLY = "TRUE" ]; then  
    
    ProcessBetaValuesForSubmitOnly

elif [ $CONTINUE = "TRUE" ]; then 

    ProcessBetaValuesForContinue #TODO: Declare all possible local variable in this function as local! Use also only capital letters!

fi
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
if [ $LISTSTATUS = "TRUE" ] || [ $LISTSTATUSALL = "TRUE" ]; then

    ListJobStatus_Main 
    #TODO: On Juqueen, declare all possible local variable in this function as local! Use PARAMETERS_STRING/PATH where needed!
    #TODO: Test on LOEWE! 

fi
#------------------------------------------------------------------------------------------------------------------------------#


#------------------------------------------------------------------------------------------------------------------------------#
# Submitting jobs
if [ $SUBMIT = "TRUE" ] || [ $SUBMITONLY = "TRUE" ] || [ $CONTINUE = "TRUE" ] || [[ $CONTINUE =~ [[:digit:]]+ ]]; then #TODO: Check if this condition can be left out

    SubmitJobsForValidBetaValues #TODO: Declare all possible local variable in this function as local!

fi
#------------------------------------------------------------------------------------------------------------------------------#

#------------------------------------------------------------------------------------------------------------------------------#
# Showing queued jobs
if [ $SHOWJOBS = "TRUE" ]; then

	ShowQueuedJobsLocal
fi
#------------------------------------------------------------------------------------------------------------------------------#


#------------------------------------------------------------------------------------------------------------------------------#
# Report on eventual problems
PrintReportForProblematicBeta
#------------------------------------------------------------------------------------------------------------------------------#

#------------------------------------------------------------------------------------------------------------------------------#
# Print acceptance rate report
if [ $ACCRATE_REPORT = "TRUE" ]; then

	AcceptanceRateReport
fi
#------------------------------------------------------------------------------------------------------------------------------#

#------------------------------------------------------------------------------------------------------------------------------#
#Empty beta directories corresponding to the beta values specified in the betas file
if [ $EMPTY_BETA_DIRS == "TRUE" ]; then

	BETASFILE="emptybetas"
	ReadBetaValuesFromFile
	EmptyBetaDirectories
fi
#------------------------------------------------------------------------------------------------------------------------------#

printf "\e[0;32m \n ...done!\n\n\e[0m"

exit 0
