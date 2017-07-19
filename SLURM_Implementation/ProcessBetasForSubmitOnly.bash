#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

function ProcessBetaValuesForSubmitOnly_SLURM()
{
    local betaValuesCopy index submitBetaDirectory inputFileGlobalPath
    #-----------------------------------------#
    betaValuesCopy=(${BHMAS_betaValues[@]})
    for index in "${!betaValuesCopy[@]}"; do
        submitBetaDirectory="$BHMAS_submitDirWithBetaFolders/$BHMAS_betaPrefix${betaValuesCopy[$index]}"
        inputFileGlobalPath="${submitBetaDirectory}/$BHMAS_inputFilename"
        if [ ! -d $submitBetaDirectory ]; then
            cecho lr "\n The directory " dir "$submitBetaDirectory" " does not exist! \n The value " emph "beta = ${betaValuesCopy[$index]}" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( ${betaValuesCopy[$index]} )
            unset -v 'betaValuesCopy[$index]'
            continue
        else
            if [ -f "$inputFileGlobalPath" ]; then
                # In the 'submitBetaDirectory' there should be ONLY the inputfile
                if [ $(ls $submitBetaDirectory | wc -l) -gt 1 ]; then
                    cecho lr "\n There are already files in " dir "$submitBetaDirectory" " beyond the input file.\n"\
                          " The value " emph "beta = ${betaValuesCopy[$index]}" " will be skipped!\n"
                    BHMAS_problematicBetaValues+=( ${betaValuesCopy[$index]} )
                    unset -v 'betaValuesCopy[$index]'
                    continue
                fi
            else
                cecho lr "\n The file " file "$inputFileGlobalPath" " does not exist!\n The value " emph "beta = ${betaValuesCopy[$index]}" " will be skipped!\n"
                BHMAS_problematicBetaValues+=( ${betaValuesCopy[$index]} )
                unset -v 'betaValuesCopy[$index]'
                continue
            fi
        fi
    done
    if [ ${#betaValuesCopy[@]} -gt 0 ]; then
        PackBetaValuesPerGpuAndCreateOrLookForJobScriptFiles "${betaValuesCopy[@]}"
    fi
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         ProcessBetaValuesForSubmitOnly_SLURM
