#!/bin/bash
# ============================================================
# functions.sh
# Common Functions for PKI HTTPS Deployment Automation
# ============================================================

##############################
# Colors
##############################

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
MAGENTA="\e[35m"
WHITE="\e[97m"
RESET="\e[0m"

##############################
# Icons
##############################

OK="[ OK ]"
INFO="[INFO]"
WARN="[WARN]"
FAIL="[FAIL]"

##############################
# Logging
##############################

LOGFILE="deployment.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $1" >> "$LOGFILE"
}

##############################
# Messages
##############################

info() {
    echo -e "${BLUE}${INFO}${RESET} $1"
    log "[INFO] $1"
}

success() {
    echo -e "${GREEN}${OK}${RESET} $1"
    log "[SUCCESS] $1"
}

warning() {
    echo -e "${YELLOW}${WARN}${RESET} $1"
    log "[WARNING] $1"
}

error() {
    echo -e "${RED}${FAIL}${RESET} $1"
    log "[ERROR] $1"
    exit 1
}

##############################
# Header
##############################

header() {

echo
echo "========================================================"
echo "$1"
echo "========================================================"
echo

}

##############################
# Check Root
##############################

check_root() {

if [[ $EUID -ne 0 ]]
then
    error "Please run this script using sudo or as root."
fi

}

##############################
# Check Command Exists
##############################

check_command() {

command -v "$1" >/dev/null 2>&1 || \
error "$1 is not installed."

}

##############################
# Install Package
##############################

install_package() {

PKG=$1

if dpkg -s "$PKG" >/dev/null 2>&1
then
    success "$PKG already installed."
else
    info "Installing $PKG ..."
    apt-get update
    apt-get install -y "$PKG"
fi

}

##############################
# Backup File
##############################

backup_file() {

FILE=$1

if [ -f "$FILE" ]
then

cp "$FILE" "$FILE.bak"

success "Backup created -> $FILE.bak"

fi

}

##############################
# Check File Exists
##############################

check_file() {

FILE=$1

if [ ! -f "$FILE" ]
then
    error "Missing file: $FILE"
fi

}

##############################
# Check Directory Exists
##############################

check_directory() {

DIR=$1

if [ ! -d "$DIR" ]
then
    mkdir -p "$DIR"
fi

}

##############################
# Progress
##############################

progress() {

STEP=$1
TOTAL=$2
MSG=$3

echo
echo "[$STEP/$TOTAL] $MSG"

}

##############################
# Execute Command
##############################

run_cmd() {

CMD="$1"

info "$CMD"

eval "$CMD"

if [ $? -eq 0 ]
then
    success "Completed"
else
    error "Command Failed"
fi

}

##############################
# Verify Certificate
##############################

verify_certificate() {

FILE=$1

check_file "$FILE"

openssl x509 \
-in "$FILE" \
-noout \
-subject \
-issuer \
-dates

}

##############################
# Restart Apache
##############################

restart_apache() {

systemctl restart apache2

systemctl is-active apache2 >/dev/null

if [ $? -eq 0 ]
then
    success "Apache restarted."
else
    error "Apache failed to restart."
fi

}

##############################
# Reload Apache
##############################

reload_apache() {

systemctl reload apache2

success "Apache reloaded."

}

##############################
# Apache Config Test
##############################

apache_test() {

apachectl configtest

}

##############################
# Update Certificates
##############################

update_trust() {

update-ca-certificates

}

##############################
# Print Line
##############################

line() {

echo "--------------------------------------------------------"

}

##############################
# Pause
##############################

pause() {

read -p "Press ENTER to continue..."

}

##############################
# Finish
##############################

finish() {

echo
echo "========================================================"
echo "Deployment Completed Successfully"
echo "========================================================"

}

##############################
# Fail Trap
##############################

trap 'echo -e "\n${RED}[ERROR] Script stopped unexpectedly.${RESET}"' ERR