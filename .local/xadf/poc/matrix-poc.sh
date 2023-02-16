#!/bin/bash
# Obtained from: https://stackoverflow.com/a/36145882/12571203
# Proof of concept on expanding multiple valued variables into an array

# Init a 4x5 matrix
a=("00 01 02 03 04" "10 11 12 13 14" "20 21 22 23 24" "30 31 32 33 34")
# Init a 4x5 matrix with comma as delimiters
b=("00,01,02,03,04" "10,11,12,13,14" "20,21,22,23,24" "30,31,32,33,34")

aset() {
  row=$1
  col=$2
  value=$3
  IFS=' ' read -r -a tmp <<< "${a[$row]}"
  tmp[$col]=$value
  a[$row]="${tmp[@]}"
}

# Set a[2][3] = 9999
aset 2 3 9999

# Show result
for r in "${a[@]}"; do
  echo $r
done

aread(){
  row=$1
  IFS=' ' read -r -a tmp <<< "${a[$row]}"
}

aread 3

stack.ls l tmp

## This does not work because IFS is not a whitespace
bset() {
  row=$1
  col=$2
  value=$3
  IFS=',' read -r -a tmp <<< "${b[$row]}"
  tmp[$col]=$value
  b[$row]="${tmp[@]}"
}

# Set b[2][3] = 88
bset 2 3 88

# Show result
for r in "${b[@]}"; do
  echo $r
done

bread(){
  row=$1
  IFS=',' read -r -a tmp <<< "${b[$row]}"
}

bread 3

stack.ls l tmp

# Reads stack [$1] and unpack its contents to stack [tmp]
stack.unpack(){
target=$1
setifs=$2
[ "$setifs" == "" ] && setifs=" "
if [ "$target" == "" ]
then
  echoerr "Error, no target is specified!"
else
  IFS="$setifs" read -r -a tmp <<< $(print $target)
fi
}

