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

function AbortSetupProcess()
{
    Fatal ${BHMAS_fatalGeneric} 'BaHaMAS setup has been aborted! Consider to rerun it, if needed.'
}

function SetColoredOutput()
{
    BHMAS_coloredOutput="$1"
    userVariables['BHMAS_coloredOutput']="${BHMAS_coloredOutput}"
}

function FireUpTheDialogBoxStoringResultAndActingAccordingly()
{
    local functionToBeCalledOnSuccess functionToBeCalledOnCancel\
          dialogOk dialogCancel dialogHelp dialogExtra\
          dialogItemHelp dialogEsc returnValue
    functionToBeCalledOnSuccess="$1"
    functionToBeCalledOnCancel="$2"
    dialogOk=0; dialogCancel=1; dialogEsc=255
    dialogHelp=2; dialogExtra=3; dialogItemHelp=4 #These only in dialog not in whiptail
    #Use new file descriptor to get dialog output
    exec 3>&1
    set +e
    resultOfBox="$(eval ${commandToBeExecuted} 2>&1 1>&3)"
    returnValue=$?
    set -e
    exec 3>&-
    case ${returnValue} in
        ${dialogOk})
            ${functionToBeCalledOnSuccess} ;;
        ${dialogCancel})
            ${functionToBeCalledOnCancel} ;;
        ${dialogHelp})
            Internal "Help button pressed, but unexpected!" ;;
        ${dialogExtra})
            Internal "Extra button pressed, but unexpected!" ;;
        ${dialogItemHelp})
            Internal "Item-help button pressed, but unexpected!" ;;
        ${dialogEsc})
            AbortSetupProcess ;;
    esac
}


MakeFunctionsDefinedInThisFileReadonly
