#!/bin/bash
########################################################################
## config variables
########################################################################
statedir="$HOME/.local/stack"

########################################################################
## Basic inclusion of useful function(s)
########################################################################

## for error messages
## If loaded from xadf, then these two functions would be present.
#echoerr() { echo "$@" >&2; }
#caterr() { cat "$@" >&2; }

########################################################################
## This section is for core functions:
## push   : to push an item to a stack
## pop    : to pop an item off a stack
## print  : to print the last item pushed without removing it
##          from a stack
## height : to print the height of a stack
## flush  : to reset a stack and remove all existing items
########################################################################

# Push: pushes item $2 to stack $1
# push v <stack> <contents>
# > push to stack and outputs content and target stack
# push t <stack> <contents>
# > push to stack and outputs only target stack
# push q <stack> <contents>
# > push to stack and outputs nothing
# push <stack> <contents>
# > calls push v <stack>
push() {
  case $1 in
    "")
      echoerr "Error: no arguments given!"
    ;;
    v|verbose)
      # outputs message, and push to stack
      echo "Push \"$3\" to stack [$2]"
      push q $2 "$3"
    ;;
    t|terse)
      # outputs message, but terser, and push to stack
      echo "Push to stack [$2]"
      push q $2 "$3"
    ;;
    q|quiet)
      # only push to stack
      if [[ "$3" == "" ]]
      then
        echoerr "Error: no content to push!"
      else
        eval $2[\${#$2[@]}]=\"$3\"
      fi
    ;;
    *)
      # calls push v <stack> <contents>
      push v $1 "$2"
    ;;
  esac
}

# Pop: removes the last item of a stack and print it
# Also pushes the last item popped into stack [last]
# If we use pop v <stack>, will pop verbosely
# If we use pop t <stack>, will pop tersely
# if we use pop <stack>, will use pop verbosely
pop(){
case $1 in
  v|verbose)
    case $2 in
      "")
        # if $2 is empty, throw an error
        echoerr "Error: no stack to pop!"
        ;;
      *) # for all else
        local height=$(eval echo \${#$2[@]})
        if [ $height -gt 0 ] # check if stack is not empty
        then # if it is not empty, pop stack
          echo "Pop stack [$2]"
          echo -n "Value: "
          pop t $2
        else
          echoerr "Stack [$2] is empty"
        fi
    esac
    ;;
  t|terse)
    case $2 in
      "")
        # if $2 is empty, throw an error
        echoerr "Error: no stack to pop!"
        ;;
      *) # for all else
        local height=$(eval echo \${#$2[@]})
        if [ $height -gt 0 ] # check if stack is not empty
        then # if it is not empty, pop stack
          # print last value
          print $2
          # store last value to stack [last]
          push q last "$(print $2)"
          # remove item from stack [$2]
          eval unset $2[-1]
        else
          echoerr "Stack [$2] is empty"
        fi
        ;;
    esac
    ;;
  q|quiet)
    case $2 in
      "")
        # if $2 is empty, throw an error
        echoerr "Error: no stack to pop!"
        ;;
      *) # for all else
        local height=$(eval echo \${#$2[@]})
        if [ $height -gt 0 ] # check if stack is not empty
        then # if it is not empty, pop stack
          # store last value to stack [last]
          push q last "$(print $2)"
          # remove item from stack [$2]
          eval unset $2[-1]
        else
          echoerr "Stack [$2] is empty"
        fi
        ;;
    esac
    ;;
  "")
    echoerr "Error: no arguments given!"
    ;;
  *)
    pop v $1
    ;;
esac
}

# Print: simply prints the value of last item in stack [$1]
print(){
  # sets up local var for evaluation
  local height=$(eval echo \${#$1[@]})
  # checks if stack is greater than zero, then proceeds
  if [ $height -gt 0 ]
  then
    eval echo \${$1[\${#$1[@]}-1]}
  else # if stack is empty, then just shout that it is empty
    echoerr "Stack [$1] is empty"
  fi
}

# Height: outputs the number of items in a stack
height(){
# If we use height v <stack>, will print height verbosely
# If we use height t <stack>, will print height tersely
# if we use height <stack>, will use height verbosely
case $1 in
  v|verbose)
    case $2 in
      "")
        # if $2 is empty, throw an error
        echoerr "Error: wrong number of arguments!"
        ;;
      *)
        eval echo -n "Stack [$2] height: "
        height t $2
        ;;
    esac
    ;;
  t|terse)
    case $2 in
      "")
        # if $2 is empty, throw an error
        echoerr "Error: wrong number of arguments!"
        ;;
      *)
        eval echo \${#$2[@]}
        ;;
    esac
    ;;
  "")
    echoerr "Error: wrong number of arguments!"
    ;;
  *)
    height v $1
    ;;
