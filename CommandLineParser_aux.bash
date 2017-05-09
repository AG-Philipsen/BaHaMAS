
#NOTE: We want to discard a potential equal sign between option name
#      and option value, but still we want to allow a potential equal
#      sign in the option value. Hence it is wrong to blindly replace
#      all the equal signs by spaces. We then iterate over the command
#      line arguments and
#       1) If the argument starts with '-' we remove only the first equal
#          sign, if present
#       2) If the argument does not start with '-' then we remove an equal
#          sign, only if it is present as first character of the argument
#
#NOTE: The following two functions will be used with readarray and therefore
#      the printf in the end uses '\n' as separator (this preserves spaces
#      in options)
function PrepareGivenOptionToBeProcessed(){
    local newOptions value tmp
    newOptions=()
    for value in "$@"; do
        [ "$value" = '=' ] && continue
        if [[ $value =~ ^-.*=.* ]]; then
            tmp="$(sed 's/=/ /' <<< "$value")"
            newOptions+=( ${tmp%% *} )  #Part before '=' without spaces (option name)
            newOptions+=( "${tmp#* }" ) #Part after '=' potentially with spaces
        else
            newOptions+=( "$(sed 's/^=//' <<< "$value")" )
        fi
    done
    printf "%s\n" "${newOptions[@]}"
}

function SplitCombinedShortOptionsInSingleOptions() {
    local newOptions value option splittedOptions
    newOptions=()
    for value in "$@"; do
        if [[ $value =~ ^-[[:alpha:]]+$ ]]; then
            splittedOptions=( $(grep -o "." <<< "${value:1}") )
            for option in "${splittedOptions[@]}"; do
                newOptions+=( "-$option" )
            done
        else
            newOptions+=( "$value" )
        fi
    done
    printf "%s\n" "${newOptions[@]}"
}


function __static__AddOptionToHelper() {
    local name description color lengthOption indentation
    lengthOption=38; indentation='    '
    if [ "$1" = '-e' ]; then
        color="$mutuallyExclusiveColor"; shift
    else
        color="$normalColor"
    fi
    name="$1"; description="$2"; shift 2
    cecho $color "$(printf "%s%-${lengthOption}s" "$indentation" "$name")" d "  ->  " $helperColor "$description"
    while [ "$1" != '' ]; do
        cecho "$(printf "%s%${lengthOption}s" "$indentation" "")      " $helperColor "$1"
        shift
    done
}

