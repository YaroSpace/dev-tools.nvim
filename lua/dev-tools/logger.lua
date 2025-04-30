local Config = require("dev-tools.config")

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
  local lines = vim.split(message, "\n")

  lines_no = Config.debug and #lines or lines_no or 1
  message = table.concat(lines, "\n", 1, lines_no)

  M.log(message, log_levels.ERROR)
end

return M
