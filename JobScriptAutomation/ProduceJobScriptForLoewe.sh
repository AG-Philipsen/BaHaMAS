function ProduceJobscript_Loewe(){
    #-----------------------------------------------------------------#
    # This piece of script uses the variable
    #   local BETA_FOR_JOBSCRIPT
    # created in the function from which it is called.
    #-----------------------------------------------------------------#
    #This jobscript is for CL2QCD only!
    echo "#!/bin/sh" > $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --job-name=${JOBSCRIPT_NAME#${JOBSCRIPT_PREFIX}_*}" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --mail-type=FAIL" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --mail-user=$USER_MAIL" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --time=$WALLTIME" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --output=${HMC_FILENAME}.%j.out" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --error=${HMC_FILENAME}.%j.err" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --partition=$LOEWE_PARTITION" >> $JOBSCRIPT_GLOBALPATH
    if [[ "$LOEWE_PARTITION" == "parallel" ]]; then
	echo "#SBATCH --constraint=$LOEWE_CONSTRAINT" >> $JOBSCRIPT_GLOBALPATH
    fi
    echo "#SBATCH --tasks=$GPU_PER_NODE" >> $JOBSCRIPT_GLOBALPATH
    if [[ "$LOEWE_NODE" != "unset" ]]; then
	echo "#SBATCH -w $LOEWE_NODE" >> $JOBSCRIPT_GLOBALPATH
    fi
    echo "" >> $JOBSCRIPT_GLOBALPATH

    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
	echo "dir$INDEX=${HOME_DIR_WITH_BETAFOLDERS}/$BETA_PREFIX${BETA_FOR_JOBSCRIPT[$INDEX]}" >> $JOBSCRIPT_GLOBALPATH
    done
    echo "" >> $JOBSCRIPT_GLOBALPATH
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
	echo "workdir$INDEX=${WORK_DIR_WITH_BETAFOLDERS}/$BETA_PREFIX${BETA_FOR_JOBSCRIPT[$INDEX]}" >> $JOBSCRIPT_GLOBALPATH
    done
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "outFile=hmc.\$SLURM_JOB_ID.out" >> $JOBSCRIPT_GLOBALPATH
    echo "errFile=hmc.\$SLURM_JOB_ID.err" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "# Check if directories exist" >> $JOBSCRIPT_GLOBALPATH
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        echo "if [ ! -d \$dir$INDEX ]; then" >> $JOBSCRIPT_GLOBALPATH
        echo "echo \"Could not find directory \\\"\$dir$INDEX\\\" for runs. Aborting...\""  >> $JOBSCRIPT_GLOBALPATH
        echo "exit -1"  >> $JOBSCRIPT_GLOBALPATH
	echo "fi"  >> $JOBSCRIPT_GLOBALPATH
	echo "" >> $JOBSCRIPT_GLOBALPATH
    done
    echo "# Print some information" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"${BETA_FOR_JOBSCRIPT[@]}\"" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"\"" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"Host: \$(hostname)\"" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"GPU:  \$GPU_DEVICE_ORDINAL\"" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"Date and time: \$(date)\"" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \$SLURM_JOB_NODELIST > $HMC_FILENAME.${BETAS_STRING:1}.\$SLURM_JOB_ID.nodelist" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "# TODO: this is necessary because the log file is produced in the directoy" >> $JOBSCRIPT_GLOBALPATH
    echo "#       of the exec. Copying it later does not guarantee that it is still the same..." >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"Copy executable to beta directories in ${WORK_DIR_WITH_BETAFOLDERS}/${BETA_PREFIX}x.xxxx...\"" >> $JOBSCRIPT_GLOBALPATH
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
	echo "cp -a $HMC_GLOBALPATH \$dir$INDEX" >> $JOBSCRIPT_GLOBALPATH
    done
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"---------------------------\"" >> $JOBSCRIPT_GLOBALPATH
    echo "export DISPLAY=:0" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"\\\"export DISPLAY=:0\\\" done!\"" >> $JOBSCRIPT_GLOBALPATH
    #echo "export GPU_MAX_HEAP_SIZE=75" >> $JOBSCRIPT_GLOBALPATH             #Max amount of total memory of GPU allowed to be used, we do not set it for the moment
    echo "echo \"---------------------------\"" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "# Run jobs from different directories" >> $JOBSCRIPT_GLOBALPATH
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
	echo "mkdir -p \$workdir$INDEX || exit 2" >> $JOBSCRIPT_GLOBALPATH
	echo "cd \$workdir$INDEX" >> $JOBSCRIPT_GLOBALPATH
	echo "pwd &" >> $JOBSCRIPT_GLOBALPATH
	echo "time srun -n 1 \$dir$INDEX/$HMC_FILENAME --input-file=\$dir$INDEX/$INPUTFILE_NAME --device=$INDEX --beta=${BETA_FOR_JOBSCRIPT[$INDEX]%%_*} > \$dir$INDEX/\$outFile 2> \$dir$INDEX/\$errFile &" >> $JOBSCRIPT_GLOBALPATH
	echo "" >> $JOBSCRIPT_GLOBALPATH
    done
    echo "wait" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "err=\`echo \$?\`" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"error_code=\$err\"" >> $JOBSCRIPT_GLOBALPATH    
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"---------------------------\"" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"Date and time: \$(date)\"" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    if [ "$HOME_DIR" != "$WORK_DIR" ]; then
	echo "# Backup files" >> $JOBSCRIPT_GLOBALPATH
	for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
	    echo "cd \$dir$INDEX || exit 2" >> $JOBSCRIPT_GLOBALPATH
	    if [ $MEASURE_PBP -ne 0 ]; then
		echo "if [ -d \"Pbp\" ]; then" >> $JOBSCRIPT_GLOBALPATH
		echo "    cd Pbp || exit 2" >> $JOBSCRIPT_GLOBALPATH
		echo "    OLD_FOLD=\"Old_\$(date +'%F_%H%M')\"" >> $JOBSCRIPT_GLOBALPATH
		echo "    mkdir \$OLD_FOLD || exit 2" >> $JOBSCRIPT_GLOBALPATH
		echo "    mv * \$OLD_FOLD" >> $JOBSCRIPT_GLOBALPATH
		echo "    cd .. || exit 2" >> $JOBSCRIPT_GLOBALPATH
		echo "else" >> $JOBSCRIPT_GLOBALPATH
		echo "    mkdir \"Pbp\" || exit -2" >> $JOBSCRIPT_GLOBALPATH
		echo "fi" >> $JOBSCRIPT_GLOBALPATH
		echo "cp \$workdir$INDEX/conf*pbp* \$dir$INDEX/Pbp || exit 2" >> $JOBSCRIPT_GLOBALPATH
	    fi
	    echo "cp \$workdir$INDEX/$OUTPUTFILE_NAME \$dir$INDEX/$OUTPUTFILE_NAME.\$SLURM_JOB_ID" >> $JOBSCRIPT_GLOBALPATH
	    echo "" >> $JOBSCRIPT_GLOBALPATH
	done
    fi
    echo "# Remove executable" >> $JOBSCRIPT_GLOBALPATH
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
	echo "rm \$dir$INDEX/$HMC_FILENAME || exit -2 " >> $JOBSCRIPT_GLOBALPATH
    done
    echo "" >> $JOBSCRIPT_GLOBALPATH
    if [ $THERMALIZE = "TRUE" ]; then
	echo "# Copy last configuration to Thermalized Configurations folder" >> $JOBSCRIPT_GLOBALPATH
	if [ $BETA_POSTFIX == "_thermalizeFromHot" ]; then
	    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
		echo "cp \$workdir$INDEX/conf.save " \
                         "${THERMALIZED_CONFIGURATIONS_PATH}/conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA_FOR_JOBSCRIPT[$INDEX]%%_*}_fromHot${MEASUREMENTS} " \
                         "|| exit -2" >> $JOBSCRIPT_GLOBALPATH
	    done
	elif [ $BETA_POSTFIX == "_thermalizeFromConf" ]; then
	    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
		echo "cp \$workdir$INDEX/conf.save " \
                         "${THERMALIZED_CONFIGURATIONS_PATH}/conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA_FOR_JOBSCRIPT[$INDEX]%%_*}_fromConf${MEASUREMENTS} " \
                         "|| exit -2" >> $JOBSCRIPT_GLOBALPATH		
	    done
	fi
    fi
}