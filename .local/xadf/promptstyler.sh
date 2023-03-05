#!/bin/bash
# A part of xadf dotfiles repository
# Copyright 2023, Hendrik Lie, licensed under GPLv3
# See branch master for LICENSE

# A collection of prompts

# Archlinux style
# PS1='[\u@\h \W]\$ '

# ??
# PS1='[\[\e]0;\u@\h \W]\a\]\$ '

# Ubuntu (colored) style
# PS1="\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ "

# Ubuntu (not sure where) style
# PS1="\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "

## From old xadf
## This one looks like: 'user@hostname:~$'
# PS1="\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ "
## This one looks like: '~$'
# PS1="\[\e[0;32m\]\w\[\e[0m\] \[\e[0;97m\]$\[\e[0m\] "

# Ubuntu (under kitty)
# PS1="\[\e]133;k;start_kitty\a\]\[\e]133;A\a\]\[\e]133;k;end_kitty\a\]\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ \[\e]133;k;start_suffix_kitty\a\]\[\e[5 q\]\[\e]2;\w\a\]\[\e]133;k;end_suffix_kitty\a\]"

# Active prompt style in container image 'archlinux-latest':
# PS1="\[\e]0;\u@\h: \w\a\]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ "

# Obtained from https://unix.stackexchange.com/a/31697/282465
# But there is a similar one at https://askubuntu.com/a/670600/126560
# color names for readibility
reset=$(tput sgr0)
bold=$(tput bold)
black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
spacedust=$(tput setaf 246)

# Now we want to filter the kinds of operating system we're on
test -f /etc/os-release && xadf_distro_name=$(grep ^NAME /etc/os-release|sed 's_^NAME=__;s_\"__g')

# Prompts, different style of (as an associative array)
declare -A xadf_prompt
xadf_prompt[arch]="\[$reset\]\[$cyan\][\[$bold\]\[$user_color\]\u@\h\\[$reset\]\[$blue\]\[$bold\] \W\[$reset\]\[$cyan\]]\\$\[$reset\] "
xadf_prompt[arch_plain]='[\u@\h \W]\$ '
xadf_prompt[fedora]="\[$reset\]\[$cyan\][\[$user_color\]\u@\h\\[$reset\]\[$blue\] \W\[$reset\]\[$cyan\]]\\$\[$reset\] "
xadf_prompt[termux]="\[\e[0;32m\]\w\[\e[0m\] \[\e[0;97m\]$\[\e[0m\] "
xadf_prompt[termux_terse]="\[\e[0;32m\]\W\[\e[0m\] \[\e[0;97m\]$\[\e[0m\] "
xadf_prompt[ubuntu]="\[$reset\]\[$user_color\]\[$bold\]\u@\h\[$reset\]:\[$blue\]\[$bold\]\w\[$reset\]\\$ "
xadf_prompt[ubuntu_default]="\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "

psmod(){
local style
style="$1"

case $style in
  --help|-h)
    printf "Commands:\n\n"
    printf "    psmod <style>\t\tset style to <style>\n"
    printf "    psmod --list/-l\t\tlist styles\n"
    printf "    psmod --help/-h\t\tshow this help text\n\n"
    ;;
  --list|-l)
    printf "Existing prompt styles:\n\n"
    for i in ${!xadf_prompt[@]}
    do
      printf " --> %s\n" "$i"
    done
    printf "\nTo select a prompt style:\n"
    printf "  psmod <style>\n\n"
    ;;
  "")
    printf >&2 "No arguments! See 'psmod --help'\n\n"
    ;;
  *)
    if [[ -n "${xadf_prompt[$style]}" ]]
    then
      unset PS1 && export PS1="${xadf_prompt[$style]}"
    else
      printf >&2 "Specified style does not exist! See 'psmod --list' for list of styles\n\n"
    fi
    ;;
esac
}

promptstyler(){
test -n "$1" && verbosity="$1"

if [ -z "$xadf_distro_name" ] # most probably running termux
then
    # Testing if it is termux
    if command -v termux-setup-storage > /dev/null
    then
        test "$verbosity" = "v" && echo "In Termux"
        unset PS1 user_color
        export PS1="${xadf_prompt[termux]}"
    fi
elif [[ "$xadf_distro_name" == "Arch Linux" ]]
then # Most likely in Arch
    test "$verbosity" = "v" && echo "In Arch"
    unset PS1 user_color
    export user_color=$cyan
    export PS1="${xadf_prompt[arch]}"
elif [[ "$xadf_distro_name" == "Fedora Linux" ]]
then # Most likely in Fedora
    test "$verbosity" = "v" && echo "In Fedora"
    unset PS1 user_color
    export user_color=$magenta
    export PS1="${xadf_prompt[fedora]}"
elif [[ "$xadf_distro_name" == "Ubuntu" ]]
then # Most likely in Ubuntu
    test "$verbosity" = "v" && echo "In Ubuntu"
    unset PS1
    user_color=$spacedust
    PS1="${xadf_prompt[ubuntu_default]}"
else # We are not sure which linux are we running on
    test "$verbosity" = "v" && echo "Not sure where"
    unset PS1 user_color
    export user_color=$spacedust
    export PS1="${xadf_prompt[arch_plain]}"
fi
}
