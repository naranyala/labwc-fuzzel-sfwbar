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
- [x] **Bugfix Sweep**: Multiple critical bugs fixed
  - `ExecTerm()` replaced with `Exec("foot -e ...")` in 15 widget files (broken click actions)
  - Missing `)` added in `weather.widget` `XWeatherIcon()` and `XWeatherDesc()` (silent empty returns)
  - Division-by-zero guards added in `memory.source`, `cpu.source`, `battery.source` (NaN values on first tick)
  - `delete_kv()` same-file redirect truncation fixed in `kvstore.sh` and `kvstore-cli.sh` (data loss on delete)
  - `button.module_pill` CSS style added for 14 un-themed widgets
  - `dock.widget` wired into `ocws.config` top bar (was orphaned)

---

## Phase 2: Rich Interactive Components & UI/UX

*Status: IN PROGRESS — foundation laid, polish needed*

### Notification System

- [x] `ocws-notify` — D-Bus notification daemon (replaces mako)
- [x] `ocws-osd-notify` — Glassmorphic popup overlay (gtk-layer-shell)
- [x] Unify notification styling across all sources (mako fallback, app notifications)
- [x] Notification history persistence (save to `ocws-kv`, restore on boot)
- [x] Action buttons in notifications (dismiss, open, reply)

### Media Applet

- [x] `media-player.widget` — Now playing display (playerctl)
- [x] `media.widget` — Compact controls (prev/play/next)
- [x] `ocws-media-art.sh` — Album art fetcher
- [ ] Rich media popup in Control Center with full album art display
- [ ] Live lyrics display (stretch goal)

### Calendar Widget

- [x] Interactive calendar popup (month navigation, date selection)
- [x] Integration with OCWS Glass styling
- [x] Click-to-open in calendar app

### Dynamic Workspaces

- [x] `workspaces.widget` — Pager-based workspace switching
- [x] Visual differentiation: empty vs populated workspace indicators
- [ ] Smooth indicator transitions
- [ ] Multi-monitor workspace management

### Dock Enhancement

- [x] `dock.widget` — Pinned applications with running indicators
- [ ] Drag-to-reorder support
- [ ] Auto-hide on fullscreen windows

### Theme Engine Enrichment

- [x] Wallpaper-adaptive palette extraction via `ocws-color`
- [x] Auto-generate theme from wallpaper (run `ocws-color` on wallpaper, feed into theme engine)
- [ ] Live theme preview (apply temporarily, revert on cancel)
- [x] Theme scheduling (auto-switch based on time of day)

---

## Phase 3: System Resilience & User Experience

*Status: PARTIAL — core infra done, polish needed*

### State Persistence

- [x] `ocws-kv` — Key-value store for persistent state
- [x] `ocws-state.sh` — State coordinator for ocws-daemon
- [ ] Wire ocws-daemon to save/restore all state on boot (volume, brightness, DND, theme) — low value: widgets self-correct via 2s polling. Revisit if sleep/resume causes persistent state loss.
- [ ] Daemon survives sleep/resume (ACPI suspend handling)
- [ ] Auto-recover Event Bus on system wake

### GUI Settings Manager

- [ ] `ocws-settings` — Native configuration popup (sfwbar or GTK/C)
- [ ] Blur toggle, theme switching, layout padding controls
- [ ] Replace manual `.config` file editing for common options

### Installer Hardening

- [x] `install.sh` — Basic installer with backup
- [ ] Atomic rollback on failure
- [x] User-friendly confirmation prompts
- [x] `distro/arch.sh` — Arch Linux / pacman
- [x] `distro/debian.sh` — Debian / Ubuntu / apt
- [x] `distro/fedora.sh` — Fedora / dnf

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
- [x] Power profile switching widget (balanced/performance/powersave)
- [x] Keyboard layout indicator (via xkbcommon)
- [x] Night light toggle widget (gammastep integration)

---

## Phase 6: Dotfiles Architecture & Abstractions

*Status: PARTIAL — see per-section checkboxes below*

