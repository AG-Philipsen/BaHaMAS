% BaHaMAS-thermalize(1) Version 0.3.1 | User Manual
% [Alessandro Sciarra](sciarra@itp.uni-frankfurt.de)
% 11 September 2020

# NAME

BaHaMAS-thermalize - Prepare what is needed and submit thermalization simulation(s)

# SYNOPSIS

**BaHaMAS thermalize** [*option* ...]

# DESCRIPTION

The **betas** file is parsed in order to gather information about the simulations that should be submitted (only uncommented lines are considered in this mode).
This mode operates exclusively on thermalization jobs.
After having prepared everything that is needed (e.g. input file. job script), jobs for the selected betas are submitted.

The starting configuration for the thermalization is automatically searched in the thermalized configurations folder and information about it is given to the user.
If no configuration with the same parameters of the actual position is found or if the **\--fromHot** option is given, a thermalization "from hot" will be started.
If at least one thermalized configuration "from hot" exists and if the **\--fromHot** option is not given, then a thermalization "from conf" will be started.

Most of the information for the simulation input file(s) is retrieved from the **betas** file, but the user can also tune some input via the command line options.
The **g***number* and **pf***number* fields in the **betas** file have priority on the **\--measurements** and **\--pf** command line options, respectively.

# OPTIONS

\--fromHot
:   Force BaHaMAS to act on thermalization(s) from hot without determining itself the thermalization type.

\--betasfile *filename*
:   Use *filename* instead of **betas** file.

\--measurements, \-m *number*
:   Specify the number of trajectories that should be done (default: 1000).

\--checkpointEvery, \-f *number*
:   Specify every how many trajectories a check-point should be stored to disk (default: 100).

\--jobscript_prefix *string*
:   Specify the prefix of the jobscript file (default: own setup).

\--walltime, \-w *dd-hh:mm:ss* |  *human-string*
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

\--confSaveEvery, \-F
:   Specify every how many trajectories the **.save** checkpoint is overwritten (default: 20).

\--cgbs *number*
:   Specify the conjugate gradient block-size and namely every how many iterations on the device the residuum is checked for convergence on the host (default: 50).

\--togglePbp
:   Invert logic value about measurement of the pbp specified by the user in the setup.

# openQCD-FASTSUM OPTIONS

\--processorsGrid, \-p
:   Specify 4 integers which refer to how many processors have to be used to split the lattice in every direction (default: 1 1 1 1).
    The first entry refer to the temporal lattice direction and the other three to the spatial ones.

\--coresPerNode
:   Specify how many nodes should be used per node (default: own setup).

# FILES

./betas
:   Only uncommented lines in the **betas** file are considered in this mode.

# SEE ALSO

**BaHaMAS**(1), **BaHaMAS-continue-thermalization**(1)

# BAHAMAS

Part of the **BaHaMAS** software.
