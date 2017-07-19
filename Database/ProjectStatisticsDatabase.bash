#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

#TODO:
#*If a filtering option is specified wrongly, should the program exit or not? If not, should the error message rather be printed in the end?
#*Is it necessary to implement the functionality where the script uses find the update the database?
#*Coloured output?
#*Other options?
#*User specific variables?
#*Putting the command line parser into another file in order to remove the cluttering - right now the parser makes up ~50% of the script.
#*Everytime the database is updated, actually create a new file with the date and time in the name? This way it possible to track how the statistics
# grow over longer periods.

function join()
{
    local IFS="$1"; shift
    printf "$*" # "$*" expands to a single argument with all the elements delimited by the first character of $IFS
}

function projectStatisticsDatabase()
{
    local FILENAME_GIVEN_AS_INPUT=""
    local CURRENT_DIRECTORY=$(pwd)

    local NF_C=$((2*1))
    local MU_C=$((2*2))
    local K_C=$((2*3))
    local NT_C=$((2*4))
    local NS_C=$((2*5))
    local BETA_C=$((2*6))
    local TRAJNO_C=$((2*7))
    local ACCRATE_C=$((2*8))
    local ACCRATE_LAST1K_C=$((2*9))
    local MAX_ACTION_C=$((2*10))
    local STATUS_C=$((2*11))
    local LASTTRAJ_C=$((2*12))

    declare -A COLUMNS=( [nfC]=$NF_C [muC]=$MU_C [kC]=$K_C [ntC]=$NT_C [nsC]=$NS_C [betaC]=$BETA_C [trajNoC]=$TRAJNO_C [accRateC]=$ACCRATE_C [accRateLast1KC]=$ACCRATE_LAST1K_C \
                              [maxDsC]=$MAX_ACTION_C [statusC]=$STATUS_C [lastTrajC]=$LASTTRAJ_C )

    #FSNA = FORMAT_SPECIFIER_NUMBER_ARRAY
    declare -A FSNA=( [nfC]="6" [muC]="7" [kC]="8" [ntC]="6" [nsC]="6" [betaC]="19" [trajNoC]="11" [accRateC]="8" [accRateLast1KC]="12" [maxDsC]="12" [statusC]="13" [lastTrajC]="11" )

    declare -A PRINTF_FORMAT_SPECIFIER_ARRAY=( [nfC]="%+${FSNA[nfC]}s" [muC]="%+${FSNA[muC]}s" [kC]="%+${FSNA[kC]}s" [ntC]="%${FSNA[ntC]}d" [nsC]="%${FSNA[nsC]}d" [betaC]="%+${FSNA[betaC]}s" \
                                                    [trajNoC]="%${FSNA[trajNoC]}d" [accRateC]="%+${FSNA[accRateC]}s" [accRateLast1KC]="%+${FSNA[accRateLast1KC]}s" [maxDsC]="%+${FSNA[maxDsC]}s" \
                                                    [statusC]="%+${FSNA[statusC]}s" [lastTrajC]="%+${FSNA[lastTrajC]}s" )

    declare -A HEADER_PRINTF_FORMAT_SPECIFIER_ARRAY=( [nfC]="%+$((${FSNA[nfC]}+1))s" [muC]="%+$((${FSNA[muC]}+1))s" [kC]="%+$((${FSNA[kC]}+1))s" [ntC]="%+$((${FSNA[ntC]}+1))s" [nsC]="%+$((${FSNA[nsC]}+1))s" [betaC]="%+$((${FSNA[betaC]}+1))s" \
                                                           [trajNoC]="%+$((${FSNA[trajNoC]}+1))s" [accRateC]="%+$((${FSNA[accRateC]}+1))s" [accRateLast1KC]="%+$((${FSNA[accRateLast1KC]}+1))s" [maxDsC]="%+$((${FSNA[maxDsC]}+1))s" [statusC]="%+$((${FSNA[statusC]}+1))s" [lastTrajC]="%+$((${FSNA[lastTrajC]}+1))s" )

    [ $BHMAS_wilson = "TRUE" ] && MASS_PARAMETER="kappa"
    [ $BHMAS_staggered = "TRUE" ] && MASS_PARAMETER="mass"

    declare -A HEADER_PRINTF_PARAMETER_ARRAY=( [nfC]="nf" [muC]=$BHMAS_chempotPrefix [kC]=$MASS_PARAMETER [ntC]=$BHMAS_ntimePrefix [nsC]=$BHMAS_nspacePrefix [betaC]="beta_chain_type" [trajNoC]="trajNo" \
                                                    [accRateC]="acc" [accRateLast1KC]="accLast1K" [maxDsC]="maxDS" [statusC]="status" [lastTrajC]="l.T.[s]" )

    declare -a NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER=()

    local NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL=""
    local NAME_OF_COLUMN_NR_OF_COLUMN_STRING=""
    local NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING=""
    local NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING=""
    local NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING=""
    local LENGTH_OF_HEADER_SEPERATOR=""
    local STATISTICS_PRINTF_FORMAT_SPECIFIER_STRING=""
    local NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN=""

    local CUSTOMIZE_COLUMNS="FALSE"

    local STATISTICS_SUMMARY="FALSE"

    local UPDATE="FALSE"
    local DISPLAY="FALSE"
    local REPORT="FALSE"
    local SHOW="FALSE"

    local READ_DIRECTORIES_FROM_FILE="FALSE"
    local FILTER_SPECIFIC_DATABASE_FILE="FALSE"

    local FILTER_NF="FALSE"
    local FILTER_MU="FALSE"
    local FILTER_MASS="FALSE"
    local FILTER_NT="FALSE"
    local FILTER_NS="FALSE"
    local FILTER_BETA="FALSE"
    local FILTER_TYPE="FALSE"
    local FILTER_TRAJNO="FALSE"
    local FILTER_ACCRATE="FALSE"
    local FILTER_ACCRATE_LAST1K="FALSE"
    local FILTER_MAX_ACTION="FALSE"
    local FILTER_STATUS="FALSE"
    local FILTER_LASTTRAJ="FALSE"

    local UPDATE_WITH_FREQUENCY="FALSE"

    declare -a NF_ARRAY=()
    declare -a MU_ARRAY=()
    declare -a MASS_ARRAY=()
    declare -a NS_ARRAY=()
    declare -a NT_ARRAY=()
    declare -a BETA_ARRAY=()
    declare -a TYPE_ARRAY=()
    declare -a STATUS_ARRAY=()

    local TRAJ_LOW_VALUE=""
    local TRAJ_HIGH_VALUE=""

    local ACCRATE_LOW_VALUE=""
    local ACCRATE_HIGH_VALUE=""

    local ACCRATE_LAST1K_LOW_VALUE=""
    local ACCRATE_LAST1K_HIGH_VALUE=""

    local LAST_TRAJ_TIME=""

    local SLEEP_TIME=""
    local UPDATE_TIME=""

    #Parse command line options
    ParseDatabaseCommandLineOption "$@"

    cecho ''
    # The PROJECT_DATABASE_FILE variable refers to a file which is an input in the filtering/displaying scenario and which is an output in the update scenario.
    # Then it has to be initialized accordingly!
    if [ "$UPDATE" = "FALSE" ]; then
        if [ "$FILENAME_GIVEN_AS_INPUT" = "" ]; then
            LATEST_DATABASE_FILE=$(ls $BHMAS_databaseGlobalPath | grep -E [0-9]{2}_[0-9]{2}_[0-9]{2}_$BHMAS_databaseFilename | sort -t "_" -k 1,1 -k 2,2 -k 3,3 | tail -n1)
            if [ "$LATEST_DATABASE_FILE" = "" ]; then
                Fatal $BHMAS_fatalFileNotFound "No older database versions found!"
            fi
            local PROJECT_DATABASE_FILE=$BHMAS_databaseGlobalPath/$LATEST_DATABASE_FILE
        else
            if [ ! f $FILENAME_GIVEN_AS_INPUT ]; then
                Fatal $BHMAS_fatalFileNotFound "File " file "$FILENAME_GIVEN_AS_INPUT" " does not exist!"
            fi
            local PROJECT_DATABASE_FILE=$FILENAME_GIVEN_AS_INPUT
        fi
    else
        if [ "$FILENAME_GIVEN_AS_INPUT" != "" ] ; then
            if [ ! -f $FILENAME_GIVEN_AS_INPUT ]; then
                Fatal $BHMAS_fatalFileNotFound "File " emph "$FILENAME_GIVEN_AS_INPUT" " does not exist!"
            fi
            local FILE_WITH_DIRECTORIES=$FILENAME_GIVEN_AS_INPUT
        else
            local FILE_WITH_DIRECTORIES=''
        fi
        local PROJECT_DATABASE_FILE=$BHMAS_databaseGlobalPath/$(date +%Y_%m_%d)_$BHMAS_databaseFilename
    fi



    if [ $DISPLAY = "TRUE" ]; then

        NF_STRING=$(join "|" "${NF_ARRAY[@]:-}")
        MU_STRING=$(join "|" "${MU_ARRAY[@]:-}")
        MASS_STRING=$(join "|" "${MASS_ARRAY[@]:-}")
        NS_STRING=$(join "|" "${NS_ARRAY[@]:-}")
        NT_STRING=$(join "|" "${NT_ARRAY[@]:-}")
        BETA_STRING=$(join "|" "${BETA_ARRAY[@]:-}")
        TYPE_STRING=$(join "|" "${TYPE_ARRAY[@]:-}")
        STATUS_STRING=$(join "|" "${STATUS_ARRAY[@]:-}")

        [ "$FILTER_TRAJNO" = "TRUE" ] && [ "$TRAJ_LOW_VALUE" = "" ]  && TRAJ_LOW_VALUE=0
        [ "$FILTER_TRAJNO" = "TRUE" ] && [ "$TRAJ_HIGH_VALUE" = "" ]  && TRAJ_HIGH_VALUE=9999999

        [ "$FILTER_ACCRATE" = "TRUE" ] && [ "$ACCRATE_LOW_VALUE" = "" ]  && ACCRATE_LOW_VALUE=0.0
        [ "$FILTER_ACCRATE" = "TRUE" ] && [ "$ACCRATE_HIGH_VALUE" = "" ]  && ACCRATE_HIGH_VALUE=100.00

        [ "$FILTER_ACCRATE_LAST1K" = "TRUE" ] && [ "$ACCRATE_LAST1K_LOW_VALUE" = "" ]  && ACCRATE_LAST1K_LOW_VALUE=0.0
        [ "$FILTER_ACCRATE_LAST1K" = "TRUE" ] && [ "$ACCRATE__LAST1KHIGH_VALUE" = "" ]  && ACCRATE_LAST1K_HIGH_VALUE=100.00


        if [ "$CUSTOMIZE_COLUMNS" = "FALSE" ]; then
            NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER=( nfC muC kC ntC nsC betaC trajNoC accRateC accRateLast1KC maxDsC statusC lastTrajC )
        fi

        for NAME_OF_COLUMN in ${!COLUMNS[@]}; do
            NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL$NAME_OF_COLUMN-${COLUMNS[$NAME_OF_COLUMN]}"|"
        done

        for NAME_OF_COLUMN in ${NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER[@]}; do
            NAME_OF_COLUMN_NR_OF_COLUMN_STRING=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING$NAME_OF_COLUMN-${COLUMNS[$NAME_OF_COLUMN]}"|"
            NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING=$NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING$NAME_OF_COLUMN--${PRINTF_FORMAT_SPECIFIER_ARRAY[$NAME_OF_COLUMN]}"|"
            NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING=$NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING$NAME_OF_COLUMN-${HEADER_PRINTF_PARAMETER_ARRAY[$NAME_OF_COLUMN]}"|"
            NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING=$NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING$NAME_OF_COLUMN--${HEADER_PRINTF_FORMAT_SPECIFIER_ARRAY[$NAME_OF_COLUMN]}"|"
            LENGTH_OF_HEADER_SEPERATOR=$(($LENGTH_OF_HEADER_SEPERATOR+${FSNA[$NAME_OF_COLUMN]}+1))
        done

        for NAME_OF_COLUMN in ${NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER[@]}; do
            [ "$NAME_OF_COLUMN" = "trajNoC" ] && break
            NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN=$(($NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN+${FSNA[$NAME_OF_COLUMN]}+1))
        done
        NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN=$((NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN+${FSNA[trajNoC]}+1))
        STATISTICS_PRINTF_FORMAT_SPECIFIER_STRING="%${NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN}s\n"
        LENGTH_OF_HEADER_SEPERATOR=$(($LENGTH_OF_HEADER_SEPERATOR+${FSNA[nfC]}+1-${#BHMAS_nflavourPrefix})) #Add dynamicly to symmetrize the line under the header (the +1 is the space that is at the beginning of the line)
        #STRIPPING OF THE LAST | SYMBOL FROM THE STRING
        NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL="${NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL%|}"
        NAME_OF_COLUMN_NR_OF_COLUMN_STRING="${NAME_OF_COLUMN_NR_OF_COLUMN_STRING%|})"
        NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING="${NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING%|}"
        NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING="${NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING%|}"
        NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING="${NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING%|}"

        awk --posix -v filterNf=$FILTER_NF -v filterMu=$FILTER_MU -v filterKappa=$FILTER_MASS -v filterNt=$FILTER_NT -v filterNs=$FILTER_NS \
            -v filterBeta=$FILTER_BETA -v filterType=$FILTER_TYPE \
            -v filterTrajNo=$FILTER_TRAJNO -v filterAccRate=$FILTER_ACCRATE -v filterAccRateLast1K=$FILTER_ACCRATE_LAST1K -v filterMaxDs=$FILTER_MAX_ACTION \
            -v filterStatus=$FILTER_STATUS -v filterLastTrajTime=$FILTER_LASTTRAJ -v statisticsSummary=$STATISTICS_SUMMARY \
            -v nfString="$NF_STRING" -v muString="$MU_STRING" -v kappaString="$MASS_STRING" -v nsString="$NS_STRING" -v ntString="$NT_STRING" -v betaString="$BETA_STRING" \
            -v typeString=$TYPE_STRING -v statusString="$STATUS_STRING" \
            -v trajLowValue=$TRAJ_LOW_VALUE -v trajHighValue=$TRAJ_HIGH_VALUE -v accRateLowValue=$ACCRATE_LOW_VALUE -v accRateHighValue=$ACCRATE_HIGH_VALUE \
            -v accRateLast1KLowValue=$ACCRATE_LAST1K_LOW_VALUE -v accRateLast1KHighValue=$ACCRATE_LAST1K_HIGH_VALUE -v lastTrajTime=$LAST_TRAJ_TIME \
            -v nameOfColumnsAndNumberOfColumnsString=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL \
            -v nameOfDisplayedColumnsAndnrOfDisplayedColumnsString=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING \
            -v nameOfDisplayedColumnsAndSpecOfColumnsString=$NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING \
            -v nameOfColumnsAndHeaderOfColumnsString=$NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING \
            -v nameOfColumnsAndHeaderSpecOfColumnsString=$NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING \
            -v statisticsFormatSpecString=$STATISTICS_PRINTF_FORMAT_SPECIFIER_STRING \
            -v lengthOfHeaderSeperator=$LENGTH_OF_HEADER_SEPERATOR '

                     BEGIN{
                         nrOfTotalColumns=split(nameOfColumnsAndNumberOfColumnsString,columnNamesAndNumbersArray,"|");

                        for(i=1;i<=nrOfTotalColumns;i++){
                            split(columnNamesAndNumbersArray[i],columnNameAndNumber,"-");
                            columnName=columnNameAndNumber[1];
                            columnNumber=columnNameAndNumber[2];
                            columnNameColumnNumber[columnName]=columnNumber;
                        }
                        nrOfDisplayedColumns=split(nameOfDisplayedColumnsAndnrOfDisplayedColumnsString,columnNamesAndNumbersArray,"|");
                        split(nameOfDisplayedColumnsAndSpecOfColumnsString,columnNamesAndSpecsArray,"|");

                        for(i=1;i<=nrOfDisplayedColumns;i++){
                            split(columnNamesAndNumbersArray[i],columnNameAndNumber,"-");
                            columnName=columnNameAndNumber[1];
                            columnNumber=columnNameAndNumber[2];
                            columnNamesInOrder[i]=columnName;
                            split(columnNamesAndSpecsArray[i],columnNameAndSpec,"--");
                            columnSpec=columnNameAndSpec[2];
                            specForColorCode="%-s";
                            columnNameColumnSpec[columnName]=specForColorCode " " columnSpec;
                        }
                        split(nameOfColumnsAndHeaderOfColumnsString,columnNamesAndHeaderArray,"|");
                        split(nameOfColumnsAndHeaderSpecOfColumnsString,columnNamesAndHeaderSpecArray,"|");

                        printf(" \033[38;5;26m");
                        for(i=1;i<=lengthOfHeaderSeperator;i++){
                            printf("=");
                        }
                        printf("\033[0m\n");
                        printf(" "); #THIS PRINTF IS IMPORTANT TO GET THE HEADER IN TO THE RIGHT PLACE
                        for(i=1;i<=nrOfDisplayedColumns;i++){
                            split(columnNamesAndHeaderArray[i],columnAndHeader,"-");
                            split(columnNamesAndHeaderSpecArray[i],columnAndHeaderSpec,"--");
                            specifierString=columnAndHeaderSpec[2];
                            printf(specifierString,columnAndHeader[2]);
                        }
                        printf("  \033[0m\n \033[0;38;5;26m");
                        for(i=1;i<=lengthOfHeaderSeperator;i++){
                            printf("=");
                        }
                        printf("\033[0m\n");
                     }
                     {critFailedCounter=0}

                     ######################################################################## FILTERING PART BEGIN ############################################################################
                     filterNf == "TRUE" {if($(columnNameColumnNumber["nfC"]) !~ nfString) {critFailedCounter--;}}
                     filterMu == "TRUE" {if($(columnNameColumnNumber["muC"]) !~ muString) {critFailedCounter--;}}
                     filterKappa == "TRUE" {if($(columnNameColumnNumber["kC"]) !~ kappaString) {critFailedCounter--;}}
                     filterNs == "TRUE" {if($(columnNameColumnNumber["nsC"]) !~ nsString) {critFailedCounter--;}}
                     filterNt == "TRUE" {if($(columnNameColumnNumber["ntC"]) !~ ntString) {critFailedCounter--;}}
                     filterBeta == "TRUE" {if($(columnNameColumnNumber["betaC"]) !~ betaString) {critFailedCounter--;}}
                     filterType == "TRUE" {if($(columnNameColumnNumber["betaC"]) !~ typeString) {critFailedCounter--;}}
                     filterStatus == "TRUE" {if($(columnNameColumnNumber["statusC"]) !~ statusString) {critFailedCounter--;}}

                     filterTrajNo == "TRUE" {if(length(trajLowValue) == 0 ? "0" : trajLowValue > $(columnNameColumnNumber["trajNoC"])){critFailedCounter--;}}
                     filterTrajNo == "TRUE" {if(length(trajHighValue) == 0 ? "999999" : trajHighValue < $(columnNameColumnNumber["trajNoC"])){critFailedCounter--;}}

                     filterAccRate == "TRUE" {if(length(accRateLowValue) == 0 ? "0" : accRateLowValue > $(columnNameColumnNumber["accRateC"])){critFailedCounter--;}}
                     filterAccRate == "TRUE" {if(length(accRateHighValue) == 0 ? "100.00" : accRateHighValue < $(columnNameColumnNumber["accRateC"])){critFailedCounter--;}}

                     filterAccRateLast1K == "TRUE" {if(length(accRateLast1KLowValue) == 0 ? "0" : accRateLast1KLowValue > $(columnNameColumnNumber["accRateLast1KC"])){critFailedCounter--;}}
                     filterAccRateLast1K == "TRUE" {if(length(accRateLast1KHighValue) == 0 ? "100.00" : accRateLast1KHighValue < $(columnNameColumnNumber["accRateLast1KC"])){critFailedCounter--;}}

                     filterLastTrajTime == "TRUE" {if(lastTrajTime > $(columnNameColumnNumber["lastTrajC"]) || $(columnNameColumnNumber["lastTrajC"]) == "------"){critFailedCounter--;}}

                     statisticsSummary == "FALSE" && critFailedCounter == 0 {
                        printf(" "); #Aesthetics
                        for(i=1;i<=nrOfDisplayedColumns;i++){
                            nameOfColumn=columnNamesInOrder[i];
                            specifierString=columnNameColumnSpec[nameOfColumn];
                            columnOfColorCode=columnNameColumnNumber[nameOfColumn]-1;
                            columnOfColumnName=columnNameColumnNumber[nameOfColumn];
                            printf(specifierString,$(columnOfColorCode),$(columnOfColumnName));
                        }
                        printf("\n");
                     }
                     statisticsSummary == "TRUE" && critFailedCounter == 0 {lineCounter++;dataRow=sprintf("%s",$0);dataRowArray[lineCounter]=dataRow}
                     ######################################################################### FILTERING PART END #############################################################################


                     ######################################################################### SUMMARY OF STATISTICS ##########################################################################
                     statisticsSummary == "TRUE" {
                        split($(columnNameColumnNumber["betaC"]),betaChainType,"_");
                        if(betaChainType[3] == "NC"){
                            statisticsSummaryArray[$(columnNameColumnNumber["nfC"]) "_" $(columnNameColumnNumber["muC"]) "_" $(columnNameColumnNumber["kC"]) "_" $(columnNameColumnNumber["ntC"]) "_" \
                            $(columnNameColumnNumber["nsC"]) "_" betaChainType[1] "_" betaChainType[3]]+=$(columnNameColumnNumber["trajNoC"]);
                        }
                    }

                    END{
                        if(statisticsSummary == "TRUE"){
                            split(dataRowArray[1],fieldsArray," ");
                            split(fieldsArray[columnNameColumnNumber["betaC"]],betaChainType,"_");

                            if(betaChainType[3] == "NC"){
                                oldKey = fieldsArray[columnNameColumnNumber["nfC"]] "_" fieldsArray[columnNameColumnNumber["muC"]] "_" fieldsArray[columnNameColumnNumber["kC"]] "_" fieldsArray[columnNameColumnNumber["ntC"]] "_" \
                                fieldsArray[columnNameColumnNumber["nsC"]] "_" betaChainType[1] "_" betaChainType[3];
                            }

                            for(i=1;i<=lineCounter;i++){
                                split(dataRowArray[i],fieldsArray," ");
                                split(fieldsArray[columnNameColumnNumber["betaC"]],betaChainType,"_");
                                if(betaChainType[3] == "NC"){
                                    newKey = fieldsArray[columnNameColumnNumber["nfC"]] "_" fieldsArray[columnNameColumnNumber["muC"]] "_" fieldsArray[columnNameColumnNumber["kC"]] "_" \
                                    fieldsArray[columnNameColumnNumber["ntC"]] "_" fieldsArray[columnNameColumnNumber["nsC"]] "_" betaChainType[1] "_" betaChainType[3]
                                }

                                if(betaChainType[3] == "NC"){
                                    if(newKey != oldKey){
                                        printf(" "); #Aesthetics
                                        printf(statisticsFormatSpecString,statisticsSummaryArray[oldKey]);
                                        oldKey=newKey;
                                    }
                                }

                                split(dataRowArray[i],columnsArray," ")
                                printf(" "); #Aesthetics
                                for(columnEntry=1;columnEntry<=nrOfDisplayedColumns;columnEntry++){
                                    nameOfColumn=columnNamesInOrder[columnEntry];
                                    specifierString=columnNameColumnSpec[nameOfColumn];
                                    columnOfColorCode=columnNameColumnNumber[nameOfColumn]-1;
                                    columnOfColumnName=columnNameColumnNumber[nameOfColumn];
                                    printf(specifierString,columnsArray[columnOfColorCode],columnsArray[columnOfColumnName]);
                                }
                                printf(" \033[0;m")
                                printf("\n");
                            }
                            printf(" "); #Aesthetics
                            printf(statisticsFormatSpecString,statisticsSummaryArray[newKey]);
                        }
                        printf(" \033[0m\033[0;38;5;26m");
                        for(i=1;i<=lengthOfHeaderSeperator;i++){
                            printf("=");
                        }
                        printf("\033[0m\n");
                    }
        ' $PROJECT_DATABASE_FILE

        cecho "\n Last update ended on " B "$(date -r $PROJECT_DATABASE_FILE +"%d.%m.%Y\e[21m at \e[1m%H:%M")" uB o "  --->  " file "$PROJECT_DATABASE_FILE" "\n"
    fi

    #==========================================================================================================================================================================================#

    if [ $UPDATE = "TRUE" ]; then

        if [ "$SLEEP_TIME" != "" ] && [ "$UPDATE_TIME" != "" ]; then
            Internal "Values for both " emph "SLEEP_TIME" " and " emph "UPDATE_TIME" " are specified but it should not be the case!"
        fi

        local TEMPORARY_FILE_WITH_DIRECTORIES="${BHMAS_databaseGlobalPath}/temporaryFileWithDirectoriesForDatabaseUpdate.dat"
        rm -f $TEMPORARY_FILE_WITH_DIRECTORIES
        local TEMPORARY_DATABASE_FILE="${BHMAS_databaseGlobalPath}/temporaryDatabaseForUpdate.dat"
        rm -f $TEMPORARY_DATABASE_FILE

        REGEX_STRING=".*/"
        for i in ${!BHMAS_parameterPrefixes[@]}; do
            REGEX_STRING=$REGEX_STRING${BHMAS_parameterPrefixes[$i]}${BHMAS_parameterRegexes[$i]}/
        done
        REGEX_STRING=${REGEX_STRING%/}

        while :
        do
            if [ "$UPDATE_TIME" != "" ]; then
                CURRENT_EPOCH=$(date +%s)
                if [ $CURRENT_EPOCH -gt $(date -d "$UPDATE_TIME" +%s) ]; then
                    TARGET_EPOCH=$(date -d "$UPDATE_TIME tomorrow" +%s)
                    cecho lp B "\n\tEntering sleeping mode. Performing next update on " emph "$(date -d "$UPDATE_TIME tomorrow" +"%d.%m.%Y \e[38;5;147mat\e[38;5;86m %H:%M")" "\n"
                else
                    TARGET_EPOCH=$(date -d "$UPDATE_TIME" +%s)
                    cecho lp B "\n\tEntering sleeping mode. Performing next update today at " emph "$(date -d "$UPDATE_TIME" +"%H:%M")" "\n"
                fi
                SLEEP_SECONDS=$(( $TARGET_EPOCH - $CURRENT_EPOCH ))
                sleep $SLEEP_SECONDS
            fi

            [ "$FILE_WITH_DIRECTORIES" = "" ] && find $BHMAS_submitDiskGlobalPath/$BHMAS_projectSubpath -regextype grep -regex "$REGEX_STRING" -type d > $TEMPORARY_FILE_WITH_DIRECTORIES
            [ "$FILE_WITH_DIRECTORIES" != "" ] && cat $FILE_WITH_DIRECTORIES > $TEMPORARY_FILE_WITH_DIRECTORIES

            if [ ! -s "$TEMPORARY_FILE_WITH_DIRECTORIES" ]; then
                Fatal $BHMAS_fatalLogicError -n emph "No directory" " for the database update! Please check the given file or the folder structure!"
            fi

            while read line
            do
                if [[ "$line" =~ ^[^#] ]]; then
                    PARAMS=( $(awk 'BEGIN{FS="/"}{print $(NF-4) " " $(NF-3) " " $(NF-2) " " $(NF-1) " " $(NF)}' <<< "$line") )
                else
                    continue
                fi

                if [ -d $line ]; then
                    cecho -n lo "\tUpdating: " wg "$line "
                    cd $line
                else
                    cecho lr "\n Directory " dir "$line" " not found, skipped!"
                    continue
                fi

                PARAMETER_DIRECTORY_STRUCTURE=${line##*$BHMAS_projectSubpath}

                ListSimulationsStatus_SLURM $PARAMETER_DIRECTORY_STRUCTURE | \
                    sed -r 's/[^(\x1b)]\[|\]|\(|\)|%//g' | \
                    sed -r 's/(\x1B\[[0-9]{1,2};[0-9]{0,2};[0-9]{0,3}m)(.)/\1 \2/g' | \
                    sed -r 's/(.)(\x1B\[.{1,2};.{1,2}m)/\1 \2/g' | \
                    sed -r 's/(\x1B\[.{1,2};.{1,2}m)(.)/\1 \2/g' |
                    awk --posix -v nf=${PARAMS[0]#$BHMAS_nflavourPrefix*} -v mu=${PARAMS[1]#$BHMAS_chempotPrefix*} -v k=${PARAMS[2]#$BHMAS_massPrefix*} -v nt=${PARAMS[3]#$BHMAS_ntimePrefix*} -v ns=${PARAMS[4]#*$BHMAS_nspacePrefix} '
                            $3 ~ /^[0-9]\.[0-9]{4}/{
                            print "\033[36m " nf " \033[36m " mu " \033[36m " k " \033[36m " nt " \033[36m " ns " " $(3-1) " " $3 " " $(5-1) " " $5 " " $(8-1) " " $8 " " $(11-1) " " $(11) " " $(18-1) " " $(18) " " $(15-1) " " $15 " " $(21-1) " " $21 " " "\033[0m"
                            }
                        ' >> $TEMPORARY_DATABASE_FILE

                cd $CURRENT_DIRECTORY
                cecho lg "...done!"
            done < <(cat $TEMPORARY_FILE_WITH_DIRECTORIES)

            if [ ! -f $TEMPORARY_DATABASE_FILE ] || [ "$(wc -l < $TEMPORARY_DATABASE_FILE)" -eq 0 ]; then
                Internal "After the database procedure, the database seems to be " emph "empty" "! Temporary files\n"\
                         file "   $TEMPORARY_DATABASE_FILE" "\n"\
                         file "   $TEMPORARY_FILE_WITH_DIRECTORIES\n"\
                         "have been left for further investigation!"
            fi

            #Updating the content of PROJECT_DATABASE_FILE
            local PROJECT_DATABASE_FILE=$BHMAS_databaseGlobalPath/$(date +%Y_%m_%d)_$BHMAS_databaseFilename
            cp $TEMPORARY_DATABASE_FILE $PROJECT_DATABASE_FILE

            #Clean up
            rm $TEMPORARY_DATABASE_FILE
            rm $TEMPORARY_FILE_WITH_DIRECTORIES

            if [ "$SLEEP_TIME" != "" ]; then
                cecho lp B "\n\tSleeping " emph "$SLEEP_TIME" " starting on " emph "$(date +"%d.%m.%Y at %H:%M:%S")" "\n"
                sleep $SLEEP_TIME
            fi

            if [ "$SLEEP_TIME" = "" ] && [ "$UPDATE_TIME" = "" ]; then
                break
            fi
        done
        cecho ''
    fi

    #==========================================================================================================================================================================================#

    if [ $REPORT = "TRUE" ]; then

        cecho lm "\n\t\t\t  " U "AUTOMATIC REPORT FROM DATABASE (status on "\
              B "$(date -r $PROJECT_DATABASE_FILE "$(cecho -n -d '+%%d.%%m.%%Y' uB ' at ' B '%%H:%%M')")" uB ")\n"

        local exitCodeAwk
        exitCodeAwk=0

        awk --posix -v betaColorColumn="$((${COLUMNS[betaC]} -1 ))" \
            -v trajNoColorColumn="$((${COLUMNS[trajNoC]} -1 ))" \
            -v accRateColorColumn="$((${COLUMNS[accRateC]} -1 ))" \
            -v accRateLast1KColorColumn="$((${COLUMNS[accRateLast1KC]} -1 ))" \
            -v maxDsColorColumn="$((${COLUMNS[maxDsC]} -1 ))" \
            -v statusColorColumn="$((${COLUMNS[statusC]} -1 ))" \
            -v lastTrajColorColumn="$((${COLUMNS[lastTrajC]} -1 ))" \
            -v defaultColor="${BHMAS_defaultListstatusColor/e/033}" \
            -v suspiciousBetaColor="${BHMAS_suspiciousBetaListstatusColor/e/033}" \
            -v wrongBetaColor="${BHMAS_wrongBetaListstatusColor/e/033}" \
            -v tooLowAccColor="${BHMAS_tooLowAcceptanceListstatusColor/e/033}" \
            -v lowAccColor="${BHMAS_lowAcceptanceListstatusColor/e/033}" \
            -v optimalAccColor="${BHMAS_optimalAcceptanceListstatusColor/e/033}" \
            -v highAccColor="${BHMAS_highAcceptanceListstatusColor/e/033}" \
            -v tooHighAccColor="${BHMAS_tooHighAcceptanceListstatusColor/e/033}" \
            -v tooHighMaxDsColor="${BHMAS_tooHighDeltaSListstatusColor/e/033}" \
            -v runningColor="${BHMAS_runningListstatusColor/e/033}" \
            -v pendingColor="${BHMAS_pendingListstatusColor/e/033}" \
            -v toBeCleanedColor="${BHMAS_toBeCleanedListstatusColor/e/033}" \
            -v stuckColor="${BHMAS_stuckSimulationListstatusColor/e/033}" \
            -v fineColor="${BHMAS_fineSimulationListstatusColor/e/033}" \
            -v tooLowAccThreshold="${BHMAS_tooLowAcceptanceThreshold}" \
            -v lowAccThreshold="${BHMAS_lowAcceptanceThreshold}" \
            -v highAccThreshold="${BHMAS_highAcceptanceThreshold}" \
            -v tooHighAccThreshold="${BHMAS_tooHighAcceptanceThreshold}" \
            -v tooHighMaxDsThreshold="${BHMAS_deltaSThreshold}" '
BEGIN{
filesToBeCleaned = 0
simTooLowAcc = 0
simLowAcc = 0
simOptimalAcc = 0
simHighAcc = 0
simTooHighAcc = 0
simTooLowAcc1K = 0
simLowAcc1K = 0
simOptimalAcc1K = 0
simHighAcc1K = 0
simTooHighAcc1K = 0
simRunning = 0
simPending = 0
simStuck = 0
simFine = 0
simOnBrokenGPU = 0
criticalSituation = 0
}
{
if($betaColorColumn == wrongBetaColor || $maxDsColorColumn == tooHighMaxDsColor){simOnBrokenGPU+=1; criticalSituation=1}
if($trajNoColorColumn == toBeCleanedColor){filesToBeCleaned+=1}
if($accRateColorColumn == tooLowAccColor){simTooLowAcc+=1; criticalSituation=1}
if($accRateColorColumn == lowAccColor){simLowAcc+=1}
if($accRateColorColumn == optimalAccColor){simOptimalAcc+=1}
if($accRateColorColumn == highAccColor){simHighAcc+=1}
if($accRateColorColumn == tooHighAccColor){simTooHighAcc+=1}
if($accRateLast1KColorColumn == tooLowAccColor){simTooLowAcc1K+=1; criticalSituation=1}
if($accRateLast1KColorColumn == lowAccColor){simLowAcc1K+=1}
if($accRateLast1KColorColumn == optimalAccColor){simOptimalAcc1K+=1}
if($accRateLast1KColorColumn == highAccColor){simHighAcc1K+=1}
if($accRateLast1KColorColumn == tooHighAccColor){simTooHighAcc1K+=1}
if($statusColorColumn == runningColor){simRunning+=1}
if($statusColorColumn == pendingColor){simPending+=1}
if($lastTrajColorColumn == stuckColor){simStuck+=1; criticalSituation=1}
if($lastTrajColorColumn == fineColor){simFine+=1}
}
END{
def="\033[0m"
red="\033[91m"
darkOrange="\033[38;5;202m"
lightOrange="\033[38;5;208m"
yellow="\033[93m"
green="\033[32m"
blue="\033[38;5;45m"
pink="\033[38;5;171m"
bold="\033[1m"
success=0
failure=1

string[0]= "\t\t" pink "                     Simulations on " bold " broken GPU"def pink": %s%s%4d " def "\n"
string[1]= "\t\t" blue "  Simulations with" bold " too low acceptance" def blue " - " bold "last 1k" def blue ": %s%s%4d" def blue "  - %s%s%4d" def blue "  [  0%%,  %2d%% )  " def "\n"
string[2]= "\t\t" blue "      Simulations with" bold " low acceptance" def blue " - " bold "last 1k" def blue ": %s%s%4d" def blue "  - %s%s%4d" def blue "  [ %2d%%,  %2d%% ) " def "\n"
string[3]= "\t\t" blue "  Simulations with" bold " optimal acceptance" def blue " - " bold "last 1k" def blue ": %s%s%4d" def blue "  - %s%s%4d" def blue "  [ %2d%%,  %2d%% ] " def "\n"
string[4]= "\t\t" blue "     Simulations with" bold " high acceptance" def blue " - " bold "last 1k" def blue ": %s%s%4d" def blue "  - %s%s%4d" def blue "  ( %2d%%,  %2d%% ] " def "\n"
string[5]= "\t\t" blue " Simulations with" bold " too high acceptance" def blue " - " bold "last 1k" def blue ": %s%s%4d" def blue "  - %s%s%4d" def blue "  ( %2d%%, 100%% ]  " def "\n"
string[6]= "\t\t" pink "                           Simulations " bold " running" def pink ": %s%s%4d " def "\n"
string[7]= "\t\t" pink "                           Simulations " bold " pending" def pink ": %s%s%4d " def "\n"
string[8]= "\t\t" blue "               Simulations " bold " stuck" def blue " (or finished): %s%s%4d " def "\n"
string[9]= "\t\t" blue "                      Simulations " bold " running fine" def blue ": %s%s%4d " def "\n"
string[10]="\t\t" pink "                    Output files " bold " to be cleaned" def pink ": %s%s%4d " def "\n"

printf string[0] , (simOnBrokenGPU>0 ? red : green)          , bold, simOnBrokenGPU
printf string[1] , (simTooLowAcc>0   ? red : green)          , bold, simTooLowAcc    , (simTooLowAcc1K>0   ? red : green)        , bold, simTooLowAcc1K,  tooLowAccThreshold
printf string[2] , (simLowAcc>0      ? darkOrange : green)   , bold, simLowAcc       , (simLowAcc1K>0      ? darkOrange : green) , bold, simLowAcc1K,     tooLowAccThreshold, lowAccThreshold
printf string[3] , (simOptimalAcc==0  ? green : green)       , bold, simOptimalAcc   , (simOptimalAcc1K==0  ? green : green)     , bold, simOptimalAcc1K, lowAccThreshold, highAccThreshold
printf string[4] , (simHighAcc>0     ? yellow : green)       , bold, simHighAcc      , (simHighAcc1K>0     ? yellow : green)     , bold, simHighAcc1K,    highAccThreshold, tooHighAccThreshold
printf string[5] , (simTooHighAcc>0  ? lightOrange : green)  , bold, simTooHighAcc   , (simTooHighAcc1K>0  ? lightOrange : green), bold, simTooHighAcc1K, tooHighAccThreshold
printf string[6] , green                                     , bold, simRunning
printf string[7] , (simPending>0     ? yellow : green)       , bold, simPending
printf string[8] , (simStuck>0     ? red : green)            , bold, simStuck
printf string[9] , green                                     , bold, simFine
printf string[10], (filesToBeCleaned>0 ? lightOrange : green), bold, filesToBeCleaned

if (criticalSituation == 1) {exit failure} else {exit success}
        }' $PROJECT_DATABASE_FILE || exitCodeAwk=1

        if [ $exitCodeAwk -ne 0 ]; then
            cecho -d -n lr "\n\t\t\t"
        else
            cecho -d -n wg "\n\t\t\t"
        fi
        cecho "Use " B "-" U "ds" uU uB " | " B "--" U "dataBase" uU " --" U "show" uU uB " option to display set of simulations.\n"
    fi

    #==========================================================================================================================================================================================#

    if [ $SHOW = "TRUE" ]; then

        local TEMPORARY_DATABASE_FILE="tmpDatabaseForShowing.dat"
        rm -f $BHMAS_databaseGlobalPath/$TEMPORARY_DATABASE_FILE

        local POSSIBLE_SIMULATIONS_TO_SHOW=( "Simulations on broken GPU"
                                             "Simulations stuck (or finished)"
                                             "Simulations with output file to be cleaned"
                                             "Simulations with too low acceptance rate"
                                             "Simulations with low acceptance rate"
                                             "Simulations with optimal acceptance rate"
                                             "Simulations with high acceptance rate"
                                             "Simulations with too high acceptance rate"
                                             "Simulations with too low acceptance rate in last 1k trajectories"
                                             "Simulations with low acceptance rate in last 1k trajectories"
                                             "Simulations with optimal acceptance rate in last 1k trajectories"
                                             "Simulations with high acceptance rate in last 1k trajectories"
                                             "Simulations with too high acceptance rate in last 1k trajectories"
                                             "Running simulations"
                                             "Pending simulations" )

        cecho -d yg "Which simulations would you like to show?\n" lp
        PS3=$(cecho -d yg '\nEnter the number corresponding to the desired set: ' lp)
        select SIMULATION in "${POSSIBLE_SIMULATIONS_TO_SHOW[@]}"; do
            if ! ElementInArray "$SIMULATION" "${POSSIBLE_SIMULATIONS_TO_SHOW[@]}"; then
                continue
            else
                case $SIMULATION in
                    "Simulations on broken GPU")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[betaC]} -1 ))" )
                        COLUMNS_TO_FILTER+=( "$((${COLUMNS[maxDsC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_wrongBetaListstatusColor/e/033}" )
                        VALUES_TO_MATCH+=( "${BHMAS_tooHighDeltaSListstatusColor/e/033}" )
                        ;;
                    "Simulations stuck (or finished)")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[lastTrajC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_stuckSimulationListstatusColor/e/033}" )
                        ;;
                    "Simulations with output file to be cleaned")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[trajNoC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_toBeCleanedListstatusColor/e/033}" )
                        ;;
                    "Simulations with too low acceptance rate")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_tooLowAcceptanceListstatusColor/e/033}" )
                        ;;
                    "Simulations with low acceptance rate")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_lowAcceptanceListstatusColor/e/033}" )
                        ;;
                    "Simulations with optimal acceptance rate")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_optimalAcceptanceListstatusColor/e/033}" )
                        ;;
                    "Simulations with high acceptance rate")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_highAcceptanceListstatusColor/e/033}" )
                        ;;
                    "Simulations with too high acceptance rate")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_tooHighAcceptanceListstatusColor/e/033}" )
                        ;;
                    "Simulations with too low acceptance rate in last 1k trajectories")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateLast1KC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_tooLowAcceptanceListstatusColor/e/033}" )
                        ;;
                    "Simulations with low acceptance rate in last 1k trajectories")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateLast1KC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_lowAcceptanceListstatusColor/e/033}" )
                        ;;
                    "Simulations with optimal acceptance rate in last 1k trajectories")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateLast1KC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_optimalAcceptanceListstatusColor/e/033}" )
                        ;;
                    "Simulations with high acceptance rate in last 1k trajectories")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateLast1KC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_highAcceptanceListstatusColor/e/033}" )
                        ;;
                    "Simulations with too high acceptance rate in last 1k trajectories")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[accRateLast1KC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_tooHighAcceptanceListstatusColor/e/033}" )
                        ;;
                    "Running simulations")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[statusC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_runningListstatusColor/e/033}" )
                        ;;
                    "Pending simulations")
                        local COLUMNS_TO_FILTER=( "$((${COLUMNS[statusC]} -1 ))" )
                        local VALUES_TO_MATCH=( "${BHMAS_pendingListstatusColor/e/033}" )
                        ;;
                esac
                break
            fi
        done
        cecho ''

        for i in ${!COLUMNS_TO_FILTER[@]}
        do
            awk --posix -v columnToFilter="${COLUMNS_TO_FILTER[$i]}" -v valueToMatch="${VALUES_TO_MATCH[$i]}" '$columnToFilter == valueToMatch{print $0}' $PROJECT_DATABASE_FILE >> $BHMAS_databaseGlobalPath/$TEMPORARY_DATABASE_FILE
        done

        if [ $(wc -l < $BHMAS_databaseGlobalPath/$TEMPORARY_DATABASE_FILE) -eq 0 ]; then
            cecho o emph "  $SIMULATION" " not found in database (last update ended on "\
                  B "$(date -r $PROJECT_DATABASE_FILE "$(cecho -n -d '+%%d.%%m.%%Y' uB ' at ' B '%%H:%%M')")" uB ").\n"
        else
            __static__DisplayDatabaseFile <(sort $BHMAS_databaseGlobalPath/$TEMPORARY_DATABASE_FILE | uniq)
            cecho "\n Last update ended on " B "$(date -r $PROJECT_DATABASE_FILE "$(cecho -n -d '+%%d.%%m.%%Y' uB ' at ' B '%%H:%%M')")"\
                  uB o "  --->  " file "$PROJECT_DATABASE_FILE" "\n"
        fi

        rm $BHMAS_databaseGlobalPath/$TEMPORARY_DATABASE_FILE

    fi

}



