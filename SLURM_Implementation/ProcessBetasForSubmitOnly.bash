#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function ProcessBetaValuesForSubmitOnly_SLURM()
{
    #-----------------------------------------#
    local BETAVALUES_COPY=(${BHMAS_betaValues[@]})
    #-----------------------------------------#
    for BETA in "${!BETAVALUES_COPY[@]}"; do
        local HOME_BETADIRECTORY="$BHMAS_submitDirWithBetaFolders/$BHMAS_betaPrefix${BETAVALUES_COPY[$BETA]}"
        local INPUTFILE_GLOBALPATH="${HOME_BETADIRECTORY}/$BHMAS_inputFilename"
        if [ ! -d $HOME_BETADIRECTORY ]; then
            cecho lr "\n The directory " dir "$HOME_BETADIRECTORY" " does not exist! \n The value " emph "beta = ${BETAVALUES_COPY[$BETA]}" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( ${BETAVALUES_COPY[$BETA]} )
            unset BETAVALUES_COPY[$BETA] #Here BETAVALUES_COPY becomes sparse
            continue
        else
            #$HOME_BETADIRECTORY already exists. Check if there are files in $HOME_BETADIRECTORY.
            if [ -f "$INPUTFILE_GLOBALPATH" ]; then
                # In the home betadirectory there should be ONLY the inputfile
                if [ $(ls $HOME_BETADIRECTORY | wc -l) -ne 1 ]; then
                    cecho lr "\n There are already files in " dir "$HOME_BETADIRECTORY" " beyond the input file.\n"\
                          " The value " emph "beta = ${BETAVALUES_COPY[$BETA]}" " will be skipped!\n"
                    BHMAS_problematicBetaValues+=( ${BETAVALUES_COPY[$BETA]} )
                    unset BETAVALUES_COPY[$BETA] #Here BETAVALUES_COPY becomes sparse
                    continue
                fi
            else
                cecho lr "\n The file " file "$INPUTFILE_GLOBALPATH" " does not exist!\n The value " emph "beta = ${BETAVALUES_COPY[$BETA]}" " will be skipped!\n"
                BHMAS_problematicBetaValues+=( ${BETAVALUES_COPY[$BETA]} )
                unset BETAVALUES_COPY[$BETA] #Here BETAVALUES_COPY becomes sparse
                continue
            fi
        fi
    done
    PackBetaValuesPerGpuAndCreateJobScriptFiles "${BETAVALUES_COPY[@]}"
}
