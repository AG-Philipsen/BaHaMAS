#!/bin/bash
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

# Script to automatically set up symlinks for existing hooks.

readonly repositoryTopLevelPath="$(git rev-parse --show-toplevel)"
readonly hookGitFolder=${repositoryTopLevelPath}/.git/hooks
readonly hookDistributedFolder=${repositoryTopLevelPath}/Hooks

source ${repositoryTopLevelPath}/ClusterIndependentCode/ErrorCodes.bash || exit 64
source ${hookDistributedFolder}/AuxiliaryFunctions.bash || exit $BHMAS_fatalBuiltin

cd $hookGitFolder

# Here we rely on the fact that in the "hooks" folder the executable files are only this
# script together with all the hooks that will then be used. It sounds reasonable.
errecho '\n'
for hook in $(find $hookDistributedFolder -maxdepth 1 -perm -111 -type f -printf "%f\n"); do
    #We have to skip this executable file
    if [ $hook != $(basename $BASH_SOURCE) ]; then
        if [ -e $hook ]; then
            if [ -L $hook ] && [ $(realpath $hook) = $hookDistributedFolder/$hook ]; then
                errecho "Hook \"$hook\" already correctly symlinked!\n" 10
                continue
            else
                errecho "Hook \"$hook\" already existing, symlink not created!\n" 9
                continue
            fi
        else
            commandToBeRun="ln -s -f ../../Hooks/$hook $hook"
            errecho "Symlinking hook \"$hook\"" 13
            errecho "$commandToBeRun"
            $commandToBeRun
            if [ ! -e $hook ]; then
                errecho "...failed!\n" 9
            else
                errecho "...done!\n" 10
            fi
        fi
    fi
done
errecho '\n'
