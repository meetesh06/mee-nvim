-- Every keymap in one place. Forgot one?
--   <leader>?   which-key: all keymaps, grouped (or just pause after <leader>, [, ], g)
--   <leader>fk  fuzzy-search every keymap by key or description
--
-- Changed from the old config (a shorter map that is also a prefix of a longer
-- one makes Neovim wait 'timeoutlen' before running it):
--   <leader>f  format        -> <leader>cf   (was blocking <leader>ff/fg/...)
--   <leader>tb blame toggle  -> <leader>ub   (were blocking <leader>t terminal)
--   <leader>th inlay hints   -> <leader>uh
--   <leader>td deleted hunks -> <leader>ud
--   <leader>a  aerial        -> <leader>a is now a symbol picker; [a/]a, <leader>an gone

local map = vim.keymap.set
local fzf = function(picker, opts)
  return function() require("fzf-lua")[picker](opts) end
end

require("which-key").add({
  { "<leader>f", group = "find" },
  { "<leader>c", group = "code" },
  { "<leader>g", group = "git (diffview)" },
  { "<leader>h", group = "hunks" },
  { "<leader>u", group = "toggles" },
})

map("n", "<leader>?", function() require("which-key").show({ global = true }) end, { desc = "Show all keymaps" })

-- Find -----------------------------------------------------------------------
map("n", "<leader>ff", fzf("files"), { desc = "Find files" })
map("n", "<leader>fg", fzf("live_grep"), { desc = "Grep project" })
map("n", "<leader>fw", fzf("grep_cword"), { desc = "Grep word under cursor" })
map("v", "<leader>fw", fzf("grep_visual"), { desc = "Grep selection" })
map("n", "<leader>fb", fzf("buffers"), { desc = "Find buffers" })
map("n", "<leader>fo", fzf("oldfiles", { cwd_only = true }), { desc = "Recent files (this project)" })
map("n", "<leader>fk", fzf("keymaps"), { desc = "Find keymaps" })
map("n", "<leader>fh", fzf("helptags"), { desc = "Find help" })
map("n", "<leader>fd", fzf("diagnostics_workspace"), { desc = "Diagnostics (project)" })
map("n", "<leader>fs", fzf("lsp_live_workspace_symbols"), { desc = "Symbols (project)" })
map("n", "<leader>fr", fzf("resume"), { desc = "Resume last search" })
map("n", "<leader>/", fzf("blines"), { desc = "Search in buffer" })
map("n", "<leader>a", function()
  -- LSP symbols when a server is attached, otherwise treesitter's
  local lsp = #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/documentSymbol" }) > 0
  require("fzf-lua")[lsp and "lsp_document_symbols" or "treesitter"]()
end, { desc = "Symbols (this file)" })

-- Per-project search exclusions: fd and rg read <project>/.ignore
-- (gitignore syntax). Keep it private with: echo .ignore >> .git/info/exclude
local function ignore_file()
  return (vim.fs.root(0, ".git") or vim.fn.getcwd()) .. "/.ignore"
end
map("n", "<leader>fx", function()
  local root = vim.fs.dirname(ignore_file())
  local dir = vim.bo.filetype == "oil" and require("oil").get_current_dir() or vim.fn.expand("%:p:h")
  local rel = vim.fs.relpath(root, dir or "") or ""
  vim.ui.input({ prompt = "Exclude from search (gitignore syntax): ", default = rel ~= "." and rel .. "/" or "" },
    function(pattern)
      if not pattern or pattern == "" then return end
      vim.fn.writefile({ pattern }, ignore_file(), "a")
      vim.notify("Added " .. pattern .. " to " .. vim.fn.fnamemodify(ignore_file(), ":~:."))
    end)
end, { desc = "Exclude folder from search (.ignore)" })
map("n", "<leader>fX", function() vim.cmd.edit(ignore_file()) end, { desc = "Edit search exclusions (.ignore)" })

