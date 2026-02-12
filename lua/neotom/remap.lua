local keymap = vim.keymap.set
local builtin = require('telescope.builtin')

-- global keymap options
local opts = { silent = true }

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- when text is wrapped, move by terimnal rows, not lines...unless a count is provided
keymap('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
keymap('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- Resize with arrows
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- Clear highlights
keymap("n", "<leader>/", "<cmd>nohlsearch<CR>", opts)

-- Close buffers
keymap("n", "<S-q>", "<cmd>Bdelete!<CR>", opts)

-- Better paste
keymap("v", "p", '"_dP', opts)

-- Insert --
-- Press jk fast to enter
keymap("i", "jk", "<ESC>", opts)
--  ;;  to go to end of the line.
keymap("i", ";;", "<C-o>$", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- maintain cursor position when yanking selections
keymap('v', 'y', 'myy`y', opts)

keymap("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Open parent directory" })
keymap("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
--keymap("n", "<leader>E", require('oil').toggle_float() { desc = "Open parent directory" })

keymap("n", "<Leader>rr", ":source $MYVIMRC<CR>", { desc = "Reload Neovim config" })

keymap("n", "<leader>tg", "<cmd>:LazyGit<CR>", { noremap = true, silent = true, desc = "Open LazyGit" })

-- disable touchpad mouse;
keymap("", "<up>", "<nop>", opts)
keymap("", "<down>", "<nop>", opts)
keymap("i", "<up>", "<nop>", opts)
keymap("i", "<down>", "<nop>", opts)


keymap("n", "<C-w>a", ":%bd|e#<CR>", { noremap = true, desc = "Close other buffers" })
keymap("n", "<C-w>w", function() vim.cmd('bufdo w') end, { silent = true, noremap = true, desc = "Write all buffers" })
keymap("n", "<C-w>c", ":bd!<CR>", { silent = true, noremap = true, desc = "Close buffer" })

-- plenary
keymap('n', '<leader>p',
  ":PlenaryBustedDirectory ./ {minimal_init = './tests/minimal_init.lua'}<CR>")

vim.keymap.set('n', '<leader>f', function() builtin.find_files(require('telescope.themes').get_ivy({})) end,
  { desc = ':Telescope find_files' })

-- local prManager = require('telescope-gitlab');
--
-- prManager.setup({
--   GITLAB_PAT = os.getenv('GITLAB_ACCESS_TOKEN'),
--   GITLAB_URL = "https://gitlab.datacomp-intranet.com",
-- })

--keymap ("n", "<leader>fm",
--   function() prManager.merge_requests(require("telescope.themes").get_ivy {}) end,
--   { desc = "Gitlab Merge Requests" })

keymap("n", "<leader>rb", function() vim.cmd('source %') end, { desc = "Source File" })

keymap('n', '<leader>N', function()
  builtin.find_files {
    cwd = vim.fn.stdpath('config')
  }
end, { desc = "Telescope: nvim config files" })

keymap('n', '<leader>P', function()
  builtin.find_files {
    cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
  }
end, { desc = "Telescope: plugin files" })

keymap('n', '<leader>b', builtin.buffers, { desc = ':Telescope buffers' })
keymap('n', '<leader>S', builtin.search_history, { desc = ':Telescope search_history' })
keymap('n', '<leader>P', builtin.spell_suggest, { desc = ':Telescope spelling_suggest' })
keymap('n', '<leader>H', builtin.help_tags, { desc = ':Telescope help_tags' })
