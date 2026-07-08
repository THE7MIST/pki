#!/bin/bash
# ============================================================
# 03_verify_cleanup.sh
# Final Verification & Trust Configuration
# ============================================================

set -e

if [ ! -f config.sh ]; then
    echo "[ERROR] config.sh not found!"
    exit 1
fi

source config.sh

cd "$OUTPUT_DIR"

echo "====================================================="
echo "      FINAL VERIFICATION & TRUST CONFIGURATION"
echo "====================================================="

############################################################
# Install Root CA
############################################################

echo
echo "[1/12] Installing Root CA into Trust Store..."

cp root.crt /usr/local/share/ca-certificates/rootca.crt

############################################################
# Update Certificates
############################################################

echo
echo "[2/12] Updating Trusted Certificates..."

update-ca-certificates

############################################################
# Verify Apache Configuration
############################################################

echo
echo "[3/12] Verifying Apache Configuration..."

apachectl configtest

############################################################
# Restart Apache
############################################################

echo
echo "[4/12] Restarting Apache..."

systemctl restart apache2

############################################################
# Apache Status
############################################################

echo
echo "[5/12] Apache Status..."

systemctl --no-pager status apache2

############################################################
# Verify Certificate Chain
############################################################

echo
echo "[6/12] Verifying Certificate Chain..."

openssl verify \
    -CAfile root.crt \
    -untrusted sub.crt \
    server.crt

############################################################
# Verify Root Certificate
############################################################

echo
echo "[7/12] Root CA Information..."

openssl x509 \
    -in root.crt \
    -noout \
    -subject \
    -issuer \
    -dates

############################################################
# Verify Sub CA
############################################################

echo
echo "[8/12] Sub CA Information..."

openssl x509 \
    -in sub.crt \
    -noout \
    -subject \
    -issuer \
    -dates

############################################################
# Verify Server Certificate
############################################################

echo
echo "[9/12] Server Certificate Information..."

openssl x509 \
    -in server.crt \
    -text \
    -noout

############################################################
# OpenSSL HTTPS Test
############################################################

echo
echo "[10/12] HTTPS Test (OpenSSL)..."

openssl s_client \
    -connect ${DOMAIN}:443 \
    -servername ${DOMAIN} \
    </dev/null

############################################################
# CURL TEST
############################################################

echo
echo "[11/12] HTTPS Test (curl)..."

curl -Iv https://${DOMAIN}

############################################################
# DNS Verification
############################################################

echo
echo "[12/12] DNS Verification..."

echo
echo "getent hosts"
getent hosts ${DOMAIN}

echo
echo "nslookup"
nslookup ${DOMAIN} || true

echo
echo "ping"
ping -c 4 ${DOMAIN} || true

############################################################
# Summary
############################################################

echo
echo "====================================================="
echo "                DEPLOYMENT SUMMARY"
echo "====================================================="

echo
echo "Domain                 : $DOMAIN"
echo "Server IP              : $SERVER_IP"
echo "Website Directory      : $WEBROOT"
echo "Apache Site            : $SITE_NAME"

echo
echo "Certificates"

echo "------------------------------------------"

echo "Root CA                : root.crt"

echo "Sub CA                 : sub.crt"

echo "Server Certificate     : server.crt"

echo "Full Chain             : fullchain.crt"

echo
echo "Certificate Location"

echo "------------------------------------------"

echo "$OUTPUT_DIR"

echo
echo "Verification"

echo "------------------------------------------"

echo "✔ Root CA Installed"

echo "✔ Certificate Chain Verified"

echo "✔ Apache Configuration Valid"

echo "✔ Apache Running"

echo "✔ HTTPS Enabled"

echo "✔ Website Accessible"

echo
echo "Open Browser"

echo "------------------------------------------"

echo "https://$DOMAIN"

echo
echo "HTTPS Deployment Completed Successfully."

exit 0