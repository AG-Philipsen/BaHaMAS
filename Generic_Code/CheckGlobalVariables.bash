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
    variablesThatMustBeNotEmpty=(
        BHMAS_lqcdSoftware
        BHMAS_submitDiskGlobalPath
        BHMAS_runDiskGlobalPath
    )
    variablesThatMustBeDeclared=(
        BHMAS_userEmail
        BHMAS_GPUsPerNode
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
        BHMAS_productionExecutableGlobalPath
        BHMAS_measurementExecutableGlobalPath
        BHMAS_excludeNodesGlobalPath
        BHMAS_useRationalApproxFiles
        BHMAS_rationalApproxGlobalPath
        BHMAS_approxHeatbathFilename
        BHMAS_approxMDFilename
        BHMAS_approxMetropolisFilename
        BHMAS_clusterPartition
        BHMAS_clusterNode
        BHMAS_clusterConstraint
        BHMAS_clusterGenericResource
        BHMAS_walltime
        BHMAS_maximumWalltime
    )
    variablesThatIfNotEmptyMustNotEndWithSlash=(
        BHMAS_submitDiskGlobalPath
        BHMAS_runDiskGlobalPath
        BHMAS_projectSubpath
        BHMAS_databaseGlobalPath
        BHMAS_thermConfsGlobalPath
        BHMAS_productionExecutableGlobalPath
        BHMAS_measurementExecutableGlobalPath
        BHMAS_rationalApproxGlobalPath
    )

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

    #Leave an empty line that I remove later if no error occurred (just to have better output)
    cecho ''

    #Check variables values (those not checked have no requirement at this point)
    if [[ ! ${BHMAS_lqcdSoftware:-} =~ ^(CL2QCD|openQCD-FASTSUM)$ ]]; then
        Error -n B emph "BHMAS_lqcdSoftware" uB " variable must be set either to " emph "CL2QCD" " or to " emph "openQCD-FASTSUM"
        mustReturn='FALSE'
    fi
    if [[ "${BHMAS_coloredOutput:-}" != 'TRUE' ]] && [[ "${BHMAS_coloredOutput:-}" != 'FALSE' ]]; then
        #Since in the following we use cecho which rely on the variable "BHMAS_coloredOutput",
        #if this was wrongly set, let us set it to 'FALSE' but still report on it
        BHMAS_coloredOutput='FALSE'
        Error -n B emph "BHMAS_coloredOutput" uB " variable must be set either to " emph "TRUE" " or to " emph "FALSE"
        mustReturn='FALSE'
    fi
    if [[ "${BHMAS_useRationalApproxFiles:-}" != '' ]]; then
        if [[ "${BHMAS_useRationalApproxFiles}" != 'TRUE' ]] && [[ "${BHMAS_useRationalApproxFiles}" != 'FALSE' ]]; then
            Error -n B emph "BHMAS_useRationalApproxFiles" uB " variable must be set either to " emph "TRUE" " or to " emph "FALSE"
            mustReturn='FALSE'
        fi
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
    if [[ "${BHMAS_productionExecutableGlobalPath:-}" != '' ]]; then
        readonly BHMAS_productionExecutableFilename="${BHMAS_productionExecutableGlobalPath##*/}"
    fi
    if [[ "${BHMAS_measurementExecutableGlobalPath:-}" != '' ]]; then
        readonly BHMAS_measurementExecutableFilename="${BHMAS_measurementExecutableGlobalPath##*/}"
    fi

    #Decide whether to return or to exit
    if [[ ${mustReturn} = 'TRUE' ]]; then
        cecho -n '\e[1A'; return
    else
        Fatal ${BHMAS_fatalVariableUnset} "Please set the above variables properly using the " emph "setup" " mode and run " B "BaHaMAS" uB " again."
    fi
}


