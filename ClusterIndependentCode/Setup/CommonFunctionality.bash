
function AbortSetupProcess()
{
    Fatal $BHMAS_fatalGeneric 'BaHaMAS setup has been aborted! Consider to rerun it, if needed.'
}

function SetColoredOutput()
{
    BHMAS_coloredOutput="$1"
    userVariables['BHMAS_coloredOutput']="$BHMAS_coloredOutput"
}

function FireUpTheDialogBoxStoringResultAndActingAccordingly()
{
    local functionToBeCalledOnSuccess functionToBeCalledOnCancel\
          dialogOk dialogCancel dialogHelp dialogExtra\
          dialogItemHelp dialogEsc returnValue
    functionToBeCalledOnSuccess="$1"
    functionToBeCalledOnCancel="$2"
    dialogOk=0; dialogCancel=1; dialogEsc=255
    dialogHelp=2; dialogExtra=3; dialogItemHelp=4 #These only in dialog not in whiptail
    #Use new file descriptor to get dialog output
    exec 3>&1
    set +e
    resultOfBox=$(eval $commandToBeExecuted 2>&1 1>&3)
    returnValue=$?
    set -e
    exec 3>&-
    case $returnValue in
        $dialogOk)
            $functionToBeCalledOnSuccess ;;
        $dialogCancel)
            $functionToBeCalledOnCancel ;;
        $dialogHelp)
            Internal "Help button pressed, but unexpected!" ;;
        $dialogExtra)
            Internal "Extra button pressed, but unexpected!" ;;
        $dialogItemHelp)
            Internal "Item-help button pressed, but unexpected!" ;;
        $dialogEsc)
            AbortSetupProcess ;;
    esac
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         AbortSetupProcess\
         SetColoredOutput\
         FireUpTheDialogBoxStoringResultAndActingAccordingly
