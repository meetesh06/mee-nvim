-- Fold Iridium PP dumps: level 1 per container (function/method/... header
-- at column 0), level 2 per basic block ("  BBn {scope: N} [...]:").

local function isHeader(l)
  return l:match("^%S") and not l:match("^file ")
end

local function isBB(l)
  return l:match("^  BB%d+") ~= nil
end

function _G.IrippFoldExpr(lnum)
  local line = vim.fn.getline(lnum)
  if line:match("^file ") then return "0" end
  if isHeader(line) then return ">1" end
  if isBB(line) then return ">2" end
  if line == "" then
    -- The blank line before a header/BB closes the previous fold
    local next = vim.fn.getline(lnum + 1)
    if isHeader(next) or next:match("^file ") then return "0" end
    if isBB(next) then return "1" end
  end
  return "="
end

vim.wo[0][0].foldmethod = "expr"
vim.wo[0][0].foldexpr = "v:lua.IrippFoldExpr(v:lnum)"
