#
#  Copyright (c) 2015,2017,2020 Alessandro Sciarra
#
#  This file is part of BaHaMAS.
#
#  BaHaMAS is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  BaHaMAS is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with BaHaMAS. If not, see <http://www.gnu.org/licenses/>.
#

function __static__CheckFileForSuspiciousTrajectory()
{
    local FILE_GLOBALPATH="$1"
    #Check whether there is any trajectory repeated but with different observables
    # TODO: Adjust the following line for codes where there is the time in the output file,
    #       or in general where there are entries in a line that repeating the same
    #       trajectory could change!
    local SUSPICIOUS_TRAJECTORY=$(awk '{val=$1; $1=""; array[val]++; if(array[val]>1 && $0 != lineRest[val]){print val; exit}; lineRest[val]=$0}' $FILE_GLOBALPATH)
    if [[ "$SUSPICIOUS_TRAJECTORY" != "" ]]; then
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
    cp $FILE_GLOBALPATH $FILE_GLOBALPATH_BACKUP || exit $BHMAS_fatalBuiltin

    if [[ "$CHECK_FOR_SUSPICIOUS_TR" = "TRUE" ]]; then
        __static__CheckFileForSuspiciousTrajectory $FILE_GLOBALPATH
    fi
    #Use sort command to clean the file: note that it is safe to give same input and output since the input file is read and THEN overwritten
    sort --numeric-sort --unique --key 1,1 --output=${FILE_GLOBALPATH} ${FILE_GLOBALPATH}
    if [[ $? -ne 0 ]]; then
        cecho lr "      Problem occurred cleaning file " file "$FILE_GLOBALPATH" "! The value " emph "beta = ${BETA%_*}" " will be skipped!\n"
        mv $FILE_GLOBALPATH_BACKUP $FILE_GLOBALPATH || exit $BHMAS_fatalBuiltin
        BHMAS_problematicBetaValues+=( $BETA )
        continue
    fi
    cecho lg "        The file " file "${BHMAS_betaPrefix}${FILE_GLOBALPATH##*/$BHMAS_betaPrefix}" " has been successfully cleaned!"\
          " [removed " B "$(($(wc -l < $FILE_GLOBALPATH_BACKUP) - $(wc -l < $FILE_GLOBALPATH)))" uB " line(s)]!"
}


function CleanOutputFiles()
{
    cecho lc B "\n " U "Cleaning" uU ":"
    for BETA in ${BHMAS_betaValues[@]}; do
        #-------------------------------------------------------------------------#
        local WORK_BETADIRECTORY="$BHMAS_runDirWithBetaFolders/$BHMAS_betaPrefix$BETA"
        local MAINFILE_GLOBALPATH="${WORK_BETADIRECTORY}/$BHMAS_outputFilename"
        local PBPFILE_GLOBALPATH="${MAINFILE_GLOBALPATH}_pbp.dat"
        #-------------------------------------------------------------------------#
        if [[ ! -f $MAINFILE_GLOBALPATH ]]; then
            cecho lr "\n    File " file "$MAINFILE_GLOBALPATH" " does not exist! The value " emph "beta = ${BETA%_*}" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( $BETA )
            continue
        fi

        cecho lc "\n   - $BETA"

        if $(sort --numeric-sort --unique --check=silent --key 1,1 ${MAINFILE_GLOBALPATH}); then
            cecho lm "        The file " file "${BHMAS_betaPrefix}${MAINFILE_GLOBALPATH##*/$BHMAS_betaPrefix}" " has not to be cleaned!"
        else
            __static__CleanFile "$MAINFILE_GLOBALPATH" "TRUE"
        fi

        if [[ -f $PBPFILE_GLOBALPATH ]]; then
            if $(sort --numeric-sort --unique --check=silent --key 1,1 ${PBPFILE_GLOBALPATH}); then
                cecho lm "        The file " file "${BHMAS_betaPrefix}${PBPFILE_GLOBALPATH##*/$BHMAS_betaPrefix}" " has not to be cleaned!"
            else
                __static__CleanFile "$PBPFILE_GLOBALPATH" "FALSE"
            fi
        fi

    done
}


MakeFunctionsDefinedInThisFileReadonly
