#!/bin/bash

#TODO: 
#*If a filtering option is specified wrongly, should the program exit or not? If not, should the error message rather be printed in the end?
#*Is it necessary to implement the functionality where the script uses find the update the database?
#*Coloured output?
#*Other options?
#*User specific variables?
#*Putting the command line parser into another file in order to remove the cluttering - right now the parser makes up ~50% of the script.
#*Everytime the database is updated, actually create a new file with the date and time in the name? This way it possible to track how the statistics
# grow over longer periods.

function join { local IFS="$1"; shift; echo "$*"; }

FILE_WITH_PATHS="directoriesToGatherStatisticsFrom.dat"
TEMPORARY_STATISTICS_FILE="tmpStatistics.dat"
PROJECT_STATISTICS_FILE="projectStatistics.dat"
CURRENT_DIRECTORY=$(pwd)

rm -f $TEMPORARY_STATISTICS_FILE

MU_C=$((2*1)) 
K_C=$((2*2)) 
NT_C=$((2*3)) 
NS_C=$((2*4)) 
BETA_C=$((2*5)) 
TRAJNO_C=$((2*6)) 
ACCRATE_C=$((2*7)) 
STATUS_C=$((2*8)) 
LASTTRAJ_C=$((2*9))

PRINTF_FORMAT_SPECIFIER_STRING=""
PRINTF_PARAMETER_STRING=""

HEADER_PRINTF_FORMAT_SPECIFIER_STRING=""
HEADER_PRINTF_PARAMETER_STRING=""
HEADER_ROW_SEPARATOR=""

declare -A COLUMNS=( [muC]=$MU_C [kC]=$K_C [ntC]=$NT_C [nsC]=$NS_C [betaC]=$BETA_C [trajNoC]=$TRAJNO_C [accRateC]=$ACCRATE_C [statusC]=$STATUS_C [lastTrajC]=$LASTTRAJ_C )

#FSNA = FORMAT_SPECIFIER_NUMBER_ARRAY
declare -A FSNA=( [muC]="7" [kC]="8" [ntC]="6" [nsC]="6" [betaC]="19" [trajNoC]="11" [accRateC]="8" [statusC]="13" [lastTrajC]="11" )

declare -A PRINTF_FORMAT_SPECIFIER_ARRAY=( [muC]="%-${FSNA[muC]}s" [kC]="%-${FSNA[kC]}s" [ntC]="%-${FSNA[ntC]}d" [nsC]="%-${FSNA[nsC]}d" [betaC]="%-${FSNA[betaC]}s" \
											[trajNoC]="%-${FSNA[trajNoC]}d" [accRateC]="%-${FSNA[accRateC]}s" [statusC]="%-${FSNA[statusC]}s" [lastTrajC]="%-${FSNA[lastTrajC]}s" )

declare -A HEADER_PRINTF_FORMAT_SPECIFIER_ARRAY=( [muC]="%-8s" [kC]="%-9s" [ntC]="%-7s" [nsC]="%-7s" [betaC]="%-20s" [trajNoC]="%-12s" [accRateC]="%-9s" [statusC]="%-14s" [lastTrajC]="%-12s" )

#declare -A HEADER_PRINTF_PARAMETER_ARRAY=( [muC]="\"mu\"" [kC]="\"kappa\"" [ntC]="\"nt\"" [nsC]="\"ns\"" [betaC]="\"beta_chain_type\"" [trajNoC]="\"trajNo\"" \
#											[accRateC]="\"acc\"" [statusC]="\"status\"" [lastTrajC]="\"l.T.[s]\"" )
declare -A HEADER_PRINTF_PARAMETER_ARRAY=( [muC]="mu" [kC]="kappa" [ntC]="nt" [nsC]="ns" [betaC]="beta_chain_type" [trajNoC]="trajNo" \
											[accRateC]="acc" [statusC]="status" [lastTrajC]="l.T.[s]" )

declare -a NR_OF_COLUMNS_TO_DISPLAY_IN_ORDER
declare -a NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER

CUSTOMIZE_COLUMNS="FALSE"

STATISTICS_SUMMARY="FALSE"

UPDATE="FALSE"

FILTER_MU="FALSE"	
FILTER_KAPPA="FALSE"	
FILTER_NT="FALSE"	
FILTER_NS="FALSE"	
FILTER_BETA="FALSE"	
FILTER_TYPE="FALSE"
FILTER_TRAJNO="FALSE"	
FILTER_ACCRATE="FALSE"	
FILTER_STATUS="FALSE"	
FILTER_LASTTRAJ="FALSE"

