---@class Keymap
---@field global string|table<{[1]:string, mode: string[]}> -- global keymap
---@field picker string -- keymap for the action picker
---@field hide boolean -- hide the action from the picker

local M = {
  ---@type Action[]|fun():Action[]
  actions = {},

  filetypes = { -- filetypes for which to attach the LSP
    include = {}, -- {} to include all, except for special buftypes, e.g. nofile|help|terminal|prompt
    exclude = {},
  },

  builtin_actions = {
    include = {}, -- filetype/group/name of actions to include or {} to include all
    exclude = {}, -- filetype/group/name of actions to exclude or true to exclude all
  },

  action_opts = { -- override default options for actions
    {
      group = "Debugging",
      name = "Log vars under cursor",
      opts = {
        logger = nil, ---@type function to log debug info, default dev-tools.log
        keymap = nil, ---@type Keymap action keymap spec, e.g.
        -- {
        --   global = "<leader>dl"|{ "<leader>dl", mode = { "n", "x" } },
        --   picker = "<M-l>",
        --   hide = true,  -- hide the action from the picker
        -- }
      },
    },
    {
      group = "Specs",
      name = "Watch specs",
      opts = {
        tree_cmd = nil, ---@type string command to run the file tree, default "git ls-files -cdmo --exclude-standard"
        test_cmd = nil, ---@type string command to run tests, default "nvim -l tests/minit.lua tests --shuffle-tests -v"
        test_tag = nil, ---@type string test tag, default "wip"
        terminal_cmd = nil, ---@type function to run the terminal, default is Snacks.terminal
      },
    },
    {
      group = "Todo",
      name = "Open Todo",
      opts = {
        filename = nil, ---@type string name of the todo file, default ".todo.md"
        template = nil, ---@type string[] -- template for the todo file
      },
    },
  },

  ui = {
    override = true, -- override vim.ui.select, requires `snacks.nvim` to be included in dependencies or installed separately
    group_actions = true, -- group actions by group or LSP group
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
--- @param group string
--- @param ... string -- keys to get from the opts table
--- @return table
M.get_action_opts = function(group, name, ...)
  local args = { ... }
  local action = vim.iter(M.action_opts):find(function(action)
    return action.name == name and action.group == group
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
