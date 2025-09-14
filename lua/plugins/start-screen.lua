return {
  "goolord/alpha-nvim",



  dependencies = { 'nvim-tree/nvim-web-devicons',
    {
      "MaximilianLloyd/ascii.nvim",
      dependencies = {
        "MunifTanjim/nui.nvim",
      },
    }
  },

  config = function()
    local startify = require("alpha.themes.startify")

    require('neotom.lotto-text').setup();
    -- available: devicons, mini, default is mini
    -- if provider not loaded and enabled is true, it will try to use another provider
    startify.file_icons.provider = "devicons"

    local neotom = {
      [[------------------------------------------]],
      [[                  ___________             ]],
      [[  ____   ____  ___\__    ___/___   _____  ]],
      [[ /    \_/ __ \/  _ \|    | /  _ \ /     \ ]],
      [[|   |  \  ___(  <_> )    |(  <_> )  y y  \]],
      [[|___|  /\___  >____/|____| \____/|__|_|  /]],
      [[     \/     \/                         \/ ]],
      [[------------------------------------------]],
      "nvim Version " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
      "neotom version " .. vim.fn.system("git rev-parse --short HEAD"):gsub("%s+$", ""),
      [[------------------------------------------]],

    }

    startify.section.footer = {
      val = "hello world"
    };

    local lotto = require('neotom.lotto-text')

    startify.section.header.val = lotto.merge_tables(lotto.getText({
      { "write",  "develop", "make", "build",       "refactor", "test", "push" },
      { "broken", "robust",  "cool", "well tested", "dubious",  "fast" },
      { "tests",  "shit",    "apps", "pipelines" }
    }, {
      "standard",
      "3-d",
      "block",
      "colossal",
      "cosmic",
      "doh",
      "epic",
      "hollywood",
      "isometric1",
      "poison",
      "roman",
      "Star Wars"

    }), neotom);

    require("alpha").setup(
      startify.config
    )

    vim.keymap.set("n", "<leader>a", function() vim.cmd(':Alpha') end, { desc = "Open Start Screen" })
  end,
}
