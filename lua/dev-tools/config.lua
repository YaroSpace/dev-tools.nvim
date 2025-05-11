local M = {
  ---@type Action[]|fun():Action[]
  actions = {},

  filetypes = { -- filetypes for which to attach the LSP
    include = {}, -- {} to include all
    exclude = {},
  },

  builtin_actions = {
    include = {}, -- filetype/category/name of actions to include or {} to include all
    exclude = {}, -- filetype/category/name of actions to exclude or true to exclude all
  },

  action_opts = { -- override options for actions
    {
      category = "Debugging",
      name = "Log vars under cursor",
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
      name = "Watch specs",
      opts = {
        tree_cmd = nil, -- command to run the file tree
        test_cmd = nil, -- command to run tests
        test_tag = nil, -- command to add tags to the test command
        terminal_cmd = nil, -- function to run the terminal
      },
    },
  },

  ui = {
    override = true, -- override vim.ui.select
    group_actions = true, -- group actions by category or LSP group
    keymaps = { filter = "<C-b>", open_group = "<C-l>", close_group = "<C-h>" },
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
--- @param name string
--- @param category string
--- @param ... string -- keys to get from the opts table
--- @return table
M.get_action_opts = function(category, name, ...)
  local args = { ... }
  local action = vim.iter(M.action_opts):find(function(action)
    return action.name == name and action.category == category
  end) or {}

  local opts = action.opts or {}
  return #args == 0 and opts or vim.tbl_get(opts, unpack(args))
end

M = setmetatable(M, {
  __index = {
    setup = function(opts)
      merge_opts(opts)
    end,
  },
})

return M
