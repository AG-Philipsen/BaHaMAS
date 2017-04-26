#!/bin/bash
#
# Script to automatically set up symlinks for existing hooks.
#
#-----------------------------------------------------------------------------#

repositoryTopLevelPath="$(git rev-parse --show-toplevel)"
source $repositoryTopLevelPath/hooks/AuxiliaryFunctions.sh || exit -2
hookGitFolder=$repositoryTopLevelPath/.git/hooks
hookDistributedFolder=$repositoryTopLevelPath/hooks

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
            ln -s -f ../../hooks/$hook $hook
        fi
    fi
done
errecho '\n'
