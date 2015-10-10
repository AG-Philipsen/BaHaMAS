function ProduceSrunCommandsFileForInversionsPerBeta(){

        ls $WORK_BETADIRECTORY | grep "conf\.[[:digit:]]\{5\}" | awk -v ns="$NSPACE" \
                                                                     -v nt="$NTIME" \
                                                                     -v useCpu="false"   \
                                                                     -v startcondition="continue" \
                                                                     -v logLevel="info" \
                                                                     -v beta="${BETA%%_*}" \
                                                                     -v kappa="0.$KAPPA" \
                                                                     -v corrDir="$CORRELATOR_DIRECTION" \
                                                                     -v solver="cg" \
                                                                     -v cgmax="30000" \
                                                                     -v cgIterationBlockSize="50" \
                                                                     -v thetaFermionTemporal="1" \
                                                                     -v maxNrCorrs="$NUMBER_SOURCES_FOR_CORRELATORS" '
        BEGIN{
                srand();
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
                    #print new_corr_name;
                    if(new_corr_name in conf_x_y_z_t_corr_key == 0)
                    {
                        conf_x_y_z_t_corr_key_new[new_corr_name];
                        conf_count[conf_nr]++;
                    }            
                }
            }

            n = asorti(conf_count, conf_count_sorted);
            for(i = 1; i <= n; ++i)
            {
               for(j in conf_x_y_z_t_corr_key_new)
               {
                   if(match(j,conf_count_sorted[i]))
                   {
                       split(j,corr_name_array,"_"); 
                       print "--sourcefile=" conf_count_sorted[i] " --use_cpu=" useCpu " --startcondition=" startcondition " --log-level=" logLevel " --ns=" ns " --nt=" nt " --source_x=" corr_name_array[2] " --source_y=" corr_name_array[3] " --source_z=" corr_name_array[4] " --source_t=" corr_name_array[5] " --beta=" beta " --kappa=" kappa " --corr_dir=" corrDir " --solver=" solver " --cgmax=" cgmax " --cg_iteration_block_size=" cgIterationBlockSize " --theta_fermion_temporal=" thetaFermionTemporal " --ferm_obs_corr_postfix=" "_" corr_name_array[2] "_" corr_name_array[3] "_" corr_name_array[4] "_" corr_name_array[5] "_corr";
                   }
               }
            }
        }' > $WORK_BETADIRECTORY/$SRUN_COMMANDSFILE_FOR_INVERSION
}

