#!/bin/bash
# -------------------------------------------------------------------
# OCWS Theme Scheduler
# Auto-switches theme based on time of day
# Usage: theme-scheduler.sh [schedule.ini]
# -------------------------------------------------------------------

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
THEME_ENGINE="$SCRIPT_DIR/theme-engine.sh"
STATE_FILE="$HOME/.config/ocws/state/current-theme"

# Default schedule: map hours to themes
DEFAULT_SCHEDULE=$(cat << 'EOF'
# Hour range → Theme name
# Format: HH-HH theme_name
# Hours use 24h format. Ranges can wrap past midnight (e.g., 22-6).
06-12 catppuccin-mocha
12-18tokyo-night
18-22 dracula
22-06 nord
EOF
)

SCHEDULE_FILE="${1:-$HOME/.config/ocws/theme-schedule.ini}"

# Parse schedule file or use default
declare -A SCHEDULE_HOURS
declare -a SCHEDULE_RANGES

parse_schedule() {
    local file="$1"
    local content

    if [[ -f "$file" ]]; then
        content=$(cat "$file")
    else
        content="$DEFAULT_SCHEDULE"
    fi

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue

        # Parse "HH-HH theme_name"
        if [[ "$line" =~ ^([0-9]{2})-([0-9]{2})[[:space:]]+(.+)$ ]]; then
            local start="${BASH_REMATCH[1]}"
            local end="${BASH_REMATCH[2]}"
            local theme="${BASH_REMATCH[3]}"
            SCHEDULE_RANGES+=("$start|$end|$theme")
        fi
    done <<< "$content"
}

# Get current hour (0-23)
get_current_hour() {
    date +%H
}

# Find theme for current hour
get_theme_for_hour() {
    local hour=$(get_current_hour)
    local hour_num=$((10#$hour))

    for range in "${SCHEDULE_RANGES[@]}"; do
        IFS='|' read -r start end theme <<< "$range"
        local start_num=$((10#$start))
        local end_num=$((10#$end))

        if [[ $start_num -le $end_num ]]; then
            # Normal range: e.g., 06-18
            if [[ $hour_num -ge $start_num && $hour_num -lt $end_num ]]; then
                echo "$theme"
                return
            fi
        else
            # Wrapping range: e.g., 22-06
            if [[ $hour_num -ge $start_num || $hour_num -lt $end_num ]]; then
                echo "$theme"
                return
            fi
        fi
    done

    # Fallback: first theme in list
    IFS='|' read -r _ _ theme <<< "${SCHEDULE_RANGES[0]}"
    echo "$theme"
}

# Apply theme if different from current
apply_if_needed() {
    local target_theme="$1"
    local current_theme=""

    if [[ -f "$STATE_FILE" ]]; then
        current_theme=$(cat "$STATE_FILE")
    fi

    if [[ "$current_theme" != "$target_theme" ]]; then
        local theme_file="$PROJECT_DIR/themes/${target_theme}.ini"
        if [[ -f "$theme_file" ]]; then
            echo "Switching theme: ${current_theme:-none} → $target_theme"
            "$THEME_ENGINE" apply "$theme_file"
            mkdir -p "$(dirname "$STATE_FILE")"
            echo "$target_theme" > "$STATE_FILE"
        else
            echo "Theme not found: $theme_file"
        fi
    fi
}

# Main
parse_schedule "$SCHEDULE_FILE"
TARGET=$(get_theme_for_hour)
apply_if_needed "$TARGET"
