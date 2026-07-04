# TODOS.md — Cross-Distro Evaluation

Evaluation checklist for labwc + sfwbar + crystal-dock dotfiles on three distro families.

---

## Known Issues (Pre-existing)

Before distro testing, these bugs exist in the current scripts:

| # | File | Issue | Severity |
|---|------|-------|----------|
| 1 | `dotfiles/install.sh:41-44` | Pre-flight checks zebar (warns "zebar not found"), should check sfwbar | Medium |
| 2 | `dotfiles/install.sh:58-66` | Creates `~/.config/zebar/` and `~/.glzr/zebar/` dirs — not needed for sfwbar | Low |
| 3 | `dotfiles/install.sh:286-301` | Validation checks `ZEBAR_V3`/`ZEBAR_V1` vars (undefined), always fails | High |
| 4 | `dotfiles/install.sh:296-301` | Summary still references `~/.glzr/zebar/main/` paths | Low |
| 5 | `dotfiles/install.sh:356` | Help text says "Zebar shell actions" instead of "Widget shell actions" | Low |
| 6 | `scripts/validate.sh:35` | `OPTIONAL_BINS` still checks for `zebar` binary | Low |
| 7 | `scripts/validate.sh:135` | References `$ZEBAR_DIR` (undefined) instead of `$SFWBAR_DIR` for widget check | High |
| 8 | `scripts/validate.sh:220` | Permissions section references `$ZEBAR_DIR` (undefined) | Medium |
| 9 | `scripts/install-deps.sh:3` | Header says "zebar" in description | Low |
| 10 | `scripts/install-deps.sh:109-114` | Debian runtime pkgs list `gsettings` and `xmllint` as package names — these are binaries, not packages (`dconf-gsettings-backend` and `libxml2-utils` are the actual packages) | Medium |
| 11 | `scripts/setup-sfwbar.sh:47` | Says `yay -S sfwbar` for Arch — sfwbar is NOT in AUR, must build from source | Medium |
| 12 | `scripts/setup-sfwbar.sh:129-133` | Module check hardcoded to `x86_64-linux-gnu` path — breaks on aarch64, Fedora, or Arch | Medium |

---

## Debian/Ubuntu (apt)

### Package Availability

| Package | apt name | Status | Notes |
|---------|----------|--------|-------|
| labwc | `labwc` | Available (Debian Trixie+/Ubuntu 25.04+) | Oldstable may lack it; build from source via `download-labwc.sh` |
| sfwbar | — | **NOT in repos** | Must build from source (`build/sfwbar-src/` already cloned) |
| crystal-dock | — | **NOT in repos** | Must build from source or PPA |
| wlroots | `libwlroots-dev` | Available (18.0+ in Trixie) | Debian Bookworm has wlroots 0.16; labwc needs 0.17+ |
| wayland | `libwayland-dev` | Available | OK |
| swaybg | `swaybg` | Available | OK |
| foot | `foot` | Available | OK |
| rofi | `rofi` (X11) / `rofi-wayland` | `rofi-wayland` needed for Wayland native | Default `rofi` may not work on Wayland |
| grim/slurp | `grim`, `slurp` | Available | OK |
| wl-clipboard | `wl-clipboard` | Available | OK |
| playerctl | `playerctl` | Available | OK |
| gammastep | `gammastep` | Available | OK |
| mako | `mako-notifier` | Available | Package name is `mako-notifier` on Debian/Ubuntu, not `mako` |
| dunst | `dunst` | Available | OK |
| polkit | `lxpolkit` | Available | Alternative: `policykit-1-gnome` |
| xmllint | `libxml2-utils` | Available | OK |
| meson/ninja | `meson`, `ninja-build` | Available | OK |

### Testing Steps

```bash
# 1. Install deps
./scripts/install-deps.sh

# 2. Build labwc (if not in repos)
./download-labwc.sh --install

# 3. Build sfwbar from source
cd build/sfwbar-src
meson setup build --prefix=$HOME/.local
ninja -C build
ninja -C build install
cd ../..

# 4. Install dotfiles
./dotfiles/install.sh

# 5. Validate
./scripts/validate.sh
```

### Evaluation Checklist

