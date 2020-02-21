#
#  Copyright (c) 2015 Christopher Czaban
#  Copyright (c) 2015-2018,2020 Alessandro Sciarra
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

function __static__SetBetaRelatedPathVariables()
{
    runBetaDirectory="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValue}"
    submitBetaDirectory="${BHMAS_submitDirWithBetaFolders}/${BHMAS_betaPrefix}${betaValue}"
    inputFileGlobalPath="${submitBetaDirectory}/${BHMAS_inputFilename}"
    outputFileGlobalPath="${runBetaDirectory}/${BHMAS_outputFilename}"
    outputPbpFileGlobalPath="${outputFileGlobalPath}_pbp.dat"
    return 0
}

function __static__GetStatusOfJobsContainingBetavalues()
{
    local beta jobsInformation
    jobsInformation="$(squeue --noheader -u $(whoami) -o "%i@%j@%T")"
    for beta in ${BHMAS_betaValues[@]}; do
        #In sed !d deletes the non matching entries -> here we keep jobs with desired beta, seed and parameters
        statusOfJobsContainingGivenBeta["$beta"]=$(sed '/'$BHMAS_betaPrefix${beta%%_*}'/!d; /'$(cut -d'_' -f2 <<< "$beta")'/!d; /'$BHMAS_parametersString'/!d' <<< "$jobsInformation")
    done
    return 0
}

function __static__CheckWhetherAnyRequiredFileOrFolderIsMissing()
{
    if [ ! -d $runBetaDirectory ]; then
        Error "The directory " dir "$runBetaDirectory" " does not exist!\n" "The value " emph "beta = $betaValue" " will be skipped!"
        BHMAS_problematicBetaValues+=( $betaValue )
        return 1
    elif [ ! -d $submitBetaDirectory ]; then
        Error "The directory " dir "$submitBetaDirectory" " does not exist!\n" "The value " emph "beta = $betaValue" " will be skipped!"
        BHMAS_problematicBetaValues+=( $betaValue )
        return 1
    elif [ ! -f $inputFileGlobalPath ]; then
        Error "The file " file "$inputFileGlobalPath" " does not exist!\n" "The value " emph "beta = $betaValue" " will be skipped!"
        BHMAS_problematicBetaValues+=( $betaValue )
        return 1
    fi
    return 0
}

function __static__CheckWhetherSimulationForGivenBetaIsAlreadyEnqueued()
{
    local jobStatus; jobStatus="${statusOfJobsContainingGivenBeta[$betaValue]}"
    if [ "$jobStatus" = "" ]; then
        return 0
    else
        if [ $(grep -c "\(RUNNING\|PENDING\)" <<< "$jobStatus") -gt 0 ]; then
            Error "The simulation seems to be already running with " emph "job-id $(cut -d'@' -f1 <<< "$jobStatus")" " and it cannot be continued!\n"\
                  "The value " emph "beta = $betaValue" " will be skipped!"
            BHMAS_problematicBetaValues+=( $betaValue )
            return 1
        else
            return 0
        fi
    fi
}

