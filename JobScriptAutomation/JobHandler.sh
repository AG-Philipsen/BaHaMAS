#!/bin/bash

#Some more or less important comments:
#The scripts ProduceJobScript.sh and ProduceInputFile.sh are called via . (source) builtin, see e.g.
#https://developer.apple.com/library/mac/documentation/OpenSource/Conceptual/ShellScripting/SubroutinesandScoping/SubroutinesandScoping.html
#Important: Unlike executing a script as a normal shell command, executing a script with the source builtin results in the second script executing within the same 
#overall context as the first script. Any variables that are modified by the second script will be seen by the calling script.


#COMMENT about awk: I avoided to use the awk command since it was not possible to pass the prefix variables to awk. 
#For this reason the test criteria for the parameters were slightly modified as well.

#COMMENT about --submit and --submitonly: ...############### INSERT COMMENT HERE ###################

#----------------------------------!!!Modify only options!!!------------------------------------#
# set default values for the modifyable variables

JOBSCRIPT_PREFIX="job.submit.script.imagMu"
CHEMPOT_PREFIX="mui"
KAPPA_PREFIX="k"
NTAU_PREFIX="nt"
NSPAT_PREFIX="ns"
BETA_PREFIX="b"
BETASFILE="betas"
CHEMPOT="PiT"
KAPPA="1000"
WALLTIME="00:30:00"
BGSIZE="32"
MEASUREMENTS="20000"
NRXPROCS="4"
NRYPROCS="2"
NRZPROCS="2"
OMPNUMTHREADS="64"
NSAVE="50"
INTSTEPS0="7"
INTSTEPS1="5"
INTSTEPS2="5"
SUBMIT="FALSE"
SUBMITONLY="FALSE"
CONTINUE="FALSE"
CONTINUE_NUMBER="0"
LISTSTATUS="FALSE"

#----------------------------------------------------------------------------------------#

#--------------------------------!!!Only modify manually!!!------------------------------#
# set default values for the non-modifyable variables

USER_MAIL="czaban@th.physik.uni-frankfurt.de"
HMC_BUILD_PATH="tmLQCD_imagMu_Juqueen/Program/build"
SIMULATION_GLOBALPATH="ImagMu_Output_Data"
HOME_DIR="/homeb/hkf8/hkf806" 
WORK_DIR="/work/hkf8/hkf806" 
SCRIPT_DIR="$HOME_DIR/Script/tmLQCD_Juqueen"
PRODUCEJOBSCRIPTSH="$HOME_DIR/Script/JobScriptAutomation/ProduceJobScript.sh"
PRODUCEINPUTFILESH="$HOME_DIR/Script/JobScriptAutomation/ProduceInputFile.sh"
HMC_TM_FILENAME="hmc_tm"
HMC_TM_GLOBALPATH="$HOME_DIR/$HMC_BUILD_PATH/$HMC_TM_FILENAME"
INPUTFILE_NAME="hmc.input"
OUTPUTFILE_NAME="output.data"
#-----------------------------------------------------------------------------------------#


