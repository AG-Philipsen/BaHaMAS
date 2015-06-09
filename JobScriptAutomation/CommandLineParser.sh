# NOTE: If at some points for some reason one would decide to allow as options
#       --startcondition and/or --host_seed (CL2QCD) one should think whether
#       the continue part should be modified or not. 

function ParseCommandLineOption(){

MUTUALLYEXCLUSIVEOPTS=( "-s | --submit" "-c | --continue" "-t | --thermalize" "-l | --liststatus" "--liststatus_all" "--submitonly" "--showjobs" "--showjobs_all" "--accRateReport" "--accRateReport_all" "--emptyBetaDirectories" "--cleanOutputFiles")
MUTUALLYEXCLUSIVEOPTS_PASSED=( )

    while [ "$1" != "" ]; do
	case $1 in
	    -h | --help )
		printf "\n\e[0;32m"
		echo "Call the script $0 with the following optional arguments:"
		echo ""
		echo "  -h | --help"
		echo "  --jobscript_prefix                 ->    default value = $JOBSCRIPT_PREFIX"
		echo "  --chempot_prefix                   ->    default value = $CHEMPOT_PREFIX"
        echo -e "  --kappa_prefix                     ->    default value = k \e[1;32m(Wilson Case ONLY)\e[0;32m"
        echo -e "  --mass_prefix                      ->    default value = mass \e[1;32m(Staggered Case ONLY)\e[0;32m"
		echo "  --ntime_prefix                     ->    default value = $NTIME_PREFIX"
		echo "  --nspace_prefix                    ->    default value = $NSPACE_PREFIX"
		echo "  --beta_prefix                      ->    default value = $BETA_PREFIX"
		echo "  --betasfile                        ->    default value = $BETASFILE"
		echo "  -m | --measurements                ->    default value = $MEASUREMENTS"
		echo "  -f | --confSaveFrequency           ->    default value = $NSAVE"
		echo "  -F | --confSavePointFrequency      ->    default value = $NSAVEPOINT"
		echo "  --intsteps0                        ->    default value = $INTSTEPS0"
		echo "  --intsteps1                        ->    default value = $INTSTEPS1"
		echo -e "  -u | --useMultipleChains           ->    if given, use multiple chain \e[1;32m(this implies that in the betas file the seed column is present)\e[0;32m"
		if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
		    echo "  --intsteps2                        ->    default value = $INTSTEPS2"
		    echo "  -w | --walltime                    ->    default value = $WALLTIME [hours:min:sec]"
		    echo "  --bgsize                           ->    default value = $BGSIZE"
		    echo "  --nrxprocs                         ->    default value = $NRXPROCS"
		    echo "  --nryprocs                         ->    default value = $NRYPROCS"
		    echo "  --nrzprocs                         ->    default value = $NRZPROCS"
		    echo "  --ompnumthreads                    ->    default value = $OMPNUMTHREADS"
		else
		    echo "  -p | --doNotMeasurePbp             ->    if given, the chiral condensate measurement is switched off"
		    echo "  -w | --walltime                    ->    default value = $WALLTIME [days-hours:min:sec]"
		    echo "  --partition                        ->    default value = $LOEWE_PARTITION"
		    echo "  --constraint                       ->    default value = $LOEWE_CONSTRAINT"
		    echo "  --node                             ->    default value = automatically assigned"
		fi
		echo -e "  --doNotUseRAfiles                  ->    if given, the Rational Approximations are evaluated \e[1;32m(Staggered Case ONLY)\e[0;32m"
		echo -e "  \e[0;34m-s | --submit\e[0;32m                      ->    jobs will be submitted"
		echo -e "  \e[0;34m--submitonly\e[0;32m                       ->    jobs will be submitted (no files are created)"
		echo -e "  \e[0;34m-t | --thermalize\e[0;32m                  ->    The thermalization is done." #TODO: Explain how
		echo -e "  \e[0;34m-c | --continue\e[0;32m                    ->    Unfinished jobs will be continued up to the nr. of measurements specified in the input file."
		echo -e "  \e[0;34m-c=[number] | --continue=[number]\e[0;32m        If a number is specified, finished jobs will be continued up to the specified number."
		if [ "$CLUSTER_NAME" = "LOEWE" ]; then
		    echo -e "                                           To resume a simulation from a given trajectory, add \e[0;34mresumefrom=[number]\e[0;32m in the betasfile."
		fi
		echo -e "  \e[0;34m-l | --liststatus\e[0;32m                  ->    The local measurement status for all beta will be displayed"
		if [ "$CLUSTER_NAME" = "LOEWE" ]; then
		    echo -e "                                           Secondary options: \e[0;34m--measureTime\e[0;32m to get information about the trajectory time"
		    echo -e "                                                              \e[0;34m--showOnlyQueued\e[0;32m not to show status about not queued jobs"
		fi
		echo -e "  \e[0;34m--liststatus_all\e[0;32m                   ->    The global measurement status for all beta will be displayed"
		echo -e "  \e[0;34m--showjobs\e[0;32m                         ->    The queued jobs will be displayed for the local parameters (kappa,nt,ns,beta)"
		echo -e "  \e[0;34m--accRateReport\e[0;32m                    ->    The acceptance rates will be computed for the specified intervals of configurations"
		echo -e "  \e[0;34m--accRateReport_all\e[0;32m                ->    The acceptance rates will be computed for the specified intervals of configurations for all parameters (kappa,nt,ns,beta)"
		echo -e "  \e[0;34m--cleanOutputFiles\e[0;32m                 ->    The output files referred to the betas contained in the betas file are cleaned (repeated lines are eliminated)"
		echo -e "                                           For safety reason, a backup of the output file is done (it is left in the output file folder with the name outputfilename_date)" 
		echo -e "                                           Secondary options: \e[0;34m--all\e[0;32m to clean output files for all betas in WORK_DIR referred to the actual path parameters"
		echo -e "  \e[0;34m--emptyBetaDirectories\e[0;32m             ->    The beta directories corresponding to the beta values specified in the file \"\e[4memptybetas\e[0;32m\" will be emptied!"
		echo -e "                                           For each beta value specified there will be a promt for confirmation! \e[1mATTENTION\e[0;32m: After the Confirmation the process cannot be undone!" 
		echo ""
		echo -e "\e[0;93mNOTE: The blue options are mutually exclusive and they are all FALSE by default! In other words, if none of them"
		echo -e "\e[0;93m      is given, the script will create beta-folders with the right files inside, but no job will be submitted."
		printf "\n\e[0m"
		exit
		shift;;
        --jobscript_prefix=* )          JOBSCRIPT_PREFIX=${1#*=}; shift ;;
        --chempot_prefix=* )            CHEMPOT_PREFIX=${1#*=}; shift ;;
	    --kappa_prefix=* )
            [ $STAGGERED = "TRUE" ] && printf "\n\e[0;31m The option --kappa_prefix can be used only in WILSON simulations! Aborting...\n\n\e[0m" && exit -1
            KAPPA_PREFIX=${1#*=}; shift ;;
	    --mass_prefix=* )
            [ $WILSON = "TRUE" ] && printf "\n\e[0;31m The option --kappa_prefix can be used only in STAGGERED simulations! Aborting...\n\n\e[0m" && exit -1
            KAPPA_PREFIX=${1#*=}; shift ;;
	    --ntime_prefix=* )              NTIME_PREFIX=${1#*=}; shift ;;
	    --nspace_prefix=* )             NSPACE_PREFIX=${1#*=}; shift ;;
	    --beta_prefix=* )               BETA_PREFIX=${1#*=}; shift ;;
	    --betasfile=* )                 BETASFILE=${1#*=}; shift ;;
	    --chempot=* )                   CHEMPOT=${1#*=}; shift ;;
	    --kappa=* )                     KAPPA=${1#*=}; shift ;;
	    -w=* | --walltime=* )           WALLTIME=${1#*=}; shift ;;
	    --bgsize=* )                    BGSIZE=${1#*=}; shift ;;
	    -m=* | --measurements=* )       MEASUREMENTS=${1#*=}; shift ;;
	    --nrxprocs=* )                  NRXPROCS=${1#*=}; shift ;;
	    --nryprocs=* )                  NRYPROCS=${1#*=}; shift ;;
	    --nrzprocs=* )                  NRZPROCS=${1#*=}; shift ;;
	    --ompnumthreads=* )             OMPNUMTHREADS=${1#*=}; shift ;;
	    -f=* | --confSaveFrequency=* )  NSAVE=${1#*=}; shift ;;
	    -F=* | --confSavePointFrequency=* )  NSAVEPOINT=${1#*=}; shift ;;
	    --intsteps0=* )                 INTSTEPS0=${1#*=}; shift ;;
	    --intsteps1=* )                 INTSTEPS1=${1#*=}; shift ;;
	    --intsteps2=* )                 INTSTEPS2=${1#*=}; shift ;;
	    -p | --doNotMeasurePbp )        MEASURE_PBP="FALSE"; shift ;;
	    --doNotUseRAfiles )
            [ $WILSON = "TRUE" ] && printf "\n\e[0;31m The option --doNotUseRAfiles can be used only in STAGGERED simulations! Aborting...\n\n\e[0m" && exit -1
            USE_RATIONAL_APPROXIMATION_FILE="FALSE"; shift ;;
	    -u | --useMultipleChains )
	        if [[ $CLUSTER_NAME != "LOEWE" ]] && [[ $CLUSTER_NAME != "LCSC" ]]; then
                    printf "\n\e[0;31m The options -u | --useMultipleChains can be used only on CSC clusters yet!! Aborting...\n\n\e[0m"
                    exit -1
		else
		    USE_MULTIPLE_CHAINS="TRUE"
		    if [ $THERMALIZE = "FALSE" ]; then
		    	BETA_POSTFIX="_continueWithNewChain"
		    fi
                fi
                shift ;;
	    --partition=* )		 LOEWE_PARTITION=${1#*=}; 
	        if [[ $CLUSTER_NAME != "LOEWE" ]]; then
		    printf "\n\e[0;31m The options --partition can be used only on the LOEWE! Aborting...\n\n\e[0m"
                    exit -1
		fi
		shift ;;
	    --constraint=* )		 LOEWE_CONSTRAINT=${1#*=}; 
	        if [[ $CLUSTER_NAME != "LOEWE" ]]; then
		    printf "\n\e[0;31m The options --constraint can be used only on the LOEWE! Aborting...\n\n\e[0m"
                    exit -1
		fi
		shift ;;
	    --node=* )	                 LOEWE_NODE=${1#*=}; 
	        if [[ $CLUSTER_NAME != "LOEWE" ]]; then
		    printf "\n\e[0;31m The options --node can be used only on the LOEWE! Aborting...\n\n\e[0m"
                    exit -1
		fi
		shift ;;
	    -s | --submit )
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		    SUBMIT="TRUE"
		shift;; 
	    --submitonly )	 			
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--submitonly" )
		    SUBMITONLY="TRUE"
		shift;; 
	    -t | --thermalize )			 
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		    THERMALIZE="TRUE"
		shift;; 
	    -c | --continue )			 
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		    CONTINUE="TRUE"		
		shift;; 
	    -c=* | --continue=* )		
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "$1" )
		    CONTINUE="TRUE"
		    CONTINUE_NUMBER=${1#*=}; 
		    if [[ ! $CONTINUE_NUMBER =~ ^[[:digit:]]+$ ]];then
		    	printf "\n\e[0;31m The specified number for --continue=[number] must be an integer containing at least one or more digits! Aborting...\n\n\e[0m" 
			exit -1
		    fi
		shift;; 
	    -l | --liststatus )
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--liststatus" )
		    LISTSTATUS="TRUE"
		    LISTSTATUSALL="FALSE"
		shift;;
	    --measureTime )
	            [ $LISTSTATUS = "FALSE" ] && printf "\n\e[0;31mSecondary option --measureTime must be given after the primary one \"-l | --liststatus\"! Aborting...\n\n\e[0m" && exit -1
		    LISTSTATUS_MEASURE_TIME="TRUE"
		shift;;
	    --showOnlyQueued )
	            [ $LISTSTATUS = "FALSE" ] && printf "\n\e[0;31mSecondary option --showOnlyQueued must be given after the primary one \"-l | --liststatus\"! Aborting...\n\n\e[0m" && exit -1
		    LISTSTATUS_SHOW_ONLY_QUEUED="TRUE"
		shift;;
	    --liststatus_all )
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--liststatus_all" )
		    LISTSTATUS="FALSE"
		    LISTSTATUSALL="TRUE"
		shift;; 
	    --showjobs )
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--showjobs" )
		    SHOWJOBS="TRUE"
		shift;; 
	    --accRateReport=* )		 INTERVAL=${1#*=}; 
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--accRateReport" )
	   	ACCRATE_REPORT="TRUE"
	    shift ;;
	    --accRateReport_all=* )		 INTERVAL=${1#*=}; 
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--accRateReport_all" )
	   	ACCRATE_REPORT="TRUE"
	   	ACCRATE_REPORT_GLOBAL="TRUE"
	    shift ;;
	    --cleanOutputFiles )
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--cleanOutputFiles" )
		CLEAN_OUTPUT_FILES="TRUE"
	    shift ;;
	    --emptyBetaDirectories )
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--emptyBetaDirectories" )
		EMPTY_BETA_DIRS="TRUE"
	    shift ;;
	    --all )
	            [ $CLEAN_OUTPUT_FILES = "FALSE" ] && printf "\n\e[0;31mSecondary option --all must be given after the primary one! Aborting...\n\n\e[0m" && exit -1
		    SECONDARY_OPTION_ALL="TRUE"
		shift;;
	    * ) printf "\n\e[0;31m Invalid option \e[1m$1\e[0;31m (see help for further information)! Aborting...\n\n\e[0m" ; exit -1 ;;
	esac
    done

    if [ ${#MUTUALLYEXCLUSIVEOPTS_PASSED[@]} -gt 1 ]; then

	    printf "\n\e[0;31m The options\n\n\e[1m" 
	    for OPT in "${MUTUALLYEXCLUSIVEOPTS[@]}"; do
		#echo "  $OPT"
		printf "  %s\n" "$OPT"
	    done
	    printf "\n\e[0;31m are mutually exclusive and must not be combined! Aborting...\n\n\e[0m" 
	    exit -1
    fi
}