esac
}

# Flush: clean up a stack, effectively destroying it
flush(){
  unset $1
  echo "Stack [$1] flushed"
}

########################################################################
## Terse sections
## pop and height functions are also supplied with its terse
## forms below,
## pop.terse    : just pop and print with no verbosity
## height.terse : just prints height with no verbosity
## Note that this is here for backward compatibility, as newer methods
## integrates terse mode directly on pop and height function.
########################################################################

# pop.terse is just function pop that just outputs stack height
# is a shorthand to pop while changing verbosity conditions, so
# we don't have to manually takes care of verbosity variable by
# hand
pop.terse(){
  pop t $1
}

# height.terse is height that just outputs stack height
# so we don't have to manually handle heightverbosity variable
height.terse(){
  height t $1
}

########################################################################
## Functions related to stack [last]. Note that by default, each pop
## operation pushes the last popped item to stack [last].
## Functions contained within this section is:
##
## pop.last : to actually pop stack [last] without sending back items
##            to stack [last]
## last.to  : to push contents of stack [last] to a target stack
## lastpop  : shorthand to "print last"
##
########################################################################

# This pops last item of stack [last], without sending the value
# back to stack [last] (because the default behavior of pop function
# sends the last popped item to last stack, then the command 'pop last'
# sends back the item to stack [last], effectively [last] is by default
# non-popable
pop.last(){
  local height=${#last[@]}
  if [ $height -gt 0 ]
  then
    print last
    unset last[-1]
  else
    echoerr "Stack [last] is empty"
  fi
}

# lastto: push all contents in stack [last] to stack [$1]
last.to(){
  local height=${#last[@]}
  while [ $height -gt 0 ]
  do
    ((--height))
    # for some unknown reasons this does not actually remove from
    # stack [last]
    push q $1 "$(pop.last)"
    pop.last > /dev/null  # to actually remove from stack [last]
  done
}

# lastpop: print out the last item in stack [last]
# a shorthand for: print last
lastpop(){
  # _last[${#_last[@]}]="$last"
  print last
}

########################################################################
## Functions related to stack [input], where new items might be
## flushed into before processing.
## take : shorthand to "push input", but can insert long strings
##        without the use of quotes.
## pop_input_step: pop stack [input] to stack [last] until counter
##        is zero.
## pop.input: pop [amount] items from stack [input] to a target stack.
########################################################################

take(){
  eval push t input \"$@\"
}

# pop stack [input] if counter is not zero
# effectively pushing items to stack [last]
pop_input_step(){
  while [ $counter -gt 0 ]
  do
    pop q input
    ((counter--))
  done
}

# pop stack [input] for [amount] times to stack [target].
# to use: pop.input [amount] [target]
pop.input(){
  counter=$1
  pop_input_step
  last.to "$2"
}

########################################################################
## Generalization of serialized functions such as pop.input so we can
## pop out stacks for n times
## pop_step : pop a source stack to stack [last] until counter
##            is zero.
## pops     : pop [amount] items from an input stack to a target stack.
########################################################################

# pop a source stack if counter is not zero
# effectively pushing items to stack [last]
pop_step(){
  while [ $counter -gt 0 ]
  do
    pop q $source
    ((counter--))
  done
}

# pop stack [source] for [amount] times to stack [target].
# to use: pops [source] [target] [amount]
pops(){
  if [ $# -eq 3 ]
  then
    source=$1
    target=$2
    counter=$3
    pop_step
    last.to "$target"
  else
    echoerr "[Error]: wrong number of arguments!"
    echoerr "To use: pops <source> <target> <amount>"
  fi
}

########################################################################
## Quirks related to stack [delta], that can act as left-handed or
## right-handed storage. It contains the following functions:
## bob      : like pop, but instead of pushing to stack [last], it pushes
##            to stack [delta]
## delta.to : like last.to, but instead of pushing all items from stack
##            [last] into a target stack, it pushes from stack [delta]
## bob_step : like pop_step but uses bob
## bobs     : like pops but use bob_step and delta.to
########################################################################

# Bob: removes the last item of a stack and print it
# Also pushes the last item popped into stack [delta]
# If we use bob v <stack>, will bob verbosely
# If we use bob t <stack>, will bob tersely
# if we use bob <stack>, will use bob verbosely
bob(){
case $1 in
  v|verbose)
    case $2 in
      "")
        # if $2 is empty, throw an error
        echoerr "Error: no stack to pop!"
        ;;
      *) # for all else
        local height=$(eval echo \${#$2[@]})
        if [ $height -gt 0 ] # check if stack is not empty
        then # if it is not empty, pop stack
          echo "Pop stack [$2]"
          echo -n "Value: "
          bob t $2
        else
          echoerr "Stack [$2] is empty"
        fi
    esac
    ;;
  t|terse)
    case $2 in
      "")
        # if $2 is empty, throw an error
        echoerr "Error: no stack to pop!"
        ;;
      *) # for all else
        local height=$(eval echo \${#$2[@]})
        if [ $height -gt 0 ] # check if stack is not empty
        then # if it is not empty, bob stack
          # print last value
          print $2
          # store last value to stack [delta]
          push q delta "$(print $2)"
          # remove item from stack [$2]
          eval unset $2[-1]
        else
          echoerr "Stack [$2] is empty"
        fi
        ;;
    esac
    ;;
  q|quiet)
    case $2 in
      "")
        # if $2 is empty, throw an error
        echoerr "Error: no stack to pop!"
        ;;
      *) # for all else
        local height=$(eval echo \${#$2[@]})
        if [ $height -gt 0 ] # check if stack is not empty
        then # if it is not empty, pop stack
          # store last value to stack [delta]
          push q delta "$(print $2)"
          # remove item from stack [$2]
          eval unset $2[-1]
        else
          echoerr "Stack [$2] is empty"
        fi
        ;;
    esac
    ;;
  "")
    echoerr "Error: no arguments given!"
    ;;
  *)
    bob v $1
    ;;