declare -a MU_ARRAY
declare -a KAPPA_ARRAY
declare -a NS_ARRAY
declare -a NT_ARRAY
declare -a BETA_ARRAY
declare -a TYPE_ARRAY
declare -a STATUS_ARRAY

TRAJ_LOW_VALUE=""
TRAJ_HIGH_VALUE=""

ACCRATE_LOW_VALUE=""
ACCRATE_HIGH_VALUE=""

LAST_TRAJ_TIME=""

UPDATE_FREQUENCY=""

while [ $# -gt 0 ]; do
	case $1 in
		-c | --columns)
			OPTION=$1
			UPDATE="FALSE"
			CUSTOMIZE_COLUMNS="TRUE"
			while [[ "$2" =~ ^[^-] ]]; do
				case $2 in
					mu)
						NR_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( ${COLUMNS[muC]} )
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( muC )
						shift
						;;
					kappa)
						NR_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( ${COLUMNS[kC]} )
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( kC )
						shift
						;;
					nt)
						NR_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( ${COLUMNS[ntC]} )
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( ntC )
						shift
						;;
					ns)
						NR_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( ${COLUMNS[nsC]} )
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( nsC )
						shift
						;;
					beta_chain_type)
						NR_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( ${COLUMNS[betaC]} )
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( betaC )
						shift
						;;
					trajNo)
						NR_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( ${COLUMNS[trajNoC]} )
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( trajNoC )
						shift
						;;
					acc)
						NR_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( ${COLUMNS[accRateC]} )
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( accRateC )
						shift
						;;
					status)
						NR_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( ${COLUMNS[statusC]} )
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( statusC )
						shift
						;;
					lastTraj)
						NR_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( ${COLUMNS[lastTrajC]} )
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( lastTrajC )
						shift
						;;
					*)
						echo "$0: $OPTION: $2: unrecognized option...exiting"
						shift
						;;
				esac	
			done
			;;
		--sum)
			STATISTICS_SUMMARY="TRUE"
			;;
		--mu)
			UPDATE="FALSE"
			FILTER_MU="TRUE"
			while [[ $2 =~ ^[^-] ]];do
				case $2 in 
					0)
						MU_ARRAY+=( 0 )
						shift
						;;
					PiT)
						MU_ARRAY+=( PiT )
						shift
						;;
					*)
						echo "$0: $1: $2: unrecognized option."
						shift
				esac
			done
			[ ${#MU_ARRAY[@]} -eq 0 ] && echo "You did not correctly specify filtering values, hence no filtering on mu will be applied." && FILTER_MU="FALSE"
			;;
		--kappa)
			UPDATE="FALSE"
			FILTER_KAPPA="TRUE"
			while [[ $2 =~ ^[[:digit:]]{4}$ ]]; do 
				KAPPA_ARRAY+=( $2 )
				shift
			done
			[ ${#KAPPA_ARRAY[@]} -eq 0 ] && echo "You did not correctly specify filtering values, hence no filtering on kappa will be applied." && FILTER_KAPPA="FALSE"
			;;
		--nt)
			UPDATE="FALSE"
			FILTER_NT="TRUE"
			while [[ $2 =~ ^[[:digit:]]{1,2}$ ]]; do 
				NT_ARRAY+=( $2 )
				shift
			done
			[ ${#NT_ARRAY[@]} -eq 0 ] && echo "You did not correctly specify filtering values, hence no filtering on nt will be applied." && FILTER_NT="FALSE"
			;;
		--ns)
			UPDATE="FALSE"
			FILTER_NS="TRUE"
			while [[ $2 =~ ^[[:digit:]]{1,2}$ ]]; do 
				NS_ARRAY+=( $2 )
				shift
			done
			[ ${#NS_ARRAY[@]} -eq 0 ] && echo "You did not correctly specify filtering values, hence no filtering on ns will be applied." && FILTER_NS="FALSE"
			;;
		--beta)
			UPDATE="FALSE"
			FILTER_BETA="TRUE"	
			while [[ $2 =~ ^[[:digit:]]\.[[:digit:]]{4}$ ]]; do 
				BETA_ARRAY+=( $2 )
				shift
			done
			[ ${#BETA_ARRAY[@]} -eq 0 ] && echo "You did not correctly specify filtering values, hence no filtering on beta will be applied." && FILTER_BETA="FALSE"
			;;
		--type)
			UPDATE="FALSE"
			FILTER_TYPE="TRUE"	
			while [[ $2 =~ ^[^-] ]];do
				case $2 in 
					fC)
						TYPE_ARRAY+=( fC )
						shift
						;;
					fH)
						TYPE_ARRAY+=( fH )
						shift
						;;
					NC)
						TYPE_ARRAY+=( NC )
						shift
						;;
					*)
						echo "$0: $1: $2: unrecognized option."
						shift
				esac
			done
			[ ${#TYPE_ARRAY[@]} -eq 0 ] && echo "You did not correctly specify filtering values, hence no filtering on the status will be applied." && FILTER_TYPE="FALSE"
			;;
		--traj)
			UPDATE="FALSE"
			FILTER_TRAJNO="TRUE"
			while [[ $2 =~ ^[\>|\<][[:digit:]]+ ]];do
				[[ $2 =~ ^\>[[:digit:]]+ ]] && TRAJ_LOW_VALUE=${2#\>*}
				[[ $2 =~ ^\<[[:digit:]]+ ]] && TRAJ_HIGH_VALUE=${2#\<*}
				shift
			done
			[ "$TRAJ_LOW_VALUE" = "" ] && [ "$TRAJ_HIGH_VALUE" = "" ] && echo "You did not correctly specify filtering values, hence no filtering on the trajectory number will be applied." && FILTER_TRAJNO="FALSE"
			;;
		--acc)
			UPDATE="FALSE"
			FILTER_ACCRATE="TRUE"
			while [[ $2 =~ ^[\>|\<][[:digit:]]+\.[[:digit:]]+ ]];do
				[[ $2 =~ ^\>[[:digit:]]+ ]] && ACCRATE_LOW_VALUE=${2#\>*}
				[[ $2 =~ ^\<[[:digit:]]+ ]] && ACCRATE_HIGH_VALUE=${2#\<*}
				shift
			done
			[ "$ACCRATE_LOW_VALUE" = "" ] && [ "$ACCRATE_HIGH_VALUE" = "" ] && echo "You did not correctly specify filtering values, hence no filtering on the acceptance rate number will be applied." && FILTER_ACCRATE="FALSE"
			;;
		--status)
			UPDATE="FALSE"
			FILTER_STATUS="TRUE"	
			while [[ $2 =~ ^[^-] ]];do
				case $2 in 
					RUNNING)
						STATUS_ARRAY+=( RUNNING )
						shift
						;;
					PENDING)
						STATUS_ARRAY+=( PENDING )
						shift
						;;
					notQueued)
						STATUS_ARRAY+=( notQueued )
						shift
						;;
					*)
						echo "$0: $1: $2: unrecognized option."
						shift
				esac
			done
			[ ${#STATUS_ARRAY[@]} -eq 0 ] && echo "You did not correctly specify filtering values, hence no filtering on the status will be applied." && FILTER_STATUS="FALSE"
			;;
		--lastTraj)
			UPDATE="FALSE"
			FILTER_LASTTRAJ="TRUE"
			if [[ "$2" =~ ^[[:digit:]]+ ]]; then
				LAST_TRAJ_TIME=$2
				shift
			fi
			[ "$LAST_TRAJ_TIME" = "" ] && echo "You did not correctly specify the time value, hence no filtering on the last trajectory time will be applied...exiting." && exit 
			;;
		-u | --update)
			if [[ $2 =~ [[:digit:]]+[s|m|h|d] ]]; then
				UPDATE_FREQUENCY=$2
				shift
			fi
			UPDATE="TRUE"
			;;
		-f | --file)
			case $2 in
				-*)
					echo "$0: $1: $2: invalid file name specified...exiting."
					echo "            --> Filenames starting with - are not permissible."
					exit
					;;
			esac
			PROJECT_STATISTICS_FILE=$2
			FILE_WITH_PATHS=$2
			shift
			;;
		-h | --help)
			echo "Displaying options:"
			echo ""
			echo "-c | --columns --> Specify the columns to be displayed."
		   	echo "               --> Possible columns are: mu, kappa, nt, ns, beta_chain_type, trajNo, acc, status, lastTraj."
		   	echo "               --> Example: -c kappa nt ns beta_chain_type trajNo."
			echo "               --> If no columns are specified, all of the above columns will be printed by default."
			echo "--color        --> Specifiy this option for displaying coloured output.(NOT YET IMPLEMENTED)"
			echo "--sum          --> Summing up the trajectory numbers of each parameter set."
			echo ""
			echo "Filtering:"
			echo ""
			echo "--mu           --> Specify filtering values for mu."
			echo "--kappa        --> Specify filtering values for kappa."
			echo "--nt           --> Specify filtering values for nt."
			echo "--ns           --> Specify filtering values for ns."
			echo "--beta         --> Specify filtering values for beta."
			echo "--type         --> Specify filtering values for the type of the simulation, i.e whether it is NC, fC or fH"
			echo "--traj         --> Specify either a minimal or a maximal value or both for the trajectory number to be filtered for."
			echo "               --> E.g. --traj \">10000\" \"<50000\" (DON'T FORGET THE QUOTES.)"
			echo "--acc          --> Specify either a minimal or a maximal value or both for the acceptance rate to be filtered for."
			echo "               --> E.g. --acc \">50.23\" \"<80.1\" (The value is in percentage. DON'T FORGET THE QUOTES.)"
			echo "--status       --> Specify status value for the corresponding simulation."
			echo "               --> Possible values are: RUNNING, PENDING, notQueued."
			echo "--lastTraj     --> Specify a value in seconds. If the specified value exceeds the value of the field, the record is not printed."
			echo "               --> Use this when you want to scan for crashed simulations."
			echo ""
			echo "Updating database:"
			echo ""
			echo "-u | --update  --> Specify this option to update the file $PROJECT_STATISTICS_FILE."
			echo "               --> This option is incompatible with any other option."
			echo "               --> Optionally a frequency can be specified with which the script performs a database update."
			echo "                   The frequency is a number followed by s = seconds, m = minutes, h = hours, d = days, e.g. --update 2h."
		    echo "                   In this case it is best to start the script in a screen session and to let it run in the background."	
			echo "General options:"
			echo ""
			echo "-f | --file    --> This option can be specified for both, the updating of the database as well as the displaying and filtering of the data."
			echo "               --> For displaying and filtering of the data the default file name is $PROJECT_STATISTICS_FILE ."
			echo "               --> Use it for updating if you want the script to read in the directories from a file. In this case the file should contain the paths to "
			echo "                   specific nsXX directories. The default filename is $FILE_WITH_PATHS ."
			echo "               --> (NOT YET IMPLEMENTED: Not specifying this option, the script will use $FILE_WITH_PATHS.) If no filename is specified for the updating procedure,"
			echo "                   the script will search via find for all nsXX directories."
			echo "               --> Filenames starting with - are not permissible."
			exit
			;;
		-*)
			echo "$0: $1: unrecognized option...exiting"
			exit
			;;
		*)
			echo "$0: $1: unrecognized option...exiting"
			exit
			;;
	esac
	shift
