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
    local oldIFS entry index
    #echo "$resultOfDialogBox"
    oldIFS=$IFS; IFS="|"; index=0
    for entry in $resultOfDialogBox; do
        userVariables[${variableNames[$index]}]="$entry"
        (( index++ )) || true
    done; IFS=$oldIFS
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
    local filenameUserSetup filenameTemplate\
          dialogDimensions dialogHeight dialogWidth formHeight\
          variableNameFieldLength variableValueFieldLength\
          formHeader commandToBeExecuted variable occurences\
          unableToRecover index variableName variableValue variableNames
    declare -A userVariables=()
    filenameUserSetup="$1"
    filenameTemplate="${filenameUserSetup/.bash/_template.bash}"
    #Read variables from template file
    for variable in $(awk '/^($|[#]+)/{next}{print $0}' "$filenameTemplate" | grep -o "BHMAS_.*"); do
        variableName=${variable%%=*}
        if [ $variableName = 'BHMAS_coloredOutput' ]; then #Treat it separately to use here cecho
            continue
        fi
        variableValue="$(sed "s/['\"]//g" <<< "${variable##*=}")"
        variableNames+=( $variableName ) #To be used later to keep names in order
        userVariables[$variableName]="$variableValue"
    done
    #Fill in variable names from maybe existent user setup
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
    #Start setting up colored output
    commandToBeExecuted="dialog --keep-tite --colors
                                --backtitle 'BaHaMAS setup'
                                --title 'BaHaMAS output'
                                --yesno '\nWould you like to activate \Zb\Z4co\Z5lo\Z1red\Zn output?' 6 60"
    __static__FireUpTheDialogBoxStoringResultAndActingAccordingly\
        "__static__SetColoredOutput TRUE"\
        "__static__SetColoredOutput FALSE"
    #Continue with BaHaMAS user variables
    exec 3>&1; dialogDimensions=$(dialog --print-maxsize 2>&1 1>&3); exec 3>&-
    dialogHeight=$(grep -o "[0-9]\+" <<< "$dialogDimensions" | head -n1 | awk '{print int(0.6*$1)}')
    dialogWidth=$(grep  -o "[0-9]\+" <<< "$dialogDimensions" | tail -n1 | awk '{print int(0.7*$1)}')
    formHeight=30 #Hard-coded since it seems there is an implicit maximum depending on the dialogHeight
    variableNameFieldLength=$(( $(LengthOfLongestEntryInArray ${variableNames[@]}) +8 ))
    variableValueFieldLength=200 #It should be enough
    formHeader='\n\ZbPlease, provide the following information (the content of a previous filled out variable can be accessed with the \Z5${nameOfTheVariable}\Z0 syntax):\Zn'
    commandToBeExecuted="dialog --keep-tite --colors --ok-label 'Configure BaHaMAS'
                                --cancel-label 'Abort setup'
                                --backtitle 'BaHaMAS setup'
                                --title 'BaHaMAS configuration'
                                --separator '|'
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
    #Produce final setup file
    __static__ProduceUserVariableFile

}
