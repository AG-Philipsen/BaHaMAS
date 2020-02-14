
function PrintReportForProblematicBeta()
{
    if [ ${#BHMAS_problematicBetaValues[@]} -gt "0" ]; then
        cecho lr "\n===================================================================================\n"\
              " For the following beta values something went wrong and hence\n"\
              " they were left out during file creation and/or job submission:"
        for BETA in ${BHMAS_problematicBetaValues[@]}; do
            cecho lr "  - " B "$BETA"
        done
        cecho lr "===================================================================================\n"
        exit $BHMAS_fatalGeneric
    fi
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         PrintReportForProblematicBeta
