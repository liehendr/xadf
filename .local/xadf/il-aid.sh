#!/bin/bash
# il helper (il-aid)
# The goal of these functions are to help il function

# igstager is a function to stage special stack
# contents into file tdl
igstager () {
  unset tdl
  for t in alpha beta gamma
  do
      stack cp $t tdl
  done
  stack write tdl $ig/tdl
}

# igsr is a convenience script for my purpose
igsr () {
  unset igs
  for t in alpha beta gamma
  do
      stack cp $t igs
  done
  stack write igs tdl_$(date +%y%m%d.%H%M).txt
}

# Prevents accidents, save only to igs
igsave(){
  stack save igs
  stack ls x
}

# Prevents accidents, load only from igs
igload(){
  stack load igs
  stack ls x
}

# ilaset will configure convenience aliases
# for working with sorting profiles
declare -A ilavar
ilavar=(
p popin
i 'lto input'
a 'lto alpha'
b 'lto beta'
g 'lto gamma'
t 'lto trash'
x 'stack ls x'
)

ilaset(){
test -z "$1" && local set="on" || local set="$1"

if [[ "$set" == "on" ]]
then
  for i in ${!ilavar[@]}
  do eval "$i(){ "${ilavar[$i]}" ;}"
  done
elif [[ "$set" == "off" ]]
then
  for i in ${!ilavar[@]}
  do unset -f $i
  done
elif [[ "$set" == "test" ]]
then
  for i in ${!ilavar[@]}
  do
    type $i 2>&1 > /dev/null
    test $? -eq 0 && echo "$i OK" || echo "$i FAIL"
  done
else
  echo "unknown argument: $1"
fi
}
