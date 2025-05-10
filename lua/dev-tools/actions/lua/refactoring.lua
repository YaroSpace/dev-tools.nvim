local function replace_region(action, prompt, template)
  local ctx = action.ctx

  vim.ui.input({ prompt = prompt, default = "" }, function(name)
    if not name then return end

    local body = template:format(name, table.concat(ctx.edit:get_range(), "\n"))
    body = vim.split(body, "\n")

    if prompt:find("Variable") then
      ctx.edit:set_range { name }
      ctx.edit:set_lines(body, ctx.range.rc[1], ctx.range.rc[1])
    else
      ctx.edit:set_lines(body, ctx.range.rc[1], ctx.range.rc[3] + 1)
    end

    local rows = vim.api.nvim_buf_line_count(ctx.buf)

    ctx.edit:indent(math.max(ctx.range.rc[1] - 1, 1), ctx.range.rc[3] + 1)
    ctx.edit:set_cursor(math.min(ctx.range.rc[1] + 2, rows), ctx.range.rc[2] + 1)
  end)
end

---@type Actions
return {
  category = "Refactoring",
  filetype = { "lua" },
  actions = {
    {
      title = "Convert fn <-> method",
      condition = function(action)
        local nodes = { "function_declaration", "function_definition" }
        return action.ctx.edit:get_node(nodes) and true
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
        replace_region(action, "Variable name:", "local %s = %s")
      end,
    },
    {
      title = "Extract function",
      fn = function(action)
        replace_region(action, "Function name:", "local function %s()\n%s\nend")
      end,
    },
  },
}
