# Lesson: Unclosed Parentheses In `If()` Chains Cause Silent Failure

## The Problem

A widget function with multiple chained `If()` calls:

```ini
Function XWeatherIcon() {
  Return(
    If(XWeatherCode = 0, "weather-clear-symbolic",
    If(XWeatherCode = 1, "weather-few-clouds-symbolic",
    ...
    If(XWeatherCode = 25, "weather-snow-symbolic",
      "weather-clear-symbolic")))))))     # ← 8 closing parens, need 9
}
```

The outer `If()` call is never closed. The function returns without a value, and the widget shows nothing.

## Root Cause

When nesting `If()` calls, each `If(` needs one closing `)` — plus one for the outer `Return(`. In `weather.widget`, both `XWeatherIcon()` and `XWeatherDesc()` have 9 `If()` calls but only 8 closing parentheses on the last line.

This is extremely hard to spot visually because the closing parens are all on one line: `))))))))`. Counting them is error-prone.

```ini
# Line 22 in weather.widget — 8 parens for 9 If() calls
      "weather-clear-symbolic"))))))))
#                                12345678 (X) wrong
```

## The Fix

Count parentheses explicitly. For 9 `If()` calls, you need 9 closing parens:

```ini
# Line 22 — 9 parens for 9 If() calls
      "weather-clear-symbolic")))))))))
#                                123456789 (OK) correct
```

Better: format nested `If()` with one paren per line to make counting obvious:

```ini
Function XWeatherIcon() {
  Return(
    If(XWeatherCode = 0, "weather-clear-symbolic",
    If(XWeatherCode = 1, "weather-few-clouds-symbolic",
    ...
    If(XWeatherCode = 25, "weather-snow-symbolic",
      "weather-clear-symbolic"
    ))))))
  )
}
```

This makes it clear that each `If(` has its own `)` on the same indentation level.

## Verification

```bash
# Count opening vs closing parens in a widget file
opens=$(grep -o 'If(' weather.widget | wc -l)
closes=$(grep -o ')' weather.widget | wc -l)
# Each If( needs one ), plus Return( needs one ), plus Function block {}
# Expected: opens + 2 (for Return + Function block) = total closes
echo "If(...) opens: $opens, total closes: $closes"
```

## Where This Applies

- `weather.widget:12-23` — `XWeatherIcon()` function
- `weather.widget:25-36` — `XWeatherDesc()` function

## Pattern To Remember

One `If(` needs exactly one `)`. When nesting `N` levels deep, count `N` closing parens. Put them one-per-line to verify.
