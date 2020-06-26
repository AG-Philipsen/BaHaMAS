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
# openQCD it has to be build from the log file.
#
# ATTENTION: To retrieve later the time from last trajectories, it
#            is important to set the last modification date of the
#            standardized file to that of the output file.
function CreateOutputFileInTheStandardFormat_openQCD-FASTSUM()
{
    CheckIfVariablesAreDeclared outputFileGlobalPath
    local runId softwareOutputFileGlobalPath trShift
    runId="$1"
    softwareOutputFileGlobalPath="$(dirname "${outputFileGlobalPath}")/${BHMAS_outputFilename}.log"
    if [[ ! -f "${softwareOutputFileGlobalPath}" ]]; then
        if [[ ${BHMAS_simulationStatusVerbose} = 'TRUE' ]]; then
            Error 'openQCD-FASTSUM output file ' file "${softwareOutputFileGlobalPath}"\
                  '\nwas not found but expected.'
        fi
        return 1
    fi
    if ! trShift=$(ExtractTrajectoryNumberFromConfigurationSymlink "$(dirname "${softwareOutputFileGlobalPath}")"); then
        if [[ ${BHMAS_simulationStatusVerbose} = 'TRUE' ]]; then
            Error 'Unable to extract initial trajectory number from configuration symlink\n'\
                  'for run ID ' emph "${runId}" ' and hence not able to create standardized output.'
        fi
        return 1
    fi
    # NOTE: "N.A." is printed for information that openQCD does not give
    #       "nan" are printed for not found numbers -> https://stackoverflow.com/a/23622339
    awk -v offset="${trShift}"\
        '
        function PrintLineToFile(tr, plaq, L_re, L_im, L_norm, dH, acc, time)
        {
            if(plaq == ""){plaq="nan"}
            if(L_re == ""){L_re="nan"}
            if(L_im == ""){L_im="nan"}
            if(L_norm == ""){L_norm="nan"}
            if(dH == ""){dH="nan"}
            if(acc == ""){acc="nan"}
            if(time == ""){time="nan"}
            printf "%8d%25s%10s%10s%25s%25s%25.15f%15s%6d%10.1f\n", tr, plaq, "N.A.", "N.A.", L_re, L_im, L_norm, dH, acc, time
        }
        {
            if( $0 ~ /^Trajectory no [1-9][0-9]*$/ )
            {
                if(trajectory != "")
                {
                    PrintLineToFile(trajectory, plaquette, polyRe, polyIm, polyNorm, deltaH, accepted, trTime)
                }
                trajectory=offset+$3
                next
            }
            if( $0 ~ /^dH =/ )
            {
                split($0, result, "(,| = )");
                deltaH=result[2]
                accepted=result[4]
                next
            }
            if( $0 ~ /^Average plaquette =/ )
            {
                plaquette=$4
                next
            }
            if( $0 ~ /^Polyakov loop =/ )
            {
                polyRe=$4
                polyIm=$5
                polyNorm=sqrt($4**2+$5**2)
                next
            }
            if( $0 ~ /^Time per trajectory =/ )
            {
                trTime=$5
                next
            }
        }
        END{
            PrintLineToFile(trajectory, plaquette, polyRe, polyIm, polyNorm, deltaH, accepted, trTime)
        } ' "${softwareOutputFileGlobalPath}" > "${outputFileGlobalPath}"

    #Adjust timestamp of standardized file
    touch -d "$(stat -c %y "${softwareOutputFileGlobalPath}")" "${outputFileGlobalPath}" || exit ${BHMAS_fatalBuiltin}
}

# This function has to extract from the ${inputFileGlobalPath} file
# the needed information and set the following variables:
#
#  -  integrationSteps0
#  -  integrationSteps1
#  -  integrationSteps2
#  -  kappaMassPreconditioning
#
function ExtractSimulationInformationFromInputFile_openQCD-FASTSUM()
{
    CheckIfVariablesAreDeclared integrationSteps0 integrationSteps1\
                                integrationSteps2 kappaMassPreconditioning
    local tmpString
    # The input file here exists
    tmpString=$(__static__FindFirstOccurenceAfterLabel '[[]Level 0[]]' 'nstep[[:space:]]+[0-9]+')
    if [[ "${tmpString}" != '' ]]; then
        integrationSteps0="${tmpString}"
    fi
    tmpString=$(__static__FindFirstOccurenceAfterLabel '[[]Level 1[]]' 'nstep[[:space:]]+[0-9]+')
    if [[ "${tmpString}" != '' ]]; then
        integrationSteps1="${tmpString}"
    fi
    # At the moment no mass preconditioning supported with openQCD
    integrationSteps2="  "
    kappaMassPreconditioning="      "
}

function __static__FindFirstOccurenceAfterLabel()
{
    awk -v sectionRegex="$1"\
        -v stringRegex="$2"\
        'BEGIN{sectionFound=0; replaced=0}
        {
            if(sectionFound==0)
            {
                if($0 ~ sectionRegex){sectionFound=1};
                next
            }
            else
            {
                if($0 ~ stringRegex)
                {
                    print $2
                    exit
                }
                next
            }
        }
        ' "${inputFileGlobalPath}" #function's return code is that of awk
}


MakeFunctionsDefinedInThisFileReadonly
