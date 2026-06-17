return {
  "rcarriga/nvim-notify",
  config = function()
    local notify = require('notify')
    notify.setup({
      background_colour = "#000000"
    })

    -- Auto-dismiss active notifications after 3 keystrokes.
    -- Any notify() call arms a counter; the next 3 keys clear all floats.
    local DISMISS_AFTER = 3
    local ns = vim.api.nvim_create_namespace("notify_autodismiss")
    local keys_left = 0

    vim.on_key(function()
      if keys_left <= 0 then return end
      keys_left = keys_left - 1
      if keys_left == 0 then
        vim.schedule(function()
          notify.dismiss({ pending = true, silent = true })
        end)
      end
    end, ns)

    local function arm()
      keys_left = DISMISS_AFTER
    end

    -- Wrap the module's __call so every caller arms the counter:
    -- vim.notify, require("notify")(...), and notify.async/etc all route here.
    local mt = getmetatable(notify)
    if mt and type(mt.__call) == "function" then
      local orig = mt.__call
      mt.__call = function(...)
        arm()
        return orig(...)
      end
    end

    -- vim.notify points at the same callable table.
    vim.notify = notify
  end
}
