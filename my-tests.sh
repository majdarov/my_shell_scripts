#!/usr/bin/bash

# connections=( nmcli c | grep vpn | cut -d ' ' -f 1 )
connections=( nmcli c | cut -d ' ' -f 1 )

# arr_conn=()
# for conn in $connections
# do
#   arr_conn+=($conn)
# done

for i in "${connections}"
do
  echo "  $((i + 1))) ${connections[$i]}"
done

exit 0
