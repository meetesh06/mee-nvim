-- Start screen for a bare `nvim`: the project (cwd) name in big letters, plus
-- recent files in this project. No plugin; the buffer is wiped as soon as you
-- open a file.
--
--   1-9        open a recent file
--   <- or ->   switch the banner face (remembered for the next start)
--
-- The banner is a FIGlet face with a colour wave travelling diagonally through
-- it. A libuv timer repaints the highlight groups while the splash is on screen
-- and stops the moment it is wiped or hidden.

local M = {}

local api = vim.api
local ns = api.nvim_create_namespace("splash")

-- Faces live in lua/core/fonts/*.lua and are picked up automatically, so
-- `./setup_font.sh "Small Slant"` is all it takes to add one. Widest first, so
-- the banner defaults to the biggest face that fits the window; <Left>/<Right>
-- on the splash pick another one and the choice is remembered.
local font_dir = vim.fs.joinpath(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h"), "fonts")
local faces = {}
for _, path in ipairs(vim.fn.glob(font_dir .. "/*.lua", false, true)) do
  local chunk = loadfile(path)
  local face = chunk and chunk()
  if type(face) == "table" and face.glyphs and face.rows then
    face.name = face.name or vim.fn.fnamemodify(path, ":t:r")
    faces[#faces + 1] = face
  end
end
table.sort(faces, function(a, b) return (a.width or 0) > (b.width or 0) end)

-- The picked face outlives the session, so the banner looks the way you left it.
local preferences = vim.fs.joinpath(vim.fn.stdpath("state"), "splash.json")

local function saved_face()
  local f = io.open(preferences, "rb")
  if not f then return nil end
  local ok, data = pcall(vim.json.decode, f:read("*a") or "")
  f:close()
  return ok and type(data) == "table" and data.face or nil
end

local function remember_face(name)
  local ok, encoded = pcall(vim.json.encode, { face = name })
  if not ok then return end
  local f = io.open(preferences, "wb")
  if f then f:write(encoded) f:close() end
end

local chosen = 1
for i, face in ipairs(faces) do
  if face.name == saved_face() then chosen = i break end
end

-- 5-row bitmap font, '#' = filled. Glyphs vary in width; 1 column between them.
local font = {
  A = { ".##.", "#..#", "####", "#..#", "#..#" },
  B = { "###.", "#..#", "###.", "#..#", "###." },
  C = { ".###", "#...", "#...", "#...", ".###" },
  D = { "###.", "#..#", "#..#", "#..#", "###." },
  E = { "####", "#...", "###.", "#...", "####" },
  F = { "####", "#...", "###.", "#...", "#..." },
  G = { ".###", "#...", "#.##", "#..#", ".###" },
  H = { "#..#", "#..#", "####", "#..#", "#..#" },
  I = { "###", ".#.", ".#.", ".#.", "###" },
  J = { "..##", "...#", "...#", "#..#", ".##." },
  K = { "#..#", "#.#.", "##..", "#.#.", "#..#" },
  L = { "#...", "#...", "#...", "#...", "####" },
  M = { "#...#", "##.##", "#.#.#", "#...#", "#...#" },
  N = { "#..#", "##.#", "#.##", "#..#", "#..#" },
  O = { ".##.", "#..#", "#..#", "#..#", ".##." },
  P = { "###.", "#..#", "###.", "#...", "#..." },
  Q = { ".##.", "#..#", "#..#", "#.##", ".###" },
  R = { "###.", "#..#", "###.", "#.#.", "#..#" },
  S = { ".###", "#...", ".##.", "...#", "###." },
  T = { "#####", "..#..", "..#..", "..#..", "..#.." },
  U = { "#..#", "#..#", "#..#", "#..#", ".##." },
  V = { "#...#", "#...#", "#...#", ".#.#.", "..#.." },
  W = { "#...#", "#...#", "#.#.#", "##.##", "#...#" },
  X = { "#...#", ".#.#.", "..#..", ".#.#.", "#...#" },
  Y = { "#...#", ".#.#.", "..#..", "..#..", "..#.." },
  Z = { "####", "...#", "..#.", ".#..", "####" },
  ["0"] = { ".##.", "#..#", "#.##", "##.#", ".##." },
  ["1"] = { ".#.", "##.", ".#.", ".#.", "###" },
  ["2"] = { "###.", "...#", ".##.", "#...", "####" },
  ["3"] = { "###.", "...#", ".##.", "...#", "###." },
  ["4"] = { "#..#", "#..#", "####", "...#", "...#" },
  ["5"] = { "####", "#...", "###.", "...#", "###." },
  ["6"] = { ".##.", "#...", "###.", "#..#", ".##." },
  ["7"] = { "####", "...#", "..#.", ".#..", ".#.." },
  ["8"] = { ".##.", "#..#", ".##.", "#..#", ".##." },
  ["9"] = { ".##.", "#..#", ".###", "...#", ".##." },
  ["-"] = { "...", "...", "###", "...", "..." },
  ["_"] = { "...", "...", "...", "...", "###" },
  ["."] = { ".", ".", ".", ".", "#" },
  [" "] = { "..", "..", "..", "..", ".." },
  ["?"] = { "###.", "...#", ".##.", "....", ".#.." },
}

-- Split into characters, not bytes, so non-ASCII directory names survive.
local function chars(text) return vim.fn.split(text, "\\zs") end

-- FIGlet rows for the whole word at native size. Box-drawing glyphs do not
-- survive being stretched (a doubled ╗ reads as ╗╗), so there is no scale here.
local function face_render(face, text)
  local src = face.upper and text:upper() or text
  local rows = {}
  for r = 1, face.rows do rows[r] = "" end
  for _, c in ipairs(chars(src)) do
    local g = face.glyphs[c] or face.glyphs["?"]
    for r = 1, face.rows do rows[r] = rows[r] .. g[r] end
  end
  return rows
end

local function face_width(face, text)
  local src = face.upper and text:upper() or text
  local width = 0
  for _, c in ipairs(chars(src)) do
    width = width + vim.fn.strdisplaywidth((face.glyphs[c] or face.glyphs["?"])[1])
  end
  return width
end

-- Block font: each pixel is 2s cells wide and s rows tall (cells are about twice
-- as tall as they are wide, so letters stay roughly square).
local function render(text, s)
  local rows = {}
  for r = 1, 5 do
    local parts = vim.tbl_map(function(c) return (font[c] or font["?"])[r] end, chars(text:upper()))
    local pattern = table.concat(parts, ".")
    local row = pattern:gsub("#", ("█"):rep(2 * s)):gsub("%.", (" "):rep(2 * s))
    for _ = 1, s do rows[#rows + 1] = row end
  end
  return rows
end

-- Banner rows for the project name, plus the face that drew them. The chosen
-- face is tried first and the rest widest-first after it, so a face too big for
-- the window steps aside for a smaller one instead of dropping to plain text.
local function art(text, w, h)
  for k = 0, #faces - 1 do
    local face = faces[((chosen - 1 + k) % #faces) + 1]
    if face_width(face, text) <= w - 4 and face.rows <= h - 9 then
      return face_render(face, text), face.name
    end
  end
  local px = 0
  for _, c in ipairs(chars(text:upper())) do px = px + #(font[c] or font["?"])[1] + 1 end
  for s = 4, 1, -1 do
    if (px - 1) * 2 * s <= w - 4 and 5 * s <= h * 0.5 then return render(text, s), "block" end
  end
end

-- Read the branch straight from .git/HEAD: no process spawn on startup.
local function branch(cwd)
  local root = vim.fs.root(cwd, ".git")
  if not root then return end
  local git = vim.fs.joinpath(root, ".git")
  if (vim.uv.fs_stat(git) or {}).type == "file" then -- worktree / submodule
    local f = io.open(git)
    local dir = f and (f:read("*l") or ""):match("^gitdir: (.+)$")
    if f then f:close() end
    if not dir then return end
    git = dir:sub(1, 1) == "/" and dir or vim.fs.joinpath(root, dir)
  end
  local f = io.open(vim.fs.joinpath(git, "HEAD"))
  if not f then return end
  local head = f:read("*l") or ""
  f:close()
  return head:match("^ref: refs/heads/(.+)$") or head:sub(1, 7)
end

local function recent(cwd, n)
  local prefix = cwd:gsub("/$", "") .. "/"
  local out = {}
  for _, f in ipairs(vim.v.oldfiles) do
    if vim.startswith(f, prefix) and (vim.uv.fs_stat(f) or {}).type == "file" then
      out[#out + 1] = f
      if #out == n then break end
    end
  end
  return out, prefix
end

-- Splash state: the buffer, its recent-file list, the animation timer and the
-- current gradient phase (0..2, ping-pongs so the sweep has no visible seam).
local state = { buf = nil, files = {}, timer = nil, phase = 0, art_rows = 0 }

local function fg(name, default) return api.nvim_get_hl(0, { name = name, link = false }).fg or default end

-- Linear blend of two 24-bit colours, t in 0..1.
local function mix(a, b, t)
  local c = 0
  for _, shift in ipairs({ 65536, 256, 1 }) do
    local x, y = math.floor(a / shift) % 256, math.floor(b / shift) % 256
    c = c + math.floor(x + (y - x) * t + 0.5) * shift
  end
  return c
end

-- A cyclic palette sampled from the theme's signal colours, so the banner reads
-- as a colour wheel that follows deepblue. Edit `stops` to retune the mood.
local WAVE_N = 36
local WAVE_TILT = 0.7 -- rows shift the wave sideways, so it travels diagonally
local function wave_palette()
  local stops = {
    fg("Title", 0xff80ff),     -- magenta
    fg("Special", 0xffa500),   -- orange
    fg("Statement", 0xffff60), -- yellow
    fg("Type", 0x90f020),      -- green
    fg("Directory", 0x5fd7d7), -- cyan
    fg("Comment", 0x80a0ff),   -- blue
  }
  local pal = {}
  for k = 0, WAVE_N - 1 do
    local u = k / WAVE_N * #stops
    local i, j = math.floor(u) % #stops, (math.floor(u) + 1) % #stops
    pal[k + 1] = mix(stops[i + 1], stops[j + 1], u - math.floor(u))
  end
  return pal
end

-- Colour each wave group by sampling the palette at (group + phase), so the
-- colour at any given column changes over time and the whole pattern appears to
-- travel sideways. Only WAVE_N highlight groups change per frame -- cheap.
local function paint_wave(phase)
  local pal = state.palette
  for g = 0, WAVE_N - 1 do
    local idx = g + phase
    local i0 = math.floor(idx) % WAVE_N
    local i1 = (i0 + 1) % WAVE_N
    api.nvim_set_hl(0, "SplashWave" .. g,
      { fg = mix(pal[i0 + 1], pal[i1 + 1], idx - math.floor(idx)), bold = true })
  end
end

-- Is the splash buffer currently displayed in any window?
local function shown()
  if not api.nvim_buf_is_valid(state.buf) then return false end
  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_is_valid(win) and api.nvim_win_get_buf(win) == state.buf then return true end
  end
  return false
end

local function stop_anim()
  if not state.timer then return end
  state.timer:stop()
  if not state.timer:is_closing() then state.timer:close() end
  state.timer = nil
end

local function start_anim()
  stop_anim()
  if state.art_rows == 0 then return end -- no block-art (fallback name): nothing to animate
  state.timer = vim.uv.new_timer()
  state.timer:start(0, 70, vim.schedule_wrap(function()
    if not shown() then return stop_anim() end -- hidden or wiped: stop burning CPU
    state.phase = (state.phase + 0.4) % WAVE_N
    paint_wave(state.phase)
  end))
end

-- Byte length of the UTF-8 cell starting at a given byte.
local function cell_bytes(b)
  if b < 0x80 then return 1 end
  if b < 0xE0 then return 2 end
  if b < 0xF0 then return 3 end
  return 4
end

-- Draw the splash into one window. Recomputes the art for that window's size,
-- records the recent files, and repaints the gradient at the current phase.
local function draw_in(buf, win)
  local w, h = api.nvim_win_get_width(win), api.nvim_win_get_height(win)
  local cwd = vim.fn.getcwd()
  local name = vim.fn.fnamemodify(cwd, ":t")
  if name == "" then name = cwd end

  local lines = {} -- entry is { art=, row= } or { segs = { {text,hl}, ... } }
  state.palette = wave_palette()
  local rows, face_name = art(name, w, h)
  if rows then
    state.art_rows = #rows
    for i = 1, #rows do lines[#lines + 1] = { art = rows[i], row = i - 1 } end
  else
    state.art_rows = 0
    lines[#lines + 1] = { segs = { { name, "Title" } } }
  end
  paint_wave(state.phase)

  lines[#lines + 1] = { segs = {} }
  local info = { { vim.fn.fnamemodify(cwd, ":~"), "Directory" } }
  local br = branch(cwd)
  if br then vim.list_extend(info, { { "  ·  ", "NonText" }, { "⎇ " .. br, "Special" } }) end
  -- Naming the face is the only feedback <Left>/<Right> gives, so keep it dim.
  if face_name and #faces > 1 then
    vim.list_extend(info, { { "  ·  ", "NonText" }, { face_name, "Comment" } })
  end
  lines[#lines + 1] = { segs = info }

  local list, prefix = recent(cwd, math.min(9, math.max(0, h - #lines - 3)))
  for i = 1, #state.files do state.files[i] = nil end
  if #list > 0 then
    lines[#lines + 1] = { segs = {} }
    local rel = vim.tbl_map(function(f) return f:sub(#prefix + 1) end, list)
    local width = math.max(unpack(vim.tbl_map(vim.fn.strdisplaywidth, rel)))
    for i, f in ipairs(rel) do
      state.files[i] = list[i]
      -- Pad to a common width so the list centres as one left-aligned block.
      lines[#lines + 1] = { segs = { { i .. "  ", "Identifier" }, { f .. (" "):rep(width - vim.fn.strdisplaywidth(f)), "Normal" } } }
    end
  end

  local text, marks = {}, {}
  for _ = 1, math.max(0, math.floor((h - #lines) / 2)) do text[#text + 1] = "" end
  for _, ln in ipairs(lines) do
    if ln.art then
      local width = vim.fn.strdisplaywidth(ln.art)
      local pad = math.max(0, math.floor((w - width) / 2))
      -- rowIdx is the 0-based line index: capture #text *before* pushing.
      local rowIdx, i, c = #text, 1, 0
      text[#text + 1] = (" "):rep(pad) .. ln.art
      -- Walk the row one cell at a time and colour every inked cell (anything
      -- but a space) by its diagonal position, so the wave sweeps through the
      -- glyphs instead of only down them.
      while i <= #ln.art do
        local b = ln.art:byte(i)
        local n = cell_bytes(b)
        if b ~= 0x20 then
          local group = math.floor(c + ln.row * WAVE_TILT) % WAVE_N
          marks[#marks + 1] = { rowIdx, pad + i - 1, pad + i - 1 + n, "SplashWave" .. group }
        end
        i, c = i + n, c + 1
      end
    else
      local segs = ln.segs
      local width = 0
      for _, sg in ipairs(segs) do width = width + vim.fn.strdisplaywidth(sg[1]) end
      local line = (" "):rep(math.max(0, math.floor((w - width) / 2)))
      for _, sg in ipairs(segs) do
        marks[#marks + 1] = { #text, #line, #line + #sg[1], sg[2] }
        line = line .. sg[1]
      end
      text[#text + 1] = line
    end
  end

  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, text)
  vim.bo[buf].modifiable = false
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    api.nvim_buf_set_extmark(buf, ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
  end
  api.nvim_win_set_cursor(win, { 1, 0 })
end

-- Redraw every window that shows the splash. The splash buffer can legitimately
-- appear in more than one window (e.g. a terminal opened in another tab), so
-- drawing only bufwinid(buf) left the other window stale.
local function draw()
  local buf = state.buf
  if not api.nvim_buf_is_valid(buf) then return end
  local any = false
  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_is_valid(win) and api.nvim_win_get_buf(win) == buf then
      any = true
      draw_in(buf, win)
    end
  end
  if not any then stop_anim() end
end

-- Show the splash in the current window. Idempotent: safe to call on startup or
-- after closing all buffers with <D-d>.
function M.show()
  local buf, win = api.nvim_get_current_buf(), api.nvim_get_current_win()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = "splash"
  for opt, val in pairs({
    number = false, relativenumber = false, cursorline = false, list = false, spell = false,
    wrap = false, signcolumn = "no", foldcolumn = "0", colorcolumn = "", statuscolumn = "",
  }) do
    api.nvim_set_option_value(opt, val, { scope = "local", win = win })
  end

  state.buf, state.phase = buf, 0

  -- Only the recent-file numbers; everything else is a normal Neovim buffer.
  for i = 1, 9 do
    vim.keymap.set("n", tostring(i), function()
      if state.files[i] then vim.cmd.edit(vim.fn.fnameescape(state.files[i])) end
    end, { buffer = buf, nowait = true, silent = true })
  end

  -- <Left>/<Right (or h/l) swap the banner face; the choice is kept for next time.
  for _, key in ipairs({ { "<Left>", -1 }, { "<Right>", 1 }, { "h", -1 }, { "l", 1 } }) do
    vim.keymap.set("n", key[1], function() M.cycle(key[2]) end,
      { buffer = buf, nowait = true, silent = true, desc = "Splash: banner face" })
  end

  -- Stop the shimmer as soon as the splash goes away.
  api.nvim_create_autocmd({ "BufWipeout", "BufUnload" }, { buffer = buf, callback = stop_anim })

  draw()
  start_anim()

  -- Redraw on resize / directory change / theme change, for every splash window.
  api.nvim_create_autocmd({ "VimResized", "WinResized", "DirChanged", "ColorScheme" }, {
    group = api.nvim_create_augroup("Splash", { clear = true }),
    callback = function()
      if not api.nvim_buf_is_valid(state.buf) then return true end -- removes the autocmd
      draw()
      if shown() then start_anim() end -- art row count may have changed after a resize
    end,
  })
end

-- Step through the installed banner faces and remember where we landed.
function M.cycle(delta)
  if #faces < 2 then return end
  chosen = ((chosen - 1 + delta) % #faces) + 1
  remember_face(faces[chosen].name)
  draw()
  if shown() then start_anim() end -- a taller face may need the timer back
end

-- Close every buffer except terminals (force, like <leader>d), then show the
-- splash. If the current window holds a terminal, :enew hides it (the shell
-- keeps running) so the splash has a clean buffer to draw on.
function M.close_all_and_show()
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype ~= "terminal" then
      api.nvim_buf_delete(bufnr, { force = true })
    end
  end
  if vim.bo[api.nvim_get_current_buf()].buftype == "terminal" then vim.cmd("enew") end
  M.show()
end

vim.opt.shortmess:append("I") -- the built-in intro would flash first

api.nvim_create_autocmd("StdinReadPre", { callback = function() vim.g.splash_stdin = true end })
api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    local buf = api.nvim_get_current_buf()
    if vim.fn.argc() > 0 or vim.g.splash_stdin or api.nvim_buf_get_name(buf) ~= ""
      or vim.bo[buf].modified or api.nvim_buf_line_count(buf) > 1 then
      return
    end
    M.show()
  end,
})

return M
