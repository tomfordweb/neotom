local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local entry_display = require("telescope.pickers.entry_display")

local M = {}

local feed_cache = {}

local function find_git_root()
  local out = vim.fn.systemlist("git -C " .. vim.fn.shellescape(vim.uv.cwd()) .. " rev-parse --show-toplevel")
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return out[1]
end

-- async glab job emitting JSON; calls cb(decoded|nil)
local function glab_json(args, git_root, cb)
  local buf = {}
  local ok = pcall(vim.fn.jobstart, args, {
    cwd = git_root,
    stdout_buffered = true,
    on_stdout = function(_, data)
      buf = data
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        return cb(nil)
      end
      local decoded_ok, val = pcall(vim.json.decode, table.concat(buf, "\n"))
      cb(decoded_ok and val or nil)
    end,
  })
  if not ok then
    cb(nil)
  end
end

local function count_open(discussions)
  local n = 0
  for _, d in ipairs(discussions or {}) do
    for _, note in ipairs(d.notes or {}) do
      if note.resolvable and not note.resolved then
        n = n + 1
        break
      end
    end
  end
  return n
end

local function short_date(iso)
  if type(iso) ~= "string" then
    return "?"
  end
  return iso:sub(1, 10)
end

-- system notes (pushes etc.) carry HTML; strip tags + collapse whitespace
local function strip_html(s)
  s = (s or ""):gsub("<[^>]*>", " ")
  s = s:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  return s
end

-- chronological feed lines for one MR's notes
local function build_feed_lines(mr, notes)
  local open_threads = 0
  for _, note in ipairs(notes or {}) do
    if note.resolvable and not note.resolved then
      open_threads = open_threads + 1
    end
  end

  local lines = {
    string.format("# !%d  %s", mr.iid, mr.title or ""),
    string.format("👍 %d   👎 %d   ⚠ %d open thread(s)", mr.upvotes or 0, mr.downvotes or 0, open_threads),
    string.format("branch: %s", mr.source_branch or "?"),
    "",
    "---",
    "",
  }

  if not notes or #notes == 0 then
    table.insert(lines, "_No activity yet._")
    return lines
  end

  for _, note in ipairs(notes) do
    local who = (note.author and note.author.username) or "?"
    local when = short_date(note.created_at)
    local body = note.body or ""
    if note.system then
      -- system notes carry pushes ("added N commits"), label changes, etc.
      table.insert(lines, string.format("- [%s] **%s** %s", when, who, strip_html(body)))
    else
      local flag = (note.resolvable and not note.resolved) and " _(open)_" or ""
      table.insert(lines, string.format("- [%s] **%s**%s:", when, who, flag))
      for _, bl in ipairs(vim.split(body, "\n", { plain = true })) do
        table.insert(lines, "    " .. bl)
      end
    end
  end

  return lines
end

local function feed_previewer(git_root)
  return previewers.new_buffer_previewer({
    title = "MR Activity",
    define_preview = function(self, entry)
      local mr = entry.value
      local function render(notes)
        if not vim.api.nvim_buf_is_valid(self.state.bufnr) then
          return
        end
        local lines = notes == false and { "_Failed to load feed._" } or build_feed_lines(mr, notes)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.bo[self.state.bufnr].filetype = "markdown"
      end

      local cached = feed_cache[mr.iid]
      if cached ~= nil then
        return render(cached)
      end

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "Loading feed…" })
      local endpoint = string.format("projects/:id/merge_requests/%d/notes?sort=asc&per_page=100", mr.iid)
      glab_json({ "glab", "api", endpoint }, git_root, function(notes)
        feed_cache[mr.iid] = notes == nil and false or notes
        render(feed_cache[mr.iid])
      end)
    end,
  })
end

local function open_url(url)
  if not url or url == "" then
    return
  end
  vim.fn.setreg("+", url)
  if os.getenv("TMUX") then
    vim.fn.system({ "tmux", "load-buffer", "-w", "-" }, url)
  elseif os.getenv("WAYLAND_DISPLAY") and vim.fn.executable("wl-copy") == 1 then
    vim.fn.system({ "wl-copy", url })
  else
    local encoded = vim.base64.encode(url)
    local tty = io.open("/dev/tty", "w")
    if tty then tty:write(string.format("\27]52;c;%s\7", encoded)); tty:close() end
  end
  vim.fn.jobstart({ "xdg-open", url }, { detach = true })
  vim.notify("Copied: " .. url, vim.log.levels.INFO)
end

local function make_entry_maker()
  local displayer = entry_display.create({
    separator = "  ",
    items = {
      { width = 6 },  -- !iid
      { remaining = true }, -- title
      { width = 16 }, -- comments
      { width = 12 }, -- votes
    },
  })

  return function(mr)
    local title = (mr.draft and "[draft] " or "") .. (mr.title or "")
    local total = mr.user_notes_count or 0
    local open = mr.open_comments or 0
    local comments
    if total == 0 then
      comments = "no comments"
    elseif open < total then
      comments = string.format("%d open (%d)", open, total)
    else
      comments = string.format("%d open", open)
    end

    return {
      value = mr,
      ordinal = title,
      display = function()
        return displayer({
          "!" .. mr.iid,
          title,
          comments,
          string.format("👍%d 👎%d", mr.upvotes or 0, mr.downvotes or 0),
        })
      end,
    }
  end
end

local function open_picker(mrs, git_root, project)
  pickers.new(require("telescope.themes").get_ivy({}), {
    prompt_title = "GitLab MRs — " .. project,
    finder = finders.new_table({
      results = mrs,
      entry_maker = make_entry_maker(),
    }),
    sorter = conf.generic_sorter({}),
    previewer = feed_previewer(git_root),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry then
          open_url(entry.value.web_url)
        end
      end)
      map({ "i", "n" }, "<C-y>", function()
        local entry = action_state.get_selected_entry()
        if entry and entry.value.web_url then
          vim.fn.setreg("+", entry.value.web_url)
          vim.notify("Yanked: " .. entry.value.web_url, vim.log.levels.INFO)
        end
      end)
      return true
    end,
  }):find()
end

M.open = function()
  local git_root = find_git_root()
  if not git_root then
    vim.notify("Not in a git repo", vim.log.levels.ERROR)
    return
  end
  local project = vim.fn.fnamemodify(git_root, ":t")

  vim.notify("Loading MRs…", vim.log.levels.INFO)
  feed_cache = {}

  glab_json({ "glab", "mr", "list", "-F", "json" }, git_root, function(mrs)
    if not mrs then
      vim.notify("glab failed — check `glab auth status`", vim.log.levels.ERROR)
      return
    end
    if #mrs == 0 then
      vim.notify("No open MRs", vim.log.levels.INFO)
      return
    end

    -- resolve exact open-comment count per MR in parallel, then open picker
    local pending = #mrs
    for _, mr in ipairs(mrs) do
      local endpoint = string.format("projects/:id/merge_requests/%d/discussions?per_page=100", mr.iid)
      glab_json({ "glab", "api", endpoint }, git_root, function(discussions)
        mr.open_comments = count_open(discussions)
        pending = pending - 1
        if pending == 0 then
          vim.schedule(function()
            open_picker(mrs, git_root, project)
          end)
        end
      end)
    end
  end)
end

M.setup = function()
  vim.keymap.set("n", "<leader>mr", M.open, { desc = "GitLab: MR picker" })
end

return M
