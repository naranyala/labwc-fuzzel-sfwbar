#!/bin/sh

# Watchdog for sfwbar

while true; do
  if ! pgrep -x "sfwbar" > /dev/null; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    if [ -f "$HOME/.config/sfwbar/wbar.config" ]; then
      sfwbar --config "$HOME/.config/sfwbar/wbar.config"
    elif [ -f "$HOME/.config/sfwbar/w10.config" ]; then
      sfwbar --config "$HOME/.config/sfwbar/w10.config"
    else
      # Fallback to minimal configuration
      mkdir -p "$HOME/.config/sfwbar"
      cat > "$HOME/.config/sfwbar/wbar.config" << 'EOF'
module.name "bar" {
  position = "top",
  height = "32px",
  background = "#1e1e2e",
  foreground = "#cdd6f4",
  
  widget {
    type = "workspaces",
    position = "left"
  },
  
  widget {
    type = "clock",
    format = "%H:%M",
    timezone = "local"
  },
  
  widget {
    type = "cpu",
    label = "CPU"
  },
  
  widget {
    type = "memory",
    label = "MEM"
  },
  
  widget {
    type = "network",
    label = "NET"
  },
  
  widget {
    type = "battery",
    label = "BAT"
  },
  
  widget {
    type = "volume",
    label = "VOL"
  }
}
EOF
      sfwbar --config "$HOME/.config/sfwbar/wbar.config"
    fi
  fi
  sleep 5
done
