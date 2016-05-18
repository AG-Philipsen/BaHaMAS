function ProduceJobscript_Loewe(){
    #-----------------------------------------------------------------#
    # This piece of script uses the variable
    #   local BETA_FOR_JOBSCRIPT
    # created in the function from which it is called.
    #-----------------------------------------------------------------#
    #This jobscript is for CL2QCD only!
    echo "#!/bin/bash" > $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --job-name=${JOBSCRIPT_NAME#${JOBSCRIPT_PREFIX}_*}" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --mail-type=FAIL" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --mail-user=$USER_MAIL" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --time=$WALLTIME" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --output=${HMC_FILENAME}.%j.out" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --error=${HMC_FILENAME}.%j.err" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --no-requeue" >> $JOBSCRIPT_GLOBALPATH
    if [ $CLUSTER_NAME = "LOEWE" ]; then
        echo "#SBATCH --partition=$LOEWE_PARTITION" >> $JOBSCRIPT_GLOBALPATH
        if [[ "$LOEWE_PARTITION" == "parallel" ]]; then
            echo "#SBATCH --constraint=$LOEWE_CONSTRAINT" >> $JOBSCRIPT_GLOBALPATH
        fi
        if [[ "$LOEWE_NODE" != "unset" ]]; then
            echo "#SBATCH -w $LOEWE_NODE" >> $JOBSCRIPT_GLOBALPATH
        fi
    elif [ $CLUSTER_NAME = "LCSC" ]; then
	    echo "#SBATCH --partition=lcsc" >> $JOBSCRIPT_GLOBALPATH
	    echo "#SBATCH --mem=64000" >> $JOBSCRIPT_GLOBALPATH
	    echo "#SBATCH --gres=gpu:$GPU_PER_NODE" >> $JOBSCRIPT_GLOBALPATH
        #Option to choose only a node with 'hawaii' GPU hardware
        echo "#SBATCH --constrain=hawaii" >> $JOBSCRIPT_GLOBALPATH
        echo "#SBATCH --exclude=lxlcsc[0014,0031,0036,0061,0097,0099,0104-0105,0116,0149,0157]" >> $JOBSCRIPT_GLOBALPATH
        #The following nodes of L-CSC are using tahiti as GPU hardware (sinfo -o "%4c %10z %8d %8m %10f %10G %D %N"), CL2QCD fails on them.
        #echo "#SBATCH --exclude=lxlcsc0043,lxlcsc0044,lxlcsc0045,lxlcsc0046,lxlcsc0047,lxlcsc0049,lxlcsc0050,lxlcsc0052,lxlcsc0053" >> $JOBSCRIPT_GLOBALPATH
    elif [ $CLUSTER_NAME = "LCSC_OLD" ]; then
        echo "#SBATCH --partition=lcsc_lqcd" >> $JOBSCRIPT_GLOBALPATH
        echo "#SBATCH --exclude=lcsc-r03n01,lcsc-r06n17,lcsc-r06n10,lcsc-r03n12,lcsc-r03n13,lcsc-r06n02,lcsc-r06n03" >> $JOBSCRIPT_GLOBALPATH
        #echo "#SBATCH --exclude=lcsc-r04n01,lcsc-r04n02,lcsc-r04n03,lcsc-r04n04,lcsc-r05n01,lcsc-r05n02,lcsc-r05n03,lcsc-r05n04,lcsc-r06n01,lcsc-r06n02,lcsc-r06n03,lcsc-r06n04,lcsc-r07n01,lcsc-r07n02,lcsc-r07n03,lcsc-r07n04,lcsc-r08n01,lcsc-r08n02,lcsc-r08n03,lcsc-r08n04,lcsc-r02n01,lcsc-r02n02,lcsc-r02n03,lcsc-r02n04,lcsc-r03n01,lcsc-r03n02,lcsc-r03n07,lcsc-r03n08,lcsc-r09n16,lcsc-r06n17,lcsc-r07n08,lcsc-r06n14,lcsc-r07n14,lcsc-r04n12,lcsc-r06n18,lcsc-r09n18" >> $JOBSCRIPT_GLOBALPATH
    fi
    echo "#SBATCH --ntasks=$GPU_PER_NODE" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        echo "dir$INDEX=${HOME_DIR_WITH_BETAFOLDERS}/$BETA_PREFIX${BETA_FOR_JOBSCRIPT[$INDEX]}" >> $JOBSCRIPT_GLOBALPATH
    done
        echo "" >> $JOBSCRIPT_GLOBALPATH
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        echo "workdir$INDEX=${WORK_DIR_WITH_BETAFOLDERS}/$BETA_PREFIX${BETA_FOR_JOBSCRIPT[$INDEX]}" >> $JOBSCRIPT_GLOBALPATH
    done
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "outFile=$HMC_FILENAME.\$SLURM_JOB_ID.out" >> $JOBSCRIPT_GLOBALPATH
    echo "errFile=$HMC_FILENAME.\$SLURM_JOB_ID.err" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "# Check if directories exist" >> $JOBSCRIPT_GLOBALPATH
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        echo "if [ ! -d \$dir$INDEX ]; then" >> $JOBSCRIPT_GLOBALPATH
        echo "echo \"Could not find directory \\\"\$dir$INDEX\\\" for runs. Aborting...\""  >> $JOBSCRIPT_GLOBALPATH
        echo "exit 2"  >> $JOBSCRIPT_GLOBALPATH
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
        echo "rm -f \$dir$INDEX/$HMC_FILENAME && cp -a $HMC_GLOBALPATH \$dir$INDEX || exit 2" >> $JOBSCRIPT_GLOBALPATH
    done
    echo "echo \"...done!\"" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    if [ "$HOME_DIR" != "$WORK_DIR" ]; then
        echo "#Copy inputfile from home to work directories..." >> $JOBSCRIPT_GLOBALPATH
        for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
            echo "cp \$dir$INDEX/$INPUTFILE_NAME \$workdir$INDEX/$INPUTFILE_NAME.\$SLURM_JOB_ID || exit 2" >> $JOBSCRIPT_GLOBALPATH            		
        done
        echo "echo \"...done!\"" >> $JOBSCRIPT_GLOBALPATH
    fi
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
        if [ $CLUSTER_NAME = "LOEWE" ]; then
            echo "time srun -n 1 \$dir$INDEX/$HMC_FILENAME --input-file=\$dir$INDEX/$INPUTFILE_NAME --device=$INDEX --beta=${BETA_FOR_JOBSCRIPT[$INDEX]%%_*} > \$dir$INDEX/\$outFile 2> \$dir$INDEX/\$errFile &" >> $JOBSCRIPT_GLOBALPATH
	    elif [ $CLUSTER_NAME = "LCSC" ]; then
	        echo "time \$dir$INDEX/$HMC_FILENAME --input-file=\$dir$INDEX/$INPUTFILE_NAME --device=$INDEX --beta=${BETA_FOR_JOBSCRIPT[$INDEX]%%_*} 2> \$dir$INDEX/\$errFile | mbuffer -q -m2M > \$dir$INDEX/\$outFile &" >> $JOBSCRIPT_GLOBALPATH
        fi
        echo "PID_SRUN_$INDEX=\${!}" >> $JOBSCRIPT_GLOBALPATH
        echo "" >> $JOBSCRIPT_GLOBALPATH
    done
    echo "#Execute wait \$PID job after job" >> $JOBSCRIPT_GLOBALPATH
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        echo "wait \$PID_SRUN_$INDEX || { printf \"\nError occurred in simulation at b${BETA_FOR_JOBSCRIPT[$INDEX]%%_*}. Please check (process id \${PID_SRUN_$INDEX})...\n\" && ERROR_OCCURRED=\"TRUE\"; }" >> $JOBSCRIPT_GLOBALPATH
    done
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "# Terminating job manually to get an email in case of failure of any run" >> $JOBSCRIPT_GLOBALPATH
    echo "if [ \"\$ERROR_OCCURRED\" = \"TRUE\" ]; then" >> $JOBSCRIPT_GLOBALPATH
    echo "   printf \"\nTerminating job with non zero exit code... (\$(date))\n\"" >> $JOBSCRIPT_GLOBALPATH
    echo "   exit 255" >> $JOBSCRIPT_GLOBALPATH
    echo "fi" >> $JOBSCRIPT_GLOBALPATH
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
            if [ $MEASURE_PBP = "TRUE" ]; then
                echo "cp \$workdir$INDEX/${OUTPUTFILE_NAME}_pbp.dat \$dir$INDEX/${OUTPUTFILE_NAME}_pbp.\$SLURM_JOB_ID || exit 2" >> $JOBSCRIPT_GLOBALPATH
            fi
            echo "cp \$workdir$INDEX/$OUTPUTFILE_NAME \$dir$INDEX/$OUTPUTFILE_NAME.\$SLURM_JOB_ID || exit 2" >> $JOBSCRIPT_GLOBALPATH
            echo "" >> $JOBSCRIPT_GLOBALPATH
        done
    fi
    echo "# Remove executable" >> $JOBSCRIPT_GLOBALPATH
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        echo "rm \$dir$INDEX/$HMC_FILENAME || exit 2 " >> $JOBSCRIPT_GLOBALPATH
    done
    echo "" >> $JOBSCRIPT_GLOBALPATH
    if [ $THERMALIZE = "TRUE" ] || [ $CONTINUE_THERMALIZATION = "TRUE" ]; then
        echo "# Copy last configuration to Thermalized Configurations folder" >> $JOBSCRIPT_GLOBALPATH
        if [ $BETA_POSTFIX == "_thermalizeFromHot" ]; then
            for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
                echo "NUMBER_LAST_CONFIGURATION_IN_FOLDER=\$(ls \$workdir$INDEX | grep 'conf.[0-9]\+' | grep -o '[0-9]\+' | sort -V | tail -n1)"  >> $JOBSCRIPT_GLOBALPATH
                echo "cp \$workdir$INDEX/conf.\${NUMBER_LAST_CONFIGURATION_IN_FOLDER} ${THERMALIZED_CONFIGURATIONS_PATH}/conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA_FOR_JOBSCRIPT[$INDEX]%%_*}_fromHot\$(sed 's/^0*//' <<< \"\$NUMBER_LAST_CONFIGURATION_IN_FOLDER\")" \
                     "|| exit 2" >> $JOBSCRIPT_GLOBALPATH
            done
        elif [ $BETA_POSTFIX == "_thermalizeFromConf" ]; then
            for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
                echo "NUMBER_LAST_CONFIGURATION_IN_FOLDER=\$(ls \$workdir$INDEX | grep 'conf.[0-9]\+' | grep -o '[0-9]\+' | sort -V | tail -n1)"  >> $JOBSCRIPT_GLOBALPATH
                #TODO: For the moment we assume 1000 tr. are done from hot. Better to avoid it
                echo "TRAJECTORIES_DONE_FROM_CONF=\$(( \$(sed 's/^0*//' <<< \"\$NUMBER_LAST_CONFIGURATION_IN_FOLDER\") - 1000 ))"  >> $JOBSCRIPT_GLOBALPATH
                echo "cp \$workdir$INDEX/conf.\${NUMBER_LAST_CONFIGURATION_IN_FOLDER} ${THERMALIZED_CONFIGURATIONS_PATH}/conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA_FOR_JOBSCRIPT[$INDEX]%%_*}_fromConf\${TRAJECTORIES_DONE_FROM_CONF} " \
                     "|| exit 2" >> $JOBSCRIPT_GLOBALPATH
            done
        fi
    fi
}
