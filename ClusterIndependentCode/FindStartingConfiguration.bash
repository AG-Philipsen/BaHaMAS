
function __static__PickUpStartingConfigurationAmongAvailableOnes()
{
    local CONFIGURATION_CHOSEN_BY_USER
    PS3=$(cecho -d "\n" yg "Enter the number corresponding to the desired configuration: " lp)
    select CONFIGURATION_CHOSEN_BY_USER in "${FOUND_CONFIGURATIONS[@]}"; do
        if ! ElementInArray "$CONFIGURATION_CHOSEN_BY_USER" "${FOUND_CONFIGURATIONS[@]}"; then
            continue
        else
            break
        fi
    done
    cecho "" #Restore also default color
    BHMAS_startConfigurationGlobalPath[$BETA]="$CONFIGURATION_CHOSEN_BY_USER"
}

function FindConfigurationGlobalPathFromWhichToStartTheSimulation()
{
    local FOUND_CONFIGURATIONS
    for BETA in "${BHMAS_betaValues[@]}"; do
        if [ "$BHMAS_betaPostfix" == "" ]; then #Single chain case: nomenclature with no beta postfix!
            FOUND_CONFIGURATIONS=( $(find $BHMAS_thermConfsGlobalPath -regextype posix-extended -regex ".*/conf[.]${BHMAS_parametersString}_${BHMAS_betaPrefix}${BETA}.*") )
            if [ ${#FOUND_CONFIGURATIONS[@]} -eq 0 ]; then
                BHMAS_startConfigurationGlobalPath[$BETA]="notFoundHenceStartFromHot"
            elif [ ${#FOUND_CONFIGURATIONS[@]} -eq 1 ]; then
                BHMAS_startConfigurationGlobalPath[$BETA]="${FOUND_CONFIGURATIONS[0]}"
            else
                cecho -d ly B "\n " U "WARNING" uU ":" uB " More than one valid starting configuration found for " emph "beta = ${BETA%%_*}" " in \n"\
                      dir "          $BHMAS_thermConfsGlobalPath" ".\n          Which should be used?\n" lp
                __static__PickUpStartingConfigurationAmongAvailableOnes
            fi
        elif [ $BHMAS_betaPostfix == "_continueWithNewChain" ]; then
            FOUND_CONFIGURATIONS=( $(find $BHMAS_thermConfsGlobalPath -regextype posix-extended -regex ".*/conf[.]${BHMAS_parametersString}_${BHMAS_betaPrefix}${BETA%_*}_fromConf[0-9]+.*") )
            if [ ${#FOUND_CONFIGURATIONS[@]} -eq 0 ]; then
                Warning "No valid starting configuration found for " emph "beta = ${BETA%_*}" "\n"\
                        "in " dir "$BHMAS_thermConfsGlobalPath" ".\n"\
                        "Looking for configuration with not exactely the same seed,\n"\
                        "matching " file "conf[.]${BHMAS_parametersString}_${BHMAS_betaPrefix}${BETA%%_*}_${BHMAS_seedPrefix}${BHMAS_seedRegex//\\/}_fromConf[0-9]+.*" "...\e[s"
                FOUND_CONFIGURATIONS=( $(find $BHMAS_thermConfsGlobalPath -regextype posix-extended -regex ".*/conf[.]${BHMAS_parametersString}_${BHMAS_betaPrefix}${BETA%%_*}_${BHMAS_seedPrefix}${BHMAS_seedRegex//\\/}_fromConf[0-9]+.*") )
                if [ ${#FOUND_CONFIGURATIONS[@]} -eq 0 ]; then
                    cecho -n "\e[1A"; Fatal $BHMAS_fatalFileNotFound " none found!"
                elif [ ${#FOUND_CONFIGURATIONS[@]} -eq 1 ]; then
                    cecho "\e[u\e[2A" lg " found a valid one!\n"
                    BHMAS_startConfigurationGlobalPath[$BETA]="${FOUND_CONFIGURATIONS[0]}"
                else
                    cecho -d "\e[u\e[2A" o " found more than one! Which should be used?\n" lp
                    __static__PickUpStartingConfigurationAmongAvailableOnes
                fi
            elif [ ${#FOUND_CONFIGURATIONS[@]} -eq 1 ]; then
                BHMAS_startConfigurationGlobalPath[$BETA]="${FOUND_CONFIGURATIONS[0]}"
            else
                Warning "More than one valid starting configuration found for " emph "beta = ${BETA%%_*}" " in \n"\
                        dir "$BHMAS_thermConfsGlobalPath" ".\nWhich should be used?"
                cecho -d -n lp; __static__PickUpStartingConfigurationAmongAvailableOnes
            fi
        elif [ $BHMAS_betaPostfix == "_thermalizeFromConf" ]; then
            if [ $(find $BHMAS_thermConfsGlobalPath -regextype posix-extended -regex ".*/conf[.]${BHMAS_parametersString}_${BHMAS_betaPrefix}${BETA%_*}_fromConf[0-9]+.*" | wc -l) -ne 0 ]; then
                Fatal $BHMAS_fatalFileExists "It seems that there is already a thermalized configuration for " emph "beta = ${BETA%_*}" " in\n"\
                      dir "$BHMAS_thermConfsGlobalPath" "!"
            fi
            FOUND_CONFIGURATIONS=( $(find $BHMAS_thermConfsGlobalPath -regextype posix-extended -regex ".*/conf[.]${BHMAS_parametersString}_${BHMAS_betaPrefix}${BHMAS_betaRegex//\\/}_${BHMAS_seedPrefix}${BHMAS_seedRegex//\\/}_fromHot[0-9]+.*") )
            #Here a 0 length of FOUND_CONFIGURATIONS is not checked since we rely on the fact that if this was the case we would have $BHMAS_betaPostfix == "_thermalizeFromHot" as set in JobHandler.bash (Thermalize case)
            declare -A FOUND_CONFIGURATIONS_WITH_BETA_AS_KEY=()
            for CONFNAME in "${FOUND_CONFIGURATIONS[@]}"; do
                local BETAVALUE_RECOVERED_FROM_NAME=$(awk '{split($1, res, "_fromHot"); print res[1]}' <<< "$CONFNAME" | sed 's/.*\('${BHMAS_betaRegex}'\).*/\1/')
                FOUND_CONFIGURATIONS_WITH_BETA_AS_KEY["$BETAVALUE_RECOVERED_FROM_NAME"]=$CONFNAME
            done
            local CLOSEST_BETA=$(FindValueOfClosestElementInArrayToGivenValue ${BETA%%_*} "${!FOUND_CONFIGURATIONS_WITH_BETA_AS_KEY[@]}")
            if [ "$CLOSEST_BETA" = "" ]; then
                Internal "Something went wrong determinig the closest beta value to the actual one to pick up the correct thermalized from Hot configuration!"
            fi
            BHMAS_startConfigurationGlobalPath[$BETA]="${FOUND_CONFIGURATIONS_WITH_BETA_AS_KEY[$CLOSEST_BETA]}"
        elif [ $BHMAS_betaPostfix == "_thermalizeFromHot" ]; then
            BHMAS_startConfigurationGlobalPath[$BETA]="notFoundHenceStartFromHot"
        else
            Internal "Something really strange happened! BHMAS_betaPostfix set to unknown value " emph "BHMAS_betaPostfix = $BHMAS_betaPostfix" "!"
        fi
    done
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         __static__PickUpStartingConfigurationAmongAvailableOnes\
         FindConfigurationGlobalPathFromWhichToStartTheSimulation
