# Demo recording

Renders the README demo GIF (`../assets/demo.gif`) by driving the **real local
Neovim config** with [VHS](https://github.com/charmbracelet/vhs). Unlike the
sibling `beads.nvim` (a plugin recorded hermetically in Docker), this is the full
config — all plugins and Mason LSP servers are already provisioned locally, so
re-bootstrapping them headlessly in a container would be flaky. We record on the
host instead.

## Render

```bash
recording/record.sh
```

That copies `recording/demo/` to a throwaway git repo, isolates the shada (clean
MRU, empty PR overlay — no personal data on screen), pre-seeds the demo MRU, and
runs `recording/demo.tape`, writing `assets/demo.gif`. Commit the GIF; nothing
auto-pushes.

## Requirements

`vhs`, `ttyd`, `ffmpeg` on `$PATH`, plus a Nerd Font matching `demo.tape`'s
`Set FontFamily`. No sudo needed — userspace install works:

```bash
mkdir -p ~/.local/bin ~/.local/share/fonts
# vhs
curl -fsSL "$(curl -fsSL https://api.github.com/repos/charmbracelet/vhs/releases/latest \
  | grep -oE 'https://[^"]*Linux_x86_64\.tar\.gz' | head -1)" | tar -xz -C /tmp
cp /tmp/vhs_*/vhs ~/.local/bin/ && chmod +x ~/.local/bin/vhs
# ttyd (static) + ffmpeg (static)
curl -fsSL -o ~/.local/bin/ttyd https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64
chmod +x ~/.local/bin/ttyd
curl -fsSL https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz | tar -xJ -C /tmp
cp /tmp/ffmpeg-*-static/ffmpeg ~/.local/bin/ && chmod +x ~/.local/bin/ffmpeg
# Nerd Font (JetBrainsMono — match the family name in demo.tape)
curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
  | tar -xJ -C ~/.local/share/fonts/ && fc-cache -f
```

`fc-list | grep -i nerd` confirms the installed family name; update
`Set FontFamily` in `demo.tape` if you use a different font.

## Files

| File         | Role                                                            |
|--------------|-----------------------------------------------------------------|
| `record.sh`  | Set up the throwaway demo + isolated state, run the tape.       |
| `demo.tape`  | The VHS script: start screen + MRU, Telescope, completion, LSP. |
| `demo/`      | Synthetic TypeScript fixture (no personal data).                |

## Notes

- **Privacy**: the start screen overlays MRU files and open PRs (`gh`/`glab`).
  `record.sh` isolates `XDG_STATE_HOME` (fresh shada) and records from a git repo
  with no remote, so only the synthetic demo files appear on screen.
- **Don't isolate `XDG_DATA_HOME`** — plugins (lazy) and Mason servers live there;
  moving it would un-provision the config and kill the LSP demo.
- **Timing is iterative**: `Sleep`/`TypingSpeed` usually need a couple of
  re-render passes to look clean. LSP actions especially may need more `Sleep`
  before the menu/hover lands.
- **Re-record per Neovim version** — the GIF is a committed artifact.
