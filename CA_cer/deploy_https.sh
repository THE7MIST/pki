#!/bin/bash
# ============================================================
# deploy_https.sh
# Master Script for PKI HTTPS Deployment
# Calls:
#   01_root_subca.sh
#   02_server_apache.sh
#   03_verify_cleanup.sh
# ============================================================
chmod +x *.sh
./check_environment.sh

set -e

clear

echo "======================================================"
echo "         PKI HTTPS Deployment Automation"
echo "======================================================"
echo

#----------------------------------------------------------
# Root Privilege Check
#----------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] Please run this script as root."
    echo
    echo "Example:"
    echo "sudo ./deploy_https.sh"
    exit 1
fi

#----------------------------------------------------------
# OpenSSL Check
#----------------------------------------------------------
if ! command -v openssl &>/dev/null; then
    echo "[INFO] Installing OpenSSL..."
    apt update
    apt install -y openssl
fi

#----------------------------------------------------------
# Apache Check
#----------------------------------------------------------
if ! command -v apache2 &>/dev/null; then
    echo "[INFO] Installing Apache..."
    apt update
    apt install -y apache2
fi

#----------------------------------------------------------
# DNS Utilities
#----------------------------------------------------------
apt install -y dnsutils curl >/dev/null 2>&1

echo
echo "========== PKI HTTPS Deployment Automation =========="
echo

##############################
# Root CA
##############################

echo "----- Root CA Details -----"

read -p "Root CA Name (Ex. MIST Root CA): " ROOT_CA_NAME
read -p "Country Code (Ex. IN): " COUNTRY
read -p "State/Province (Ex. Maharashtra): " STATE
read -p "City/Locality (Ex. Pune): " CITY
read -p "Organization (Ex. MIST): " ORG
read -p "Organizational Unit (Ex. Cyber Security): " OU
read -p "Root CA Validity in Days (Ex. 3650): " ROOT_VALIDITY

echo

##############################
# Sub CA
##############################

echo "----- Sub CA Details -----"

read -p "Sub CA Name (Ex. MIST Sub CA): " SUB_CA_NAME
read -p "Sub CA Validity in Days (Ex. 1825): " SUB_VALIDITY

echo

##############################
# Server Certificate
##############################

echo "----- Web Server Certificate -----"

read -p "Website Domain (Ex. www.mist.ac.in): " DOMAIN

read -p "Subject Alternative Names (Comma separated): " SAN

read -p "Server Certificate Validity (Ex. 365): " SERVER_VALIDITY

echo

##############################
# Web Server
##############################

echo "----- Web Server -----"

read -p "Server IP Address: " SERVER_IP

read -p "Website Document Root (Ex. /var/www/mist): " WEBROOT

read -p "Apache Site Name (Ex. mist): " SITE_NAME

echo

##############################
# Crypto
##############################

echo "----- Cryptography -----"

read -p "RSA Key Size [2048]: " KEY_SIZE

KEY_SIZE=${KEY_SIZE:-2048}

echo

##############################
# Output
##############################

echo "----- Output -----"

read -p "Certificate Output Directory: " OUTPUT_DIR

mkdir -p "$OUTPUT_DIR"

echo

###########################################################
# Save Configuration
###########################################################

cat > config.sh <<EOF
ROOT_CA_NAME="$ROOT_CA_NAME"
COUNTRY="$COUNTRY"
STATE="$STATE"
CITY="$CITY"
ORG="$ORG"
OU="$OU"

ROOT_VALIDITY="$ROOT_VALIDITY"

SUB_CA_NAME="$SUB_CA_NAME"
SUB_VALIDITY="$SUB_VALIDITY"

DOMAIN="$DOMAIN"
SAN="$SAN"
SERVER_VALIDITY="$SERVER_VALIDITY"

SERVER_IP="$SERVER_IP"

WEBROOT="$WEBROOT"

SITE_NAME="$SITE_NAME"

KEY_SIZE="$KEY_SIZE"

OUTPUT_DIR="$OUTPUT_DIR"
EOF

chmod +x config.sh

echo
echo "======================================="
echo "Configuration Saved Successfully"
echo "======================================="
echo

cat config.sh

echo
read -p "Continue Deployment? (Y/N): " choice

case "$choice" in
    y|Y)
        ;;
    *)
        echo
        echo "Deployment Cancelled."
        exit
        ;;
esac

###########################################################
# Check Required Scripts
###########################################################

FILES=(
"01_root_subca.sh"
"02_server_apache.sh"
"03_verify_cleanup.sh"
)

for f in "${FILES[@]}"
do
    if [[ ! -f "$f" ]]; then
        echo
        echo "[ERROR] Missing File -> $f"
        exit 1
    fi
done

chmod +x 01_root_subca.sh
chmod +x 02_server_apache.sh
chmod +x 03_verify_cleanup.sh

echo
echo "======================================="
echo "Starting Deployment..."
echo "======================================="
echo

sleep 2

###########################################################
# Execute Scripts
###########################################################

echo "[1/3] Running Root/Sub CA Setup..."
./01_root_subca.sh

echo
echo "[2/3] Running Server & Apache Setup..."
./02_server_apache.sh

echo
echo "[3/3] Running Verification..."
./03_verify_cleanup.sh

echo
echo "======================================="
echo "HTTPS Deployment Completed Successfully"
echo "======================================="
echo

echo "Certificates Location : $OUTPUT_DIR"
echo "Website Directory     : $WEBROOT"
echo "Domain                : $DOMAIN"

echo
echo "Open Browser:"
echo "https://$DOMAIN"

echo
exit 0
