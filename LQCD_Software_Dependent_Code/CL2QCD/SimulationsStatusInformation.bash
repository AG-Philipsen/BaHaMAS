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

# This function is meant to create the output file in the standard
# BaHaMAS format from the software output file(s). This file global
# path is is given in the variable ${outputFileGlobalPath} and for
# CL2QCD nothing has to be done, since CL2QCD format is also the
# standrard BaHaMAS format. Still a symbolic link needs to be created.
function CreateOutputFileInTheStandardFormat_CL2QCD()
{
    local softwareOutputFileGlobalPath
    softwareOutputFileGlobalPath="$(dirname "${outputFileGlobalPath}")/${BHMAS_outputFilename}"
    if [[ ! -f "${softwareOutputFileGlobalPath}" ]]; then
        Error 'CL2QCD output file ' file "${softwareOutputFileGlobalPath}"\
              '\nwas not found but expected.'
        return
    fi
    (
        cd "$(dirname "${outputFileGlobalPath}")"
        ln -s -f "${BHMAS_outputFilename}" "$(basename "${outputFileGlobalPath}")" || exit ${BHMAS_fatalBuiltin}
    )
}

# This function has to extract from the ${inputFileGlobalPath} file
# the needed information and set the following variables:
#
#  -  integrationSteps0
#  -  integrationSteps1
#  -  integrationSteps2
#  -  kappaMassPreconditioning
#
function ExtractSimulationInformationFromInputFile_CL2QCD()
{
    CheckIfVariablesAreDeclared integrationSteps0 integrationSteps1\
                                integrationSteps2 kappaMassPreconditioning
    local tmpString
    # The input file here exists
    tmpString=$(sed -n 's/^integrationSteps0=\([[:digit:]]\+\)/\1/p' "${inputFileGlobalPath}")
    if [[ "${tmpString}" != '' ]]; then
        integrationSteps0="${tmpString}"
    fi
    tmpString=$(sed -n 's/^integrationSteps1=\([[:digit:]]\+\)/\1/p' "${inputFileGlobalPath}")
    if [[ "${tmpString}" != '' ]]; then
        integrationSteps1="${tmpString}"
    fi
    if [[ $(grep -o "useMP=1" ${inputFileGlobalPath} | wc -l) -eq 1 ]]; then
        tmpString=$(sed -n 's/^integrationSteps2=\([[:digit:]]\+\)/\1/p' "${inputFileGlobalPath}")
        if [[ "${tmpString}" != '' ]]; then
            integrationSteps2="-${tmpString}"
        else
            integrationSteps2='--'
        fi
        tmpString=$(sed -n 's/^kappaMP=\([[:digit:]]\+[.][[:digit:]]\+\)/\1/p' "${inputFileGlobalPath}")
        if [[ "${tmpString}" != '' ]]; then
            kappaMassPreconditioning="-${tmpString}"
        else
            kappaMassPreconditioning='-----'
        fi
    else
        integrationSteps2="  "
        kappaMassPreconditioning="      "
    fi
}


MakeFunctionsDefinedInThisFileReadonly
