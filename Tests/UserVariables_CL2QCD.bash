#
#  Copyright (c) 2017-2018,2020 Alessandro Sciarra
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

function DeclareOutputRelatedGlobalVariables()
{
    readonly BHMAS_coloredOutput='TRUE'
}

function DeclareUserDefinedGlobalVariables()
{
    BHMAS_lqcdSoftware="CL2QCD"
    readonly BHMAS_userEmail="user@test.com"
    readonly BHMAS_submitDiskGlobalPath="${BHMAS_repositoryTopLevelPath}/Tests/RunTestFolder/SubmitDisk"
    readonly BHMAS_runDiskGlobalPath="${BHMAS_repositoryTopLevelPath}/Tests/RunTestFolder/RunDisk"
    readonly BHMAS_GPUsPerNode=999
    readonly BHMAS_jobScriptFolderName="Jobscripts_TEST"
    readonly BHMAS_excludeNodesGlobalPath="${BHMAS_submitDiskGlobalPath}/ExcludeNodes_TEST"
    readonly BHMAS_projectSubpath="StaggeredFakeProject"
    readonly BHMAS_productionExecutableGlobalPath="${BHMAS_repositoryTopLevelPath}/Tests/AuxiliaryFiles/fakeExecutable"
    readonly BHMAS_productionCodebaseGlobalPath=''
    readonly BHMAS_productionMakefileTarget=''
    readonly BHMAS_compiler=''
    readonly BHMAS_compilerFlags=''
    readonly BHMAS_folderWithMPIHeaderGlobalPath=''
    readonly BHMAS_inputFilename="fakeInput"
    readonly BHMAS_jobScriptPrefix="fakePrefix"
    readonly BHMAS_outputFilename="fakeOutput"
    readonly BHMAS_plaquetteColumn=2
    readonly BHMAS_deltaHColumn=8
    readonly BHMAS_acceptanceColumn=9
    readonly BHMAS_trajectoryTimeColumn=10
    readonly BHMAS_useRationalApproxFiles='TRUE'
    readonly BHMAS_rationalApproxGlobalPath="${BHMAS_submitDiskGlobalPath}/${BHMAS_projectSubpath}/Rational_Approximations"
    readonly BHMAS_approxHeatbathFilename="Approx_Heatbath"
    readonly BHMAS_approxMDFilename="Approx_MD"
    readonly BHMAS_approxMetropolisFilename="Approx_Metropolis"
    readonly BHMAS_databaseFilename="OverviewDatabase"
    readonly BHMAS_databaseGlobalPath="${BHMAS_submitDiskGlobalPath}/${BHMAS_projectSubpath}/SimulationsOverview"
    readonly BHMAS_measurementExecutableGlobalPath="${BHMAS_repositoryTopLevelPath}/Tests/AuxiliaryFiles/fakeExecutable"
    readonly BHMAS_thermConfsGlobalPath="${BHMAS_submitDiskGlobalPath}/${BHMAS_projectSubpath}/Thermalized_Configurations"

    #Possible default value for options which can then not be given via command line
    BHMAS_walltime=""
    BHMAS_clusterPartition=""
    BHMAS_clusterNode=""
    BHMAS_clusterConstraint=""
    BHMAS_clusterGenericResource=""
    BHMAS_maximumWalltime="1-00:00:00"
}


MakeFunctionsDefinedInThisFileReadonly
