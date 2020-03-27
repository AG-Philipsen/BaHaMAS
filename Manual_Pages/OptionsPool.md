# OPTIONS

\--till *number*
:   Specify till which trajectory number the simulations should be continued.

\--betasfile *filename*
:   Use *filename* instead of **betas** file.

\--measurements *number*
:   Specify the number of trajectories that should be done (default: 1000).

\--checkpointEvery *number*
:   Specify every how many trajectories a check-point should be stored to disk (default: 100).

\--pf *number*
:   Specify how many pseudofermions should be used (default: 1).

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

\--confSaveEvery
:   Specify every how many trajectories the **.save** checkpoint is overwritten (default: 20).
