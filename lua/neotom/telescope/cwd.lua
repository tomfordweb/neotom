-- https://dev.to/voyeg3r/nvim-telescope-toggle-cwd-1fhk
-- File: ~/.config/nvim/lua/core/utils/telescope.lua
-- Last Change: 2025-06-23
-- Author: Sergio Araujo

local M = {}

local actions = require('telescope.actions')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local ts_utils = require('telescope.utils')
local builtin = require('telescope.builtin')
local utils = require('telescope.utils')

--- Returns project_root
--- @param bufnr number|nil Buffer
--- @return string root dir
local function get_root(bufnr)
  bufnr = bufnr or 0
  local markers = {
    '.git',
    '.hg',
    '.svn',
    'pyproject.toml',
    'setup.py',
    'requirements.txt',
    'package.json',
    'tsconfig.json',
    'Makefile',
    'CMakeLists.txt',
    '.nvim-root',
  }

  return vim.fs.root(bufnr, markers) or vim.fn.getcwd()
end;


-- Função para path_display que remove prefixo Termux e mantém estilo tail+path
local function oldfiles_path_display(_, path)
  local termux_prefix = '/data/data/com.termux/files/home/'
  if path:sub(1, #termux_prefix) == termux_prefix then path = path:sub(#termux_prefix + 1) end

  local tail = utils.path_tail(path)
  local display = string.format('%s %s', tail, path)
  local hl_start = #tail + 1
  local hl_end = #display

  return display, { { { hl_start, hl_end }, 'Comment' } }
end

-- Garante um diretório válido mesmo que buffer esteja vazio
local function get_valid_buf_dir()
  local dir = ts_utils.buffer_dir()
  return (dir and dir ~= '') and dir or vim.loop.cwd()
end

-- Find files com toggle de cwd
M.find_files_with_toggle = function()
  local root = get_root()
  if not root or root == '' then
    vim.notify('Root dir não encontrado. Você está fora de um projeto?', vim.log.levels.WARN, {
      title = 'Find Files',
    })
    return
  end

  local buf_dir = get_valid_buf_dir()
  local current_cwd = root

  local function picker()
    builtin.find_files({
      cwd = current_cwd,
      attach_mappings = function(prompt_bufnr, map)
        map('i', '<a-d>', function()
          actions.close(prompt_bufnr)
          local new_cwd = (current_cwd == root) and buf_dir or root
          local title = 'Find Files'

          if new_cwd ~= current_cwd then
            current_cwd = new_cwd
            vim.notify('cwd switched to: ' .. current_cwd, vim.log.levels.INFO, { title = title })
          else
            vim.notify('cwd não foi alterado (já em ' .. current_cwd .. ')', vim.log.levels.WARN, { title = title })
          end

          picker()
        end)
        return true
      end,
    })
  end

  picker()
end

-- Grep customizado com toggle de cwd e preservação do prompt
M.custom_grep_with_toggle = function()
  local root = get_root()
  if not root or root == '' then
    vim.notify('Root dir não encontrado. Você está fora de um projeto?', vim.log.levels.WARN, {
      title = 'Custom Grep',
    })
    return
  end

  local buf_dir = get_valid_buf_dir()
  local current_cwd = root
  local current_prompt = ''

  local function picker()
    pickers
        .new({}, {
          prompt_title = 'Custom Grep',
          finder = finders.new_job(function(prompt)
            if prompt == '' then return nil end
            current_prompt = prompt
            return { 'rg', '--vimgrep', '--no-heading', prompt }
          end, nil, { cwd = current_cwd }),
          previewer = conf.grep_previewer({}),
          sorter = conf.generic_sorter({}),
          default_text = current_prompt,
          attach_mappings = function(prompt_bufnr, map)
            map('i', '<a-d>', function()
              actions.close(prompt_bufnr)
              local new_cwd = (current_cwd == root) and buf_dir or root
              local title = 'Custom Grep'

              if new_cwd ~= current_cwd then
                current_cwd = new_cwd
                vim.notify('cwd switched to: ' .. current_cwd, vim.log.levels.INFO, { title = title })
              else
                vim.notify('cwd não foi alterado (já em ' .. current_cwd .. ')', vim.log.levels.WARN, { title = title })
              end

              picker()
            end)
            return true
          end,
        })
        :find()
  end

  picker()
end

-- Oldfiles com path_display customizado para Termux
M.oldfiles_clean = function()
  builtin.oldfiles({
    path_display = oldfiles_path_display,
    layout_strategy = 'vertical', -- ou "horizontal", conforme preferir
    layout_config = {
      height = 0.5,               -- aqui você diminui a altura (0.3 = 30% da tela)
      width = 0.7,                -- opcional: ajustar largura também
      prompt_position = 'top',
      preview_cutoff = 1,         -- para esconder preview em telas pequenas
    },
  })
end

M.setup = function()
  vim.keymap.set("n", '<leader>c', function() M.find_files_with_toggle() end,
    { desc = 'Find Files (toggle raiz/buffer com Alt+D)' })
  vim.keymap.set("n", '<leader>C', function() M.custom_grep_with_toggle() end,
    { desc = 'Find Files (toggle raiz/buffer com Alt+D)' })
end

return M
