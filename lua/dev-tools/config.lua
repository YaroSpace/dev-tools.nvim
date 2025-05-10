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

  action_opts = { -- override options for actions
    {
      category = "Debugging",
      title = "Log vars under cursor",
      opts = {
        logger = nil, -- function to log debug info
        keymap = nil, -- action keymap, e.g.
        -- {
        --   global = "<leader>dl"|{ "<leader>dl", mode = { "n", "x" } },
        --   picker = "<M-l>",
        --   hide = true,  -- hide the action from the picker
        -- }
      },
    },
    {
      category = "Specs",
      title = "Watch specs",
      opts = {
        tree_cmd = nil, -- command to run the file tree
        test_cmd = nil, -- command to run tests
        test_tag = nil, -- command to add tags to the test command
        terminal_cmd = nil, -- function to run the terminal
      },
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

--- Get action options
--- @param title string
--- @param category string
--- @return table
M.get_action_opts = function(category, title)
  local action = vim.iter(M.action_opts):find(function(action)
    return action.title == title and action.category == category
  end) or {}
  return action.opts or {}
end

M = setmetatable(M, {
  __index = {
    setup = function(opts)
      merge_opts(opts)
    end,
  },
})

return M
