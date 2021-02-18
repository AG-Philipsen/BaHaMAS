% BaHaMAS-continue-thermalization(1) Version 0.3.1 | User Manual
% [Alessandro Sciarra](sciarra@itp.uni-frankfurt.de)
% 11 September 2020

# NAME

BaHaMAS-continue-thermalization - Adjust input file(s) and resume thermalization simulation(s)

# SYNOPSIS

**BaHaMAS continue-thermalization** [*option* ...]

# DESCRIPTION

The **betas** file is parsed in order to gather information about the simulations that should be continued (only uncommented lines are considered in this mode).
This mode operates exclusively on thermalization jobs and it tries to continue them.

Whether a thermalization "from hot" or a thermalization "from conf" should be continued is determined based on the existence of an already thermalized configuration from hot in the folder of thermalized configurations.
**If at least one exists, then it is assumed that a thermalization "from conf" is being done.**
This might not be what the user wants, though.
If e.g. a thermalization "from hot" is finished but one other crashed and the user wishes to resume it, then the automatic mechanism should be disabled.
This can be comfortably done using the **\--fromHot** option.

The input file of each simulation is adjusted according to the option passed and some sanity checks are performed.
Refer to the manual page of the **continue** execution mode to read in detail how the input file is adjusted.

# OPTIONS

\--till, \-t *number*
:   Specify till which trajectory number the simulations should be continued.

\--fromHot
:   Force BaHaMAS to act on thermalization(s) from hot without determining itself the thermalization type.

\--betasfile *filename*
:   Use *filename* instead of **betas** file.

\--measurements, \-m *number*
:   Specify the number of trajectories that should be done (default: 1000).

\--updateExecutable
:   Make BaHaMAS produce again the executable file and replace the existing one in the beta folder(s), instead of simply using it.
    This option can be handy e.g. if the administrators of the cluster changed or updated some software and you are then required to recreate your executable(s).

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

\--checkpointEvery, \-f *number*
:   Specify every how many trajectories a check-point should be stored to disk (default: 100).

# openQCD-FASTSUM OPTIONS

\--coresPerNode
:   Specify how many nodes should be used per node (default: own setup).

# FILES

./betas
:   Only uncommented lines in the **betas** file are considered in this mode.

# SEE ALSO

**BaHaMAS**(1), **BaHaMAS-continue**(1)

# BAHAMAS

Part of the **BaHaMAS** software.
