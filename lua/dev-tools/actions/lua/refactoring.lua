---@type Actions
return {
  category = "Refactoring",
  filetype = { "lua" },
  actions = {
    {
      title = "Extract variable",
      filetype = { "lua" },
      fn = function(action)
        local ctx = action.ctx

        vim.ui.input({ prompt = "Variable name:", default = "" }, function(var_name)
          if not var_name then return end

          local var_body = ("local %s = %s"):format(var_name, ctx.edit:get_range()[1])

          ctx.edit:set_range { var_name }
          ctx.edit:set_lines({ var_body }, ctx.range.rc[1], ctx.range.rc[1])

          vim.api.nvim_win_set_cursor(0, { ctx.range.rc[1] + 1, ctx.range.rc[3] + 1 })
          vim.cmd("normal =0") -- indent

          vim.api.nvim_win_set_cursor(0, { ctx.range.rc[1] + 2, ctx.range.rc[2] + 1 })
        end)
      end,
    },
    {
      title = "Extract function",
      fn = function(ctx)
        --
      end,
    },
  },
}
