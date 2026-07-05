# Lesson 12: Building JSON by String Concatenation

**Files affected:** `scripts/workspace-presets.sh`, `scripts/ocws-state.sh`
**Severity:** Medium — produces malformed JSON that silently breaks any consumer

---

## What Happened

### workspace-presets.sh — heredoc with array-as-JSON

```bash
cat > "$preset_file" << EOF
{
  "keybindings": {
    "common": [
      "A-r": "Reconfigure",       # BUG: arrays use [], not {}
      "A-q": "Close",             # BUG: this is object syntax inside an array
      ...
    ],
  }
}
EOF
```

This produces invalid JSON. Arrays (`[...]`) hold values; objects (`{...}`) hold
key-value pairs. Mixing the two breaks JSON parsers. Additionally, trailing commas
after the last element (`"A-a": "Execute fuzzel"` followed by `]`) are illegal in
JSON (valid in JavaScript but not JSON).

### ocws-state.sh — manual JSON assembly via string concatenation

```bash
local json_pairs=""
for key in "${!pairs[@]}"; do
    json_pairs="$json_pairs, \"$key\": \"${pairs[$key]}\""
done
json_pairs="{${json_pairs#\", }}"   # strip leading ", " then wrap in {}
echo "$json_pairs" > "$state_file"
```

Problems:
1. If a value contains `"`, `\`, or newlines, the resulting JSON is malformed.
2. The `#", "` strip only removes the first `", ` — if the loop starts with an
   empty `json_pairs` the result is `{, "key": "val"}` which is invalid.
3. No escaping means injection: a value of `bad"value` produces `"key": "bad"value"`.

## The Fix

**Always use `jq` to produce JSON.** It handles all escaping automatically:

```bash
# From an associative array
declare -A pairs=([artist]='AC/DC' [title]='Back "In" Black')

# Build args dynamically
jq_args=()
for key in "${!pairs[@]}"; do
    jq_args+=(--arg "$key" "${pairs[$key]}")
done
# Build the jq expression
jq_expr=$(printf '"%s": $%s, ' "${!pairs[@]}" | sed 's/, $//')
jq -n "${jq_args[@]}" "{$jq_expr}" > "$state_file"
```

Or for fixed-structure JSON in a heredoc, use `jq` as the template engine:

```bash
jq -n \
    --arg name "$name" \
    --arg desc "$description" \
    --argjson ws_num "${ws_number:-1}" \
    '{
        name: $name,
        description: $desc,
        workspace: { number: $ws_num }
    }' > "$preset_file"
```

For the workspace keybindings, use a proper JSON object instead of an array:

```json
"keybindings": {
    "A-r": "Reconfigure",
    "A-q": "Close"
}
```

## The General Rule

> **Never build JSON by concatenating strings.** Use `jq -n` with `--arg` / `--argjson`
> for all JSON generation. This guarantees:
> - Proper quoting of strings
> - Escaping of special characters (`"`, `\`, newlines, tabs)
> - Structurally valid output every time

| Pattern | Problem | Fix |
|---|---|---|
| `echo "{\"k\": \"$v\"}"` | No escaping of `$v` | `jq -n --arg k "$v" '{"k": $k}'` |
| heredoc with `$vars` | Values with `"` break structure | `jq -n --arg v "$var" '...'` |
| String concat loop | Leading/trailing comma bugs | `jq -n` with dynamic args |

## How to Catch It

```bash
# Validate all JSON files after generation
jq . "$preset_file" > /dev/null || echo "Invalid JSON: $preset_file"

# In CI: validate every .json written by the codebase
find ~/.config/ocws -name "*.json" -exec jq empty {} \; 2>&1 | grep -v '^$'
```
