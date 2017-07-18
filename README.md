<img src="https://github.com/AG-Philipsen/BaHaMAS/blob/images/Logo.png?raw=true" align="right" width="30%" height="30%"/>

# BaHaMAS

`BaHaMAS` stands for ***Ba**sh **Ha**ndler to **M**onitor and **A**dministrate **S**imulations* and it is a tool to efficiently run LQCD simulations on supercomputers. During years, it has grown and improved, so that it has by now plenty of functionality to submit, monitor, continue and resume jobs.

### Origin of the code as disclaimer

`BaHaMAS` has been developed to run LQCD simulations with the [CL<sup>2</sup>QCD] software on clusters provided with the [slurm] job scheduler. Therefore, if you are using a different scheduler or a different software, the implementation of some functionality could be potentially missing.
However, reading the documentation, it should be clear that the structure of the code allows for easy generalisations<sup>1</sup> and it should not be difficult to provide an implementation for a different job scheduler and/or for a different software.

<sup>1</sup> <sub>_This statement could be at the moment not true. `BaHaMAS` is in an intense development phase and a lot of work is being done to provide a more solid structure, which will allow easier extensions in future. For example, some features are [CL<sup>2</sup>QCD] specific and they are still hard coded._</sub>

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

Being written in bash, `BaHaMAS` does not need to be compiled or installed. Once cloned the repository, it can be run straight away. Nevertheless, to be able to properly work, it needs to be configured with some information. Run it with the `-h` option to get a compact _getting started_ (or refer to the documentation to have a complete overview).

## Coming soon

  - [ ] Online documentation for user and developer
  - [ ] Refactoring of the code to more easily include new software and/or new job schedulers
  - [ ] Progress percentage and remaining time per simulation in `--liststatus` option


## Authors

`BaHaMAS` was born in 2014 and it has been developed in a very small team. Use [git] functionalities like, for example, `git shortlog -sne` if you are interested in getting an overview of contributions by different authors. Feel free to contact us if you have suggestions, feedbacks, bug reports or anything else about the software.


License
----
| Code | Logo and Images |
| :--: | :--: |
|[MIT](https://github.com/AxelKrypton/BaHaMAS/blob/master/LICENSE.md)| All rights are reserved|

[//]: # (These are reference links used in the body of this note and get stripped out when the markdown processor does its job. There is no need to format nicely because it shouldn't be seen. Thanks SO - http://stackoverflow.com/questions/4823468/store-comments-in-markdown-syntax)


   [slurm]: <https://slurm.schedmd.com/>
   [CL<sup>2</sup>QCD]: <https://github.com/AG-Philipsen/cl2qcd>
   [git]: <https://git-scm.com>
   [logo]: <https://github.com/AG-Philipsen/BaHaMAS/blob/master/Logo.png>
