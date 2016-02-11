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

MU_C=1 
K_C=2 
NT_C=3 
NS_C=4 
BETA_C=5 
TRAJNO_C=6 
ACCRATE_C=7 
STATUS_C=8 

PRINTF_FORMAT_SPECIFIER_STRING=""
PRINTF_PARAMETER_STRING=""

HEADER_PRINTF_FORMAT_SPECIFIER_STRING=""
HEADER_PRINTF_PARAMETER_STRING=""
HEADER_ROW_SEPARATOR=""

declare -A COLUMNS=( [muC]=$MU_C [kC]=$K_C [ntC]=$NT_C [nsC]=$NS_C [betaC]=$BETA_C [trajNoC]=$TRAJNO_C [accRateC]=$ACCRATE_C [statusC]=$STATUS_C )

#FSNA = FORMAT_SPECIFIER_NUMBER_ARRAY
declare -A FSNA=( [muC]="7" [kC]="8" [ntC]="6" [nsC]="6" [betaC]="19" [trajNoC]="11" [accRateC]="8" [statusC]="13" )

declare -A PRINTF_FORMAT_SPECIFIER_ARRAY=( [muC]="%-${FSNA[muC]}s" [kC]="%-${FSNA[kC]}s" [ntC]="%-${FSNA[ntC]}d" [nsC]="%-${FSNA[nsC]}d" [betaC]="%-${FSNA[betaC]}s" \
											[trajNoC]="%-${FSNA[trajNoC]}d" [accRateC]="%-${FSNA[accRateC]}s" [statusC]="%-${FSNA[statusC]}s" )

declare -A HEADER_PRINTF_FORMAT_SPECIFIER_ARRAY=( [muC]="%-7s" [kC]="%-8s" [ntC]="%-6s" [nsC]="%-6s" [betaC]="%-19s" [trajNoC]="%-11s" [accRateC]="%-8s" [statusC]="%-13s" )

declare -A HEADER_PRINTF_PARAMETER_ARRAY=( [muC]="\"mu\"" [kC]="\"kappa\"" [ntC]="\"nt\"" [nsC]="\"ns\"" [betaC]="\"beta_chain_type\"" [trajNoC]="\"trajNo\"" \
											[accRateC]="\"acc\"" [statusC]="\"status\"" )

declare -a DISPLAY_COLUMNS

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
						DISPLAY_COLUMNS+=( ${COLUMNS[muC]} )
						shift
						;;
					kappa)
						DISPLAY_COLUMNS+=( ${COLUMNS[kC]} )
						shift
						;;
					nt)
						DISPLAY_COLUMNS+=( ${COLUMNS[ntC]} )
						shift
						;;
					ns)
						DISPLAY_COLUMNS+=( ${COLUMNS[nsC]} )
						shift
						;;
					beta_chain_type)
						DISPLAY_COLUMNS+=( ${COLUMNS[betaC]} )
						shift
						;;
					trajNo)
						DISPLAY_COLUMNS+=( ${COLUMNS[trajNoC]} )
						shift
						;;
					acc)
						DISPLAY_COLUMNS+=( ${COLUMNS[accRateC]} )
						shift
						;;
					status)
						DISPLAY_COLUMNS+=( ${COLUMNS[statusC]} )
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
		   	echo "               --> Possible columns are: mu, kappa, nt, ns, beta_chain_type, trajNo, acc, status."
		   	echo "               --> Example: -c kappa nt ns beta_chain_type trajNo."
			echo "               --> If no columns are specified, all of the above columns will be printed by default."
			echo "--color        --> Specifiy this option for displaying coloured output.(NOT YET IMPLEMENTED)"
			echo "--sum          --> Summing up the trajectory numbers of each parameter set."
			echo ""
			echo "Filtering:"
			echo ""
			echo "--mu           --> Specify a filtering values for mu."
			echo "--kappa        --> Specify a filtering values for kappa."
			echo "--nt           --> Specify a filtering values for nt."
			echo "--ns           --> Specify a filtering values for ns."
			echo "--beta         --> Specify a filtering values for beta."
			echo "--type         --> Specify a filtering values for the type of the simulation, i.e whether it is NC, fC or fH"
			echo "--traj         --> Specify either a minimal or a maximal value or both for the trajectory number to be filtered for."
			echo "               --> E.g. --traj \">10000\" \"<50000\" (DON'T FORGET THE QUOTES.)"
			echo "--acc          --> Specify either a minimal or a maximal value or both for the acceptance rate to be filtered for."
			echo "               --> E.g. --acc \">50.23\" \"<80.1\" (The value is in percentage. DON'T FORGET THE QUOTES.)"
			echo "--status       --> Specify status value for the corresponding simulation."
			echo "               --> Possible values are: RUNNING, PENDING, notQueued."
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
	DISPLAY_COLUMNS=( ${COLUMNS[muC]} ${COLUMNS[kC]} ${COLUMNS[ntC]} ${COLUMNS[nsC]} ${COLUMNS[betaC]} ${COLUMNS[trajNoC]} ${COLUMNS[accRateC]} ${COLUMNS[statusC]} )