# extract options and their arguments into variables.
while [ "$1" != "" ]; do
    case $1 in
      -h | --help )
          printf "\n\e[0;32m"
          echo "Call the script $0 with the following optional arguments:"
          echo "  -h | --help"
          echo "  --jobscript_prefix            ->    default value = job.submit.script.imagMu"
          echo "  --chempot_prefix   		->    default value = mu"
          echo "  --kappa_prefix                ->    default value = k"
          echo "  --nt_prefix                   ->    default value = nt"
          echo "  --ns_prefix            	->    default value = ns"
          echo "  --beta_prefix         	->    default value = b"
          echo "  --betasfile             	->    default value = betas"
	  echo "  --chempot			->    default value = PiT"
	  echo "  --kappa			->    default value = 1000"
          echo "  --walltime              	->    default value = 00:30:00 (30min)"
	  echo "  --bgsize			->    default value = 32"
	  echo "  --measurements                ->    default value = 20000"
	  echo "  --nrxprocs			->    default value = 4"
	  echo "  --nryprocs			->    default value = 2"
	  echo "  --nrzprocs			->    default value = 2"
	  echo "  --ompnumthreads		->    default value = 64"
	  echo "  --nsave			->    default value = 50"
	  echo "  --intsteps0			->    default value = 7"
	  echo "  --intsteps1			->    default value = 5"
	  echo "  --intsteps2			->    default value = 5"
	  echo "  --submit			->    jobs will be submitted"
	  echo "  --submitonly 			->    jobs will be submitted (no files are created)"
	  echo "  --continue | --continue=[number]"			
	  echo "				->    Unfinished jobs will be continued up to the nr. of measurements specified in the hmc.input file."
	  echo "				->    If a number is specified finished jobs will be continued up to the specified number."
	  echo "  --liststatus 			->    The measurement status for all beta in the current directory will be displayed"
          printf "\n\e[0m"
          exit
          shift;;
      --jobscript_prefix=* )             JOBSCRIPT_PREFIX=${1#*=}; shift ;;
      --chempot_prefix=* )    		 CHEMPOT_PREFIX=${1#*=}; shift ;;
      --kappa_prefix=* )                 KAPPA_PREFIX=${1#*=}; shift ;;
      --nt_prefix=* )                  	 NTAU_PREFIX=${1#*=}; shift ;;
      --ns_prefix=* )             	 NSPAT_PREFIX=${1#*=}; shift ;;
      --beta_prefix=* )          	 BETA_PREFIX=${1#*=}; shift ;;
      --betasfile=* )  			 BETASFILE=${1#*=}; shift ;;
      --chempot=* )			 CHEMPOT=${1#*=}; shift ;;
      --kappa=* )			 KAPPA=${1#*=}; shift ;;
      --walltime=* )                   	 WALLTIME=${1#*=}; shift ;;
      --bgsize=* )                   	 BGSIZE=${1#*=}; shift ;;
      --measurements=* )		 MEASUREMENTS=${1#*=}; shift ;;
      --nrxprocs=* )		 	 NRXPROCS=${1#*=}; shift ;;
      --nryprocs=* )		 	 NRYPROCS=${1#*=}; shift ;;
      --nrzprocs=* )		 	 NRZPROCS=${1#*=}; shift ;;
      --ompnumthreads=* )		 OMPNUMTHREADS=${1#*=}; shift ;;
      --nsave=* )		 	 NSAVE=${1#*=}; shift ;;
      --intsteps0=* )		 	 INTSTEPS0=${1#*=}; shift ;;
      --intsteps1=* )		 	 INTSTEPS1=${1#*=}; shift ;;
      --intsteps2=* )		 	 INTSTEPS2=${1#*=}; shift ;;
      --submit )		  
		if [ $SUBMITONLY = "FALSE" ] && [ $CONTINUE = "FALSE" ] && [ $LISTSTATUS = "FALSE" ]; then 

			SUBMIT="TRUE"

		else		

			printf "\n\e[0;31m The options --submit, --submitonly, --continue, and --liststatus must not be combined! Aborting...\n\n\e[0m" 
			exit -1

		fi;
	shift;; 
      --submitonly )	 			
		if [ $SUBMIT = "FALSE" ] && [ $CONTINUE = "FALSE" ] && [ $LISTSTATUS = "FALSE" ]; then 

			SUBMITONLY="TRUE"

		else		

			printf "\n\e[0;31m The options --submit, --submitonly, --continue, and --liststatus must not be combined! Aborting...\n\n\e[0m" 
			exit -1

		fi;
	shift;; 
      --continue )			 
		if [ $SUBMITONLY = "FALSE" ] && [ $SUBMIT = "FALSE" ] && [ $LISTSTATUS = "FALSE" ]; then

			CONTINUE="TRUE"		
		else 

			printf "\n\e[0;31m The options --submit, --submitonly, --continue, and --liststatus must not be combined! Aborting...\n\n\e[0m" 
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

			printf "\n\e[0;31m The options --submit, --submitonly, --continue, and --liststatus must not be combined! Aborting...\n\n\e[0m" 
			exit -1
			
		fi
	shift;; 
      --liststatus )
		if [ $SUBMITONLY = "FALSE" ] && [ $SUBMIT = "FALSE" ] && [ $CONTINUE = "FALSE" ]; then

			LISTSTATUS="TRUE"
		else
			
			printf "\n\e[0;31m The options --submit, --submitonly, --continue, and --liststatus must not be combined! Aborting...\n\n\e[0m" 
			exit -1
		fi
	shift;; 
      * ) printf "\n\e[0;31mError parsing the options! Aborting...\n\n\e[0m" ; exit -1 ;;
    esac
done


#----------------------------Check if the necessary scripts exist -------------------------------------#
if [ ! -f $PRODUCEJOBSCRIPTSH ] || [ ! -f $PRODUCEINPUTFILESH ] || [ ! -f $HMC_TM_GLOBALPATH ]; then
	printf "\n\e[0;31m One or more of the following scripts are missing:\n\e[0m"
	printf "\n\e[0;31m $PRODUCEJOBSCRIPTSH\n\e[0m"
	printf "\n\e[0;31m $PRODUCEINPUTFILESH\n\e[0m"
	printf "\n\e[0;31m $HMC_TM_GLOBALPATH\n\e[0m"
	printf "\n\e[0;31m Aborting...\n\e[0m"
	exit -1
fi
#------------------------------------------------------------------------------------------------------#

#-------------------Make sure that each constituent of the path occurs only once in the path--------------------#

Var=$(echo $(pwd) | grep -o "homeb" | wc -l)
if [ $Var -ne 1 ] ; then
	printf "\n\e[0;31m The string \"homeb\" may only occure once in the path! Aborting...\n\n\e[0m" 
	exit 1
fi
Var=$(echo $(pwd) | grep -o "hkf8[^[:digit:]]" | wc -l)
if [ $Var -ne 1 ] ; then
	printf "\n\e[0;31m The string \"hkf8\" may only occure once in the path! Aborting...\n\n\e[0m" 
	exit 1
fi
Var=$(echo $(pwd) | grep -o "hkf80[[:digit:]]" | wc -l)
if [ $Var -ne 1 ] ; then
	printf "\n\e[0;31m The string \"hkf80X\" may only occure once in the path! Aborting...\n\n\e[0m" 
	exit 1
