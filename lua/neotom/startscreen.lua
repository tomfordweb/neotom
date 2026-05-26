-- Animated "hacker" start screen: matrix-rain background, typewriter->glitch
-- NEOTOM wordmark, MRU list, async PR/MR list. Driven by one vim.uv timer.

local api = vim.api
local uv = vim.uv or vim.loop

local M = {}

local ns = api.nvim_create_namespace("neotom_start")

local function open_url(url)
  if not url or url == "" then return end
  vim.fn.setreg("+", url)
  local encoded = vim.base64.encode(url)
  local tty = io.open("/dev/tty", "w")
  if tty then
    tty:write(string.format("\27]52;c;%s\7", encoded))
    tty:close()
  end
  vim.fn.jobstart({ "xdg-open", url }, { detach = true })
  vim.notify("Copied: " .. url, vim.log.levels.INFO)
end
local FPS_MS = 66        -- active fps while the wordmark dissolves in
local IDLE_FPS_MS = 120  -- slower fps once fully revealed

-- NEOTOM wordmark (verbatim from the old alpha startify header)
local ART = {
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
}
local COMPACT = { " N E O T O M " }

-- ascii-only glyph set keeps 1 char == 1 column == 1 byte (alignment-safe)
local GLYPHS = {}
for ch in ("01<>[]{}/\\|=+*-_#%$&?!abcdefABCDEF0123456789"):gmatch(".") do
  GLYPHS[#GLYPHS + 1] = ch
end
local function rand_glyph()
  return GLYPHS[math.random(#GLYPHS)]
end

-- highlight groups (defined once in setup)
local function define_hl()
  local set = api.nvim_set_hl
  set(0, "NeotomRainHead", { fg = "#d6ffe0", bold = true })
  set(0, "NeotomRain1", { fg = "#7cff9b" })
  set(0, "NeotomRain2", { fg = "#38c46a" })
  set(0, "NeotomRain3", { fg = "#1f7d42" })
  set(0, "NeotomRain4", { fg = "#0d3b20" })
  set(0, "NeotomText", { fg = "#9cff9c", bold = true })
  set(0, "NeotomGlitchR", { fg = "#ff2d6b", bold = true })
  set(0, "NeotomGlitchC", { fg = "#28e7ff", bold = true })
  set(0, "NeotomDim", { fg = "#4a5a50" })
  set(0, "NeotomHint", { fg = "#5fd7a7", bold = true })
  set(0, "NeotomKey", { fg = "#ffd75f", bold = true })
  set(0, "NeotomMRU", { fg = "#cfe8d8" })
  set(0, "NeotomPR", { fg = "#79c0ff", underline = true })
  set(0, "NeotomWT", { fg = "#c9b8ff" })
  set(0, "NeotomWTActive", { fg = "#e8d8ff", bold = true })
end

-- ----------------------------------------------------------------------------
-- sources: MRU + async worktrees/HEAD/PRs (all bump state.ov_version on update
-- so the cached overlay is rebuilt)
-- ----------------------------------------------------------------------------
local function bump(state)
  state.ov_version = (state.ov_version or 0) + 1
end

local function get_mru()
  local files, seen = {}, {}
  local cache = vim.fn.stdpath("cache")
  local data = vim.fn.stdpath("data")
  for _, f in ipairs(vim.v.oldfiles) do
    if vim.fn.filereadable(f) == 1 and not seen[f]
        and not f:find(cache, 1, true) and not f:find(data, 1, true) then
      seen[f] = true
      files[#files + 1] = f
      if #files >= 8 then break end
    end
  end
  return files
end

local function fetch_worktrees(state)
  local cwd = vim.fn.getcwd()
  vim.system({ "git", "-C", cwd, "worktree", "list", "--porcelain" }, { text = true }, function(o)
    local trees, current = {}, {}
    if o.code == 0 and o.stdout then
      for line in (o.stdout .. "\n"):gmatch("([^\n]*)\n") do
        if line == "" then
          if current.path then trees[#trees + 1] = current end
          current = {}
        elseif line:match("^worktree ") then
          current.path = line:sub(10)
        elseif line:match("^branch ") then
          current.branch = line:sub(8):gsub("^refs/heads/", "")
        elseif line == "bare" then
          current.branch = "(bare)"
        end
      end
      if current.path then trees[#trees + 1] = current end
    end
    vim.schedule(function()
      state.worktrees = trees
      bump(state)
    end)
  end)
end

local function fetch_head(state)
  local cfg = vim.fn.stdpath("config")
  vim.system({ "git", "-C", cfg, "rev-parse", "--short", "HEAD" }, { text = true }, function(o)
    local head = "?"
    if o.code == 0 and o.stdout then head = o.stdout:gsub("%s+$", "") end
    if head == "" then head = "?" end
    vim.schedule(function()
      state.footer2 = "neotom " .. head
      bump(state)
    end)
  end)
end

local function fetch_prs(state)
  local cwd = vim.fn.getcwd()
  state.pr_status = "loading"
  vim.system({ "git", "-C", cwd, "remote", "get-url", "origin" }, { text = true }, function(o)
    local url = (o.stdout or ""):gsub("%s+$", "")
    local host
    if url:find("github.com", 1, true) then
      host = "github"
    elseif url:find("gitlab", 1, true) then
      host = "gitlab"
    end
    if not host then
      vim.schedule(function()
        state.pr_status = "none"
        state.prs = {}
        bump(state)
      end)
      return
    end
    local cmd
    if host == "github" then
      cmd = { "gh", "pr", "list", "--json", "number,title,url", "--limit", "8" }
    else
      cmd = { "glab", "mr", "list", "--output", "json", "-P", "8" }
    end
    vim.system(cmd, { cwd = cwd, text = true }, function(r)
      vim.schedule(function()
        if r.code ~= 0 or not r.stdout or r.stdout == "" then
          state.pr_status = "none"
          state.prs = {}
          bump(state)
          return
        end
        local ok, data = pcall(vim.json.decode, r.stdout)
        if not ok or type(data) ~= "table" then
          state.pr_status = "none"
          state.prs = {}
          bump(state)
          return
        end
        local prs = {}
        for _, pr in ipairs(data) do
          local link = pr.url or pr.web_url
          if link then
            prs[#prs + 1] = { title = pr.title or "(untitled)", url = link }
          end
        end
        state.prs = prs
        state.pr_status = (#prs > 0) and "loaded" or "none"
        bump(state)
      end)
    end)
  end)
end

-- ----------------------------------------------------------------------------
-- rendering helpers
-- ----------------------------------------------------------------------------
-- seg pool: reuse the entry tables across frames to avoid per-frame GC churn
local function add_seg(state, row0, c0, c1, hl)
  local n = state.seg_n + 1
  local s = state.segs[n]
  if s then
    s[1], s[2], s[3], s[4] = row0, c0, c1, hl
  else
    state.segs[n] = { row0, c0, c1, hl }
  end
  state.seg_n = n
end

-- collapse a row's per-cell hls into contiguous extmark spans; returns row text
local function emit_row(state, row0, chars, hls, width)
  local n = width
  local i = 1
  while i <= n do
    local h = hls[i]
    if h then
      local j = i
      while j + 1 <= n and hls[j + 1] == h do j = j + 1 end
      add_seg(state, row0, i - 1, j, h)
      i = j + 1
    else
      i = i + 1
    end
  end
  return table.concat(chars, "", 1, n)
end

local function new_drop(band_h)
  return {
    y = -math.random(0, band_h),
    speed = 0.4 + math.random() * 0.9,
    len = math.random(6, 16),
    last = -1,
    glyphs = {},
  }
end

local function trail_hl(k, len)
  if k == 0 then return "NeotomRainHead" end
  local frac = k / len
  if frac < 0.25 then return "NeotomRain1" end
  if frac < 0.5 then return "NeotomRain2" end
  if frac < 0.8 then return "NeotomRain3" end
  return "NeotomRain4"
end

-- ----------------------------------------------------------------------------
-- static overlay (MRU / worktrees / PRs / footer)
-- Built once per (art-choice, H, data-version) and cached on state, since the
-- content + devicon lookups don't change between data updates.
-- ----------------------------------------------------------------------------
local function build_overlay(state, W, H, art_top, art_h)
  local ov_rows = {}
  local actions = {}
  local cur = art_top + art_h + 2

  local function push_ov(str)
    local r = cur
    if cur < H then ov_rows[cur] = { text = str, spans = {} } end
    cur = cur + 1
    return r
  end
  local function push_ov_seg(str, hl, col0, col1)
    local r = push_ov(str)
    if ov_rows[r] then
      ov_rows[r].spans[#ov_rows[r].spans + 1] = { col0 or 0, col1 or #str, hl }
    end
    return r
  end
  -- tag a row for the typewriter/glitch effect (titles + footer only)
  local function anim(r)
    if ov_rows[r] then ov_rows[r].anim = true end
  end

  push_ov("")
  anim(push_ov_seg("  MOST RECENT", "NeotomHint"))
  local mru = state.mru
  if #mru == 0 then
    push_ov_seg("  (none)", "NeotomDim")
  else
    for i, f in ipairs(mru) do
      local icon, ihl = " ", "NeotomMRU"
      if state.devicons then
        local name = vim.fn.fnamemodify(f, ":t")
        local ext = vim.fn.fnamemodify(f, ":e")
        local ic, hl = state.devicons.get_icon(name, ext, { default = true })
        if ic then icon, ihl = ic, hl or "NeotomMRU" end
      end
      local key = "  [" .. i .. "] "
      local disp = vim.fn.fnamemodify(f, ":~:.")
      local str = key .. icon .. " " .. disp
      local r = push_ov(str)
      if ov_rows[r] then
        local sp = ov_rows[r].spans
        sp[#sp + 1] = { 0, #key, "NeotomKey" }
        sp[#sp + 1] = { #key, #key + #icon, ihl }
        sp[#sp + 1] = { #key + #icon, #str, "NeotomMRU" }
      end
      actions[r] = function() state.open_file(f) end
    end
  end

  push_ov("")
  anim(push_ov_seg("  WORKTREES", "NeotomHint"))
  local worktrees = state.worktrees
  if worktrees == nil then
    push_ov_seg("  scanning...", "NeotomDim")
  elseif #worktrees == 0 then
    push_ov_seg("  (none)", "NeotomDim")
  else
    local active = vim.fn.getcwd()
    for _, wt in ipairs(worktrees) do
      local is_active = wt.path == active
      local branch = wt.branch or "(detached)"
      local name = vim.fn.fnamemodify(wt.path, ":t")
      local str = "   " .. (is_active and "* " or "  ") .. name .. "  [" .. branch .. "]"
      local r = push_ov(str)
      if ov_rows[r] then
        ov_rows[r].spans[#ov_rows[r].spans + 1] = { 0, #str, is_active and "NeotomWTActive" or "NeotomWT" }
      end
      local path = wt.path
      actions[r] = function()
        M.stop()
        vim.cmd("cd " .. vim.fn.fnameescape(path))
        vim.cmd("enew")
        vim.notify("cwd → " .. path, vim.log.levels.INFO)
      end
    end
  end

  push_ov("")
  anim(push_ov_seg("  PULL REQUESTS", "NeotomHint"))
  if state.pr_status == "loading" then
    push_ov_seg("  decrypting...", "NeotomDim")
  elseif state.pr_status == "none" then
    push_ov_seg("  (none)", "NeotomDim")
  else
    for _, pr in ipairs(state.prs) do
      local str = "   " .. pr.title
      local r = push_ov(str)
      if ov_rows[r] then
        ov_rows[r].spans[#ov_rows[r].spans + 1] = { 0, #str, "NeotomPR" }
      end
      actions[r] = function() open_url(pr.url) end
    end
  end

  push_ov("")
  anim(push_ov_seg("  " .. state.footer1, "NeotomDim"))
  anim(push_ov_seg("  " .. state.footer2, "NeotomDim"))

  return ov_rows, actions
end

-- ----------------------------------------------------------------------------
-- frame builder
-- ----------------------------------------------------------------------------
local function build_frame(state, W, H)
  local art = (W < #ART[1] + 2) and COMPACT or ART
  local is_compact = art == COMPACT
  local art_w = #art[1]
  local art_h = #art
  local left = math.max(0, math.floor((W - art_w) / 2))
  local art_top = 3
  local rain_bot = H - 1

  -- (re)allocate drops + reusable row buffers on resize
  if state.W ~= W or state.H ~= H then
    state.W = W
    state.H = H
    state.drops = {}
    local cb, hb = {}, {}
    for c = 1, W do state.drops[c] = new_drop(rain_bot) end
    for r = 0, H - 1 do
      local rc, rh = {}, {}
      for c = 1, W do rc[c] = " "; rh[c] = false end
      cb[r] = rc; hb[r] = rh
    end
    state.chars_buf = cb
    state.hls_buf = hb
    state.ov_cache_key = nil -- art-choice / H may have changed
    -- reset rain-dissolve reveal state (geometry/art may have changed)
    local tg = 0
    for _, l in ipairs(art) do
      for i = 1, #l do if l:byte(i) ~= 32 then tg = tg + 1 end end
    end
    state.total_glyphs = tg
    state.exposed = {}
    state.exposed_count = 0
    state.done = false
    state.fresh = {}
  end

  -- advance rain
  for c = 1, W do
    local d = state.drops[c]
    d.y = d.y + d.speed
    local head = math.floor(d.y)
    if head ~= d.last then
      for r = d.last + 1, head do d.glyphs[r] = rand_glyph() end
      d.last = head
    end
    if d.y - d.len > rain_bot then
      state.drops[c] = new_drop(rain_bot)
    end
  end

  -- rain-dissolve reveal: a wordmark cell is exposed once a rain drop in its
  -- column has dripped past its row; freshly-exposed cells flash this frame
  local fresh = state.fresh
  for k in pairs(fresh) do fresh[k] = nil end
  for arow = 0, art_h - 1 do
    local line = art[arow + 1]
    local r = art_top + arow
    local erow = state.exposed[arow]
    if not erow then erow = {}; state.exposed[arow] = erow end
    for ac = 1, art_w do
      if not erow[ac] and line:byte(ac) ~= 32 then
        local col = left + ac
        local d = (col >= 1 and col <= W) and state.drops[col] or nil
        if d and math.floor(d.y) >= r then
          erow[ac] = true
          state.exposed_count = state.exposed_count + 1
          fresh[arow * 4096 + ac] = true
        end
      end
    end
  end
  if not state.done and state.exposed_count >= state.total_glyphs then
    state.done = true
  end

  -- cached static overlay (rebuilt only when art-choice / H / data changes)
  local key = (is_compact and "C" or "F") .. ":" .. H .. ":" .. (state.ov_version or 0)
  if state.ov_cache_key ~= key then
    state.ov_rows, state.ov_actions = build_overlay(state, W, H, art_top, art_h)
    state.ov_cache_key = key
  end
  local ov_rows = state.ov_rows
  state.actions = state.ov_actions

  -- fill reusable buffers: rain background, then wordmark + content on top
  local cb, hb = state.chars_buf, state.hls_buf
  for r = 0, H - 1 do
    local rc, rh = cb[r], hb[r]
    for c = 1, W do rc[c] = " "; rh[c] = false end
  end

  -- rain, written column-major straight into the row buffers
  for c = 1, W do
    local d = state.drops[c]
    local head = math.floor(d.y)
    local len = d.len
    for k = 0, len - 1 do
      local r = head - k
      if r >= 0 and r <= rain_bot then
        cb[r][c] = d.glyphs[r] or rand_glyph()
        hb[r][c] = trail_hl(k, len)
      end
    end
  end

  -- wordmark overlay: exposed letters shown; the passing drip head flashes bright
  for arow = 0, art_h - 1 do
    local r = art_top + arow
    if r >= 0 and r <= rain_bot then
      local rc, rh = cb[r], hb[r]
      local line = art[arow + 1]
      local erow = state.exposed[arow]
      for ac = 1, art_w do
        if line:byte(ac) ~= 32 then
          local col = left + ac
          if col >= 1 and col <= W then
            local d = state.drops[col]
            local head = d and math.floor(d.y) or -1
            if head == r or fresh[arow * 4096 + ac] then
              rc[col] = line:sub(ac, ac)
              rh[col] = "NeotomRainHead"
            elseif erow and erow[ac] then
              rc[col] = line:sub(ac, ac)
              rh[col] = "NeotomText"
            end
          end
        end
      end
    end
  end

  -- little red glitches on already-exposed letters
  for _ = 1, math.random(0, 2) do
    local arow = math.random(0, art_h - 1)
    local erow = state.exposed[arow]
    if erow then
      local ac = math.random(1, art_w)
      if erow[ac] then
        local r = art_top + arow
        local col = left + ac
        if r >= 0 and r <= rain_bot and col >= 1 and col <= W then
          cb[r][col] = rand_glyph()
          hb[r][col] = "NeotomGlitchR"
        end
      end
    end
  end

  -- content overlay + emit rows
  local lines = state.lines
  if not lines then lines = {}; state.lines = lines end
  state.seg_n = 0
  for r = 0, H - 1 do
    local rc, rh = cb[r], hb[r]
    local ov = ov_rows[r]
    if ov then
      local text = ov.text
      local tlen = math.min(#text, W)
      for ci = 1, tlen do
        rc[ci] = text:sub(ci, ci)
        rh[ci] = false
      end
      for _, sp in ipairs(ov.spans) do
        local hi = math.min(sp[2], W)
        local hl = sp[3]
        for ci = sp[1] + 1, hi do rh[ci] = hl end
      end
      -- little red glitch flicker on titles/footer
      if ov.anim and tlen > 0 and math.random() < 0.12 then
        local ci = math.random(1, tlen)
        rc[ci] = rand_glyph()
        rh[ci] = "NeotomGlitchR"
      end
    end
    lines[r + 1] = emit_row(state, r, rc, rh, W)
  end
  for i = H + 1, #lines do lines[i] = nil end

  return lines
end

-- ----------------------------------------------------------------------------
-- lifecycle
-- ----------------------------------------------------------------------------
function M.stop()
  if M.timer then
    M.timer:stop()
    if not M.timer:is_closing() then M.timer:close() end
    M.timer = nil
  end
end

local function draw(buf, lines, state)
  if not api.nvim_buf_is_valid(buf) then return end
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local segs = state.segs
  for i = 1, state.seg_n do
    local s = segs[i]
    pcall(api.nvim_buf_set_extmark, buf, ns, s[1], s[2], {
      end_col = s[3],
      hl_group = s[4],
    })
  end
end

local function tick(state)
  local buf = state.buf
  if not (buf and api.nvim_buf_is_valid(buf)) then
    M.stop()
    return
  end
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    M.stop()
    return
  end
  local W = api.nvim_win_get_width(win)
  local H = api.nvim_win_get_height(win)
  state.frame = state.frame + 1
  local lines = build_frame(state, W, H)
  draw(buf, lines, state)
  if not state.cursor_set then
    -- place cursor on first MRU entry if present
    local first
    for r in pairs(state.actions) do
      if not first or r < first then first = r end
    end
    if first then
      pcall(api.nvim_win_set_cursor, win, { first + 1, 0 })
    end
    state.cursor_set = true
  end
  -- once the wordmark is fully revealed, slow the timer to cut idle CPU
  if state.done and not state.throttled then
    state.throttled = true
    if M.timer then
      M.timer:stop()
      M.timer:start(0, IDLE_FPS_MS, vim.schedule_wrap(function() tick(state) end))
    end
  end
end

local function set_keymaps(buf, state)
  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true })
  end
  map("<CR>", function()
    local row = api.nvim_win_get_cursor(0)[1] - 1
    local fn = state.actions[row]
    if fn then fn() end
  end)
  for i = 1, 9 do
    map(tostring(i), function()
      local f = state.mru[i]
      if f then state.open_file(f) end
    end)
  end
  map("r", function() fetch_prs(state) end)
  map("q", function()
    M.stop()
    vim.cmd("qa")
  end)
  map("<Esc>", function()
    M.stop()
    vim.cmd("enew")
  end)
end

function M.open()
  M.stop()
  local v = vim.version()
  local ok_dev, devicons = pcall(require, "nvim-web-devicons")

  local state = {
    frame = 0,
    done = false,
    throttled = false,
    exposed = {},
    exposed_count = 0,
    total_glyphs = 0,
    fresh = {},
    W = nil,
    H = nil,
    drops = {},
    chars_buf = nil,
    hls_buf = nil,
    lines = nil,
    segs = {},
    seg_n = 0,
    ov_version = 0,
    ov_cache_key = nil,
    ov_rows = nil,
    ov_actions = nil,
    mru = get_mru(),
    worktrees = nil, -- async; renders "scanning..." until loaded
    prs = {},
    pr_status = "loading",
    actions = {},
    cursor_set = false,
    devicons = ok_dev and devicons or nil,
    footer1 = ("nvim %d.%d.%d"):format(v.major, v.minor, v.patch),
    footer2 = "neotom", -- async rev-parse fills in the short hash
  }
  M.state = state

  local buf = api.nvim_create_buf(false, true)
  state.buf = buf
  state.open_file = function(f)
    M.stop()
    vim.cmd("edit " .. vim.fn.fnameescape(f))
  end

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "neotomstart"
  vim.bo[buf].modifiable = false

  api.nvim_win_set_buf(0, buf)
  local win = api.nvim_get_current_win()
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].list = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].cursorline = false
  vim.wo[win].wrap = false
  vim.wo[win].spell = false
  vim.wo[win].colorcolumn = ""
  vim.wo[win].fillchars = "eob: "

  set_keymaps(buf, state)
  fetch_worktrees(state)
  fetch_head(state)
  fetch_prs(state)

  api.nvim_create_autocmd({ "BufLeave", "BufWipeout" }, {
    buffer = buf,
    once = true,
    callback = function() M.stop() end,
  })

  M.timer = uv.new_timer()
  M.timer:start(0, FPS_MS, vim.schedule_wrap(function() tick(state) end))
end

function M.setup()
  define_hl()
  vim.keymap.set("n", "<leader>a", M.open, { desc = "Open Start Screen" })
  vim.api.nvim_create_autocmd("ColorScheme", { callback = define_hl })
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      if vim.fn.argc(-1) == 0
          and api.nvim_buf_line_count(0) == 1
          and api.nvim_buf_get_lines(0, 0, 1, false)[1] == ""
          and vim.bo.filetype == "" then
        M.open()
      end
    end,
  })
end

M.setup()

return M
