
function AcceptanceRateReport(){

local FILENAME='output.data'

local DIR_WITH_BETAS=$WORK_DIR_WITH_BETAFOLDERS

DATE='D_'$(date +"%d_%m_%Y")'_T_'$(date +"%H_%M")

local ACCRATE_REPORT_PREFIX="$HOME_DIR_WITH_BETAFOLDERS/acceptancerate_report_"
local ACCRATE_REPORT="$ACCRATE_REPORT_PREFIX$CHEMPOT_PREFIX$CHEMPOT"_"$KAPPA_PREFIX$KAPPA"_"$NTIME_PREFIX$NTIME"_"$NSPACE_PREFIX$NSPACE_$DATE.txt"

rm -f $ACCRATE_REPORT_PREFIX*

if [ ! -d $DIR_WITH_BETAS ]; then
	echo "Invalid directory specified..."
	exit
elif [[ ! $INTERVAL =~ [[:digit:]]+ ]]; then
	echo "Interval must be an integer number..."
	exit
fi

local BETA_DIR_ARRAY=( $(ls $DIR_WITH_BETAS | grep "b[[:digit:]]\.[[:digit:]]\{4\}") )

if [ ${#BETA_DIR_ARRAY[@]} -lt 1 ]; then
	echo "No beta directories in the specified directory..."
	exit
fi

for BETA_DIR in ${BETA_DIR_ARRAY[@]}; do

	BETA_DIR_NAME=$(echo $BETA_DIR | grep -o "b[[:digit:]]\.[[:digit:]]\{4\}")

	if [ ! -f $DIR_WITH_BETAS/$BETA_DIR/$FILENAME ]; then

		echo "File output.data does in exist in $BETA_DIR"
		continue
	fi

	NRLINES_ARRAY+=( $(awk '{if(NR%'$INTERVAL'==0){counter++;}}END{print counter}' $DIR_WITH_BETAS/$BETA_DIR/$FILENAME) )

	DATA_ARRAY+=( $BETA_DIR_NAME )
	POS_BETA_STRING+=( $(expr ${#DATA_ARRAY[@]} - 1) )
	DATA_ARRAY+=( $(awk '{if(NR%'$INTERVAL'==0){printf("%.2f \n", sum/'$INTERVAL');sum=0}}{sum+=$7}' $DIR_WITH_BETAS/$BETA_DIR/$FILENAME) )

done

#echo "Size of array DATA_ARRAY: ${#DATA_ARRAY[@]}"
#echo "Size of array POS_BETA_STRING: ${#POS_BETA_STRING[@]}"

#for POS in ${POS_BETA_STRING[@]}; do
#
#	printf "%d\t" $POS
#done
#echo ''


#FIND LARGEST NUMBER OF INTERVALS
LARGEST_INTERVAL=${NRLINES_ARRAY[0]}
for NRLINES in ${NRLINES_ARRAY[@]}; do

	if [ $NRLINES -gt $LARGEST_INTERVAL ]; then
		LARGEST_INTERVAL=$NRLINES	
	fi
	#printf "%d\t" $NRLINES
done
echo ''

#PRINT ROW WITH BETAS
BETA_COUNTER=0
printf "Intervals "
printf "Intervals " >> $ACCRATE_REPORT
while [ $BETA_COUNTER -lt ${#BETA_DIR_ARRAY[@]} ]; do

	INDEX=${POS_BETA_STRING[$BETA_COUNTER]}

	printf "%s " ${DATA_ARRAY[$INDEX]}
	printf "%s " ${DATA_ARRAY[$INDEX]} >> $ACCRATE_REPORT

	BETA_COUNTER=$(expr $BETA_COUNTER + 1)
done
echo ''
printf "\n" >> $ACCRATE_REPORT

#PRINT ACCEPTANCE RATES
COUNTER=1
while [ $COUNTER -lt $(expr $LARGEST_INTERVAL + 1) ];do

	printf "%02d% 8s" $COUNTER $EMPTY
	printf "%02d% 8s" $COUNTER $EMPTY >> $ACCRATE_REPORT

	POS_INDEX=1

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
	echo ''
	printf "\n" >> $ACCRATE_REPORT
		
	COUNTER=$(expr $COUNTER + 1)
done

}




