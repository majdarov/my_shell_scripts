#! /usr/bin/env bash

# Use options for set params:
#
#  Usage: add-certs.v3.sh
#
# -n VpnUser
# -d /directory/to/set/certs, if not use -> set ../certs/${NameOfConnection}
# -c NameOfConnection
# -s server address
# --certs-only - only unpack certs, not add connection
# --help - this help

# 'Set -e' to exit on error, '-o pipefail' to exit on piped commands failing
set -e
set -o pipefail
# set -x

show_usage() {
    cat 1>&2 << EOF
    Usage: bash $0 [OPTIONS]

    Use options for set params:

     -n VpnUser
     -d /directory/to/set/certs, if not use -> set ../certs/\${NameOfConnection}
     -c NameOfConnection
     -s server address
     --certs-only - only unpack certs, not add connection
     --help - this help'

EOF
        exit 1
}

# Set base options
vpn_user=''
conn_name=''
_path=''
_server=''
_certs_only=false

# if [ $# -gt 0 ]
#     then
#         echo $@
#         echo
# fi

while [[ $1 == --* ]]
do
    echo $1
    case $1 in
        --certs-only)
            _certs_only=true
            shift
            ;;
        --help)
            show_usage
            # echo
            # head $0 -n 10 | tail -n 8 | tr -d '#'
            # echo
            # exit 0
            ;;
        *)
            shift
            continue
            ;;
    esac
done


while getopts "d:n:c:s:" opt; do
    case $opt in
        d) _path="$OPTARG";;
        n) vpn_user="$OPTARG";;
        c) conn_name="$OPTARG";;
        s) _server="$OPTARG";;
        \?) continue ;; # echo "Неизвестная опция"; exit 1;;
    esac
done
shift $((OPTIND-1))

cat 1>&2 <<EOF
vpn_user: ${vpn_user}
_path: ${_path}
conn_name: ${conn_name}
_server: ${_server}
_certs_only: ${_certs_only}
EOF

# Check OpenSSL version
_v_ossl=$(openssl version | awk '{print $2}' | cut -d '.' -f 1)
echo "Using OpenSSL version ${_v_ossl}"

_legacy=''

if [ $((_v_ossl)) -ge 3 ]
    then
        echo "Using legacy certificates"
        _legacy='-legacy'
fi

#  Check and read VpnUser
if [ -z ${vpn_user} ]; then
    # Read user input
    read -p "Enter user name [ default: vpnclient ]: " vpn_user
    vpn_user=${vpn_user:-vpnclient}
fi

_certificate="${vpn_user}.p12"

if [ ! -f ${_certificate} ]
then
    echo "Certificate ${_certificate} not found."
    exit 1
fi

# Check and read server address
if ! [ $_server ]; then
    # Read server address
    read -p "Enter server address: " _server
fi
octet="(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])"
ipv4_regex="${octet}\.${octet}\.${octet}\.${octet}"

if [[ -z "${_server}" || ! ${_server} =~ ${ipv4_regex} ]]
    then
        echo "Server address not specified."
        exit 1
fi

echo "Adding certificates to user \"${vpn_user}\" for Server address: ${_server}..."

# Check and read Connection Name
if [[ -z ${conn_name} || ! ${_certs_only} ]]; then
    read -p "Enter VPN connection name [ default: VPN ]: " conn_name
fi
connection=${conn_name:-VPN}

# Check path to certs
if ! [ $_path ]; then
    _path=./certs/${connection}
fi
[ -d  ${_path} ] || mkdir -p ${_path}

openssl pkcs12 -in ${vpn_user}.p12 -cacerts -nokeys -out ${_path}/ca.cer $_legacy
openssl pkcs12 -in ${vpn_user}.p12 -clcerts -nokeys -out ${_path}/client.cer $_legacy
openssl pkcs12 -in ${vpn_user}.p12 -nocerts -nodes  -out ${_path}/client.key $_legacy
# rm ${vpn_user}.p12

cd ${_path}

sudo chown root:root ca.cer client.cer client.key
sudo chmod 600 ca.cer client.cer client.key

if [ ${_certs_only} == true ]; then
    cat 1>&2 <<EOF
    User certificates sets in ${_path}
    for vpn_user: ${vpn_user}
EOF
    exit 0
fi


_vpn_data="address = ${_server}, certificate = ${_path}/ca.cer, encap = no, esp = aes128gcm16, ipcomp = no, method = key, proposal = yes, usercert = ${_path}/client.cer, userkey = ${_path}/client.key, virtual = yes"

sudo nmcli c add type vpn ifname -- vpn-type strongswan connection.id ${connection} connection.autoconnect no vpn.data "${_vpn_data}"

exit 0
