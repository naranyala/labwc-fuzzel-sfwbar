#!/usr/bin/env bash
# build-wayland.sh — Build and install bleeding-edge Wayland from source
#
# Builds wayland 1.26.90 (dev) from sources/wayland/ and installs to
# /usr/local so it doesn't conflict with system packages.
#
# Usage:
#   ./build-wayland.sh              # Full build + install
#   ./build-wayland.sh --prefix=/opt/wayland  # Custom prefix
#   ./build-wayland.sh --build-only  # Build without installing
#   ./build-wayland.sh --validate    # Run validation after install

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCES_DIR="${SCRIPT_DIR}/sources"
WAYLAND_SRC="${SOURCES_DIR}/wayland"
WAYLAND_PROTO_SRC="${SOURCES_DIR}/wayland-protocols"

# Defaults
PREFIX="/usr/local"
BUILD_ONLY=false
DO_VALIDATE=false
JOBS=$(nproc 2>/dev/null || echo 4)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()    { echo -e "${GREEN}[+]${NC} $*"; }
warn()   { echo -e "${YELLOW}[!]${NC} $*"; }
err()    { echo -e "${RED}[x]${NC} $*" >&2; }
header() { echo -e "\n${CYAN}═══ $* ═══${NC}"; }

# ── Parse args ───────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix=*)    PREFIX="${1#*=}" ;;
        --build-only)  BUILD_ONLY=true ;;
        --validate)    DO_VALIDATE=true ;;
        --jobs=*)      JOBS="${1#*=}" ;;
        -h|--help)
            echo "Usage: $0 [--prefix=/path] [--build-only] [--validate] [--jobs=N]"
            exit 0
            ;;
        *) err "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# ── Check prerequisites ─────────────────────────────────────────────────

header "Checking prerequisites"

check_cmd() {
    if ! command -v "$1" &>/dev/null; then
        err "Required command not found: $1"
        return 1
    fi
}

MISSING=()
for cmd in meson ninja gcc pkg-config; do
    check_cmd "$cmd" || MISSING+=("$cmd")
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    err "Missing tools: ${MISSING[*]}"
    echo "Install with: dnf install ${MISSING[*]} (or your package manager)"
    exit 1
fi

# Check libffi
if ! pkg-config --exists libffi 2>/dev/null; then
    err "libffi not found. Install: dnf install libffi-devel"
    exit 1
fi

log "All prerequisites found"
log "  meson:  $(meson --version)"
log "  ninja:  $(ninja --version)"
log "  gcc:    $(gcc --version | head -1)"
log "  prefix: $PREFIX"
log "  jobs:   $JOBS"

# ── Check sources exist ─────────────────────────────────────────────────

header "Checking source trees"

if [[ ! -d "$WAYLAND_SRC/.git" ]]; then
    err "Wayland source not found at $WAYLAND_SRC"
    err "Run ./download-wayland.sh first"
    exit 1
fi

if [[ ! -d "$WAYLAND_PROTO_SRC/.git" ]]; then
    err "wayland-protocols source not found at $WAYLAND_PROTO_SRC"
    err "Run ./download-wayland.sh first"
    exit 1
fi

WAYLAND_VER=$(grep "version:" "$WAYLAND_SRC/meson.build" | head -1 | sed "s/.*'\(.*\)'.*/\1/")
PROTO_VER=$(grep "version:" "$WAYLAND_PROTO_SRC/meson.build" | head -1 | sed "s/.*'\(.*\)'.*/\1/")
log "Wayland source version: $WAYLAND_VER"
log "wayland-protocols source version: $PROTO_VER"

# ── Build wayland-protocols ─────────────────────────────────────────────

header "Building wayland-protocols"

PROTO_BUILD="${WAYLAND_PROTO_SRC}/build"
PROTO_INSTALL="${PREFIX}"

if [[ -d "$PROTO_BUILD" ]]; then
    log "Reconfiguring wayland-protocols..."
    meson setup --reconfigure --prefix="$PROTO_INSTALL" "$PROTO_BUILD" "$WAYLAND_PROTO_SRC" >/dev/null
else
    log "Configuring wayland-protocols..."
    meson setup --prefix="$PROTO_INSTALL" "$PROTO_BUILD" "$WAYLAND_PROTO_SRC" >/dev/null