function __static__SetLastConfigurationAndLastPRNGFilenamesCleaningBetafolderAndOutputFileIfNeeded()
{
    #If the option resumefrom is given in the betasfile we have to clean the $runBetaDirectory, otherwise just set the name of conf and prng
    if KeyInArray $betaValue BHMAS_trajectoriesToBeResumedFrom; then
        #NOTE: If the user wishes to resume from the last avialable checkpoint, then we have to find here which is
        #      the "last" valid one. Valid means that both the conf and the prng file are present with the same number
        if [ ${BHMAS_trajectoriesToBeResumedFrom[$betaValue]} = "last" ]; then
            #comm expects alphabetically sorted input, then we sort numerically the output and we take the last number
            BHMAS_trajectoriesToBeResumedFrom[$betaValue]=$(comm -12  <(ls -1 $runBetaDirectory | sed -n 's/^'${BHMAS_configurationPrefix}'0*\([1-9][0-9]*\)$/\1/p' | sort)\
                                                                 <(ls -1 $runBetaDirectory | sed -n 's/^'${BHMAS_prngPrefix}'0*\([1-9][0-9]*\)$/\1/p' | sort) | sort -n | tail -n1)
            if [[ ! ${BHMAS_trajectoriesToBeResumedFrom[$betaValue]} =~ ^[0-9]+$ ]]; then
                Error "Unable to find " emph "last valid checkpoint" " to resume from!\n" "The value " emph "beta = $betaValue" " will be skipped!"
                BHMAS_problematicBetaValues+=( $betaValue )
                return 1
            fi
        fi
        cecho lm B U "ATTENTION" uU ":" uB " The simulation for " B emph "beta = ${betaValue%_*}"\
              uB " will be resumed from trajectory " B emph "${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}" uB "."
        # TODO: Previously here was put an AskUser directive to prevent to mess up the folder moving files in Trash in case the user
        #       forgot some resumefrom label in betas file. It is however annoying when the user really wants to resume many simulations.
        #       Implement mechanism to undo file move/modification maybe trapping CTRL-C or acting in case of UserSaidNo at the end of this
        #       function (ideally asking the user again if he wants to restore everything as it was).

        nameOfLastConfiguration=$(printf "${BHMAS_configurationPrefix//\\/}%0${BHMAS_checkpointMinimumNumberOfDigits}d" "${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}")
        if [ ! -f "${runBetaDirectory}/${nameOfLastConfiguration}" ];then
            Error "Configuration " emph "$nameOfLastConfiguration" " not found in "\
                  dir "$runBetaDirectory" " folder.\n" "The value " emph "beta = $betaValue" " will be skipped!"
            BHMAS_problematicBetaValues+=( $betaValue )
            return 1
        fi
        nameOfLastPRNG=$(printf "${BHMAS_prngPrefix//\\/}%0${BHMAS_checkpointMinimumNumberOfDigits}d" "${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}")
        if [ ! -f "${runBetaDirectory}/${nameOfLastPRNG}" ]; then
            nameOfLastPRNG="" #If the prng.xxxxx is not found, use random seed
        fi
        #If the BHMAS_outputFilename is not in the runBetaDirectory stop and not do anything else for this betaValue
        if [ ! -f $outputFileGlobalPath ]; then
            Error "File " file "$BHMAS_outputFilename" " not found in " dir "$runBetaDirectory" " folder.\n" "The value " emph "beta = $betaValue" " will be skipped!"
            BHMAS_problematicBetaValues+=( $betaValue )
            return 1
        fi
        #Now it should be feasable to resume simulation ---> clean runBetaDirectory
        #Create in runBetaDirectory a folder named Trash_$(date) where to mv all the file produced after the traj. ${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}
        local trashFolderName filename numberFromFile prefix
        trashFolderName="$runBetaDirectory/Trash_$(date +'%F_%H%M%S')"
        mkdir $trashFolderName || exit $BHMAS_fatalBuiltin
        for filename in $(ls -1 $runBetaDirectory | sed -n -e '/^'${BHMAS_configurationRegex}'.*$/p' -e '/^'${BHMAS_prngRegex}'.*$/p'); do
            #Move to trash only 'conf.xxxxx(whatever)' or 'prng.xxxxx(whatever)' files with xxxxx larger than the resume from trajectory
            numberFromFile=$(sed -n 's/^\('${BHMAS_configurationPrefix}'\|'${BHMAS_prngPrefix}'\)0*\([1-9][0-9]*\).*$/\2/p' <<< "${filename}")
            if [ $numberFromFile -gt ${BHMAS_trajectoriesToBeResumedFrom[$betaValue]} ]; then
                mv $runBetaDirectory/$filename $trashFolderName
            fi
        done
        #Move to trash conf.save(whatever) and prng.save(whatever) files if existing
        for prefix in ${BHMAS_configurationPrefix} ${BHMAS_prngPrefix}; do
            for filename in $(compgen -G "$runBetaDirectory/${prefix}${BHMAS_standardCheckpointPostfix}*"); do
                mv $filename $trashFolderName
            done
        done
        #Move the output file to Trash, and duplicate it parsing it in awk deleting all the trajectories after the resume from one, included (if found)
        mv $outputFileGlobalPath $trashFolderName || exit $BHMAS_fatalBuiltin
        if ! awk -v tr="${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}"\
             'BEGIN{found=1} $1<tr{print $0} $1==(tr-1){found=0} END{exit found}'\
             ${trashFolderName}/$(basename $outputFileGlobalPath) > $outputFileGlobalPath; then
            Error "Measurement for trajectory " emph "$(( BHMAS_trajectoriesToBeResumedFrom[$betaValue] - 1 ))" " not found in outputfile "\
                  emph "$outputFileGlobalPath\n" "The value " emph "beta = $betaValue" " will be skipped!"
            mv $trashFolderName/* $runBetaDirectory || exit $BHMAS_fatalBuiltin
            rmdir $trashFolderName || exit $BHMAS_fatalBuiltin
            BHMAS_problematicBetaValues+=( $betaValue )
            return 1
        fi
        #Make same operations on pbp file, if existing
        if [ -f $outputPbpFileGlobalPath ]; then
            mv $outputPbpFileGlobalPath $trashFolderName || exit $BHMAS_fatalBuiltin
            if ! awk -v tr="${BHMAS_trajectoriesToBeResumedFrom[$betaValue]}"\
                 'BEGIN{found=1} $1<tr{print $0} $1==(tr-1){found=0} END{exit found}'\
                 ${trashFolderName}/$(basename $outputPbpFileGlobalPath) > $outputPbpFileGlobalPath; then
                Error "Measurement for trajectory " emph "$(( BHMAS_trajectoriesToBeResumedFrom[$betaValue] - 1 ))" " not found in pbp outputfile "\
                      emph "$outputPbpFileGlobalPath\n" "The value " emph "beta = $betaValue" " will be skipped!"
                mv $trashFolderName/* $runBetaDirectory || exit $BHMAS_fatalBuiltin
                rmdir $trashFolderName || exit $BHMAS_fatalBuiltin
                BHMAS_problematicBetaValues+=( $betaValue )
                return 1
            fi
        fi
    elif [ -f "$runBetaDirectory/${BHMAS_configurationPrefix//\\/}${BHMAS_standardCheckpointPostfix}" ]; then #If resumefrom has not been given use conf.save if present, otherwise use the last checkpoint
        nameOfLastConfiguration="${BHMAS_configurationPrefix//\\/}${BHMAS_standardCheckpointPostfix}"
        if [ -f "$runBetaDirectory/${BHMAS_prngPrefix//\\/}${BHMAS_standardCheckpointPostfix}" ]; then
            nameOfLastPRNG="${BHMAS_prngPrefix//\\/}${BHMAS_standardCheckpointPostfix}"
        else
            nameOfLastPRNG=""
        fi
    else
        nameOfLastConfiguration=$(ls -1 $runBetaDirectory | sed -n '/^'${BHMAS_configurationRegex}'$/p' | sort -V | tail -n1)
        nameOfLastPRNG=$(ls -1 $runBetaDirectory | sed -n '/^'${BHMAS_prngRegex}'$/p' | sort -V | tail -n1)
    fi
    return 0
}

function __static__CheckWhetherFoundCheckpointIsGoodToContinue()
{
    #The variable nameOfLastConfiguration should be set here, if not it means no conf was available!
    if [ "$nameOfLastConfiguration" == "" ]; then
        Error "No configuration found in " dir "$runBetaDirectory" ".\n" "The value " emph "beta = $betaValue" " will be skipped!"
        BHMAS_problematicBetaValues+=( $betaValue )
        return 1
    fi
    if [ "$nameOfLastPRNG" = "" ]; then
        Warning "No valid PRNG file for configuration " file "${BHMAS_betaPrefix}${betaValue}/$nameOfLastConfiguration" " was found! Using a random seed."
    fi
    #Check that, in case the continue is done from a "numeric" configuration, the number of conf and prng is the same
    if [[ "$nameOfLastConfiguration" =~ [.][0-9]+$ ]] && [[ "$nameOfLastPRNG" =~ [.][0-9]+$ ]]; then
        if [ $(sed 's/^0*//g' <<< "${nameOfLastConfiguration#*.}") -ne $(sed 's/^0*//g' <<< "${nameOfLastPRNG#*.}") ]; then
            Error "The numbers of " emph "${BHMAS_configurationPrefix//\\/}xxxxx" " and "\
                  emph "${BHMAS_prngPrefix//\\/}xxxxx" " are different! Check the respective folder!\n"\
                  "The value " emph "beta = $betaValue" " will be skipped!"
            BHMAS_problematicBetaValues+=( $betaValue )
            return 1
        fi
    fi
    return 0
}

