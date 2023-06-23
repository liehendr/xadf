#!/bin/bash
## Wrapper for mpv and some fancy tasks such as building a playlist

mplay(){
# Default states
mplay_exit_state=0
mplay_watch_mode=0
mplay_list_mode=0
mplay_playlist="play.list"

# Argument parser
while :;
do
  case $1 in
    w|watch) # watch mode switch
      mplay_watch_mode=1
      shift
      ;;
    l|list|updatelist) # list mode switch
      mplay_list_mode=1
      shift
      ;;
    -p | --playlist )
      if test -z "$2"
      then
        printf >&2 "Error! No playlist file given!\n"
        mplay_exit_state=1
        break
      else
        mplay_playlist="$2"
        shift 2
      fi
      ;;
    -h | --help ) # Display help text
      printf "function mplay() - convenience function to play media files.\n\nTo use:\n"
      printf "\tmplay <w/l> [-p,--playlist FILE]\n\n"
      printf "Arguments:\n"
      printf "\tw,watch             Watch from playlist file\n"
      printf "\tl,list,updatelist   Update playlist file\n"
      printf "\t-p,--playlist FILE  Supply a custom playlist file\tDefault: play.list\n"
      printf "\t-h,--help           Display this help text\n"
      printf "\n"
      mplay_exit_state=-1
      break
      ;;
    "") # no more arguments
      break
      ;;
    * ) # some unexpected arguments
      printf >&2 "Error! Unexpected argument %s\n" "$1"
      mplay_exit_state=2
      break
      ;;
  esac
done

if test $mplay_list_mode -eq 0 -a $mplay_watch_mode -eq 0 -a $mplay_exit_state -eq 0
then
  printf >&2 "Error! Neither watch mode or list mode is active!\n\tUsage: mplay -h\n"
  mplay_exit_state=3
fi

# Exit state is okay
if test $mplay_exit_state -eq 0
then
  # List mode is always parsed first, so we will always have something to play
  if test $mplay_list_mode -eq 1
  then # Update playlist file
    ls|grep -i "mkv$\|mp4$" |tee "${mplay_playlist}"
  fi
  # Watch mode, run mpv using mplay_playlist file
  if test $mplay_watch_mode -eq 1
  then # Play the playlist file
    mpv --playlist="${mplay_playlist}"
  fi
elif test $mplay_exit_state -ne -1
then
  printf "Error status: %s\n" "$mplay_exit_state"
fi
}