fi
Var=$(echo $(pwd) | grep -o "mui" | wc -l)
if [ $Var -ne 1 ] ; then
	printf "\n\e[0;31m The string \"mui\" may only occure once in the path! Aborting...\n\n\e[0m" 
	exit 1
fi
Var=$(echo $(pwd) | grep -o "k[[:digit:]]" | wc -l)
if [ $Var -ne 1 ] ; then
	printf "\n\e[0;31m The string \"kXXXX\" may only occure once in the path! Aborting...\n\n\e[0m" 
	exit 1
fi
Var=$(echo $(pwd) | grep -o "nt[[:digit:]]" | wc -l)
if [ $Var -ne 1 ] ; then
	printf "\n\e[0;31m The string \"ntXX\" may only occure once in the path! Aborting...\n\n\e[0m" 
	exit 1
fi
Var=$(echo $(pwd) | grep -o "ns[[:digit:]]" | wc -l)
if [ $Var -ne 1 ] ; then
	printf "\n\e[0;31m The string \"nsXX\" may only occure once in the path! Aborting...\n\n\e[0m" 
	exit 1
fi
#---------------------------------------------------------------------------------------------------------------#

#-------------------------------------Read parameters from pwd and check their format-------------------------------------#

KAPPA=$(echo $(pwd) | sed "s/^.*\/$KAPPA_PREFIX\([[:digit:]]\{4\}\).*$/\1/")
if [[ ! $KAPPA =~ ^[[:digit:]]{4}$ ]]; then
	printf "\n\e[0;31m Unable to recover kappa from the path \"$(pwd)\". Aborting...\n\n\e[0m"
	exit -1
fi

NTAU=$(echo $(pwd) | sed "s/^.*\/$NTAU_PREFIX\([[:digit:]]\{1\}\).*$/\1/") # Nt MUST have one digit only so far
	if [[ ! $NTAU =~ ^[[:digit:]]{1}$ ]]; then
	printf "\n\e[0;31m Unable to recover Nt from the path \"$(pwd)\". Aborting...\n\n\e[0m"
	exit -1
fi

NSPAT=$(echo $(pwd) | sed "s/^.*\/$NSPAT_PREFIX\([[:digit:]]\{2\}\).*$/\1/") # Ns MUST have two digit only so far 
	if [[ ! $NSPAT =~ ^[[:digit:]]{2}$ ]]; then
	printf "\n\e[0;31m Unable to recover Ns from the path \"$(pwd)\". Aborting...\n\n\e[0m"
	exit -1
fi
#-------------------------------------------------------------------------------------------------------------------------#

#-----------------------------------Crosscheck HOME_DIR_WITH_BETAFOLDERS path with actual position---------------------------------#

HOME_DIR_WITH_BETAFOLDERS="$HOME_DIR/$SIMULATION_GLOBALPATH/$CHEMPOT_PREFIX$CHEMPOT/$KAPPA_PREFIX$KAPPA/$NTAU_PREFIX$NTAU/$NSPAT_PREFIX$NSPAT"
if [ "$HOME_DIR_WITH_BETAFOLDERS" != "$(pwd)" ]; then
	printf "\n\e[0;31m Constructed path to directory containing beta folders does not match the actual position! Aborting...\n\n\e[0m"
	exit -1
fi
#------------------------------------------------------------------------------------------------------------------------------#

#-------------------------------------Construct WORK_DIR_WITH_BETAFOLDERS------------------------------------------------------#
WORK_DIR_WITH_BETAFOLDERS="$WORK_DIR/$SIMULATION_GLOBALPATH/$CHEMPOT_PREFIX$CHEMPOT/$KAPPA_PREFIX$KAPPA/$NTAU_PREFIX$NTAU/$NSPAT_PREFIX$NSPAT"
#------------------------------------------------------------------------------------------------------------------------------#

