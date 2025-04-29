local Config = require("dev-tools.config")
local Logger = require("dev-tools.logger")

local M = {}

local function extract_variable()
  --
end

local function get_ctx(params)
  if not (params and params.textDocument) then return {} end

  local buf = vim.uri_to_bufnr(params.textDocument.uri)
  local cursor = vim.api.nvim_win_get_cursor(vim.fn.bufwinid(buf))
  local file = vim.uri_to_fname(params.textDocument.uri)

  return {
    buf = buf,
    lnum = params.range and params.range.start.line or cursor[1],
    col = params.range and params.range.start.character or cursor[2],
    file = file,
    ext = vim.fn.fnamemodify(file, ":e"),
    ft = vim.api.nvim_get_option_value("filetype", { buf = buf }),
    range = params.range,
  }
end

local function code_actions(params)
  local actions = {
    { title = "Extract variable", category = "Refactoring", command = "copy_as_curl", fn = extract_variable },
  }

  if not params then return actions end
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
  if Config.filetypes.exclude and vim.tbl_contains(Config.filetypes.exclude, ft) then return end
  if Config.filetypes.include and not vim.tbl_contains(Config.filetypes.include, ft) then return end

  M.start_lsp(buf)
end

function M.start_lsp(buf)
  local server = new_server()

  local dispatchers = {
    on_exit = function(code, signal)
      Logger.error("Dev-tools server exited with code " .. code .. " and signal " .. signal)
    end,
  }

  local client_id = vim.lsp.get_client_by_id(buf)
  if client_id then vim.lsp.stop_client(client_id) end

  client_id = vim.lsp.start({
    name = "dev-tools",
    cmd = server,
    root_dir = "",
    bufnr = buf,
    on_init = function(_client) end,
    on_exit = function(_code, _signal) end,
    commands = vim.iter(code_actions()):fold({}, function(acc, action)
      acc[action.command] = action.fn
      return acc
    end),
  }, dispatchers)

  return client_id
end

return M
