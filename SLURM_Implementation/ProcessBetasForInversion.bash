#---------------------------------------------#
#   Copyright (c)  2017  Alessandro Sciarra   #
#---------------------------------------------#

function __static__ProduceSrunCommandsFileForInversionsPerBeta()
{

    if [ "$BHMAS_chempot" != '0' ]; then
        cecho lr "\n Inversion of configuration with nonzero chemical potential not allowed!\n"
        exit -1
    fi

    if [ $(($BHMAS_nspace*$BHMAS_nspace*$BHMAS_nspace*$BHMAS_ntime)) -lt $BHMAS_numberOfSourcesForCorrelators ]; then
        cecho lr "\n Number of required sources bigger than available positions ("\
              emph "$(($BHMAS_nspace*$BHMAS_nspace*$BHMAS_nspace*$BHMAS_ntime)) <= $BHMAS_numberOfSourcesForCorrelators" ")! Not allowed...\n"
        exit -1
    fi

    ls $WORK_BETADIRECTORY | grep "^conf\.[[:digit:]]\{5\}" | awk -v ns="$BHMAS_nspace" \
                                                                  -v nt="$BHMAS_ntime" \
                                                                  -v useCpu="false"   \
                                                                  -v startcondition="continue" \
                                                                  -v logLevel="info" \
                                                                  -v beta="${BETA%%_*}" \
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
        }' > $WORK_BETADIRECTORY/$BHMAS_inversionSrunCommandsFilename

}

function ProcessBetaValuesForInversion_SLURM()
{
    local LOCAL_BHMAS_betaValuesToBeSubmitted=()

    for BETA in ${BHMAS_betaValues[@]}; do
        #-------------------------------------------------------------------------#
        local WORK_BETADIRECTORY="$BHMAS_runDirWithBetaFolders/$BHMAS_betaPrefix$BETA"
        local NUMBER_OF_CONF_IN_BETADIRECTORY=$(find $WORK_BETADIRECTORY -regex "$WORK_BETADIRECTORY/conf[.][0-9]*" | wc -l)
        local NUMBER_OF_TOTAL_CORRELATORS=$(($NUMBER_OF_CONF_IN_BETADIRECTORY * $BHMAS_numberOfSourcesForCorrelators))
        local NUMBER_OF_EXISTING_CORRELATORS=$(find $WORK_BETADIRECTORY -regextype posix-extended -regex "$WORK_BETADIRECTORY/conf[.][0-9]*(_[0-9]+){4}_corr" | wc -l)
        local NUMBER_OF_MISSING_CORRELATORS=$(($NUMBER_OF_TOTAL_CORRELATORS - $NUMBER_OF_EXISTING_CORRELATORS))
        #-------------------------------------------------------------------------#
        __static__ProduceSrunCommandsFileForInversionsPerBeta
        local NUMBER_OF_INVERSION_COMMANDS=$(wc -l < $WORK_BETADIRECTORY/$BHMAS_inversionSrunCommandsFilename)
        if [ $NUMBER_OF_MISSING_CORRELATORS -ne $NUMBER_OF_INVERSION_COMMANDS ]; then
            cecho lr "\n File with commands for inversion expected to contain " emph "$NUMBER_OF_MISSING_CORRELATORS"\
                  " lines, but having " emph "$NUMBER_OF_INVERSION_COMMANDS" ". The value " emph "beta = $BETA" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( $BETA )
            continue
        fi
        if [ ! -s $WORK_BETADIRECTORY/$BHMAS_inversionSrunCommandsFilename ] && [ $NUMBER_OF_MISSING_CORRELATORS -ne 0 ]; then
            cecho lr "\n File with commands for inversion found to be " emph "empty" ", but expected to contain "\
                  emph "$NUMBER_OF_MISSING_CORRELATORS" " lines! The value " emph "beta = $BETA" " will be skipped!\n"
            BHMAS_problematicBetaValues+=( $BETA )
            continue
        fi
        #If file seems fine put it to submit list
        LOCAL_BHMAS_betaValuesToBeSubmitted+=( $BETA )
    done

    #Partition of the LOCAL_BHMAS_betaValuesToBeSubmitted into group of BHMAS_GPUsPerNode and create the JobScript files inside the JOBSCRIPT_FOLDER
    mkdir -p ${BHMAS_submitDirWithBetaFolders}/$BHMAS_jobScriptFolderName || exit -2
    PackBetaValuesPerGpuAndCreateJobScriptFiles "${LOCAL_BHMAS_betaValuesToBeSubmitted[@]}"
}
