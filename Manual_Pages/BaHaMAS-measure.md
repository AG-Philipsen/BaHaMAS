% BaHaMAS-measure(1) Version 1.0.0 | User Manual
% [Alessandro Sciarra](sciarra@itp.uni-frankfurt.de)
% 14 April 2020

# NAME

BaHaMAS-measure - Prepare what is needed and submit measurement job(s)

# SYNOPSIS

**BaHaMAS measure** [*option* ...]

# DESCRIPTION

The **betas** file is parsed in order to gather information about on which configuration sets it should be acted (only uncommented lines are considered in this mode).
This mode operates exclusively on new-chains folders.

**CL2QCD** behaviour consists in calculating correlators on the given configurations.
Running this mode e.g. on an unfinished beta folder will result in an attempt to complete the calculation.
Said differently, already existing correlators will not be evaluated agian.

**openQCD-FASTSUM** does not support this mode.

# OPTIONS

\--betasfile *filename*
:   Use *filename* instead of **betas** file.

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

# FILES

./betas
:   Only uncommented lines in the **betas** file are considered in this mode.

# SEE ALSO

**BaHaMAS**(1)

# BAHAMAS

Part of the **BaHaMAS** software.
