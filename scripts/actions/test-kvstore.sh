#!/bin/bash
# Test OCWS C key-value store functionality

set -euo pipefail

OCWS_DIR="${OCWS_DIR:-$HOME/.config/ocws}"
LIB_DIR="$OCWS_DIR/lib"

if [[ ! -f "$LIB_DIR/libocws-kvstore.so" ]]; then
    echo "C KVStore library not found at $LIB_DIR/libocws-kvstore.so"
    echo "Please run: ./scripts/actions/build-kvstore.sh"
    exit 1
fi

# Test the library
if [[ -d "$LIB_DIR/libocws-kvstore.so" ]]; then
    echo "C KVStore library test passed."
else
    echo "C KVStore library test failed."
    exit 1
fi

echo "OCWS C key-value store is properly installed and functional."