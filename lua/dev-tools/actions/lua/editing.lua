local Logger = require("dev-tools.logger")
local sj_nodes = { "table_constructor", "if_statement", "function_declaration", "function_definition" }

---@type Actions
return {
  category = "Editing",
  filetype = { "lua" },
  actions = {
    {
      title = "Split/join",
      filter = function(ctx)
        return ctx.edit:get_node(sj_nodes) and true
      end,
      fn = function(action)
        local ctx = action.ctx
        local node, range = ctx.edit:get_node(sj_nodes)
        local type, text = node:type(), ctx.edit:get_node_text(node) or ""

        local split = text:find("\n")
        text = split and text:gsub("\n%s*", " ") or text

        local before = ctx.edit:get_range(range[1], 0, range[1], range[2])[1]
        local after = ctx.edit:get_range(range[3], range[4], range[3], -1)[1]

        if type == "table_constructor" then
          text = split and text or text:gsub("[{,]", "%1\n"):gsub("}", "\n}")
        elseif type == "if_statement" then
          text = split and text or text:gsub("then", "%1\n"):gsub("else", "\n%1"):gsub("end$", "\n%1")
        elseif type == "function_declaration" or type == "function_definition" then
          local params = node:field("parameters")[1]
          params = ctx.edit:get_node_text(params):gsub("[%(%)]", "%%%1")
          text = split and text or text:gsub(params, "%1\n"):gsub("end$", "\n%1")
        end

        ctx.edit:set_lines(vim.split(before .. text .. after, "\n"), range[1], range[3] + 1)
        ctx.edit:indent(range[1], range[3] + 1)
      end,
    },
    {
      title = "Convert from JSON",
      fn = function(action)
        local ctx = action.ctx
        local lines = ctx.edit:get_lines()

        lines = table.concat(lines, " ")
        lines = lines:match("^%s*{") and lines or "{" .. lines .. "}"

        local status, json = pcall(vim.fn.json_decode, lines)
        if not status then return Logger.error("Error parsing JSON: " .. json) end

        lines = vim.split(vim.inspect(json), "\n")
        ctx.edit:set_lines(lines)
        ctx.edit:indent()
      end,
    },
  },
}
