
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
        readonly BHMAS_staggered='TRUE'
    else
        readonly BHMAS_staggered='FALSE'
    fi
    if [ $(grep "[wW]ilson" <<< "$PWD" | wc -l) -gt 0 ]; then
        readonly BHMAS_wilson='TRUE'
    else
        readonly BHMAS_wilson='FALSE'
    fi
    #Parameters positions
    readonly BHMAS_nflavourPosition=0
    readonly BHMAS_chempotPosition=1
    readonly BHMAS_massPosition=2
    readonly BHMAS_ntimePosition=3
    readonly BHMAS_nspacePosition=4
    #Parameters prefixes (here not readonly since they can be changed by user -> set as readonly in command line parser!)
    BHMAS_nflavourPrefix="Nf"
    BHMAS_chempotPrefix="mui"
    [ $BHMAS_wilson = "TRUE" ] && BHMAS_massPrefix="k" || BHMAS_massPrefix="mass"
    BHMAS_ntimePrefix="nt"
    BHMAS_nspacePrefix="ns"
    declare -ga BHMAS_parameterPrefixes=( [$BHMAS_nflavourPosition]=$BHMAS_nflavourPrefix
                                           [$BHMAS_chempotPosition]=$BHMAS_chempotPrefix
                                           [$BHMAS_massPosition]=$BHMAS_massPrefix
                                           [$BHMAS_ntimePosition]=$BHMAS_ntimePrefix
                                           [$BHMAS_nspacePosition]=$BHMAS_nspacePrefix )
    #Parameters variable names (the parameters variables are declared as readonly when reading from path)
    declare -rgA BHMAS_parameterVariableNames=( [$BHMAS_nflavourPrefix]="BHMAS_nflavour"
                                                [$BHMAS_chempotPrefix]="BHMAS_chempot"
                                                [$BHMAS_massPrefix]="BHMAS_mass"
                                                [$BHMAS_ntimePrefix]="BHMAS_ntime"
                                                [$BHMAS_nspacePrefix]="BHMAS_nspace" )
    #Parameters regular expressions
    readonly BHMAS_nflavourRegex='[0-9]\([.][0-9]\)\?'
    readonly BHMAS_chempotRegex='\(0\|PiT\)'
    readonly BHMAS_massRegex='\([0-9][.]\)\?[0-9]\{4\}'
    readonly BHMAS_ntimeRegex='[0-9]\{1,2\}'
    readonly BHMAS_nspaceRegex='[0-9]\{1,2\}'
    declare -rga BHMAS_parameterRegexes=( [$BHMAS_nflavourPosition]=$BHMAS_nflavourRegex
                                          [$BHMAS_chempotPosition]=$BHMAS_chempotRegex
                                          [$BHMAS_massPosition]=$BHMAS_massRegex
                                          [$BHMAS_ntimePosition]=$BHMAS_ntimeRegex
                                          [$BHMAS_nspacePosition]=$BHMAS_nspaceRegex )
    #Parameters path and string (initialized and made readonly later)
    BHMAS_parametersPath=''     # --> e.g. /Nf2/muiPiT/k1550/nt6/ns12    or   /Nf2/mui0/mass0250/nt4/ns8
    BHMAS_parametersString=''   # --> e.g.  Nf2_muiPiT_k1550_nt6_ns12    or    Nf2_mui0_mass0250_nt4_ns8
    #Beta and seed information (intentionally not in arrays of prefixes, regexes, etc.)
    #(here not readonly since they can be changed by user -> set as readonly in command line parser!)
    readonly BHMAS_betaPosition=5
    BHMAS_betaPrefix='b'
    BHMAS_betaPostfix='_continueWithNewChain' #Here we set it supposing it is not a thermalization. If indeed it is, the postfix will be overwritten!
    readonly BHMAS_betaRegex='[0-9][.][0-9]\{4\}'
    BHMAS_seedPrefix='s'
    readonly BHMAS_seedRegex='[0-9]\{4\}'
    BHMAS_betaFolderShortRegex=$BHMAS_betaRegex'_'$BHMAS_seedPrefix'[0-9]\{4\}_[[:alpha:]]\+'
    BHMAS_betaFolderRegex=$BHMAS_betaPrefix$BHMAS_betaFolderShortRegex
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
    BHMAS_betasFilename='betas'
    BHMAS_numberOfTrajectories=20000
    BHMAS_checkpointFrequency=100
    BHMAS_savepointFrequency=20
    BHMAS_inverterBlockSize=50
    BHMAS_useMultipleChains='TRUE'
    BHMAS_measurePbp='TRUE'
    BHMAS_numberOfPseudofermions=1
    readonly JOBS_STATUS_PREFIX='jobs_status_'

    #Internal BaHaMAS variables
    BHMAS_betaValues=()
    BHMAS_betaValuesToBeSubmitted=()
    BHMAS_problematicBetaValues=()
    declare -gA BHMAS_scaleZeroIntegrationSteps=()
    declare -gA BHMAS_scaleOneIntegrationSteps=()
    declare -gA BHMAS_trajectoriesToBeResumedFrom=()
    declare -gA BHMAS_massPreconditioningValues=()
    declare -gA BHMAS_timesPerTrajectory=()
    declare -gA BHMAS_goalStatistics=()
    declare -gA BHMAS_startConfigurationGlobalPath=()

    #Mutually exclusive options variables
    BHMAS_submitOption='FALSE'
    BHMAS_submitonlyOption='FALSE'
    BHMAS_thermalizeOption='FALSE'
    BHMAS_continueOption='FALSE'
    BHMAS_trajectoryNumberUpToWhichToContinue=0
    BHMAS_continueThermalizationOption='FALSE'
    BHMAS_jobstatusOption='FALSE'
    BHMAS_jobstatusUser="$(whoami)"
    BHMAS_jobstatusAll='FALSE'
    BHMAS_jobstatusLocal='FALSE'
    BHMAS_liststatusOption='FALSE'
    BHMAS_liststatusMeasureTimeOption='TRUE'
    BHMAS_liststatusShowOnlyQueuedOption='FALSE'
    BHMAS_accRateReportOption='FALSE'
    BHMAS_accRateReportInterval=1000
    BHMAS_cleanOutputFilesOption='FALSE'
    BHMAS_cleanAllOutputFiles='FALSE'
    BHMAS_completeBetasFileOption='FALSE'
    BHMAS_numberOfChainsToBeInTheBetasFile=4
    BHMAS_uncommentBetasOption='FALSE'
    BHMAS_commentBetasOption='FALSE'
    BHMAS_betasWithSeedToBeToggled=()
    BHMAS_betasToBeToggled=()
    BHMAS_invertConfigurationsOption='FALSE'
    readonly BHMAS_inversionSrunCommandsFilename="srunCommandsFileForInversions"
    readonly BHMAS_correlatorDirection=0
    readonly BHMAS_numberOfSourcesForCorrelators=8
    BHMAS_databaseOption='FALSE'
    BHMAS_optionsToBePassedToDatabase=()

    #Variables for output color
    readonly BHMAS_defaultListstatusColor="\e[0;36m"
    readonly BHMAS_suspiciousBetaListstatusColor="\e[0;33m"
    readonly BHMAS_wrongBetaListstatusColor="\e[0;91m"
    readonly BHMAS_tooHighDeltaSListstatusColor="\e[0;91m"
    readonly BHMAS_tooHighDeltaPListstatusColor="\e[0;91m"
    readonly BHMAS_tooLowAcceptanceListstatusColor="\e[38;5;9m"
    readonly BHMAS_lowAcceptanceListstatusColor="\e[38;5;208m"
    readonly BHMAS_optimalAcceptanceListstatusColor="\e[38;5;10m"
    readonly BHMAS_highAcceptanceListstatusColor="\e[38;5;11m"
    readonly BHMAS_tooHighAcceptanceListstatusColor="\e[38;5;202m"
    readonly BHMAS_runningListstatusColor="\e[0;32m"
    readonly BHMAS_pendingListstatusColor="\e[0;33m"
    readonly BHMAS_toBeCleanedListstatusColor="\e[0;31m"
    readonly BHMAS_stuckSimulationListstatusColor="\e[0;91m"
    readonly BHMAS_fineSimulationListstatusColor="\e[0;32m"

    #Variables for acceptances/deltaS thresholds
    readonly BHMAS_tooLowAcceptanceThreshold=68
    readonly BHMAS_lowAcceptanceThreshold=70
    readonly BHMAS_highAcceptanceThreshold=78
    readonly BHMAS_tooHighAcceptanceThreshold=90
    readonly BHMAS_deltaSThreshold=6
    readonly BHMAS_deltaPThreshold=6

    #Variables to make first step towards independence from software (NO SPACES in them assumed!)
    readonly BHMAS_configurationPrefix='conf\.'
    readonly BHMAS_prngPrefix='prng\.' #tell user about BRE http://en.wikipedia.org/wiki/Regular_expression#POSIX_basic_and_extended
    readonly BHMAS_standardCheckpointPostfix='save'
    readonly BHMAS_checkpointMinimumNumberOfDigits=5
    readonly BHMAS_configurationRegex="${BHMAS_configurationPrefix}[0-9]\+"
    readonly BHMAS_prngRegex="${BHMAS_prngPrefix}[0-9]\+"
}

# The following variables cannot be declared at the
# beginning of BaHaMAS, since they need some information
# which needs to be extracted from the path.
function DeclareBetaFoldersPathsAsGlobalVariables()
{
    readonly BHMAS_submitDirWithBetaFolders="$BHMAS_submitDiskGlobalPath/$BHMAS_projectSubpath$BHMAS_parametersPath"
    readonly BHMAS_runDirWithBetaFolders="$BHMAS_runDiskGlobalPath/$BHMAS_projectSubpath$BHMAS_parametersPath"
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         DeclarePathRelatedGlobalVariables\
         DeclareBaHaMASGlobalVariables\
         DeclareBetaFoldersPathsAsGlobalVariables
