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

  builtin_opts = { -- default options for actions
    specs = {
      tree_cmd = nil,
      test_cmd = nil,
      test_tag = nil,
      terminal_cmd = nil,
    },

    debug = {
      logger = nil,
    },
  },

  override_ui = true, -- override vim.ui.select

  ui = {
    keymaps = { filter = "<C-b>" },
  },

  debug = false, -- extra debug info
  cache = true, -- cache the actions on start
}

local function merge_opts(opts)
  for k, v in pairs(opts or {}) do
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
