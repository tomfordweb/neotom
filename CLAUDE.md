# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A personal Neovim configuration built around `lazy.nvim` for plugin management. The config is split into two modules: `neotom` (primary config) and `mhvdc` (work-specific PHP file extensions).

## Plugin Management

- **Install/update plugins:** `:Lazy` inside Neovim
- **LSP servers and formatters come from nix** (`nixos/home/neovim.nix` in the dotfiles repo) — they ship on nvim's PATH via `programs.neovim.extraPackages`. `:Mason` remains as an escape hatch for one-off servers on non-nix machines.
- `lazy-lock.json` is gitignored on purpose — plugin versions float per machine, so there is nothing to commit after `:Lazy sync`.

## Docker Environment

A `Dockerfile` is provided for a reproducible test environment:

```bash
docker build --build-arg TAG=nightly -t neotom .
docker run -it neotom nvim
```

The `dependencies.sh` script installs `prettierd` for formatting.

## Architecture

**Entry point:** `init.lua` loads `neotom`, `mhvdc`, and `lotto-text` modules.

**`lua/neotom/`** — Core configuration:
- `lazy.lua` — Bootstraps lazy.nvim; sets `<Space>` as leader
- `options.lua` — Vim options (2-space indent, relative numbers, spell check, no mouse)
- `remap.lua` — All global keymaps
- `autocommands.lua` — LSP attach keymaps, diagnostic display, filetype overrides
- `telescope/` — Custom telescope pickers (multigrep with file glob filtering, cwd picker)

**`lua/plugins/`** — One file per plugin group, each returning a lazy.nvim spec table:
- `lsp.lua` — Mason, mason-lspconfig, conform.nvim (formatters), nvim-cmp (completion), LuaSnip
- `telescope.lua` — Telescope with fzf-native and lazygit extensions
- `treesitter.lua` — Parsers + treesitter-context
- `theme.lua` — cyberdream colorscheme, recolored to the desktop rice palette
  (`rice/palette.json` in the dotfiles repo is the source of truth for those hexes)
- Other plugins are standalone and self-contained in their file

**`lua/mhvdc/`** — Work module; registers `.class` and `.snip` as PHP filetypes.

**`after/ftplugin/`** — Filetype overrides: PHP uses 4-space indent (differs from global 2-space).

**`lua/snippets/`** — LuaSnip snippet definitions.

## LSP & Formatters

Language servers are configured directly via lspconfig in `lsp.lua` and expected on PATH (nix provides them; on non-nix machines install via `:Mason` or the system package manager): `ts_ls`, `angularls`, `intelephense`, `pyright`, `pylsp`, `lua_ls`, `bashls`, `jsonls`, `docker_language_server`, `docker_compose_language_service`, `graphql`, `eslint`, `oxlint`, `emmet_ls`, `ansiblels`, `marksman`, `hyprls`, `gitlab_ci_ls`, `nixd`.

Formatters via conform.nvim: `prettierd` (JS/TS/HTML/CSS/JSON/YAML/Markdown/GraphQL), `shfmt` (shell), `black` (Python).

## Key Keymaps

| Key | Action |
|-----|--------|
| `<leader>f` | Find files (telescope) |
| `<leader>g` | Live multi-grep — syntax: `<pattern>  <file_glob>` |
| `<leader>b` | Buffer picker |
| `<leader>e` or `-` | Oil.nvim file browser (floating) |
| `<leader>tg` | LazyGit |
| `<leader>ca` | Code actions |
| `<leader>cr` | Rename symbol |
| `<leader>rr` | Reload config |
| `jk` | Exit insert mode |
| `<S-l>` / `<S-h>` | Next/previous buffer |
| `gd` | Go to definition |
| `K` | Hover docs |
| `gr` | Go to references |

Arrow keys are disabled intentionally.

## Adding a New Plugin

Create a new file in `lua/plugins/` returning a lazy.nvim spec table:

```lua
return {
  "author/plugin-name",
  config = function()
    require("plugin-name").setup({})
  end,
}
```

Lazy.nvim auto-discovers all files in `lua/plugins/`.


<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:7510c1e2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->
