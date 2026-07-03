#!/bin/bash
#
# download-labwc.sh — Download latest labwc source from GitHub, build, and install
# Cleans up source after build. No leftover files.
#
set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"

info()  { echo -e "\033[0;34m[INFO]\033[0m  $*"; }
pass()  { echo -e "\033[0;32m[PASS]\033[0m  $*"; }
fail()  { echo -e "\033[0;31m[FAIL]\033[0m  $*"; exit 1; }

cleanup() { [[ -n "${TMPDIR:-}" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"; }
trap cleanup EXIT

# -------------------------------------------------------------------
# 1. Check build dependencies
# -------------------------------------------------------------------
info "Checking build dependencies..."
MISSING=()
for cmd in meson ninja gcc pkg-config curl; do
  command -v "$cmd" &>/dev/null || MISSING+=("$cmd")
done
if [ ${#MISSING[@]} -gt 0 ]; then
  fail "Missing build tools: ${MISSING[*]}\n  Install them with your package manager (e.g. sudo apt install meson ninja-build gcc pkg-config curl)"
fi

for lib in wayland-client wlroots libxml-2.0 cairo pangocairo glib-2.0 libinput libpng xkbcommon; do
  if ! pkg-config --exists "$lib" 2>/dev/null; then
    MISSING+=("$lib")
  fi
done
if [ ${#MISSING[@]} -gt 0 ]; then
  fail "Missing libraries: ${MISSING[*]}\n  Install dev packages (e.g. sudo apt install libwayland-dev libwlroots-dev libxml2-dev libcairo2-dev libpango1.0-dev libglib2.0-dev libinput-dev libpng-dev libxkbcommon-dev)"
fi
pass "Build dependencies OK"

# -------------------------------------------------------------------
# 2. Determine latest version from GitHub
# -------------------------------------------------------------------
info "Fetching latest labwc release from GitHub..."
REPO="labwc/labwc"
API_URL="https://api.github.com/repos/$REPO/releases/latest"
TAG=$(curl -sL "$API_URL" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\(.*\)",/\1/')

if [ -z "$TAG" ]; then
  info "No release found, using master branch"
  TAG="master"
  TARBALL_URL="https://github.com/$REPO/archive/refs/heads/master.tar.gz"
else
  info "Latest release: $TAG"
  TARBALL_URL="https://github.com/$REPO/archive/refs/tags/$TAG.tar.gz"
fi

# -------------------------------------------------------------------
# 3. Download and extract
# -------------------------------------------------------------------
TMPDIR=$(mktemp -d)
info "Downloading labwc source ($TAG) ..."
curl -sL "$TARBALL_URL" -o "$TMPDIR/labwc.tar.gz"

info "Extracting ..."
EXTRACT_DIR=$(tar -tzf "$TMPDIR/labwc.tar.gz" | head -1 | cut -d/ -f1)
tar -xzf "$TMPDIR/labwc.tar.gz" -C "$TMPDIR"
SRC_DIR="$TMPDIR/$EXTRACT_DIR"
pass "Source ready"

# -------------------------------------------------------------------
# 4. Build
# -------------------------------------------------------------------
info "Building labwc ($TAG) ..."
cd "$SRC_DIR"
meson setup build/ || fail "meson setup failed"
meson compile -C build/ || fail "meson compile failed"
pass "Build successful"

# -------------------------------------------------------------------
# 5. Install (optional — requires sudo)
# -------------------------------------------------------------------
if [ "${1:-}" = "--install" ] || [ "${1:-}" = "-i" ]; then
  info "Installing labwc to $PREFIX ..."
  meson install --skip-subprojects -C build/ || fail "meson install failed"
  pass "labwc $TAG installed to $PREFIX"
  labwc --version 2>/dev/null && pass "labwc is available in PATH" || warn "labwc not in PATH yet — log out/in or add $PREFIX/bin to PATH"
else
  info "Build complete. To install system-wide, run:"
  info "  sudo $0 --install"
  info "Or re-run this script with --install:"
  info "  ./download-labwc.sh --install"
fi

# Source cleaned up automatically by trap
pass "Done. Run labwc with: ./scripts/start-labwc.sh"
