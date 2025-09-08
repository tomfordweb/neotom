return {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' }
  },
  config = function()
    local actions = require("telescope.actions")
    local builtin = require('telescope.builtin')

    require('telescope').setup {
      defaults = {
        prompt_prefix = "   ",
        sorting_strategy = "ascending",
        path_display = { "smart" },
        file_ignore_patterns = { ".git/", "node_modules", "vendor" },
        pickers = {
          find_files = {
            theme = "ivy",
            hidden = true
          },
        },
        fzf = {
          fuzzy = true,                   -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true,    -- override the file sorter
          case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
          -- the default case_mode is "smart_case"
        },
        mappings = {
          n = { ["q"] = require("telescope.actions").close },
          i = {
            ["<Down>"] = actions.move_selection_next,
            ["<Up>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-d>"] = actions.delete_buffer + actions.move_to_top
          },
        },
      }
    }

    require('telescope').load_extension('fzf');

    vim.keymap.set('n', '<leader>ff', function() builtin.find_files(require('telescope.themes').get_ivy({})) end,
      { desc = ':Telescope find_files' })
    require("neotom.telescope.multigrep").setup()
    vim.keymap.set('n', '<leader>fn', function()
      builtin.find_files {
        cwd = vim.fn.stdpath('config')
      }
    end, { desc = "Telescope: nvim config files" })
    vim.keymap.set('n', '<leader>fp', function()
      builtin.find_files {
        cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
      }
    end, { desc = "Telescope: plugin files" })
    vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = ':Telescope buffers' })
    vim.keymap.set('n', '<leader>fs', builtin.search_history, { desc = ':Telescope search_history' })
    vim.keymap.set('n', '<leader>fS', builtin.spell_suggest, { desc = ':Telescope spelling_suggest' })
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = ':Telescope help_tags' })
  end
}
