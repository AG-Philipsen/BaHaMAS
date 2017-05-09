#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function __static__CheckAvailabilityOfProgram() {
    if hash $1 2>/dev/null; then
        return 0
    else
        cecho lr "Program " ly $1 lr " was not found, but it is required to run " B "BaHaMAS" uB ". Aborting...\n"; exit -1
    fi
}

function __static__IsFoundVersionOlderThanRequired() {
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

function __static__CheckAboutProgram() {
    local requiredVersion foundVersion program
    program=$1; foundVersion=''
    __static__CheckAvailabilityOfProgram $program
    case $program in
        bash )
            requiredVersion='4.2.53'
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
            cecho lr "Function " B "$FUNCNAME" uB " called with unexpected program! Aborting...\n"; exit -1 ;;
    esac
    if [[ ! $foundVersion =~ ^[0-9]([.0-9])* ]]; then
        cecho ly B "\n WARNING" uB ": Unable to recover " lo "$program" ly " version, skipping check on minimum requirement!"
    else
       if __static__IsFoundVersionOlderThanRequired $requiredVersion $foundVersion; then
           cecho lr "\n Version " ly "$foundVersion" lr " of " ly "$program" lr " was found but version " lg "$requiredVersion" lr " is required!"
           return 1
       fi
    fi
    return 0
}


function CheckSystemRequirements() {
    local programsToBeChecked program returnValue
    returnValue=0
    programsToBeChecked=(bash awk sed)
    for program in ${programsToBeChecked[@]}; do
        __static__CheckAboutProgram $program
        (( returnValue+=$? ))
    done
    if [ $returnValue -gt 0 ]; then
        cecho lr "\n Please (maybe locally) install the required versions of the above programs and run " B "BaHaMAS" uB " again.\n"
        exit -1
    fi
}
