return {
  "neovim/nvim-lspconfig",
  dependencies = {
    -- conform
    {
      "stevearc/conform.nvim",
      config = function()
        require("conform").setup({
          formatters_by_ft = {
            sh = { "shfmt" },
            bash = { "shfmt" },
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
            python = { "black" },
            php = { "php_cs_fixer" },
            phtml = { "php_cs_fixer" },
          },
          formatters = {
            php_cs_fixer = {
              args = function(self, ctx)
                local root = vim.fs.root(ctx.buf, { "composer.json", ".php-cs-fixer.dist.php", ".php-cs-fixer.php" })
                    or vim.fs.root(vim.fn.getcwd(), { "composer.json", ".php-cs-fixer.dist.php", ".php-cs-fixer.php" })
                    or vim.fn.getcwd()
                local config = root .. "/.php-cs-fixer.dist.php"
                if vim.fn.filereadable(config) == 0 then
                  config = root .. "/.php-cs-fixer.php"
                end
                if vim.fn.filereadable(config) == 1 then
                  return { "fix", "--no-interaction", "--quiet", "--config", config, "$FILENAME" }
                end
                -- -- no project config — pass rules directly (Docker wrapper needs no extra mounts)
                return {
                  "fix", "--no-interaction", "--quiet",
                  "--rules", table.concat({
                  '{"@PSR12":true',
                  '"array_syntax":{"syntax":"short"}',
                  '"array_indentation":true',
                  '"trailing_comma_in_multiline":{"elements":["arrays","arguments"]}',
                  '"no_whitespace_before_comma_in_array":true',
                  '"trim_array_spaces":true',
                  '"single_quote":true',
                  '"binary_operator_spaces":{"default":"single_space"}}',
                }, ","),
                  "$FILENAME",
                }
              end,
            },
          },
          notify_on_error = true,
          format_on_save = {
            timeout_ms = 3000,
            lsp_format = "fallback",
          },
        })
      end
    },

    -- management
    "williamboman/mason.nvim",
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
    -- {
    --   "github/copilot.vim",
    --   config = function()
    --     vim.g.copilot_no_tab_map = true
    --     -- vim.g.copilot_workspace_folders = { "~/code" }
    --     vim.keymap.set('i', '<C-Space>', 'copilot#Accept("\\<CR>")', {
    --       expr = true,
    --       replace_keycodes = false
    --     })
    --   end
    -- },
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

    -- disable cmp for markdown
    require("cmp").setup.filetype('markdown', {
      sources = {},
    })
    require("fidget").setup({
      notification = {
        override_vim_notify = true,
        filter_notices = function(msg, level)
          if vim.fn.mode() == "i" then return false end
          return true
        end,
      }
    })
    require("mason").setup()

    require("mason-lspconfig").setup({
      ensure_installed = {
        "angularls",
        "pyright",
        "lua_ls",
        "intelephense",
        "python-lsp-server",
        "ansiblels",
        "bashls",
        "marksman",
        "docker_compose_language_service",
        "hyprls",
        "docker_language_server",
        "emmet_ls",
        "eslint",
        "oxlint",
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
        ["python-lsp-server"] = function()
          require("lspconfig").pylsp.setup({
            -- Customize pylsp options here if needed
            settings = {
              pylsp = {
                plugins = {
                  -- Enable/disable specific pylsp plugins
                  pyflakes = { enabled = true },
                  autopep8 = { enabled = true },
                  -- ... other plugins
                },
              },
            },
          })
        end,
        ["pyright"] = function()
          require("lspconfig").pyright.setup()
        end,
        ["bashls"] = function()
          require("lspconfig").bashls.setup()
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
        ["intelephense"] = function()
          require("lspconfig").intelephense.setup({
            capabilities = capabilities,
            settings = {
              intelephense = {
                environment = {
                  -- set to match your Docker PHP version (7.4, 8.0, 8.1, etc.)
                  phpVersion = "8.0",
                },
                files = {
                  -- default is 1MB — Symfony vendor files routinely exceed this, causing silent indexing failures
                  maxSize = 5000000,
                  associations = { "*.php", "*.phtml" },
                  exclude = {
                    "**/.git/**",
                    "**/.svn/**",
                    "**/node_modules/**",
                    "**/.DS_Store/**",
                    -- skip test dirs inside vendor but keep vendor itself indexed
                    "**/vendor/**/{Tests,tests,test,spec}/**",
                  },
                },
                completion = {
                  insertUseDeclaration = true,
                  fullyQualifyGlobalConstantsAndFunctions = false,
                  triggerParameterHints = true,
                  maxItems = 100,
                  propertyCase = "camel",
                },
                stubs = {
                  "apache", "bcmath", "bz2", "calendar", "Core", "ctype",
                  "curl", "date", "dom", "exif", "fileinfo", "filter", "fpm",
                  "ftp", "gd", "hash", "iconv", "intl", "json", "ldap",
                  "libxml", "mbstring", "meta", "mysqli", "openssl", "pcntl",
                  "pcre", "PDO", "pdo_mysql", "pdo_pgsql", "pdo_sqlite", "pgsql",
                  "Phar", "posix", "readline", "Reflection", "session",
                  "SimpleXML", "soap", "sockets", "sodium", "SPL", "sqlite3",
                  "standard", "superglobals", "tokenizer", "xml", "xmlreader",
                  "xmlwriter", "xsl", "zip", "zlib",
                },
                diagnostics = {
                  enable = true,
                },
                format = {
                  enable = true,
                  braces = "psr2",
                },
              },
            },
          })
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
        -- noselect - do not automatically select the first element
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
        -- { name = "copilot" },
        { name = 'nvim_lsp' },
        { name = "path" },
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
