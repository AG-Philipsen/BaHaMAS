#!/bin/sh

if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
    
    echo '# Script developed by Alessandro Sciarra' > $JOBSCRIPT_GLOBALPATH
    echo '# NOTE: This is only an example. Look for <<< and >>> to find where something' >> $JOBSCRIPT_GLOBALPATH
    echo '#       should be replaced (also "<<<" and ">>>" must be replaced)!)' >> $JOBSCRIPT_GLOBALPATH
    echo '# ' >> $JOBSCRIPT_GLOBALPATH
    echo '# IMPORTANT: This script file MUST be in the input directory, namely IDIR (see below).' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# CRUCIAL: To guarantee the correct working of tmLQCD, and in particular of the' >> $JOBSCRIPT_GLOBALPATH
    echo '#          Polyakov loop measurement, NP (and also bg_size) MUST be 32 times a' >> $JOBSCRIPT_GLOBALPATH
    echo '#	   power of 2. For example, NP=32, NP=64, NP=128, ... are good coices.' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo '##########################################' >> $JOBSCRIPT_GLOBALPATH
    echo '# things to edit' >> $JOBSCRIPT_GLOBALPATH
    echo 'KAPPA='"'""$KAPPA""'"'' >> $JOBSCRIPT_GLOBALPATH
    echo 'NTIME='"'""$NTIME""'"'' >> $JOBSCRIPT_GLOBALPATH
    echo 'NSPACE='"'""$NSPACE""'"'' >> $JOBSCRIPT_GLOBALPATH
    echo 'BETA='"'""$BETA""'"'' >> $JOBSCRIPT_GLOBALPATH
    echo '# @ job_name         = '"$CHEMPOT_PREFIX""$CHEMPOT"'_'"$KAPPA_PREFIX""$KAPPA"'_'"$NTIME_PREFIX""$NTIME"'_'"$NSPACE_PREFIX""$NSPACE"'_'"$BETA_PREFIX""$BETA" >> $JOBSCRIPT_GLOBALPATH
    echo '# @ notify_user      = '"$USER_MAIL" >> $JOBSCRIPT_GLOBALPATH
    echo 'export THIS_JOB='"$JOBSCRIPT_PREFIX"'_'"$CHEMPOT_PREFIX""$CHEMPOT"'_'"$KAPPA_PREFIX"'${KAPPA}_'"$NTIME_PREFIX"'${NTIME}_'"$NSPACE_PREFIX"'${NSPACE}_'"$BETA_PREFIX"'${BETA}' >> $JOBSCRIPT_GLOBALPATH
    echo 'export SPECIFIC_PATH='"$SIMULATION_PATH"'/mui'"$CHEMPOT"'/'"$KAPPA_PREFIX"'${KAPPA}/'"$NTIME_PREFIX"'${NTIME}/'"$NSPACE_PREFIX"'${NSPACE}/'"$BETA_PREFIX"'${BETA}' >> $JOBSCRIPT_GLOBALPATH
    echo 'export HOME_DIR='"$HOME_DIR" >> $JOBSCRIPT_GLOBALPATH
    echo 'export WORK_DIR='"$WORK_DIR" >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo '#########################################' >> $JOBSCRIPT_GLOBALPATH
    echo '# actual script' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo '# @ error            = $(job_name).$(jobid).out' >> $JOBSCRIPT_GLOBALPATH
    echo '# @ output           = $(job_name).$(jobid).out' >> $JOBSCRIPT_GLOBALPATH
    echo '# @ environment      = COPY_ALL;' >> $JOBSCRIPT_GLOBALPATH
    echo '# @ wall_clock_limit =' "$WALLTIME"  >> $JOBSCRIPT_GLOBALPATH
    echo '# @ notification     = error' >> $JOBSCRIPT_GLOBALPATH
    echo '# @ job_type         = bluegene' >> $JOBSCRIPT_GLOBALPATH
    echo '## # @ bg_connectivity  = TORUS' >> $JOBSCRIPT_GLOBALPATH
    echo '# @ bg_size          =' "$BGSIZE" >> $JOBSCRIPT_GLOBALPATH
    echo '# @ queue' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo '##################################################################################' >> $JOBSCRIPT_GLOBALPATH
    echo '# Prevents execution of more than 1 job with same name' >> $JOBSCRIPT_GLOBALPATH
    echo 'sleep 10' >> $JOBSCRIPT_GLOBALPATH
    echo 'if [ "`llq -f %jn | grep -E "^$LOADL_JOB_NAME[ ]*$" | wc -l`" -gt "1" ]; then' >> $JOBSCRIPT_GLOBALPATH
    echo '  echo "A job with the same name is already running !!!!"' >> $JOBSCRIPT_GLOBALPATH
    echo '  echo "Exiting !!!!"' >> $JOBSCRIPT_GLOBALPATH
    echo '  exit' >> $JOBSCRIPT_GLOBALPATH
    echo 'fi' >> $JOBSCRIPT_GLOBALPATH
    echo '##################################################################################' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo '# bg_size 32 is one node-board, it corresponts to 32 nodes with 16 cores each,' >> $JOBSCRIPT_GLOBALPATH
    echo '# each core can handle up to four processes so for a pure MPI job' >> $JOBSCRIPT_GLOBALPATH
    echo '# there would be 2048 processes' >> $JOBSCRIPT_GLOBALPATH
    echo '# However, because we run in a hybrid MPI / OpenMP mode we run one process' >> $JOBSCRIPT_GLOBALPATH
    echo '# per node with 64 threads each, giving the highest performance so far' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo 'export NP=32' >> $JOBSCRIPT_GLOBALPATH
    echo 'export NT=64' >> $JOBSCRIPT_GLOBALPATH
    echo 'export NPN=1' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo 'export OMP_NUM_THREADS=${NT}' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo '##################################################################################' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# directory where the input file is stored and where the observables are copied back to' >> $JOBSCRIPT_GLOBALPATH
    echo 'export IDIR=${HOME_DIR}/${SPECIFIC_PATH}' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# input file complete path' >> $JOBSCRIPT_GLOBALPATH
    echo 'export IFILE=${IDIR}/hmc.input' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# output directory (where everything is saved ---> it should be on the work disk)' >> $JOBSCRIPT_GLOBALPATH
    echo 'export ODIR=${WORK_DIR}/${SPECIFIC_PATH}' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# directory where the executable is stored' >> $JOBSCRIPT_GLOBALPATH
    echo 'export EDIR=${IDIR}' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# directory with the scripts (StartToContinue.sh, GetParameterValue.sh, Produce.nstore_counter)' >> $JOBSCRIPT_GLOBALPATH
    echo 'export SDIR='"${SCRIPT_DIR}" >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# Save initial position to go back at the end of the job. In this case if the job is' >> $JOBSCRIPT_GLOBALPATH
    echo '# submitted again, the standard output is saved to the same directory' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo 'startingPosition=$(pwd)' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# Create the output directory if it does not exist' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo 'if [[ ! -d ${ODIR} ]]' >> $JOBSCRIPT_GLOBALPATH
    echo 'then' >> $JOBSCRIPT_GLOBALPATH
    echo '  mkdir -p ${ODIR}' >> $JOBSCRIPT_GLOBALPATH
    echo 'fi' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# Move to output directory and run the job' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo 'cd ${ODIR}' >> $JOBSCRIPT_GLOBALPATH
    echo 'runjob --np ${NP} --ranks-per-node ${NPN} --cwd ${ODIR} --exe ${EDIR}/hmc_tm --args -f --args ${IFILE}' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# Recover the exit code of the job' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo 'err=`echo $?`' >> $JOBSCRIPT_GLOBALPATH
    echo 'echo "-------------------------------------------------------------------------------------"' >> $JOBSCRIPT_GLOBALPATH
    echo 'echo "Job finished with exit code $err"' >> $JOBSCRIPT_GLOBALPATH
    echo 'echo ""' >> $JOBSCRIPT_GLOBALPATH
    echo 'cd $startingPosition' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# Check if the hmc run was completed or not, checking tr. number of input file and output.data' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# NOTE: If one resumes a simulation that, for example, has already 50 trajectories in the' >> $JOBSCRIPT_GLOBALPATH
    echo '#       output.data file, and would like to perform 10 more trajectories, then he has to' >> $JOBSCRIPT_GLOBALPATH
    echo '#       set the "Total number of trajectories" in the input file to 60 (in general to the' >> $JOBSCRIPT_GLOBALPATH
    echo '#       number of progressive lines of the output.data file plus the number of new trajectory).' >> $JOBSCRIPT_GLOBALPATH
    echo '#       If not, he will get from below a message like "Done 60 trajectories out of 10" and the' >> $JOBSCRIPT_GLOBALPATH
    echo '#	  job will stop (in general this is serious if the job is actually not finished but it' >> $JOBSCRIPT_GLOBALPATH
    echo '#       seems so because of something like that and it is not again submitted).' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo 'eval $(bash ${SDIR}/GetTotNumTrajectories.sh ${IFILE})' >> $JOBSCRIPT_GLOBALPATH
    echo 'if [ ! -z ${ERROR_OCCURRED+x} ]; then' >> $JOBSCRIPT_GLOBALPATH
    echo '   echo "Error occurred getting \"Total number of trajectories\" from file ${IFILE}"' >> $JOBSCRIPT_GLOBALPATH
    echo '   exit -1' >> $JOBSCRIPT_GLOBALPATH
    echo 'fi ' >> $JOBSCRIPT_GLOBALPATH
    echo 'export TOTAL_TRAJECTORIES=$PARAM_READ' >> $JOBSCRIPT_GLOBALPATH
    echo 'export LAST_TRAJECTORY=$(awk '"'"'BEGIN{traj_num = -1; numLines=0}{if($1>traj_num){ numLines++; traj_num = $1}}END{print numLines}'"'"' ${ODIR}/output.data)' >> $JOBSCRIPT_GLOBALPATH
    echo 'echo "Done $LAST_TRAJECTORY trajectories out of $TOTAL_TRAJECTORIES"' >> $JOBSCRIPT_GLOBALPATH
    echo 'echo""' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# If job not concluded, submit it again. ' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# NOTE: The simulation is resumed differently if the code was' >> $JOBSCRIPT_GLOBALPATH
    echo '#       interrupted from within the main or otherwise (read below)' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo '# NOTE: Here we copy back Observables everytime the job is resubmitted.' >> $JOBSCRIPT_GLOBALPATH
    echo '#       We think it makes sense because than it is immediatly clear how' >> $JOBSCRIPT_GLOBALPATH
    echo '#       many times the job was continued (just with ls in IDIR). Notice' >> $JOBSCRIPT_GLOBALPATH
    echo '#       that this Observables backups are NOT cleaned and then one MUST NOT' >> $JOBSCRIPT_GLOBALPATH
    echo '#       use them like they are for data elaboration!!!' >> $JOBSCRIPT_GLOBALPATH
    echo '#' >> $JOBSCRIPT_GLOBALPATH
    echo 'if [ $LAST_TRAJECTORY -lt $TOTAL_TRAJECTORIES ]; then' >> $JOBSCRIPT_GLOBALPATH
    echo '   #' >> $JOBSCRIPT_GLOBALPATH
    echo '   # If the exit code of the job is 17, it means that the executable' >> $JOBSCRIPT_GLOBALPATH
    echo '   # interrupted because maximum time was exceeded. Then it is safe' >> $JOBSCRIPT_GLOBALPATH
    echo '   # to submit again the job continuing from conf.save and rlxd.save' >> $JOBSCRIPT_GLOBALPATH
    echo '   # and not from last configuration checkpoint. In all the other cases' >> $JOBSCRIPT_GLOBALPATH
    echo '   # we use the Produce.nstore_counter script to resume the simulation' >> $JOBSCRIPT_GLOBALPATH
    echo '   # from last configuration checkpoint.' >> $JOBSCRIPT_GLOBALPATH
    echo '   #' >> $JOBSCRIPT_GLOBALPATH
    echo '   if [ $err -ne 17 ]; then' >> $JOBSCRIPT_GLOBALPATH
    echo '      eval $(bash ${SDIR}/GetParameterValue.sh ${IFILE} Nsave)' >> $JOBSCRIPT_GLOBALPATH
    echo '      if [ ! -z ${ERROR_OCCURRED+x} ]; then' >> $JOBSCRIPT_GLOBALPATH
    echo '         echo "Error occurred getting \"Nsave\" from file ${IFILE}"' >> $JOBSCRIPT_GLOBALPATH
    echo '         exit -1' >> $JOBSCRIPT_GLOBALPATH
    echo '      fi ' >> $JOBSCRIPT_GLOBALPATH
    echo '      export NSAVE=$PARAM_READ' >> $JOBSCRIPT_GLOBALPATH
    echo '      if [ $(($NSAVE)) -eq 0 ]; then ' >> $JOBSCRIPT_GLOBALPATH
    echo '          echo "NSAVE has not been correctly read from in the input, or it is set to zero!"' >> $JOBSCRIPT_GLOBALPATH
    echo '          exit -1' >> $JOBSCRIPT_GLOBALPATH
    echo '      fi' >> $JOBSCRIPT_GLOBALPATH
    echo '      bash ${SDIR}/Produce.nstore_counter.sh ${ODIR} ${NSAVE}' >> $JOBSCRIPT_GLOBALPATH
    echo '      if [ $? -ne 0 ]; then' >> $JOBSCRIPT_GLOBALPATH
    echo '         echo "Error occurred producing .nstore_counter file!"' >> $JOBSCRIPT_GLOBALPATH
    echo '         exit -1' >> $JOBSCRIPT_GLOBALPATH
    echo '      fi  ' >> $JOBSCRIPT_GLOBALPATH
    echo '   else' >> $JOBSCRIPT_GLOBALPATH
    echo '      echo ""' >> $JOBSCRIPT_GLOBALPATH
    echo '      echo "Simulation terminated from inside the main because maximum time was exceeded."' >> $JOBSCRIPT_GLOBALPATH
    echo '      echo "  --->  Continuing from conf.save and rldx.save!"' >> $JOBSCRIPT_GLOBALPATH
    echo '      echo ""' >> $JOBSCRIPT_GLOBALPATH
    echo '   fi' >> $JOBSCRIPT_GLOBALPATH
    echo '   #' >> $JOBSCRIPT_GLOBALPATH
    echo '   # In any case we have to change the starting condition to continue and' >> $JOBSCRIPT_GLOBALPATH
    echo '   # adjust the number of Measurements that have still to be done' >> $JOBSCRIPT_GLOBALPATH
    echo '   #' >> $JOBSCRIPT_GLOBALPATH
    echo '   numberOfMissingTrajectories=$(($TOTAL_TRAJECTORIES - $LAST_TRAJECTORY))' >> $JOBSCRIPT_GLOBALPATH
    echo '   bash ${SDIR}/UpdateMeasurementsNumber.sh ${IFILE} $numberOfMissingTrajectories' >> $JOBSCRIPT_GLOBALPATH
    echo '   if [ $? -ne 0 ]; then' >> $JOBSCRIPT_GLOBALPATH
    echo '      echo "Error occurred changing the number of Measurements to be done!"' >> $JOBSCRIPT_GLOBALPATH
    echo '      exit -1' >> $JOBSCRIPT_GLOBALPATH
    echo '   fi' >> $JOBSCRIPT_GLOBALPATH
    echo '   bash ${SDIR}/StartToContinue.sh ${IFILE}' >> $JOBSCRIPT_GLOBALPATH
    echo '   if [ $? -ne 0 ]; then' >> $JOBSCRIPT_GLOBALPATH
    echo '      echo "Error occurred changing starting condition to continue!"' >> $JOBSCRIPT_GLOBALPATH
    echo '      exit -1' >> $JOBSCRIPT_GLOBALPATH
    echo '   fi' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo '   day=$(date +'"'"'%d.%m.%Y_%H.%M'"'"')' >> $JOBSCRIPT_GLOBALPATH
    echo '   cp ${ODIR}/output.data ${IDIR}/output.data.${day}' >> $JOBSCRIPT_GLOBALPATH
    echo '   cp ${ODIR}/polyakovloop_dir0 ${IDIR}/polykovloop_dir0.${day}' >> $JOBSCRIPT_GLOBALPATH
    echo '   printf "Removing ${ODIR}/..conf.tmp* files..."' >> $JOBSCRIPT_GLOBALPATH
    echo '   rm ${ODIR}/..conf.tmp*' >> $JOBSCRIPT_GLOBALPATH
    echo '   printf "done!\n"' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo '   ' >> $JOBSCRIPT_GLOBALPATH
    echo '   llsubmit ${IDIR}/${THIS_JOB}' >> $JOBSCRIPT_GLOBALPATH
    echo 'else' >> $JOBSCRIPT_GLOBALPATH
    echo '   #' >> $JOBSCRIPT_GLOBALPATH
    echo '   # If the hmc run is concluded clean and copy back last data' >> $JOBSCRIPT_GLOBALPATH
    echo '   #' >> $JOBSCRIPT_GLOBALPATH
    echo '   bash ${SDIR}/CleanOutputData.sh ${ODIR}/output.data' >> $JOBSCRIPT_GLOBALPATH
    echo '   if [ $? -ne 0 ]; then' >> $JOBSCRIPT_GLOBALPATH
    echo '      echo "Error occurred cleaning file ${ODIR}/output.data!"' >> $JOBSCRIPT_GLOBALPATH
    echo '      exit -1' >> $JOBSCRIPT_GLOBALPATH
    echo '   fi' >> $JOBSCRIPT_GLOBALPATH
    echo '   bash ${SDIR}/CleanOutputData.sh ${ODIR}/polyakovloop_dir0' >> $JOBSCRIPT_GLOBALPATH
    echo '   if [ $? -ne 0 ]; then' >> $JOBSCRIPT_GLOBALPATH
    echo '      echo "Error occurred cleaning file ${ODIR}/polyakovloop_dir0!"' >> $JOBSCRIPT_GLOBALPATH
    echo '      exit -1' >> $JOBSCRIPT_GLOBALPATH
    echo '   fi' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    echo '   day=$(date +'"'"'%d.%m.%Y_%H.%M'"'"')' >> $JOBSCRIPT_GLOBALPATH
    echo '   cp ${ODIR}/output.data ${IDIR}/output.data.${day}' >> $JOBSCRIPT_GLOBALPATH
    echo '   cp ${ODIR}/polyakovloop_dir0 ${IDIR}/polykovloop_dir0.${day}' >> $JOBSCRIPT_GLOBALPATH
    echo '   printf "Removing ${ODIR}/..conf.tmp* files..."' >> $JOBSCRIPT_GLOBALPATH
    echo '   rm ${ODIR}/..conf.tmp*' >> $JOBSCRIPT_GLOBALPATH
    echo '   printf "done!\n"' >> $JOBSCRIPT_GLOBALPATH
    echo 'fi' >> $JOBSCRIPT_GLOBALPATH
    echo '' >> $JOBSCRIPT_GLOBALPATH
    
