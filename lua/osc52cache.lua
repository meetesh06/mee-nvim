-- osc52cache.lua
-- Clipboard for headless Neovim + --remote-ui over SSH (Ghostty).
-- Copy:  sent to the Mac clipboard via OSC 52 (nvim_ui_send reaches remote UIs).
-- Paste: `p` uses the last Neovim yank; Cmd+V pastes the Mac clipboard.
-- The terminal is never asked to send the clipboard back, because large
-- replies over SSH can be misread as keystrokes.

local osc52 = require("vim.ui.clipboard.osc52")

local cache = { lines = { "" }, regtype = "v" }

local function copy(reg)
  local send = osc52.copy(reg)
  return function(lines, regtype)
    cache.lines, cache.regtype = lines, regtype
    send(lines, regtype)
  end
end

local function paste()
  return { cache.lines, cache.regtype }
end

vim.g.clipboard = {
  name = "OSC 52 (copy only)",
  copy  = { ["+"] = copy("+"), ["*"] = copy("*") },
  paste = { ["+"] = paste,     ["*"] = paste },
}
vim.opt.clipboard = "unnamedplus"
