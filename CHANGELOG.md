# Changelog

All notable changes to this project will be documented in this file, starting from d38d08fc48e45a779a19b083d27fa2482e0e891a, namely the first commit in 2020.
They are listed in a reversal chronological order.

Although this project does not strictly adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html), it follows some aspects inspired from it.
Generally, given a version number **X.Y.Z**,

* **Z** is incremented for minor but user-relevant changes (e.g. bug fixes),
* **Y** is incremented for substantial refactoring and/or the introduction of minor new functionality and
* **X** for the introduction of substantial new features.

The prefix of each tag will be **bahamas-** and, although most of the time it will be the case, it is not automatic that a Release (in the GitLab sense) will be created for each repository tag.
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

## Unreleased

* :x: The **Hooks** folder has been removed from the repository since the [GitHooks](https://github.com/AxelKrypton/GitHooks) shall be used.
* :new: Add **CONTRIBUTING.md** and **CHANGELOG.md** files to repository.

<!-- ## Version 0.1.0 &ensp;<sub><sup>XX month YYYY</sup></sub> -->
