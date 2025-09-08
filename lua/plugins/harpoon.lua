return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    local fidget = require("fidget")
    local conf = require("telescope.config").values
    -- basic telescope configuration
    local function toggle_telescope(harpoon_files)
      local file_paths = {}
      for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
      end

      require("telescope.pickers").new({}, {
        prompt_title = "Harpoon",
        finder = require("telescope.finders").new_table({
          results = file_paths,
        }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
      }):find()
    end
    -- REQUIRED
    harpoon:setup()
    -- REQUIRED

    vim.keymap.set("n", "<leader>a", function()
      harpoon:list():add()
      local fileName = vim.fn.expand('%');
      fidget.notify(string.format("󰛢 %s", vim.fn.expand('%')), "info", { group = "harpoon" })
    end)

    vim.keymap.set("n", "<leader>hh", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
      { desc = "Harpoon toggle quick menu" })

    vim.keymap.set("n", "<header>h1", function() harpoon:list():select(1) end, { desc = "Harpoon select 1" })
    vim.keymap.set("n", "<leader>h2", function() harpoon:list():select(2) end, { desc = "Harpoon select 2" })
    vim.keymap.set("n", "<leader>h3", function() harpoon:list():select(3) end, { desc = "Harpoon select 3" })
    vim.keymap.set("n", "<leader>h4", function() harpoon:list():select(4) end, { desc = "Harpoon select 4" })

    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set("n", "<leader>hj", function() harpoon:list():prev() end, { desc = "Harpoon previous" })
    vim.keymap.set("n", "<leader>hk", function() harpoon:list():next() end, { desc = "Harpoon next" })
    vim.keymap.set("n", "<leader>he", function() toggle_telescope(harpoon:list()) end, { desc = "Open harpoon window" })
  end
}
