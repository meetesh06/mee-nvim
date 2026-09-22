local opt = vim.opt

opt.number = true          -- Show line numbers
opt.relativenumber = true  -- Relative line numbers for fast navigation
opt.tabstop = 2            -- Number of spaces a tab counts for
opt.shiftwidth = 2         -- Size of an indent
opt.expandtab = true       -- Turn tabs into spaces
opt.smartindent = true     -- Insert indents automatically
opt.termguicolors = true   -- True color support
opt.signcolumn = "yes"     -- Always show the sign column to prevent shifting text
opt.clipboard = "unnamedplus" -- Sync with system clipboard
opt.cursorline = true
opt.ignorecase = true      -- Case-insensitive search...
opt.smartcase = true       -- ...unless the pattern has a capital
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 5
opt.undofile = true        -- Keep undo history across restarts
opt.updatetime = 250
opt.timeoutlen = 300       -- which-key pops up after this many ms
opt.ttimeoutlen = 10       -- Esc takes effect after 10ms (default 50)
opt.winborder = "rounded"  -- Borders on hover/diagnostic/signature floats
opt.matchpairs:append("<:>")
opt.fillchars:append({ diff = "╱" }) -- filler rows in side-by-side diffs

-- Never lose unsaved work on an accidental :q / :qa. Instead of failing with
-- "E37: No write since last change", prompt: Save changes? [Y]es/[N]o/[C]ancel.
-- Cancel genuinely aborts the quit. Note that :q! / ZQ still discard on purpose.
opt.confirm = true

-- Treesitter code folding
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99

opt.spell = false
opt.spelllang = { "en_us" }

-- Show the project (cwd) folder name in the terminal/window title, so it's
-- easy to tell apart multiple nvim instances open in different terminal tabs.
opt.title = true
opt.titlestring = "nvim - %{fnamemodify(getcwd(), ':t')}"

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = { spacing = 2, prefix = "●" },
  float = { source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
})

-- Briefly flash yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})