fi

log "Installing wayland-protocols..."
DESTDIR="" ninja -C "$PROTO_BUILD" install >/dev/null
log "wayland-protocols installed to $PROTO_INSTALL"

# ── Build wayland ───────────────────────────────────────────────────────

header "Building wayland $WAYLAND_VER"

WAYLAND_BUILD="${WAYLAND_SRC}/build"

# Clean previous build for reproducibility
if [[ -d "$WAYLAND_BUILD" ]]; then
    log "Cleaning previous build..."
    rm -rf "$WAYLAND_BUILD"
fi

log "Configuring wayland..."
# Build with tests disabled for faster compilation, static libraries for Zig linking
meson setup \
    --prefix="$PREFIX" \
    --buildtype=release \
    --default-library=both \
    -Dtests=false \
    -Ddocumentation=false \
    -Dlibraries=true \
    -Dscanner=true \
    "$WAYLAND_BUILD" "$WAYLAND_SRC" 2>&1 | tail -5

log "Building with $JOBS jobs..."
ninja -C "$WAYLAND_BUILD" -j"$JOBS" 2>&1 | tail -3

if [[ "$BUILD_ONLY" == "true" ]]; then
    header "Build complete (not installed)"
    log "Build artifacts at: $WAYLAND_BUILD/"
    log "Libraries:"
    ls -la "$WAYLAND_BUILD"/src/libwayland*.so* 2>/dev/null || true
    ls -la "$WAYLAND_BUILD"/src/libwayland*.a 2>/dev/null || true
    log "Scanner:"
    ls -la "$WAYLAND_BUILD"/wayland-scanner 2>/dev/null || true
    exit 0
fi

header "Installing wayland $WAYLAND_VER"

# Install with sudo if prefix requires it
if [[ -w "$PREFIX" ]] 2>/dev/null; then
    DESTDIR="" ninja -C "$WAYLAND_BUILD" install 2>&1 | tail -3
else
    log "Installing with sudo..."
    sudo DESTDIR="" ninja -C "$WAYLAND_BUILD" install 2>&1 | tail -3
fi

# Update library cache
if [[ -w /etc/ld.so.conf.d/ ]] 2>/dev/null; then
    echo "$PREFIX/lib64" | sudo tee /etc/ld.so.conf.d/wayland-local.conf >/dev/null
else
    warn "Cannot update ldconfig — you may need to add $PREFIX/lib64 to LD_LIBRARY_PATH"
fi
sudo ldconfig 2>/dev/null || true

log "Wayland $WAYLAND_VER installed to $PREFIX"

# ── Create pkgconfig override ───────────────────────────────────────────

header "Setting up pkg-config"

PC_DIR="${PREFIX}/lib64/pkgconfig"
if [[ ! -d "$PC_DIR" ]]; then
    PC_DIR="${PREFIX}/lib/pkgconfig"
fi

if [[ -d "$PC_DIR" ]]; then
    export PKG_CONFIG_PATH="${PC_DIR}:${PKG_CONFIG_PATH:-}"
    log "pkg-config path: $PC_DIR"
    log "  wayland-client: $(pkg-config --modversion wayland-client 2>/dev/null || echo 'not found')"
    log "  wayland-server: $(pkg-config --modversion wayland-server 2>/dev/null || echo 'not found')"
    log "  wayland-scanner: $(which wayland-scanner 2>/dev/null || echo 'not found')"
fi

# ── Validate ────────────────────────────────────────────────────────────

if [[ "$DO_VALIDATE" == "true" ]]; then
    header "Running validation"
    exec "${SCRIPT_DIR}/validate-wayland.sh" --prefix="$PREFIX"
fi

header "Installation complete"

cat <<EOF

Installed:
  wayland $WAYLAND_VER → $PREFIX
  wayland-protocols $PROTO_VER → $PREFIX

To use the new wayland:
  export PKG_CONFIG_PATH=$PC_DIR:\$PKG_CONFIG_PATH
  export LD_LIBRARY_PATH=$PREFIX/lib64:\$LD_LIBRARY_PATH

Or validate:
  ./validate-wayland.sh --prefix=$PREFIX

To rebuild wayland in the zigshell:
  cd src/shells/zigshell-cairo-pango && zig build
  cd src/shells/zigshell-blend2d && zig build

EOF
