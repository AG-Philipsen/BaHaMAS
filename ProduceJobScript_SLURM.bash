function __static__AddToJobscriptFile() {
    while [ $# -ne 0 ]; do
        printf "%s\n" "$1" >> $JOBSCRIPT_GLOBALPATH
        shift
    done
}

function ProduceJobscript_SLURM(){
    rm -f $JOBSCRIPT_GLOBALPATH || exit -2
    touch $JOBSCRIPT_GLOBALPATH || exit -2

    #-----------------------------------------------------------------#
    # This piece of script uses the variable
    #   local BETA_FOR_JOBSCRIPT
    # created in the function from which it is called.
    #-----------------------------------------------------------------#
    #This jobscript is for CL2QCD only!
    __static__AddToJobscriptFile\
        "#!/bin/bash"\
        ""\
        "#SBATCH --job-name=${JOBSCRIPT_NAME#${JOBSCRIPT_PREFIX}_*}"\
        "#SBATCH --mail-type=FAIL"\
        "#SBATCH --mail-user=$USER_MAIL"\
        "#SBATCH --time=$WALLTIME"\
        "#SBATCH --output=${HMC_FILENAME}.%j.out"\
        "#SBATCH --error=${HMC_FILENAME}.%j.err"\
        "#SBATCH --no-requeue"

    [ "$CLUSTER_PARTITION"        != '' ] && __static__AddToJobscriptFile "#SBATCH --partition=$CLUSTER_PARTITION"
    [ "$CLUSTER_NODE"             != '' ] && __static__AddToJobscriptFile "#SBATCH --nodelist=$CLUSTER_NODE"
    [ "$CLUSTER_CONSTRAINT"       != '' ] && __static__AddToJobscriptFile "#SBATCH --constraint=$CLUSTER_CONSTRAINT"
    [ "$CLUSTER_GENERIC_RESOURCE" != '' ] && __static__AddToJobscriptFile "#SBATCH --gres=$CLUSTER_GENERIC_RESOURCE"

    #Trying to retrieve information about the list of nodes to be excluded if user gave file
    if [ "$FILE_WITH_WHICH_NODES_TO_EXCLUDE" != '' ]; then
        if [ -f "$FILE_WITH_WHICH_NODES_TO_EXCLUDE" ]; then
            EXCLUDE_STRING=$(grep -oE '\-\-exclude=.*\[.*\]' $FILE_WITH_WHICH_NODES_TO_EXCLUDE 2>/dev/null)
        elif [[ $FILE_WITH_WHICH_NODES_TO_EXCLUDE =~ : ]]; then
            EXCLUDE_STRING=$(ssh ${FILE_WITH_WHICH_NODES_TO_EXCLUDE%%:*} "grep -oE '\-\-exclude=.*\[.*\]' ${FILE_WITH_WHICH_NODES_TO_EXCLUDE#*:} 2>/dev/null")
        fi
        if [ "$EXCLUDE_STRING" != "" ]; then
            __static__AddToJobscriptFile "#SBATCH $EXCLUDE_STRING"
            cecho "\e[1A\e[80C\t$EXCLUDE_STRING"
        else
            cecho "\n" ly B U "WARNING" uU ":" uB " No exclude string to exclude nodes in jobscript found!\n"\
                  "         Do you still want to continue with jobscript creation? [Y/N]"
            while read CONFIRM; do
                if [ "$CONFIRM" = "Y" ]; then
                    break
                elif [ "$CONFIRM" = "N" ]; then
                    cecho "\n" B lr "Exiting from job script creation process...\n"
                    rm -f $JOBSCRIPT_GLOBALPATH
                    exit
                else
                    cecho -n lc B " Please enter Y (yes) or N (no): "
                fi
            done
        fi
    fi

    __static__AddToJobscriptFile "#SBATCH --ntasks=$GPU_PER_NODE" ""
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        __static__AddToJobscriptFile "dir$INDEX=${HOME_DIR_WITH_BETAFOLDERS}/$BETA_PREFIX${BETA_FOR_JOBSCRIPT[$INDEX]}"
    done
    __static__AddToJobscriptFile ""
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        __static__AddToJobscriptFile "workdir$INDEX=${WORK_DIR_WITH_BETAFOLDERS}/$BETA_PREFIX${BETA_FOR_JOBSCRIPT[$INDEX]}"
    done
    __static__AddToJobscriptFile\
        ""\
        "outFile=$HMC_FILENAME.\$SLURM_JOB_ID.out"\
        "errFile=$HMC_FILENAME.\$SLURM_JOB_ID.err"\
        ""\
        "# Check if directories exist"
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        __static__AddToJobscriptFile\
            "if [ ! -d \$dir$INDEX ]; then"\
            "  echo \"Could not find directory \\\"\$dir$INDEX\\\" for runs. Aborting...\"" \
            "  exit 2" \
            "fi" \
            ""
    done
    __static__AddToJobscriptFile\
        "# Print some information"\
        "echo \"$(printf "%s " ${BETA_FOR_JOBSCRIPT[@]})\""\
        "echo \"\""\
        "echo \"Host: \$(hostname)\""\
        "echo \"GPU:  \$GPU_DEVICE_ORDINAL\""\
        "echo \"Date and time: \$(date)\""\
        "echo \$SLURM_JOB_NODELIST > $HMC_FILENAME.${BETAS_STRING:1}.\$SLURM_JOB_ID.nodelist"\
        ""\
        "# TODO: this is necessary because the log file is produced in the directoy"\
        "#       of the exec. Copying it later does not guarantee that it is still the same..."\
        "echo \"Copy executable to beta directories in ${WORK_DIR_WITH_BETAFOLDERS}/${BETA_PREFIX}x.xxxx...\""
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        __static__AddToJobscriptFile "rm -f \$dir$INDEX/$HMC_FILENAME && cp -a $HMC_GLOBALPATH \$dir$INDEX || exit 2"
    done
    __static__AddToJobscriptFile "echo \"...done!\"" ""
    if [ "$HOME_DIR" != "$WORK_DIR" ]; then
        __static__AddToJobscriptFile "#Copy inputfile from home to work directories..."
        for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
            __static__AddToJobscriptFile "mkdir -p \$workdir$INDEX && cp \$dir$INDEX/$INPUTFILE_NAME \$workdir$INDEX/$INPUTFILE_NAME.\$SLURM_JOB_ID || exit 2"
        done
        __static__AddToJobscriptFile "echo \"...done!\""
    fi
    __static__AddToJobscriptFile\
        ""\
        "echo \"---------------------------\""\
        "export DISPLAY=:0"\
        "echo \"\\\"export DISPLAY=:0\\\" done!\""\
        "echo \"---------------------------\""\
        ""\
        "# Since we could run the job with a pipeline to handle the std output with mbuffer, we must activate pipefail to get the correct error code!"\
        "set -o pipefail"\
        ""\
        "# Run jobs from different directories"
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        __static__AddToJobscriptFile\
            "mkdir -p \$workdir$INDEX || exit 2"\
            "cd \$workdir$INDEX"\
            "pwd &"\
            "if hash mbuffer 2>/dev/null; then"\
            "    time \$dir$INDEX/$HMC_FILENAME --input-file=\$dir$INDEX/$INPUTFILE_NAME --device=$INDEX --beta=${BETA_FOR_JOBSCRIPT[$INDEX]%%_*} 2> \$dir$INDEX/\$errFile | mbuffer -q -m2M > \$dir$INDEX/\$outFile &"\
            "else"\
            "    time srun -n 1 \$dir$INDEX/$HMC_FILENAME --input-file=\$dir$INDEX/$INPUTFILE_NAME --device=$INDEX --beta=${BETA_FOR_JOBSCRIPT[$INDEX]%%_*} > \$dir$INDEX/\$outFile 2> \$dir$INDEX/\$errFile &"\
            "fi"\
            "PID_SRUN_$INDEX=\${!}"\
            ""
    done
    __static__AddToJobscriptFile "#Execute wait \$PID job after job"
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        __static__AddToJobscriptFile "wait \$PID_SRUN_$INDEX || { printf \"\nError occurred in simulation at b${BETA_FOR_JOBSCRIPT[$INDEX]%_*}. Please check (process id \${PID_SRUN_$INDEX})...\n\" && ERROR_OCCURRED=\"TRUE\"; }"
    done
    __static__AddToJobscriptFile\
        ""\
        "# Terminating job manually to get an email in case of failure of any run"\
        "if [ \"\$ERROR_OCCURRED\" = \"TRUE\" ]; then"\
        "   printf \"\nTerminating job with non zero exit code... (\$(date))\n\""\
        "   exit 255"\
        "fi"\
        ""\
        "# Unset pipefail since not needed anymore"\
        "set +o pipefail"\
        ""\
        "echo \"---------------------------\""\
        ""\
        "echo \"Date and time: \$(date)\""\
        "" ""
    if [ "$HOME_DIR" != "$WORK_DIR" ]; then
        __static__AddToJobscriptFile "# Backup files"
        for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
            __static__AddToJobscriptFile "cd \$dir$INDEX || exit 2"
            if [ $MEASURE_PBP = "TRUE" ]; then
                __static__AddToJobscriptFile "cp \$workdir$INDEX/${OUTPUTFILE_NAME}_pbp.dat \$dir$INDEX/${OUTPUTFILE_NAME}_pbp.\$SLURM_JOB_ID || exit 2"
            fi
            __static__AddToJobscriptFile "cp \$workdir$INDEX/$OUTPUTFILE_NAME \$dir$INDEX/$OUTPUTFILE_NAME.\$SLURM_JOB_ID || exit 2" ""
        done
    fi
    __static__AddToJobscriptFile "# Remove executable"
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        __static__AddToJobscriptFile "rm \$dir$INDEX/$HMC_FILENAME || exit 2"
    done
    __static__AddToJobscriptFile ""
    if [ $THERMALIZE = "TRUE" ] || [ $CONTINUE_THERMALIZATION = "TRUE" ]; then
        __static__AddToJobscriptFile "# Copy last configuration to Thermalized Configurations folder"
        if [ $BETA_POSTFIX == "_thermalizeFromHot" ]; then
            for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
                __static__AddToJobscriptFile\
                    "NUMBER_LAST_CONFIGURATION_IN_FOLDER=\$(ls \$workdir$INDEX | grep 'conf.[0-9]\+' | grep -o '[0-9]\+' | sort -V | tail -n1)" \
                    "cp \$workdir$INDEX/conf.\${NUMBER_LAST_CONFIGURATION_IN_FOLDER} ${THERMALIZED_CONFIGURATIONS_PATH}/conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA_FOR_JOBSCRIPT[$INDEX]%_*}_fromHot\$(sed 's/^0*//' <<< \"\$NUMBER_LAST_CONFIGURATION_IN_FOLDER\") || exit 2"
            done
        elif [ $BETA_POSTFIX == "_thermalizeFromConf" ]; then
            for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
                __static__AddToJobscriptFile "NUMBER_LAST_CONFIGURATION_IN_FOLDER=\$(ls \$workdir$INDEX | grep 'conf.[0-9]\+' | grep -o '[0-9]\+' | sort -V | tail -n1)"
                #TODO: For the moment we assume 1000 tr. are done from hot. Better to avoid it
                __static__AddToJobscriptFile\
                    "TRAJECTORIES_DONE_FROM_CONF=\$(( \$(sed 's/^0*//' <<< \"\$NUMBER_LAST_CONFIGURATION_IN_FOLDER\") - 1000 ))"\
                    "cp \$workdir$INDEX/conf.\${NUMBER_LAST_CONFIGURATION_IN_FOLDER} ${THERMALIZED_CONFIGURATIONS_PATH}/conf.${PARAMETERS_STRING}_${BETA_PREFIX}${BETA_FOR_JOBSCRIPT[$INDEX]%_*}_fromConf\${TRAJECTORIES_DONE_FROM_CONF} || exit 2"
            done
        fi
    fi
}
