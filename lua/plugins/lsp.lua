return {
  "neovim/nvim-lspconfig",
  dependencies = {
    -- conform
    {
      "stevearc/conform.nvim",
      config = function()
        require("conform").setup({
          formatters_by_ft = {
            javascript = { "prettierd" },
            typescript = { "prettierd" },
            html = { "prettierd" },
            css = { "prettierd" },
            scss = { "prettierd" },
            json = { "prettierd" },
            yaml = { "prettierd" },
            markdown = { "prettierd" },
            htmlangular = { "prettierd" },
            graphql = { "prettierd" },
          },
          format_on_save = {
            -- These options will be passed to conform.format()
            timeout_ms = 500,
            lsp_format = "fallback",
          },
        })
      end
    },

    -- management
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "mason-org/mason-lspconfig.nvim",
    -- autocompleteion
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "j-hui/fidget.nvim",
    -- snippets
    {
      "L3MON4D3/LuaSnip",
      version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
      build = "make install_jsregexp",
      dependencies = { "rafamadriz/friendly-snippets", "saadparwaiz1/cmp_luasnip" },


      config = function()
        local ls = require("luasnip")
        require("luasnip.loaders.from_vscode").lazy_load() -- load vscode style snippets from installed plugins
        require("luasnip.loaders.from_lua").load({ paths = { vim.fn.stdpath("config") .. "/lua/snippets" } })
        ls.config.set_config {
          history = true,
          updateevents = "TextChanged,TextChangedI",
          enable_autosnippets = true,
        }



        vim.keymap.set("n", "<leader>rs", "<cmd>source ~/.config/nvim/lua/plugins/luasnip.lua<CR>",
          { desc = "Reload Luasnip config" })
      end
    },
    -- github copilot
    {
      "github/copilot.vim",
      config = function()
        vim.g.copilot_no_tab_map = true
        -- vim.g.copilot_workspace_folders = { "~/code" }
        vim.keymap.set('i', '<C-Space>', 'copilot#Accept("\\<CR>")', {
          expr = true,
          replace_keycodes = false
        })
      end
    },
    -- this is basically vim lsp integration for lua
    {
      "folke/lazydev.nvim",
      ft = "lua", -- only load on lua files
      opts = {
        library = {
          -- Load luvit types when the `vim.uv` word is found
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      },
    },
    {
      "hrsh7th/nvim-cmp",
      event = { "InsertEnter", "CmdlineEnter" },
    },
  },
  config = function()
    local cmp = require('cmp')
    local ls = require("luasnip")
    local cmp_lsp = require("cmp_nvim_lsp")
    local capabilities = vim.tbl_deep_extend("force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      cmp_lsp.default_capabilities())

    require("fidget").setup({})
    require("mason").setup()

    require("mason-lspconfig").setup({
      ensure_installed = {
        "angularls",    -- ng
        "lua_ls",       -- lua
        "intelephense", -- php
        "ansiblels",    --ansible
        "bashls",       --shell
        "marksman",     --markdown
        "docker_compose_language_service",
        "docker_language_server",
        "emmet_ls",
        "eslint",
        "gitlab_ci_ls",
        "graphql",
        "jsonls",
        "ts_ls"
      },
      handlers = {
        function(server_name) -- default handler (optional)
          require("lspconfig")[server_name].setup {
            capabilities = capabilities
          }
        end,
        ["lua_ls"] = function()
          local lspconfig = require("lspconfig")
          lspconfig.lua_ls.setup {
            capabilities = capabilities,
            settings = {
              Lua = {
                format = {
                  enable = true,
                  -- Put format options here
                  -- NOTE: the value should be STRING!!
                  defaultConfig = {
                    indent_style = "space",
                    indent_size = "2",
                  }
                },
              }
            }
          }
        end,
      }
    })
    cmp.setup({
      snippet = {
        expand = function(args)
          ls.lsp_expand(args.body) -- For `luasnip` users.
        end,
      },
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      completion = {
        completeopt = 'menu,menuone,noinsert'
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
        ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
        ["<C-e>"] = cmp.mapping {
          i = cmp.mapping.abort(),
          c = cmp.mapping.close(),
        },
        -- Accept currently selected item. If none selected, `select` first item.
        -- Set `select` to `false` to only confirm explicitly selected items.
        ["<CR>"] = cmp.mapping.confirm { select = false },
        ["<C-j>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          elseif ls.expandable() then
            ls.expand()
          elseif ls.expand_or_jumpable() then
            ls.expand_or_jump()
          else
            fallback()
          end
        end, {
          "i",
          "s",
        }),
        ["<C-l>"] = cmp.mapping(function(fallback)
          if ls.choice_active() then
            ls.change_choice(1)
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-k>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif ls.jumpable(-1) then
            ls.jump(-1)
          else
            fallback()
          end
        end, {
          "i",
          "s",
        }),
      }),
      sources = cmp.config.sources({
        { name = "luasnip" },
        { name = "copilot" },
        { name = 'nvim_lsp' },
        { name = "async_path" },
        { name = "nvim_lua" },
        { name = "lazydev", group_index = 0, -- set group index to 0 to skip loading LuaLS completions
        }
      }, {
        { name = 'buffer' },
      })
    })

    vim.diagnostic.config({
      -- underline = false,
      signs = {
        severity = {
          min = vim.diagnostic.severity.INFO,
          min = vim.diagnostic.severity.WARN,
          max = vim.diagnostic.severity.ERROR,
        },
        text = {
          [vim.diagnostic.severity.ERROR] = '',
          [vim.diagnostic.severity.WARN] = '󰶬',
          [vim.diagnostic.severity.INFO] = '',
          [vim.diagnostic.severity.HINT] = '󰌵',
        },
        -- linehl = {
        --   [vim.diagnostic.severity.ERROR] = 'ErrorMsg',
        -- },
        numhl = {
          [vim.diagnostic.severity.WARN] = 'WarningMsg',
        },
      },
      float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
    })
  end
}
