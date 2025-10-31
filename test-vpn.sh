#! /usr/bin/sh

vpn=$(nmcli c show | grep TW-VPN | tr ' ' '\n' | grep "\S" | tail -n 1)
# echo "VPN is: $vpn"
if [ $vpn = "--" ]; then
  nmcli c up TW-VPN > /dev/null
fi

echo "VPN is running!"

# add this script in crontab
# crontab -e

# Check config vpn server
nmcli c show SPB_VPN | grep "VPN.CFG" | grep address | tr ' ' '\n' | tail -1
