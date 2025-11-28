return {
  "goolord/alpha-nvim",
  dependencies = { 'nvim-tree/nvim-web-devicons',
    {
      "MaximilianLloyd/ascii.nvim",
      dependencies = {
        "MunifTanjim/nui.nvim",
      },
    }
  },

  config = function()
    local startify = require("alpha.themes.startify")

    local function multi_line_text_to_table(result)
      local pos, fonttbl = 0, {}
      for st, sp in function() return string.find(result, "\n", pos, true) end do
        table.insert(fonttbl, string.sub(result, pos, st - 1))
        pos = sp + 1
      end
      table.insert(fonttbl, string.sub(result, pos))
      return fonttbl
    end

    local function mergeTables(destinationTable, sourceTable)
      for i = 1, #sourceTable do
        table.insert(destinationTable, sourceTable[i])
      end
      return destinationTable
    end

    startify.file_icons.provider = "devicons"

    startify.section.header.val = mergeTables(
      multi_line_text_to_table(
        vim.fn.system('jp2a  $XDG_CONFIG_HOME/nvim/neotom.png --invert --width=80')
      ), {
        "nvim Version " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
        "neotom version " .. vim.fn.system("git rev-parse --short HEAD"):gsub("%s+$", ""),
      })
    require("alpha").setup(
      startify.config
    )

    vim.keymap.set("n", "<leader>a", function() vim.cmd(':Alpha') end, { desc = "Open Start Screen" })
  end,
}
