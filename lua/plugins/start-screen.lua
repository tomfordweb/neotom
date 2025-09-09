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
    local ascii = require("ascii")
    function mergeTables(destinationTable, sourceTable)
      for i = 1, #sourceTable do
        table.insert(destinationTable, sourceTable[i])
      end
      return destinationTable
    end

    -- available: devicons, mini, default is mini
    -- if provider not loaded and enabled is true, it will try to use another provider
    startify.file_icons.provider = "devicons"
    -- startify.section.header.val = {
    --   [[                _,.-----.,_              ]],
    --   [[             ,-~           ~-.           ]],
    --   [[            ,^___           ___^.        ]],
    --   [[          /~"   ~"   .   "~   "~\        ]],
    --   [[         Y  ,--._    I    _.--.  Y       ]],
    --   [[          | Y     ~-. | ,-~     Y |      ]],
    --   [[          | |        }:{        | |      ]],
    --   [[          j l       / | \       ! l      ]],
    --   [[       .-~  (__,.--" .^. "--.,__)  ~-.   ]],
    --   [[       (           / / | \ \           ) ]],
    --   [[       \.____,   ~  \/"\/  ~   .____,/   ]],
    --   [[        ^.____                 ____.^    ]],
    --   [[           | |T ~\  !   !  /~ T| |       ]],
    --   [[           | |l   _ _ _ _ _   !| |       ]],
    --   [[           | l \/V V V V V V\/ j |       ]],
    --   [[           l  \ \|_|_|_|_|_|/ /  !       ]],
    --   [[            \  \[T T T T T TI/  /        ]],
    --   [[             \  `^-^-^-^-^-^'  /         ]],
    --   [[              \               /          ]],
    --   [[               \.           ,/           ]],
    --   [[                 "^-.___,-^"             ]],
    -- }
    -- startify.section.header.val = {
    --   [[       *                                                   *        ]],
    --   [[      *                                                     *       ]],
    --   [[    **                                                       **     ]],
    --   [[*   **                                                       **   * ]],
    --   [[**   **          *                               *          **   ** ]],
    --   [[***    *         **                             **         *    *** ]],
    --   [[ ****            *********************************            ****  ]],
    --   [[   *******      ***           *******           ***      *******    ]],
    --   [[      ************             *****             ************       ]],
    --   [[         **********    **** * **   ** *******   **********          ]],
    --   [[               ********** ** **     ** ****************             ]],
    --   [[         *************** ** **  ***  **  *****************          ]],
    --   [[          ******   *********************  ******   ******           ]],
    --   [[                    **********************  ***                     ]],
    --   [[                    ************************ **                     ]],
    --   [[                     **** ** ** **** ** ** **                       ]],
    --   [[                      ***  *  *  **  *  *  ***                      ]],
    --   [[                       **                  **                       ]],
    --   [[                         *                *                         ]],
    --   [[                                                                    ]],
    --   [[                                                                    ]],
    --   [[                                                                    ]],
    neotom = {
      [[                                ___________                         ]],
      [[                ____   ____  ___\__    ___/___   _____              ]],
      [[               /    \_/ __ \/  _ \|    | /  _ \ /     \             ]],
      [[              |   |  \  ___(  <_> )    |(  <_> )  y y  \            ]],
      [[              |___|  /\___  >____/|____| \____/|__|_|  /            ]],
      [[                   \/     \/                         \/             ]],
      [[                                                                    ]],
      [[                                                                    ]],
      [[                                                                    ]],
    }
    startify.section.header.val = mergeTables(ascii.get_random_global(), neotom)
    require("alpha").setup(
      startify.config
    )
  end,
}