### 6a. Directory Structure (fix 50-file flat mess)

Current — everything flat in `dotfiles/ocws/`:
```
36 .widget files   +   3 .source files   +   5 .sh files   +   CSS   +   configs
```

Proposed — group by concern:
```
dotfiles/ocws/
├── bars/                  # Bar layout definitions
│   ├── topbar.config
│   └── bottombar.config
├── widgets/
│   ├── system/            # System metrics (battery, cpu, memory, disk, temp, network)
│   ├── media/             # Media player + controls
│   ├── controls/          # Volume, brightness, wifi, bluetooth, nightlight, power
│   ├── applets/           # Weather, calendar, clipboard
│   ├── core/              # Launcher, workspaces, clock, showdesktop, tray, dock
│   └── popups/            # Control center, notifications, quick settings, sysmon
├── sources/               # Data source definitions (scanners without UI)
├── css/                   # Split by concern: base.css, bars.css, widgets.css, popups.css
├── scripts/               # Daemon, emitter, state coordinator, helpers
├── plugins/               # Third-party user-installed widgets
└── icons/                 # Custom SVG icons
```

- [ ] Group `.widget` files into subdirectories by category
- [ ] Split `ocws.config` into `bars/topbar.config`, `bars/bottombar.config`, and `css/` files
- [ ] Move inline CSS from widget files into `css/widgets.css`
- [ ] Update all `include()` paths in configs

### 6b. Data Source / UI Split

*Status: SKIPPED — evaluated, YAGNI. Only the volume scanner is duplicated (volume-text.widget + ocws-control-center.widget). Extracting 9+ scanners into separate files for 1:1 relationships is pure overhead with no reuse benefit. The volume duplication is minor and causes no bugs.*

- [x] Evaluated — not enough reuse to justify the churn. Revisit if >50% of scanners are shared.

### 6c. Event Bus Contract

The daemon → `ocws-emit.sh` → sfwbar variable flow is implicit. 18 `ocws-emit.sh` calls exist but there's no single place listing the mapping.

- [x] Document the full event contract in `docs/events.md` mapping every IPC event to its sfwbar variable and which widgets consume it
- [x] Add `# OCWS:` comments in `ocws-daemon.sh` declaring the event namespace for each `ocws-emit.sh` call
- [x] Add a check in `test-rendering.sh` that every emitted event has a corresponding consumer

### 6d. Widget-Set Profiles

Currently `plugins.config` is one hardcoded include list. Adding or removing a widget means editing it.

- [x] Create `config/widget-sets/standard.set` (core + system metrics only — minimal)
- [x] Create `config/widget-sets/full.set` (everything — current default)
- [x] Main config just picks a set: `include("widget-sets/standard.set")`
- [x] Add profile switching support to `theme-engine.sh` (`--profile standard|full`) — low value, `ocws.config` already uses `include("widget-sets/full.set")`; editing the config is simpler than a CLI flag

### 6e. User Overlay Config

The install script copies `dotfiles/ocws/` to `~/.config/ocws/`, overwriting user edits. No separation between "platform" and "my changes".

- [x] Add `include("~/.config/ocws/user.config")` as the last line in `ocws.config` (before `#CSS`)
- [x] `user.config` can override widget positions, CSS, terminal choice, etc.
- [x] Install script never touches `user.config` — creates it only if missing
- [x] Document in a comment at the top of `ocws.config`: *"Edit user.config for personal changes — this file gets overwritten on update"*

### 6f. Widget Template System

Many text-widgets follow the same pattern: icon + value + tooltip + popup detail. The boilerplate repeats ~30 lines per widget across 15+ metric widgets.

- [ ] Evaluate whether sfwbar's `Function()` + `Config()` can generate standard text/widget patterns
- [ ] If feasible, create `templates/text-widget.tmpl` macro that reduces 30 lines → 5:

