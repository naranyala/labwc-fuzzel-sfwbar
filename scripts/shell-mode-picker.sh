#!/bin/bash
# Uses fuzzel to select shell mode

declare -A MODES=(
    ["1. Noctalia (Default)"]="noctalia"
    ["2. SFWBar + Crystal Dock"]="crystal_dock"
    ["3. SFWBar Dual Panel"]="double_panel"
)

# Generate list for fuzzel
OPTIONS=""
for key in "${!MODES[@]}"; do
    OPTIONS+="$key\n"
done

# Run fuzzel
SELECTION=$(echo -e "$OPTIONS" | sort | fuzzel -d -p "Select Shell Mode: " -l 3)

if [ -n "$SELECTION" ]; then
    MODE_ID="${MODES[$SELECTION]}"
    if [ -n "$MODE_ID" ]; then
        /home/naranyala/.local/bin/shell-switcher.sh "$MODE_ID" &
    fi
fi
