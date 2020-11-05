# Changelog

All notable changes to this project will be documented in this file, starting from d38d08fc48e45a779a19b083d27fa2482e0e891a, namely the first commit in 2020.
They are listed in a reversal chronological order.

Although this project does not strictly adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html), it follows some aspects inspired from it.
Generally, given a version number **X.Y.Z**,

* **Z** is incremented for minor but user-relevant changes (e.g. bug fixes),
* **Y** is incremented for substantial refactoring and/or the introduction of minor new functionality and
* **X** for the introduction of substantial new features.

The prefix of each tag will be `BaHaMAS-` and, although most of the time it will be the case, it is not automatic that a Release (in the GitLab sense) will be created for each repository tag.
This is however always true for major releases (i.e. when **X** is increased).

## Meaning of the symbols in this file

* :new:              &nbsp; New feature
* :white_check_mark: &nbsp; Enhancement
* :recycle:          &nbsp; Substantial refactoring
* :boom:             &nbsp; Substantial change
* :sos:              &nbsp; Bug fix
* :no_entry_sign:    &nbsp; Deprecated
* :x:                &nbsp; Removed feature

#### Note about breaking changes

Staying backward compatibile should be a pillar of any healthy programming environment in the sense that everybody should strive to minimize breaking changes.
However, it is impossible to avoid those, especially in an earlier phase of development, when many decisions are impossible to be taken in a fully aware way.

---

## [Unreleased]

* :boom: Some setup variable names have been improved. This require running the `setup` mode once again to update the user-setup.
* :white_check_mark: Improve functional tests to cover more real-life cases.

## [Version 0.3.1] &ensp;<sub><sup>11 September 2020</sup></sub>

* :sos: **Hot-fix:** Many execution modes (e.g. `thermalize`) were broken with multiple simulations per job. This has been fixed now.

## [Version 0.3.0] &ensp;<sub><sup>10 September 2020</sup></sub>

* :white_check_mark: Implement system requirements overview in general in-terminal help.
* :new: Add `--fromHot` option to `thermalize` and `continue-thermalization` execution modes to explicitly act on thermalization(s) from hot.
* :boom: Gauge observables of openQCD-FASTSUM have been divided by the number of colours, i.e. by 3, in the standardized output file.
* :sos: The `simulation-status` execution mode now correctly handles freshly submitted simulations.
* :sos: Fix bug in `complete-betas-file` execution mode.
* :white_check_mark: Improve quoting expansions in `continue` mode which was hitting a [`bash-5.0` bug](https://unix.stackexchange.com/a/596526/370049).
* :sos: Fix minor bug in sourcing order to let `help`, `version` and `setup` mode work also when no scheduler is available.
* :sos: Fix typo in job script for production for CL2QCD which was causing immediate simulation crash.
* :white_check_mark: Improve run-time checkpoints renaming mechanism of openQCD-FASTSUM in `continue` mode.
* :sos: Fix bug in adding information to metadata file (only the last run ID was considered).
* :white_check_mark: Require minimum version (`1.8.5`) for `git` and adjust `--version` mode accordingly.
* :sos: Fix bug in checking prefixes in invocation path and make path handling stricter to avoid ambiguities.
* :white_check_mark: Add pending time information (up to present) to `job-status` mode for pending jobs.
* :sos: Fix a bug in `simulation-status` mode which was not correctly determining the status of jobs.
* :sos: Require `bash 4.4` as minimum version since BaHaMAS uses the `-d` option of `readarray`.
* :white_check_mark: Add command line option to change number of cores per node to be used.
* :sos: Fix minor bug in command line autocompletion of software specific options.
* :sos: Fix bug in `job-status` mode due to node information interpreted as glob pattern.

## [Version 0.2.0] &ensp;<sub><sup>29 May 2020</sup></sub>

* :new: All execution modes except from `measure` one are now supported for openQCD-FASTSUM software. The measure mode will not be implemented in the next future.
* :new: Autocompletion for command line execution modes and options has been added together with an automatic setup for the user.
* :new: `simulation-status` mode has been implemented for openQCD-FASTSUM software.
* :new: `continue` mode has been implemented for openQCD-FASTSUM software.
* :boom: The `g` field in the betas file has now always the meaning of **goal statistics**, i.e. how many trajectories *in the given run* should be produced.
* :boom: Name convention for thermalised configurations was changed to include in their names the trajectory number they refer to.
* :new: Execution modes to start production jobs have been implemented for openQCD-FASTSUM software.
* :new: Compilation of openQCD-FASTSUM codebase for production added together with some setup variables.
* :new: Add a hidden metadata file mechanism to check LQCD software consistency.
* :white_check_mark: The setup suggests and optionally helps the user to improve the environment for a better BaHaMAS usage.
* :new: Manual pages have been added and connected to the `--help` option which acts now differently for each mode.
* :recycle: LQCD software specific code and scheduler specific code has been moved to own directory and an interface to the generic code has been added.
* :boom: BaHaMAS execution modes have been added and mutually exclusive options removed.

## [Version 0.1.0] &ensp;<sub><sup>17 February 2020</sup></sub>

* :sos: BaHaMAS requested the setup to be done before the help could be displayed. This condition was relaxed.
* :x: The **Hooks** folder has been removed from the repository since the [GitHooks](https://github.com/AxelKrypton/GitHooks) shall be used.
* :new: Add **CONTRIBUTING.md** and **CHANGELOG.md** files to repository.
* :sos: Fix tests failures due to hard-coded path in tests setup.


[Unreleased]: https://github.com/AG-Philipsen/BaHaMAS/compare/BaHaMAS-0.3.1...develop
[Version 0.3.1]: https://github.com/AG-Philipsen/BaHaMAS/releases/tag/BaHaMAS-0.3.1
[Version 0.3.0]: https://github.com/AG-Philipsen/BaHaMAS/releases/tag/BaHaMAS-0.3.0
[Version 0.2.0]: https://github.com/AG-Philipsen/BaHaMAS/releases/tag/BaHaMAS-0.2.0
[Version 0.1.0]: https://github.com/AG-Philipsen/BaHaMAS/releases/tag/BaHaMAS-0.1.0
