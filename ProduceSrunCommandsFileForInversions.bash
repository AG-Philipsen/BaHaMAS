function ProduceSrunCommandsFileForInversionsPerBeta()
{

    if [ "$CHEMPOT" != '0' ]; then
        cecho lr "\n Inversion of configuration with nonzero chemical potential not allowed!\n"
        exit -1
    fi

    if [ $(($NSPACE*$NSPACE*$NSPACE*$NTIME)) -lt $NUMBER_SOURCES_FOR_CORRELATORS ]; then
        cecho lr "\n Number of required sources bigger than available positions ("\
              emph "$(($NSPACE*$NSPACE*$NSPACE*$NTIME)) <= $NUMBER_SOURCES_FOR_CORRELATORS" ")! Not allowed...\n"
        exit -1
    fi

    ls $WORK_BETADIRECTORY | grep "^conf\.[[:digit:]]\{5\}" | awk -v ns="$NSPACE" \
                                                                  -v nt="$NTIME" \
                                                                  -v useCpu="false"   \
                                                                  -v startcondition="continue" \
                                                                  -v logLevel="info" \
                                                                  -v beta="${BETA%%_*}" \
                                                                  -v mass="0.$MASS" \
                                                                  -v corrDir="$CORRELATOR_DIRECTION" \
                                                                  -v solver="cg" \
                                                                  -v cgmax="30000" \
                                                                  -v cgIterationBlockSize="50" \
                                                                  -v thetaFermionTemporal="1" \
                                                                  -v maxNrCorrs="$NUMBER_SOURCES_FOR_CORRELATORS" \
                                                                  -v chemPot="$CHEMPOT" \
                                                                  -v wilson="$WILSON" \
                                                                  -v staggered="$STAGGERED" '
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
        }' > $WORK_BETADIRECTORY/$SRUN_COMMANDSFILE_FOR_INVERSION

}
