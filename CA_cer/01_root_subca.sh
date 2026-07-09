#!/bin/bash
# ============================================================
# 01_root_subca.sh
# Generates:
#   - Root CA
#   - Sub CA
# Requires:
#   config.sh
# ============================================================

set -e

if [ ! -f config.sh ]; then
    echo "[ERROR] config.sh not found!"
    exit 1
fi

source config.sh

echo "=============================================="
echo "        ROOT CA + SUB CA CREATION"
echo "=============================================="

mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

############################################################
# ROOT EXTENSION FILE
############################################################

cat > root.ext <<EOF
basicConstraints=critical,CA:TRUE
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
EOF

############################################################
# SUB EXTENSION FILE
############################################################

cat > sub.ext <<EOF
basicConstraints=critical,CA:TRUE,pathlen:0
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
EOF

############################################################
echo
echo "[1/10] Generating Root CA Private Key..."
############################################################

openssl genpkey \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:$KEY_SIZE \
    -out root.key

echo "Done."

############################################################
echo
echo "[2/10] Generating Root CA CSR..."
############################################################

openssl req \
    -new \
    -key root.key \
    -out root.csr \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=$OU/CN=$ROOT_CA_NAME"

echo "Done."

############################################################
echo
echo "[3/10] Creating Root Certificate..."
############################################################

openssl x509 \
    -req \
    -in root.csr \
    -signkey root.key \
    -out root.crt \
    -days "$ROOT_VALIDITY" \
    -extfile root.ext

echo "Done."

############################################################
echo
echo "[4/10] Verifying Root Certificate..."
############################################################

openssl x509 \
    -in root.crt \
    -text \
    -noout

echo
echo "Root Certificate Verified."

############################################################
echo
echo "[5/10] Generating Sub CA Private Key..."
############################################################

openssl genpkey \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:$KEY_SIZE \
    -out sub.key

echo "Done."

############################################################
echo
echo "[6/10] Generating Sub CA CSR..."
############################################################

openssl req \
    -new \
    -key sub.key \
    -out sub.csr \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=$OU/CN=$SUB_CA_NAME"

echo "Done."

############################################################
echo
echo "[7/10] Signing Sub CA Certificate..."
############################################################

openssl x509 \
    -req \
    -in sub.csr \
    -CA root.crt \
    -CAkey root.key \
    -CAcreateserial \
    -out sub.crt \
    -days "$SUB_VALIDITY" \
    -extfile sub.ext

echo "Done."

############################################################
echo
echo "[8/10] Verifying Sub CA Certificate..."
############################################################

openssl x509 \
    -in sub.crt \
    -text \
    -noout

echo
echo "Sub CA Certificate Verified."

############################################################
echo
echo "[9/10] Verifying Certificate Chain..."
############################################################

openssl verify \
    -CAfile root.crt \
    sub.crt

############################################################
echo
echo "[10/10] Generated Files"
############################################################

ls -lh

echo
echo "=============================================="
echo "Root CA & Sub CA Successfully Created"
echo "=============================================="

echo
echo "Generated Files:"
echo "-----------------------------"
echo "root.key"
echo "root.csr"
echo "root.crt"
echo "root.srl"
echo
echo "sub.key"
echo "sub.csr"
echo "sub.crt"
echo
echo "root.ext"
echo "sub.ext"
echo
echo "Location:"
echo "$OUTPUT_DIR"
echo
exit 0