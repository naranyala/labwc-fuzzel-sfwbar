#!/usr/bin/env bash
# Install OCWS key-value store C library dependencies

set -euo pipefail

OCWS_DIR="${OCWS_DIR:-$HOME/.config/ocws}"

# Install system dependencies
if command -v yum >/dev/null 2>&1; then
    sudo yum install -y gcc make libc6-dev  # RHEL/CentOS/Fedora
elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y gcc make libc-dev  # Debian/Ubuntu
elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S base-devel  # Arch Linux
else
    echo "Unsupported package manager. Please install gcc and make manually."
    exit 1
fi

echo "Dependencies installed successfully."