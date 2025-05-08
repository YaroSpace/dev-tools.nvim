local Opts = require("dev-tools.config").builtin_opts.debug

DevTools.log = Opts.logger
  or function(...)
    vim.print(unpack(vim
      .iter({ ... })
      :map(function(v)
        return vim.inspect(v)
      end)
      :totable()))
  end

---@type Actions
return {
  category = "Debugging",
  filetype = { "lua" },
  actions = {
    {
      title = "Log var under cursor",
      fn = function(action)
        local ctx = action.ctx

        local var = ctx.edit:get_range()[1]
        var = var ~= "" and var or vim.fn.expand("<cword>")

        vim.fn.append(ctx.row, ('DevTools.log("%s: ", %s)'):format(var, var))
        ctx.edit:indent()
        ctx.edit:set_cursor(ctx.row + 1)
      end,
    },
  },
}
