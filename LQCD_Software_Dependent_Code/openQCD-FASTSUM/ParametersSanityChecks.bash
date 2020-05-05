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

function PerformParametersSanityChecks_openQCD-FASTSUM()
{
    local index
    case ${BHMAS_executionMode} in
        mode:new-chain | mode:prepare-only | mode:thermalize | mode:continue* )
            if [[ ${BHMAS_executionMode} != mode:continue* ]]; then
                __static__WarnIfProcessorCombinationIsUnset
                __static__CheckIfProcessorCombinationIsAllowed
            fi
            __static__CheckIfSAPBlockSizeIsAllowed
            if [[ ${BHMAS_executionMode} != mode:continue* ]]; then
                for index in "${BHMAS_processorsGrid[@]}"; do
                    BHMAS_productionExecutableFilename+="_${index}"
                done
            fi
            ;;
    esac
    readonly BHMAS_productionExecutableFilename
}

function __static__WarnIfProcessorCombinationIsUnset()
{
    if [[ ${#BHMAS_processorsGrid[@]} -ne 4 ]]; then
        Warning 'The processor grid was not specified, using (1 1 1 1).'
        BHMAS_processorsGrid=( 1 1 1 1 )
    fi
}

function __static__CheckIfProcessorCombinationIsAllowed()
{
    local usedCores index error; error=0
    usedCores=$(CalculateProductOfIntegers ${BHMAS_processorsGrid[@]})
    #Number of cores multiple of those per node
    if (( usedCores % BHMAS_coresPerNode != 0 )); then
        error=1
    fi
    for index in {0..3}; do
        #Number of processors in each dimension 1 or even
        if (( BHMAS_processorsGrid[index] != 1 )) && (( BHMAS_processorsGrid[index] % 2 != 0 )); then
            error=2
        fi
        #Each local lattice dimension at least 4 and even
        if (( BHMAS_latticeSize[index] / BHMAS_processorsGrid[index] < 4 )) || (( BHMAS_latticeSize[index] / BHMAS_processorsGrid[index] % 2 != 0 )); then
            error=3
        fi
    done
    case ${error} in
        0)
            ;;
        1)
            Error "The total number of used cores (${usedCores})\n"\
                  "must be multiple of those per node (${BHMAS_coresPerNode}).\n"\
                  "$((BHMAS_coresPerNode - usedCores % BHMAS_coresPerNode)) will be left unused wasting time!"
            AskUser -n 'Do you want to continue?'
            if UserSaidNo; then
                Fatal ${BHMAS_fatalCommandLine} 'Specified processors grid would lead to waste of resources.'
            fi
            ;;
        2)
            Fatal ${BHMAS_fatalCommandLine} "Number of processors in each dimension must be 1 or even!"
            ;;
        3)
            Fatal ${BHMAS_fatalCommandLine} "Each local lattice dimension must be at least 4 and even!"
            ;;
        *)
            Fatal ${BHMAS_fatalCommandLine} "Processors grid specified is not allowed to run openQCD-FASTSUM!"
            ;;
    esac
}

function __static__CheckIfSAPBlockSizeIsAllowed()
{
    for index in "${!BHMAS_sapBlockSize[@]}"; do # Skip for if sap array is empty!
        if(( (BHMAS_latticeSize[index]/BHMAS_processorsGrid[index]) % BHMAS_sapBlockSize[index] != 0 )); then
            Fatal ${BHMAS_fatalCommandLine} \
                "The SAP block size in direction ${index} does not divide the\n"\
                "local lattice in such a direction ($((latticeSize[index]/processorsGrid[index]))).\n"\
                'Please adjust it and run the script again.'
        fi
    done
}


MakeFunctionsDefinedInThisFileReadonly
