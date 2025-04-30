local Logger = require("dev-tools.logger")

---@type Actions
return {
  category = "Editing",
  filetype = { "lua" },
  actions = {
    {
      title = "Split table",
      filetype = { "lua" },
      fn = function(action)
        local ctx = action.ctx
        local ts = vim.treesitter
        local line = ctx.edit:get_lines()[1]

        vim.api.nvim_win_set_cursor(ctx.win, { ctx.range.rc[1] + 1, (line:find("{") or 1) + 2 })

        local tbl, range = ctx.edit:get_node("table_constructor")
        if not tbl then return end

        local tbl_lines = vim.split(ts.get_node_text(tbl, ctx.buf):gsub("[{}]", ""), ",")
        tbl_lines = vim
          .iter(tbl_lines)
          :map(function(line)
            return line .. ","
          end)
          :totable()

        local lines = {}

        table.insert(lines, line:match("^.*{"))
        vim.list_extend(lines, tbl_lines)
        table.insert(lines, line:match("}.*$"))

        ctx.edit:set_lines(lines, range[1], range[1] + 1)

        vim.api.nvim_win_set_cursor(ctx.win, { range[1] + 1, 1 })
        vim.cmd("normal V" .. #lines .. "j=")
      end,
    },
    {
      title = "Join table",
      filetype = { "lua" },
      fn = function(action)
        local ctx = action.ctx
        local ts = vim.treesitter
        local line = ctx.edit:get_lines()[1]

        vim.api.nvim_win_set_cursor(ctx.win, { ctx.range.rc[1] + 1, (line:find("{") or 1) + 2 })

        local tbl, range = ctx.edit:get_node("table_constructor")
        if not tbl then return end

        local tbl_lines = vim.split(ts.get_node_text(tbl, ctx.buf):gsub("[{}\n]", ""), ",")
        tbl_lines = vim
          .iter(tbl_lines)
          :map(function(line)
            line = line:match("^%s*(.-)%s*$") or ""
            return #line > 0 and line or nil
          end)
          :totable()

        local lines = table.concat(tbl_lines, ", ")
        local buf_lines = ctx.edit:get_lines(range[1], range[3] + 1)

        lines = buf_lines[1] .. lines .. buf_lines[#buf_lines]:gsub("^%s*", "")

        ctx.edit:set_lines({ lines }, range[1], range[3] + 1)
        vim.api.nvim_win_set_cursor(ctx.win, { range[1] + 1, 1 })
      end,
    },

    {
      title = "Convert from JSON",
      filetype = { "lua" },
      fn = function(action)
        local ctx = action.ctx
        local lines = ctx.edit:get_lines()

        lines = table.concat(lines, " ")
        lines = lines:match("^%s*{") and lines or "{" .. lines .. "}"

        local status, json = pcall(vim.fn.json_decode, lines)
        if not status then return Logger.error("Error parsing JSON: " .. json) end

        lines = vim.split(vim.inspect(json), "\n")

        ctx.edit:set_lines(lines)
        vim.cmd("normal V" .. #lines .. "j=")
      end,
    },
  },
}
