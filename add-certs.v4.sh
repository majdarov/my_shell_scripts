#!/usr/bin/env bash

# Script for adding VPN certificates and creating VPN connections
#
# Usage: add-certs.v4.sh [OPTIONS]
#
# Options:
#   -n VpnUser         VPN user name (default: vpnclient)
#   -d /directory      Directory to set certs (default: ./certs/ConnectionName)
#   -c NameOfConnection VPN connection name (default: VPN)
#   -s server_address  Server address (required)
#   --certs-only       Only unpack certs, don't add connection
#   --help             Show this help message

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*" >&2
    fi
}

# Show usage information
show_usage() {
    cat << EOF
Usage: bash $0 [OPTIONS]

Options:
  -n VpnUser         VPN user name (default: vpnclient)
  -d /directory      Directory to set certs (default: ./certs/ConnectionName)
  -c NameOfConnection VPN connection name (default: VPN)
  -s server_address  Server address (required)
  --certs-only       Only unpack certs, don't add connection
  --help             Show this help message

Examples:
  $0 -n john -s 192.168.1.1 -c office-vpn
  $0 --certs-only -n alice -d /tmp/certs -s vpn.company.com

Environment variables:
  DEBUG=1            Enable debug output

EOF
    exit 1
}

# Validate IP address format
validate_ip() {
    local ip=$1
    local octet='(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])'
    local ipv4_regex="^${octet}\.${octet}\.${octet}\.${octet}$"
    
    if [[ ! $ip =~ $ipv4_regex ]]; then
        return 1
    fi
    return 0
}

# Validate hostname/FQDN format
validate_hostname() {
    local hostname=$1
    # Basic hostname validation (can be improved)
    if [[ ! $hostname =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    return 0
}

# Validate server address (IP or hostname)
validate_server_address() {
    local addr=$1
    
    # Try IP validation first
    if validate_ip "$addr"; then
        log_debug "Server address validated as IP: $addr"
        return 0
    fi
    
    # Try hostname validation
    if validate_hostname "$addr"; then
        log_debug "Server address validated as hostname: $addr"
        return 0
    fi
    
    log_error "Invalid server address format: $addr"
    log_error "Must be a valid IPv4 address or hostname"
    return 1
}

# Validate file exists and is readable
validate_file() {
    local file=$1
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi
    if [[ ! -r "$file" ]]; then
        log_error "File not readable: $file"
        return 1
    fi
    return 0
}

# Validate directory is writable
validate_writable_dir() {
    local dir=$1
    if [[ ! -d "$dir" ]]; then
        log_error "Directory not found: $dir"
        return 1
    fi
    if [[ ! -w "$dir" ]]; then
        log_error "Directory not writable: $dir"
        return 1
    fi
    return 0
}

# Check if running with sufficient privileges
check_privileges() {
    if [[ $EUID -ne 0 && $_certs_only != true ]]; then
        log_warn "This script may require root privileges for VPN connection creation"
        log_warn "Running with sudo may be necessary"
        return 1
    fi
    return 0
}

# Check if nmcli is available
check_nmcli() {
    if ! command -v nmcli >/dev/null 2>&1; then
        log_error "nmcli command not found. Please install NetworkManager."
        return 1
    fi
    return 0
}

# Backup existing VPN connection if it exists
backup_existing_connection() {
    local conn_name=$1
    if nmcli c show "$conn_name" >/dev/null 2>&1; then
        log_warn "Connection '$conn_name' already exists"
        read -p "Do you want to delete the existing connection? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Deleting existing connection: $conn_name"
            if ! sudo nmcli c delete "$conn_name"; then
                log_error "Failed to delete existing connection"
                return 1
            fi
        else
            log_info "Keeping existing connection. Exiting."
            exit 0
        fi
    fi
    return 0
}

# Default values
vpn_user="vpnclient"
conn_name="VPN"
certs_dir=""
server_addr=""
certs_only=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n)
            vpn_user="$2"
            shift 2
            ;;
        -c)
            conn_name="$2"
            shift 2
            ;;
        -d)
            certs_dir="$2"
            shift 2
            ;;
        -s)
            server_addr="$2"
            shift 2
            ;;
        --certs-only)
            certs_only=true
            shift
            ;;
        --help)
            show_usage
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$server_addr" ]]; then
    log_error "Server address is required"
    show_usage
