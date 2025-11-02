#! /usr/bin/env sh

set -e
set -o pipefail

chk_count=3
_vpn=$1

if [ -z $_vpn ]; then
    cat 0>&2 <<EOF

    WARNING: Need name of vpn connection!

    Usage: $0 [NameOfVpnConnection]

EOF
    exit 1
fi

checkConnVpn() {
#  local cfg_addr=$(nmcli c show $1 | grep "VPN.CFG" | grep address | tr ' ' '\n' | tail -1)
  local cfg_addr=$(nmcli c show $1 | grep vpn.data | tr ',' '\n' | head -n 1 | cut -d '=' -f 2 | tr -d ' ')
  real_addr=$(curl -4 ifconfig.co)>/dev/null
  if [ "${cfg_addr}" = "${real_addr}" ]; then
    return 0
  else
    return 1
  fi
}

while [[ ! checkConnVpn ${_vpn} && ${chk_count} -gt 0]]; do
  sudo nmcli c up ${_vpn}
  chk_count=$((chk_count - 1))
  sleep 1
done

if checkConnVpn ${_vpn}; then
  echo "VPN is running! Address: ${real_addr} Connection: ${_vpn}"
else
  echo "Not VPN is Running!"
fi

unset _vpn
unset real_addr

exit 0
