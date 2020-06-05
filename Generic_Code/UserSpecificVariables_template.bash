#
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
#         if [[ ${BHMAS_wilson} = "TRUE" ]]; then
#             ...
#         elif [[ ${BHMAS_staggered} = "TRUE" ]]; then
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
    BHMAS_lqcdSoftware="CL2QCD"
    readonly BHMAS_userEmail=""
    readonly BHMAS_submitDiskGlobalPath=""
    readonly BHMAS_runDiskGlobalPath=""
    readonly BHMAS_GPUsPerNode=
    readonly BHMAS_jobScriptFolderName=""
    readonly BHMAS_excludeNodesGlobalPath=""
    readonly BHMAS_projectSubpath=""
    readonly BHMAS_productionExecutableGlobalPath=""
    readonly BHMAS_productionCodebaseGlobalPath=""
    readonly BHMAS_productionMakefileTarget=""
    readonly BHMAS_compiler="$(which mpicc)"
    readonly BHMAS_compilerFlags=""
    readonly BHMAS_folderWithMPIHeaderGlobalPath="${BHMAS_compiler/%bin\/mpicc/include}"
    readonly BHMAS_inputFilename=""
    readonly BHMAS_outputFilename=""
    readonly BHMAS_useRationalApproxFiles='FALSE'
    readonly BHMAS_rationalApproxGlobalPath=""
    readonly BHMAS_approxHeatbathFilename=""
    readonly BHMAS_approxMDFilename=""
    readonly BHMAS_approxMetropolisFilename=""
    readonly BHMAS_databaseFilename=""
    readonly BHMAS_databaseGlobalPath=""
    readonly BHMAS_measurementExecutableGlobalPath=""
    readonly BHMAS_thermConfsGlobalPath=""
    readonly BHMAS_maximumWalltime=""

    #Possible default value for options which then may not be given via command line
    BHMAS_coresPerNode=
    BHMAS_measurePbp='FALSE'
    BHMAS_jobScriptPrefix=""
    BHMAS_walltime=""
    BHMAS_clusterPartition=""
    BHMAS_clusterNode=""
    BHMAS_clusterConstraint=""
    BHMAS_clusterGenericResource=""
}


MakeFunctionsDefinedInThisFileReadonly

# Documentation:
#
#     BHMAS_coloredOutput                    -->  it can be 'TRUE' or 'FALSE' and can be used to disable coloured output
#     BHMAS_lqcdSoftware                     -->  it can be either CL2QCD or openQCD-FASTSUM
#     BHMAS_userEmail                        -->  mail to which job information (e.g. failures) is sent to
#     BHMAS_submitDiskGlobalPath             -->  global path to the disk from which the jobs are submitted (see further informations below)
#     BHMAS_runDiskGlobalPath                -->  global path to the disk from which the jobs are run (see further informations below)
#     BHMAS_GPUsPerNode                      -->  number of GPUs per node
#     BHMAS_coresPerNode                     -->  number of physical CPU cores per node
#     BHMAS_jobScriptFolderName              -->  name of the folder where the job scripts are collected
#     BHMAS_excludeNodesGlobalPath           -->  local or remote global path to file containing the directive to exclude nodes
#     BHMAS_projectSubpath                   -->  path from HOME and WORK to the folder containing the parameters folders structure (see further informations below)
#     BHMAS_productionExecutableGlobalPath   -->  production executable global path
#     BHMAS_productionCodebaseGlobalPath     -->  production codebase (if it has to be compiled)
#     BHMAS_productionMakefileTarget         -->  production Makefile (if it has to be compiled)
#     BHMAS_compiler                         -->  compiler maybe needed for Makefile (if it has to be compiled)
#     BHMAS_compilerFlags                    -->  flags to be given to the compiler (if it has to be compiled)
#     BHMAS_folderWithMPIHeaderGlobalPath    -->  folder where mpi.h is located (if it has to be compiled)
#     BHMAS_inputFilename                    -->  name of the inputfile
#     BHMAS_jobScriptPrefix                  -->  prefix of the jobscript name
#     BHMAS_outputFilename                   -->  name of the outputfile
#     BHMAS_rationalApproxGlobalPath         -->  global path to the folder containing the rational approximations
#     BHMAS_approxHeatbathFilename           -->  rational approximation used for the pseudofermion fields
#     BHMAS_approxMDFilename                 -->  rational approximation used for the molecular dynamis
#     BHMAS_approxMetropolisFilename         -->  rational approximation used for the metropolis test
#     BHMAS_measurementExecutableGlobalPath  -->  inverter executable global path
#     BHMAS_thermConfsGlobalPath             -->  global path to the folder containing the thermalized configurations
#     BHMAS_databaseGlobalPath               -->  directory where the the simulation status files are stored (it MUST be a GLOBALPATH)
#     BHMAS_databaseFilename                 -->  name of the file containing the database
#     BHMAS_maximumWalltime                  -->  maximum walltime accepted by the scheduler in the format 'days-hours:min:sec'
#     BHMAS_walltime                         -->  jobs walltime in the format 'days-hours:min:sec'
#     BHMAS_clusterPartition                 -->  name of the partition of the cluster that has to be used
#     BHMAS_clusterNode                      -->  list of nodes that have to be used
#     BHMAS_clusterConstraint                -->  constraint on hardware of the cluster
#     BHMAS_clusterGenericResource           -->  cluster resource selection
#
# Some further information:
#
#   The BHMAS_submitDiskGlobalPath, BHMAS_runDiskGlobalPath, BHMAS_projectSubpath variables above could be a bit confusing. Basically, they are used to build the global
#   path of the folders from which the jobs are submitted and run. In particular:
#
#       - folder global path from which jobs are submitted:  ${BHMAS_submitDiskGlobalPath}/${BHMAS_projectSubpath}/${BHMAS_parametersPath}
#       -       folder global path from which jobs are run:  ${BHMAS_runDiskGlobalPath}/${BHMAS_projectSubpath}/${BHMAS_parametersPath}
#
#   where ${BHMAS_parametersPath} is the folder structure like 'Nf2/muiPiT/k1550/nt6/ns12' or like 'Nf3/mui0/mass0250/nt4/ns8'.
#
