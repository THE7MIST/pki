#!/bin/bash

set -e

echo "[+] Updating packages..."
sudo apt update

echo "[+] Installing dependencies..."
sudo apt install -y \
build-essential \
cmake \
qtbase5-dev \
qttools5-dev \
libqt5svg5-dev \
libssl-dev

echo "[+] Moving to Downloads..."
cd ~/Downloads

echo "[+] Extracting archive..."
tar -xzf xca-2.9.0.tar.gz

echo "[+] Entering source directory..."
cd xca-2.9.0

echo "[+] Creating build directory..."
mkdir -p build
cd build

echo "[+] Configuring build..."
cmake ..

echo "[+] Compiling..."
make -j$(nproc)

echo "[+] Installing..."
sudo make install

echo "[+] Verifying installation..."
which xca

echo "[+] Launching XCA..."
xca &