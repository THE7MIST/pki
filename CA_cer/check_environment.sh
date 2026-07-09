#!/bin/bash
# ============================================================
# check_environment.sh
# Pre-Deployment Environment Checker
# ============================================================

set -e

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

PASS=0
FAIL=0
WARN=0

pass() {
    echo -e "${GREEN}[PASS]${RESET} $1"
    ((PASS++))
}

fail() {
    echo -e "${RED}[FAIL]${RESET} $1"
    ((FAIL++))
}

warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
    ((WARN++))
}

info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

echo
echo "==========================================================="
echo "      PKI HTTPS DEPLOYMENT ENVIRONMENT CHECKER"
echo "==========================================================="
echo

###########################################################
# Root Check
###########################################################

if [[ $EUID -eq 0 ]]; then
    pass "Running as root"
else
    fail "Run this script using sudo."
fi

###########################################################
# Operating System
###########################################################

if [ -f /etc/os-release ]; then
    source /etc/os-release
    info "Operating System : $PRETTY_NAME"

    if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
        pass "Supported Linux Distribution"
    else
        warn "Untested Distribution"
    fi
else
    fail "Cannot determine operating system."
fi

###########################################################
# Required Commands
###########################################################

echo
info "Checking Required Commands..."

COMMANDS=(
openssl
apache2
apachectl
curl
ping
getent
systemctl
update-ca-certificates
a2enmod
a2ensite
a2dissite
)

for CMD in "${COMMANDS[@]}"
do
    if command -v "$CMD" >/dev/null 2>&1
    then
        pass "$CMD found"
    else
        fail "$CMD missing"
    fi
done

###########################################################
# Optional Commands
###########################################################

OPTIONAL=(
nslookup
dig
)

echo
info "Checking Optional Commands..."

for CMD in "${OPTIONAL[@]}"
do
    if command -v "$CMD" >/dev/null 2>&1
    then
        pass "$CMD found"
    else
        warn "$CMD not installed"
    fi
done

###########################################################
# Apache Service
###########################################################

echo
info "Apache Service"

if systemctl is-active apache2 >/dev/null 2>&1
then
    pass "Apache is running"
else
    warn "Apache is not running"
fi

###########################################################
# Ports
###########################################################

echo
info "Checking Ports..."

if ss -tln | grep -q ":80 "
then
    pass "Port 80 listening"
else
    warn "Port 80 not listening"
fi

if ss -tln | grep -q ":443 "
then
    pass "Port 443 listening"
else
    warn "Port 443 not listening"
fi

###########################################################
# Internet
###########################################################

echo
info "Internet Connectivity"

if ping -c 1 8.8.8.8 >/dev/null 2>&1
then
    pass "Internet available"
else
    warn "No Internet connection"
fi

###########################################################
# DNS
###########################################################

echo
info "DNS Resolution"

if getent hosts google.com >/dev/null
then
    pass "DNS working"
else
    warn "DNS resolution failed"
fi

###########################################################
# Apache Modules
###########################################################

echo
info "Apache SSL Module"

if apache2ctl -M 2>/dev/null | grep -q ssl_module
then
    pass "SSL module enabled"
else
    warn "SSL module disabled"
fi

###########################################################
# Existing Certificates
###########################################################

echo
info "Checking Existing Certificates"

CERTS=(
root.crt
sub.crt
server.crt
fullchain.crt
)

for FILE in "${CERTS[@]}"
do
    if [ -f "$FILE" ]
    then
        warn "$FILE already exists"
    else
        pass "$FILE not present"
    fi
done

###########################################################
# Output Directory
###########################################################

echo
info "Output Directory"

if [ -f config.sh ]
then
    source config.sh

    if [ -d "$OUTPUT_DIR" ]
    then
        warn "Output directory already exists"
    else
        pass "Output directory available"
    fi
else
    warn "config.sh not found"
fi

###########################################################
# Apache Config
###########################################################

echo
info "Apache Configuration"

if apachectl configtest >/dev/null 2>&1
then
    pass "Apache configuration OK"
else
    fail "Apache configuration has errors"
fi

###########################################################
# Disk Space
###########################################################

echo
info "Disk Space"

SPACE=$(df -h / | awk 'NR==2 {print $4}')

echo "Available Space : $SPACE"

###########################################################
# Memory
###########################################################

echo
info "Memory"

free -h

###########################################################
# Summary
###########################################################

echo
echo "==========================================================="
echo "SUMMARY"
echo "==========================================================="

echo -e "${GREEN}PASS : $PASS${RESET}"
echo -e "${YELLOW}WARN : $WARN${RESET}"
echo -e "${RED}FAIL : $FAIL${RESET}"

echo

if [ "$FAIL" -eq 0 ]
then
    echo -e "${GREEN}Environment is ready for deployment.${RESET}"
    exit 0
else
    echo -e "${RED}Please resolve the failures before deploying.${RESET}"
    exit 1
fi