#!/usr/bin/env bash
# Render the neotom README demo GIF (assets/demo.gif) with VHS, driving the REAL
# local Neovim config so every flashy feature (LSP, completion, treesitter) is
# live. Unlike ../beads.nvim's hermetic Docker pipeline, this records on the host
# because the full config + Mason servers are already provisioned locally.
#
#   recording/record.sh
#
# What it does, hermetically enough to avoid leaking personal data on camera:
#   - copies recording/demo/ to a throwaway $DEMO_DIR (a fresh git repo with NO
#     remote, so the start screen's `gh pr list` overlay comes up empty)
#   - isolates XDG_STATE_HOME (empty shada -> no personal MRU) while keeping the
#     real XDG_DATA_HOME/XDG_CONFIG_HOME (plugins + Mason + the neotom config)
#   - pre-seeds the demo MRU so the start-screen 1-9 list shows the demo files
#   - runs the tape from the repo root; Output lands in assets/demo.gif
#
# Re-record per Neovim version. Commit the GIF; nothing here auto-pushes.
#
# Requires: vhs, ttyd, ffmpeg on PATH, and a Nerd Font matching demo.tape's
# `Set FontFamily`. Userspace install (no sudo) is fine — see recording/README.md.
set -euo pipefail

REPO="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$REPO"

for bin in vhs ttyd ffmpeg nvim; do
  command -v "$bin" >/dev/null || { echo "missing on PATH: $bin (see recording/README.md)" >&2; exit 1; }
done

# Throwaway demo project: fresh, no remote, with one commit so gitsigns has history.
# NOT under /tmp — the config's shada has `r/tmp/`, which excludes /tmp paths from
# oldfiles, so a /tmp demo dir would never populate the start-screen MRU.
export DEMO_DIR="${DEMO_DIR:-$HOME/.cache/neotom-demo}"
rm -rf "$DEMO_DIR"
mkdir -p "$DEMO_DIR"
cp recording/demo/* "$DEMO_DIR"/
git -C "$DEMO_DIR" init -q
git -C "$DEMO_DIR" -c user.email=demo@example.com -c user.name=demo add -A
git -C "$DEMO_DIR" -c user.email=demo@example.com -c user.name=demo commit -q -m "demo fixture"

# Isolate shada (clean MRU) but keep the real config + plugin/Mason data dirs.
export XDG_STATE_HOME="$(mktemp -d)"
export XDG_CONFIG_HOME="$(dirname "$REPO")"          # .../config (parent of nvim)
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# Pre-seed the demo MRU into the isolated shada. oldfiles is ordered by edit
# order (first edited -> index 1), and get_mru() takes them in order, so edit
# app.ts FIRST to make it MRU #1 (the file the tape opens with "1"). VimLeave on
# +qa writes oldfiles to the shada (each file gets a '" mark on buffer-leave).
( cd "$DEMO_DIR" && nvim --headless \
    +"edit app.ts" +"edit util.ts" +"edit config.json" +"edit notes.md" \
    +"qa" >/dev/null 2>&1 )

echo "==> rendering assets/demo.gif (DEMO_DIR=$DEMO_DIR, XDG_STATE_HOME=$XDG_STATE_HOME)"
vhs recording/demo.tape

ls -lh "$REPO/assets/demo.gif"
