local opts = require("dev-tools.config").get_action_opts("Debugging", "Log vars under cursor")
DevTools = opts.logger or require("dev-tools.log")

local function insert_log(action, method)
  local ctx = action.ctx
  local var = ctx.edit:get_range()[1]
  var = var ~= "" and var or ctx.word

  vim.fn.append(ctx.row + 1, ('%s("%s: ", %s)'):format(method, var:gsub('"', ""), var))
  ctx.edit:indent()
  ctx.edit:set_cursor(ctx.row + 1)
end

---@type Actions
return {
  group = "Debugging",
  filetype = { "lua" },
  actions = {
    {
      name = "Log vars under cursor",
      fn = function(action)
        insert_log(action, "DevTools.log")
      end,
      desc = "Log var/selection",
    },
    {
      name = "Log trace vars under cursor",
      fn = function(action)
        insert_log(action, "DevTools.trace")
      end,
      desc = "Log with trace",
    },
    {
      name = "Log on condition",
      fn = function(action)
        insert_log(action, "DevTools.iff")
      end,
    },
    {
      name = "Log in spec",
      fn = function(action)
        insert_log(action, "DevTools.spec")
      end,
      desc = "Log showing running spec",
    },
    {
      name = "Logs clear",
      fn = function(action)
        local ctx = action.ctx
        local lines = vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, true)

        for i, line in ipairs(lines) do
          line = line:gsub("%s*DevTools%..+%(.-%)%s*", "")

          if lines[i] ~= line and line == "" then
            table.remove(lines, i)
          else
            lines[i] = line
          end
        end

        ctx.edit:set_lines(lines, 0, -1)
      end,
      desc = "Clear all logs",
    },
  },
}
