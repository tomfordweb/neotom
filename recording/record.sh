#!/usr/bin/env bash
# Render the neotom README demo GIF (assets/demo.gif), driving the REAL local
# Neovim config so every flashy feature (LSP, completion, treesitter, icons) is
# live. Unlike ../beads.nvim's hermetic Docker pipeline, this records on the host
# because the full config + Mason servers are already provisioned locally.
#
#   recording/record.sh
#
# Pipeline: tmux (headless pane) -> asciinema (records nvim's PTY) -> agg (GIF).
#
#   We previously used VHS, but VHS renders through ttyd's bundled xterm.js, which
#   mis-measures every Nerd Font's cell width as ~2x on this machine (glyphs land
#   in the left half of double-wide cells -> "busted" letter-spacing). Every
#   VHS-compatible ttyd (1.7.2-1.7.7) has the bug; older ttyd is rejected by VHS.
#   agg rasterizes with its own font engine (fontdue/swash), so the system font +
#   Nerd Font icons render at correct width. See recording/README.md.
#
# Hermetic enough to avoid leaking personal data on camera:
#   - copies recording/demo/ to a throwaway $DEMO_DIR (a fresh git repo with NO
#     remote, so the start screen's `gh pr list` overlay comes up empty)
#   - isolates XDG_STATE_HOME (empty shada -> no personal MRU) while keeping the
#     real XDG_DATA_HOME/XDG_CONFIG_HOME (plugins + Mason + the neotom config)
#   - pre-seeds the demo MRU so the start-screen 1-9 list shows the demo files
#
# Re-record per Neovim version. Commit the GIF; nothing here auto-pushes.
#
# Requires: tmux, asciinema, agg, nvim on PATH, and the Nerd Font named in FONT
# below (userspace install, no sudo — see recording/README.md).
set -euo pipefail

REPO="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$REPO"

for bin in tmux asciinema agg nvim; do
  command -v "$bin" >/dev/null || { echo "missing on PATH: $bin (see recording/README.md)" >&2; exit 1; }
done

# Must match the ghostty config font; use the Mono (NFM) Nerd Font variant.
FONT="MonaspiceNe Nerd Font Mono"
FONT_SIZE=18
COLS=110            # terminal grid; with FONT_SIZE 18 -> ~1250x857 GIF (>=1024x768)
ROWS=33

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
# app.ts FIRST to make it MRU #1 (the file the demo opens with "1"). VimLeave on
# +qa writes oldfiles to the shada (each file gets a '" mark on buffer-leave).
( cd "$DEMO_DIR" && nvim --headless \
    +"edit app.ts" +"edit util.ts" +"edit config.json" +"edit notes.md" \
    +"qa" >/dev/null 2>&1 )

CAST="$(mktemp --suffix=.cast)"
SOCK="neotomdemo"
TS="0.06"   # per-keystroke delay (typewriter feel; VHS used 60ms)

cleanup() { tmux -L "$SOCK" kill-server 2>/dev/null || true; rm -f "$CAST"; }
trap cleanup EXIT
tmux -L "$SOCK" kill-server 2>/dev/null || true

# Helpers driving the recorded pane ('s'). key(): named keys (Space/Enter/Escape/
# C-u/Down). lit(): one literal chunk. type(): literal chunk, char-by-char.
key()  { tmux -L "$SOCK" send-keys -t s "$@"; }
lit()  { tmux -L "$SOCK" send-keys -t s -l "$1"; }
type() { local s=$1 i; for ((i=0; i<${#s}; i++)); do lit "${s:i:1}"; sleep "$TS"; done; }

echo "==> recording (DEMO_DIR=$DEMO_DIR, XDG_STATE_HOME=$XDG_STATE_HOME)"

# The pane's only command is asciinema recording nvim, so the cast starts at the
# nvim launch (no shell prompt on camera) and ends when nvim quits.
tmux -L "$SOCK" new-session -d -s s -x "$COLS" -y "$ROWS" \
  "cd '$DEMO_DIR' && asciinema rec --overwrite -q -c nvim '$CAST'"

# Start screen: matrix-rain + NEOTOM reveal, then the MRU overlay. Let the hero
# breathe — this is the headline shot.
sleep 5

# HERO: open the top recent file straight from the start-screen MRU list (1-9).
lit "1"; sleep 2.5

# Telescope find-files: live-type FILTER narrows the result list, Enter opens it.
key Space; lit "f"; sleep 0.8
type "util"; sleep 1.6
key Enter; sleep 1.5

# Back to the TS entry point for the LSP tour.
lit ":e app.ts"; key Enter; sleep 1.8

# nvim-cmp completion menu (member completion on the `user` object). Esc leaves
# insert, then "u" undoes the scratch insertion.
lit "Go"; type "user."; sleep 1.7
key Escape; lit "u"; sleep 0.8

# LSP: hover docs (K opens the float; Esc dismisses).
lit "/greet"; key Enter; sleep 0.5
lit "K"; sleep 2
key Escape

# LSP: references -> quickfix list. Close it with :cclose (Esc won't).
lit "gr"; sleep 2.2
lit ":cclose"; key Enter; sleep 0.6

# LSP: jump to the live diagnostic; ]d opens a floating diagnostic window.
lit "]d"; sleep 2.2

# LSP: code action menu (TS source actions). Pick "Add all missing imports" (3rd)
# so the import line visibly gains `formatName` and the diagnostic clears.
key Space; lit "ca"; sleep 2.2
key Down; sleep 0.35
key Down; sleep 0.5
key Enter; sleep 1.8

# LSP: rename symbol (<leader>cr). Input is prefilled with the symbol, so C-u
# clears it before typing the new name.
lit "/user"; key Enter; sleep 0.4
key Space; lit "cr"; sleep 0.9
key C-u; type "account"; key Enter; sleep 1.7

# Multigrep with the glob-filter syntax: "<pattern>  <glob>". Close with two Esc.
key Space; lit "g"; sleep 0.8
type "function  *.ts"; sleep 2
key Escape; sleep 0.3
key Escape; sleep 0.4

# Oil floating file browser (the bento listing with icons + mtime).
lit "-"; sleep 2.2

# Teardown. Esc back to normal, then force-quit everything (edits are throwaway).
key Escape
lit ":qa!"; key Enter

# Wait for nvim to exit -> asciinema flushes the cast -> the pane command ends.
for _ in $(seq 1 50); do
  tmux -L "$SOCK" has-session -t s 2>/dev/null || break
  sleep 0.2
done
sleep 0.5

echo "==> rendering assets/demo.gif with agg ($FONT @ ${FONT_SIZE}px, ${COLS}x${ROWS})"
agg --font-family "$FONT" --font-size "$FONT_SIZE" --last-frame-duration 2 \
  "$CAST" "$REPO/assets/demo.gif"

ls -lh "$REPO/assets/demo.gif"
