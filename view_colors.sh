#!/usr/bin/bash

if [ -z $1 ]; then
  d=0
else
  d=$1
fi

for c in {1..256}; do
  color=$(tput setaf $c)
  b=$(($c + $d))
  bl=""
  if [[ $b -eq 128 || $c -eq 128 ]]; then bl=$(tput blink); fi
  if [ $b -gt 256 ]; then b=$(($b-256)); fi
  bg_color=$(tput setab $b)
  printf "${bl}${bg_color}${color}$c-$b "
  tput sgr0
done
echo -en $(tput sgr0)
echo
echo
