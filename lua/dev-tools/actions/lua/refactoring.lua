---@type Actions
return {
  category = "Refactoring",
  filetype = { "lua" },
  actions = {
    {
      title = "Convert fn <-> method",
      filter = function(ctx)
        local nodes = { "function_declaration", "function_definition" }
        return ctx.edit:get_node(nodes)
      end,
      fn = function(action)
        local ctx = action.ctx
        local node = ctx.edit:get_node("function_declaration") or ctx.edit:get_node("function_definition")

        local fn_name, fn_params = node:field("name")[1], node:field("parameters")[1]
        fn_params = ctx.edit:get_node_text(fn_params)

        if fn_name then
          fn_name = ctx.edit:get_node_text(fn_name)
        else
          fn_name = ctx.edit:get_previous_node(node, true):field("field")[1]
          fn_name = ctx.edit:get_node_text(fn_name)
        end

        local fn_text = vim.split(ctx.edit:get_node_text(node), "\n")

        if node:type() == "function_declaration" then
          fn_text[1] = ("M.%s = function%s"):format(fn_name, fn_params)
        else
          fn_text[1] = ("local function %s%s"):format(fn_name, fn_params)
        end

        if fn_text[1]:find("\n") then return end

        local range = { node:range() }
        ctx.edit:set_lines(fn_text, range[1], range[3] + 1)
      end,
    },
    {
      title = "Extract variable",
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