esac
}

# delta.to: push all contents in stack [delta] to stack [$1]
# Note that since it uses pop, it also pushes to [last].
# Interestingly, it means we are cloning data, as now the same
# set of data is present in both stack [$1] and stack [last]
delta.to(){
  local height=${#delta[@]}
  while [ $height -gt 0 ]
  do
    ((--height))
    push q $1 "$(print delta)"
    pop q delta # to actually remove from stack [delta]
  done
}


# pop a source stack if counter is not zero
# effectively pushing items to stack [last]
bob_step(){
  while [ $counter -gt 0 ]
  do
    bob q $source
    ((counter--))
  done
}

# pop stack [source] for [amount] times to stack [target].
# to use: pops [source] [target] [amount]
bobs(){
  if [ $# -eq 3 ]
  then
    source=$1
    target=$2
    counter=$3
    bob_step
    delta.to "$target"
  else
    echoerr "[Error]: wrong number of arguments!"
    echoerr "To use: bobs <source> <target> <amount>"
  fi
}

########################################################################
## shorthands to some long commands:
## pop input -> popin
## last.to   -> lto
## delta.to  -> dto
## some useful sequences:
## ito -> routes input to target, one item at a time
## cit -> routes input to target via dto, one by one,
##        while stores routed item history in stack [last]
########################################################################

popin(){
pop input
}

lto(){
last.to $@
}

dto(){
delta.to $@
}

ito(){
pop input
lto $@
}

cit(){
bob input
dto $@
}

########################################################################
## List items of special stacks.
## These two functions are no longer necessary since the advent of our
## new stack.ls function, that can universally display contents of any
## stacks in a bash shell environment.
## We keep them here for demonstrative purposes only.
## Their use are discouraged, and if you have to, do these instead:
## list.input > stack.ls t input
## show.input > stack.ls v input
########################################################################

# This prints value for every indices
list.input(){
  for i in ${!input[@]}
  do
    echo "${input[$i]}"
  done
}

# This prints value for every indices and its associated
# indices
show.input(){
  height input
  for i in ${!input[@]}
  do
    echo "$i: ${input[$i]}"
  done
}

########################################################################
## Useful functions to explore the states of this implementation
########################################################################

# Reinitialize all special storages
flush.all(){
for target in input last alpha beta gamma delta
do
  unset $target
done
}

########################################################################
## Stacksystem management: move, copy, or reverse stacks
########################################################################

# Stack superfunction, supposedly will allow access to all functions starting
# with stack.(name) or even to replace them.

stack(){
case $1 in
  mv)
    # move stack contents
    if [ $# -eq 3 ]
    then
      # we need to make sure that last is empty first
      unset last
      local source=$2
      local target=$3
      pops $source $target $(height t $source)
    else
      echoerr "[Error]: Wrong number of arguments!"
      echoerr "To use: stack mv <source> <target>"
    fi
    ;;
  cp)
    # copy stack contents
    if [ $# -eq 3 ]
    then
      local source=$2
      local target=$3
      # ensure last is empty
      unset last
      bobs $source $target $(height t $source)
      last.to $source
      pops $source delta $(height t $source)
      delta.to $source
      # ensure last is empty
      unset last
    else
      echoerr "[Error]: Wrong number of arguments!"
      echoerr "To use: stack cp <source> <target>"
    fi
    ;;
  rv)
    # reverses stack contents
    if [ $# -eq 2 ]
    then
      # no need to flush, as stack mv will flush them for us
      local target=$2
      stack.mv $target delta
      delta.to $target
      unset last
    else
      echoerr "[Error]: Wrong number of arguments!"
      echoerr "To use: stack rv <target>"
    fi
    ;;
  mir)
    # copy stack contents and reverses order at destination
    if [ $# -eq 3 ]
    then
      # no need to flush, as stack mv will flush them for us
      local source=$2
      local target=$3
      # chirality is preserved from source
      stack mv $source delta
      # chirality is reversed on target
      delta.to $target
      # chirality is preserved on source
      last.to $source
      unset last
    else
      echoerr "[Error]: Wrong number of arguments!"
      echoerr "To use: stack mir <source> <target>"
    fi
    ;;
  read)
    # read a newline-delimited file and load contents to a stack
    if [[ $# -ge 2 && $# -le 3 ]]
    then
      local o="$IFS" # stores ifs to a variable
      local source=$2
      local target=$3
      # failsafe if no array target is included,
      # target is stack [input]
      [ "$target" == "" ] && target="input"
      IFS=$'\n' #alters IFS to newline
      for s in $(cat $source)
      do
        push q $target "$s"
      done
      IFS="$o" # restores ifs
      echo "File $source is loaded to Stack [$target]"
    else
      echoerr "[Error]: Wrong number of arguments!"
      echoerr "To use: stack read <source> <target>"
      echoerr "where <source> is a newline delimited file"
      echoerr "and <target> is a stack"
    fi
    ;;
  write)
    # write contents of a stack to a newline-delimited file
    local source=$2
    local target=$3
    if [ $# -eq 3 ]
    then
      stack ls t $source > $target
      echo "Stack [$source] is saved to file $target"
    else
      echoerr "[Error]: Wrong number of arguments!"
      echoerr "To use: stack write <source> <target>"
      echoerr "where <source> is a stack, and <target> is a"
      echoerr "newline delimited file"
    fi
    ;;
  ls)
    # list contents of a stack
    local ls_switch="$2"
    case $ls_switch in
      l|list)
        # list the contents ordinarily (eg. with height shown)
        # and indices are shown.
        case $3 in
        # if no target stack is specified, throw an error
          "")
            echoerr "Error! No target stack is specified!"
            echoerr "To use: stack ls $ls_switch <stack>"
            ;;
          *)
            height $3
            for i in $(eval echo \${!$3[@]})
            do
              eval echo "\$i: \${$3[\$i]}"
            done
            ;;        
        esac
        ;;
      t|terse)
        # list the contents of a stack in terse manner (only
        # its contents, no height, and no indices. One item
        # per line.
        case $3 in
        # if no target stack is specified, throw an error
          "")
            echoerr "Error! No target stack is specified!"
            echoerr "To use: stack ls $ls_switch <stack>"
            ;;
          *)
            for i in $(eval echo \${!$3[@]})
            do
              eval echo "\${$3[\$i]}"
            done
            ;;
        esac
        ;;
      s|size|hi|height)
        # list the content's heights, alias for height.
        # Mainly because h|height might be confused from
        # h|help
        case $3 in
        # if no target stack is specified, throw an error
          "")
            echoerr "Error! No target stack is specified!"
            echoerr "To use: stack ls $ls_switch <stack>"
            ;;
          *)
            height $3
            ;; 
        esac
        ;;
      ts|th|height.terse|size.terse)
        # list the content's heights, alias for height.
        # This is the terse version
        case $3 in
        # if no target stack is specified, throw an error
          "")
            echoerr "Error! No target stack is specified!"
            echoerr "To use: stack ls $ls_switch <stack>"
            ;;
          *)
            height t $3
            ;;
        esac
        ;;
      x|special)
        # list stack heights of all special stacks, their
        # contents, along with their indices.
        stack ls l input
        echo
        stack ls l last
        echo
        stack ls l alpha
        echo
        stack ls l beta
        echo
        stack ls l gamma
        echo
        stack ls l delta
        echo
        ;;
      xl|special.list)
        # list only stack heights of all special stacks.
        stack ls s input
        stack ls s last
        stack ls s alpha
        stack ls s beta
        stack ls s gamma
        stack ls s delta
        ;;
      h|help)
        # list the content's heights, alias for height.
        # Mainly because h|height might be confused from
        # h|help
        stack.help.ls
        ;;
      "") # in case no arguments are given
        echoerr "Error! No arguments!"
        ;;
      *)
        # list the contents ordinarily (eg. with height shown)
        # and indices are shown. Default behavior.
        stack.ls l $ls_switch
        ;;
    esac
    ;;
  rm)
    unset $2
    ;;
  save)
    # save special stacks to a state directory
    # make states dir if not existing
    if [ ! -d "$statedir" ]
    then
      mkdir "$statedir"
    fi
    
    local slot="$2"
    case $slot in
    ""|default)
      local save="$statedir/default"
      ;;
    *)
      local save="$statedir/$slot"
      ;;
    esac
    
    # make slot dir if not existing
    if [ ! -d $save ]
    then
      mkdir "$save"
    fi
    
    for stack in input last alpha beta gamma delta
    do
      stack write $stack $save/$stack > /dev/null
    done
    echo "Stacks internal states saved!"
    ;;
  saves)
    # list saved states and manage state directory
    if [ -d $statedir ]
    then
      case $2 in
        list|ls|l)
          local oldifs="$IFS" # stores ifs to a variable
          IFS=$'\n' #alters IFS to newline
          for s in $(ls $statedir)
          do
            if [ -d "$statedir/$s" ]
            then
              echo "State Slot: $s"
            fi
          done
          IFS="$oldifs" # restores ifs
          ;;
        remove|rm|r)
          if [[ -n "$3" && -d "$statedir/$3" ]]
          then
            echo "Remove State Slot: $3"
            rm -r "$statedir/$3"
          else
            echoerr "Error! No slot is specified for deletion, or target slot is not a directory!"
          fi
          ;;
        h|help)
          stack.help.saves
          ;;
        *)
          stack.err.saves
          ;;
      esac
    else
      echoerr "No saved state directory is found!"
    fi
    ;;
  load)
    # read a state directory and recreate states of special stacks
    local target="$2"
    case $target in
    "")
      local save="$statedir/default"
      ;;
    *)
      local save="$statedir/$target"
      ;;
    esac
    
    if [ -d $save ]
    then
      flush.all
      for stack in input last alpha beta gamma delta
      do
        stack read $save/$stack $stack > /dev/null
      done
      echo "Saved stacks internal states restored!"
    else
      echoerr "Error: Specified saved states not found in the system!"
    fi
    ;;
  help)
    # show help
    stack.help
    ;;
  "")
    echoerr "Error: No switch given! See: stack help"
    ;;
  *)
    echoerr "Error: Wrong switch given! See: stack help"
    ;;