done

MU_STRING=$(join "|" "${MU_ARRAY[@]}")
KAPPA_STRING=$(join "|" "${KAPPA_ARRAY[@]}")
NS_STRING=$(join "|" "${NS_ARRAY[@]}")
NT_STRING=$(join "|" "${NT_ARRAY[@]}")
BETA_STRING=$(join "|" "${BETA_ARRAY[@]}")
TYPE_STRING=$(join "|" "${TYPE_ARRAY[@]}")
STATUS_STRING=$(join "|" "${STATUS_ARRAY[@]}")

[ "$FILTER_TRAJNO" = "TRUE" ] && [ "$TRAJ_LOW_VALUE" = "" ]  && TRAJ_LOW_VALUE=0
[ "$FILTER_TRAJNO" = "TRUE" ] && [ "$TRAJ_HIGH_VALUE" = "" ]  && TRAJ_HIGH_VALUE=9999999

[ "$FILTER_ACCRATE" = "TRUE" ] && [ "$ACCRATE_LOW_VALUE" = "" ]  && ACCRATE_LOW_VALUE=0.0
[ "$FILTER_ACCRATE" = "TRUE" ] && [ "$ACCRATE_HIGH_VALUE" = "" ]  && ACCRATE_HIGH_VALUE=100.00



if [ "$CUSTOMIZE_COLUMNS" = "FALSE" ]; then
	NR_OF_COLUMNS_TO_DISPLAY_IN_ORDER=( ${COLUMNS[muC]} ${COLUMNS[kC]} ${COLUMNS[ntC]} ${COLUMNS[nsC]} ${COLUMNS[betaC]} ${COLUMNS[trajNoC]} ${COLUMNS[accRateC]} ${COLUMNS[statusC]} ${COLUMNS[lastTrajC]} )
	NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER=( muC kC ntC nsC betaC trajNoC accRateC statusC lastTrajC )
