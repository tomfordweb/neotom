# VHS tape for the neotom README demo GIF.
#
# Drives the REAL local Neovim config (all plugins + Mason LSP live) against a
# throwaway copy of recording/demo/ in $DEMO_DIR. recording/record.sh sets up
# that dir, an isolated XDG_STATE_HOME (clean shada -> no personal MRU), pre-seeds
# the demo MRU, and runs this tape from the repo root so Output lands in assets/.
#
#   recording/record.sh        # don't run `vhs demo.tape` directly — it needs the env
#
# Render dep: vhs + ttyd + ffmpeg on PATH, a Nerd Font installed (FontFamily below).

Output "assets/demo.gif"

Set Shell bash
Set FontFamily "JetBrainsMono Nerd Font"
Set FontSize 16
Set Width 1100
Set Height 680
Set Padding 18
Set Framerate 20
Set TypingSpeed 60ms

# Enter the seeded demo dir and launch the real config. VHS spawns its own shell,
# so cd explicitly; $DEMO_DIR is exported by record.sh into the vhs environment.
Hide
Type 'cd "$DEMO_DIR" && clear' Enter
Type "nvim" Enter
Sleep 4s
Show

# Start screen: matrix-rain + NEOTOM reveal, then the MRU overlay. Let the hero
# breathe — this is the headline shot.
Sleep 4s

# HERO: open the top recent file straight from the start-screen MRU list (1-9).
Type "1"
Sleep 2500ms

# Telescope find-files: live-type FILTER narrows the result list, Enter opens it
# (a second buffer -> bufferline).
Space
Type "f"
Sleep 800ms
Type "util"
Sleep 1600ms
Enter
Sleep 1500ms

# Back to the TS entry point for the LSP tour.
Type ":e app.ts"
Enter
Sleep 1800ms

# nvim-cmp completion menu (member completion on the `user` object).
Type "Gouser."
Sleep 1700ms
Escape
Type "u"
Sleep 800ms

# LSP: hover docs on a symbol (K opens the float; cursor move / Esc dismisses).
Type "/greet"
Enter
Sleep 500ms
Type "K"
Sleep 2s
Escape

# LSP: references — vim.lsp.buf.references() populates the quickfix list and opens
# it. Close the quickfix window with :cclose (Esc won't close it).
Type "gr"
Sleep 2200ms
Type ":cclose"
Enter
Sleep 600ms

# LSP: jump to the live diagnostic; ]d opens a floating diagnostic window.
Type "]d"
Sleep 2200ms

# LSP: code action menu (TS source actions). Pick "Add all missing imports" (3rd)
# so the import line visibly gains `formatName` and the diagnostic clears.
# Selecting auto-closes the picker (no Esc desync).
Space
Type "ca"
Sleep 2200ms
Down
Sleep 350ms
Down
Sleep 500ms
Enter
Sleep 1800ms

# LSP: rename symbol (<leader>cr). The input is prefilled with the symbol, so
# Ctrl+U clears it before typing the new name.
Type "/user"
Enter
Sleep 400ms
Space
Type "cr"
Sleep 900ms
Ctrl+U
Type "account"
Enter
Sleep 1700ms

# Multigrep with the glob-filter syntax: "<pattern>  <glob>". Close with two Esc.
Space
Type "g"
Sleep 800ms
Type "function  *.ts"
Sleep 2s
Escape
Sleep 300ms
Escape
Sleep 400ms

# Oil floating file browser (the bento listing with icons + mtime).
Type "-"
Sleep 2200ms

# Teardown. Esc back to normal, then force-quit everything (edits are throwaway).
Escape
Type ":qa!"
Enter
Sleep 1s
