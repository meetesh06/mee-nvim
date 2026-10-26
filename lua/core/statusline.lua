-- Tiny statusline (replaces lualine): coloured text on the editor background.
--   ▌ MODE   project  branch +add ~chg -del   icon dir/file ●
--        ● rec @q  diagnostics  ● LSP  filetype  line:col
--
-- The accent bar and mode name take the mode's colour (so 'showmode' is off).
-- Icons need the Nerd Font symbols, which ghostty bundles. LSP: "● clangd"
-- when attached and idle, "◌ clangd indexing 42%" while the server reports
-- progress, nothing when no server is attached. Below 100 columns the file's
-- directory and the LSP names are dropped.
--
-- Unsaved changes: the file name turns orange with a ●, and so does the
-- line-number column of every window showing that file.

local function hl(group, text) return "%#" .. group .. "#" .. text end
local esc = function(s) return (s:gsub("%%", "%%%%")) end

local progress = {} -- client id -> latest progress text

-- mode() first char -> label, highlight suffix
local modes = {
  n = { "NORMAL", "Normal" },
  i = { "INSERT", "Insert" },
  v = { "VISUAL", "Visual" },
  V = { "V-LINE", "Visual" },
  ["\22"] = { "V-BLOCK", "Visual" },
  s = { "SELECT", "Visual" },
  S = { "S-LINE", "Visual" },
  ["\19"] = { "S-BLOCK", "Visual" },
  R = { "REPLACE", "Replace" },
  c = { "COMMAND", "Command" },
  r = { "PROMPT", "Command" },
  ["!"] = { "SHELL", "Terminal" },
  t = { "TERMINAL", "Terminal" },
}

-- Icon highlights (devicons colour on the bar background), made on the fly
-- and reset on :colorscheme.
local made = {}
local function tinted(group)
  local name = "StlIcon" .. group
  if not made[name] then
    local get = function(g) return vim.api.nvim_get_hl(0, { name = g, link = false }) end
    vim.api.nvim_set_hl(0, name, { fg = get(group).fg, bg = get("StatusLine").bg })
    made[name] = true
  end
  return name
end

-- Nerd Font glyphs, escaped so editors and copy/paste can't drop them.
local FOLDER, BRANCH = "\u{f07b}", "\u{e725}"

local function mode_group()
  local m = vim.api.nvim_get_mode().mode
  local label, group = unpack(modes[m:sub(1, 1)] or { m:upper(), "Normal" })
  if m:find("^no") then label = "PENDING" end -- after d/y/c, waiting for a motion
  return "StlMode" .. group, label
end

local function icon()
  if vim.bo.filetype == "oil" then return hl(tinted("Directory"), FOLDER) end
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then return "" end
  local name = vim.fn.expand("%:t")
  local glyph, group = devicons.get_icon(name, vim.fn.fnamemodify(name, ":e"), { default = true })
  return hl(tinted(group), glyph)
end

local function lsp_part(wide)
  local names, busy = {}, {}
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    table.insert(names, c.name)
    if progress[c.id] then table.insert(busy, c.name .. " " .. progress[c.id]) end
  end
  if #names == 0 then return "" end
  if #busy > 0 then return hl("StlLspBusy", " ◌ " .. esc(table.concat(busy, ", ")) .. " ") end
  return hl("StlLspOk", " ●" .. (wide and " " .. esc(table.concat(names, ", ")) or "") .. " ")
end

-- Directory dimmed, file name bright. Relative to the project when inside it.
local function file_part(wide)
  local name = vim.api.nvim_buf_get_name(0)
  if vim.bo.filetype == "oil" then name = require("oil").get_current_dir() or name end
  if name == "" then return hl("StlDir", " [No Name]") end
  name = vim.fn.fnamemodify(name, ":~:.")
  local dir, file = name:match("^(.*/)(.-)$")
  if not dir then dir, file = "", name end
  if file == "" then dir, file = "", dir end -- a directory (oil)
  local out = icon() .. " " .. (wide and hl("StlDir", esc(dir)) or "") .. hl(vim.bo.modified and "StlModified" or "StlFile", esc(file))
  if vim.bo.modified then out = out .. hl("StlModified", " ●") end
  if vim.bo.readonly or not vim.bo.modifiable then out = out .. hl("StlDir", " [RO]") end
  return out
