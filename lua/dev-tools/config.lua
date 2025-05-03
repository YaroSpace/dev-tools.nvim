---@class Config
---@field actions Action[] - list of custom actions
---@field filetypes {include: string[], exclude: string[]} - filetypes to include/exclude

---@type Config
local M = {
  actions = {},

  filetypes = { -- filetypes for which to attach the LSP
    include = {},
    exclude = {},
  },

  builtin_actions = {
    include = {}, -- filetype/category/title of actions to include
    exclude = {}, -- filetype/category/title of actions to exclude or true to exclude all
  },

  debug = true, -- extra debug info
}

local function merge_opts(opts)
  for k, v in pairs(opts) do
    if type(v) == "table" and type(M[k]) == "table" then
      M[k] = vim.tbl_deep_extend("force", M[k], v)
    else
      M[k] = v
    end
  end
end

M = setmetatable(M, {
  __index = {
    setup = function(opts)
      merge_opts(opts)
    end,
  },
})

return M
