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
        if [[ $variable != 'BHMAS_coloredOutput' ]]; then
            commandToBeExecuted+=" '${variable}:' $index 3 '${userVariables[$variable]}'  $index $variableNameFieldLength $variableValueFieldLength 0 "
            (( index++ )) || true
        fi
    done
    #Display main dialog box
    FireUpTheDialogBoxStoringResultAndActingAccordingly\
        __static__ParseSetupResultAndFillInUserVariablesArray\
        AbortSetupProcess
}


MakeFunctionsDefinedInThisFileReadonly
