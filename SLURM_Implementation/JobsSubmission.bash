#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function SubmitJobsForValidBetaValues_SLURM()
{
    if [ ${#BHMAS_betaValuesToBeSubmitted[@]} -gt "0" ]; then
        cecho lc "\n==================================================================================="
        cecho bb " Jobs will be submitted for the following beta values:"
        for BETA in ${BHMAS_betaValuesToBeSubmitted[@]}; do
            cecho "  - $BETA"
        done

        for BETA in ${BHMAS_betaValuesToBeSubmitted[@]}; do
            if [ $BHMAS_useMultipleChains == "FALSE" ]; then
                local PREFIX_TO_BE_GREPPED_FOR="$BHMAS_betaPrefix"
            else
                local PREFIX_TO_BE_GREPPED_FOR="$BHMAS_seedPrefix"
            fi
            local TEMP_ARRAY=( $(sed 's/_/ /g' <<< "$BETA") )
            if [ $(grep -o "${PREFIX_TO_BE_GREPPED_FOR}\([[:digit:]][.]\)\?[[:alnum:]]\{4\}" <<< "$BETA" | wc -l) -ne $BHMAS_GPUsPerNode ]; then
                cecho -n ly B "\n " U "WARNING" uU ":" uB " At least one job is being submitted with less than " emph "$BHMAS_GPUsPerNode" " runs inside."
                AskUser "         Would you like to submit in any case?"
                if UserSaidNo; then
                    cecho lr B "\n No jobs will be submitted."
                    return
                fi
            fi
        done

        for BETA in ${BHMAS_betaValuesToBeSubmitted[@]}; do
            local SUBMITTING_DIRECTORY="${BHMAS_submitDirWithBetaFolders}/$BHMAS_jobScriptFolderName"
            local JOBSCRIPT_NAME="$(GetJobScriptName ${BETA})"
            cd $SUBMITTING_DIRECTORY
            cecho bb "\n Actual location: " dir "$(pwd)"\
                  B "\n      Submitting: " uB emph "sbatch $JOBSCRIPT_NAME"
            sbatch $JOBSCRIPT_NAME
        done
        cecho lc "\n==================================================================================="
    else
        cecho lr B " No jobs will be submitted."
    fi
}
