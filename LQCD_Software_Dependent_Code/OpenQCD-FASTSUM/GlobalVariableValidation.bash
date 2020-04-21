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
function PrepareSoftwareSpecificGlobalVariableValidation_OpenQCD-FASTSUM()
{
    CheckIfVariablesAreDeclared productionJobsNeededVariables schedulerVariables\
                                neededFiles neededFolders
    # OpenQCD-FASTSUM requires to compile the production executable for
    # each job and hence BaHaMAS has to know what to do
    productionJobsNeededVariables+=(
        BHMAS_productionCodebaseGlobalPath
        BHMAS_productionMakefileTarget
        BHMAS_Compiler
        BHMAS_CompilerFlags
        BHMAS_MPIIncludeGlobalPath
    )
}


MakeFunctionsDefinedInThisFileReadonly
