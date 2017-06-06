#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function __static__AbortSetupProcess()
{
    cecho lr '\n BaHaMAS setup has been aborted! Consider to rerun it, if needed.\n'
    exit -1
}

function __static__SetColoredOutput()
{
    BHMAS_coloredOutput="$1"
    userVariables['BHMAS_coloredOutput']="$BHMAS_coloredOutput"
}

function __static__FireUpTheDialogBoxStoringResultAndActingAccordingly()
{
    local functionToBeCalledOnSuccess functionToBeCalledOnCancel\
          dialogOk dialogCancel dialogHelp dialogExtra\
          dialogItemHelp dialogEsc returnValue
    functionToBeCalledOnSuccess="$1"
    functionToBeCalledOnCancel="$2"
    dialogOk=0; dialogCancel=1; dialogHelp=2
    dialogExtra=3; dialogItemHelp=4; dialogEsc=255
    #Use new file descriptor to get dialog output
    exec 3>&1
    set +e
    resultOfDialogBox=$(eval $commandToBeExecuted 2>&1 1>&3)
    returnValue=$?
    set -e
    exec 3>&-
    case $returnValue in
        $dialogOk)
            $functionToBeCalledOnSuccess ;;
        $dialogCancel)
            $functionToBeCalledOnCancel ;;
        $dialogHelp)
            cecho o "\n INTERNAL: Help button pressed, but unexpected! Aborting...\n"
            exit -1 ;;
        $dialogExtra)
            cecho o "\n INTERNAL: Extra button pressed, but unexpected! Aborting...\n"
            exit -1 ;;
        $dialogItemHelp)
            cecho o "\n INTERNAL: Item-help button pressed, but unexpected! Aborting...\n"
            exit -1 ;;
        $dialogEsc)
            __static__AbortSetupProcess ;;
    esac
}

function __static__ParseSetupResultAndFillInUserVariablesArray()
{
    echo "$resultOfDialogBox"
}

function MakeInteractiveSetupAndCreateUserDefinedVariablesFile()
{
    BHMAS_coloredOutput='FALSE' #To use cecho
    local filenameUserSetup filenameTemplate\
          dialogDimensions dialogHeight dialogWidth formHeight\
          variableNameFieldLength variableValueFieldLength\
          formHeader commandToBeExecuted variable\
          index variableName variableValue variableNames
    declare -A userVariables=()
    filenameUserSetup="$1"
    filenameTemplate="${filenameUserSetup/.bash/_template.bash}"
    #Start setting up colored output
    commandToBeExecuted="dialog --keep-tite --yesno 'Would you like to activate colored output?' 5 50"
    __static__FireUpTheDialogBoxStoringResultAndActingAccordingly\
        "__static__SetColoredOutput TRUE"\
        "__static__SetColoredOutput FALSE"
    #Read variables from template file
    for variable in $(awk '/^($|[#]+)/{next}{print $0}' "$filenameTemplate" | grep -o "BHMAS_.*"); do
        variableName=${variable%%=*}
        variableValue="$(sed "s/['\"]//g" <<< "${variable##*=}")"
        variableNames+=( $variableName ) #To be used later to keep names in order
        userVariables[$variableName]="$variableValue"
    done
    #Fill in variable names from maybe existent user setup
    if [ -f "$filenameUserSetup" ]; then
        for variable in ${!userVariables[@]}; do
            #TODO: What about several formulations?!
            if [ $(awk '/^($|[#]+)/{next}{print $0}' "$filenameUserSetup" | grep -o "${variable}=.*" | wc -l) -eq 1 ]; then
                userVariables[$variable]="$(sed -n "s/^[^#].*${variable}=\(.*\)/\1/p" $filenameUserSetup | sed "s/['\"]//g")"
            else
                printf " WARNING: Unable to recover set value for variable \"$variable\"\n"
            fi
        done
    fi
    #Continue with BaHaMAS user variables
    exec 3>&1; dialogDimensions=$(dialog --print-maxsize 2>&1 1>&3); exec 3>&-
    dialogHeight=$(grep -o "[0-9]\+" <<< "$dialogDimensions" | head -n1 | awk '{print int(0.6*$1)}')
    dialogWidth=$(grep  -o "[0-9]\+" <<< "$dialogDimensions" | tail -n1 | awk '{print int(0.7*$1)}')
    formHeight=30 #Hard-coded since it seems there is an implicit maximum depending on the dialogHeight
    variableNameFieldLength=$(( $(LengthOfLongestEntryInArray ${variableNames[@]}) +8 ))
    variableValueFieldLength=200 #It should be enough
    formHeader='\nPlease, provide the following information (the content of a previous filled out variable can be accessed with the ${nameOfTheVariable} syntax):'
    commandToBeExecuted="dialog --keep-tite --clear --ok-label 'Configure'
                                --exit-label 'Abort'
                                --title 'BaHaMAS configuration'
                                --form '$formHeader'
                         $dialogHeight $dialogWidth $formHeight"
    #Complete dialog box command
    index=1
    for variable in ${variableNames[@]}; do
        if [ $variable != 'BHMAS_coloredOutput' ]; then
            commandToBeExecuted+=" '${variable}:' $index 3 '${userVariables[$variable]}'  $index $variableNameFieldLength $variableValueFieldLength 0 "
            (( index++ )) || true
        fi
    done
    #Display main dialog box
    __static__FireUpTheDialogBoxStoringResultAndActingAccordingly\
        __static__ParseSetupResultAndFillInUserVariablesArray\
        __static__AbortSetupProcess


}
