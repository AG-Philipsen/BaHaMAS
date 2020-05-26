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
function CreateOutputFileInTheStandardFormat_openQCD-FASTSUM()
{
    local runId  softwareOutputFileGlobalPath trShift
    runId="$1"
    softwareOutputFileGlobalPath="$(dirname "${outputFileGlobalPath}")/${BHMAS_outputFilename}.log"
    if [[ ! -f "${softwareOutputFileGlobalPath}" ]]; then
        Error 'openQCD-FASTSUM output file ' file "${softwareOutputFileGlobalPath}"\
              '\nwas not found but expected.'
        return
    fi
    if ! trShift=$(ExtractTrajectoryNumberFromConfigurationSymlink "${runId}"); then
        Error 'Unable to extract initial trajectory number from configuration symlink\n'\
              'for run ID ' emph "${runId}" ' and hence not able to create standardized output.'
        return
    fi
    # NOTE: "N.A." is printed for information that openQCD does not give
    #       "nan" are printed for not found numbers -> https://stackoverflow.com/a/23622339
    awk -v offset="${trShift}"\
        '
        {
            if( $0 ~ /^Trajectory no [1-9][0-9]*$/ )
            {
                tr=offset+$3
                trajectories[tr]=tr
                next
            }
            if( $0 ~ /^dH =/ )
            {
                split($0, result, "(,| = )");
                deltaH[tr]=result[2]
                accepted[tr]=result[4]
                next
            }
            if( $0 ~ /^Average plaquette =/ )
            {
                plaq[tr]=$4
                next
            }
            if( $0 ~ /^Polyakov loop =/ )
            {
                polyRe[tr]=$4
                polyIm[tr]=$5
                polySq[tr]=sqrt($4**2+$5**2)
                next
            }
            if( $0 ~ /^Time per trajectory =/ )
            {
                trTime[tr]=$5
                next
            }

        }
        END{
            for(tr in trajectories)
            {
                if(deltaH[tr] == ""){deltaH[tr]="nan"}
                if(accepted[tr] == ""){accepted[tr]="nan"}
                if(plaq[tr] == ""){plaq[tr]="nan"}
                if(polyRe[tr] == ""){polyRe[tr]="nan"}
                if(polyIm[tr] == ""){polyIm[tr]="nan"}
                if(polySq[tr] == ""){polySq[tr]="nan"}
                printf "%8d%25s%10s%10s%25s%25s%25.15f%15s%6d%10.1f\n", tr, plaq[tr], "N.A.", "N.A.", polyRe[tr], polyIm[tr], polySq[tr], deltaH[tr], accepted[tr], trTime[tr]
            }
        }' "${softwareOutputFileGlobalPath}" > "${outputFileGlobalPath}"
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
