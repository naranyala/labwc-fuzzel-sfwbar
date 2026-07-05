# Theme Engine and Installer Architecture Lessons

## The Problem
The project's ecosystem had fragmented deployment and configuration issues:
1. Running `theme-engine.sh apply` generated over 50 "Unknown template variable" warnings (e.g., `{{GTK_THEME}}`, `{{ROFI_BG}}`, `{{MAKO_FONT}}`).
2. Running the main `install.sh` script silently skipped deploying configurations for major components like `rofi`, `mako`, `qt6ct`, and `zebar`, and GTK themes failed to apply.

## The Cause
1. **Hardcoded Template Variable Parsing**: The `theme-engine.sh` script lacked generic resolvers. It only successfully parsed `FOOT_*` variables, leaving variables for other apps unresolved.
2. **Incomplete Installer Script**: `install.sh` lacked deployment blocks (`cp -r ...`) for newly added ecosystem components. Furthermore, it looked for GTK configs in `dotfiles/gtk/`, whereas the theme engine exported them to version-specific directories (`dotfiles/gtk-3.0/` and `dotfiles/gtk-4.0/`).
3. **Improper Export Paths**: The `theme-engine.sh export` command incorrectly bypassed the `dotfiles/` directory for Zebar, writing directly to the user's home directory (`$HOME/.glzr/...`), which broke version control syncing.

## The Solution
- **Dynamic Variable Resolution**: Enhanced `theme-engine.sh` to automatically map variable prefixes (`ROFI_*`, `MAKO_*`, `QT_*`, `GTK_*`, `FONT_*`, `CURSOR_*`, `COLOR_*`) to their respective `.ini` sections dynamically.
- **Installer Completeness**: Added deployment blocks in `install.sh` for `rofi`, `mako`, `qt6ct`, `zebar`, and `foot`, and corrected the GTK sync logic to pull from `gtk-3.0` and `gtk-4.0`.
- **Export Path Fixes**: Corrected the Zebar export logic in `theme-engine.sh` to map `$HOME` paths strictly to `$DOTFILES_DIR` paths during export.
