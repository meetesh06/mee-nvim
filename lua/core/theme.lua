local M = {}

local IST_OFFSET = 5 * 60 * 60 + 30 * 60
local timer = vim.uv.new_timer()

function M.theme_for_epoch(epoch)
  local hour = os.date("!*t", epoch + IST_OFFSET).hour
  return hour >= 9 and hour < 20 and "deepblue" or "neonvoid"
end

local function seconds_until_switch(epoch)
  local t = os.date("!*t", epoch + IST_OFFSET)
  local now = t.hour * 3600 + t.min * 60 + t.sec
  local target
  if now < 9 * 3600 then
    target = 9 * 3600
  elseif now < 20 * 3600 then
    target = 20 * 3600
  else
    target = 33 * 3600
  end
  return target - now
end

local function schedule()
  timer:start(seconds_until_switch(os.time()) * 1000, 0, vim.schedule_wrap(function()
    M.apply()
    schedule()
  end))
end

function M.apply()
  local theme = M.theme_for_epoch(os.time())
  if vim.g.colors_name ~= theme then vim.cmd.colorscheme(theme) end
end

function M.setup()
  M.apply()
  schedule()
end

return M
