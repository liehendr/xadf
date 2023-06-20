#/bin/bash
############################################
#  bash script:	verinsius.sh
#  author:	Hendrik Lie
#  e-mail:	hendriklie72@gmail.com
#  comments:	- published under the GPL
# A company for verinsius.bc, where we demonstrates how to use the file in a
# bash script
############################################

# bc dir
bcd="$HOME/.local/share/bc"

bcvr(){
bc -lq $bcd/verinsius.bc $@
}

calcbc(){
echo "$@"|bcvr
}

demo(){
# store the value of current system time as cl timestamp in sternus
etos_stamp=$(calcbc "unix2etos($(date +%s))")

# convert the value we stored before back to unix time, and display it as a
# formatted date time
date -d @$(calcbc "etos2unix($etos_stamp)")
}

cl2unix(){
# converts CL notation to datetime string
unix=$(calcbc "cl2unix($1)")
date -d @"$unix" +'%Y-%m-%d %T %z'
}

unix2cl(){
# converts datetime string to CL notation
# calcbc "unix2cl($(date -d "$@" +%s))"
unix="$(date -d "$@" +%s)"
cl=$(calcbc "scale=8;unix2cl($unix)")
echo $cl
}

unix2ask(){
# converts datetime string to Askitos Format
unix="$(date -d "$@" +%s)"
cls=$(calcbc "scale=8;unix2cl($unix)")
ask=$(calcbc "scale=0;(${cls:6:4}/25)+1000")
jdn=$(calcbc "((${cls:6:4}/25)-${ask:1:3})*25+100")
drj=$(calcbc "scale=0;(${cls:10:5}/2)+10000")
echo "${cls:0:5}-${ask:1:3}-${jdn:1:2} ${drj:1:4}"
}

ask2unix(){
# Converts askitos format into cl format
# like 67552-110-11 1792 to 67552.27613585
# Then use that to convert back to unix with cl2unix
local askf="$@"
local len=${#askitos}
drj=${askf:(($len-4))}
jdn=${askf:(($len-7)):2}
ask=${askf:(($len-11)):3}
vrs=${askf:0:(($len-12))}
cls=$(calcbc "scale=8;$drj*2*10^-8+$jdn*10^-4+$ask*25*10^-4+$vrs")
cl2unix "$cls"
}

ask2cl() 
{ 
local askf="$@";
local len=${#askitos};
drj=${askf:(($len-4))};
jdn=${askf:(($len-7)):2};
ask=${askf:(($len-11)):3};
vrs=${askf:0:(($len-12))};
cls=$(calcbc "scale=8;$drj*2*10^-8+$jdn*10^-4+$ask*25*10^-4+$vrs");
echo $cls
}

cl2ask(){
# converts CL notation to Askitos Format
local cls="$@"
ask=$(calcbc "scale=0;(${cls:6:4}/25)+1000")
jdn=$(calcbc "((${cls:6:4}/25)-${ask:1:3})*25+100")
drj=$(calcbc "scale=0;(${cls:10:5}/2)+10000")
echo "${cls:0:5}-${ask:1:3}-${jdn:1:2} ${drj:1:4}"
}

clconv(){
case $1 in
demo)
  demo
  ;;
cl2unix)
  cl2unix "$2"
  ;;
unix2cl)
  unix2cl "$2"
  ;;
*)
  demo
  ;;
esac
}

################################################################################
# Some fun perks: terminal clock that autorefreshes every 1 second, while
# displaying Etoan time.
################################################################################

clclock_zero(){
# Other than normal dates, will also print CL timestamps
# Requires verinsius.sh and verinsius.bc to be present in the environment
# and is loaded in recipe.txt
# GPS is always 19 seconds behind TAI
# At least until 28 June 2023, this TAI offset is still valid
set_clt
set_mct
clear
cat <<EOF
+--------------------------------------+
|[ Human Date and Time                ]|
+--------------------------------------+
| PC:    $datepc
| UTC:   $dateutc
| GPS:   $dategps
| LORAN: $dateloran
| TAI:   $datetai
+--------------------------------------+
|[ Etoan Date and Time                ]|
+--------------------------------------+
| Verinsius:      $cls CL
| Askitos Format: ${cls:0:5}-${ask:1:3}-${jdn:1:2} ${drj:1:4}
+--------------------------------------+
EOF
}

clclock_one(){
# Only shows normal scale
set_clt
clear
cat <<EOF
Verinsius: $cls CL
EOF
}

clclock_two(){
# Shows normal scale and a fancy framed scale
set_clt
clear
cat <<EOF

     +---------------+
     |+[[  ${cls:0:5}  ]]+|
     |+[[  ${cls:5:5}  ]]+|
     |+[[   ${cls:10:5}  ]]+|
     +---------------+

EOF
}

clclock_three(){
# Shows CL stamp to 4 decimal places, and show Derajat values
set_clt
clear
cat <<EOF

     +---------------+
     |+[ ${cls:0:5} CL  ]+|
     |+[ ${cls:5:5}     ]+|
     |+[  ${drj:1:4} drj ]+|
     +---------------+

EOF
}