esac
}

# move all contents of one stack to another stack
stack.mv(){
  stack mv $@
}

# copy content of one stack to a new stack
stack.cp(){
  stack cp $@
}

# reverses the chirality of target
stack.rv(){
  stack rv $@
}

# mirrors source to target, target will have an opposite chirality
stack.mir(){
  stack mir $@
}

# read from file and store to a target stack.
# if no target is specified, target is [input]
stack.read(){
  stack read $@
}

# Write a target stack to a target file.
# Now supports writing any stack to any file, via the use
# of new stack.ls function.
stack.write(){
  stack write $@
}

# display the heights of all special stacks
# This is a replacement for original stack.ls. Superior from
# the original function as it allows listing of any stacks,
# not just from special stacks.
# Display the content of any stacks, with some switches to
# modify its behavior
stack.ls(){
  stack ls $@
}

# save states to $HOME/.local/stack
stack.save(){
  stack save $@
}

# load states to $HOME/.local/stack
stack.load(){
  stack load $@
}

# Manage saved states
stack.saves(){
  stack saves $@
}

###############################################################################
# gives help on stacksystem management
###############################################################################

stack.help(){
cat <<EOF

###########################################################
## StackSystem Management List of Commands: ###############
###########################################################

~$ stack mv <source> <target>
   > move the contents of stack <source> to stack <target>
   > while preserving their data order.
~$ stack cp <source> <target>
   > copy the contents of stack <source> to stack <target>
   > while preserving their data order.
~$ stack rv <target>
   > reverses the order of contents of stack <target>.
~$ stack mir <source> <target>
   > copy the contents of stack <source> to stack <target>
   > with data order at <target> is reversed.

###########################################################
## [Warning]: Do not use stack [last] or stack [delta]   ##
##            as either source or target for functions   ##
##            above!                                     ##
###########################################################

~$ stack rm <stack>
   > Alias for: unset <stack>
~$ stack ls <stack/argument>
   > to print the contents of stacks. Has its own
   > help text accessible by passing arguments: h, help
~$ stack read <file> <stack>
   > copy the contents of <file> to stack <stack>
   > if <stack> is unspecified, copy to stack [input]
~$ stack write <stack> <file>
   > copy the contents of stack <stack> to <file>
~$ stack save
   > copy the contents of special stacks to stack.sh data
   > directory (stack.sh data directory is typically
   > found at ~/.local/stack/). Not to be confused with
   > stack.saves that list existing saved states.
~$ stack load
   > load the contents of stack.sh data directory to
   > special stacks (stack.sh data directory is typically
   > found at ~/.local/stack/). Note that this function
   > flushes all special stacks before restoring old stack
   > states.
~$ stack saves <switch> <slot>
   > list or remove existing saved states. There are three
   > switches: remove (rm), list (ls), and help (h).

EOF
}

