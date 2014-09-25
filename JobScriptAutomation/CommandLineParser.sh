function ParseCommandLineOption(){
    while [ "$1" != "" ]; do
	case $1 in
	    -h | --help )
		printf "\n\e[0;32m"
		echo "Call the script $0 with the following optional arguments:"
		echo ""
		echo "  -h | --help"
		echo "  --jobscript_prefix                 ->    default value = job.submit.script.imagMu"
		echo "  --chempot_prefix                   ->    default value = mu"
		echo "  --kappa_prefix                     ->    default value = k"
		echo "  --ntime_prefix                     ->    default value = nt"
		echo "  --nspace_prefix                    ->    default value = ns"
		echo "  --beta_prefix                      ->    default value = b"
		echo "  --betasfile                        ->    default value = betas"
		echo "  --chempot                          ->    default value = PiT"
		echo "  --kappa                            ->    default value = 1000"
		echo "  --walltime                         ->    default value = 00:30:00 (30min)"
		echo "  --bgsize                           ->    default value = 32"
		echo "  --measurements                     ->    default value = 20000"
		echo "  --nrxprocs                         ->    default value = 4"
		echo "  --nryprocs                         ->    default value = 2"
		echo "  --nrzprocs                         ->    default value = 2"
		echo "  --ompnumthreads                    ->    default value = 64"
		echo "  --nsave                            ->    default value = 50"
		echo "  --intsteps0                        ->    default value = 7"
		echo "  --intsteps1                        ->    default value = 5"
		echo "  --intsteps2                        ->    default value = 5"
		echo "  --partition                        ->    default value = parallel (ONLY for LOEWE)"
		echo -e "  \e[0;34m--submit\e[0;32m                           ->    jobs will be submitted"
		echo -e "  \e[0;34m--submitonly\e[0;32m                       ->    jobs will be submitted (no files are created)"
		echo -e "  \e[0;34m--continue | --continue=[number]\e[0;32m   ->    Unfinished jobs will be continued up to the nr. of measurements specified in the input file."
		echo -e "                                     ->    If a number is specified finished jobs will be continued up to the specified number."
		echo -e "  \e[0;34m--liststatus\e[0;32m                       ->    The local measurement status for all beta will be displayed"
		echo -e "  \e[0;34m--liststatus_all\e[0;32m                   ->    The global measurement status for all beta will be displayed"
		echo -e "  \e[0;34m--showjobs\e[0;32m                         ->    The queued jobs for the current directoy will be displayed"
		echo -e "  \e[0;34m--showjobs_all\e[0;32m                     ->    The queued jobs for all directories will be displayed"
		echo -e "  \e[0;34m--accRateReport\e[0;32m                    ->    default value = 1000 (The acceptance rates will be computed for intervalls of 1000 configurations)"
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
	    --partition=* )		 LOEWE_PARTITION=${1#*=}; 
	        if [[ $CLUSTER_NAME != "LOEWE" ]]; then
		    printf "\n\e[0;31m The options --partition can be used only on the LOEWE! Aborting...\n\n\e[0m"
                    exit -1
		fi
		shift ;;
	    --submit )
	        if [ $SUBMITONLY = "FALSE" ] && [ $CONTINUE = "FALSE" ] && [ $LISTSTATUS = "FALSE" ]; then 
		    SUBMIT="TRUE"
		else		
		    #printf "\n\e[0;31m The options --submit, --submitonly, --continue, and --liststatus must not be combined! Aborting...\n\n\e[0m" 
		    printf "\n\e[0;31m The options " 
		    for OPT in ${MUTUALLYEXCLUSIVEOPTS[@]}; do
			printf "%s, " $OPT	
		    done
		    printf "are mutually exclusive and must not be combined! Aborting...\n\n\e[0m" 
		    exit -1
		fi;
		shift;; 
	    --submitonly )	 			
	        if [ $SUBMIT = "FALSE" ] && [ $CONTINUE = "FALSE" ] && [ $LISTSTATUS = "FALSE" ]; then 
		    SUBMITONLY="TRUE"
		else		
		    #printf "\n\e[0;31m The options --submit, --submitonly, --continue, and --liststatus must not be combined! Aborting...\n\n\e[0m" 
		    printf "\n\e[0;31m The options " 
		    for OPT in ${MUTUALLYEXCLUSIVEOPTS[@]}; do
			printf "%s, " $OPT	
		    done
		    printf "are mutually exclusive and must not be combined! Aborting...\n\n\e[0m" 
		    exit -1
		fi;
		shift;; 
	    --continue )			 
	        if [ $SUBMITONLY = "FALSE" ] && [ $SUBMIT = "FALSE" ] && [ $LISTSTATUS = "FALSE" ]; then
		    CONTINUE="TRUE"		
		else 
		    #printf "\n\e[0;31m The options --submit, --submitonly, --continue, and --liststatus must not be combined! Aborting...\n\n\e[0m" 
		    printf "\n\e[0;31m The options " 
		    for OPT in ${MUTUALLYEXCLUSIVEOPTS[@]}; do
			printf "%s, " $OPT	
		    done
		    printf "are mutually exclusive and must not be combined! Aborting...\n\n\e[0m" 
		    exit -1
		fi
		shift;; 
	    --continue=* )		
	        if [ $SUBMITONLY = "FALSE" ] && [ $SUBMIT = "FALSE" ] && [ $LISTSTATUS = "FALSE" ]; then
		    CONTINUE="TRUE"
		    CONTINUE_NUMBER=${1#*=}; 
		    if [[ ! $CONTINUE_NUMBER =~ [[:digit:]]+ ]];then
		    	printf "\n\e[0;31m The specified number for --continue=[number] must be an integer containing at least one or more digits! Aborting...\n\n\e[0m" 
			exit -1
		    fi
		else 
		    #printf "\n\e[0;31m The options --submit, --submitonly, --continue, and --liststatus must not be combined! Aborting...\n\n\e[0m" 
		    printf "\n\e[0;31m The options " 
		    for OPT in ${MUTUALLYEXCLUSIVEOPTS[@]}; do
			printf "%s, " $OPT	
		    done
		    printf "are mutually exclusive and must not be combined! Aborting...\n\n\e[0m" 
		    exit -1
		fi
		shift;; 
	    --liststatus )
	        if [ $SUBMITONLY = "FALSE" ] && [ $SUBMIT = "FALSE" ] && [ $CONTINUE = "FALSE" ] && [ $LISTSTATUSALL = "FALSE" ]; then
		    LISTSTATUS="TRUE"
		    LISTSTATUSALL="FALSE"
		else
		    #printf "\n\e[0;31m The options --submit, --submitonly, --continue, and --liststatus must not be combined! Aborting...\n\n\e[0m" 
		    printf "\n\e[0;31m The options " 
		    for OPT in ${MUTUALLYEXCLUSIVEOPTS[@]}; do
			printf "%s, " $OPT	
		    done
		    printf "are mutually exclusive and must not be combined! Aborting...\n\n\e[0m" 
		    exit -1
		fi
		shift;; 
	    --liststatus_all )
	        if [ $SUBMITONLY = "FALSE" ] && [ $SUBMIT = "FALSE" ] && [ $CONTINUE = "FALSE" ] && [ $LISTSTATUS = "FALSE" ]; then
		    LISTSTATUS="TRUE"
		    LISTSTATUSALL="TRUE"
		else
		    #printf "\n\e[0;31m The options --submit, --submitonly, --continue, and --liststatus must not be combined! Aborting...\n\n\e[0m" 
		    printf "\n\e[0;31m The options " 
		    for OPT in ${MUTUALLYEXCLUSIVEOPTS[@]}; do
			printf "%s, " $OPT	
		    done
		    printf "are mutually exclusive and must not be combined! Aborting...\n\n\e[0m" 
		    exit -1
		fi
		shift;; 
	    --showjobs )
	        if [ $SUBMITONLY = "FALSE" ] && [ $SUBMIT = "FALSE" ] && [ $CONTINUE = "FALSE" ] && [ $LISTSTATUS = "FALSE" ]; then
		    SHOWJOBS="TRUE"
		    SHOWJOBSALL="FALSE"
		else
		    #printf "\n\e[0;31m The options --submit, --submitonly, --continue, and --liststatus must not be combined! Aborting...\n\n\e[0m" 
		    printf "\n\e[0;31m The options " 
		    for OPT in ${MUTUALLYEXCLUSIVEOPTS[@]}; do
			printf "%s, " $OPT	
		    done
		    printf "are mutually exclusive and must not be combined! Aborting...\n\n\e[0m" 
		    exit -1
		fi
		shift;; 
	    --showjobs_all )
	        if [ $SUBMITONLY = "FALSE" ] && [ $SUBMIT = "FALSE" ] && [ $CONTINUE = "FALSE" ] && [ $LISTSTATUS = "FALSE" ]; then
		    SHOWJOBS="TRUE"
		    SHOWJOBSALL="TRUE"
		else
		    #printf "\n\e[0;31m The options --submit, --submitonly, --continue, and --liststatus must not be combined! Aborting...\n\n\e[0m" 
		    printf "\n\e[0;31m The options " 
		    for OPT in ${MUTUALLYEXCLUSIVEOPTS[@]}; do
			printf "%s, " $OPT	
		    done
		    printf "are mutually exclusive and must not be combined! Aborting...\n\n\e[0m" 
		    exit -1
		fi
		shift;; 
	    --accRateReport=* )		 INTERVAL=${1#*=}; 
	   	ACCRATE_REPORT=TRUE
	    shift ;;
	    * ) printf "\n\e[0;31mError parsing the options! Aborting...\n\n\e[0m" ; exit -1 ;;
	esac
    done
}
