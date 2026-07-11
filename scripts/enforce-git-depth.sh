#!/bin/bash
# ==============================================================================
# script: enforce-git-depth.sh
# description: Detects `git clone` without `--depth=1` and automatically fixes them
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${CYAN}==> Scanning repository for shallow clone violations...${NC}"

# Find all files containing "git clone"
files_with_clones=$(grep -Rl "git clone" "$ROOT_DIR" | grep -v "/.git/")

VIOLATIONS_FOUND=0
FIXES_APPLIED=0

for file in $files_with_clones; do
    # Skip this script itself to prevent it modifying its own logic
    if [[ "$file" == *"enforce-git-depth.sh"* ]]; then
        continue
    fi

    # Read file line by line to keep line numbers for reporting
    line_num=1
    while IFS= read -r line; do
        # Check if line has "git clone" but DOES NOT have "--depth"
        if echo "$line" | grep -q "git clone" && ! echo "$line" | grep -Eq -- "--depth(=| )"; then
            echo -e "${YELLOW}[Violating Line]${NC} ${file#"$ROOT_DIR/"}:$line_num: $line"
            VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
        fi
        line_num=$((line_num + 1))
    done < "$file"

    # Automatically fix the file using sed if violations exist in it
    if grep -q "git clone" "$file" && ! grep -q "\-\-depth" "$file"; then
        # This replaces `git clone ` with `git clone --depth=1 `
        sed -i 's/git clone /git clone --depth=1 /g' "$file"
        echo -e "${GREEN}  ✓ Auto-fixed in ${file#"$ROOT_DIR/"}${NC}"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    # Handle cases where some lines have depth and others don't in the same file
    elif grep -q "git clone" "$file"; then
        # Uses a more precise sed that ignores lines already containing --depth
        sed -i '/--depth/! s/git clone /git clone --depth=1 /g' "$file"
    fi
done

echo ""
if [ "$VIOLATIONS_FOUND" -eq 0 ]; then
    echo -e "${GREEN}✅ Perfect! All 'git clone' commands are already shallow clones (--depth=1).${NC}"
else
    echo -e "${GREEN}✅ Fixed $VIOLATIONS_FOUND violations across $FIXES_APPLIED files.${NC}"
fi