- [ ] `install-deps.sh` runs without errors on fresh Debian Trixie
- [ ] `install-deps.sh` runs without errors on fresh Ubuntu 24.04 LTS
- [ ] `install-deps.sh` correctly identifies `apt` as package manager
- [ ] `install-deps.sh` runtime pkg `gsettings` replaced with correct Debian package name
- [ ] `install-deps.sh` runtime pkg `xmllint` replaced with `libxml2-utils`
- [ ] `install-deps.sh` runtime pkg `rofi` changed to `rofi-wayland` (or made conditional)
- [ ] `download-labwc.sh` builds labwc successfully
- [ ] sfwbar builds from source with meson/ninja (prefix `~/.local`)
- [ ] sfwbar modules install to correct lib path (not hardcoded `x86_64-linux-gnu`)
- [ ] `dotfiles/install.sh` completes without errors
- [ ] `dotfiles/install.sh` no longer creates `~/.config/zebar/` or `~/.glzr/zebar/`
- [ ] `dotfiles/install.sh` validation section works (no undefined `$ZEBAR_V3`/`$ZEBAR_V1`)
- [ ] `scripts/validate.sh` passes without referencing `$ZEBAR_DIR`
- [ ] Session file written to `/usr/share/wayland-sessions/labwc.desktop`
- [ ] `~/.local/bin` added to PATH correctly
- [ ] labwc launches from TTY via `start-labwc.sh`
- [ ] sfwbar launches and displays statusbar
- [ ] crystal-dock launches (if installed)
- [ ] Wallpaper loads via swaybg
- [ ] Keybinds functional (rofi launcher, screenshots, volume, brightness)
- [ ] Theme switching works (`themes.sh`)

### Known Debian Issues

- [ ] wlroots version: Bookworm ships 0.16, labwc 0.18+ needs wlroots 0.17+. Must build from source or use Trixie.
- [ ] `rofi` package is X11-only in older repos; need `rofi-wayland` (available in Trixie/Plucky).
- [ ] `sfwbar` not in any Debian/Ubuntu repo — must always build from source.
- [ ] `crystal-dock` not in repos — must build from source.
- [ ] Session file dir `/usr/share/wayland-sessions/` exists but needs `sudo` to write.
- [ ] `~/.local/bin` not always in PATH by default on minimal installs.
- [ ] `mako` package name is `mako-notifier` on Debian/Ubuntu (conflicts with Haskell build tool).

---

## Fedora (dnf)

### Package Availability

| Package | dnf name | Status | Notes |
|---------|----------|--------|-------|
| labwc | `labwc` | Available (Fedora 40+) | OK |
| sfwbar | `sfwbar` | **Available in Fedora 40+** | Only distro where sfwbar is packaged |
| crystal-dock | — | **NOT in repos** | Must build from source |
| wlroots | `wlroots-devel` | Available | OK |
| wayland | `wayland-devel` | Available | OK |
| swaybg | `swaybg` | Available | OK |
| foot | `foot` | Available | OK |
| rofi | `rofi-wayland` | Available | Use `rofi-wayland` not `rofi` |
| grim/slurp | `grim`, `slurp` | Available | OK |
| wl-clipboard | `wl-clipboard` | Available | OK |
| playerctl | `playerctl` | Available | OK |
| gammastep | `gammastep` | Available | OK |
| mako | `mako` | Available | OK |
| dunst | `dunst` | Available | OK |
| polkit | `polkit-gnome` | Available | OK |
| xmllint | `libxml2` | Available (provides xmllint) | `install-deps.sh` says `libxml2-utils` — wrong for Fedora |
| meson/ninja | `meson`, `ninja-build` | Available | OK |

### Testing Steps

```bash
# 1. Install deps
./scripts/install-deps.sh

# 2. Build labwc (or use package)
sudo dnf install labwc

# 3. Install sfwbar (available in repos)
sudo dnf install sfwbar

# 4. Install dotfiles
./dotfiles/install.sh

# 5. Validate
./scripts/validate.sh
```

### Evaluation Checklist

- [ ] `install-deps.sh` runs without errors on fresh Fedora 40
- [ ] `install-deps.sh` runs without errors on fresh Fedora 41
- [ ] `install-deps.sh` correctly identifies `dnf` as package manager
- [ ] `install-deps.sh` runtime pkg `libxml2-utils` replaced with `libxml2` for Fedora
- [ ] `install-deps.sh` skips building sfwbar from source (uses `dnf install sfwbar`)
- [ ] `dotfiles/install.sh` completes without errors
- [ ] `dotfiles/install.sh` no longer creates zebar directories
- [ ] `dotfiles/install.sh` validation section works
- [ ] `scripts/validate.sh` passes without referencing `$ZEBAR_DIR`
- [ ] `setup-sfwbar.sh` detects sfwbar as repo-installed and skips source build instructions
- [ ] `setup-sfwbar.sh` module path detection works on Fedora lib layout (`/usr/lib64/sfwbar/`)
- [ ] Session file written to `/usr/share/wayland-sessions/labwc.desktop`
- [ ] `~/.local/bin` added to PATH correctly
- [ ] labwc launches from TTY via `start-labwc.sh`
- [ ] sfwbar launches and displays statusbar
- [ ] crystal-dock launches (if installed)
- [ ] Wallpaper loads via swaybg
- [ ] Keybinds functional (rofi launcher, screenshots, volume, brightness)
- [ ] Theme switching works (`themes.sh`)
- [ ] No SELinux denials from autostart scripts or sfwbar module loading

