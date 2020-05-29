% BaHaMAS-acceptance-rate-report(1) Version 0.2.0 | User Manual
% [Alessandro Sciarra](sciarra@itp.uni-frankfurt.de)
% 29 May 2020

# NAME

BaHaMAS-acceptance-rate-report - Produce a table with acceptance rates in subsequent intervals

# SYNOPSIS

**BaHaMAS acceptance-rate-report** [*option* ...]

# DESCRIPTION

The **betas** file is parsed in order to gather information about on which folders it should be acted (only uncommented lines are considered in this mode).
This mode operates exclusively on new-chains folders and in particular on the simulation output files.

Looking for the Metropolis test acceptance output, BaHaMAS calculates and prints to the output a report in which the acceptance rates will be summarized.
The interval width can be adjusted using the **\--interval** option.
Only the acceptance for complete intervals is calculated.

# OPTIONS

\--interval *number*
:   Specify how many trajectories should be considered to calculate the acceptance rate.

\--betasfile *filename*
:   Use *filename* instead of **betas** file.

# FILES

./betas
:   Only uncommented lines in the **betas** file are considered in this mode.

# SEE ALSO

**BaHaMAS**(1)

# BAHAMAS

Part of the **BaHaMAS** software.
