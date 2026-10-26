-- Start screen for a bare `nvim`: the project (cwd) name in big block letters,
-- scaled to fill the window, plus git branch, recent files in this project
-- and a few keys. No plugin; the buffer is wiped as soon as you open a file.
--
--   1-9 open a recent file   f find   g grep   r recent   e explorer
--   n   new buffer           q quit   s restore session (if this project has one)

local api = vim.api
local ns = api.nvim_create_namespace("splash")

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

local function chars(text) return vim.fn.split(text:upper(), "\\zs") end

-- Each pixel is 2s cells wide and s rows tall (cells are about twice as tall
-- as they are wide, so letters stay roughly square).
local function render(text, s)
  local rows = {}
  for r = 1, 5 do
    local parts = vim.tbl_map(function(c) return (font[c] or font["?"])[r] end, chars(text))
    local row = table.concat(parts, "."):gsub("#", ("█"):rep(2 * s)):gsub("%.", (" "):rep(2 * s))
    for _ = 1, s do rows[#rows + 1] = row end
  end
  return rows
end

-- Largest scale that fits, or nil if even scale 1 is too wide.
local function art(text, w, h)
  local px = 0
  for _, c in ipairs(chars(text)) do px = px + #(font[c] or font["?"])[1] + 1 end
  for s = 4, 1, -1 do
    if (px - 1) * 2 * s <= w - 4 and 5 * s <= h * 0.5 then return render(text, s) end
  end
end

-- One highlight per art row, fading from Title to Directory.
local function gradient(n)
  local function fg(name, default) return api.nvim_get_hl(0, { name = name, link = false }).fg or default end
  local a, b = fg("Title", 0xff80ff), fg("Directory", 0x5fd7d7)
  for i = 1, n do
    local t, c = n > 1 and (i - 1) / (n - 1) or 0, 0
    for _, shift in ipairs({ 65536, 256, 1 }) do
      local x, y = math.floor(a / shift) % 256, math.floor(b / shift) % 256
      c = c + math.floor(x + (y - x) * t + 0.5) * shift
    end
    api.nvim_set_hl(0, "SplashArt" .. i, { fg = c, bold = true })
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

local function draw(buf, files)
  local win = vim.fn.bufwinid(buf)
  if win == -1 then return end
  local w, h = api.nvim_win_get_width(win), api.nvim_win_get_height(win)
  local cwd = vim.fn.getcwd()
  local name = vim.fn.fnamemodify(cwd, ":t")
  if name == "" then name = cwd end

  local lines = {} -- each line is a list of { text, hl } segments
  local rows = art(name, w, h)
  if rows then
    gradient(#rows)
    for i, row in ipairs(rows) do lines[#lines + 1] = { { row, "SplashArt" .. i } } end
  else
    lines[#lines + 1] = { { name, "Title" } }
  end

  lines[#lines + 1] = {}
  local info = { { vim.fn.fnamemodify(cwd, ":~"), "Comment" } }
  local br = branch(cwd)
  if br then vim.list_extend(info, { { "  ·  ", "NonText" }, { "⎇ " .. br, "Special" } }) end
  lines[#lines + 1] = info

  local list, prefix = recent(cwd, math.min(9, math.max(0, h - #lines - 6)))
  for i = 1, #files do files[i] = nil end
  if #list > 0 then
    lines[#lines + 1] = {}
    local rel = vim.tbl_map(function(f) return f:sub(#prefix + 1) end, list)
    local width = math.max(unpack(vim.tbl_map(vim.fn.strdisplaywidth, rel)))
    for i, f in ipairs(rel) do
      files[i] = list[i]
      -- Pad to a common width so the list centres as one left-aligned block.
      lines[#lines + 1] = { { i .. "  ", "Number" }, { f .. (" "):rep(width - vim.fn.strdisplaywidth(f)), "Normal" } }
    end
  end

  lines[#lines + 1] = {}
  local hints, keys = {}, { { "f", "find" }, { "g", "grep" }, { "r", "recent" }, { "e", "explore" }, { "n", "new" }, { "q", "quit" } }
  if require("core.session").exists() then table.insert(keys, 1, { "s", "session" }) end
  for _, k in ipairs(keys) do
    vim.list_extend(hints, { { k[1], "Special" }, { " " .. k[2] .. "   ", "Comment" } })
  end
  hints[#hints][1] = hints[#hints][1]:gsub("%s+$", "")
  lines[#lines + 1] = hints

  local text, marks = {}, {}
  for _ = 1, math.max(0, math.floor((h - #lines) / 2)) do text[#text + 1] = "" end
  for _, segs in ipairs(lines) do
    local width = 0
    for _, s in ipairs(segs) do width = width + vim.fn.strdisplaywidth(s[1]) end
    local line = (" "):rep(math.max(0, math.floor((w - width) / 2)))
    for _, s in ipairs(segs) do
      marks[#marks + 1] = { #text, #line, #line + #s[1], s[2] }
      line = line .. s[1]
    end
    text[#text + 1] = line
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

local function open()
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

  local files = {}
  local function map(lhs, rhs) vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, silent = true }) end
  local fzf = function(cmd, opts) return function() require("fzf-lua")[cmd](opts) end end
  map("f", fzf("files"))
  map("g", fzf("live_grep"))
  map("r", fzf("oldfiles", { cwd_only = true }))
  map("e", function() require("oil").open() end)
  map("n", "<cmd>enew<cr>")
  map("s", function() require("core.session").load() end)
  map("q", "<cmd>qa<cr>")
  for i = 1, 9 do
    map(tostring(i), function()
      if files[i] then vim.cmd.edit(vim.fn.fnameescape(files[i])) end
    end)
  end

  draw(buf, files)
  api.nvim_create_autocmd({ "VimResized", "WinResized", "DirChanged", "ColorScheme" }, {
    group = api.nvim_create_augroup("Splash", { clear = true }),
    callback = function()
      if not api.nvim_buf_is_valid(buf) then return true end -- removes the autocmd
      draw(buf, files)
    end,
  })
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
    open()
  end,
})