else

    echo "#!/bin/sh" > $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --tasks=1" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --cpus-per-task=1" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --job-name=${JOBSCRIPT_NAME#${JOBSCRIPT_PREFIX}_*}" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --mail-type=FAIL" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --mail-user=$USER_MAIL" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --output=${HMC_TM_FILENAME}.%j.out" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --error=${HMC_TM_FILENAME}.%j.err" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --time=$WALLTIME" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --gres=gpu:1" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --partition=$LOEWE_PARTITION" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "WORKDIR=$WORK_DIR/$SIMULATION_PATH$PARAMETERS_PATH/$BETA_PREFIX$BETA" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"Host: \$(hostname)\"" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"GPU:  \$GPU_DEVICE_ORDINAL\"" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"Date and time: \$(date)\"" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "# prepare" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \$SLURM_JOB_NODELIST > hmc.\$SLURM_JOB_ID.nodelist" >> $JOBSCRIPT_GLOBALPATH
    echo "mkdir -p \$WORKDIR || exit 2" >> $JOBSCRIPT_GLOBALPATH
    echo "cd \$WORKDIR || exit 2" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"---------------------------\"" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "export DISPLAY=:0" >> $JOBSCRIPT_GLOBALPATH
    echo "export GPU_MAX_HEAP_SIZE=75" >> $JOBSCRIPT_GLOBALPATH
    echo "# report where we are" >> $JOBSCRIPT_GLOBALPATH
    echo "srun hostname" >> $JOBSCRIPT_GLOBALPATH
    echo "# check gpu" >> $JOBSCRIPT_GLOBALPATH
    echo "srun aticonfig --odgc --odgt --adapter=all" >> $JOBSCRIPT_GLOBALPATH
    echo "# blablabla" >> $JOBSCRIPT_GLOBALPATH
    echo "srun aticonfig --od-enable" >> $JOBSCRIPT_GLOBALPATH
    echo "# modify gpu clock to factory defaults" >> $JOBSCRIPT_GLOBALPATH
    echo "srun aticonfig --odsc 850,1200" >> $JOBSCRIPT_GLOBALPATH
    echo "# check gpu again" >> $JOBSCRIPT_GLOBALPATH
    echo "srun aticonfig --odgc --odgt --adapter=all" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"---------------------------\"" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "# run hmc" >> $JOBSCRIPT_GLOBALPATH
    echo "srun --gres=gpu:1 $HMC_TM_GLOBALPATH --input-file=\$SLURM_SUBMIT_DIR/hmc.input --kappa=0.$KAPPA --ns=$NSPACE --nt=$NTIME --hmcsteps=$MEASUREMENTS --integrationsteps0=$INTSTEPS0 --integrationsteps1=$INTSTEPS1 --savefrequency=$NSAVE --startcondition=hot --beta=$BETA || exit 1" >> $JOBSCRIPT_GLOBALPATH
    echo "err=\`echo \$?\`" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"---------------------------\"" >> $JOBSCRIPT_GLOBALPATH
    echo "# Reset clocks to default" >> $JOBSCRIPT_GLOBALPATH
    echo "srun aticonfig --odsc 750,1100" >> $JOBSCRIPT_GLOBALPATH
    echo "# done messing with clocks" >> $JOBSCRIPT_GLOBALPATH
    echo "srun aticonfig --od-disable" >> $JOBSCRIPT_GLOBALPATH
    echo "# check gpu again" >> $JOBSCRIPT_GLOBALPATH
    echo "srun aticonfig --odgc --odgt --adapter=all" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "# backup core results" >> $JOBSCRIPT_GLOBALPATH
    echo "cp -a hmc.log \$SLURM_SUBMIT_DIR/hmc.\$SLURM_JOB_ID.log || exit 2" >> $JOBSCRIPT_GLOBALPATH
    echo "cp -a hmc_output \$SLURM_SUBMIT_DIR/hmc_output.\$SLURM_JOB_ID || exit 2" >> $JOBSCRIPT_GLOBALPATH
    echo "cp -a hmc_output \$SLURM_SUBMIT_DIR || exit 2" >> $JOBSCRIPT_GLOBALPATH
    echo "cp -a *.dat  \$SLURM_SUBMIT_DIR || exit 2" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"---------------------------\"" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "# go back and clean up" >> $JOBSCRIPT_GLOBALPATH
    echo "cd \$SLURM_SUBMIT_DIR" >> $JOBSCRIPT_GLOBALPATH
    echo "rm \$WORKDIR/*pbp.dat" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH

fi

