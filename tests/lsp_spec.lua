---@diagnostic disable: missing-fields, undefined-field, param-type-mismatch

local config = require("dev-tools.config")
local dev_tools = require("dev-tools")
local h = require("test_helper")
local lsp = require("dev-tools.lsp")

describe("LSP server", function()
  local buf, result, expected

  before_each(function()
    dev_tools.setup {
      actions = { { name = "Test Action", filetype = { "rs" }, fn = function() end } },

      filetypes = {
        include = { "lua", "python" },
        exclude = { "javascript" },
      },

      builtin_actions = {
        include = { "lua", "Editing" },
        exclude = { "Specs", "Split/join" },
      },

      action_opts = {
        {
          category = "Debugging",
          name = "Log vars under cursor",
          opts = {
            logger = nil,
            keymap = { global = { "<leader>dl", mode = { "n", "i" } } },
          },
        },
        {
          category = "Specs",
          name = "Toggle code/spec",
          opts = {
            keymap = { global = "<leader>fs", picker = "<M-l>" },
          },
        },
      },
      debug = true,
    }
  end)

  after_each(function()
    h.delete_all_bufs()
  end)

  describe("config", function()
    it("merges user config", function()
      assert.is_same(config.actions[1].name, "Test Action")
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
        name = "Test Action 2",
        fn = function() end,
      }
      dev_tools.register_action {
        { name = "Test Action 3", fn = function() end },

        { name = "Test Action 4", fn = function() end },
      }
      assert.is_same(config.actions[1].name, "Test Action")
      assert.is_same(config.actions[2].name, "Test Action 2")
      assert.is_same(config.actions[3].name, "Test Action 3")
      assert.is_same(config.actions[4].name, "Test Action 4")
    end)

    it("sets global keymaps", function()
      vim.g.mapleader = ","
      buf = h.create_buf({}, "test.lua")

      local keymaps = h.get_maps()
      assert.has_properties(keymaps, {
        ["<leader>dl"] = "Dev-tools: Log vars under cursor",
        ["<leader>fs"] = "Dev-tools: Toggle code/spec",
      })
    end)
  end)

  describe("LSP", function()
    it("starts for included filetypes", function()
      buf = h.create_buf({}, "test.lua")

      local client = vim.lsp.get_clients({ bufnr = buf, name = "dev-tools" })[1]
      assert.is_not_nil(client)
    end)

    it("does not start for excluded filetypes", function()
      buf = h.create_buf({}, "test.js")

      local client = vim.lsp.get_clients({ bufnr = buf, name = "dev-tools" })[1]
      assert.is_nil(client)
    end)

    it("collects actions on start", function()
      buf = h.create_buf({}, "test.lua")

      result = vim
        .iter(lsp.actions)
        :map(function(action)
          return action.name
        end)
        :totable()

      assert.is_true(h.contains(result, { "Test Action", "Convert from JSON" }))
      assert.is_false(h.contains(result, { "Watch specs", "Split/join" }))
    end)

    it("filters actions on call", function()
      dev_tools.register_action {
        { name = "Test Action 2", condition = "test", fn = function() end, filetype = { "rs" } },
        { name = "Test Action 3", condition = "other", fn = function() end, filetype = { "rs" } },
        {
          name = "Test Action 4",
          condition = function(action)
            return action.ctx.bufname:match("test")
          end,
          fn = function() end,
          filetype = { "rs" },
        },
        {
          name = "Test Action 5",
          condition = function(action)
            return action.ctx.bufname:match("other")
          end,
          fn = function() end,
          filetype = { "rs" },
        },
      }

      buf = h.create_buf({}, "test.rs")

      local ctx = lsp.get_ctx { textDocument = { uri = vim.uri_from_bufnr(buf) } }
      local actions = lsp.code_actions(ctx)

      result = vim
        .iter(actions)
        :map(function(action)
          return action.name
        end)
        :totable()

      assert.is_true(h.contains(result, { "Test Action", "Test Action 2", "Test Action 4" }))
    end)
  end)
end)

--- custom picker
--- show action info
--- set picker keymaps
--- hide action
