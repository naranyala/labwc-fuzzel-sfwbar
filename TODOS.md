# OCWS (Our C-Written Shell) Strategic Roadmap & TODOs

## Strategic Focus Areas

This document outlines the multi-phase strategy for the development of **OCWS** and the
`labwc-fuzzel-sfwbar` platform. Focus is exclusively on this pure C-native Wayland paradigm.

**Key Priority**: Make OCWS a cohesive, complete "batteries-included" platform.

---

## Phase 1: Platform Consolidation & Core Infrastructure

*Status: COMPLETE*

### Completed Items

- [x] **Widget System Unification**: Merged shell/widgets/ with dotfiles/ocws/ implementations
- [x] **Plugin Autoloader**: `~/.config/ocws/plugins/` auto-injected at boot
- [x] **Event Bus API**: `ocws-emit` with full namespace coverage (System.*, Media.*, Network.*)
- [x] **Theme Engine**: INI profiles -> templates -> rendered configs (11 config surfaces)
- [x] **C Utility Suite**: 15 binaries built via `zig build`

| Binary | Purpose | Status |
|--------|---------|--------|
| `ocws-sysmon` | System metrics (CPU/mem/net/bat/bt/brightness/temp) | Done |
| `ocws-clip` | Clipboard manager (cliphist + fuzzel picker) | Done |
| `ocws-shot` | Screenshot tool (grim + slurp + annotation) | Done |
| `ocws-lock` | Screen lock wrapper (swaylock) | Done |
| `ocws-kv` | Key-value persistent store (flat file) | Done |
| `ocws-brightness` | Smooth backlight control (cubic easing) | Done |
| `ocws-volume` | Smooth PulseAudio control (cubic easing) | Done |
| `ocws-notify` | Native D-Bus notification daemon | Done |
| `ocws-wallpaper` | Time-of-day wallpaper transitions | Done |
| `ocws-color` | Wallpaper palette extraction (median-cut) | Done |
| `ocws-ocr` | Screen OCR (Tesseract) | Done |
| `ocws-recorder` | Screen recording (wf-recorder wrapper) | Done |
| `ocws-live-bg` | Animated live background (GTK layer shell) | Done |
| `ocws-osd-notify` | Glassmorphic notification popup (GTK layer shell) | Done |
| `ocws-hypertile` | Dynamic tiling for labwc | Done |

- [x] **Sources Learning Library**: 22 docs in `sources-learn/` covering all dependencies + OCWS internals

---

## Phase 2: Rich Interactive Components & UI/UX

*Status: IN PROGRESS — foundation laid, polish needed*

### Notification System

- [x] `ocws-notify` — D-Bus notification daemon (replaces mako)
- [x] `ocws-osd-notify` — Glassmorphic popup overlay (gtk-layer-shell)
- [ ] Unify notification styling across all sources (mako fallback, app notifications)
- [ ] Notification history persistence (save to `ocws-kv`, restore on boot)
- [ ] Action buttons in notifications (dismiss, open, reply)

### Media Applet

- [x] `media-player.widget` — Now playing display (playerctl)
- [x] `media.widget` — Compact controls (prev/play/next)
- [x] `ocws-media-art.sh` — Album art fetcher
- [ ] Rich media popup in Control Center with full album art display
- [ ] Live lyrics display (stretch goal)

### Calendar Widget

- [ ] Interactive calendar popup (month navigation, date selection)
- [ ] Integration with OCWS Glass styling
- [ ] Click-to-open in calendar app

### Dynamic Workspaces

- [x] `workspaces.widget` — Pager-based workspace switching
- [ ] Visual differentiation: empty vs populated workspace indicators
- [ ] Smooth indicator transitions
- [ ] Multi-monitor workspace management

### Dock Enhancement

- [ ] `dock.widget` — Pinned applications with running indicators
- [ ] Drag-to-reorder support
- [ ] Auto-hide on fullscreen windows

### Theme Engine Enrichment

- [x] Wallpaper-adaptive palette extraction via `ocws-color`
- [ ] Auto-generate theme from wallpaper (run `ocws-color` on wallpaper, feed into theme engine)
- [ ] Live theme preview (apply temporarily, revert on cancel)
- [ ] Theme scheduling (auto-switch based on time of day)

---

## Phase 3: System Resilience & User Experience

*Status: PARTIAL — core infra done, polish needed*

### State Persistence

- [x] `ocws-kv` — Key-value store for persistent state
- [x] `ocws-state.sh` — State coordinator for ocws-daemon
- [ ] Wire ocws-daemon to save/restore all state on boot (volume, brightness, DND, theme)
- [ ] Daemon survives sleep/resume (ACPI suspend handling)
- [ ] Auto-recover Event Bus on system wake

### GUI Settings Manager

