% BaHaMAS(1) Version 0.4.0 | General User Manual
% Alessandro Sciarra
% 22 February 2021

# NAME

BaHaMAS - Bash Handler to Monitor and Administrate Simulations

# SYNOPSIS

**BaHaMAS** [--help] [--version] [--setup]
         *execution-mode* [*option* ...]

# DESCRIPTION

`BaHaMAS` is a tool to efficiently run LQCD simulations on supercomputers.
During years, it has grown and improved, so that it has by now plenty of functionality to submit, monitor, continue and resume jobs.

It should be intuitive to use it, especially if you are a bit familiar with the git version control system.
Several execution modes are available and you can obtain usage information for each of them using their **\--help** option.

A more detailed general overview is available [online](https://gitlab.itp.uni-frankfurt.de/lattice-qcd/ag-philipsen/BaHaMAS/-/wikis/home).

# OPTIONS

\--help
:   Display a minimal summary of this manual in the terminal.

\--version
:   Print a version message in the terminal.

\--setup
:   Configure the program.
    You will be asked to fill out a form through a self-explainatory, rudimental, but functional GUI.
    This option can also be used to update and/or complete previous configurations.

# EXECUTION MODES

Execution modes can be classified in three categories.

---

1. There are execution modes meant to prepare needed files and folders and/or submit new simulation(s).
   These all begins parsing the **betas** file and they then act only on uncommented lines in it.

continue
:   Unfinished new-chains jobs (if it is possible to deduce it) will be continued.
    The input file of each simulation is adjusted according to the option passed.
    The number of trajectories which will be done is determined as follows.

     * If the **\--measurements** option is given, then it will be used.
     * Otherwise, if the **\--till***=number* option is given, then it will be used.
     * Otherwise, if the **g***number* field is present in the **betas** file, then it will be used.
     * Otherwise, the measurement option in the input file is not modified.

    To resume a simulation from a given trajectory, add a **r***number* field in the **betas** file.
    Use **rlast** in the **betas** file to resume a simulation from the last saved checkpoint.

continue-thermalization
:   As **continue**, but for thermalization runs.

measure
:   Prepare what is needed and submit measurement simulation(s).

prepare-only
:   Files and folders for the chains obtained from the **betas** file are prepared.
    Needed jobscripts are created but none of them is submitted.

submit-only
:   After having checked that all needed files and jobscripts are available, new-chain simulation(s) are submitted.

new-chain
:   This mode is doing at the same time what can be done separately by **prepare-only** and **submit-only** modes.

thermalize
:   As submit, but for thermalization runs.

---

2. Another class of execution modes are meant to monitor queued jobs or to get report about existing simulation(s).
   Most of them do not parse the **betas** file or have an option to consider all runs in a given folder.

acceptance-rate-report
:   Produce a table with acceptance rates in subsequent intervals of trajectories for the simulation(s) obtained from the **betas** file.

clean-output-files
:   Check and if needed clean the measurement file for the simulation(s) obtained from the **betas** file.

database
:   Access to database functionality.
    This allows to update, plan an update or display with possible filtering the own database.
    A report out of it can also be produced.
    It is a very valuable feature, in particular to have a project overview.

job-status
:   Produce an overview of all submitted jobs getting information from scheduler.

simulation-status
:   Produce a detailed report of all simulation(s) in a given folder.
    Colours are used here to highlight problematic runs.
    If something is red, some investigation is required.

---

3. To the last class of execution modes belong those to perform automatized operations on the **betas** file.

complete-betas-file
:   Complete the betas file adding new chains to it.

comment-betas
:   Comment lines in the betas file.

uncomment-betas
:   Uomment lines in the betas file.

# FILES

./betas
:   Running `BaHaMAS` in most modes relies on a local configuration file, which name must be `betas`.
    Refer to [its dedicated section](https://gitlab.itp.uni-frankfurt.de/lattice-qcd/ag-philipsen/BaHaMAS/-/wikis/Getting-started#betasFile) in the Wiki for more information.

# ENVIRONMENT

No environment variable affects `BaHaMAS` behaviour at the moment.

# DIAGNOSTICS

Error messages can cause immediate termination or not.
They result in a message to the standard output prefixed by `ERROR:` or by `FATAL:`, respectively.
If an error occur, an explanation follows in a way such that the user can react properly.

Although it should not happen, throughout the code there are **Internal** error messages which are prefixed by the `INTERNAL:` string when printed to the terminal.
In case you get one of them executing `BaHaMAS`, it is very important that you report a bug to the authors.

# REPORTING BUGS

The best way to report a bug is to open an issue on GitLab.
Maintainers will be automatically notified.

Be as specific as possible in order to reproduce the issue and, in case you got an **Internal** error, be so kind to include the error message.

# AUTHOR

`BaHaMAS` was started by [Alessandro Sciarra](sciarra@itp.uni-frankfurt.de) in 2014.
You can have a look to the Contributors page in the Repository on GitLab to have more information.
If you cloned the repository on your machine, you can also use git commands like `git shortlog -sne` to get an overview.

# SEE ALSO

The [online Wiki](https://gitlab.itp.uni-frankfurt.de/lattice-qcd/ag-philipsen/BaHaMAS/-/wikis/home) contains the full documentation.
