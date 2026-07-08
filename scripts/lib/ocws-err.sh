#!/bin/bash
# ocws-err.sh — Centralized error handling for OCWS shell scripts.
#
# Source it right after the shebang:
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/ocws-err.sh"
# then opt in with:
#   ocws_enable_strict
#
# ocws_enable_strict turns on strict mode (set -Eeuo pipefail) and installs
# an ERR trap that, on any failing command, sends a critical desktop
# notification (via ocws-notify) describing the command and line, and aborts
# the script. Use ocws_die() for explicit failures and ocws_warn() for
# non-fatal issues.
#
# Tolerant patterns such as `cmd || true` keep working: the compound exits
# 0, so the trap does not fire.

source "$(dirname "${BASH_SOURCE[0]}")/ocws-notify.sh"

_ocws_err_handler() {
    local lineno="$1" cmd="$2" rc="${3:-1}"
    local msg="Command failed at line ${lineno}: ${cmd} (exit ${rc})"
    printf '\033[0;31m✗\033[0m %s\n' "$msg" >&2
    ocws_notify_error "OCWS Error" "$msg"
    exit "$rc"
}

# Enable strict mode + ERR trap. Call explicitly so scripts can do their own
# setup (argument parsing, env detection) before failures become fatal.
ocws_enable_strict() {
    set -Eeuo pipefail
    trap '_ocws_err_handler "${LINENO}" "${BASH_COMMAND}" "$?"' ERR
}

# ocws_die <message> — notify + abort immediately.
ocws_die() {
    printf '\033[0;31m✗\033[0m %s\n' "$*" >&2
    ocws_notify_error "OCWS Error" "$*"
    exit 1
}

# ocws_warn <message> — notify + log, keep going.
ocws_warn() {
    printf '\033[1;33m⚠\033[0m %s\n' "$*" >&2
    ocws_notify_warn "OCWS Warning" "$*"
}
