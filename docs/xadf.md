---
title: Xeno Authority Dot Files
subtitle: xadf Technical Documentation and Manual
author: Hendrik Lie

## Fonts and formatting.
fontfamily: times
fontsize: 12pt
linestretch: 1.25
indent: true
papersize: a4

## Layout?
numbersections: true
secnumdepth: 1

## part, chapter, section, or default:
top-level-division: chapter
toc-depth: 2
hyperrefoptions: linktoc=all
reference-section-title: Bibliography
documentclass: book

## Language
lang: en-US
---

`xadf` (an acronym for *Xeno Authority Dot Files*) is a wrapper script for creating, authoring, and managing dotfiles as a bare git repository with [bare git and alias method](https://news.ycombinator.com/item?id=11071754). All you have to do is to [obtain the executable and place them in an appropriate path](#obtaining-xadf-executable), then you can perform [minimal installation](#minimal-installation) and set up a bare git repository with a git directory somewhere at `$HOME`. Instead of setting up a new bare git repository, it is actually possible to configure `xadf` to manage your own custom bare git directory with [custom installation](#custom-installation).

Have fun :)

> **Disclaimer:** While the idea (and name) of `xadf` dates back to [my original](#migrating-from-xadf-v0), butchered ways of backing up dotfiles, I was inspired to create the current implementation after reading through [Alfunx's implementation on additional commands](https://github.com/alfunx/.dotfiles#additional-commands).

> **Note for forkers:** It is not recommended to use my setup right away. You should at least inspect the scripts and configuration files of my setup. Maybe you'd be more interested in the main `xadf` script, how it manages dotfiles at home directory, what to change if you're forking this repository (or `xadf` specifically) or its installation steps.

> In that case you may wish to jump to [Code Design of xadf](#code-design-of-xadf) for an overview of `xadf` code structure, [Installation](#installation-of-xadf) on how to install `xadf` and use it to manage your dotfiles with git, or even reading through `xadf`'s [technical specifications](#implementing-bare-git-with-alias-method-as-a-helper-script).

[TOC]

# Introduction

I've been looking for a way to conveniently manage my dotfiles with git version control. The question remains on how to properly do it? The options are either using [stow](https://brandon.invergo.net/news/2012-05-26-using-gnu-stow-to-manage-your-dotfiles.html), or bare git and alias method (see [archlinux wiki page on dotfiles](https://wiki.archlinux.org/title/Dotfiles)).

After testing the `stow` method, I concluded that it provides only marginal improvements at the expense of symlinking in home directory and complicated setup (manually copy config files and recreate the directory tree for each stow packages). The bare git and alias method seems simpler, directly work at home directory instead of a separate folder, avoids symlinking, and we can selectively decide which file to track. [The set up](https://gitlab.com/Siilwyn/my-dotfiles/tree/master/.my-dotfiles) seems to be simpler too.

However the problem remains on how to include [`LICENSE`](./LICENSE) and `README.md` at the root of repository but not in our actual home folder. It is trivial with `stow` method, where we just place them in the root of the repository, while each folder represents stow packages. With git, we have to use smart branch hacks to hide `LICENSE` and `README.md` from our actual home directory.

The following sections will describe basic idea of how to set up bare git and alias method, how to deal with `LICENSE` and `README.md`, and my actual implementation of bare git and alias method.

# Manage Dotfiles with Bare Git and Alias Method - Basic Idea

Basically, to manage dotfiles with git bare methods, we have to set up a bare repository, and use a different work-tree. Then to replicate it, we clone with `--separate-git-dir` argument to a temporary directory. Then we rsync (except for `.git` folder) to home directory, and later remove the temporary directory.

## Setup

The basic idea is to initialize a bare git repository over an existing (or fresh) home directory, then set up an alias (ideally add them to `.bashrc` or `.bash_aliases`), and add a remote for us to push to.

```bash
git init --bare $HOME/xadf
alias xadf='git --git-dir=$HOME/xadf/ --work-tree=$HOME'
xadf remote add origin git@gitlab.com:heno72/xadf.git
```

## Replication

If the repository is already been set up, we can just clone the repo with separate git directory. Initially, we will need to clone the work tree to a temporary directory, and then sync the content of the temporary directory to our home directory. Later we can just delete the temporary directory.

```bash
git clone --separate-git-dir=$HOME/xadf https://gitlab.com/heno72/xadf.git .xadf-tmp
rsync --recursive --verbose --exclude '.git' .xadf-tmp/ $HOME/
rm --recursive .xadf-tmp
```

## Configuration

Since there would be a ton of files in a real home directory, having them shown all the time will be a nuisance and a straightforward distraction. Here we configure git to not show untracked files.

Additionally, since we are cloning from git https clone url, we may need to change to git ssh clone url. Otherwise we will have to type our credentials on every push operation. Make sure to set up ssh keys on the machine and add it to your git account beforehand.

```bash
xadf config status.showUntrackedFiles no
xadf remote set-url origin git@gitlab.com:heno72/xadf-gb.git
```

> Note that since untracked files are not shown, when you made changes to file you actually track, it is tempting to just use `xadf add .` especially when you have a bunch of them. **_DON'T!_** Just don't, as it means you'd include all files in `$HOME`, which is certainly undesirable. You should specify each files you want to add.

## Usage

After setting up, we can just use the alias to substitute `git` command in our home directory. We can use it like any normal git command. Therefore eliminating collision with real git repository under home. Also typical `git` commands would not work at our home root since it does not contain `~/.git` directory.

```bash
xadf status
xadf add .gitconfig
xadf commit -m 'Add gitconfig'
xadf push
```

## Dealing with repository meta files

A `README.md` is very helpful to document the usage of our repository, and a `LICENSE` will also clarify the terms of use of our repository. An additional `docs/` folder might be necessary to document a more elaborate use case of our setup. However we may not want to have those files and directories in our real home folder. [This answer](https://stackoverflow.com/a/62614921/12571203) actually provide a gist of how to do it, but I accidentally reinvent that in a spur of inspiration:

1. First initiate a git repo for xadf and make initial commits without readme and/or license.
2. Then we make a branch, say, branch `trunk`.
3. Then in branch `master`, adds readme and license.
4. Afterwards, changes to config files are done or branched from branch `trunk` only. Then branch `trunk` may be merged to `master` often. But never the other way around (from production, merge master).

As long as we work with the `trunk` branch and never merge `master` there, we will be okay. Additionally, more branches can be added from branch `trunk` (and not `master`). Further changes of `trunk` can be merged to any subsequent branches. Likewise, if so desired, any other branches but `master` can be merged to `trunk`.

## Strategy to deal with multiple branches

Though, honestly I would advise to make shared configs on `trunk` and later merge them to other branches and branch `master`.

Therefore, we can visualize the branching and merging direction like this:

```mermaid
flowchart TB
subgraph "Branch tree"
    A[Master] --> B[Trunk]
    B --> C[Termux]
    B --> D[Laptop]
end
subgraph "Merge direction"
    E[Trunk] --> F[Master]
    F -->|Undesirable| E
    E <--> G[Termux]
    E <--> H[Laptop]
end
```

> only merge `trunk` to `master`, `termux`, or `laptop`, or from `termux` or `laptop` to `trunk`, but never merge `master` to `trunk`.

A more complicated tree is actually possible:

```mermaid
graph TD;
  Trunk-->Master;
  Trunk-->Termux;
  Trunk<-->Home;
  Termux<-->SamsungA30;
  Termux<-->GalaxyNote;
  Trunk-->Work;
  Work<-->Laptop;
  Work<-->Desktop;
```

Example git history looks like the following:

```mermaid
gitGraph
    commit
    commit
    branch trunk
    commit
    branch termux
    commit
    checkout main
    commit
    checkout trunk
    commit
    checkout termux
    merge trunk
    commit
    checkout main
    merge trunk
    checkout trunk
    commit
    commit
    checkout main
    merge trunk
    checkout termux
    merge trunk
```

> Notice that all branches (including main) merge trunk to them, but not the other way around. That way you can place common configurations in branch `trunk`, and you merge them to machine-specific or setup-specific branches frequently.

# Implementing Bare Git with Alias method as a helper script

Instead of just using alias, and do all of the steps described in previous section manually, I want to have them be done automatically with a script. The goal is to have a single script that will handle installation (cloning repo with separate git directory, checking out to correct branch, syncing repo contents to home directory, set up helper configuration files so we can use the tool on the next login or new terminal sessions), and can function as an alias to git with separate git directory (essentially an alias for `git --git-dir=$xadfdir --work-tree=$HOME`, where `$xadfdir` is declared in the aforementioned helper configuration file) for day to day use.

Since I already have a working `.bashrc` configurations in most of my machines and setups (especially my android's termux), I want the mechanism to be minimally invasive to `.bashrc`. We could later decide to track `.bashrc` in separate machine-specific branches, or the produced configuration files in `~/.config/xadf` (`$xadfconfig`) if necessary. We should also distinguish `.local` and `.config` use. I want `.local` to be used to store custom functions and templates, while `.config` folder to specifically store `xadf` related configurations, or configuration files of custom functions or custom scripts shipped with `xadf` in `~/.local/{bin,xadf}`

The following subsections will outline the basic directory structures, specification of configuration files and config constructor files, and specification of `xadf` itself. We will also outline installation, uninstallation, and usage.

## xadf Directory Structure

A minimal `xadf` would inhabit the following locations, and be populated with the following files:

```
# Relative to $HOME/
xadf/              # the default git directory for xadf ($xadfdir), configurable on install
.local/
  bin/             # xadfrc will add this as $PATH
    xadf           # a helper script and an alias of git commands
  xadf/            # $xadfmods
    templates/     # especially useful for constructor functions
      default-recipe.txt
      template-xadfrc
    bash_aliases   # custom aliases
    bash_functions # custom functions
    <other custom modules and functions>
.config/
  xadf/            # $xadfconfig
    xadfrc         # formerly head.sh, sourced from .bashrc
    recipe.txt     # to determine which modules from $xadfmods to load
README.md          # a readme file                     (branch master only)
LICENSE            # our license file, currently GPLv3 (branch master only)
```

There will obviously be other configuration files for other apps, but the above directory structure is the most relevant for `xadf` script.

The configuration files in `.config/xadf/` will ensure that on login, or in a new shell session, the following steps will be run:

```
~/.bashrc
   > loads ~/.config/xadf/xadfrc
~/.config/xadf/xadfrc
   > ensures ~/.local/bin is in the $PATH
   > defines xadfconfig="$HOME/.config/xadf"
   > defines xadfmods="$HOME/.local/share/xadf"
   > defines xadfdir="$HOME/xadf/" # configurable by xadf during install
   > if no $xadfconfig/recipe.txt, calls `xadf --build-recipe`
   > else sources $xadfconfig/recipe.txt
~/.config/xadf/recipe.txt
   > if present, sources $xadfmods/bash_aliases
   > if present, sources $xadfmods/bash_functions
```

Therefore the most important parts of a minimal `xadf` environment are:

- a properly configured `~/.bashrc`
- a valid `~/.config/xadf/xadfrc` configuration
- an usable `~/.config/xadf/recipe.txt`

## Technical Specification of xadfrc

```
File     : xadfrc
Location : ~/.config/xadf/
```

**Description:** An init script supposed to be called from `.bashrc`, and performs the following actions:

1. ensures `~/.local/bin` is in the `$PATH`
2. defines `xadfconfig="$HOME/.config/xadf"`
3. defines `xadfmods="$HOME/.local/share/xadf"`
4. defines `xadfdir="$HOME/xadf/"`, configurable with `xadf --seat DIR` during installation
5. if `$xadfconfig/recipe.txt` is absent, calls `xadf --build-recipe`
6. else sources `$xadfconfig/recipe.txt`

```
File     : template-xadfrc
Location : ~/.local/xadf/templates/
```

**Description:** Not exactly `xadfrc`, but a template to be called by `xadf` script and produces `xadfrc`. It is almost identical with `xadfrc` except `$` sign is carefully escaped. For `$xadfdir` definition, it would come with a template or pattern that can be parsed by `xadf` to produce correct git directory of the dotfiles repo.

On parsing `template-xadfrc`, we can escape all `$` in the file, prepend and append `CAT <<EOF` and `EOF` to the template text, and then source it from terminal (or script) while piping it to `sed`. For example:

```bash
~$ . template-xadfrc|sed "s#$HOME#$\HOME#"
```

The `sed` command must use double quotes instead of single quotes so the `$HOME` part will undergo string expansion, before we substitute the string. Therefore the value of `$HOME` (eg. /home/username/) will be replaced with literal string `$HOME`.

## Technical Specification of recipe.txt

```
File     : recipe.txt
Location : ~/.config/xadf/
```

**Description:** A text file sourced by `xadfrc` during login or on a new terminal session, whose sole responsibility is to load select bash functions in `$xadfmods` directory. Must contain valid bash syntax.

It is automatically generated by `xadf` during install, or is reset when `xadf -r` is run, or is built from `default-recipe.txt`. Though later can be configured to load other modules in `$xadfmods`. Due to its nature on being sourced by `xadfrc` that is itself sourced from `.bashrc`, you can actually use it as an extension of `.bashrc`.

```
File     : default-recipe.txt
Location : ~/.local/xadf/templates/
```

The content of `$xadfmods/templates/default-recipe.txt` that is used to build default `recipe.txt` should at least performs the following actions:

1. if present, sources `$xadfmods/bash_aliases`
2. if present, sources `$xadfmods/bash_functions`

## Technical Specification of xadf

### Summary

This is essentially our dotfiles repo controller. It can also function as an installer script: downloading the entire repo, sets up alias, append source directive to `.bashrc`, and syncs all contents from dotfiles to `$HOME`. When called, it can also function as an alias for git with separate home dir, where the git directory is set at either `$HOME/xadf` or somewhere that is specified with `--seat` at install time.

**Program:** `xadf`

**Description:** A bash script to control and manage dotfiles in a home folder with bare git methods. When called without its native arguments, act as an alias of `git --git-dir=$xadfdir --work-tree=$HOME`

> **WARNING:** By default, it will sync all contents of the repository (obviously excluding `.git`) to `$HOME`. If it is undesirable, back up your files when necessary, or comment out the rsync command from `xadf` script directly.

### Options

The following are its native options:

**-l / --list-tracked PATH**
: lists tracked file, an alias of `xadf ls-tree --full-tree -r --name-only HEAD "$@"`. May expect arguments in form of PATH relative to repository root. Note: it is ***MUTUALLY EXCLUSIVE WITH*** other options after this option.

**-r / --build-recipe**
: produce `$xadfconfig/recipe.txt` by copying `$xadfmods/default-recipe.txt`

**-x / --build-xadfrc**
: produce `$xadfconfig/xadfrc` by constructing from `$xadfmods/template-xadfrc`. You can include `--seat DIR` so `xadfrc` is configured for a custom git directory.

**-t / --touch-bashrc**
: modifies `~/.bashrc` to source `$xadfconfig/xadfrc` if it does not already.

**--init-bare**
: Initialize a bare git repository at `$HOME`. you can specify custom git directory with '--seat DIR' option.

**-c / --custom-seat DIR**
: Sets xadf git directory to DIR, then assumes the following commands are git commands. Useful to use an alternative git directory.

**-o / --set-origin-url URL**
: Changes remote url to the specified URL. Essentially an alias for: `xadf remote set-url origin URL`

**--xadf-repo**
: Essentially an alias for: `xadf remote set-url origin git@gitlab.com:heno72/xadf.git`.
If you want to use your own git clone url, supply with `--set-origin-url/-o URL`.

**--heno**
: *REPLACED* with `--xadf-repo` since `xadf version v1.16.20230227.2312+optimize_mkdir`. Configures git upstream link, essentially an alias for `xadf remote set-url origin git@gitlab.com:heno72/xadf.git`.

**-h / --help**
: prints help and exit.

**--usage**
: Display usage examples and then exit.

**-v / --version**
: prints version and exit

Installation-specific options:

**--custom-install**
: Configure xadf to load from a non-xadf bare git repository. You can specify custom git directory with `--seat DIR` option. This is very useful if you already managed your dotfiles with bare git and alias method. Note that without `--seat DIR` option, the default git repository is `~/xadf` anyway, so you may need to specify your dotfiles git directory.

**--minimal-install**
: Install only core xadf files (honors `--branch/b BRANCH` option). BRANCH here is the branch of this repository. If BRANCH is not set, it defaults to this repository's branch 'trunk'. This is also useful if you want to set up your own bare git repository, or if you already have a bare git repository set up.

**-i / --install**
: function as an installer, and perform installation of xadf into user's `$HOME`, and building `xadfrc`. By default, configure xadf git directory in `$HOME/xadf`

**--seat DIR**
: configures xadf git directory to a custom location DIR instead of `$HOME/xadf` during install time. Is meant to be used in conjuction of option `-i / --install`

**-b / --branch NAME**
: checks out to branch NAME during install. Without this argument, it is identical to call the program with option `--branch master`

**--clone-source/-s URL**
: Sets a custom git repository URL to clone from during install. Note that it assumes you already have xadf installed in your home directory (see `--minimal-install`). Should be used with option `--install/-i`.

### Installer

The use of `-i` option when executing `xadf` should perform the following actions:

1. Replicate from xadf git repository with separate git configuration. If `--clone-source/-s URL` is set, replicate from the specified git clone URL, otherwise it will use its native clone URL (this repository). It will also produces a temporary directory `$HOME/.xadf-tmp` to store all contents of the repo. If `--seat` is set, replicate git directory to the specified location. Otherwise, replicate git directory to `$HOME/xadf`
2. Switch working directory to `$HOME/.xadf-tmp`
3. If `--branch` is set, checks out to branch NAME
4. `rsync` all contents of `$HOME/.xadf-tmp/` except '.git' to `$HOME`
5. Return to `$HOME`
6. Removes `$HOME/.xadf-tmp/`
7. Make untracked files not shown. Equivalent to `xadf config status.showUntrackedFiles no`
8. Check if `.bashrc` exists. If exists, go to 10, else go to 9
9. Copy from `/etc/skel/.bashrc` to `~/.bashrc`, and continue to 10
10. If `.bashrc` does not contain `. $HOME/.config/xadf/xadfrc`, appends that line to the end of `~/.bashrc`. Note that it should at first strip all comments off by piping to sed (does not modify `.bashrc`) and then performs `grep` search.
11. Builds `xadfrc` from `$xadfmods/templates/template-xadfrc` (honors `--seat` option)
12. If `recipe.txt` is absent, builds `recipe.txt` from `$xadfmods/templates/default-recipe.txt`

# Code Design of xadf

Following the specifications of `xadf` and its supporting configurations, we can then outline how the code should be structured.

1. Define state variables:
   
   > **Note for forkers:** you may want to change the values of `xadf_https_repo` and `xadf_ssh_repo` to point to your forked repository instead of mine.

```bash
version=<version number> # (for use with --version)
vanilla_xadf=0
build_recipe=0
build_xadfrc=0
touch_bashrc=0
init_bare=0
install_mode=0
install_seat="$HOME/xadf"
install_branch="trunk"
xadf_clone_url="https://gitlab.com/heno72/xadf.git"
xadf_set_url="git@gitlab.com:heno72/xadf.git"
set_origin_url=0
```

2. Define function `xadf_build_recipe()`

   > See [Technical specification of recipe.txt](#technical-specification-of-recipetxt)

   This function's sole purpose is to generate `recipe.txt` from our template. It does so by using program `cat`.

3. Define function `xadf_build_xadfrc()`

   > See [Technical specification of xadfrc](#technical-specification-of-xadfrc)

   This function's sole purpose is to generate a valid and usable `xadfrc` file to be sourced from `.bashrc`. The template will produce a valid `xadfrc` that points to the correct bare git repo directory (declare `$xadfdir`, however during installation it is the value of `xadf` internal variable `$install_seat`).

   It will display the `$xadfdir` in `$HOME/xadf` format instead of `/home/username/xadf` by the use of sed via pipeline:
   
   > `. ~/.local/xadf/templates/template-xadfrc | sed "s#$HOME#\$HOME#" > ~/.config/xadf/xadfrc`

4. Define function `xadf_touch_bashrc()`
   
   A new addition. Basically I split the original step 10 of the [installer routine](#installer) into a separate function. Therefore I can append an option that will also activate that routine independently when invoked.

5. Define function `xadf_init_bare()`
   
   Basically does only: `git init --bare "$install_seat"`. It can be used in conjuction of `--seat DIR` as it takes $install_seat variable: `xadf --init-bare [--seat DIR]`. Essentially the function initiate a new empty bare git repository somewhere at `$HOME`.

6. Define function `xadf_custom_install()`

   Basically the function will invoke function `xadf_build_xadfrc()`, `xadf_build_recipe()` (only if `recipe.txt` is not already present), and `xadf_touch_bashrc()`. It also honors `--seat DIR` option to specify a custom location for your bare git directory.

7. Define function `xadf_minimal_test()`

   This function detects whether the base contents of `$xadfmods/templates` (`bash_aliases`, `bash_functions`, `default-recipe.txt`, and `template-xadfrc`) are present. This is meant to assist the `xadf_minimal_install()` function.

8. Define function `xadf_curl_download()` and function `xadf_wget_download()`

   Their sole purpose is to download `xadf` and its support files (the ones tested in function no. 7). Function `xadf_minimal_install()` is meant to be the one that invoke them.

9. Define function `xadf_minimal_install()`

   Its purpose is to create basic directory structures for a minimal `xadf` installation (when using `--minimal-install` option), then download the files listed below. It will try if `wget` exists first, and download with `wget` if it does exist.
   Otherwise it will attempt to try and use `curl`, and scream if neither of them exists.

```
~/.local/bin/xadf
~/.local/xadf/templates/bash_aliases
~/.local/xadf/templates/bash_functions
~/.local/xadf/templates/default-recipe.txt
~/.local/xadf/templates/template-xadfrc
```

10. Define function `xadf_clone_source()`

    Essentially performs step 1 to step 6 of the [installation routine](#installer). It is separated from `xadf_install()` for clarity.

11. Define function `xadf_install()`

    > See [Installer](#installer)

    This is by far the most complicated function of the code.
    For almost each steps it will test whether the action is completed succesfully.
    It will break when it encountered errors, and possibly clean up to not interfere up with future installation attempt.

12. Define function `xadf_touch_origin()`
    
    Supposedly an analog of `git remote set-url origin URL`. Will call itself if it is already configured, otherwise will manually call git. Its sole responsibility is to configure origin url of your bare git repository.

13. Define function `xadf_version()`

    > Prints program name and version, then exit.

14. Define function `xadf_show_usage()`

    > Runs `xadf -v`, then prints usage text, then exit.

15. Define function `xadf_show_help()`

    > Runs `xadf -v`, then prints help text, then exit.

16. Parse options.
   
    Basic while loop that is true until is told to break, then arguments are passed via case conditionals.

    For option `-l / --list-tracked`, run: `xadf ls-tree --full-tree -r --name-only HEAD "$@"`. Note that it may also expect to be provided arguments, for example to specify which file or directory do we want to see (just like `ls` in some ways).

    For option `-h / --help`, runs `xadf_show_help()` and then exit.

    For option `--usage`, runs `xadf_show_usage()` and then exit.

    For option `-v / --version`, runs `xadf_version()` and then exit.

    For all other native `xadf` options, they will only be used to manipulate state variables.

    - `-i / --install` changes `install_mode=1`
    - `--custom-install` changes `install_mode=2`
    - `--minimal-install` changes `install_mode=3`
    - `--seat` changes `$install_seat` to DIR
    - `-b / --branch` changes `$install_branch` to NAME
    - `-r / --build-recipe` changes `build_recipe=1`
    - `-x / --build-xadfrc` changes `build_xadfrc=1`
    - `-t / --touch-bashrc` changes `touch_bashrc=1`
    - `--init-bare` changes `init_bare=1`
    - `--xadf-repo` changes `vanilla_xadf=1`
    - `--heno` changes `is_heno=1` (*REMOVED*, replaced with `--xadf-repo`)
    - `-o / --set-origin-url` changes `set_origin_url=1` and set `$xadf_set_url` to URL
    - `-s / --clone-source` changes `$xadf_clone_url` to URL
    - `-c / --custom-seat` changes `$install_seat` to DIR and then run `git --git-dir="$install_seat" --work-tree="$HOME" "$@"` (assuming all arguments following it as git commands)
   
    When no native `xadf` options are provided, run: `git --git-dir="$xadfdir" --work-tree="$HOME" "$@"`. Note that it should fail if `$xadfdir` is not set (that is, no xadf installed yet). It will expect all arguments following it to be git arguments, so treat it just like you would a `git` command.

8. Main section

   Check state variables, and decide what function to call.

   1. if `init_bare=1`, then calls `xadf_init_bare()`
   1. if `install_mode=1`, then calls `xadf_install()`
   1. if `install_mode=2`, then calls `xadf_custom_install()`
   1. if `install_mode=3`, then calls `xadf_minimal_install()`
   1. if `build_recipe=1`, then calls `xadf_build_recipe()`
   1. if `build_xadfrc=1`, then calls `xadf_build_xadfrc()`
   1. if `touch_bashrc=1`, then calls `xadf_touch_bashrc()`
   4. if `vanilla_xadf=1` or `set_origin_url=1`, then calls `xadf_touch_origin()`

# Installation of xadf

If you are reading this, it is likely that you are interested with either my dotfiles configuration, managing your dotfiles with bare git and alias method, or the `xadf` executable itself. The following sections might therefore be useful for you:

- [obtaining xadf executable](#obtaining-xadf-executable): a very useful and powerful wrapper script that can help managing your dotfiles with bare git and alias method.
- [normal installation](#normal-installation): installs `xadf` along with the entire content of this repository.
- [custom installation](#custom-installation): will configure an already installed `xadf` to use another git directory.
- [minimal installation](#minimal-installation): will only install `xadf` executables and a minimal set of files meant to be used by `xadf`.

## Obtaining xadf executable

> **Tip:** You may wish to [check dependencies](#dependencies-of-xadf) required to properly run xadf.

I have designed this project in a way that replicating my configuration is as simple as obtaining the `xadf` executable and running it. Therefore `xadf` is designed to be able to bootstrap, clone and configure git managed dotfiles to any `$HOME` in any linux system. After everything is configured, it can then be used to manage your dotfiles using git. However the first step is to obtain the executable itself.

You can download xadf script [here](https://gitlab.com/heno72/xadf/-/raw/master/.local/bin/xadf). Then you need to make it executable. Place it somewhere in your `$PATH`. Ideally save it as `$HOME/.local/bin/xadf` so it will be replaced with the latest version of `xadf` from our git repository.

```bash
# Download the script
wget -c https://gitlab.com/heno72/xadf/-/raw/master/.local/bin/xadf

# Make the script executable
chmod +x xadf

# Move to local bin directory, you may need to make it.
mv xadf ~/.local/bin/
```

If `$HOME/.local/bin/` is not in your path, you can include it with the following command:

```bash
PATH=~/.local/bin:$PATH
```

## Normal Installation

After you obtain `xadf` executable and put it in an appropriate location, you can then run:

```bash
xadf -i [--seat DIR] [--branch BRANCH] [--xadf-repo]
```

Option `--seat DIR` will change default git directory from `~/xadf` to DIR. DIR can be any directory under home of your choice, (eg. `~/.xadf` or `~/.dotfiles`).

Option `--branch BRANCH` will change checked out branch from default branch to branch BRANCH (of your choice). The branch must already exist in your repository.

As we are downloading from https git clone url, we must provide our credentials on every push. This is generally undesirable. Provided that we already set up ssh keys in our environment, we can use option `--xadf-repo` to change the link from https clone url to our git ssh clone url. If you wish to set up a custom git clone url, consider using `--set-origin-url/-o URL` option.

If `xadfrc` is not created during installation, or if it is damaged at later date, you can use `xadf -x` or `xadf --build-xadfrc` to rebuild it. If you set up a custom git DIR with `--seat DIR`, then you may need to also supply it when building `xadfrc`, or else it would point to wrong `$xadfdir` location.

Or you might as well perform a [custom installation](#custom-installation).

## Custom Installation

After having cloned this repository to your `$HOME` and setting up `xadf` accordingly (should already be done with `-i` option), circumstances might arise where you need to change your git directory. For example if you have already cloned this repository and the git repository is set to `~/xadf` (the default behavior when you just run `xadf -i`), you may want to change it to something like `~/.dotfiles`.

In that case, you can actually move the `$xadfdir` location from default `~/xadf` or any previously set directory (eg. moving it to `~/.dotfiles` or `~/.xadf`), and then update `xadfrc` with the following commands:

```bash
# Move git directory (eg. from ~/xadf to ~/.dotfiles)
mv ~/xadf ~/.dotfiles

# To prevent xadf from getting confused of previous xadf-specific environment variables
unset xadfdir

# Build xadfrc to use new git dir location
xadf --build-xadfrc --seat ~/.dotfiles
# or
xadf -x --seat ~/.dotfiles

# Source your .bashrc
. ~/.bashrc

# Check whether everything is succesfully configured or not
xadf status -sb
```

If the command sequences above are too scary for you, there's actually a shortcut for all of that built into `xadf` itself. After you copy or move your git directory to any DIR you prefer (in this example you move `~/xadf` to `~/.dotfiles`), you can run the following:

```bash
# change DIR to your preferred location (eg. ~/.dotfiles)
xadf -x --seat DIR
xadf -r
xadf -t
. ~/.bashrc
```

Or alternately, you can just run this to perform all of the actions above:

```bash
xadf --custom-install [--seat DIR]
. ~/.bashrc
```

Really, it can't be any simpler than that.
It will configure your `.bashrc` to load `xadfrc`, and `xadfrc` will be configured to set `$xadfdir` to DIR. This is also particularly useful if you want to _switch to your own bare git repository_.

However if you want to start everything from scratch, including starting your own bare git repository, or if you don't want to ruin your current perfect set up, you may want to consider [minimal install](#minimal-installation) instead.

## Minimal Installation

If you prefer a more DIY approach or you do not want to ruin your `$HOME` with my configuration files, it is actually possible to *only* install `xadf` and nothing else (not even cloning from my repository). This is the least invasive method I can craft for you.

After all, the only files actually required for `xadf` to run are:

```
# The xadf executable
~/.local/bin/xadf

# Templates for xadf configuration files
~/.local/xadf/templates/bash_aliases
~/.local/xadf/templates/bash_functions
~/.local/xadf/templates/default-recipe.txt
~/.local/xadf/templates/template-xadfrc
```

Once they are downloaded and placed in appropriate locations, you just have to make `xadf` executable and put `~/.local/bin` in your `$PATH`. You can do it all by yourself (manually navigate to those files from my repository, download them, and place them in appropriate locations), or after you [obtain the executable](#obtaining-xadf-executable), you can just run:

```bash
# Install the minimal set of xadf files
# Note that BRANCH is the branch in xadf native repository.
xadf --minimal-install [--branch BRANCH]
```

Then you can do anything you like, really.

If you want to initialize a new bare git repository, run:

```bash
# if --seat is not specified, default to ~/xadf
xadf --init-bare [--seat DIR]
```

Then you will need to configure your `xadf` to point to and manage the newly created bare git directory with:

```bash
# specify --seat DIR if your git repository is anywhere but ~/xadf
xadf --custom-install [--seat DIR]
```

Alternatively, you may already have a dotfiles repository designed to be managed by git, or specifically configured for bare git and alias method. You can then automagically use `xadf` to replicate your configurations by running:

```bash
xadf -i -s URL [--seat DIR] [-b BRANCH]
```

Note that:

1. URL is the url of your git repository that xadf should clone from.
1. DIR is your preferred location for git directory (eg. ~/.dotfiles).
   If DIR is not specified, defaults to '~/xadf'
1. BRANCH is the git branch of your liking from your configuration.
   If BRANCH is not specified, defaults to 'trunk'

If you are using this method of installing `xadf`, the only reference to my repository is just hardcoded in `xadf` file itself. This is only required so you can keep your `xadf` updated to the latest version by simply running `xadf --minimal-install [--branch BRANCH]` again.

> **Note:** currently there's a bug where after `xadf` is updated in that manner, some bash error messages are shown without impeding the function of the script. It is apparently safe to ignore, as it might be caused by bash trying to access the old `xadf` executable that will be rewritten when using `--minimal-install`. The function will run just fine because the executable rewriting will happen near the end of the file as function `xadf_minimal_install()` is actually invoked.

## Dependencies of xadf

`xadf` is nothing but a single executable bash script, and depends on a variety of programs installed in your environment. The following is a non-exahustive list of programs that you need to have installed before running the script:

- `bash` - GNU bash
- `cat` - GNU coreutils
- `sed` - GNU sed
- `git`
- `rm` - GNU coreutils
- `rsync`
- `realpath` - GNU coreutils
- `wget` - GNU Wget

# Uninstallation of xadf

In case we want to uninstall `xadf`, all we have to do is to remove:

```
.local/bin/xadf
.local/xadf/
.config/xadf/
```

Note that the above list is not comprehensive, and will only uninstall xadf and its helper resources. Configuration files of other programs will remain. It should be possible to delete every file git tracks in your home directory by piping `xadf -l` output to `xargs rm -rf`:

```bash
xadf -l | xargs rm -rf
```

Warning, do so at your own risk, and only if you know what you're doing.

And then remove a line in `~/.bashrc` that sources `~/.config/xadf/xadfrc`. Also do:

```bash
unset xadfconfig xadfmods xadfdir
```

It is required to unset those variables because it might interfere in the next attempt to install `xadf`

# Migrating from xadf v0

> **Note:** This section is for my personal use.

The `xadf v0` is actually my previous poor attempt to back up and manage dotfiles. I was having difficulties on setting up a repository, that I can pull into a new machine, and then use custom bash function `xadf()` to pull and update config files. Then I will have to manually sync the content of the repository into appropriate locations on my real home.

As you may have guessed, it is very easy for me to forget to actually edit inside xadf directory (a separate location from my actual dotfiles location), and sync to home directory. I ended up editing directly on my home directory, and syncing them one by one to the repository.

Because of the frustration on managing them in such a tedious workflow, I decided to research more on how to manage dotfiles. That brings us to the current incarnation of `xadf`.

However it is not entirely an useless experience for me. In fact because of the previous incarnation of `xadf`, I get the inspiration of the current `.bashrc > xadfrc > recipe.txt` (it was `.bashrc > head.sh > recipe.txt` in `xadf v0`).

## Brief differences between xadf v0 and current xadf script

`xadf v0` was designed to operate in a single location (designated `$xadf` directory) that will contain custom functions, extensions for bash aliases and bash functions, and other configuration files. Meanwhile in `xadf`, all the files are meant to reside direclty in user home directory.

Its installation is also similar. All we have to do is to clone the repository to any location we wish under `$HOME` (normally `~/Documents/xadf/`), change directory there, and run `xadf.sh`. It will generate `head.sh` and `recipe.txt` if they are not present already, and append a line in `~/.bashrc` to source `head.sh`. Then we manually sync the content of `config/` to `~/.config/` and the content of `local/` to `~/.local/`. That last step must be repeated on every update made in `config/` and `local/` under `$xadf/`.

| xadf v0 | current xadf | comment |
| :------ | :----------- | :------ |
| `$xadf/`                 | `~/`                        | Root directory of the repository |
| `$xadf/config/`          | `~/.config/`                | Previous `xadf v0` requires us to manually sync them with `~/.config/` |
| `$xadf/custom/`          | `~/.local/xadf/`            | Where we place `bash_functions`, `bash_aliases`, and various custom bash scripts. The `bash_function` file in `xadf v0` used to have a custom `xadf()` function to update `$xadf` directory with remote, or reload `head.sh`. |
| `$xadf/local/`           | `~/.local/`                 | Generally where we place binaries or shared files (for programs to use) |
| `$xadf/xadf.sh`          | `~/.local/bin/xadf`         | Not exactly a direct analog. In `xadf v0`, its responsibility is to generate `head.sh` and `recipe.txt`, while also appending a line in `.bashrc` to source `head.sh` if it is not present. Meanwhile the current incarnation manages everything from installing to day-to-day use. |
| `$xadf/head.sh`          | `~/.config/xadf/xadfrc`     | Manages xadf-specific variables, especially where it would look for configuration files. Also loads `recipe.txt` |
| `$xadf/recipe.txt`       | `~/.config/xadf/recipe.txt` | A definition file for what modules to load, also function as an extension of `.bashrc` |

One major difference of current incarnation of `xadf` with `xadf v0` is that configuration files in `$xadf/` is not the same as configuration files in `$HOME/`. This is not true with the current incarnation where the working directory of `xadf` repository is exactly `$HOME`.

Similar to the current incarnation, I designed `xadf v0` to be minimally invasive to the home directory. Meaning its entire life hangs on the existence of a line in `.bashrc` that loads `$xadf/head.sh`. It is useful for my case because it means all I have to do is simply to remove or comment out that line.

## Removing xadf v0

As described in the previous section, removing `xadf v0` should be fairly trivial and easy. Ideally it should also be done before installing `xadf` because of the existence of `xadf()` bash function in a system managed with `xadf v0`. We also want to do it in the most simplest and reproducible manner.

The exact actions that must be exactly followed are:

1. Comment out the line in `.bashrc` that sources `$xadf/head.sh`
2. Unset `xadf()` from your environment to not interfere with `~/.local/bin/xadf`

Hence the following oneliner:

```
sed -i 's_^source.*xadf/head\.sh._#&_' ~/.bashrc && unset -f xadf
```

The `sed` invocation search within `~/.bashrc` for a line that starts with `source`, then followed with anything, then also contain `xadf/head.sh` and one more character (I specifically searched for the ending `"`), then replace it with the string `# ` and all the matches (the regex pattern `&` does it). If it is successfully removed, it will unset function in your bash environment named `xadf`.

Afterwards you can safely remove `$xadf` if so desired:

```
rm -rf "$xadf"
```

That is the entire necessary steps required to remove `xadf v0`. You can then proceed to [install `xadf`](#installation-of-xadf).
