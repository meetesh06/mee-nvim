#!/usr/bin/env bash
#
# Set up the FIGlet banner faces used by the start screen (lua/core/splash.lua).
#
#   ./setup_font.sh                       list installed faces + help
#   ./setup_font.sh list
#   ./setup_font.sh install "Small Slant" fetch a face by name
#   ./setup_font.sh Alligator             same: a bare name implies install
#   ./setup_font.sh install https://example.com/Foo.flf foo
#   ./setup_font.sh install ./downloaded/Foo.flf foo
#   ./setup_font.sh preview doom nvim
#   ./setup_font.sh remove alligator
#
# Faces are written to lua/core/fonts/, which the splash scans at startup, so a
# new face shows up in the <-/-> picker after :source $MYVIMRC (or a restart) --
# no config edit. The splash offers the widest face that fits and remembers the
# one you last picked.
#
# Bare names come from the figlet-fonts repo through the jsDelivr CDN -- about
# 370 faces there -- and any .flf URL or local path works too. (raw.githubusercontent
# is blocked on this machine, hence the CDN.)

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# The FIGlet parsing is Lua, run inside Neovim so it can use vim.system/vim.fn.
# It is fed on a file descriptor so the whole tool stays in this one file.
SPLASH_FONT_ROOT="$ROOT" nvim --headless --clean -l /dev/fd/3 "$@" 3<<'LUA'
local api = vim.api
local DIR = (vim.env.SPLASH_FONT_ROOT or ".") .. "/lua/core/fonts"
local CDN = "https://cdn.jsdelivr.net/gh/xero/figlet-fonts@main/"

-- ---------------------------------------------------------------- FIGlet ----

