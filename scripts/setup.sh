#!/bin/bash
#
# setup.sh — One-shot full setup: deps → build labwc → install config
#
# Runs the full install chain. Idempotent — safe to re-run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

pass()  { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
info()  { echo -e "  ${CYAN}→${NC} $1"; }
fail()  { echo -e "  ${RED}✗${NC} $1"; exit 1; }
section() { echo -e "\n${BOLD}[$1]${NC}"; }

SKIP_DEPS=false
SKIP_BUILD=false
SKIP_DOTFILES=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-deps) SKIP_DEPS=true; shift ;;
    --skip-build) SKIP_BUILD=true; shift ;;
    --skip-dotfiles) SKIP_DOTFILES=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --skip-deps       Skip dependency installation"
      echo "  --skip-build      Skip labwc build (use existing binary)"
      echo "  --skip-dotfiles   Skip config installation"
      echo "  --dry-run         Show what would be done"
      echo "  --help            Show this help"
      echo ""
      exit 0
      ;;
    *) shift ;;
  esac
done

echo ""
echo "========================================"
echo "  labwc + Zebar + crystal-dock Setup"
echo "========================================"
echo ""

if $DRY_RUN; then
  info "DRY RUN — no changes will be made"
  echo ""
fi

# -------------------------------------------------------------------
section "System Overview"
# -------------------------------------------------------------------
echo "  OS:   $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo 'unknown')"
echo "  Arch: $(uname -m)"
echo "  User: $(whoami)"
echo "  Home: $HOME"
echo "  Project: $PROJECT_DIR"

if command -v labwc &>/dev/null; then
  echo "  labwc: $(labwc --version 2>/dev/null | head -1)"
else
  echo "  labwc: not installed"
fi

# -------------------------------------------------------------------
section "1. System Dependencies"
# -------------------------------------------------------------------
if $SKIP_DEPS; then
  info "Skipped (--skip-deps)"
elif $DRY_RUN; then
  info "Would run: $SCRIPT_DIR/install-deps.sh"
else
  info "Installing build and runtime dependencies..."
  if [ -f "$SCRIPT_DIR/install-deps.sh" ]; then
    bash "$SCRIPT_DIR/install-deps.sh" && pass "Dependencies installed"
  else
    warn "install-deps.sh not found, skipping"
  fi
fi

# -------------------------------------------------------------------
section "2. Build labwc from Source"
# -------------------------------------------------------------------
if $SKIP_BUILD; then
  info "Skipped (--skip-build)"
elif command -v labwc &>/dev/null && $DRY_RUN; then
  info "labwc already installed, would skip (use --skip-build to confirm)"
elif $DRY_RUN; then
  info "Would run: $PROJECT_DIR/download-labwc.sh --install"
else
  if ! command -v labwc &>/dev/null; then
    info "Building labwc from latest source..."
    if [ -f "$PROJECT_DIR/download-labwc.sh" ]; then
      bash "$PROJECT_DIR/download-labwc.sh" --install && pass "labwc built and installed"
    else
      fail "download-labwc.sh not found"
    fi
  else
    info "labwc already installed: $(labwc --version 2>/dev/null | head -1)"
  fi
fi

# -------------------------------------------------------------------
section "3. Install Configuration"
# -------------------------------------------------------------------
if $SKIP_DOTFILES; then
  info "Skipped (--skip-dotfiles)"
elif $DRY_RUN; then
  info "Would run: $PROJECT_DIR/dotfiles/install.sh"
else
  info "Installing dotfiles..."
  if [ -f "$PROJECT_DIR/dotfiles/install.sh" ]; then
    bash "$PROJECT_DIR/dotfiles/install.sh" && pass "Configuration installed"
  else
    fail "dotfiles/install.sh not found"
  fi
fi

# -------------------------------------------------------------------
section "4. Validate Setup"
# -------------------------------------------------------------------
if $DRY_RUN; then
  info "Would run: $SCRIPT_DIR/validate.sh"
else
  if [ -f "$SCRIPT_DIR/validate.sh" ]; then
    bash "$SCRIPT_DIR/validate.sh" || true
  fi
fi

# -------------------------------------------------------------------
section "Summary"
# -------------------------------------------------------------------
echo ""
echo "  labwc:     $(command -v labwc 2>/dev/null && echo 'installed' || echo 'missing')"
echo "  Config:    $( [ -d "$HOME/.config/labwc" ] && echo 'installed' || echo 'missing')"
echo "  Zebar:     $(command -v zebar 2>/dev/null && echo 'found' || echo 'not found')"
echo "  Dock:      $(command -v crystal-dock 2>/dev/null && echo 'found' || echo 'not found')"

LABWC_BIN="$(command -v labwc 2>/dev/null || true)"
if [ -n "$LABWC_BIN" ]; then
  echo ""
  echo "  Launch from TTY:"
  echo "    $SCRIPT_DIR/start-labwc.sh"
  echo ""
  echo "  Or select 'labwc' from your display manager."
fi
echo ""
