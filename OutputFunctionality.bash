#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

# Useful reference: http://misc.flogisoft.com/bash/tip_colors_and_formatting

#TODO: Some of the functionality used here could be not present in
#      different environment. Probably it should be considered to
#      build some functionality on top. For example, here the 256
#      colors are used but it could be useful to provide a 8 colors
#      only alternative, which is widely supported (mapping the 256
#      used colors back to 8 colors).
#      For the moment we give the possibility to the user to deactivate
#      completely colors, loosing then some database functionality.
#
#TODO: Colors in BaHaMAS have been chosen thinking to dark terminal
#      background. Implement here some functionality to provide a
#      version of colors which are well suited for light bg terminal.

function cecho()
{
    local escape endline format text outputString defaultFormat
    escape="\033["; endline="\n"; defaultFormat="${escape}0m"
    format=''; text=''; outputString=''
    while [ "$1" != '' ]; do
        case "$1" in
            #Font format
            bold         |   B) format="${escape}1m" ;;
            underlined   |   U) format="${escape}4m" ;;
            u-bold       |  uB) format="${escape}21m" ;;
            u-underlined |  uU) format="${escape}24m" ;;
            #Font standard 8 color
            black   | bk) format="${escape}30m" ;;
            red     |  r) format="${escape}31m" ;;
            green   |  g) format="${escape}32m" ;;
            yellow  |  y) format="${escape}33m" ;;
            blue    |  b) format="${escape}34m" ;;
            magenta |  m) format="${escape}35m" ;;
            cyan    |  c) format="${escape}36m" ;;
            gray    | gr) format="${escape}37m" ;;
            #Font standard bright 8 color
            d-gray    | dgr) format="${escape}90m" ;;
            l-red     |  lr) format="${escape}91m" ;;
            l-green   |  lg) format="${escape}92m" ;;
            l-yellow  |  ly) format="${escape}93m" ;;
            l-blue    |  lb) format="${escape}94m" ;;
            l-magenta |  lm) format="${escape}95m" ;;
            l-cyan    |  lc) format="${escape}96m" ;;
            white     |   w) format="${escape}97m" ;;
            #Font 256 colors
            b-blue   | bb) format="${escape}38;5;26m"  ;;
            b-cyan   | bc) format="${escape}38;5;45m"  ;;
            w-green  | wg) format="${escape}38;5;48m"  ;;
            y-green  | yg) format="${escape}38;5;118m" ;;
            purple   |  p) format="${escape}38;5;135m" ;;
            l-purple | lp) format="${escape}38;5;147m" ;;
            pink     | pk) format="${escape}38;5;198m" ;;
            orange   |  o) format="${escape}38;5;202m" ;;
            l-orange | lo) format="${escape}38;5;208m" ;;
            #other possibilities
            default | d) format="${escape}0m" ;;
            -n) endline='' ;;
            -d) defaultFormat='' ;;
            *) text="$1"
        esac
        shift
        if [ "$format" != '' ]; then
            [ "$BaHaMAS_colouredOutput" = 'TRUE' ] && outputString+="$format"
        fi
        if [ "$text" != '' ]; then
            outputString+="$text"
        fi
        format=''; text='' #To avoid to put them again in outputString
    done
    outputString+="$defaultFormat$endline"
    printf "$outputString"
}

function UserSaidYes()
{
    local userAnswer
    while read userAnswer; do
        if [ "$userAnswer" = "Y" ]; then
            return 0
        elif [ "$userAnswer" = "N" ]; then
            return 1
        else
            printf "\n Please enter Y (yes) or N (no): "
        fi
    done
}

function UserSaidNo()
{
    if UserSaidYes; then
        return 1
    else
        return 0
    fi
}


#format="${escape}38;5;9m  " ;;    lr
#format="${escape}38;5;10m " ;;    lg
#format="${escape}38;5;11m " ;;    ly
#format="${escape}38;5;13m " ;;    lm
#format="${escape}38;5;27m " ;;    bb
#format="${escape}38;5;34m " ;;     g
#format="${escape}38;5;39m " ;;     b
#format="${escape}38;5;49m " ;;    wg
#format="${escape}38;5;69m " ;;     b
#format="${escape}38;5;83m " ;;    wg
#format="${escape}38;5;86m " ;;    lc
#format="${escape}38;5;123m" ;;    lc
#format="${escape}38;5;171m" ;;     p
#format="${escape}38;5;207m" ;;    lm
