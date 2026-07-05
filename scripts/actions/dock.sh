#!/bin/bash
# dock.sh — Dock widget for OCWS
# Launches the enhanced dock with app pinning and task management features

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add OCWS to path
export PATH="$SCRIPT_DIR:$PATH"

# Default dock configuration
doCK_MODE="pinned"

# Display usage
usage() {
    cat << EOF
Dock Widget - App Pinning + Task Management
===========================================

Features:
  - Pinned apps: Quick launch icons
  - Running tasks: Switch between open apps
  - Recent apps: Last 10 used applications
  - Add apps: Pin new apps to the dock
  - Drag support: Move apps between categories

Usage: dock.sh <command> [options]

Commands:
  list              Show all pinned apps
  add <name> <cmd>  Add a new app to dock
  remove <name>     Remove an app from dock
  recent           Show recent apps
  clear            Clear all dock data
  help             Show this help message

Examples:
  dock.sh list
  dock.sh add terminal kitty
  dock.sh add browser firefox
  dock.sh add editor vim
EOF
exit 0
}

# List all pinned apps
list_dock_apps() {
    local apps_file="$HOME/.local/share/ocws/dock_apps"
    
    echo "Pinned Applications:"
    echo "------------------"
    
    if [[ -f "$apps_file" ]]; then
        local counter=1
        while IFS='|' read -r app_name app_cmd; do
            [[ -z "$app_name" ]] && continue
            echo "$counter. $app_name - $app_cmd"
            ((counter++))
        done < "$apps_file"
        
        echo ""
        echo "Total: $((counter-1)) applications"
    else
        echo "No pinned applications."
        echo "Use: dock.sh add <name> <command> to add apps"
    fi
}

# Add a new app to dock
add_dock_app() {
    local name="$1"
    local cmd="$2"
    
    if [[ -z "$name" || -z "$cmd" ]]; then
        echo "Error: Both app name and command required."
        echo "Usage: dock.sh add <name> <command>"
        exit 1
    fi
    
    local apps_file="$HOME/.local/share/ocws/dock_apps"
    mkdir -p "$(dirname "$apps_file")"
    
    # Add to dock apps
    echo "${name}|${cmd}" >> "$apps_file"
    echo "Added app to dock: $name"
    
    # Also add to recent apps
    local recent_file="$HOME/.local/share/ocws/recent_apps"
    echo "$cmd $name" >> "$recent_file"
}

# Remove an app from dock
remove_dock_app() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo "Error: App name required."
        echo "Usage: dock.sh remove <name>"
        exit 1
    fi
    
    local apps_file="$HOME/.local/share/ocws/dock_apps"
    
    if [[ ! -f "$apps_file" ]]; then
        echo "No apps found to remove."
        return 0
    fi
    
    # Create temporary file without the specified app
    local temp_file="$(mktemp)"
    while IFS='|' read -r app_name app_cmd; do
        if [[ "$app_name" == "$name" ]]; then
            echo "Removed app from dock: $name"
            continue
        fi
        echo "${app_name}|${app_cmd}" >> "$temp_file"
    done < "$apps_file"
    
    mv "$temp_file" "$apps_file"
}

# Show recent apps
list_recent_apps() {
    local recent_file="$HOME/.local/share/ocws/recent_apps"
    
    echo "Recent Applications (Last 10)"
    echo "----------------------------"
    
    if [[ -f "$recent_file" ]]; then
        local counter=1
        while IFS=' ' read -r cmd app_name; do
            [[ -z "$cmd" ]] && continue
            echo "$counter. $app_name - $cmd"
            ((counter++))
        done < "$recent_file"
        
        echo ""
        echo "Total: $((counter-1)) recent apps"
    else
        echo "No recent apps track found."
    fi
}

# Clear all dock data
clear_dock() {
    local apps_file="$HOME/.local/share/ocws/dock_apps"
    local recent_file="$HOME/.local/share/ocws/recent_apps"
    local history_file="$HOME/.local/share/ocws/app_history.log"
    
    echo "Clearing dock data..."
    
    rm -f "$apps_file"
    rm -f "$recent_file"
    rm -f "$history_file"
    
    mkdir -p "$(dirname "$apps_file")"
    
    echo "Dock data cleared successfully."
}

# Main execution
command="${1:-}"
shift

case "$command" in
    list|show)
        list_dock_apps
        ;;
    
    add)
        if [[ $# -lt 2 ]]; then
            echo "Error: Both app name and command required."
            usage
            exit 1
        fi
        add_dock_app "$1" "$2"
        ;;
    
    remove|rm)
        if [[ $# -lt 1 ]]; then
            echo "Error: App name required."
            usage
            exit 1
        fi
        remove_dock_app "$1"
        ;;
    
    recent)
        list_recent_apps
        ;;
    
    clear)
        clear_dock
        ;;
    
    help|--help|-h|*-help|*help)
        usage
        ;;
    
    "")
        usage
        ;;
    
    *)
        echo "Unknown command: $command"
        echo "Available commands: list, add, remove, recent, clear, help"
        exit 1
        ;;
esac
