#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

function __static__AddOptionToHelper()
{
    local name description color lengthOption indentation
    lengthOption=38; indentation='    '
    if [ "$1" = '-e' ]; then
        color="$mutuallyExclusiveColor"; shift
    else
        color="$normalColor"
    fi
    name="$1"; description="$2"; shift 2
    cecho $color "$(printf "%s%-${lengthOption}s" "$indentation" "$name")" d "  ->  " $helperColor "$description"
    while [ "${1:-}" != '' ]; do
        cecho "$(printf "%s%${lengthOption}s" "$indentation" "")      " $helperColor "$1"
        shift
    done
}

function __static__PrintDefault()
{
    if [ "${1:-}" = '' ]; then
        cecho -n -d o 'unset' $helperColor
    else
        #The ' \e[1D' insert a space and then moves back the cursor by one column.
        #This is a hack to avoid not to have $1 printed in case it matches a color
        #option of cecho. TODO: Think about better way!
        cecho -n -d $helperColor " \e[1D$1"
    fi
}

function __static__PrintHelperHeader()
{
    cecho lc '\n'\
          ' #-------------------------------------------------------------------------#\n'\
          ' #         ____              __  __            __  ___   ___     _____     #\n'\
          ' #        / __ )   ____ _   / / / /  ____ _   /  |/  /  /   |   / ___/     #\n'\
          ' #       / __  |  / __ `/  / /_/ /  / __ `/  / /|_/ /  / /| |   \__ \      #\n'\
          ' #      / /_/ /  / /_/ /  / __  /  / /_/ /  / /  / /  / ___ |  ___/ /      #\n'\
          ' #     /_____/   \__,_/  /_/ /_/   \__,_/  /_/  /_/  /_/  |_| /____/       #\n'\
          ' #                                                                         #\n'\
          ' #-------------------------------------------------------------------------#\n'\
          '\n'\
          '     Run BaHaMAS with the ' emph '--setup' ' option to configure the program.\n'\
          '     You will be asked to fill out a form through a self-explainatory,\n'\
          '     rudimental, but functional GUI. The ' emph '--setup' ' option can also be\n'\
          '     used to update and/or complete previous configurations.'\
          '\n'
}

