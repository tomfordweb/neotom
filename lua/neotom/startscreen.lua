-- Animated "hacker" start screen: matrix-rain background, typewriter->glitch
-- NEOTOM wordmark, MRU list, async PR/MR list. Driven by one vim.uv timer.

local api = vim.api
local uv = vim.uv or vim.loop

local M = {}

local ns = api.nvim_create_namespace("neotom_start")
local FPS_MS = 66

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
end

-- ----------------------------------------------------------------------------
-- sources: MRU + async PRs
-- ----------------------------------------------------------------------------
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
          return
        end
        local ok, data = pcall(vim.json.decode, r.stdout)
        if not ok or type(data) ~= "table" then
          state.pr_status = "none"
          state.prs = {}
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
      end)
    end)
  end)
end

-- ----------------------------------------------------------------------------
-- rendering helpers
-- ----------------------------------------------------------------------------
local function emit_row(segs, row0, chars, hls, width)
  local n = width
  local i = 1
  while i <= n do
    local h = hls[i]
    if h then
      local j = i
      while j + 1 <= n and hls[j + 1] == h do j = j + 1 end
      segs[#segs + 1] = { row0, i - 1, j, h }
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
-- frame builder
-- ----------------------------------------------------------------------------
local function build_frame(state, W, H)
  local art = (W < #ART[1] + 2) and COMPACT or ART
  local art_w = #art[1]
  local art_h = #art
  local left = math.max(0, math.floor((W - art_w) / 2))
  local art_top = 3
  local band_bot = art_top + art_h + 2

  -- advance rain (resize-aware)
  if state.W ~= W then
    state.W = W
    state.drops = {}
    for c = 1, W do state.drops[c] = new_drop(band_bot) end
  end
  for c = 1, W do
    local d = state.drops[c]
    d.y = d.y + d.speed
    local head = math.floor(d.y)
    if head ~= d.last then
      for r = d.last + 1, head do d.glyphs[r] = rand_glyph() end
      d.last = head
    end
    if d.y - d.len > band_bot then
      state.drops[c] = new_drop(band_bot)
    end
  end

  -- precompute rain cells: rain_ch[r][c], rain_hl[r][c]
  local rain_ch, rain_hl = {}, {}
  for c = 1, W do
    local d = state.drops[c]
    local head = math.floor(d.y)
    for k = 0, d.len - 1 do
      local r = head - k
      if r >= 0 and r <= band_bot then
        rain_ch[r] = rain_ch[r] or {}
        rain_hl[r] = rain_hl[r] or {}
        rain_ch[r][c] = d.glyphs[r] or rand_glyph()
        rain_hl[r][c] = trail_hl(k, d.len)
      end
    end
  end

  -- text fx state
  if state.phase == "typing" then
    state.reveal = state.reveal + 2
    if state.reveal >= art_w then state.phase = "glitch" end
  end
  local corrupt, tear_row, tear_dx, flicker = {}, nil, 0, false
  if state.phase == "glitch" then
    local n = math.random(0, 6)
    for _ = 1, n do
      local rr = math.random(0, art_h - 1)
      corrupt[rr] = corrupt[rr] or {}
      corrupt[rr][math.random(1, art_w)] = (math.random() < 0.5) and "NeotomGlitchR" or "NeotomGlitchC"
    end
    if math.random() < 0.3 then
      tear_row = math.random(0, art_h - 1)
      tear_dx = math.random(-2, 2)
    end
    flicker = math.random() < 0.06
  end

  local lines, segs = {}, {}

  -- band rows (rain + wordmark overlay)
  for r = 0, band_bot do
    local chars, hls = {}, {}
    for c = 1, W do
      chars[c] = (rain_ch[r] and rain_ch[r][c]) or " "
      hls[c] = (rain_hl[r] and rain_hl[r][c]) or false
    end
    local arow = r - art_top
    if arow >= 0 and arow < art_h then
      local dx = (tear_row == arow) and tear_dx or 0
      local line = art[arow + 1]
      for ac = 1, art_w do
        local revealed = (state.phase == "glitch") or (ac <= state.reveal)
        if revealed then
          local glyph = line:sub(ac, ac)
          if glyph ~= " " then
            local col = left + ac + dx
            if col >= 1 and col <= W then
              local hl = "NeotomText"
              if flicker then
                hl = "NeotomDim"
              elseif corrupt[arow] and corrupt[arow][ac] then
                hl = corrupt[arow][ac]
                glyph = rand_glyph()
              end
              chars[col] = glyph
              hls[col] = hl
            end
          end
        end
      end
      -- typing cursor bar
      if state.phase == "typing" then
        local col = left + math.min(state.reveal + 1, art_w)
        if col >= 1 and col <= W then
          chars[col] = "▌"
          hls[col] = "NeotomRainHead"
        end
      end
    end
    lines[r + 1] = emit_row(segs, r, chars, hls, W)
  end

  -- lower sections
  local actions = {}
  local function push(str)
    lines[#lines + 1] = str
    return #lines - 1
  end
  local function push_seg(str, hl, col0, col1)
    local r = push(str)
    segs[#segs + 1] = { r, col0 or 0, col1 or #str, hl }
    return r
  end

  push("")
  push_seg("  MOST RECENT", "NeotomHint")
  local mru = state.mru
  if #mru == 0 then
    push_seg("  (none)", "NeotomDim")
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
      local r = push(str)
      segs[#segs + 1] = { r, 0, #key, "NeotomKey" }
      segs[#segs + 1] = { r, #key, #key + #icon, ihl }
      segs[#segs + 1] = { r, #key + #icon, #str, "NeotomMRU" }
      actions[r] = function() state.open_file(f) end
    end
  end

  push("")
  push_seg("  PULL REQUESTS", "NeotomHint")
  if state.pr_status == "loading" then
    push_seg("  decrypting...", "NeotomDim")
  elseif state.pr_status == "none" then
    push_seg("  (none)", "NeotomDim")
  else
    for _, pr in ipairs(state.prs) do
      local str = "   " .. pr.title
      local r = push(str)
      segs[#segs + 1] = { r, 0, #str, "NeotomPR" }
      actions[r] = function() vim.ui.open(pr.url) end
    end
  end

  push("")
  push_seg("  " .. state.footer1, "NeotomDim")
  push_seg("  " .. state.footer2, "NeotomDim")

  state.actions = actions
  return lines, segs
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

local function draw(buf, lines, segs)
  if not api.nvim_buf_is_valid(buf) then return end
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, s in ipairs(segs) do
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
  local lines, segs = build_frame(state, W, H)
  draw(buf, lines, segs)
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
    vim.cmd("enew")
  end)
  map("<Esc>", function()
    M.stop()
    vim.cmd("enew")
  end)
end

function M.open()
  M.stop()
  local cfg = vim.fn.stdpath("config")
  local head = vim.fn.systemlist({ "git", "-C", cfg, "rev-parse", "--short", "HEAD" })[1] or "?"
  local v = vim.version()
  local ok_dev, devicons = pcall(require, "nvim-web-devicons")

  local state = {
    frame = 0,
    phase = "typing",
    reveal = 0,
    W = nil,
    drops = {},
    mru = get_mru(),
    prs = {},
    pr_status = "loading",
    actions = {},
    cursor_set = false,
    devicons = ok_dev and devicons or nil,
    footer1 = ("nvim %d.%d.%d"):format(v.major, v.minor, v.patch),
    footer2 = "neotom " .. head,
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