function __static__DisplayDatabaseFile()
{

    if [ "$CUSTOMIZE_COLUMNS" = "FALSE" ]; then
        NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER=( nfC muC kC ntC nsC betaC trajNoC accRateC accRateLast1KC maxDsC statusC lastTrajC )
    fi

    for NAME_OF_COLUMN in ${!COLUMNS[@]}; do
        NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL$NAME_OF_COLUMN-${COLUMNS[$NAME_OF_COLUMN]}"|"
    done

    for NAME_OF_COLUMN in ${NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER[@]}; do
        NAME_OF_COLUMN_NR_OF_COLUMN_STRING=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING$NAME_OF_COLUMN-${COLUMNS[$NAME_OF_COLUMN]}"|"
        NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING=$NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING$NAME_OF_COLUMN--${PRINTF_FORMAT_SPECIFIER_ARRAY[$NAME_OF_COLUMN]}"|"
        NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING=$NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING$NAME_OF_COLUMN-${HEADER_PRINTF_PARAMETER_ARRAY[$NAME_OF_COLUMN]}"|"
        NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING=$NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING$NAME_OF_COLUMN--${HEADER_PRINTF_FORMAT_SPECIFIER_ARRAY[$NAME_OF_COLUMN]}"|"
        LENGTH_OF_HEADER_SEPERATOR=$(($LENGTH_OF_HEADER_SEPERATOR+${FSNA[$NAME_OF_COLUMN]}+1))
    done

    LENGTH_OF_HEADER_SEPERATOR=$(($LENGTH_OF_HEADER_SEPERATOR+${FSNA[muC]}+1-${#BHMAS_chempotPrefix})) #Add dynamicly to simmetrize the line under the header (the +1 is the space that is at the beginning of the line)
    #STRIPPING OF THE LAST | SYMBOL FROM THE STRING
    NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL="${NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL%|}"
    NAME_OF_COLUMN_NR_OF_COLUMN_STRING="${NAME_OF_COLUMN_NR_OF_COLUMN_STRING%|}"
    NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING="${NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING%|}"
    NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING="${NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING%|}"
    NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING="${NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING%|}"

    awk --posix -v nameOfColumnsAndNumberOfColumnsString=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL \
        -v nameOfDisplayedColumnsAndnrOfDisplayedColumnsString=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING \
        -v nameOfDisplayedColumnsAndSpecOfColumnsString=$NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING \
        -v nameOfColumnsAndHeaderOfColumnsString=$NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING \
        -v nameOfColumnsAndHeaderSpecOfColumnsString=$NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING \
        -v lengthOfHeaderSeperator=$LENGTH_OF_HEADER_SEPERATOR '
                     BEGIN{
                         nrOfTotalColumns=split(nameOfColumnsAndNumberOfColumnsString,columnNamesAndNumbersArray,"|");

                        for(i=1;i<=nrOfTotalColumns;i++){
                            split(columnNamesAndNumbersArray[i],columnNameAndNumber,"-");
                            columnName=columnNameAndNumber[1];
                            columnNumber=columnNameAndNumber[2];
                            columnNameColumnNumber[columnName]=columnNumber;
                        }
                        nrOfDisplayedColumns=split(nameOfDisplayedColumnsAndnrOfDisplayedColumnsString,columnNamesAndNumbersArray,"|");
                        split(nameOfDisplayedColumnsAndSpecOfColumnsString,columnNamesAndSpecsArray,"|");

                        for(i=1;i<=nrOfDisplayedColumns;i++){
                            split(columnNamesAndNumbersArray[i],columnNameAndNumber,"-");
                            columnName=columnNameAndNumber[1];
                            columnNumber=columnNameAndNumber[2];
                            columnNamesInOrder[i]=columnName;
                            split(columnNamesAndSpecsArray[i],columnNameAndSpec,"--");
                            columnSpec=columnNameAndSpec[2];
                            specForColorCode="%-s";
                            columnNameColumnSpec[columnName]=specForColorCode " " columnSpec;
                        }
                        split(nameOfColumnsAndHeaderOfColumnsString,columnNamesAndHeaderArray,"|");
                        split(nameOfColumnsAndHeaderSpecOfColumnsString,columnNamesAndHeaderSpecArray,"|");

                        printf(" \033[38;5;26m");
                        for(i=1;i<=lengthOfHeaderSeperator;i++){
                            printf("=");
                        }
                        printf("\033[0m\n");
                        printf(" "); #THIS PRINTF IS IMPORTANT TO GET THE HEADER IN TO THE RIGHT PLACE
                        for(i=1;i<=nrOfDisplayedColumns;i++){
                            split(columnNamesAndHeaderArray[i],columnAndHeader,"-");
                            split(columnNamesAndHeaderSpecArray[i],columnAndHeaderSpec,"--");
                            specifierString=columnAndHeaderSpec[2];
                            printf(specifierString,columnAndHeader[2]);
                        }
                        printf("  \033[0m\n \033[0;38;5;26m");
                        for(i=1;i<=lengthOfHeaderSeperator;i++){
                            printf("=");
                        }
                        printf("\033[0m\n");
                     }
{
                        printf(" "); #Aesthetics
                        for(i=1;i<=nrOfDisplayedColumns;i++){
                            nameOfColumn=columnNamesInOrder[i];
                            specifierString=columnNameColumnSpec[nameOfColumn];
                            columnOfColorCode=columnNameColumnNumber[nameOfColumn]-1;
                            columnOfColumnName=columnNameColumnNumber[nameOfColumn];
                            printf(specifierString,$(columnOfColorCode),$(columnOfColumnName));
                        }
                        printf("\n");
}
                    END{
                        printf(" \033[0m\033[0;38;5;26m");
                        for(i=1;i<=lengthOfHeaderSeperator;i++){
                            printf("=");
                        }
                        printf("\033[0m\n");
                    }'     $1

}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         join\
         projectStatisticsDatabase\
         __static__DisplayDatabaseFile
