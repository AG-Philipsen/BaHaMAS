#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

function __static__CheckAvailabilityOfProgram()
{
    if hash $1 2>/dev/null; then
        return 0
    else
        Fatal $BHMAS_fatalRequirement "Program " emph "$1" " was not found, but it is required to run " B "BaHaMAS" uB "."
    fi
}

function __static__IsFoundVersionOlderThanRequired()
{
    [ $1 = $2 ] && return 1
    #Here I suppose 'sort -V' is available, even though it is part
    #of Linux coreutils. In any case we use coreutils functionalities
    #around in BaHaMAS and at the moment we do not make further checks.
    local foundVersion requiredVersion newerVersion
    requiredVersion=$1; foundVersion=$2
    newerVersion=$(printf '%s\n%s' $requiredVersion $foundVersion | sort -V | tail -n1)
    if [ $newerVersion = $requiredVersion ]; then
        return 0
    else
        return 1
    fi
}

function __static__CheckAboutProgram()
{
    local requiredVersion foundVersion program
    program=$1; foundVersion=''
    __static__CheckAvailabilityOfProgram $program
    case $program in
        bash )
            requiredVersion='4.3.30'
            foundVersion="$(sed 's/ /./g' <<< "${BASH_VERSINFO[@]:0:3}")"
            ;;
        awk )
            requiredVersion='3.1.7'
            if awk --version >/dev/null 2>&1; then
                foundVersion=$(awk --version | head -n1 | grep -o "^GNU Awk [0-9.]\+" | grep -o "[0-9.]\+")
            fi
            ;;
        sed )
            requiredVersion='4.2.1'
            if sed --version >/dev/null 2>&1; then
                foundVersion=$(sed --version | head -n1 | grep -o "[0-9.]\+")
            fi
            ;;
        *)
            Internal "Function " B "$FUNCNAME" uB " called with unexpected program!" ;;
    esac
    if [[ ! $foundVersion =~ ^[0-9]([.0-9])* ]]; then
        Warning "Unable to recover " emph "$program" " version, skipping check on minimum requirement!"
    else
        if __static__IsFoundVersionOlderThanRequired $requiredVersion $foundVersion; then
            Error "Version " emph "$foundVersion" " of " emph "$program" " was found but version " emph "$requiredVersion" " is required!"
            return 1
        fi
    fi
    return 0
}


function CheckSystemRequirements()
{
    local programsToBeChecked program returnValue
    returnValue=0
    programsToBeChecked=(bash awk sed)
    for program in ${programsToBeChecked[@]}; do
        __static__CheckAboutProgram $program
        (( returnValue+=$? )) || true #'|| true' because of set -e option
    done
    if [ $returnValue -gt 0 ]; then
        cecho -n "\e[1A"
        Fatal $BHMAS_fatalRequirement "Please (maybe locally) install the required versions of the above programs and run " B "BaHaMAS" uB " again."
    fi
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         __static__CheckAvailabilityOfProgram\
         __static__IsFoundVersionOlderThanRequired\
         __static__CheckAboutProgram\
         CheckSystemRequirements
