#
#  Copyright (c)
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

function __static__AddToInputFile()
{
    while [ $# -ne 0 ]; do
        printf "%s\n" "$1" >> $inputFileGlobalPath
        shift
    done
}

function ProduceInputFile_CL2QCD()
{
    local betaValue inputFileGlobalPath numberOfTrajectoriesToBeDone massAsNumber
    betaValue="$1"
    inputFileGlobalPath="$2"
    numberOfTrajectoriesToBeDone=$3
    rm -f $inputFileGlobalPath || exit $BHMAS_fatalBuiltin
    touch $inputFileGlobalPath || exit $BHMAS_fatalBuiltin
    if [ $(grep -c "[.]" <<< "${BHMAS_mass}") -eq 0 ]; then
        massAsNumber="0.${BHMAS_mass}"
    else
        massAsNumber="${BHMAS_mass}"
    fi

    #This input file is for CL2QCD only!
    if [ $BHMAS_wilson = "TRUE" ]; then
        __static__AddToInputFile "fermionAction=wilson"
    elif [ $BHMAS_staggered = "TRUE" ]; then
        __static__AddToInputFile \
            "fermionAction=rooted_stagg"\
            "nTastes=$BHMAS_nflavour"
        if [ $BHMAS_useRationalApproxFiles = "TRUE" ]; then
            __static__AddToInputFile "readRationalApproxFromFile=1"
            if [ $BHMAS_numberOfPseudofermions -eq 1 ]; then
                __static__AddToInputFile\
                    "rationalApproxFileHB=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_${BHMAS_approxHeatbathFilename}"\
                    "rationalApproxFileMD=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_${BHMAS_approxMDFilename}"\
                    "rationalApproxFileMetropolis=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_${BHMAS_approxMetropolisFilename}"
            else
                __static__AddToInputFile\
                    "rationalApproxFileHB=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_pf${BHMAS_numberOfPseudofermions}_${BHMAS_approxHeatbathFilename}"\
                    "rationalApproxFileMD=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_pf${BHMAS_numberOfPseudofermions}_${BHMAS_approxMDFilename}"\
                    "rationalApproxFileMetropolis=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_pf${BHMAS_numberOfPseudofermions}_${BHMAS_approxMetropolisFilename}"
            fi
        else
            __static__AddToInputFile "readRationalApproxFromFile=0"
        fi
        __static__AddToInputFile "nPseudoFermions=${BHMAS_numberOfPseudofermions}"\
                                 "findminmaxMaxIterations=10000"

    fi
    __static__AddToInputFile \
        "useCPU=false"\
        "thetaFermionSpatial=0"\
        "thetaFermionTemporal=1"\
        "useEO=1"
    if [ $BHMAS_chempot = "0" ]; then
        __static__AddToInputFile "useChemicalPotentialIm=0"
    else
        __static__AddToInputFile "useChemicalPotentialIm=1"
        if [ $BHMAS_chempot = "PiT" ]; then
            __static__AddToInputFile "chemicalPotentialIm=$(awk -v ntime="${BHMAS_ntime}" 'BEGIN{printf "%.15f\n", atan2(0, -1)/ntime}')"
        else
            Fatal $BHMAS_fatalValueError "Unknown value " emph "$BHMAS_chempot" " of imaginary chemical potential for input file!"
        fi
    fi
    #Information about solver and measurements
    if [ $BHMAS_wilson = "TRUE" ]; then
        __static__AddToInputFile "solver=cg"
    fi
    __static__AddToInputFile \
        "solverMaxIterations=15000"\
        "measureCorrelators=0"
    if [ $BHMAS_measurePbp = "TRUE" ]; then
        __static__AddToInputFile \
            "measurePbp=1"\
            "sourceType=volume"\
            "sourceContent=gaussian"
        if [ $BHMAS_wilson = "TRUE" ]; then
            __static__AddToInputFile "nSources=16"
        elif [ $BHMAS_staggered = "TRUE" ]; then
            __static__AddToInputFile \
                "nSources=1"\
                "pbpMeasurements=8"
        fi
        __static__AddToInputFile \
            "fermObsInSingleFile=1"\
            "fermObsPbpPrefix=${BHMAS_outputFilename}"
    fi
    #Information about integrators
    if [ $BHMAS_wilson = "TRUE" ]; then
        __static__AddToInputFile \
            "solverRestartEvery=2000"\
            "useKernelMergingFermionMatrix=1"
        if KeyInArray "$betaValue" BHMAS_massPreconditioningValues; then
            __static__AddToInputFile \
                "solverResiduumCheckEvery=10"\
                "useMP=1"\
                "solverMP=cg"\
                "kappaMP=0.${BHMAS_massPreconditioningValues[$betaValue]#*,}"\
                "nTimeScales=3"\
                "integrator2=twomn"\
                "integrationSteps2=${BHMAS_massPreconditioningValues[$betaValue]%,*}"
        else
            __static__AddToInputFile \
                "solverResiduumCheckEvery=$BHMAS_inverterBlockSize"\
                "nTimeScales=2"
        fi
    elif [ $BHMAS_staggered = "TRUE" ]; then
        __static__AddToInputFile \
            "solverResiduumCheckEvery=$BHMAS_inverterBlockSize"\
            "nTimeScales=2"
    fi
    __static__AddToInputFile \
        "tau=1"\
        "integrator0=twomn"\
        "integrator1=twomn"\
        "integrationSteps0=${BHMAS_scaleZeroIntegrationSteps[$betaValue]}"\
        "integrationSteps1=${BHMAS_scaleOneIntegrationSteps[$betaValue]}"\
        "nSpace=$BHMAS_nspace"\
        "nTime=$BHMAS_ntime"
    if [ $BHMAS_wilson = "TRUE" ]; then
        __static__AddToInputFile \
            "kappa=${massAsNumber}"\
            "nHmcSteps=$numberOfTrajectoriesToBeDone"
    elif [ $BHMAS_staggered = "TRUE" ]; then
        __static__AddToInputFile \
            "mass=${massAsNumber}"\
            "nRhmcSteps=$numberOfTrajectoriesToBeDone"
    fi
    __static__AddToInputFile \
        "createCheckpointEvery=$BHMAS_checkpointFrequency"\
        "overwriteTemporaryCheckpointEvery=$BHMAS_savepointFrequency"
    if [ ${BHMAS_startConfigurationGlobalPath[$betaValue]} == "notFoundHenceStartFromHot" ]; then
        __static__AddToInputFile "startCondition=hot"
    else
        __static__AddToInputFile \
            "startCondition=continue"\
            "initialConf=${BHMAS_startConfigurationGlobalPath[$betaValue]}"
    fi
    if [ $BHMAS_useMultipleChains == "TRUE" ]; then
        local SEED_EXTRACTED_FROM_BETA="$(awk '{split($1, result, "_"); print substr(result[2],2)}' <<< "$betaValue")"
        if [[ ! $SEED_EXTRACTED_FROM_BETA =~ ^[[:digit:]]{4}$ ]] || [[ $SEED_EXTRACTED_FROM_BETA == "0000" ]]; then
            Fatal $BHMAS_fatalValueError "Seed " emph "$SEED_EXTRACTED_FROM_BETA" " not allowed to be put in inputfile for CL2QCD!"
        else
            __static__AddToInputFile "hostSeed=$SEED_EXTRACTED_FROM_BETA"
        fi
    fi
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         __static__AddToInputFile\
         ProduceInputFile_CL2QCD
