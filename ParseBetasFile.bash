#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function ParseBetasFile()
{
    if [ ! -e $BHMAS_betasFilename ]; then
        cecho lr "\n  File " emph "$BHMAS_betasFilename" " not found in $(pwd). Aborting...\n"
        exit -1
    fi

    #For syncronization reason the betas file MUST contain the beta value in the first column! Check:
    for ENTRY in $(awk '{split($0, res, "#"); print res[1]}' $BHMAS_betasFilename |  awk '{print $1}'); do
        if [[ ! "$ENTRY" =~ ^[[:digit:]][.][[:digit:]]{4}$ ]]; then
            cecho lr "\n The betas file MUST contain the beta value in the first column! Aborting...\n"
            exit -1
        fi
    done

    BETAVALUES=()
    local SEED_ARRAY_TEMP=()
    local BHMAS_scaleZeroIntegrationSteps_TEMP=()
    local BHMAS_scaleOneIntegrationSteps_TEMP=()
    local CONTINUE_RESUMETRAJ_TEMP=()
    local MASS_PRECONDITIONING_TEMP=()
    local RESUME_REGEXPR="resumefrom=\([[:digit:]]\+\|last\)"
    local MP_REGEXPR="MP=(.*)"
    local SEARCH_RESULT=""  # Auxiliary variable to help to parse the file
    local OLD_IFS=$IFS      # save the field separator
    local IFS=$'\n'         # new field separator, the end of line
    for LINE in $(cat $BHMAS_betasFilename); do
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
        if [ $BHMAS_useMultipleChains == "FALSE" ]; then
            BHMAS_scaleZeroIntegrationSteps_TEMP+=( $(awk '{print $2}' <<< "$LINE") )
            BHMAS_scaleOneIntegrationSteps_TEMP+=( $(awk '{print $3}' <<< "$LINE") )
        else
            SEED_ARRAY_TEMP+=( $(awk '{print $2}' <<< "$LINE") )
            BHMAS_scaleZeroIntegrationSteps_TEMP+=( $(awk '{print $3}' <<< "$LINE") )
            BHMAS_scaleOneIntegrationSteps_TEMP+=( $(awk '{print $4}' <<< "$LINE") )
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

    if [ $BHMAS_useMultipleChains == "TRUE" ]; then
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
        if [ "$(awk '{split($0, res, "'#'"); print res[1]}' $BHMAS_betasFilename |\
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

    if [ ${#BHMAS_scaleZeroIntegrationSteps_TEMP[@]} -ne 0 ]; then #If the first intsteps array is empty the second CANNOT be not empty (because of how I read them with awk from file)
        for STEPS in ${BHMAS_scaleZeroIntegrationSteps_TEMP[@]} ${BHMAS_scaleOneIntegrationSteps_TEMP[@]}; do
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

        if [ ${#BHMAS_scaleZeroIntegrationSteps_TEMP[@]} -ne ${#BETAVALUES[@]} ] || [ ${#BHMAS_scaleOneIntegrationSteps_TEMP[@]} -ne ${#BETAVALUES[@]} ]; then
            cecho lr "\n Integrators steps not specified for ALL beta in betas file! Aborting...\n"
            exit -1
        fi

        #Now that all the checks have been done, build associative arrays for later use of integration steps
        for INDEX in "${!BETAVALUES[@]}"; do
            BHMAS_scaleZeroIntegrationSteps["${BETAVALUES[$INDEX]}"]="${BHMAS_scaleZeroIntegrationSteps_TEMP[$INDEX]}"
            BHMAS_scaleOneIntegrationSteps["${BETAVALUES[$INDEX]}"]="${BHMAS_scaleOneIntegrationSteps_TEMP[$INDEX]}"
        done
    else
        #Build associative arrays for later use of integration steps with the same value for all betas
        for INDEX in "${!BETAVALUES[@]}"; do
            BHMAS_scaleZeroIntegrationSteps["${BETAVALUES[$INDEX]}"]=$INTSTEPS0
            BHMAS_scaleOneIntegrationSteps["${BETAVALUES[$INDEX]}"]=$INTSTEPS1
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
            BHMAS_trajectoriesToBeResumedFrom["${BETAVALUES[$INDEX]}"]="$TEMP_STR"
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
            BHMAS_massPreconditioningValues["${BETAVALUES[$INDEX]}"]="$TEMP_STR"
        fi
    done

    cecho lc "\n============================================================================================================"
    cecho lp " Read beta values:"
    for BETA in ${BETAVALUES[@]}; do
        cecho -n "  - $BETA\t [Integrator steps ${BHMAS_scaleZeroIntegrationSteps[$BETA]}-${BHMAS_scaleOneIntegrationSteps[$BETA]}]"
        if KeyInArray $BETA BHMAS_trajectoriesToBeResumedFrom; then
            cecho -n "$(printf "   [resume from tr. %+6s]" "${BHMAS_trajectoriesToBeResumedFrom[$BETA]}")"
        else
            cecho -n "                          "
        fi
        if KeyInArray $BETA BHMAS_massPreconditioningValues; then
            cecho -n "$(printf "   MP=(%d-0.%4d)" "${BHMAS_massPreconditioningValues[$BETA]%,*}" "${BHMAS_massPreconditioningValues[$BETA]#*,}")"
        fi
        cecho ''
    done
    cecho lc "============================================================================================================"
}