fi

#This loop is necessary in order build the format specified and parameter string for the printf function invoked in awk.
for COLUMN_NUMBER in ${DISPLAY_COLUMNS[@]}; do 
	for QUANTITY in ${!COLUMNS[@]}; do
		if [ $COLUMN_NUMBER = ${COLUMNS[$QUANTITY]} ]; then

			HEADER_PRINTF_FORMAT_SPECIFIER_STRING=$HEADER_PRINTF_FORMAT_SPECIFIER_STRING${HEADER_PRINTF_FORMAT_SPECIFIER_ARRAY[$QUANTITY]}
			HEADER_PRINTF_PARAMETER_STRING=$HEADER_PRINTF_PARAMETER_STRING,${HEADER_PRINTF_PARAMETER_ARRAY[$QUANTITY]}
			
			PRINTF_FORMAT_SPECIFIER_STRING=$PRINTF_FORMAT_SPECIFIER_STRING${PRINTF_FORMAT_SPECIFIER_ARRAY[$QUANTITY]}
			PRINTF_PARAMETER_STRING=$PRINTF_PARAMETER_STRING,\$${COLUMNS[$QUANTITY]}

			for ((i=0;i<${FSNA[$QUANTITY]};i++)); do
				HEADER_ROW_SEPARATOR=$HEADER_ROW_SEPARATOR"-"
			done
		fi
	done
done

NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN=""
for COLUMN_NUMBER in ${DISPLAY_COLUMNS[@]}; do 
	for QUANTITY in ${!COLUMNS[@]}; do
		if [ $COLUMN_NUMBER = ${COLUMNS[$QUANTITY]} ]; then
			[ "$QUANTITY" = "trajNoC" ] && break 2
			NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN=$(($NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN+${FSNA[$QUANTITY]}))
		fi
	done
done

STATISTICS_PRINTF_FORMAT_SPECIFIER_STRING="%${NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN}s"
#echo nr of whitespaces $NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN

HEADER_ROW_SEPARATOR="\"$HEADER_ROW_SEPARATOR\""