function PrintHelper(){
    local helperColor normalColor mutuallyExclusiveColor
    helperColor='g'; normalColor='m'; mutuallyExclusiveColor='b'
    cecho -d $helperColor
    cecho -d " Call " B "BaHaMAS" uB " with the following optional arguments:" "\n"
    __static__AddOptionToHelper "-h | --help"                      ""
    __static__AddOptionToHelper "--jobscript_prefix"               "default value = $JOBSCRIPT_PREFIX"
    __static__AddOptionToHelper "--chempot_prefix"                 "default value = $CHEMPOT_PREFIX"
    __static__AddOptionToHelper "--mass_prefix"                    "default value = $MASS_PREFIX"
    __static__AddOptionToHelper "--ntime_prefix"                   "default value = $NTIME_PREFIX"
    __static__AddOptionToHelper "--nspace_prefix"                  "default value = $NSPACE_PREFIX"
    __static__AddOptionToHelper "--beta_prefix"                    "default value = $BETA_PREFIX"
    __static__AddOptionToHelper "--betasfile"                      "default value = $BETASFILE"
    __static__AddOptionToHelper "-m | --measurements"              "default value = $MEASUREMENTS"
    __static__AddOptionToHelper "-f | --confSaveFrequency"         "default value = $NSAVE"
    __static__AddOptionToHelper "-F | --confSavePointFrequency"    "default value = $NSAVEPOINT"
    __static__AddOptionToHelper "--intsteps0"                      "default value = $INTSTEPS0"
    __static__AddOptionToHelper "--intsteps1"                      "default value = $INTSTEPS1"
    __static__AddOptionToHelper "--cgbs"                           "default value = $CGBS (cg_iteration_block_size)"
    __static__AddOptionToHelper "--doNotUseMultipleChains"         "multiple chain usage and nomenclature are disabled"\
                                "(in the betas file the seed column is NOT present)"
    __static__AddOptionToHelper "-p | --doNotMeasurePbp"     "the chiral condensate measurement is switched off"
    __static__AddOptionToHelper "-w | --walltime"            "default value = $WALLTIME [days-hours:min:sec]"
    __static__AddOptionToHelper "--partition"                "default value = '$CLUSTER_PARTITION'"
    __static__AddOptionToHelper "--constraint"               "default value = '$CLUSTER_CONSTRAINT'"
    __static__AddOptionToHelper "--node"                     "default value = '$CLUSTER_NODE'"
    cecho ""
    __static__AddOptionToHelper -e "-s | --submit"                "jobs will be submitted"
    __static__AddOptionToHelper -e "--submitonly"                 "jobs will be submitted (no files are created)"
    __static__AddOptionToHelper -e "-t | --thermalize"            "The thermalization is done."
    __static__AddOptionToHelper -e "-c     | --continue"          "Unfinished jobs will be continued doing the nr. of measurements specified in the input"
    __static__AddOptionToHelper -e "-c[=#] | --continue[=#]"      "file. If a number is specified, jobs will be continued up to the specified number."\
                                "$(cecho "To resume a simulation from a given trajectory, add " bc "resumefrom=[number]" $helperColor " in")"\
                                "$(cecho "the betasfile. Use " bc "resumefrom=last" $helperColor " in the betasfile to resume a simulation")"\
                                "$(cecho "from the last saved " p "conf.[[:digit:]]+" $helperColor " file.")"
    __static__AddOptionToHelper -e "-C     | --continueThermalization"      "Unfinished thermalizations will be continued doing the nr. of measurements specified in the"
    __static__AddOptionToHelper -e "-C[=#] | --continueThermalization[=#]"  "input file. If a number is specified, thermalizations will be continued up to the specified"\
                                "$(cecho "number. To resume a thermalization from a given trajectory, add " bc "resumefrom=[number]" $helperColor " in")"\
                                "$(cecho "the betasfile. Use " bc "resumefrom=last" $helperColor " in the betasfile to resume a thermalization")"\
                                "$(cecho "from the last saved " p "conf.[[:digit:]]+" $helperColor " file.")"
    __static__AddOptionToHelper -e "-l | --liststatus" "A report of the local simulation status for all beta will be displayed"\
                                "$(cecho  B "Secondary options" uB ": " $mutuallyExclusiveColor "--measureTime" $helperColor " to get information about the trajectory time")"\
                                "$(cecho "                   " $mutuallyExclusiveColor "--showOnlyQueued" $helperColor " not to show status about not queued jobs")"
    __static__AddOptionToHelper -e "--accRateReport[=number]" "The acceptance rates will be computed on the output files of the given beta every "\
                                "1000 trajectories and summarized in a table. If a number is specified, this is used"\
                                "as interval width. Only the acceptance for complete intervals is calculated."
    __static__AddOptionToHelper -e "--cleanOutputFiles" "The output files referred to the betas contained in the betas file are cleaned"\
                                "(repeated lines are eliminated). For safety reason, a backup of the output file is done"\
                                "(it is left in the output file folder with the name outputfilename_date)."\
                                "$(cecho "Secondary options: " $mutuallyExclusiveColor "--all" $helperColor " to clean output files for all betas in present folder")"
    __static__AddOptionToHelper -e "--completeBetasFile[=number]" "The beta file is completed adding for each beta new chains in order to have as many"\
                                "chain as specified. If no number is specified, 4 is used. This option, if"\
                                "$(cecho $mutuallyExclusiveColor "--doNotUseMultipleChains" $helperColor " has not been given, uses the seed in the second field to")"\
                                "generate new chains (or one new field containing the seed is inserted)."
    __static__AddOptionToHelper -e "-U | --uncommentBetas" "This option uncomments the specified betas (all remaining entries will be commented)."\
                                "The betas can be specified either with a seed or without. The format of the specified string"\
                                "$(cecho "can either contain the output of the " $mutuallyExclusiveColor "--liststatus" $helperColor " option, e.g. " c "5.4380_s5491_NC" $helperColor ", or simply")"\
                                "$(cecho "beta values like " c "5.4380" $helperColor ", or a mix of both. If pure beta values are given then all seeds")"\
                                "of the given beta value will be uncommented."
    __static__AddOptionToHelper -e "-u | --commentBetas" "$(cecho "The reverse option of " $mutuallyExclusiveColor "--uncommentBetas" $helperColor ".")"
    __static__AddOptionToHelper -e "-i | --invertConfigurations" "Invert configurations and produce correlator files for betas and seed specified in the betas file."
    __static__AddOptionToHelper -e "-d | --dataBase" "Update, display and filter database. This is a subprogram plenty of functionality."\
                                "$(cecho "Run this script with the option " $mutuallyExclusiveColor "--helpDatabase" $helperColor " to get an explanation about the various")"\
                                "$(cecho "possibilities. To work with the database, specify the " $mutuallyExclusiveColor "--dataBase" $helperColor " option followed by all")"\
                                "$(cecho "the database options. Differently said, all options given after " $mutuallyExclusiveColor "--dataBase" $helperColor " are options")"\
                                "for the database subprogram."
    cecho ''
    cecho ly B\
          'NOTE:' uB " The " $mutuallyExclusiveColor "blue options" ly ' are mutually exclusive and they are all ' c 'FALSE' ly ' by default! In other words, if none of them\n'\
          '      is given, the script will try to create beta-folders with the right files inside, but no job will be submitted.'
    cecho ''
    cecho lo B\
          'NOTE:' uB ' Short options can be combined, and one specification via = can be appended to the last short option specified.\n'\
          '      For example ' lc '-dl' lo ' is equivalent to ' lc '-d -l' lo ' and ' lc '-pcm=10000' lo ' is equivalent to ' lc '-p -c -m=10000' lo '.'
    cecho ''
}
