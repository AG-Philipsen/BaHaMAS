% BaHaMAS-prepare-only(1) Version 1.0.0 | User Manual
% [Alessandro Sciarra](sciarra@itp.uni-frankfurt.de)
% 14 April 2020

# NAME

BaHaMAS-prepare-only - Prepare needed files and folders to submit new-chain simulation(s)

# SYNOPSIS

**BaHaMAS prepare-only** [*option* ...]

# DESCRIPTION

The **betas** file is parsed in order to gather information about which simulation should be prepared (only uncommented lines are considered in this mode).
This mode operates exclusively on new-chain jobs and it prepares everything is needed to submit them.

If successfully run, the user can have a look at the files created and submit the jobs at a later point using the **submit-only** execution mode.

# OPTIONS

\--betasfile *filename*
:   Use *filename* instead of **betas** file.

\--measurements *number*
:   Specify the number of trajectories that should be done (default: 1000).

\--checkpointEvery *number*
:   Specify every how many trajectories a check-point should be stored to disk (default: 100).

\--jobscript_prefix *string*
:   Specify the prefix of the jobscript file (default: own setup).

\--walltime *dd-hh:mm:ss* |  *human-string*
:   Specify the simulation wall-time (default: own setup).
    To specify e.g. one day, you can either use the standard form **1-00:00:00** or a more handy *human-string*, in the example **1d**.
    Supported postfixes are **d** for days, **h** for hours, **m** for minutes and **s** for seconds.
    **1-12:06:30** is then equivalent to **1d12h6m30s**.

\--partition *string*
:   Specify on which partition the job should be submitted (default: own setup).
    For instance, for SLURM, this will use the **\--partition** sbatch directive.

\--node *node-list*
:   Specify on which node(s) the job should be submitted (default: own setup).
    The *node-list* has to comply with the cluster specifications.
    For instance, for SLURM, this will use the **\--nodelist** sbatch directive.

\--constraint *string*
:   Specify a hardware constraint for the to-be-submitted jobs (default: own setup).
    The *string* has to comply with the cluster specifications.
    For instance, for SLURM, this will use the **\--gres** sbatch directive.

\--resource *string*
:   Specify a resource selection (default: own setup).
    The *string* has to comply with the cluster specifications.
    For instance, for SLURM, this will use the **\--constraint** sbatch directive.

# CL2QCD OPTIONS

\--pf *number*
:   Specify how many pseudofermions should be used (default: 1).

\--confSaveEvery
:   Specify every how many trajectories the **.save** checkpoint is overwritten (default: 20).

\--cgbs *number*
:   Specify the conjugate gradient block-size and namely every how many iterations on the device the residuum is checked for convergence on the host (default: 50).

# openQCD-FASTSUM OPTIONS

\--processorsGrid
:   Specify 4 integers which refer to how many processors have to be used to split the lattice in every direction (default: 1 1 1 1).
    The first entry refer to the temporal lattice direction and the other three to the spatial ones.

# FILES

./betas
:   Only uncommented lines in the **betas** file are considered in this mode.

# SEE ALSO

**BaHaMAS**(1), **BaHaMAS-submit-only**(1)

# BAHAMAS

Part of the **BaHaMAS** software.
