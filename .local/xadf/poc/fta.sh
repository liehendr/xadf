#!/bin/bash
# Proof of concept on listing a content of a directory to an array
# Copy obtained from:
# https://www.cyberciti.biz/tips/handling-filenames-with-spaces-in-bash.html

# Get files in $DIR into fileArray
file2var(){
#TGT="$1"
#DIR="$2"
DIR="$1"

# failsafe, fallback to input
#[ "$TGT" == "" ] && TGT="input"

# failsafe - fall back to current directory
[ "$DIR" == "" ] && DIR="."

# save old ifs
oldifs="$IFS"

# set a new ifs
IFS=$'\n'

# expand files in target dir to an array
fileArray=($(find $DIR -type f))

# restores old ifs
IFS="$oldifs"
}

# Get directories in $DIR into dirArray
dir2var(){
#TGT="$1"
#DIR="$2"
DIR="$1"

# failsafe, fallback to input
#[ "$TGT" == "" ] && TGT="input"

# failsafe - fall back to current directory
[ "$DIR" == "" ] && DIR="."

# save old ifs
oldifs="$IFS"

# set a new ifs
IFS=$'\n'

# expand directories in target dir to an array
dirArray=($(find $DIR -type d))

# restores old ifs
IFS="$oldifs"
}

# Get the content of the array and do some work to it
fileArrayjob(){
# get length of an array
#tLen=$(eval echo \${#$TGT[@]})
tLen=${#fileArray[@]}

# use for loop read all filenames
for (( i=0; i<${tLen}; i++ ));
do
  echo "${fileArray[$i]}"
done
}

dirArrayjob(){
# get length of an array
#tLen=$(eval echo \${#$TGT[@]})
tLen=${#dirArray[@]}

# use for loop read all filenames
for (( i=0; i<${tLen}; i++ ));
do
  echo "${dirArray[$i]}"
done
}

ftatest(){
file2var $@
fileArrayjob
}

dtatest(){
dir2var $@
dirArrayjob
}
