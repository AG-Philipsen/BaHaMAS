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
    BHMAS_lqcdSoftware="openQCD-FASTSUM"
    readonly BHMAS_userEmail="user@test.com"
    readonly BHMAS_submitDiskGlobalPath="${BHMAS_repositoryTopLevelPath}/Tests/RunTestFolder/SubmitDisk"
    readonly BHMAS_runDiskGlobalPath="${BHMAS_repositoryTopLevelPath}/Tests/RunTestFolder/RunDisk"
    readonly BHMAS_GPUsPerNode=
    readonly BHMAS_jobScriptFolderName="Jobscripts_TEST"
    readonly BHMAS_excludeNodesGlobalPath="${BHMAS_submitDiskGlobalPath}/ExcludeNodes_TEST"
    readonly BHMAS_projectSubpath="WilsonFakeProject"
    readonly BHMAS_productionExecutableGlobalPath=''
    readonly BHMAS_productionCodebaseGlobalPath="${BHMAS_repositoryTopLevelPath}/Tests/AuxiliaryFiles/fakeOpenQCD-FASTSUM"
    readonly BHMAS_productionMakefileTarget="qcd1"
    readonly BHMAS_compiler="$(which mpicc)"
    readonly BHMAS_compilerFlags='-std=c99 -O2 -DAVX -DFMA3 -Werror -Wall'
    readonly BHMAS_folderWithMPIHeaderGlobalPath="${BHMAS_compiler/%bin\/mpicc/include}"
    readonly BHMAS_inputFilename="fakeInput"
    readonly BHMAS_jobScriptPrefix="fakePrefix"
    readonly BHMAS_outputFilename="fakeOutput"
    readonly BHMAS_plaquetteColumn=
    readonly BHMAS_deltaHColumn=
    readonly BHMAS_acceptanceColumn=
    readonly BHMAS_trajectoryTimeColumn=
    readonly BHMAS_useRationalApproxFiles=''
    readonly BHMAS_rationalApproxGlobalPath=''
    readonly BHMAS_approxHeatbathFilename=''
    readonly BHMAS_approxMDFilename=''
    readonly BHMAS_approxMetropolisFilename=''
    readonly BHMAS_databaseFilename="OverviewDatabase"
    readonly BHMAS_databaseGlobalPath="${BHMAS_submitDiskGlobalPath}/${BHMAS_projectSubpath}/SimulationsOverview"
    readonly BHMAS_measurementExecutableGlobalPath=''
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
