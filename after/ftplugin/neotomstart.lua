local win = vim.api.nvim_get_current_win()
local saved = {
  number = vim.wo[win].number,
  relativenumber = vim.wo[win].relativenumber,
  list = vim.wo[win].list,
  signcolumn = vim.wo[win].signcolumn,
  cursorline = vim.wo[win].cursorline,
  wrap = vim.wo[win].wrap,
  spell = vim.wo[win].spell,
  colorcolumn = vim.wo[win].colorcolumn,
  fillchars = vim.wo[win].fillchars,
}

vim.wo.number = false
vim.wo.relativenumber = false
vim.wo.list = false
vim.wo.signcolumn = "no"
vim.wo.cursorline = false
vim.wo.wrap = false
vim.wo.spell = false
vim.wo.colorcolumn = ""
vim.wo.fillchars = "eob: "

vim.api.nvim_create_autocmd("BufLeave", {
  buffer = vim.api.nvim_get_current_buf(),
  once = true,
  callback = function()
    for k, v in pairs(saved) do
      vim.wo[win][k] = v
    end
  end,
})
