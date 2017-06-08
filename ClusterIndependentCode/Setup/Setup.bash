#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/Setup/CommonFunctionality.bash   || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/Setup/SetupDialog.bash           || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/ClusterIndependentCode/Setup/SetupWhiptail.bash         || exit -2

function __static__ReadVariablesFromTemplateFile()
{
    local variable variableName variableValue
    for variable in $(awk '/^($|[#]+)/{next}{print $0}' "$filenameTemplate" | grep -o "BHMAS_.*"); do
        variableName=${variable%%=*}
        if [ $variableName = 'BHMAS_coloredOutput' ]; then #Treat it separately to use here cecho
            continue
        fi
        variableValue="$(sed "s/['\"]//g" <<< "${variable##*=}")"
        variableNames+=( $variableName ) #To be used later to keep names in order
        userVariables[$variableName]="$variableValue"
    done
}

function __static__FillInVariablesFromMaybeExistentUserSetup()
{
    local variable unableToRecover occurences
    if [ -f "$filenameUserSetup" ]; then
        BHMAS_coloredOutput=( $(sed -n "s/^[^#].*BHMAS_coloredOutput=\(.*\)/\1/p" $filenameUserSetup | sed "s/['\"]//g") )
        if [ ${#BHMAS_coloredOutput[@]} -ne 1 ]; then
            BHMAS_coloredOutput='FALSE'
        fi
        unableToRecover=()
        for variable in ${!userVariables[@]}; do
            #TODO: What about several formulations?!
            occurences=( $(sed -n "s/^[^#].*\(${variable}=.*\)/\1/p" $filenameUserSetup | sed "s/['\"]//g") )
            if [ ${#occurences[@]} -le 1 ]; then
                userVariables[$variable]=${occurences[0]##*=}
            else
                unableToRecover+=( $variable )
            fi
        done
        if [ ${#unableToRecover[@]} -ne 0 ]; then
            cecho B ly "\n " U "WARNING" uU ":" uB " Unable to recover the previously set value for the following variable(s):"
            for variable in ${unableToRecover[@]}; do
                cecho ly "           - " lo "$variable"
            done
        fi
    fi
}

function __static__ProduceUserVariableFile()
{
    local backupFile variable
    backupFile="${filenameUserSetup}_$(date +%H%M%S)"
    if [ -f $filenameUserSetup ]; then
        mv $filenameUserSetup $backupFile || exit -2
    fi
    cp $filenameTemplate $filenameUserSetup || exit -2
    #Delete commented lines from user file
    sed -i '/^[[:space:]]*[#]/d' $filenameUserSetup
    #Set variables
    for variable in ${!userVariables[@]}; do
        if [ $(grep -o '\$' <<< "${userVariables[$variable]}" | wc -l) -eq 0 ]; then
            sed -i "s#\(^.*${variable}=\).*#\1'${userVariables[$variable]}'#g" $filenameUserSetup
        else
            sed -i "s#\(^.*${variable}=\).*#\1\"${userVariables[$variable]}\"#g" $filenameUserSetup
        fi
    done
    rm -f $backupFile
}

function MakeInteractiveSetupAndCreateUserDefinedVariablesFile()
{
    local filenameUserSetup filenameTemplate variableNames
    declare -A userVariables=()
    filenameUserSetup="$1"
    filenameTemplate="${filenameUserSetup/.bash/_template.bash}"
    variableNames=()

    __static__ReadVariablesFromTemplateFile
    __static__FillInVariablesFromMaybeExistentUserSetup #Here 'BHMAS_coloredOutput' is defined as global

    if hash dialog 2>/dev/null; then
        MakeInteractiveSetupUsingDialog
    elif hash whiptail 2>/dev/null; then
        MakeInteractiveSetupUsingWhiptail
    else
        cecho lr "\n Programs " emph "dialog" " and " emph "whitptail" " were not found, but they are required to run the " B "BaHaMAS setup" uB ".\n"\
              " Consider to install any of them or read in the documentation how to make the BaHaMAS setup manually! Aborting...\n"; exit -1
    fi

    #Produce final setup file
    __static__ProduceUserVariableFile
}
