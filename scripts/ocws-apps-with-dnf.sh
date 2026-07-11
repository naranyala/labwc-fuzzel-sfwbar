#!/usr/bin/env bash

# OCWS Apps Installer using DNF
# This script provides an interactive menu to select and install common applications.

set -e

# Check if dnf is available
if ! command -v dnf &> /dev/null; then
    echo "Error: 'dnf' package manager is not found. This script is intended for Fedora/RHEL-based systems."
    exit 1
fi

# Check if whiptail is available (provided by newt package)
if ! command -v whiptail &> /dev/null; then
    echo "Installing 'newt' package which provides 'whiptail' for the interactive UI..."
    sudo dnf install -y newt
fi

echo "Starting OCWS Apps Installer..."

# Define available applications for checklist
# Format: "App" "Description" "ON/OFF"
CHOICES=$(whiptail --title "OCWS Fresh Install Apps" --checklist \
"Select the applications you want to install.\nUse [SPACE] to select/deselect, [UP/DOWN] to navigate, and [ENTER] to confirm." 30 90 20 \
"git" "Version control system" ON \
"curl" "Data transfer tool" ON \
"wget" "Network utility" ON \
"zsh" "Z shell" OFF \
"neovim" "Vim-based text editor" OFF \
"btop" "Resource monitor" ON \
"fastfetch" "System information tool" ON \
"eza" "Modern replacement for ls" OFF \
"ripgrep" "Line-oriented search tool (rg)" OFF \
"fd-find" "Simple, fast alternative to find" OFF \
"fzf" "Command-line fuzzy finder" OFF \
"jq" "Command-line JSON processor" OFF \
"stow" "Symlink manager (great for dotfiles)" ON \
"gcc" "GNU Compiler Collection" OFF \
"make" "Build automation tool" OFF \
"cmake" "Cross-platform build system" OFF \
"nodejs" "JavaScript runtime" OFF \
"python3-pip" "Python package installer" OFF \
"kitty" "GPU-based terminal emulator" OFF \
"alacritty" "Fast terminal emulator" OFF \
"fira-code-fonts" "Fira Code Monospaced Font" ON \
"fontawesome-fonts" "FontAwesome Icons" ON \
"tar" "Archiving utility" ON \
"unzip" "ZIP archive extraction" ON \
"p7zip" "7-Zip archiver" OFF \
"thunar" "Lightweight file manager" ON \
"gvfs" "Virtual filesystem for Thunar" ON \
"polkit-gnome" "PolicyKit authentication agent" ON \
"gnome-keyring" "Password and secret manager" ON \
"xdg-user-dirs" "Manage user directories" ON \
"xdg-utils" "Desktop integration utilities" ON \
"pavucontrol" "PulseAudio Volume Control" ON \
"pipewire-pulse" "PulseAudio server emulation" ON \
"network-manager-applet" "Network Manager UI" ON \
"blueman" "Bluetooth Manager" OFF \
"grim" "Wayland screenshot tool" ON \
"slurp" "Wayland screen region selector" ON \
"swappy" "Wayland native snapshot editor" ON \
"wl-clipboard" "Wayland copy/paste utilities" ON \
"kanshi" "Wayland dynamic display config" OFF \
"brightnessctl" "Backlight control" OFF \
"playerctl" "Media player control" OFF \
"mako" "Wayland notification daemon" OFF \
"swaybg" "Wayland wallpaper utility" OFF \
"wlogout" "Wayland logout menu" OFF \
"swayidle" "Wayland idle management daemon" OFF \
"swaylock" "Wayland screen locker" OFF \
"qt5ct" "Qt5 Configuration Tool" OFF \
"qt6ct" "Qt6 Configuration Tool" OFF \
"kvantum" "SVG-based theme engine for Qt" OFF \
"papirus-icon-theme" "Papirus icon theme" OFF \
"lxappearance" "GTK+ theme switcher" OFF \
"mpv" "Command-line media player" OFF \
"imv" "Image viewer for Wayland" OFF \
"firefox" "Web browser" OFF \
3>&1 1>&2 2>&3)

exit_status=$?

if [ $exit_status -eq 0 ]; then
    if [ -z "$CHOICES" ]; then
        echo "No applications selected. Exiting."
        exit 0
    fi
    
    # Strip quotes from whiptail output
    SELECTED_APPS=$(echo $CHOICES | tr -d '"')
    
    clear
    echo "======================================"
    echo "You have selected the following apps:"
    echo "$SELECTED_APPS"
    echo "======================================"
    echo ""
    
    # Confirm before installation
    if whiptail --title "Confirm Installation" --yesno "Proceed with installing the selected packages via DNF?" 10 60; then
        clear
        echo "Updating package repositories..."
        sudo dnf check-update || true
        
        echo "Installing packages..."
        # Using unquoted variable to allow word splitting for dnf install arguments
        sudo dnf install -y $SELECTED_APPS
        
        echo ""
        echo "======================================"
        echo "Installation complete!"
        echo "======================================"
    else
        clear
        echo "Installation cancelled by user."
    fi
else
    clear
    echo "Installation cancelled."
fi