# Make logical checks on variables that must be necessarily set only in some cases and therefore not always used
# EXAMPLE: If user wants only to produce confs, BHMAS_measurementExecutableFilename can be unset
# Checks also existence directories/files depending on what BaHaMAS should do
function CheckBaHaMASVariablesAndExistenceOfFilesAndFoldersDependingOnUserCase()
{
    local index variable variablesThatMustBeNotEmpty productionJobsNeededVariables schedulerVariables\
          neededFolders neededFiles rationalApproxFolder rationalApproxFiles listOfVariablesAsString
    mustReturn='TRUE'
    productionJobsNeededVariables=(
        BHMAS_inputFilename
        BHMAS_outputFilename
        BHMAS_productionExecutableGlobalPath
        BHMAS_jobScriptPrefix
        BHMAS_jobScriptFolderName
    )
    schedulerVariables=(  #BHMAS_walltime can be empty here, we check later if user gave time in betas file!
        BHMAS_GPUsPerNode #This is here and not in the array above because it is needed also in measure mode!
        BHMAS_maximumWalltime
        BHMAS_userEmail
    )
    variablesThatMustBeNotEmpty=(
        BHMAS_submitDiskGlobalPath
        BHMAS_runDiskGlobalPath
        BHMAS_projectSubpath
    )
    neededFolders=(
        "${BHMAS_submitDiskGlobalPath}"
        "${BHMAS_submitDiskGlobalPath}/${BHMAS_projectSubpath}"
    )
    if [[ "${BHMAS_submitDiskGlobalPath}" != "${BHMAS_runDiskGlobalPath}" ]]; then
        neededFolders+=(
            "${BHMAS_runDiskGlobalPath}"
            "${BHMAS_runDiskGlobalPath}/${BHMAS_projectSubpath}"
        )
    fi
    neededFiles=()
    rationalApproxFolder=()
    rationalApproxFiles=()

    #If user wants to read the rational approximation from file check relative variables
    if [[ ${BHMAS_useRationalApproxFiles} = 'TRUE' ]]; then
        productionJobsNeededVariables+=(
            BHMAS_rationalApproxGlobalPath
            BHMAS_approxHeatbathFilename
            BHMAS_approxMDFilename
            BHMAS_approxMetropolisFilename
        )
        rationalApproxFolder+=( "${BHMAS_rationalApproxGlobalPath}" )
        rationalApproxFiles+=(
            "${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}*${BHMAS_approxHeatbathFilename}"
            "${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}*${BHMAS_approxMDFilename}"
            "${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}*${BHMAS_approxMetropolisFilename}"
        )
    fi

    #Populate further arrays depending on LQCD software
    PrepareSoftwareSpecificGlobalVariableValidation

    #Check variables depending on BaHaMAS execution mode
    case ${BHMAS_executionMode} in

        mode:new-chain )
            variablesThatMustBeNotEmpty+=(
                ${productionJobsNeededVariables[@]}
                ${schedulerVariables[@]}
                BHMAS_thermConfsGlobalPath
            )
            neededFolders+=( "${BHMAS_thermConfsGlobalPath}" "${rationalApproxFolder[@]:-}" )
            neededFiles+=( "${BHMAS_productionExecutableGlobalPath}" "${rationalApproxFiles[@]:-}" )
            readonly BHMAS_walltimeIsNeeded='TRUE'
            ;;

        mode:prepare-only )
            variablesThatMustBeNotEmpty+=(
                ${productionJobsNeededVariables[@]}
                ${schedulerVariables[@]}
                BHMAS_thermConfsGlobalPath
            )
            neededFolders+=( "${BHMAS_thermConfsGlobalPath}" "${rationalApproxFolder[@]:-}" )
            neededFiles+=( "${BHMAS_productionExecutableGlobalPath}" "${rationalApproxFiles[@]:-}" )
            readonly BHMAS_walltimeIsNeeded='TRUE'
            ;;

        mode:submit-only )
            variablesThatMustBeNotEmpty+=(
                BHMAS_inputFilename
                BHMAS_jobScriptPrefix
                BHMAS_jobScriptFolderName
            )
            neededFolders+=( "${rationalApproxFolder[@]:-}" )
            neededFiles+=( "${BHMAS_productionExecutableGlobalPath}" "${rationalApproxFiles[@]:-}" )
            ;;

        mode:thermalize )
            variablesThatMustBeNotEmpty+=(
                ${productionJobsNeededVariables[@]}
                ${schedulerVariables[@]}
                BHMAS_thermConfsGlobalPath
            )
            neededFolders+=( "${BHMAS_thermConfsGlobalPath}" "${rationalApproxFolder[@]:-}" )
            neededFiles+=( "${BHMAS_productionExecutableGlobalPath}" "${rationalApproxFiles[@]:-}" )
            readonly BHMAS_walltimeIsNeeded='TRUE'
            ;;

        mode:continue )
            variablesThatMustBeNotEmpty+=(
                ${productionJobsNeededVariables[@]}
                ${schedulerVariables[@]}
            )
            neededFolders+=( "${rationalApproxFolder[@]:-}" )
            neededFiles+=( "${BHMAS_productionExecutableGlobalPath}" "${rationalApproxFiles[@]:-}" )
            readonly BHMAS_walltimeIsNeeded='TRUE'
            ;;

        mode:continue-thermalization )
            variablesThatMustBeNotEmpty+=(
                ${productionJobsNeededVariables[@]}
                ${schedulerVariables[@]}
                BHMAS_thermConfsGlobalPath
            )
            neededFolders+=( "${BHMAS_thermConfsGlobalPath}" "${rationalApproxFolder[@]:-}" )
            neededFiles+=( "${BHMAS_productionExecutableGlobalPath}" "${rationalApproxFiles[@]:-}" )
            readonly BHMAS_walltimeIsNeeded='TRUE'
            ;;

        mode:simulation-status )
            variablesThatMustBeNotEmpty+=(
                BHMAS_inputFilename
                BHMAS_outputFilename
                BHMAS_plaquetteColumn
                BHMAS_deltaHColumn
                BHMAS_acceptanceColumn
                BHMAS_trajectoryTimeColumn
            )
            ;;

        mode:acceptance-rate-report )
            variablesThatMustBeNotEmpty+=(
                BHMAS_acceptanceColumn
                BHMAS_outputFilename
            )
            ;;

        mode:clean-output-files )
            variablesThatMustBeNotEmpty+=( BHMAS_outputFilename )
            ;;

        mode:complete-betas-file )
            ;;

        mode:uncomment-betas )
            ;;

        mode:comment-betas )
            ;;

        mode:measure )
            variablesThatMustBeNotEmpty+=(
                BHMAS_jobScriptPrefix
                BHMAS_jobScriptFolderName
                BHMAS_measurementExecutableGlobalPath
                ${schedulerVariables[@]}
            )
            neededFiles+=( "${BHMAS_measurementExecutableGlobalPath}" )
            ;;

        mode:database )
            variablesThatMustBeNotEmpty+=(
                BHMAS_inputFilename
                BHMAS_outputFilename
                BHMAS_plaquetteColumn
                BHMAS_deltaHColumn
                BHMAS_acceptanceColumn
                BHMAS_trajectoryTimeColumn
                BHMAS_databaseGlobalPath
                BHMAS_databaseFilename
            )
            neededFolders+=( "${BHMAS_databaseGlobalPath}" )
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
        Error "To run " B "BaHaMAS" uB " in " emph "${BHMAS_executionMode#mode:}"\
              " execution mode, the following " emph "variable(s)" " must be " emph "set" " and " emph "not empty" ": ${listOfVariablesAsString}"
        Fatal ${BHMAS_fatalVariableUnset} -n "Please set the above variables properly using the " emph "setup" " mode and run " B "BaHaMAS" uB " again."
    else
        for index in "${!neededFolders[@]}"; do
            if [[ -d "${neededFolders[${index}]}" ]]; then
                unset -v 'neededFolders[${index}]'
            fi
        done
        for index in "${!neededFiles[@]}"; do
            #use stat in if instead of [[ -f ]] since we have a glob * in name
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
        Error "To run " B "BaHaMAS" uB " in " emph "${BHMAS_executionMode}"\
              " execution mode, the following specified " B dir "folder(s)" uB " or " file "file(s)" " must " emph "exist" ": ${listOfVariablesAsString}"
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
