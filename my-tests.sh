#!/usr/bin/env bash

# connections=($( ls -al | cut -d ' ' -f 9 ))
# 
# for i in "${connections}"
# do
#   echo "  $((i + 1))) '${connections[$i]}'"
# done
# 
tput setaf 1 && tput setab 35
printf "Script $0 in work!!!$(tput sgr0)\n"
exit 0
