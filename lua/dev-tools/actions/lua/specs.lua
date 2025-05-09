local Opts = require("dev-tools.config").builtin_opts.specs

local tree_cmd = Opts.tree_cmd or "git ls-files -cdmo --exclude-standard"
local test_cmd = Opts.test_cmd or "nvim -l tests/minit.lua tests --shuffle-tests -v"
local test_tag = test_cmd .. (Opts.test_tag or " --tags=wip")

local function watch_cmd(cmd)
  return ("while sleep 0.1; do %s | entr -d -c %s; done"):format(tree_cmd, cmd)
end

local open_terminal = Opts.terminal_cmd
  or function(cmd, root)
    Snacks.terminal.toggle(cmd, {
      shell = "/usr/bin/bash",
      cwd = root or vim.uv.cwd(),
      auto_close = false,
      start_insert = false,
      auto_insert = false,
      win = { position = "right", width = vim.o.columns * 0.4, wo = { winbar = "" } },
    })
  end

---@type Actions
return {
  category = "Specs",
  filetype = { "lua" },
  filter = "_spec",
  actions = {
    {
      title = "Watch specs",
      fn = function(action)
        local ctx = action.ctx

        vim.cmd("normal :w")
        local cmd = "cd " .. ctx.root .. " && " .. watch_cmd(test_cmd)

        open_terminal(cmd, ctx.root)
        vim.api.nvim_set_current_win(ctx.win)
      end,
      desc = "Watch all specs",
    },
    {
      title = "Watch wip",
      fn = function(action)
        local ctx = action.ctx

        vim.cmd("normal :w")
        local cmd = "cd " .. ctx.root .. " && " .. watch_cmd(test_tag)

        open_terminal(cmd, ctx.root)
        vim.api.nvim_set_current_win(ctx.win)
      end,
      desc = "Watch #wip specs",
    },
  },
}
