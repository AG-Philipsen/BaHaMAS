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

function ProduceInputFile_openQCD-FASTSUM()
{
    local runId inputFileGlobalPath numberOfTrajectoriesToBeDone\
          betaValue seedValue massAsNumber nTimeScales scaleOneIntegrationStepsToBeUsed\
          forcesInLevelZero solverToBeUsed sapArrayToBeUsed
    runId="$1"
    inputFileGlobalPath="$2"
    numberOfTrajectoriesToBeDone=$3
    if [[ ! ${runId} =~ ^(${BHMAS_betaRegex//\\/})_${BHMAS_seedPrefix}(${BHMAS_seedRegex//\\/})${BHMAS_betaPostfix}$ ]]; then
        Internal 'Run ID ' emph "${runId}" ' in ' emph "${FUNCNAME}" ' does not match expected format!'
    else
        betaValue=${BASH_REMATCH[1]}
        seedValue=${BASH_REMATCH[2]}
    fi
    if [[ $(grep -c "[.]" <<< "${BHMAS_mass}") -eq 0 ]]; then
        massAsNumber="0.${BHMAS_mass}"
    else
        massAsNumber="${BHMAS_mass}"
    fi

    # Handle integrator time scales here
    if KeyInArray "${runId}" BHMAS_scaleOneIntegrationSteps; then # Second timescale was specified
        nTimeScales=2
        forcesInLevelZero='0'
        scaleOneIntegrationStepsToBeUsed="${BHMAS_scaleOneIntegrationSteps[${runId}]}"
    else # Just one timescale specified in the betas file
        nTimeScales=1
        forcesInLevelZero='0 1'
        scaleOneIntegrationStepsToBeUsed=1 #placeholder in input file, not used
    fi

    # This check has to be done here because the number of
    # trjectories can be different from beta to beta.
    if (( numberOfTrajectoriesToBeDone % BHMAS_checkpointFrequency != 0 )); then
        Fatal ${BHMAS_fatalCommandLine} \
            'openQCD-FASTSUM requires the number of to-be-done trajectories\n'\
            ' to be multiple of the gap between checkpoints. The choosen vales\n'\
            emph "    trajectoriesToBeDone=${numberOfTrajectoriesToBeDone}\n"\
            emph "         checkpointEvery=${BHMAS_checkpointFrequency}\n"\
            'are not valid. Please adjust them and run the script again.'
    fi

    if [[ ${#BHMAS_sapBlockSize[@]} -eq 0 ]]; then
        solverToBeUsed=(0 1)
        sapArrayToBeUsed=(1 1 1 1) #placeholder in input file, not used
    else
        solverToBeUsed=(2 3)
        sapArrayToBeUsed=( ${BHMAS_sapBlockSize[@]} )
    fi

    #ATTENTION: Since openQCD-FASTSUM supports it, it is better to always put in the
    #           input file all blocks of information, even though some might not be used.
    #           This simplifies a lot the continue logic, since there we can then assume
    #           that blocks of input are in the inputfile (e.g. switch from 1 to 2 timescales).
    exec 5>&1 1> "${inputFileGlobalPath}"

    cat <<END_OF_INPUTFILE
[Run name]
name         ${BHMAS_outputFilename}

[Directories]
log_dir      ${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${beta}
dat_dir      ${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${beta}
loc_dir      ${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${beta}
cnfg_dir     ${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${beta}

[Random number generator]
level        0
seed         ${seedValue}

[Lattice parameters]
beta         ${betaValue}
c0           1
kappa        ${massAsNumber}
csw          0

[Boundary conditions]
type         3
theta        0.0 0.0 0.0

[HMC parameters]
actions      0 1
npf          1
mu           0.0
nlv          ${nTimeScales}
tau          1

[MD trajectories]
nth          0
ntr          ${numberOfTrajectoriesToBeDone}
dtr_log      1
dtr_ms       10000000 # i.e. never measure
dtr_cnfg     ${BHMAS_checkpointFrequency}

[Action 0]
action       ACG

[Action 1]
action       ACF_TM1
ipf          0
im0          0
imu          0
isp          ${solverToBeUsed[1]}

[Action 2]
action       ACF_TM1_EO_SDET
ipf          0
im0          0
imu          0
isp          ${solverToBeUsed[1]}

[Force 0]
force        FRG

[Force 1]
force        FRF_TM1
isp          ${solverToBeUsed[0]}
ncr          0

[Force 2]
force        FRF_TM1_EO_SDET
isp          ${solverToBeUsed[0]}
ncr          0

[Solver 0]
solver       CGNE
nmx          ${BHMAS_inverterMaxIterations}
res          1.0e-6

[Solver 1]
solver       CGNE
nmx          ${BHMAS_inverterMaxIterations}
res          1.0e-12

[Level 0]
integrator   OMF2
lambda       0.1931833275037836
nstep        ${BHMAS_scaleZeroIntegrationSteps[${runId}]}
forces       ${forcesInLevelZero}

[Level 1]
integrator   OMF2
lambda       0.1931833275037836
nstep        ${scaleOneIntegrationStepsToBeUsed}
forces       1

[SAP]
bs ${sapArrayToBeUsed[@]}

[Solver 2]
solver SAP_GCR
nkv 16
isolv 1
nmr 4
ncy 5
nmx 24
res 1.0e-6

[Solver 3]
solver SAP_GCR
nkv 16
isolv 1
nmr 4
ncy 5
nmx 24
res 1.0e-12

END_OF_INPUTFILE

    exec 1>&5-
}
