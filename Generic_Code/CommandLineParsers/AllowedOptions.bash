#
#  Copyright (c) 2020-2021 Alessandro Sciarra
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

# This function will be reused in manual composition
# to populate the option sections of each manual page
# and in the autocompletion code to keep maintenance
# overhead as small as possible and potentially absent.
#
# ATTENTION: Since this file is sourced by the autocompletion
#            code, which in turn is sourced in the user .bashrc
#            file, it is important to just have one function
#            here and do not rely on other BaHaMAS functionality
#            kile utility functions. E.g. we do not mark this
#            function as readonly as done in the rest of the
#            codebase. Moreover, the function name has a prefix.
function _BaHaMAS_DeclareAllowedOptionsPerModeOrSoftware()
{
    # Sub-parser options
    if [[ "${BHMAS_MANUALMODE-x}" = 'TRUE' ]] || [[ "${BHMAS_AUTOCOMPLETION-x}" = 'TRUE' ]]; then
        allowedOptionsPerModeOrSoftware=(
            ['mode:thermalize']='--fromHot '
            ['mode:continue']='--till '
            ['mode:continue-thermalization']='--till --fromHot '
            ['mode:job-status']='--user --allUsers --local --onlyGivenPartition '
            ['mode:simulation-status']='--doNotMeasureTime --showOnlyQueued --verbose '
            ['mode:acceptance-rate-report']='--interval '
            ['mode:clean-output-files']='--all '
            ['mode:complete-betas-file']='--chains '
            ['mode:comment-betas']='--betas '
            ['mode:uncomment-betas']='--betas '
        )
    fi
    # Each execution mode does not accept the same options and it makes
    # sense to be stricter and to allow only the used ones instead of
    # just ignoring them if not used. The same is valid for options which
    # are restricted to some software only. Note that here we refer option
    # which are either in common to multiple modes or in common to multiple
    # software. An associative array allows to have here an overview. We use
    # as key either a mode or a software to then put in the value those options
    # that are allowed. We will use then two entries of it later to validate.
    #
    # NOTE: The associative array must be declared in the caller
    local productionOptionsCL2QCD clusterOptions
    productionOptions='--measurements --checkpointEvery'
    productionOptionsCL2QCD='--pf --confSaveEvery --cgbs --togglePbp'
    productionOptionsOpenQCD='--processorsGrid --coresPerNode'
    clusterOptions='--walltime  --partition  --node  --constraint  --resource'
    allowedOptionsPerModeOrSoftware+=(
        #-------------------------------------------------------------------------------
        # Specific-mode, all-software options
        ['mode:prepare-only']+="--betasfile ${productionOptions} --jobscript_prefix ${clusterOptions}"
        ['mode:submit-only']+='--betasfile --jobscript_prefix'
        ['mode:new-chain']+="--betasfile  ${productionOptions} --jobscript_prefix ${clusterOptions}"
        ['mode:thermalize']+="--betasfile  ${productionOptions} --jobscript_prefix ${clusterOptions}"
        ['mode:continue']+="--betasfile --measurements --updateExecutable --jobscript_prefix ${clusterOptions}"
        ['mode:continue-thermalization']+="--betasfile --measurements --updateExecutable --jobscript_prefix ${clusterOptions}"
        ['mode:job-status']+='--partition'
        ['mode:simulation-status']+=''
        ['mode:acceptance-rate-report']+='--betasfile'
        ['mode:clean-output-files']+='--betasfile'
        ['mode:complete-betas-file']+='--betasfile'
        ['mode:comment-betas']+='--betasfile'
        ['mode:uncomment-betas']+='--betasfile'
        ['mode:measure']+="--betasfile --jobscript_prefix ${clusterOptions}"
        ['mode:database']+=''
        #-------------------------------------------------------------------------------
        # Multiple mode, specific/multiple-software options
        ["mode:prepare-only_CL2QCD"]+="${productionOptionsCL2QCD}"
        ["mode:new-chain_CL2QCD"]+="${productionOptionsCL2QCD}"
        ["mode:thermalize_CL2QCD"]+="${productionOptionsCL2QCD}"
        ["mode:continue_CL2QCD"]+="${productionOptionsCL2QCD} --checkpointEvery"
        ["mode:continue-thermalization_CL2QCD"]+="${productionOptionsCL2QCD} --checkpointEvery"
        ["mode:prepare-only_openQCD-FASTSUM"]+="${productionOptionsOpenQCD}"
        ["mode:new-chain_openQCD-FASTSUM"]+="${productionOptionsOpenQCD}"
        ["mode:thermalize_openQCD-FASTSUM"]+="${productionOptionsOpenQCD}"
        ["mode:continue_openQCD-FASTSUM"]+='--coresPerNode'
        ["mode:continue-thermalization_openQCD-FASTSUM"]+='--coresPerNode'
        #-------------------------------------------------------------------------------
        # All-modes, specific-software options
        ['CL2QCD']+=''
        ['openQCD-FASTSUM']+=''
    )
}
