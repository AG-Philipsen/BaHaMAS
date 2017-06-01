#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function SubmitJobsForValidBetaValues_SLURM()
{
    if [ ${#BHMAS_betaValuesToBeSubmitted[@]} -gt 0 ]; then
        local betaString stringToBeGreppedFor submittingDirectory jobScriptFilename
        cecho lc "\n==================================================================================="
        cecho bb " Jobs will be submitted for the following beta values:"
        for betaString in ${BHMAS_betaValuesToBeSubmitted[@]}; do
            cecho "  - $betaString"
        done
        for betaString in ${BHMAS_betaValuesToBeSubmitted[@]}; do
            if [ $BHMAS_useMultipleChains == "FALSE" ]; then
                stringToBeGreppedFor="${BHMAS_betaPrefix}${BHMAS_betaRegex}"
            else
                stringToBeGreppedFor="${BHMAS_seedPrefix}${BHMAS_seedRegex}"
            fi
            if [ $(grep -o "${stringToBeGreppedFor}" <<< "$betaString" | wc -l) -ne $BHMAS_GPUsPerNode ]; then
                cecho -n ly B "\n " U "WARNING" uU ":" uB " At least one job is being submitted with less than " emph "$BHMAS_GPUsPerNode" " runs inside."
                AskUser "         Would you like to submit in any case?"
                if UserSaidNo; then
                    cecho lr B "\n No jobs will be submitted."
                    return
                fi
            fi
        done
        for betaString in ${BHMAS_betaValuesToBeSubmitted[@]}; do
            submittingDirectory="${BHMAS_submitDirWithBetaFolders}/$BHMAS_jobScriptFolderName"
            jobScriptFilename="$(GetJobScriptFilename ${betaString})"
            cd $submittingDirectory
            cecho bb "\n Actual location: " dir "$(pwd)"\
                  B "\n      Submitting: " uB emph "sbatch $jobScriptFilename"
            sbatch $jobScriptFilename
        done
        cecho lc "==================================================================================="
    else
        cecho lr B "\n No jobs will be submitted.\n"
    fi
}