-- A face is { name, rows, upper, width, glyphs = { [char] = { row, ... } } }.
local function parse_flf(text, label)
  local lines = {}
  for line in (text .. "\n"):gmatch("([^\r\n]*)\r?\n") do lines[#lines + 1] = line end

  local header = lines[1] or ""
  if header:sub(1, 5) ~= "flf2a" and header:sub(1, 5) ~= "flf2b" then
    return nil, "not a FIGlet font (header starts " .. header:sub(1, 5) .. ")"
  end
  local hardblank = header:sub(6, 6)
  local height = tonumber(header:sub(7):match("%-?%d+") or "")
  if not height or height < 1 or height > 30 then return nil, "unreadable glyph height" end

  local function clean(s)
    s = s:gsub("@+$", "")
    return table.concat(vim.split(s, hardblank, { plain = true }), " ")
  end
  local function blank(s) return s:match("^ *$") ~= nil end
  local function block(i)
    local rows = {}
    for r = 0, height - 1 do rows[r + 1] = clean(lines[i + r] or "") end
    return rows
  end

  -- The header does not count comment lines reliably, so find the first glyph
  -- block instead: `height` lines ending in '@', the last of them in '@@'. The
  -- space glyph (code 32) must be blank and 'A' (65) non-blank, which pins the
  -- real start and rejects comment lines that happen to end in '@'.
  local start
  for i = 2, #lines - height * 34 do
    local ok = true
    for r = 0, height - 1 do
      if not (lines[i + r] or ""):match("@$") then ok = false break end
    end
    if ok and (lines[i + height - 1] or ""):match("@@$") then
      local space_ok, a_ok = true, false
      for _, row in ipairs(block(i)) do
        if not blank(row) then space_ok = false break end
      end
      for r = 0, height - 1 do
        if not blank(clean(lines[i + 33 * height + r] or "")) then a_ok = true break end
      end
      if space_ok and a_ok then start = i break end
    end
  end
  if not start then return nil, "could not locate the first glyph" end

  local glyphs, count = {}, 0
  for code = 32, 126 do
    local base = start + (code - 32) * height
    if base + height - 1 > #lines then break end
    glyphs[string.char(code)] = block(base)
    count = count + 1
  end
  if count < 40 then return nil, "only " .. count .. " glyphs found" end

  -- Some faces draw lowercase as uppercase; that lets the splash fold case.
  local upper = true
  for _, pair in ipairs({ { "a", "A" }, { "z", "Z" } }) do
    if vim.inspect(glyphs[pair[1]]) ~= vim.inspect(glyphs[pair[2]]) then upper = false break end
  end

  local sample = "abcdefghijklmnopqrstuvwxyz0123456789"
  local width = 0
  for _, c in ipairs(vim.split(upper and sample:upper() or sample, "", { plain = true })) do
    width = width + api.nvim_strwidth((glyphs[c] or glyphs[" "])[1])
  end

  return { name = label, rows = height, upper = upper, width = width / #sample, glyphs = glyphs }
end

local function render(face, text)
  local rows = {}
  for r = 1, face.rows do rows[r] = "" end
  for _, c in ipairs(vim.split(face.upper and text:upper() or text, "", { plain = true })) do
    local g = face.glyphs[c] or face.glyphs["?"] or face.glyphs[" "]
    for r = 1, face.rows do rows[r] = rows[r] .. g[r] end
  end
  return table.concat(rows, "\n")
end

-- ---------------------------------------------------------------- files ----

local function slug(name)
  local s = name:lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
  return s == "" and "face" or s
end

local function quote(s)
  return '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

local function emit(face, source)
  local out = {
    "-- " .. face.name .. ", a FIGlet face fetched from " .. source,
    "-- on " .. os.date("%Y-%m-%d") .. " by setup_font.sh. Refresh it with:",
    "--   ./setup_font.sh install '" .. face.name .. "'",
    "return {",
    ("  name = %s,"):format(quote(face.name)),
    "  rows = " .. face.rows .. ",",
    "  upper = " .. tostring(face.upper) .. ", -- "
      .. (face.upper and "no distinct lowercase in this face" or "this face has distinct lowercase glyphs"),
    ("  width = %.2f, -- average columns per character; orders the picker"):format(face.width),
    "  glyphs = {",
  }
  for code = 32, 126 do
    local rows = face.glyphs[string.char(code)]
    if rows then
      local parts = {}
      for _, row in ipairs(rows) do parts[#parts + 1] = quote(row) end
      out[#out + 1] = ("    [%s] = { %s },"):format(quote(string.char(code)), table.concat(parts, ", "))
    end
  end
  out[#out + 1] = "  },"
  out[#out + 1] = "}"
  return table.concat(out, "\n") .. "\n"
end

local function installed()
  local faces = {}
  for _, path in ipairs(vim.fn.glob(DIR .. "/*.lua", false, true)) do
    local chunk = loadfile(path)
    local face = chunk and chunk()
    if type(face) == "table" and face.glyphs and face.rows then
      face.file = vim.fn.fnamemodify(path, ":t:r")
      faces[#faces + 1] = face
    end
  end
  table.sort(faces, function(a, b) return (a.width or 0) > (b.width or 0) end)
  return faces
end

-- -------------------------------------------------------------- fetching ----

local function fetch(url)
  local res = vim.system({ "curl", "-fsSL", "--max-time", "30", url }, { text = true }):wait()
  if res.code ~= 0 then
    return nil, ("curl exited %d: %s"):format(res.code, (res.stderr or ""):gsub("^%s*(.-)%s*$", "%1"))
  end
  return res.stdout
end

-- Returns url, name -- or nil, name, data when `what` is a local file.
local function resolve(what)
  if what:find("://") then return what, vim.fn.fnamemodify(what, ":t"):gsub("%.flf$", "") end
  local path = vim.fn.expand(what)
  if vim.fn.filereadable(path) == 1 then
    local f = io.open(path, "rb")
    local data = f and f:read("*a") or nil
    if f then f:close() end
    return nil, vim.fn.fnamemodify(path, ":t:r"), data
  end
  local name = what:gsub("%.flf$", "")
  return CDN .. name:gsub(" ", "%%20") .. ".flf", name
end

-- ------------------------------------------------------------- commands ----

local function cmd_list()
  local faces = installed()
  if #faces == 0 then return print("no faces installed") end
  print(("  %-16s %-16s %5s %7s"):format("FILE", "NAME", "ROWS", "COLS/C"))
  for _, f in ipairs(faces) do
    print(("  %-16s %-16s %5d %7.2f"):format(f.file, f.name, f.rows, f.width or 0))
  end
  print("\n  widest first: the splash uses the widest that fits, or the one you last picked")
end

local function cmd_install(what, alias)
  local url, name, data = resolve(what)
  local source = what
  if not data then
    if not url then return print("cannot resolve " .. what) end
    io.stderr:write("fetching " .. url .. "\n")
    local err
    data, err = fetch(url)
    if not data then return print("download failed: " .. err) end
    source = url
  end
  local face, err = parse_flf(data, alias or name or what)
  if not face then return print("parse failed: " .. err) end
  face.name = alias or face.name
  vim.fn.mkdir(DIR, "p")
  local file = DIR .. "/" .. slug(face.name) .. ".lua"
  local f = io.open(file, "wb")
  if not f then return print("cannot write " .. file) end
  f:write(emit(face, source))
  f:close()
  print(("wrote %s  (%d rows, %.2f cols/char, %d glyphs)"):format(
    vim.fn.fnamemodify(file, ":."), face.rows, face.width, vim.tbl_count(face.glyphs)))
  print(render(face, "nvim"))
  print("\n  run :source $MYVIMRC in Neovim, then <-/-> on the splash to pick it")
end

local function cmd_preview(file, text)
  local chunk = loadfile(DIR .. "/" .. (file or "") .. ".lua")
  if not chunk then return print("no such face: " .. tostring(file) .. " (try `list`)") end
  print(render(chunk(), text))
end

local function cmd_remove(name)
  local file = DIR .. "/" .. slug(name) .. ".lua"
  if vim.fn.filereadable(file) ~= 1 then return print("no such face: " .. name) end
  os.remove(file)
  print("removed " .. vim.fn.fnamemodify(file, ":."))
end

local usage = [[usage: ./setup_font.sh <command>

  list                        installed faces, widest first
  install <name|url|file>     fetch a .flf into lua/core/fonts/
                              a bare name comes from the figlet-fonts repo
  remove <name>               delete an installed face
  preview <file> [text]       render text with an installed face

A bare font name is the same as `install`: ./setup_font.sh Alligator]]

-- Our own invocation is `nvim --headless --clean -l <script> <args...>`, so
-- everything after the script path is a real argument.
local argv, after = {}, false
for _, a in ipairs(vim.v.argv) do
  if after then
    argv[#argv + 1] = a
  elseif a == "-l" then
    after = true
  end
end
table.remove(argv, 1) -- the script path itself

local commands = { list = cmd_list, install = cmd_install, remove = cmd_remove, preview = cmd_preview }
local command = argv[1]
if not command then
  cmd_list()
  print("")
  print(usage)
elseif commands[command] then
  table.remove(argv, 1)
  if command == "install" and not argv[1] then
    print(usage)
  else
    commands[command](argv[1], argv[2])
  end
else
  cmd_install(command, argv[2]) -- ./setup_font.sh Alligator
end
LUA
