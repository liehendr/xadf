#!/bin/bash
# Should operate in "~/Pictures/gallery-dl/twitter"
# Note that it fails horribly for twitter accounts that starts with numbers, as
# bash variables can not start with a number

twarx_load(){
source $xadf/custom/poc/extract-twarx.sh
}

# Get contents of folder $1 into an array named $1
twarx_getf(){
fileArray="$1"

# remove previously created file meta.dl in $1
if [ -f "$fileArray/convert.do" ]
then
  rm "$fileArray/convert.do"
fi

# remove previously created file meta.dl in $1 if it exists
if [ -f "$fileArray/meta.dl" ]
then
  rm "$fileArray/meta.dl"
fi

# Produce an array of files
eval "unset \"$fileArray\""
oldifs="$IFS"
IFS=$'\n'
eval "$fileArray=(\$(find \"$fileArray\" -type f))"
height $fileArray
push alpha "getf,$(height t $fileArray),$fileArray"
IFS="$oldifs"
}

twarx_transf(){
#unset QUE
#stack.cp $1 QUE
twarx_target="$1"
# This function does not alter stack $1
# This performs the following specific functions:
# 1. get value of variable $1[@],
# 2. truncating the first ${#twarx_target}+1 characters,
# 3. replace the resultant truncated string's beginning with:
#    twitter_$twarx_target_
# In short, they replaced a string that would look like this:
# > chimmieez/1599005906250788865_1.mp4.json
# ino a string that look like this:
# > twitter_chimmieez_1599005906250788865_1.mp4.json

eval "unset transf_$twarx_target"

# Do the thing
for i in $(eval echo \${!$twarx_target[@]})
do
  trans_tgt=$(\
  eval "echo \${$twarx_target[$i]:\${#twarx_target}+1}" |\
  eval "sed 's/^/${twarx_target}\/twitter_${twarx_target}_/'"\
  )
  eval push transf_$twarx_target \"mv \${$twarx_target[$i]} $trans_tgt\" \
  > /dev/null
done

eval height transf_$twarx_target
push beta "transf,$(eval "height t transf_$twarx_target"),$twarx_target"

# write contents to convert.do
eval "stack.write transf_$twarx_target $twarx_target/convert.do"

# To actually execute them:
# $(eval "print transf_$1")
# eval "pop transf_$1"
}

twarx_getl(){
#unset QUE
#stack.cp $1 QUE
twarx_target="$1"
# This function does not alter stack $1
# This performs the following specific functions to get the value of var heyo:
# 1. unset variable link_$1
# 2. for every i in indices of stack $1,
#    a. get the string of stack $1 index $i into var $string
#    b. get the tail of var $string by removing the first n+1 characters, where
#       n is the length of $1, then store it to var $twtail
#    c. get the first 19 characters of string $twtail and store it in var $twid
#    d. use $1 and $twid to construct a link with the following format:
#       https://twitter.com/<$1>/status/<$twid> and store it in var $twlink
#    e. push $twlink to stack link_$1
# 3. display the height of stack link_$1

eval unset link_$twarx_target

# Do the thing
for i in $(eval echo \${!$twarx_target[@]})
do
  string="$(eval echo \${$twarx_target[$i]})"
  twtail=`echo ${string:${#twarx_target}+1}`
  twid=`echo ${twtail:0:19}`
  twlink="https://twitter.com/$twarx_target/status/$twid"
  eval push link_$twarx_target \"$twlink\" \
  > /dev/null
done

# eval height link_$twarx_target

# print to file, then reload the file back to stack
eval "stack.ls t link_$twarx_target | sort -u > $twarx_target/meta.dl"
eval "unset link_$twarx_target"
eval "stack.read $twarx_target/meta.dl link_$twarx_target"
push gamma "getl,$(eval "height t link_$twarx_target"),$twarx_target"

}

twarx_convert(){
# Convert contents of folder $1 from old filename format to new filename format.
# 1. Get the contents of $1 in an array $1
# 2. Get commands to move old filename format to new filename format, and store
#    them on array transf_$1
# 3. Get links of contents inside $1, and store them on array link_$1
# 4. 
twarx_getf "$1"
getf=$?
twarx_getl "$1"
getl=$?
twarx_transf "$1"
transf=$?
echo "getf exit status: $getf"
echo "getl exit status: $getl"
echo "transf exit status: $transf"
push error "$1,$getf,$getl,$transf"
# echo "This folder contains contents of the following posts:"
# cat "$1/meta.dl"
# echo "This folder has already or will be converted to the following:"
# cat "$1/convert.do"
}

twarx_getd(){
OLDIFS="$IFS" # saves old IFS

IFS=$'\n' # change IFS to newline
for f in $(ls)
do
  # convert and obtain $f/meta.dl and $f/convert.do
  if [ -d $f ]
  then
    echo $f
    # twarx_convert $f
  fi
done

IFS="$OLDIFS" # restores IFS
}

