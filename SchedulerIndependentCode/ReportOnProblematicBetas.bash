#
#  Copyright (c) 2017,2020 Alessandro Sciarra
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

function PrintReportForProblematicBeta()
{
    if [ ${#BHMAS_problematicBetaValues[@]} -gt "0" ]; then
        cecho lr "\n===================================================================================\n"\
              " For the following beta values something went wrong and hence\n"\
              " they were left out during file creation and/or job submission:"
        for BETA in ${BHMAS_problematicBetaValues[@]}; do
            cecho lr "  - " B "$BETA"
        done
        cecho lr "===================================================================================\n"
        exit $BHMAS_fatalGeneric
    fi
}


MakeFunctionsDefinedInThisFileReadonly
