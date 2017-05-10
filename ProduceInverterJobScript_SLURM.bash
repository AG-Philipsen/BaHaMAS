function __static__AddToInverterJobscriptFile() {
    while [ $# -ne 0 ]; do
        printf "%s\n" "$1" >> $JOBSCRIPT_GLOBALPATH
        shift
    done
}

function ProduceInverterJobscript_SLURM(){
    rm -f $JOBSCRIPT_GLOBALPATH || exit -2
    touch $JOBSCRIPT_GLOBALPATH || exit -2

    #-----------------------------------------------------------------#
    # This piece of script uses the variable
    #   local BETA_FOR_JOBSCRIPT
    # created in the function from which it is called.
    #-----------------------------------------------------------------#
    #This jobscript is for CL2QCD only!
    __static__AddToInverterJobscriptFile\
        "#!/bin/bash"\
        ""\
        "#SBATCH --job-name=${JOBSCRIPT_NAME#${JOBSCRIPT_PREFIX}_*}"\
        "#SBATCH --mail-type=FAIL"\
        "#SBATCH --mail-user=$USER_MAIL"\
        "#SBATCH --time=$WALLTIME"\
        "#SBATCH --output=${INVERTER_FILENAME}.%j.out"\
        "#SBATCH --error=${INVERTER_FILENAME}.%j.err"\
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
            __static__AddToInverterJobscriptFile "#SBATCH $EXCLUDE_STRING"
            cecho "\e[1A\e[80C\t$EXCLUDE_STRING"
        else
            cecho -n "\n" ly B U "WARNING" uU ":" uB " No exclude string to exclude nodes in jobscript found!\n"\
                  "         Do you still want to continue with jobscript creation? [Y/N] "
            if UserSaidNo; then
                cecho "\n" B lr "Exiting from job script creation process...\n"
                rm -f $JOBSCRIPT_GLOBALPATH
                exit
            fi
        fi
    fi

    __static__AddToInverterJobscriptFile "#SBATCH --ntasks=$GPU_PER_NODE" ""
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        __static__AddToInverterJobscriptFile "dir$INDEX=${HOME_DIR_WITH_BETAFOLDERS}/$BETA_PREFIX${BETA_FOR_JOBSCRIPT[$INDEX]}"
    done
    __static__AddToInverterJobscriptFile ""
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        __static__AddToInverterJobscriptFile "workdir$INDEX=${WORK_DIR_WITH_BETAFOLDERS}/$BETA_PREFIX${BETA_FOR_JOBSCRIPT[$INDEX]}"
    done
    __static__AddToInverterJobscriptFile\
        ""\
        "outFile=$INVERTER_FILENAME.\$SLURM_JOB_ID.out"\
        "errFile=$INVERTER_FILENAME.\$SLURM_JOB_ID.err"\
        ""\
        "# Check if directories exist"
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        __static__AddToInverterJobscriptFile\
            "if [ ! -d \$dir$INDEX ]; then"\
            "  echo \"Could not find directory \\\"\$dir$INDEX\\\" for runs. Aborting...\"" \
            "  exit 2" \
            "fi" \
            ""
    done
    __static__AddToInverterJobscriptFile\
        "# Print some information"\
        "echo \"$(printf "%s " ${BETA_FOR_JOBSCRIPT[@]})\""\
        "echo \"\""\
        "echo \"Host: \$(hostname)\""\
        "echo \"GPU:  \$GPU_DEVICE_ORDINAL\""\
        "echo \"Date and time: \$(date)\""\
        "echo \$SLURM_JOB_NODELIST > $INVERTER_FILENAME.${BETAS_STRING:1}.\$SLURM_JOB_ID.nodelist"\
        ""\
        "# TODO: this is necessary because the log file is produced in the directoy"\
        "#       of the exec. Copying it later does not guarantee that it is still the same..."\
        "echo \"Copy executable to beta directories in ${WORK_DIR_WITH_BETAFOLDERS}/${BETA_PREFIX}x.xxxx...\""
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        __static__AddToInverterJobscriptFile "rm -f \$dir$INDEX/$INVERTER_FILENAME && cp -a $INVERTER_GLOBALPATH \$dir$INDEX || exit 2"
    done
    __static__AddToInverterJobscriptFile\
        "echo \"...done!\""\
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
        #The following check is done twice. During the creation of the jobscript for the case in which the $SRUN_COMMANDSFILE_FOR_INVERSION does not exist from the beginning on and
        #in the jobscript itself for the case in which it exists during the creation of the jobscript but accidentally gets deleted later on after the creation.
        #if [ ! -e $workdir$INDEX/$SRUN_COMMANDSFILE_FOR_INVERSION ]; then #SHOULD BE LIKE THIS??
        if [ ! -e ${WORK_DIR_WITH_BETAFOLDERS}/$BETA_PREFIX${BETA_FOR_JOBSCRIPT[$INDEX]}/$SRUN_COMMANDSFILE_FOR_INVERSION ]; then #I THINK WORK_BETADIRECTORY has to be replaced!!!!
            cecho lr "File ${WORK_DIR_WITH_BETAFOLDERS}/$BETA_PREFIX${BETA_FOR_JOBSCRIPT[$INDEX]}/$SRUN_COMMANDSFILE_FOR_INVERSION with execution commands for the inversion does not exist...aborting"
            exit 30
        fi
        __static__AddToInverterJobscriptFile\
            "mkdir -p \$workdir$INDEX || exit 2"\
            "cd \$workdir$INDEX"\
            "pwd"\
            "if [ ! -e \$workdir$INDEX/$SRUN_COMMANDSFILE_FOR_INVERSION ]; then"\
            "  echo \"File \$workdir$INDEX/$SRUN_COMMANDSFILE_FOR_INVERSION with execution commands for the inversion does not exist...aborting\""\
            "  exit 30"\
            "fi"\
            "OLD_IFS=\$IFS"\
            "IFS=\$'\n'"\
            "for line in \$(cat \$workdir$INDEX/$SRUN_COMMANDSFILE_FOR_INVERSION); do"\
            "    IFS=\$OLD_IFS #Restore here old IFS to give separated options (and not only one)to CL2QCD!"\
            "    if hash mbuffer 2>/dev/null; then"\
            "        time \$dir$INDEX/$INVERTER_FILENAME \$line --device=$INDEX 2>> \$dir$INDEX/\$errFile | mbuffer -q -m2M >> \$dir$INDEX/\$outFile"\
            "    else"\
            "        time srun -n 1 \$dir$INDEX/$INVERTER_FILENAME \$line --device=$INDEX 2>> \$dir$INDEX/\$errFile >> \$dir$INDEX/\$outFile"\
            "    fi"\
            "    if [ \$? -ne 0 ]; then"\
            "        printf \"\nError occurred in simulation at b${BETA_FOR_JOBSCRIPT[$INDEX]%_*}.\n\""\
            "        CONFIGURATION_$INDEX=\$(grep -o \"conf.[[:digit:]]\{5\}\" <<< \"\$line\")"\
            "        CORRELATOR_POSTFIX_$INDEX=\$(grep -o \"_[[:digit:]]\+_[[:digit:]]\+_[[:digit:]]\+_[[:digit:]]\+_corr\"  <<< \"\$line\")"\
            "        echo \$CONFIGURATION_$INDEX\$CORRELATOR_POSTFIX_$INDEX >> \$dir$INDEX/failed_inversions_tmp_file"\
            "    fi"\
            "done &"\
            "IFS=\$OLD_IFS"\
            "PID_FOR_$INDEX=\${!}"\
            ""
    done
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        __static__AddToInverterJobscriptFile\
            "wait \$PID_FOR_$INDEX || { printf \"\nError occurred in simulation at b${BETA_FOR_JOBSCRIPT[$INDEX]%_*}. Please check (process id \${PID_FOR_$INDEX})...\n\"; }"
    done
    __static__AddToInverterJobscriptFile\
        ""\
        "# Unset pipefail since not needed anymore"\
        "set +o pipefail"\
        ""\
        "echo \"---------------------------\""\
        ""\
        "echo \"Date and time: \$(date)\""\
        "" ""\
        "# Remove executable"
    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        __static__AddToInverterJobscriptFile "rm \$dir$INDEX/$INVERTER_FILENAME || exit 2"
    done
    __static__AddToInverterJobscriptFile ""

    for INDEX in "${!BETA_FOR_JOBSCRIPT[@]}"; do
        __static__AddToInverterJobscriptFile\
            "if [ -e \$dir$INDEX/failed_inversions_tmp_file ]; then"\
            "  ERROR_OCCURRED="TRUE""\
            "  echo \"Failed inversions at b${BETA_FOR_JOBSCRIPT[$INDEX]%_*}:\" >> \$dir$INDEX/\$errFile"\
            "  cat \$dir$INDEX/failed_inversions_tmp_file >> \$dir$INDEX/\$errFile"\
            "  rm \$dir$INDEX/failed_inversions_tmp_file"\
            "fi"
    done

    __static__AddToInverterJobscriptFile\
        "if [ \"\$ERROR_OCCURRED\" = \"TRUE\" ]; then"\
        "  printf \"\nTerminating job with non zero exit code... (\$(date))\n\""\
        "  exit 255"\
        "fi"
}
