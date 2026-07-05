#!/usr/bin/env bash
# Build OCWS configuration engine C library

OCWS_DIR="${OCWS_DIR:-$HOME/.config/ocws}"
LIB_DIR="$OCWS_DIR/lib"
mkdir -p "$LIB_DIR"

cd "$(dirname "$0")"/../src/ocws-config.c"
echo "Building OCWS Configuration Engine..."

echo "Source files:"
for f in *.c; do echo "  $f"; done

echo "Build directory:"
ls -la

echo "Target:"
cat Makefile.inc 2>/dev/null || echo "No Makefile.inc found"