-- Per-project sessions: open files, splits and tabs are saved on quit, one
-- session per directory. Restore with `s` on the start screen or :SessionLoad.
--
-- Only saved when nvim was started without file arguments (`nvim` or `nvim .`),
-- so a quick `nvim some/file` never overwrites the project's session.

local M = {}

-- No folds/terminal/blank: restored terminals and empty windows are just noise.
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help" }

function M.file(dir)
  local name = vim.fs.normalize(dir or vim.fn.getcwd()):gsub("[/\\:]", "%%")
  return vim.fs.joinpath(vim.fn.stdpath("state"), "sessions", name .. ".vim")
end

function M.exists() return vim.uv.fs_stat(M.file()) ~= nil end

function M.load()
  local file = M.file()
  if not vim.uv.fs_stat(file) then
    return vim.notify("No session for " .. vim.fn.getcwd(), vim.log.levels.WARN)
  end
  local ok, err = pcall(vim.cmd.source, vim.fn.fnameescape(file))
  if not ok then vim.notify("Session restore failed: " .. err, vim.log.levels.ERROR) end
end

local function has_files()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted and vim.bo[b].buftype == "" and vim.api.nvim_buf_get_name(b) ~= "" then
      return true
    end
  end
end

function M.save()
  if not has_files() then return end -- don't replace a good session with an empty one
  local file = M.file()
  vim.fn.mkdir(vim.fs.dirname(file), "p")
  vim.cmd("mksession! " .. vim.fn.fnameescape(file))
end

local project = vim.fn.argc() == 0 or (vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1)

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    if project and not vim.g.session_off then M.save() end
  end,
})

vim.api.nvim_create_user_command("SessionLoad", M.load, { desc = "Restore this directory's session" })
vim.api.nvim_create_user_command("SessionSave", M.save, { desc = "Save this directory's session now" })
vim.api.nvim_create_user_command("SessionDelete", function()
  os.remove(M.file())
  vim.g.session_off = true -- and don't re-create it when this nvim quits
  vim.notify("Session deleted")
end, { desc = "Delete this directory's session" })

return M
