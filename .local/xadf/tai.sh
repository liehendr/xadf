#!/bin/sh

tai_1(){
# The following part is obtained from https://serverfault.com/a/812163/989389
echo "The ../leaps/UTC methods:"
echo -n "UTC:   "; TZ='UTC' date
echo -n "GPS:   "; TZ='UTC' date --date='TZ="../leaps/UTC" now -9 seconds'
echo -n "LORAN: "; TZ='UTC' date --date='TZ="../leaps/UTC" now'
echo -n "TAI:   "; TZ='UTC' date --date='TZ="../leaps/UTC" now 10 seconds'
}

tai_2(){
# Meanwhile, this one is adjusted because we don't have that ../leaps/UTC
# part. Also I have to adjusted the values slightly so it fits with this
# page: http://www.leapsecond.com/java/gpsclock.htm
echo "The right/UTC methods:"
echo -n "UTC:   "; TZ='UTC' date
# GPS is always 19 seconds behind TAI
echo -n "GPS:   "; TZ='UTC' date --date='TZ="right/UTC" now 18 seconds'
echo -n "LORAN: "; TZ='UTC' date --date='TZ="right/UTC" now 27 seconds'
# At least until 28 June 2023, this TAI offset is still valid
echo -n "TAI:   "; TZ='UTC' date --date='TZ="right/UTC" now 37 seconds'
}

tai_1_loop(){
while :
do
  clear
  tai_1
  sleep 1s
done
}

tai_2_loop(){
while :
do
  clear
  tai_2
  sleep 1s
done
}

case $1:$2 in
  first:"")
    tai_1
    ;;
  second:"")
    tai_2
    ;;
  first:loop)
    tai_1_loop
    ;;
  second:loop)
    tai_2_loop
    ;;
  *)
    tai_2
    ;;
esac
