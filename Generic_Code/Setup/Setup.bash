#
#  Copyright (c) 2017-2018,2020 Alessandro Sciarra
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
    source "${BHMAS_repositoryTopLevelPath}/Generic_Code/Setup/${fileToBeSourced}.bash" || exit ${BHMAS_fatalBuiltin}
done && unset -v 'fileToBeSourced'

function __static__ReadVariablesFromTemplateFile()
{
    local line variableName variableValue
    while read -r line; do
        if [[ ! ${line} =~ ^[[:space:]]*(readonly )?BHMAS_ ]]; then
            continue
        else
            line=$(grep -o "BHMAS_.*" <<< "${line}")
        fi
        variableName=${line%%=*}
        if [[ ${variableName} = 'BHMAS_coloredOutput' ]]; then #Treat it separately to use here cecho
            continue
        fi
        variableValue="$(sed "s/['\"]//g" <<< "${line##*=}")"
        #Perform command substitution at setup time
        if [[ ${variableValue} =~ ^\$\((.*)\)$ ]]; then
            set +e
            variableValue="$(${BASH_REMATCH[1]} 2>&1)"
            if [[ $? -ne 0 ]]; then
                variableValue="\$(${BASH_REMATCH[1]})"
            fi
            set -e
        fi
        variableNames+=( ${variableName} ) #To be used later to keep names in order
        userVariables[${variableName}]="${variableValue}"
    done < "${filenameTemplate}"
}

function __static__FillInVariablesFromMaybeExistentUserSetup()
{
    local variable unableToRecover occurences
    if [[ -f "${BHMAS_userSetupFile}" ]]; then
        BHMAS_coloredOutput=( $(sed -n "s/^[^#].*BHMAS_coloredOutput=\(.*\)/\1/p" ${BHMAS_userSetupFile} | sed "s/['\"]//g") )
        if [[ ${#BHMAS_coloredOutput[@]} -ne 1 ]]; then
            BHMAS_coloredOutput='FALSE'
        fi
        unableToRecover=()
        #TODO: What about several formulations?!
        for variable in ${!userVariables[@]}; do
            #To consider spaces in variable value, use readarray here and split only on endline
            readarray -t occurences < <(sed -n "s/^[^#].*\(${variable}=.*\)/\1/p" ${BHMAS_userSetupFile} | sed "s/['\"]//g")
            if [[ ${#occurences[@]} -eq 1 ]]; then
                userVariables[${variable}]=${occurences[0]#*=}
            else
                unableToRecover+=( ${variable} )
            fi
        done
        if [[ ${#unableToRecover[@]} -ne 0 ]]; then
            local warningString;
            Warning -N "Unable to recover the previously set value for the following variable(s):"
            for variable in ${unableToRecover[@]}; do
                Warning -n -e -N " - " lo "${variable}"
            done
            Warning -n -e -N "Maybe they were missing just because recently introduced in BaHaMAS."
            Warning -n -e -N "Press enter to continue (and to let the setup add them)."; read
        fi
    fi
}

function __static__ProduceUserVariableFile()
{
    local backupFile variable
    backupFile="${BHMAS_userSetupFile}_$(date +%H%M%S)"
    if [[ -f ${BHMAS_userSetupFile} ]]; then
        mv ${BHMAS_userSetupFile} ${backupFile} || exit ${BHMAS_fatalBuiltin}
    fi
    cp ${filenameTemplate} ${BHMAS_userSetupFile} || exit ${BHMAS_fatalBuiltin}
    #Delete commented lines from user file
    sed -i '/^[[:space:]]*[#]/d' ${BHMAS_userSetupFile}
    #Set variables
    for variable in ${!userVariables[@]}; do
        #Here we need to transform '\' into '\\' in sed since sed then has to print '\'.
        if [[ $(grep -o '\$' <<< "${userVariables[${variable}]}" | wc -l) -eq 0 ]]; then
            sed -i "s#\(^.*${variable}=\).*#\1'${userVariables[${variable}]//\\/\\\\}'#g" ${BHMAS_userSetupFile}
        else
            sed -i "s#\(^.*${variable}=\).*#\1\"${userVariables[${variable}]//\\/\\\\}\"#g" ${BHMAS_userSetupFile}
        fi
    done
    rm -f ${backupFile}
}

function __static__GiveMessageToUserAboutEnvironmentVariables()
{
    local commandString manualPath grepString pathAlreadyAdded manpathAlreadyAdded
    manualPath="${BHMAS_repositoryTopLevelPath}/Manual_Pages"
    if [[ ! ${PATH} =~ (^|:)${BHMAS_repositoryTopLevelPath// /\\ }(:|$) ]]; then
        grepString='# To use BaHaMAS from any position'
        if [[ $(grep -c "${grepString}" ~/.bashrc) -eq 0 ]]; then
            cecho wg '\n'\
                  'If you would like to be able to use ' emph 'BaHaMAS' ' as command from any position,\n'\
                  'you can add the following snippet to your shell login file (e.g. ~/.bashrc):'\
                  ''
            cecho -d '\033[48;5;16m'
            cecho -d lr "${grepString}"
            cecho -d ly 'if ' w '[[ ! ' lg '"${PATH:-}"' w " =~ (^|:)${BHMAS_repositoryTopLevelPath// /\\ }(:|$) ]];" ly ' then'
            cecho -d bb '    export ' o 'PATH' w '=' lg "\"${BHMAS_repositoryTopLevelPath}:\${PATH:-}\""
            cecho ly 'fi'
            cecho ''
            cecho wg 'Adapt the above lines accordingly if you use a different shell than bash.\n'
            AskUser -n "\e[1DWould you like to add the snippet above to your $(cecho -d ly '~/.bashrc' lc) file?"
            if UserSaidYes; then
                cecho -d "\n${grepString}\n"\
                      'if [[ ! "${PATH:-}" =~ (^|:)'"${BHMAS_repositoryTopLevelPath// /\\ }"'(:|$) ]]; then\n'\
                      "    export PATH=\"${BHMAS_repositoryTopLevelPath}:\${PATH:-}\"\n"\
                      'fi' >> "${HOME}/.bashrc"
                cecho lo '\nDo not forget to source the ' emph '~/.bashrc' ' file in order to let the changes take effect.'
            fi
        else
            pathAlreadyAdded='TRUE'
            cecho lo '\n'\
                  'It seems that the snippet to use the ' emph 'BaHaMAS' ' command was already added to\n'\
                  'your ' emph '~/.bashrc' ' file. You need source it in order to use the ' emph 'BaHaMAS' ' command.'
        fi
    fi
    if [[ ! ${MANPATH:-} =~ (^|:)${manualPath// /\\ }(:|$) ]]; then
        grepString='# To have access to BaHaMAS manuals'
        if [[ $(grep -c "${grepString}" ~/.bashrc) -eq 0 ]]; then
            cecho wg '\n'\
                  'If you would like to be able to use the ' emph 'man' ' command to get information\n'\
                  'about BaHaMAS and its execution modes, you can add the following snippet\n'\
                  'to your shell login file (e.g. ~/.bashrc):'\
                  ''
            cecho -d '\033[48;5;16m'
            cecho -d lr "${grepString}"
            cecho -d ly 'if ' w '[[ ! ' lg '"${MANPATH:-}"' w " =~ (^|:)${manualPath// /\\ }(:|$) ]];" ly ' then'
            cecho -d bb '    export ' o 'MANPATH' w '=' lg "\"\${MANPATH:-}:${manualPath}\""
            cecho ly 'fi'
            cecho ''
            cecho wg 'Adapt the above lines accordingly if you use a different shell than bash.\n'
            AskUser -n "\e[1DWould you like to add the snippet above to your $(cecho -d ly '~/.bashrc' lc) file?"
            if UserSaidYes; then
                cecho -d "\n${grepString}\n"\
                      'if [[ ! "${MANPATH:-}" =~ (^|:)'"${manualPath// /\\ }"'(:|$) ]]; then\n'\
                      '    export MANPATH="${MANPATH:-}:'"${manualPath}\"\n"\
                      'fi' >> "${HOME}/.bashrc"
                cecho lo '\nDo not forget to source the ' emph '~/.bashrc' ' file in order to let the changes take effect.\n'
            fi
        else
            manpathAlreadyAdded='TRUE'
            cecho lo '\n'\
                  'It seems that the snippet to use the ' emph 'man' ' command combined with BaHaMAS was already added\n'\
                  'to your ' emph '~/.bashrc' ' file. You need source it in order to use commands like ' emph 'man BaHaMAS' '.'
        fi
    fi
    if [[ ${pathAlreadyAdded:-}${manpathAlreadyAdded:-} = *TRUE* ]]; then
        cecho ''
    fi
}

function MakeInteractiveSetupAndCreateUserDefinedVariablesFile()
{
    local filenameTemplate variableNames
    declare -A userVariables=()
    filenameTemplate="${BHMAS_userSetupFile/.bash/_template.bash}"
    variableNames=()

    __static__ReadVariablesFromTemplateFile
    __static__FillInVariablesFromMaybeExistentUserSetup #Here 'BHMAS_coloredOutput' is defined as global

    if hash dialog 2>/dev/null; then
        MakeInteractiveSetupUsingDialog
    elif hash whiptail 2>/dev/null; then
        MakeInteractiveSetupUsingWhiptail
    else
        Fatal ${BHMAS_fatalRequirement} "Programs " emph "dialog" " and " emph "whitptail" " were not found, but they are required to run the " emph "BaHaMAS setup" ".\n"\
              "Consider to install any of them or read in the documentation how to make the BaHaMAS setup manually!"
    fi

    #Produce final setup file
    __static__ProduceUserVariableFile

    __static__GiveMessageToUserAboutEnvironmentVariables
}


MakeFunctionsDefinedInThisFileReadonly
