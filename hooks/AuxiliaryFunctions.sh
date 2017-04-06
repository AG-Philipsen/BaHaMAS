#-------------------------------------------------#
# Collection of functions used in the hooks files #
#-------------------------------------------------#

function errecho() {
    local indentation="   "
    if [ $# -eq 1 ]; then
        echo -e -n "$indentation$1\e[0m" 1>&2
    elif [ $# -eq 2 ]; then
        echo -e -n "\e[38;5;$2m$indentation$1\e[0m" 1>&2
    elif [ $# -eq 3 ]; then
        echo -e -n "\e[$2;38;5;$3m$indentation$1\e[0m" 1>&2
    fi
}

#------------------------------------#
# commit-msg hook specific functions #
#------------------------------------#

function GiveAdviceToResumeCommit() {
    errecho 'To resume editing your commit message, run the command:\n\n' 202
    errecho '   git commit -e -F '"$commitMessageFile\n\n" 11
}

function IsCommitMessageEmpty() {
    [ -s "$1" ] && return 1 || return 0
}

function RemoveTrailingSpacesAtBeginOfFirstThreeLines() {
    sed -i -e '1,3{s/^[[:blank:]]*//}' "$1"
}

function RemoveTrailingSpacesAtEndOfEachLine() {
    sed -i -e 's/[[:blank:]]*$//g' "$1"
}

function AddEndOfLineAtEndOfFileIfMissing() {
    #This does not work on empty files, but here it is not!
    [ -z "$(tail -c 1 "$1")" ] || echo '' >> "$1"
}

function CapitalizeFirstLetterFirstLine() {
    sed -i -e  '1s/^\(.\)/\U\1/' "$1"
}

function RemovePointAtTheEndFirstLine() {
    sed -i -e  '1s/[.!?]\+$//g' "$1"
}

function IsCommitMessageAMerge() {
    [ $(cat "$1" | head -1 | grep -c "^Merge ") -gt 0 ] && return 0 || return 1
}

function IsCommitMessageARevert() {
    [ $(cat "$1" | head -1 | grep -c "^Revert ") -gt 0 ] && return 0 || return 1
}

function IsFirstLineNotStartingWithLetter(){ #Assume no trailing spaces, since removed
    [ $(cat "$1" | head -1 | grep -c '^[[:alpha:]]') -gt 0 ] && return 1 || return 0
}

function IsFirstLineTooShort() {
    [ $(cat "$1" | head -1 | grep -c '^.\{7\}') -gt 0 ] && return 1 || return 0
}

function IsFirstLineTooLong() {
    [ $(cat "$1" | head -1 | grep -c '^..\{60\}') -gt 0 ]  && return 0 || return 1
}

function IsSecondLineNotEmpty() {
    [ $(wc -l < "$1") -lt 2 ] && return 1 #Needed otherwise head and tail below match first line
    [ $(cat "$1" | head -2 | tail -1 | grep -c '^[[:blank:]]*$') -gt 0 ]  && return 1 || return 0
}

function IsAnyOfTheLinesAfterTheSecondTooLong() {
    [ $(cat "$1" | tail -n +2 | grep -c '^..\{72\}') -gt 0 ] && return 0 || return 1
}

function PrintHookFailure() {
    errecho '\n'
    errecho 'HOOK FAILURE (commit-msg):' 1 9
    errecho "$@\n" 9
    errecho '\n'
}

function AbortCommit() {
    PrintHookFailure "$@"
    GiveAdviceToResumeCommit
    exit 1
}
