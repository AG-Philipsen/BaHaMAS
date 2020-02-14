
function __static__GetSectionLine()
{
    cecho $sectionColor B U "$1" uU ":"
}

function __static__AddSectionLine()
{
    cecho $sectionColor "\n  " "$(__static__GetSectionLine "$1")" "\n"
}

function __static__AddOptionToDatabaseHelper()
{
    local name description lengthOption indentation
    lengthOption=15; indentation='     '
    name="$1"; description="$2"; shift 2
    cecho $groupExclusiveColor "$(printf "%s%-${lengthOption}s" "$indentation" "$name")" d "  ->  " $groupExclusiveColor "$description"
    while [ $# -ne 0 ]; do
        cecho "$(printf "%s%${lengthOption}s" "$indentation" "")      " $groupExclusiveColor "$1"
        shift
    done
}

function PrintDatabaseHelper()
{
    local sectionColor groupExclusiveColor defaultMassParameter
    defaultMassParameter='\e[91m${massPrefix}\e[0m'
    [ "${MASS_PARAMETER:-}" = '' ] && MASS_PARAMETER="$defaultMassParameter"
    declare -A groupColors=( ['DISPLAY']='p' ['UPDATE']='pk' ['REPORT']='lc' ['GENERAL']='o' )
    sectionColor='g'
    __static__AddSectionLine "Displaying options"
    groupExclusiveColor=${groupColors['DISPLAY']}
    __static__AddOptionToDatabaseHelper "-c | --columns" "Specify the columns to be displayed."\
                                        "$(cecho $groupExclusiveColor "Possible columns are: " emph "nf" ", " emph "mu" ", " emph "$MASS_PARAMETER" ", " emph "nt" ", " emph "ns" ", " emph "beta_chain_type" ", " emph "maxDS" ", ")"\
                                        "$(cecho $groupExclusiveColor "                      " emph "maxDP" ", " emph "trajNo" ", " emph "acc" ", " emph "accLast1k" ", " emph "status" ", " emph "lastTraj" ", " emph "timeTraj" ".")"\
                                        "$(cecho "Example:  " lp "-c $MASS_PARAMETER" lp " nt ns beta_chain_type trajNo")"\
                                        "If no columns are specified, all of the above columns will be printed by default."
    __static__AddOptionToDatabaseHelper "--sum" "Summing up the trajectory numbers of each parameter set."
    sectionColor='wg'
    __static__AddSectionLine "Filtering"
    __static__AddOptionToDatabaseHelper "--mu" "Specify filtering values for mu."
    __static__AddOptionToDatabaseHelper "--$MASS_PARAMETER" "Specify filtering values for $MASS_PARAMETER$(cecho -n -d $groupExclusiveColor)."
    __static__AddOptionToDatabaseHelper "--nt"   "Specify filtering values for nt."
    __static__AddOptionToDatabaseHelper "--ns"   "Specify filtering values for ns."
    __static__AddOptionToDatabaseHelper "--beta" "Specify filtering values for beta."
    __static__AddOptionToDatabaseHelper "--type" "Specify filtering values for the type of the simulation (i.e. NC, fC or fH)"
    __static__AddOptionToDatabaseHelper "--traj" "Specify either a minimal or a maximal value or both for the"\
                                        "trajectory number to be filtered for."\
                                        "$(cecho "Example:  " lp "--traj \">10000\" \"<50000\"" $groupExclusiveColor "  (do not forget the " B "quotes" uB ").")"
    __static__AddOptionToDatabaseHelper "--acc" "Specify either a minimal or a maximal value (in percentage) or both for the"\
                                        "acceptance rate to be filtered for."\
                                        "$(cecho "Example:  " lp "--acc \">50.23\" \"<80.1\"" $groupExclusiveColor "  (do not forget the " B "quotes" uB ").")"
    #(NOT YET IMPLEMENTED) __static__AddOptionToDatabaseHelper "--maxDS" "Specify either a minimal or a maximal value or both for the acceptance rate to be filtered for."
    __static__AddOptionToDatabaseHelper "--status" "Specify status value for the corresponding simulation."\
                                        "$(cecho $groupExclusiveColor "Possible values are: " emph "RUNNING" ", " emph "PENDING" ", " emph "notQueued" ".")"
    __static__AddOptionToDatabaseHelper "--lastTraj" "Specify a value in seconds. If the specified value exceeds the value of the"\
                                        "field, the record is not printed."
    sectionColor='g'
    __static__AddSectionLine "Updating database"
    groupExclusiveColor=${groupColors['UPDATE']}
    __static__AddOptionToDatabaseHelper "-u | --update" "Specify this option to (re)create the database file. Optionally, you can"\
                                        ""\
                                        "1) specify a sleep time after which the script repeatedly performs a database update."\
                                        "   The sleep time is a number followed by s = seconds, m = minutes, h = hours, d = days."\
                                        "$(cecho "   Example:  " lp "--update 2h")"\
                                        "2) specify an update time at which the script once per day performs a database update"\
                                        "   The update time format is hh:mm:ss with 24h format for hours. Seconds or minutes"\
                                        "   and seconds can be omitted."\
                                        "$(cecho "   Example:  " lp "--update 07:15" $groupExclusiveColor "  will update the database every day at 07:15:00.")"\
                                        ""\
                                        "It can be useful to run the script in background in a screen session."
    sectionColor='lo'
    __static__AddSectionLine "General options"
    groupExclusiveColor=${groupColors['GENERAL']}
    __static__AddOptionToDatabaseHelper "-f | --file" "This option can be specified for both the updating of the database and the"\
                                        "displaying/filtering of the data."\
                                        ""\
                                        "$(cecho "\e[10D$(__static__GetSectionLine "Updating") " $groupExclusiveColor "If you don't wish the script to simply search for all directories")"\
                                        "containing data, use this option to specify a file with directories"\
                                        "(abosulte paths) in which the script looks for data."\
                                        ""\
                                        "$(cecho "\e[12D$(__static__GetSectionLine "Displaying") " $groupExclusiveColor "If you don't wish the script to use the latest database")"\
                                        "file, use this option to specify a file to display and filter."\
                                        ""
    __static__AddOptionToDatabaseHelper "-l | --local" "To use this option, the script should be called from a position such that"\
                                        "mu, $MASS_PARAMETER$(cecho -n -d $groupExclusiveColor), nt and ns can be extracted from the path. This option will add to"\
                                        "$(cecho "the given ones the " ${groupColors['DISPLAY']} "--mu --$MASS_PARAMETER" ${groupColors['DISPLAY']} " --nt --ns" $groupExclusiveColor " options with the values extracted")"\
                                        "from the path. At the moment it is not compatible with any of such options."
    sectionColor='g'
    __static__AddSectionLine "Report from database"
    groupExclusiveColor=${groupColors['REPORT']}
    __static__AddOptionToDatabaseHelper "-r | --report" "Specify this option to get a colorful report of the simulations"\
                                        "using the last updated database."
    __static__AddSectionLine "Show from database"
    __static__AddOptionToDatabaseHelper "-s | --show" "Specify this option to show a particular set of simulations"\
                                        "using the last updated database. Which set to be displayed"\
                                        "will be asked and can be choosen interactively."
    cecho '\n'
    cecho ly "  " B U\
          "NOTE" uU ":" uB " Please, remember that the " ${groupColors['DISPLAY']} "display" ly ", " ${groupColors['UPDATE']} "update" ly " and " ${groupColors['REPORT']} "report/show" ly " options are not compatible!"
    cecho ''
    if [ $MASS_PARAMETER = "$defaultMassParameter" ]; then
        cecho lr "  " B U\
              "ATTENTION" uU ":" uB lc " Note that " lr "$MASS_PARAMETER" lc " refers to the mass prefix that will be used in simulations (e.g. " ly "mass" lc " or " ly "k" lc ")."
        cecho ''
    fi

}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         __static__GetSectionLine\
         __static__AddSectionLine\
         __static__AddOptionToDatabaseHelper\
         PrintDatabaseHelper
