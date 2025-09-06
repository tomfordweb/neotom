# neotom

Features:

1) A full development environment for: Javascript, Typescript, Bash, PHP, Python, Lua
2) Full LSP support through neovim, mason, and mason-lspconfig. Including autocompletion, linting, formatting, and snippets.
3) Luasnip integration
4) Lazygit integration.
3) copilot integration

# Other dependencies

Rust and Cargo must be installed and on path.

### Github copilot 

This must be done in order to get copilot working. You should only need to run this once.

```
:Copilot setup
```

# Icons

Make sure your machine has a nerd font installed. See alacritty.yml

Icons can be searched here: copy the icon and paste it where the sign is needed in the config.
https://www.nerdfonts.com/cheat-sheet

# Commands

1: `:Lazy` - Opens up lazy.nvim which is the package manager I like.
1: `:Mason` - LSP installer.

* [Lazy](https://github.com/wbthomason/packer.nvim)
* [Telescope](https://github.com/nvim-telescope/telescope.nvim)
* [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter)


# Credits

Some of code taken from configs and lessons from:

* [ThePrimeagen](https://www.youtube.com/@ThePrimeagen)
* [TJ DeVries](https://www.youtube.com/@tjdevries)

