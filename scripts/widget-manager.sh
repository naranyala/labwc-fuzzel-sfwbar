#!/bin/bash
#
# widget-manager.sh — Manage zebar widget themes
#
# List, install, remove, preview, and create widget themes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ZEBAR_DIR="${HOME}/.config/zebar"
WIDGET_SRC="$PROJECT_DIR/dotfiles/zebar/widgets"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

pass()  { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
info()  { echo -e "  ${CYAN}→${NC} $1"; }
fail()  { echo -e "  ${RED}✗${NC} $1"; exit 1; }
section() { echo -e "\n${BOLD}[$1]${NC}"; }

ACTION="${1:-help}"
shift || true

case "$ACTION" in
  list|ls)
    echo ""
    echo "== Available Widget Themes =="
    echo ""
    
    # From project
    if [ -d "$WIDGET_SRC" ]; then
      info "Project widgets ($WIDGET_SRC):"
      for dir in "$WIDGET_SRC"/*/; do
        if [ -d "$dir" ] && [ -f "$dir/index.html" ]; then
          local_name=$(basename "$dir")
          local_size=$(wc -c < "$dir/index.html" 2>/dev/null || echo "?")
          echo "  $local_name ${DIM}($local_size bytes)${NC}"
        fi
      done
    fi
    
    # From user config
    if [ -d "$ZEBAR_DIR/widgets" ]; then
      echo ""
      info "Installed widgets ($ZEBAR_DIR/widgets):"
      for dir in "$ZEBAR_DIR/widgets"/*/; do
        if [ -d "$dir" ] && [ -f "$dir/index.html" ]; then
          local_name=$(basename "$dir")
          local_size=$(wc -c < "$dir/index.html" 2>/dev/null || echo "?")
          echo "  $local_name ${DIM}($local_size bytes)${NC}"
        fi
      done
    fi
    
    # Main widget
    if [ -d "$ZEBAR_DIR/main" ] && [ -f "$ZEBAR_DIR/main/index.html" ]; then
      echo ""
      info "Main widget (status bar): installed"
    fi
    echo ""
    ;;

  install|add)
    WIDGET_NAME="${1:-}"
    if [ -z "$WIDGET_NAME" ]; then
      fail "Usage: $0 install <widget-name>"
    fi
    
    WIDGET_SRC_DIR="$WIDGET_SRC/$WIDGET_NAME"
    WIDGET_DST_DIR="$ZEBAR_DIR/widgets/$WIDGET_NAME"
    
    if [ ! -d "$WIDGET_SRC_DIR" ]; then
      fail "Widget '$WIDGET_NAME' not found in $WIDGET_SRC"
    fi
    
    if [ -d "$WIDGET_DST_DIR" ]; then
      warn "Widget '$WIDGET_NAME' already installed"
      read -rp "Overwrite? [y/N] " ans
      if [[ ! "$ans" =~ ^[Yy] ]]; then
        info "Cancelled"
        exit 0
      fi
      rm -rf "$WIDGET_DST_DIR"
    fi
    
    mkdir -p "$(dirname "$WIDGET_DST_DIR")"
    cp -r "$WIDGET_SRC_DIR" "$WIDGET_DST_DIR"
    pass "Installed widget: $WIDGET_NAME"
    echo ""
    info "Launch with: zebar start-widget $WIDGET_NAME"
    echo ""
    ;;

  remove|rm)
    WIDGET_NAME="${1:-}"
    if [ -z "$WIDGET_NAME" ]; then
      fail "Usage: $0 remove <widget-name>"
    fi
    
    WIDGET_DST_DIR="$ZEBAR_DIR/widgets/$WIDGET_NAME"
    
    if [ ! -d "$WIDGET_DST_DIR" ]; then
      fail "Widget '$WIDGET_NAME' not installed"
    fi
    
    read -rp "Remove widget '$WIDGET_NAME'? [y/N] " ans
    if [[ ! "$ans" =~ ^[Yy] ]]; then
      info "Cancelled"
      exit 0
    fi
    
    rm -rf "$WIDGET_DST_DIR"
    pass "Removed widget: $WIDGET_NAME"
    echo ""
    ;;

  enable)
    WIDGET_NAME="${1:-}"
    if [ -z "$WIDGET_NAME" ]; then
      fail "Usage: $0 enable <widget-name>"
    fi
    
    WIDGET_SRC_FILE="$WIDGET_SRC/$WIDGET_NAME/index.html"
    WIDGET_DST_FILE="$ZEBAR_DIR/main/index.html"
    
    if [ ! -f "$WIDGET_SRC_FILE" ]; then
      fail "Widget '$WIDGET_NAME' not found"
    fi
    
    # Backup current main widget
    if [ -f "$WIDGET_DST_FILE" ]; then
      cp "$WIDGET_DST_FILE" "${WIDGET_DST_FILE}.backup"
      info "Backed up current main widget"
    fi
    
    cp "$WIDGET_SRC_FILE" "$WIDGET_DST_FILE"
    if [ -f "$WIDGET_SRC/$WIDGET_NAME/style.css" ]; then
      cp "$WIDGET_SRC/$WIDGET_NAME/style.css" "$ZEBAR_DIR/main/style.css"
    fi
    
    pass "Enabled widget '$WIDGET_NAME' as main widget"
    echo ""
    info "Restart zebar to see changes: pkill zebar && zebar startup"
    echo ""
    ;;

  disable)
    BACKUP="$ZEBAR_DIR/main/index.html.backup"
    if [ ! -f "$BACKUP" ]; then
      fail "No backup found to restore"
    fi
    
    cp "$BACKUP" "$ZEBAR_DIR/main/index.html"
    pass "Restored original main widget"
    echo ""
    ;;

  create)
    WIDGET_NAME="${1:-}"
    if [ -z "$WIDGET_NAME" ]; then
      fail "Usage: $0 create <widget-name>"
    fi
    
    WIDGET_DIR="$WIDGET_SRC/$WIDGET_NAME"
    
    if [ -d "$WIDGET_DIR" ]; then
      fail "Widget '$WIDGET_NAME' already exists"
    fi
    
    mkdir -p "$WIDGET_DIR"
    
    cat > "$WIDGET_DIR/index.html" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      margin: 0;
      padding: 0;
      background: transparent;
      font-family: 'JetBrains Mono', monospace;
      color: #cdd6f4;
    }
    .widget {
      background: rgba(30, 30, 46, 0.85);
      padding: 8px 16px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      gap: 16px;
    }
    .item {
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    .label {
      font-size: 10px;
      color: #a6adc8;
    }
    .value {
      font-size: 14px;
      font-weight: bold;
    }
  </style>
</head>
<body>
  <div class="widget">
    <div class="item">
      <span class="label">TIME</span>
      <span class="value" id="time">--:--</span>
    </div>
    <div class="item">
      <span class="label">CPU</span>
      <span class="value" id="cpu">--%</span>
    </div>
    <div class="item">
      <span class="label">MEM</span>
      <span class="value" id="mem">--%</span>
    </div>
  </div>

  <script>
    function updateTime() {
      const now = new Date();
      document.getElementById('time').textContent = 
        now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
    }
    
    function updateStats() {
      // Placeholder - replace with real system data
      document.getElementById('cpu').textContent = Math.floor(Math.random() * 100) + '%';
      document.getElementById('mem').textContent = Math.floor(Math.random() * 100) + '%';
    }
    
    updateTime();
    updateStats();
    setInterval(updateTime, 1000);
    setInterval(updateStats, 5000);
  </script>
</body>
</html>
HTMLEOF

    pass "Created widget: $WIDGET_NAME"
    echo ""
    info "Edit: $WIDGET_DIR/index.html"
    info "Install: $0 install $WIDGET_NAME"
    echo ""
    ;;

  edit)
    WIDGET_NAME="${1:-}"
    if [ -z "$WIDGET_NAME" ]; then
      fail "Usage: $0 edit <widget-name>"
    fi
    
    WIDGET_FILE="$WIDGET_SRC/$WIDGET_NAME/index.html"
    if [ ! -f "$WIDGET_FILE" ]; then
      fail "Widget '$WIDGET_NAME' not found"
    fi
    
    ${EDITOR:-nano} "$WIDGET_FILE"
    pass "Widget edited"
    ;;

  help|--help|-h|*)
    echo ""
    echo "== Widget Manager =="
    echo ""
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  list              List available widget themes"
    echo "  install <name>    Install a widget theme"
    echo "  remove <name>     Remove an installed widget"
    echo "  enable <name>     Set a widget as the main bar"
    echo "  disable           Restore original main widget"
    echo "  create <name>     Create a new widget template"
    echo "  edit <name>       Edit a widget's HTML"
    echo "  help              Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 install compact"
    echo "  $0 enable detailed"
    echo "  $0 create my-widget"
    echo ""
    ;;
esac
