function SplitCombinedShortOptionsInSingloOptions() {
    local NEW_OPTIONS=()
    for VALUE in "$@"; do
        if [[ $VALUE =~ ^-[[:alpha:]]+(=.*)?$ ]]; then
            if [ $(grep -c "=" <<< "$VALUE") -gt 0 ]; then
                local OPTION_EQUAL_PART=${VALUE##*=}
                VALUE=${VALUE%%=*}
            else
                local OPTION_EQUAL_PART=""
            fi
            local SPLITTED_OPTIONS=( $(grep -o "." <<< "${VALUE:1}") )
            for OPTION in "${SPLITTED_OPTIONS[@]}"; do
                NEW_OPTIONS+=( "-$OPTION" )
            done && unset -v 'OPTION'
            [ "$OPTION_EQUAL_PART" != "" ] && NEW_OPTIONS[${#NEW_OPTIONS[@]}-1]="${NEW_OPTIONS[${#NEW_OPTIONS[@]}-1]}=$OPTION_EQUAL_PART" #Add =.* to last option
        else
            NEW_OPTIONS+=($VALUE)
        fi
    done && unset -v 'VALUE'
    printf "%s " "${NEW_OPTIONS[@]}"
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
    cecho -d " Call the script $0 with the following optional arguments:" "\n"
    __static__AddOptionToHelper "-h | --help"                      ""
    __static__AddOptionToHelper "--jobscript_prefix"               "default value = $JOBSCRIPT_PREFIX"
    __static__AddOptionToHelper "--chempot_prefix"                 "default value = $CHEMPOT_PREFIX"
    __static__AddOptionToHelper "--kappa_prefix"                   "$(cecho "default value = k    " B "(Wilson    Case ONLY)" uB)"
    __static__AddOptionToHelper "--mass_prefix"                    "$(cecho "default value = mass " B "(Staggered Case ONLY)" uB)"
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
    #if [ "$CLUSTER_NAME" = "JUQUEEN" ]; then
    #    cecho -d\
    #          "  --intsteps2                        ->    default value = $INTSTEPS2"                         "\n"\
    #          "  -w | --walltime                    ->    default value = $WALLTIME [hours:min:sec]"          "\n"\
    #          "  --bgsize                           ->    default value = $BGSIZE"                            "\n"\
    #          "  --nrxprocs                         ->    default value = $NRXPROCS"                          "\n"\
    #          "  --nryprocs                         ->    default value = $NRYPROCS"                          "\n"\
    #          "  --nrzprocs                         ->    default value = $NRZPROCS"                          "\n"\
    #          "  --ompnumthreads                    ->    default value = $OMPNUMTHREADS"
    __static__AddOptionToHelper "-p | --doNotMeasurePbp"     "the chiral condensate measurement is switched off"
    __static__AddOptionToHelper "-w | --walltime"            "default value = $WALLTIME [days-hours:min:sec]"
    __static__AddOptionToHelper "--partition"                "default value = $LOEWE_PARTITION"
    __static__AddOptionToHelper "--constraint"               "default value = $LOEWE_CONSTRAINT"
    __static__AddOptionToHelper "--node"                     "default value = automatically assigned"
    __static__AddOptionToHelper "--doNotUseRAfiles" "the Rational Approximations are evaluated (Staggered Case ONLY)"
    cecho ""
    __static__AddOptionToHelper -e "-s | --submit"                "jobs will be submitted"
    __static__AddOptionToHelper -e "--submitonly"                 "jobs will be submitted (no files are created)"
    __static__AddOptionToHelper -e "-t | --thermalize"            "The thermalization is done."
    __static__AddOptionToHelper -e "-c     | --continue"          "Unfinished jobs will be continued doing the nr. of measurements specified in the input"
    __static__AddOptionToHelper -e "-c=[#] | --continue=[#]"      "file .If a number is specified, jobs will be continued up to the specified number."\
                                "$(cecho "To resume a simulation from a given trajectory, add " bc "resumefrom=[number]" $helperColor " in")"\
                                "$(cecho "the betasfile. Use " bc "resumefrom=last" $helperColor " in the betasfile to resume a simulation")"\
                                "$(cecho "from the last saved " p "conf.[[:digit:]]+" $helperColor " file.")"
    __static__AddOptionToHelper -e "-C     | --continueThermalization"      "Unfinished thermalizations will be continued doing the nr. of measurements specified in the"
    __static__AddOptionToHelper -e "-C=[#] | --continueThermalization=[#]"  "input file. If a number is specified, thermalizations will be continued up to the specified"\
                                "$(cecho "number. To resume a thermalization from a given trajectory, add " bc "resumefrom=[number]" $helperColor " in")"\
                                "$(cecho "the betasfile. Use " bc "resumefrom=last" $helperColor " in the betasfile to resume a thermalization")"\
                                "$(cecho "from the last saved " p "conf.[[:digit:]]+" $helperColor " file.")"
    __static__AddOptionToHelper -e "-l | --liststatus" "A report of the local simulation status for all beta will be displayed"\
                                "$(cecho  U "Secondary options" uU ": " $mutuallyExclusiveColor "--measureTime" $helperColor " to get information about the trajectory time")"\
                                "$(cecho "                   " $mutuallyExclusiveColor "--showOnlyQueued" $helperColor " not to show status about not queued jobs")"
    __static__AddOptionToHelper -e "--accRateReport=[#]" "The acceptance rates will be computed on the output files of the given"\
                                "betas every [#] configurations and summarized in a table."
    __static__AddOptionToHelper -e "--cleanOutputFiles" "The output files referred to the betas contained in the betas file are cleaned"\
                                "(repeated lines are eliminated). For safety reason, a backup of the output file is done"\
                                "(it is left in the output file folder with the name outputfilename_date)."\
                                "$(cecho "Secondary options: " $mutuallyExclusiveColor "--all" $helperColor " to clean output files for all betas in present folder")"
    __static__AddOptionToHelper -e "--completeBetasFile[=number]" "The beta file is completed adding for each beta new chains in order to have as many chain as specified."\
                                "$(cecho "If no number is specified, 4 is used. This option, if " $mutuallyExclusiveColor "--doNotUseMultipleChains" $helperColor " has not been given, uses")"\
                                "the seed in the second field to generate new chains (or one new field containing the seed is inserted)."
    __static__AddOptionToHelper -e "-U | --uncommentBetas" "This option uncomments the specified betas (all remaining entries will be commented)."\
                                "The betas can be specified either with a seed or without. The format of the specified string"\
                                "$(cecho "can either contain the output of the " $mutuallyExclusiveColor "--liststatus" $helperColor " option, e.g. " c "5.4380_s5491_NC" $helperColor ", or simply")"\
                                "$(cecho "beta values like " c "5.4380" $helperColor ", or a mix of both. If pure beta values are given then all seeds")"\
                                "of the given beta value will be uncommented."
    __static__AddOptionToHelper -e "-u | --commentBetas" "$(cecho "Is the reverse option of the " $mutuallyExclusiveColor "--uncommentBetas" $helperColor " option")"
    __static__AddOptionToHelper -e "-i | --invertConfigurations" "Invert configurations and produce correlator files for betas and seed specified in the betas file."
    __static__AddOptionToHelper -e "-d | --dataBase" "Update, display and filter database. This is a subprogram plenty of functionalities. Run this script with"\
                                "$(cecho "the option " $mutuallyExclusiveColor "--helpDatabase" $helperColor " to get an explanation about the various possibilities. To work with the database,")"\
                                "$(cecho "specify the " $mutuallyExclusiveColor "--dataBase" $helperColor " option followed by all the database options. Differently said, all options given")"\
                                "$(cecho "after " $mutuallyExclusiveColor "--dataBase" $helperColor " are options for the database subprogram.")"
    cecho ''
    cecho ly B\
          'NOTE:' uB ' The " $mutuallyExclusiveColor "blue options' ly ' are mutually exclusive and they are all ' c 'FALSE' ly ' by default! In other words, if none of them\n'\
          '      is given, the script will try to create beta-folders with the right files inside, but no job will be submitted.'
    cecho ''
    cecho lo B\
          'NOTE:' uB ' Short options can be combined, and one specification via = can be appended to the last short option specified.\n'\
          '      For example ' lc '-dl' lo ' is equivalent to ' lc '-d -l' lo ' and ' lc '-pcm=10000' lo ' is equivalent to ' lc '-p -c -m=10000' lo '.'
    cecho ''
}
