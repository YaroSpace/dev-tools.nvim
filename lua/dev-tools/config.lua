local M = {
  ---@type Action[]
  actions = {},

  filetypes = { -- filetypes for which to attach the LSP
    include = {},
    exclude = {},
  },

  builtin_actions = {
    include = {}, -- filetype/category/title of actions to include or {} to include all
    exclude = {}, -- filetype/category/title of actions to exclude or true to exclude all
  },

  builtin_opts = { -- default options for actions
    specs = {
      tree_cmd = nil, -- command to run the file tree
      test_cmd = nil, -- command to run tests
      test_tag = nil, -- command to add tags to the test command
      terminal_cmd = nil, -- function to run the terminal
    },

    debug = {
      logger = nil, -- function to log debug info
    },
  },

  action_keymaps = { -- global keymaps for actions
    {
      category = nil, -- category of the action
      title = nil, -- title of the action
      keymap = nil, -- keymap, e.g. { "<C-b>", mode = { "n", "i" } }
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