### Known Fedora Issues

- [ ] `sfwbar` is available in repos — `install-deps.sh` should NOT build from source on Fedora.
- [ ] `crystal-dock` not in repos — always needs source build.
- [ ] `install-deps.sh` lists `libxml2-utils` for Fedora but correct package is `libxml2`.
- [ ] Fedora may have newer wlroots than labwc expects — version mismatch possible.
- [ ] SELinux could interfere with autostart scripts or sfwbar module loading.
- [ ] `/usr/share/wayland-sessions/` exists, needs `sudo` for session file.
- [ ] `setup-sfwbar.sh` module path hardcoded to `x86_64-linux-gnu` — Fedora uses `/usr/lib64/`.

---

## Arch Linux (pacman)

### Package Availability

| Package | pacman name | Status | Notes |
|---------|-------------|--------|-------|
| labwc | `labwc` | Available (extra repo) | OK |
| sfwbar | — | **NOT in repos, NOT in AUR** | Must build from source |
| crystal-dock | — | **NOT in repos/AUR** | Must build from source |
| wlroots | `wlroots` | Available | OK |
| wayland | `wayland` | Available | OK |
| swaybg | `swaybg` | Available | OK |
| foot | `foot` | Available | OK |
| rofi | `rofi-wayland` | Available (AUR) | `rofi` (X11) is in repos; `rofi-wayland` is AUR |
| grim/slurp | `grim`, `slurp` | Available | OK |
| wl-clipboard | `wl-clipboard` | Available | OK |
| playerctl | `playerctl` | Available | OK |
| gammastep | `gammastep` | Available | OK |
| mako | `mako` | Available | OK |
| dunst | `dunst` | Available | OK |
| polkit | `polkit-gnome` | Available | OK |
| xmllint | `libxml2` | Available (provides xmllint) | OK |
| meson/ninja | `meson`, `ninja` | Available | Note: `ninja` not `ninja-build` |

### Testing Steps

```bash
# 1. Install deps
./scripts/install-deps.sh

# 2. Build labwc (or use pacman)
sudo pacman -S labwc

# 3. Build sfwbar from source
cd build/sfwbar-src
meson setup build --prefix=$HOME/.local
ninja -C build
ninja -C build install
cd ../..

# 4. Install dotfiles
./dotfiles/install.sh

# 5. Validate
./scripts/validate.sh
```

### Evaluation Checklist

- [ ] `install-deps.sh` runs without errors on fresh Arch installation
- [ ] `install-deps.sh` correctly identifies `pacman` as package manager
- [ ] `install-deps.sh` runtime pkg `rofi` changed to `rofi-wayland` (requires AUR helper)
- [ ] `install-deps.sh` build pkg `ninja` is correct (Arch uses `ninja`, not `ninja-build`)
- [ ] `download-labwc.sh` builds labwc successfully (or skip if `pacman -S labwc` used)
- [ ] sfwbar builds from source with meson/ninja (prefix `~/.local`)
- [ ] sfwbar modules install to correct lib path (Arch uses `/usr/lib/`)
- [ ] `dotfiles/install.sh` completes without errors
- [ ] `dotfiles/install.sh` no longer creates zebar directories
- [ ] `dotfiles/install.sh` validation section works
- [ ] `scripts/validate.sh` passes without referencing `$ZEBAR_DIR`
- [ ] `setup-sfwbar.sh` does NOT suggest `yay -S sfwbar` (sfwbar not in AUR)
- [ ] `setup-sfwbar.sh` module path detection works on Arch lib layout (`/usr/lib/sfwbar/`)
- [ ] Session file written to `/usr/share/wayland-sessions/labwc.desktop`
- [ ] `~/.local/bin` added to PATH correctly (not in PATH by default on Arch)
- [ ] labwc launches from TTY via `start-labwc.sh`
- [ ] sfwbar launches and displays statusbar
- [ ] crystal-dock launches (if installed)
- [ ] Wallpaper loads via swaybg
- [ ] Keybinds functional (rofi launcher, screenshots, volume, brightness)
- [ ] Theme switching works (`themes.sh`)

### Known Arch Issues

- [ ] `sfwbar` not packaged anywhere on Arch — must build from source.
- [ ] `rofi-wayland` is in AUR, not extra/community repos — users need an AUR helper.
- [ ] `crystal-dock` not in repos/AUR — must build from source.
- [ ] Arch uses rolling release; wlroots/labwc versions may shift unexpectedly.
- [ ] `/usr/share/wayland-sessions/` exists, needs `sudo`.
- [ ] `~/.local/bin` is NOT in PATH by default — must add manually or via profile.d.
- [ ] `setup-sfwbar.sh:47` says `yay -S sfwbar` — this is WRONG; sfwbar is not in AUR.
- [ ] `install-deps.sh` uses `ninja-build` for pacman — Arch package is just `ninja`.

