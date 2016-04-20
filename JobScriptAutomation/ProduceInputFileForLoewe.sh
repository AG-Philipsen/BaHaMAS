function ProduceInputFile_Loewe() {
    rm -f $INPUTFILE_GLOBALPATH || exit -2
    touch $INPUTFILE_GLOBALPATH || exit -2
    #This input file is for CL2QCD only!
    if [ $WILSON = "TRUE" ]; then
        echo "fermact=wilson" >> $INPUTFILE_GLOBALPATH
    elif [ $STAGGERED = "TRUE" ]; then
        echo "fermact=rooted_stagg" >> $INPUTFILE_GLOBALPATH
        echo "num_tastes=$NFLAVOUR" >> $INPUTFILE_GLOBALPATH
        if [ $USE_RATIONAL_APPROXIMATION_FILE = "TRUE" ]; then
            echo "read_rational_approximations_from_file=1" >> $INPUTFILE_GLOBALPATH
            echo "approx_heatbath_file=${RATIONAL_APPROXIMATIONS_PATH}/Nf${NFLAVOUR}_${APPROX_HEATBATH_NAME}" >> $INPUTFILE_GLOBALPATH
            echo "approx_md_file=${RATIONAL_APPROXIMATIONS_PATH}/Nf${NFLAVOUR}_${APPROX_MD_NAME}" >> $INPUTFILE_GLOBALPATH
            echo "approx_metropolis_file=${RATIONAL_APPROXIMATIONS_PATH}/Nf${NFLAVOUR}_${APPROX_METROPOLIS_NAME}" >> $INPUTFILE_GLOBALPATH
        else
            echo "read_rational_approximations_from_file=0" >> $INPUTFILE_GLOBALPATH
        fi
        echo "findminmax_max=10000" >> $INPUTFILE_GLOBALPATH
    fi
    echo "use_cpu=false" >> $INPUTFILE_GLOBALPATH
    echo "theta_fermion_spatial=0" >> $INPUTFILE_GLOBALPATH
    echo "theta_fermion_temporal=1" >> $INPUTFILE_GLOBALPATH
    echo "use_eo=1" >> $INPUTFILE_GLOBALPATH
    if [ $CHEMPOT = "0" ]; then
        echo "use_chem_pot_im=0" >> $INPUTFILE_GLOBALPATH
    else
        echo "use_chem_pot_im=1" >> $INPUTFILE_GLOBALPATH
        if [ $CHEMPOT = "PiT" ]; then
            echo "chem_pot_im=0.523598775598299" >> $INPUTFILE_GLOBALPATH
        else
            printf "\n\e[0;31m Unknown value of imaginary chemical potential for input file! Aborting...\n\n\e[0m" 
            exit -1
        fi
    fi
    #Information about solver and measurements
    echo "solver=cg" >> $INPUTFILE_GLOBALPATH
    echo "cgmax=8000" >> $INPUTFILE_GLOBALPATH
    echo "measure_correlators=0" >> $INPUTFILE_GLOBALPATH
    if [ $MEASURE_PBP = "TRUE" ]; then
        echo "measure_pbp=1" >> $INPUTFILE_GLOBALPATH
        echo "sourcetype=volume" >> $INPUTFILE_GLOBALPATH
        echo "sourcecontent=gaussian" >> $INPUTFILE_GLOBALPATH
        if [ $WILSON = "TRUE" ]; then
            echo "num_sources=16" >> $INPUTFILE_GLOBALPATH
        elif [ $STAGGERED = "TRUE" ]; then
            echo "num_sources=1" >> $INPUTFILE_GLOBALPATH
            echo "pbp_measurements=8" >> $INPUTFILE_GLOBALPATH
        fi
        echo "ferm_obs_to_single_file=1" >> $INPUTFILE_GLOBALPATH
        echo "ferm_obs_pbp_prefix=${OUTPUTFILE_NAME}" >> $INPUTFILE_GLOBALPATH
    fi
    #Information about integrators
    if [ $WILSON = "TRUE" ]; then    
        echo "iter_refresh=2000" >> $INPUTFILE_GLOBALPATH
        echo "use_merge_kernels_fermion=1" >> $INPUTFILE_GLOBALPATH
        if KeyInArray "${BETAVALUES_COPY[$INDEX]}" MASS_PRECONDITIONING_ARRAY; then
            echo "cg_iteration_block_size=10" >> $INPUTFILE_GLOBALPATH
            echo "use_mp=1" >> $INPUTFILE_GLOBALPATH
            echo "solver_mp=cg" >> $INPUTFILE_GLOBALPATH
            echo "kappa_mp=0.${MASS_PRECONDITIONING_ARRAY[${BETAVALUES_COPY[$INDEX]}]#*,}" >> $INPUTFILE_GLOBALPATH
            echo "num_timescales=3" >> $INPUTFILE_GLOBALPATH
            echo "integrator2=twomn" >> $INPUTFILE_GLOBALPATH
            echo "integrationsteps2=${MASS_PRECONDITIONING_ARRAY[${BETAVALUES_COPY[$INDEX]}]%,*}" >> $INPUTFILE_GLOBALPATH
        else
            echo "cg_iteration_block_size=$CGBS" >> $INPUTFILE_GLOBALPATH
            echo "num_timescales=2" >> $INPUTFILE_GLOBALPATH
        fi
    elif [ $STAGGERED = "TRUE" ]; then
        echo "cg_iteration_block_size=$CGBS" >> $INPUTFILE_GLOBALPATH
        echo "num_timescales=2" >> $INPUTFILE_GLOBALPATH
    fi
    echo "tau=1" >> $INPUTFILE_GLOBALPATH
    echo "integrator0=twomn" >> $INPUTFILE_GLOBALPATH
    echo "integrator1=twomn" >> $INPUTFILE_GLOBALPATH
    echo "integrationsteps0=${INTSTEPS0_ARRAY[${BETAVALUES_COPY[$INDEX]}]}" >> $INPUTFILE_GLOBALPATH
    echo "integrationsteps1=${INTSTEPS1_ARRAY[${BETAVALUES_COPY[$INDEX]}]}" >> $INPUTFILE_GLOBALPATH
    #Information about physical parameters
    echo "nspace=$NSPACE" >> $INPUTFILE_GLOBALPATH
    echo "ntime=$NTIME" >> $INPUTFILE_GLOBALPATH
    if [ $WILSON = "TRUE" ]; then
        echo "kappa=0.$MASS" >> $INPUTFILE_GLOBALPATH
        echo "hmcsteps=$MEASUREMENTS" >> $INPUTFILE_GLOBALPATH
    elif [ $STAGGERED = "TRUE" ]; then
        echo "mass=0.$MASS" >> $INPUTFILE_GLOBALPATH
        echo "rhmcsteps=$MEASUREMENTS" >> $INPUTFILE_GLOBALPATH
    fi
    echo "savefrequency=$NSAVE" >> $INPUTFILE_GLOBALPATH
    echo "savepointfrequency=$NSAVEPOINT" >> $INPUTFILE_GLOBALPATH
    if [ ${STARTCONFIGURATION_GLOBALPATH[${BETAVALUES_COPY[$INDEX]}]} == "notFoundHenceStartFromHot" ]; then
        echo "startcondition=hot" >> $INPUTFILE_GLOBALPATH
    else
        echo "startcondition=continue" >> $INPUTFILE_GLOBALPATH
        echo "sourcefile=${STARTCONFIGURATION_GLOBALPATH[${BETAVALUES_COPY[$INDEX]}]}" >> $INPUTFILE_GLOBALPATH
    fi
    if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then
        local SEED_EXTRACTED_FROM_BETA="$(echo ${BETAVALUES_COPY[$INDEX]} | awk '{split($1, result, "_"); print substr(result[2],2)}')"
        if [[ ! $SEED_EXTRACTED_FROM_BETA =~ ^[[:digit:]]{4}$ ]] || [[ $SEED_EXTRACTED_FROM_BETA == "0000" ]]; then
            printf "\n\e[0;31m Seed not allowed to be put in inputfile for CL2QCD! Aborting...\n\n\e[0m" 
            exit -1
        else
            echo "host_seed=$SEED_EXTRACTED_FROM_BETA" >> $INPUTFILE_GLOBALPATH
        fi
    fi

	#Copy input file from homedir to workdir, in case they are different
	if [ $HOME_DIR != $WORK_DIR ] && [ -d $WORK_BETADIRECTORY ];then
		cp $INPUTFILE_GLOBALPATH  $WORK_BETADIRECTORY/$INPUTFILE_NAME
	fi	
}


