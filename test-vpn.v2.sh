#! /usr/bin/bash

_vpn=$1

if [ -z $1 ]; then
    echo<<EOF

    WARNING: Need name of vpn connection!

    Usage: $0 [NameOfVpnConnection]

EOF
    exit 1
fi

check-conn-vpn() {
  local cfg_addr=$(nmcli c show $1 | grep "VPN.CFG" | grep address | tr ' ' '\n' | tail -1)
  real_addr=$(curl -4 ifconfig.co)>>/dev/null
  if [ "${cfg_addr}" = "${real_addr}" ]; then
    return 0
  else
    return 1
  fi
}

if check-conn-vpn $1; then
  echo "VPN is running! Address: ${real_addr} Connection: ${_vpn}"
else
  echo "Not VPN is Running!"
fi

unset _vpn
unset real_addr

exit 0
