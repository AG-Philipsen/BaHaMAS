% BaHaMAS-clean-output-files(1) Version 0.2.0 | User Manual
% [Alessandro Sciarra](sciarra@itp.uni-frankfurt.de)
% 29 May 2020

# NAME

BaHaMAS-clean-output-files - Check and if needed clean the measurement file(s)

# SYNOPSIS

**BaHaMAS clean-output-files** [*option* ...]

# DESCRIPTION

Unless the **\--all** option is given, the **betas** file is parsed in order to gather information about on which folders it should be acted (only uncommented lines are considered in this mode).
This mode operates exclusively on new-chains folders and in particular on the simulation output files.

It can happen that a trajectory is continued and a bunch of trajectories are then repeated.
This implies that these repeated trajectories appear more than once in the output file(s) and this might lead to wrong analysis.
In this execution mode, BaHaMAS will go throught the output files and clean them, keeping only the first occurence of each trajectory.
For safety reason, a backup of the output file is done and it is left in the output file folder with a suffix constructed from the cleaning date.

# OPTIONS

\--all, \-a
:   All existing new-chain folders are considered and the **betas** file is not parsed.

\--betasfile *filename*
:   Use *filename* instead of **betas** file.

# FILES

./betas
:   Only uncommented lines in the **betas** file are considered in this mode.

# SEE ALSO

**BaHaMAS**(1), **BaHaMAS-simulation-status**(1)

# BAHAMAS

Part of the **BaHaMAS** software.
