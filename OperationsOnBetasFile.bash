#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

#REMARK: Here the parsing of the betas file is implemented. All the prefixes
#        are at the moment hard coded and not extracted into variables.
#        Moreover, for the seed prefix, an hard-coded 's' is used and not
#        the 'BHMAS_seedPrefix'. This is due to the fact that a longer value
#        for the 'BHMAS_seedPrefix' would oblige the user to use this longer
#        value in all her/his betas files.

function __static__CheckExistenceBetasFileAndAddEndOfLineAtTheEndIfMissing()
{
    if [ ! -e $BHMAS_betasFilename ]; then
        cecho lr "\n  File " emph "$BHMAS_betasFilename" " not found in $(pwd). Aborting...\n"
        exit -1
    else
        #Add a end of line at end of file if missing
        sed -i '$a\' "$BHMAS_betasFilename"
    fi
}

function __static__CheckFormatBetasFileEntry()
{
    local beta integrationStepsRegex massPreconditioningRegex resumeRegex statisticsRegex timesRegex
    #Grep regexes, we eliminate backslashes easily with variable expansion
    integrationStepsRegex='[0-9]\+\(-[0-9]\+\)*'
    massPreconditioningRegex='[0-9]\+,[0-9]\+'
    resumeRegex='\([0-9]\+\|last\)'
    statisticsRegex='[0-9]\+'
    timesRegex='[0-9]\+\([.][0-9]*\)\?'
    case "$1" in
        integrationSteps )
            if [[ ! $2 =~ ^${integrationStepsRegex//\\/}$ ]]; then
                cecho lr "\n Integration steps entry " emph "$2" " in " file "$BHMAS_betasFilename" " file does not match expected format! Aborting...\n"
                exit -1
            fi ;;
        massPreconditioning )
            if [[ ! $2 =~ ^${massPreconditioningRegex//\\/}$ ]]; then
                cecho lr "\n Mass preconditioning entry " emph "$2" " in " file "$BHMAS_betasFilename" " file does not match expected format! Aborting...\n"
                exit -1
            fi ;;
        resumeFrom )
            if [[ ! $2 =~ ^${resumeRegex//\\/}$ ]]; then
                cecho lr "\n Resume from trajectory entry " emph "$2" " in " file "$BHMAS_betasFilename" " file does not match expected format! Aborting...\n"
                exit -1
            fi ;;
        statistics )
            if [[ ! $2 =~ ^${statisticsRegex//\\/}$ ]]; then
                cecho lr "\n Goal statistics entry " emph "$2" " in " file "$BHMAS_betasFilename" " file does not match expected format! Aborting...\n"
                exit -1
            fi ;;
        trajectoryTime )
            if [[ ! $2 =~ ^${timesRegex//\\/}$ ]]; then
                cecho lr "\n Trajectory time entry " emph "$2" " in " file "$BHMAS_betasFilename" " file does not match expected format! Aborting...\n"
                exit -1
            fi ;;
        * )
            cecho lr "\n Function " emph "$FUNCNAME" " wrongly called! Aborting...\n"; exit -1 ;;
    esac
}

function __static__CheckAndParseSingleLine()
{
    local entry beta tmpSeed entriesToBeParsed
    if [[ ! $1 =~ ^${BHMAS_betaRegex//\\/}$ ]]; then
        cecho lr "\n No " emph "beta value" " found at beginning of line in " file "$BHMAS_betasFilename" " file! Aborting...\n"
        exit -1
    else
        beta="$1"
    fi
    tmpSeed=''
    for entry in "${@:2}"; do
        if [[ $entry =~ ^s${BHMAS_seedRegex//\\/}$ ]]; then
            tmpSeed=${entry:1}
        else
            entriesToBeParsed+=( "$entry" )
        fi
    done
    if [ $BHMAS_useMultipleChains == "TRUE" ]; then
        if [ "$tmpSeed" = '' ]; then
            cecho lr "\n Seed missing in " file "$BHMAS_betasFilename" " file for " emph "beta = $beta" " Aborting...\n"
            exit -1
        fi
        beta+="_${BHMAS_seedPrefix}${tmpSeed}${BHMAS_betaPostfix}"
    fi
    set -- "${entriesToBeParsed[@]}"
    #Put information in global variables
    BHMAS_betaValues+=( "$beta" )
    while [ $# -ne 0 ]; do
        case "$1" in
            i* )
                entry=${1:1}
                __static__CheckFormatBetasFileEntry integrationSteps "$entry"
                if [ $(grep -o "-" <<< "$entry" | wc -l) -ne 1 ]; then
                    cecho lr "\n Unable to use a different number of integration steps different than " emph "2" " for " emph "beta = ${beta%_*}" "! Aborting...\n"
                    exit -1
                fi
                BHMAS_scaleZeroIntegrationSteps["$beta"]=${entry%%-*}
                BHMAS_scaleOneIntegrationSteps["$beta"]=${entry##*-}
                #If generalized in future, something like  BHMAS_integrationSteps["$beta"]=${entry//-/}
                ;;
            mp* )
                entry=${1:2}
                __static__CheckFormatBetasFileEntry massPreconditioning "$entry"
                BHMAS_massPreconditioningValues["$beta"]=$entry ;;
            r* )
                entry=${1:1}
                __static__CheckFormatBetasFileEntry resumeFrom "$entry"
                BHMAS_trajectoriesToBeResumedFrom["$beta"]=$entry ;;
            g* )
                entry=${1:1}
                __static__CheckFormatBetasFileEntry statistics "$entry"
                BHMAS_goalStatistics["$beta"]=$entry ;;
            t* )
                entry=${1:1}
                __static__CheckFormatBetasFileEntry trajectoryTime "$entry"
                BHMAS_timesPerTrajectory["$beta"]=$entry ;;
            * )
                cecho lr "\n Invalid prefix found in " file "$BHMAS_betasFilename" " file for entry " emph "$1" "! Aborting...\n"
                exit -1 ;;
        esac
        shift
    done
}

function __static__CheckConsistencyInformationExtractedFromBetasFile()
{
    #Check for missing entries which need to be there
    if [ ${#BHMAS_betaValues[@]} -eq 0 ]; then
        cecho lr "\n  No beta values in betas file. Aborting...\n"
        exit -1
    fi
    for beta in "${BHMAS_betaValues[@]}"; do
        if ! KeyInArray "$beta" BHMAS_scaleZeroIntegrationSteps || ! KeyInArray "$beta" BHMAS_scaleOneIntegrationSteps; then
            cecho lr "\n Integration steps information missing in " file "$BHMAS_betasFilename" " file for " emph "beta = ${beta%_*}" "! Aborting...\n"
            exit -1
        fi
    done
    if [ $BHMAS_useMultipleChains = 'TRUE' ]; then
        #Check whether same seed is provided multiple times for same beta
        if [ $(printf "%s\n" "${BHMAS_betaValues[@]%_*}" | sort -n | uniq -d | wc -l) -ne 0 ]; then
            cecho lr "\n The " B "same" uB " seed was provided multiple times for the same beta in the " file "$BHMAS_betasFilename" " file! Aborting...\n"
            exit -1
        fi
    else
        #Check whether same beta is provided multiple times
        if [ $(printf "%s\n" "${BHMAS_betaValues[@]}" | sort -n | uniq -d | wc -l) -ne 0 ]; then
            cecho lr "\n The " B "same" uB " beta was provided multiple times in the " file "$BHMAS_betasFilename" " file! Aborting...\n"
            exit -1
        fi
    fi
}

function __static__FillMissingTimesPerTrajectoryIfAnyIsSpecified()
{
    if [ ${#BHMAS_timesPerTrajectory[@]} -eq 0 ]; then
        return
    fi
    #If an entry in the BHMAS_timesPerTrajectory is missing, put in the time referring to the closest beta
    # NOTE: If different times for same beta are provided, the highest is used.
    #
    # TODO: Think whether leaving here the array BHMAS_timesPerTrajectory only partially filled and
    #       look later in the job creation step for times at different betas. It could be useful
    #       to avoid to attribute an unnecessary high walltime to a simulation that could use a
    #       smaller walltime. For the moment we want to simplify the calculation of the walltime
    #       preparing here the array BHMAS_timesPerTrajectory such that there is a time per each beta/seed.
    local beta betaToBeUsed
    declare -A availableTimes=() #store times to use ONLY given times to complete BHMAS_timesPerTrajectory array
    for beta in "${!BHMAS_timesPerTrajectory[@]}"; do
        if ! KeyInArray ${beta%%_*} availableTimes; then
            availableTimes[${beta%%_*}]=${BHMAS_timesPerTrajectory[$beta]}
        else
            availableTimes[${beta%%_*}]=$(awk '{if($1>$2){print $1}else{print $1}}' <<<  "${BHMAS_timesPerTrajectory[$beta]} ${availableTimes[${beta%%_*}]}")
        fi
    done

    for beta in "${BHMAS_betaValues[@]}"; do
        if ! KeyInArray $beta BHMAS_timesPerTrajectory; then
            betaToBeUsed="$(FindValueOfClosestElementInArrayToGivenValue ${beta%%_*} ${!availableTimes[@]})"
            BHMAS_timesPerTrajectory[$beta]=${availableTimes[$betaToBeUsed]}
        fi
    done
}

function __static__PrintReportOnExtractedInformationFromBetasFile()
{
    cecho lc "\n============================================================================================================"
    cecho lp " Read beta values:"
    for BETA in ${BHMAS_betaValues[@]}; do
        cecho -n "   - $BETA [Integrator steps $(printf "%2d-%2d"  "${BHMAS_scaleZeroIntegrationSteps[$BETA]}" "${BHMAS_scaleOneIntegrationSteps[$BETA]}") ]"
        if KeyInArray $BETA BHMAS_trajectoriesToBeResumedFrom; then
            cecho -n "$(printf "   [resume from tr. %+7s]" "${BHMAS_trajectoriesToBeResumedFrom[$BETA]}")"
        else
            cecho -n "                          "
        fi
        if KeyInArray $BETA BHMAS_massPreconditioningValues; then
            cecho -n "$(printf "   MP=(%d-0.%4d)" "${BHMAS_massPreconditioningValues[$BETA]%,*}" "${BHMAS_massPreconditioningValues[$BETA]#*,}")"
        fi
        cecho ''
    done
    cecho lc "============================================================================================================"
}

function ParseBetasFile()
{
    __static__CheckExistenceBetasFileAndAddEndOfLineAtTheEndIfMissing

    local line
    while read line; do
        if [[ $line =~ ^[[:blank:]]*# ]] || [[ $line =~ ^[[:blank:]]*$ ]]; then
            continue #Skip commented or empty lines
        fi
        line="${line%%#*}" #Skip in line comments
        __static__CheckAndParseSingleLine $line
    done < <(cat "$BHMAS_betasFilename")

    __static__CheckConsistencyInformationExtractedFromBetasFile
    __static__FillMissingTimesPerTrajectoryIfAnyIsSpecified
    __static__PrintReportOnExtractedInformationFromBetasFile
}

#In the function below we complete the betas file adding new chains until the desired number
#is reached. The adopted strategy is the following:
#
#  1) check and parse the betas file (using __static__CheckAndParseSingleLine)
#     counting how many times each beta occurs
#  2) go through the file again sorting it, adding new lines (the last line
#     in which a beta occurs is duplicated as many times as needed) and replacing
#     the seed with the new one.
#
#NOTE: Parsing twice the file increase simplicity of the code and it is hardly a performance problem.
function __static__GetNonZeroFourDigitsRandomNumberDifferentFrom()
{
    local fourDigitsNumber; fourDigitsNumber='0000'
    RANDOM=$(date +%N)  #RANDOM seed from date
    until [ $(grep -o "$fourDigitsNumber" <<< "0000 $@" | wc -l) -eq 0 ]; do
        fourDigitsNumber=$(( (RANDOM+1000)%10000 )) # $RANDOM is in [0,32767]
    done
    printf "%04d" $fourDigitsNumber
}

function CompleteBetasFile()
{
    if [ $BHMAS_useMultipleChains = 'FALSE' ]; then
        cecho lr "\n Option " emph "--doNotUseMultipleChains" " not compatible with " emph "--completeBetasFile" " one. Aborting...\n"
        exit -1
    fi
    __static__CheckExistenceBetasFileAndAddEndOfLineAtTheEndIfMissing
    local line tmpFilename inlineComment beta seed
    declare -A betaOccurences betaCounter alreadyUsedSeeds
    while read line; do
        if [[ $line =~ ^[[:blank:]]*# ]] || [[ $line =~ ^[[:blank:]]*$ ]]; then
            continue #Skip commented or empty lines
        fi
        line="${line%%#*}" #Skip in line comments
        __static__CheckAndParseSingleLine $line
        if ! KeyInArray ${BHMAS_betaValues[-1]%%_*} betaOccurences; then
            betaOccurences[${BHMAS_betaValues[-1]%%_*}]=0
        fi
        (( betaOccurences[${BHMAS_betaValues[-1]%%_*}]++ )) || true   #'|| true' because of set -e option
    done < <(cat "$BHMAS_betasFilename")
    #Now it is fine to assume that beta is in the first position of the betas file
    #and that the seed is present on each line, since the multiple chains are used
    tmpFilename="${BHMAS_betasFilename}_$(date +%H%M%S-%3N)"
    cp "$BHMAS_betasFilename" "$tmpFilename" || exit -2; rm "$BHMAS_betasFilename" || exit -2
    while read line; do
        if [[ $line =~ ^[[:blank:]]*# ]] || [[ $line =~ ^[[:blank:]]*$ ]]; then
            cecho -d "$line" >> $BHMAS_betasFilename
            continue #Put commented or empty lines as such into file
        fi
        beta=$(awk '{print $1}' <<< "$line")
        seed=$(grep -o "s${BHMAS_seedRegex}" <<< "$line" | tail -n1)
        if ! KeyInArray $beta betaCounter; then
            betaCounter[$beta]=0
            alreadyUsedSeeds[$beta]=''
        fi
        (( betaCounter[$beta]++ )) || true  #'|| true' because of set -e option
        alreadyUsedSeeds[$beta]+="$seed "
        cecho -d "$line" >> $BHMAS_betasFilename
        if [ ${betaCounter[$beta]} -eq ${betaOccurences[$beta]} ]; then
            while [ ${betaCounter[$beta]} -lt $BHMAS_numberOfChainsToBeInTheBetasFile ]; do
                seed='s'$(__static__GetNonZeroFourDigitsRandomNumberDifferentFrom ${alreadyUsedSeeds[$beta]} )
                #Replace last occurence of seed in 'line' using new one
                #NOTE: since if user had more seeds on the same line, only the last
                #      would be used in BaHaMAS, here we consistently behave with this
                #      rule and we replace only the last seed given (sed is very greedy)
                line=$(sed 's/\(.*\)'s${BHMAS_seedRegex}'/\1'$seed'/g' <<< "$line")
                #Print new line to file
                cecho -d "$line" >> $BHMAS_betasFilename
                (( betaCounter[$beta]++ )) || true  #'|| true' because of set -e option
            done
        fi
    done < <(cat "$tmpFilename")
}
