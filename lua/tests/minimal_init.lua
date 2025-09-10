vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/plenary.nvim')
require('plenary.busted')
