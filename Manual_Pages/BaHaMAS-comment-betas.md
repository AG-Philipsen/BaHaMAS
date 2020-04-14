% BaHaMAS-comment-betas(1) Version 1.0.0 | User Manual
% [Alessandro Sciarra](sciarra@itp.uni-frankfurt.de)
% 14 April 2020

# NAME

BaHaMAS-comment-betas - Comment lines in the **betas** file

# SYNOPSIS

**BaHaMAS comment-betas** [*option* ...]

# DESCRIPTION

It often happens to have to exclude few lines from the **betas** file to then let BaHaMAS act on the remianing ones.
This execution mode is meant to facilitate this operation.

The betas can be specified with the **\--betas** option either with a seed or without.
The format of the specified string can be one of the following:

* the format of the label of the **simulation-status** mode, e.g. `5.4380_s5491_NC`;
* simply a beta value like `5.4380`;
* a mix of both.

The suffix with the type of the chain is optional.
If pure beta values are given then all seeds of the given beta value will be commented out.

Runnig this mode without options will uncomment all lines in the **betas** file.

# OPTIONS

\--betas *space-separated_list*
:   The beta line(s) to be toggled in the **betas** file.

\--betasfile *filename*
:   Use *filename* instead of **betas** file.

# FILES

./betas
:   Only uncommented lines in the **betas** file are considered in this mode.

# SEE ALSO

**BaHaMAS**(1), **BaHaMAS-uncomment-betas**(1)

# BAHAMAS

Part of the **BaHaMAS** software.
