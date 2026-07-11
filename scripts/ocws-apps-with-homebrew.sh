#!/bin/bash
# ocws-apps-with-homebrew.sh — Interactive app installer via Homebrew
# Pick and install apps to boost a fresh OCWS install.
#
# Usage:
#   ./scripts/ocws-apps-with-homebrew.sh              # interactive menu
#   ./scripts/ocws-apps-with-homebrew.sh --all         # install everything
#   ./scripts/ocws-apps-with-homebrew.sh --list        # list available apps
#   ./scripts/ocws-apps-with-homebrew.sh --status     # show installed vs available
#   ./scripts/ocws-apps-with-homebrew.sh --search X   # search apps across categories
#   ./scripts/ocws-apps-with-homebrew.sh --category X # install a category
#   ./scripts/ocws-apps-with-homebrew.sh --preset X   # install a preset bundle
#   ./scripts/ocws-apps-with-homebrew.sh --dry-run    # show what would be installed
#   ./scripts/ocws-apps-with-homebrew.sh --help       # show help

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ocws-ansi.sh"

# ── State ────────────────────────────────────────────────────────────────────────

OCWS_DIR="${OCWS_DIR:-$HOME/.config/ocws}"
INSTALL_LOG="$OCWS_DIR/apps-installed.log"
mkdir -p "$OCWS_DIR"

# ── Cached brew state (populated once at startup) ──────────────────────────────

declare -A INSTALLED_FORMULAE
declare -A INSTALLED_CASKS

cache_brew_state() {
    local line
    while IFS= read -r line; do
        INSTALLED_FORMULAE["$line"]=1
    done < <(brew list --formula 2>/dev/null || true)
    while IFS= read -r line; do
        INSTALLED_CASKS["$line"]=1
    done < <(brew list --cask 2>/dev/null || true)
}

is_installed() {
    [[ -n "${INSTALLED_FORMULAE[$1]+_}" ]] || [[ -n "${INSTALLED_CASKS[$1]+_}" ]]
}

# ── App registry ────────────────────────────────────────────────────────────────

declare -A CATEGORIES
declare -A APP_DESC
declare -A APP_CASK
declare -A APP_TAGS

# ── Browsers ────────────────────────────────────────────────────────────────────
CATEGORIES[browsers]="brave-browser chromium firefox-developer-edition microsoft-edge vivaldi google-chrome"
APP_DESC[brave-browser]="Privacy-focused Chromium browser"
APP_DESC[chromium]="Open-source browser"
APP_DESC[firefox-developer-edition]="Firefox for developers"
APP_DESC[microsoft-edge]="Microsoft Edge browser"
APP_DESC[vivaldi]="Feature-rich Chromium browser"
APP_DESC[google-chrome]="Google Chrome"

# ── Editors ─────────────────────────────────────────────────────────────────────
CATEGORIES[editors]="neovim vim helix micro nano"
APP_DESC[neovim]="Modern Vim-based editor"
APP_DESC[vim]="Classic text editor"
APP_DESC[helix]="Post-modern modal editor"
APP_DESC[micro]="Simple terminal editor"
APP_DESC[nano]="Simple GNU editor"

# ── IDEs & Code ─────────────────────────────────────────────────────────────────
CATEGORIES[ides]="code cursor"
APP_CASK[code]=""
APP_DESC[code]="Visual Studio Code"
APP_CASK[cursor]=""
APP_DESC[cursor]="AI-powered code editor"

# ── Terminals ───────────────────────────────────────────────────────────────────
CATEGORIES[terminals]="kitty alacritty wezterm"
APP_DESC[kitty]="GPU-accelerated terminal emulator"
APP_DESC[alacritty]="Fast, GPU-accelerated terminal"
APP_DESC[wezterm]="GPU-accelerated terminal + mux"

# ── Dev Tools ───────────────────────────────────────────────────────────────────
CATEGORIES[devtools]="git delta ripgrep fd fzf bat eza lazygit gh jq yq sd choose dogo watchexec"
APP_DESC[git]="Version control"
APP_DESC[delta]="Better git diffs"
APP_DESC[ripgrep]="Fast grep replacement"
APP_DESC[fd]="Fast find replacement"
APP_DESC[fzf]="Fuzzy finder"
APP_DESC[bat]="Cat with syntax highlighting"
APP_DESC[eza]="Modern ls replacement"
APP_DESC[lazygit]="Terminal git UI"
APP_DESC[gh]="GitHub CLI"
APP_DESC[jq]="JSON processor"
APP_DESC[yq]="YAML processor"
APP_DESC[sd]="Intuitive find & replace"
APP_DESC[choose]="Cut-like tool for structured text"
APP_DESC[dogo]="Dead simple linter runner"
APP_DESC[watchexec]="Runs commands on file changes"

