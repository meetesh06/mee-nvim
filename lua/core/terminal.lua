-- Floating terminal that keeps its shell alive between toggles (replaces
-- toggleterm). Opens in normal mode: `i` to start typing, <Esc> to stop,
-- <leader>t or `q` (normal mode) hides it. The border shows which mode you're
-- in: bright green "TYPING" inside the shell, dim "NORMAL" when not.

local M = { buf = nil, win = nil }

local function style(typing)
  if not (M.win and vim.api.nvim_win_is_valid(M.win)) then return end
  local hl = typing and "TermBorderActive" or "TermBorderIdle"
  vim.wo[M.win].winhighlight = "FloatBorder:" .. hl .. ",FloatTitle:" .. hl
  vim.api.nvim_win_set_config(M.win, {
    title = typing and " terminal · TYPING (Esc to stop) " or " terminal · NORMAL (i to type) ",
    title_pos = "center",
  })
end

function M.toggle()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_hide(M.win)
    M.win = nil
    return
  end

  local fresh = not (M.buf and vim.api.nvim_buf_is_valid(M.buf))
  if fresh then M.buf = vim.api.nvim_create_buf(false, true) end

  local width = math.floor(vim.o.columns * 0.85)
  local height = math.floor(vim.o.lines * 0.8)
  M.win = vim.api.nvim_open_win(M.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2) - 1,
    title = " terminal ",
    title_pos = "center",
  })

  if fresh then
    vim.fn.jobstart(vim.o.shell, {
      term = true,
      on_exit = function() -- shell exited: close the window, start fresh next time
        if M.win and vim.api.nvim_win_is_valid(M.win) then vim.api.nvim_win_close(M.win, true) end
        if M.buf and vim.api.nvim_buf_is_valid(M.buf) then vim.api.nvim_buf_delete(M.buf, { force = true }) end
        M.buf, M.win = nil, nil
      end,
    })
    vim.keymap.set("n", "q", M.toggle, { buffer = M.buf, desc = "Hide terminal" })
    vim.api.nvim_create_autocmd("TermEnter", { buffer = M.buf, callback = function() style(true) end })
    vim.api.nvim_create_autocmd("TermLeave", { buffer = M.buf, callback = function() style(false) end })
  end
  style(false)
end

return M
