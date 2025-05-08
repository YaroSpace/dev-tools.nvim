local Actions = require("dev-tools.actions")
local Config = require("dev-tools.config")
local Lsp = require("dev-tools.lsp")

local M = {}

_G.DevTools = {} -- global table to store dev-tools helpers

local function init()
  vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("Dev-tools filetype setup", { clear = true }),
    callback = function(ev)
      Lsp.start(ev.buf, ev.match)
    end,
  })
end

---@param actions Action|Actions[]
M.register_action = function(actions)
  Actions.register(actions)
end

---@param opts Config
M.setup = function(opts)
  Config.setup(opts)
  init()
  return Config
end

return M
