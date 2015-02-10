# Collection of function needed in the job handler script.

# Load auxiliary bash files that will be used.
source $HOME/Script/JobScriptAutomation/AuxiliaryFunctionsForLoewe.sh || exit -2
source $HOME/Script/JobScriptAutomation/AuxiliaryFunctionsForJuqueen.sh || exit -2
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
    local OLD_IFS=$IFS      # save the field separator           
    local IFS=$'\n'     # new field separator, the end of line           
    for LINE in $(cat $BETASFILE); do          
	if [[ $LINE =~ ^[[:blank:]]*# ]]; then
	    continue
	fi
	LINE=`echo $LINE | awk '{split($0, res, "#"); print res[1]}'`
	if [[ $(echo $LINE | grep -o "resumefrom=[[:digit:]]\+") != "" ]]; then
	    CONTINUE_RESUMETRAJ_TEMP+=( $(echo $LINE | grep -o "resumefrom=[[:digit:]]\+") )
	else
	    CONTINUE_RESUMETRAJ_TEMP+=( "notFound" )
	fi
	LINE=$( echo $LINE | sed 's/resumefrom=[[:digit:]]\+//g' )
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
	if [ "$(awk '{split($0, res, "\#"); print res[1]}' $BETASFILE |\
                sed -e 's/resumefrom=[[:digit:]]\+//g' -e '/^$/d' |\
                awk '{array[$1,$2]++}END{for(ind in array){if(array[ind]>1){print -1; exit}}}')" == -1 ]; then
	    printf "\n\e[0;31m Same seed provided multiple times for same beta!! Aborting...\n\n\e[0m"
            exit -1
        fi

	#NOTE: If one uses the option --useMultipleChains and forgets the seeds column and the second integrator steps column
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
		printf "\n\e[0;31m Invalid integrator step entry in betas file (only one or two digits admitted)! Aborting...\n\n\e[0m"
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

    for INDEX in "${!CONTINUE_RESUMETRAJ_TEMP[@]}"; do
	local TEMP_STR=${CONTINUE_RESUMETRAJ_TEMP[$INDEX]}
	if [[ $TEMP_STR == "notFound" ]]; then
	    continue
	fi
	TEMP_STR=${TEMP_STR#"resumefrom="}
	if [[ ! $TEMP_STR =~ ^[1-9][[:digit:]]*$ ]]; then
	    printf "\n\e[0;31m Invalid resume trajectory number in betasfile! Aborting...\n\n\e[0m"
            exit -1
	fi
	#Build associative array for later use 
	CONTINUE_RESUMETRAJ_ARRAY["${BETAVALUES[$INDEX]}"]="$TEMP_STR"
    done

    printf "\n\e[0;36m===================================================================================\n\e[0m"
    printf "\e[0;34m Read beta values:\n\e[0m"
    
    for BETA in ${BETAVALUES[@]}; do
	printf "  - $BETA"
	if [ "${#INTSTEPS0_ARRAY[@]}" -gt 0 ]; then
	    printf "\t (Integrator steps ${INTSTEPS0_ARRAY[$BETA]}-${INTSTEPS1_ARRAY[$BETA]})\n"
	else
	    printf "\n"
	fi
    done
    
    printf "\e[0;36m===================================================================================\n\e[0m"

    if [ "$CLUSTER_NAME" = "LOEWE" ]; then
	if [ $(echo "${#BETAVALUES[@]}" | awk '{print $1 % '"$GPU_PER_NODE"'}') -ne 0 ]; then
	    printf "\n\e[0;33m \e[1m\e[4mWARNING\e[24m:\e[0;33m Number of beta values provided not multiple of $GPU_PER_NODE. WASTING computing time...\n\n\e[0m"
	fi
    fi

    if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then exit; fi
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
	printf "\e[0;31mOption --showjobs not yet implemented on the LOEWE! Aborting...\e[0m"; exit -1
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
