#!/bin/bash

# A useful bash alias, found this from AskUbuntu: https://askubuntu.com/a/749207/126560
# Use:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && (echo terminal; exit 0) || (echo error; exit 1))" "$([ $? = 0 ] && echo Task finished || echo Something went wrong!)" "$(history | sed -n "\$s/^\s*[0-9]\+\s*\(.*\)[;&|]\s*alert\$/\1/p")"'

# I use this command often, so might as well alias it
alias rs='rsync -artvcis --progress'

# A useful git alias to display all tracked files, or you can specify a specific dir or file in the repo tree
alias gitls='git ls-tree --full-tree -r --name-only HEAD'
