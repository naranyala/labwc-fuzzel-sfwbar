# wl-clipboard — Learning Material

> Source: `./sources/wl-clipboard` | Upstream: https://github.com/bugaevc/wl-clipboard

---

## What is wl-clipboard?

**wl-clipboard** provides `wl-copy` and `wl-paste` — the Wayland equivalents of `xclip`/`xsel`.
Used everywhere in OCWS scripts: copying screenshots, emoji picks, calc results, feeding cliphist.

---

## wl-copy — Copy to clipboard

```bash
echo "hello" | wl-copy           # copy text from stdin
wl-copy "hello world"            # copy inline text
wl-copy < ~/file.txt             # copy file content
wl-copy < ~/photo.png            # copy an image
wl-copy --clear                  # clear clipboard
wl-copy --primary "text"         # copy to primary selection (middle-click)
printf "no-newline" | wl-copy    # preserve exact bytes
```

### wl-copy flags

| Flag | Description |
|------|-------------|
| `--primary` / `-p` | Use primary selection |
| `--trim-newline` / `-n` | Strip trailing newline from stdin |
| `--paste-once` / `-o` | Serve clipboard once then exit |
| `--clear` / `-c` | Clear clipboard |
| `--type MIME` / `-t` | Set MIME type |
| `--foreground` / `-f` | Don't daemonize |

---

## wl-paste — Paste from clipboard

```bash
wl-paste                         # paste text to stdout
wl-paste > clipboard.txt         # paste to file
wl-paste --list-types            # show available MIME types
wl-paste --type image/png > img.png
wl-paste --no-newline            # no trailing newline
wl-paste --primary               # paste from primary selection

# Watch mode — run command on each clipboard change
wl-paste --watch cliphist store
wl-paste --type text/plain --watch cliphist store
wl-paste --type image --watch cliphist store
```

### wl-paste flags

| Flag | Description |
|------|-------------|
| `--primary` / `-p` | Paste from primary selection |
| `--no-newline` / `-n` | No trailing newline |
| `--list-types` / `-l` | List available MIME types |
| `--type MIME` / `-t` | Request specific MIME type |
| `--watch CMD` / `-w` | Run CMD on each clipboard change |

---

## OCWS Usage Patterns

```bash
# Screenshot region → clipboard
grim -g "$(slurp)" - | wl-copy

# Emoji picker → clipboard
emoji=$(cat ~/.local/share/emoji.txt | fuzzel --dmenu)
echo -n "$emoji" | wl-copy

# Calc result → clipboard
echo "$(fuzzel --dmenu --accept-input --prompt 'calc: ')" | bc | wl-copy

# Clipboard history daemon (autostart)
wl-paste --type text/plain --watch cliphist store &
wl-paste --type image --watch cliphist store &
```

---

## Build from Source

```bash
cd sources/wl-clipboard
meson build && ninja -C build
sudo ninja -C build install
```

**Dependencies:** meson, wayland
