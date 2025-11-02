# Мои скрипты для различных ситуаций

## VPN client

### [add-certs.v3.sh](./add-certs.v3.sh)

Usage: `bash ./add-certs.v3.sh [OPTIONS]`

Use options for set params:

    -n VpnUser (default `vpnclient`)
    -d /directory/to/set/certs, if not use -> set ../certs/${NameOfConnection}
    -c NameOfConnection (default `VPN`)
    -s server address
    --certs-only - only unpack certs, not add connection
    --help

Скрипт распаковывает файл `${VpnUser}.p12` в указанную директорию и создает vpn подключение `$NameOfConnection`.