function __static__MakeTemporaryCopyOfOriginalInputFile()
{
    #Make a temporary copy of the input file that will be used to restore in case the original input file.
    #This is to avoid to modify some parameters and then skip beta because of some error leaving the input file modified!
    #If the beta is skipped this temporary file is used to restore the original input file, otherwise it is deleted.
    originalInputFileGlobalPath="${inputFileGlobalPath}_original"
    cp $inputFileGlobalPath $originalInputFileGlobalPath || exit $BHMAS_fatalBuiltin
    return 0
}

function __static__RestoreOriginalInputFile()
{
    mv $originalInputFileGlobalPath $inputFileGlobalPath; return 0
}

function __static__AddOptionsToInputFile()
{
    printf "%s\n" $@ >> $inputFileGlobalPath #One per line!
}

function __static__FindAndReplaceSingleOccurenceInFile()
{
    if [ $# -ne 3 ]; then
        Internal "The function " emph "$FUNCNAME" " has been wrongly called (" emph "3 arguments needed" ")!"
    fi
    local filename stringToBeFound replaceString
    filename="$1"; stringToBeFound="$2"; replaceString="$3"
    if [ ! -f "$filename" ]; then
        Fatal $BHMAS_fatalFileNotFound "File " file "$filename" " has not been found!"
    elif [ $(grep -c "$stringToBeFound" $filename) -eq 0 ]; then
        Error "The string " emph "$stringToBeFound" " has " emph "not been found" " in file "\
              file "${filename##$BHMAS_runDirWithBetaFolders/}" "!\n" "The value " emph "beta = $betaValue" " will be skipped!"
        BHMAS_problematicBetaValues+=( $betaValue )
        return 1
    elif [ $(grep -c "$stringToBeFound" $filename) -gt 1 ]; then
        Error "The string " emph "$stringToBeFound" " occurs " emph "more than once" " in file "\
              file "${filename##$BHMAS_runDirWithBetaFolders/}" "!\n" "The value " emph "beta = $betaValue" " will be skipped!"
        BHMAS_problematicBetaValues+=( $betaValue )
        return 1
    fi
    sed -i "s@${stringToBeFound}@${replaceString}@g" $filename #function's return code is that of sed
}

function __static__ModifyOptionsInInputFile()
{
    local oldString newString
    while [ $# -gt 0 ]; do
        case $1 in
            startCondition=* )                  oldString="startCondition=[[:alpha:]]\+";                newString="startCondition=${1#*=}" ;;
            initialConf=* )                     oldString="initialConf=[[:alnum:][:punct:]]*";           newString="initialConf=${1#*=}" ;;
            initialPRNG=* )                     oldString="initialPRNG=[[:alnum:][:punct:]]*";           newString="initialPRNG=${1#*=}" ;;
            hostSeed=* )                        oldString="hostSeed=[0-9]\+";                            newString="hostSeed=${1#*=}" ;;
            intsteps0=* )                       oldString="integrationSteps0=[0-9]\+";                   newString="integrationSteps0=${1#*=}" ;;
            intsteps1=* )                       oldString="integrationSteps1=[0-9]\+";                   newString="integrationSteps1=${1#*=}" ;;
            f=* | confSaveFrequency=* )         oldString="createCheckpointEvery=[0-9]\+";               newString="createCheckpointEvery=${1#*=}" ;;
            F=* | confSavePointFrequency=* )    oldString="overwriteTemporaryCheckpointEvery=[0-9]\+";   newString="overwriteTemporaryCheckpointEvery=${1#*=}" ;;
            m=* | measurements=* )              oldString="mcSteps=[0-9]\+";                             newString="mcSteps=${1#*=}" ;;  # This replacement works both with nHmcSteps and nRhmcSteps
            measurePbp=* )                      oldString="measurePbp=[0-9]\+";                          newString="measurePbp=${1#*=}" ;;
            useMP=* )                           oldString="useMP=[0-9]\+";                               newString="useMP=${1#*=}" ;;
            kappaMP=* )                         oldString="kappaMP=[0-9]\+[.][0-9]\+";                   newString="kappaMP=${1#*=}" ;;
            intsteps2=* )                       oldString="integrationSteps2=[0-9]\+";                   newString="integrationSteps2=${1#*=}" ;;
            solverResiduumCheckEvery=* )        oldString="solverResiduumCheckEvery=[0-9]\+";            newString="solverResiduumCheckEvery=${1#*=}" ;;
            nTimeScales=* )                     oldString="nTimeScales=[0-9]\+";                         newString="nTimeScales=${1#*=}" ;;
            nPseudoFermions=* )                 oldString="nPseudoFermions=[0-9]\+";                     newString="nPseudoFermions=${1#*=}" ;;
            * )
                Error "The option " emph "$1" " cannot be handled in the continue scenario.\n" "Simulation cannot be continued. The value " emph "beta = $betaValue" " will be skipped!"
                BHMAS_problematicBetaValues+=( $betaValue )
                return 1 ;;
        esac
        __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "$oldString" "$newString" || return 1
        shift
    done
    return 0
}