twarx_queue(){
unset input
unset alpha
unset beta
unset gamma
unset error
twarx_getd > convert.list
stack.read convert.list input

for i in ${!input[@]}
do
  echo "[twarx_queue]: ${input[$i]}"
  twarx_convert "${input[$i]}"
  # source "${input[$i]}"/convert.do
done

}

twarx_do(){
for i in ${!input[@]}
do
  source ${input[$i]}/convert.do
done
}

twarx_ls(){
unset twlink
for i in ${!input[@]}
do
  # ls ${input[$i]} | grep -v "convert.do\|meta.dl"
  stack.read ${input[$i]}/meta.dl twlink
  # sleep 2s
done
}

################################################################################
## Testbed, to try out new ideas before crafting real functions above
################################################################################

# Get files in $DIR into fileArray
get_files(){
# make sure twfile is empty
flush st_twfile
flush st_twid

DIR="$1"

# failsafe - fall back to current directory
[ "$DIR" == "" ] && DIR="."

export twarx_target="$DIR"

oldifs="$IFS"
IFS=$'\n'

# expand files in target dir to an array
st_twfile=($(find $DIR -type f))
# Expressed like this, we can actually have the array of filenames be of any
# array name we wished.
# testtgt="TargetString"
# eval "$testtgt=(\$(find \$DIR -type f))"

# Show how high st_twfile is
height st_twfile

IFS="$oldifs"
}

# Get twid of item at stack twfile, and pop them
get_twid(){
string="$(print st_twfile)"
pop st_twfile
twtail=`echo ${string:${#twarx_target}+1}`
twid=`echo ${twtail:0:19}`
stackstate="$(print st_twid)"
if [[ "$stackstate" != "$twid" ]]
then
  push st_twid "$twid"
fi
}

get_twid_step(){
  while [ $counter -gt 0 ]
  do
    get_twid
    ((counter--))
  done
}

get_twid_all(){
  counter=$(height t st_twfile)
  echo "Flushing $counter items from st_twfile"
  get_twid_step > /dev/null
}

twarx_id(){
if [ -d $1 ]
then
  echo "[twarx_id]: Getting file list from $1"
  get_files $1 > /dev/null
  get_twid_all > /dev/null
  echo "[twarx_id]: Trimming duplicates"
  stack.ls t st_twid|sort -u > twid_${twarx_target}
  flush st_twid > /dev/null
  echo "[twarx_id]: Presenting results to stack [st_twid]"
  stack.read twid_${twarx_target} st_twid > /dev/null
  height st_twid
else
  echoerr "[twarx_id]: Error, folder $1 does not exist!"
fi
}

twarx_transform(){
flush twarx_trans > /dev/null
echo "\${alpha[3]}: ${alpha[3]}"
# In short, they replaced a string that would look like this:
# > chimmieez/1599005906250788865_1.mp4.json
# ino a string that look like this:
# > chimmieez/twitter_chimmieez_1599005906250788865_1.mp4.json
twarx_trans=$(\
echo ${alpha[3]:${#twarx_target}+1}|\
eval "sed 's/^/${twarx_target}\/twitter_${twarx_target}_/'"\
)
echo "\$twarx_trans: $twarx_trans"
echo "Command to issue:"
echo "mv ${alpha[3]} $twarx_trans"
}

toheyo(){
flush heyo
flush heyotwo
echo "\${alpha[3]}: ${alpha[3]}"
# This performs the following specific functions to get the value of var heyo:
# 1. get value of variable alpha[3],
# 2. truncating the first ${#twarx_target}+1 characters,
# 3. replace the resultant truncated string's beginning with:
#    twitter_$twarx_target_
# In short, they replaced a string that would look like this:
# > chimmieez/1599005906250788865_1.mp4.json
# ino a string that look like this:
# > twitter_chimmieez_1599005906250788865_1.mp4.json
heyo=$(\
echo ${alpha[3]:${#twarx_target}+1}|\
eval "sed 's/^/twitter_${twarx_target}_/'"\
)
echo "\$heyo: $heyo"
# Below's code is similar to above, but instead would transform the string into
# a string like this:
# > chimmieez/twitter_chimmieez_1599005906250788865_1.mp4.json
heyotwo=$(\
echo ${alpha[3]:${#twarx_target}+1}|\
eval "sed 's/^/${twarx_target}\/twitter_${twarx_target}_/'"\
)
echo "\$heyotwo: $heyotwo"

echo "Command to issue:"
echo "move ${alpha[3]} to $heyotwo"
}

# Get Twitter IDs
get_id_poc(){
target="$1"

echo $target

get_files $target

stringtest="$(print fileArray)"

echo $stringtest

# twid=`echo ${stringtest:${#target}+1}|sed 's/_[1-4]\.jpg\.json//'`
# twtail=`echo ${stringtest:${#target}+1}|sed 's/_1\.jpg\.json//;s/_1\.mp4\.json//'`
twtail=`echo ${stringtest:${#target}+1}`

echo $twtail
echo ${#twtail}

twid=`echo ${twtail:0:19}`
echo $twid

}
