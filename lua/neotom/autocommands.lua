local augroup = vim.api.nvim_create_augroup

local autocmd = vim.api.nvim_create_autocmd

local fidget = require('fidget')



-- blink highlight thing - advent of neovim
autocmd('TextYankPost', {
  group = augroup('neotom.HighlightYank', {}),
  pattern = '*',
  callback = function()
    vim.highlight.on_yank({
      higroup = 'IncSearch',
      timeout = 40,
    })
  end,
})


-- hit 'q' to ez close on specific buffers
autocmd("FileType", {
  pattern = { "qf", "help", "man", "lspinfo", "spectre_panel" },
  callback = function()
    vim.cmd [[
      nnoremap <silent> <buffer> q :close<CR>
      set nobuflisted
    ]]
  end,
})

autocmd("CursorHold", {
  group = augroup('neotom.DiagnosticFloat', {}),
  callback = function()
    vim.diagnostic.open_float(nil, {
      scope = "line",
      close_events = { "CursorMoved", "CursorMovedI", "BufHidden", "InsertCharPre", "WinLeave" },
      focusable = false, -- Set to true if you want to be able to focus the float
    })
  end,
})

-- lsp keybinds
autocmd('LspAttach', {
  group = augroup('neotom.UserLspConfig', {}),
  callback = function(e)
    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, { buffer = e.buf, desc = "Go to definition" })
    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, { buffer = e.buf, desc = "Hover documentation" })
    vim.keymap.set("n", "<leader>ca", function()
      -- honestly it would be cool to merge these but idk how.
      if (vim.bo.filetype == "typescript" or vim.bo.filetype == "typescriptreact") then
        vim.cmd(':LspTypescriptSourceAction')
      else
        vim.lsp.buf.code_action()
      end
    end, { buffer = e.buf, desc = "Code action" })
    vim.keymap.set("n", "gr", function() vim.lsp.buf.references() end, { buffer = e.buf, desc = "Go to references" })
    vim.keymap.set("n", "<leader>cr", function() vim.lsp.buf.rename() end, { buffer = e.buf, desc = "Rename" })
    vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end,
      { buffer = e.buf, desc = "Next diagnostic" })
    vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end,
      { buffer = e.buf, desc = "Prev diagnostic" })
  end
})

-- JS word nav
autocmd("FileType", {
  pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact", "htmlangular" },
  callback = function()
    vim.opt_local.iskeyword:append({ '$', '@' })
    -- treat a dash as a word
    vim.opt_local.iskeyword:remove({ '-' })
  end,
})

-- have to start treesitter by hand currently for php
autocmd('FileType', {
  pattern = { 'php' },
  callback = function()
    vim.treesitter.start()
  end,
})
-- only do cursorline in active buffer
-- not quite working yet..
-- autocmd({ "WinEnter", "BufEnter", "BufWinEnter" }, {
--   group = augroup("CursorLine", { clear = true }),
--   callback = function()
--     vim.opt_local.cursorline = true
--   end,
-- })
--
-- autocmd({ "WinLeave" }, {
--   group = augroup("CursorLine", { clear = true }),
--   callback = function()
--     vim.opt_local.cursorline = false
--   end,
-- })
