function __static__AcceptanceRateReportLocal(){

	PARAMETERS_PATH=""
	ReadParametersFromPath $(pwd) #defining WORK_DIR_WITH_BETAFOLDERS
	WORK_DIR_WITH_BETAFOLDERS="$WORK_DIR/$SIMULATION_PATH$PARAMETERS_PATH"

	if [ ! -d $DIR_WITH_BETAS ]; then
		echo "Invalid directory specified..."
		exit
	elif [[ ! $INTERVAL =~ [[:digit:]]+ ]]; then
		echo "Interval must be an integer number..."
		exit
	fi

	ReadBetaValuesFromFile

	local BETA_DIR_ARRAY=()

	for BETA in ${BETAVALUES[@]}; do

		BETA_DIR_ARRAY+=( "b$BETA" )
	done

	if [ ${#BETA_DIR_ARRAY[@]} -lt 1 ]; then
		echo "No beta directories in the specified directory..."
		exit
	fi

	#SOME ARRAYS NEEDED FOR THE FURTHER PROCESS
	local NRLINES_ARRAY=()
	local DATA_ARRAY=()
	local POS_BETA_STRING=()

	for BETA_DIR in ${BETA_DIR_ARRAY[@]}; do

		BETA_DIR_NAME=$(echo $BETA_DIR | grep -o "b[[:digit:]]\.[[:digit:]]\{4\}")

		if [ ! -f $WORK_DIR_WITH_BETAFOLDERS/$BETA_DIR/$FILENAME ]; then

			echo "File output.data does not in exist in $WORK_DIR_WITH_BETAFOLDERS/$BETA_DIR"
			continue
		fi

		NRLINES_ARRAY+=( $(awk '{if(NR%'$INTERVAL'==0){counter++;}}END{print counter}' $WORK_DIR_WITH_BETAFOLDERS/$BETA_DIR/$FILENAME) )

		DATA_ARRAY+=( $BETA_DIR_NAME )
		POS_BETA_STRING+=( $(expr ${#DATA_ARRAY[@]} - 1) )
		DATA_ARRAY+=( $(awk '{if(NR%'$INTERVAL'==0){printf("%.2f \n", sum/'$INTERVAL');sum=0}}{sum+=$7}' $WORK_DIR_WITH_BETAFOLDERS/$BETA_DIR/$FILENAME) )

	done

	#FIND LARGEST NUMBER OF INTERVALS
	local LARGEST_INTERVAL=${NRLINES_ARRAY[0]} #Initialize LARGEST_INTERVAL variable

	for NRLINES in ${NRLINES_ARRAY[@]}; do

		if [ $NRLINES -gt $LARGEST_INTERVAL ]; then
			LARGEST_INTERVAL=$NRLINES	
		fi
	done

	printf "\n"

	#PRINT HEADER LINE
	printf "\n      %s  %s  %s\n" $MASS_PREFIX$MASS $NTIME_PREFIX$NTIME $NSPACE_PREFIX$NSPACE >> $ACCRATE_REPORT

	#PRINT ROW WITH BETAS
	local BETA_COUNTER=0

	printf "Intervals "
	printf "Intervals " >> $ACCRATE_REPORT

	while [ $BETA_COUNTER -lt ${#BETA_DIR_ARRAY[@]} ]; do

		INDEX=${POS_BETA_STRING[$BETA_COUNTER]}

		printf "%s " ${DATA_ARRAY[$INDEX]}
		printf "%s " ${DATA_ARRAY[$INDEX]} >> $ACCRATE_REPORT

		BETA_COUNTER=$(expr $BETA_COUNTER + 1)
	done
	
	printf "\n"
	printf "\n" >> $ACCRATE_REPORT

	#PRINT ACCEPTANCE RATES
	local COUNTER=1

	while [ $COUNTER -lt $(expr $LARGEST_INTERVAL + 1) ];do

		printf "%02d% 8s" $COUNTER $EMPTY
		printf "%02d% 8s" $COUNTER $EMPTY >> $ACCRATE_REPORT

		local POS_INDEX=1

		for POS in ${POS_BETA_STRING[@]}; do
			
			DATA_INDEX=$(expr $POS + $COUNTER)

			if [ $POS_INDEX -eq ${#POS_BETA_STRING[@]} ]; then

				if [ $DATA_INDEX -lt ${#DATA_ARRAY[@]} ]; then

					printf "%s    " ${DATA_ARRAY[$DATA_INDEX]}
					printf "%s    " ${DATA_ARRAY[$DATA_INDEX]} >> $ACCRATE_REPORT
				else
					printf "        " ${DATA_ARRAY[$DATA_INDEX]}
					printf "        " ${DATA_ARRAY[$DATA_INDEX]} >> $ACCRATE_REPORT
				fi

			elif [ $POS_INDEX -lt ${#POS_BETA_STRING[@]} ]; then

				if [ $DATA_INDEX -lt ${POS_BETA_STRING[$POS_INDEX]} ]; then

					printf "%s    " ${DATA_ARRAY[$DATA_INDEX]}
					printf "%s    " ${DATA_ARRAY[$DATA_INDEX]} >> $ACCRATE_REPORT
				else
					printf "        " ${DATA_ARRAY[$DATA_INDEX]}
					printf "        " ${DATA_ARRAY[$DATA_INDEX]} >> $ACCRATE_REPORT
				fi
			fi

			#printf "(%s %s)" $DATA_INDEX $POS_INDEX

			POS_INDEX=$(expr $POS_INDEX + 1)
		done
		printf "\n"
		printf "\n" >> $ACCRATE_REPORT
			
		COUNTER=$(expr $COUNTER + 1)
	done

}

function __static__AcceptanceRateReportGlobal(){

	local ORIGINAL_PATH=$(pwd)

	local JOBS_STATUS_FILE_GLOBAL=$HOME_DIR'/'$SIMULATION_PATH'/global_'$JOBS_STATUS_PREFIX$DATE'.txt'

	local ACCRATE_REPORT_PREFIX="$HOME_DIR/$SIMULATION_PATH/global_acceptancerate_report_"

	local ACCRATE_REPORT="$ACCRATE_REPORT_PREFIX$DATE.txt"

	rm -f $ACCRATE_REPORT

	BuildRegexPath

	for i in ${DIRECTORY_ARRAY[@]}; do

		local DIR_WITH_BETAS=$i
		
		cd $DIR_WITH_BETAS

		__static__AcceptanceRateReportLocal

		cd $ORIGINAL_PATH

		printf "\n" >> $ACCRATE_REPORT
	done
}


function AcceptanceRateReport(){

	local FILENAME='output.data'

	DATE='D_'$(date +"%d_%m_%Y")'_T_'$(date +"%H_%M")

	if [ $ACCRATE_REPORT_GLOBAL = "FALSE" ]; then

		printf "Printing local acceptance rate report...\n"

		local DIR_WITH_BETAS=$WORK_DIR_WITH_BETAFOLDERS

		local ACCRATE_REPORT_PREFIX="$HOME_DIR_WITH_BETAFOLDERS/acceptancerate_report_"

		local ACCRATE_REPORT="$ACCRATE_REPORT_PREFIX$CHEMPOT_PREFIX$CHEMPOT"_"$MASS_PREFIX$MASS"_"$NTIME_PREFIX$NTIME"_"$NSPACE_PREFIX$NSPACE_$DATE.txt"

		rm -f $ACCRATE_REPORT_PREFIX*

		__static__AcceptanceRateReportLocal

	elif [ $ACCRATE_REPORT_GLOBAL = "TRUE" ]; then 

		printf "Printing global acceptance rate report...\n"

		__static__AcceptanceRateReportGlobal
	fi
}