fi

if ! validate_server_address "$server_addr"; then
    exit 1
fi

# Validate certificate file
cert_file="${vpn_user}.p12"
if ! validate_file "$cert_file"; then
    exit 1
fi

# Check OpenSSL version and set legacy flag if needed
openssl_version=$(openssl version | awk '{print $2}' | cut -d '.' -f 1)
log_info "Using OpenSSL version $openssl_version"

legacy_flag=""
if [[ $openssl_version -ge 3 ]]; then
    log_info "Using legacy certificates flag for OpenSSL 3.x"
    legacy_flag="-legacy"
fi

# Set certificate directory
if [[ -z "$certs_dir" ]]; then
    certs_dir="./certs/${conn_name}"
else
    certs_dir="${certs_dir}/${conn_name}"
fi

# Create certificate directory
log_info "Creating certificate directory: $certs_dir"
if ! mkdir -p "$certs_dir"; then
    log_error "Failed to create directory: $certs_dir"
    exit 1
fi

# Validate certificate directory is writable
if ! validate_writable_dir "$(dirname "$certs_dir")"; then
    exit 1
fi

# Extract certificates from PKCS12 file
log_info "Extracting certificates for user: $vpn_user"

log_debug "Extracting CA certificate..."
if ! openssl pkcs12 -in "$cert_file" -cacerts -nokeys -out "${certs_dir}/ca.cer" $legacy_flag 2>/dev/null; then
    log_error "Failed to extract CA certificate"
    exit 1
fi

log_debug "Extracting client certificate..."
if ! openssl pkcs12 -in "$cert_file" -clcerts -nokeys -out "${certs_dir}/client.cer" $legacy_flag 2>/dev/null; then
    log_error "Failed to extract client certificate"
    exit 1
fi

log_debug "Extracting client key..."
if ! openssl pkcs12 -in "$cert_file" -nocerts -nodes -out "${certs_dir}/client.key" $legacy_flag 2>/dev/null; then
    log_error "Failed to extract client key"
    exit 1
fi

# Set proper permissions
log_info "Setting file permissions"
chmod 600 "${certs_dir}/ca.cer" "${certs_dir}/client.cer" "${certs_dir}/client.key" 2>/dev/null || true

if [[ $certs_only == true ]]; then
    log_info "Certificate extraction completed successfully"
    log_info "Certificates location: $certs_dir"
    exit 0
fi

# Check prerequisites for VPN connection creation
if ! check_nmcli; then
    exit 1
fi

# Check privileges
if ! check_privileges; then
    log_error "Root privileges required for VPN connection creation"
    exit 1
fi

# Backup existing connection if it exists
backup_existing_connection "$conn_name"

# Create VPN connection using nmcli
log_info "Creating VPN connection: $conn_name"

vpn_data="address = ${server_addr}, certificate = ${certs_dir}/ca.cer, encap = no, esp = aes128gcm16, ipcomp = no, method = key, proposal = yes, usercert = ${certs_dir}/client.cer, userkey = ${certs_dir}/client.key, virtual = yes"

log_debug "VPN data: $vpn_data"

if ! sudo nmcli c add type vpn ifname -- vpn-type strongswan \
    connection.id "$conn_name" \
    connection.autoconnect no \
    vpn.data "$vpn_data"; then
    log_error "Failed to create VPN connection"
    exit 1
fi

log_info "VPN connection '$conn_name' created successfully"
log_info "Server: $server_addr"
log_info "Certificates: $certs_dir"

# Optional: Show connection details
if command -v nmcli >/dev/null 2>&1; then
    log_info "Current VPN connections:"
    nmcli c show | grep vpn || true
fi

exit 0