- [ ] `ocws-settings` — Native configuration popup (sfwbar or GTK/C)
- [ ] Blur toggle, theme switching, layout padding controls
- [ ] Replace manual `.config` file editing for common options

### Installer Hardening

- [x] `install.sh` — Basic installer with backup
- [ ] Atomic rollback on failure
- [ ] User-friendly confirmation prompts
- [ ] `distro/arch.sh` — Arch Linux / pacman
- [ ] `distro/debian.sh` — Debian / Ubuntu / apt
- [ ] `distro/fedora.sh` — Fedora / dnf

### Validation & Health

- [x] `validate.sh` — Post-install verification (25+ checks)
- [x] `health-check.sh` — System health diagnostics
- [x] `fix.sh` --dry-run — Auto-repair broken configs

---

## Phase 4: Distribution & Community Integration

*Status: NOT STARTED*

- [ ] **AUR Packaging**: `ocws-desktop-git` PKGBUILD
  - Full dependency resolution (labwc, sfwbar, fuzzel)
  - `yay -S ocws-desktop-git` one-shot install

- [ ] **Standalone Installer**: Decouple from labwc
  - Support Sway, Hyprland, other wlroots compositors
  - Auto-detect compositor, adapt config format

- [ ] **Documentation Site**: Generate from `docs/` + `sources-learn/`
  - Searchable reference
  - Interactive config builder

---

## Phase 5: Ecosystem Enrichment & Premium Features

*Status: FOUNDATION LAID — C utilities enable new capabilities*

### Desktop Widgets (Conky Replacements)

- [ ] Floating desktop clocks (wayland layer surface)
- [ ] Weather applets (open-meteo API, already in weather.widget)
- [ ] Hardware sensor dashboards (CPU, mem, temp, network)
- [ ] Interactive sticky notes (persistent via ocws-kv)
- [ ] System monitor graph widgets (CPU/mem history)

### AI/LLM Integration

- [ ] `ocws-assistant` — Floating glassmorphic AI chat widget
- [ ] Voice-activated command palette (integrated with fuzzel)
- [ ] Local LLM hooks for screen text analysis (via `ocws-ocr`)
- [ ] Clipboard intelligence (summarize, translate, explain via LLM)

### Advanced Applets

- [ ] Crypto/stock ticker plugins (API polling + chart widget)
- [ ] Spotify/MPD live lyrics display
- [ ] GitHub/GitLab notification tray (API polling)
- [ ] Weather radar map overlay
- [ ] Pomodoro timer widget

### Dynamic Wallpapers & Animations

- [x] `ocws-wallpaper` — Time-of-day transitions (built)
- [ ] Animated live wallpapers via `ocws-live-bg` (built, needs integration)
- [ ] Window open/close animations via labwc rules
- [ ] Parallax scrolling wallpapers
- [ ] Wallpaper blur on window hover

### System Enhancements

- [x] `ocws-brightness` — Smooth brightness (built)
- [x] `ocws-volume` — Smooth volume (built)
- [ ] Display management widget (via wlr-randr, multi-monitor layout presets)
- [ ] Power profile switching widget (balanced/performance/powersave)
- [ ] Keyboard layout indicator (via xkbcommon)
- [ ] Night light toggle widget (gammastep integration)

---

## Project Status Summary

### Implemented (Phase 1 Complete)
- Modular widget architecture in `dotfiles/ocws/`
- Dynamic theme engine with glassmorphic CSS injection
- 15 C helper binaries built via `zig build`
- Event Bus with full namespace coverage
- Plugin autoloader
- Key-value persistent store
- 22 learning docs in `sources-learn/`
- Post-install validation and health checks

### In Progress (Phase 2)
- Notification system polish (ocws-notify + ocws-osd-notify)
- Rich media applet with album art
- Calendar widget
- Theme engine enrichment (wallpaper-adaptive, scheduling)

### Gaps to Close (Phase 3)
- Daemon resilience on sleep/resume
- State persistence wiring (ocws-daemon + ocws-kv)
- GUI settings manager
- Distro install scripts

### Not Started (Phase 4-5)
- AUR packaging
- Standalone installer
- Desktop widgets, AI integration, advanced applets

---

## Risk Mitigation

1. **Delete legacy cruft** before adding new features
2. **Simplest solution that works** — avoid premature abstraction
3. **Implement one component at a time** with clear boundaries
4. **Automate testing** for all integrations
5. **Document decisions** inline with `# OCWS:` comments

## Development Timeline

| Phase | Focus | Status |
|-------|-------|--------|
| Phase 1 | Platform consolidation | Complete |
| Phase 2 | Rich components | In Progress |
| Phase 3 | Resilience & UX | Partial |
| Phase 4 | Distribution | Not Started |
| Phase 5 | Ecosystem enrichment | Foundation Laid |
