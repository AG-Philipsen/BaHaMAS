function __static__AddToJobscriptFile()
{
    while [ $# -ne 0 ]; do
        printf "%s\n" "$1" >> $jobScriptGlobalPath
        shift
    done
}

function ProduceJobscript_CL2QCD()
{
    rm -f $jobScriptGlobalPath || exit -2
    touch $jobScriptGlobalPath || exit -2

    #-----------------------------------------------------------------#
    # This piece of script uses the variable
    #   local betasForJobScript
    # created in the function from which it is called.
    #-----------------------------------------------------------------#
    #This jobscript is for CL2QCD only!
    __static__AddToJobscriptFile\
        "#!/bin/bash"\
        ""\
        "#SBATCH --job-name=${jobScriptFilename#${BHMAS_jobScriptPrefix}_*}"\
        "#SBATCH --mail-type=FAIL"\
        "#SBATCH --mail-user=$BHMAS_userEmail"\
        "#SBATCH --time=$BHMAS_walltime"\
        "#SBATCH --output=${HMC_FILENAME}.%j.out"\
        "#SBATCH --error=${HMC_FILENAME}.%j.err"\
        "#SBATCH --no-requeue"

    [ "$BHMAS_clusterPartition"       != '' ] && __static__AddToJobscriptFile "#SBATCH --partition=$BHMAS_clusterPartition"
    [ "$BHMAS_clusterNode"            != '' ] && __static__AddToJobscriptFile "#SBATCH --nodelist=$BHMAS_clusterNode"
    [ "$BHMAS_clusterConstraint"      != '' ] && __static__AddToJobscriptFile "#SBATCH --constraint=$BHMAS_clusterConstraint"
    [ "$BHMAS_clusterGenericResource" != '' ] && __static__AddToJobscriptFile "#SBATCH --gres=$BHMAS_clusterGenericResource"

    #Trying to retrieve information about the list of nodes to be excluded if user gave file
    if [ "$BHMAS_excludeNodesGlobalPath" != '' ]; then
        if [ -f "$BHMAS_excludeNodesGlobalPath" ]; then
            EXCLUDE_STRING=$(grep -oE '\-\-exclude=.*\[.*\]' $BHMAS_excludeNodesGlobalPath 2>/dev/null)
        elif [[ $BHMAS_excludeNodesGlobalPath =~ : ]]; then
            EXCLUDE_STRING=$(ssh ${BHMAS_excludeNodesGlobalPath%%:*} "grep -oE '\-\-exclude=.*\[.*\]' ${BHMAS_excludeNodesGlobalPath#*:} 2>/dev/null")
        fi
        if [ "${EXCLUDE_STRING:-}" != "" ]; then
            __static__AddToJobscriptFile "#SBATCH $EXCLUDE_STRING"
            cecho "\e[1A\e[80C\t$EXCLUDE_STRING"
        else
            cecho -n "\n " ly B U "WARNING" uU ":" uB " No exclude string to exclude nodes in jobscript found!"
            AskUser "         Do you still want to continue with jobscript creation?"
            if UserSaidNo; then
                cecho "\n" B lr "Exiting from job script creation process...\n"
                rm -f $jobScriptGlobalPath
                exit 0
            fi
        fi
    fi

    __static__AddToJobscriptFile "#SBATCH --ntasks=$BHMAS_GPUsPerNode" ""
    for INDEX in "${!betasForJobScript[@]}"; do
        __static__AddToJobscriptFile "dir$INDEX=${BHMAS_submitDirWithBetaFolders}/$BHMAS_betaPrefix${betasForJobScript[$INDEX]}"
    done
    __static__AddToJobscriptFile ""
    for INDEX in "${!betasForJobScript[@]}"; do
        __static__AddToJobscriptFile "workdir$INDEX=${BHMAS_runDirWithBetaFolders}/$BHMAS_betaPrefix${betasForJobScript[$INDEX]}"
    done
    __static__AddToJobscriptFile\
        ""\
        "outFile=$HMC_FILENAME.\$SLURM_JOB_ID.out"\
        "errFile=$HMC_FILENAME.\$SLURM_JOB_ID.err"\
        ""\
        "# Check if directories exist"
    for INDEX in "${!betasForJobScript[@]}"; do
        __static__AddToJobscriptFile\
            "if [ ! -d \$dir$INDEX ]; then"\
            "  echo \"Could not find directory \\\"\$dir$INDEX\\\" for runs. Aborting...\"" \
            "  exit 2" \
            "fi" \
            ""
    done
    __static__AddToJobscriptFile\
        "# Print some information"\
        "echo \"$(printf "%s " ${betasForJobScript[@]})\""\
        "echo \"\""\
        "echo \"Host: \$(hostname)\""\
        "echo \"GPU:  \$GPU_DEVICE_ORDINAL\""\
        "echo \"Date and time: \$(date)\""\
        "echo \$SLURM_JOB_NODELIST > $HMC_FILENAME.${betasString:1}.\$SLURM_JOB_ID.nodelist"\
        ""\
        "# TODO: this is necessary because the log file is produced in the directoy"\
        "#       of the exec. Copying it later does not guarantee that it is still the same..."\
        "echo \"Copy executable to beta directories in ${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}x.xxxx...\""
    for INDEX in "${!betasForJobScript[@]}"; do
        __static__AddToJobscriptFile "rm -f \$dir$INDEX/$HMC_FILENAME && cp -a $BHMAS_hmcGlobalPath \$dir$INDEX || exit 2"
    done
    __static__AddToJobscriptFile "echo \"...done!\"" ""
    if [ "$BHMAS_submitDiskGlobalPath" != "$BHMAS_runDiskGlobalPath" ]; then
        __static__AddToJobscriptFile "#Copy inputfile from home to work directories..."
        for INDEX in "${!betasForJobScript[@]}"; do
            __static__AddToJobscriptFile "mkdir -p \$workdir$INDEX && cp \$dir$INDEX/$BHMAS_inputFilename \$workdir$INDEX/$BHMAS_inputFilename.\$SLURM_JOB_ID || exit 2"
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
    for INDEX in "${!betasForJobScript[@]}"; do
        __static__AddToJobscriptFile\
            "mkdir -p \$workdir$INDEX || exit 2"\
            "cd \$workdir$INDEX"\
            "pwd &"\
            "if hash mbuffer 2>/dev/null; then"\
            "    time \$dir$INDEX/$HMC_FILENAME --input-file=\$dir$INDEX/$BHMAS_inputFilename --device=$INDEX --beta=${betasForJobScript[$INDEX]%%_*} 2> \$dir$INDEX/\$errFile | mbuffer -q -m2M > \$dir$INDEX/\$outFile &"\
            "else"\
            "    time srun -n 1 \$dir$INDEX/$HMC_FILENAME --input-file=\$dir$INDEX/$BHMAS_inputFilename --device=$INDEX --beta=${betasForJobScript[$INDEX]%%_*} > \$dir$INDEX/\$outFile 2> \$dir$INDEX/\$errFile &"\
            "fi"\
            "PID_SRUN_$INDEX=\${!}"\
            ""
    done
    __static__AddToJobscriptFile "#Execute wait \$PID job after job"
    for INDEX in "${!betasForJobScript[@]}"; do
        __static__AddToJobscriptFile "wait \$PID_SRUN_$INDEX || { printf \"\nError occurred in simulation at b${betasForJobScript[$INDEX]%_*}. Please check (process id \${PID_SRUN_$INDEX})...\n\" && ERROR_OCCURRED=\"TRUE\"; }"
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
    if [ "$BHMAS_submitDiskGlobalPath" != "$BHMAS_runDiskGlobalPath" ]; then
        __static__AddToJobscriptFile "# Backup files"
        for INDEX in "${!betasForJobScript[@]}"; do
            __static__AddToJobscriptFile "cd \$dir$INDEX || exit 2"
            if [ $BHMAS_measurePbp = "TRUE" ]; then
                __static__AddToJobscriptFile "cp \$workdir$INDEX/${BHMAS_outputFilename}_pbp.dat \$dir$INDEX/${BHMAS_outputFilename}_pbp.\$SLURM_JOB_ID || exit 2"
            fi
            __static__AddToJobscriptFile "cp \$workdir$INDEX/$BHMAS_outputFilename \$dir$INDEX/$BHMAS_outputFilename.\$SLURM_JOB_ID || exit 2" ""
        done
    fi
    __static__AddToJobscriptFile "# Remove executable"
    for INDEX in "${!betasForJobScript[@]}"; do
        __static__AddToJobscriptFile "rm \$dir$INDEX/$HMC_FILENAME || exit 2"
    done
    __static__AddToJobscriptFile ""
    if [ $BHMAS_thermalizeOption = "TRUE" ] || [ $BHMAS_continueThermalizationOption = "TRUE" ]; then
        __static__AddToJobscriptFile "# Copy last configuration to Thermalized Configurations folder"
        if [ $BHMAS_betaPostfix == "_thermalizeFromHot" ]; then
            for INDEX in "${!betasForJobScript[@]}"; do
                __static__AddToJobscriptFile\
                    "NUMBER_LAST_CONFIGURATION_IN_FOLDER=\$(ls \$workdir$INDEX | grep 'conf.[0-9]\+' | grep -o '[0-9]\+' | sort -V | tail -n1)" \
                    "cp \$workdir$INDEX/conf.\${NUMBER_LAST_CONFIGURATION_IN_FOLDER} ${BHMAS_thermConfsGlobalPath}/conf.${BHMAS_parametersString}_${BHMAS_betaPrefix}${betasForJobScript[$INDEX]%_*}_fromHot\$(sed 's/^0*//' <<< \"\$NUMBER_LAST_CONFIGURATION_IN_FOLDER\") || exit 2"
            done
        elif [ $BHMAS_betaPostfix == "_thermalizeFromConf" ]; then
            for INDEX in "${!betasForJobScript[@]}"; do
                __static__AddToJobscriptFile "NUMBER_LAST_CONFIGURATION_IN_FOLDER=\$(ls \$workdir$INDEX | grep 'conf.[0-9]\+' | grep -o '[0-9]\+' | sort -V | tail -n1)"
                #TODO: For the moment we assume 1000 tr. are done from hot. Better to avoid it
                __static__AddToJobscriptFile\
                    "TRAJECTORIES_DONE_FROM_CONF=\$(( \$(sed 's/^0*//' <<< \"\$NUMBER_LAST_CONFIGURATION_IN_FOLDER\") - 1000 ))"\
                    "cp \$workdir$INDEX/conf.\${NUMBER_LAST_CONFIGURATION_IN_FOLDER} ${BHMAS_thermConfsGlobalPath}/conf.${BHMAS_parametersString}_${BHMAS_betaPrefix}${betasForJobScript[$INDEX]%_*}_fromConf\${TRAJECTORIES_DONE_FROM_CONF} || exit 2"
            done
        fi
    fi
}
