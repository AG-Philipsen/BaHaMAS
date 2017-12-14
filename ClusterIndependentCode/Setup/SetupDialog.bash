#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENSE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

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
    local commandToBeExecuted resultOfBox lines columns\
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
    lines=$(tput lines)
    columns=$(tput cols)
    dialogHeight=$((lines-16))
    dialogWidth=$((columns-10))
    formHeight=$((dialogHeight-23))
    variableNameFieldLength=$(( $(LengthOfLongestEntryInArray ${variableNames[@]}) +8 ))
    variableValueFieldLength=180 #It should be enough
    formHeader='\n
    \ZbPlease, provide the following information (the content of a previous filled out variable can be accessed with the \Z5${nameOfTheVariable}\Z0 syntax).\Zn\n\n
    Consider that \Z4NOT\Z0 all values of the variables must be provided and, in general, only some of them are needed to run BaHaMAS with a particular option.\n
    If a needed variable is left unset, you will be notified when you run BaHaMAS and you can rerun the setup to give the missing values.\n\n'
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


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         __static__ParseSetupResultAndFillInUserVariablesArray\
         MakeInteractiveSetupUsingDialog
