
function BuildRegexPath(){

	PARAMETER_REGEX_ARRAY=([$MASS_POSITION]=$MASS_PREFIX$MASS_REGEX [$NTIME_POSITION]=$NTIME_PREFIX$NTIME_REGEX [$NSPACE_POSITION]=$NSPACE_PREFIX$NSPACE_REGEX)

	for i in ${PARAMETER_REGEX_ARRAY[@]}; do

		REGEX_PATH=$REGEX_PATH"/$i"
	done

	local REGEX_PATH='.*'$REGEX_PATH

	FIND_LOCATION_PATH=$HOME_DIR'/'$SIMULATION_PATH'/'$CHEMPOT_PREFIX$CHEMPOT'/'

	DIRECTORY_ARRAY=( $(find $FIND_LOCATION_PATH -regextype grep -regex $REGEX_PATH) )
}

