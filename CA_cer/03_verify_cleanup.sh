#!/bin/bash
# ============================================================
# 03_verify_cleanup.sh
# Final Verification, Trust Installation & Browser Import
# ============================================================

set -e

if [ ! -f config.sh ]; then
    echo "[ERROR] config.sh not found!"
    exit 1
fi

source config.sh

############################################################
# Verify Output Directory
############################################################

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "[ERROR] Output directory not found: $OUTPUT_DIR"
    exit 1
fi

cd "$OUTPUT_DIR"

############################################################
# Verify Required Files
############################################################

REQUIRED_FILES=(
    root.crt
    sub.crt
    server.crt
    server.key
    fullchain.crt
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "[ERROR] Missing file: $file"
        exit 1
    fi
done

echo "====================================================="
echo " FINAL VERIFICATION & TRUST CONFIGURATION"
echo "====================================================="

############################################################
# Install Root CA
############################################################

echo
echo "[1/14] Installing Root CA into System Trust Store..."

sudo rm -f /usr/local/share/ca-certificates/rootca.crt
sudo cp root.crt /usr/local/share/ca-certificates/rootca.crt

############################################################
# Update Trust Store
############################################################

echo
echo "[2/14] Updating Trusted Certificates..."

sudo update-ca-certificates --fresh

############################################################
# Verify Apache Configuration
############################################################

echo
echo "[3/14] Verifying Apache Configuration..."

sudo apachectl configtest

############################################################
# Restart Apache
############################################################

echo
echo "[4/14] Restarting Apache..."

sudo systemctl restart apache2

############################################################
# Apache Status
############################################################

echo
echo "[5/14] Apache Service Status..."

sudo systemctl --no-pager status apache2

############################################################
# Verify Certificate Chain
############################################################

echo
echo "[6/14] Verifying Certificate Chain..."

openssl verify \
    -CAfile root.crt \
    -untrusted sub.crt \
    server.crt

############################################################
# Verify Root Certificate
############################################################

echo
echo "[7/14] Root CA Information..."

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
echo "[8/14] Sub CA Information..."

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
echo "[9/14] Server Certificate Information..."

openssl x509 \
    -in server.crt \
    -text \
    -noout

############################################################
# OpenSSL HTTPS Test
############################################################

echo
echo "[10/14] HTTPS Test (OpenSSL)..."

openssl s_client \
    -connect "${DOMAIN}:443" \
    -servername "${DOMAIN}" \
    -verify_return_error \
    -brief \
    </dev/null

############################################################
# CURL TEST
############################################################

echo
echo "[11/14] HTTPS Test (curl)..."

curl --fail --silent --show-error -Iv "https://${DOMAIN}"

############################################################
# DNS Verification
############################################################

echo
echo "[12/14] DNS Verification..."

echo
echo "getent hosts"
getent hosts "${DOMAIN}"

echo
echo "nslookup"
nslookup "${DOMAIN}" || true

echo
echo "ping"
ping -c 4 "${DOMAIN}" || true

############################################################
# Firefox Trust (APT + Snap Firefox)
############################################################

echo
echo "[13/14] Importing Root CA into Firefox..."

# Install certutil if missing
if ! command -v certutil >/dev/null 2>&1; then
    echo "Installing libnss3-tools..."
    sudo apt-get update -y
    sudo apt-get install -y libnss3-tools
fi

# Detect Firefox Profile (APT or Snap)
PROFILE=$(find \
    "$HOME/.mozilla/firefox" \
    "$HOME/snap/firefox/common/.mozilla/firefox" \
    -maxdepth 1 \
    -type d \
    -name "*.default*" 2>/dev/null | head -n 1)

if [ -n "$PROFILE" ]; then

    echo "Firefox Profile : $PROFILE"

    # Remove old certificate (if it exists)
    certutil \
        -D \
        -d "sql:$PROFILE" \
        -n "$ROOT_CA_NAME" \
        2>/dev/null || true

    # Import Root CA
    certutil \
        -A \
        -d "sql:$PROFILE" \
        -n "$ROOT_CA_NAME" \
        -t "CT,C,C" \
        -i "$OUTPUT_DIR/root.crt"

    echo "[OK] Root CA imported into Firefox."

    # Restart Firefox if running
    if pgrep firefox >/dev/null; then
        echo "Restarting Firefox..."
        pkill firefox
        sleep 2
    fi

    nohup firefox >/dev/null 2>&1 &

else
    echo "[INFO] Firefox profile not found. Skipping Firefox import."
fi

############################################################
# Deployment Summary
############################################################

echo
echo "====================================================="
echo "               DEPLOYMENT SUMMARY"
echo "====================================================="

echo
echo "Domain                 : $DOMAIN"
echo "Server IP              : $SERVER_IP"
echo "Website Directory      : $WEBROOT"
echo "Apache Site            : $SITE_NAME"

echo
echo "Certificates"
echo "-----------------------------------------------------"
echo "Root CA                : root.crt"
echo "Sub CA                 : sub.crt"
echo "Server Certificate     : server.crt"
echo "Certificate Chain      : fullchain.crt"

echo
echo "Certificate Location"
echo "-----------------------------------------------------"
echo "$OUTPUT_DIR"

echo
echo "Verification"
echo "-----------------------------------------------------"
echo "✔ Root CA Installed"
echo "✔ Certificate Chain Verified"
echo "✔ Apache Configuration Valid"
echo "✔ Apache Running"
echo "✔ HTTPS Enabled"
echo "✔ DNS Resolution Verified"

if [ -n "$PROFILE" ]; then
    echo "✔ Firefox Root CA Imported"
else
    echo "⚠ Firefox Root CA Not Imported (Profile Not Found)"
fi

echo
echo "Open Browser"
echo "-----------------------------------------------------"
echo "https://$DOMAIN"

echo
echo "====================================================="
echo "      HTTPS DEPLOYMENT COMPLETED SUCCESSFULLY"
echo "====================================================="

exit 0
