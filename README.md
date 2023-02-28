# `~/.*` managed with `xadf`

![Obligatory screenshot](pics/screenshot.png)

Welcome to my dotfiles repository! Managed with [bare git and alias method](https://news.ycombinator.com/item?id=11071754), implemented as a custom controller script ([`xadf`](.local/bin/xadf)) that also functions as a standalone installation script to replicate my dotfiles configuration to any unix home directory with bash.
Also features a number of custom bash functions (the [`$xadfmods`](.local/xadf/)) either for my use or just for fun.

[TOC]

# Dotfiles Management 101

There are myriads of way to manage dotfiles, either using just a handful of general tools such as [git](https://git-scm.com/) and [stow](https://www.gnu.org/software/stow/), or a set of specialized [wrapper tools](https://wiki.archlinux.org/title/Dotfiles#Tools). In this section, I will provide a brief summary of how to [manage dotfiles with stow](https://brandon.invergo.net/news/2012-05-26-using-gnu-stow-to-manage-your-dotfiles.html), and with bare git and alias. Following that is an alternative wrapper script I created for my own use.

## Stow method

Stow allows one to collect a group of files in 'packages', that can be installed to any location via symlinking (for managing dotfiles, the installation directory is usually `$HOME`). A package consists of a package directory that contain files and directories mirroring the target install location up to the root of installation directory. Consider you have program `alpha`, `beta`, and `gamma`, each having their own set of files and directories where they will look for configuration files:

```
~/
  .config/
    alpha/
      config
  .local/
    share/
      beta/
        clutter
    bin/
      beta
  .gamma/
    settings.xml
  .gammarc
```

All you need to do is to move them into a stow directory, and recreate the entire directory tree inside that stow directory. Alternatively, you can group them into per-program basis:

```
~/.dotfiles/
  alpha/
    .config/
      alpha/
        config
  beta/
    .local/
      share/
        beta/
          clutter
      bin/
        beta
  gamma/
    .gamma/
      settings.xml
    .gammarc
```

Then all we have to do is:

```bash
# navigate to the stow directory
cd ~/.dotfiles

# manually select each packages for installation to ~/
stow alpha
stow beta
stow gamma

# alternatively, install all packages to ~/
for pkg in */ ; do stow $pkg ; done
```

> Note that stow's default behavior is to install the packages inside a stow directory (here it is `~/.dotfiles`) to the parent directory of the stow directory (in this case we want it to be `~/`).

If you want to delete them, you will need to do:

```bash
# navigate to the stow directory
cd ~/.dotfiles

# You can select which package to delete
stow -D alpha
stow -D beta
stow -D gamma

# Or delete all packages present here simultaneously
for pkg in */ ; do stow -D $pkg ; done
```

It is also possible that a collision occur (when the file stow is trying to 'install' is already present in the install directory). In that case, you can use `--adopt` option:

```bash
stow --adopt alpha
```

What it does is that the existing file in the install directory (in this case `~/`) will be moved inside our stow directory (in this example `~/.dotfiles`), and a symlink to the file will instead be created at the install directory.

After everything is configured to your liking, you can just turn the stow directory (`~/.dotfiles`) into a git repository to sync with your preferred remote.

Further reading on the stow method can be found [here](https://venthur.de/2021-12-19-managing-dotfiles-with-stow.html) and [here](https://alexpearce.me/2016/02/managing-dotfiles-with-stow/).

## Bare git and alias method

Basically, to manage dotfiles with git bare methods, we have to set up a bare repository, and use a different work-tree. Then to replicate it, we clone with `--separate-git-dir` argument to a temporary directory. Then we rsync (except for `.git` folder) to home directory, and later remove the temporary directory.

[Siilwyn](https://github.com/Siilwyn/my-dotfiles/tree/master/.my-dotfiles) made a very brief guide on how to set up and manage such setup. Furthermore there is also [this article](https://www.atlassian.com/git/tutorials/dotfiles), and the method is [popularized here](https://news.ycombinator.com/item?id=11071754).

In the next subsections, I will take the liberty to briefly demonstrate such setup. If you want more explanation to follow along, you may consider reading [this article](docs/xadf.md#manage-dotfiles-with-bare-git-and-alias-method---basic-idea).

### Setup

```bash
git init --bare $HOME/xadf
alias xadf='git --git-dir=$HOME/xadf/ --work-tree=$HOME'
xadf remote add origin git@gitlab.com:heno72/xadf.git
```

### Replication

```bash
git clone --separate-git-dir=$HOME/xadf https://gitlab.com/heno72/xadf.git .xadf-tmp
rsync --recursive --verbose --exclude '.git' .xadf-tmp/ $HOME/
rm --recursive .xadf-tmp
```

### Configuration

```bash
xadf config status.showUntrackedFiles no
xadf remote set-url origin git@gitlab.com:heno72/xadf-gb.git
```

### Usage

```bash
xadf status
xadf add .gitconfig
xadf commit -m 'Add gitconfig'
xadf push
```

## xadf: a custom implementation of bare git and alias methods

After trying both methods outlined above, I find myself liking the bare git and alias method. However I wanted more: a way to perform all of the steps outlined in the previous section from just a single wrapper script. I also want the file to be the one that will also manage the dotfiles after everything is set up. One of the requirement of such script is that it can be minimally invasive to existing setup. You may want to read more to read how I [implement the script here](docs/xadf.md#implementing-bare-git-with-alias-method-as-a-helper-script).

To demonstrate the prowess of my implementation, here's how I can rapidly set up a new empty bare git repository after [obtaining the script and placing it in my PATH](docs/xadf.md#obtaining-xadf-executable):

```bash
# Install xadf base files necessary to configure it
xadf --minimal-install

# Initialize an empty bare git repository and configure xadf to manage it
xadf --init-bare --seat ~/.dotfiles
xadf --custom-install --seat ~/.dotfiles

# Source ~/.bashrc to load the new configuration
. ~/.bashrc

# Hide untracked files
xadf config status.showUntrackedFiles no
```

You can read more about this from my [minimal installation guide](docs/xadf.md#minimal-installation).

I might also have already a custom dotfiles repository meant to be managed by bare git and alias method, and I want `xadf` to clone and manage them.

```bash
# skip this if you already have it configured
xadf --minimal-install

# Clone from my custom dotfiles repository
xadf -i -s git@gitlab.com:heno72/xadf-gb.git --seat ~/.dotfiles

# Source ~/.bashrc to load the new configuration
. ~/.bashrc

# Check the status of my repository
xadf status -sb
```

Suppose, you already have one existing bare git repository at `~/.dotfiles` managed with an alias as in vanilla bare git and alias method. After installing xadf with `xadf --minimal-install`, you want to manage your existing bare git repository with `xadf` instead of your own alias. In that case, you can [configure xadf to manage the custom git directory](docs/xadf.md#custom-installation) with:

```bash
xadf --custom-install --seat ~/.dotfiles
. ~/.bashrc
```