function __static__PrintAboutOptionsToStandardOutput()
{
    local addedOrSet toInto
    addedOrSet="${1:?Argument not properly passed to function $FUNCNAME}"; shift
    [ $addedOrSet = 'Added' ] && toInto='to' || toInto='into'
    if [ $# -eq 1 ]; then
        cecho wg " ${addedOrSet} option " emph "$1" " $toInto the " file "$(basename $inputFileGlobalPath)" " file."
    else
        cecho wg " ${addedOrSet} options " emph "$1"; shift
        while [ $# -gt 1 ]; do
            cecho wg "             " emph "$1"; shift
        done
        cecho wg "             " emph "$1" " $toInto the " file "$(basename $inputFileGlobalPath)" " file."
    fi
}

function __static__PrintAddedOptionsToStandardOutput()
{
    __static__PrintAboutOptionsToStandardOutput "Added" "$@"
}

function __static__PrintModifiedOptionsToStandardOutput()
{
    __static__PrintAboutOptionsToStandardOutput "Set" "$@"
}

function __static__FindAndSetNumberOfTrajectoriesAlreadyProduced()
{
    # Strategy to recover the number of done measurement:
    #   1) if nameOfLastConfiguration contains the number of the conf, use it. Otherwise,
    #   2) try to extract from within the configuration file (specific CL2QCD). Otherwise,
    #   3) if the output file exists, use it. Otherwise,
    #   4) print an error and skip beta.
    numberOfTrajectoriesAlreadyProduced="$(sed -n 's/^[^1-9]*\([0-9]\+\)[^0-9]*$/\1/p' <<< "$nameOfLastConfiguration")" #extract number without leading zeros (only if exactly one number is in conf name)
    if [ "$numberOfTrajectoriesAlreadyProduced" = '' ]; then
        numberOfTrajectoriesAlreadyProduced="$(sed -n "s/^trajectory nr = \([1-9][0-9]*\)$/\1/p" ${runBetaDirectory}/${nameOfLastConfiguration} || true)"
    fi
    if [ "$numberOfTrajectoriesAlreadyProduced" = '' ]; then
        if [ -f $outputFileGlobalPath ]; then
            numberOfTrajectoriesAlreadyProduced=$(awk 'END{print $1 + 1}' $outputFileGlobalPath) #The +1 is here necessary because the first tr. is supposed to be the number 0.
        fi
    fi
    if [ "$numberOfTrajectoriesAlreadyProduced" = '' ]; then
        Error "It was not possible to deduce the number of already produced trajectories!\n" "The value " emph "beta = $betaValue" " will be skipped!"
        BHMAS_problematicBetaValues+=( $betaValue )
        return 1
    else
        return 0
    fi
}

function __static__IsSimulationFinished()
{
    local startingStatistics goalStatistics continueOptionString
    startingStatistics=$1; goalStatistics=$2; continueOptionString="--continue"
    if [ $startingStatistics -gt $goalStatistics ]; then
        if [ $BHMAS_trajectoryNumberUpToWhichToContinue -ne 0 ]; then
            continueOptionString+="=$BHMAS_trajectoryNumberUpToWhichToContinue"
        fi
        Error "It was found that the number of done measurements is " emph "$startingStatistics > $goalStatistics = goal trajectory" ".\n"\
              "The option " emph "--continue" " cannot be applied. The value " emph "beta = $betaValue" " will be skipped!"
        BHMAS_problematicBetaValues+=( $betaValue )
        return 1
    elif [ $startingStatistics -eq $goalStatistics ]; then
        if KeyInArray $betaValue BHMAS_trajectoriesToBeResumedFrom; then
            #If we resume from and simulation is finished, delete from std output the 'ATTENTION' line
            cecho -d -n "\e[1A\e[K"
        fi
        cecho lg " The simulation for " lo "beta = $betaValue" lg " seems to be finished, it will not be continued!"
        return 1
    fi
    return 0
}

function __static__HandleMeasurementsInInputFile()
{
    # There are differente possibilities to set the number of measurements in the input file
    # and we have to decide a list of priorities:
    #   1) if the '--measurements' option is given, then it will be used. Otherwise,
    #   2) if the '--continue=[number]' option is given, then it will be used. Otherwise,
    #   3) if the 'g[number]' field is present in the betas file, then it will be used. Otherwise,
    #   4) the measurement option in the input file is not modified!
    #
    #
    local optionsToBeAddedOrModified numberOfTrajectoriesAlreadyProduced
    if WasAnyOfTheseOptionsGivenToBaHaMAS '-m' '--measurements'; then
        optionsToBeAddedOrModified="measurements=$BHMAS_numberOfTrajectories"
    elif [ $BHMAS_trajectoryNumberUpToWhichToContinue -ne 0 ]; then
        __static__FindAndSetNumberOfTrajectoriesAlreadyProduced || { __static__RestoreOriginalInputFile && return 1; }
        __static__IsSimulationFinished $numberOfTrajectoriesAlreadyProduced $BHMAS_trajectoryNumberUpToWhichToContinue || { __static__RestoreOriginalInputFile && return 1; }
        optionsToBeAddedOrModified="measurements=$(( BHMAS_trajectoryNumberUpToWhichToContinue - numberOfTrajectoriesAlreadyProduced ))"
    elif KeyInArray $betaValue BHMAS_goalStatistics; then
        __static__FindAndSetNumberOfTrajectoriesAlreadyProduced || { __static__RestoreOriginalInputFile && return 1; }
        __static__IsSimulationFinished $numberOfTrajectoriesAlreadyProduced ${BHMAS_goalStatistics[$betaValue]} || { __static__RestoreOriginalInputFile && return 1; }
        optionsToBeAddedOrModified="measurements=$(( BHMAS_goalStatistics[$betaValue] - numberOfTrajectoriesAlreadyProduced ))"
    else
        return 0
    fi
    __static__ModifyOptionsInInputFile $optionsToBeAddedOrModified || { __static__RestoreOriginalInputFile && return 1; }
    __static__PrintModifiedOptionsToStandardOutput $optionsToBeAddedOrModified
    return 0
}

function __static__HandlePbpInInputFile()
{
    local measurePbpValueForInputFile string pbpStrings optionsToBeAddedOrModified
    if [ $BHMAS_measurePbp = "FALSE" ]; then
        measurePbpValueForInputFile=0
    elif [ $BHMAS_measurePbp = "TRUE" ]; then
        measurePbpValueForInputFile=1
        #If the pbp file already exists non empty, add end of line to it to be sure the prompt is at the beginning of a new line
        if [ -f $outputPbpFileGlobalPath ] && [ $(wc -l < $outputPbpFileGlobalPath) -ne 0 ]; then
            sed -i '$a\' $outputPbpFileGlobalPath
        fi
    fi
    optionsToBeAddedOrModified=("measurePbp=$measurePbpValueForInputFile")
    if [ $(grep -c "measurePbp" $inputFileGlobalPath) -eq 0 ]; then
        pbpStrings=(sourceType sourceContent nSources pbpMeasurements fermObsInSingleFile fermObsPbpPrefix)
        for string in "${pbpStrings[@]}"; do
            if [ $(grep -c "$string" $inputFileGlobalPath) -ne 0 ]; then
                Error "The option " emph "measurePbp" " is not present in the input file but one or more specification about how to calculate\n"\
                      "the chiral condensate are present. Suspicious situation, investigate! The value " emph "beta = $betaValue" " will be skipped!"
                BHMAS_problematicBetaValues+=( $betaValue )
                __static__RestoreOriginalInputFile && return 1
            fi
        done
        optionsToBeAddedOrModified+=("sourceType=volume" "sourceContent=gaussian")
        if [ $BHMAS_wilson = "TRUE" ]; then
            optionsToBeAddedOrModified+=("nSources=16")
        elif [ $BHMAS_staggered = "TRUE" ]; then
            optionsToBeAddedOrModified+=("nSources=1" "pbpMeasurements=8" "fermObsInSingleFile=1" "fermObsPbpPrefix=${BHMAS_outputFilename}")
        fi
        __static__AddOptionsToInputFile ${optionsToBeAddedOrModified[@]}
        __static__PrintAddedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
    else
        #If measurePbp is in input file we assume that relative options are there and fine
        __static__ModifyOptionsInInputFile ${optionsToBeAddedOrModified[@]} || { __static__RestoreOriginalInputFile && return 1; }
        __static__PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
    fi
    return 0
}

function __static__HandleMultiplePseudofermionsInInputFile()
{
    if [ $BHMAS_staggered = "TRUE" ]; then #Multiple pseudofermions simply ignored if not staggered
        local oldOption newOption optionsToBeAddedOrModified
        optionsToBeAddedOrModified=("nPseudoFermions=${BHMAS_numberOfPseudofermions}")
        if [ $(grep -c "nPseudoFermions" $inputFileGlobalPath) -eq 0 ]; then
            __static__AddOptionsToInputFile ${optionsToBeAddedOrModified[@]}
            __static__PrintAddedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
        else
            __static__ModifyOptionsInInputFile ${optionsToBeAddedOrModified[@]} || { __static__RestoreOriginalInputFile && return 1; }
            __static__PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
        fi
        #Always replace approx files with correct ones (maybe unnecessary, but easy to be done always)
        oldOption="rationalApproxFileHB=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_\(pf[1-9]\+_\)\?Approx_Heatbath"
        newOption="${oldOption%/*}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_Approx_Heatbath"
        [ $BHMAS_numberOfPseudofermions -gt 1 ] && newOption="${newOption/Approx_Heatbath/pf${BHMAS_numberOfPseudofermions}_Approx_Heatbath}"
        __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "$oldOption" "$newOption" || { __static__RestoreOriginalInputFile && return 1; }
        __static__PrintModifiedOptionsToStandardOutput ${newOption}
        oldOption="rationalApproxFileMD=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_\(pf[1-9]\+_\)\?Approx_MD"
        newOption="${oldOption%/*}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_Approx_MD"
        [ $BHMAS_numberOfPseudofermions -gt 1 ] && newOption="${newOption/Approx_MD/pf${BHMAS_numberOfPseudofermions}_Approx_MD}"
        __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "$oldOption" "$newOption" || { __static__RestoreOriginalInputFile && return 1; }
        __static__PrintModifiedOptionsToStandardOutput ${newOption}
        oldOption="rationalApproxFileMetropolis=${BHMAS_rationalApproxGlobalPath}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_\(pf[1-9]\+_\)\?Approx_Metropolis"
        newOption="${oldOption%/*}/${BHMAS_nflavourPrefix}${BHMAS_nflavour}_Approx_Metropolis"
        [ $BHMAS_numberOfPseudofermions -gt 1 ] && newOption="${newOption/Approx_Metropolis/pf${BHMAS_numberOfPseudofermions}_Approx_Metropolis}"
        __static__FindAndReplaceSingleOccurenceInFile $inputFileGlobalPath "$oldOption" "$newOption" || { __static__RestoreOriginalInputFile && return 1; }
        __static__PrintModifiedOptionsToStandardOutput ${newOption}
    fi
    return 0
}

function __static__HandleMassPreconditioningInInputFile()
{
    if [ $BHMAS_wilson = "TRUE" ]; then #Mass preconditioning simply ignored if not Wilson
        local string massPreconditioningStrings optionsToBeAddedOrModified
        if KeyInArray $betaValue BHMAS_massPreconditioningValues; then
            optionsToBeAddedOrModified=("useMP=1")
            if [ $(grep -c "useMP" $inputFileGlobalPath) -eq 0 ]; then
                massPreconditioningStrings=(solverMP kappaMP integrator2 integrationSteps2)
                for string in "${massPreconditioningStrings[@]}"; do
                    if [ $(grep -c "$string" $inputFileGlobalPath) -ne 0 ]; then
                        Error "The option " emph "useMP" " is not present in the input file but one or more specification about how to use\n"\
                              "mass preconditioning are present. Suspicious situation, investigate! The value " emph "beta = $betaValue" " will be skipped!"
                        BHMAS_problematicBetaValues+=( $betaValue )
                        __static__RestoreOriginalInputFile && return 1
                    fi
                done
                optionsToBeAddedOrModified+=("solverMP=cg" "kappaMP=0.${BHMAS_massPreconditioningValues[$betaValue]#*,}"
                                             "integrator2=twomn" "integrationSteps2=${BHMAS_massPreconditioningValues[$betaValue]%,*}")
                __static__AddOptionsToInputFile ${optionsToBeAddedOrModified[@]}
                __static__PrintAddedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
                optionsToBeAddedOrModified=("nTimeScales=3" "solverResiduumCheckEvery=10")
                __static__ModifyOptionsInInputFile ${optionsToBeAddedOrModified[@]} || { __static__RestoreOriginalInputFile && return 1; }
                __static__PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
            else
                #Here I assume that the specifications for mass preconditioning are already in the input file and I just modify them!
                #In any case, the function '__static__ModifyOptionsInInputFile' will catch any missing option and the beta will be skipped
                optionsToBeAddedOrModified+=("kappaMP=0.${BHMAS_massPreconditioningValues[$betaValue]#*,}" "nTimeScales=3"
                                             "intsteps2=${BHMAS_massPreconditioningValues[$betaValue]%,*}" "solverResiduumCheckEvery=10")
                __static__ModifyOptionsInInputFile ${optionsToBeAddedOrModified[@]} || { __static__RestoreOriginalInputFile && return 1; }
                __static__PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
            fi
        else
            #Here check if mass preconditioning is in the input file and if so switch it off
            if [ $(grep -c "useMP" $inputFileGlobalPath) -gt 0 ]; then #Use '-gt 0' instead of '-eq 1' so that we also check multiple occurences
                optionsToBeAddedOrModified=("useMP=0" "solverResiduumCheckEvery=50" "nTimeScales=2")
                __static__ModifyOptionsInInputFile ${optionsToBeAddedOrModified[@]} || { __static__RestoreOriginalInputFile && return 1; }
                __static__PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
            fi
        fi
    fi
    return 0
}

function __static__HandleStartConditionInInputFile()
{
    #Always convert startcondition in continue (and do not notify user, it is understood)
    __static__ModifyOptionsInInputFile "startCondition=continue" || { __static__RestoreOriginalInputFile && return 1; }
    return 0
}

function __static__HandleStartConfigurationInInputFile()
{
    local optionsToBeAddedOrModified
    optionsToBeAddedOrModified="initialConf=$runBetaDirectory/${nameOfLastConfiguration}"
    if [ $(grep -c "initialConf=[[:alnum:][:punct:]]*" $inputFileGlobalPath) -eq 0 ]; then
        __static__AddOptionsToInputFile $optionsToBeAddedOrModified
        __static__PrintAddedOptionsToStandardOutput $optionsToBeAddedOrModified
    else
        #In order to use __static__ModifyOptionsInInputFile I have to escape the slashes in the path (for sed)
        __static__ModifyOptionsInInputFile ${optionsToBeAddedOrModified//\//\\\/} || { __static__RestoreOriginalInputFile && return 1; }
        __static__PrintModifiedOptionsToStandardOutput $optionsToBeAddedOrModified
    fi
    return 0
}

function __static__HandlePRNGStateInInputFile()
{
    local optionsToBeAddedOrModified
    if [ "$nameOfLastPRNG" == "" ]; then
        #Delete eventual line from input file with initialPRNG (here we must use a random seed)
        sed -i '/initialPRNG/d' $inputFileGlobalPath
        optionsToBeAddedOrModified="hostSeed=$(printf "%04d" $(( (RANDOM+1000)%10000 )) )"
        if [ $(grep -c "hostSeed=[0-9]\{4\}" $inputFileGlobalPath) -eq 0 ]; then
            __static__AddOptionsToInputFile $optionsToBeAddedOrModified
            __static__PrintAddedOptionsToStandardOutput $optionsToBeAddedOrModified
        else
            __static__ModifyOptionsInInputFile $optionsToBeAddedOrModified || { __static__RestoreOriginalInputFile && return 1; }
            __static__PrintModifiedOptionsToStandardOutput $optionsToBeAddedOrModified
        fi
    else
        #Delete eventual line from input file with hostSeed (here we use an initialPRNG)
        sed -i '/hostSeed/d' $inputFileGlobalPath
        optionsToBeAddedOrModified="initialPRNG=$runBetaDirectory/${nameOfLastPRNG}"
        if [ $(grep -c "initialPRNG=[[:alnum:][:punct:]]*" $inputFileGlobalPath) -eq 0 ]; then
            __static__AddOptionsToInputFile $optionsToBeAddedOrModified
            __static__PrintAddedOptionsToStandardOutput $optionsToBeAddedOrModified
        else
            #In order to use __static__ModifyOptionsInInputFile I have to escape the slashes in the path (for sed)
            __static__ModifyOptionsInInputFile ${optionsToBeAddedOrModified//\//\\\/} || { __static__RestoreOriginalInputFile && return 1; }
            __static__PrintModifiedOptionsToStandardOutput $optionsToBeAddedOrModified
        fi
    fi
    return 0
}

function __static__HandleIntegrationStepsInInputFile()
{
    local optionsToBeAddedOrModified
    #Always set the integrator steps, that could have changed or not
    optionsToBeAddedOrModified=("intsteps0=${BHMAS_scaleZeroIntegrationSteps[$betaValue]}" "intsteps1=${BHMAS_scaleOneIntegrationSteps[$betaValue]}")
    __static__ModifyOptionsInInputFile ${optionsToBeAddedOrModified[@]} || { __static__RestoreOriginalInputFile && return 1; }
    __static__PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
}

function __static__HandleFurtherOptionsInInputFile()
{
    local commandLineOptionsToBeConsidered index option optionsToBeAddedOrModified
    commandLineOptionsToBeConsidered=( "-f" "--confSaveFrequency" "-F" "--confSavePointFrequency" )
    optionsToBeAddedOrModified=()
    #Here it is fine to assume option value follows option name after a space (see ParseCommandLineOption function)
    for index in ${!BHMAS_specifiedCommandLineOptions[@]}; do
        option=${BHMAS_specifiedCommandLineOptions[$index]}
        if ! ElementInArray ${option} ${commandLineOptionsToBeConsidered[@]}; then
            continue
        fi
        optionsToBeAddedOrModified+=("${option##*-}=${BHMAS_specifiedCommandLineOptions[$((index+1))]}")
    done
    if [ ${#optionsToBeAddedOrModified[@]} -ne 0 ]; then
        __static__ModifyOptionsInInputFile ${optionsToBeAddedOrModified[@]} || { __static__RestoreOriginalInputFile && return 1; }
        __static__PrintModifiedOptionsToStandardOutput ${optionsToBeAddedOrModified[@]}
    fi
    return 0
}

function ProcessBetaValuesForContinue_SLURM()
{
    local betaValue runBetaDirectory submitBetaDirectory inputFileGlobalPath outputFileGlobalPath outputPbpFileGlobalPath\
          betaValuesToBeSubmitted nameOfLastConfiguration nameOfLastPRNG originalInputFileGlobalPath
    betaValuesToBeSubmitted=()
    #Associative array filled in the function called immediately after (global because of bug, see link here below)
    declare -A -g statusOfJobsContainingGivenBeta=() #http://lists.gnu.org/archive/html/bug-bash/2013-09/msg00025.html
    __static__GetStatusOfJobsContainingBetavalues
    for betaValue in ${BHMAS_betaValues[@]}; do
        cecho ''
        __static__SetBetaRelatedPathVariables                                                      || continue
        __static__CheckWhetherAnyRequiredFileOrFolderIsMissing                                     || continue
        __static__CheckWhetherSimulationForGivenBetaIsAlreadyEnqueued                              || continue
        __static__SetLastConfigurationAndLastPRNGFilenamesCleaningBetafolderAndOutputFileIfNeeded  || continue
        __static__CheckWhetherFoundCheckpointIsGoodToContinue                                      || continue
        __static__MakeTemporaryCopyOfOriginalInputFile
        __static__HandleMeasurementsInInputFile            || continue
        __static__HandlePbpInInputFile                     || continue
        __static__HandleMultiplePseudofermionsInInputFile  || continue
        __static__HandleMassPreconditioningInInputFile     || continue
        __static__HandleStartConditionInInputFile          || continue
        __static__HandleStartConfigurationInInputFile      || continue
        __static__HandlePRNGStateInInputFile               || continue
        __static__HandleIntegrationStepsInInputFile        || continue
        __static__HandleFurtherOptionsInInputFile          || continue
        #If the script runs fine and it arrives here, it means no 'continue' was done
        rm $originalInputFileGlobalPath
        betaValuesToBeSubmitted+=( $betaValue )
    done
    if [ ${#betaValuesToBeSubmitted[@]} -ne 0 ]; then
       mkdir -p ${BHMAS_submitDirWithBetaFolders}/$BHMAS_jobScriptFolderName || exit $BHMAS_fatalBuiltin
       PackBetaValuesPerGpuAndCreateOrLookForJobScriptFiles "${betaValuesToBeSubmitted[@]}"
       #Ask the user if he want to continue submitting job
       AskUser "Check if the continue option did its job correctly. Would you like to submit the jobs?"
       if UserSaidNo; then
           cecho lr B "\n No jobs will be submitted.\n"
           exit $BHMAS_successExitCode
       fi
    fi
    unset -v 'statusOfJobsContainingGivenBeta'
}


MakeFunctionsDefinedInThisFileReadonly
