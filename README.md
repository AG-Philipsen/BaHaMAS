<img src="https://gitlab.itp.uni-frankfurt.de/lattice-qcd/ag-philipsen/BaHaMAS/-/wikis/images/LogoDigital.png" align="right" width="30%" height="30%"/>

# BaHaMAS

`BaHaMAS` stands for ***Ba**sh **Ha**ndler to **M**onitor and **A**dministrate **S**imulations* and it is a tool to efficiently run LQCD simulations on supercomputers. During years, it has grown and improved, so that it has by now plenty of functionality to submit, monitor, continue and resume jobs.

### Origin of the code

`BaHaMAS` has been initially developed to run LQCD simulations with the [CL<sup>2</sup>QCD] software on clusters provided with the [slurm] job scheduler.
Although this could sound quite limitating, a remarkable effort has been done to give modularity to the codebase and, by now, scheduler and LQCD-software dependent code has been isolated.
Therefore, the structure of the code allows for easy generalisations and it should not be difficult to provide an implementation for a different job scheduler and/or for a different software.

### Supported LQCD software and job scheduler

Any (software, scheduler) combination among the supported ones is allowed.

|     **LQCD software**      |   **Scheduler**   |
|     :---------------:      |   :-----------:   |
| [CL<sup>2</sup>QCD]        | [slurm]           |
| [openQCD-FASTSUM]          |                   |

## Main Features

 - **Thermalise** configurations for a given set of parameters
 - **Submit** jobs for configurations production (with one or several replica)
 - **Continue** a simulation from the last checkpoint
 - **Resume** a simulation from a previous checkpoint
 - Get an **overview** of the queued jobs
 - Get a **report** on the status of the simulations for a given set of parameters
 - Use the **database** for complete control on your project
 - Keep easily under control the **acceptance rate** of each run
 - **Clean** the output files for a successive analysis
 - Calculate **correlators** on produced configurations
 - *...and many others!*

## Quick Start

Being written in bash, `BaHaMAS` does not need to be compiled or installed.
Once cloned the repository, it can be run straight away.
Nevertheless, to be able to properly work, it needs to be configured with some information, running an intuitive and interactive setup.
Its usage on the command line is `git`-inspired and you can explore the funcitonality yourself running `BaHaMAS` without arguments and then following the compact _getting started_ you will obtain.
Each `BaHaMAS` execution mode has a dedicated manual that you can read directly in the terminal.
To have a more complete and descriptive overview, you can refer to the [Wiki], where also a more abstract description of how `BaHaMAS` works is offered.

## Authors

`BaHaMAS` was born in 2014 and it has been developed in [a very small team][authors].
Use [git] functionalities like, for example, `git shortlog -sne` if you are interested in getting an overview of contributions by different authors.
Feel free to contact us if you have suggestions, feedbacks, bug reports or anything else about the software.


License
----

The logo of `BaHaMAS` has been created and drawn by **Aurora Somaglia** and then digitalized by **Carine Thalman**.
Other hand drawn pictures have been realized by Aurora Somaglia as well, while the remaining digital ones in the Wiki have been done by **Alessandro Sciarra**.

|     **Code**      |   **Logo and Images**   |
|     :------:      |   :-----------------:   |
| [GPLv3](/LICENSE) | All rights are reserved |

[//]: # (These are reference links used in the body of this note and get stripped out when the markdown processor does its job. There is no need to format nicely because it shouldn't be seen. Thanks SO - http://stackoverflow.com/questions/4823468/store-comments-in-markdown-syntax)


   [slurm]: <https://slurm.schedmd.com/>
   [CL<sup>2</sup>QCD]: <https://github.com/AG-Philipsen/cl2qcd>
   [openQCD-FASTSUM]: <https://gitlab.com/fastsum/openqcd-fastsum>
   [Wiki]: <https://gitlab.itp.uni-frankfurt.de/lattice-qcd/ag-philipsen/BaHaMAS/-/wikis/home>
   [git]: <https://git-scm.com>
   [logo]: <https://gitlab.itp.uni-frankfurt.de/lattice-qcd/ag-philipsen/BaHaMAS/-/blob/images/Logo.png>
   [authors]: <https://gitlab.itp.uni-frankfurt.de/lattice-qcd/ag-philipsen/BaHaMAS/-/wikis/Authors>
