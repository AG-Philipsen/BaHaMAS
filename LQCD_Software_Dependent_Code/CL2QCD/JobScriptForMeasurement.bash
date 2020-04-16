#
#  Copyright (c) 2015 Christopher Czaban
#  Copyright (c) 2016-2018,2020 Alessandro Sciarra
#
#  This file is part of BaHaMAS.
#
#  BaHaMAS is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  BaHaMAS is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with BaHaMAS. If not, see <http://www.gnu.org/licenses/>.
#

function __static__AddToInverterJobscriptFile()
{
    while [[ $# -ne 0 ]]; do
        printf "%s\n" "$1" >> ${jobScriptGlobalPath}
        shift
    done
}

function AddSoftwareSpecificPartToMeasurementJobScript_CL2QCD()
{
    local jobScriptGlobalPath betaValues index
    jobScriptGlobalPath="$1"; shift
    betaValues=( "$@" )

    #Job script variables
    for index in "${!betaValues[@]}"; do
        __static__AddToInverterJobscriptFile "dir${index}=${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValues[${index}]}"
    done
    __static__AddToInverterJobscriptFile ""
    for index in "${!betaValues[@]}"; do
        __static__AddToInverterJobscriptFile "workdir${index}=${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValues[${index}]}"
    done
    __static__AddToInverterJobscriptFile\
        ""\
        "outFile=${BHMAS_measurementExecutableFilename}.\${SLURM_JOB_ID}.out"\
        "errFile=${BHMAS_measurementExecutableFilename}.\${SLURM_JOB_ID}.err"\
        ""\
        "# Check if directories exist"

    #Job script directory checks
    for index in "${!betaValues[@]}"; do
        __static__AddToInverterJobscriptFile\
            "if [[ ! -d \${dir${index}} ]]; then"\
            "  echo \"Could not find directory \\\"\${dir${index}}\\\" for runs. Aborting...\"" \
            "  exit ${BHMAS_fatalFileNotFound}" \
            "fi" \
            ""
    done

    #Print some information
    __static__AddToInverterJobscriptFile\
        "# Print some information"\
        "echo \"$(printf "%s " ${betaValues[@]})\""\
        "echo \"\""\
        "echo \"Host: \$(hostname)\""\
        "echo \"GPU:  \${GPU_DEVICE_ORDINAL}\""\
        "echo \"Date and time: \$(date)\""\
        "echo \${SLURM_JOB_NODELIST} > ${BHMAS_measurementExecutableFilename}.${betasString:1}.\${SLURM_JOB_ID}.nodelist"\
        ""

    #Copying executable file(s) and if working on different disks also input file
    __static__AddToJobscriptFile\
        "# TODO: this is necessary because the log file is produced in the directoy"\
        "#       of the exec. Copying it later does not guarantee that it is still the same..."\
        "echo \"Copy executable to beta directories in ${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}x.xxxx...\""
    for index in "${!betaValues[@]}"; do
        __static__AddToInverterJobscriptFile "rm -f \${dir${index}}/${BHMAS_measurementExecutableFilename} && cp -a ${BHMAS_measurementExecutableGlobalPath} \${dir${index}} || exit ${BHMAS_fatalBuiltin}"
    done

    #Some more output information and run command(s)
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
    for index in "${!betaValues[@]}"; do
        #The following check is done twice. During the creation of the jobscript for the case in which the ${BHMAS_inversionSrunCommandsFilename} does not exist from the beginning on and
        #in the jobscript itself for the case in which it exists during the creation of the jobscript but accidentally gets deleted later on after the creation.
        if [[ ! -e ${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValues[${index}]}/${BHMAS_inversionSrunCommandsFilename} ]]; then
            Fatal ${BHMAS_fatalFileNotFound} "File " emph "${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValues[${index}]}/${BHMAS_inversionSrunCommandsFilename}"\
                  " with execution commands for the inversion was not found!"
        fi
        __static__AddToInverterJobscriptFile\
            "mkdir -p \${workdir${index}} || exit ${BHMAS_fatalBuiltin}"\
            "cd \${workdir${index}}"\
            "pwd"\
            "if [[ ! -e \${workdir${index}}/${BHMAS_inversionSrunCommandsFilename} ]]; then"\
            "  echo \"File \${workdir${index}}/${BHMAS_inversionSrunCommandsFilename} with execution commands for the inversion was not found! Aborting...\""\
            "  exit ${BHMAS_fatalFileNotFound}"\
            "fi"\
            "OLD_IFS=\${IFS}"\
            "IFS=\$'\n'"\
            "for line in \$(cat \${workdir${index}}/${BHMAS_inversionSrunCommandsFilename}); do"\
            "    IFS=\${OLD_IFS} #Restore here old IFS to give separated options (and not only one)to CL2QCD!"\
            "    if hash mbuffer 2>/dev/null; then"\
            "        time \${dir${index}}/${BHMAS_measurementExecutableFilename} \${line} --deviceId=${index} 2>> \${dir${index}}/\${errFile} | mbuffer -q -m2M >> \${dir${index}}/\${outFile}"\
            "    else"\
            "        time srun -n 1 \${dir${index}}/${BHMAS_measurementExecutableFilename} \${line} --deviceId=${index} 2>> \${dir${index}}/\${errFile} >> \${dir${index}}/\${outFile}"\
            "    fi"\
            "    if [[ \$? -ne 0 ]]; then"\
            "        printf \"\nError occurred in simulation at b${betaValues[${index}]%_*}.\n\""\
            "        CONFIGURATION_${index}=\$(grep -o \"${BHMAS_configurationPrefix}[[:digit:]]\{5\}\" <<< \"\${line}\")"\
            "        CORRELATOR_POSTFIX_${index}=\$(grep -o \"_[[:digit:]]\+_[[:digit:]]\+_[[:digit:]]\+_[[:digit:]]\+_corr\"  <<< \"\${line}\")"\
            "        echo \${CONFIGURATION_${index}}\${CORRELATOR_POSTFIX_${index}} >> \${dir${index}}/failed_inversions_tmp_file"\
            "    fi"\
            "done &"\
            "IFS=\${OLD_IFS}"\
            "PID_FOR_${index}=\${!}"\
            ""
    done

    #Waiting for job(s) and handling exit code
    for index in "${!betaValues[@]}"; do
        __static__AddToInverterJobscriptFile\
            "wait \${PID_FOR_${index}} || { printf \"\nError occurred in simulation at b${betaValues[${index}]%_*}. Please check (process id \${PID_FOR_${index}})...\n\"; }"
    done
    __static__AddToInverterJobscriptFile\
        ""\
        "# Unset pipefail since not needed anymore"\
        "set +o pipefail"\
        ""\
        "echo \"---------------------------\""\
        ""\
        "echo \"Date and time: \$(date)\""\
        "" ""

    #Remove executable(s) and check if calculation went fine
    __static__AddToInverterJobscriptFile "# Remove executable"
    for index in "${!betaValues[@]}"; do
        __static__AddToInverterJobscriptFile "rm \${dir${index}}/${BHMAS_measurementExecutableFilename} || exit ${BHMAS_fatalBuiltin}"
    done
    __static__AddToInverterJobscriptFile ""
    for index in "${!betaValues[@]}"; do
        __static__AddToInverterJobscriptFile\
            "if [[ -e \${dir${index}}/failed_inversions_tmp_file ]]; then"\
            "  ERROR_OCCURRED="TRUE""\
            "  echo \"Failed inversions at b${betaValues[${index}]%_*}:\" >> \${dir${index}}/\${errFile}"\
            "  cat \${dir${index}}/failed_inversions_tmp_file >> \${dir${index}}/\${errFile}"\
            "  rm \${dir${index}}/failed_inversions_tmp_file"\
            "fi"
    done
    __static__AddToInverterJobscriptFile\
        "if [[ \"\${ERROR_OCCURRED}\" = \"TRUE\" ]]; then"\
        "  printf \"\nTerminating job with non zero exit code... (\$(date))\n\""\
        "  exit ${BHMAS_fatalGeneric}"\
        "fi"
}


MakeFunctionsDefinedInThisFileReadonly
