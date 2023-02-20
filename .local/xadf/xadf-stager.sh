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

# Takes two arguments: gitbot <route> <base>
# If only one argument, take it as <route>, and <base> is assumed 'development'
# If no argument is given, take <route> as $xadfconfig/gitroutes.txt
# If <route> does not exist, copy from $xadfmods/templates/default-gitroutes.txt
#
# Warning, improver use of these tools might ruin your git history!
#
gitbot(){
# Configure variables and fallback condition
local route="$1" && test -z "$1" && local route="$xadfconfig/gitroutes.txt"
local base="$2" && test -z "$2" && local base="development"

# first let's refresh $base and resolve any conflicts
git checkout $base
git pull
git push

# Then perform the magic
if test ! -f $route
then
  cp $xadfmods/templates/default-gitroutes.txt $route
else
  test -f $route && . $route
fi

# Return to $base
git checkout $base
}
