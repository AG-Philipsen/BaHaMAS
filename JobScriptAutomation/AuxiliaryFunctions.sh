# Collection of function needed in the job handler script.

# Load auxiliary bash files that will be used.
source $HOME/Script/JobScriptAutomation/AuxiliaryFunctionsForLoewe.sh || exit -2
source $HOME/Script/JobScriptAutomation/AuxiliaryFunctionsForJuqueen.sh || exit -2
source $HOME/Script/JobScriptAutomation/ListJobsStatusForLoewe.sh || exit -2
source $HOME/Script/JobScriptAutomation/ListJobsStatusForJuqueen.sh || exit -2
#------------------------------------------------------------------------------------#

function ReadBetaValuesFromFile(){

    if [ ! -e $BETASFILE ]; then
	printf "\n\e[0;31m  File \"$BETASFILE\" not found in $(pwd). Aborting...\n\n\e[0m"
	exit -1
    fi

    #For syncronization reason the betas file MUST contain the beta value in the first column! Check:
    for ENTRY in $(awk '{split($0, res, "#"); print res[1]}' $BETASFILE |  awk '{print $1}'); do
	if [[ ! "$ENTRY" =~ ^[[:digit:]][.][[:digit:]]{4}$ ]]; then
            printf "\n\e[0;31m The betas file MUST contain the beta value in the first column! Aborting...\n\n\e[0m"
            exit -1
	fi
    done

    BETAVALUES=()
    local SEED_ARRAY_TEMP=()
    local INTSTEPS0_ARRAY_TEMP=()
    local INTSTEPS1_ARRAY_TEMP=()
    local CONTINUE_RESUMETRAJ_TEMP=()
    local MASS_PRECONDITIONING_TEMP=()
    local RESUME_REGEXPR="resumefrom=[[:digit:]]\+"
    local MP_REGEXPR="MP=(.*)"
    local SEARCH_RESULT=""  # Auxiliary variable to help to parse the file
    local OLD_IFS=$IFS      # save the field separator           
    local IFS=$'\n'         # new field separator, the end of line           
    for LINE in $(cat $BETASFILE); do          
       	if [[ $LINE =~ ^[[:blank:]]*# ]]; then
	    continue
	fi
	LINE=`echo $LINE | awk '{split($0, res, "#"); print res[1]}'`
	#Look for "resumefrom=*" check it, save the content and delete it
	SEARCH_RESULT=( $(echo $LINE | grep -o "$RESUME_REGEXPR") )
	case ${#SEARCH_RESULT[@]} in
	    0 ) CONTINUE_RESUMETRAJ_TEMP+=( "notFound" );;
	    1 ) CONTINUE_RESUMETRAJ_TEMP+=( ${SEARCH_RESULT[0]}); LINE=$( echo $LINE | sed 's/'$RESUME_REGEXPR'//g' );;
	    * ) printf "\n\e[0;31m String \"resumefrom=*\" specified multiple times per line in betasfile! Aborting...\n\n\e[0m"; exit -1;;
	esac
	#Look for "MP=(*,*)" check it, save the content and delete it
	SEARCH_RESULT=( $(echo $LINE | grep -o "$MP_REGEXPR") )
	case ${#SEARCH_RESULT[@]} in
	    0 ) MASS_PRECONDITIONING_TEMP+=( "notFound" );;
	    1 ) MASS_PRECONDITIONING_TEMP+=( ${SEARCH_RESULT[0]}); LINE=$( echo $LINE | sed 's/'$MP_REGEXPR'//g' );;
	    * ) printf "\n\e[0;31m String \"MP=(*,*)\" specified multiple times per line in betasfile! Aborting...\n\n\e[0m"; exit -1;;
	esac
	#Read the rest
	BETAVALUES+=( $(echo $LINE | awk '{print $1}') )
	if [ $USE_MULTIPLE_CHAINS == "FALSE" ]; then
	    INTSTEPS0_ARRAY_TEMP+=( $(echo $LINE | awk '{print $2}') )
	    INTSTEPS1_ARRAY_TEMP+=( $(echo $LINE | awk '{print $3}') )
	else
	    SEED_ARRAY_TEMP+=( $(echo $LINE | awk '{print $2}') )
	    INTSTEPS0_ARRAY_TEMP+=( $(echo $LINE | awk '{print $3}') )
	    INTSTEPS1_ARRAY_TEMP+=( $(echo $LINE | awk '{print $4}') )
	fi
    done          
    IFS=$OLD_IFS     # restore default field separator 

    #Check whether the entries in the file have the right format, otherwise abort
    if [ ${#BETAVALUES[@]} -eq 0 ]; then
	printf "\n\e[0;31m  No beta values in betas file. Aborting...\n\n\e[0m"
	exit -1
    fi

    #NOTE: The following check on beta is redundant ---> TODO: Think deeply about and in case remove it!
    for BETA in ${BETAVALUES[@]}; do
	if [[ ! $BETA =~ ^[[:digit:]].[[:digit:]]{4}$ ]]; then
	    printf "\n\e[0;31m Invalid beta entry in betas file! Aborting...\n\n\e[0m"
	    exit -1
	fi
    done

    if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then
	if [ ${#SEED_ARRAY_TEMP[@]} -ne ${#BETAVALUES[@]} ]; then
	    printf "\n\e[0;31m  Number of provided seeds differ from the number of provided beta values in betas file. Aborting...\n\n\e[0m"
	    exit -1
	fi
	
	for SEED in ${SEED_ARRAY_TEMP[@]}; do
	    if [[ ! $SEED =~ ^[[:digit:]]{4}$ ]]; then
		printf "\n\e[0;31m Invalid seed entry in betas file! Aborting...\n\n\e[0m"
		exit -1
	    fi
	done
	
	#Check whether same seed is provided multiple times for same beta --> do it with an associative array in awk after having removed "resumefrom=", EMPTYLINES and comments
	if [ "$(awk '{split($0, res, "'#'"); print res[1]}' $BETASFILE |\
                sed -e 's/'$RESUME_REGEXPR'//g' -e 's/'$MP_REGEXPR'//g' -e '/^$/d' |\
                awk '{array[$1,$2]++}END{for(ind in array){if(array[ind]>1){print -1; exit}}}')" == -1 ]; then
	    printf "\n\e[0;31m Same seed provided multiple times for same beta!! Aborting...\n\n\e[0m"
            exit -1
        fi

	#NOTE: If one uses the option -u | --useMultipleChains and forgets the seeds column and the second integrator steps column
	#      in the betas file, then the first column of integrator steps is used as seed and the default integrators steps
	#      are used. In the case in which the first integrator steps is a 4-digit number, the script will do its job without
	#      throwing any exception. We didn't cure this case since it is a very remote case................

        #Modify the content of BETAVALUES[@] from x.xxxx to x.xxxx_syyyy in order to use this new label in the associative arrays everyehere!
	for INDEX in "${!BETAVALUES[@]}"; do
	    BETAVALUES[$INDEX]="${BETAVALUES[$INDEX]}_s${SEED_ARRAY_TEMP[$INDEX]}$BETA_POSTFIX"
	done
    fi

    if [ ${#INTSTEPS0_ARRAY_TEMP[@]} -ne 0 ]; then #If the first intsteps array is empty the second CANNOT be not empt (because of how I read them with awk from file)
	for STEPS in ${INTSTEPS0_ARRAY_TEMP[@]} ${INTSTEPS1_ARRAY_TEMP[@]}; do
	    if [[ ! $STEPS =~ ^[[:digit:]]{1,2}$ ]]; then
		printf "\n\e[0;31m Invalid integrator step entry in betas file (only one or two digits admitted)! Aborting...\n\e[0m"
	        if [[ $STEPS =~ ^[[:digit:]]{4}$ ]]; then
		    printf "\e[0;31m   \e[4mHINT\e[0;31m: Maybe your intention was to use the \e[1m-u | --useMultipleChains\e[0;31m option...\n\n\e[0m"
		    exit -1
	    	else
		    printf "\n"
		fi
		exit -1
	    fi
	done
	
	if [ ${#INTSTEPS0_ARRAY_TEMP[@]} -ne ${#BETAVALUES[@]} ] || [ ${#INTSTEPS1_ARRAY_TEMP[@]} -ne ${#BETAVALUES[@]} ]; then
	    printf "\n\e[0;31m Integrators steps not specified for ALL beta in betas file! Aborting...\n\n\e[0m"
            exit -1
	fi

	#Now that all the checks have been done, build associative arrays for later use of integration steps 
	for INDEX in "${!BETAVALUES[@]}"; do
	    INTSTEPS0_ARRAY["${BETAVALUES[$INDEX]}"]="${INTSTEPS0_ARRAY_TEMP[$INDEX]}"
	    INTSTEPS1_ARRAY["${BETAVALUES[$INDEX]}"]="${INTSTEPS1_ARRAY_TEMP[$INDEX]}"
	done	
    else
	#Build associative arrays for later use of integration steps with the same value for all betas
	for INDEX in "${!BETAVALUES[@]}"; do
	    INTSTEPS0_ARRAY["${BETAVALUES[$INDEX]}"]=$INTSTEPS0
	    INTSTEPS1_ARRAY["${BETAVALUES[$INDEX]}"]=$INTSTEPS1
	done		
    fi

    for INDEX in "${!BETAVALUES[@]}"; do
	local TEMP_STR=${CONTINUE_RESUMETRAJ_TEMP[$INDEX]}
	if [[ $TEMP_STR != "notFound" ]]; then
	    TEMP_STR=${TEMP_STR#"resumefrom="}
	    if [[ ! $TEMP_STR =~ ^[1-9][[:digit:]]*$ ]]; then
		printf "\n\e[0;31m Invalid resume trajectory number in betasfile! Aborting...\n\n\e[0m"
		exit -1
	    fi
	    #Build associative array for later use 
	    CONTINUE_RESUMETRAJ_ARRAY["${BETAVALUES[$INDEX]}"]="$TEMP_STR"
	fi
	TEMP_STR=${MASS_PRECONDITIONING_TEMP[$INDEX]}
	if [[ $TEMP_STR != "notFound" ]]; then
	    TEMP_STR=$(echo ${TEMP_STR#"MP=("})
	    TEMP_STR=${TEMP_STR%")"}
	    #Build associative array for later use
	    if [[ ! $TEMP_STR =~ ^[[:digit:]]{1,2},[[:digit:]]{3,4}$ ]]; then
                printf "\n\e[0;31m Invalid Mass Preconditioning parameters in betasfile! The string must match the regular\n"
		printf " expression \e[1m^MP=([[:digit:]]{1,2},[[:digit:]]{3,4})\$\e[0;31m but it doesn't! Aborting...\n\n\e[0m"
                exit -1
            fi
	    MASS_PRECONDITIONING_ARRAY["${BETAVALUES[$INDEX]}"]="$TEMP_STR"
	fi
    done

    printf "\n\e[0;36m============================================================================================================\n\e[0m"
    printf "\e[0;34m Read beta values:\n\e[0m"
    
    for BETA in ${BETAVALUES[@]}; do
	printf "  - $BETA\t [Integrator steps ${INTSTEPS0_ARRAY[$BETA]}-${INTSTEPS1_ARRAY[$BETA]}]"
	if KeyInArray $BETA CONTINUE_RESUMETRAJ_ARRAY; then
	    printf "   [resume from tr. %5d]" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}"
	else
	    printf "                          "
	fi
	if KeyInArray $BETA MASS_PRECONDITIONING_ARRAY; then
	    printf "   MP=(%d-0.%4d)" "${MASS_PRECONDITIONING_ARRAY[$BETA]%,*}" "${MASS_PRECONDITIONING_ARRAY[$BETA]#*,}"
	fi
	printf "\n"
    done
    
    printf "\e[0;36m============================================================================================================\n\e[0m"

    #If we are not in the continue scenario, look for the correct configuration to start from and set the global path
    if [ $CONTINUE = "FALSE" ]; then
	for BETA in "${BETAVALUES[@]}"; do
	    if [ "$BETA_POSTFIX" == "" ]; then
		local FOUND_CONFIGURATIONS=( $(ls $THERMALIZED_CONFIGURATIONS_PATH | grep "conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA}.*") )
		if [ ${#FOUND_CONFIGURATIONS[@]} -eq 0 ]; then
		    STARTCONFIGURATION_GLOBALPATH[$BETA]="notFoundHenceStartFromHot"
		elif [ ${#FOUND_CONFIGURATIONS[@]} -eq 1 ]; then
		    STARTCONFIGURATION_GLOBALPATH[$BETA]="${THERMALIZED_CONFIGURATIONS_PATH}/${FOUND_CONFIGURATIONS[0]}"
		else
		    printf "\n\e[0;31m No valid starting configuration found for beta = ${BETA%%_*} in \"$THERMALIZED_CONFIGURATIONS_PATH\"\n"
		    printf " Zero or more than 1 configurations match the following name: \"conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA%%_*}_fromConf*\"! Aborting...\n\n\e[0m"
		    exit -1
		fi		
	    elif [ $BETA_POSTFIX == "_continueWithNewChain" ]; then
		local FOUND_CONFIGURATIONS=( $(ls $THERMALIZED_CONFIGURATIONS_PATH | grep "conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA%%_*}_fromConf[[:digit:]]\+.*") )
		if [ ${#FOUND_CONFIGURATIONS[@]} -ne 1 ]; then
		    printf "\n\e[0;31m No valid starting configuration found for beta = ${BETA%%_*} in \"$THERMALIZED_CONFIGURATIONS_PATH\"\n"
		    printf " Zero or more than 1 configurations match the following name: \"conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA%%_*}_fromConf*\"! Aborting...\n\n\e[0m"
		    exit -1
		else
		    STARTCONFIGURATION_GLOBALPATH[$BETA]="${THERMALIZED_CONFIGURATIONS_PATH}/${FOUND_CONFIGURATIONS[0]}"
		fi
	    elif [ $BETA_POSTFIX == "_thermalizeFromConf" ]; then
		if [ $(ls $THERMALIZED_CONFIGURATIONS_PATH | grep "conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA%%_*}_fromConf[[:digit:]]\+.*" | wc -l) -ne 0 ]; then
		    printf "\n\e[0;31m It seems that there is already a thermalized configuration for beta = ${BETA%%_*}\n"
		    printf " in \"$THERMALIZED_CONFIGURATIONS_PATH\"! Aborting...\n\n\e[0m"
                    exit -1
		fi
		local FOUND_CONFIGURATIONS=( $(ls $THERMALIZED_CONFIGURATIONS_PATH | grep "conf.${PARAMETERS_STRING}_${BETA_PREFIX}[[:digit:]][.][[:digit:]]\{4\}_fromHot[[:digit:]]\+.*") )
		declare -A FOUND_CONFIGURATIONS_WITH_BETA_AS_KEY
		for CONFNAME in "${FOUND_CONFIGURATIONS[@]}"; do
		    local BETAVALUE_RECOVERED_FROM_NAME=$(echo $CONFNAME | awk '{split($1, res, "_fromHot"); print res[1]}' | sed 's/.*\([[:digit:]][.][[:digit:]]\{4\}\).*/\1/')
		    FOUND_CONFIGURATIONS_WITH_BETA_AS_KEY["$BETAVALUE_RECOVERED_FROM_NAME"]=$CONFNAME
		done
		local CLOSEST_BETA=$(FindValueOfClosestElementInArrayToGivenValue ${BETA%%_*} "${!FOUND_CONFIGURATIONS_WITH_BETA_AS_KEY[@]}")
		STARTCONFIGURATION_GLOBALPATH[$BETA]="${THERMALIZED_CONFIGURATIONS_PATH}/${FOUND_CONFIGURATIONS_WITH_BETA_AS_KEY[$CLOSEST_BETA]}"
	    elif [ $BETA_POSTFIX == "_thermalizeFromHot" ]; then
		STARTCONFIGURATION_GLOBALPATH[$BETA]="notFoundHenceStartFromHot"
	    else
		printf "\n\e[0;31m Something really strange happened! BETA_POSTFIX set to unknown value (${BETA_POSTFIX})! Aborting...\n\n\e[0m"
                exit -1
	    fi
	done
    fi
}


function ProduceInputFileAndJobScriptForEachBeta()
{
    if [ "$CLUSTER_NAME" = "JUQUEEN" ]
    then 
	ProduceInputFileAndJobScriptForEachBeta_Juqueen
    else 
	ProduceInputFileAndJobScriptForEachBeta_Loewe
    fi
}


function ProcessBetaValuesForSubmitOnly()
{
    if [ "$CLUSTER_NAME" = "JUQUEEN" ]
    then
	ProcessBetaValuesForSubmitOnly_Juqueen
    else
	ProcessBetaValuesForSubmitOnly_Loewe
    fi
}


function ProcessBetaValuesForContinue()
{    
    if [ "$CLUSTER_NAME" = "JUQUEEN" ]
    then
	ProcessBetaValuesForContinue_Juqueen	
    else
	ProcessBetaValuesForContinue_Loewe
    fi
}


function ShowQueuedJobsLocal()
{
    if [ "$CLUSTER_NAME" = "JUQUEEN" ]
    then
	ShowQueuedJobsLocal_Juqueen
    else
	printf "\n\e[0;31mOption --showjobs not yet implemented on the LOEWE! Aborting...\n\n\e[0m"; exit -1
    fi
}


function SubmitJobsForValidBetaValues()
{
    if [ "$CLUSTER_NAME" = "JUQUEEN" ]
    then
	SubmitJobsForValidBetaValues_Juqueen
    else
	SubmitJobsForValidBetaValues_Loewe
    fi
}


function PrintReportForProblematicBeta() {

    if [ ${#PROBLEM_BETA_ARRAY[@]} -gt "0" ]; then	
	printf "\n\e[0;31m===================================================================================\n\e[0m"
	printf "\e[0;31m For the following beta values something went wrong and hence\n\e[0m"
	printf "\e[0;31m they were left out during file creation and/or job submission:\n"
	for BETA in ${PROBLEM_BETA_ARRAY[@]}; do
	    printf "  - \e[1m$BETA\e[0;31m\n"
	done
	printf "\e[0;31m===================================================================================\n\e[0m"
    fi
}


function ListJobStatus()
{
    if [ "$CLUSTER_NAME" = "JUQUEEN" ]
    then
	ListJobStatus_Juqueen
    else
	ListJobStatus_Loewe
    fi
}


function CleanOutputFiles()
{
    printf "\n\e[1;36m \e[4mCleaning\e[0m\e[1;36m:\n\n\e[0m"
    for BETA in ${BETAVALUES[@]}; do
        #-------------------------------------------------------------------------#
	local WORK_BETADIRECTORY="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
	local OUTPUTFILE_GLOBALPATH="${WORK_BETADIRECTORY}/$OUTPUTFILE_NAME"
        #-------------------------------------------------------------------------#
	if [ ! -f $OUTPUTFILE_GLOBALPATH ]; then
	    printf "\e[0;31m    File \"$OUTPUTFILE_GLOBALPATH\" not existing! Leaving out beta = ${BETA%_*} .\n\n\e[0m"
            PROBLEM_BETA_ARRAY+=( $BETA )
	    continue
	fi

	if $(sort --numeric-sort --unique --check=silent --key 1,1 ${OUTPUTFILE_GLOBALPATH}); then
	    printf "\e[38;5;13m    The file \"${BETA_PREFIX}${OUTPUTFILE_GLOBALPATH##*/$BETA_PREFIX}\" has not to be cleaned!\n\e[0m"
	else
            #Do a backup of the file
	    local OUTPUTFILE_BACKUP="${OUTPUTFILE_GLOBALPATH}_$(date +'%F_%H%M')"
	    cp $OUTPUTFILE_GLOBALPATH $OUTPUTFILE_BACKUP || exit -2
	    #Check whether there is any trajectory repeated but with different observables
	    #TODO: Adjust the following line for JUQUEEN where there is the time in the output file!
	    local SUSPICIOUS_TRAJECTORY=$(awk '{val=$1; $1=""; array[val]++; if(array[val]>1 && $0 != lineRest[val]){print val; exit}; lineRest[val]=$0}' $OUTPUTFILE_GLOBALPATH)
	    if [ "$SUSPICIOUS_TRAJECTORY" != "" ]; then
		printf "    \e[38;5;202mFound different observables for same trajectory number! First occurence at trajectory $SUSPICIOUS_TRAJECTORY. The file will be cleaned anyway,\n"
		printf "    use the backup file \"$OUTPUTFILE_BACKUP\" in case of need.\n\e[0m"
	    fi
            #Use sort command to clean the file: note that it is safe to give same input
            #and output since the input file is read and THEN overwritten
	    sort --numeric-sort --unique --key 1,1 --output=${OUTPUTFILE_GLOBALPATH} ${OUTPUTFILE_GLOBALPATH}
	    if [ $? -ne 0 ]; then
		printf "\e[0;31m    Problem occurred cleaning file \"$OUTPUTFILE_GLOBALPATH\"! Leaving out beta = ${BETA%_*} .\n\n\e[0m"
		PROBLEM_BETA_ARRAY+=( $BETA )
	    fi
	    printf "\e[0;92m    The file \"${BETA_PREFIX}${OUTPUTFILE_GLOBALPATH##*/$BETA_PREFIX}\" has been successfully cleaned!"
	    printf " [removed $(($(wc -l < $OUTPUTFILE_BACKUP) - $(wc -l < $OUTPUTFILE_GLOBALPATH))) line(s)]!\n\e[0m"
	fi
    done
}
