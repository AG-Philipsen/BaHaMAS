#!/bin/bash

#Some scripts could be called via . (source) builtin, see e.g.
#https://developer.apple.com/library/mac/documentation/OpenSource/Conceptual/ShellScripting/SubroutinesandScoping/SubroutinesandScoping.html
#Important: Unlike executing a script as a normal shell command, executing a script with the source builtin results in the second script executing within the same 
#overall context as the first script. Any variables that are modified by the second script will be seen by the calling script.

#COMMENT about -s | --submit and --submitonly: ...############### INSERT COMMENT HERE ###################

# NOTE: Usually in this script, if an error occurs, a short description is given to the user.
#       Nevertheless, it is annoying and not really necessary to check every single operation.
#       As compromise, we chose the return code -2 (=> 254) to be returned for standard operations
#       like source, mkdir, cd, ecc.

#-----------------------------------------------------------------------------------------------------------------#
# Load auxiliary bash files that will be used.
source $HOME/Script/PathManagement.sh || exit -2
source $HOME/Script/JobScriptAutomation/AuxiliaryFunctions.sh || exit -2
source $HOME/Script/JobScriptAutomation/AcceptanceRateReport.sh || exit -2
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
MEASURE_PBP="TRUE"
INTERVAL="1000"
USE_MULTIPLE_CHAINS="FALSE"
SUBMIT="FALSE"
SUBMITONLY="FALSE"
THERMALIZE="FALSE"
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
if [ ! -f $HMC_GLOBALPATH ]; then
    printf "\n\e[0;31m The following file has not been found:\n\e[0m"
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
    CheckSingleOccurrenceInPath $(echo $HOME_DIR | sed 's/\// /g') "$CHEMPOT_PREFIX" "${KAPPA_PREFIX}[[:digit:]]\+" "${NTIME_PREFIX}[[:digit:]]\+" "${NSPACE_PREFIX}[[:digit:]]\+"
fi

ReadParametersFromPath $(pwd)

HOME_DIR_WITH_BETAFOLDERS="$HOME_DIR/$SIMULATION_PATH$PARAMETERS_PATH"
WORK_DIR_WITH_BETAFOLDERS="$WORK_DIR/$SIMULATION_PATH$PARAMETERS_PATH"

if [ "$HOME_DIR_WITH_BETAFOLDERS" != "$(pwd)" ]; then
        printf "\n\e[0;31m HOME_DIR_WITH_BETAFOLDERS=$HOME_DIR_WITH_BETAFOLDERS\n"
	printf "\e[0;31m Constructed path to directory containing beta folders does not match the actual position! Aborting...\n\n\e[0m"
	exit -1
fi
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Treat each mutually exclusive option separately, even if some steps are in common. This improves readability!
# It is also evident what the script does in the various options!

SUBMIT_BETA_ARRAY=()
PROBLEM_BETA_ARRAY=() #Arrays that will contain the beta values that actually will be processed
declare -A INTSTEPS0_ARRAY
declare -A INTSTEPS1_ARRAY
declare -A CONTINUE_RESUMETRAJ_ARRAY 
declare -A MASS_PRECONDITIONING_ARRAY 
declare -A STARTCONFIGURATION_GLOBALPATH #NOTE: Before bash 4.2 associative array are LOCAL by default (from bash 4.2 one can do "declare -g ARRAY" to make it global).
                                         #      This is the reason why they are declared here and not in ReadBetaValuesFromFile where it would be natural!!

if [ ${#MUTUALLYEXCLUSIVEOPTS_PASSED[@]} = 0 ]; then

    if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then CheckParallelizationTmlqcdForJuqueen; fi
    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES
    ProduceInputFileAndJobScriptForEachBeta

elif [ $SUBMITONLY = "TRUE" ]; then

    if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then CheckParallelizationTmlqcdForJuqueen; fi
    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES
    ProcessBetaValuesForSubmitOnly
    SubmitJobsForValidBetaValues #TODO: Declare all possible local variable in this function as local!

elif [ $SUBMIT = "TRUE" ]; then

    if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then CheckParallelizationTmlqcdForJuqueen; fi
    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES
    ProduceInputFileAndJobScriptForEachBeta
    SubmitJobsForValidBetaValues #TODO: Declare all possible local variable in this function as local!

elif [ $THERMALIZE = "TRUE" ]; then

    if [ $USE_MULTIPLE_CHAINS = "FALSE" ]; then
	printf "\n\e[0;31mOption -t | --thermalize implemented ONLY combined with -u | --useMultipleChains option! Aborting...\n\n\e[0m"; exit -1
    fi
    if [ $MEASURE_PBP = "TRUE" ]; then
	printf "\n\e[1;33;4mMeasurement of PBP switched off during thermalization!!\n\e[0m"
	MEASURE_PBP="FALSE"
    fi
    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES
    ProduceInputFileAndJobScriptForEachBeta
    SubmitJobsForValidBetaValues #TODO: Declare all possible local variable in this function as local!

elif [ $CONTINUE = "TRUE" ]; then

    if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then CheckParallelizationTmlqcdForJuqueen; fi
    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES
    ProcessBetaValuesForContinue #TODO: Declare all possible local variable in this function as local! Use also only capital letters!
    SubmitJobsForValidBetaValues #TODO: Declare all possible local variable in this function as local!

elif [ $LISTSTATUS = "TRUE" ] || [ $LISTSTATUSALL = "TRUE" ]; then

    ListJobStatus   #TODO: On Juqueen, declare all possible local variable in this function as local! Use PARAMETERS_STRING/PATH where needed!

elif [ $SHOWJOBS = "TRUE" ]; then

    ShowQueuedJobsLocal

elif [ $ACCRATE_REPORT = "TRUE" ]; then

    AcceptanceRateReport

elif [ $EMPTY_BETA_DIRS == "TRUE" ]; then
    
    BETASFILE="emptybetas"
    ReadBetaValuesFromFile
    EmptyBetaDirectories
    
fi


#------------------------------------------------------------------------------------------------------------------------------#
# Report on eventual problems
PrintReportForProblematicBeta
#------------------------------------------------------------------------------------------------------------------------------#

printf "\e[0;32m \n ...done!\n\n\e[0m"

exit 0

