# Foot Terminal Configuration Lessons

## The Problem
When generating configurations for the `foot` terminal emulator, users encountered errors such as:
`error: foot: ~/.config/foot/foot.ini:27: [colors-dark:].regular7: #bac2de: color must be in RGB format`

## The Cause
There were two strict syntax rules in `foot`'s configuration that were being violated by the generated template:
1. **Hex Color Format**: `foot` requires RGB hex colors to be specified **without** the `#` prefix (e.g., `1e1e2e` instead of `#1e1e2e`).
2. **Colors Section Naming**: `foot` expects the section containing terminal color definitions to be explicitly named `[colors]`. It does not support arbitrary section names like `[colors-dark]`.

## The Solution
- Updated the template `templates/foot.ini.tmpl` to use the correct `[colors]` section header.
- Added parsing logic in `scripts/theme-engine.sh` to automatically strip `#` prefixes from any variables destined for the `foot` configuration (i.e. variables prefixed with `color_`).
