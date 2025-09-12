local keymap = vim.keymap.set

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

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- maintain cursor position when yanking selections
keymap('v', 'y', 'myy`y', opts)

keymap("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Open parent directory" })
--keymap("n", "<leader>E", require('oil').toggle_float() { desc = "Open parent directory" })

keymap("n", "<Leader>rr", ":source $MYVIMRC<CR>", { desc = "Reload Neovim config" })

keymap("n", "<leader>tg", "<cmd>:LazyGit<CR>", { noremap = true, silent = true, desc = "Open LazyGit" })


-- get the keymap to reload my nvim config
