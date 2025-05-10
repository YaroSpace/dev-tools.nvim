local M = {}

---@param path string
---@return string|nil
M.get_plugin_path = function(path)
  path = ("/" .. path) or ""
  local source = debug.getinfo(1).source
  local dir_path = source:match("@(.*/)") or source:match("@(.*\\)")

  if not dir_path then return end

  return vim.fs.normalize(dir_path .. path)
end

---@param bufnr integer
---@param mode "v"|"V"
M.range_from_selection = function(bufnr, mode)
  local start = vim.fn.getpos("v")
  local end_ = vim.fn.getpos(".")

  local start_row, start_col = start[2], start[3]
  local end_row, end_col = end_[2], end_[3]

  if start_row == end_row and end_col < start_col then
    end_col, start_col = start_col, end_col
  elseif end_row < start_row then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  if mode == "V" then
    start_col = 1
    local lines = vim.api.nvim_buf_get_lines(bufnr, end_row - 1, end_row, true)
    end_col = #lines[1]
  end

  return {
    ["start"] = { start_row, start_col - 1 },
    ["end"] = { end_row, end_col - 1 },
  }
end

return M
