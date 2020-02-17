# Contributing to BaHaMAS

A lot of effort has been devoted to set up a uniform developing framework and it is important to comply with the codebase rules, which are described in the following.

## Git development pattern

You might have heard about git-flow.
It is a very simple and effective Git branching model, which dates back to 2010 and which has been even implemented as git extension (both by its autor and by other people).
Actually, it is by now quite popular and it gained a spot in the official Bitbucket git documentation.
If you are new to it, you can read [the original post](https://nvie.com/posts/a-successful-git-branching-model/) by the author and/or the [Bitbucket page](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) on it.

If you want to contribute to `BaHaMAS`, you should probably work on a feature branch and then submit a merge request.
We encourage you to use the [AVH Edition](https://github.com/petervanderdoes/gitflow-avh) of git-flow since it should include some ameliorated feature with respect [to the original implementation](https://github.com/nvie/gitflow) of the author, which seem [not to be maintained anymore](https://github.com/nvie/gitflow/issues/6452).

## Comply with the codebase style

The general advice is pretty trivial: **Be consistent with what you find**.
However, it is worth giving you here a bit more information, so that it should be easier to follow the general rule.

### Editing existing files or creating new ones

`BaHaMAS` is distributed under the terms of the GPLv3 license.
In general, you should follow the instructions therein.
Some guidelines for authors are provided in the following, in order to reach a coherent style of copyright and licensing notices.

* If you are contributing for the first time, be sure that your git username and email are [set up correctly](https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup).
  To check them you can run `git config --list` and see the values of the `user.name` and `user.email` fields.
* If you create a new file, add copyright and license remarks to a comment at the top of the file (after a possible shebang).
  A templates is provided below.
  Copyright remarks should not only use the **(C)** symbol, but also the term **Copyright**.
  Use the `.bash` extension (not `.sh`) for files containing *bash* code.
* When editing an existing file, ensure there is a copyright remark with your name.
  If there is none, add one directly below any existing copyright remarks.
  If there is already a copyright remark with your name, ensure it contains the current year.
  Otherwise add the current year.
  The years should form a comma-separated list.
  If more than two subsequent years are given, the list can be merged into a range.
* Please, do not write an email next to your name in the copyright statement.
  It is unnecessary and it can be easily retrieved e.g. via `git shortlog -sne`.

The following sample shows how the top level comment of a `.bash` source file should look like,

```bash
#
#  Copyright (c) 2019-2020 John Smith
#
[License notice]
#
```

where `[License notice]` is the following text.

```bash
#  This file is part of BaHaMAS.
#
#  BaHaMAS is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  BaHaMAS is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with BaHaMAS. If not, see <http://www.gnu.org/licenses/>.
```

### Use available hooks

In the past, `BaHaMAS` was distributed with some hooks, which might have been used to enforce the codebase policies.
This is not anymore the case, simply because those hooks have been extracted into a [standalone repository](https://github.com/AxelKrypton/GitHooks), which you are encouraged to clone and use.
In this way, you will have hooks in an independent place than where you use them and you can even share them across different repositories.
After having cloned somewhere the **GitHooks** repository, you can run its `hooksSetup.bash` script e.g. from within the `BaHaMAS` repository.
Use the `-h` option first and then run it again tuning the setup you wish.
For example, you can put the license notice above in a local file called `LicenseNotice.txt` and then run the following command from within the `BaHaMAS` repository.

```bash
/path/to/GitHooks/hooksSetup.bash -g . -c --activateCommitFormatCheck --activateLicenseNoticeCheck --noticeFile LicenseNotice.txt --extensionsLicense .bash .awk --activateCopyrightCheck --extensionsCopyright .bash .awk --activateSpacesFixAndCheck
```

To know which policy is then enforced, refer to the **GitHooks** [README](https://github.com/AxelKrypton/GitHooks/blob/master/README.md).

### Bonus track

Most of the editors have the possibility to help you in typing a commit message.

* `vim` does it in a natural way and even with default configuration provides a nice syntax highlighting for commit messages.
  Using colours, it notifies you if your commit summary is too long or if you are typing something on the second line that should be empty.
  To automatically wrap the commit description at 72 characters, you could add `set textwidth=72` to your `.vimrc` file in your home directory.
  To make git use `vim` as editor for all your repositories, use something like `git config --global core.editor vim`.

* If your favourite editor is `emacs`, the way is not so down-hill.
  But it is not so tough neither.
  From MELPA you can download the git-commit package, which will provide you with useful functionality.
  Then you can add few lines to your `~/.emacs`, which could look like below.
  ```emacs-lisp
  ;; Git specific operation to simplify environment when committing
  (setq column-number-mode t)              ; show column number in the mode line
  (global-git-commit-mode)                 ; activate git-commit mode
  (setq git-commit-summary-max-length 49)  ;  - changing style in first line after the 50th char
  (setq git-commit-fill-column 71 )        ;  - activate auto-fill-mode on space and return
  (aset auto-fill-chars ?. t)              ;    after the 72th char. It can be useful to have
  (aset auto-fill-chars ?? t)              ;    line folded also on any of the punctuation like
  (aset auto-fill-chars ?! t)              ;    .?! which could be inserted beyond char 72.
  ```
  If your `~/.emacs` file takes some time to be loaded and you would like to quickly fire up `emacs` to make a commit, then you could put the code above in some lighter standalone file - e.g. `~/.emacs_for_git` - and then tell git how to invoke properly the editor, e.g. via `git config --global core.editor "emacs -nw -Q -l ${HOME}/.emacs_for_git"`.
