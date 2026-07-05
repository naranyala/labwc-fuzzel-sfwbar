#!/bin/bash
# shell-mode.sh — Switch between shell modes: sfwbar-plus, sfwbar, and legacy modes

MODE="${1:-}"

if [ -z "$MODE" ]; then
  echo "Usage: $0 <mode>"
  echo ""
  echo "Modes:"
  echo "  sfwbar-plus  labwc + enhanced OCWS with rich shell features (default)"
  echo "  sfwbar       labwc + sfwbar only (minimal OCWS)"
  echo ""
  echo "Legacy modes (mapped to sfwbar-plus):"
  echo "  noctalia     labwc + noctalia shell"
  echo "  crystal      labwc + crystal-dock only"
  echo "  both         labwc + both sfwbar + crystal-dock"
  echo ""
  echo "Current mode: $(cat ~/.config/labwc-widgets/shell-mode 2>/dev/null || echo sfwbar-plus)"
  exit 0
fi

# API: Support both old and new mode names
if [ "$MODE" = "noctalia" ]; then
    echo "⚠️  WARNING: 'noctalia' mode is deprecated. Use 'sfwbar-plus' for equivalent functionality."
    echo "   Noctalia features are being incorporated into sfwbar-plus."
    MODE="sfwbar-plus"
    echo "$MODE" > ~/.config/labwc-widgets/shell-mode
    if [ -x "$(dirname "${BASH_SOURCE[0]}")/../scripts/toggle-shell" ]; then
        "$(dirname "${BASH_SOURCE[0]}")/../scripts/toggle-shell" "$MODE"
    else
        echo "Error: toggle-shell script not found"
        exit 1
    fi
    exit 0
fi

if [ "$MODE" = "crystal" ]; then
    echo "⚠️  WARNING: 'crystal' mode is deprecated. Use 'sfwbar-plus' for enhanced features."
    echo "   Crystal-dock features are being incorporated into sfwbar-plus."
    MODE="sfwbar-plus"
    echo "$MODE" > ~/.config/labwc-widgets/shell-mode
    if [ -x "$(dirname "${BASH_SOURCE[0]}")/../scripts/toggle-shell" ]; then
        "$(dirname "${BASH_SOURCE[0]}")/../scripts/toggle-shell" "$MODE"
    else
        echo "Error: toggle-shell script not found"
        exit 1
    fi
    exit 0
fi

if [ "$MODE" = "both" ]; then
    echo "⚠️  WARNING: 'both' mode is deprecated. Use 'sfwbar-plus' for unified shell with both panels."
    echo "   The dual-panel configuration is now part of 'sfwbar-plus' mode."
    MODE="sfwbar-plus"
    echo "$MODE" > ~/.config/labwc-widgets/shell-mode
    if [ -x "$(dirname "${BASH_SOURCE[0]}")/../scripts/toggle-shell" ]; then
        "$(dirname "${BASH_SOURCE[0]}")/../scripts/toggle-shell" "$MODE"
    else
        echo "Error: toggle-shell script not found"
        exit 1
    fi
    exit 0
fi

if [ "$MODE" != "sfwbar" ] && [ "$MODE" != "sfwbar-plus" ]; then
    echo "Error: Invalid mode '$MODE'"
    echo "Valid modes: sfwbar, sfwbar-plus"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
if [ -x "$SCRIPT_DIR/scripts/toggle-shell" ]; then
  "$SCRIPT_DIR/scripts/toggle-shell" "$MODE"
else
  echo "Error: toggle-shell script not found at $SCRIPT_DIR/scripts/toggle-shell"
  exit 1
fi

echo "✅ Shell mode changed to: $MODE"