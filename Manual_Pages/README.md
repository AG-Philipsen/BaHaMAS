# Manual pages

This folder contains the manual pages of the BaHaMAS codebase.
As user, the only relevant files for you are those beginning with **BaHaMAS** and with the **.md** extension.
For a better reading experience, open them in the browser.
In the terminal, instead, you should rather use the manuals pages contained in the `man1` folder, e.g. opening them via `man -l path/to/man1/manpage`.

## Information for developer

As developer of BaHaMAS, it is your responsibility to keep documentation up-to-date.
Some work has been done to unburden the overhead of dealing woth documentation by hand.
Please, take some time to read and understand the following remarks.

* Manual pages are written as markdown pages, so that the user can read them in the browser.
  Especially, they can be referred from the Wiki, making its maintenance easier as well.
  **Hence, you should only edit markdown files by hand.**

* Since BaHaMAS execution modes shares some command line options, we do not want that different manual pages contain different documentation of the same command line option!
  Therefore, **you should never edit by hand the `# *OPTIONS` section(s) in the manuals of the execution modes.**

* If you need to add/edit/remove an option, do it in the `OptionsPool.md`.
  This file is used as input to automatically populate the manual pages.
  It is important to keep empty lines to separate options, as well as after the last option in the file.
  It might happen, that the same option in BaHaMAS is allowed by different execution modes with *different meaning* and then with different description.
  To allow the population mechanism to select the correct option, please be sure to add a `@execution-mode@` string at the end of the option line.
  Here an example of the correct syntax.
  ```
  \--all @mode:job-status@
  ```
  Clearly, in this case, the option refer to one mode only and it has to be repeated for other modes.

* In this folder you will find a **Makefile**, which implements automatic creation of the manual pages.
  Simply give `make` to update/create all manuals.
  Note that it is a natural capability of makefiles to work on only those files whose source changed.
  Internally, the **Makefile** calls at first the **PopulateOptions.bash** script (except than for the main manual) and then `pandoc` to convert the markdown files into manuals.
  If you do not have **pandoc** installed, you need to [get it](https://pandoc.org/installing.html).
  Be sure the `pandoc` command is available in the shell, e.g. it is in a one of the `PATH` folders.

* While a multiple occurrence of an option in the pool of options triggers a failure of the `make` command, a missing option will only give an error message.
  It is developer's responsibility to take action in both cases, though.

* You can call the **PopulateOptions.bash** script by hand, given that you provide as only command line argument the markdown file which should be edited.
  Call it as e.g. `VERBOSE=1 ./PopulateOptions.bash <BaHaMAS-...].md>` in order to obtain more information at execution time.

* At the top of each manual page there are few metadata.
  **Be sure they stay up-to-date.**
  In particular, when making a new release, the version number and the date should be updated.
