return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  branch = "main",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  init = function()
    vim.g.no_plugin_maps = true
  end,
  config = function()
    require("nvim-treesitter-textobjects").setup({
      select = {
        lookahead = true,
        selection_modes = {
          ["@function.outer"] = "V",
          ["@class.outer"] = "V",
          ["@parameter.outer"] = "v",
        },
      },
      move = { set_jumps = true },
    })

    local select = require("nvim-treesitter-textobjects.select").select_textobject
    local function sel(key, query)
      vim.keymap.set({ "x", "o" }, key, function() select(query, "textobjects") end,
        { desc = "TS select " .. query })
    end
    sel("af", "@function.outer")
    sel("if", "@function.inner")
    sel("ac", "@class.outer")
    sel("ic", "@class.inner")
    sel("aa", "@parameter.outer")
    sel("ia", "@parameter.inner")

    local move = require("nvim-treesitter-textobjects.move")
    vim.keymap.set({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end,
      { desc = "Next function" })
    vim.keymap.set({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end,
      { desc = "Prev function" })
  end,
}
