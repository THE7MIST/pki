#!/bin/bash
# ============================================================
# rollback.sh
# Removes PKI HTTPS Deployment and Restores Apache
# ============================================================

set -e

##############################################
# Check config
##############################################

if [ ! -f config.sh ]; then
    echo "[ERROR] config.sh not found."
    exit 1
fi

source config.sh

echo
echo "========================================================="
echo "            HTTPS DEPLOYMENT ROLLBACK"
echo "========================================================="
echo

read -p "Are you sure? This will remove the deployment. (y/N): " CHOICE

case "$CHOICE" in
    y|Y)
        ;;
    *)
        echo "Rollback cancelled."
        exit 0
        ;;
esac

##############################################
# Disable Website
##############################################

echo
echo "[1/12] Disabling Apache Site..."

if [ -f /etc/apache2/sites-available/$SITE_NAME.conf ]; then
    a2dissite "$SITE_NAME.conf"
fi

##############################################
# Enable Default Site
##############################################

echo
echo "[2/12] Enabling Default Site..."

if [ -f /etc/apache2/sites-available/000-default.conf ]; then
    a2ensite 000-default.conf
fi

##############################################
# Remove VirtualHost
##############################################

echo
echo "[3/12] Removing VirtualHost..."

rm -f "/etc/apache2/sites-available/$SITE_NAME.conf"

##############################################
# Remove Apache ServerName
##############################################

echo
echo "[4/12] Removing ServerName..."

sed -i "\|^ServerName $DOMAIN|d" /etc/apache2/apache2.conf

##############################################
# Remove Hosts Entry
##############################################

echo
echo "[5/12] Removing /etc/hosts Entry..."

sed -i "\|$DOMAIN|d" /etc/hosts

##############################################
# Remove Root CA
##############################################

echo
echo "[6/12] Removing Trusted Root CA..."

rm -f /usr/local/share/ca-certificates/rootca.crt

##############################################
# Update Trust Store
##############################################

echo
echo "[7/12] Updating CA Certificates..."

update-ca-certificates

##############################################
# Remove Output Directory
##############################################

echo
echo "[8/12] Removing Generated Certificates..."

if [ -d "$OUTPUT_DIR" ]; then
    rm -rf "$OUTPUT_DIR"
fi

##############################################
# Remove Website Files
##############################################

echo
echo "[9/12] Removing Website..."

if [ -d "$WEBROOT" ]; then
    rm -rf "$WEBROOT"
fi

##############################################
# Reload Apache
##############################################

echo
echo "[10/12] Reloading Apache..."

systemctl daemon-reload

##############################################
# Restart Apache
##############################################

echo
echo "[11/12] Restarting Apache..."

systemctl restart apache2

##############################################
# Apache Status
##############################################

echo
echo "[12/12] Apache Status..."

systemctl --no-pager status apache2

##############################################
# Summary
##############################################

echo
echo "========================================================="
echo "             ROLLBACK COMPLETED"
echo "========================================================="

echo
echo "Removed:"
echo "-----------------------------------------"
echo "✔ Root CA Trust"
echo "✔ Server Certificate"
echo "✔ Sub CA Certificate"
echo "✔ Root CA Certificate"
echo "✔ Certificate Chain"
echo "✔ Website"
echo "✔ VirtualHost"
echo "✔ Apache ServerName"
echo "✔ Hosts Entry"
echo "✔ Output Directory"

echo
echo "Apache restored to default configuration."

echo
exit 0