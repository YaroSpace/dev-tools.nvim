---@class Config
---@field actions Action[] - list of custom actions
---@field filetypes {include: string[], exclude: string[]} - filetypes to include/exclude

local M = {}

---@type Config
local defaults = {
  actions = {},
  filetypes = {
    include = {},
    exclude = {},
  },
}

local function merge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      merge(dst[k], v)
    else
      dst[k] = v
    end
  end

  return dst
end

M = setmetatable(defaults, {
  __index = {
    setup = function(opts)
      merge(M, opts)
    end,
  },
})

return M
