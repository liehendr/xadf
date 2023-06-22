#!/bin/bash
## This function makes qr code of text $2, then it
## displays the resulting qrcode.
function qrquick
{
  if [ $# -eq 2 ]; then
    qrencode -s 12 -m 1 -o $1.png "$2";
    display $1.png
  else
    echo "usage: qrquick <output> <text>"
  fi
}