# ── Languages & Runtimes ────────────────────────────────────────────────────────
CATEGORIES[runtimes]="node python go rustup"
APP_DESC[node]="JavaScript runtime"
APP_DESC[python]="Python 3"
APP_DESC[go]="Go programming language"
APP_DESC[rustup]="Rust toolchain installer"

# ── System Tools ────────────────────────────────────────────────────────────────
CATEGORIES[system]="btop htop tmux stow tree ncdu dust duf bottom hyperfine tokei"
APP_DESC[btop]="Modern resource monitor"
APP_DESC[htop]="Interactive process viewer"
APP_DESC[tmux]="Terminal multiplexer"
APP_DESC[stow]="Symlink manager for dotfiles"
APP_DESC[tree]="Directory tree viewer"
APP_DESC[ncdu]="Disk usage analyzer"
APP_DESC[dust]="Disk usage (modern du)"
APP_DESC[duf]="Disk usage/free (modern df)"
APP_DESC[bottom]="Process viewer (btm)"
APP_DESC[hyperfine]="Benchmarking tool"
APP_DESC[tokei]="Code statistics (LOC counter)"

# ── Networking ──────────────────────────────────────────────────────────────────
CATEGORIES[networking]="curl wget httpie nmap bandwhich dog dnslookup"
APP_DESC[curl]="URL transfer tool"
APP_DESC[wget]="Network downloader"
APP_DESC[httpie]="Human-friendly HTTP client"
APP_DESC[nmap]="Network scanner"
APP_DESC[bandwhich]="Bandwidth utilization monitor"
APP_DESC[dog]="Modern DNS client"
APP_DESC[dnslookup]="DNS lookup utility"

# ── Security ────────────────────────────────────────────────────────────────────
CATEGORIES[security]="gnupg age sops openssl"
APP_DESC[gnupg]="GNU Privacy Guard"
APP_DESC[age]="Modern file encryption"
APP_DESC[sops]="Secrets management"
APP_DESC[openssl]="TLS/SSL toolkit"

# ── Media ───────────────────────────────────────────────────────────────────────
CATEGORIES[media]="mpv ffmpeg yt-dlp imv sox"
APP_DESC[mpv]="Minimalist media player"
APP_DESC[ffmpeg]="Audio/video converter"
APP_DESC[yt-dlp]="YouTube video downloader"
APP_DESC[imv]="Simple Wayland image viewer"
APP_DESC[sox]="Sound processing Swiss army knife"

# ── Containers & Cloud ──────────────────────────────────────────────────────────
CATEGORIES[containers]="docker podman kubectl helm lazydocker dive"
APP_DESC[docker]="Container runtime"
APP_DESC[podman]="Daemonless container engine"
APP_DESC[kubectl]="Kubernetes CLI"
APP_DESC[helm]="Kubernetes package manager"
APP_DESC[lazydocker]="Terminal UI for docker"
APP_DESC[dive]="Docker image layer explorer"

# ── Clipboard & Input ──────────────────────────────────────────────────────────
CATEGORIES[clipboard]="wl-clipboard xclip"
APP_DESC[wl-clipboard]="Wayland clipboard utilities"
APP_DESC[xclip]="X11 clipboard"

# ── File Management ─────────────────────────────────────────────────────────────
CATEGORIES[files]="ranger lf yazi"
APP_DESC[ranger]="Console file manager"
APP_DESC[lf]="Terminal file manager"
APP_DESC[yazi]="Blazing fast terminal file manager"

# ── Misc / Fun ──────────────────────────────────────────────────────────────────
CATEGORIES[misc]="cowsay fortune sl cmatrix"
APP_DESC[cowsay]="Talking cow"
APP_DESC[fortune]="Random quotes"
APP_DESC[sl]="Steam locomotive"
APP_DESC[cmatrix]="Digital rain"

