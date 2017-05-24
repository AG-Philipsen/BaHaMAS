# Load auxiliary bash files that will be used.
source ${BaHaMAS_repositoryTopLevelPath}/AuxiliaryFunctions_SLURM.bash || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/ListJobsStatus_SLURM.bash     || exit -2
source ${BaHaMAS_repositoryTopLevelPath}/CleanOutputFiles.bash         || exit -2
#------------------------------------------------------------------------------------#

function __static__PrintOldLineToBetasFileAndShiftArrays()
{
    if [ $BHMAS_useMultipleChains == "TRUE" ]; then
        printf "${BETA_ARRAY[0]}\t${SEED_ARRAY[0]}\t${REST_OF_THE_LINE_ARRAY[0]}"  >> $BHMAS_betasFilename
        SEED_JUST_PRINTED_TO_FILE="${SEED_ARRAY[0]}"
        SEED_ARRAY=("${SEED_ARRAY[@]:1}")
    else
        printf "${BETA_ARRAY[0]}\t${REST_OF_THE_LINE_ARRAY[0]}" >> $BHMAS_betasFilename
    fi
    BETA_JUST_PRINTED_TO_FILE="${BETA_ARRAY[0]}"
    REST_OF_THE_LINE_JUST_PRINTED_TO_FILE="${REST_OF_THE_LINE_ARRAY[0]}"
    BETA_ARRAY=("${BETA_ARRAY[@]:1}")
    REST_OF_THE_LINE_ARRAY=("${REST_OF_THE_LINE_ARRAY[@]:1}")
}

function __static__PrintNewLineToBetasFile()
{
    printf "$BETA_JUST_PRINTED_TO_FILE\t$NEW_SEED\t$REST_OF_THE_LINE_JUST_PRINTED_TO_FILE" >> $BHMAS_betasFilename
}

