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

Скрипт распаковывает файл `${VpnUser}.p12` в указанную директорию (извлекает сертификаты `ca.crt`, `client.crt`, `client.key`) и создает vpn подключение `$NameOfConnection`.
С опцией **--certs-only** - только извлекает сертификаты.

### [test-vpn.v3.sh](./test-vpn.v3.sh)

Usage: `bash ./test-vpn.v3.sh [-s -c $NameOfConnection] | [$NameOfConnection]`

Проверяет указанное подключение и, если не активно, пробует подключиться. Максимальное количество попыток подключения указано в переменной **$chk_count**.

**-s** - тихий режим, используется вместе с опцией **-с $NameOfConnection**
