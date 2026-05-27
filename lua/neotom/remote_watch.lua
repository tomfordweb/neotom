local M = {}
local uv = vim.uv or vim.loop

local INTERVAL_MS = 60 * 1000

local function notify(msg, level, opts)
  local ok, nvim_notify = pcall(require, "notify")
  if ok then
    nvim_notify(msg, level, opts)
  else
    vim.notify(msg, level)
  end
end

local state = {
  timer = nil,
  upstream_hash = {},   -- [cwd] = string
  base_hash = {},       -- [cwd] = string
  base_branch = {},     -- [cwd] = string | false  (false = checked, none found)
  uptodate_shown = {},  -- [cwd] = bool; reset when changes detected
}

local function trim(s)
  return (s or ""):match("^%s*(.-)%s*$")
end

local function parse_commits(stdout)
  local commits = {}
  for line in (stdout or ""):gmatch("[^\n]+") do
    local h, s, a = line:match("^([^\t]+)\t([^\t]*)\t(.*)$")
    if h then commits[#commits + 1] = { hash = h, subject = s, author = a } end
  end
  return commits
end

local function make_link(remote_url, hash)
  if not remote_url or remote_url == "" or not hash then return nil end
  local url = remote_url
    :gsub("^git@([^:]+):(.+)$", "https://%1/%2")
    :gsub("%.git$", "")
  if url:find("github.com", 1, true) then return url .. "/commit/" .. hash end
  if url:find("gitlab", 1, true) then return url .. "/-/commit/" .. hash end
  return nil
end

-- Find the remote branch this branch diverged from most recently.
-- Uses git log --simplify-by-decoration to find the first remote branch
-- in the ancestry that isn't the current upstream.
local function detect_base(cwd, upstream_name, cb)
  local cached = state.base_branch[cwd]
  if cached ~= nil then
    cb(cached ~= false and cached or nil)
    return
  end
  vim.system(
    { "git", "-C", cwd, "log", "--simplify-by-decoration", "--pretty=%D", "HEAD" },
    { text = true },
    function(o)
      local found = nil
      if o.code == 0 then
        for line in (o.stdout or ""):gmatch("[^\n]+") do
          for dec in line:gmatch("[^,]+") do
            -- strip "HEAD -> branchname" prefix, then trim
            dec = trim(dec):gsub("^HEAD %-> %S+", "")
            dec = trim(dec)
            if dec:match("^origin/") and dec ~= upstream_name and not dec:match("^origin/HEAD") then
              found = dec
              break
            end
          end
          if found then break end
        end
      end
      state.base_branch[cwd] = found or false
      cb(found)
    end
  )
end

local function tick()
  local cwd = vim.fn.getcwd()

  -- guard: bail if not a git repo
  vim.system({ "git", "-C", cwd, "rev-parse", "--git-dir" }, { text = true }, function(g)
    if g.code ~= 0 then return end

    -- fetch (continue regardless of result — offline is fine)
    vim.system({ "git", "-C", cwd, "fetch", "--quiet" }, { text = true }, function()

      -- get upstream hash + display name
      vim.system({ "git", "-C", cwd, "rev-parse", "@{u}" }, { text = true }, function(uh)
        vim.system({ "git", "-C", cwd, "rev-parse", "--abbrev-ref", "@{u}" }, { text = true }, function(un)
          local u_hash = uh.code == 0 and trim(uh.stdout) or nil
          local u_name = un.code == 0 and trim(un.stdout) or nil

          detect_base(cwd, u_name, function(b_name)

            local function after_base_hash(b_hash)
              local old_u = state.upstream_hash[cwd]
              local old_b = state.base_hash[cwd]

              if u_hash then state.upstream_hash[cwd] = u_hash end
              if b_hash then state.base_hash[cwd] = b_hash end

              local u_first = old_u == nil and u_hash ~= nil
              local b_first = old_b == nil and b_hash ~= nil
              local u_changed = old_u ~= nil and u_hash ~= nil and old_u ~= u_hash
              local b_changed = old_b ~= nil and b_hash ~= nil and old_b ~= b_hash

              -- no changes: fire "up to date" once per cwd (not every poll)
              if not u_changed and not b_changed then
                if not u_first and not b_first and not state.uptodate_shown[cwd] then
                  state.uptodate_shown[cwd] = true
                  vim.schedule(function()
                    notify(
                      string.format("✓ up to date  %s  base: %s",
                        u_name or "(no upstream)", b_name or "(none)"),
                      vim.log.levels.INFO,
                      { title = "remote watch" }
                    )
                  end)
                end
                return
              end

              -- changes detected: reset uptodate flag so it shows again next time clean
              state.uptodate_shown[cwd] = false

              -- get remote url for link building, then query commit logs
              vim.system({ "git", "-C", cwd, "remote", "get-url", "origin" }, { text = true }, function(ru)
                local remote_url = ru.code == 0 and trim(ru.stdout) or ""
                local pending = 0
                local u_commits, b_commits = {}, {}

                local function maybe_notify()
                  if pending > 0 then return end
                  vim.schedule(function()
                    if u_changed and #u_commits > 0 then
                      local n = #u_commits
                      local lines = { string.format("↑ %d new commit%s on %s",
                        n, n == 1 and "" or "s", u_name or "upstream") }
                      for i, c in ipairs(u_commits) do
                        if i > 5 then break end
                        lines[#lines + 1] = "• " .. c.subject .. " — " .. c.author
                      end
                      local link = make_link(remote_url, u_commits[1].hash)
                      if link then lines[#lines + 1] = link end
                      vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
                    end

                    if b_changed and #b_commits > 0 then
                      local n = #b_commits
                      local lines = { string.format("⚠ base branch %s advanced (%d commit%s)",
                        b_name, n, n == 1 and "" or "s") }
                      for i, c in ipairs(b_commits) do
                        if i > 5 then break end
                        lines[#lines + 1] = "• " .. c.subject .. " — " .. c.author
                      end
                      local link = make_link(remote_url, b_commits[1].hash)
                      if link then lines[#lines + 1] = link end
                      lines[#lines + 1] = "Consider rebasing."
                      vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN)
                    end
                  end)
                end

                if u_changed then
                  pending = pending + 1
                  vim.system(
                    { "git", "-C", cwd, "log", old_u .. ".." .. u_hash, "--format=%H\t%s\t%an" },
                    { text = true },
                    function(lc)
                      u_commits = parse_commits(lc.stdout)
                      pending = pending - 1
                      maybe_notify()
                    end
                  )
                end

                if b_changed then
                  pending = pending + 1
                  vim.system(
                    { "git", "-C", cwd, "log", old_b .. ".." .. b_hash, "--format=%H\t%s\t%an" },
                    { text = true },
                    function(lc)
                      b_commits = parse_commits(lc.stdout)
                      pending = pending - 1
                      maybe_notify()
                    end
                  )
                end
              end)
            end

            if b_name then
              vim.system({ "git", "-C", cwd, "rev-parse", b_name }, { text = true }, function(bh)
                after_base_hash(bh.code == 0 and trim(bh.stdout) or nil)
              end)
            else
              after_base_hash(nil)
            end

          end)
        end)
      end)
    end)
  end)
end

function M.stop()
  if M.timer then
    M.timer:stop()
    if not M.timer:is_closing() then M.timer:close() end
    M.timer = nil
  end
end

function M.start()
  M.stop()
  M.timer = uv.new_timer()
  M.timer:start(0, INTERVAL_MS, vim.schedule_wrap(function() tick() end))
end

function M.setup()
  M.start()
  vim.api.nvim_create_autocmd("DirChanged", {
    callback = function()
      local cwd = vim.fn.getcwd()
      state.upstream_hash[cwd] = nil
      state.base_hash[cwd] = nil
      state.base_branch[cwd] = nil
      state.uptodate_shown[cwd] = false
      M.start()
    end,
  })
end

M.setup()
return M
