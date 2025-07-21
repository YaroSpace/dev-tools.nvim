local Config = require("dev-tools.config")
local Logger = require("dev-tools.logger")
local Utils = require("dev-tools.utils")

---@class Actions
---@field group string|nil - group of actions
---@field filetype string[]|nil - filetype to limit the actions group to
---@field actions Action[]|fun(): Action[] - list of actions

---@class Action
---@field name string - name of the action
---@field group string|nil - group of the action
---@field condition string|nil|fun(ctx: ActionCtx): boolean - function or pattern to match against buffer name
---@field filetype string[]|nil - filetype to limit the action to
---@field fn fun(action: ActionCtx) - function to execute the action
---@field desc string|nil - description of the action
---
---@private
---@field command? string - LSP command to execute the action
---@field title? string - formatted title of the action
---@field _is_condition? fun(acttion: ActionCtx): boolean - whether action ondition evaluates to true
---@filed _hide? boolean - whether the action should be hidden from the UI

---@class ActionCtx: Action
---@field ctx Ctx - context of the action

local M = {}

M.last_action = function() end

local function pcall_wrap(name, fn)
  return function(action)
    local status, error = xpcall(function(action)
      _ = action:_is_condition() and fn(action)
    end, debug.traceback, action)
    if not status then return Logger.error("Error executing " .. name .. ":\n" .. error, 2) end

    M.set_last_action(name, fn, action)
  end
end

M.set_last_action = function(name, fn, action)
  vim.o.operatorfunc = "v:lua.require'dev-tools.actions'.last_action"

  ---@diagnostic disable-next-line: duplicate-set-field
  M.last_action = function() end
  vim.cmd.normal("g@l")

  ---@diagnostic disable-next-line: duplicate-set-field
  M.last_action = function()
    action.ctx = require("dev-tools.lsp").get_ctx()
    pcall_wrap(name, fn)(action)
  end
end

local validate_action = function(action)
  local status, error = pcall(function()
    vim.validate("name", action.name, { "string" })
    vim.validate("group", action.group, { "string" }, true)
    vim.validate("condition", action.condition, { "function", "string" }, true)
    vim.validate("filetype", action.filetype, "table", true)
    vim.validate("fn", action.fn, "function")
    vim.validate("desc", action.desc, "string", true)
  end)

  if not status then return Logger.error("Invalid action: " .. error, 2) end

  return true
end

local function make_action(module, action)
  action = vim.deepcopy(action)

  action.group = action.group or module.group
  action.title = action.name .. " (" .. action.group:lower() .. ")"
  action.command = action.title:gsub("%W", "_"):lower()

  action.fn = pcall_wrap(action.name, action.fn)

  action.filetype = action.filetype or module.filetype
  action.condition = action.condition or module.condition or ".*"

  action._is_condition = function(action)
    return (action.filetype == nil or vim.tbl_contains(action.filetype, action.ctx.filetype))
      and (
        action.condition == nil
        or (type(action.condition) == "function" and action:condition())
        or (type(action.condition) == "string") and action.ctx.bufname:match(action.condition)
      )
  end

  action.desc = action.desc or ""

  return action
end

local function set_global_keymap(module, action)
  local keymap = Config.get_action_opts(action.group or module.group, action.name, "keymap", "global")
  if not keymap then return end

  local map = keymap[1] or keymap
  local mode = keymap.mode or "n"

  action._hide = keymap.hide

  vim.keymap.set(mode, map, function()
    action = make_action(module, action)
    action.ctx = require("dev-tools.lsp").get_ctx()
    action:fn()
  end, { desc = "Dev-tools: " .. action.name })
end

M.built_in = function()
  local builtin = Config.builtin_actions
  if builtin.exclude == true then return {} end

  local actions_path = Utils.get_plugin_path("actions")

  local modules = vim
    .iter(vim.fn.glob(actions_path .. "/**/*", false, true))
    :filter(function(path)
      return not path:find("init.lua") and vim.fn.isdirectory(path) ~= 1
    end)
    :totable()

  return vim.iter(modules):fold({}, function(acc, path)
    local module, error = loadfile(path)
    if not module then return acc, Logger.error("Error loading module " .. path .. ":\n" .. error, 2) end

    module = module()
    if not module or not type(module.actions) == "table" then return acc end

    local actions = type(module.actions) == "function" and module.actions() or module.actions
    vim.iter(actions):each(function(action)
      if not validate_action(action) then return end

      set_global_keymap(module, action)

      local tags = vim.list_extend({ action.group or module.group, action.name }, (action.filetype or module.filetype or {}))

      if vim.tbl_contains(builtin.exclude or {}, function(v)
        return vim.tbl_contains(tags, v)
      end, { predicate = true }) then return end

      if
        (builtin.include == nil or #builtin.include == 0)
        or vim.tbl_contains(builtin.include, function(v)
          return vim.tbl_contains(tags, v)
        end, { predicate = true })
      then
        acc = vim.list_extend(acc, { make_action(module, action) })
      end
    end)

    return acc
  end)
end

M.custom = function()
  local actions = type(Config.actions) == "function" and Config.actions() or Config.actions
  return vim.iter(actions):fold({}, function(acc, action)
    return vim.list_extend(acc, { make_action({ group = "Custom" }, action) })
  end)
end

M.register = function(actions)
  actions = vim.islist(actions) and actions or { actions }

  vim.iter(actions):each(function(action)
    Config.actions = vim.list_extend(Config.actions, { action })
  end)

  local cache = Config.cache
  require("dev-tools.lsp").code_actions()

  Config.cache = cache
end

---@class ActionOpts: vim.lsp.buf.code_action.Opts
---@field group? string - only show actions matching this group
---@field name? string - only show actions matching this name
---@field kind? string - only show actions matching this kind

---@param opts? ActionOpts
M.open = function(opts)
  vim.g.dev_tools_action_opts = opts or {}
  vim.lsp.buf.code_action(opts)
end

return M
