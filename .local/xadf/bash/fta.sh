#!/bin/bash
# Proof of concept on listing a content of a directory to an array
# Copy obtained from:
# https://www.cyberciti.biz/tips/handling-filenames-with-spaces-in-bash.html

# Get files in $DIR into stack [$TGT]
fta(){
DIR="$1"
TGT="$2"

# failsafe - fall back to current directory
[ "$DIR" == "" ] && DIR="."
# failsafe, fallback to input
[ "$TGT" == "" ] && TGT="input"

# save old ifs
oldifs="$IFS"

# set a new ifs
IFS=$'\n'

# expand files in target dir to an array
eval "$TGT=(\$(find \$DIR -type f))"

# restores old ifs
IFS="$oldifs"
}

# Get directories in $DIR into stack [$TGT]
dta(){
DIR="$1"
TGT="$2"

# failsafe - fall back to current directory
[ "$DIR" == "" ] && DIR="."
# failsafe, fallback to input
[ "$TGT" == "" ] && TGT="input"

# save old ifs
oldifs="$IFS"

# set a new ifs
IFS=$'\n'

# expand directories in target dir to an array
eval "$TGT=(\$(find \$DIR -type d))"

# restores old ifs
IFS="$oldifs"
}
