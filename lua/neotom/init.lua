require("neotom.remap");
require("neotom.options")
require("neotom.lazy");
require("neotom.autocommands");
require("neotom.lotto-text");


function SetColors(color)
  -- color = color or "catppuccin-macchiato" -- catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha
  color = color or "catppuccin-mocha" -- catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha

  vim.cmd.colorscheme(color)
  -- https://neovim.io/doc/user/syntax.html#_13.-highlight-command
  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })

  -- Set the color for relative line numbers
  vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = '#f9e2af', bold = true })
  vim.api.nvim_set_hl(0, 'LineNr', { fg = '#f5c2e7', bold = true })
  vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = '#fab387', bold = true })
end

SetColors()
