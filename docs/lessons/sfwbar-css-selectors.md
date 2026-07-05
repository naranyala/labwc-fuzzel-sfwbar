# Lesson: sfwbar CSS Selectors Depend on Bar Naming

## The Problem

When bars are **named** in the config, sfwbar uses that name as the CSS window ID — **not** the default `sfwbar`. All CSS targeting `window#sfwbar` silently fails to style named bars.

## Root Cause

```ini
# ocws.config
bar "topbar:top" { ... }     # → window CSS id = "topbar"
bar "bottombar:bottom" { ... } # → window CSS id = "bottombar"
```

The CSS had:
```css
/* WRONG — matches only unnamed bars */
window#sfwbar { ... }
```

## The Fix

Use the bar's name (the part before `:`) as the CSS ID:

```css
/* CORRECT — matches both named bars */
window#topbar, window#bottombar { ... }
```

## Rules

1. **Unnamed bar** `bar { ... }` → CSS id = `sfwbar` (default)
2. **Named bar** `bar "foo:top" { ... }` → CSS id = `foo`
3. The grid inside a bar also gets the bar name as its CSS id (`grid#foo`)
4. CSS selectors must match the actual bar name, not the default

## Example

```ini
bar "mynav:top" {
  edge = "top"
  widget "clock"
}
```

```css
/* Must use #mynav, not #sfwbar */
window#mynav {
  background-color: rgba(0, 0, 0, 0.8);
}
```

## Where This Applies

- `ocws.config` CSS section
- `ocws.css` / `theme.css` files
- Template files (`*.tmpl`)
- Any CSS included via `include()` in widget files