clclock_four(){
# Shows CL stamp to 4 decimal places, and show Derajat values
# Also shows Askitos and Jadan
set_clt
clear
cat <<EOF

   +-------------------+
   |+[ ${cls:0:10} CL ]+|
   +-------------------+
   |+[ Askitos:  ${ask:1:3} ]+|
   |+[ Jadan  :   ${jdn:1:2} ]+|
   |+[ Derajat: ${drj:1:4} ]+|
   +-------------------+

EOF
}

clclock_five(){
# Shows CL stamp to 4 decimal places, and in Year-ASK-JD format
# Also shows Derajat
set_clt
clear
cat <<EOF

   +-------------------+
   |+[ ${cls:0:10} CL ]+|
   +-------------------+
   |+[ ${cls:0:5}-${ask:1:3}-${jdn:1:2}  ]+|
   |+[ Derajat: ${drj:1:4} ]+|
   +-------------------+

EOF
}

clclock_six(){
# Shows CL stamp to 4 decimal places, a space, and 5th-8th decimal places
# Show time in Year-ASK-JD format
# Also shows Derajat
set_clt
clear
cat <<EOF

   +-----------------------+
   |+[ ${cls:0:14} CL ]+|
   +-----------------------+
   |+[ ${cls:0:5}-${ask:1:3}-${jdn:1:2} ${drj:1:4} ]+|
   +-----------------------+

EOF
}

clclock_human(){
set_clt
set_mct
clear
cat <<EOF
+--------------------------------------+
|[ Human Date and Time                ]|
+--------------------------------------+
| PC:    $datepc
| UTC:   $dateutc
| GPS:   $dategps
| LORAN: $dateloran
| TAI:   $datetai
+--------------------------------------+
EOF
}

clclock_etoan(){
# Shows CL stamp to 4 decimal places, a space, and 5th-8th decimal places
# Show time in Year-ASK-JD format
# Also shows Derajat
set_clt
clear
cat <<EOF
+--------------------------------------+
|[ Etoan Date and Time                ]|
+--------------------------------------+
| Verinsius:      $cls CL
| Askitos Format: ${cls:0:5}-${ask:1:3}-${jdn:1:2} ${drj:1:4}
+--------------------------------------+
EOF
}

clclock_seven(){
set_clt
clear
cat <<EOF
Verinsius:      $cls CL
Askitos Format: ${cls:0:5}-${ask:1:3}-${jdn:1:2} ${drj:1:4}
EOF
}

clclock_eight(){
set_clt
set_mct
clear
cat <<EOF
PC:             $datepc
Verinsius:      $cls CL
Askitos Format: ${cls:0:5}-${ask:1:3}-${jdn:1:2} ${drj:1:4}
EOF
}

clclock_nine(){
set_clt
clclock_timer="0.1s"
printf "\rVerinsius: $cls CL"
}

clclock_ten(){
set_clt
clclock_timer="0.1s"
printf "\rAskitos Format: ${cls:0:5}-${ask:1:3}-${jdn:1:2} ${drj:1:4}"
}

clclock_eleven(){
set_clt
clclock_timer="0.1s"
printf "\r# $cls CL"
}

clclock_twelve(){
set_clt
clclock_timer="0.1s"
printf "\r# ${cls:0:5}-${ask:1:3}-${jdn:1:2} ${drj:1:4}"
}

clclock_thirteen(){
set_mct
clclock_timer="0.1s"
printf "\r#TAI: $datetai"
}

clclock_fourteen(){
set_mct
clclock_timer="0.1s"
printf "\r#PC: $datepc"
}

set_clt(){
# Set verinsius time
cls=$(unix2cl 'now 37 seconds')
ask=$(calcbc "scale=0;(${cls:6:4}/25)+1000")
jdn=$(calcbc "((${cls:6:4}/25)-${ask:1:3})*25+100")
drj=$(calcbc "scale=0;(${cls:10:5}/2)+10000")
}

set_mct(){
# Set human time
formatdate="%Y-%m-%d %T %z"
datepc="$(date +"$formatdate")"
dateutc="$(TZ='UTC' date +"$formatdate")"
dategps="$(TZ='UTC' date --date='TZ="right/UTC" now 18 seconds' +"$formatdate")"
dateloran="$(TZ='UTC' date --date='TZ="right/UTC" now 27 seconds' +"$formatdate")"
datetai="$(TZ='UTC' date --date='TZ="right/UTC" now 37 seconds' +"$formatdate")"
}

clclock(){
clclock_timer="1s"
while :
do
  case $1 in
  zero)
    clclock_zero
    ;;
  one)
    clclock_one
    ;;
  '')
    clclock_two
    ;;
  *)
    eval "clclock_$1"
    ;;
  esac
  sleep $clclock_timer
done
}

cls_loop(){
while :
do
  clear
  clstamp
  sleep 1s
done
}