end

function _G.Statusline()
  local wide = vim.o.columns >= 100
  local mode, label = mode_group()
  local gap = hl("StatusLine", "   ")

  local parts = {
    hl(mode, "▌ " .. label), gap,
    hl("StlProject", esc(vim.fn.fnamemodify(vim.fn.getcwd(), ":t"))),
  }
  local branch = vim.b.gitsigns_head
  if branch and branch ~= "" then
    table.insert(parts, hl("StlBranch", "  " .. BRANCH .. " " .. esc(branch)))
    local s = vim.b.gitsigns_status_dict or {}
    for _, d in ipairs({ { "added", "+", "StlAdd" }, { "changed", "~", "StlChange" }, { "removed", "-", "StlDelete" } }) do
      if (s[d[1]] or 0) > 0 then table.insert(parts, hl(d[3], " " .. d[2] .. s[d[1]])) end
    end
  end

  if vim.bo.filetype == "splash" then return table.concat(parts) .. hl("StatusLine", "") end -- start screen

  vim.list_extend(parts, { gap, file_part(wide), hl("StatusLine", "%=") })
  local reg = vim.fn.reg_recording()
  if reg ~= "" then table.insert(parts, hl("StlRecording", "● rec @" .. reg .. "  ")) end
  table.insert(parts, hl("StatusLine", vim.diagnostic.status() .. " "))
  table.insert(parts, lsp_part(wide))
  table.insert(parts, hl("StlMuted", " " .. vim.bo.filetype .. "   %l:%c "))
  return table.concat(parts)
end

vim.o.laststatus = 3 -- one global statusline
vim.o.showmode = false -- the coloured mode name replaces "-- INSERT --"
vim.o.statusline = "%!v:lua.Statusline()"

local group = vim.api.nvim_create_augroup("Statusline", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = function() made = {} end })
vim.api.nvim_create_autocmd({ "DiagnosticChanged", "LspAttach", "LspDetach", "ModeChanged", "RecordingEnter", "RecordingLeave" }, {
  group = group,
  callback = function() vim.schedule(function() vim.cmd.redrawstatus() end) end,
})
-- Orange gutter for unsaved files. Our two entries are added to / removed from
-- 'winhighlight' so whatever else a window maps there (oil, fzf) is kept.
local nr_map = { "LineNr:ModifiedLineNr", "CursorLineNr:ModifiedCursorLineNr" }
local function mark_modified(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    local entries = vim.tbl_filter(function(e)
      return e ~= "" and not vim.tbl_contains(nr_map, e)
    end, vim.split(vim.wo[win].winhighlight, ","))
    if vim.bo[buf].modified and vim.bo[buf].buftype == "" then vim.list_extend(entries, nr_map) end
    vim.wo[win].winhighlight = table.concat(entries, ",")
  end
end
vim.api.nvim_create_autocmd({ "BufModifiedSet", "BufWinEnter", "BufWritePost" }, {
  group = group,
  callback = function(ev) mark_modified(ev.buf) end,
})

vim.api.nvim_create_autocmd("LspProgress", {
  group = group,
  callback = function(ev)
    local v = ev.data.params.value
    if type(v) ~= "table" then return end
    if v.kind == "end" then
      progress[ev.data.client_id] = nil
    else
      local text = v.title or ""
      if v.message and v.message ~= "" then text = text .. " " .. v.message end
      if v.percentage then text = text .. " " .. v.percentage .. "%" end
      progress[ev.data.client_id] = text
    end
    vim.cmd.redrawstatus()
  end,
})
