#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

function ProduceInputFileAndJobScriptForEachBeta_SLURM()
{
    local betaValuesCopy index beta submitBetaDirectory temporaryNumberOfTrajectories
    betaValuesCopy=(${BHMAS_betaValues[@]})
    for index in "${!betaValuesCopy[@]}"; do
        local submitBetaDirectory="$BHMAS_submitDirWithBetaFolders/$BHMAS_betaPrefix${betaValuesCopy[$index]}"
        if [ -d "$submitBetaDirectory" ]; then
            if [ $(ls $submitBetaDirectory | wc -l) -gt 0 ]; then
                cecho lr "\n There are already files in " dir "$submitBetaDirectory" ".\n The value " emph "beta = ${betaValuesCopy[$index]}" " will be skipped!\n"
                BHMAS_problematicBetaValues+=( ${betaValuesCopy[$index]} )
                unset -v 'betaValuesCopy[$index]' #Here betaValuesCopy becomes sparse
                continue
            fi
        fi
    done
    if [ ${#betaValuesCopy[@]} -eq 0 ]; then
        return
    fi
    #Make betaValuesCopy not sparse
    betaValuesCopy=(${betaValuesCopy[@]})
    for beta in "${betaValuesCopy[@]}"; do
        submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${beta}"
        cecho -n b " Creating directory " dir "$submitBetaDirectory" "..."
        mkdir -p $submitBetaDirectory || exit -2
        cecho lg " done!"
        cecho lc "   Configuration used: " file "${BHMAS_startConfigurationGlobalPath[$beta]}"
        if KeyInArray "$beta" BHMAS_goalStatistics; then
            temporaryNumberOfTrajectories=${BHMAS_goalStatistics["$beta"]}
        else
            temporaryNumberOfTrajectories=$BHMAS_numberOfTrajectories
        fi
        ProduceInputFile_CL2QCD "${beta}" "${submitBetaDirectory}/${BHMAS_inputFilename}" $temporaryNumberOfTrajectories
    done
    mkdir -p ${BHMAS_submitDirWithBetaFolders}/$BHMAS_jobScriptFolderName || exit -2
    PackBetaValuesPerGpuAndCreateOrLookForJobScriptFiles "${betaValuesCopy[@]}"
}
