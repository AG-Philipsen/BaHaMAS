% BaHaMAS-job-status(1) Version 0.3.1 | User Manual
% [Alessandro Sciarra](sciarra@itp.uni-frankfurt.de)
% 11 September 2020

# NAME

BaHaMAS-job-status - Give overview of submitted jobs getting information from scheduler

# SYNOPSIS

**BaHaMAS job-status** [*option* ...]

# DESCRIPTION

Although each scheduler offers plenty of functionality to check enqueued jobs, this BaHaMAS execution mode is an add-on to gather together the main information the user might be interested in, producing a nice report to the standard output.

Jobs with different status are displayed with different colors.

* **Red** is used if the submitted job is pending without that its starting time is known.
* **Yellow** is used if the submitted job is pending and its starting time is known.
* **Green** is used if the submitted job is running.
* **Magenta** is used for other status, e.g. when a job is in the completing phase.

The report terminates with a numerical summary.

# OPTIONS

\--user, \-u
:   Only the jobs enqueued by the specified user are considered in the report (default: user that runs the command).

\--local, \-l
:   Only jobs submitted from the present directory are considered in the report.

\--all, \-a
:   All enqueued jobs are considered in the report.

\--partition *string*
:   Limit the report to the specified partition (default: own setup).

# SEE ALSO

**BaHaMAS**(1)

# BAHAMAS

Part of the **BaHaMAS** software.
