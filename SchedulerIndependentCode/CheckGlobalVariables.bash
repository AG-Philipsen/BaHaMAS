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

function CheckUserDefinedVariablesAndDefineDependentAdditionalVariables()
{
    local variablesThatMustBeNotEmpty\
          variablesThatMustBeDeclared\
          variablesThatIfNotEmptyMustNotEndWithSlash\
          index variable mustReturn listOfVariablesAsString
    mustReturn='TRUE'
    variablesThatMustBeNotEmpty=( BHMAS_userEmail
                                  BHMAS_submitDiskGlobalPath
                                  BHMAS_runDiskGlobalPath )
    variablesThatMustBeDeclared=( BHMAS_GPUsPerNode
                                  BHMAS_jobScriptFolderName
                                  BHMAS_projectSubpath
                                  BHMAS_inputFilename
                                  BHMAS_jobScriptPrefix
                                  BHMAS_outputFilename
                                  BHMAS_plaquetteColumn
                                  BHMAS_deltaHColumn
                                  BHMAS_acceptanceColumn
                                  BHMAS_trajectoryTimeColumn
                                  BHMAS_databaseFilename
                                  BHMAS_databaseGlobalPath
                                  BHMAS_thermConfsGlobalPath
                                  BHMAS_hmcGlobalPath
                                  BHMAS_inverterGlobalPath
                                  BHMAS_excludeNodesGlobalPath
                                  BHMAS_rationalApproxGlobalPath
                                  BHMAS_approxHeatbathFilename
                                  BHMAS_approxMDFilename
                                  BHMAS_approxMetropolisFilename
                                  BHMAS_clusterPartition
                                  BHMAS_clusterNode
                                  BHMAS_clusterConstraint
                                  BHMAS_clusterGenericResource
                                  BHMAS_walltime
                                  BHMAS_maximumWalltime )
    variablesThatIfNotEmptyMustNotEndWithSlash=(BHMAS_submitDiskGlobalPath
                                                BHMAS_runDiskGlobalPath
                                                BHMAS_projectSubpath
                                                BHMAS_databaseGlobalPath
                                                BHMAS_thermConfsGlobalPath
                                                BHMAS_hmcGlobalPath
                                                BHMAS_inverterGlobalPath
                                                BHMAS_rationalApproxGlobalPath )

    #Check variables and unset them if they are fine
    for index in "${!variablesThatMustBeNotEmpty[@]}"; do
        if [[ -n "${!variablesThatMustBeNotEmpty[${index}]:+x}" ]]; then
            #Variable set and not empty
            unset -v 'variablesThatMustBeNotEmpty[${index}]'
        fi
    done
    for index in "${!variablesThatMustBeDeclared[@]}"; do
        if [[ -n "${!variablesThatMustBeDeclared[${index}]+x}" ]]; then
            #Variable set
            unset -v 'variablesThatMustBeDeclared[${index}]'
        fi
    done
    for index in "${!variablesThatIfNotEmptyMustNotEndWithSlash[@]}"; do
        if [[ -n "${!variablesThatIfNotEmptyMustNotEndWithSlash[${index}]:+x}" ]] && [[ "${!variablesThatIfNotEmptyMustNotEndWithSlash[${index}]}" =~ /[[:space:]]*$ ]]; then
            continue
        else
            unset -v 'variablesThatIfNotEmptyMustNotEndWithSlash[${index}]'
        fi
    done

    #Leave an empty line that I remove later if no error occurred (just to have better output
    cecho ''

    #Check variables values (those not checked have no requirement at this point)
    if [[ "${BHMAS_coloredOutput:-}" != 'TRUE' ]] && [[ "${BHMAS_coloredOutput:-}" != 'FALSE' ]]; then
        #Since in the following we use cecho which rely on the variable "BHMAS_coloredOutput",
        #if this was wrongly set, let us set it to 'FALSE' but still report on it
        BHMAS_coloredOutput='FALSE'
        Error -n B emph "BHMAS_coloredOutput" uB " variable must be set either to " emph "TRUE" " or to " emph "FALSE"
        mustReturn='FALSE'
    fi
    if [[ "${BHMAS_useRationalApproxFiles:-}" != 'TRUE' ]] && [[ "${BHMAS_useRationalApproxFiles:-}" != 'FALSE' ]]; then
        Error -n B emph "BHMAS_useRationalApproxFiles" uB " variable must be set either to " emph "TRUE" " or to " emph "FALSE"
        mustReturn='FALSE'
    fi
    for variable in BHMAS_walltime BHMAS_maximumWalltime; do
        if [[ "${!variable:-}" != '' ]] && [[ ! ${!variable} =~ ^([0-9]+-)?[0-9]{1,2}:[0-9]{2}:[0-9]{2}$ ]]; then
            Error -n B emph "${variable}" uB " variable format invalid. Correct format: " emph "days-hours:min:sec" " or " emph "hours:min:sec"
            mustReturn='FALSE'
        fi
    done
    if [[ "${BHMAS_GPUsPerNode:-}" != '' ]] && [[ ! ${BHMAS_GPUsPerNode} =~ ^[1-9][0-9]*$ ]]; then
        Error -n B emph "BHMAS_GPUsPerNode" uB " variable format invalid. It has to be a " emph "positive integer" " number."
        mustReturn='FALSE'
    fi
    if [[ "${BHMAS_plaquetteColumn:-}" != '' ]] && [[ ! ${BHMAS_plaquetteColumn} =~ ^[1-9][0-9]*$ ]]; then
        Error -n B emph "BHMAS_plaquetteColumn" uB " variable format invalid. It has to be a " emph "positive integer" " number."
        mustReturn='FALSE'
    fi
    if [[ "${BHMAS_deltaHColumn:-}" != '' ]] && [[ ! ${BHMAS_deltaHColumn} =~ ^[1-9][0-9]*$ ]]; then
        Error -n B emph "BHMAS_deltaHColumn" uB " variable format invalid. It has to be a " emph "positive integer" " number."
        mustReturn='FALSE'
    fi
    if [[ "${BHMAS_acceptanceColumn:-}" != '' ]] && [[ ! ${BHMAS_acceptanceColumn} =~ ^[1-9][0-9]*$ ]]; then
        Error -n B emph "BHMAS_acceptanceColumn" uB " variable format invalid. It has to be a " emph "positive integer" " number."
        mustReturn='FALSE'
    fi
    if [[ "${BHMAS_trajectoryTimeColumn:-}" != '' ]] && [[ ! ${BHMAS_trajectoryTimeColumn} =~ ^[1-9][0-9]*$ ]]; then
        Error -n B emph "BHMAS_trajectoryTimeColumn" uB " variable format invalid. It has to be a " emph "positive integer" " number."
        mustReturn='FALSE'
    fi

    #If variables remained in arrays, print error
    if [[ ${#variablesThatMustBeNotEmpty[@]} -ne 0 ]]; then
        listOfVariablesAsString=''
        for variable in "${variablesThatMustBeNotEmpty[@]}"; do
            listOfVariablesAsString+="\n$(cecho -d lo " " B) ${variable}"
        done
        Error -n "The following variable(s) must be " emph "set" " and " emph "not empty" ": ${listOfVariablesAsString}"
        mustReturn='FALSE'
    fi
    if [[ ${#variablesThatMustBeDeclared[@]} -ne 0 ]]; then
        listOfVariablesAsString=''
        for variable in "${variablesThatMustBeDeclared[@]}"; do
            listOfVariablesAsString+="\n$(cecho -d lo " " B) ${variable}"
        done
        Error -n "The following variable(s) must be " emph "declared" ": ${listOfVariablesAsString}"
        mustReturn='FALSE'
    fi
    if [[ ${#variablesThatIfNotEmptyMustNotEndWithSlash[@]} -ne 0 ]]; then
        for variable in "${variablesThatIfNotEmptyMustNotEndWithSlash[@]}"; do
            listOfVariablesAsString+="\n$(cecho -d lo " " B) ${variable}"
        done
        Error -n "The following variable(s) must " emph "not end with '/'" ": ${listOfVariablesAsString}"
        mustReturn='FALSE'
    fi


    #Define dependent additional variables
    if [[ "${BHMAS_hmcGlobalPath:-}" != '' ]]; then
        readonly BHMAS_hmcFilename="${BHMAS_hmcGlobalPath##*/}"
    fi
    if [[ "${BHMAS_inverterGlobalPath:-}" != '' ]]; then
        readonly BHMAS_inverterFilename="${BHMAS_inverterGlobalPath##*/}"
    fi

    #Decide whether to return or to exit
    if [[ ${mustReturn} = 'TRUE' ]]; then
        cecho -n '\e[1A'; return
    else
        Fatal ${BHMAS_fatalVariableUnset} "Please set the above variables properly using the " emph "--setup" " option and run " B "BaHaMAS" uB " again."
    fi
}


# Make logical checks on variables that must be necessarily set only in some cases and therefore not always used
# EXAMPLE: If user wants only to produce confs, BHMAS_inverterFilename can be unset
# Checks also existence directories/files depending on what BaHaMAS should do
function CheckBaHaMASVariablesAndExistenceOfFilesAndFoldersDependingOnUserCase()
{
    local index variable option variablesThatMustBeNotEmpty jobsNeededVariables schedulerVariables\
          neededFolders neededFiles rationalApproxFolder rationalApproxFiles listOfVariablesAsString
    mustReturn='TRUE'
    jobsNeededVariables=(BHMAS_inputFilename  BHMAS_outputFilename  BHMAS_hmcGlobalPath  BHMAS_jobScriptPrefix  BHMAS_jobScriptFolderName)
    schedulerVariables=(BHMAS_GPUsPerNode  BHMAS_maximumWalltime  BHMAS_userEmail) #BHMAS_walltime can be empty here, we check later if user gave time in betas file!
    variablesThatMustBeNotEmpty=(BHMAS_submitDiskGlobalPath  BHMAS_runDiskGlobalPath  BHMAS_projectSubpath)
    neededFolders=( "${BHMAS_submitDiskGlobalPath}" "${BHMAS_submitDiskGlobalPath}/${BHMAS_projectSubpath}" )
    if [[ "${BHMAS_submitDiskGlobalPath}" != "${BHMAS_runDiskGlobalPath}" ]]; then
        neededFolders+=( "${BHMAS_runDiskGlobalPath}" "${BHMAS_runDiskGlobalPath}/${BHMAS_projectSubpath}" )
    fi
    neededFiles=()
    rationalApproxFolder=()
    rationalApproxFiles=()

    #If user wants to read the rational approximation from file check relative variables
    if [[ ${BHMAS_useRationalApproxFiles} = 'TRUE' ]]; then
        jobsNeededVariables+=( BHMAS_rationalApproxGlobalPath
                               BHMAS_approxHeatbathFilename
                               BHMAS_approxMDFilename
                               BHMAS_approxMetropolisFilename )
        rationalApproxFolder+=( "${BHMAS_rationalApproxGlobalPath}" )
        rationalApproxFiles+=( "${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}*${BHMAS_approxHeatbathFilename}"
                               "${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}*${BHMAS_approxMDFilename}"
                               "${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}*${BHMAS_approxMetropolisFilename}" )
    fi

    #Check variables depending on BaHaMAS execution mode
    case ${BHMAS_executionMode} in

        mode:submit )
            option="$(cecho -d "with the " B "--submit" uB)"
            variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]}  ${schedulerVariables[@]}
                                           BHMAS_thermConfsGlobalPath )
            neededFolders+=( "${BHMAS_thermConfsGlobalPath}" ${rationalApproxFolder[@]:-} )
            neededFiles+=( "${BHMAS_hmcGlobalPath}" ${rationalApproxFiles[@]:-} )
            readonly BHMAS_walltimeIsNeeded='TRUE'
            ;;

        mode:submit-only )

            option="$(cecho -d "with the " B "--submitonly" uB)"
            variablesThatMustBeNotEmpty+=( BHMAS_inputFilename
                                           BHMAS_jobScriptPrefix
                                           BHMAS_jobScriptFolderName
                                           BHMAS_thermConfsGlobalPath )
            neededFolders+=( "${BHMAS_thermConfsGlobalPath}" ${rationalApproxFolder[@]:-} )
            neededFiles+=( "${BHMAS_hmcGlobalPath}" ${rationalApproxFiles[@]:-} )
            ;;

        mode:thermalize )
            option="$(cecho -d "with the " B "--thermalize" uB)"
            variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]} ${schedulerVariables[@]}
                                           BHMAS_thermConfsGlobalPath )
            neededFolders+=( "${BHMAS_thermConfsGlobalPath}" ${rationalApproxFolder[@]:-} )
            neededFiles+=( "${BHMAS_hmcGlobalPath}" ${rationalApproxFiles[@]:-} )
            readonly BHMAS_walltimeIsNeeded='TRUE'
            ;;

        mode:continue )
            option="$(cecho -d "with the " B "--continue" uB)"
            variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]} ${schedulerVariables[@]} )
            neededFolders+=( ${rationalApproxFolder[@]:-} )
            neededFiles+=( "${BHMAS_hmcGlobalPath}" ${rationalApproxFiles[@]:-} )
            readonly BHMAS_walltimeIsNeeded='TRUE'
            ;;

        mode:continue-thermalization )
            option="$(cecho -d "with the " B "--continueThermalization" uB)"
            variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]} ${schedulerVariables[@]}
                                           BHMAS_thermConfsGlobalPath )
            neededFolders+=( "${BHMAS_thermConfsGlobalPath}" ${rationalApproxFolder[@]:-} )
            neededFiles+=( "${BHMAS_hmcGlobalPath}" ${rationalApproxFiles[@]:-} )
            readonly BHMAS_walltimeIsNeeded='TRUE'
            ;;

        mode:simulation-status )
            option="$(cecho -d "with the " B "--liststatus" uB)"
            variablesThatMustBeNotEmpty+=( BHMAS_hmcGlobalPath #TODO: Remove, now it's only for --measureTime
                                           BHMAS_inputFilename
                                           BHMAS_outputFilename
                                           BHMAS_plaquetteColumn
                                           BHMAS_deltaHColumn
                                           BHMAS_acceptanceColumn
                                           BHMAS_trajectoryTimeColumn )
            ;;

        mode:acceptance-rate-report )
            option="$(cecho -d "with the " B "--accRateReport" uB)"
            variablesThatMustBeNotEmpty+=( BHMAS_acceptanceColumn  BHMAS_outputFilename )
            ;;

        mode:clean-output-files )
            option="$(cecho -d "with the " B "--cleanOutputFiles" uB)"
            variablesThatMustBeNotEmpty+=( BHMAS_outputFilename )
            ;;

        mode:complete-betas-file )
            option="$(cecho -d "with the " B "--completeBetasFile" uB)"
            ;;

        mode:uncomment-betas )
            option="$(cecho -d "with the " B "--uncommentBetas" uB)"
            ;;

        mode:comment-betas )
            option="$(cecho -d "with the " B "--commentBetas" uB)"
            ;;

        mode:invert-configurations )
            option="$(cecho -d "with the " B "--invertConfigurations" uB)"
            variablesThatMustBeNotEmpty+=( BHMAS_jobScriptPrefix
                                           BHMAS_jobScriptFolderName
                                           BHMAS_inverterGlobalPath
                                           ${schedulerVariables[@]} )
            neededFiles+=( "${BHMAS_inverterGlobalPath}" )
            ;;

        mode:database )
            option="$(cecho -d "with the " B "--dataBase" uB)"
            variablesThatMustBeNotEmpty+=( BHMAS_inputFilename
                                           BHMAS_outputFilename
                                           BHMAS_plaquetteColumn
                                           BHMAS_deltaHColumn
                                           BHMAS_acceptanceColumn
                                           BHMAS_trajectoryTimeColumn
                                           BHMAS_databaseGlobalPath
                                           BHMAS_databaseFilename )
            neededFolders+=( "${BHMAS_databaseGlobalPath}" )
            ;;

        mode:default )
            option='without any mutually exclusive'
            variablesThatMustBeNotEmpty+=( ${jobsNeededVariables[@]} ${schedulerVariables[@]}
                                           BHMAS_thermConfsGlobalPath )
            neededFolders+=( "${BHMAS_thermConfsGlobalPath}" ${rationalApproxFolder[@]:-} )
            neededFiles+=( "${BHMAS_hmcGlobalPath}" ${rationalApproxFiles[@]:-} )
            readonly BHMAS_walltimeIsNeeded='TRUE'
            ;;

        * )
            Internal "Unknown execution mode \"${BHMAS_executionMode}\" in ${FUNCNAME} function."
            ;;
    esac

    #If BHMAS_walltimeIsNeeded not declared, put it false
    [[ "${BHMAS_walltimeIsNeeded:-}" = '' ]] && readonly BHMAS_walltimeIsNeeded='FALSE'

    #Check if variables are defined and not empty
    for index in "${!variablesThatMustBeNotEmpty[@]}"; do
        if [[ -n "${!variablesThatMustBeNotEmpty[${index}]:+x}" ]]; then
            unset -v 'variablesThatMustBeNotEmpty[${index}]'
        fi
    done

    #If variables remained, print error otherwise check needed files/folders
    if [[ ${#variablesThatMustBeNotEmpty[@]} -ne 0 ]]; then
        listOfVariablesAsString=''
        for variable in "${variablesThatMustBeNotEmpty[@]}"; do
            listOfVariablesAsString+="\n$(cecho -d ly " " B) ${variable}"
        done
        Error "To run " B "BaHaMAS" uB " ${option} " "option, the following " emph "variable(s)" " must be " emph "set" " and " emph "not empty" ": ${listOfVariablesAsString}"
        Fatal ${BHMAS_fatalVariableUnset} -n "Please set the above variables properly using the " emph "--setup" " option and run " B "BaHaMAS" uB " again."
    else
        for index in "${!neededFolders[@]}"; do
            if [[ -d "${neededFolders[${index}]}" ]]; then
                unset -v 'neededFolders[${index}]'
            fi
        done
        for index in "${!neededFiles[@]}"; do
            #use stat in if instead of [[ -f ]] since we have a glob * in name (for database)
            if stat -t ${neededFiles[${index}]} >/dev/null 2>&1; then
                unset -v 'neededFiles[${index}]'
            fi
        done
    fi

    #If required files/folders were not found, print error and exit
    if [[ ${#neededFolders[@]} -ne 0 ]] || [[ ${#neededFiles[@]} -ne 0 ]]; then
        listOfVariablesAsString=''
        for variable in ${neededFolders[@]+"${neededFolders[@]}"}; do
            listOfVariablesAsString+="\n$(cecho -d dir " " B) ${variable}"
        done
        for variable in ${neededFiles[@]+"${neededFiles[@]}"}; do
            listOfVariablesAsString+="\n$(cecho -d file " ") ${variable}"
        done
        Error "To run " B "BaHaMAS" uB " ${option} " "option, the following specified " B dir "folder(s)" uB " or " file "file(s)" " must " emph "exist" ": ${listOfVariablesAsString}"
        Fatal ${BHMAS_fatalFileNotFound} -n "Please check the path variables in the " B "BaHaMAS" uB " setup and run the program again."
    fi
}


#Make final additional checks on paths to beta folders
function CheckBetaFoldersPathsVariables()
{
    if [[ ${BHMAS_submitDirWithBetaFolders} != "$(pwd)" ]]; then
        Fatal ${BHMAS_fatalPathError} "Constructed path to directory containing beta folders\n"\
              dir "   ${BHMAS_submitDirWithBetaFolders}" "\ndoes not match the actual position\n"\
              dir "   $(pwd)"
    fi
    if [[ ! -d ${BHMAS_runDirWithBetaFolders} ]]; then
        Fatal ${BHMAS_fatalPathError} "Constructed path to directory containing beta folders on scratch\n"\
              dir "   ${BHMAS_runDirWithBetaFolders}" "\nseems not to be a valid path!"
    fi
}


MakeFunctionsDefinedInThisFileReadonly
