-- Language servers, configured with Neovim's built-in vim.lsp.config (no
-- lspconfig/mason). The binaries come from the system; see setup.sh.
-- blink.cmp adds its completion capabilities to every server automatically.
--
-- Built-in LSP keymaps (Neovim 0.11+): grn rename, gra code action,
-- grr references, gri implementation, grt type definition, gO document symbols,
-- K hover, <C-s> signature help (insert). Extra ones are in keymaps.lua.

-- Buffers whose name carries a scheme (diffview://, gitsigns://, oil://, ...)
-- are not on disk. diffview clears 'buftype' for the staged version of a file,
-- so without this clangd attaches to a diffview:// buffer and rejects every
-- request with "clangd only supports 'file' URI scheme for workspace files".
local function is_file_buf(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name ~= "" and not name:match("^%a[%w+.-]*://")
end

-- root_dir that never calls on_dir for a non-file buffer, so the server never
-- attaches to it.
local function root(markers)
  return function(bufnr, on_dir)
    if is_file_buf(bufnr) then on_dir(vim.fs.root(bufnr, markers) or vim.fn.getcwd()) end
  end
end

vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
    "--function-arg-placeholders",
    "--fallback-style=llvm",
    "--query-driver=/usr/bin/g++,/usr/bin/gcc,/usr/bin/c++",
    "--log=error", -- keep ~/.local/state/nvim/lsp.log small
  },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_dir = root({
    ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json",
    "compile_flags.txt", "configure.ac", ".git",
  }),
  init_options = { fallbackFlags = { "-std=c++20" } },
  capabilities = { offsetEncoding = { "utf-8", "utf-16" } },
})

vim.lsp.config("vtsls", {
  cmd = { "vtsls", "--stdio" },
  filetypes = {
    "javascript", "javascriptreact", "javascript.jsx",
    "typescript", "typescriptreact", "typescript.tsx",
  },
  root_dir = root({ "tsconfig.json", "jsconfig.json", "package.json", ".git" }),
  init_options = { hostInfo = "neovim" },
})

vim.lsp.enable({ "clangd", "vtsls" })

-- Restart servers gracefully: stop, wait, re-attach (the same way
-- vim.lsp.enable() attaches). The built-in :lsp restart kills clangd, which
-- then complains "quit with exit code 1".
local function restart(clients, before_start)
  for _, c in ipairs(clients) do c:stop() end
  vim.wait(5000, function()
    return vim.iter(clients):all(function(c) return c:is_stopped() end)
  end)
  if before_start then before_start() end
  vim.cmd.doautoall("nvim.lsp.enable FileType")
end

vim.api.nvim_create_user_command("LspRestart", function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then return vim.notify("No LSP attached to this buffer", vim.log.levels.WARN) end
  restart(clients)
  vim.notify("Restarted " .. table.concat(vim.tbl_map(function(c) return c.name end, clients), ", "))
end, { desc = "Restart the language servers attached to this buffer" })

-- Wipe clangd's on-disk index (<root>/.cache/clangd, or next to a
-- compile_commands.json one folder down, e.g. build/) and start it fresh.
vim.api.nvim_create_user_command("ClangdResetIndex", function()
  local clients = vim.lsp.get_clients({ name = "clangd" })
  local root = clients[1] and clients[1].root_dir or vim.fn.getcwd()
  local dirs = vim.list_extend(vim.fn.glob(root .. "/.cache/clangd", false, true),
    vim.fn.glob(root .. "/*/.cache/clangd", false, true))
  if #dirs == 0 then return vim.notify("No clangd index found under " .. root, vim.log.levels.WARN) end
  local list = table.concat(vim.tbl_map(function(d) return "   " .. vim.fn.fnamemodify(d, ":~") end, dirs), "\n")
  if vim.fn.confirm("Delete clangd index and restart?\n\n" .. list .. "\n", "&Yes\n&No", 2) ~= 1 then return end

  restart(clients, function()
    for _, d in ipairs(dirs) do vim.fn.delete(d, "rf") end
  end)
  vim.cmd.redraw()
  vim.notify("clangd index deleted; re-indexing")
end, { desc = "Delete clangd's background index and restart it" })
