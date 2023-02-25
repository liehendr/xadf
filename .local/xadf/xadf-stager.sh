#!/bin/bash

# stager <source> <target>
gitstager(){
local source="$1" && test -z "$1" && local source="trunk"
local target="$2" && test -z "$2" && local target="master"

if [ ! -f ".git/config" ]
then
  echo "Not in a git repo!" >&2
  # exit 1
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

xadf_check_ver_config(){
# check version config file
# If none, scream
# If there is one, read then write
# But increment minor ver by 1
if test ! -f ~/.config/xadf/xadf_devel.cfg
then
  export xadfcommit_bad_states=1
else
  . ~/.config/xadf/xadf_devel.cfg
  cat << EOF > ~/.config/xadf/xadf_devel.cfg
xadf_major_ver='$xadf_major_ver'
xadf_minor_ver='$((++xadf_minor_ver))'
EOF
fi
}

# Check if xadf is modified
# If it is, add to variable
xadf_check_modified(){
unset xadf_is_modified git_xadf_path
xadf_is_modified=$(git status -s|grep xadf$|sed 's_...__')
if test -z "$xadf_is_modified"
then
  printf >&2 "xadf is not modified\n"
  export xadfcommit_bad_states=1
else
  export git_xadf_path=$(realpath ${xadf_is_modified})
fi
}

xadf_commit_append_version(){
# Check if label is given
# If yes, do long form
# If none, do short form
xadf_version_only="${xadf_major_ver}\.${xadf_minor_ver}\.$(date +%Y%m%d\.%H%M)"

if test -z "$xadf_version_label"
then
  xadf_version_full="${xadf_version_only}"
else
  xadf_version_full="${xadf_version_only}+${xadf_version_label}"
fi

unset xadf_version_label

sed -i -e 's#^version=.*$#version=DUMMYVER#' \
    -e "s#DUMMYVER#${xadf_version_full}#" "${git_xadf_path}"
}

xadf_safe_commit(){
${git_xadf_path} -v
if test $? -gt 0
then
  printf >&2 "WARNING! Malformed executable '%s'\n" "${git_xadf_path}"
else
  git add ${xadf_is_modified}
  git commit
fi
}

xadfcommit(){
# Safety feature, if 1 then abort at execution
export xadfcommit_bad_states=0

# Parse arguments and call functions
# If -L/--label is given, parse label

while :;
do
  case $1 in
    -L | --label )
      if test -z "$2"
      then
        printf >&2 "WARNING! No label given\n"
        export xadfcommit_bad_states=1
        break
      else
        xadf_version_label="$2"
        shift 2
      fi
      ;;
    "" )
      break
      ;;
    * )
      printf >&2 "WARNING! Unknown argument '%s'\n" "$1"
      export xadfcommit_bad_states=1
      break
      ;;
  esac
done

# Protective measures, to only run if state is good
if test $xadfcommit_bad_states -eq 0
then xadf_check_ver_config ; fi

if test $xadfcommit_bad_states -eq 0
then xadf_check_modified ; fi

if test $xadfcommit_bad_states -eq 0
then xadf_commit_append_version; fi

if test $xadfcommit_bad_states -eq 0
then xadf_safe_commit; fi
}