# ── Display order ───────────────────────────────────────────────────────────────

CATEGORY_ORDER=(
    browsers editors ides terminals devtools runtimes
    system networking security media containers clipboard files misc
)

CATEGORY_LABELS=(
    "Browsers" "Editors" "IDEs & Code" "Terminals" "Dev Tools" "Runtimes"
    "System Tools" "Networking" "Security" "Media" "Containers & Cloud"
    "Clipboard & Input" "File Management" "Misc & Fun"
)

# ── Presets ──────────────────────────────────────────────────────────────────────

declare -A PRESETS
PRESETS[minimal]="devtools:system"
PRESETS[developer]="devtools:runtimes:system:terminals:browsers:editors:ides"
PRESETS[power-user]="devtools:runtimes:system:terminals:browsers:editors:ides:networking:security:media:files"
PRESETS[wayland]="clipboard:files:media:terminals"
PRESETS[dotfiles]="system:devtools:editors:terminals"

PRESET_DESC[minimal]="Essential CLI tools + system utils"
PRESET_DESC[developer]="Full dev environment (editors + runtimes + tools)"
PRESET_DESC[power-user]="Everything available"
PRESET_DESC[wayland]="Wayland desktop essentials"
PRESET_DESC[dotfiles]="Dotfile management tools"

# ── Helpers ─────────────────────────────────────────────────────────────────────

ensure_brew() {
    if ! command -v brew &>/dev/null; then
        ocws_info "Homebrew not found. Installing..."
        source "$SCRIPT_DIR/install-brew.sh"
    fi
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null || true)"
    cache_brew_state
}

dedup() {
    local -a out=()
    local item
    for item in "$@"; do
        local found=0
        local u
        for u in "${out[@]:-}"; do
            [[ "$u" == "$item" ]] && found=1 && break
        done
        [[ $found -eq 0 ]] && out+=("$item")
    done
    printf '%s\n' "${out[@]}"
}

collect_apps_from_categories() {
    local -a cats=("$@")
    local -a all=()
    local cat
    for cat in "${cats[@]}"; do
        # trim whitespace
        cat=$(echo "$cat" | xargs)
        if [[ -n "${CATEGORIES[$cat]+_}" ]]; then
            local app
            for app in ${CATEGORIES[$cat]}; do
                all+=("$app")
            done
        fi
    done
    dedup "${all[@]}"
}

print_header() {
    echo ""
    echo -e "${OCWS_BOLD}╔══════════════════════════════════════════════════════╗${OCWS_NC}"
    echo -e "${OCWS_BOLD}║        OCWS Apps Installer (via Homebrew)           ║${OCWS_NC}"
    echo -e "${OCWS_BOLD}╚══════════════════════════════════════════════════════╝${OCWS_NC}"
    echo ""
}

progress_bar() {
    local current=$1 total=$2 width=30
    local filled=$((current * width / total))
    local empty=$((width - filled))
    local pct=$((current * 100 / total))
    printf "\r  ["
    printf '█%.0s' $(seq 1 $filled 2>/dev/null) || true
    printf '░%.0s' $(seq 1 $empty 2>/dev/null) || true
    printf "] %3d%% (%d/%d)" "$pct" "$current" "$total"
}

brew_install() {
    local pkg="$1"
    if is_installed "$pkg"; then
        return 0
    fi
    if [[ -n "${APP_CASK[$pkg]+_}" ]]; then
        brew install --cask "$pkg" 2>&1
    else
        brew install "$pkg" 2>&1
    fi
    local rc=$?
    if [[ $rc -eq 0 ]]; then
        echo "$pkg $(date -Iseconds)" >> "$INSTALL_LOG"
        # update cache
        if [[ -n "${APP_CASK[$pkg]+_}" ]]; then
            INSTALLED_CASKS["$pkg"]=1
        else
            INSTALLED_FORMULAE["$pkg"]=1
        fi
    fi
    return $rc
}

# ── List ────────────────────────────────────────────────────────────────────────

