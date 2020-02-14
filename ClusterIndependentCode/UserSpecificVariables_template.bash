
# User provided variables necessary in order to use BaHaMAS
#
# NOTE: This is only a template file and it MUST be copied into another file
#       called "UserSpecificVariables.bash" and completed, setting all the
#       variables to proper values. Feel free to customize your checks, but
#       consider that this function is called at the beginning of BaHaMAS.
#
# NOTE: Use the variables 'BHMAS_wilson' and 'BHMAS_staggered' to define
#       differently the same variables in the two cases. For example:
#
#         if [ $BHMAS_wilson = "TRUE" ]; then
#             ...
#         elif [ $BHMAS_staggered = "TRUE" ]; then
#             ...
#         fi
#
# ATTENTION: Do not put slashes "/" at the end of the paths variables!!

function DeclareOutputRelatedGlobalVariables()
{
    readonly BHMAS_coloredOutput='TRUE'
}

function DeclareUserDefinedGlobalVariables()
{
    readonly BHMAS_userEmail=""
    readonly BHMAS_submitDiskGlobalPath=""
    readonly BHMAS_runDiskGlobalPath=""
    readonly BHMAS_GPUsPerNode=
    readonly BHMAS_jobScriptFolderName=""
    readonly BHMAS_excludeNodesGlobalPath=""
    readonly BHMAS_projectSubpath=""
    readonly BHMAS_hmcGlobalPath=""
    readonly BHMAS_inputFilename=""
    readonly BHMAS_outputFilename=""
    readonly BHMAS_plaquetteColumn=
    readonly BHMAS_deltaHColumn=
    readonly BHMAS_acceptanceColumn=
    readonly BHMAS_trajectoryTimeColumn=
    readonly BHMAS_useRationalApproxFiles='FALSE'
    readonly BHMAS_rationalApproxGlobalPath=""
    readonly BHMAS_approxHeatbathFilename=""
    readonly BHMAS_approxMDFilename=""
    readonly BHMAS_approxMetropolisFilename=""
    readonly BHMAS_databaseFilename=""
    readonly BHMAS_databaseGlobalPath=""
    readonly BHMAS_inverterGlobalPath=""
    readonly BHMAS_thermConfsGlobalPath=""
    readonly BHMAS_maximumWalltime=""

    #Possible default value for options which then may not be given via command line
    BHMAS_jobScriptPrefix=""
    BHMAS_walltime=""
    BHMAS_clusterPartition=""
    BHMAS_clusterNode=""
    BHMAS_clusterConstraint=""
    BHMAS_clusterGenericResource=""
}


#----------------------------------------------------------------#
#Set functions readonly
readonly -f\
         DeclareOutputRelatedGlobalVariables\
         DeclareUserDefinedGlobalVariables

# Documentation:
#
#     BHMAS_coloredOutput              -->  it can be 'TRUE' or 'FALSE' and can be used to disable coloured output
#     BHMAS_userEmail                  -->  mail to which job information (e.g. failures) is sent to
#     BHMAS_submitDiskGlobalPath       -->  global path to the disk from which the jobs are submitted (see further informations below)
#     BHMAS_runDiskGlobalPath          -->  global path to the disk from which the jobs are run (see further informations below)
#     BHMAS_GPUsPerNode                -->  number of GPUs per node
#     BHMAS_jobScriptFolderName        -->  name of the folder where the job scripts are collected
#     BHMAS_excludeNodesGlobalPath     -->  local or remote global path to file containing the directive to exclude nodes
#     BHMAS_projectSubpath             -->  path from HOME and WORK to the folder containing the parameters folders structure (see further informations below)
#     BHMAS_hmcGlobalPath              -->  production executable global path
#     BHMAS_inputFilename              -->  name of the inputfile
#     BHMAS_jobScriptPrefix            -->  prefix of the jobscript name
#     BHMAS_outputFilename             -->  name of the outputfile
#     BHMAS_plaquetteColumn            -->  number of column containing the plaquette value [first column is column number 1].
#     BHMAS_deltaHColumn               -->  number of column containing the dH value [first column is column number 1].
#     BHMAS_acceptanceColumn           -->  number of column containing outcomes (zeros or ones) of Metropolis test [first column is column number 1].
#     BHMAS_trajectoryTimeColumn       -->  number of column containing the trajectory time in seconds [first column is column number 1].
#     BHMAS_rationalApproxGlobalPath   -->  global path to the folder containing the rational approximations
#     BHMAS_approxHeatbathFilename     -->  rational approximation used for the pseudofermion fields
#     BHMAS_approxMDFilename           -->  rational approximation used for the molecular dynamis
#     BHMAS_approxMetropolisFilename   -->  rational approximation used for the metropolis test
#     BHMAS_inverterGlobalPath         -->  inverter executable global path
#     BHMAS_thermConfsGlobalPath       -->  global path to the folder containing the thermalized configurations
#     BHMAS_databaseGlobalPath         -->  directory where the the simulation status files are stored (it MUST be a GLOBALPATH)
#     BHMAS_databaseFilename           -->  name of the file containing the database
#     BHMAS_maximumWalltime            -->  maximum walltime accepted by the scheduler in the format 'days-hours:min:sec'
#     BHMAS_walltime                   -->  jobs walltime in the format 'days-hours:min:sec'
#     BHMAS_clusterPartition           -->  name of the partition of the cluster that has to be used
#     BHMAS_clusterNode                -->  list of nodes that have to be used
#     BHMAS_clusterConstraint          -->  constraint on hardware of the cluster
#     BHMAS_clusterGenericResource     -->  cluster resource selection
#
# Some further information:
#
#   The BHMAS_submitDiskGlobalPath, BHMAS_runDiskGlobalPath, BHMAS_projectSubpath variables above could be a bit confusing. Basically, they are used to build the global
#   path of the folders from which the jobs are submitted and run. In particular:
#
#       - folder global path from which jobs are submitted:  $BHMAS_submitDiskGlobalPath/$BHMAS_projectSubpath/$BHMAS_parametersPath
#       -       folder global path from which jobs are run:  $BHMAS_runDiskGlobalPath/$BHMAS_projectSubpath/$BHMAS_parametersPath
#
#   where $BHMAS_parametersPath is the folder structure like 'Nf2/muiPiT/k1550/nt6/ns12' or like 'Nf3/mui0/mass0250/nt4/ns8'.
#