```ini
# Current (30 lines)
button "cpu-text" {
  style = "module_pill"
  label { value = "󰍛 " + Str(XCpuLoad, 0) + "%" }
  ...
}
PopUp("CpuPopup") { ... }

# Target (5 lines with template)
IncludeTemplate("text-widget.tmpl", "cpu-text",
  icon = "󰍛", value = Str(XCpuLoad, 0) + "%",
  popup_title = "CPU Monitor",
  popup_detail = "Usage: " + Str(XCpuUtilization*100, 1) + "%\n...",
  tooltip = "Click to open htop"
)
```

### 6g. Variable Contract (IPC Single Source of Truth)

**Problem**: `ocws-emit.sh` maps API names → variable names. Widgets read variable names.
These must match manually. We fixed 4 mismatches this session (battery, memory, disk).

- [x] Create `contracts/variables.ini` declaring every IPC variable:
  ```ini
  [system.volume]
  emit_name = XVolLevel
  widget_files = volume-text.widget, ocws-control-center.widget
  ```
- [ ] Auto-generate `ocws-emit.sh` case statements from the contract
- [ ] Script to validate: all widget variable references exist in contract
- [ ] Script to validate: all contract variables are defined by a scanner/source

### 6h. CSS Token Standardization

**Problem**: Colors defined 3 ways: `@define-color` in theme.css, hardcoded hex in ocws.css,
hardcoded rgba in widget files. Theme changes require editing 3+ files.

- [ ] Create `tokens.css` with all `@define-color` declarations:
  ```css
  @define-color ocws_bg #1e1e2e;
  @define-color ocws_fg #cdd6f4;
  @define-color ocws_accent #89b4fa;
  @define-color ocws_surface_alpha_50 alpha(@ocws_surface, 0.5);
  ```
- [ ] Update all widget `#CSS` sections to use `@ocws_*` tokens
- [ ] Update `ocws.config` CSS section to use tokens
- [ ] Theme engine generates `tokens.css` from INI → single file regeneration
- [ ] Remove hardcoded hex/rgba from all widget files

### 6i. Widget Schema & Validation

**Problem**: Widgets repeat scanner → export → popup → CSS pattern with no validation.
Typos in variable names or PopUp names silently break.

- [ ] Design `widget.schema.json` defining valid widget structure
- [ ] Create `ocws-validate` CLI that checks:
  - All referenced variables are defined by a scanner
  - All PopUp triggers have matching definitions
  - All CSS classes have matching rules
  - No duplicate exported button/label names
- [ ] Run validation in `install.sh` before deploying
- [ ] CI integration for PR validation

### 6j. Unified State Layer

**Problem**: State managed by 3 disconnected systems: `ocws-kv` (C), `ocws-state.sh` (bash),
`ocws-daemon.sh` (IPC only). Sleep/resume loses state.

- [ ] Design `ocws-state` daemon architecture:
  - Owns `~/.config/ocws/state/`
  - CLI: `ocws-state get/set/del/watch`
  - Auto-saves on change, auto-restores on boot
  - ACPI suspend/resume hooks
  - Streams changes to sfwbar via IPC
- [ ] Replace `ocws-state.sh` with `ocws-state` CLI
- [ ] Wire `ocws-daemon.sh` to use `ocws-state` for persistence
- [ ] Add sleep/resume handling via `systemd-suspend-hook` or `acpid`

### 6k. C Utility Shared Library

**Problem**: `ocws-brightness.c` and `ocws-volume.c` duplicate `ease_out_cubic()` and
`animate_to()`. Multiple utilities iterate `/sys/class/backlight/`.

- [ ] Extract `libocws/` with:
  - `easing.h` — `ease_out_cubic()`, `ease_in_out_cubic()`
  - `backlight.h` — `backlight_get_max()`, `backlight_set()`, `backlight_animate()`
  - `audio.h` — `audio_get_volume()`, `audio_set_volume()`, `audio_animate()`
  - `sysfs.h` — `sysfs_read_int()`, `sysfs_read_string()`, `sysfs_iter_dir()`
- [ ] Refactor `ocws-brightness.c` and `ocws-volume.c` to use shared lib
- [ ] Update `build.zig` to build `libocws` as static library

