#!/bin/bash
########################################################################
## igdl specifics
########################################################################
## This function remove pattern $2 from file $1
function rmfrlist
{
  if [ $# -eq 2 ]; then
    ## remove pattern $2 from file $1
    cat "$1" | grep -v "$2" > tmp.txt
    ## Overwriting the original file with filtered file
    cat tmp.txt > "$1"
    rm tmp.txt
  else
    echo "usage: rmfrlist <file> <pattern>"
    echo "For example, to remove any trace of tawan_v from file randomlist:"
    echo "~$ rmfrlist randomlist tawan_v"
  fi
}