#-----------------------------------Check for correct specification of parallelization parameters---------------------------------#
if [ $LISTSTATUS = "FALSE" ]; then
	printf "\n\e[0;36m===================================================================================\n\e[0m"
	printf "\e[0;34m Checking parameters for parallelization using:\n\e[0m"
	printf "   BGSIZE  = $BGSIZE\n"
	printf "   NRXPROC = $NRXPROCS\n"
	printf "   NRZPROC = $NRZPROCS\n"
	printf "   NRYPROC = $NRYPROCS\n"

	if [ $(echo $BGSIZE | awk '{print log($1/32)/log(2)-int(log($1/32)/log(2))}') != "0" ]; then
		
		printf "\n\e[0;31m BGSIZE=$BGSIZE cannot be used with tmLQCD on Juqueeen! Aborting...\n\n\e[0m"
		exit -1

	elif [ $(echo $BGSIZE $NRXPROCS $NRYPROCS $NRZPROCS | awk '{print $1/($2*$3*$4)-int($1/($2*$3*$4))}') != "0" ]; then
		
		printf "\n\e[0;31m The number of processes in time direction has to be integer! Aborting...\n\n\e[0m"
		exit -1
		
	elif [ $(echo $NSPAT $NRXPROCS | awk '{print ($1/$2)-int($1/$2)}') != "0" ]; then
		
		printf "\n\e[0;31m The local lattice size in x-direction has to be integer! Aborting...\n\n\e[0m"
		exit -1

	elif [ $(echo $NSPAT $NRYPROCS | awk '{print ($1/$2)-int($1/$2)}') != "0" ]; then

		printf "\n\e[0;31m The local lattice size in y-direction has to be integer! Aborting...\n\n\e[0m"
		exit -1

	elif [ $(echo $NSPAT $NRZPROCS | awk '{print ($1/$2)-int($1/$2)}') != "0" ]; then

		printf "\n\e[0;31m The local lattice size in z-direction has to be integer! Aborting...\n\n\e[0m"
		exit -1

	elif [ $((($NSPAT/$NRZPROCS)%2)) != "0" ]; then

		printf "\n\e[0;31m The local lattice size in z-direction has to be even! Aborting...\n\n\e[0m"
		exit -1

	elif [ $((($NSPAT*$NSPAT*$NSPAT/($NRXPROCS*$NRYPROCS*$NRZPROCS))%2)) != "0" ]; then
		
		printf "\n\e[0;31m The product of the lattice sizes in spatial direction has to be even! Aborting...\n\n\e[0m"
		exit -1

	elif [ $(echo $BGSIZE $NRXPROCS $NRYPROCS $NRZPROCS $NTAU | awk '{print $5/($1/($2*$3*$4))-int($5/($1/($2*$3*$4)))}') != "0" ]; then

		printf "\n\e[0;31m The local lattice size in t-direction has to be integer! Aborting...\n\n\e[0m"
		exit -1

	elif [ $(($NSPAT/$NRXPROCS)) -le 1 ] || [ $(($NSPAT/$NRYPROCS)) -le 1 ] || 
	     #[ $(($NSPAT/$NRZPROCS)) -le 1 ] || [ $(($NTAU/($BGSIZE/($NRXPROCS*$NRYPROCS*$NRZPROCS)))) -le 1 ]; then
	     [ $(($NSPAT/$NRZPROCS)) -le 1 ] || [ $(($NTAU/($BGSIZE/($NRXPROCS*$NRYPROCS*$NRZPROCS)))) -lt 1 ]; then

		printf "\n\e[0;31m No local lattice size is allowed to be 1! Aborting...\n\n\e[0m"
		exit -1

	elif [ $(($NSPAT/$NRXPROCS)) -ge $NSPAT ] || [ $(($NSPAT/$NRYPROCS)) -ge $NSPAT ] || 
	     [ $(($NSPAT/$NRZPROCS)) -ge $NSPAT ] || [ $(($NTAU/($BGSIZE/($NRXPROCS*$NRYPROCS*$NRZPROCS)))) -ge $NTAU ]; then

		printf "\n\e[0;31m No local lattice size is allowed to be equal to or bigger than the total lattice size! Aborting...\n\n\e[0m"
		exit -1
		
	fi

	printf "\e[0;32m The parallelization is fine!\n"
	printf "\e[0;36m===================================================================================\n\e[0m"
fi
#---------------------------------------------------------------------------------------------------------------------------------#

