#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function CheckUserDefinedVariablesAndDefineDependentAdditionalVariables()
{
    local variablesThatMustBeNotEmpty\
          variablesThatMustBeDeclared\
          variablesThatIfNotEmptyMustNotEndWithSlash\
          index variable mustReturn
    mustReturn='TRUE'
    variablesThatMustBeNotEmpty=( BHMAS_userEmail
                                  BHMAS_submitDiskGlobalPath
                                  BHMAS_runDiskGlobalPath )
    variablesThatMustBeDeclared=( BHMAS_GPUsPerNode
                                  BHMAS_jobScriptFolderName
                                  BHMAS_projectSubpath
                                  BHMAS_inputFilename
                                  BHMAS_jobScriptPrefix
                                  BHMAS_outputFilename
                                  BHMAS_acceptanceColumn
                                  BHMAS_databaseFilename
                                  BHMAS_databaseGlobalPath
                                  BHMAS_thermConfsGlobalPath
                                  BHMAS_hmcGlobalPath
                                  BHMAS_inverterGlobalPath
                                  BHMAS_excludeNodesGlobalPath
                                  BHMAS_rationalApproxGlobalPath
                                  BHMAS_approxHeatbathFilename
                                  BHMAS_approxMDFilename
                                  BHMAS_approxMetropolisFilename
                                  BHMAS_clusterPartition
                                  BHMAS_clusterNode
                                  BHMAS_clusterConstraint
                                  BHMAS_clusterGenericResource
                                  BHMAS_walltime )
    variablesThatIfNotEmptyMustNotEndWithSlash=(BHMAS_submitDiskGlobalPath
                                                BHMAS_runDiskGlobalPath
                                                BHMAS_projectSubpath
                                                BHMAS_databaseGlobalPath
                                                BHMAS_thermConfsGlobalPath
                                                BHMAS_hmcGlobalPath
                                                BHMAS_inverterGlobalPath
                                                BHMAS_rationalApproxGlobalPath )

    #Check variables and unset them if they are fine
    for index in "${!variablesThatMustBeNotEmpty[@]}"; do
        if [ -n "${!variablesThatMustBeNotEmpty[$index]:+x}" ]; then
            #Variable set and not empty
            unset -v 'variablesThatMustBeNotEmpty[$index]'
        fi
    done
    for index in "${!variablesThatMustBeDeclared[@]}"; do
        if [ -n "${!variablesThatMustBeDeclared[$index]+x}" ]; then
            #Variable set
            unset -v 'variablesThatMustBeDeclared[$index]'
        fi
    done
    for index in "${!variablesThatIfNotEmptyMustNotEndWithSlash[@]}"; do
        if [ -n "${!variablesThatIfNotEmptyMustNotEndWithSlash[$index]:+x}" ] && [[ "${!variablesThatIfNotEmptyMustNotEndWithSlash[$index]}" =~ /[[:space:]]*$ ]]; then
            continue
        else
            unset -v 'variablesThatIfNotEmptyMustNotEndWithSlash[$index]'
        fi
    done

    #Check variables values (those not checked have no requirement at this point)
    if [ "$BHMAS_colouredOutput" != 'TRUE' ] && [ "$BHMAS_colouredOutput" != 'FALSE' ]; then
        #Since in the following we use cecho which rely on the variable "BHMAS_colouredOutput",
        #if this was wrongly set, let us set it to 'FALSE' but still report on it
        BHMAS_colouredOutput='FALSE'
        cecho lr "\n " B "BHMAS_colouredOutput" uB " variable must be set either to " ly "TRUE" lr " or to " ly "FALSE"
        mustReturn='FALSE'
    fi
    if [ "$BHMAS_useRationalApproxFiles" != 'TRUE' ] && [ "$BHMAS_useRationalApproxFiles" != 'FALSE' ]; then
        cecho lr "\n " B "BHMAS_useRationalApproxFiles" uB " variable must be set either to " ly "TRUE" lr " or to " ly "FALSE"
        mustReturn='FALSE'
    fi
    if [ "$BHMAS_walltime" != '' ] && [[ ! $BHMAS_walltime =~ ^([0-9]+-)?[0-9]{1,2}:[0-9]{2}:[0-9]{2}$ ]]; then
        cecho lr "\n " B "BHMAS_walltime" uB " variable format invalid. Correct format: " ly "days-hours:min:sec" lr " or " ly "hours:min:sec"
        mustReturn='FALSE'
    fi
    if [ "$BHMAS_GPUsPerNode" != '' ] && [[ ! $BHMAS_GPUsPerNode =~ ^[1-9]+$ ]]; then
        cecho lr "\n " B "BHMAS_GPUsPerNode" uB " variable format invalid. It has to be a " ly "positive integer" lr " number."
        mustReturn='FALSE'
    fi
    if [ "$BHMAS_acceptanceColumn" != '' ] && [[ ! $BHMAS_acceptanceColumn =~ ^[1-9]+$ ]]; then
        cecho lr "\n " B "BHMAS_acceptanceColumn" uB " variable format invalid. It has to be a " ly "positive integer" lr " number."
        mustReturn='FALSE'
    fi

    #If variables remained in arrays, print error
    if [ ${#variablesThatMustBeNotEmpty[@]} -ne 0 ]; then
        cecho "\n " ly "The following variable(s) must be " B "set" uB " and " B "not empty" uB ":\n"
        for variable in "${variablesThatMustBeNotEmpty[@]}"; do
            cecho lo "   " B "$variable"
        done
        mustReturn='FALSE'
    fi
    if [ ${#variablesThatMustBeDeclared[@]} -ne 0 ]; then
        cecho "\n " ly "The following variable(s) must be " B "declared" uB ":\n"
        for variable in "${variablesThatMustBeDeclared[@]}"; do
            cecho lo "   " B "$variable"
        done
        mustReturn='FALSE'
    fi
    if [ ${#variablesThatIfNotEmptyMustNotEndWithSlash[@]} -ne 0 ]; then
        cecho "\n " ly "The following variable(s) must " B "not end with '/'" uB ":\n"
        for variable in "${variablesThatIfNotEmptyMustNotEndWithSlash[@]}"; do
            cecho lo "   " B "$variable"
        done
        mustReturn='FALSE'
    fi


    #Define dependent additional variables
    if [ "$BHMAS_hmcGlobalPath" != '' ]; then
        HMC_FILENAME="${BHMAS_hmcGlobalPath##*/}"
    fi
    if [ "$BHMAS_inverterGlobalPath" != '' ]; then
        INVERTER_FILENAME="${BHMAS_inverterGlobalPath##*/}"
    fi

    #Decide whether to return or to exit
    if [ $mustReturn = 'TRUE' ]; then
        return
    else
        cecho lr "\n Please set the above variables properly and run " B "BaHaMAS" uB " again.\n"
        exit -1
    fi
}


# Make logical checks on variables that must be necessarily set only in some cases and therefore not always used
# EXAMPLE: If user wants only to produce confs, INVERTER_FILENAME can be unset
# Checks also existence directories/files depending on what BaHaMAS should do
function CheckBaHaMASVariablesAndExistenceOfFilesAndFoldersDependingOnUserCase()
{
    local index variable option variablesThatMustBeNotEmpty jobsNeededVariables schedulerVariables\
          neededFolders neededFiles rationalApproxFolder rationalApproxFiles
    mustReturn='TRUE'
    jobsNeededVariables=(BHMAS_inputFilename  BHMAS_outputFilename  BHMAS_hmcGlobalPath  BHMAS_jobScriptPrefix  BHMAS_jobScriptFolderName)
    schedulerVariables=(BHMAS_GPUsPerNode  BHMAS_walltime  BHMAS_userEmail)
    variablesThatMustBeNotEmpty=(BHMAS_submitDiskGlobalPath  BHMAS_runDiskGlobalPath  BHMAS_projectSubpath)
    neededFolders=( "$BHMAS_submitDiskGlobalPath" "${BHMAS_submitDiskGlobalPath}/$BHMAS_projectSubpath" )
    if [ "$BHMAS_submitDiskGlobalPath" != "$BHMAS_runDiskGlobalPath" ]; then
        neededFolders+=( "$BHMAS_runDiskGlobalPath" "${BHMAS_runDiskGlobalPath}/$BHMAS_projectSubpath" )
    fi
    neededFiles=()
    rationalApproxFolder=()
    rationalApproxFiles=()

    #If user wants to read the rational approximation from file check relative variables
    if [ $BHMAS_useRationalApproxFiles = 'TRUE' ]; then
        jobsNeededVariables+=( BHMAS_rationalApproxGlobalPath
                               BHMAS_approxHeatbathFilename
                               BHMAS_approxMDFilename
                               BHMAS_approxMetropolisFilename )
        rationalApproxFolder+=( "$BHMAS_rationalApproxGlobalPath" )
        rationalApproxFiles+=( "${BHMAS_rationalApproxGlobalPath}/$BHMAS_approxHeatbathFilename"
                               "${BHMAS_rationalApproxGlobalPath}/$BHMAS_approxMDFilename"
                               "${BHMAS_rationalApproxGlobalPath}/$BHMAS_approxMetropolisFilename" )
    fi

    #Check variables depending on BaHaMAS invocation
    if [ $SUBMIT = 'TRUE' ]; then
        option="$(cecho "with the " B "--submit")"
        variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]}  ${schedulerVariables[@]}
                                       BHMAS_thermConfsGlobalPath )
        neededFolders+=( "$BHMAS_thermConfsGlobalPath" ${rationalApproxFolder[@]} )
        neededFiles+=( "$BHMAS_hmcGlobalPath" ${rationalApproxFiles[@]} )

    elif [ $SUBMITONLY = 'TRUE' ]; then
        option="$(cecho "with the " B "--submitonly")"
        variablesThatMustBeNotEmpty+=( BHMAS_inputFilename
                                       BHMAS_jobScriptPrefix
                                       BHMAS_jobScriptFolderName
                                       BHMAS_thermConfsGlobalPath )
        neededFolders+=( "$BHMAS_thermConfsGlobalPath" ${rationalApproxFolder[@]} )
        neededFiles+=( "$BHMAS_hmcGlobalPath" ${rationalApproxFiles[@]} )

    elif [ $THERMALIZE = 'TRUE' ]; then
        option="$(cecho "with the " B "--thermalize")"
        variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]} ${schedulerVariables[@]}
                                       BHMAS_thermConfsGlobalPath )
        neededFolders+=( "$BHMAS_thermConfsGlobalPath" ${rationalApproxFolder[@]} )
        neededFiles+=( "$BHMAS_hmcGlobalPath" ${rationalApproxFiles[@]} )

    elif [ $CONTINUE = 'TRUE' ]; then
        option="$(cecho "with the " B "--continue")"
        variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]}  ${schedulerVariables[@]} )
        neededFiles+=( ${rationalApproxFolder[@]} )
        neededFiles+=( "$BHMAS_hmcGlobalPath" ${rationalApproxFiles[@]} )

    elif [ $CONTINUE_THERMALIZATION = 'TRUE' ]; then
        option="$(cecho "with the " B "--continueThermalization")"
        variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]} ${schedulerVariables[@]}
                                       BHMAS_thermConfsGlobalPath )
        neededFolders+=( "$BHMAS_thermConfsGlobalPath" ${rationalApproxFolder[@]} )
        neededFiles+=( "$BHMAS_hmcGlobalPath" ${rationalApproxFiles[@]} )

    elif [ $ACCRATE_REPORT = 'TRUE' ]; then
        option="$(cecho "with the " B "--accRateReport")"
        variablesThatMustBeNotEmpty+=( BHMAS_acceptanceColumn  BHMAS_outputFilename )

    elif [ $CLEAN_OUTPUT_FILES = 'TRUE' ]; then
        option="$(cecho "with the " B "--cleanOutputFiles")"
        variablesThatMustBeNotEmpty+=( BHMAS_outputFilename )

    elif [ $COMPLETE_BETAS_FILE = 'TRUE' ]; then
        option="$(cecho "with the " B "--completeBetasFile")"

    elif [ $UNCOMMENT_BETAS = 'TRUE' ]; then
        option="$(cecho "with the " B "--uncommentBetas")"

    elif [ $COMMENT_BETAS = 'TRUE' ]; then
        option="$(cecho "with the " B "--commentBetas")"

    elif [ $INVERT_CONFIGURATIONS = 'TRUE' ]; then
        option="$(cecho "with the " B "--invertConfigurations")"
        variablesThatMustBeNotEmpty+=( BHMAS_jobScriptPrefix
                                       BHMAS_jobScriptFolderName
                                       BHMAS_inverterGlobalPath
                                       ${schedulerVariables[@]} )
        neededFiles+=( "$BHMAS_inverterGlobalPath" )

    elif [ $LISTSTATUS = 'TRUE' ]; then
        option="$(cecho "with the " B "--liststatus")"
        variablesThatMustBeNotEmpty+=( BHMAS_inputFilename
                                       BHMAS_outputFilename
                                       BHMAS_acceptanceColumn )

    elif [ $CALL_DATABASE = 'TRUE' ]; then
        option="$(cecho "with the " B "--dataBase")"
        variablesThatMustBeNotEmpty+=( BHMAS_inputFilename
                                       BHMAS_outputFilename
                                       BHMAS_acceptanceColumn
                                       BHMAS_databaseGlobalPath
                                       BHMAS_databaseFilename )
        neededFolders+=( "$BHMAS_databaseGlobalPath" )
        neededFiles+=( "${BHMAS_databaseGlobalPath}/*$BHMAS_databaseFilename" )

    else
        option='without any mutually exclusive'
        variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]} ${schedulerVariables[@]}
                                       BHMAS_thermConfsGlobalPath )
        neededFolders+=( "$BHMAS_thermConfsGlobalPath" ${rationalApproxFolder[@]} )
        neededFiles+=( "$BHMAS_hmcGlobalPath" ${rationalApproxFiles[@]} )
    fi

    #Check if variables are defined and not empty
    for index in "${!variablesThatMustBeNotEmpty[@]}"; do
        if [ -n "${!variablesThatMustBeNotEmpty[$index]:+x}" ]; then
            unset -v 'variablesThatMustBeNotEmpty[$index]'
        fi
    done

    #If variables remained, print error otherwise check needed files/folders
    if [ ${#variablesThatMustBeNotEmpty[@]} -ne 0 ]; then
        cecho "\n " lo "To run " B "BaHaMAS" uB " $option "\
              lo "option, the following " ly "variable(s)" lo " must be " B "set" uB " and " B "not empty" uB ":\n"
        for variable in "${variablesThatMustBeNotEmpty[@]}"; do
            cecho ly "   " B "$variable"
        done
        cecho lr "\n Please set the above variables properly and run " B "BaHaMAS" uB " again.\n"
        exit -1
    else
        for index in "${!neededFolders[@]}"; do
            if [ -d "${neededFolders[$index]}" ]; then
                unset -v 'neededFolders[$index]'
            fi
        done
        for index in "${!neededFiles[@]}"; do
            #use stat in if instead of [ -f ] since we have a glob * in name (for database)
            if stat -t ${neededFiles[$index]} >/dev/null 2>&1; then
                unset -v 'neededFiles[$index]'
            fi
        done
    fi

    #If required files/folders were not found, print error and exit
    if [ ${#neededFolders[@]} -ne 0 ] || [ ${#neededFiles[@]} -ne 0 ]; then
        cecho "\n " lo "To run " B "BaHaMAS" uB " $option "\
              lo "option, the following specified " lb B "folder(s)" uB lo " or " wg "file(s)" lo " must " B "exist" uB ":\n"
        for variable in "${neededFolders[@]}"; do
            cecho lb "   " B "$variable"
        done
        for variable in "${neededFiles[@]}"; do
            cecho wg "   $variable"
        done
        cecho lr "\n Please check the path variables in the " B "BaHaMAS" uB " setup and run the program again.\n"
        exit -1
    fi
}


#Make final additional checks on paths to beta folders
function CheckBetaFoldersPathsVariables()
{
    if [ $HOME_DIR_WITH_BETAFOLDERS != "$(pwd)" ]; then
        cecho "\n"\
              lr " Constructed path to directory containing beta folders\n"\
              ly "   $HOME_DIR_WITH_BETAFOLDERS"\
              lr " does not match the actual position"\
              ly "   $(pwd)"\
              lr " Aborting...\n"
        exit -1
    fi
    if [ ! -d $WORK_DIR_WITH_BETAFOLDERS ]; then
        cecho "\n"\
              lr " Constructed path to directory containing beta folders on scratch\n"\
              ly "   $WORK_DIR_WITH_BETAFOLDERS"\
              lr " seems not to exist! Aborting...\n"
        exit -1
    fi
}
