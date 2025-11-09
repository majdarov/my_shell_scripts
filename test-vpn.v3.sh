#! /usr/bin/env bash

set -e
set -o pipefail

chk_count=3
_vpn=$1
_silent=false

while getopts "c:s" opt; do
    case $opt in
        c) _vpn="$OPTARG";;
        s) _silent=true;;
        \?) echo "Неизвестная опция"; exit 1;;
    esac
done
shift $((OPTIND-1))

selectConnection() {
  local arr_conn=($(nmcli c | grep vpn | cut -d ' ' -f 1))

  echo "Select coneection for check it:"
  for i in ${!arr_conn[@]}
  do
    echo "  $((i + 1))) ${arr_conn[$i]}"
  done

  read -p "Enter number (1 - ${#arr_conn[@]}):    " num
  num=${num:-1}
  _vpn=${arr_conn[$((num - 1))]}

  unset num
}

if [ -z $_vpn ] || [[ $_vpn =~ ^-. ]]; then
  if [ $_silent = true ]; then
    echo "WARNING: Need name of vpn connection!"
    exit 1;
  fi
  selectConnection
fi

checkConnVpn() {
  local cfg_addr=$(nmcli c show $1 | grep vpn.data | tr ',' '\n' | head -n 1 | cut -d '=' -f 2 | tr -d ' ')
  real_addr=$(curl -s ifconfig.co)>/dev/null
  if [ "${cfg_addr}" = "${real_addr}" ]; then
    return 0
  else
    return 1
  fi
}

while ! checkConnVpn ${_vpn} && [ ${chk_count} -gt 0 ]; do
  sudo nmcli c up ${_vpn} > /dev/null
  chk_count=$((chk_count - 1))
  sleep 2
done

if checkConnVpn ${_vpn}; then
  echo "VPN is running! Address: ${real_addr} Connection: ${_vpn}"
  if [ $_silent = false ]; then read -n 1 -p "Want you down this vpn (y/N): " yn; fi
else
  echo "VPN is NOT Running!"
fi

if [ "$yn" = "y" ] || [ "$yn" = "Y" ]; then
  echo
  sudo nmcli c down ${_vpn} > /dev/null
  echo "VPN is down!"
fi

unset _vpn
unset real_addr
unset chk_count
unset yn

exit 0
