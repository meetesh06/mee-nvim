-- Set leader key before anything else
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- vim.g.clipboard = "osc52"

require("core.options")
require("core.plugins") -- vim.pack: install + configure plugins
require("core.lsp")
require("core.keymaps") -- every keymap lives here; <leader>? or <leader>fk to browse them
require("core.statusline")

-- deepblue = darkblue with readable diffs/UI. Edit theme/deepblue.lua and run
-- `nvim -l scripts/gen-theme.lua` to regenerate it (plus the ghostty theme).
vim.cmd.colorscheme("deepblue")

-- Ask before quitting with unsaved changes. Replaces the old VimLeavePre
-- buffer-count warning, which could never actually stop an exit.
require("core.quit")
