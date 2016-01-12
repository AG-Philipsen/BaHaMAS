# Collection of function needed in the job handler script.

# Load auxiliary bash files that will be used.
source $HOME/Script/JobScriptAutomation/AuxiliaryFunctionsForLoewe.sh || exit -2
source $HOME/Script/JobScriptAutomation/AuxiliaryFunctionsForJuqueen.sh || exit -2
source $HOME/Script/JobScriptAutomation/ListJobsStatusForLoewe.sh || exit -2
source $HOME/Script/JobScriptAutomation/ListJobsStatusForJuqueen.sh || exit -2
source $HOME/Script/JobScriptAutomation/CleanOutputFiles.sh || exit -2
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
    local RESUME_REGEXPR="resumefrom=\([[:digit:]]\+\|last\)"
    local MP_REGEXPR="MP=(.*)"
    local SEARCH_RESULT=""  # Auxiliary variable to help to parse the file
    local OLD_IFS=$IFS      # save the field separator           
    local IFS=$'\n'         # new field separator, the end of line           
    for LINE in $(cat $BETASFILE); do          
        if [[ $LINE =~ ^[[:blank:]]*# ]] || [[ $LINE =~ ^[[:blank:]]*$ ]]; then
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
            if [[ ! $SEED =~ ^[[:alnum:]]{4}$ ]]; then
            printf "\n\e[0;31m Invalid seed entry in betas file! Aborting...\n\n\e[0m"
            exit -1
            fi
        done
        
        #Check whether same seed is provided multiple times for same beta --> do it with an associative array in awk after having removed "resumefrom=", EMPTYLINES and comments
        if [ "$(awk '{split($0, res, "'#'"); print res[1]}' $BETASFILE |\
                sed -e 's/'$RESUME_REGEXPR'//g' -e 's/'$MP_REGEXPR'//g' -e '/^[[:space:]]*$/d' |\
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
            if [[ ! $TEMP_STR =~ ^[1-9][[:digit:]]*$ ]] && [ $TEMP_STR != "last" ]; then
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
            printf "   [resume from tr. %+6s]" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}"
        else
            printf "                          "
        fi
        if KeyInArray $BETA MASS_PRECONDITIONING_ARRAY; then
            printf "   MP=(%d-0.%4d)" "${MASS_PRECONDITIONING_ARRAY[$BETA]%,*}" "${MASS_PRECONDITIONING_ARRAY[$BETA]#*,}"
        fi
            printf "\n"
    done
    printf "\e[0;36m============================================================================================================\n\e[0m"

    #If we are not in the continue scenario (and not in other script use cases), look for the correct configuration to start from and set the global path
    if [ $CONTINUE = "FALSE" ] && [ $CLEAN_OUTPUT_FILES = "FALSE" ] && [ $EMPTY_BETA_DIRS = "FALSE" ] && [ $INVERT_CONFIGURATIONS = "FALSE" ]; then
        for BETA in "${BETAVALUES[@]}"; do
            if [ "$BETA_POSTFIX" == "" ]; then #Old nomenclature case: no beta postfix!
                local FOUND_CONFIGURATIONS=( $(ls $THERMALIZED_CONFIGURATIONS_PATH | grep "conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA}.*") )
                if [ ${#FOUND_CONFIGURATIONS[@]} -eq 0 ]; then
                    STARTCONFIGURATION_GLOBALPATH[$BETA]="notFoundHenceStartFromHot"
                elif [ ${#FOUND_CONFIGURATIONS[@]} -eq 1 ]; then
                    STARTCONFIGURATION_GLOBALPATH[$BETA]="${THERMALIZED_CONFIGURATIONS_PATH}/${FOUND_CONFIGURATIONS[0]}"
                else
                    printf "\n\e[0;31m No valid starting configuration found for beta = ${BETA%%_*} in \"$THERMALIZED_CONFIGURATIONS_PATH\"\n"
                    printf " Zero or more than 1 configurations match the following name: \"conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA}.*\"! Aborting...\n\n\e[0m"
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


#TODO: After having refactored the function ReadBetaValuesFromFile, one could reuse some functionality of there.
function __static__PrintOldLineToBetasFileAndShiftArrays(){
    if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then
        printf "${BETA_ARRAY[0]}\t${SEED_ARRAY[0]}\t${REST_OF_THE_LINE_ARRAY[0]}\n"  >> $BETASFILE
        SEED_JUST_PRINTED_TO_FILE="${SEED_ARRAY[0]}"
        SEED_ARRAY=("${SEED_ARRAY[@]:1}")
    else
        printf "${BETA_ARRAY[0]}\t${REST_OF_THE_LINE_ARRAY[0]}\n" >> $BETASFILE
    fi
    BETA_JUST_PRINTED_TO_FILE="${BETA_ARRAY[0]}"
    REST_OF_THE_LINE_JUST_PRINTED_TO_FILE="${REST_OF_THE_LINE_ARRAY[0]}"
    BETA_ARRAY=("${BETA_ARRAY[@]:1}")
    REST_OF_THE_LINE_ARRAY=("${REST_OF_THE_LINE_ARRAY[@]:1}")
}

function __static__PrintNewLineToBetasFile(){
    printf "$BETA_JUST_PRINTED_TO_FILE\t$NEW_SEED\t$REST_OF_THE_LINE_JUST_PRINTED_TO_FILE\n" >> $BETASFILE
}

function CompleteBetasFile(){
    local OLD_IFS=$IFS      # save the field separator
    local IFS=$'\n'         # new field separator, the end of line
    local BETA=""
    local BETA_ARRAY=()
    local REST_OF_THE_LINE=""
    local REST_OF_THE_LINE_ARRAY=()
    local COMMENTED_LINE_ARRAY=()
    [ $USE_MULTIPLE_CHAINS == "TRUE" ] && local SEED="" && local SEED_ARRAY=()
    for LINE in $(sort -k1n $BETASFILE); do
        if [[ $LINE =~ ^[[:blank:]]*$ ]]; then
            continue
        fi
        if [[ $LINE =~ ^[[:blank:]]*# ]]; then
            COMMENTED_LINE_ARRAY+=( "$LINE" )
            continue
        fi
        LINE=`echo $LINE | awk '{split($0, res, "#"); print res[1]}'`
        BETA=$(awk '{print $1}' <<< "$LINE")
        REST_OF_THE_LINE=$(awk '{$1=""; print $0}' <<< "$LINE")
        if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then
            SEED=$(awk '{print $1}' <<< "$REST_OF_THE_LINE")
            REST_OF_THE_LINE=$(awk '{$1=""; print $0}' <<< "$REST_OF_THE_LINE")
        else
            if [[ $(awk '{print $1}' <<< "$REST_OF_THE_LINE") =~ ^[[:digit:]]{4}$ ]]; then
                printf "\n\e[0;33m \e[1m\e[4mWARNING\e[24m:\e[0;33m It seems you put seeds in betas file but you invoked\n"
                printf "          this script without \"-u\" option. Would you like to continue (Y/N)? \e[0m"
                local CONFIRM="";
                while read CONFIRM; do
                    if [ "$CONFIRM" = "Y" ]; then
                        break;
                    elif [ "$CONFIRM" = "N" ]; then
                        return
                    else
                        printf "\n\e[0;33m Please enter Y (yes) or N (no): \e[0m"
                    fi
                done
            fi
        fi
        #Check each entry
        if [[ ! $BETA =~ ^[[:digit:]].[[:digit:]]{4}$ ]]; then
            printf "\n\e[0;31m Invalid beta entry in betas file! Aborting...\n\n\e[0m"
            exit -1
        fi
        if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then
            if [[ ! $SEED =~ ^[[:digit:]]{4}$ ]]; then
                printf "\n\e[0;31m Invalid seed entry in betas file! Aborting...\n\n\e[0m"
                exit -1
            fi
        fi
        #Checks done, fill arrays
        BETA_ARRAY+=( $BETA )
        [ $USE_MULTIPLE_CHAINS == "TRUE" ] && SEED_ARRAY+=( $SEED )
        REST_OF_THE_LINE_ARRAY+=( "$REST_OF_THE_LINE" )
    done
    IFS=$OLD_IFS     # restore default field separator

    #Produce complete betas file
    local BETASFILE_BACKUP="${BETASFILE}_backup"
    mv $BETASFILE $BETASFILE_BACKUP || exit -2
    while [ "${#BETA_ARRAY[@]}" -ne 0 ]; do
        local BETA_JUST_PRINTED_TO_FILE=""
        local SEED_JUST_PRINTED_TO_FILE=""
        local REST_OF_THE_LINE_JUST_PRINTED_TO_FILE=""
        local NUMBER_OF_BETA_PRINTED_TO_FILE=0
        #In case multiple chains are used, the betas with already a seed are copied to file
        if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then
            __static__PrintOldLineToBetasFileAndShiftArrays
            (( NUMBER_OF_BETA_PRINTED_TO_FILE++ ))
            while [ "${BETA_ARRAY[0]}" = $BETA_JUST_PRINTED_TO_FILE ]; do #This while works because above we read the betasfile sorted!
                __static__PrintOldLineToBetasFileAndShiftArrays
                (( NUMBER_OF_BETA_PRINTED_TO_FILE++ ))
            done
        fi
        #Then complete file
        if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then
            local SEED_TO_GENERATE_NEW_SEED_FROM="$SEED_JUST_PRINTED_TO_FILE"
        else
            local SEED_TO_GENERATE_NEW_SEED_FROM="${BETA_ARRAY[0]##*[.]}"
            #Unset arrays pretending to have written to file to uniform __static__PrintNewLineToBetasFile function
            BETA_JUST_PRINTED_TO_FILE="${BETA_ARRAY[0]}"
            REST_OF_THE_LINE_JUST_PRINTED_TO_FILE="${REST_OF_THE_LINE_ARRAY[0]}"
            BETA_ARRAY=("${BETA_ARRAY[@]:1}")
            REST_OF_THE_LINE_ARRAY=("${REST_OF_THE_LINE_ARRAY[@]:1}")
            #Print first line with starting seed
            NEW_SEED=$SEED_TO_GENERATE_NEW_SEED_FROM
            __static__PrintNewLineToBetasFile
            (( NUMBER_OF_BETA_PRINTED_TO_FILE++ ))
        fi
        for((INDEX=$NUMBER_OF_BETA_PRINTED_TO_FILE; INDEX<$NUMBER_OF_CHAINS_TO_BE_IN_THE_BETAS_FILE; INDEX++)); do
            local NEW_SEED=$(sed -e 's/\(.\)/\n\1/g' <<< "$SEED_TO_GENERATE_NEW_SEED_FROM"  | awk 'BEGIN{ORS=""}NR>1{print ($1+1)%10}')
            __static__PrintNewLineToBetasFile
            SEED_TO_GENERATE_NEW_SEED_FROM=$NEW_SEED
        done
        echo "" >> $BETASFILE
    done
    #Print commented lines
    for LINE in "${COMMENTED_LINE_ARRAY[@]}"; do
        echo $LINE >> $BETASFILE
    done
    rm $BETASFILE_BACKUP

    printf "\n\e[38;5;13m New betasfile successfully created!\e[0m\n"
}


function UncommentEntriesInBetasFile()
{
    if [ $UNCOMMENT_BETAS = "TRUE" ]
    then
        #at first comment all lines
        sed -i "s/^\([^#].*\)/#\1/" $BETASFILE

        local IFS=' '
        local OLD_IFS=$IFS
        for i in ${UNCOMMENT_BETAS_SEED_ARRAY[@]}
        do
            #echo entry: $i
            IFS='_'
            local U_ARRAY=( $i )
            local U_BETA=${U_ARRAY[0]}
            local U_SEED=${U_ARRAY[1]}
            local U_SEED=${U_SEED#s}

            sed -i "s/^#\(.*$U_BETA.*$U_SEED.*\)$/\1/" $BETASFILE #If there is a "#" in front of the line, remove it
        done
        IFS=$OLD_IFS

        for i in ${UNCOMMENT_BETAS_ARRAY[@]}
        do
            U_BETA=$i
            sed -i "s/^#\(.*$U_BETA.*\)$/\1/" $BETASFILE #If there is a "#" in front of the line, remove it
        done

    elif [ $COMMENT_BETAS = "TRUE" ] #Basically the reverse case of the above
    then
        #at first uncomment all lines
        sed -i "s/^#\(.*\)/\1/" $BETASFILE

        local IFS=' '
        local OLD_IFS=$IFS
        for i in ${UNCOMMENT_BETAS_SEED_ARRAY[@]}
        do
            #echo entry: $i
            IFS='_'
            local U_ARRAY=( $i )
            local U_BETA=${U_ARRAY[0]}
            local U_SEED=${U_ARRAY[1]}
            local U_SEED=${U_SEED#s}

            sed -i "s/^\($U_BETA.*$U_SEED.*\)$/#\1/" $BETASFILE #If there is no "#" in front of the line, put one
        done
        IFS=$OLD_IFS

        for i in ${UNCOMMENT_BETAS_ARRAY[@]}
        do
            U_BETA=$i
            sed -i "s/^\($U_BETA.*\)$/#\1/" $BETASFILE #If there is no "#" in front of the line, put one
        done
    fi

    less $BETASFILE
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


function ProcessBetaValuesForInversion()
{    
    if [ "$CLUSTER_NAME" = "JUQUEEN" ]
    then
        printf "\n\e[0;31mOption --invertConfigurations not yet implemented on the Juqueen! Aborting...\n\n\e[0m"; exit -1
    else
        ProcessBetaValuesForInversion_Loewe
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
