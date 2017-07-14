#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

function __static__AddToInputFile()
{
    while [ $# -ne 0 ]; do
        printf "%s\n" "$1" >> $inputFileGlobalPath
        shift
    done
}

function ProduceInputFile_CL2QCD()
{
    local betaValue inputFileGlobalPath numberOfTrajectoriesToBeDone
    betaValue="$1"
    inputFileGlobalPath="$2"
    numberOfTrajectoriesToBeDone=$3
    rm -f $inputFileGlobalPath || exit $BHMAS_fatalBuiltin
    touch $inputFileGlobalPath || exit $BHMAS_fatalBuiltin

    #This input file is for CL2QCD only!
    if [ $BHMAS_wilson = "TRUE" ]; then
        __static__AddToInputFile "fermact=wilson"
    elif [ $BHMAS_staggered = "TRUE" ]; then
        __static__AddToInputFile \
            "fermact=rooted_stagg"\
            "num_tastes=$BHMAS_nflavour"
        if [ $BHMAS_useRationalApproxFiles = "TRUE" ]; then
            __static__AddToInputFile \
                "read_rational_approximations_from_file=1"\
                "approx_heatbath_file=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_${BHMAS_approxHeatbathFilename}"\
                "approx_md_file=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_${BHMAS_approxMDFilename}"\
                "approx_metropolis_file=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_${BHMAS_approxMetropolisFilename}"
        else
            __static__AddToInputFile "read_rational_approximations_from_file=0"
        fi
        __static__AddToInputFile "findminmax_max=10000"
    fi
    __static__AddToInputFile \
        "use_cpu=false"\
        "theta_fermion_spatial=0"\
        "theta_fermion_temporal=1"\
        "use_eo=1"
    if [ $BHMAS_chempot = "0" ]; then
        __static__AddToInputFile "use_chem_pot_im=0"
    else
        __static__AddToInputFile "use_chem_pot_im=1"
        if [ $BHMAS_chempot = "PiT" ]; then
            __static__AddToInputFile "chem_pot_im=0.523598775598299"
        else
            Fatal $BHMAS_fatalValueError "Unknown value " emph "$BHMAS_chempot" " of imaginary chemical potential for input file!"
        fi
    fi
    #Information about solver and measurements
    __static__AddToInputFile \
        "solver=cg"\
        "cgmax=15000"\
        "measure_correlators=0"
    if [ $BHMAS_measurePbp = "TRUE" ]; then
        __static__AddToInputFile \
            "measure_pbp=1"\
            "sourcetype=volume"\
            "sourcecontent=gaussian"
        if [ $BHMAS_wilson = "TRUE" ]; then
            __static__AddToInputFile "num_sources=16"
        elif [ $BHMAS_staggered = "TRUE" ]; then
            __static__AddToInputFile \
                "num_sources=1"\
                "pbp_measurements=8"
        fi
        __static__AddToInputFile \
            "ferm_obs_to_single_file=1"\
            "ferm_obs_pbp_prefix=${BHMAS_outputFilename}"
    fi
    #Information about integrators
    if [ $BHMAS_wilson = "TRUE" ]; then
        __static__AddToInputFile \
            "iter_refresh=2000"\
            "use_merge_kernels_fermion=1"
        if KeyInArray "$betaValue" BHMAS_massPreconditioningValues; then
            __static__AddToInputFile \
                "cg_iteration_block_size=10"\
                "use_mp=1"\
                "solver_mp=cg"\
                "kappa_mp=0.${BHMAS_massPreconditioningValues[$betaValue]#*,}"\
                "num_timescales=3"\
                "integrator2=twomn"\
                "integrationsteps2=${BHMAS_massPreconditioningValues[$betaValue]%,*}"
        else
            __static__AddToInputFile \
                "cg_iteration_block_size=$BHMAS_inverterBlockSize"\
                "num_timescales=2"
        fi
    elif [ $BHMAS_staggered = "TRUE" ]; then
        __static__AddToInputFile \
            "cg_iteration_block_size=$BHMAS_inverterBlockSize"\
            "num_timescales=2"
    fi
    __static__AddToInputFile \
        "tau=1"\
        "integrator0=twomn"\
        "integrator1=twomn"\
        "integrationsteps0=${BHMAS_scaleZeroIntegrationSteps[$betaValue]}"\
        "integrationsteps1=${BHMAS_scaleOneIntegrationSteps[$betaValue]}"\
        "nspace=$BHMAS_nspace"\
        "ntime=$BHMAS_ntime"
    if [ $BHMAS_wilson = "TRUE" ]; then
        __static__AddToInputFile \
            "kappa=0.$BHMAS_mass"\
            "hmcsteps=$numberOfTrajectoriesToBeDone"
    elif [ $BHMAS_staggered = "TRUE" ]; then
        __static__AddToInputFile \
            "mass=0.$BHMAS_mass"\
            "rhmcsteps=$numberOfTrajectoriesToBeDone"
    fi
    __static__AddToInputFile \
        "savefrequency=$BHMAS_checkpointFrequency"\
        "savepointfrequency=$BHMAS_savepointFrequency"
    if [ ${BHMAS_startConfigurationGlobalPath[$betaValue]} == "notFoundHenceStartFromHot" ]; then
        __static__AddToInputFile "startcondition=hot"
    else
        __static__AddToInputFile \
            "startcondition=continue"\
            "sourcefile=${BHMAS_startConfigurationGlobalPath[$betaValue]}"
    fi
    if [ $BHMAS_useMultipleChains == "TRUE" ]; then
        local SEED_EXTRACTED_FROM_BETA="$(awk '{split($1, result, "_"); print substr(result[2],2)}' <<< "$betaValue")"
        if [[ ! $SEED_EXTRACTED_FROM_BETA =~ ^[[:digit:]]{4}$ ]] || [[ $SEED_EXTRACTED_FROM_BETA == "0000" ]]; then
            Fatal $BHMAS_fatalValueError "Seed " emph "$SEED_EXTRACTED_FROM_BETA" " not allowed to be put in inputfile for CL2QCD!"
        else
            __static__AddToInputFile "host_seed=$SEED_EXTRACTED_FROM_BETA"
        fi
    fi
}
