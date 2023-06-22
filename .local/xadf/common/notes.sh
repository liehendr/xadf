#!/bin/bash
## A very useful notetaking function that stores notes in ~/.notes
## Obtained from https://unix.stackexchange.com/a/59979/282465
# To make the code compatible for both zsh and bash
type emulate >/dev/null 2>/dev/null || alias emulate=true

# If ~/.notes does not exist, create one
test ! -d ~/.notes && mkdir ~/.notes

# Notetaking function. To use:
#   n file ...
# Can be any number of files
function n() {
  emulate -L ksh
  local arg; typeset -a files
  for arg; do files+=( ~/".notes/$arg" ); done
  ${EDITOR:-nano} "${files[@]}" 
}

## A compliment of above, list contents of our note storage
function nls() {
  tree -CRl --noreport $HOME/.notes | awk '{
      if (NF==1) print $1; 
      else if (NF==2) print $2; 
      else if (NF==4) print $2;
      else if (NF==3) printf "  %s\n", $3 
    }'
}
