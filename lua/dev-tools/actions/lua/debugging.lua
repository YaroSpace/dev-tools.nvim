local Opts = require("dev-tools.config").builtin_opts.debug
DevTools = Opts.logger or require("dev-tools.log")

local function insert_log(action, method)
  local ctx = action.ctx
  local var = ctx.edit:get_range()[1]
  var = var ~= "" and var or vim.fn.expand("<cword>")

  vim.fn.append(ctx.row, ('%s("%s: ", %s)'):format(method, var:gsub('"', ""), var))
  ctx.edit:indent()
  ctx.edit:set_cursor(ctx.row + 1)
end

---@type Actions
return {
  category = "Debugging",
  filetype = { "lua" },
  actions = {
    {
      title = "Log vars under cursor",
      fn = function(action)
        insert_log(action, "DevTools.log")
      end,
    },
    {
      title = "Log trace vars under cursor",
      fn = function(action)
        insert_log(action, "DevTools.trace")
      end,
    },
    {
      title = "Log on condition",
      fn = function(action)
        insert_log(action, "DevTools.iff")
      end,
    },
    {
      title = "Log in spec",
      fn = function(action)
        insert_log(action, "DevTools.spec")
      end,
    },
  },
}
