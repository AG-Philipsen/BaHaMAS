#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function __static__ParseSetupResultAndFillInUserVariablesArray()
{
    local oldIFS entry index
    oldIFS=$IFS; IFS="|"; index=0
    for entry in $resultOfBox; do
        userVariables[${variableNames[$index]}]="$entry"
        (( index++ )) || true
    done; IFS=$oldIFS
}

function MakeInteractiveSetupUsingDialog()
{
    local commandToBeExecuted resultOfBox dialogDimensions\
          dialogHeight dialogWidth formHeight variableNameFieldLength\
          variableValueFieldLength formHeader index
    #Start setting up colored output
    commandToBeExecuted="dialog --keep-tite --colors
                                --backtitle 'BaHaMAS setup'
                                --title 'BaHaMAS output'
                                --yesno '\nWould you like to activate \Zb\Z4co\Z5lo\Z1red\Zn output?' 6 60"
    FireUpTheDialogBoxStoringResultAndActingAccordingly\
        "SetColoredOutput TRUE"\
        "SetColoredOutput FALSE"
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
    FireUpTheDialogBoxStoringResultAndActingAccordingly\
        __static__ParseSetupResultAndFillInUserVariablesArray\
        AbortSetupProcess
}
