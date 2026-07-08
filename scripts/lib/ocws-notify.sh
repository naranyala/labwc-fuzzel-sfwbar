#!/bin/bash
# ocws-notify.sh — Canonical OCWS desktop notification helper.
#
# Source it from any OCWS script:
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/ocws-notify.sh"
#
# Notifications are delivered through notify-send, which routes to the
# active notification daemon (ocws-notify / mako / dunst) over D-Bus.
# When no client is available the message is logged via the system logger
# and printed to stderr, so errors are never silently lost.
#
# This is the single source of truth — replace the many ad-hoc notify()
# helpers across the repo with ocws_notify().

# ocws_notify <title> [body] [icon] [urgency]
#   urgency: low | normal | critical  (default: normal)
ocws_notify() {
    local title="${1:-OCWS}"
    local body="${2:-}"
    local icon="${3:-}"
    local urgency="${4:-normal}"

    if command -v notify-send >/dev/null 2>&1; then
        local -a args=(-a "$title" -t 3000 -u "$urgency")
        [[ -n "$icon" ]] && args+=(-i "$icon")
        notify-send "${args[@]}" "$body" 2>/dev/null
        return $?
    fi

    if command -v logger >/dev/null 2>&1; then
        logger -t "$title" "$body"
    fi
    printf '[%s] %s\n' "$title" "$body" >&2
}

# ocws_notify_error <title> <body> [icon] — surface a failure (critical)
ocws_notify_error() {
    ocws_notify "${1:-OCWS Error}" "${2:-}" "${3:-dialog-error}" critical
}

# ocws_notify_warn <title> <body> [icon] — non-fatal warning
ocws_notify_warn() {
    ocws_notify "${1:-OCWS Warning}" "${2:-}" "${3:-dialog-warning}" normal
}
