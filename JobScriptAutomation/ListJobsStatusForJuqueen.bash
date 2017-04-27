#Comment:
#Pattern used for  functions __static__DetermineCreationDateAndSubmits and function __static__CreateSubmitsFile:
#date -d @$(date +"%s") +"%d.%m.%y %H:%M"
#A string %s is passed to date which has the format of seconds and is converted into date and time.
#see manual page for a detailed description of the options.

function __static__DetermineCreationDateAndSubmits(){

    if [[ $(ls $HOME_BETADIRECTORY"/" | egrep -o "b[[:digit:]]\.[[:digit:]]{4}_created_[[:digit:]]{2}_[[:digit:]]{2}_[[:digit:]]{2}" | wc -l) = 1 ]]; then

        CREATION_DATE=$(ls $HOME_BETADIRECTORY"/" | egrep -o "b[[:digit:]]\.[[:digit:]]{4}_created_[[:digit:]]{2}_[[:digit:]]{2}_[[:digit:]]{2}" | egrep -o "[[:digit:]]{2}_[[:digit:]]{2}_[[:digit:]]{2}" | sed "s/_/\./g")
        #CREATION_DATE=$(ls $HOME_BETADIRECTORY"/" | egrep -o "b[[:digit:]]\.[[:digit:]]{4}_created_[[:digit:]]{2}igit:]]{2}_[[:digit:]]{2}" | egrep -o "[[:digit:]]{2}_[[:digit:]]{2}_[[:digit:]]{2}" | sed "s/_/\./g")
    else
        CREATION_DATE="NN.NN.NN"
    fi

    if [ -f "$WORK_BETADIRECTORY/history_hmc_tm" ]; then

        NRSUBMITS=$(grep "Timestamp" "$WORK_BETADIRECTORY/history_hmc_tm" | wc -l)
        SUBMITFIRST=$(date -d @$(date +"$(grep "Timestamp" $WORK_BETADIRECTORY/history_hmc_tm | egrep -o "[[:digit:]]{10}" | head -n1)") +"%d.%m.%y")
        SUBMITLAST=$(date -d @$(date +"$(grep "Timestamp" $WORK_BETADIRECTORY/history_hmc_tm | egrep -o "[[:digit:]]{10}" | tail -n1)") +"%d.%m.%y")

#$(date -d @$(date +"$(grep "Timestamp" $WORK_BETADIRECTORY/history_hmc_tm | egrep -o "[[:digit:]]{10}" | tail -n1)") +"%d.%m.%y")
    else
        NRSUBMITS="NNN"
        SUBMITFIRST="NN.NN.NN"
        SUBMITLAST="NN.NN.NN"
    fi
}


