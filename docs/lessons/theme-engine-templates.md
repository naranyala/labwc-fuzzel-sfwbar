# Lesson: Theme Engine Template Variable Fallbacks

## The Problem

The theme engine (`theme-engine.sh`) renders `{{VARIABLE}}` placeholders in template files. When a theme INI doesn't define a color key, the variable resolves to an **empty string**, leaving the literal `{{COLOR_BG}}` in the output CSS instead of using the intended default.

## How It Works

1. Theme INI defines colors: `[colors] bg=#1e1e2e`
2. Template has: `background-color: {{COLOR_BG}};`
3. `render_template()` looks up `COLOR_BG` via `ini_get("colors.bg", "#1e1e2e")`
4. If the INI defines `bg`, the value is used. If not, the default is returned.
5. The result replaces `{{COLOR_BG}}` in the template.

## The Bug

The `case` statement in `render_template()` defines defaults, but they're never used as fallbacks because `ini_get` always returns *something* (either the INI value or the default parameter). However, if the INI key exists but is **empty**, or if the section header is malformed, `ini_get` returns empty and the template variable is replaced with nothing.

```bash
# Bug: empty var_value means the {{VARIABLE}} stays in output
content="${content//\{\{$var_name\}\}/$var_value}"
```

## The Fix

Add explicit fallback when `var_value` is empty:

```bash
if [[ -z "$var_value" ]]; then
    case "$var_name" in
        COLOR_BG)      var_value="#1e1e2e" ;;
        COLOR_FG)      var_value="#cdd6f4" ;;
        COLOR_SURFACE) var_value="#1e1e2e" ;;
        COLOR_BORDER)  var_value="#45475a" ;;
        COLOR_ACCENT)  var_value="#89b4fa" ;;
        COLOR_URGENT)  var_value="#f38ba8" ;;
        COLOR_OK)      var_value="#a6e3a1" ;;
        COLOR_MUTED)   var_value="#a6adc8" ;;
        OCWS_BLUR)     var_value="5" ;;
        OCWS_BORDER)   var_value="1" ;;
        OCWS_RADIUS)   var_value="8" ;;
        OCWS_SHADOW)   var_value="4" ;;
    esac
fi
content="${content//\{\{$var_name\}\}/$var_value}"
```

## Lesson

Always provide fallback defaults **at the point of use**, not just in the lookup function. The lookup function's default parameter is a convenience, not a guarantee — it can be bypassed by empty INI values, missing sections, or malformed keys.
