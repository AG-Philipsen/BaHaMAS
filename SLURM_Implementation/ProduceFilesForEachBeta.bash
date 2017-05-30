#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function ProduceInputFileAndJobScriptForEachBeta_SLURM()
{
    #---------------------------------------------------------------------------------------------------------------------#
    #NOTE: Since this function has to iterate over the betas either doing something and putting the value into
    #      BHMAS_betaValuesToBeSubmitted or putting the beta value into BHMAS_problematicBetaValues, it is better to make a local copy
    #      of BHMAS_betaValues in order not to alter the original global array. Actually on the LOEWE the jobs are packed
    #      and this implies that whenever a problematic beta is encoutered it MUST be removed from the betavalues array
    #      (otherwise the authomatic packing would fail in the sense that it would include a problematic beta).
    local BETAVALUES_COPY=(${BHMAS_betaValues[@]})
    #---------------------------------------------------------------------------------------------------------------------#
    for INDEX in "${!BETAVALUES_COPY[@]}"; do
        local HOME_BETADIRECTORY="$BHMAS_submitDirWithBetaFolders/$BHMAS_betaPrefix${BETAVALUES_COPY[$INDEX]}"
        if [ -d "$HOME_BETADIRECTORY" ]; then
            if [ $(ls $HOME_BETADIRECTORY | wc -l) -gt 0 ]; then
                cecho lr "\n There are already files in " dir "$HOME_BETADIRECTORY" ".\n The value " emph "beta = ${BETAVALUES_COPY[$INDEX]}" " will be skipped!\n"
                BHMAS_problematicBetaValues+=( ${BETAVALUES_COPY[$INDEX]} )
                unset BETAVALUES_COPY[$INDEX] #Here BETAVALUES_COPY becomes sparse
                continue
            fi
        fi
    done
    #Make BETAVALUES_COPY not sparse
    BETAVALUES_COPY=(${BETAVALUES_COPY[@]})
    #If the previous for loop went through, we create the beta folders (just to avoid to create some folders and then abort)
    for INDEX in "${!BETAVALUES_COPY[@]}"; do
        local HOME_BETADIRECTORY="$BHMAS_submitDirWithBetaFolders/$BHMAS_betaPrefix${BETAVALUES_COPY[$INDEX]}"
        cecho -n lb " Creating directory " dir "$BHMAS_betaPrefix${BETAVALUES_COPY[$INDEX]}" "..."
        mkdir $HOME_BETADIRECTORY || exit -2
        cecho lg " done!"
        cecho lc "   Configuration used: " file "${BHMAS_startConfigurationGlobalPath[${BETAVALUES_COPY[$INDEX]}]}"
        #Call the file to produce the input file
        local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$BHMAS_inputFilename"
        ProduceInputFile_SLURM
    done
    # Partition the BETAVALUES_COPY array into group of BHMAS_GPUsPerNode and create the JobScript files inside the JOBSCRIPT_FOLDER
    mkdir -p ${BHMAS_submitDirWithBetaFolders}/$BHMAS_jobScriptFolderName || exit -2
    PackBetaValuesPerGpuAndCreateJobScriptFiles "${BETAVALUES_COPY[@]}"
}
