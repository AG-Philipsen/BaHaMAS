#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function GetJobScriptFilename()
{
    local stringWithBetaValues; stringWithBetaValues="$1"

    if [ $BHMAS_invertConfigurationsOption = "TRUE" ]; then
        printf "${BHMAS_jobScriptPrefix}_${BHMAS_parametersString}__${stringWithBetaValues}_INV"
    else
        if [ "$BHMAS_betaPostfix" == "_thermalizeFromConf" ]; then
            printf "${BHMAS_jobScriptPrefix}_${BHMAS_parametersString}__${stringWithBetaValues}_TC"
        elif [ "$BHMAS_betaPostfix" == "_thermalizeFromHot" ]; then
            printf "${BHMAS_jobScriptPrefix}_${BHMAS_parametersString}__${stringWithBetaValues}_TH"
        else
            printf "${BHMAS_jobScriptPrefix}_${BHMAS_parametersString}__${stringWithBetaValues}"
        fi
    fi
}

function __static__GetJobBetasStringUsing()
{
    local beta betaValuesToBeUsed betasStringToBeReturned
    betaValuesToBeUsed=( $@ ); betasStringToBeReturned=""
    declare -A seedsOfSameBeta=()
    for beta in "${betaValuesToBeUsed[@]}"; do
        seedsOfSameBeta[${beta%%_*}]+="_$(awk '{split($0, res, "_"); print res[2]}' <<< "$beta")"
    done
    #Here I iterate again on betaValuesToBeUsed and not on ${!seedsOfSameBeta[@]} in order to guarantee an order
    #in betasStringToBeReturned (remember that associative arrays keys are not sorted in general). Note that now
    #I have to use the same 'beta' only once and this is easily achieved unsetting the seedsOfSameBeta array
    #entry once used it
    for beta in "${betaValuesToBeUsed[@]}"; do
        beta=${beta%%_*}
        if KeyInArray $beta seedsOfSameBeta; then
            betasStringToBeReturned="${betasStringToBeReturned}__${BHMAS_betaPrefix}${beta}${seedsOfSameBeta[${beta}]}"
            unset 'seedsOfSameBeta[${beta}]'
        fi
    done
    if [ $BHMAS_useMultipleChains == "FALSE" ]; then
        betasStringToBeReturned="$(sed -e 's/___/_/g' -e 's/_$//' <<< "$betasStringToBeReturned")"
    fi
    printf "${betasStringToBeReturned:2}" #I cut here the two initial underscores
}

function PackBetaValuesPerGpuAndCreateOrLookForJobScriptFiles()
{
    local betaValuesToBeSplit betasForJobScript betasString jobScriptFilename jobScriptGlobalPath
    betaValuesToBeSplit=( $@ )
    cecho lc "\n================================================================================="
    cecho bb "  The following beta values have been grouped (together with the seed if used):"
    while [[ "${!betaValuesToBeSplit[@]}" != "" ]]; do
        betasForJobScript=(${betaValuesToBeSplit[@]:0:$BHMAS_GPUsPerNode})
        betaValuesToBeSplit=(${betaValuesToBeSplit[@]:$BHMAS_GPUsPerNode})
        cecho -n "   ->"
        for BETA in "${betasForJobScript[@]}"; do
            cecho -n "    ${BHMAS_betaPrefix}${BETA%_*}"
        done
        cecho ""
        betasString="$(__static__GetJobBetasStringUsing ${betasForJobScript[@]})"
        jobScriptFilename="$(GetJobScriptFilename ${betasString})"
        jobScriptGlobalPath="${BHMAS_submitDirWithBetaFolders}/$BHMAS_jobScriptFolderName/$jobScriptFilename"
        if [ $BHMAS_submitonlyOption = "FALSE" ]; then
            if [ -e $jobScriptGlobalPath ]; then
                mv $jobScriptGlobalPath ${jobScriptGlobalPath}_$(date +'%F_%H%M') || exit -2
            fi
            #Call the file to produce the jobscript file
            if [ $BHMAS_invertConfigurationsOption = "TRUE" ]; then
                ProduceInverterJobscript_CL2QCD
            else
                ProduceJobscript_CL2QCD "$jobScriptGlobalPath" "$jobScriptFilename" "${betasForJobScript[@]}"
            fi
            if [ -e $jobScriptGlobalPath ]; then
                BHMAS_betaValuesToBeSubmitted+=( "${betasString}" )
            else
                cecho lr "\n Jobscript " file "$jobScriptFilename" " failed to be created! Skipping this job submission!\n"
                BHMAS_problematicBetaValues+=( "${betasString}" )
                continue
            fi
        else
            if [ -e $jobScriptGlobalPath ]; then
                BHMAS_betaValuesToBeSubmitted+=( "${betasString}" )
            else
                cecho lr "\n Jobscript " file "$jobScriptFilename" " not found! Option " emph "--submitonly" " cannot be applied! Skipping this job submission!\n"
                BHMAS_problematicBetaValues+=( "${betasString}" )
                continue
            fi
        fi
    done
    cecho lc "================================================================================="
}