list_apps() {
    print_header
    local total=0
    local inst_count=0
    local i cat label app status
    for i in "${!CATEGORY_ORDER[@]}"; do
        cat="${CATEGORY_ORDER[$i]}"
        label="${CATEGORY_LABELS[$i]}"
        echo -e "${OCWS_CYAN}$label${OCWS_NC}"
        for app in ${CATEGORIES[$cat]}; do
            status=" "
            if is_installed "$app"; then
                status="${OCWS_GREEN}✓${OCWS_NC}"
                inst_count=$((inst_count + 1))
            fi
            printf "    [%s] %-24s %s\n" "$status" "$app" "${APP_DESC[$app]:-}"
            total=$((total + 1))
        done
        echo ""
    done
    echo -e "${OCWS_DIM}$inst_count/$total installed — ${#CATEGORY_ORDER[@]} categories${OCWS_NC}"
}

# ── Status ──────────────────────────────────────────────────────────────────────

show_status() {
    print_header
    local installed=0 available=0
    local i cat label app

    for i in "${!CATEGORY_ORDER[@]}"; do
        cat="${CATEGORY_ORDER[$i]}"
        label="${CATEGORY_LABELS[$i]}"
        local cat_apps=()
        for app in ${CATEGORIES[$cat]}; do
            available=$((available + 1))
            if is_installed "$app"; then
                cat_apps+=("$app")
                installed=$((installed + 1))
            fi
        done
        if [[ ${#cat_apps[@]} -gt 0 ]]; then
            echo -e "  ${OCWS_CYAN}$label${OCWS_NC}"
            for app in "${cat_apps[@]}"; do
                echo -e "    ${OCWS_GREEN}✓${OCWS_NC} $app"
            done
        fi
    done

    if [[ $installed -eq 0 ]]; then
        echo -e "  ${OCWS_DIM}No apps installed via Homebrew yet${OCWS_NC}"
    fi

    echo ""
    echo -e "${OCWS_BOLD}── Summary ──${OCWS_NC}"
    echo -e "  Installed: ${OCWS_GREEN}$installed${OCWS_NC} / $available"
    if [[ $available -gt 0 ]]; then
        echo -e "  Coverage:  $(( installed * 100 / available ))%"
    fi
    echo ""

    if [[ -f "$INSTALL_LOG" ]]; then
        echo -e "${OCWS_BOLD}Recent installs:${OCWS_NC}"
        tail -10 "$INSTALL_LOG" 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done
        echo ""
    fi
}

# ── Search ──────────────────────────────────────────────────────────────────────

search_apps() {
    local query="${1:-}"
    if [[ -z "$query" ]]; then
        ocws_fail "Usage: --search <query>"
    fi

    print_header
    echo -e "Searching for: ${OCWS_BOLD}$query${OCWS_NC}"
    echo ""

    local found=0 i cat label app desc status
    for i in "${!CATEGORY_ORDER[@]}"; do
        cat="${CATEGORY_ORDER[$i]}"
        label="${CATEGORY_LABELS[$i]}"
        local match_in_cat=()
        for app in ${CATEGORIES[$cat]}; do
            desc="${APP_DESC[$app]:-}"
            if [[ "${app,,}" == *"${query,,}"* ]] || [[ "${desc,,}" == *"${query,,}"* ]]; then
                status=" "
                is_installed "$app" && status="${OCWS_GREEN}✓${OCWS_NC}"
                match_in_cat+=("    [$status] $app — $desc")
                found=$((found + 1))
            fi
        done
        if [[ ${#match_in_cat[@]} -gt 0 ]]; then
            echo -e "  ${OCWS_CYAN}$label${OCWS_NC}"
            for m in "${match_in_cat[@]}"; do
                echo "$m"
            done
            echo ""
        fi
    done

    if [[ $found -eq 0 ]]; then
        echo -e "  ${OCWS_DIM}No matches found${OCWS_NC}"
    else
        echo -e "${OCWS_DIM}Found $found match(es)${OCWS_NC}"
    fi
}

# ── Interactive menu via fuzzel/rofi/wofi ───────────────────────────────────────

run_gui_menu() {
    local prompt="$1"
    local items="$2"

    if command -v fuzzel &>/dev/null; then
        echo "$items" | fuzzel --dmenu -p "$prompt" -w 50 -l 20 2>/dev/null
    elif command -v rofi &>/dev/null; then
        echo "$items" | rofi -dmenu -p "$prompt" -theme-str "window {width: 450px;}" 2>/dev/null
    elif command -v wofi &>/dev/null; then
        echo "$items" | wofi --dmenu -p "$prompt" 2>/dev/null
    else
        return 1
    fi
}

# ── Terminal-based multi-select ─────────────────────────────────────────────────

terminal_multiselect() {
    local prompt="$1"
    shift
    local -a options=("$@")
    local -a selected=()
    local cursor=0
    local page_size=18
    local page_start=0
    local total=${#options[@]}

    # Pre-build selected set as associative array for O(1) lookup
    declare -A sel_map

    while true; do
        clear
        echo -e "${OCWS_BOLD}$prompt${OCWS_NC}"
        echo -e "${OCWS_DIM}Space=toggle  Enter=confirm  a=all  n=none  j/k=scroll${OCWS_NC}"
        echo ""

        local page_end=$((page_start + page_size))
        [[ $page_end -gt $total ]] && page_end=$total

        local i marker line
        for i in $(seq $page_start $((page_end - 1))); do
            marker=" "
            [[ -n "${sel_map[$i]+_}" ]] && marker="${OCWS_GREEN}✓${OCWS_NC}"
            if [[ $i -eq $cursor ]]; then
                echo -e "${OCWS_BOLD}>${OCWS_NC}  [${marker}] ${options[$i]}"
            else
                echo "    [${marker}] ${options[$i]}"
            fi
        done

        if [[ $page_start -gt 0 ]] || [[ $page_end -lt $total ]]; then
            echo ""
            echo -e "${OCWS_DIM}  $((page_start+1))-$page_end of $total${OCWS_NC}"
        fi

        local key
        read -rsn1 key
        case "$key" in
            $'\x1b')
                local key2
                read -rsn2 -t 0.1 key2
                case "$key2" in
                    '[A')
                        [[ $cursor -gt 0 ]] && cursor=$((cursor - 1))
                        [[ $cursor -lt $page_start ]] && page_start=$cursor
                        ;;
                    '[B')
                        [[ $cursor -lt $((total - 1)) ]] && cursor=$((cursor + 1))
                        [[ $cursor -ge $((page_start + page_size)) ]] && page_start=$((cursor - page_size + 1))
                        ;;
                esac
                ;;
            'j')
                [[ $cursor -lt $((total - 1)) ]] && cursor=$((cursor + 1))
                [[ $cursor -ge $((page_start + page_size)) ]] && page_start=$((cursor - page_size + 1))
                ;;
            'k')
                [[ $cursor -gt 0 ]] && cursor=$((cursor - 1))
                [[ $cursor -lt $page_start ]] && page_start=$cursor
                ;;
            ' ')
                if [[ -n "${sel_map[$cursor]+_}" ]]; then
                    unset "sel_map[$cursor]"
                else
                    sel_map["$cursor"]=1
                fi
                ;;
            'a')
                local idx
                for idx in $(seq $page_start $((page_end - 1))); do
                    sel_map["$idx"]=1
                done
                ;;
            'n')
                unset sel_map
                declare -A sel_map
                ;;
            '')
                break
                ;;
        esac
    done

    # Collect results
    local idx
    for idx in $(seq 0 $((total - 1))); do
        [[ -n "${sel_map[$idx]+_}" ]] && echo "${options[$idx]}"
    done
}

