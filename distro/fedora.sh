#!/bin/bash
set -euo pipefail

echo "Installing OCWS dependencies for Fedora..."

PKGS=(
    labwc fuzzel foot rofi mako qt6ct
    swaybg swayidle swaylock gammastep dunst
    playerctl wl-clipboard cliphist grim slurp
    jq crudini libxml2
)

if dnf search sfwbar | grep -qi "sfwbar"; then
    PKGS+=(sfwbar)
else
    echo "Warning: sfwbar not found in DNF repos. You may need to compile from source or add a COPR."
fi

sudo dnf install -y "${PKGS[@]}"

echo "Dependencies successfully installed."