function __static__CreateSubmitsFile(){

    local SUBMITS_FILE="Submits"

    local TIMESTAMP_ARRAY=( )

    local SUBMITS_ARRAY=( )

    if [ -f "$WORK_BETADIRECTORY/history_hmc_tm" ]; then

        TIMESTAMP_ARRAY=( $(grep "Timestamp" $WORK_BETADIRECTORY/history_hmc_tm | egrep -o "[[:digit:]]{10}") )

        for i in ${TIMESTAMP_ARRAY[@]}; do

            SUBMITS_ARRAY+=( $(date -d @$(date +"$i") +"%d.%m.%y_%H:%M") )
        done
    fi

    if [ -d $HOME_BETADIRECTORY ] && [ ${#SUBMITS_ARRAY[@]} -gt 0 ]; then

        rm -f $HOME_BETADIRECTORY/$SUBMITS_FILE

        for i in ${SUBMITS_ARRAY[@]}; do

            echo $i >> $HOME_BETADIRECTORY/$SUBMITS_FILE
        done
    fi
}

function __static__ListJobsStatus_local(){

    printf "\n\e[0;36m==================================================================================================\n\e[0m"

    printf "\n\e[0;34m%s  %s  %s\n" $MASS_PREFIX$MASS $NTIME_PREFIX$NTIME $NSPACE_PREFIX$NSPACE
    printf "\n      %s  %s  %s\n" $MASS_PREFIX$MASS $NTIME_PREFIX$NTIME $NSPACE_PREFIX$NSPACE >> $JOBS_STATUS_FILE
    printf "\n  Beta Total /  Done  Acc int0/1    Status Sub. Nr /    First /     Last\n\e[0m"
    printf "      Beta Total /  Done  Acc int0/1    Status Sub. Nr /    First /     Last\n" >> $JOBS_STATUS_FILE

    for i in b*; do

        #Assigning beta value to BETA variable for readability
        BETA=$(echo $i | grep -o "[[:digit:]].[[:digit:]]\{4\}")

        if [[ ! $BETA =~ [[:digit:]].[[:digit:]]{4} ]]; then

            continue;
        fi

        STATUS=$(llq -W -f %jn %st -u $(whoami) | awk '$1 ~ /^muiPiT_'$MASS_PREFIX$MASS'_'$NTIME_PREFIX$NTIME'_'$NSPACE_PREFIX$NSPACE'_'$i'$/ {print $2}')

        if [ ${#STATUS} -eq 0 ]; then
            STATUS="notQueued"
        elif [ $STATUS = R ]; then
            STATUS="running"
        elif [ $STATUS = I ]; then
            STATUS="idling"
        fi

        #----------Constructing WORK_BETADIRECTORY, HOME_BETADIRECTORY, JOBSCRIPT_GLOBALPATH and INPUTFILE_GLOBALPATH---------#
        WORK_BETADIRECTORY="$WORK_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
        HOME_BETADIRECTORY="$HOME_DIR_WITH_BETAFOLDERS/$BETA_PREFIX$BETA"
        INPUTFILE_GLOBALPATH="$HOME_BETADIRECTORY/$INPUTFILE_NAME"
        OUTPUTFILE_GLOBALPATH="$WORK_BETADIRECTORY/$OUTPUTFILE_NAME"
        #---------------------------------------------------------------------------------------------------------------------#

        local WORKDIRS_EXIST="TBD" #TBD = To be determined
        local ACCEPTANCE="TBD"
        local INT0="N"
        local INT1="N"

        if [ -d $WORK_BETADIRECTORY ] && [ -f $OUTPUTFILE_GLOBALPATH ]; then

            WORKDIRS_EXIST="true"
            ACCEPTANCE=$(awk '{ sum+=$7} END {if(NR != 0){acc=sum/(NR); printf "%.2f", acc} else {acc="N.NN";printf "%s", acc} }' $OUTPUTFILE_GLOBALPATH)
        else
            WORKDIRS_EXIST="false"
             ACCEPTANCE="N.NN"
        fi

        if [ -d $HOME_BETADIRECTORY ] && [ -f $INPUTFILE_GLOBALPATH ]; then

            INT0=$(awk '{if (($1 ~ /Integrationsteps0/) || ($1 ~ /IntegrationSteps0/)){print $3}}' $INPUTFILE_GLOBALPATH)
            INT1=$(awk '{if ($1 ~ /IntegrationSteps1/){print $3}}' $INPUTFILE_GLOBALPATH)

            TOTAL_NR_TRAJECTORIES=$(grep "Total number of trajectories" $INPUTFILE_GLOBALPATH | grep -o "[[:digit:]]\+")
            #TOTAL_NR_TRAJECTORIES=$(expr $TOTAL_NR_TRAJECTORIES - 0)

            if [ $WORKDIRS_EXIST = "true" ]; then

                TRAJECTORIES_DONE=$(tail -n1 $OUTPUTFILE_GLOBALPATH | grep -o "^[[:digit:]]\{8\}")
                TRAJECTORIES_DONE=$(expr $TRAJECTORIES_DONE + 1)
            else

                TRAJECTORIES_DONE=0
            fi
            MEASUREMENTS_REMAINING=$(expr $TOTAL_NR_TRAJECTORIES - $TRAJECTORIES_DONE)

            if [ $STATUS = "notQueued" ] && [ $MEASUREMENTS_REMAINING -eq "0" ]; then

                STATUS="finished"

            elif [ $STATUS = "notQueued" ] && [ $MEASUREMENTS_REMAINING -ne "0" ] && [ $WORKDIRS_EXIST = "true" ]; then

                STATUS="canceled"

            elif [ $STATUS = "notQueued" ] && [ $MEASUREMENTS_REMAINING -ne "0" ] && [ $WORKDIRS_EXIST = "false" ]; then

                STATUS="unknown"
            fi

            __static__DetermineCreationDateAndSubmits

                printf "\e[0;34m%s %5d / %5d $ACCEPTANCE    $INT0/$INT1  %8s     %3s / $SUBMITFIRST / $SUBMITLAST\n\e[0m" $BETA $TOTAL_NR_TRAJECTORIES $TRAJECTORIES_DONE $STATUS $NRSUBMITS
                printf "      %s %5d / %5d $ACCEPTANCE    $INT0/$INT1  %8s     %3s / $SUBMITFIRST / $SUBMITLAST\n" $BETA $TOTAL_NR_TRAJECTORIES $TRAJECTORIES_DONE $STATUS $NRSUBMITS >> $JOBS_STATUS_FILE

            __static__CreateSubmitsFile
        fi

    done
}

function __static__ListJobsStatus_global(){

        ORIGINAL_HOME_DIR_WITH_BETAFOLDERS=$HOME_DIR_WITH_BETAFOLDERS
        ORIGINAL_WORK_DIR_WITH_BETAFOLDERS=$WORK_DIR_WITH_BETAFOLDERS

        PARAMETER_REGEX_ARRAY=()
        DIRECTORY_ARRAY=()
        #Filling PARAMETER_REGEX_ARRAY and DIRECTORY_ARRAY:
        BuildRegexPath


        for i in ${DIRECTORY_ARRAY[@]}; do

            cd $i

            PARAMETERS_PATH=""
            PARAMETERS_STRING=""

            ReadParametersFromPath $(pwd)

            HOME_DIR_WITH_BETAFOLDERS="$HOME_DIR/$SIMULATION_PATH$PARAMETERS_PATH"

            if [ "$HOME_DIR_WITH_BETAFOLDERS" != "$(pwd)" ]; then
                printf "\n\e[0;31m Constructed path to directory containing beta folders does not match the actual position! Aborting...\n\n\e[0m"
                exit -1
            fi
            #echo $HOME_DIR_WITH_BETAFOLDERS
            WORK_DIR_WITH_BETAFOLDERS="$WORK_DIR/$SIMULATION_PATH$PARAMETERS_PATH"
            #echo $WORK_DIR_WITH_BETAFOLDERS

            JOBS_STATUS_FILE="jobs_status_"$CHEMPOT_PREFIX$CHEMPOT"_"$MASS_PREFIX$MASS"_"$NTIME_PREFIX$NTIME"_"$NSPACE_PREFIX$NSPACE".txt"
            #echo $JOBS_STATUS_FILE
            rm -f $JOBS_STATUS_FILE

            __static__ListJobsStatus_local
        done

        cd $ORIGINAL_HOME_DIR_WITH_BETAFOLDERS
}

function __static__BuildGlobalJobStatusFile(){

    DATE='D_'$(date +"%d_%m_%Y")'_T_'$(date +"%H_%M")
    JOBS_STATUS_FILE_GLOBAL=$HOME_DIR'/'$SIMULATION_PATH'/global_'$JOBS_STATUS_PREFIX$DATE'.txt'

    rm -f $JOBS_STATUS_FILE_GLOBAL

    REGEX_PATH=$JOBS_STATUS_PREFIX'[^~]*$'
    REGEX_PATH='.*'$REGEX_PATH

    for i in ${DIRECTORY_ARRAY[@]}; do

        LOCAL_FILE=$(find $i -regextype grep -regex $REGEX_PATH)

        MASS_TMP=`echo $LOCAL_FILE | grep -o "$JOBS_STATUS_PREFIX.*" | grep -o "$MASS_PREFIX$MASS_REGEX"`
        NTIME_TMP=`echo $LOCAL_FILE | grep -o "$JOBS_STATUS_PREFIX.*" | grep -o "$NTIME_PREFIX$NTIME_REGEX"`
        NSPACE_TMP=`echo $LOCAL_FILE | grep -o "$JOBS_STATUS_PREFIX.*" | grep -o "$NSPACE_PREFIX$NSPACE_REGEX"`

        #echo "$MASS_TMP $NTIME_TMP $NSPACE_TMP" >> "$JOBS_STATUS_FILE_GLOBAL"
        #echo "cat $LOCAL_FILE >> $JOBS_STATUS_FILE_GLOBAL"
        cat $LOCAL_FILE >> "$JOBS_STATUS_FILE_GLOBAL"
        echo "" >> "$JOBS_STATUS_FILE_GLOBAL"
    done

    printf "\n\e[0;34m A global jobs status file has been created: %s\n\e[0m" $JOBS_STATUS_FILE_GLOBAL
}

function ListJobStatus_Juqueen(){

    DATE='D_'$(date +"%d_%m_%Y")'_T_'$(date +"%H_%M")

    #-----------Prepare array with directories for which a job status file shall be produced---------------#

    if [ $LISTSTATUS = "TRUE" ]; then

    JOBS_STATUS_FILE="jobs_status_"$CHEMPOT_PREFIX$CHEMPOT"_"$MASS_PREFIX$MASS"_"$NTIME_PREFIX$NTIME"_"$NSPACE_PREFIX$NSPACE".txt"
    echo "NSPACE:$NSPACE"
    echo "JOBS_STATUS_FILE: $JOBS_STATUS_FILE"
    rm -f $JOBS_STATUS_FILE

    printf "\n\e[0;36m==================================================================================================\n\e[0m"
    printf "\e[0;34m Listing current local measurements status...\n\e[0m"

    __static__ListJobsStatus_local

    elif [ $LISTSTATUSALL = "TRUE" ]; then

    printf "\n\e[0;36m==================================================================================================\n\e[0m"
    printf "\e[0;34m Listing current global measurements status...\n\e[0m"

    __static__ListJobsStatus_global

    printf "\n\e[0;36m==================================================================================================\n\e[0m"
    __static__BuildGlobalJobStatusFile
    fi

    printf "\e[0;36m==================================================================================================\n\e[0m"
}
