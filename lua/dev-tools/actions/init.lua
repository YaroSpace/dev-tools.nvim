local Config = require("dev-tools.config")
local Utils = require("dev-tools.utils")

---@class Actions
---@field category string - category of the action (used for filtering)
---@field actions Action[] - list of actions
---@field filter string|nil|fun(ctx: Ctx): boolean - filter to limit the action category to
---@field filetype string[]|nil - filetype to limit the action category to

---@class Action
---@field title string - title of the action (used for display)
---@field category string|nil - category of the action (used for filtering)
---@field fn fun(action: ActionCtx) - function to execute the action
---@field filter string|nil|fun(ctx: Ctx): boolean - filter to limit the action to
---@field filetype string[]|nil - filetype to limit the action to

---@class ActionCtx: Action
---@field ctx Ctx - context of the action

local M = {}

local function make_action(module, action)
  action = vim.deepcopy(action)

  action.category = action.category or module.category
  action.command = action.title:gsub("%W", "_"):lower()
  action.title = action.title .. " (" .. action.category:lower() .. ")"

  action.filter = action.filter or module.filter
  action.filetype = action.filetype or module.filetype

  action.filter = not (action.filter or action.filetype) and ".*" or action.filter

  return action
end

M.built_in = function()
  local actions_path = Utils.get_plugin_path("actions")

  local modules = vim
    .iter(vim.fn.glob(actions_path .. "/*", false, true))
    :map(function(path)
      return not path:find("init.lua") and vim.fn.fnamemodify(path, ":t:r") or nil
    end)
    :totable()

  return vim.iter(modules):fold({}, function(acc, module)
    module = require("dev-tools.actions." .. module)

    vim.iter(module.actions):each(function(action)
      acc = vim.list_extend(acc, { make_action(module, action) })
    end)

    return acc
  end)
end

M.custom = function()
  return vim.iter(Config.actions):fold({}, function(acc, action)
    return vim.list_extend(acc, { make_action({ category = "Custom" }, action) })
  end)
end

M.register = function(action)
  Config.actions = vim.list_extend(Config.actions, { action })
end

return M
