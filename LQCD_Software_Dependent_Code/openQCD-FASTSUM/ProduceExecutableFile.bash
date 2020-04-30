#
#  Copyright (c) 2020 Alessandro Sciarra
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

function ProduceExecutableFileInGivenBetaDirectory_openQCD-FASTSUM()
{
    local betaDirectoryGlobalPath auxiliaryCompilationFilename makefileGlobalpath
    betaDirectoryGlobalPath="$1"
    auxiliaryCompilationFilename='compile_settings.txt'
    makefileGlobalpath="${BHMAS_productionCodebaseGlobalPath}/build/Makefile"
    if [[ ${BHMAS_executionMode} != 'mode:measure' ]]; then
        if [[ ! -f "${makefileGlobalpath}" ]]; then
            Fatal ${BHMAS_fatalFileNotFound}\
                "Makefile of openQCD-FASTSUM was not found as\n"\
                file "${makefileGlobalpath}" '.\n'\
                "Be sure you specify the correct position in the BaHaMAS setup."
        else
            (
                cd "${betaDirectoryGlobalPath}"
                __static__CreateAuxiliaryCompilationFile
                cecho lg '\n Compiling openQCD-FASTSUM...'
                set +e #Manual error handling
                make -j16 -f "${makefileGlobalpath}" "${BHMAS_productionMakefileTarget}"
                if [[ $? -ne 0 ]]; then
                    Fatal ${BHMAS_fatalBuiltin}\
                        'The compilation of openQCD-FASTSUM failed. You can try to manually compile it via\n'\
                        emph "   cd ${betaDirectoryGlobalPath}\n"\
                        emph "   make -f '${makefileGlobalpath}' '${BHMAS_productionMakefileTarget}'\n"\
                        'to investigate the problem. Be sure that the needed modules\n'\
                        'or analogous are loaded correctly and the environment is correctly set.\n'\
                        'The mpicc used was ' emph "${BHMAS_compiler}" '.'
                else
                    __static__MoveCompilationInputFileToOwnFolder "${betaDirectoryGlobalPath}"
                    # Move cursor bottom left due to openQCD-FASTSUM makefile output
                    #  LINES and COLUMNS not necessarily set -> https://stackoverflow.com/a/48016366
                    if [[ "${BHMAS_TESTMODE:-}" != 'TRUE' ]]; then
                        cecho -d "\e[$(tput lines);0H"
                    fi
                    cecho lg ' ...compilation completed successfully!'
                fi
            )
            fi
    else
        Internal 'Function ' emph "${FUNCNAME}" ' called in ' emph "${BHMAS_executionMode#mode:}" ' execution mode!'
    fi
}

function __static__CreateAuxiliaryCompilationFile()
{
    CheckIfVariablesAreDeclared auxiliaryCompilationFilename
    exec 5>&1 1> "${auxiliaryCompilationFilename}"

    cat <<END_OF_COMPILATION_FILE
CODELOC ${BHMAS_productionCodebaseGlobalPath}

COMPILER ${BHMAS_compiler}
MPI_INCLUDE ${BHMAS_folderWithMPIHeaderGlobalPath}

CFLAGS ${BHMAS_compilerFlags}
LDFLAGS

NPROC0_TOT 1
NPROC1_TOT 1
NPROC2_TOT 1
NPROC3_TOT 1

L0 $(( BHMAS_ntime  / 1 ))
L1 $(( BHMAS_nspace / 1 ))
L2 $(( BHMAS_nspace / 1 ))
L3 $(( BHMAS_nspace / 1 ))

NPROC0_BLK 1
NPROC1_BLK 1
NPROC2_BLK 1
NPROC3_BLK 1

END_OF_COMPILATION_FILE

    exec 1>&5-
}

function __static__MoveCompilationInputFileToOwnFolder()
{
    CheckIfVariablesAreDeclared auxiliaryCompilationFilename
    local betaDirectoryGlobalPath compilationFolderGlobalpath destinationFilename
    betaDirectoryGlobalPath="$1"
    compilationFolderGlobalpath="${BHMAS_submitDirWithBetaFolders}/${BHMAS_compilationFolderName}"
    destinationFilename="${auxiliaryCompilationFilename/.txt/_$(basename "${betaDirectoryGlobalPath}")_$(date +'%Y-%m-%d_%H%M%S').txt}"
    if [[ -f "${destinationFilename}" ]]; then
        Internal 'Auxiliary compilation file ' file "${destinationFilename}"\
                 '\nseems to exist already in folder ' dir "${compilationFolderGlobalpath}"\
                 '\nwhich should not be the case in ' emph "${FUNCNAME}" '.'
    else
        mkdir -p "${compilationFolderGlobalpath}" || exit ${BHMAS_fatalBuiltin}
        mv "${betaDirectoryGlobalPath}/${auxiliaryCompilationFilename}"\
           "${compilationFolderGlobalpath}/${destinationFilename}" || exit ${BHMAS_fatalBuiltin}
    fi
}


MakeFunctionsDefinedInThisFileReadonly