[ "$UPDATE" = "FALSE" ] && [ ! -f $PROJECT_STATISTICS_FILE ] && echo "$PROJECT_STATISTICS_FILE does not exist. Call $0 -u to create it...exiting." && exit
if [ "$UPDATE" = "FALSE" ]; then
		awk --posix -v filterMu=$FILTER_MU -v filterKappa=$FILTER_KAPPA -v filterNt=$FILTER_NT -v filterNs=$FILTER_NS -v filterBeta=$FILTER_BETA -v filterType=$FILTER_TYPE \
					-v filterTrajNo=$FILTER_TRAJNO -v filterAccRate=$FILTER_ACCRATE -v filterStatus=$FILTER_STATUS -v statisticsSummary=$STATISTICS_SUMMARY \
					-v muString="$MU_STRING" -v kappaString="$KAPPA_STRING" -v nsString="$NS_STRING" -v ntString="$NT_STRING" -v betaString="$BETA_STRING" \
					-v typeString=$TYPE_STRING -v statusString="$STATUS_STRING" \
					-v trajLowValue=$TRAJ_LOW_VALUE -v trajHighValue=$TRAJ_HIGH_VALUE -v accRateLowValue=$ACCRATE_LOW_VALUE -v accRateHighValue=$ACCRATE_HIGH_VALUE \
					-v muColumn=${COLUMNS[muC]} -v kappaColumn=${COLUMNS[kC]} -v ntColumn=${COLUMNS[ntC]} -v nsColumn=${COLUMNS[nsC]} \
					-v betaColumn=${COLUMNS[betaC]} -v trajNoColumn=${COLUMNS[trajNoC]} -v accRateColumn=${COLUMNS[accRateC]} -v statusColumn=${COLUMNS[statusC]} '

						 {critFailedCounter=0}

						 filterMu == "TRUE" {if($(muColumn) !~ muString) {critFailedCounter--;}}
						 filterKappa == "TRUE" {if($(kappaColumn) !~ kappaString) {critFailedCounter--;}}
						 filterNs == "TRUE" {if($(nsColumn) !~ nsString) {critFailedCounter--;}}
						 filterNt == "TRUE" {if($(ntColumn) !~ ntString) {critFailedCounter--;}}
						 filterBeta == "TRUE" {if($(betaColumn) !~ betaString) {critFailedCounter--;}}
						 filterType == "TRUE" {if($(betaColumn) !~ typeString) {critFailedCounter--;}}
						 filterStatus == "TRUE" {if($(statusColumn) !~ statusString) {critFailedCounter--;}}

						 filterTrajNo == "TRUE" {if(length(trajLowValue) == 0 ? "0" : trajLowValue > $(trajNoColumn)){critFailedCounter--;}}
						 filterTrajNo == "TRUE" {if(length(trajHighValue) == 0 ? "999999" : trajHighValue < $(trajNoColumn)){critFailedCounter--;}}

						 filterAccRate == "TRUE" {if(length(accRateLowValue) == 0 ? "0" : accRateLowValue > $(accRateColumn)){critFailedCounter--;}}
						 filterAccRate == "TRUE" {if(length(accRateHighValue) == 0 ? "100.00" : accRateHighValue < $(accRateColumn)){critFailedCounter--;}}
						 
						 statisticsSummary == "FALSE" && critFailedCounter == 0 {print $0}
						 statisticsSummary == "TRUE" && critFailedCounter == 0 {lineCounter++;dataRow=sprintf("%s",$0);dataRowArray[lineCounter]=dataRow}

						 #SUMMARY OF STATISTICS
						 statisticsSummary == "TRUE" {
							split($(betaColumn),betaChainType,"_");
							if(betaChainType[3] == "NC"){statisticsSummaryArray[$(muColumn) "_" $(kappaColumn) "_" $(ntColumn) "_" $(nsColumn) "_" betaChainType[1] "_" betaChainType[3]]+=$(trajNoColumn);}
						}
						END{
							if(statisticsSummary == "TRUE"){
								split(dataRowArray[1],fieldsArray," ");
								split(fieldsArray[betaColumn],betaChainType,"_");
								if(betaChainType[3] == "NC"){oldKey = fieldsArray[muColumn] "_" fieldsArray[kappaColumn] "_" fieldsArray[ntColumn] "_" fieldsArray[nsColumn] "_" betaChainType[1] "_" betaChainType[3];}
								for(i=1;i<=lineCounter;i++){
									split(dataRowArray[i],fieldsArray," ");	
									split(fieldsArray[betaColumn],betaChainType,"_");
									if(betaChainType[3] == "NC"){newKey = fieldsArray[muColumn] "_" fieldsArray[kappaColumn] "_" fieldsArray[ntColumn] "_" fieldsArray[nsColumn] "_" betaChainType[1] "_" betaChainType[3]}
									if(betaChainType[3] == "NC"){if(newKey != oldKey){printf("sum: %d\n",statisticsSummaryArray[oldKey]); oldKey=newKey}}
									print dataRowArray[i]
								}
								printf("sum: %d\n",statisticsSummaryArray[newKey]);
							}
						}
			' $PROJECT_STATISTICS_FILE | \
		awk --posix -v betaColumn=${COLUMNS[betaC]} -v trajNoColumn=${COLUMNS[trajNoC]} -v statisticsSummary="TRUE" '
					BEGIN{
							printf("'$HEADER_PRINTF_FORMAT_SPECIFIER_STRING'\n"'$HEADER_PRINTF_PARAMETER_STRING');
							printf("%s\n",'$HEADER_ROW_SEPARATOR');
						 }
						 $0 !~ /^sum/{
							 
								printf("'$PRINTF_FORMAT_SPECIFIER_STRING'\n"'$PRINTF_PARAMETER_STRING');
						 }
						 $0 ~ /^sum/{
						 	printf("%'$(($NUMBER_OF_WHITESPACES_TILL_TRAJECTORY_COLUMN+5))'s\n",$0)
					 	 }
					'
fi


if [ "$UPDATE" = "TRUE" ]; then
	[ ! -f $FILE_WITH_PATHS ] && echo "$0: File $FILE_WITH_PATHS containing paths to the nsXX directories does not exist...exiting" && exit
	while :
	do
		while read line
		do
			PARAMS=( $(echo $line | awk 'BEGIN{FS="/"}{print $(NF-3) " " $(NF-2) " " $(NF-1) " " $(NF)}') )
			
			if [ -d $line ]; then
				echo updating $line ...
				cd $line
			else
				continue
			fi
			${HOME}/Script/JobScriptAutomation/JobHandler.sh -l | \
			sed -r "s:\x1B\[[0-9;]*[mK]::g" | \
			sed -r 's/(\[|\]|\)|\(|%)//g' | \
			awk --posix -v mu=${PARAMS[0]#mui*} -v k=${PARAMS[1]#k*} -v nt=${PARAMS[2]#nt*} -v ns=${PARAMS[3]#*ns} '

							$0 ~ /^[[:digit:]]\.[[:digit:]]{4}/{
								print mu " " k " " nt " " ns " " $1 " " $2 " " $3 " " $6
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
