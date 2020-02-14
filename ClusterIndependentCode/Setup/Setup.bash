#
#  Copyright (c)
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

#Load needed files
for fileToBeSourced in "CommonFunctionality" "SetupDialog" "SetupWhiptail"; do
    source "${BHMAS_repositoryTopLevelPath}/ClusterIndependentCode/Setup/${fileToBeSourced}.bash" || exit $BHMAS_fatalBuiltin
done && unset -v 'fileToBeSourced'


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
            if [ ${#occurences[@]} -eq 1 ]; then
                userVariables[$variable]=${occurences[0]##*=}
            else
                unableToRecover+=( $variable )
            fi
        done
        if [ ${#unableToRecover[@]} -ne 0 ]; then
            local warningString;
            Warning -N "Unable to recover the previously set value for the following variable(s):"
            for variable in ${unableToRecover[@]}; do
                Warning -n -e -N " - " lo "$variable"
            done
            Warning -n -e -N "Maybe they were missing just because recently introduced in BaHaMAS."
            Warning -n -e -N "Press enter to continue (and to let the setup add them)."; read
        fi
    fi
}

function __static__ProduceUserVariableFile()
{
    local backupFile variable
    backupFile="${filenameUserSetup}_$(date +%H%M%S)"
    if [ -f $filenameUserSetup ]; then
        mv $filenameUserSetup $backupFile || exit $BHMAS_fatalBuiltin
    fi
    cp $filenameTemplate $filenameUserSetup || exit $BHMAS_fatalBuiltin
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
        Fatal $BHMAS_fatalRequirement "Programs " emph "dialog" " and " emph "whitptail" " were not found, but they are required to run the " emph "BaHaMAS setup" ".\n"\
              "Consider to install any of them or read in the documentation how to make the BaHaMAS setup manually!"
    fi

    #Produce final setup file
    __static__ProduceUserVariableFile
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         __static__ReadVariablesFromTemplateFile\
         __static__FillInVariablesFromMaybeExistentUserSetup\
         __static__ProduceUserVariableFile\
         MakeInteractiveSetupAndCreateUserDefinedVariablesFile
