local M = {}

M.get_plugin_path = function(path)
  path = ("/" .. path) or ""
  local source = debug.getinfo(1).source
  local dir_path = source:match("@(.*/)") or source:match("@(.*\\)")

  if not dir_path then return end

  return vim.fs.normalize(dir_path .. path)
end

return M
