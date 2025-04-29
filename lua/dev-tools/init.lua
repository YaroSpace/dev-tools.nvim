local Config = require("dev-tools.config")
local Lsp = require("dev-tools.lsp")

local M = {}

local function init()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("Dev-tools filetype setup", { clear = true }),
    callback = function(ev)
      Lsp.start(ev.buf, ev.match)
    end,
  })
end

M.setup = function(opts)
  Config.setup(opts)
  init()
end

return M
