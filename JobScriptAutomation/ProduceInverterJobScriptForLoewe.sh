function ProduceInverterJobscript_Loewe(){

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
    echo "#SBATCH --output=${INVERTER_FILENAME}.%j.out" >> $JOBSCRIPT_GLOBALPATH
    echo "#SBATCH --error=${INVERTER_FILENAME}.%j.err" >> $JOBSCRIPT_GLOBALPATH
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
        #The following nodes of L-CSC are using tahiti as GPU hardware (sinfo -o "%4c %10z %8d %8m %10f %10G %D %N"), CL2QCD fails on them.
    elif [ $CLUSTER_NAME = "LCSC_OLD" ]; then
        echo "#SBATCH --partition=lcsc_lqcd" >> $JOBSCRIPT_GLOBALPATH
        echo "#SBATCH --exclude=lcsc-r03n01,lcsc-r06n17,lcsc-r06n10,lcsc-r03n12,lcsc-r03n13,lcsc-r06n02,lcsc-r06n03" >> $JOBSCRIPT_GLOBALPATH
    fi

	if [ -f "$FILE_WITH_WHICH_NODES_TO_EXCLUDE" ]; then
		EXCLUDE_STRING=$(grep -oE '\-\-exclude=.*\[.*\]' $FILE_WITH_WHICH_NODES_TO_EXCLUDE 2>/dev/null)
	elif [[ $FILE_WITH_WHICH_NODES_TO_EXCLUDE =~ : ]]; then 
        EXCLUDE_STRING=$(ssh ${FILE_WITH_WHICH_NODES_TO_EXCLUDE%%:*} "grep -oE '\-\-exclude=.*\[.*\]' ${FILE_WITH_WHICH_NODES_TO_EXCLUDE#*:} 2>/dev/null")
	fi
    if [ "$EXCLUDE_STRING" != "" ]; then
        echo "#SBATCH $EXCLUDE_STRING"  >> $JOBSCRIPT_GLOBALPATH
        printf "\e[1A\e[80C\t$EXCLUDE_STRING\n"
    else
        printf "\n\e[0;33m \e[1m\e[4mWARNING\e[24m:\e[0;33m No exclude string to exclude nodes in jobscript found!"
        printf " Do you still want to continue with jobscript creation? [Y/N] \e[0m"
        while read CONFIRM; do
            if [ "$CONFIRM" = "Y" ]; then
                break
            elif [ "$CONFIRM" = "N" ]; then
                printf "\n\e[1;31m Exiting from job script creation process...\e[0m\n\n"
                rm -f $JOBSCRIPT_GLOBALPATH
                exit
            else
                printf "\e[0;36m\e[1m Please enter Y (yes) or N (no): \e[0m"
            fi
        done
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
    echo "outFile=$INVERTER_FILENAME.\$SLURM_JOB_ID.out" >> $JOBSCRIPT_GLOBALPATH
    echo "errFile=$INVERTER_FILENAME.\$SLURM_JOB_ID.err" >> $JOBSCRIPT_GLOBALPATH
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
    echo "echo \$SLURM_JOB_NODELIST > $INVERTER_FILENAME.${BETAS_STRING:1}.\$SLURM_JOB_ID.nodelist" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "# TODO: this is necessary because the log file is produced in the directoy" >> $JOBSCRIPT_GLOBALPATH
    echo "#       of the exec. Copying it later does not guarantee that it is still the same..." >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"Copy executable to beta directories in ${WORK_DIR_WITH_BETAFOLDERS}/${BETA_PREFIX}x.xxxx...\"" >> $JOBSCRIPT_GLOBALPATH
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        echo "rm -f \$dir$INDEX/$INVERTER_FILENAME && cp -a $INVERTER_GLOBALPATH \$dir$INDEX || exit 2" >> $JOBSCRIPT_GLOBALPATH
    done
    echo "echo \"...done!\"" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"---------------------------\"" >> $JOBSCRIPT_GLOBALPATH
    echo "export DISPLAY=:0" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"\\\"export DISPLAY=:0\\\" done!\"" >> $JOBSCRIPT_GLOBALPATH
    #echo "export GPU_MAX_HEAP_SIZE=75" >> $JOBSCRIPT_GLOBALPATH             #Max amount of total memory of GPU allowed to be used, we do not set it for the moment
    echo "echo \"---------------------------\"" >> $JOBSCRIPT_GLOBALPATH
    if [ $CLUSTER_NAME = "LCSC" ]; then
        echo "# Since we run the job with a pipeline to handle the std output with mbuffer, we must activate pipefail to get the correct error code!" >> $JOBSCRIPT_GLOBALPATH
        echo "set -o pipefail" >> $JOBSCRIPT_GLOBALPATH
        echo "" >> $JOBSCRIPT_GLOBALPATH
    fi
    echo "# Run jobs from different directories" >> $JOBSCRIPT_GLOBALPATH
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        #The following check is done twice. During the creation of the jobscript for the case in which the $SRUN_COMMANDSFILE_FOR_INVERSION does not exist from the beginning on and 
        #in the jobscript itself for the case in which it exists during the creation of the jobscript but accidentally gets deleted later on after the creation.
        #if [ ! -e $workdir$INDEX/$SRUN_COMMANDSFILE_FOR_INVERSION ]; then #SHOULD BE LIKE THIS??
        if [ ! -e ${WORK_DIR_WITH_BETAFOLDERS}/$BETA_PREFIX${BETA_FOR_JOBSCRIPT[$INDEX]}/$SRUN_COMMANDSFILE_FOR_INVERSION ]; then #I THINK WORK_BETADIRECTORY has to be replaced!!!!
            echo "File ${WORK_DIR_WITH_BETAFOLDERS}/$BETA_PREFIX${BETA_FOR_JOBSCRIPT[$INDEX]}/$SRUN_COMMANDSFILE_FOR_INVERSION with execution commands for the inversion does not exist...aborting"
            exit 30
        fi
        echo "mkdir -p \$workdir$INDEX || exit 2" >> $JOBSCRIPT_GLOBALPATH
        echo "cd \$workdir$INDEX" >> $JOBSCRIPT_GLOBALPATH
        echo "pwd" >> $JOBSCRIPT_GLOBALPATH
        echo "if [ ! -e \$workdir$INDEX/$SRUN_COMMANDSFILE_FOR_INVERSION ]; then" >> $JOBSCRIPT_GLOBALPATH
        echo "  echo \"File \$workdir$INDEX/$SRUN_COMMANDSFILE_FOR_INVERSION with execution commands for the inversion does not exist...aborting\"" >> $JOBSCRIPT_GLOBALPATH
        echo "  exit 30" >> $JOBSCRIPT_GLOBALPATH
        echo "fi" >> $JOBSCRIPT_GLOBALPATH
        echo "OLD_IFS=\$IFS" >> $JOBSCRIPT_GLOBALPATH
        echo "IFS=\$'\n'" >> $JOBSCRIPT_GLOBALPATH
        echo "for line in \$(cat \$workdir$INDEX/$SRUN_COMMANDSFILE_FOR_INVERSION); do" >> $JOBSCRIPT_GLOBALPATH
        echo "IFS=\$OLD_IFS #Restore here old IFS to give separated options (and not only one)to CL2QCD!" >> $JOBSCRIPT_GLOBALPATH 
        if [ $CLUSTER_NAME = "LOEWE" ]; then
            echo "  time srun -n 1 \$dir$INDEX/$INVERTER_FILENAME \$line --device=$INDEX 2>> \$dir$INDEX/\$errFile >> \$dir$INDEX/\$outFile " >> $JOBSCRIPT_GLOBALPATH
        elif [ $CLUSTER_NAME = "LCSC" ]; then
            echo "  time \$dir$INDEX/$INVERTER_FILENAME \$line --device=$INDEX 2>> \$dir$INDEX/\$errFile | mbuffer -q -m2M >> \$dir$INDEX/\$outFile " >> $JOBSCRIPT_GLOBALPATH
        fi
        echo "  if [ \$? -ne 0 ]; then" >> $JOBSCRIPT_GLOBALPATH
        echo "       printf \"\nError occurred in simulation at b${BETA_FOR_JOBSCRIPT[$INDEX]%_*}.\n\"" >> $JOBSCRIPT_GLOBALPATH
        echo "       CONFIGURATION_$INDEX=\$(echo \$line | grep -o \"conf.[[:digit:]]\{5\}\")" >> $JOBSCRIPT_GLOBALPATH
        echo "       CORRELATOR_POSTFIX_$INDEX=\$(echo \$line | grep -o \"_[[:digit:]]\+_[[:digit:]]\+_[[:digit:]]\+_[[:digit:]]\+_corr\")" >> $JOBSCRIPT_GLOBALPATH
        echo "       echo \$CONFIGURATION_$INDEX\$CORRELATOR_POSTFIX_$INDEX >> \$dir$INDEX/failed_inversions_tmp_file" >> $JOBSCRIPT_GLOBALPATH
        echo "  fi" >> $JOBSCRIPT_GLOBALPATH
        #echo "  sleep 3 #This sleep is neccessary for the mbuffer used above in the srun command. Since mbuffer is used in a loop many times in a row, it produces problems if there is no pause put inbetween the consecutive mbuffer calls." >> $JOBSCRIPT_GLOBALPATH
        echo "done &" >> $JOBSCRIPT_GLOBALPATH
        echo "IFS=\$OLD_IFS" >> $JOBSCRIPT_GLOBALPATH
        #PUT PID_FOR ASSIGNMENT HERE
        echo "PID_FOR_$INDEX=\${!}" >> $JOBSCRIPT_GLOBALPATH
        echo "" >> $JOBSCRIPT_GLOBALPATH
    done
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        echo "wait \$PID_FOR_$INDEX || { printf \"\nError occurred in simulation at b${BETA_FOR_JOBSCRIPT[$INDEX]%_*}. Please check (process id \${PID_FOR_$INDEX})...\n\"; }" >> $JOBSCRIPT_GLOBALPATH
    done
    echo "" >> $JOBSCRIPT_GLOBALPATH
    if [ $CLUSTER_NAME = "LCSC" ]; then
        echo "# Unset pipefail since not needed anymore" >> $JOBSCRIPT_GLOBALPATH
        echo "set +o pipefail" >> $JOBSCRIPT_GLOBALPATH
        echo "" >> $JOBSCRIPT_GLOBALPATH
    fi
    echo "echo \"---------------------------\"" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "echo \"Date and time: \$(date)\"" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "" >> $JOBSCRIPT_GLOBALPATH
    echo "# Remove executable" >> $JOBSCRIPT_GLOBALPATH
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        echo "rm \$dir$INDEX/$INVERTER_FILENAME || exit 2 " >> $JOBSCRIPT_GLOBALPATH
    done
    echo "" >> $JOBSCRIPT_GLOBALPATH

    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        echo "if [ -e \$dir$INDEX/failed_inversions_tmp_file ]; then" >> $JOBSCRIPT_GLOBALPATH
        echo "  ERROR_OCCURRED="TRUE"" >> $JOBSCRIPT_GLOBALPATH
        echo "  echo \"Failed inversions at b${BETA_FOR_JOBSCRIPT[$INDEX]%_*}:\" >> \$dir$INDEX/\$errFile" >> $JOBSCRIPT_GLOBALPATH
        echo "  cat \$dir$INDEX/failed_inversions_tmp_file >> \$dir$INDEX/\$errFile" >> $JOBSCRIPT_GLOBALPATH
        echo "  rm \$dir$INDEX/failed_inversions_tmp_file" >> $JOBSCRIPT_GLOBALPATH
        echo "fi" >> $JOBSCRIPT_GLOBALPATH
    done

    echo "if [ \"\$ERROR_OCCURRED\" = \"TRUE\" ]; then" >> $JOBSCRIPT_GLOBALPATH
        echo "  printf \"\nTerminating job with non zero exit code... (\$(date))\n\"" >> $JOBSCRIPT_GLOBALPATH
        echo "  exit 255" >> $JOBSCRIPT_GLOBALPATH
    echo "fi" >> $JOBSCRIPT_GLOBALPATH
}
