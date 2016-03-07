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
source $HOME/Script/JobScriptAutomation/ProjectStatisticsDatabase.sh || exit -2
#-----------------------------------------------------------------------------------------------------------------#

#-----------------------------------------------------------------------------------------------------------------#
# Global variables declared in other scripts
#   STAGGERED="TRUE" or WILSON="TRUE"
#   NFLAVOUR_PREFIX="Nf"
#   CHEMPOT_PREFIX="mui"
#   NTIME_PREFIX="nt"
#   NSPACE_PREFIX="ns"
#   MASS_PREFIX="k" or MASS_PREFIX="mass"
#   NFLAVOUR_POSITION=0
#   CHEMPOT_POSITION=1
#   MASS_POSITION=2
#   NTIME_POSITION=3
#   NSPACE_POSITION=4
#   NFLAVOUR
#   CHEMPOT
#   MASS
#   NSPACE
#   NTIME
#   PARAMETERS_PATH    <---This is the string in the path with the 4 parameters with slash in front, e.g. /Nf2/muiPiT/k1550/nt6/ns12   or   /Nf2/mui0/mass0250/nt4/ns8
#   PARAMETERS_STRING  <---This is the string in the path with the 4 parameters with underscores, e.g. Nf2_muiPiT_k1550_nt6_ns12   or   Nf2_mui0_mass0250_nt4_ns8

#-----------------------------------------------------------------------------------------------------------------#
# Set default values for the command line parameters

BETASFILE="betas"
BETA_POSTFIX="_continueWithNewChain" #Here we set the BETA_POSTFIX supposing it is not a thermalization. If indeed it is, the postfix will be overwritten in the thermalize case in the main!
WALLTIME="7-00:00:00"
BGSIZE="32"
MEASUREMENTS="20000"
NRXPROCS="4"
NRYPROCS="2"
NRZPROCS="2"
OMPNUMTHREADS="64"
NSAVE="100"
NSAVEPOINT="20"
INTSTEPS0="7"
INTSTEPS1="5"
INTSTEPS2="5"
CGBS="50"
MEASURE_PBP="TRUE"
INTERVAL="1000"
USE_MULTIPLE_CHAINS="TRUE"
SUBMIT="FALSE"
SUBMITONLY="FALSE"
THERMALIZE="FALSE"
CONTINUE="FALSE"
CONTINUE_NUMBER="0"
CONTINUE_THERMALIZATION="FALSE"
LISTSTATUS="FALSE"
LISTSTATUS_MEASURE_TIME="FALSE"
LISTSTATUS_SHOW_ONLY_QUEUED="FALSE"
LISTSTATUSALL="FALSE"
CLUSTER_NAME="LOEWE"
LOEWE_PARTITION="gpu"
LOEWE_NODE="unset"
JOBS_STATUS_PREFIX="jobs_status_"
SHOWJOBS="FALSE"
ACCRATE_REPORT="FALSE"
ACCRATE_REPORT_GLOBAL="FALSE"
EMPTY_BETA_DIRS="FALSE"
CLEAN_OUTPUT_FILES="FALSE"
SECONDARY_OPTION_ALL="FALSE"
COMPLETE_BETAS_FILE="FALSE"
UNCOMMENT_BETAS="FALSE"
COMMENT_BETAS="FALSE"
INVERT_CONFIGURATIONS="FALSE"
CALL_DATABASE="FALSE"
NUMBER_OF_CHAINS_TO_BE_IN_THE_BETAS_FILE="4"
if [ $STAGGERED = "TRUE" ]; then
    USE_RATIONAL_APPROXIMATION_FILE="TRUE"
fi

