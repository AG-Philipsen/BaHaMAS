# Collection of function needed in the job handler script.

# Load auxiliary bash files that will be used.
source ${BaHaMAS_repositoryTopLevelPath}/AuxiliaryFunctions_SLURM.bash || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/ListJobsStatus_SLURM.bash     || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/CleanOutputFiles.bash         || exit -2
#------------------------------------------------------------------------------------#

function ReadBetaValuesFromFile()
{
    if [ ! -e $BETASFILE ]; then
        cecho lr "\n  File " emph "$BETASFILE" " not found in $(pwd). Aborting...\n"
        exit -1
    fi

    #For syncronization reason the betas file MUST contain the beta value in the first column! Check:
    for ENTRY in $(awk '{split($0, res, "#"); print res[1]}' $BETASFILE |  awk '{print $1}'); do
        if [[ ! "$ENTRY" =~ ^[[:digit:]][.][[:digit:]]{4}$ ]]; then
            cecho lr "\n The betas file MUST contain the beta value in the first column! Aborting...\n"
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
        LINE=`awk '{split($0, res, "#"); print res[1]}' <<< "$LINE"`
        #Look for "resumefrom=*" check it, save the content and delete it
        SEARCH_RESULT=( $(grep -o "$RESUME_REGEXPR" <<< "$LINE" || true) ) #'|| true' because of set -e
        case ${#SEARCH_RESULT[@]} in
            0 ) CONTINUE_RESUMETRAJ_TEMP+=( "notFound" );;
            1 ) CONTINUE_RESUMETRAJ_TEMP+=( ${SEARCH_RESULT[0]}); LINE=$( sed 's/'$RESUME_REGEXPR'//g' <<< "$LINE" );;
            * ) cecho lr "\n String " emph "resumefrom=*" " specified multiple times per line in betasfile! Aborting...\n"; exit -1;;
        esac
        #Look for "MP=(*,*)" check it, save the content and delete it
        SEARCH_RESULT=( $(grep -o "$MP_REGEXPR" <<< "$LINE" || true) ) #'|| true' because of set -e
        case ${#SEARCH_RESULT[@]} in
            0 ) MASS_PRECONDITIONING_TEMP+=( "notFound" );;
            1 ) MASS_PRECONDITIONING_TEMP+=( ${SEARCH_RESULT[0]}); LINE=$( sed 's/'$MP_REGEXPR'//g' <<< "$LINE" );;
            * ) cecho lr "\n String " emph "MP=(*,*)" " specified multiple times per line in betasfile! Aborting...\n"; exit -1;;
        esac
        #Read the rest
        BETAVALUES+=( $(awk '{print $1}' <<< "$LINE") )
        if [ $USE_MULTIPLE_CHAINS == "FALSE" ]; then
            INTSTEPS0_ARRAY_TEMP+=( $(awk '{print $2}' <<< "$LINE") )
            INTSTEPS1_ARRAY_TEMP+=( $(awk '{print $3}' <<< "$LINE") )
        else
            SEED_ARRAY_TEMP+=( $(awk '{print $2}' <<< "$LINE") )
            INTSTEPS0_ARRAY_TEMP+=( $(awk '{print $3}' <<< "$LINE") )
            INTSTEPS1_ARRAY_TEMP+=( $(awk '{print $4}' <<< "$LINE") )
        fi
    done
    IFS=$OLD_IFS     # restore default field separator

    #Check whether the entries in the file have the right format, otherwise abort
    if [ ${#BETAVALUES[@]} -eq 0 ]; then
        cecho lr "\n  No beta values in betas file. Aborting...\n"
        exit -1
    fi

    #NOTE: The following check on beta is redundant ---> TODO: Think deeply about and in case remove it!
    for BETA in ${BETAVALUES[@]}; do
        if [[ ! $BETA =~ ^[[:digit:]].[[:digit:]]{4}$ ]]; then
            cecho lr "\n Invalid beta entry in betas file! Aborting...\n"
            exit -1
        fi
    done

    if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then
        if [ ${#SEED_ARRAY_TEMP[@]} -ne ${#BETAVALUES[@]} ]; then
            cecho lr "\n  Number of provided seeds differ from the number of provided beta values in betas file. Aborting...\n"
            exit -1
        fi

        for SEED in ${SEED_ARRAY_TEMP[@]}; do
            if [[ ! $SEED =~ ^[[:alnum:]]{4}$ ]]; then
                cecho lr "\n Invalid seed entry in betas file! Aborting...\n"
                exit -1
            fi
        done

        #Check whether same seed is provided multiple times for same beta --> do it with an associative array in awk after having removed "resumefrom=", EMPTYLINES and comments
        if [ "$(awk '{split($0, res, "'#'"); print res[1]}' $BETASFILE |\
                sed -e 's/'$RESUME_REGEXPR'//g' -e 's/'$MP_REGEXPR'//g' -e '/^[[:space:]]*$/d' |\
                awk '{array[$1,$2]++}END{for(ind in array){if(array[ind]>1){print -1; exit}}}')" == -1 ]; then
            cecho lr "\n Same seed provided multiple times for same beta!! Aborting...\n"
            exit -1
        fi

        #NOTE: If one uses multiple chains and forgets the seeds column and the second integrator steps column
        #      in the betas file, then the first column of integrator steps is used as seed and the default integrators steps
        #      are used. In the case in which the first integrator steps is a 4-digit number, the script will do its job without
        #      throwing any exception. We didn't cure this case since it is a very remote case................

        #Modify the content of BETAVALUES[@] from x.xxxx to x.xxxx_syyyy in order to use this new label in the associative arrays everyehere!
        for INDEX in "${!BETAVALUES[@]}"; do
            BETAVALUES[$INDEX]="${BETAVALUES[$INDEX]}_s${SEED_ARRAY_TEMP[$INDEX]}$BHMAS_betaPostfix"
        done
    fi

    if [ ${#INTSTEPS0_ARRAY_TEMP[@]} -ne 0 ]; then #If the first intsteps array is empty the second CANNOT be not empty (because of how I read them with awk from file)
        for STEPS in ${INTSTEPS0_ARRAY_TEMP[@]} ${INTSTEPS1_ARRAY_TEMP[@]}; do
            if [[ ! $STEPS =~ ^[[:digit:]]{1,2}$ ]]; then
                cecho lr "\n Invalid integrator step entry in betas file (only one or two digits admitted)! Aborting..."
                if [[ $STEPS =~ ^[[:digit:]]{4}$ ]]; then
                    cecho lr B "   HINT" uB ": Maybe your intention was to use Multiple Chains...\n"
                else
                    cecho ""
                fi
                exit -1
            fi
        done

        if [ ${#INTSTEPS0_ARRAY_TEMP[@]} -ne ${#BETAVALUES[@]} ] || [ ${#INTSTEPS1_ARRAY_TEMP[@]} -ne ${#BETAVALUES[@]} ]; then
            cecho lr "\n Integrators steps not specified for ALL beta in betas file! Aborting...\n"
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
                cecho lr "\n Invalid resume trajectory number in betasfile! Aborting...\n"
                exit -1
            fi
            #Build associative array for later use
            CONTINUE_RESUMETRAJ_ARRAY["${BETAVALUES[$INDEX]}"]="$TEMP_STR"
        fi
        TEMP_STR=${MASS_PRECONDITIONING_TEMP[$INDEX]}
        if [[ $TEMP_STR != "notFound" ]]; then
            TEMP_STR=${TEMP_STR#"MP=("}
            TEMP_STR=${TEMP_STR%")"}
            #Build associative array for later use
            if [[ ! $TEMP_STR =~ ^[[:digit:]]{1,2},[[:digit:]]{3,4}$ ]]; then
                cecho lr "\n Invalid Mass Preconditioning parameters in betasfile! The string must match the regular\n"\
                      " expression " emph  '^MP=([[:digit:]]{1,2},[[:digit:]]{3,4})$' "! Aborting...\n"
                exit -1
            fi
            MASS_PRECONDITIONING_ARRAY["${BETAVALUES[$INDEX]}"]="$TEMP_STR"
        fi
    done

    cecho lc "\n============================================================================================================"
    cecho lp " Read beta values:"
    for BETA in ${BETAVALUES[@]}; do
        cecho -n "  - $BETA\t [Integrator steps ${INTSTEPS0_ARRAY[$BETA]}-${INTSTEPS1_ARRAY[$BETA]}]"
        if KeyInArray $BETA CONTINUE_RESUMETRAJ_ARRAY; then
            cecho -n "$(printf "   [resume from tr. %+6s]" "${CONTINUE_RESUMETRAJ_ARRAY[$BETA]}")"
        else
            cecho -n "                          "
        fi
        if KeyInArray $BETA MASS_PRECONDITIONING_ARRAY; then
            cecho -n "$(printf "   MP=(%d-0.%4d)" "${MASS_PRECONDITIONING_ARRAY[$BETA]%,*}" "${MASS_PRECONDITIONING_ARRAY[$BETA]#*,}")"
        fi
        cecho ''
    done
    cecho lc "============================================================================================================"

    #If we are not in the continue scenario (and not in other script use cases), look for the correct configuration to start from and set the global path
    if [ $CONTINUE = "FALSE" ] && [ $CLEAN_OUTPUT_FILES = "FALSE" ] && [ $INVERT_CONFIGURATIONS = "FALSE" ] && [ $ACCRATE_REPORT = "FALSE" ]; then
        for BETA in "${BETAVALUES[@]}"; do
            if [ "$BHMAS_betaPostfix" == "" ]; then #Old nomenclature case: no beta postfix!
                local FOUND_CONFIGURATIONS=( $(ls $BHMAS_thermConfsGlobalPath | grep "^conf.${BHMAS_parametersString}_${BHMAS_betaPrefix}${BETA}.*") )
                if [ ${#FOUND_CONFIGURATIONS[@]} -eq 0 ]; then
                    STARTCONFIGURATION_GLOBALPATH[$BETA]="notFoundHenceStartFromHot"
                elif [ ${#FOUND_CONFIGURATIONS[@]} -eq 1 ]; then
                    STARTCONFIGURATION_GLOBALPATH[$BETA]="${BHMAS_thermConfsGlobalPath}/${FOUND_CONFIGURATIONS[0]}"
                else
                    cecho lr "\n No valid starting configuration found for " emph "beta = ${BETA}" " in " dir "$BHMAS_thermConfsGlobalPath" "\n"\
                          " More than 1 configuration matches " file "conf.${BHMAS_parametersString}_${BHMAS_betaPrefix}${BETA}.*" "! Aborting...\n"
                    exit -1
                fi
            elif [ $BHMAS_betaPostfix == "_continueWithNewChain" ]; then
                local FOUND_CONFIGURATIONS=( $(ls $BHMAS_thermConfsGlobalPath | grep "^conf.${BHMAS_parametersString}_${BHMAS_betaPrefix}${BETA%_*}_fromConf[[:digit:]]\+.*") )
                if [ ${#FOUND_CONFIGURATIONS[@]} -eq 0 ]; then
                    cecho -n ly B "\n " U "WARNING" uU ":" uB " No valid starting configuration found for " emph "beta = ${BETA%_*}" "\n"\
                          "          in " dir "$BHMAS_thermConfsGlobalPath" ".\n"\
                          "          Looking for configuration with not exactely the same seed,\n"\
                          "          matching " file "conf.${BHMAS_parametersString}_${BHMAS_betaPrefix}${BETA%%_*}_${BHMAS_seedPrefix}${BHMAS_seedRegex}_fromConf[[:digit:]]\+.*"
                    FOUND_CONFIGURATIONS=( $(ls $BHMAS_thermConfsGlobalPath | grep "^conf.${BHMAS_parametersString}_${BHMAS_betaPrefix}${BETA%%_*}_${BHMAS_seedPrefix}${BHMAS_seedRegex}_fromConf[[:digit:]]\+.*") )
                    if [ ${#FOUND_CONFIGURATIONS[@]} -eq 0 ]; then
                        cecho lr " none found! Aborting...\n"
                        exit -1
                    elif [ ${#FOUND_CONFIGURATIONS[@]} -eq 1 ]; then
                        cecho lg " found a valid one!\n"
                        STARTCONFIGURATION_GLOBALPATH[$BETA]="${BHMAS_thermConfsGlobalPath}/${FOUND_CONFIGURATIONS[0]}"
                    else
                        cecho -d o " found more than one! Which should be used?\n" bb
                        PS3=$(cecho -d "\n" yg "Enter the number corresponding to the desired configuration: " bb)
                        select CONFIGURATION_CHOSEN_BY_USER in "${FOUND_CONFIGURATIONS[@]}"; do
                            if ! ElementInArray "$CONFIGURATION_CHOSEN_BY_USER" "${FOUND_CONFIGURATIONS[@]}"; then
                                continue
                            else
                                break
                            fi
                        done
                        cecho "" #Restore also default color
                        STARTCONFIGURATION_GLOBALPATH[$BETA]="${BHMAS_thermConfsGlobalPath}/$CONFIGURATION_CHOSEN_BY_USER"
                    fi
                elif [ ${#FOUND_CONFIGURATIONS[@]} -eq 1 ]; then
                    STARTCONFIGURATION_GLOBALPATH[$BETA]="${BHMAS_thermConfsGlobalPath}/${FOUND_CONFIGURATIONS[0]}"
                else
                    cecho ly B "\n " U "WARNING" uU ":" uB " More than one valid starting configuration found for " emph "beta = ${BETA%%_*}" " in "\
                          dir "$BHMAS_thermConfsGlobalPath" ".\nWhich should be used?\n" bc
                    PS3=$(cecho -d "\n" yg "Enter the number corresponding to the desired configuration: " bc)
                    select CONFIGURATION_CHOSEN_BY_USER in "${FOUND_CONFIGURATIONS[@]}"; do
                        if ! ElementInArray "$CONFIGURATION_CHOSEN_BY_USER" "${FOUND_CONFIGURATIONS[@]}"; then
                            continue
                        else
                            break
                        fi
                    done
                    cecho "" #Restore also default color
                    STARTCONFIGURATION_GLOBALPATH[$BETA]="${BHMAS_thermConfsGlobalPath}/$CONFIGURATION_CHOSEN_BY_USER"
                fi
            elif [ $BHMAS_betaPostfix == "_thermalizeFromConf" ]; then
                if [ $(ls $BHMAS_thermConfsGlobalPath | grep "^conf.${BHMAS_parametersString}_${BHMAS_betaPrefix}${BETA%_*}_fromConf[[:digit:]]\+.*" | wc -l) -ne 0 ]; then
                    cecho lr "\n It seems that there is already a thermalized configuration for " emph "beta = ${BETA%_*}" " in " dir "$BHMAS_thermConfsGlobalPath" "! Aborting...\n"
                    exit -1
                fi
                local FOUND_CONFIGURATIONS=( $(ls $BHMAS_thermConfsGlobalPath | grep "^conf.${BHMAS_parametersString}_${BHMAS_betaPrefix}${BHMAS_betaRegex}_${BHMAS_seedPrefix}${BHMAS_seedRegex}_fromHot[[:digit:]]\+.*") )
                #Here a 0 length of FOUND_CONFIGURATIONS is not checked since we rely on the fact that if this was the case we would have $BHMAS_betaPostfix == "_thermalizeFromHot" as set in JobHandler.bash (Thermalize case)
                declare -A FOUND_CONFIGURATIONS_WITH_BETA_AS_KEY
                for CONFNAME in "${FOUND_CONFIGURATIONS[@]}"; do
                    local BETAVALUE_RECOVERED_FROM_NAME=$(awk '{split($1, res, "_fromHot"); print res[1]}' <<< "$CONFNAME" | sed 's/.*\('${BHMAS_betaRegex}'\).*/\1/')
                    FOUND_CONFIGURATIONS_WITH_BETA_AS_KEY["$BETAVALUE_RECOVERED_FROM_NAME"]=$CONFNAME
                done
                local CLOSEST_BETA=$(FindValueOfClosestElementInArrayToGivenValue ${BETA%%_*} "${!FOUND_CONFIGURATIONS_WITH_BETA_AS_KEY[@]}")
                if [ "$CLOSEST_BETA" = "" ]; then
                    cecho lr "\n Something went wrong in determinig the closest beta value to the actual one to pick up the correct thermalized from Hot configuration! Aborting...\n"
                    exit -1
                fi
                STARTCONFIGURATION_GLOBALPATH[$BETA]="${BHMAS_thermConfsGlobalPath}/${FOUND_CONFIGURATIONS_WITH_BETA_AS_KEY[$CLOSEST_BETA]}"
            elif [ $BHMAS_betaPostfix == "_thermalizeFromHot" ]; then
                STARTCONFIGURATION_GLOBALPATH[$BETA]="notFoundHenceStartFromHot"
            else
                cecho lr "\n Something really strange happened! BHMAS_betaPostfix set to unknown value " emph "BHMAS_betaPostfix = $BHMAS_betaPostfix" "! Aborting...\n"
                exit -1
            fi
        done
    fi
}


#TODO: After having refactored the function ReadBetaValuesFromFile, one could reuse some functionality of there.
function __static__PrintOldLineToBetasFileAndShiftArrays()
{
    if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then
        printf "${BETA_ARRAY[0]}\t${SEED_ARRAY[0]}\t${REST_OF_THE_LINE_ARRAY[0]}"  >> $BETASFILE
        SEED_JUST_PRINTED_TO_FILE="${SEED_ARRAY[0]}"
        SEED_ARRAY=("${SEED_ARRAY[@]:1}")
    else
        printf "${BETA_ARRAY[0]}\t${REST_OF_THE_LINE_ARRAY[0]}" >> $BETASFILE
    fi
    BETA_JUST_PRINTED_TO_FILE="${BETA_ARRAY[0]}"
    REST_OF_THE_LINE_JUST_PRINTED_TO_FILE="${REST_OF_THE_LINE_ARRAY[0]}"
    BETA_ARRAY=("${BETA_ARRAY[@]:1}")
    REST_OF_THE_LINE_ARRAY=("${REST_OF_THE_LINE_ARRAY[@]:1}")
}

function __static__PrintNewLineToBetasFile()
{
    printf "$BETA_JUST_PRINTED_TO_FILE\t$NEW_SEED\t$REST_OF_THE_LINE_JUST_PRINTED_TO_FILE" >> $BETASFILE
}

function CompleteBetasFile()
{
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
        LINE=$(awk '{split($0, res, "#"); print res[1]}' <<< "$LINE")
        BETA=$(awk '{print $1}' <<< "$LINE")
        REST_OF_THE_LINE=$(awk '{$1=""; print $0}' <<< "$LINE")
        if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then
            SEED=$(awk '{print $1}' <<< "$REST_OF_THE_LINE")
            REST_OF_THE_LINE=$(awk '{$1=""; print $0}' <<< "$REST_OF_THE_LINE")
        else
            if [[ $(awk '{print $1}' <<< "$REST_OF_THE_LINE") =~ ^[[:digit:]]{4}$ ]]; then
                cecho ly B "\n " U "WARNING" uU ":" uB " It seems you put seeds in betas file but you invoked this script with the " emph "--doNotUseMultipleChains" " option."
                AskUser "Would you like to continue?"
                if UserSaidNo; then
                    return
                fi
            fi
        fi
        #Check each entry
        if [[ ! $BETA =~ ^[[:digit:]].[[:digit:]]{4}$ ]]; then
            cecho lr "\n Invalid beta entry in betas file! Aborting...\n"
            exit -1
        fi
        if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then
            if [[ ! $SEED =~ ^[[:digit:]]{4}$ ]]; then
                cecho lr "\n Invalid seed entry in betas file! Aborting...\n"
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
            (( NUMBER_OF_BETA_PRINTED_TO_FILE++ )) || true #'|| true' because of set -e option
            while [ "${BETA_ARRAY[0]:-}" = $BETA_JUST_PRINTED_TO_FILE ]; do #This while works because above we read the betasfile sorted!
                __static__PrintOldLineToBetasFileAndShiftArrays
                (( NUMBER_OF_BETA_PRINTED_TO_FILE++ )) || true #'|| true' because of set -e option
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
            (( NUMBER_OF_BETA_PRINTED_TO_FILE++ )) || true #'|| true' because of set -e option
        fi
        for((INDEX=$NUMBER_OF_BETA_PRINTED_TO_FILE; INDEX<$NUMBER_OF_CHAINS_TO_BE_IN_THE_BETAS_FILE; INDEX++)); do
            local NEW_SEED=$(sed -e 's/\(.\)/\n\1/g' <<< "$SEED_TO_GENERATE_NEW_SEED_FROM"  | awk 'BEGIN{ORS=""}NR>1{print ($1+1)%10}')
            __static__PrintNewLineToBetasFile
            SEED_TO_GENERATE_NEW_SEED_FROM=$NEW_SEED
        done
        cecho -d "" >> $BETASFILE
    done
    #Print commented lines http://stackoverflow.com/a/34361807
    for LINE in ${COMMENTED_LINE_ARRAY[@]+"COMMENTED_LINE_ARRAY[@]"}; do
        cecho -d $LINE >> $BETASFILE
    done
    rm $BETASFILE_BACKUP

    cecho lm "\n New betasfile successfully created!"
}


function UncommentEntriesInBetasFile()
{
    #at first comment all lines
    sed -i "s/^\([^#].*\)/#\1/" $BETASFILE

    local IFS=' '
    local OLD_IFS=$IFS
    for i in ${UNCOMMENT_BETAS_SEED_ARRAY[@]+"UNCOMMENT_BETAS_SEED_ARRAY[@]"}; do
        IFS='_'
        local U_ARRAY=( $i )
        local U_BETA=${U_ARRAY[0]}
        local U_SEED=${U_ARRAY[1]}
        local U_SEED=${U_SEED#s}
        sed -i "s/^#\(.*$U_BETA.*$U_SEED.*\)$/\1/" $BETASFILE #If there is a "#" in front of the line, remove it
    done
    IFS=$OLD_IFS

    for i in ${UNCOMMENT_BETAS_ARRAY[@]+"UNCOMMENT_BETAS_ARRAY[@]"}; do
        U_BETA=$i
        sed -i "s/^#\(.*$U_BETA.*\)$/\1/" $BETASFILE #If there is a "#" in front of the line, remove it
    done
}

function CommentEntriesInBetasFile()
{
    #at first uncomment all lines
    sed -i "s/^#\(.*\)/\1/" $BETASFILE

    local IFS=' '
    local OLD_IFS=$IFS
    for i in ${UNCOMMENT_BETAS_SEED_ARRAY[@]+"UNCOMMENT_BETAS_SEED_ARRAY"}; do
        IFS='_'
        local U_ARRAY=( $i )
        local U_BETA=${U_ARRAY[0]}
        local U_SEED=${U_ARRAY[1]}
        local U_SEED=${U_SEED#s}
        sed -i "s/^\($U_BETA.*$U_SEED.*\)$/#\1/" $BETASFILE #If there is no "#" in front of the line, put one
    done
    IFS=$OLD_IFS

    for i in ${UNCOMMENT_BETAS_ARRAY[@]+"UNCOMMENT_BETAS_ARRAY"}; do
        U_BETA=$i
        sed -i "s/^\($U_BETA.*\)$/#\1/" $BETASFILE #If there is no "#" in front of the line, put one
    done
}


function PrintReportForProblematicBeta()
{
    if [ ${#PROBLEM_BETA_ARRAY[@]} -gt "0" ]; then
        cecho lr "\n===================================================================================\n"\
              " For the following beta values something went wrong and hence\n"\
              " they were left out during file creation and/or job submission:"
        for BETA in ${PROBLEM_BETA_ARRAY[@]}; do
            cecho lr "  - " B "$BETA"
        done
        cecho lr "===================================================================================\n"
        exit -1
    fi
}

#------------------------------------------------------------------------------------------------------------------------------#

function __static__CheckExistenceOfFunctionAndCallIt()
{
    local nameOfTheFunction
    nameOfTheFunction=$1
    if [ "$(type -t $nameOfTheFunction)" = 'function' ]; then
        $nameOfTheFunction
    else
        cecho "\n" lr "Function " emph "$nameOfTheFunction" " for " emph "$BaHaMAS_clusterScheduler" " scheduler not found!"
        cecho "\n" lr "Please provide an implementation following the " B "BaHaMAS" uB " documentation and source the file. Aborting...\n"
        exit -1
    fi
}


function ProduceInputFileAndJobScriptForEachBeta()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BaHaMAS_clusterScheduler
}


function ProcessBetaValuesForSubmitOnly()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BaHaMAS_clusterScheduler
}


function ProcessBetaValuesForContinue()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BaHaMAS_clusterScheduler
}


function ProcessBetaValuesForInversion()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BaHaMAS_clusterScheduler
}


function SubmitJobsForValidBetaValues()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BaHaMAS_clusterScheduler
}


function ListJobStatus()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BaHaMAS_clusterScheduler
}