-- Files / buffers / windows --------------------------------------------------
map("n", "<leader>e", function() require("oil").toggle_float() end, { desc = "File explorer (float)" })
map("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })

-- Close all buffers except terminals (force, no "unsaved changes?" prompts).
-- Includes unlisted buffers too, since gitsigns diff views are created unlisted.
map("n", "<leader>d", function()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype ~= "terminal" then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end
end, { desc = "Delete all buffers except terminals (force)" })

-- Close every buffer except the current one (and terminals)
map("n", "<leader>D", function()
  local current = vim.api.nvim_get_current_buf()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if bufnr ~= current and vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype ~= "terminal" then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end
end, { desc = "Delete all buffers except the current one (force)" })

-- Toggle full screen split
map("n", "<leader>z", function()
  if vim.fn.tabpagenr("$") > 1 and vim.fn.tabpagenr() == vim.fn.tabpagenr("$") then
    vim.cmd("tabclose")
  else
    vim.cmd("tab split")
  end
end, { desc = "Toggle fullscreen for tab" })

map("n", "<Esc>", "<cmd>nohlsearch<cr><Esc>", { desc = "Clear search highlight" })

-- Terminal -------------------------------------------------------------------
map("n", "<leader>t", function() require("core.terminal").toggle() end, { desc = "Toggle floating terminal" })
map("t", "<Esc>", [[<C-\><C-n>]], { desc = "Escape terminal mode" })

-- Diagnostics ----------------------------------------------------------------
local jump = function(count, severity)
  return function() vim.diagnostic.jump({ count = count, severity = severity, float = true }) end
end
map("n", "<leader>x", vim.diagnostic.open_float, { desc = "Show line diagnostics" })
map("n", "[d", jump(-1), { desc = "Previous diagnostic" })
map("n", "]d", jump(1), { desc = "Next diagnostic" })
map("n", "[e", jump(-1, vim.diagnostic.severity.ERROR), { desc = "Previous error" })
map("n", "]e", jump(1, vim.diagnostic.severity.ERROR), { desc = "Next error" })

-- Code / LSP -----------------------------------------------------------------
-- Built in and always available: grn rename, gra action, grr references,
-- gri implementation, grt type def, gO outline, K hover.
map({ "n", "v" }, "<leader>cf", function() require("conform").format({ async = true }) end,
  { desc = "Format buffer or range" })

map("n", "<leader>cR", "<cmd>LspRestart<cr>", { desc = "Restart LSP" })
map("n", "<leader>cI", "<cmd>ClangdResetIndex<cr>", { desc = "Reset clangd index (rebuild cache)" })
map("n", "<leader>cL", "<cmd>checkhealth vim.lsp<cr>", { desc = "LSP info (attached servers, logs)" })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local function bmap(lhs, rhs, desc) map("n", lhs, rhs, { buffer = ev.buf, desc = desc }) end
    bmap("gd", vim.lsp.buf.definition, "Go to definition")
    bmap("gD", vim.lsp.buf.declaration, "Go to declaration")
    bmap("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
    bmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
    bmap("<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>", "Switch source/header (C/C++)")
  end,
})

-- clangd's source/header switch, which lspconfig used to provide
vim.api.nvim_create_user_command("LspClangdSwitchSourceHeader", function()
  local client = vim.lsp.get_clients({ bufnr = 0, name = "clangd" })[1]
  if not client then return vim.notify("clangd is not attached", vim.log.levels.WARN) end
  client:request("textDocument/switchSourceHeader", vim.lsp.util.make_text_document_params(0), function(err, uri)
    if err or not uri then return vim.notify("No matching source/header", vim.log.levels.INFO) end
    vim.cmd.edit(vim.uri_to_fname(uri))
  end, 0)
end, { desc = "Switch between C/C++ source and header" })

-- Toggles --------------------------------------------------------------------
map("n", "<leader>uh", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, { desc = "Toggle inlay hints" })
map("n", "<leader>ub", function() require("gitsigns").toggle_current_line_blame() end, { desc = "Toggle line blame" })
map("n", "<leader>ud", function() require("gitsigns").toggle_deleted() end, { desc = "Toggle deleted hunks" })
map("n", "<leader>uf", function()
  vim.g.format_on_save = not vim.g.format_on_save
  vim.notify("Format on save " .. (vim.g.format_on_save and "on" or "off"))
end, { desc = "Toggle format on save" })
map("n", "<leader>uw", "<cmd>set wrap!<cr>", { desc = "Toggle line wrap" })
map("n", "<leader>us", "<cmd>set spell!<cr>", { desc = "Toggle spell check" })

