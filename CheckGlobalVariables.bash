#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function CheckUserDefinedVariables(){
    local variablesThatMustBeNotEmpty\
          variablesThatMustBeTrueOrFalse\
          variablesThatMustBeDeclared index variable
    variablesThatMustBeNotEmpty=( USER_MAIL
                                  HMC_BUILD_PATH
                                  HOME_DIR
                                  WORK_DIR
                                  GPU_PER_NODE
                                  JOBSCRIPT_LOCALFOLDER
                                  SIMULATION_PATH
                                  HMC_FILENAME
                                  INPUTFILE_NAME
                                  JOBSCRIPT_PREFIX
                                  OUTPUTFILE_NAME
                                  ACCEPTANCE_COLUMN
                                  PROJECT_DATABASE_FILENAME
                                  PROJECT_DATABASE_DIRECTORY
                                  SRUN_COMMANDSFILE_FOR_INVERSION
                                  INVERTER_FILENAME
                                  THERMALIZED_CONFIGURATIONS_PATH
                                  HMC_GLOBALPATH
                                  INVERTER_GLOBALPATH )
    variablesThatMustBeTrueOrFalse=( BaHaMAS_colouredOutput )
    variablesThatMustBeDeclared=( FILE_WITH_WHICH_NODES_TO_EXCLUDE
                                  RATIONAL_APPROXIMATIONS_PATH
                                  APPROX_HEATBATH_NAME
                                  APPROX_MD_NAME
                                  APPROX_METROPOLIS_NAME )

    #Check variables and unset them if they are fine
    for index in "${!variablesThatMustBeNotEmpty[@]}"; do
        if [ -n "${!variablesThatMustBeNotEmpty[$index]:+x}" ]; then
            #Variable set and not empty
            unset -v 'variablesThatMustBeNotEmpty[$index]'
        else
            #Variable unset or set but empty
            continue
        fi
    done
    for index in "${!variablesThatMustBeTrueOrFalse[@]}"; do
        if [ "${!variablesThatMustBeTrueOrFalse[$index]}" = 'TRUE' ] || [ "${!variablesThatMustBeTrueOrFalse[$index]}" = 'FALSE' ]; then
            #Variable ok
            unset -v 'variablesThatMustBeTrueOrFalse[$index]'
        else
            #Variable wrong
            continue
        fi
    done
    for index in "${!variablesThatMustBeDeclared[@]}"; do
        if [ -n "${!variablesThatMustBeDeclared[$index]+x}" ]; then
            #Variable set
            unset -v 'variablesThatMustBeDeclared[$index]'
        else
            #Variable unset
            continue
        fi
    done

    #Since in the following we use cecho which rely on the variable "BaHaMAS_colouredOutput",
    #if this was wrongly set, let us set it to 'FALSE' but still report on it
    if ElementInArray BaHaMAS_colouredOutput ${variablesThatMustBeTrueOrFalse[@]}; then
        BaHaMAS_colouredOutput='FALSE'
    fi

    #If variables remained, print error and exit
    if [ ${#variablesThatMustBeNotEmpty[@]} -ne 0 ]; then
        cecho "\n " ly "The following variable(s) must be " B "set" uB " and " B "not empty" uB ":\n"
        for variable in "${variablesThatMustBeNotEmpty[@]}"; do
            cecho lo "   " B "$variable"
        done
    fi
    if [ ${#variablesThatMustBeTrueOrFalse[@]} -ne 0 ]; then
        cecho "\n " ly "The following variable(s) must be set either to " B "TRUE" uB " or to " B "FALSE" uB ":\n"
        for variable in "${variablesThatMustBeTrueOrFalse[@]}"; do
            cecho lo "   " B "$variable"
        done
    fi
    if [ ${#variablesThatMustBeDeclared[@]} -ne 0 ]; then
        cecho "\n " ly "The following variable(s) must be " B "declared" uB ":\n"
        for variable in "${variablesThatMustBeDeclared[@]}"; do
            cecho lo "   " B "$variable"
        done
    fi

    if [ $(( ${#variablesThatMustBeNotEmpty[@]} + ${#variablesThatMustBeTrueOrFalse[@]} + ${#variablesThatMustBeDeclared[@]})) -eq 0 ]; then
        return
    else
        cecho lr "\n\n Please set properly the user variables and run " B "BaHaMAS" uB " again.\n"
        exit -1
    fi

}