function PrintMainHelper()
{
    local helperColor normalColor mutuallyExclusiveColor
    helperColor='g'; normalColor='m'; mutuallyExclusiveColor='b'
    __static__PrintHelperHeader
    cecho -d $helperColor
    cecho -d "  Call " B "BaHaMAS" uB " with the following optional arguments:" "\n"
    __static__AddOptionToHelper "-h | --help"                   ""
    __static__AddOptionToHelper "--jobscript_prefix"            "default value = $(__static__PrintDefault ${BHMAS_jobScriptPrefix:-})"
    __static__AddOptionToHelper "--chempot_prefix"              "default value = $(__static__PrintDefault ${BHMAS_chempotPrefix:-})"
    __static__AddOptionToHelper "--mass_prefix"                 "default value = $(__static__PrintDefault ${BHMAS_massPrefix:-})"
    __static__AddOptionToHelper "--ntime_prefix"                "default value = $(__static__PrintDefault ${BHMAS_ntimePrefix:-})"
    __static__AddOptionToHelper "--nspace_prefix"               "default value = $(__static__PrintDefault ${BHMAS_nspacePrefix:-})"
    __static__AddOptionToHelper "--beta_prefix"                 "default value = $(__static__PrintDefault ${BHMAS_betaPrefix:-})"
    __static__AddOptionToHelper "--betasfile"                   "default value = $(__static__PrintDefault ${BHMAS_betasFilename:-})"
    __static__AddOptionToHelper "-m | --measurements"           "default value = $(__static__PrintDefault ${BHMAS_numberOfTrajectories:-})"
    __static__AddOptionToHelper "-f | --confSaveFrequency"      "default value = $(__static__PrintDefault ${BHMAS_checkpointFrequency:-})"
    __static__AddOptionToHelper "-F | --confSavePointFrequency" "default value = $(__static__PrintDefault ${BHMAS_savepointFrequency:-})"
    __static__AddOptionToHelper "--cgbs"                        "default value = $(__static__PrintDefault ${BHMAS_inverterBlockSize:-}) (cg_iteration_block_size)"
    __static__AddOptionToHelper "--doNotUseMultipleChains"      "multiple chain usage and nomenclature are disabled"\
                                "(in the betas file the seed column is NOT present)"
    __static__AddOptionToHelper "-p | --doNotMeasurePbp"        "the chiral condensate measurement is switched off"
    __static__AddOptionToHelper "-w | --walltime"               "default value = $(__static__PrintDefault ${BHMAS_walltime:-}) [days-hours:min:sec]"
    __static__AddOptionToHelper "--partition"                   "default value = $(__static__PrintDefault ${BHMAS_clusterPartition:-})"
    __static__AddOptionToHelper "--constraint"                  "default value = $(__static__PrintDefault ${BHMAS_clusterConstraint:-})"
    __static__AddOptionToHelper "--node"                        "default value = $(__static__PrintDefault ${BHMAS_clusterNode:-})"
    cecho ""
    __static__AddOptionToHelper -e "-s | --submit"             "jobs will be submitted"
    __static__AddOptionToHelper -e "--submitonly"              "jobs will be submitted (no files are created)"
    __static__AddOptionToHelper -e "-t | --thermalize"         "The thermalization is done."
    __static__AddOptionToHelper -e "-c[=#] | --continue[=#]"   "Unfinished jobs will be continued doing the nr. of measurements specified in the input"\
                                "file. If a number is specified, jobs will be continued up to the specified number."\
                                "$(cecho "To resume a simulation from a given trajectory, add " bc "r[number]" $helperColor " in the betasfile.")"\
                                "$(cecho "Use " bc "rlast" $helperColor " in the betasfile to resume a simulation from the last saved " p "${BHMAS_configurationPrefix//\\/}[0-9]+" $helperColor " file.")"
    __static__AddOptionToHelper -e "-C[=#] | --continueThermalization[=#]"  "Unfinished thermalizations will be continued doing the nr. of measurements specified in the"\
                                "input file. If a number is specified, thermalizations will be continued up to the specified"\
                                "$(cecho "number. To resume a thermalization from a given trajectory, add " bc "r[number]" $helperColor " in the betasfile.")"\
                                "$(cecho "Use " bc "rlast" $helperColor " in the betasfile to resume a thermalization from the last saved " p "${BHMAS_configurationPrefix//\\/}[0-9]+" $helperColor " file.")"
    __static__AddOptionToHelper -e "-j | --jobstatus" "An overview on the queued jobs will be given"\
                                "$(cecho B "Secondary options" uB ": " $mutuallyExclusiveColor "-u | --user" $helperColor " to get information about a different user")"\
                                "$(cecho "                   " $mutuallyExclusiveColor "-a | --all" $helperColor " to display all queued jobs on the given partition, if specified")"\
                                "$(cecho "                   " $mutuallyExclusiveColor "-l | --local" $helperColor " to display jobs submitted from the present directory")"
    __static__AddOptionToHelper -e "-l | --liststatus" "A report of the local simulation status for all beta will be displayed"\
                                "$(cecho B "Secondary options" uB ": " $mutuallyExclusiveColor "--measureTime" $helperColor " to get information about the trajectory time")"\
                                "$(cecho "                   " $mutuallyExclusiveColor "--showOnlyQueued" $helperColor " not to show status about not queued jobs")"
    __static__AddOptionToHelper -e "--accRateReport[=number]" "The acceptance rates will be computed on the output files of the given beta every "\
                                "1000 trajectories and summarized in a table. If a number is specified, this is used"\
                                "as interval width. Only the acceptance for complete intervals is calculated."
    __static__AddOptionToHelper -e "--cleanOutputFiles" "The output files referred to the betas contained in the betas file are cleaned"\
                                "(repeated lines are eliminated). For safety reason, a backup of the output file is done"\
                                "(it is left in the output file folder with the name outputfilename_date)."\
                                "$(cecho B "Secondary options" uB ": " $mutuallyExclusiveColor "-a | --all" $helperColor " to clean output files for all betas in present folder")"
    __static__AddOptionToHelper -e "--completeBetasFile[=number]" "The beta file is completed adding for each beta new chains in order to have as many"\
                                "chains as specified. If no number is specified, 4 is used. New seeds are randomly drawn."
    __static__AddOptionToHelper -e "-U | --uncommentBetas" "This option uncomments the specified betas (all remaining entries will be commented)."\
                                "The betas can be specified either with a seed or without. The format of the specified string"\
                                "$(cecho "can either contain the output of the " $mutuallyExclusiveColor "--liststatus" $helperColor " option, e.g. " c "5.4380_s5491_NC" $helperColor ", or simply")"\
                                "$(cecho "beta values like " c "5.4380" $helperColor ", or a mix of both. The suffix with the type of the chain is optional.")"\
                                "If pure beta values are given then all seeds of the given beta value will be uncommented."
    __static__AddOptionToHelper -e "-u | --commentBetas" "$(cecho "The reverse option of " $mutuallyExclusiveColor "--uncommentBetas" $helperColor ".")"
    __static__AddOptionToHelper -e "-i | --invertConfigurations" "Invert configurations and produce correlator files for betas and seed specified in the betas file."
    __static__AddOptionToHelper -e "-d | --database" "Update, display and filter database. This is a subprogram plenty of functionality."\
                                "$(cecho "Run this script with the option " $mutuallyExclusiveColor "--helpDatabase" $helperColor " to get an explanation about the various")"\
                                "$(cecho "possibilities. To work with the database, specify the " $mutuallyExclusiveColor "--database" $helperColor " option followed by all")"\
                                "$(cecho "the database options. Differently said, all options given after " $mutuallyExclusiveColor "--database" $helperColor " are options")"\
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


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         __static__AddOptionToHelper\
         __static__PrintDefault\
         __static__PrintHelperHeader\
         PrintMainHelper
