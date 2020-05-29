% BaHaMAS-submit-only(1) Version 0.2.0 | User Manual
% [Alessandro Sciarra](sciarra@itp.uni-frankfurt.de)
% 29 May 2020

# NAME

BaHaMAS-submit-only - Submit new-chain simulation(s) after needed consistency checks

# SYNOPSIS

**BaHaMAS submit-only** [*option* ...]

# DESCRIPTION

The **betas** file is parsed in order to gather information about the simulations that should be submitted (only uncommented lines are considered in this mode).
This mode operates exclusively on new-chain jobs.
After having checked that all needed files exist, jobs for the selected betas are submitted.

This mode is thought to be used after having run BaHaMAS in the **prepare-only** execution mode.

# OPTIONS

\--betasfile *filename*
:   Use *filename* instead of **betas** file.

\--jobscript_prefix *string*
:   Specify the prefix of the jobscript file (default: own setup).

# FILES

./betas
:   Only uncommented lines in the **betas** file are considered in this mode.

# SEE ALSO

**BaHaMAS**(1), **BaHaMAS-prepare-only**(1)

# BAHAMAS

Part of the **BaHaMAS** software.