### 6l. Widget Plugin API with Lifecycle

**Problem**: Plugin system is just `include()` — no lifecycle, no dependency resolution,
no error handling. Broken widget silently takes down entire bar.

- [ ] Design `plugin.ini` manifest format:
  ```ini
  [plugin]
  name = volume-text
  [requires]
  variables = XVolLevel, XVolMuted
  provides = volume-text
  [load_order]
  after = ocws-sysmon.source
  ```
- [ ] Plugin loader resolves dependency graph before loading
- [ ] Validate variables before loading widgets
- [ ] Graceful degradation: skip broken widgets, load rest

---

## Abstraction Priority Matrix

| # | Abstraction | Effort | Impact | Bugs Prevented | Section |
|---|-------------|--------|--------|----------------|---------|
| 1 | Variable Contract | Low | HIGH | IPC mismatches | 6g |
| 2 | CSS Token Standardization | Medium | HIGH | Theme inconsistencies | 6h |
| 3 | Widget Schema & Validation | Medium | MEDIUM | Widget typos, missing deps | 6i |
| 4 | Directory Restructure | Medium | MEDIUM | Navigation, onboarding | 6a |
| 5 | Data Source / UI Split | Medium | MEDIUM | Duplicated scanners | 6b |
| 6 | Unified State Layer | High | HIGH | State loss on sleep/resume | 6j |
| 7 | C Utility Shared Library | Medium | MEDIUM | Code duplication | 6k |
| 8 | Widget Plugin API | High | MEDIUM | Silent widget failures | 6l |
| 9 | Widget-Set Profiles | Low | LOW | Config rigidity | 6d |
| 10 | User Overlay Config | Low | LOW | User edits overwritten | 6e |

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

### Not Started (Phase 4-5)
- AUR packaging
- Standalone installer
- Desktop widgets, AI integration, advanced applets

### Proposed (Phase 6 — Architecture Abstractions)
- Directory restructure (flat → grouped by concern)
- Variable contract (IPC single source of truth)
- CSS token standardization
- Widget schema & validation
- Unified state layer with sleep/resume
- C utility shared library
- Widget plugin API with lifecycle
- Widget templates: evaluate `Function()` + `Config()` for reducing boilerplate

### Delivered (Phase 6)
- Event contract: `docs/events.md` documenting all daemon→sfwbar IPC mappings
- Widget-set profiles: `full.set` + `standard.set` created, config uses `include("widget-sets/full.set")`
- User overlay: `include("user.config")` with install-guard already in place

### Skipped (Phase 6 — YAGNI)
- Data source split: no reuse benefit, 1:1 scanner→widget ratios
- Theme-engine profile switching: CLI flag over a config edit is over-engineering

### Proposed (Phase 7 — C-Native Transition)
- `ocws-brokerd`: C-native DBus state daemon replacing `ocws-daemon.sh`
- `ocws-config`: YAML-driven C configuration parser replacing `theme-engine.sh`
- `ocws_ipc.h`: Type-safe C IPC library replacing `ocws-emit.sh`
- Component API: Dynamic UI injection via DBus instead of static `.widget` includes

---

## Risk Mitigation

1. **Delete legacy cruft** before adding new features
2. **Simplest solution that works** — avoid premature abstraction
3. **Implement one component at a time** with clear boundaries
4. **Automate testing** for all integrations
5. **Document decisions** inline with `# OCWS:` comments
6. **Phase 6 abstractions** — Evaluate each before implementing; low-effort/high-impact items (Variable Contract, CSS Tokens, Config Validation) ship first

## Development Timeline

| Phase | Focus | Status |
|-------|-------|--------|
| Phase 1 | Platform consolidation | Complete |
| Phase 2 | Rich components | In Progress |
| Phase 3 | Resilience & UX | Partial |
| Phase 4 | Distribution | Not Started |
| Phase 5 | Ecosystem enrichment | Foundation Laid |
| Phase 6 | Architecture abstractions | Partial (3 delivered, 2 skipped) |
