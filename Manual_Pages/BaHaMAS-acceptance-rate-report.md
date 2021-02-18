% BaHaMAS-acceptance-rate-report(1) Version 0.3.1 | User Manual
% [Alessandro Sciarra](sciarra@itp.uni-frankfurt.de)
% 11 September 2020

# NAME

BaHaMAS-acceptance-rate-report - Produce a table with acceptance rates in subsequent intervals

# SYNOPSIS

**BaHaMAS acceptance-rate-report** [*option* ...]

# DESCRIPTION

The **betas** file is parsed in order to gather information about on which folders it should be acted (only uncommented lines are considered in this mode).
This mode operates on the newest beta folders and in particular on the simulation output files.
This means that if no new chain folder exist, a thermalization from conf is considered and if this is also not existing, a thermalization from hot is used.

Looking for the Metropolis test acceptance output, BaHaMAS calculates and prints to the output a report in which the acceptance rates will be summarized.
The interval width can be adjusted using the **\--interval** option.
Only the acceptance for complete intervals is calculated.

# OPTIONS

\--interval *number*
:   Specify how many trajectories should be considered to calculate the acceptance rate.

\--onlyFromHot
:   Only thermalizations from hot will be included in the acceptance rate report.

\--onlyFromConf
:   Only thermalizations from conf will be included in the acceptance rate report.

\--onlyNewChains
:   Only new chains will be included in the acceptance rate report.

\--betasfile *filename*
:   Use *filename* instead of **betas** file.

# FILES

./betas
:   Only uncommented lines in the **betas** file are considered in this mode.

# SEE ALSO

**BaHaMAS**(1)

# BAHAMAS

Part of the **BaHaMAS** software.
