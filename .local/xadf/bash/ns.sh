#!/bin/bash

# ntfssanitizer(){
# for f in $(eval echo \${!$1[@]})
# do
#   file=$(eval echo "\${$1[\$f]}")
  # file="${target[$f]}"
#   printf "chmod 660: $file\n"
#   chmod 660 "${file}" 2>> ~/sanitizererror.log
# done
# printf "Completed: $(height t $1) files chmoded\n"
# }

# Ntfs Sanitize File
nsf(){
for f in $(eval echo \${!$1[@]})
do
  file=$(eval echo "\${$1[\$f]}")
  printf "chmod 660: $file\n"
  chmod 660 "${file}" 2>> ~/sanitizererror-files.log
done
printf "Completed: $(height t $1) files chmoded\n"
}

# Ntfs Sanitize Dir
nsd(){
for f in $(eval echo \${!$1[@]})
do
  folder=$(eval echo "\${$1[\$f]}")
  printf "chmod 770: $folder\n"
  chmod 770 "${folder}" 2>> ~/sanitizererror-dir.log
done
printf "Completed: $(height t $1) Directories chmoded\n"
}
