#!/bin/bash
# Reads stack [$1] and unpack its contents to stack [$2]
stack.unpack(){
local source=$1
local output=$2
local setifs=$3
[ "$setifs" == "" ] && setifs=" "
[ "$output" == "" ] && output="tmp"
if [ "$source" == "" ]
then
  echoerr "Error, no source is specified!"
else
  IFS="$setifs" eval "read -r -a $output" <<< $(print $source)
  echo "Last value of Stack [$source] is unpacked to Stack [$output]"
fi
}

