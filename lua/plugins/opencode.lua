-- opencode.nvim — talk to a running opencode server from inside nvim.
--
-- The plugin needs an `opencode --port <n>` server. It finds an existing one
-- with pgrep + lsof; when lsof is missing (the case on these nix hosts) it
-- falls back to starting its own via `server.start`, which is the terminal
-- toggled by <leader>ot below, so both paths share one opencode instance.

local terminal = { buf = nil, win = nil }

local function open_terminal()
  vim.cmd("botright vsplit")
  terminal.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(terminal.win, math.max(80, math.floor(vim.o.columns * 0.4)))

  if terminal.buf and vim.api.nvim_buf_is_valid(terminal.buf) then
    vim.api.nvim_win_set_buf(terminal.win, terminal.buf)
  else
    terminal.buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_win_set_buf(terminal.win, terminal.buf)
    vim.fn.jobstart("opencode --port", { term = true })
  end

  vim.wo[terminal.win].number = false
  vim.wo[terminal.win].relativenumber = false
  vim.wo[terminal.win].spell = false
  vim.cmd("startinsert")
end

local function toggle_terminal()
  if terminal.win and vim.api.nvim_win_is_valid(terminal.win) then
    vim.api.nvim_win_hide(terminal.win)
    terminal.win = nil
    return
  end
  open_terminal()
end

local function opencode()
  return require("opencode")
end

-- `@this` is cursor-position-only in normal mode; a range only comes from a
-- visual selection or an operator. So select the line first, then ask.
local function ask_line(default)
  return function()
    vim.cmd("normal! V")
    opencode().ask(default)
  end
end

local function command(name)
  return function()
    opencode().command(name)
  end
end

return {
  "nickjvandyke/opencode.nvim",
  version = "*",
  config = function()
    -- Required so buffers pick up edits opencode makes on disk.
    vim.o.autoread = true

    ---@type opencode.Opts
    vim.g.opencode_opts = {
      server = {
        start = function()
          local current = vim.api.nvim_get_current_win()
          open_terminal()
          vim.api.nvim_set_current_win(current)
        end,
      },
    }

    vim.api.nvim_create_autocmd("User", {
      pattern = "OpencodeEvent:session.status",
      callback = function(args)
        if args.data.event.properties.status.type == "error" then
          vim.notify("opencode error", vim.log.levels.ERROR)
        end
      end,
    })
  end,
  keys = {
    { "<leader>oa", function() opencode().ask("@this: ") end, mode = { "n", "x" }, desc = "Ask about this" },
    { "<leader>oA", function() opencode().ask() end, mode = { "n", "x" }, desc = "Ask (no context)" },
    { "<leader>ol", ask_line("@this: "), desc = "Ask about this line" },
    { "<leader>oL", function() opencode().prompt("@this ") end, mode = "x", desc = "Send selection, no prompt" },
    { "<leader>os", function() opencode().select() end, mode = { "n", "x" }, desc = "Select prompt/command" },
    { "<leader>ot", toggle_terminal, desc = "Toggle opencode terminal" },
    { "<leader>on", command("session.new"), desc = "New session" },
    { "<leader>ou", command("session.undo"), desc = "Undo last change" },
    { "<leader>oR", command("session.redo"), desc = "Redo last change" },
    { "<leader>oc", command("agent.cycle"), desc = "Cycle agent" },
    { "<leader>ox", command("prompt.clear"), desc = "Clear prompt" },
    { "<leader>ok", command("session.half.page.up"), desc = "Scroll session up" },
    { "<leader>oj", command("session.half.page.down"), desc = "Scroll session down" },
    -- Operator: gow appends a word, goap a paragraph, goo the current line.
    { "go", function() return opencode().operator("@this ") end, mode = { "n", "x" }, expr = true, desc = "Append range to opencode" },
    { "goo", function() return opencode().operator("@this ") .. "_" end, expr = true, desc = "Append line to opencode" },
  },
}
