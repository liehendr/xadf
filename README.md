**Welcome to my dotfiles repository!**

My dotfiles repository, managed with [bare git and alias method](https://news.ycombinator.com/item?id=11071754), implemented as a custom controller script ([`xadf`](.local/bin/xadf)) that also function as a standalone installation script to replicate my dotfiles configuration to any unix home directory with bash.
Also features a number of custom bash functions (the [`$xadfmods`](.local/xadf/)) either for my use or just for fun.

[TOC]

# Introduction

Since 6 February 2023, I've been looking for a way to conveniently manage my dotfiles with git version control. The question remains on how to properly do it? The options are either using [stow](https://brandon.invergo.net/news/2012-05-26-using-gnu-stow-to-manage-your-dotfiles.html), or bare git and alias method (see [archlinux wiki page on dotfiles](https://wiki.archlinux.org/title/Dotfiles).

After testing the `stow` methods in 13 February 2023, I concluded that it provides only marginal improvements at the expense of symlinking in home directory and complicated setup (manually copy config files and recreate the directory tree for each stow packages). The bare git and alias method seems simpler, directly work at home directory instead of a separate folder, avoids symlinking, and we can selectively decide which file to track. ([The set up](https://gitlab.com/Siilwyn/my-dotfiles/tree/master/.my-dotfiles)) seems to be simpler too.

However the problem remains on how to include [`LICENSE`](./LICENSE) and `README.md` at the root of repository but not in our actual home folder. It is trivial with `stow` method, where we just place them in the root of the repository, while each folder represents stow packages. With git, we have to use smart branch hacks to hide `LICENSE` and `README.md` from our actual home directory.

The following sections will describe basic idea of how to set up bare git and alias method, how to deal with `LICENSE` and `README.md`, and my actual implementation of bare git and alias method.

# Manage Dotfiles with Bare Git and Alias Method - Basic Idea

Basically, to manage dotfiles with git bare methods, we have to set up a bare repository, and use a different work-tree. Then to replicate it, we clone with `--separate-git-dir` argument to a temporary directory. Then we rsync (except for `.git` folder) to home directory, and later remove the temporary directory.

## Setup

The basic idea is to initialize a bare git repository over an existing (or fresh) home directory, then set up an alias (ideally add them to `.bashrc` or `.bash_aliases`), and add a remote for us to push to.

```
git init --bare $HOME/xadf
alias xadf='git --git-dir=$HOME/xadf/ --work-tree=$HOME'
xadf remote add origin git@gitlab.com:heno72/xadf.git
```

## Replication

If the repository is already been set up, we can just clone the repo with separate git directory. Initially, we will need to clone the work tree to a temporary directory, and then sync the content of the temporary directory to our home directory. Later we can just delete the temporary directory.

```
git clone --separate-git-dir=$HOME/xadf https://gitlab.com/heno72/xadf.git .xadf-tmp
rsync --recursive --verbose --exclude '.git' .xadf-tmp/ $HOME/
rm --recursive .xadf-tmp
```

## Configuration

Since there would be a ton of files in a real home directory, having them shown all the time will be a nuisance and a straightforward distraction. Here we configure git to not show untracked files.

Additionally, since we are cloning from https link, we may need to change the link to ssh clone link. Otherwise we will have to type our credentials on every push operation. Make sure to set up ssh keys on the machine and add it to your git account beforehand.

```
xadf config status.showUntrackedFiles no
xadf remote set-url origin git@gitlab.com:heno72/xadf-gb.git
```

## Usage

After setting up, we can just use the alias to substitute `git` command in our home directory. We can use it like any normal git command. Therefore eliminating collision with real git repository under home. Also typical `git` commands would not work at our home root since it does not contain `~/.git` directory.

```
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

Though, honestly I would advise to make shared configs on `trunk` and later merge them to other branches and branch `master`.

Therefore, we can visualize the merge direction like this:
```
master < trunk <> termux
               <> laptop
```
> only merge `trunk` to `master`, `termux`, or `laptop`, or from `termux` or `laptop` to `trunk`, but never merge `master` to `trunk`.

# Implementing Bare Git with Alias method as a helper script

Instead of just using alias, and do all of the steps described in previous section manually, I want to have them be done automatically with a script. The goal is to have a single script that will handle installation (cloning repo with separate git directory, checking out to correct branch, syncing repo contents to home directory, set up helper configuration files so we can use the tool on the next login or new terminal sessions), and can function as an alias to git with separate git directory (essentially an alias for `git --git-dir=$xadfdir --work-tree=$HOME`, where `$xadfdir` is declared in the aforementioned helper configuration file) for day to day use.

Since I already have working `.bashrc` configurations in most of my machines and setups (especially my android's termux), I want the mechanism to be minimally invasive to `.bashrc`. We could later decide to track `.bashrc` in separate machine-specific branches, or the produced configuration files in `~/.config/xadf` (`$xadfconfig`) if necessary. We should also distinguish `.local` and `.config` use. I want `.local` to be used to store custom functions and and templates, while `.config` folder to specifically store `xadf` related configurations, or configuration files of custom functions or custom scripts shipped with `xadf` in `~/.local/{bin,xadf}`

The following subsections will outline the basic directory structures, specification of configuration files and config constructor files, and specification of `xadf` itself. We will also outline installation, uninstallation, and usage.

## xadf Directory Structure

A minimal `xadf` would inhabit the following locations, and be populated with the following files:

```
# Relative to $HOME/
xadf/              # the default git directory for xadf, configurable on install
                   # xadf will declare it as $xadfdir
.local/
  bin/             # xadfrc will add this as $PATH
    xadf           # a helper script and an alias of git commands
  xadf/            # xadfrc will declare it as $xadfmods
    templates/     # especially useful for constructor functions
      default-recipe.txt
      template-xadfrc
    bash_aliases   # common aliases for our use
    bash_functions # common functions for our use
    <other custom modules and functions>
.config/
  xadf/            # xadfrc will declare it as $xadfconfig
    xadfrc         # formerly head.sh, sourced from .bashrc
    recipe.txt     # to determine which modules from $xadfmods to load
README.md          # this file                         (only present in branch master)
LICENSE            # our license file, currently GPLv3 (only present in branch master)
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
File: template-xadfrc
Location: ~/.local/xadf/templates/
```

**Description:** Not exactly `xadfrc`, but a template to be called by `xadf` script and produces `xadfrc`. It is almost identical with `xadfrc` except `$` sign is carefully escaped. For `$xadfdir` definition, it would come with a template or pattern that can be parsed by `xadf` to produce correct git directory of the dotfiles repo.

On parsing `template-xadfrc`, we can escape all `$` in the file, prepend and append `CAT <<EOF` and `EOF` to the template text, and then source it from terminal (or script) while piping it to `sed`. For example:

```
~$ . template-xadfrc|sed "s#$HOME#$\HOME#"
```

The `sed` command must use double quotes instead of single quotes so the `$HOME` part will undergo string expansion, before we substitute the string. Therefore the value of `$HOME` (eg. /home/username/) will be replaced with literal string `$HOME`.

## Technical Specification of recipe.txt

```
File: recipe.txt
Location: ~/.config/xadf/
```

**Description:** A text file sourced by `xadfrc` during login or on a new terminal session, whose sole responsibility is to load select bash functions in `$xadfmods` directory. Must contain valid bash syntax.

It is automatically generated by `xadf` during install, or is reset when `xadf -r` is run, or is built from `default-recipe.txt`. Though later can be configured to load other modules in `$xadfmods`. Due to its nature on being sourced by `xadfrc` that is itself sourced from `.bashrc`, you can actually use it as an extension of `.bashrc`.

```
File: default-recipe.txt
Location: ~/.local/xadf/templates/
```

The content of `$xadfmods/templates/default-recipe.txt` that is used to build default `recipe.txt` should at least perfomrs the following actions:

1. if present, sources `$xadfmods/bash_aliases`
2. if present, sources `$xadfmods/bash_functions`

## Technical Specification of xadf

### Summary

This is essentially our dotfiles repo controller. It can also function as an installer script: downloading the entire repo, sets up alias, append source directive to .bashrc, and syncs all contents from dotfiles to `$HOME`. When called, it can also function as an alias for git with separate home dir, where the git directory is set at either `$HOME/xadf` or somewhere that is specified with `--seat` at install time.

**Program:** `xadf`

**Description:** A bash script to control and manage dotfiles in a home folder with bare git methods. When called without its native arguments, act as an alias of `git --git-dir=$xadfdir --work-tree=$HOME`

> **WARNING:** By default, it will sync all contents of the repository (obviously excluding `.git`) to `$HOME`. If it is undesirable, back up your files when necessary, or comment out the rsync command from `xadf` script directly.

### Options

The following are its native options:

**-r / --build-recipe**
: produce `$xadfconfig/recipe.txt` by copying `$xadfmods/default-recipe.txt`

**-x / --build-xadfrc**
: produce `$xadfconfig/xadfrc` by constructing from `$xadfmods/template-xadfrc`

**-l / --list-tracked**
: lists tracked file, an alias of `xadf ls-tree --full-tree -r --name-only HEAD "$@"`. May expect arguments in form of path relative to repository root. See README.md of dotfiles repo of alfunx. Note: it is ***MUTUALLY EXCLUSIVE WITH*** other options after this option.

**--heno**
: configures upstream link, essentially an alias for `xadf remote set-url origin git@gitlab.com:heno72/xadf.git` (for my personal needs, don't do that if you don't have write access there! If so desired, you can change the option or the url to your own).

**-v / --version**
: prints version and exit

**-h / --help**
: prints help and exit

Installation-specific options:

**-i / --install**
: function as an installer, and perform installation of xadf into user's `$HOME`, and building `xadfrc`. By default, configure xadf git directory in `$HOME/xadf`

**--seat DIR**
: configures xadf git directory to a custom location DIR instead of `$HOME/xadf` during install time. Is meant to be used in conjuction of option `-i / --install`

**-b NAME / --branch NAME**
: checks out to branch NAME. Without this argument, it is identical to call the program with option `--branch master`

### Install actions

The use of `-i` option when executing `xadf` should perform the following actions:

1. Replicate from xadf git repository with separate git configuration. It will also specify a temporary location `$HOME/.xadf-tmp` to store all contents of the repo. If `--seat` is set, replicate git directory to the specified location. Otherwise, replicate git directory to `$HOME/xadf`
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

### Code Design

1. Define state variables:

```
version=<version number> # (for use with --version)
is_heno=0
build_recipe=0
build_xadfrc=0
install_mode=0
install_seat="$HOME/xadf"
install_branch=master
```

2. Define function `xadf_build_recipe()`

   > See [Technical specification of recipe.txt]()

3. Define function `xadf_build_xadfrc()`

   > See [Technical specification of xadfrc]()

4. Define function `xadf_install()`

   > See [Install actions]()

5. Define function `xadf_version()`

   > Prints program name and version, then exit.

6. Define function `xadf_show_help()`

   > Runs `xadf -v`, then prints help text, then exit.

7. Parse options.
   
   Basic while loop that is true until is told to break, then arguments are passed via case conditionals.

   For option `-l / --list-tracked`, run: `xadf ls-tree --full-tree -r --name-only HEAD "$@"`. Note that it may also expect to be provided arguments, for example to specify which file or directory do we want to see (just like `ls` in some ways).

   For option `-h / --help`, runs `xadf_show_help()` and then exit.

   For option `-v / --version`, runs `xadf_version()` and then exit.

   For all other native `xadf` options, they will only be used to manipulate state variables.
   a. `-i / --image` changes `install_mode=1`
   b. `--seat` changes `$install_seat` to DIR
   c. `-b / --branch` changes `$install_branch` to NAME
   d. `-r / --build-recipe` changes `build_recipe=1`
   e. `-x / --build-xadfrc` changes `build_xadfrc=1`
   f. `--heno` changes `is_heno=1`

   When no native `xadf` options are provided, run: `git --git-dir="$xadfdir" --work-tree="$HOME" "$@"`. Note that it should fail if `$xadfdir` is not set (that is, no xadf installed yet). It will expect all arguments following it to be git arguments, so treat it just like you would a `git` command.

8. Main section

   Check state variables, and decide what function to call.

   a. if `install_mode=1`, then calls `xadf_install()`
   b. if `build_recipe=1`, then calls `xadf_build_recipe()`
   c. if `build_xadfrc=1`, then calls `xadf_build_xadfrc()`
   d. if `is_heno=1`, then runs `xadf remote set-url origin git@gitlab.com:heno72/xadf.git`

## Installation

Download xadf script [here](https://gitlab.com/heno72/xadf/-/raw/master/.local/bin/xadf), then make it executable. Place it somewhere in your `$PATH`. Ideally save it as `$HOME/.local/bin/xadf` so it will be replaced with the latest version of `xadf` from our git repository. If `$HOME/.local/bin/` is not in your path, you can actually run the following command:

```bash
PATH=~/.local/bin:$PATH
```

Then run:

```bash
xadf -i [--seat DIR] [--branch BRANCH] [--heno]
```

Option `--seat DIR` will change default git directory from `~/xadf` to DIR (of your choice, eg. `~/.xadf`).

Option `--branch BRANCH` will change checked out branch from default branch to branch BRANCH (of your choice). The branch must already exist in your repository.

## Uninstallation

In case we want to uninstall `xadf`, all we have to do is to remove:

```
.local/bin/xadf
.local/xadf/
.config/xadf/
```

And then remove a line in `~/.bashrc` that sources `~/.config/xadf/xadfrc`. Also do:

```
unset xadfconfig xadfmods xadfdir
```

It is required to unset those variables because it might interfere in the next attempt to install `xadf`