-- Git hunks (gitsigns) -------------------------------------------------------
local gs = function(fn, ...)
  local args = { ... }
  return function() require("gitsigns")[fn](unpack(args)) end
end
map("n", "]h", function()
  if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else require("gitsigns").nav_hunk("next") end
end, { desc = "Next git hunk" })
map("n", "[h", function()
  if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else require("gitsigns").nav_hunk("prev") end
end, { desc = "Previous git hunk" })
map("n", "<leader>hs", gs("stage_hunk"), { desc = "Stage hunk" })
map("n", "<leader>hr", gs("reset_hunk"), { desc = "Reset hunk" })
map("n", "<leader>hS", gs("stage_buffer"), { desc = "Stage buffer" })
map("n", "<leader>hu", gs("undo_stage_hunk"), { desc = "Undo stage hunk" })
map("n", "<leader>hR", gs("reset_buffer"), { desc = "Reset buffer" })
map("n", "<leader>hp", gs("preview_hunk"), { desc = "Preview hunk" })
map("n", "<leader>hb", gs("blame_line", { full = true }), { desc = "Blame line (popup)" })
map("n", "<leader>hd", gs("diffthis"), { desc = "Diff against index" })
map("n", "<leader>hD", gs("diffthis", "~1"), { desc = "Diff against last commit" })
map("v", "<leader>hs", function() require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
  { desc = "Stage selected lines" })
map("v", "<leader>hr", function() require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
  { desc = "Reset selected lines" })
map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select git hunk" })

-- Git (diffview) -------------------------------------------------------------
-- Reuse an open diff panel (switch to its tab and refresh) instead of opening
-- a second one. g<Tab> jumps back to the previous tab.
map("n", "<leader>gd", function()
  local DiffView = require("diffview.scene.views.diff.diff_view").DiffView
  for _, view in ipairs(require("diffview.lib").views) do
    if view:instanceof(DiffView) and vim.api.nvim_tabpage_is_valid(view.tabpage) then
      vim.api.nvim_set_current_tabpage(view.tabpage)
      return vim.cmd("DiffviewRefresh")
    end
  end
  vim.cmd("DiffviewOpen")
end, { desc = "Diff working tree (reuse if open)" })
map("n", "<leader>gc", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "Current file history" })
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "Branch / repo history" })
map("n", "<leader>gf", "<cmd>DiffviewToggleFiles<cr>", { desc = "Toggle diffview file panel" })
map("n", "<leader>gC", "<cmd>GitCommit<cr>", { desc = "Commit staged changes" })
map("n", "<leader>gs", fzf("git_status"), { desc = "Changed files (picker)" })
map("n", "<leader>gl", fzf("git_commits"), { desc = "Commit log (picker)" })

-- Commit what's staged, with a one-line message. Also `cc` in the diffview
-- file panel (see plugins.lua). For a multi-line message use `git commit`
-- in the terminal (<leader>t).
vim.api.nvim_create_user_command("GitCommit", function()
  local root = vim.fs.root(0, ".git") or vim.fn.getcwd()
  local staged = vim.system({ "git", "diff", "--cached", "--name-only" }, { cwd = root, text = true }):wait()
  if staged.code ~= 0 then return vim.notify(staged.stderr, vim.log.levels.ERROR) end
  local files = vim.split(vim.trim(staged.stdout), "\n", { trimempty = true })
  if #files == 0 then return vim.notify("Nothing staged (stage with - / S in the diff panel)", vim.log.levels.WARN) end

  vim.ui.input({ prompt = ("Commit %d file%s: "):format(#files, #files > 1 and "s" or "") }, function(msg)
    if not msg or vim.trim(msg) == "" then return end
    vim.system({ "git", "commit", "-m", msg }, { cwd = root, text = true }, vim.schedule_wrap(function(res)
      if res.code ~= 0 then -- e.g. a pre-commit hook failed
        return vim.notify("Commit failed:\n" .. res.stdout .. res.stderr, vim.log.levels.ERROR)
      end
      vim.notify(vim.split(res.stdout, "\n")[1])
      pcall(vim.cmd, "DiffviewRefresh")
    end))
  end)
end, { desc = "Commit staged changes" })

-- <leader>q (guarded quit) is defined in lua/core/quit.lua
