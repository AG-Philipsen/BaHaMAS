#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

function __static__AddToJobscriptFile()
{
    while [ $# -ne 0 ]; do
        printf "%s\n" "$1" >> $jobScriptGlobalPath
        shift
    done
}

function ProduceJobscript_CL2QCD()
{
    local jobScriptGlobalPath jobScriptFilename walltime betaValues index excludeString
    jobScriptGlobalPath="$1"; jobScriptFilename="$2"; walltime="$3"; shift 3
    betaValues=( "$@" )

    rm -f $jobScriptGlobalPath || exit $BHMAS_fatalBuiltin
    touch $jobScriptGlobalPath || exit $BHMAS_fatalBuiltin

    #-----------------------------------------------------------------#
    # This piece of script uses the variable
    #   local betaValues
    # created in the function from which it is called.
    #-----------------------------------------------------------------#
    #This jobscript is for CL2QCD only!
    __static__AddToJobscriptFile\
        "#!/bin/bash"\
        ""\
        "#SBATCH --job-name=${jobScriptFilename#${BHMAS_jobScriptPrefix}_*}"\
        "#SBATCH --mail-type=FAIL"\
        "#SBATCH --mail-user=$BHMAS_userEmail"\
        "#SBATCH --time=$walltime"\
        "#SBATCH --output=${BHMAS_hmcFilename}.%j.out"\
        "#SBATCH --error=${BHMAS_hmcFilename}.%j.err"\
        "#SBATCH --no-requeue"

    [ "$BHMAS_clusterPartition"       != '' ] && __static__AddToJobscriptFile "#SBATCH --partition=$BHMAS_clusterPartition"
    [ "$BHMAS_clusterNode"            != '' ] && __static__AddToJobscriptFile "#SBATCH --nodelist=$BHMAS_clusterNode"
    [ "$BHMAS_clusterConstraint"      != '' ] && __static__AddToJobscriptFile "#SBATCH --constraint=$BHMAS_clusterConstraint"
    [ "$BHMAS_clusterGenericResource" != '' ] && __static__AddToJobscriptFile "#SBATCH --gres=$BHMAS_clusterGenericResource"

    #Trying to retrieve information about the list of nodes to be excluded if user gave file
    if [ "$BHMAS_excludeNodesGlobalPath" != '' ]; then
        if [ -f "$BHMAS_excludeNodesGlobalPath" ]; then
            excludeString=$(grep -oE '\-\-exclude=.*\[.*\]' $BHMAS_excludeNodesGlobalPath 2>/dev/null)
        elif [[ $BHMAS_excludeNodesGlobalPath =~ : ]]; then
            excludeString=$(ssh ${BHMAS_excludeNodesGlobalPath%%:*} "grep -oE '\-\-exclude=.*\[.*\]' ${BHMAS_excludeNodesGlobalPath#*:} 2>/dev/null")
        fi
        if [ "${excludeString:-}" != "" ]; then
            __static__AddToJobscriptFile "#SBATCH $excludeString"
            cecho "\e[1A\e[80C\t$excludeString"
        else
            cecho -n "\n " ly B U "WARNING" uU ":" uB " No exclude string to exclude nodes in jobscript found!"
            AskUser "         Do you still want to continue with jobscript creation?"
            if UserSaidNo; then
                cecho "\n" B lr "Exiting from job script creation process...\n"
                rm -f $jobScriptGlobalPath
                exit $BHMAS_successExitCode
            fi
        fi
    fi

    __static__AddToJobscriptFile "#SBATCH --ntasks=$BHMAS_GPUsPerNode" ""
    for index in "${!betaValues[@]}"; do
        __static__AddToJobscriptFile "dir${index}=${BHMAS_submitDirWithBetaFolders}/$BHMAS_betaPrefix${betaValues[${index}]}"
    done
    __static__AddToJobscriptFile ""
    for index in "${!betaValues[@]}"; do
        __static__AddToJobscriptFile "workdir${index}=${BHMAS_runDirWithBetaFolders}/$BHMAS_betaPrefix${betaValues[${index}]}"
    done
    __static__AddToJobscriptFile\
        ""\
        "outFile=$BHMAS_hmcFilename.\$SLURM_JOB_ID.out"\
        "errFile=$BHMAS_hmcFilename.\$SLURM_JOB_ID.err"\
        ""\
        "# Check if directories exist"
    for index in "${!betaValues[@]}"; do
        __static__AddToJobscriptFile\
            "if [ ! -d \$dir${index} ]; then"\
            "  echo \"Could not find directory \\\"\$dir${index}\\\" for runs. Aborting...\"" \
            "  exit $BHMAS_fatalFileNotFound" \
            "fi" \
            ""
    done
    __static__AddToJobscriptFile\
        "# Print some information"\
        "echo \"$(printf "%s " ${betaValues[@]})\""\
        "echo \"\""\
        "echo \"Host: \$(hostname)\""\
        "echo \"GPU:  \$GPU_DEVICE_ORDINAL\""\
        "echo \"Date and time: \$(date)\""\
        "echo \$SLURM_JOB_NODELIST > $BHMAS_hmcFilename.${betasString:1}.\$SLURM_JOB_ID.nodelist"\
        ""\
        "# TODO: this is necessary because the log file is produced in the directoy"\
        "#       of the exec. Copying it later does not guarantee that it is still the same..."\
        "echo \"Copy executable to beta directories in ${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}x.xxxx...\""
    for index in "${!betaValues[@]}"; do
        __static__AddToJobscriptFile "rm -f \$dir${index}/$BHMAS_hmcFilename && cp -a $BHMAS_hmcGlobalPath \$dir${index} || exit $BHMAS_fatalBuiltin"
    done
    __static__AddToJobscriptFile "echo \"...done!\"" ""
    if [ "$BHMAS_submitDiskGlobalPath" != "$BHMAS_runDiskGlobalPath" ]; then
        __static__AddToJobscriptFile "#Copy inputfile from home to work directories..."
        for index in "${!betaValues[@]}"; do
            __static__AddToJobscriptFile "mkdir -p \$workdir${index} && cp \$dir${index}/$BHMAS_inputFilename \$workdir${index}/$BHMAS_inputFilename.\$SLURM_JOB_ID || exit $BHMAS_fatalBuiltin"
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
    for index in "${!betaValues[@]}"; do
        __static__AddToJobscriptFile\
            "mkdir -p \$workdir${index} || exit $BHMAS_fatalBuiltin"\
            "cd \$workdir${index}"\
            "pwd &"\
            "if hash mbuffer 2>/dev/null; then"\
            "    time \$dir${index}/$BHMAS_hmcFilename --input-file=\$dir${index}/$BHMAS_inputFilename --device=${index} --beta=${betaValues[${index}]%%_*} 2> \$dir${index}/\$errFile | mbuffer -q -m2M > \$dir${index}/\$outFile &"\
            "else"\
            "    time srun -n 1 \$dir${index}/$BHMAS_hmcFilename --input-file=\$dir${index}/$BHMAS_inputFilename --device=${index} --beta=${betaValues[${index}]%%_*} > \$dir${index}/\$outFile 2> \$dir${index}/\$errFile &"\
            "fi"\
            "PID_SRUN_${index}=\${!}"\
            ""
    done
    __static__AddToJobscriptFile "#Execute wait \$PID job after job"
    for index in "${!betaValues[@]}"; do
        __static__AddToJobscriptFile "wait \$PID_SRUN_${index} || { printf \"\nError occurred in simulation at b${betaValues[${index}]%_*}. Please check (process id \${PID_SRUN_${index}})...\n\" && ERROR_OCCURRED=\"TRUE\"; }"
    done
    __static__AddToJobscriptFile\
        ""\
        "# Terminating job manually to get an email in case of failure of any run"\
        "if [ \"\$ERROR_OCCURRED\" = \"TRUE\" ]; then"\
        "   printf \"\nTerminating job with non zero exit code... (\$(date))\n\""\
        "   exit $BHMAS_fatalGeneric"\
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
        for index in "${!betaValues[@]}"; do
            __static__AddToJobscriptFile "cd \$dir${index} || exit $BHMAS_fatalBuiltin"
            if [ $BHMAS_measurePbp = "TRUE" ]; then
                __static__AddToJobscriptFile "cp \$workdir${index}/${BHMAS_outputFilename}_pbp.dat \$dir${index}/${BHMAS_outputFilename}_pbp.\$SLURM_JOB_ID || exit $BHMAS_fatalBuiltin"
            fi
            __static__AddToJobscriptFile "cp \$workdir${index}/$BHMAS_outputFilename \$dir${index}/$BHMAS_outputFilename.\$SLURM_JOB_ID || exit $BHMAS_fatalBuiltin" ""
        done
    fi
    __static__AddToJobscriptFile "# Remove executable"
    for index in "${!betaValues[@]}"; do
        __static__AddToJobscriptFile "rm \$dir${index}/$BHMAS_hmcFilename || exit $BHMAS_fatalBuiltin"
    done
    __static__AddToJobscriptFile ""
    if [ $BHMAS_thermalizeOption = "TRUE" ] || [ $BHMAS_continueThermalizationOption = "TRUE" ]; then
        __static__AddToJobscriptFile "# Copy last configuration to Thermalized Configurations folder"
        if [ $BHMAS_betaPostfix == "_thermalizeFromHot" ]; then
            for index in "${!betaValues[@]}"; do
                __static__AddToJobscriptFile\
                    "NUMBER_LAST_CONFIGURATION_IN_FOLDER=\$(ls \$workdir${index} | grep 'conf.[0-9]\+' | grep -o '[0-9]\+' | sort -V | tail -n1)" \
                    "cp \$workdir${index}/conf.\${NUMBER_LAST_CONFIGURATION_IN_FOLDER} ${BHMAS_thermConfsGlobalPath}/conf.${BHMAS_parametersString}_${BHMAS_betaPrefix}${betaValues[${index}]%_*}_fromHot\$(sed 's/^0*//' <<< \"\$NUMBER_LAST_CONFIGURATION_IN_FOLDER\") || exit $BHMAS_fatalBuiltin"
            done
        elif [ $BHMAS_betaPostfix == "_thermalizeFromConf" ]; then
            for index in "${!betaValues[@]}"; do
                __static__AddToJobscriptFile "NUMBER_LAST_CONFIGURATION_IN_FOLDER=\$(ls \$workdir${index} | grep 'conf.[0-9]\+' | grep -o '[0-9]\+' | sort -V | tail -n1)"
                #TODO: For the moment we assume 1000 tr. are done from hot. Better to avoid it
                __static__AddToJobscriptFile\
                    "TRAJECTORIES_DONE_FROM_CONF=\$(( \$(sed 's/^0*//' <<< \"\$NUMBER_LAST_CONFIGURATION_IN_FOLDER\") - 1000 ))"\
                    "cp \$workdir${index}/conf.\${NUMBER_LAST_CONFIGURATION_IN_FOLDER} ${BHMAS_thermConfsGlobalPath}/conf.${BHMAS_parametersString}_${BHMAS_betaPrefix}${betaValues[${index}]%_*}_fromConf\${TRAJECTORIES_DONE_FROM_CONF} || exit $BHMAS_fatalBuiltin"
            done
        fi
    fi
}
