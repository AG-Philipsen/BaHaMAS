#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

function __static__AddToInverterJobscriptFile()
{
    while [ $# -ne 0 ]; do
        printf "%s\n" "$1" >> $jobScriptGlobalPath
        shift
    done
}

function ProduceInverterJobscript_CL2QCD()
{
    rm -f $jobScriptGlobalPath || exit $BHMAS_fatalBuiltin
    touch $jobScriptGlobalPath || exit $BHMAS_fatalBuiltin

    #-----------------------------------------------------------------#
    # This piece of script uses the variable
    #   local betasForJobScript
    # created in the function from which it is called.
    #-----------------------------------------------------------------#
    #This jobscript is for CL2QCD only!
    __static__AddToInverterJobscriptFile\
        "#!/bin/bash"\
        ""\
        "#SBATCH --job-name=${jobScriptFilename#${BHMAS_jobScriptPrefix}_*}"\
        "#SBATCH --mail-type=FAIL"\
        "#SBATCH --mail-user=$BHMAS_userEmail"\
        "#SBATCH --time=$BHMAS_walltime"\
        "#SBATCH --output=${BHMAS_inverterFilename}.%j.out"\
        "#SBATCH --error=${BHMAS_inverterFilename}.%j.err"\
        "#SBATCH --no-requeue"

    [ "$BHMAS_clusterPartition"        != '' ] && __static__AddToJobscriptFile "#SBATCH --partition=$BHMAS_clusterPartition"
    [ "$BHMAS_clusterNode"             != '' ] && __static__AddToJobscriptFile "#SBATCH --nodelist=$BHMAS_clusterNode"
    [ "$BHMAS_clusterConstraint"       != '' ] && __static__AddToJobscriptFile "#SBATCH --constraint=$BHMAS_clusterConstraint"
    [ "$BHMAS_clusterGenericResource" != '' ] && __static__AddToJobscriptFile "#SBATCH --gres=$BHMAS_clusterGenericResource"

    #Trying to retrieve information about the list of nodes to be excluded if user gave file
    if [ "$BHMAS_excludeNodesGlobalPath" != '' ]; then
        if [ -f "$BHMAS_excludeNodesGlobalPath" ]; then
            EXCLUDE_STRING=$(grep -oE '\-\-exclude=.*\[.*\]' $BHMAS_excludeNodesGlobalPath 2>/dev/null)
        elif [[ $BHMAS_excludeNodesGlobalPath =~ : ]]; then
            EXCLUDE_STRING=$(ssh ${BHMAS_excludeNodesGlobalPath%%:*} "grep -oE '\-\-exclude=.*\[.*\]' ${BHMAS_excludeNodesGlobalPath#*:} 2>/dev/null")
        fi
        if [ "${EXCLUDE_STRING:-}" != "" ]; then
            __static__AddToInverterJobscriptFile "#SBATCH $EXCLUDE_STRING"
            cecho "\e[1A\e[80C\t$EXCLUDE_STRING"
        else
            cecho -n "\n " ly B U "WARNING" uU ":" uB " No exclude string to exclude nodes in jobscript found!\n"
            AskUser "         Do you still want to continue with jobscript creation?"
            if UserSaidNo; then
                cecho "\n" B lr "Exiting from job script creation process...\n"
                rm -f $jobScriptGlobalPath
                exit $BHMAS_successExitCode
            fi
        fi
    fi

    __static__AddToInverterJobscriptFile "#SBATCH --ntasks=$BHMAS_GPUsPerNode" ""
    for INDEX in "${!betasForJobScript[@]}"; do
        __static__AddToInverterJobscriptFile "dir$INDEX=${BHMAS_submitDirWithBetaFolders}/$BHMAS_betaPrefix${betasForJobScript[$INDEX]}"
    done
    __static__AddToInverterJobscriptFile ""
    for INDEX in "${!betasForJobScript[@]}"; do
        __static__AddToInverterJobscriptFile "workdir$INDEX=${BHMAS_runDirWithBetaFolders}/$BHMAS_betaPrefix${betasForJobScript[$INDEX]}"
    done
    __static__AddToInverterJobscriptFile\
        ""\
        "outFile=$BHMAS_inverterFilename.\$SLURM_JOB_ID.out"\
        "errFile=$BHMAS_inverterFilename.\$SLURM_JOB_ID.err"\
        ""\
        "# Check if directories exist"
    for INDEX in "${!betasForJobScript[@]}"; do
        __static__AddToInverterJobscriptFile\
            "if [ ! -d \$dir$INDEX ]; then"\
            "  echo \"Could not find directory \\\"\$dir$INDEX\\\" for runs. Aborting...\"" \
            "  exit $BHMAS_fatalFileNotFound" \
            "fi" \
            ""
    done
    __static__AddToInverterJobscriptFile\
        "# Print some information"\
        "echo \"$(printf "%s " ${betasForJobScript[@]})\""\
        "echo \"\""\
        "echo \"Host: \$(hostname)\""\
        "echo \"GPU:  \$GPU_DEVICE_ORDINAL\""\
        "echo \"Date and time: \$(date)\""\
        "echo \$SLURM_JOB_NODELIST > $BHMAS_inverterFilename.${betasString:1}.\$SLURM_JOB_ID.nodelist"\
        ""\
        "# TODO: this is necessary because the log file is produced in the directoy"\
        "#       of the exec. Copying it later does not guarantee that it is still the same..."\
        "echo \"Copy executable to beta directories in ${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}x.xxxx...\""
    for INDEX in "${!betasForJobScript[@]}"; do
        __static__AddToInverterJobscriptFile "rm -f \$dir$INDEX/$BHMAS_inverterFilename && cp -a $BHMAS_inverterGlobalPath \$dir$INDEX || exit $BHMAS_fatalBuiltin"
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
    for INDEX in "${!betasForJobScript[@]}"; do
        #The following check is done twice. During the creation of the jobscript for the case in which the $BHMAS_inversionSrunCommandsFilename does not exist from the beginning on and
        #in the jobscript itself for the case in which it exists during the creation of the jobscript but accidentally gets deleted later on after the creation.
        if [ ! -e ${BHMAS_runDirWithBetaFolders}/$BHMAS_betaPrefix${betasForJobScript[$INDEX]}/$BHMAS_inversionSrunCommandsFilename ]; then
            Fatal $BHMAS_fatalFileNotFound "File " emph "${BHMAS_runDirWithBetaFolders}/$BHMAS_betaPrefix${betasForJobScript[$INDEX]}/$BHMAS_inversionSrunCommandsFilename"\
                  " with execution commands for the inversion was not found!"
        fi
        __static__AddToInverterJobscriptFile\
            "mkdir -p \$workdir$INDEX || exit $BHMAS_fatalBuiltin"\
            "cd \$workdir$INDEX"\
            "pwd"\
            "if [ ! -e \$workdir$INDEX/$BHMAS_inversionSrunCommandsFilename ]; then"\
            "  echo \"File \$workdir$INDEX/$BHMAS_inversionSrunCommandsFilename with execution commands for the inversion was not found! Aborting...\""\
            "  exit $BHMAS_fatalFileNotFound"\
            "fi"\
            "OLD_IFS=\$IFS"\
            "IFS=\$'\n'"\
            "for line in \$(cat \$workdir$INDEX/$BHMAS_inversionSrunCommandsFilename); do"\
            "    IFS=\$OLD_IFS #Restore here old IFS to give separated options (and not only one)to CL2QCD!"\
            "    if hash mbuffer 2>/dev/null; then"\
            "        time \$dir$INDEX/$BHMAS_inverterFilename \$line --device=$INDEX 2>> \$dir$INDEX/\$errFile | mbuffer -q -m2M >> \$dir$INDEX/\$outFile"\
            "    else"\
            "        time srun -n 1 \$dir$INDEX/$BHMAS_inverterFilename \$line --device=$INDEX 2>> \$dir$INDEX/\$errFile >> \$dir$INDEX/\$outFile"\
            "    fi"\
            "    if [ \$? -ne 0 ]; then"\
            "        printf \"\nError occurred in simulation at b${betasForJobScript[$INDEX]%_*}.\n\""\
            "        CONFIGURATION_$INDEX=\$(grep -o \"conf.[[:digit:]]\{5\}\" <<< \"\$line\")"\
            "        CORRELATOR_POSTFIX_$INDEX=\$(grep -o \"_[[:digit:]]\+_[[:digit:]]\+_[[:digit:]]\+_[[:digit:]]\+_corr\"  <<< \"\$line\")"\
            "        echo \$CONFIGURATION_$INDEX\$CORRELATOR_POSTFIX_$INDEX >> \$dir$INDEX/failed_inversions_tmp_file"\
            "    fi"\
            "done &"\
            "IFS=\$OLD_IFS"\
            "PID_FOR_$INDEX=\${!}"\
            ""
    done
    for INDEX in "${!betasForJobScript[@]}"; do
        __static__AddToInverterJobscriptFile\
            "wait \$PID_FOR_$INDEX || { printf \"\nError occurred in simulation at b${betasForJobScript[$INDEX]%_*}. Please check (process id \${PID_FOR_$INDEX})...\n\"; }"
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
    for INDEX in "${!betasForJobScript[@]}"; do
        __static__AddToInverterJobscriptFile "rm \$dir$INDEX/$BHMAS_inverterFilename || exit $BHMAS_fatalBuiltin"
    done
    __static__AddToInverterJobscriptFile ""

    for INDEX in "${!betasForJobScript[@]}"; do
        __static__AddToInverterJobscriptFile\
            "if [ -e \$dir$INDEX/failed_inversions_tmp_file ]; then"\
            "  ERROR_OCCURRED="TRUE""\
            "  echo \"Failed inversions at b${betasForJobScript[$INDEX]%_*}:\" >> \$dir$INDEX/\$errFile"\
            "  cat \$dir$INDEX/failed_inversions_tmp_file >> \$dir$INDEX/\$errFile"\
            "  rm \$dir$INDEX/failed_inversions_tmp_file"\
            "fi"
    done

    __static__AddToInverterJobscriptFile\
        "if [ \"\$ERROR_OCCURRED\" = \"TRUE\" ]; then"\
        "  printf \"\nTerminating job with non zero exit code... (\$(date))\n\""\
        "  exit $BHMAS_fatalGeneric"\
        "fi"
}
