local config = require("dev-tools.config")
local filename = config.get_action_opts("Todo", "Open Todo", "filename") or ".todo.md"
local template = config.get_action_opts("Todo", "Open Todo", "template")
  or {
    "# TODO",
    "",
    "## Done",
    "",
    "## Ideas",
    "",
    "- [ ] Idea 1",
    "",
    "## Tasks",
    "",
    "- [ ] Task 1",
  }

local function create_todo_file(path, item)
  vim.ui.select({ "Yes", "No" }, { prompt = "Create TODO file?" }, function(choice)
    if choice == "Yes" then
      vim.cmd("edit " .. path)

      if item then table.insert(template, "[-] " .. item) end
      vim.api.nvim_buf_set_lines(0, 0, -1, false, template)

      vim.cmd("write")
      vim.cmd("normal! G")
    end
  end)
end

---@type Actions
return {
  group = "Todo",
  actions = {
    {
      name = "Open Todo",
      fn = function(action)
        local path = action.ctx.root .. "/" .. filename
        if vim.fn.filereadable(path) == 0 then return create_todo_file(path) end
        vim.cmd("edit " .. path)
      end,
    },
    {
      name = "Add Todo",
      fn = function(action)
        local path = action.ctx.root .. "/" .. filename

        vim.ui.input({ prompt = "Todo: " }, function(input)
          if not input or input == "" then return end
          if vim.fn.filereadable(path) == 0 then return create_todo_file(path, input) end

          vim.cmd("edit " .. path)
          vim.api.nvim_buf_set_lines(0, -1, -1, false, { "[-] " .. input })

          vim.cmd("write")
          vim.cmd("normal! G")
        end)
      end,
    },
  },
}