#TODO: could one reuse some functionality of parsing of betas file here!?
function CompleteBetasFile()
{
    local OLD_IFS=$IFS      # save the field separator
    local IFS=$'\n'         # new field separator, the end of line
    local BETA=""
    local BETA_ARRAY=()
    local REST_OF_THE_LINE=""
    local REST_OF_THE_LINE_ARRAY=()
    local COMMENTED_LINE_ARRAY=()
    [ $BHMAS_useMultipleChains == "TRUE" ] && local SEED="" && local SEED_ARRAY=()
    for LINE in $(sort -k1n $BHMAS_betasFilename); do
        if [[ $LINE =~ ^[[:blank:]]*$ ]]; then
            continue
        fi
        if [[ $LINE =~ ^[[:blank:]]*# ]]; then
            COMMENTED_LINE_ARRAY+=( "$LINE" )
            continue
        fi
        LINE=$(awk '{split($0, res, "#"); print res[1]}' <<< "$LINE")
        BETA=$(awk '{print $1}' <<< "$LINE")
        REST_OF_THE_LINE=$(awk '{$1=""; print $0}' <<< "$LINE")
        if [ $BHMAS_useMultipleChains == "TRUE" ]; then
            SEED=$(awk '{print $1}' <<< "$REST_OF_THE_LINE")
            REST_OF_THE_LINE=$(awk '{$1=""; print $0}' <<< "$REST_OF_THE_LINE")
        else
            if [[ $(awk '{print $1}' <<< "$REST_OF_THE_LINE") =~ ^[[:digit:]]{4}$ ]]; then
                cecho ly B "\n " U "WARNING" uU ":" uB " It seems you put seeds in betas file but you invoked this script with the " emph "--doNotUseMultipleChains" " option."
                AskUser "Would you like to continue?"
                if UserSaidNo; then
                    return
                fi
            fi
        fi
        #Check each entry
        if [[ ! $BETA =~ ^[[:digit:]].[[:digit:]]{4}$ ]]; then
            cecho lr "\n Invalid beta entry in betas file! Aborting...\n"
            exit -1
        fi
        if [ $BHMAS_useMultipleChains == "TRUE" ]; then
            if [[ ! $SEED =~ ^[[:digit:]]{4}$ ]]; then
                cecho lr "\n Invalid seed entry in betas file! Aborting...\n"
                exit -1
            fi
        fi
        #Checks done, fill arrays
        BETA_ARRAY+=( $BETA )
        [ $BHMAS_useMultipleChains == "TRUE" ] && SEED_ARRAY+=( $SEED )
        REST_OF_THE_LINE_ARRAY+=( "$REST_OF_THE_LINE" )
    done
    IFS=$OLD_IFS     # restore default field separator

    #Produce complete betas file
    local betasFilenameBackup="${BHMAS_betasFilename}_backup"
    mv $BHMAS_betasFilename $betasFilenameBackup || exit -2
    while [ "${#BETA_ARRAY[@]}" -ne 0 ]; do
        local BETA_JUST_PRINTED_TO_FILE=""
        local SEED_JUST_PRINTED_TO_FILE=""
        local REST_OF_THE_LINE_JUST_PRINTED_TO_FILE=""
        local NUMBER_OF_BETA_PRINTED_TO_FILE=0
        #In case multiple chains are used, the betas with already a seed are copied to file
        if [ $BHMAS_useMultipleChains == "TRUE" ]; then
            __static__PrintOldLineToBetasFileAndShiftArrays
            (( NUMBER_OF_BETA_PRINTED_TO_FILE++ )) || true #'|| true' because of set -e option
            while [ "${BETA_ARRAY[0]:-}" = $BETA_JUST_PRINTED_TO_FILE ]; do #This while works because above we read the betasfile sorted!
                __static__PrintOldLineToBetasFileAndShiftArrays
                (( NUMBER_OF_BETA_PRINTED_TO_FILE++ )) || true #'|| true' because of set -e option
            done
        fi
        #Then complete file
        if [ $BHMAS_useMultipleChains == "TRUE" ]; then
            local SEED_TO_GENERATE_NEW_SEED_FROM="$SEED_JUST_PRINTED_TO_FILE"
        else
            local SEED_TO_GENERATE_NEW_SEED_FROM="${BETA_ARRAY[0]##*[.]}"
            #Unset arrays pretending to have written to file to uniform __static__PrintNewLineToBetasFile function
            BETA_JUST_PRINTED_TO_FILE="${BETA_ARRAY[0]}"
            REST_OF_THE_LINE_JUST_PRINTED_TO_FILE="${REST_OF_THE_LINE_ARRAY[0]}"
            BETA_ARRAY=("${BETA_ARRAY[@]:1}")
            REST_OF_THE_LINE_ARRAY=("${REST_OF_THE_LINE_ARRAY[@]:1}")
            #Print first line with starting seed
            NEW_SEED=$SEED_TO_GENERATE_NEW_SEED_FROM
            __static__PrintNewLineToBetasFile
            (( NUMBER_OF_BETA_PRINTED_TO_FILE++ )) || true #'|| true' because of set -e option
        fi
        for((INDEX=$NUMBER_OF_BETA_PRINTED_TO_FILE; INDEX<$BHMAS_numberOfChainsToBeInTheBetasFile; INDEX++)); do
            local NEW_SEED=$(sed -e 's/\(.\)/\n\1/g' <<< "$SEED_TO_GENERATE_NEW_SEED_FROM"  | awk 'BEGIN{ORS=""}NR>1{print ($1+1)%10}')
            __static__PrintNewLineToBetasFile
            SEED_TO_GENERATE_NEW_SEED_FROM=$NEW_SEED
        done
        cecho -d "" >> $BHMAS_betasFilename
    done
    #Print commented lines http://stackoverflow.com/a/34361807
    for LINE in ${COMMENTED_LINE_ARRAY[@]+"COMMENTED_LINE_ARRAY[@]"}; do
        cecho -d $LINE >> $BHMAS_betasFilename
    done
    rm $betasFilenameBackup

    cecho lm "\n New betasfile successfully created!"
}


function UncommentEntriesInBetasFile()
{
    #at first comment all lines
    sed -i "s/^\([^#].*\)/#\1/" $BHMAS_betasFilename

    local IFS=' '
    local OLD_IFS=$IFS
    for i in ${BHMAS_betasWithSeedToBeToggled[@]+"BHMAS_betasWithSeedToBeToggled[@]"}; do
        IFS='_'
        local U_ARRAY=( $i )
        local U_BETA=${U_ARRAY[0]}
        local U_SEED=${U_ARRAY[1]}
        local U_SEED=${U_SEED#s}
        sed -i "s/^#\(.*$U_BETA.*$U_SEED.*\)$/\1/" $BHMAS_betasFilename #If there is a "#" in front of the line, remove it
    done
    IFS=$OLD_IFS

    for i in ${BHMAS_betasToBeToggled[@]+"BHMAS_betasToBeToggled[@]"}; do
        U_BETA=$i
        sed -i "s/^#\(.*$U_BETA.*\)$/\1/" $BHMAS_betasFilename #If there is a "#" in front of the line, remove it
    done
}

function CommentEntriesInBetasFile()
{
    #at first uncomment all lines
    sed -i "s/^#\(.*\)/\1/" $BHMAS_betasFilename

    local IFS=' '
    local OLD_IFS=$IFS
    for i in ${BHMAS_betasWithSeedToBeToggled[@]+"BHMAS_betasWithSeedToBeToggled"}; do
        IFS='_'
        local U_ARRAY=( $i )
        local U_BETA=${U_ARRAY[0]}
        local U_SEED=${U_ARRAY[1]}
        local U_SEED=${U_SEED#s}
        sed -i "s/^\($U_BETA.*$U_SEED.*\)$/#\1/" $BHMAS_betasFilename #If there is no "#" in front of the line, put one
    done
    IFS=$OLD_IFS

    for i in ${BHMAS_betasToBeToggled[@]+"BHMAS_betasToBeToggled"}; do
        U_BETA=$i
        sed -i "s/^\($U_BETA.*\)$/#\1/" $BHMAS_betasFilename #If there is no "#" in front of the line, put one
    done
}


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
        exit -1
    fi
}

#------------------------------------------------------------------------------------------------------------------------------#

function __static__CheckExistenceOfFunctionAndCallIt()
{
    local nameOfTheFunction
    nameOfTheFunction=$1
    if [ "$(type -t $nameOfTheFunction)" = 'function' ]; then
        $nameOfTheFunction
    else
        cecho "\n" lr "Function " emph "$nameOfTheFunction" " for " emph "$BHMAS_clusterScheduler" " scheduler not found!"
        cecho "\n" lr "Please provide an implementation following the " B "BaHaMAS" uB " documentation and source the file. Aborting...\n"
        exit -1
    fi
}


function ProduceInputFileAndJobScriptForEachBeta()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}


function ProcessBetaValuesForSubmitOnly()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}


function ProcessBetaValuesForContinue()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}


function ProcessBetaValuesForInversion()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}


function SubmitJobsForValidBetaValues()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}


function ListJobStatus()
{
    __static__CheckExistenceOfFunctionAndCallIt   ${FUNCNAME}_$BHMAS_clusterScheduler
}
