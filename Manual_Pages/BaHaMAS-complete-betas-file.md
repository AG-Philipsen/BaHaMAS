% BaHaMAS-complete-betas-file(1) Version 1.0.0 | User Manual
% [Alessandro Sciarra](sciarra@itp.uni-frankfurt.de)
% 14 April 2020

# NAME

BaHaMAS-complete-betas-file -

# SYNOPSIS

**BaHaMAS complete-betas-file** [*option* ...]

# DESCRIPTION

Adding new lines to the **betas** file can be quite tedious, especially if different chains differ e.g. only in the seed value.
This BaHaMAS execution mode will complete the betas file adding for each beta new chains till having as many chains as specified using the **\--chains** option.
New seeds are randomly drawn.

# OPTIONS

\--chains *number*
:   The number of chains that must exist per beta value in the **betas** file (default: 4).

\--betasfile *filename*
:   Use *filename* instead of **betas** file.

# FILES

./betas
:   Only uncommented lines in the **betas** file are considered in this mode.

# SEE ALSO

**BaHaMAS**(1), **BaHaMAS-comment-betas**(1) , **BaHaMAS-uncomment-betas**(1)

# BAHAMAS

Part of the **BaHaMAS** software.
