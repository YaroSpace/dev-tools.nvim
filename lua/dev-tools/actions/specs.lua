local Logger = require("dev-tools.logger")

local function get_spec(ctx)
  local ids = { "it", "describe", "context", "example", "specify", "test", "pending" }

  local pos = ctx.line:find("[^%s%c]") or 0
  ctx.edit:set_cursor(ctx.range.rc[1] + 1, pos)

  local fn_name, fn_name_txt, fn_args
  local node = ctx.edit:get_node("function_call", nil, function(node)
    fn_name, fn_args = node:field("name")[1], node:field("arguments")[1]
    fn_name_txt = ctx.edit:get_node_text(fn_name)

    return vim.tbl_contains(ids, fn_name_txt)
  end)

  if not node then return end
  return fn_name, fn_name_txt, fn_args
end

---@type Actions
return {
  category = "Specs",
  condition = "_spec",
  actions = {
    {
      name = "Toggle pending",
      fn = function(action)
        local ctx = action.ctx

        local _, spec_name, spec_desc = get_spec(ctx)
        if not spec_desc then return end

        local lnum = spec_desc:range()
        local line = ctx.edit:get_lines(lnum, lnum + 1)[1]

        local prev_name = line:match(spec_name .. [[%(['"](.+)::]]) or "it"
        line = line:match("pending") and line:gsub("pending", prev_name):gsub(prev_name .. "::", "")
          or line:gsub(spec_name .. [[%((['"])]], "pending(%1" .. spec_name .. "::")

        ctx.edit:set_lines({ line }, lnum, lnum + 1)
        ctx.edit:write()
      end,
    },
    {
      name = "Toggle wip",
      fn = function(action)
        local ctx = action.ctx

        local _, spec_name, spec_desc = get_spec(ctx)
        if not spec_desc then return end

        local lnum = spec_desc:range()
        local line = ctx.edit:get_lines(lnum, lnum + 1)[1]

        line = line:match("#wip") and line:gsub("#wip ", "") or line:gsub(spec_name .. [[%(['"].-]], "%1#wip ")

        ctx.edit:set_lines({ line }, lnum, lnum + 1)
        ctx.edit:write()
      end,
    },
    {
      name = "Toggle code/spec",
      condition = ".*",
      fn = function(action)
        local ctx = action.ctx
        local name = vim.fn.fnamemodify(ctx.bufname, ":t")

        if ctx.bufname:match("_spec") then
          name = name:gsub("_spec", "")
        else
          name = name:gsub("(([^%.]+)%.(%w+))$", "%2.-_spec.%3")
        end

        local alt_file = vim.fs.find(function(file, path)
          return file:match(name .. "$") and not path:match("/%.[^/]+/")
        end, { path = ctx.root, limit = 1, type = "file" }) or {}

        alt_file = alt_file[1]
          or vim.fs.find(function(path)
            return path:match("_spec.lua$")
          end, { path = ctx.root, limit = 1, type = "file" })[1]

        if alt_file and #alt_file > 0 then return vim.cmd("e " .. alt_file) end

        Logger.info("No alt file found")
      end,
    },
  },
}
