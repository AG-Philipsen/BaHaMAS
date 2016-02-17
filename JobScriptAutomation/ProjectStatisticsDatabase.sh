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

function projectStatisticsDatabase(){

local FILE_WITH_DIRECTORIES=""
local TEMPORARY_FILE_WITH_DIRECTORIES="temporaryFileWithDirectoriesForDatabaseUpdate.dat"
local TEMPORARY_DATABASE_FILE="tmpDatabase.dat"
local SPECIFIED_PROJECT_DATABASE_FILE=$PROJECT_DATABASE_DIRECTORY/$(date +%d_%m_%y)_$PROJECT_DATABASE_FILENAME
local CURRENT_DIRECTORY=$(pwd)

rm -f $PROJECT_DATABASE_DIRECTORY/$TEMPORARY_DATABASE_FILE
rm -f $TEMPORARY_FILE_WITH_DIRECTORIES

MU_C=$((2*1)) 
K_C=$((2*2)) 
NT_C=$((2*3)) 
NS_C=$((2*4)) 
BETA_C=$((2*5)) 
TRAJNO_C=$((2*6)) 
ACCRATE_C=$((2*7)) 
STATUS_C=$((2*8)) 
LASTTRAJ_C=$((2*9))

declare -A COLUMNS=( [muC]=$MU_C [kC]=$K_C [ntC]=$NT_C [nsC]=$NS_C [betaC]=$BETA_C [trajNoC]=$TRAJNO_C [accRateC]=$ACCRATE_C [statusC]=$STATUS_C [lastTrajC]=$LASTTRAJ_C )

#FSNA = FORMAT_SPECIFIER_NUMBER_ARRAY
declare -A FSNA=( [muC]="7" [kC]="8" [ntC]="6" [nsC]="6" [betaC]="19" [trajNoC]="11" [accRateC]="8" [statusC]="13" [lastTrajC]="11" )

declare -A PRINTF_FORMAT_SPECIFIER_ARRAY=( [muC]="%-${FSNA[muC]}s" [kC]="%-${FSNA[kC]}s" [ntC]="%-${FSNA[ntC]}d" [nsC]="%-${FSNA[nsC]}d" [betaC]="%-${FSNA[betaC]}s" \
											[trajNoC]="%-${FSNA[trajNoC]}d" [accRateC]="%-${FSNA[accRateC]}s" [statusC]="%-${FSNA[statusC]}s" [lastTrajC]="%-${FSNA[lastTrajC]}s" )

declare -A HEADER_PRINTF_FORMAT_SPECIFIER_ARRAY=( [muC]="%-8s" [kC]="%-9s" [ntC]="%-7s" [nsC]="%-7s" [betaC]="%-20s" [trajNoC]="%-12s" [accRateC]="%-9s" [statusC]="%-14s" [lastTrajC]="%-12s" )

[ $WILSON = "TRUE" ] && MASS_PARAMETER="kappa"
[ $STAGGERED = "TRUE" ] && MASS_PARAMETER="mass"

declare -A HEADER_PRINTF_PARAMETER_ARRAY=( [muC]="mu" [kC]=$MASS_PARAMETER [ntC]="nt" [nsC]="ns" [betaC]="beta_chain_type" [trajNoC]="trajNo" \
											[accRateC]="acc" [statusC]="status" [lastTrajC]="l.T.[s]" )

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

local READ_DIRECTORIES_FROM_FILE="FALSE"
local FILTER_SPECIFIC_DATABASE_FILE="FALSE"

local FILTER_MU="FALSE"	
local FILTER_KAPPA="FALSE"	
local FILTER_NT="FALSE"	
local FILTER_NS="FALSE"	
local FILTER_BETA="FALSE"	
local FILTER_TYPE="FALSE"
local FILTER_TRAJNO="FALSE"	
local FILTER_ACCRATE="FALSE"	
local FILTER_STATUS="FALSE"	
local FILTER_LASTTRAJ="FALSE"

declare -a local MU_ARRAY
declare -a local KAPPA_ARRAY
declare -a local NS_ARRAY
declare -a local NT_ARRAY
declare -a local BETA_ARRAY
declare -a local TYPE_ARRAY
declare -a local STATUS_ARRAY

local TRAJ_LOW_VALUE=""
local TRAJ_HIGH_VALUE=""

local ACCRATE_LOW_VALUE=""
local ACCRATE_HIGH_VALUE=""

local LAST_TRAJ_TIME=""

local UPDATE_FREQUENCY=""

while [ $# -gt 0 ]; do
	case $1 in
		-c | --columns)
			OPTION=$1
			UPDATE="FALSE"
			CUSTOMIZE_COLUMNS="TRUE"
			while [[ "$2" =~ ^[^-] ]]; do
				case $2 in
					mu)
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( muC )
						shift
						;;
					$MASS_PARAMETER)
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( kC )
						shift
						;;
					nt)
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( ntC )
						shift
						;;
					ns)
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( nsC )
						shift
						;;
					beta_chain_type)
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( betaC )
						shift
						;;
					trajNo)
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( trajNoC )
						shift
						;;
					acc)
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( accRateC )
						shift
						;;
					status)
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( statusC )
						shift
						;;
					lastTraj)
						NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER+=( lastTrajC )
						shift
						;;
					*)
						echo "$0: $OPTION: $2: unrecognized option...exiting"
						return
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
			[ ${#MU_ARRAY[@]} -eq 0 ] && echo "You did not correctly specify filtering values, hence no filtering on mu will be applied." && FILTER_MU="FALSE" && return
			;;
		--$MASS_PARAMETER)
			UPDATE="FALSE"
			FILTER_KAPPA="TRUE"
			while [[ $2 =~ ^[[:digit:]]{4}$ ]]; do 
				KAPPA_ARRAY+=( $2 )
				shift
			done
			[ ${#KAPPA_ARRAY[@]} -eq 0 ] && echo "You did not correctly specify filtering values, hence no filtering on $MASS_PARAMETER will be applied." && FILTER_KAPPA="FALSE" && return
			;;
		--nt)
			UPDATE="FALSE"
			FILTER_NT="TRUE"
			while [[ $2 =~ ^[[:digit:]]{1,2}$ ]]; do 
				NT_ARRAY+=( $2 )
				shift
			done
			[ ${#NT_ARRAY[@]} -eq 0 ] && echo "You did not correctly specify filtering values, hence no filtering on nt will be applied." && FILTER_NT="FALSE" && return
			;;
		--ns)
			UPDATE="FALSE"
			FILTER_NS="TRUE"
			while [[ $2 =~ ^[[:digit:]]{1,2}$ ]]; do 
				NS_ARRAY+=( $2 )
				shift
			done
			[ ${#NS_ARRAY[@]} -eq 0 ] && echo "You did not correctly specify filtering values, hence no filtering on ns will be applied." && FILTER_NS="FALSE" && return
			;;
		--beta)
			UPDATE="FALSE"
			FILTER_BETA="TRUE"	
			while [[ $2 =~ ^[[:digit:]]\.[[:digit:]]{4}$ ]]; do 
				BETA_ARRAY+=( $2 )
				shift
			done
			[ ${#BETA_ARRAY[@]} -eq 0 ] && echo "You did not correctly specify filtering values, hence no filtering on beta will be applied." && FILTER_BETA="FALSE" && return
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
						echo "$0: $1: $2: unrecognized option...exiting" && return
						shift
				esac
			done
			[ ${#TYPE_ARRAY[@]} -eq 0 ] && echo "You did not correctly specify filtering values, hence no filtering on the status will be applied." && FILTER_TYPE="FALSE" && return
			;;
		--traj)
			UPDATE="FALSE"
			FILTER_TRAJNO="TRUE"
			while [[ $2 =~ ^[\>|\<][[:digit:]]+ ]];do
				[[ $2 =~ ^\>[[:digit:]]+ ]] && TRAJ_LOW_VALUE=${2#\>*}
				[[ $2 =~ ^\<[[:digit:]]+ ]] && TRAJ_HIGH_VALUE=${2#\<*}
				shift
			done
			[ "$TRAJ_LOW_VALUE" = "" ] && [ "$TRAJ_HIGH_VALUE" = "" ] && echo "You did not correctly specify filtering values, hence no filtering on the trajectory number will be applied." && FILTER_TRAJNO="FALSE" && return
			;;
		--acc)
			UPDATE="FALSE"
			FILTER_ACCRATE="TRUE"
			while [[ $2 =~ ^[\>|\<][[:digit:]]+\.[[:digit:]]+ ]];do
				[[ $2 =~ ^\>[[:digit:]]+ ]] && ACCRATE_LOW_VALUE=${2#\>*}
				[[ $2 =~ ^\<[[:digit:]]+ ]] && ACCRATE_HIGH_VALUE=${2#\<*}
				shift
			done
			[ "$ACCRATE_LOW_VALUE" = "" ] && [ "$ACCRATE_HIGH_VALUE" = "" ] && echo "You did not correctly specify filtering values, hence no filtering on the acceptance rate number will be applied." && FILTER_ACCRATE="FALSE" && return
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
						echo "$0: $1: $2: unrecognized option...exiting" && return
						shift
				esac
			done
			[ ${#STATUS_ARRAY[@]} -eq 0 ] && echo "You did not correctly specify filtering values, hence no filtering on the status will be applied." && FILTER_STATUS="FALSE" && return
			;;
		--lastTraj)
			UPDATE="FALSE"
			FILTER_LASTTRAJ="TRUE"
			if [[ "$2" =~ ^[[:digit:]]+ ]]; then
				LAST_TRAJ_TIME=$2
				shift
			fi
			[ "$LAST_TRAJ_TIME" = "" ] && echo "You did not correctly specify the time value, hence no filtering on the last trajectory time will be applied...exiting." && return 
			;;
		-u | --update)
			if [[ $2 =~ [[:digit:]]+[s|m|h|d] ]]; then
				UPDATE_FREQUENCY=$2
				shift
			fi
			UPDATE="TRUE"
			;;
		-f | --file)
			READ_DIRECTORIES_FROM_FILE="TRUE"
			FILTER_SPECIFIC_DATABASE_FILE="TRUE"
			case $2 in
				-*)
					echo "$0: $1: $2: invalid file name specified...exiting."
					echo "            --> Filenames starting with - are not permissible."
					return
					;;
			esac
			[ "$UPDATE" = "FALSE" ] && SPECIFIED_PROJECT_DATABASE_FILE=$2
			[ "$UPDATE" = "TRUE" ] && FILE_WITH_DIRECTORIES=$2
			shift
			;;
		-h | --help)
			echo "Displaying options:"
			echo ""
			echo "-c | --columns --> Specify the columns to be displayed."
		   	echo "               --> Possible columns are: mu, $MASS_PARAMETER, nt, ns, beta_chain_type, trajNo, acc, status, lastTraj."
		   	echo "               --> Example: -c $MASS_PARAMETER nt ns beta_chain_type trajNo."
			echo "               --> If no columns are specified, all of the above columns will be printed by default."
			echo "--color        --> Specifiy this option for displaying coloured output.(NOT YET IMPLEMENTED)"
			echo "--sum          --> Summing up the trajectory numbers of each parameter set."
			echo ""
			echo "Filtering:"
			echo ""
			echo "--mu           --> Specify filtering values for mu."
			echo "--$MASS_PARAMETER        --> Specify filtering values for $MASS_PARAMETER."
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
			echo "-u | --update  --> Specify this option to (re)create the file $SPECIFIED_PROJECT_DATABASE_FILE."
			echo "               --> This option is incompatible with any other option."
			echo "               --> Optionally a frequency can be specified at which the script performs a database update."
			echo "                   The frequency is a number followed by s = seconds, m = minutes, h = hours, d = days, e.g. --update 2h."
		    echo "                   In this case it is best to start the script in a screen session and to let it run in the background."	
			echo "General options:"
			echo ""
			echo "-f | --file    --> This option can be specified for both, the updating of the database as well as the displaying and filtering of the data."
			echo ""
			echo "               --> Updating:"
			echo "               --> If you don't wish the script to simply search for all directories containing data, use this option to specify a file with directories (abosulte paths)"
			echo "               --> in which the script looks for data."
			echo ""
			echo "               --> Displaying and Filtering:"
			echo "               --> If you don't wish the script to use the latest database file, use this option to specify a file to display and filter."
			return
			;;
		-*)
			echo "$0: $1: unrecognized option...exiting"
			return
			;;
		*)
			echo "$0: $1: unrecognized option...exiting"
			return
			;;
	esac
	shift
done

if [ "$UPDATE" = "FALSE" ] && [ ! -f $SPECIFIED_PROJECT_DATABASE_FILE ] && [ $FILTER_SPECIFIC_DATABASE_FILE = "FALSE" ]; then
	echo "Found no up to date database file with date $(date +%d_%m_%y). Looking for older versions..."
	LATEST_DATABASE_FILE=$(ls $PROJECT_DATABASE_DIRECTORY | grep -E [[:digit:]]{2}_[[:digit:]]{2}_[[:digit:]]{2}_projectStatistics.dat | sort -t "_" -k 3,3 -k 2,2 -k 1,1 | tail -n1)
	[ $LATEST_DATABASE_FILE = "" ] && echo "No older database versions found...exiting." && return
	echo "Found older version: $LATEST_DATABASE_FILE"
	SPECIFIED_PROJECT_DATABASE_FILE=$PROJECT_DATABASE_DIRECTORY/$LATEST_DATABASE_FILE
elif [ "$UPDATE" = "FALSE" ] && [ ! -f $SPECIFIED_PROJECT_DATABASE_FILE ] && [ $FILTER_SPECIFIC_DATABASE_FILE = "TRUE" ]; then
	echo "$SPECIFIED_PROJECT_DATABASE_FILE does not exist....exiting." 
	return
fi

if [ "$UPDATE" = "FALSE" ]; then

	echo "Current database file: $SPECIFIED_PROJECT_DATABASE_FILE"

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
		NAME_OF_COLUMNS_TO_DISPLAY_IN_ORDER=( muC kC ntC nsC betaC trajNoC accRateC statusC lastTrajC )
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
	NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN=$((NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN+7))
	STATISTICS_PRINTF_FORMAT_SPECIFIER_STRING="%${NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN}s\n"

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

					 ######################################################################## FILTERING PART BEGIN ############################################################################
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
					 ######################################################################### FILTERING PART END #############################################################################


					 ######################################################################### SUMMARY OF STATISTICS ##########################################################################
					 statisticsSummary == "TRUE" {
						split($(columnNameColumnNumber["betaC"]),betaChainType,"_");
						if(betaChainType[3] == "NC"){
							statisticsSummaryArray[$(columnNameColumnNumber["muC"]) "_" $(columnNameColumnNumber["kC"]) "_" $(columnNameColumnNumber["ntC"]) "_" \
							$(columnNameColumnNumber["nsC"]) "_" betaChainType[1] "_" betaChainType[3]]+=$(columnNameColumnNumber["trajNoC"]);
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
		' $SPECIFIED_PROJECT_DATABASE_FILE
fi


if [ "$UPDATE" = "TRUE" ]; then

	REGEX_STRING=".*/"
	for i in $(seq 0 3); do
		REGEX_STRING=$REGEX_STRING${PARAMETER_PREFIXES[$i]}${PARAMETER_REGEXES[$i]}/
	done
	REGEX_STRING=${REGEX_STRING%/}		


	while :
	do
		[ "$READ_DIRECTORIES_FROM_FILE" = "FALSE" ] && find $HOME_DIR/$SIMULATION_PATH -regextype grep -regex "$REGEX_STRING" > $TEMPORARY_FILE_WITH_DIRECTORIES
		[ "$READ_DIRECTORIES_FROM_FILE" = "TRUE" ] && cat $FILE_WITH_DIRECTORIES > $TEMPORARY_FILE_WITH_DIRECTORIES

		while read line
		do
			echo line: $line
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

			PARAMETER_DIRECTORY_STRUCTURE=${line##*$SIMULATION_PATH}

			ListJobStatus_Loewe $PARAMETER_DIRECTORY_STRUCTURE | \
			sed -r 's/[^(\x1b)]\[|\]|\(|\)|%//g' | \
			sed -r 's/(\x1B\[[[:digit:]]{1,2};[[:digit:]]{0,2};[[:digit:]]{0,3}m)(.)/\1 \2/g' | \
			sed -r 's/(.)(\x1B\[.{1,2};.{1,2}m)/\1 \2/g' | \
			sed -r 's/(\x1B\[.{1,2};.{1,2}m)(.)/\1 \2/g' |
			awk --posix -v mu=${PARAMS[0]#mui*} -v k=${PARAMS[1]#$KAPPA_PREFIX*} -v nt=${PARAMS[2]#nt*} -v ns=${PARAMS[3]#*ns} '

							$3 ~ /^[[:digit:]]\.[[:digit:]]{4}/{
								print $(3-1) " " mu " " $(3-1) " " k " " $(3-1) " " nt " " $(3-1) " " ns " " $(3-1) " " $3 " " $(5-1) " " $5 " " $(8-1) " " $8 " " $(15-1) " " $15 " " $(19-1) " " $19 " " "\033[0m"
							}
						' >> $PROJECT_DATABASE_DIRECTORY/$TEMPORARY_DATABASE_FILE

			cd $CURRENT_DIRECTORY
			echo updated $line ...
		done < <(cat $TEMPORARY_FILE_WITH_DIRECTORIES)

		[ "$(wc -l $PROJECT_DATABASE_DIRECTORY/$TEMPORARY_DATABASE_FILE | awk '{print $1}')" -eq 0 ] && echo "Empty database, please investigate...exiting." && return

		cp $PROJECT_DATABASE_DIRECTORY/$TEMPORARY_DATABASE_FILE $SPECIFIED_PROJECT_DATABASE_FILE

		#Clean up
		rm $PROJECT_DATABASE_DIRECTORY/$TEMPORARY_DATABASE_FILE
		rm $TEMPORARY_FILE_WITH_DIRECTORIES

		if [ "$UPDATE_FREQUENCY" = "" ]; then 
			break 
		else 
			sleep $UPDATE_FREQUENCY 
		fi
	done
fi

}
