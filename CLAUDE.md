# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A personal Neovim configuration built around `lazy.nvim` for plugin management. The config is split into two modules: `neotom` (primary config) and `mhvdc` (work-specific PHP file extensions).

## Plugin Management

- **Install/update plugins:** `:Lazy` inside Neovim
- **Install/update LSP servers and formatters:** `:Mason` inside Neovim
- The `lazy-lock.json` lockfile pins plugin commits — commit changes to this file when intentionally upgrading plugins.

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
- `theme.lua` — Kanagawa colorscheme ("wave" dark, "lotus" light)
- Other plugins are standalone and self-contained in their file

**`lua/mhvdc/`** — Work module; registers `.class` and `.snip` as PHP filetypes.

**`after/ftplugin/`** — Filetype overrides: PHP uses 4-space indent (differs from global 2-space).

**`lua/snippets/`** — LuaSnip snippet definitions.

## LSP & Formatters

Language servers managed via Mason: `ts_ls`, `angularls`, `intelephense`, `pyright`, `lua_ls`, `bashls`, `jsonls`, `dockerls`, `graphql`, `eslint`, `oxlint`, `emmet_ls`, `ansiblels`, `marksman`, `hyprls`, `gitlab_ci_ls`.

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
