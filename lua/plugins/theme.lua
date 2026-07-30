-- cyberdream, recolored to the desktop rice palette.
--
-- The dotfiles repo generates waybar/wofi/eww/ghostty/tmux colors from a single
-- source of truth (rice/palette.json — "cyberdream: neon-catppuccin"). Upstream
-- cyberdream ships its own neon palette, which is close in spirit but a visible
-- mismatch next to those, so the colors below are the palette's values mapped
-- onto cyberdream's fourteen keys. Editing them here without editing
-- rice/palette.json puts the editor back out of step with the desktop.
return {
  "scottmckendry/cyberdream.nvim",
  lazy = false,    -- Load immediately
  priority = 1000, -- Load before all other plugins
  opts = {
    variant = "default", -- dark; "auto" would follow vim.o.background
    transparent = false, -- ghostty already owns the window background
    italic_comments = true,
    terminal_colors = true,
    colors = {
      bg = "#11111b",           -- base
      bg_alt = "#181825",       -- mantle
      bg_highlight = "#313244", -- surface0
      fg = "#cdd6f4",           -- text
      grey = "#6c7086",         -- overlay0
      blue = "#89b4fa",
      green = "#a6e3a1",
      cyan = "#22d3ee",
      red = "#f38ba8",
      yellow = "#f9e2af",
      magenta = "#ff6ac1",      -- neon-pink
      pink = "#f5c2e7",
      orange = "#fab387",       -- peach
      purple = "#cba6f7",       -- mauve
    },
  },
  config = function(_, opts)
    require("cyberdream").setup(opts)
    vim.cmd("colorscheme cyberdream")
  end,
}
