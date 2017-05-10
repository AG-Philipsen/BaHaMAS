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
    variablesThatMustBeNotEmpty=( USER_MAIL
                                  HOME_DIR
                                  WORK_DIR )
    variablesThatMustBeDeclared=( GPU_PER_NODE
                                  JOBSCRIPT_LOCALFOLDER
                                  SIMULATION_PATH
                                  INPUTFILE_NAME
                                  JOBSCRIPT_PREFIX
                                  OUTPUTFILE_NAME
                                  ACCEPTANCE_COLUMN
                                  PROJECT_DATABASE_FILENAME
                                  PROJECT_DATABASE_DIRECTORY
                                  THERMALIZED_CONFIGURATIONS_PATH
                                  HMC_GLOBALPATH
                                  INVERTER_GLOBALPATH
                                  FILE_WITH_WHICH_NODES_TO_EXCLUDE
                                  RATIONAL_APPROXIMATIONS_PATH
                                  APPROX_HEATBATH_NAME
                                  APPROX_MD_NAME
                                  APPROX_METROPOLIS_NAME
                                  CLUSTER_PARTITION
                                  CLUSTER_NODE
                                  CLUSTER_CONSTRAINT
                                  CLUSTER_GENERIC_RESOURCE
                                  WALLTIME )
    variablesThatIfNotEmptyMustNotEndWithSlash=(HOME_DIR
                                                WORK_DIR
                                                SIMULATION_PATH
                                                PROJECT_DATABASE_DIRECTORY
                                                THERMALIZED_CONFIGURATIONS_PATH
                                                HMC_GLOBALPATH
                                                INVERTER_GLOBALPATH
                                                RATIONAL_APPROXIMATIONS_PATH )

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
    if [ "$BaHaMAS_colouredOutput" != 'TRUE' ] && [ "$BaHaMAS_colouredOutput" != 'FALSE' ]; then
        #Since in the following we use cecho which rely on the variable "BaHaMAS_colouredOutput",
        #if this was wrongly set, let us set it to 'FALSE' but still report on it
        BaHaMAS_colouredOutput='FALSE'
        cecho lr "\n " B "BaHaMAS_colouredOutput" uB " variable must be set either to " ly "TRUE" lr " or to " ly "FALSE"
        mustReturn='FALSE'
    fi
    if [ "$USE_RATIONAL_APPROXIMATION_FILE" != 'TRUE' ] && [ "$USE_RATIONAL_APPROXIMATION_FILE" != 'FALSE' ]; then
        cecho lr "\n " B "USE_RATIONAL_APPROXIMATION_FILE" uB " variable must be set either to " ly "TRUE" lr " or to " ly "FALSE"
        mustReturn='FALSE'
    fi
    if [ "$WALLTIME" != '' ] && [[ ! $WALLTIME =~ ^([0-9]+-)?[0-9]{1,2}:[0-9]{2}:[0-9]{2}$ ]]; then
        cecho lr "\n " B "WALLTIME" uB " variable format invalid. Correct format: " ly "days-hours:min:sec" lr " or " ly "hours:min:sec"
        mustReturn='FALSE'
    fi
    if [ "$GPU_PER_NODE" != '' ] && [[ ! $GPU_PER_NODE =~ ^[1-9]+$ ]]; then
        cecho lr "\n " B "GPU_PER_NODE" uB " variable format invalid. It has to be a " ly "positive integer" lr " number."
        mustReturn='FALSE'
    fi
    if [ "$ACCEPTANCE_COLUMN" != '' ] && [[ ! $ACCEPTANCE_COLUMN =~ ^[1-9]+$ ]]; then
        cecho lr "\n " B "ACCEPTANCE_COLUMN" uB " variable format invalid. It has to be a " ly "positive integer" lr " number."
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
    if [ "$HMC_GLOBALPATH" != '' ]; then
        HMC_FILENAME="${HMC_GLOBALPATH##*/}"
    fi
    if [ "$INVERTER_GLOBALPATH" != '' ]; then
        INVERTER_FILENAME="${INVERTER_GLOBALPATH##*/}"
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
    jobsNeededVariables=(INPUTFILE_NAME  OUTPUTFILE_NAME  HMC_GLOBALPATH  JOBSCRIPT_PREFIX  JOBSCRIPT_LOCALFOLDER)
    schedulerVariables=(GPU_PER_NODE  WALLTIME  USER_MAIL)
    variablesThatMustBeNotEmpty=(HOME_DIR  WORK_DIR  SIMULATION_PATH)
    neededFolders=( "$HOME_DIR" "${HOME_DIR}/$SIMULATION_PATH"  "$WORK_DIR" "${WORK_DIR}/$SIMULATION_PATH")
    neededFiles=()
    rationalApproxFolder=()
    rationalApproxFiles=()

    #If user wants to read the rational approximation from file check relative variables
    if [ $USE_RATIONAL_APPROXIMATION_FILE = 'TRUE' ]; then
        jobsNeededVariables+=( RATIONAL_APPROXIMATIONS_PATH
                               APPROX_HEATBATH_NAME
                               APPROX_MD_NAME
                               APPROX_METROPOLIS_NAME )
        rationalApproxFolder+=( "$RATIONAL_APPROXIMATIONS_PATH" )
        rationalApproxFiles+=( "${RATIONAL_APPROXIMATIONS_PATH}/$APPROX_HEATBATH_NAME"
                               "${RATIONAL_APPROXIMATIONS_PATH}/$APPROX_MD_NAME"
                               "${RATIONAL_APPROXIMATIONS_PATH}/$APPROX_METROPOLIS_NAME" )
    fi

    #Check variables depending on BaHaMAS invocation
    if [ $SUBMIT = 'TRUE' ]; then
        option="$(cecho "with the " B "--submit")"
        variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]}  ${schedulerVariables[@]}
                                       THERMALIZED_CONFIGURATIONS_PATH )
        neededFolders+=( "$THERMALIZED_CONFIGURATIONS_PATH" ${rationalApproxFolder[@]} )
        neededFiles+=( "$HMC_GLOBALPATH" ${rationalApproxFiles[@]} )

    elif [ $SUBMITONLY = 'TRUE' ]; then
        option="$(cecho "with the " B "--submitonly")"
        variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]} ${schedulerVariables[@]}
                                       THERMALIZED_CONFIGURATIONS_PATH )
        neededFolders+=( "$THERMALIZED_CONFIGURATIONS_PATH" ${rationalApproxFolder[@]} )
        neededFiles+=( "$HMC_GLOBALPATH" ${rationalApproxFiles[@]} )

    elif [ $THERMALIZE = 'TRUE' ]; then
        option="$(cecho "with the " B "--thermalize")"
        variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]} ${schedulerVariables[@]}
                                       THERMALIZED_CONFIGURATIONS_PATH )
        neededFolders+=( "$THERMALIZED_CONFIGURATIONS_PATH" ${rationalApproxFolder[@]} )
        neededFiles+=( "$HMC_GLOBALPATH" ${rationalApproxFiles[@]} )

    elif [ $CONTINUE = 'TRUE' ]; then
        option="$(cecho "with the " B "--continue")"
        variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]}  ${schedulerVariables[@]} )
        neededFiles+=( ${rationalApproxFolder[@]} )
        neededFiles+=( "$HMC_GLOBALPATH" ${rationalApproxFiles[@]} )

    elif [ $CONTINUE_THERMALIZATION = 'TRUE' ]; then
        option="$(cecho "with the " B "--continueThermalization")"
        variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]} ${schedulerVariables[@]}
                                       THERMALIZED_CONFIGURATIONS_PATH )
        neededFolders+=( "$THERMALIZED_CONFIGURATIONS_PATH" ${rationalApproxFolder[@]} )
        neededFiles+=( "$HMC_GLOBALPATH" ${rationalApproxFiles[@]} )

    elif [ $ACCRATE_REPORT = 'TRUE' ]; then
        option="$(cecho "with the " B "--accRateReport")"
        variablesThatMustBeNotEmpty+=( ACCEPTANCE_COLUMN  OUTPUTFILE_NAME )

    elif [ $CLEAN_OUTPUT_FILES = 'TRUE' ]; then
        option="$(cecho "with the " B "--cleanOutputFiles")"
        variablesThatMustBeNotEmpty+=( OUTPUTFILE_NAME )

    elif [ $COMPLETE_BETAS_FILE = 'TRUE' ]; then
        option="$(cecho "with the " B "--completeBetasFile")"

    elif [ $UNCOMMENT_BETAS = 'TRUE' ]; then
        option="$(cecho "with the " B "--uncommentBetas")"

    elif [ $COMMENT_BETAS = 'TRUE' ]; then
        option="$(cecho "with the " B "--commentBetas")"

    elif [ $INVERT_CONFIGURATIONS = 'TRUE' ]; then
        option="$(cecho "with the " B "--invertConfigurations")"
        variablesThatMustBeNotEmpty+=( JOBSCRIPT_PREFIX
                                       JOBSCRIPT_LOCALFOLDER
                                       INVERTER_GLOBALPATH
                                       ${schedulerVariables[@]} )
        neededFiles+=( "$INVERTER_GLOBALPATH" )

    elif [ $LISTSTATUS = 'TRUE' ]; then
        option="$(cecho "with the " B "--liststatus")"
        variablesThatMustBeNotEmpty+=( INPUTFILE_NAME
                                       OUTPUTFILE_NAME
                                       ACCEPTANCE_COLUMN )

    elif [ $CALL_DATABASE = 'TRUE' ]; then
        option="$(cecho "with the " B "--dataBase")"
        variablesThatMustBeNotEmpty+=( INPUTFILE_NAME
                                       OUTPUTFILE_NAME
                                       ACCEPTANCE_COLUMN
                                       PROJECT_DATABASE_DIRECTORY
                                       PROJECT_DATABASE_FILENAME )
        neededFolders+=( "$PROJECT_DATABASE_DIRECTORY" )
        neededFiles+=( "${PROJECT_DATABASE_DIRECTORY}/$PROJECT_DATABASE_FILENAME" )

    else
        option='without any mutually exclusive'
        variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]} ${schedulerVariables[@]}
                                       THERMALIZED_CONFIGURATIONS_PATH )
        neededFolders+=( "$THERMALIZED_CONFIGURATIONS_PATH" ${rationalApproxFolder[@]} )
        neededFiles+=( "$HMC_GLOBALPATH" ${rationalApproxFiles[@]} )
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
            if [ -f "${neededFiles[$index]}" ]; then
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
