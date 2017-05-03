function __static__CheckFileForSuspiciousTrajectory(){
    local FILE_GLOBALPATH="$1"
    #Check whether there is any trajectory repeated but with different observables
    # TODO: Adjust the following line for JUQUEEN where there is the time in the output file!
    local SUSPICIOUS_TRAJECTORY=$(awk '{val=$1; $1=""; array[val]++; if(array[val]>1 && $0 != lineRest[val]){print val; exit}; lineRest[val]=$0}' $FILE_GLOBALPATH)
    if [ "$SUSPICIOUS_TRAJECTORY" != "" ]; then
        printf "        \e[38;5;202mFound different lines for same trajectory number! First occurence at trajectory $SUSPICIOUS_TRAJECTORY. The file will be cleaned anyway,\n"
        printf "        use the backup file \"${FILE_GLOBALPATH}_[date]\" in case of need.\n\e[0m"
    fi
}

function __static__CleanFile(){
    local FILE_GLOBALPATH="$1"
    local CHECK_FOR_SUSPICIOUS_TR="$2"
    #Do a backup of the file
    local FILE_GLOBALPATH_BACKUP="${FILE_GLOBALPATH}_$(date +'%F_%H%M')"
    cp $FILE_GLOBALPATH $FILE_GLOBALPATH_BACKUP || exit -2

    if [ "$CHECK_FOR_SUSPICIOUS_TR" = "TRUE" ]; then
        __static__CheckFileForSuspiciousTrajectory $FILE_GLOBALPATH
    fi
    #Use sort command to clean the file: note that it is safe to give same input and output since the input file is read and THEN overwritten
    sort --numeric-sort --unique --key 1,1 --output=${FILE_GLOBALPATH} ${FILE_GLOBALPATH}
    if [ $? -ne 0 ]; then
        printf "\e[0;31m        Problem occurred cleaning file \"$FILE_GLOBALPATH\"! Leaving out beta = ${BETA%_*} .\n\n\e[0m"
        mv $FILE_GLOBALPATH_BACKUP $FILE_GLOBALPATH || exit -2
        PROBLEM_BETA_ARRAY+=( $BETA )
        continue
    fi
    printf "\e[0;92m        The file \"${BETA_PREFIX}${FILE_GLOBALPATH##*/$BETA_PREFIX}\" has been successfully cleaned!"
    printf " [removed $(($(wc -l < $FILE_GLOBALPATH_BACKUP) - $(wc -l < $FILE_GLOBALPATH))) line(s)]!\n\e[0m"
}


function CleanOutputFiles()
{
    printf "\n\e[1;36m \e[4mCleaning\e[0m\e[1;36m:\n\e[0m"
    for BETA in ${BETAVALUES[@]}; do
        #-------------------------------------------------------------------------#
        local WORK_BETADIRECTORY="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
        local MAINFILE_GLOBALPATH="${WORK_BETADIRECTORY}/$OUTPUTFILE_NAME"
        local PBPFILE_GLOBALPATH="${MAINFILE_GLOBALPATH}_pbp.dat"
        #-------------------------------------------------------------------------#
        if [ ! -f $MAINFILE_GLOBALPATH ]; then
            printf "\n\e[0;31m    File \"$MAINFILE_GLOBALPATH\" not existing! Leaving out beta = ${BETA%_*} .\n\e[0m"
            PROBLEM_BETA_ARRAY+=( $BETA )
            continue
        fi

        printf "\n   \e[1;36m- $BETA\n\e[0m"

        if $(sort --numeric-sort --unique --check=silent --key 1,1 ${MAINFILE_GLOBALPATH}); then
            printf "\e[38;5;13m        The file \"${BETA_PREFIX}${MAINFILE_GLOBALPATH##*/$BETA_PREFIX}\" has not to be cleaned!\n\e[0m"
        else
            __static__CleanFile "$MAINFILE_GLOBALPATH" "TRUE"
        fi

        if [ -f $PBPFILE_GLOBALPATH ]; then
            if $(sort --numeric-sort --unique --check=silent --key 1,1 ${PBPFILE_GLOBALPATH}); then
                printf "\e[38;5;13m        The file \"${BETA_PREFIX}${PBPFILE_GLOBALPATH##*/$BETA_PREFIX}\" has not to be cleaned!\n\e[0m"
            else
                __static__CleanFile "$PBPFILE_GLOBALPATH" "FALSE"
            fi
        fi

    done
}
