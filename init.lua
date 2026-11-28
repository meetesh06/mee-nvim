-- Set leader key before anything else
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("osc52cache")
require("core.options")
require("core.plugins") 
require("core.lsp")
require("core.keymaps")
require("core.statusline")

-- Switch between Deepblue by day and Neon Void by night (India Standard Time).
require("core.theme").setup()

-- Ask before quitting with unsaved changes. Replaces the old VimLeavePre
-- buffer-count warning, which could never actually stop an exit.
require("core.quit")
require("core.session")
require("core.splash")

vim.filetype.add({
  extension = {
    iripp = "iripp"
  },
  -- Forge pretty-printer dumps: out.iri/AFTER_*_PASSES.pp.iri
  pattern = {
    [".*%.pp%.iri"] = "iripp"
  }
})
