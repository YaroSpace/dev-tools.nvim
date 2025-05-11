---@diagnostic disable: missing-fields, undefined-field, param-type-mismatch

local config = require("dev-tools.config")
local dev_tools = require("dev-tools")
local h = require("test_helper")
local lsp = require("dev-tools.lsp")

local function call_action(category, name)
  local action = vim.iter(lsp.actions):find(function(action)
    return action.category == category and action.name == name
  end)

  if not action then return vim.print("Action not found") end

  action.ctx = lsp.get_ctx()
  action:fn()
end

describe("LSP server", function()
  local buf, result, expected
  local input

  before_each(function()
    dev_tools.setup {
      filetypes = { include = { "lua" } },
      action_opts = {
        {
          category = "Debugging",
          name = "Log vars under cursor",
          opts = { logger = LOG },
        },
      },
      debug = true,
    }

    stub(vim.ui, "input", function(_, fn)
      fn(input)
    end)
  end)

  after_each(function()
    h.delete_all_bufs()
    vim.ui.input:revert()
  end)

  describe("config", function()
    it("extract variable", function()
      buf = h.create_buf(
        ([[
        local a = print(vim.fn.bufnr())
        end
      ]]):to_table(),
        "test.lua"
      )

      vim.api.nvim_win_set_cursor(0, { 1, 20 })
      h.send_keys("vib")

      input = "var_name"
      call_action("Refactoring", "Extract variable")

      result = h.get_buf_lines(buf):to_string()
      assert.has_string(result, "local var_name = vim.fn.bufnr()")
      assert.has_string(result, "local a = print(var_name)")
    end)
  end)
end)
