#!/bin/bash

## Specific functions to get user agents from our server

uaput(){
case $1 in
"")
  target=ytua
  ;;
*)
  target=$1
  ;;
esac

ftp ftp.xenomancy.id <<EOF
cd xenoagents/agents
put $target
bye
EOF
}

uaget(){
case $1 in
"")
  target=ytua
  ;;
*)
  target=$1
  ;;
esac

ftp ftp.xenomancy.id <<EOF
cd xenoagents/agents
get $target
bye
EOF
}


