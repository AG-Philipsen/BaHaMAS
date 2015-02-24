function ProduceInputFile_Loewe() {
    #This input file is for CL2QCD only!
    echo "use_cpu=false" > $INPUTFILE_GLOBALPATH
    echo "theta_fermion_spatial=0" >> $INPUTFILE_GLOBALPATH
    echo "theta_fermion_temporal=1" >> $INPUTFILE_GLOBALPATH
    echo "use_chem_pot_im=1" >> $INPUTFILE_GLOBALPATH
    echo "chem_pot_im=0.523598775598299" >> $INPUTFILE_GLOBALPATH
    echo "use_eo=1" >> $INPUTFILE_GLOBALPATH
    echo "solver=cg" >> $INPUTFILE_GLOBALPATH
    echo "measure_correlators=0" >> $INPUTFILE_GLOBALPATH
    if [ $MEASURE_PBP -ne 0 ]; then
	echo "measure_pbp=1" >> $INPUTFILE_GLOBALPATH
	echo "sourcetype=volume" >> $INPUTFILE_GLOBALPATH
	echo "sourcecontent=gaussian" >> $INPUTFILE_GLOBALPATH
	echo "num_sources=16" >> $INPUTFILE_GLOBALPATH
    fi
    echo "tau=1" >> $INPUTFILE_GLOBALPATH
    echo "cgmax=8000" >> $INPUTFILE_GLOBALPATH
    echo "cg_iteration_block_size=50" >> $INPUTFILE_GLOBALPATH
    echo "iter_refresh=2000" >> $INPUTFILE_GLOBALPATH
    echo "use_merge_kernels_fermion=1" >> $INPUTFILE_GLOBALPATH
    echo "num_timescales=2" >> $INPUTFILE_GLOBALPATH
    echo "integrator0=twomn" >> $INPUTFILE_GLOBALPATH
    echo "integrator1=twomn" >> $INPUTFILE_GLOBALPATH
    echo "kappa=0.$KAPPA" >> $INPUTFILE_GLOBALPATH
    echo "nspace=$NSPACE" >> $INPUTFILE_GLOBALPATH
    echo "ntime=$NTIME" >> $INPUTFILE_GLOBALPATH
    echo "hmcsteps=$MEASUREMENTS" >> $INPUTFILE_GLOBALPATH
    echo "integrationsteps0=${INTSTEPS0_ARRAY[${BETAVALUES_COPY[$INDEX]}]}" >> $INPUTFILE_GLOBALPATH
    echo "integrationsteps1=${INTSTEPS1_ARRAY[${BETAVALUES_COPY[$INDEX]}]}" >> $INPUTFILE_GLOBALPATH
    echo "savefrequency=$NSAVE" >> $INPUTFILE_GLOBALPATH
    if [ ${STARTCONFIGURATION_GLOBALPATH[${BETAVALUES_COPY[$INDEX]}]} == "notFoundHenceStartFromHot" ]; then
	echo "startcondition=hot" >> $INPUTFILE_GLOBALPATH
    else
	echo "startcondition=continue" >> $INPUTFILE_GLOBALPATH
	echo "sourcefile=${STARTCONFIGURATION_GLOBALPATH[${BETAVALUES_COPY[$INDEX]}]}" >> $INPUTFILE_GLOBALPATH
    fi
    if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then
	echo "host_seed=$(echo ${BETAVALUES_COPY[$INDEX]} | awk '{split($1, result, "_"); print substr(result[2],2)}')" >> $INPUTFILE_GLOBALPATH
    fi
}
