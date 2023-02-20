#!/bin/bash

# stager <source> <target>
gitstager(){
local source="$1" && test -z "$1" && local source="trunk"
local target="$2" && test -z "$2" && local target="master"

if [ ! -f ".git/config" ]
then
  echo "Not in a git repo!" >&2
  exit 1
else
  printf "checkout '%s'..." "$target"
  printf "merge '%s'" "$source"
  git checkout $target && \
  git pull && \
  git merge $source && \
  git push
fi
}

git checkout development

gitstager development trunk
gitstager trunk master
gitstager trunk termux

git checkout development
