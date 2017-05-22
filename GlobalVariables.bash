#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

#----------------------------------------------------------------------------------#
# Variables about operations on path. For the moment we hard-code the existence    #
# of 5 parameters and of their order in the path. Maybe there is an elegant        #
# way to generalize this feature of BaHaMAS, but at the moment we leave it so.     #
#                                                                                  #
# NOTE: Since we have 5 parameters (Nf, kappa, mu, ns, nt), in principle there     #
#       are 5!=120 possible orders. Here we fix the order using an array.          #
#                                                                                  #
# ATTENTION: For the moment, BaHaMAS is built ad hoc for CL2QCD and since the      #
#            algorithms to be run for staggered and Wilson fermions are rather     #
#            different, we introduce here two variables to detect in which         #
#            situation we are. The idea is that only one variable must be 'TRUE'   #
#            and this can also be used to bypass the distinction in case it        #
#            is not needed. Note that the use of two variables can be thought      #
#            to be an overhead since in principle a single variable would be       #
#            enough. Actually, having two variables increases readability of       #
#            the code and this approach is open to future new cases.               #
#----------------------------------------------------------------------------------#

#NOTE: Here we want to use 'readonly' for variable which are constant and global,
#      but we must use 'declare' instead of 'readonly' for arrays since they seem to
#      stay local and not global with the 'readonly' keyword
#      http://gnu-bash.2382.n7.nabble.com/4-4-5-trouble-declaring-readonly-array-variables-td18385.html
#      http://lists.gnu.org/archive/html/bug-bash/2015-11/msg00140.html
function DeclarePathRelatedGlobalVariables()
{
    #Setting of the correct formulation based on the path.
    if [ $(grep "[sS]taggered" <<< "$PWD" | wc -l) -gt 0 ]; then
        readonly STAGGERED='TRUE'
    else
        readonly STAGGERED='FALSE'
    fi
    if [ $(grep "[wW]ilson" <<< "$PWD" | wc -l) -gt 0 ]; then
        readonly WILSON='TRUE'
    else
        readonly WILSON='FALSE'
    fi
    #Parameters positions
    readonly NFLAVOUR_POSITION=0
    readonly CHEMPOT_POSITION=1
    readonly MASS_POSITION=2
    readonly NTIME_POSITION=3
    readonly NSPACE_POSITION=4
    #Parameters prefixes
    readonly NFLAVOUR_PREFIX="Nf"
    readonly CHEMPOT_PREFIX="mui"
    [ $WILSON = "TRUE" ] && readonly MASS_PREFIX="k" || readonly MASS_PREFIX="mass"
    readonly NTIME_PREFIX="nt"
    readonly NSPACE_PREFIX="ns"
    declare -rga PARAMETER_PREFIXES=( [$NFLAVOUR_POSITION]=$NFLAVOUR_PREFIX
                                      [$CHEMPOT_POSITION]=$CHEMPOT_PREFIX
                                      [$MASS_POSITION]=$MASS_PREFIX
                                      [$NTIME_POSITION]=$NTIME_PREFIX
                                      [$NSPACE_POSITION]=$NSPACE_PREFIX )
    #Parameters variable names (declred as readonly when reading from path)
    declare -rgA PARAMETER_VARIABLE_NAMES=( [$NFLAVOUR_PREFIX]="NFLAVOUR"
                                            [$CHEMPOT_PREFIX]="CHEMPOT"
                                            [$MASS_PREFIX]="MASS"
                                            [$NTIME_PREFIX]="NTIME"
                                            [$NSPACE_PREFIX]="NSPACE" )
    #Parameters regular expressions
    readonly NFLAVOUR_REGEX='[[:digit:]]\([.][[:digit:]]\)\?'
    readonly CHEMPOT_REGEX='\(0\|PiT\)'
    readonly MASS_REGEX='[[:digit:]]\{4\}'
    readonly NTIME_REGEX='[[:digit:]]\{1,2\}'
    readonly NSPACE_REGEX='[[:digit:]]\{1,2\}'
    declare -rga PARAMETER_REGEXES=( [$NFLAVOUR_POSITION]=$NFLAVOUR_REGEX
                                     [$CHEMPOT_POSITION]=$CHEMPOT_REGEX
                                     [$MASS_POSITION]=$MASS_REGEX
                                     [$NTIME_POSITION]=$NTIME_REGEX
                                     [$NSPACE_POSITION]=$NSPACE_REGEX )
    #Parameters path and string (initialized and made readonly later)
    PARAMETERS_PATH=''     # --> e.g. /Nf2/muiPiT/k1550/nt6/ns12    or   /Nf2/mui0/mass0250/nt4/ns8
    PARAMETERS_STRING=''   # --> e.g.  Nf2_muiPiT_k1550_nt6_ns12    or    Nf2_mui0_mass0250_nt4_ns8
    #Beta and seed information
    readonly BETA_POSITION=5
    readonly BETA_PREFIX="b"
    BETA_POSTFIX='_continueWithNewChain' #Here we set it supposing it is not a thermalization. If indeed it is, the postfix will be overwritten!
    readonly BETA_REGEX='[[:digit:]][.][[:digit:]]\{4\}'
    readonly SEED_PREFIX="s"
    readonly SEED_REGEX='[[:digit:]]\{4\}'
    readonly BETA_FOLDER_SHORT_REGEX=$BETA_REGEX'_'$SEED_PREFIX'[[:digit:]]\{4\}_[[:alpha:]]\+'
    readonly BETA_FOLDER_REGEX=$BETA_PREFIX$BETA_FOLDER_SHORT_REGEX
}

