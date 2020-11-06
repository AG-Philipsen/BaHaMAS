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
#
# ATTENTION: To retrieve later the time from last trajectories, it
#            is important to set the last modification date of the
#            standardized file to that of the output file.
function CreateOutputFileInTheStandardFormat_CL2QCD()
{
    CheckIfVariablesAreDeclared outputFileGlobalPath
    local softwareOutputFileGlobalPath symlinkName
    softwareOutputFileGlobalPath="$(dirname "${outputFileGlobalPath}")/${BHMAS_outputFilename}"
    symlinkName="$(basename "${outputFileGlobalPath}")"
    if [[ ! -f "${softwareOutputFileGlobalPath}" ]]; then
        if [[ ${BHMAS_simulationStatusVerbose} = 'TRUE' ]]; then
            Error 'CL2QCD output file ' file "${softwareOutputFileGlobalPath}"\
                  '\nwas not found but expected.'
        fi
        return 1
    fi
    (
        cd "$(dirname "${outputFileGlobalPath}")"
        ln -s -f "${BHMAS_outputFilename}" "${symlinkName}" || exit ${BHMAS_fatalBuiltin}
        #Adjust timestamp of symbolic link
        touch -d "$(stat -c %y "${BHMAS_outputFilename}")" -h "${symlinkName}" || exit ${BHMAS_fatalBuiltin}
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
    local numScales tmpString
    # The input file here exists
    numScales=$(sed -n 's/^nTimeScales=\([[:digit:]]\+\)/\1/p' "${inputFileGlobalPath}")
    if [[ ${numScales} = '' ]]; then
        return 0
    fi
    tmpString=$(sed -n 's/^integrationSteps0=\([[:digit:]]\+\)/\1/p' "${inputFileGlobalPath}")
    if [[ "${tmpString}" != '' ]]; then
        integrationSteps0="${tmpString}"
        integrationSteps1='' # To avoid dashes in one times scale case
    fi
    if [[ ${numScales} -gt 1 ]]; then
        tmpString=$(sed -n 's/^integrationSteps1=\([[:digit:]]\+\)/\1/p' "${inputFileGlobalPath}")
        if [[ "${tmpString}" != '' ]]; then
            integrationSteps1="-${tmpString}"
        fi
    fi
    if [[ ${numScales} -eq 3 ]]; then
        if [[ $(grep -o "useMP=1" ${inputFileGlobalPath} | wc -l) -eq 1 ]]; then
            tmpString=$(sed -n 's/^integrationSteps2=\([[:digit:]]\+\)/\1/p' "${inputFileGlobalPath}")
            if [[ "${tmpString}" != '' ]]; then
                integrationSteps2="-${tmpString}"
            fi
            tmpString=$(sed -n 's/^kappaMP=\([[:digit:]]\+[.][[:digit:]]\+\)/\1/p' "${inputFileGlobalPath}")
            if [[ "${tmpString}" != '' ]]; then
                kappaMassPreconditioning="-${tmpString}"
            fi
        fi
    else
        integrationSteps2=''
        kappaMassPreconditioning=''
    fi
}


MakeFunctionsDefinedInThisFileReadonly
