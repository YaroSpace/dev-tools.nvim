local M = {}

local default_options = {
  title = "dev-tools",
}

local log_levels = vim.log.levels

M.log = function(message, level)
  level = level or log_levels.INFO
  local notify = vim.in_fast_event() and vim.schedule_wrap(vim.notify) or vim.notify
  notify(message, level, default_options)
end

M.info = function(message)
  M.log(message, log_levels.INFO)
end

M.warn = function(message)
  M.log(message, log_levels.WARN)
end

M.error = function(message, lines_no)
  M.log(message, log_levels.ERROR)
end

return M
