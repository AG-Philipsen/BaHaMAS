#
#  Copyright (c) 2020 Alessandro Sciarra
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

# This function will be called rather at the beginnin of the function
# CheckBaHaMASVariablesAndExistenceOfFilesAndFoldersDependingOnExecutionMode
# which will then finish to populate the "variablesThatMustBeNotEmpty"
# array depending on the execution mode.
#
# This function has the following arrays available, which have been
# created to gather variable names and avoid code duplication (refer
# to the caller to see in which modes are they used).
#  - productionJobsNeededVariables
#  - schedulerVariables
#
# Here new variables can either be added to the above arrays or directly
# to "variablesThatMustBeNotEmpty", depending on the execution mode.
#
# Two more arrays are also available and they can be populated here
# (checks on files and folder are performed at the end of the caller).
#  - neededFiles
#  - neededFolders
#
function PrepareSoftwareSpecificGlobalVariableValidation_CL2QCD()
{
    CheckIfVariablesAreDeclared productionJobsNeededVariables schedulerVariables\
                                neededFiles neededFolders
    # CL2QCD does not get compiled by BaHaMAS, hence the executable
    # must be available somewhere and BaHaMAS just copies it
    productionJobsNeededVariables+=(
        BHMAS_productionExecutableGlobalPath
    )
    schedulerVariables+=(
        BHMAS_GPUsPerNode #This is here and not in the array above because it is needed also in measure mode!
    )

    # If user wants to read the rational approximation from file check relative variables
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

    case ${BHMAS_executionMode} in
        mode:*-only | mode:new-chain | mode:thermalize | mode:continue* )
            neededFolders+=( "${rationalApproxFolder[@]}" )
            neededFiles+=( "${BHMAS_productionExecutableGlobalPath}" "${rationalApproxFiles[@]}" )
            ;;
        *)
            ;;
    esac
}


MakeFunctionsDefinedInThisFileReadonly