fi

HEADER_ROW_SEPARATOR="\"$HEADER_ROW_SEPARATOR\""

[ "$UPDATE" = "FALSE" ] && [ ! -f $PROJECT_STATISTICS_FILE ] && echo "$PROJECT_STATISTICS_FILE does not exist. Call $0 -u to create it...exiting." && exit

if [ "$UPDATE" = "FALSE" ]; then

	
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

	NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN=""
	for NAME_OF_COLUMN in ${NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER[@]}; do
			[ "$NAME_OF_COLUMN" = "trajNoC" ] && break
			NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN=$(($NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN+${FSNA[$NAME_OF_COLUMN]}+1))
	done
	NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN=$((NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN+7))
	STATISTICS_PRINTF_FORMAT_SPECIFIER_STRING="%${NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN}s\n"
	echo nr of whitespaces $NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN

	#STRIPPING OF THE LAST | SYMBOL FROM THE STRING
	NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL=$(echo ${NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL%"|"})
	NAME_OF_COLUMN_NR_OF_COLUMN_STRING=$(echo ${NAME_OF_COLUMN_NR_OF_COLUMN_STRING%"|"})
	NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING=$(echo ${NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING%"|"})
	NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING=$(echo ${NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING%"|"})
	NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING=$(echo ${NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING%"|"})

	awk --posix -v filterMu=$FILTER_MU -v filterKappa=$FILTER_KAPPA -v filterNt=$FILTER_NT -v filterNs=$FILTER_NS \
				-v filterBeta=$FILTER_BETA -v filterType=$FILTER_TYPE \
				-v filterTrajNo=$FILTER_TRAJNO -v filterAccRate=$FILTER_ACCRATE -v filterStatus=$FILTER_STATUS -v filterLastTrajTime=$FILTER_LASTTRAJ \
				-v statisticsSummary=$STATISTICS_SUMMARY \
				-v muString="$MU_STRING" -v kappaString="$KAPPA_STRING" -v nsString="$NS_STRING" -v ntString="$NT_STRING" -v betaString="$BETA_STRING" \
				-v typeString=$TYPE_STRING -v statusString="$STATUS_STRING" \
				-v trajLowValue=$TRAJ_LOW_VALUE -v trajHighValue=$TRAJ_HIGH_VALUE -v accRateLowValue=$ACCRATE_LOW_VALUE \
				-v accRateHighValue=$ACCRATE_HIGH_VALUE -v lastTrajTime=$LAST_TRAJ_TIME \
				-v nameOfColumnsAndNumberOfColumnsString=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING__ALL \
				-v nameOfDisplayedColumnsAndnrOfDisplayedColumnsString=$NAME_OF_COLUMN_NR_OF_COLUMN_STRING \
				-v nameOfDisplayedColumnsAndSpecOfColumnsString=$NAME_OF_COLUMN_SPEC_OF_COLUMN_STRING \
				-v nameOfColumnsAndHeaderOfColumnsString=$NAME_OF_COLUMN_HEADER_OF_COLUMN_STRING \
				-v nameOfColumnsAndHeaderSpecOfColumnsString=$NAME_OF_COLUMN_HEADER_SPEC_OF_COLUMN_STRING \
				-v statisticsFormatSpecString=$STATISTICS_PRINTF_FORMAT_SPECIFIER_STRING \
				-v lengthOfHeaderSeperator=$LENGTH_OF_HEADER_SEPERATOR '

					 BEGIN{
					 print statisticsFormatSpecString
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
						printf(" "); #THIS PRINTF IS IMPORTANT TO GET THE HEADER IN TO THE RIGHT PLACE
						for(i=1;i<=nrOfDisplayedColumns;i++){
							split(columnNamesAndHeaderArray[i],columnAndHeader,"-");
							split(columnNamesAndHeaderSpecArray[i],columnAndHeaderSpec,"--");
							specifierString=columnAndHeaderSpec[2];
							printf(specifierString,columnAndHeader[2]);
						}
						printf("\n");
						for(i=1;i<=lengthOfHeaderSeperator;i++){
							printf("-");
						}
						printf("\n");
					 }
					 {critFailedCounter=0}

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

					 filterLastTrajTime == "TRUE" {if(lastTrajTime > $(columnNameColumnNumber["lastTrajC"]) || $(columnNameColumnNumber["lastTrajC"]) == "------"){critFailedCounter--;}}
					 
					 statisticsSummary == "FALSE" && critFailedCounter == 0 {
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

					 #SUMMARY OF STATISTICS
					 statisticsSummary == "TRUE" {
						split($(columnNameColumnNumber["betaC"]),betaChainType,"_");
						if(betaChainType[3] == "NC"){
							statisticsSummaryArray[$(columnNameColumnNumber["muC"]) "_" $(columnNameColumnNumber["kC"]) "_" $(columnNameColumnNumber["ntC"]) "_" $(columnNameColumnNumber["nsC"]) "_" betaChainType[1] "_" betaChainType[3]]+=$(columnNameColumnNumber["trajNoC"]);
						}
					}

					END{
						if(statisticsSummary == "TRUE"){
							split(dataRowArray[1],fieldsArray," ");
							split(fieldsArray[columnNameColumnNumber["betaC"]],betaChainType,"_");

							if(betaChainType[3] == "NC"){
								oldKey = fieldsArray[columnNameColumnNumber["muC"]] "_" fieldsArray[columnNameColumnNumber["kC"]] "_" fieldsArray[columnNameColumnNumber["ntC"]] "_" \
								fieldsArray[columnNameColumnNumber["nsC"]] "_" betaChainType[1] "_" betaChainType[3];
							}

							for(i=1;i<=lineCounter;i++){
								split(dataRowArray[i],fieldsArray," ");	
								split(fieldsArray[columnNameColumnNumber["betaC"]],betaChainType,"_");
								if(betaChainType[3] == "NC"){
									newKey = fieldsArray[columnNameColumnNumber["muC"]] "_" fieldsArray[columnNameColumnNumber["kC"]] "_" fieldsArray[columnNameColumnNumber["ntC"]] "_" \
									fieldsArray[columnNameColumnNumber["nsC"]] "_" betaChainType[1] "_" betaChainType[3]
								}

								if(betaChainType[3] == "NC"){
									if(newKey != oldKey){
										printf(statisticsFormatSpecString,statisticsSummaryArray[oldKey]); 
										oldKey=newKey;
									}
								}

								split(dataRowArray[i],columnsArray," ")
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
							printf(statisticsFormatSpecString,statisticsSummaryArray[newKey]);
						}
					}
		' $PROJECT_STATISTICS_FILE
fi


if [ "$UPDATE" = "TRUE" ]; then
	[ ! -f $FILE_WITH_PATHS ] && echo "$0: File $FILE_WITH_PATHS containing paths to the nsXX directories does not exist...exiting" && exit
	while :
	do
		while read line
		do
			if [[ "$line" =~ ^[^#] ]]; then 
				PARAMS=( $(echo $line | awk 'BEGIN{FS="/"}{print $(NF-3) " " $(NF-2) " " $(NF-1) " " $(NF)}') )
			else
				continue 
			fi
			
			if [ -d $line ]; then
				echo updating $line ...
				cd $line
			else
				continue
			fi
			${HOME}/Script/JobScriptAutomation/JobHandler.sh -l | \
			sed -r 's/[^(\x1b)]\[|\]|\(|\)|%//g' | \
			sed -r 's/(\x1B\[[[:digit:]]{1,2};[[:digit:]]{0,2};[[:digit:]]{0,2}m)(.)/\1 \2/g' | \
			sed -r 's/(.)(\x1B\[.{1,2};.{1,2}m)/\1 \2/g' | \
			sed -r 's/(\x1B\[.{1,2};.{1,2}m)(.)/\1 \2/g' |
			awk --posix -v mu=${PARAMS[0]#mui*} -v k=${PARAMS[1]#k*} -v nt=${PARAMS[2]#nt*} -v ns=${PARAMS[3]#*ns} '

							$3 ~ /^[[:digit:]]\.[[:digit:]]{4}/{
								print $(3-1) " " mu " " $(3-1) " " k " " $(3-1) " " nt " " $(3-1) " " ns " " $(3-1) " " $3 " " $(5-1) " " $5 " " $(8-1) " " $8 " " $(15-1) " " $15 " " $(19-1) " " $19 " " "\033[0m"
							}

						' >> $CURRENT_DIRECTORY/$TEMPORARY_STATISTICS_FILE

			cd $CURRENT_DIRECTORY
			echo updated $line ...
		done <$FILE_WITH_PATHS
		cp $TEMPORARY_STATISTICS_FILE $PROJECT_STATISTICS_FILE
		rm -f $TEMPORARY_STATISTICS_FILE

		if [ "$UPDATE_FREQUENCY" = "" ]; then 
			break 
		else 
			sleep $UPDATE_FREQUENCY 
		fi
	done
fi
