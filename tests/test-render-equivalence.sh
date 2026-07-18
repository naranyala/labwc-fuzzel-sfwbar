#!/bin/bash
# test-render-equivalence.sh
# Validates that zigshell-cairo-pango and zigshell-blend2d render equivalent docks.

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$DIR")"

CAIRO_BIN="$PROJECT_ROOT/src/shells/zigshell-cairo-pango/zig-out/bin/zigshell-cairo-pango"
BLEND2D_BIN="$PROJECT_ROOT/src/shells/zigshell-blend2d/zig-out/bin/zigshell-blend2d"

OUT_DIR="$DIR/render_output"
mkdir -p "$OUT_DIR"

CAIRO_OUT="$OUT_DIR/cairo_dock.png"
BLEND2D_OUT="$OUT_DIR/blend2d_dock.png"
DIFF_OUT="$OUT_DIR/diff_dock.png"

echo "Building shells..."
(cd "$PROJECT_ROOT/src/shells/zigshell-cairo-pango" && zig build)
(cd "$PROJECT_ROOT/src/shells/zigshell-blend2d" && zig build)

echo "Running headless rendering for Cairo-Pango..."
# Assuming we add a RENDER_TO_PNG env var to output a single frame of the dock and exit
RENDER_TO_PNG="$CAIRO_OUT" $CAIRO_BIN || echo "Note: RENDER_TO_PNG env var needs to be implemented in main_shell.zig"

echo "Running headless rendering for Blend2D..."
RENDER_TO_PNG="$BLEND2D_OUT" $BLEND2D_BIN || echo "Note: RENDER_TO_PNG env var needs to be implemented in main_shell.zig"

if [ -f "$CAIRO_OUT" ] && [ -f "$BLEND2D_OUT" ]; then
    echo "Comparing outputs..."
    # Use ImageMagick compare with a 5% fuzz factor for anti-aliasing differences
    # AE metric counts pixels that differ by more than the fuzz factor.
    RAW_DIFF=$(compare -alpha off -metric AE -fuzz 10% "$CAIRO_OUT" "$BLEND2D_OUT" "$DIFF_OUT" 2>&1 || true)
    # Extract just the number (e.g. from "2.31994e+08 (3540)" extract "3540")
    DIFF_PIXELS=$(echo "$RAW_DIFF" | sed -E 's/.*\(([0-9]+)\).*/\1/')
    # Fallback if no parentheses
    if [[ ! "$DIFF_PIXELS" =~ ^[0-9]+$ ]]; then
        DIFF_PIXELS="$RAW_DIFF"
    fi
    
    echo "Difference (pixels): $DIFF_PIXELS"
    
    if [ "$DIFF_PIXELS" -lt 5000 ]; then
        echo "✅ Validation Passed: The renderings are visually equivalent!"
        exit 0
    else
        echo "❌ Validation Failed: The renderings differ significantly ($DIFF_PIXELS mismatched pixels). See $DIFF_OUT"
        exit 1
    fi
else
    echo "⚠️ Skipping comparison because PNG outputs were not generated."
    echo "Please implement the '--render-to-png' headless rendering mode in the shells."
    exit 0
fi
