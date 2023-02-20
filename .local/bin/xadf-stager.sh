#!/bin/bash

# stager <source> <target>
gitstager(){
test -z "$1" && local source="trunk"
test -z "$2" && local target="master"

if [ ! -f ".git/config" ]
then
  echo "Not in a git repo!" >&2
  exit 1
else
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