#-----------------------------Read beta values from BETASFILE and write them into BETAVALUES array--------------------------#
if [ $LISTSTATUS = "FALSE" ]; then

	if [ ! -e $BETASFILE ]; then

		printf "\n\e[0;31m  File \"$BETASFILE\" not found in $(pwd). Aborting...\n\n\e[0m"
		exit -1
	fi

	#Write beta values from BETASFILE into BETAVALUES array
	BETAVALUES=( $(grep -o "^[[:blank:]]*[[:digit:]]\.[[:digit:]]\{4\}" $BETASFILE) )

	if [ ${#BETAVALUES[@]} -gt "0" ]; then	

		printf "\n\e[0;36m===================================================================================\n\e[0m"
		printf "\e[0;34m Read beta values:\n\e[0m"
		for i in ${BETAVALUES[@]}; do
			echo "  - $i"
		done
		printf "\e[0;36m===================================================================================\n\e[0m"
	else

		printf "\e[0;34m No beta values in betas file. Aborting...:\n\e[0m"
		exit -1
	fi
fi
#---------------------------------------------------------------------------------------------------------------------------#

#-----------------Produce input file and jobscript for each beta and place it in the corresponding directory-------------------#
#Array that will contain the beta values that actually will be processed
SUBMIT_BETA_ARRAY=()
PROBLEM_BETA_ARRAY=()

if [ $SUBMITONLY = "FALSE" ] && [ $CONTINUE = "FALSE" ] && [ $LISTSTATUS = "FALSE" ]; then  

	for i in ${BETAVALUES[@]}; do

		#Assigning beta value to BETA variable for readability
		BETA=$i

		#-------------Constructing HOME_BETADIRECTORY, JOBSCRIPT_NAME, JOBSCRIPT_GLOBALPATH and INPUTFILE_GLOBALPATH-------------------#
		HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
		JOBSCRIPT_NAME="$JOBSCRIPT_PREFIX"_"$CHEMPOT_PREFIX$CHEMPOT"_"$KAPPA_PREFIX$KAPPA"_"$NTAU_PREFIX$NTAU"_"$NSPAT_PREFIX$NSPAT"_"$BETA_PREFIX$BETA"
		JOBSCRIPT_GLOBALPATH=$HOME_BETADIRECTORY/$JOBSCRIPT_NAME
		INPUTFILE_GLOBALPATH=$HOME_BETADIRECTORY/$INPUTFILE_NAME
		#-------------------------------------------------------------------------------------------------------------------------#

		if [ ! -d $HOME_BETADIRECTORY ]; then

			printf "\e[0;34m Creating directory for beta = $BETA...\n\e[0m"
			mkdir $HOME_BETADIRECTORY
			#Adding beta value to SUBMIT_BETA_ARRAY
			SUBMIT_BETA_ARRAY+=( $BETA )
			
			#Test if mkdir $HOME_BETADIRECTORY was successful
			if [ ! -d $HOME_BETADIRECTORY ]; then
				printf "\n\e[0;31m Could not create directory $HOME_BETADIRECTORY ....Aborting\n\e[0m"
				exit -1
			fi
		else
			#$HOME_BETADIRECTORY already exists. Check if there are files in $HOME_BETADIRECTORY. 
			#If this is the case, ask the user if the script shall proceed.
			if [ $(ls $HOME_BETADIRECTORY | wc -l) -gt 0 ]; then

				printf "\n\e[0;31m There are already files in $HOME_BETADIRECTORY...\n\e[0m"
				printf "\e[0;31m Leaving out $BETA ...\n\n\e[0m"
				PROBLEM_BETA_ARRAY+=( $BETA )
				continue
			fi
		fi



#-----------------------Build jobscript and input file and put them together with hmc_tm into the $HOME_BETADIRECTORY------------------#

		. $PRODUCEJOBSCRIPTSH	
		. $PRODUCEINPUTFILESH	
		printf "\e[0;34m Copying $HMC_TM_GLOBALPATH to $HOME_BETADIRECTORY/ \n\e[0m"
		cp $HMC_TM_GLOBALPATH $HOME_BETADIRECTORY

		if [ -f "$INPUTFILE_GLOBALPATH" ] && [ -f "$JOBSCRIPT_GLOBALPATH" ] && [ -f "$HOME_BETADIRECTORY/$HMC_TM_FILENAME" ]; then

			printf "\e[0;34m Built files successfully...\n\n\e[0m"
		else

			printf "\n\e[0;31m One or more of the following files are missing:\n\e[0m"
			printf "\n\e[0;31m $INPUTFILE_GLOBALPATH\n\e[0m"
			printf "\n\e[0;31m $JOBSCRIPT_GLOBALPATH\n\e[0m"
			printf "\n\e[0;31m $HOME_BETADIRECTORY/$HMC_TM_FILENAME\n\e[0m"
			printf "\n\e[0;31m Aborting...\n\e[0m"
			exit -1
		fi
#---------------------------------------------------------------------------------------------------------------------------------#
	#done from for loop in line 238
	done
	
#elif from if in line 233
elif [ $SUBMITONLY = "TRUE" ] && [ $CONTINUE = "FALSE" ] && [ $LISTSTATUS = "FALSE" ]; then  

	for i in ${BETAVALUES[@]}; do

		#Assigning beta value to BETA variable for readability
		BETA=$i

		#-------------Constructing HOME_BETADIRECTORY, JOBSCRIPT_NAME, JOBSCRIPT_GLOBALPATH and INPUTFILE_GLOBALPATH-------------------#
		HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
		JOBSCRIPT_NAME="$JOBSCRIPT_PREFIX"_"$CHEMPOT_PREFIX$CHEMPOT"_"$KAPPA_PREFIX$KAPPA"_"$NTAU_PREFIX$NTAU"_"$NSPAT_PREFIX$NSPAT"_"$BETA_PREFIX$BETA"
		JOBSCRIPT_GLOBALPATH=$HOME_BETADIRECTORY/$JOBSCRIPT_NAME
		INPUTFILE_GLOBALPATH=$HOME_BETADIRECTORY/$INPUTFILE_NAME
		#-------------------------------------------------------------------------------------------------------------------------#

		if [ ! -d $HOME_BETADIRECTORY ]; then

			printf "\e[0;31m Directory for beta = $BETA does not exist.\n\e[0m"
			printf "\e[0;31m Going to next beta...\n\e[0m"
			PROBLEM_BETA_ARRAY+=( $BETA )
			continue
		else

			#$HOME_BETADIRECTORY already exists. Check if there are files in $HOME_BETADIRECTORY. 
			#If this is the case, ask the user if the script shall proceed.
			if [ -f "$INPUTFILE_GLOBALPATH" ] && [ -f "$JOBSCRIPT_GLOBALPATH" ] && [ -f "$HOME_BETADIRECTORY/$HMC_TM_FILENAME" ]; then

				#Check if there are more than 3 files, this means that there are more files than
				#jobscript, input file and hmc_tm which should not be the case
				if [ $(ls $HOME_BETADIRECTORY | wc -l) -gt 3 ]; then

					printf "\n\e[0;31m There are already files in $HOME_BETADIRECTORY...\n\e[0m"
					printf "\e[0;31m Leaving out $BETA ...\n\n\e[0m"
					PROBLEM_BETA_ARRAY+=( $BETA )
					continue
				fi

				#The following will not happen if the previous if-case applied
				#Adding beta value to SUBMIT_BETA_ARRAY
				SUBMIT_BETA_ARRAY+=( $BETA )
			else

				printf "\n\e[0;31m One or more of the following files are missing:\n\e[0m"
				printf "\n\e[0;31m $INPUTFILE_GLOBALPATH\n\e[0m"
				printf "\n\e[0;31m $JOBSCRIPT_GLOBALPATH\n\e[0m"
				printf "\n\e[0;31m $HOME_BETADIRECTORY/$HMC_TM_FILENAME\n\e[0m"
				printf "\e[0;31m Leaving out $BETA ...\n\n\e[0m"
				PROBLEM_BETA_ARRAY+=( $BETA )
				continue
			fi
		fi
	done

elif [ $CONTINUE = "TRUE" ]; then 
	
	for i in ${BETAVALUES[@]}; do

		#Assigning beta value to BETA variable for readability
		BETA=$i

		#-------------Constructing WORK_BETADIRECTORY, HOME_BETADIRECTORY, JOBSCRIPT_NAME, JOBSCRIPT_GLOBALPATH and INPUTFILE_GLOBALPATH-------------------#
		WORK_BETADIRECTORY="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
		HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
		JOBSCRIPT_NAME="$JOBSCRIPT_PREFIX"_"$CHEMPOT_PREFIX$CHEMPOT"_"$KAPPA_PREFIX$KAPPA"_"$NTAU_PREFIX$NTAU"_"$NSPAT_PREFIX$NSPAT"_"$BETA_PREFIX$BETA"
		INPUTFILE_GLOBALPATH="$HOME_BETADIRECTORY/$INPUTFILE_NAME"
		OUTPUTFILE_GLOBALPATH="$WORK_BETADIRECTORY/$OUTPUTFILE_NAME"
		#-------------------------------------------------------------------------------------------------------------------------#

		if [ ! -f $INPUTFILE_GLOBALPATH ]; then
			
			printf "\n\e[0;31m $INPUTFILE_GLOBALPATH does not exist.\n\e[0m"
			printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\e[0m"
			PROBLEM_BETA_ARRAY+=( $BETA )
			continue

		elif [ ! -f $OUTPUTFILE_GLOBALPATH ]; then

			printf "\n\e[0;31m $OUTPUTFILE_GLOBALPATH does not exist.\n\e[0m"
			printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\e[0m"
			PROBLEM_BETA_ARRAY+=( $BETA )
			continue
		fi

		grep -q "^StartCondition = continue" $INPUTFILE_GLOBALPATH
		if [ $(echo $?) = 0 ]; then 

			StartCondition="continue" 
		else 
			
			StartCondition="undefined" 
		fi

		grep -q "^InitialStoreCounter = readin" $INPUTFILE_GLOBALPATH

		if [ $(echo $?) = 0 ]; then 

			InitialStoreCounter="readin" 
		else 
			
			InitialStoreCounter="undefined" 
		fi

		if [  $StartCondition != "continue" ]; then
			
			printf "\n\e[0;31m StartCondition for beta = $BETA is not set to continue.\n\e[0m"
			printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\e[0m"
			PROBLEM_BETA_ARRAY+=( $BETA )
			continue

		elif [ $InitialStoreCounter != "readin" ]; then

			printf "\n\e[0;31m InitialStoreCounter for beta = $BETA is not set to readin.\n\e[0m"
			printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\e[0m"
			PROBLEM_BETA_ARRAY+=( $BETA )
			continue
		fi

		if [ $CONTINUE_NUMBER -eq 0 ]; then

			TOTAL_NR_TRAJECTORIES=$(grep "^#[[:blank:]]\+Total[[:blank:]]\+number[[:blank:]]\+of[[:blank:]]\+trajectories" $INPUTFILE_GLOBALPATH | grep -o "=[[:blank:]]*[[:digit:]]\+[[:blank:]]*#*" | grep -o "[[:digit:]]\+")	
		
		else

			TOTAL_NR_TRAJECTORIES=$CONTINUE_NUMBER
 			sed -i "s/\(^#[[:blank:]]\+Total[[:blank:]]\+number[[:blank:]]\+of[[:blank:]]\+trajectories[[:blank:]]\+=[[:blank:]]*\)[[:digit:]]\+[[:blank:]]*#*.*/\1$TOTAL_NR_TRAJECTORIES/" $INPUTFILE_GLOBALPATH
			
		fi

		TRAJECTORIES_DONE=$(tail -n1 $OUTPUTFILE_GLOBALPATH | grep -o "^[[:digit:]]\+")
		TRAJECTORIES_DONE=$(expr $TRAJECTORIES_DONE + 1)

		MEASUREMENTS_REMAINING=$(expr $TOTAL_NR_TRAJECTORIES - $TRAJECTORIES_DONE)

		if [ $MEASUREMENTS_REMAINING -gt 0 ]; then

			sed -i "s/\(^Measurements.*$\)/#\1\nMeasurements = $MEASUREMENTS_REMAINING/" $INPUTFILE_GLOBALPATH
			SUBMIT_BETA_ARRAY+=( $BETA )
		else
			
			printf "\n\e[0;31m For beta = $BETA the difference between the total nr of trajectories and the trajectories already done\n\e[0m"
			printf "\e[0;31m is smaller or equal to zero.\n\e[0m"
			printf "\e[0;31m Simulation cannot be continued. Leaving out beta = $BETA .\n\e[0m"
			PROBLEM_BETA_ARRAY+=( $BETA )
			continue	
		fi
	done
fi

#COMMENT: ####################OPTION SHOULD BE RECONSIDERED AND IMPROVED!!!!!!!!!!!!!!!!!!!##########################################
if [ $LISTSTATUS = "TRUE" ]; then

	JOBS_STATUS_FILE="jobs_status_""$CHEMPOT_PREFIX$CHEMPOT"_"$KAPPA_PREFIX$KAPPA"_"$NTAU_PREFIX$NTAU"_"$NSPAT_PREFIX$NSPAT"".txt"

	if [ -f $JOBS_STATUS_FILE ]; then
		
		rm $JOBS_STATUS_FILE
	fi

	printf "\n\e[0;36m==================================================================================================\n\e[0m"
	printf "\e[0;34m Listing current measurements status...\n\e[0m"

	#printf "\n\e[0;34mBeta \t Total nr of trajectories \t Trajectories done \t trajectories remaining\n\e[0m"
	printf "\n\e[0;34m%s  %s  %s  %s %s %s\n\e[0m" "  Beta" "Total nr of trajectories" "Trajectories done" "Trajectories remaining" "Status"
	printf "%s  %s  %s  %s %s\n" "  Beta" "Total nr of trajectories" "Trajectories done" "Trajectories remaining" "Status" >> $JOBS_STATUS_FILE
	for i in b*; do

		#Assigning beta value to BETA variable for readability
		BETA=$(echo $i | grep -o "[[:digit:]].[[:digit:]]\{4\}")

		if [[ ! $BETA =~ [[:digit:]].[[:digit:]]{4} ]]; then
				
			continue;
		fi

		#JOBID_ARRAY=( $(llq -u hkf806 | grep -o "juqueen[[:alnum:]]\{3\}\.[[:digit:]]\+\.[[:digit:]]") )
		JOBID_ARRAY=( $(llq -u hkf806 | awk -v lines=$(llq -u hkf806 | wc -l) 'NR>2 && NR<lines-1{print $1}') )
		for k in ${JOBID_ARRAY[@]}; do

		
			JOBID=$k
			#if [ $i = "b5.7500" ]; then 
			#	echo $JOBID 
			#fi
 			JOBNAME=$(llq -l $JOBID | grep "Job Name:" | sed "s/^.*Job Name: \(muiPiT.*$\)/\1/")
			#if [ $i = "b.57500" ]; then echo $JOBNAME 
			#fi
			JOBNAME_NTAU=$(echo $JOBNAME | sed "s/^.*_nt\([[:digit:]]\)_.*$/\1/")
			JOBNAME_NSPAT=$(echo $JOBNAME | sed "s/^.*_n[[:alpha:]]\([[:digit:]]\{2\}\)_.*$/\1/")
			JOBNAME_KAPPA=$(echo $JOBNAME | sed "s/^.*_k\([[:digit:]]\{4\}\)_.*$/\1/")
			JOBNAME_BETA=$(echo $JOBNAME | sed "s/^.*\([[:digit:]]\.[[:digit:]]\{4\}$\)/\1/")

			STATUS="notQueued"	

			if [ $JOBNAME_BETA = $BETA ] && [ $JOBNAME_KAPPA = $KAPPA ] && [ $JOBNAME_NTAU = $NTAU ] && [ $JOBNAME_NSPAT = $NSPAT ]; then

				STATUS=$(llq -l $JOBID | grep "^[[:blank:]]*Status:" | sed "s/^.*Status: \([[:alpha:]].*$\)/\1/")
				#if [ $i = "b5.7500" ]; then echo "break" 
				#fi
				break;
			fi

		done

		#if [ $i = "b5.7500" ]; then echo "after break" 
		#fi

		#----Constructing WORK_BETADIRECTORY, HOME_BETADIRECTORY, JOBSCRIPT_NAME, JOBSCRIPT_GLOBALPATH and INPUTFILE_GLOBALPATH---#
		WORK_BETADIRECTORY="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
		HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
		INPUTFILE_GLOBALPATH="$HOME_BETADIRECTORY/$INPUTFILE_NAME"
		OUTPUTFILE_GLOBALPATH="$WORK_BETADIRECTORY/$OUTPUTFILE_NAME"
		#-------------------------------------------------------------------------------------------------------------------------#

		if [ -d $WORK_BETADIRECTORY ] && [ -f $OUTPUTFILE_GLOBALPATH ]; then

			WORKDIRS_EXIST="true"
		else 

			WORKDIRS_EXIST="false"
		fi

		if [ -d $HOME_BETADIRECTORY ] && [ -f $INPUTFILE_GLOBALPATH ]; then
						
			#if [ $i = "b5.7500" ]; then echo "after break in if" 
			#fi

			TOTAL_NR_TRAJECTORIES=$(grep "Total number of trajectories" $INPUTFILE_GLOBALPATH | grep -o "[[:digit:]]\+")	
			TOTAL_NR_TRAJECTORIES=$(expr $TOTAL_NR_TRAJECTORIES - 0)

			if [ $WORKDIRS_EXIST = "true" ]; then

				TRAJECTORIES_DONE=$(tail -n1 $OUTPUTFILE_GLOBALPATH | grep -o "^[[:digit:]]\{8\}")
				TRAJECTORIES_DONE=$(expr $TRAJECTORIES_DONE + 1)
			else

				TRAJECTORIES_DONE=0
			fi
			MEASUREMENTS_REMAINING=$(expr $TOTAL_NR_TRAJECTORIES - $TRAJECTORIES_DONE)

			if [ $STATUS = "notQueued" ] && [ $MEASUREMENTS_REMAINING -eq "0" ]; then

				STATUS="finished"

			elif [ $STATUS = "notQueued" ] && [ $MEASUREMENTS_REMAINING -ne "0" ] && [ $WORKDIRS_EXIST = "true" ]; then

				STATUS="canceled"
			fi

			#printf "\e[0;34m$BETA \t $TOTAL_NR_TRAJECTORIES \t $TRAJECTORIES_DONE \t $MEASUREMENTS_REMAINING\n\e[0m"
			#26
			printf "\e[0;34m%.4f  %24d  %17d  %22d %s\n\e[0m" "$BETA" "$TOTAL_NR_TRAJECTORIES" "$TRAJECTORIES_DONE" "$MEASUREMENTS_REMAINING" "$STATUS"
			printf "%.4f  %24d  %17d  %22d %s\n" "$BETA" "$TOTAL_NR_TRAJECTORIES" "$TRAJECTORIES_DONE" "$MEASUREMENTS_REMAINING" "$STATUS" >> $JOBS_STATUS_FILE
		fi
		
	done
	printf "\e[0;36m==================================================================================================\n\e[0m"
fi

#------------------------------------------------------------------------------------------------------------------------------#

#--------------------------------------------------Submitting jobs-------------------------------------------------------------#
if [ $SUBMIT = "TRUE" ] || [ $SUBMITONLY = "TRUE" ] || [ $CONTINUE = "TRUE" ] || [[ $CONTINUE =~ [[:digit:]]+ ]]; then
#COMMENT: ####################CHECK IF THE ABOVE IF CONDITION CAN BE LEFT OUT!!!!!!!!!!!!!!!!!!!##########################################

	if [ ${#SUBMIT_BETA_ARRAY[@]} -gt "0" ]; then

		printf "\n\e[0;36m===================================================================================\n\e[0m"
		printf "\e[0;34m Jobs will be submitted for the following beta values:\n\e[0m"
		for i in ${SUBMIT_BETA_ARRAY[@]}; do
			echo "  - $i"
		done
		printf "\e[0;36m===================================================================================\n\e[0m"

		for i in ${SUBMIT_BETA_ARRAY[@]}; do

			#Assigning beta value to BETA variable for readability
			BETA=$i

			#-------------Constructing HOME_BETADIRECTORY, JOBSCRIPT_NAME, JOBSCRIPT_GLOBALPATH-------------------#
			HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
			JOBSCRIPT_NAME="$JOBSCRIPT_PREFIX"_"$CHEMPOT_PREFIX$CHEMPOT"_"$KAPPA_PREFIX$KAPPA"_"$NTAU_PREFIX$NTAU"_"$NSPAT_PREFIX$NSPAT"_"$BETA_PREFIX$BETA"
			JOBSCRIPT_GLOBALPATH=$HOME_BETADIRECTORY/$JOBSCRIPT_NAME
			#-------------------------------------------------------------------------------------------------#

			cd $HOME_BETADIRECTORY
			printf "\n\e[0;34m actual location: $(pwd) \n\e[0m"
			printf "\e[0;34m Submitting:\n\e[0m"
			printf "\e[0;34m llsubmit $JOBSCRIPT_GLOBALPATH\n\e[0m"
			llsubmit $JOBSCRIPT_GLOBALPATH
			cd ..
		done
	else
		printf " \e[1;37;41mNo jobs will be submitted.\e[0m\n"
	fi
fi

#------------------------------------------------------------------------------------------------------------------------------#

#--------------------------------------Printing report for problem betas-------------------------------------------------------#
if [ ${#PROBLEM_BETA_ARRAY[@]} -gt "0" ]; then	
printf "\e[0;31m \n For the following beta values something went wrong \n\e[0m"
printf "\e[0;31m and hence these were left out during file creation and/or job submission:\n\e[0m"

	printf "\n\e[0;31m===================================================================================\n\e[0m"
	printf "\e[0;31m problematic beta values:\n"
	for i in ${PROBLEM_BETA_ARRAY[@]}; do
		echo "  - $i"
	done
	printf "\e[0;31m===================================================================================\n\e[0m"
fi
#------------------------------------------------------------------------------------------------------------------------------#

printf "\e[0;34m \n done..\n\e[0m"

exit 0
