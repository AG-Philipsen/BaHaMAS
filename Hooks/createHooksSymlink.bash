#!/bin/bash

#-------------------------------------------------------------------------------#
#   This file is part of BaHaMAS and it is subject to the terms and conditions  #
#   defined in the LICENCE.md file, which is distributed within the software.   #
#-------------------------------------------------------------------------------#

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
