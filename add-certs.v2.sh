#! /usr/bin/env bash

# Run as root in /root/ folder

# 'Set -e' to exit on error, '-o pipefail' to exit on piped commands failing
set -e
set -o pipefail
# set -x

# Check OpenSSL version
_v_ossl=$(openssl version | awk '{print $2}' | cut -d '.' -f 1)
echo "Using OpenSSL version ${_v_ossl}"

_legacy=''

if [ $((_v_ossl)) -ge 3 ]
    then
        echo "Using legacy certificates"
        _legacy='-legacy'
fi

# Read user input
read -p "Enter user name [ default: vpnclient ]: " _user
user=${_user:-vpnclient}

_certificate="${user}.p12"

if [ ! -f ${_certificate} ]
then
    echo "Certificate ${_certificate} not found."
    exit 1
fi

# Read server address
read -p "Enter server address: " _server
octet="(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])"
ipv4_regex="${octet}\.${octet}\.${octet}\.${octet}"

if [[ -z "${_server}" || ! ${_server} =~ ${ipv4_regex} ]]
    then
        echo "Server address not specified."
        exit 1
fi

echo "Adding certificates to user \"${user}\" for Server address: ${_server}..."

read -p "Enter VPN connection name [ default: VPN ]: " _connection
connection=${_connection:-VPN}

_path=~/.certs/${connection}

test -d ${_path} || mkdir -p ${_path}

openssl pkcs12 -in ${user}.p12 -cacerts -nokeys -out ${_path}/ca.cer $_legacy
openssl pkcs12 -in ${user}.p12 -clcerts -nokeys -out ${_path}/client.cer $_legacy
openssl pkcs12 -in ${user}.p12 -nocerts -nodes  -out ${_path}/client.key $_legacy
rm ${user}.p12

cd ${_path}

sudo chown root:root ca.cer client.cer client.key
sudo chmod 600 ca.cer client.cer client.key


_vpn_data="address = ${_server}, certificate = ${_path}/ca.cer, encap = no, esp = aes128gcm16, ipcomp = no, method = key, proposal = yes, usercert = ${_path}/client.cer, userkey = ${_path}/client.key, virtual = yes"

sudo nmcli c add type vpn ifname -- vpn-type strongswan connection.id ${connection} connection.autoconnect no vpn.data "${_vpn_data}"

exit 0
