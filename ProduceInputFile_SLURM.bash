function __static__AddToInputFile()
{
    while [ $# -ne 0 ]; do
        printf "%s\n" "$1" >> $INPUTFILE_GLOBALPATH
        shift
    done
}

function ProduceInputFile_SLURM()
{
    rm -f $INPUTFILE_GLOBALPATH || exit -2
    touch $INPUTFILE_GLOBALPATH || exit -2

    #This input file is for CL2QCD only!
    if [ $WILSON = "TRUE" ]; then
        __static__AddToInputFile "fermact=wilson"
    elif [ $STAGGERED = "TRUE" ]; then
        __static__AddToInputFile \
            "fermact=rooted_stagg"\
            "num_tastes=$NFLAVOUR"
        if [ $USE_RATIONAL_APPROXIMATION_FILE = "TRUE" ]; then
            __static__AddToInputFile \
                "read_rational_approximations_from_file=1"\
                "approx_heatbath_file=${RATIONAL_APPROXIMATIONS_PATH}/Nf${NFLAVOUR}_${APPROX_HEATBATH_NAME}"\
                "approx_md_file=${RATIONAL_APPROXIMATIONS_PATH}/Nf${NFLAVOUR}_${APPROX_MD_NAME}"\
                "approx_metropolis_file=${RATIONAL_APPROXIMATIONS_PATH}/Nf${NFLAVOUR}_${APPROX_METROPOLIS_NAME}"
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
    if [ $CHEMPOT = "0" ]; then
        __static__AddToInputFile "use_chem_pot_im=0"
    else
        __static__AddToInputFile "use_chem_pot_im=1"
        if [ $CHEMPOT = "PiT" ]; then
            __static__AddToInputFile "chem_pot_im=0.523598775598299"
        else
            cecho "\n" r " Unknown value of imaginary chemical potential for input file! Aborting...\n"
            exit -1
        fi
    fi
    #Information about solver and measurements
    __static__AddToInputFile \
        "solver=cg"\
        "cgmax=15000"\
        "measure_correlators=0"
    if [ $MEASURE_PBP = "TRUE" ]; then
        __static__AddToInputFile \
            "measure_pbp=1"\
            "sourcetype=volume"\
            "sourcecontent=gaussian"
        if [ $WILSON = "TRUE" ]; then
            __static__AddToInputFile "num_sources=16"
        elif [ $STAGGERED = "TRUE" ]; then
            __static__AddToInputFile \
                "num_sources=1"\
                "pbp_measurements=8"
        fi
        __static__AddToInputFile \
            "ferm_obs_to_single_file=1"\
            "ferm_obs_pbp_prefix=${OUTPUTFILE_NAME}"
    fi
    #Information about integrators
    if [ $WILSON = "TRUE" ]; then
        __static__AddToInputFile \
            "iter_refresh=2000"\
            "use_merge_kernels_fermion=1"
        if KeyInArray "${BETAVALUES_COPY[$INDEX]}" MASS_PRECONDITIONING_ARRAY; then
            __static__AddToInputFile \
                "cg_iteration_block_size=10"\
                "use_mp=1"\
                "solver_mp=cg"\
                "kappa_mp=0.${MASS_PRECONDITIONING_ARRAY[${BETAVALUES_COPY[$INDEX]}]#*,}"\
                "num_timescales=3"\
                "integrator2=twomn"\
                "integrationsteps2=${MASS_PRECONDITIONING_ARRAY[${BETAVALUES_COPY[$INDEX]}]%,*}"
        else
            __static__AddToInputFile \
                "cg_iteration_block_size=$CGBS"\
                "num_timescales=2"
        fi
    elif [ $STAGGERED = "TRUE" ]; then
        __static__AddToInputFile \
            "cg_iteration_block_size=$CGBS"\
            "num_timescales=2"
    fi
    __static__AddToInputFile \
        "tau=1"\
        "integrator0=twomn"\
        "integrator1=twomn"\
        "integrationsteps0=${INTSTEPS0_ARRAY[${BETAVALUES_COPY[$INDEX]}]}"\
        "integrationsteps1=${INTSTEPS1_ARRAY[${BETAVALUES_COPY[$INDEX]}]}"\
        "nspace=$NSPACE"\
        "ntime=$NTIME"
    if [ $WILSON = "TRUE" ]; then
        __static__AddToInputFile \
            "kappa=0.$MASS"\
            "hmcsteps=$MEASUREMENTS"
    elif [ $STAGGERED = "TRUE" ]; then
        __static__AddToInputFile \
            "mass=0.$MASS"\
            "rhmcsteps=$MEASUREMENTS"
    fi
    __static__AddToInputFile \
        "savefrequency=$NSAVE"\
        "savepointfrequency=$NSAVEPOINT"
    if [ ${STARTCONFIGURATION_GLOBALPATH[${BETAVALUES_COPY[$INDEX]}]} == "notFoundHenceStartFromHot" ]; then
        __static__AddToInputFile "startcondition=hot"
    else
        __static__AddToInputFile \
            "startcondition=continue"\
            "sourcefile=${STARTCONFIGURATION_GLOBALPATH[${BETAVALUES_COPY[$INDEX]}]}"
    fi
    if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then
        local SEED_EXTRACTED_FROM_BETA="$(echo ${BETAVALUES_COPY[$INDEX]} | awk '{split($1, result, "_"); print substr(result[2],2)}')"
        if [[ ! $SEED_EXTRACTED_FROM_BETA =~ ^[[:digit:]]{4}$ ]] || [[ $SEED_EXTRACTED_FROM_BETA == "0000" ]]; then
            cecho "\n" r " Seed not allowed to be put in inputfile for CL2QCD! Aborting...\n"
            exit -1
        else
            __static__AddToInputFile "host_seed=$SEED_EXTRACTED_FROM_BETA"
        fi
    fi
}
