#!/bin/sh

if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then

    echo '#######################################################' > $INPUTFILE_GLOBALPATH
    echo '## sample tmlqcd input file for imagMu runs on Juqueen' >> $INPUTFILE_GLOBALPATH
    echo "##beta =	$BETA	" >> $INPUTFILE_GLOBALPATH
    echo "##kappa =	0.$KAPPA" >> $INPUTFILE_GLOBALPATH
    echo '##amu =	0.' >> $INPUTFILE_GLOBALPATH
    echo '##2kappamu =	0.' >> $INPUTFILE_GLOBALPATH
    echo '##apply mass preconditioning with' >> $INPUTFILE_GLOBALPATH
    echo '##2kappamu2 =	notUsedYet' >> $INPUTFILE_GLOBALPATH
    echo '' >> $INPUTFILE_GLOBALPATH
    echo '#######################################################' >> $INPUTFILE_GLOBALPATH
    echo '## mass parameters' >> $INPUTFILE_GLOBALPATH
    echo "kappa = 0.$KAPPA" >> $INPUTFILE_GLOBALPATH
    echo '2KappaMu = 0.' >> $INPUTFILE_GLOBALPATH
    echo '' >> $INPUTFILE_GLOBALPATH
    echo '#######################################################' >> $INPUTFILE_GLOBALPATH
    echo '## global parameters' >> $INPUTFILE_GLOBALPATH
    echo "L = $NSPACE" >> $INPUTFILE_GLOBALPATH
    echo "T = $NTIME" >> $INPUTFILE_GLOBALPATH
    echo "Measurements = $MEASUREMENTS" >> $INPUTFILE_GLOBALPATH
    echo "# Total number of trajectories = $MEASUREMENTS" >> $INPUTFILE_GLOBALPATH
    echo '' >> $INPUTFILE_GLOBALPATH
    echo '#######################################################' >> $INPUTFILE_GLOBALPATH
    echo '## MPI parameters' >> $INPUTFILE_GLOBALPATH
    echo "NrXProcs = $NRXPROCS" >> $INPUTFILE_GLOBALPATH
    echo "NrYProcs = $NRYPROCS" >> $INPUTFILE_GLOBALPATH
    echo "NrZProcs = $NRZPROCS" >> $INPUTFILE_GLOBALPATH
    echo '' >> $INPUTFILE_GLOBALPATH
    echo "OmpNumThreads=$OMPNUMTHREADS" >> $INPUTFILE_GLOBALPATH
    echo '' >> $INPUTFILE_GLOBALPATH
    echo '#######################################################' >> $INPUTFILE_GLOBALPATH
    echo '## startconditions' >> $INPUTFILE_GLOBALPATH
    echo '#StartCondition = restart' >> $INPUTFILE_GLOBALPATH
    echo '#StartCondition = cold' >> $INPUTFILE_GLOBALPATH
    echo 'StartCondition = hot' >> $INPUTFILE_GLOBALPATH
    echo '#StartCondition = continue' >> $INPUTFILE_GLOBALPATH
    echo 'InitialStoreCounter = readin' >> $INPUTFILE_GLOBALPATH
    echo '#InitialStoreCounter = 0' >> $INPUTFILE_GLOBALPATH
    echo '' >> $INPUTFILE_GLOBALPATH
    echo '#######################################################' >> $INPUTFILE_GLOBALPATH
    echo '## simulation parameters' >> $INPUTFILE_GLOBALPATH
    echo "Nsave=$NSAVE" >> $INPUTFILE_GLOBALPATH
    echo 'BCAngleT=1.' >> $INPUTFILE_GLOBALPATH
    echo 'UseEvenOdd = yes' >> $INPUTFILE_GLOBALPATH
    echo 'DebugLevel=1' >> $INPUTFILE_GLOBALPATH
    echo 'ThermalisationSweeps = 0' >> $INPUTFILE_GLOBALPATH
    echo '' >> $INPUTFILE_GLOBALPATH
    echo '#######################################################' >> $INPUTFILE_GLOBALPATH
    echo '## measurements' >> $INPUTFILE_GLOBALPATH
    echo 'BeginMeasurement POLYAKOVLOOP' >> $INPUTFILE_GLOBALPATH
    echo '  Frequency = 1' >> $INPUTFILE_GLOBALPATH
    echo 'EndMeasurement' >> $INPUTFILE_GLOBALPATH
    echo '' >> $INPUTFILE_GLOBALPATH
    echo '#BeginMeasurement PIONNORM' >> $INPUTFILE_GLOBALPATH
    echo '#  Frequency = 4' >> $INPUTFILE_GLOBALPATH
    echo '#  MaxSolverIterations = 20000' >> $INPUTFILE_GLOBALPATH
    echo '#EndMeasurement' >> $INPUTFILE_GLOBALPATH
    echo '' >> $INPUTFILE_GLOBALPATH
    echo '#BeginMeasurement CORRELATORS' >> $INPUTFILE_GLOBALPATH
    echo '#  Frequency = 4' >> $INPUTFILE_GLOBALPATH
    echo '#  MaxSolverIterations = 20000' >> $INPUTFILE_GLOBALPATH
    echo '#EndMeasurement' >> $INPUTFILE_GLOBALPATH
    echo '' >> $INPUTFILE_GLOBALPATH
    echo '#######################################################' >> $INPUTFILE_GLOBALPATH
    echo '## monomials' >> $INPUTFILE_GLOBALPATH
    echo 'BeginMonomial GAUGE' >> $INPUTFILE_GLOBALPATH
    echo "  beta=$BETA" >> $INPUTFILE_GLOBALPATH
    echo '  Timescale=0' >> $INPUTFILE_GLOBALPATH
    echo '  Type=wilson' >> $INPUTFILE_GLOBALPATH
    echo 'EndMonomial' >> $INPUTFILE_GLOBALPATH
    echo '' >> $INPUTFILE_GLOBALPATH
    echo 'BeginMonomial DET' >> $INPUTFILE_GLOBALPATH
    echo '  Timescale=1' >> $INPUTFILE_GLOBALPATH
    echo '  2KappaMu=0.' >> $INPUTFILE_GLOBALPATH
    echo "  kappa=0.$KAPPA" >> $INPUTFILE_GLOBALPATH
    echo '  AcceptancePrecision = 1.e-20' >> $INPUTFILE_GLOBALPATH
    echo '  ForcePrecision = 1.e-14' >> $INPUTFILE_GLOBALPATH
    echo '  Name = det' >> $INPUTFILE_GLOBALPATH
    echo '  solver = cg' >> $INPUTFILE_GLOBALPATH
    echo 'EndMonomial' >> $INPUTFILE_GLOBALPATH
    echo '' >> $INPUTFILE_GLOBALPATH
    echo '#BeginMonomial DETRATIO' >> $INPUTFILE_GLOBALPATH
    echo '#  Timescale = 2' >> $INPUTFILE_GLOBALPATH
    echo '#  2KappaMu = 0.' >> $INPUTFILE_GLOBALPATH
    echo '#  2KappaMu2 = notYetUsed' >> $INPUTFILE_GLOBALPATH
    echo "#  kappa = 0.$KAPPA" >> $INPUTFILE_GLOBALPATH
    echo '#  kappa2 = 0.' >> $INPUTFILE_GLOBALPATH
    echo '#  MaxSolverIterations = 20000' >> $INPUTFILE_GLOBALPATH
    echo '#  AcceptancePrecision = 1.e-20' >> $INPUTFILE_GLOBALPATH
    echo '#  ForcePrecision = 1.e-14' >> $INPUTFILE_GLOBALPATH
    echo '#  Name = detrat' >> $INPUTFILE_GLOBALPATH
    echo '#  solver = cg' >> $INPUTFILE_GLOBALPATH
    echo '#EndMonomial' >> $INPUTFILE_GLOBALPATH
    echo '' >> $INPUTFILE_GLOBALPATH
    echo '#######################################################' >> $INPUTFILE_GLOBALPATH
    echo '## integrator settings' >> $INPUTFILE_GLOBALPATH
    echo 'BeginIntegrator' >> $INPUTFILE_GLOBALPATH
    echo '  Type0 = 2MN' >> $INPUTFILE_GLOBALPATH
    echo '  Type1 = 2MN' >> $INPUTFILE_GLOBALPATH
    echo '  Type2 = 2MN' >> $INPUTFILE_GLOBALPATH
    echo "  IntegrationSteps0 = $INTSTEPS0" >> $INPUTFILE_GLOBALPATH
    echo "  IntegrationSteps1 = $INTSTEPS1" >> $INPUTFILE_GLOBALPATH
    echo "  IntegrationSteps2 = $INTSTEPS2" >> $INPUTFILE_GLOBALPATH
    echo '  tau = 1.' >> $INPUTFILE_GLOBALPATH
    echo '  Lambda0 = 0.19' >> $INPUTFILE_GLOBALPATH
    echo '  Lambda1 = 0.21' >> $INPUTFILE_GLOBALPATH
    echo '  Lambda2 = 0.22' >> $INPUTFILE_GLOBALPATH
    echo '  NumberOfTimescales = 2' >> $INPUTFILE_GLOBALPATH
    echo 'EndIntegrator' >> $INPUTFILE_GLOBALPATH

