#!/usr/bin/env python3

import subprocess

# Get vpn connections
def get_vpn_connections():
    result = subprocess.run(['nmcli c show'], shell=True, capture_output=True, text=True)
    l_conn = result.stdout.split('\n')[1:-1]
    return [ l.split() for l in l_conn if 'vpn' in l ]
#-----------end------------

# Get active vpn connection
def get_active_vpn_connections(cf: list):
    for i in range(len(cf)):
        if cf[i][3] != '--':
            return [ True, cf[i][0] ]
        else:
            return [ False, '' ]
#-----------end------------

# Activate vpn connection
def activate_vpn_connection(cf: list):
    print("Select vpn connection for test")
    for i in range(len(cf)):
        print(f"{i+1}) {cf[i][0]}")

    print(f"Select number 1..{len(cf)}: ", end=' ')

    i = input()
    if not i:
        i = 0
    else:
        i = int(i)

    if 0 < i <= len(cf):
        cf_vpn = cf[i-1][0]
        print(f"Selected {cf_vpn}")
        subprocess.run(['nmcli', 'c', 'up', cf_vpn])
    else:
        print(f"Connection process aborted!")
        exit(0)
#-----------end------------

# Deactivate vpn connection
def deactivate_vpn_connection(cf_vpn: str):
    result = subprocess.run(['nmcli', 'c', 'down', cf_vpn])
    if result.returncode == 0:
        print(f"Connection {cf_vpn} deactivated! \n Do you want activate any connection (y/N)?: ", end='')
        yn = input()
        if yn == 'y':
            activate_vpn_connection(get_vpn_connections())
        else:
            exit(0)
    else:
        print(result.stderr)
        exit(1)
#-----------end------------

# Main
cf = get_vpn_connections()
is_active_vpn, cf_vpn = get_active_vpn_connections(cf)

if not is_active_vpn:
    activate_vpn_connection(cf)
else:
    print(f"Connection {cf_vpn} is active!")
    print("Do you want to deactivate it? (y/N): ", end=' ')
    yn = input()
    if yn == 'y':
        deactivate_vpn_connection(cf_vpn)
    else:
        exit(0)
