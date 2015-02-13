# NOTE: If at some points for some reason one would decide to allow as options
#       --startcondition and/or --host_seed (CL2QCD) one should think whether
#       the continue part should be modified or not. 

function ParseCommandLineOption(){

MUTUALLYEXCLUSIVEOPTS=( "--submit" "--submitonly" "--continue" "--thermalize" "--liststatus" "--liststatus_all" "--showjobs" "--showjobs_all" "--accRateReport" "--accRateReport_all --emptyBetaDirectories" )
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
		echo "  --kappa_prefix                     ->    default value = $KAPPA_PREFIX"
		echo "  --ntime_prefix                     ->    default value = $NTIME_PREFIX"
		echo "  --nspace_prefix                    ->    default value = $NSPACE_PREFIX"
		echo "  --beta_prefix                      ->    default value = $BETA_PREFIX"
		echo "  --betasfile                        ->    default value = $BETASFILE"
		echo "  --measurements                     ->    default value = $MEASUREMENTS"
		echo "  --nsave                            ->    default value = $NSAVE"
		echo "  --intsteps0                        ->    default value = $INTSTEPS0"
		echo "  --intsteps1                        ->    default value = $INTSTEPS1"
		echo -e "  --useMultipleChains                ->    if given, use multiple chain \e[1;32m(this implies that in the betas file the seed column is present)\e[0;32m"
		if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
		    echo "  --intsteps2                        ->    default value = $INTSTEPS2"
		    echo "  --walltime                         ->    default value = $WALLTIME [hours:min:sec]"
		    echo "  --bgsize                           ->    default value = $BGSIZE"
		    echo "  --nrxprocs                         ->    default value = $NRXPROCS"
		    echo "  --nryprocs                         ->    default value = $NRYPROCS"
		    echo "  --nrzprocs                         ->    default value = $NRZPROCS"
		    echo "  --ompnumthreads                    ->    default value = $OMPNUMTHREADS"
		else
		    echo "  --walltime                         ->    default value = $WALLTIME [days-hours:min:sec]"
		    echo "  --pbp                              ->    default value = $MEASURE_PBP"
		    echo "  --partition                        ->    default value = $LOEWE_PARTITION"
		    echo "  --constraint                       ->    default value = $LOEWE_CONSTRAINT"
		    echo "  --node                             ->    default value = automatically assigned"
		fi
		echo -e "  \e[0;34m--submit\e[0;32m                           ->    jobs will be submitted"
		echo -e "  \e[0;34m--submitonly\e[0;32m                       ->    jobs will be submitted (no files are created)"
		echo -e "  \e[0;34m--thermalize\e[0;32m                       ->    The thermalization is done." #TODO: Explain how!
		echo -e "  \e[0;34m--continue | --continue=[number]\e[0;32m   ->    Unfinished jobs will be continued up to the nr. of measurements specified in the input file."
		echo -e "                                     ->    If a number is specified, finished jobs will be continued up to the specified number."
                if [ "$CLUSTER_NAME" = "LOEWE" ]; then
		    echo -e "                                     ->    To resume a simulation from a given trajectory, add \e[0;34mresumefrom=[number]\e[0;32m in the betasfile."
		fi
		echo -e "  \e[0;34m-l | --liststatus\e[0;32m                  ->    The local measurement status for all beta will be displayed"
		echo -e "  \e[0;34m--liststatus_all\e[0;32m                   ->    The global measurement status for all beta will be displayed"
		echo -e "  \e[0;34m--showjobs\e[0;32m                         ->    The queued jobs will be displayed for the local parameters (kappa,nt,ns,beta)"
		echo -e "  \e[0;34m--accRateReport\e[0;32m                    ->    The acceptance rates will be computed for the specified intervalls of configurations)"
		echo -e "  \e[0;34m--accRateReport_all\e[0;32m                ->    The acceptance rates will be computed for the specified intervalls of configurations for all parameters (kappa,nt,ns,beta)"
		echo -e "  \e[0;34m--emptyBetaDirectories\e[0;32m             ->    CAUTION: The beta directories corresponding to the beta values specified in the betas file will be emptied!"
		echo -e "                                     ->    For each beta value specified there will be a promt for confirmation! After the Confirmation the process cannot bet undone!" 
		echo ""
		echo -e "\e[0;33mNOTE: The blue options are mutually exclusive and they are all FALSE by default! In other words, if none of them"
		echo -e "\e[0;33m      is given, the script will create beta-folders with the right files inside, but no job will be submitted."
		printf "\n\e[0m"
		exit
		shift;;
	    --jobscript_prefix=* )       JOBSCRIPT_PREFIX=${1#*=}; shift ;;
            --chempot_prefix=* )    	 CHEMPOT_PREFIX=${1#*=}; shift ;;
	    --kappa_prefix=* )           KAPPA_PREFIX=${1#*=}; shift ;;
	    --ntime_prefix=* )           NTIME_PREFIX=${1#*=}; shift ;;
	    --nspace_prefix=* )          NSPACE_PREFIX=${1#*=}; shift ;;
	    --beta_prefix=* )          	 BETA_PREFIX=${1#*=}; shift ;;
	    --betasfile=* )  		 BETASFILE=${1#*=}; shift ;;
	    --chempot=* )		 CHEMPOT=${1#*=}; shift ;;
	    --kappa=* )			 KAPPA=${1#*=}; shift ;;
	    --walltime=* )               WALLTIME=${1#*=}; shift ;;
	    --bgsize=* )                 BGSIZE=${1#*=}; shift ;;
	    --measurements=* )		 MEASUREMENTS=${1#*=}; shift ;;
	    --nrxprocs=* )		 NRXPROCS=${1#*=}; shift ;;
	    --nryprocs=* )		 NRYPROCS=${1#*=}; shift ;;
	    --nrzprocs=* )		 NRZPROCS=${1#*=}; shift ;;
	    --ompnumthreads=* )		 OMPNUMTHREADS=${1#*=}; shift ;;
	    --nsave=* )		 	 NSAVE=${1#*=}; shift ;;
	    --intsteps0=* )		 INTSTEPS0=${1#*=}; shift ;;
	    --intsteps1=* )		 INTSTEPS1=${1#*=}; shift ;;
	    --intsteps2=* )		 INTSTEPS2=${1#*=}; shift ;;
	    --pbp=* )		         MEASURE_PBP=${1#*=}; shift ;;
	    --useMultipleChains )
	        if [[ $CLUSTER_NAME != "LOEWE" ]]; then
                    printf "\n\e[0;31m The options --useMultipleChains can be used only on the LOEWE yet!! Aborting...\n\n\e[0m"
                    exit -1
		else
		    USE_MULTIPLE_CHAINS="TRUE"
		    BETA_POSTFIX="_continueWithNewChain"
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
	    --submit )
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--submit" )
		    SUBMIT="TRUE"
		shift;; 
	    --submitonly )	 			
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--submitonly" )
		    SUBMITONLY="TRUE"
		shift;; 
	    --thermalize )			 
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--thermalize" )
		    THERMALIZE="TRUE"
		    #Here we fix the beta postfix just looking for thermalized conf from hot at the actual parameters (no matter at which beta);
		    #if at least one configuration thermalized from hot is present, it means the thermalization has to be done from conf (the
		    #correct beta to be used is selected then later in the script ---> see where the array STARTCONFIGURATION_GLOBALPATH is filled
		    if [ $(ls $THERMALIZED_CONFIGURATIONS_PATH | grep "conf.${PARAMETERS_STRING}_${BETA_PREFIX}[[:digit:]][.][[:digit:]]\{4\}_fromHot[[:digit:]]\+.*" | wc -l) -eq 0 ]; then
			BETA_POSTFIX="_thermalizeFromHot"
		    else
			BETA_POSTFIX="_thermalizeFromConf"
		    fi	
		shift;; 
	    --continue )			 
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--continue" )
		    CONTINUE="TRUE"		
		shift;; 
	    --continue=* )		
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--continue" )
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
	    --emptyBetaDirectories )
		MUTUALLYEXCLUSIVEOPTS_PASSED+=( "--emptyBetaDirectories" )
		EMPTY_BETA_DIRS="TRUE"
	    shift ;;
	    * ) printf "\n\e[0;31mError parsing the options! Aborting...\n\n\e[0m" ; exit -1 ;;
	esac
    done

    if [ ${#MUTUALLYEXCLUSIVEOPTS_PASSED[@]} -gt 1 ]; then

	    printf "\n\e[0;31m The options " 
	    for OPT in ${MUTUALLYEXCLUSIVEOPTS[@]}; do
		printf "%s, " $OPT	
	    done
	    printf "are mutually exclusive and must not be combined! Aborting...\n\n\e[0m" 
	    exit -1
    fi
}
