local Actions = require("dev-tools.actions")
local Config = require("dev-tools.config")
local Edit = require("dev-tools.edit")
local Logger = require("dev-tools.logger")
local Pickers = require("dev-tools.pickers")

local M = {
  actions = {},
  commands = {},
}

---@class Ctx
---@field buf number - buffer number
---@field win number - window number
---@field row number - current line number
---@field col number - current column number
---@field line string - current line
---@field ts_node TSNode|nil - current TS node
---@field ts_type string|nil - type of the current TS node
---@field ts_range table<number, number, number, number>|nil - range of the current TS node
---@field bufname string - full path to file in buffer
---@field root string - root directory of the file
---@field filetype string - filetype
---@field range Range|nil - range of the current selection
---@field edit Edit - edititng functions

---@class Range
---@field start {line: number, character: number} - start position of the range
---@field end {line: number, character: number} - end position of the range
---@field rc table<number, number, number, number> - row/col format

---@return ActionCtx
local function get_ctx(params)
  if not (params and params.textDocument) then return {} end

  local buf = vim.uri_to_bufnr(params.textDocument.uri)
  local cursor = vim.api.nvim_win_get_cursor(vim.fn.bufwinid(buf))
  local row = params.range and params.range.start.line or cursor[1]
  local col = params.range and params.range.start.character or cursor[2]
  local node = vim.treesitter.get_node()

  local file = vim.uri_to_fname(params.textDocument.uri)
  local root = vim.fs.root(file, { ".git", ".gitignore" }) or ""

  if params.range then
    params.range.rc = {
      params.range.start.line,
      params.range.start.character,
      params.range["end"].line,
      params.range["end"].character,
    }
  end

  local ctx = {
    buf = buf,
    win = vim.fn.win_findbuf(buf)[1],
    row = row,
    col = col,
    line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1],
    ts_type = node and node:type() or nil,
    ts_range = node and { node:range() },
    bufname = file,
    root = root,
    filetype = vim.api.nvim_get_option_value("filetype", { buf = buf }),
    range = params.range,
  }

  ctx.edit = setmetatable(ctx, {
    __index = function(t, k)
      if k == "ts_node" then return node end
      return Edit[k] or rawget(t, k)
    end,
  })

  return ctx
end

local function update_lsp_commands()
  vim.iter(M.actions):each(function(action)
    M.commands[action.command] = action.fn
  end)
end

---@param ctx Ctx|nil
local function code_actions(ctx)
  local built_in = Actions.built_in()
  local custom = Actions.custom()

  if not (M.actions and Config.cache) then
    M.actions = vim.list_extend(custom, built_in)
    update_lsp_commands()
  end

  if not ctx then return M.actions end

  return vim
    .iter(M.actions)
    :filter(function(action)
      action.ctx = ctx
      return (action.filetype == nil or vim.tbl_contains(action.filetype, ctx.filetype))
        and (
          not action.filter
          or (type(action.filter) == "function" and action.filter(ctx))
          or (type(action.filter) == "string") and ctx.bufname:match(action.filter)
        )
    end)
    :totable()
end

local function initialize()
  return {
    capabilities = {
      codeActionProvider = true,
    },
  }
end

local handlers = {
  ["initialize"] = initialize,
  ["textDocument/codeAction"] = code_actions,
  ["shutdown"] = function() end,
}

local function new_server()
  local function server(dispatchers)
    local closing = false
    local srv = {}

    function srv.request(method, params, handler)
      local status, error = xpcall(function()
        local ctx = get_ctx(params)
        _ = handlers[method] and handler(nil, handlers[method](ctx))
      end, debug.traceback)

      if not status then Logger.error("Error in LSP request: " .. error) end
      return true
    end

    function srv.notify(method, _)
      if method == "exit" then dispatchers.on_exit(0, 15) end
    end

    function srv.is_closing()
      return closing
    end

    function srv.terminate()
      closing = true
    end

    return srv
  end

  return server
end

M.start = function(buf, ft)
  if vim.tbl_contains(Config.filetypes.exclude or {}, ft) then return end
  if not vim.tbl_contains(Config.filetypes.include or {}, ft) then return end

  M.start_lsp(buf)
  _ = Config.override_ui and Pickers.stub()
end

function M.start_lsp(buf)
  local server = new_server()

  local dispatchers = {
    on_exit = function(code, signal)
      Logger.error("Dev-tools server exited with code " .. code .. " and signal " .. signal)
    end,
  }

  local client_id = vim.lsp.get_clients { name = "dev-tools" }

  M.actions = code_actions()

  client_id = vim.lsp.start({
    name = "dev-tools",
    cmd = server,
    root_dir = "",
    bufnr = buf,
    on_init = function(_client) end,
    on_exit = function(_code, _signal) end,
    commands = M.commands,
  }, dispatchers)

  return client_id
end

return M
