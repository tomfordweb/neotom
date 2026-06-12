# Demo recording

Renders the README demo GIF (`../assets/demo.gif`) by driving the **real local
Neovim config**. Unlike the sibling `beads.nvim` (a plugin recorded hermetically
in Docker), this is the full config — all plugins and Mason LSP servers are
already provisioned locally, so re-bootstrapping them headlessly in a container
would be flaky. We record on the host instead.

## Render

```bash
recording/record.sh
```

That copies `recording/demo/` to a throwaway git repo, isolates the shada (clean
MRU, empty PR overlay — no personal data on screen), pre-seeds the demo MRU,
drives Neovim through the demo choreography, and writes `assets/demo.gif`. Commit
the GIF; nothing auto-pushes.

## Pipeline: why not VHS?

We record with **tmux → [asciinema](https://asciinema.org) → [agg](https://github.com/asciinema/agg)**:

- A headless `tmux` pane runs `asciinema rec -c nvim`, so the cast starts at the
  Neovim launch (no shell prompt on camera) and ends when Neovim quits.
- `record.sh` drives the session with `tmux send-keys` (the choreography lives in
  the script, not a separate file).
- `agg` rasterizes the cast to GIF with its own font engine.

We previously used [VHS](https://github.com/charmbracelet/vhs), but VHS renders
through `ttyd`'s bundled **xterm.js**, which mis-measures every Nerd Font's cell
width as ~2× on this machine — glyphs land in the left half of double-wide cells,
producing "busted" letter-spacing. The bug is present in *every* VHS-compatible
`ttyd` (1.7.2–1.7.7) and older `ttyd` is rejected by VHS, so there was no working
combination. `agg` doesn't use xterm.js, so the system font + Nerd Font icons
render at the correct width.

## Requirements

`tmux`, `asciinema`, `agg`, `nvim` on `$PATH`, plus the Nerd Font named in
`record.sh` (`FONT`). No sudo needed — userspace install works:

```bash
# asciinema (pipx/pip) + agg (cargo, or grab a release binary)
pipx install asciinema        # or: pip install --user asciinema
cargo install --git https://github.com/asciinema/agg
# Nerd Font (Monaspace — use the *Mono* (NFM) variant; matches the ghostty config)
mkdir -p ~/.local/share/fonts/Monaspace
curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Monaspace.tar.xz \
  | tar -xJ -C ~/.local/share/fonts/Monaspace && fc-cache -f
```

`fc-list | grep -i monaspice` confirms the installed family name
(`MonaspiceNe Nerd Font Mono`); update `FONT` in `record.sh` if you use a
different font.

## Files

| File         | Role                                                                     |
|--------------|--------------------------------------------------------------------------|
| `record.sh`  | Set up the throwaway demo + isolated state, drive nvim, render with agg. |
| `demo/`      | Synthetic TypeScript fixture (no personal data).                         |

## Notes

- **Privacy**: the start screen overlays MRU files and open PRs (`gh`/`glab`).
  `record.sh` isolates `XDG_STATE_HOME` (fresh shada) and records from a git repo
  with no remote, so only the synthetic demo files appear on screen.
- **Don't isolate `XDG_DATA_HOME`** — plugins (lazy) and Mason servers live there;
  moving it would un-provision the config and kill the LSP demo.
- **Timing is iterative**: the `sleep`s and per-keystroke `TS` delay in `record.sh`
  usually need a couple of re-render passes to look clean. LSP actions especially
  may need more `sleep` before the menu/hover lands.
- **Grid → GIF size**: `COLS`/`ROWS`/`FONT_SIZE` in `record.sh` set the terminal
  grid; the current values render ~1250×857.
- **Re-record per Neovim version** — the GIF is a committed artifact.