stack.help.ls(){
cat <<EOF

To use:

~$ stack ls [switches] <stack>

Switches:

- l, list
  > list stack heights of a target stack, and display
    stack contents along with its indices. It is also
    the default behavior when no switches are given.

- t, terse
  > Prints only the contents of stack <target>, stack
    height header and indices are not given.

- s, size
  > Prints the height of a target stack.
    An alias for: height <stack>

- ts, size.terse
  > Prints only the height of a target stack. It is
    a terse version of switches: s, size

- hi, height
  > Synonymous with switches: s, size

- th, height.terse
  > Synonymous with switches: ts, size.terse

- x, special
  > list stack heights of all special stacks,
    and their contents, along with their indices.

- xl, special.list
  > list only stack heights of all special stacks.

- h, help
  > produces this help text.

EOF
}

stack.help.saves(){
cat <<EOF
To use:
~$ stack saves <switch> <slot>

Existing switches:
- h, help
  > Produces this help text.
- ls, list
  > list existing saved states of the system.
    Does not require <slot>.
- rm, remove <slot>
  > remove an existing specified slot. Must
    include a <slot> to delete.
EOF
}

stack.err.saves(){
caterr <<EOF
Requires an argument! To use:
~$ stack saves <switch> <slot>
EOF
}

########################################################################
## Trash Can Section Below
## does not work, but i keep it here for future reference
########################################################################
# list(){
#echo "Print all values in Stack [$1]"
#stack=( ${$1[@]} )
#for i in ${!stack[@]}
#do
#  eval echo \"\$i: \"\${$1[\$i]}\"\"
#done
#echo "All content(s) of Stack [$1] is printed!"
#}
#!/bin/bash
# source $HOME/array.sh
# note that this list does not accept whitespace
# if there is any whitespace, whitespace is treated
# as delimiter
#list.tdl(){
#for s in ${tdl[@]}
#do echo "$s"
#done
#}
