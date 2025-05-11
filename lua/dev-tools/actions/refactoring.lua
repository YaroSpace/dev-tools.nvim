-- "https://github.com/ThePrimeagen/refactoring.nvim",

---@type Actions
return {
  category = "Refact (Prime)",
  filetypes = { "go", "javascript", "lua", "python", "typescript" },
  actions = function()
    local status, refactors = pcall(require("refactoring").get_refactors)
    if not status then return {} end

    local actions = {}

    for _, name in ipairs(refactors) do
      table.insert(actions, {
        title = name,
        name = name,
        condition = function(action)
          return action.ctx.edit:get_range()[1] ~= ""
        end,
        fn = function(action)
          local keys = require("refactoring").refactor(action.name)
          vim.cmd.normal(keys == "g@" and "gvg@" or keys)
        end,
      })
    end

    return actions
  end,
}
