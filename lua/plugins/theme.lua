return {
  "rebelot/kanagawa.nvim",
  lazy = false,    -- Load immediately
  priority = 1000, -- Load before all other plugins
  opts = {
    -- Optional configuration
    theme = "wave", -- "wave" (default), "dragon", or "lotus"
    background = {
      dark = "wave",
      light = "lotus",
    },
  },
  config = function(_, opts)
    require("kanagawa").setup(opts)
    vim.cmd("colorscheme kanagawa")
  end,
}
