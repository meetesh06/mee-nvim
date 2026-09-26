-- Plugins, managed by Neovim's built-in vim.pack (0.12+).
--
--   :lua vim.pack.update()   update everything (review, then :write to apply)
--   nvim-pack-lock.json      pinned revisions; commit it
--
-- To remove a plugin: delete it below, then :lua vim.pack.del({ "name" }).
-- Keymaps for all of these live in lua/core/keymaps.lua.

-- Build hooks. Registered before vim.pack.add() so they also run on install.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "nvim-treesitter" and kind == "update" then
      if not ev.data.active then vim.cmd.packadd("nvim-treesitter") end
      vim.cmd("TSUpdate")
    end
  end,
})

local gh = function(repo) return "https://github.com/" .. repo end

vim.pack.add({
  gh("nvim-tree/nvim-web-devicons"),
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  { src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") }, -- tagged: ships a prebuilt fuzzy matcher
  gh("rafamadriz/friendly-snippets"),
  gh("ibhagwan/fzf-lua"),
  gh("stevearc/oil.nvim"),
  gh("stevearc/conform.nvim"),
  gh("lewis6991/gitsigns.nvim"),
  gh("sindrets/diffview.nvim"),
  gh("kylechui/nvim-surround"),
  gh("folke/which-key.nvim"),
}, { confirm = false })

-- Treesitter -----------------------------------------------------------------
-- The `main` branch only installs parsers; highlighting/indent are switched on
-- per buffer below. Needs the tree-sitter CLI (>= 0.26.1) to compile parsers.

local parsers = {
  "c", "cpp", "javascript", "typescript", "tsx", "json",
  "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline", "bash",
}
local ts = require("nvim-treesitter")
local missing = vim.tbl_filter(function(lang)
  return not vim.tbl_contains(ts.get_installed("parsers"), lang)
end, parsers)
if #missing > 0 then ts.install(missing) end -- async, no-op once installed

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
  callback = function(ev)
    -- No parser for this filetype: leave the buffer on vim regex syntax.
    if not pcall(vim.treesitter.start, ev.buf) then return end
    local lang = vim.treesitter.language.get_lang(ev.match)
    if lang and vim.treesitter.query.get(lang, "indents") then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Completion (blink.cmp) -----------------------------------------------------
-- <C-Space> open, <C-y>/<CR> accept, <Tab>/<S-Tab> or <C-n>/<C-p> move,
-- <C-e> close, <C-b>/<C-f> scroll docs, <C-k> signature help.

require("blink.cmp").setup({
  keymap = {
    preset = "default",
    ["<CR>"] = { "accept", "fallback" },
    ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
  },
  completion = {
    list = { selection = { preselect = true, auto_insert = false } },
    documentation = { auto_show = true, auto_show_delay_ms = 300 },
  },
  signature = { enabled = true },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
  fuzzy = { implementation = "prefer_rust_with_warning" },
})

-- Fuzzy finder (fzf-lua) -----------------------------------------------------
-- Files come from fd and grep from rg, so both honour .gitignore and a
-- per-project `.ignore` file (see <leader>fx). Inside the picker:
--   <A-i> toggle respecting .gitignore/.ignore, <A-h> toggle hidden files,
--   <Tab> multi-select (<CR> then fills the quickfix list), <A-q> selection to
--   quickfix, <C-s>/<C-v>/<C-t> open in split/vsplit/tab, <F1> all picker keys.

local fzf = require("fzf-lua")
fzf.setup({
  fzf_colors = true, -- follow the colorscheme
  winopts = { height = 0.85, width = 0.85, preview = { layout = "flex", flip_columns = 140 } },
})
fzf.register_ui_select()

-- File explorer (oil) ----------------------------------------------------------
-- A directory is just a buffer: rename/delete/create files by editing lines,
-- then :w. `-` goes up a directory, <CR> opens, g? shows help.
-- Split keys match fzf-lua: <C-v> vertical, <C-s> horizontal, <C-t> tab.

require("oil").setup({
  watch_for_changes = true,
  view_options = { show_hidden = true },
  float = { max_width = 0.6, max_height = 0.7 },
  keymaps = {
    ["q"] = "actions.close",
    ["<C-v>"] = { "actions.select", opts = { vertical = true } },
    ["<C-s>"] = { "actions.select", opts = { horizontal = true } },
    ["<C-h>"] = false,
  },
})

-- Formatting (conform) -------------------------------------------------------
-- <leader>cf formats the buffer (or the visual selection). Format on save is
-- off by default; <leader>uf toggles it for the session.

require("conform").setup({
  formatters_by_ft = {
    c = { "clang-format" },
    cpp = { "clang-format" },
    javascript = { "prettierd", "prettier", stop_after_first = true },
    javascriptreact = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "prettierd", "prettier", stop_after_first = true },
    json = { "prettierd", "prettier", stop_after_first = true },
    lua = { "stylua" },
    ["_"] = { "trim_whitespace" },
  },
  formatters = {
    -- Fall back to LLVM style if no project-level .clang-format exists
    ["clang-format"] = { prepend_args = { "--fallback-style=LLVM" } },
  },
  format_on_save = function(bufnr)
    if not vim.g.format_on_save then return end
    local ft = vim.bo[bufnr].filetype
    -- clang-format only: clangd formatting would be a second pass
    if ft == "c" or ft == "cpp" then return { timeout_ms = 500, lsp_format = "never" } end
    -- prettierd needs a moment to spin up its daemon on a cold start
    if ft:match("^javascript") or ft:match("^typescript") then
      return { timeout_ms = 2000, lsp_format = "fallback" }
    end
    return { timeout_ms = 500, lsp_format = "fallback" }
  end,
})

-- Git ------------------------------------------------------------------------

require("gitsigns").setup({
  signs = {
    add = { text = "┃" },
    change = { text = "┃" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
    untracked = { text = "┆" },
  },
  current_line_blame = false, -- <leader>ub toggles it
  current_line_blame_opts = { delay = 300 },
  current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
})

-- In the file panel: - or s stage/unstage file, S stage all, U unstage all,
-- X discard file's changes, cc commit staged (:GitCommit), g? all keys.
require("diffview").setup({
  enhanced_diff_hl = true,
  keymaps = {
    file_panel = {
      { "n", "cc", "<cmd>GitCommit<cr>", { desc = "Commit staged changes" } },
    },
  },
  view = {
    default = { layout = "diff2_horizontal" },
    merge_tool = { layout = "diff3_horizontal", disable_diagnostics = true },
    file_history = { layout = "diff2_horizontal" },
  },
})

-- Editing --------------------------------------------------------------------

require("nvim-surround").setup({}) -- ys{motion}{char}, ds{char}, cs{old}{new}

-- Keymap help (which-key) ----------------------------------------------------
-- Pops up after <leader>, [, ], g, z, etc. Group names are set in keymaps.lua.

require("which-key").setup({ preset = "helix" })
