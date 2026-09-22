-- Quit guard: ask before throwing away unsaved work, the way a GUI editor does.
--
-- This has to hook the *command*, not an autocmd: VimLeavePre and QuitPre fire
-- after Neovim has already committed to exiting and cannot be cancelled. By
-- running the prompt before `:qall` is ever issued, declining simply never quits.

local M = {}

-- Listed, real-file buffers with unwritten changes.
local function unsaved_buffers()
  local dirty = {}

  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    local buftype = vim.bo[info.bufnr].buftype
    if vim.bo[info.bufnr].modified and (buftype == "" or buftype == "acwrite") then
      table.insert(dirty, {
        bufnr = info.bufnr,
        name = info.name ~= "" and vim.fn.fnamemodify(info.name, ":~:.") or "[No Name]",
        named = info.name ~= "",
      })
    end
  end

  return dirty
end

---Prompt about unsaved buffers, then quit unless the user backs out.
---@param quit_cmd string command to run once the user has decided to leave
function M.guarded_quit(quit_cmd)
  local dirty = unsaved_buffers()

  if #dirty == 0 then
    vim.cmd(quit_cmd)
    return
  end

  local lines = {}
  for _, buf in ipairs(dirty) do
    table.insert(lines, "   " .. buf.name)
  end

  local choice = vim.fn.confirm(
    string.format(
      "You have %d unsaved file%s:\n\n%s\n",
      #dirty,
      #dirty > 1 and "s" or "",
      table.concat(lines, "\n")
    ),
    "&Save all and quit\n&Discard changes and quit\n&Cancel",
    3, -- default to Cancel, so a stray <CR> is never destructive
    "Question"
  )

  if choice == 1 then
    -- `:wall` cannot write a buffer that has no filename; stay put and let the
    -- user deal with it rather than quitting with the work still unsaved.
    local unnamed = vim.tbl_filter(function(buf)
      return not buf.named
    end, dirty)

    if #unnamed > 0 then
      vim.api.nvim_echo({
        { "Cannot save: ", "ErrorMsg" },
        { string.format("%d buffer(s) have no filename. Use :saveas first.", #unnamed) },
      }, true, {})
      return
    end

    local ok, err = pcall(vim.cmd, "wall")
    if not ok then
      vim.api.nvim_echo({ { "Save failed, not quitting: ", "ErrorMsg" }, { tostring(err) } }, true, {})
      return
    end

    vim.cmd(quit_cmd)
  elseif choice == 2 then
    vim.cmd(quit_cmd .. "!")
  end
  -- choice 3 (Cancel) or 0 (<Esc>): stay in the editor
end

-- These must accept a bang: typing `!` is itself what triggers the abbreviation,
-- so `:q!` arrives here as `:Quit!`. A bang means "I know, discard it" -- skip
-- the prompt entirely, exactly like the builtin.
vim.api.nvim_create_user_command("Quitall", function(opts)
  if opts.bang then
    vim.cmd("qall!")
    return
  end
  M.guarded_quit("qall")
end, { bang = true, desc = "Quit all, prompting about unsaved files" })

-- `:q` only ends the session when it is the last window of the last tab page;
-- otherwise it just closes a split and needs no prompt.
vim.api.nvim_create_user_command("Quit", function(opts)
  if opts.bang then
    vim.cmd("quit!")
    return
  end

  if vim.fn.winnr("$") == 1 and vim.fn.tabpagenr("$") == 1 then
    M.guarded_quit("quit")
  else
    vim.cmd("quit")
  end
end, { bang = true, desc = "Close window, prompting about unsaved files when it would exit" })

-- Route the everyday quit commands through the guard. The <expr> form only
-- rewrites a whole command line, so `:q somefile` or `:q!` are left alone.
local function abbrev(lhs, rhs)
  vim.keymap.set("ca", lhs, function()
    return (vim.fn.getcmdtype() == ":" and vim.fn.getcmdline() == lhs) and rhs or lhs
  end, { expr = true })
end

abbrev("q", "Quit")
abbrev("quit", "Quit")
abbrev("qa", "Quitall")
abbrev("qall", "Quitall")
abbrev("quita", "Quitall")
abbrev("quitall", "Quitall")

-- ZZ writes before quitting, so it is already safe. ZQ is an explicit discard.
vim.keymap.set("n", "<leader>q", "<cmd>Quitall<cr>", { desc = "Quit (prompt if unsaved)" })

return M