#Variables for Liststatus colors and acceptances thresholds (here since they are used also by the database)
DEFAULT_LISTSTATUS_COLOR="\e[0;36m"
SUSPICIOUS_BETA_LISTSTATUS_COLOR="\e[0;33m"
WRONG_BETA_LISTSTATUS_COLOR="\e[0;91m"
TOO_LOW_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;9m"
LOW_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;208m"
OPTIMAL_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;10m"
HIGH_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;11m"
TOO_HIGH_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;202m"
RUNNING_LISTSTATUS_COLOR="\e[0;32m"
PENDING_LISTSTATUS_COLOR="\e[0;33m"
CLEANING_LISTSTATUS_COLOR="\e[0;31m"
STUCK_SIMULATION_LISTSTATUS_COLOR="\e[0;91m"
FINE_SIMULATION_LISTSTATUS_COLOR="\e[0;32m"
#-----------------
TOO_LOW_ACCEPTANCE_THRESHOLD=68
LOW_ACCEPTANCE_THRESHOLD=70
HIGH_ACCEPTANCE_THRESHOLD=78
TOO_HIGH_ACCEPTANCE_THRESHOLD=90

#####################################CREATE OPTIONS FOR COMMAND-LINE-PARSER######################################
#Inverter Options
CORRELATOR_DIRECTION="0" 
NUMBER_SOURCES_FOR_CORRELATORS="8"


#Important arrays for uncomment functionality. PUT THEM ELSEWHERE?
UNCOMMENT_BETAS_SEED_ARRAY=()
UNCOMMENT_BETAS_ARRAY=()

#Array for the options string 
DATABASE_OPTIONS=()

#-----------------------------------------------------------------------------------------------------------------#
# Set default values for the non-modifyable variables ---> Modify this file to change them!
source $HOME/Script/JobScriptAutomation/UserSpecificVariables.sh || exit -2
#-----------------------------------------------------------------------------------------------------------------#


#-----------------------------------------------------------------------------------------------------------------#
# Extract options and their arguments into variables, saving a copy of the specified options in an array for later use.
source $HOME/Script/JobScriptAutomation/CommandLineParser.sh || exit -2
# NOTE: The CLUSTER_NAME variable has not been so far put in the parser since
#       it can be either LOEWE or LCSC or JUQUEEN. It is set using whoami/hostname. Change this in future if needed!
if [[ $(whoami) =~ ^hkf[[:digit:]]{3} ]]; then
    CLUSTER_NAME="JUQUEEN"
    WALLTIME="00:30:00"
elif [ "$(hostname)" = "lxlcsc0001" ]; then
    CLUSTER_NAME="LCSC"
elif [ "$(hostname)" = "lqcd-login" ]; then
    CLUSTER_NAME="LCSC_OLD" #Temporary, until all nodes will be moved to gsi
fi

SPECIFIED_COMMAND_LINE_OPTIONS=( $(SplitCombinedShortOptionsInSingloOptions $@) )
#If the help is asked, it doesn't matter which other options are given to the script
if ElementInArray "-h" ${SPECIFIED_COMMAND_LINE_OPTIONS[@]} || ElementInArray "--help" ${SPECIFIED_COMMAND_LINE_OPTIONS[@]}; then
    SPECIFIED_COMMAND_LINE_OPTIONS=( "--help" )
elif ElementInArray "--helpDatabase" ${SPECIFIED_COMMAND_LINE_OPTIONS[@]}; then
	SPECIFIED_COMMAND_LINE_OPTIONS=( "-d" "-h" )
fi

ParseCommandLineOption "${SPECIFIED_COMMAND_LINE_OPTIONS[@]}"
CheckWilsonStaggeredVariables

if [ "$CALL_DATABASE" = "TRUE" ]; then
	projectStatisticsDatabase ${DATABASE_OPTIONS[@]}	
	exit
fi

ReadParametersFromPath $(pwd)
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
    CheckSingleOccurrenceInPath "homeb" "hkf8/" "hkf8[[:digit:]]\+" "${NFLAVOUR_PREFIX}${NFLAVOUR_REGEX}" "${CHEMPOT_PREFIX}${CHEMPOT_REGEX}" "${MASS_PREFIX}${MASS_REGEX}" "${NTIME_PREFIX}${NTIME_REGEX}" "${NSPACE_PREFIX}${NSPACE_REGEX}"