# ── Confirmation prompt ─────────────────────────────────────────────────────────

confirm_install() {
    local -a apps=("$@")
    local total=${#apps[@]}

    echo ""
    echo -e "${OCWS_BOLD}── Will install $total app(s) ──${OCWS_NC}"
    echo ""

    local already=0 would_install=0
    local app
    for app in "${apps[@]}"; do
        if is_installed "$app"; then
            echo -e "  ${OCWS_GREEN}✓${OCWS_NC} $app ${OCWS_DIM}(already installed)${OCWS_NC}"
            already=$((already + 1))
        else
            echo -e "  ${OCWS_YELLOW}○${OCWS_NC} $app"
            would_install=$((would_install + 1))
        fi
    done

    echo ""
    if [[ $would_install -eq 0 ]]; then
        echo -e "${OCWS_DIM}Nothing to install — all $total app(s) already present.${OCWS_NC}"
        return 1
    fi

    echo -e "${OCWS_DIM}$already already installed, $would_install to install${OCWS_NC}"
    echo ""
    read -rp "Proceed? [Y/n] " answer
    case "${answer,,}" in
        n|no) return 1 ;;
        *) return 0 ;;
    esac
}

# ── Interactive picker ──────────────────────────────────────────────────────────

interactive_pick() {
    print_header

    local -a pick_items=()
    local i
    for i in "${!CATEGORY_ORDER[@]}"; do
        pick_items+=("${CATEGORY_LABELS[$i]}")
    done
    pick_items+=("--- Presets ---")
    local preset
    for preset in "${!PRESETS[@]}"; do
        pick_items+=("Preset: $preset — ${PRESET_DESC[$preset]}")
    done
    pick_items+=(">> Install ALL")

    local chosen
    if chosen=$(run_gui_menu "Pick categories:" "$(printf '%s\n' "${pick_items[@]}")"); then
        if [[ "$chosen" == ">> Install ALL" ]]; then
            install_all
            return
        fi

        # Check for preset
        if [[ "$chosen" == Preset:* ]]; then
            local preset_name
            preset_name=$(echo "$chosen" | sed 's/.*Preset: //' | sed 's/ —.*//')
            install_preset "$preset_name"
            return
        fi

        # Map GUI label back to category name
        local -a chosen_cats=()
        while IFS= read -r line; do
            for i in "${!CATEGORY_LABELS[@]}"; do
                if [[ "$line" == "${CATEGORY_LABELS[$i]}" ]]; then
                    chosen_cats+=("${CATEGORY_ORDER[$i]}")
                fi
            done
        done <<< "$chosen"

        local -a unique_apps
        unique_apps=$(collect_apps_from_categories "${chosen_cats[@]}")

        local selected
        selected=$(terminal_multiselect "Select apps to install:" "${unique_apps[@]}")

        if [[ -z "$selected" ]]; then
            ocws_warn "No apps selected."
            return
        fi

        local -a selected_arr
        mapfile -t selected_arr <<< "$selected"
        install_apps "${selected_arr[@]}"
    else
        terminal_category_pick
    fi
}

