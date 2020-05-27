% BaHaMAS-continue(1) Version 1.0.0 | User Manual
% [Alessandro Sciarra](sciarra@itp.uni-frankfurt.de)
% 27 March 2020

# NAME

BaHaMAS-continue - Adjust input file(s) and resume new-chain simulation(s)

# SYNOPSIS

**BaHaMAS continue** [*option* ...]

# DESCRIPTION

The **betas** file is parsed in order to gather information about the simulations that should be continued (only uncommented lines are considered in this mode).
This mode operates exclusively on new-chains jobs and it tries to continue them.
The input file of each simulation is adjusted according to the option passed and some sanity checks are performed.
The number of trajectories which will be done is determined as follows.

 * If the **\--measurements** option is given, then it will be used.
 * Otherwise, if the **\--till***=number* option is given, then it will be used.
 * Otherwise, if the **g***number* field is present in the **betas** file, then it will be used.
 * Otherwise, the measurement option in the input file is not modified.

To resume a simulation from a given trajectory, add a **r***number* field in the **betas** file.
Use **rlast** in the **betas** file to resume a simulation from the last saved checkpoint.
If the **r** field is absent in the **betas** file, the adopted behaviour is software-dependent.

 * For **CL2QCD**, which support a temporary check-point mechanism, this will be used (and a cleaning of the output file(s) will be needed at a later stage).
 * For **openQCD-FASTSUM** the run will be resumed as if **rlast** was specified.

If possible, based on the provided information, it is checked if each simulation is finished and, if so, it is not continued and a message is printed for the user.

# OPTIONS

\--till, \-t *number*
:   Specify till which trajectory number the simulations should be continued.

\--betasfile *filename*
:   Use *filename* instead of **betas** file.

\--measurements, \-m *number*
:   Specify the number of trajectories that should be done (default: 1000).

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

\--processorsGrid, \-p
:   Specify 4 integers which refer to how many processors have to be used to split the lattice in every direction (default: 1 1 1 1).
    The first entry refer to the temporal lattice direction and the other three to the spatial ones.

# FILES

./betas
:   Only uncommented lines in the **betas** file are considered in this mode.

# SEE ALSO

**BaHaMAS**(1)

# BAHAMAS

Part of the **BaHaMAS** software.
