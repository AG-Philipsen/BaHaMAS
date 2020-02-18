#
#  Copyright (c) 2017,2020 Alessandro Sciarra
#
#  This file is part of BaHaMAS.
#
#  BaHaMAS is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  BaHaMAS is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with BaHaMAS. If not, see <http://www.gnu.org/licenses/>.
#

function __static__DisplayMenuBoxWithPresentVariablesAndActOnInput()
{
    local menuHeader index lines columns
    lines=$(tput lines)
    columns=$(tput cols)
    menuHeader='\n
    Please, provide the following information (the content of a previous filled out variable can be accessed with the ${nameOfTheVariable} syntax).\n\n
    Consider that NOT all values of the variables must be provided and, in general, only some of them are needed to run BaHaMAS with a particular option.\n
    If a needed variable is left unset, you will be notified when you run BaHaMAS and you can rerun the setup to give the missing values.\n\n'
    commandToBeExecuted="whiptail --ok-button 'Modify variable'
                                  --cancel-button 'Abort setup'
                                  --backtitle 'BaHaMAS setup'
                                  --title 'BaHaMAS configuration'
                                  --menu '$menuHeader'
                         $((lines-6)) $((columns-10)) $((lines-22))"
    #Complete dialog box command
    index=1
    for variable in ${variableNames[@]}; do
        if [ $variable != 'BHMAS_coloredOutput' ]; then
            commandToBeExecuted+=" '${variable}:' '${userVariables[$variable]}' "
            (( index++ )) || true
        fi
    done
    commandToBeExecuted+=" '' '' 'Configure BaHaMAS' 'Select this line to submit your modifications' "

    #Display main dialog box
    FireUpTheDialogBoxStoringResultAndActingAccordingly\
        "__static__DisplayFreeInputBoxAndSetGivenInputValue"\
        AbortSetupProcess
}

function __static__SetValueOfVariableObtainedFromUser()
{
    userVariables[${variableInputBox%?}]="$resultOfBox"
}

function __static__DisplayFreeInputBoxAndSetGivenInputValue()
{
    local variableInputBox inputHeader variable inputBoxLines
    variableInputBox="$resultOfBox"; inputBoxLines=8
    if [ "$variableInputBox" = "Configure BaHaMAS" ]; then
        return 0
    else
        inputHeader=''
        for variable in ${variableNames[@]}; do
            if [ $variable = ${variableInputBox%?} ]; then
                break
            else
                inputHeader+=" $variable\n"
                (( inputBoxLines++ )) || true
            fi
        done
        [ "$inputHeader" != '' ] && inputHeader="\n Possible variables to be used:\n\n$inputHeader"
        inputHeader+='\n\n Enter the value for the variable:'
        commandToBeExecuted="whiptail --title '${variableInputBox%?}'
                                      --backtitle 'BaHaMAS setup'
                                      --inputbox '$inputHeader'
                             $((inputBoxLines+5)) 78 ${userVariables[${variableInputBox%?}]//\$/\\\$}" #Escape $ sign to avoid evaluation of variable
        FireUpTheDialogBoxStoringResultAndActingAccordingly\
            __static__SetValueOfVariableObtainedFromUser\
            ""
        #Pop up again menu dialog
        __static__DisplayMenuBoxWithPresentVariablesAndActOnInput
    fi
}

function MakeInteractiveSetupUsingWhiptail()
{
    local commandToBeExecuted resultOfBox
    #Start setting up colored output
    commandToBeExecuted="whiptail --backtitle 'BaHaMAS setup'
                                  --title 'BaHaMAS output'
                                  --yesno '\n Would you like to activate colored output?' 8 50"
    FireUpTheDialogBoxStoringResultAndActingAccordingly\
        "SetColoredOutput TRUE"\
        "SetColoredOutput FALSE"
    #Continue with BaHaMAS user variables
    __static__DisplayMenuBoxWithPresentVariablesAndActOnInput
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         __static__DisplayMenuBoxWithPresentVariablesAndActOnInput\
         __static__SetValueOfVariableObtainedFromUser\
         __static__DisplayFreeInputBoxAndSetGivenInputValue\
         MakeInteractiveSetupUsingWhiptail