else

    echo "use_cpu=false" > $INPUTFILE_GLOBALPATH
    echo "theta_fermion_spatial=0" >> $INPUTFILE_GLOBALPATH
    echo "theta_fermion_temporal=1" >> $INPUTFILE_GLOBALPATH
    echo "use_chem_pot_im=1" >> $INPUTFILE_GLOBALPATH
    echo "chem_pot_im=0.523598775598299" >> $INPUTFILE_GLOBALPATH
    echo "use_eo=1" >> $INPUTFILE_GLOBALPATH
    echo "solver=cg" >> $INPUTFILE_GLOBALPATH
    if [ $MEASURE_PBP -ne 0 ]; then
	echo "measure_pbp=1" >> $INPUTFILE_GLOBALPATH
	echo "sourcetype=volume" >> $INPUTFILE_GLOBALPATH
	echo "sourcecontent=gaussian" >> $INPUTFILE_GLOBALPATH
	echo "num_sources=16" >> $INPUTFILE_GLOBALPATH
    fi
    echo "tau=1" >> $INPUTFILE_GLOBALPATH
    echo "cgmax=8000" >> $INPUTFILE_GLOBALPATH
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
    echo "startcondition=${STARTCONDITION[$INDEX]}" >> $INPUTFILE_GLOBALPATH
    if [[ "${STARTCONDITION[$INDEX]}" == "continue" ]]; then
	echo "sourcefile=$HOME_BETADIRECTORY/${CONFIGURATION_SOURCEFILE[$INDEX]}" >> $INPUTFILE_GLOBALPATH
    fi
    if [ $USE_MULTIPLE_CHAINS == "TRUE" ]; then
	echo "host_seed=$(echo ${BETAVALUES_COPY[$INDEX]} | awk '{split($1, result, "_"); print substr(result[2],2)}')" >> $INPUTFILE_GLOBALPATH
    fi
fi




