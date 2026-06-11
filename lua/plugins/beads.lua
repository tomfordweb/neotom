return {
  dir = vim.fn.expand("$HOME") .. "/code/tomfordweb/beads.nvim",
  name = "beads.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("beads").setup({ keymaps = true })
    require("telescope").load_extension("beads")
  end,
}