terminal_category_pick() {
    local -a cat_labels=()
    local i
    for i in "${!CATEGORY_ORDER[@]}"; do
        cat_labels+=("${CATEGORY_LABELS[$i]}")
    done

    local chosen
    chosen=$(terminal_multiselect "Select categories:" "${cat_labels[@]}")

    if [[ -z "$chosen" ]]; then
        ocws_warn "No categories selected."
        return
    fi

    # Map label back to category name
    local -a chosen_cats=()
    while IFS= read -r line; do
        for i in "${!CATEGORY_LABELS[@]}"; do
            if [[ "$line" == "${CATEGORY_LABELS[$i]}" ]]; then
                chosen_cats+=("${CATEGORY_ORDER[$i]}")
            fi
        done
    done <<< "$chosen"

    local -a unique_apps
    unique_apps=$(collect_apps_from_categories "${chosen_cats[@]}")

    local selected
    selected=$(terminal_multiselect "Select apps to install:" "${unique_apps[@]}")

    if [[ -z "$selected" ]]; then
        ocws_warn "No apps selected."
        return
    fi

    local -a selected_arr
    mapfile -t selected_arr <<< "$selected"
    install_apps "${selected_arr[@]}"
}

# ── Install logic ───────────────────────────────────────────────────────────────

install_apps() {
    local -a apps=("$@")
    local dry_run="${DRY_RUN:-0}"
    local total=${#apps[@]}
    local ok=0 fail=0 skip=0

    ensure_brew

    if [[ "$dry_run" != "1" ]]; then
        confirm_install "${apps[@]}" || return 0
    fi

    echo ""
    ocws_info "Installing $total apps via Homebrew..."
    echo ""

    local app idx=0
    for app in "${apps[@]}"; do
        idx=$((idx + 1))
        progress_bar $idx $total

        if [[ "$dry_run" == "1" ]]; then
            if is_installed "$app"; then
                skip=$((skip + 1))
            else
                echo ""
                echo -e "  ${OCWS_YELLOW}○${OCWS_NC} $app"
            fi
            continue
        fi

        if is_installed "$app"; then
            skip=$((skip + 1))
            continue
        fi

        if brew_install "$app" >/dev/null 2>&1; then
            ok=$((ok + 1))
        else
            echo ""
            echo -e "  ${OCWS_RED}✗${OCWS_NC} $app failed"
            fail=$((fail + 1))
        fi
    done

    echo ""
    echo ""
    echo -e "${OCWS_BOLD}── Results ──${OCWS_NC}"
    if [[ "$dry_run" == "1" ]]; then
        echo -e "  Would install: $((total - skip))"
        echo -e "  Already have:   $skip"
    else
        echo -e "  ${OCWS_GREEN}Installed: $ok${OCWS_NC}"
        echo -e "  Skipped:   $skip (already installed)"
        [[ $fail -gt 0 ]] && echo -e "  ${OCWS_RED}Failed:    $fail${OCWS_NC}"
    fi
    echo ""
}

install_all() {
    ensure_brew
    print_header
    ocws_info "Installing ALL available apps..."
    echo ""

    local -a all_apps=()
    local cat app
    for cat in "${CATEGORY_ORDER[@]}"; do
        for app in ${CATEGORIES[$cat]}; do
            all_apps+=("$app")
        done
    done

    local -a unique
    unique=$(dedup "${all_apps[@]}")
    local -a unique_arr
    mapfile -t unique_arr <<< "$unique"
    install_apps "${unique_arr[@]}"
}

install_preset() {
    local preset="${1:-}"
    if [[ -z "${PRESETS[$preset]+_}" ]]; then
        ocws_fail "Unknown preset: $preset. Available: ${!PRESETS[*]}"
    fi

    ensure_brew
    print_header
    echo -e "${OCWS_CYAN}Preset:${OCWS_NC} $preset — ${PRESET_DESC[$preset]}"
    echo ""

    IFS=':' read -ra parts <<< "${PRESETS[$preset]}"
    local -a apps
    apps=$(collect_apps_from_categories "${parts[@]}")

    local -a apps_arr
    mapfile -t apps_arr <<< "$apps"
    install_apps "${apps_arr[@]}"
}

# ── CLI ─────────────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTION]

Interactive app installer via Homebrew for OCWS fresh installs.

Options:
  (none)              Interactive category + app picker
  --all, -a           Install all available apps
  --list, -l          List all available apps (checkmarks show installed)
  --status, -s        Show installed vs available summary
  --search, -q <q>    Search apps by name or description
  --category, -c <n>  Install a specific category
  --preset, -p <n>    Install a preset bundle
  --dry-run, -d       Show what would be installed (no changes)
  --help, -h          Show this help

Categories:
$(for c in "${CATEGORY_ORDER[@]}"; do echo "  $c"; done)

Presets:
  minimal      Essential CLI tools + system utils
  developer    Full dev environment (editors + runtimes + tools)
  power-user   Everything available
  wayland      Wayland desktop essentials
  dotfiles     Dotfile management tools

Examples:
  $(basename "$0")                     # interactive picker
  $(basename "$0") --preset developer  # install developer bundle
  $(basename "$0") -c devtools         # install dev tools category
  $(basename "$0") -q editor           # search for editor apps
  $(basename "$0") -d --all            # preview what --all would do
EOF
}

