#!/bin/bash
# This is just a quick function I use to see the progress of extraction
# in casper folder, of file filesystem.squashfs, while issuing the command:
# sudo 7z x xubuntu-22.04.1-desktop-amd64.iso -o/path/to/fat32/ubuntu/live/usb
squashcheck(){
echo "Checker is active, put some rudimentary checks."
string=$(ls -l filesystem.squashfs)
echo $string
echo Current filesize is ${string:26:11} bit
lastsize="${string:26:11}"
echo "Executing loops"

while :
do
  string=$(ls -l filesystem.squashfs)
  if [[ ${string:26:11} = 2271723520 ]]
  then
    break
  fi
  if [[ "$lastsize" != "${string:26:11}" ]]
  then
    echo $string
    bps=$(echo " (${string:26:11} - $lastsize)/5 " | bc -q)
    prog=$(echo "scale=2; 100*${string:26:11}/2271723520"|bc -lq)
    echo "Average speed is $bps bit/s, progress is $prog %"
    sleep 5s
    lastsize="${string:26:11}"
  fi
done
}
