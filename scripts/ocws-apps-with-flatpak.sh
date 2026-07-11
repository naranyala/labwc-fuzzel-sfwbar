#!/bin/bash
# ==============================================================================
# script: ocws-apps-with-flatpak.sh
# description: Interactive app installer for fresh OCWS installs
#              Pick and install apps from curated categories via Flatpak
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()  { echo -e "\n${CYAN}==>${NC} $*"; }
pass()  { echo -e "  ${GREEN}✓${NC} $*"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $*"; }
fail()  { echo -e "  ${RED}✗${NC} $*"; exit 1; }
header() { echo -e "\n${BOLD}$*${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Ensure Flatpak is available
# ---------------------------------------------------------------------------
ensure_flatpak() {
    if ! command -v flatpak &>/dev/null; then
        info "Flatpak not found. Installing..."
        if [ -f "$SCRIPT_DIR/scripts/install-flatpak.sh" ]; then
            bash "$SCRIPT_DIR/scripts/install-flatpak.sh"
        else
            if command -v dnf &>/dev/null; then
                sudo dnf install -y flatpak
            elif command -v apt-get &>/dev/null; then
                sudo apt-get install -y flatpak
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm flatpak
            else
                fail "Could not install Flatpak. No supported package manager found."
            fi
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
        fi
    fi

    if ! flatpak remote-list 2>/dev/null | grep -q flathub; then
        info "Adding Flathub repository..."
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
    fi
    pass "Flatpak ready."
}

# ---------------------------------------------------------------------------
# App catalog — format: "id|display name|description"
# Every app ID appears in exactly one category (zero duplicates)
# ---------------------------------------------------------------------------
declare -a CAT_BROWSERS=(
    "org.mozilla.firefox|Firefox|Mozilla Firefox web browser"
    "com.google.Chrome|Google Chrome|Google Chrome web browser"
    "com.brave.Browser|Brave|Privacy-focused Chromium browser"
    "org.chromium.Chromium|Chromium|Open-source browser project"
    "com.vivaldi.Vivaldi|Vivaldi|Feature-rich Chromium browser"
    "io.gitlab.librewolf-community|LibreWolf|Privacy-hardened Firefox fork"
    "org.gnome.Epiphany|Epiphany|GNOME web browser"
    "org.torproject.torbrowser-launcher|Tor Browser|Anonymizing browser"
)

declare -a CAT_MEDIA=(
    "org.videolan.VLC|VLC|Media player and framework"
    "io.github.celluloid_player.Celluloid|Celluloid|MPV-based GTK4 video player"
    "com.obsproject.Studio|OBS Studio|Streaming and recording"
    "com.github.Matemu.kew|Kew|Terminal music player"
    "io.github.nickvision.cavalier|Cavalier|Audio visualizer (CAVA GUI)"
    "com.mastermindzh.tidal-hifi|TIDAL HiFi|Music streaming"
    "io.github.lumeer.MusicPod|MusicPod|Music, podcast, and radio player"
    "io.github.nickvision.Aura|Aura|Music player"
    "io.github.nickvision.parabolic|Parabolic|Media downloader (yt-dlp GUI)"
    "io.github.nickvision.tagger|Tagger|Music file tag editor"
    "com.github.nickvision.money|Money|Personal finance tracker"
    "io.github.GradienceTeam.Gradience|Gradience|GTK4 theme customizer"
)

declare -a CAT_COMMUNICATION=(
    "com.discordapp.Discord|Discord|Voice, video, and text chat"
    "org.telegram.desktop|Telegram|Telegram Messenger"
    "org.signal.Signal|Signal|Encrypted messaging"
    "us.zoom.Zoom|Zoom|Video conferencing"
    "io.element.Element|Element|Matrix protocol client"
    "com.mattermost.Desktop|Mattermost|Team messaging"
    "com.slack.Slack|Slack|Team collaboration"
    "org.jitsi.jitsi-meet|Jitsi Meet|Video conferencing (self-hosted)"
)

declare -a CAT_DEVELOPMENT=(
    "com.visualstudio.code|VS Code|Code editor by Microsoft"
    "com.sublimetext.SublimeText|Sublime Text|Sophisticated text editor"
    "io.github.shiftrtech.wezterm|WezTerm|GPU-accelerated terminal"
)

declare -a CAT_CREATIVE=(
    "org.gimp.GIMP|GIMP|Image editor"
    "org.inkscape.Inkscape|Inkscape|Vector graphics editor"
    "org.kde.krita|Krita|Digital painting"
    "org.blender.Blender|Blender|3D modeling and rendering"
    "com.github.nickvision.akira|Akira|UI/UX design tool"
    "org.kde.kdenlive|Kdenlive|Non-linear video editor"
    "org.shotcut.Shotcut|Shotcut|Video editor"
)

declare -a CAT_OFFICE=(
    "org.libreoffice.LibreOffice|LibreOffice|Full office suite"
    "com.onlyoffice.DesktopEditors|OnlyOffice|Office suite (MS format compatible)"
    "md.obsidian.Obsidian|Obsidian|Markdown knowledge base"
    "com.logseq.Logseq|Logseq|Outliner and knowledge base"
    "com.zellij.Zellij|Zellij|Terminal multiplexer"
    "org.gnome.Calculator|Calculator|GNOME calculator"
    "org.gnome.Calendar|Calendar|GNOME calendar"
)

declare -a CAT_GRAPHICS=(
    "org.darktable.Darktable|Darktable|Photography workflow and RAW editor"
    "org.gnome.Shotwell|Shotwell|Photo organizer"
    "org.kde.gwenview|Gwenview|Image viewer and editor"
    "org.kde.spectacle|Spectacle|Screenshot tool"
)

declare -a CAT_AUDIO=(
    "org.audacityteam.Audacity|Audacity|Audio editor"
    "com.nikoss.libra|Libra|Audio recorder and editor"
)

declare -a CAT_SYSTEM=(
    "com.github.tchx84.GParted|GParted|Partition editor"
    "org.gnome.FileRoller|File Roller|Archive manager"
    "com.transmissionbt.Transmission|Transmission|BitTorrent client"
    "com.mattjakeman.ExtensionManager|Extension Manager|GNOME Shell extensions"
    "io.github.nickvision.poweroption|Power Options|Power management"
    "com.usebottles.Bottles|Bottles|Wine prefix manager"
    "org.gnome.baobab|Disk Usage Analyzer|Disk space visualization"
    "io.github.nickvision.uzuri|Uzuri|GTK theme manager"
)

declare -a CAT_UTILITIES=(
    "org.gnome.TextEditor|Text Editor|Simple text editor"
)

declare -a CAT_GAMING=(
    "com.valvesoftware.Steam|Steam|Valve gaming platform"
    "com.heroicgameslauncher.hgl|Heroic Games|Epic/GOG/Amazon games"
    "net.lutris.Lutris|Lutris|Open gaming platform"
    "org.libretune.RetroArch|RetroArch|Retro gaming emulator frontend"
    "com.dosbox.DOSBox|DOSBox|DOS emulator"
)

declare -a CAT_PRIVACY=(
    "com.protonvpn|ProtonVPN|VPN by Proton"
    "org.keepassxc.KeePassXC|KeePassXC|Password manager"
)

declare -a CAT_PRODUCTIVITY=(
    "org.gnome.Todo|Todo|GNOME task manager"
)

# Category metadata: "VAR_NAME|Label|Icon"
declare -a CATEGORIES=(
    "CAT_BROWSERS|Browsers|🌐"
    "CAT_MEDIA|Media & Entertainment|🎵"
    "CAT_COMMUNICATION|Communication|💬"
    "CAT_DEVELOPMENT|Development|🛠"
    "CAT_CREATIVE|Creative|🎨"
    "CAT_OFFICE|Office & Productivity|📝"
    "CAT_GRAPHICS|Graphics & Photography|📷"
    "CAT_AUDIO|Audio Production|🎧"
    "CAT_SYSTEM|System Utilities|⚙"
    "CAT_UTILITIES|Utilities|🔧"
    "CAT_GAMING|Gaming|🎮"
    "CAT_PRIVACY|Privacy & Security|🔒"
    "CAT_PRODUCTIVITY|Productivity|⚡"
)

# ---------------------------------------------------------------------------
# Display a category and collect selections
# Returns selected app IDs in the global SELECTED_APPS array
# ---------------------------------------------------------------------------
SELECTED_APPS=()

display_category() {
    local var_name="$1"
    local label="$2"
    local -n apps_ref="$var_name"
    local count=${#apps_ref[@]}

    if [ "$count" -eq 0 ]; then
        return
    fi

    header "  $label"
    local idx=1
    for entry in "${apps_ref[@]}"; do
        IFS='|' read -r app_id app_name app_desc <<< "$entry"
        local installed_mark=""
        if flatpak list --app 2>/dev/null | grep -q "$app_id"; then
            installed_mark=" ${GREEN}[installed]${NC}"
        fi
        echo -e "    ${CYAN}${idx}${NC}) ${app_name}${NC} — ${DIM}${app_desc}${NC}${installed_mark}"
        idx=$((idx + 1))
    done
    echo -e "    ${DIM}Enter numbers separated by spaces, 'all' for everything, or Enter to skip${NC}"
    echo -n "    Selection: "
    read -r choices

    if [ -z "$choices" ]; then
        return
    fi

    if [ "$choices" = "all" ]; then
        for entry in "${apps_ref[@]}"; do
            IFS='|' read -r app_id _ _ <<< "$entry"
            SELECTED_APPS+=("$app_id")
        done
        return
    fi

    for choice in $choices; do
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
            local idx2=1
            for entry in "${apps_ref[@]}"; do
                if [ "$idx2" -eq "$choice" ]; then
                    IFS='|' read -r app_id _ _ <<< "$entry"
                    SELECTED_APPS+=("$app_id")
                    break
                fi
                idx2=$((idx2 + 1))
            done
        else
            warn "Invalid selection: $choice (skipped)"
        fi
    done
}

# ---------------------------------------------------------------------------
# Install selected apps via Flatpak
# ---------------------------------------------------------------------------
install_selected() {
    if [ ${#SELECTED_APPS[@]} -eq 0 ]; then
        info "No apps selected. Nothing to install."
        return
    fi

    # Deduplicate
    local -a unique=()
    for app in "${SELECTED_APPS[@]}"; do
        local found=false
        for u in "${unique[@]+"${unique[@]}"}"; do
            if [ "$u" = "$app" ]; then found=true; break; fi
        done
        if [ "$found" = false ]; then
            unique+=("$app")
        fi
    done
    SELECTED_APPS=("${unique[@]}")

    local total=${#SELECTED_APPS[@]}
    header "Installing $total app(s) via Flatpak..."
    echo ""

    local installed=0
    local skipped=0
    local failed=0

    for app_id in "${SELECTED_APPS[@]}"; do
        # Already installed?
        if flatpak list --app 2>/dev/null | grep -q "$app_id"; then
            echo -e "  ${YELLOW}⏭${NC} $app_id — already installed"
            skipped=$((skipped + 1))
            continue
        fi

        echo -e "  ${CYAN}↓${NC} Installing $app_id..."
        if flatpak install -y flathub "$app_id" 2>&1 | tail -1; then
            pass "$app_id installed"
            installed=$((installed + 1))
        else
            warn "Failed to install $app_id"
            failed=$((failed + 1))
        fi
    done

    echo ""
    header "Summary"
    echo -e "  Installed: ${GREEN}${installed}${NC}"
    echo -e "  Skipped (already present): ${YELLOW}${skipped}${NC}"
    [ "$failed" -gt 0 ] && echo -e "  Failed: ${RED}${failed}${NC}"
    echo ""
}

# ---------------------------------------------------------------------------
# Show currently installed Flatpak apps
# ---------------------------------------------------------------------------
show_installed() {
    info "Currently installed Flatpak apps:"
    if flatpak list --app 2>/dev/null | grep -q .; then
        flatpak list --app --columns=name,application 2>/dev/null | while IFS=$'\t' read -r name appid; do
            echo -e "  ${GREEN}✓${NC} $name ${DIM}($appid)${NC}"
        done
    else
        echo -e "  ${DIM}No Flatpak apps installed.${NC}"
    fi
    echo ""
}

# ---------------------------------------------------------------------------
# Uninstall interactive
# ---------------------------------------------------------------------------
uninstall_mode() {
    info "Installed Flatpak apps:"
    local -a app_ids=()
    local idx=1
    while IFS=$'\t' read -r name appid; do
        [ -z "$appid" ] && continue
        echo -e "  ${CYAN}${idx}${NC}) $name ${DIM}($appid)${NC}"
        app_ids+=("$appid")
        idx=$((idx + 1))
    done < <(flatpak list --app --columns=name,application 2>/dev/null)

    if [ ${#app_ids[@]} -eq 0 ]; then
        echo -e "  ${DIM}Nothing to uninstall.${NC}"
        return
    fi

    echo ""
    echo -e "  ${DIM}Enter numbers to uninstall, separated by spaces${NC}"
    echo -n "  Selection: "
    read -r choices

    for choice in $choices; do
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#app_ids[@]}" ]; then
            local app_id="${app_ids[$((choice - 1))]}"
            echo -e "  ${CYAN}↓${NC} Uninstalling $app_id..."
            flatpak uninstall -y "$app_id" 2>&1 | tail -1
            pass "$app_id removed"
        else
            warn "Invalid: $choice"
        fi
    done
}

# ---------------------------------------------------------------------------
# Main menu
# ---------------------------------------------------------------------------
main() {
    echo -e "\n${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║   OCWS Apps Installer                       ║${NC}"
    echo -e "${BOLD}║   Pick apps for your fresh install           ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"

    ensure_flatpak

    while true; do
        echo ""
        echo -e "  ${CYAN}1${NC}) Install apps"
        echo -e "  ${CYAN}2${NC}) Show installed Flatpak apps"
        echo -e "  ${CYAN}3${NC}) Uninstall Flatpak apps"
        echo -e "  ${CYAN}4${NC}) Quit"
        echo -n "  Choose [1-4]: "
        read -r action

        case "${action:-4}" in
            1)
                SELECTED_APPS=()
                echo ""
                for cat_entry in "${CATEGORIES[@]}"; do
                    IFS='|' read -r var_name label icon <<< "$cat_entry"
                    display_category "$var_name" "$label"
                done

                if [ ${#SELECTED_APPS[@]} -gt 0 ]; then
                    echo ""
                    header "Selected apps:"
                    for app_id in "${SELECTED_APPS[@]}"; do
                        echo -e "  ${CYAN}•${NC} $app_id"
                    done
                    echo -n "  Proceed with installation? [Y/n]: "
                    read -r confirm
                    if [[ ! "${confirm:-Y}" =~ ^[Nn]$ ]]; then
                        install_selected
                    else
                        info "Cancelled."
                    fi
                else
                    info "No apps selected."
                fi
                ;;
            2)
                show_installed
                ;;
            3)
                uninstall_mode
                ;;
            4|q|Q)
                echo -e "\n  ${GREEN}Done.${NC}\n"
                exit 0
                ;;
            *)
                warn "Invalid choice."
                ;;
        esac
    done
}

main "$@"