#----------------------------------------------------------------------------------#
# The following variables are instead for BaHaMAS functionality. Most of them      #
# are needed for the command line options and the main branches of the flow of     #
# the code. Some are just about the coloured output, while some others are simply  #
# necessary for the implementation of the different features.                      #
#----------------------------------------------------------------------------------#

function DeclareBaHaMASGlobalVariables()
{

    #Variables about general options
    BETASFILE='betas'
    MEASUREMENTS=20000
    NSAVE=100
    NSAVEPOINT=20
    INTSTEPS0=7
    INTSTEPS1=5
    INTSTEPS2=5
    CGBS=50
    USE_MULTIPLE_CHAINS='TRUE'
    MEASURE_PBP='TRUE'
    readonly JOBS_STATUS_PREFIX='jobs_status_'

    #Internal BaHaMAS variables
    readonly BaHaMAS_clusterScheduler="$(SelectClusterSchedulerName)"
    SUBMIT_BETA_ARRAY=()
    PROBLEM_BETA_ARRAY=()
    declare -gA INTSTEPS0_ARRAY
    declare -gA INTSTEPS1_ARRAY
    declare -gA CONTINUE_RESUMETRAJ_ARRAY
    declare -gA MASS_PRECONDITIONING_ARRAY
    declare -gA STARTCONFIGURATION_GLOBALPATH

    #Mutually exclusive options variables
    SUBMIT='FALSE'
    SUBMITONLY='FALSE'
    THERMALIZE='FALSE'
    CONTINUE='FALSE'
    CONTINUE_NUMBER=0
    CONTINUE_THERMALIZATION='FALSE'
    LISTSTATUS='FALSE'
    LISTSTATUS_MEASURE_TIME='FALSE'
    LISTSTATUS_SHOW_ONLY_QUEUED='FALSE'
    ACCRATE_REPORT='FALSE'
    INTERVAL=1000
    CLEAN_OUTPUT_FILES='FALSE'
    SECONDARY_OPTION_ALL='FALSE'
    COMPLETE_BETAS_FILE='FALSE'
    NUMBER_OF_CHAINS_TO_BE_IN_THE_BETAS_FILE=4
    UNCOMMENT_BETAS='FALSE'
    COMMENT_BETAS='FALSE'
    UNCOMMENT_BETAS_SEED_ARRAY=()
    UNCOMMENT_BETAS_ARRAY=()
    INVERT_CONFIGURATIONS='FALSE'
    readonly SRUN_COMMANDSFILE_FOR_INVERSION="srunCommandsFileForInversions"
    readonly CORRELATOR_DIRECTION="0"
    readonly NUMBER_SOURCES_FOR_CORRELATORS="8"
    CALL_DATABASE='FALSE'
    DATABASE_OPTIONS=()

    #Variables for output color
    readonly DEFAULT_LISTSTATUS_COLOR="\e[0;36m"
    readonly SUSPICIOUS_BETA_LISTSTATUS_COLOR="\e[0;33m"
    readonly WRONG_BETA_LISTSTATUS_COLOR="\e[0;91m"
    readonly TOO_HIGH_DELTA_S_LISTSTATUS_COLOR="\e[0;91m"
    readonly TOO_LOW_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;9m"
    readonly LOW_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;208m"
    readonly OPTIMAL_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;10m"
    readonly HIGH_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;11m"
    readonly TOO_HIGH_ACCEPTANCE_LISTSTATUS_COLOR="\e[38;5;202m"
    readonly RUNNING_LISTSTATUS_COLOR="\e[0;32m"
    readonly PENDING_LISTSTATUS_COLOR="\e[0;33m"
    readonly CLEANING_LISTSTATUS_COLOR="\e[0;31m"
    readonly STUCK_SIMULATION_LISTSTATUS_COLOR="\e[0;91m"
    readonly FINE_SIMULATION_LISTSTATUS_COLOR="\e[0;32m"

    #Variables for acceptances/deltaS thresholds
    readonly TOO_LOW_ACCEPTANCE_THRESHOLD=68
    readonly LOW_ACCEPTANCE_THRESHOLD=70
    readonly HIGH_ACCEPTANCE_THRESHOLD=78
    readonly TOO_HIGH_ACCEPTANCE_THRESHOLD=90
    readonly DELTA_S_THRESHOLD=6
}

# The following variables cannot be declared at the
# beginning of BaHaMAS, since they need some information
# which needs to be extracted from the path.
function DeclareBetaFoldersPathsAsGlobalVariables()
{
    readonly HOME_DIR_WITH_BETAFOLDERS="$SUBMIT_DISK_GLOBALPATH/$PROJECT_SUBPATH$PARAMETERS_PATH"
    readonly WORK_DIR_WITH_BETAFOLDERS="$RUN_DISK_GLOBALPATH/$PROJECT_SUBPATH$PARAMETERS_PATH"
}
