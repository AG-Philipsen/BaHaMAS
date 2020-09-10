% BaHaMAS-simulation-status(1) Version 0.3.0 | User Manual
% [Alessandro Sciarra](sciarra@itp.uni-frankfurt.de)
% 10 September 2020

# NAME

BaHaMAS-simulation-status - Produce report of folder simulation(s)

# SYNOPSIS

**BaHaMAS simulation-status** [*option* ...]

# DESCRIPTION

All existing beta folders are considered and a report containing lots of information about the simulation is printed to the standard output.

If coloured output is activated in the BaHaMAS setup, coloured entries will signal potential problems.
A detailed explanation of the color code used can be found in the Wiki, but in general reddish entries signals something to be checked.

The beta label in the report can be copied and used to edit the betas file using the **comment-betas** and **uncomment-betas** execution modes.

The functionality provided here is internally used by the **database** mode, but the latter offers much more flexibility, although not all information of the simulation status is at the moment there integrated.

# OPTIONS

\--doNotMeasureTime
:   Switch off trajectory times measurement.
    No information about production time per trajectory will be displayed.

\--showOnlyQueued
:   Limit the simulation status report to simulations for which a job is enqueued.
    This option can be useful when many simulations are run in the same folder.

\--verbose
:   Explicitly print errors instead of ignoring folders or simply do not extract information.

# SEE ALSO

**BaHaMAS**(1), **BaHaMAS-database**(1), **BaHaMAS-comment-betas**(1), **BaHaMAS-uncomment-betas**(1), [Wiki pages](https://gitlab.itp.uni-frankfurt.de/lattice-qcd/ag-philipsen/BaHaMAS/-/wikis/home)

# BAHAMAS

Part of the **BaHaMAS** software.
