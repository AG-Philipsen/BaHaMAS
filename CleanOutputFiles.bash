function __static__CheckFileForSuspiciousTrajectory()
{
    local FILE_GLOBALPATH="$1"
    #Check whether there is any trajectory repeated but with different observables
    # TODO: Adjust the following line for JUQUEEN where there is the time in the output file!
    local SUSPICIOUS_TRAJECTORY=$(awk '{val=$1; $1=""; array[val]++; if(array[val]>1 && $0 != lineRest[val]){print val; exit}; lineRest[val]=$0}' $FILE_GLOBALPATH)
    if [ "$SUSPICIOUS_TRAJECTORY" != "" ]; then
        cecho o "        Found different lines for same trajectory number! First occurence at trajectory " emph "$SUSPICIOUS_TRAJECTORY"\
              ". The file will be cleaned anyway,\n"\
              "        use the backup file " file "${FILE_GLOBALPATH}_[date]" " in case of need."
    fi
}

function __static__CleanFile()
{
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
        cecho lr "      Problem occurred cleaning file " file "$FILE_GLOBALPATH" "! The value " emph "beta = ${BETA%_*}" " will be skipped!\n"
        mv $FILE_GLOBALPATH_BACKUP $FILE_GLOBALPATH || exit -2
        PROBLEM_BETA_ARRAY+=( $BETA )
        continue
    fi
    cecho lg "        The file " file "${BETA_PREFIX}${FILE_GLOBALPATH##*/$BETA_PREFIX}" " has been successfully cleaned!"\
          " [removed " B "$(($(wc -l < $FILE_GLOBALPATH_BACKUP) - $(wc -l < $FILE_GLOBALPATH)))" uB " line(s)]!"
}


function CleanOutputFiles()
{
    cecho lc B "\n " U "Cleaning" uU ":"
    for BETA in ${BETAVALUES[@]}; do
        #-------------------------------------------------------------------------#
        local WORK_BETADIRECTORY="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
        local MAINFILE_GLOBALPATH="${WORK_BETADIRECTORY}/$OUTPUT_FILENAME"
        local PBPFILE_GLOBALPATH="${MAINFILE_GLOBALPATH}_pbp.dat"
        #-------------------------------------------------------------------------#
        if [ ! -f $MAINFILE_GLOBALPATH ]; then
            cecho lr "\n    File " file "$MAINFILE_GLOBALPATH" " does not exist! The value " emph "beta = ${BETA%_*}" " will be skipped!\n"
            PROBLEM_BETA_ARRAY+=( $BETA )
            continue
        fi

        cecho lc "\n   - $BETA"

        if $(sort --numeric-sort --unique --check=silent --key 1,1 ${MAINFILE_GLOBALPATH}); then
            cecho lm "        The file " file "${BETA_PREFIX}${MAINFILE_GLOBALPATH##*/$BETA_PREFIX}" " has not to be cleaned!"
        else
            __static__CleanFile "$MAINFILE_GLOBALPATH" "TRUE"
        fi

        if [ -f $PBPFILE_GLOBALPATH ]; then
            if $(sort --numeric-sort --unique --check=silent --key 1,1 ${PBPFILE_GLOBALPATH}); then
                cecho lm "        The file " file "${BETA_PREFIX}${PBPFILE_GLOBALPATH##*/$BETA_PREFIX}" " has not to be cleaned!"
            else
                __static__CleanFile "$PBPFILE_GLOBALPATH" "FALSE"
            fi
        fi

    done
}
