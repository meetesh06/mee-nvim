-- Tiny statusline (replaces lualine):
--   project | branch +add ~chg -del | file [+]    diagnostics | LSP | filetype | line:col pct
--
-- LSP: "● clangd" when attached and idle, "◌ clangd indexing 42%" while the
-- server reports progress, nothing when no server is attached.

local function hl(group, text) return "%#" .. group .. "#" .. text end
local esc = function(s) return (s:gsub("%%", "%%%%")) end

local progress = {} -- client id -> latest progress text

local function lsp_part()
  local names, busy = {}, {}
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    table.insert(names, c.name)
    if progress[c.id] then table.insert(busy, c.name .. " " .. progress[c.id]) end
  end
  if #names == 0 then return "" end
  if #busy > 0 then return hl("StlLspBusy", " ◌ " .. esc(table.concat(busy, ", ")) .. " ") end
  return hl("StlLspOk", " ● " .. table.concat(names, ", ") .. " ")
end

function _G.Statusline()
  local parts = { hl("StlProject", " " .. esc(vim.fn.fnamemodify(vim.fn.getcwd(), ":t")) .. " ") }

  local branch = vim.b.gitsigns_head
  if branch and branch ~= "" then
    local git = "  " .. branch
    local s = vim.b.gitsigns_status_dict or {}
    for _, d in ipairs({ { "added", "+" }, { "changed", "~" }, { "removed", "-" } }) do
      if (s[d[1]] or 0) > 0 then git = git .. " " .. d[2] .. s[d[1]] end
    end
    table.insert(parts, hl("StlBranch", esc(git) .. " "))
  end

  table.insert(parts, hl("StatusLine", " %f %m%r"))
  table.insert(parts, "%=")
  table.insert(parts, vim.diagnostic.status() .. " ")
  table.insert(parts, lsp_part())
  table.insert(parts, hl("StlMuted", " " .. vim.bo.filetype .. "  %l:%c  %p%% "))
  return table.concat(parts)
end

vim.o.laststatus = 3 -- one global statusline
vim.o.statusline = "%!v:lua.Statusline()"

local group = vim.api.nvim_create_augroup("Statusline", { clear = true })
vim.api.nvim_create_autocmd({ "DiagnosticChanged", "LspAttach", "LspDetach" }, {
  group = group,
  callback = function() vim.schedule(function() vim.cmd.redrawstatus() end) end,
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
