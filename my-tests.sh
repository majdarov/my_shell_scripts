#!/usr/bin/bash

connections=$(nmcli c | grep vpn | cut -d ' ' -f 1)

arr_conn=()
for conn in $connections
do
  arr_conn+=($conn)
done

for i in ${!arr_conn[@]}
do
  echo "  $((i + 1))) ${arr_conn[$i]}"
done

