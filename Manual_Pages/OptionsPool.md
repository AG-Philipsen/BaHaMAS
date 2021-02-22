# OPTIONS

\--fromHot
:   Force BaHaMAS to act on thermalization(s) from hot without determining itself the thermalization type.

\--measurePbp
:   Force BaHaMAS to measure the pbp ignoring the setup value and the fact being in a thermalization run.

\--updateExecutable
:   Make BaHaMAS produce again the executable file and replace the existing one in the beta folder(s), instead of simply using it.
    This option can be handy e.g. if the administrators of the cluster changed or updated some software and you are then required to recreate your executable(s).

\--till, \-t *number*
:   Specify till which trajectory number the simulations should be continued.

\--interval *number*
:   Specify how many trajectories should be considered to calculate the acceptance rate.

\--onlyFromHot
:   Only thermalizations from hot will be included in the acceptance rate report.

\--onlyFromConf
:   Only thermalizations from conf will be included in the acceptance rate report.

\--onlyNewChains
:   Only new chains will be included in the acceptance rate report.

\--allUsers, \-a
:   Jobs enqueued by any user are considered in the report, even if a specific user is specified.

\--partition *string* @mode:job-status@
:   Limit the report to the specified partition (default: own setup).

\--onlyGivenPartition
:   Only jobs enqueued in the given partition (either on the command line or in the own setup) are considered in the report.

\--user, \-u @mode:job-status@
:   Only the jobs enqueued by the specified user are considered in the report (default: user that runs the command).

\--local, \-l @mode:job-status@
:   Only jobs submitted from the present directory or a sub-folder of it are considered in the report.

\--all, \-a @mode:clean-output-files@
:   All existing new-chain folders are considered and the **betas** file is not parsed.

\--doNotMeasureTime
:   Switch off trajectory times measurement.
    No information about production time per trajectory will be displayed.

\--showOnlyQueued
:   Limit the simulation status report to simulations for which a job is enqueued.
    This option can be useful when many simulations are run in the same folder.

\--verbose
:   Explicitly print errors instead of ignoring folders or simply do not extract information.

\--chains *number*
:   The number of chains that must exist per beta value in the **betas** file (default: 4).

\--betas *space-separated_list*
:   The beta line(s) to be toggled in the **betas** file.

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

\--confSaveEvery, \-F
:   Specify every how many trajectories the **.save** checkpoint is overwritten (default: 20).

\--cgbs *number*
:   Specify the conjugate gradient block-size and namely every how many iterations on the device the residuum is checked for convergence on the host (default: 50).

\--pf *number*
:   Specify how many pseudofermions should be used (default: 1).

\--togglePbp
:   Invert logic value about measurement of the pbp specified by the user in the setup.

# OPENQCD-FASTSUM OPTIONS

\--processorsGrid, \-p
:   Specify 4 integers which refer to how many processors have to be used to split the lattice in every direction (default: 1 1 1 1).
    The first entry refer to the temporal lattice direction and the other three to the spatial ones.

\--coresPerNode
:   Specify how many nodes should be used per node (default: own setup).


# This line is here just to avoid that any git hook remove trailing empty lines relevant for manuals
