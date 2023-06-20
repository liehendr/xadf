#!/bin/bash

## ssl encryption function

function ssl-encrypt
{
  if [ $# -eq 2 ]; then
    openssl enc -aes-256-cbc -a -salt -in $1 -out $2
  else
    echo "usage: ssl-encrypt <source> <destination>"
  fi
}

function ssl-decrypt
{
  if [ $# -eq 2 ]; then
    openssl enc -aes-256-cbc -d -a -in $1 -out $2
  else
    echo "usage: ssl-decrypt <source> <destination>"
  fi
}