main() {
    case "${1:-}" in
        --all|-a)
            install_all
            ;;
        --list|-l)
            ensure_brew
            list_apps
            ;;
        --status|-s)
            ensure_brew
            show_status
            ;;
        --search|-q)
            ensure_brew
            search_apps "${2:-}"
            ;;
        --category|-c)
            local cat="${2:-}"
            if [[ -z "$cat" ]]; then
                ocws_fail "Missing category name. Available: ${CATEGORY_ORDER[*]}"
            fi
            local found=0 c
            for c in "${CATEGORY_ORDER[@]}"; do
                [[ "$c" == "$cat" ]] && found=1 && break
            done
            [[ $found -eq 0 ]] && ocws_fail "Unknown category: $cat. Available: ${CATEGORY_ORDER[*]}"
            ensure_brew
            print_header
            echo -e "${OCWS_CYAN}Category:${OCWS_NC} $cat"
            install_apps ${CATEGORIES[$cat]}
            ;;
        --preset|-p)
            local preset="${2:-}"
            if [[ -z "$preset" ]]; then
                ocws_fail "Missing preset name. Available: ${!PRESETS[*]}"
            fi
            install_preset "$preset"
            ;;
        --dry-run|-d)
            DRY_RUN=1
            shift
            main "$@"
            ;;
        --help|-h)
            usage
            ;;
        *)
            interactive_pick
            ;;
    esac
}

main "$@"
