---@diagnostic disable: missing-fields, undefined-field, param-type-mismatch

local config = require("dev-tools.config")
local dev_tools = require("dev-tools")
local h = require("test_helper")
local lsp = require("dev-tools.lsp")

describe("LSP server", function()
  local result, expected

  before_each(function()
    dev_tools.setup {
      actions = { { title = "Test Action", filetype = { "rs" }, fn = function() end } },

      filetypes = {
        include = { "lua", "python" },
        exclude = { "javascript" },
      },

      builtin_actions = {
        include = { "lua", "Editing" },
        exclude = { "Specs", "Split/join" },
      },

      debug = true,
    }
  end)

  after_each(function()
    h.delete_all_bufs()
  end)

  describe("config", function()
    it("merges user config", function()
      assert.is_same(config.actions[1].title, "Test Action")
      assert.has_properties(config, {
        filetypes = {
          include = { "lua", "python" },
          exclude = { "javascript" },
        },
        builtin_actions = {
          include = { "lua", "Editing" },
          exclude = { "Specs" },
        },
        cache = true, -- default
        debug = true,
      })
    end)
  end)

  describe("init", function()
    it("registers actions", function()
      dev_tools.register_action {
        title = "Test Action 2",
        fn = function() end,
      }
      assert.is_same(config.actions[1].title, "Test Action")
      assert.is_same(config.actions[2].title, "Test Action 2")
    end)
  end)

  describe("LSP", function()
    it("starts for included filetypes", function()
      result = h.create_buf({}, "test.lua")
      vim.api.nvim_set_option_value("filetype", "lua", { buf = result })

      local client = vim.lsp.get_clients({ bufnr = result, name = "dev-tools" })[1]
      assert.is_not_nil(client)
    end)

    it("does not start for excluded filetypes", function()
      result = h.create_buf({}, "test.js")
      vim.api.nvim_set_option_value("filetype", "javascript", { buf = result })

      local client = vim.lsp.get_clients({ bufnr = result, name = "dev-tools" })[1]
      assert.is_nil(client)
    end)

    it("collects actions on start", function()
      result = h.create_buf({}, "test.lua")
      vim.api.nvim_set_option_value("filetype", "lua", { buf = result })

      result = vim
        .iter(lsp.actions)
        :map(function(action)
          return action._title
        end)
        :totable()

      assert.is_true(h.contains(result, { "Test Action", "Convert from JSON" }))
      assert.is_false(h.contains(result, { "Watch specs", "Split/join" }))
    end)

    it("filters actions on call", function()
      dev_tools.register_action {
        { title = "Test Action 2", filter = "test", fn = function() end, filetype = { "rs" } },
        { title = "Test Action 3", filter = "other", fn = function() end, filetype = { "rs" } },
        {
          title = "Test Action 4",
          filter = function(ctx)
            return ctx.bufname:match("test")
          end,
          fn = function() end,
          filetype = { "rs" },
        },
        {
          title = "Test Action 5",
          filter = function(ctx)
            return ctx.bufname:match("other")
          end,
          fn = function() end,
          filetype = { "rs" },
        },
      }

      local buf = h.create_buf({}, "test.lua")
      vim.api.nvim_set_option_value("filetype", "rs", { buf = buf })

      local ctx = lsp.get_ctx { textDocument = { uri = vim.uri_from_bufnr(buf) } }
      local actions = lsp.code_actions(ctx)

      result = vim
        .iter(actions)
        :map(function(action)
          return action._title
        end)
        :totable()

      assert.is_true(h.contains(result, { "Test Action", "Test Action 2", "Test Action 4" }))
    end)
  end)
end)

--- custom picker