---

## Cross-Distro Compatibility Matrix

| Component | Debian/Ubuntu | Fedora | Arch |
|-----------|--------------|--------|------|
| labwc | Build from source (or Trixie+) | `dnf install` | `pacman -S` |
| sfwbar | Build from source | `dnf install` | Build from source |
| crystal-dock | Build from source | Build from source | Build from source |
| rofi-wayland | `apt install rofi-wayland` (Trixie+) | `dnf install rofi-wayland` | AUR (`yay -S rofi-wayland`) |
| polkit | `lxpolkit` | `polkit-gnome` | `polkit-gnome` |
| xmllint | `libxml2-utils` | `libxml2` | `libxml2` |
| ninja | `ninja-build` | `ninja-build` | `ninja` |
| mako | `mako-notifier` | `mako` | `mako` |
| sfwbar module path | `~/.local/lib/x86_64-linux-gnu/sfwbar/` | `/usr/lib64/sfwbar/` | `/usr/lib/sfwbar/` or `~/.local/lib/sfwbar/` |

---

## Fix List (Scripts to Update)

Priority-ordered list of script fixes required before cross-distro validation:

| Priority | # | Script | Fix | Status |
|----------|---|--------|-----|--------|
| **P0** | 1 | `dotfiles/install.sh` | Replace zebar pre-flight check with sfwbar check | ✅ Fixed |
| **P0** | 2 | `dotfiles/install.sh` | Remove zebar directory creation, keep only sfwbar paths | ✅ Fixed |
| **P0** | 3 | `dotfiles/install.sh` | Fix validation section — remove zebar refs, validate sfwbar config | ✅ Fixed |
| **P0** | 4 | `scripts/validate.sh` | Fix `$ZEBAR_DIR` → `$SFWBAR_DIR` | ✅ Fixed |
| **P1** | 5 | `scripts/setup-sfwbar.sh` | Fix module path detection — use dynamic arch detection | ✅ Fixed |
| **P1** | 6 | `scripts/setup-sfwbar.sh` | Fix Arch instructions — sfwbar NOT in AUR, build from source | ✅ Fixed |
| **P1** | 7 | `scripts/setup-sfwbar.sh` | Add Fedora-specific instructions | ✅ Fixed |
| **P1** | 8 | `scripts/install-deps.sh` | Fix Debian runtime pkg names | ✅ Fixed |
| **P1** | 9 | `scripts/install-deps.sh` | Fix Fedora runtime pkg names | ✅ Fixed |
| **P1** | 10 | `scripts/install-deps.sh` | Fix Arch build pkg names | ✅ Fixed |
| **P2** | 11 | `dotfiles/install.sh` | Update summary text — remove zebar paths | ✅ Fixed |
| **P2** | 12 | `dotfiles/install.sh` | Update help text — "Widget shell actions" | ✅ Fixed |
| **P2** | 13 | `scripts/install-deps.sh` | Update header — "sfwbar" | ✅ Fixed |
| **P2** | 14 | `scripts/validate.sh` | Remove `zebar` from `OPTIONAL_BINS`, add `sfwbar` | ✅ Fixed |

---

## Test Environments

Recommended VM/container setups for evaluation:

| Distro | ISO / Image | Notes |
|--------|-------------|-------|
| Debian 13 (Trixie) | `debian-13-genericcloud-amd64.qcow2` | Has labwc + wlroots 0.18 in repos |
| Debian 12 (Bookworm) | `debian-12-genericcloud-amd64.qcow2` | Needs source build for labwc + wlroots |
| Ubuntu 24.04 LTS | `ubuntu-24.04-live-server-amd64.iso` | May need PPA for labwc |
| Ubuntu 25.04 | `ubuntu-25.04-desktop-amd64.iso` | Has labwc in repos |
| Fedora 40 | `Fedora-Everything-40-x86_64.iso` | sfwbar in repos |
| Fedora 41 | `Fedora-Everything-41-x86_64.iso` | sfwbar in repos |
| Arch Linux | `archlinux-x86_64.iso` (rolling) | Need `base-devel` + AUR helper |

---

## Progress Tracker

| Phase | Status |
|-------|--------|
| Script audit (zebar remnants) | ⬜ Not started |
| P0 fixes applied | ⬜ Not started |
| P1 fixes applied | ⬜ Not started |
| P2 fixes applied | ⬜ Not started |
| Debian Trixie test | ⬜ Not started |
| Debian Bookworm test | ⬜ Not started |
| Ubuntu 24.04 test | ⬜ Not started |
| Fedora 40 test | ⬜ Not started |
| Fedora 41 test | ⬜ Not started |
| Arch Linux test | ⬜ Not started |
| All distros pass `validate.sh` | ⬜ Not started |