else
    CheckSingleOccurrenceInPath $(echo $HOME_DIR | sed 's/\// /g') "${NFLAVOUR_PREFIX}${NFLAVOUR_REGEX}" "${CHEMPOT_PREFIX}${CHEMPOT_REGEX}" "${MASS_PREFIX}${MASS_REGEX}" "${NTIME_PREFIX}${NTIME_REGEX}" "${NSPACE_PREFIX}${NSPACE_REGEX}"
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

elif [ $THERMALIZE = "TRUE" ] || [ $CONTINUE_THERMALIZATION = "TRUE" ]; then

    if [ $USE_MULTIPLE_CHAINS = "FALSE" ]; then
        [ $THERMALIZE = "TRUE" ] && printf "\n\e[0;31m Option -t | --thermalize implemented ONLY combined not with --doNotUseMultipleChains option! Aborting...\n\n\e[0m"
	    [ $CONTINUE_THERMALIZATION = "TRUE" ] && printf "\n\e[0;31m Option -C | --continueThermalization implemented ONLY combined not with --doNotUseMultipleChains option! Aborting...\n\n\e[0m"
        exit -1
    fi
    #Here we fix the beta postfix just looking for thermalized conf from hot at the actual parameters (no matter at which beta);
    #if at least one configuration thermalized from hot is present, it means the thermalization has to be done from conf (the
    #correct beta to be used is selected then later in the script ---> see where the array STARTCONFIGURATION_GLOBALPATH is filled
    #
    # TODO: If a thermalization from hot is finished but one other crashed and one wishes to resume it, the postfix should be
    #       from Hot but it is from conf since in $THERMALIZED_CONFIGURATIONS_PATH a conf from hot is found. Think about how to fix this.
    if [ $(ls $THERMALIZED_CONFIGURATIONS_PATH | grep "conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA_REGEX}_fromHot[[:digit:]]\+.*" | wc -l) -eq 0 ]; then
	    BETA_POSTFIX="_thermalizeFromHot"
    else
	    BETA_POSTFIX="_thermalizeFromConf"
    fi	
    if [ $MEASURE_PBP = "TRUE" ]; then
	    printf "\n \e[1;33;4mMeasurement of PBP switched off during thermalization!!\n\e[0m"
	    MEASURE_PBP="FALSE"
    fi
    ReadBetaValuesFromFile  # Here we declare and fill the array BETAVALUES
    if [ $THERMALIZE = "TRUE" ]; then
        ProduceInputFileAndJobScriptForEachBeta
    elif [ $CONTINUE_THERMALIZATION = "TRUE" ]; then
        ProcessBetaValuesForContinue
    fi
    
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

elif [ $CLEAN_OUTPUT_FILES = "TRUE" ]; then
    
    if [ $SECONDARY_OPTION_ALL = "TRUE" ]; then
        BETAVALUES=( $( ls $WORK_DIR_WITH_BETAFOLDERS | grep "^${BETA_PREFIX}${BETA_REGEX}" | awk '{print substr($1,2)}') )
    else
        ReadBetaValuesFromFile
    fi
    CleanOutputFiles

elif [ $EMPTY_BETA_DIRS = "TRUE" ]; then
    
    BETASFILE="emptybetas"
    ReadBetaValuesFromFile
    EmptyBetaDirectories
    
elif [ $COMPLETE_BETAS_FILE = "TRUE" ]; then

    CompleteBetasFile
    
elif [ $UNCOMMENT_BETAS = "TRUE" ] || [ $COMMENT_BETAS = "TRUE" ]; then

	UncommentEntriesInBetasFile

elif [ $INVERT_CONFIGURATIONS = "TRUE" ]; then

    ReadBetaValuesFromFile
    ProcessBetaValuesForInversion 
    #SubmitJobsForValidBetaValues
fi



#------------------------------------------------------------------------------------------------------------------------------#
# Report on eventual problems
PrintReportForProblematicBeta
#------------------------------------------------------------------------------------------------------------------------------#

printf "\e[0;32m \n ...done!\n\n\e[0m"

exit 0

