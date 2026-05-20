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


    startify.file_icons.provider = "devicons"

    startify.section.header.val = {
      "                @@@  C@@@   @@@G@@@    @@@@    t@0G@@@@@@    @@@t     i@@@,   @@@@@                ",
      "               @@@@@ @@@@@ @@@@@@@@   O@@@@@@  @@@@@@@@@@   @@@@@@   @@@@@@  @@@@@@                ",
      "               @@@@@ 8@@@; @@@@@@@@  @@@@@@@@  @@@@@@@@@@  @@@@@@@@  @@@@@@  @@@@@@                ",
      "               @@@@@@@@@@  @@@@@@@@  @@@@@@@@@ @@@@@@@@@@ @@@@@@@@@  @@@@@@@ @@@@@@                ",
      "               @@@@@@@@@@  @@@@@@@@  @@@@@@@@@ @@@@@@@@@@ @@@@@@@@@1 @@@@@@@ @@@@@@                ",
      "               @@@@@@@@@@  @@@@@@@@ 1@@@@@@@@@ @@@@@@@8@@ @@@@@@@@@C 0@@@@@@@@@@@@@                ",
      "               @@@@@@@@@@  @@@@   @ ,@@@@ @@@@ @@t@@@@ @@ @@@@ C@@@: @@@@@@@@@@@@@@                ",
      "               @@@@@@@@@@  @@@C     i@@@  @@@@  . @@@@    @@@@  @@@@ @@@@8@@@@1@@@@                ",
      "               @@@@@@@@@@  @@@@@@.  @@@@@ @@@@    @@@@    @@@@  @@@@ @@@@G@@@@ @@@O                ",
      "                @@@@@@@@@  @@@@@@@  @@@@@ @@@@    @@@@    @@@@  @@@: @@@@@@@@@ @@@0                ",
      "                @@@ @@@@@  @@@@@@@  @@@@@ @@@@    @@@@    @@@@  @@@: :@@@@@@@@f@@@L                ",
      "                @@@ t@@@@  @@@@@@L   @@@@ @@@@    @@@@.    @@@ :@@@t  @@@@ @@@f@@@C                ",
      "                @@@  @@@@  @@@@      @@@@ @@@@    @@@@     @@@@@@@@:  @@@@ @@  @@@                 ",
      "                @@@  @@@@  @@@@  @@   @@@@@@@L    @@@@     @@@@@@@@   @@@  @@  @@@                 ",
      "                @@@   @@@  @@@@@@@@   @@@@@@@      @@@     @@@@@@@    @@@   '  @@@                 ",
      "                @@@   @@O   @@@@@@@   @@@@@@       @@@     f@@@@@@    @@@      @@@                 ",
      "                 @@    @    @@@@@@.    @@@@        @@       C@@@@      @@      @@@                 ",
      "                              @@       .@@                   @@@                @                  ",
      "                                                                                                   ",
      "nvim Version " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
      "neotom version " .. vim.fn.system("git rev-parse --short HEAD"):gsub("%s+$", ""),
    }
    require("alpha").setup(
      startify.config
    )

    vim.keymap.set("n", "<leader>a", function() vim.cmd(':Alpha') end, { desc = "Open Start Screen" })
  end,
}
