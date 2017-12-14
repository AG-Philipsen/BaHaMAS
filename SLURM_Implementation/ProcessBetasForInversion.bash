#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENSE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

function __static__ProduceSrunCommandsFileForInversionsPerBeta()
{
    local betaDirectory betaValue filename
    betaDirectory="$1"; betaValue="$2"; filename="$3"
    if [ "$BHMAS_chempot" != '0' ]; then
        Fatal $BHMAS_fatalValueError "Inversion of configuration with nonzero chemical potential not allowed!"
    fi

    if [ $(($BHMAS_nspace*$BHMAS_nspace*$BHMAS_nspace*$BHMAS_ntime)) -lt $BHMAS_numberOfSourcesForCorrelators ]; then
        Fatal $BHMAS_fatalValueError "Number of required sources bigger than available positions ("\
              emph "$(($BHMAS_nspace*$BHMAS_nspace*$BHMAS_nspace*$BHMAS_ntime)) <= $BHMAS_numberOfSourcesForCorrelators" ")!"
    fi

    ls $betaDirectory | grep "^conf\.[[:digit:]]\{5\}" | awk -v ns="$BHMAS_nspace" \
                                                             -v nt="$BHMAS_ntime" \
                                                             -v useCpu="false"   \
                                                             -v startcondition="continue" \
                                                             -v logLevel="info" \
                                                             -v beta="${betaValue%%_*}" \
                                                             -v mass="0.$BHMAS_mass" \
                                                             -v corrDir="$BHMAS_correlatorDirection" \
                                                             -v solver="cg" \
                                                             -v cgmax="30000" \
                                                             -v cgIterationBlockSize="50" \
                                                             -v thetaFermionTemporal="1" \
                                                             -v maxNrCorrs="$BHMAS_numberOfSourcesForCorrelators" \
                                                             -v chemPot="$BHMAS_chempot" \
                                                             -v wilson="$BHMAS_wilson" \
                                                             -v staggered="$BHMAS_staggered" '
        BEGIN{
            srand();
            if(chemPot == 0){
                chemPotString="--use_chem_pot_im=0";
            }else{
                exit
            }
            if(wilson == "TRUE"){
                options_discretization = "--kappa=" mass " --fermact=wilson --num_sources=12"
            }else if (staggered == "TRUE"){
                options_discretization = "--mass=" mass " --fermact=rooted_stagg --num_sources=3"
            }
        }
        {
            split($1,corr_name_array,"_");
            conf_count[corr_name_array[1]]++;
            if(corr_name_array[2] ~ /^[[:digit:]]{1,2}$/)
            {
                conf_x_y_z_t_corr_key[$1];
            }
        }
        END{
            for(conf_nr in conf_count)
            {
                while(conf_count[conf_nr] <= maxNrCorrs)
                {
                    coordinates = int(rand()*ns) "_" int(rand()*ns) "_" int(rand()*ns) "_" int(rand()*nt) "_" "corr";
                    new_corr_name = conf_nr "_" coordinates;
                    if(new_corr_name in conf_x_y_z_t_corr_key == 0)
                    {
                        conf_x_y_z_t_corr_key_new[new_corr_name];
                        conf_count[conf_nr]++;
                    }
                }
            }

            n = asorti(conf_x_y_z_t_corr_key_new, list_of_correlators_to_calculate);
            for(i = 1; i <= n; ++i)
            {
                split(list_of_correlators_to_calculate[i], parts_of_correlator_name, "_");
                print "--sourcefile=" parts_of_correlator_name[1] " --use_cpu=" useCpu " --startcondition=" startcondition " --log-level=" logLevel " --ns=" ns " --nt=" nt " --source_x=" parts_of_correlator_name[2] " --source_y=" parts_of_correlator_name[3] " --source_z=" parts_of_correlator_name[4] " --source_t=" parts_of_correlator_name[5] " --beta=" beta " --corr_dir=" corrDir " --solver=" solver " --cgmax=" cgmax " --cg_iteration_block_size=" cgIterationBlockSize " --theta_fermion_temporal=" thetaFermionTemporal " --ferm_obs_corr_postfix=" "_" parts_of_correlator_name[2] "_" parts_of_correlator_name[3] "_" parts_of_correlator_name[4] "_" parts_of_correlator_name[5] "_corr" " " chemPotString " " options_discretization;
            }
        }' > "$filename"

}

function ProcessBetaValuesForInversion_SLURM()
{
    local betaValuesToBeSubmitted beta runBetaDirectory numberOfConfigurationsInBetaDirectory\
          numberOfTotalCorrelators numberOfExistingCorrelators numberOfMissingCorrelators numberOfInversionCommands
    betaValuesToBeSubmitted=()
    for beta in ${BHMAS_betaValues[@]}; do
        runBetaDirectory="${BHMAS_runDirWithBetaFolders}/${BHMAS_betaPrefix}${beta}"
        numberOfConfigurationsInBetaDirectory=$(find $runBetaDirectory -regex "$runBetaDirectory/conf[.][0-9]*" | wc -l)
        numberOfTotalCorrelators=$(($numberOfConfigurationsInBetaDirectory * $BHMAS_numberOfSourcesForCorrelators))
        numberOfExistingCorrelators=$(find $runBetaDirectory -regextype posix-extended -regex "$runBetaDirectory/conf[.][0-9]*(_[0-9]+){4}_corr" | wc -l)
        numberOfMissingCorrelators=$(($numberOfTotalCorrelators - $numberOfExistingCorrelators))
        __static__ProduceSrunCommandsFileForInversionsPerBeta "$runBetaDirectory" "$beta" "${runBetaDirectory}/${BHMAS_inversionSrunCommandsFilename}"
        numberOfInversionCommands=$(wc -l < $runBetaDirectory/$BHMAS_inversionSrunCommandsFilename)
        if [ $numberOfMissingCorrelators -ne $numberOfInversionCommands ]; then
            cecho lr "\n File with commands for inversion expected to contain " emph "$numberOfMissingCorrelators"\
                  " lines, but having " emph "$numberOfInversionCommands" ". The value " emph "beta = $beta" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( $beta )
            continue
        fi
        if [ ! -s $runBetaDirectory/$BHMAS_inversionSrunCommandsFilename ] && [ $numberOfMissingCorrelators -ne 0 ]; then
            cecho lr "\n File with commands for inversion found to be " emph "empty" ", but expected to contain "\
                  emph "$numberOfMissingCorrelators" " lines! The value " emph "beta = $beta" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( $beta )
            continue
        fi
        #If file seems fine put it to submit list
        betaValuesToBeSubmitted+=( $beta )
    done
    if [ ${#betaValuesToBeSubmitted[@]} -ne 0 ]; then
        mkdir -p ${BHMAS_submitDirWithBetaFolders}/$BHMAS_jobScriptFolderName || exit $BHMAS_fatalBuiltin
        PackBetaValuesPerGpuAndCreateOrLookForJobScriptFiles "${betaValuesToBeSubmitted[@]}"
    fi
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         __static__ProduceSrunCommandsFileForInversionsPerBeta\
         ProcessBetaValuesForInversion_SLURM
