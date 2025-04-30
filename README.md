# dev-tools.nvim

A Neovim plugin that provides an in-process LSP server, a community library and a convenient interface for customization - to enhance your Neovim with custom code action.

## Features

- 🚀 In-process LSP server for code actions
- 🧩 Simple, intuitive interface and helpers for managing and creating code actions
- 📚 Community-driven library of useful code actions

## Installation and setup

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'yarospace/dev-tools.nvim',
  ---@type Config
  opts = {
    actions = {},

    filetypes = { -- filetypes for which to attach the LSP
      include = {},
      exclude = {},
    },

    builtin_actions = {
      exclude = {}, -- language/category/title of actions to exclude or true to exclude all
    },

    debug = true, -- extra debug info on errors
  }
}
```

## Usage

- Code actions are accessible via the default LSP keymaps, e.g. `gra`, `<leader>ca`, `<leader>la`, etc. 

## Adding code actions

- Custom actions can be added to the `opts.actions` table in your configuration or registered via `require('dev-tools').register_action({})`

```lua
---@class Action
---@field title string - title of the action
---@field category string|nil - category of the action
---@field filter string|nil|fun(ctx: Ctx): boolean - filter to limit the action to
---@field filetype string[]|nil - filetype to limit the action to
---@field fn fun(action: ActionCtx) - function to execute the action

---@class ActionCtx: Action
---@field ctx Ctx - context of the action

---@class Ctx
---@field buf number - buffer number
---@field win number - window number
---@field row number - current line number
---@field col number - current column number
---@field bufname string - full path to file in buffer
---@field root string - root directory of the file
---@field ext string - file extension
---@field filetype string - filetype
---@field range Range|nil - range of the current selection
---@field edit Edit - edititng functions

---@class Range
---@field start {line: number, character: number} - start position of the range
---@field end {line: number, character: number} - end position of the range
---@field rc table<number, number, number, number> - row/col format

opts = {
  ---@type Action[]
  actions = {
    {
      title = "Extract variable",
      filetype = { "lua" },
      fn = function(action)
        local ctx = action.ctx

        vim.ui.input({ prompt = "Variable name:", default = "" }, function(var_name)
          if not var_name then return end

          local var_body = ("local %s = %s"):format(var_name, ctx.edit:get_range()[1])

          ctx.edit:set_range { var_name }
          ctx.edit:set_lines({ var_body }, ctx.range.rc[1], ctx.range.rc[1])

          vim.api.nvim_win_set_cursor(0, { ctx.range.rc[1] + 1, ctx.range.rc[3] + 1 })
          vim.cmd("normal =0") -- indent

          vim.api.nvim_win_set_cursor(0, { ctx.range.rc[1] + 2, ctx.range.rc[2] + 1 })
        end)
      end,
    },
  }
}
```

There are several helper functions to make it easier to create actions:

```lua
---@class Edit
---@field get_node fun(self: Ctx, type: string, node?: TSNode|nil, predicate?: fun(node: TSNode): boolean| nil): TSNode|nil, table <number, number, number, number>|nil
---@field get_lines fun(self: Ctx, l_start?: number, l_end?: number): string[]
---@field set_lines fun(self: Ctx, lines: string[], l_start?: number, l_end?: number)
---@field get_range fun(self: Ctx): string[]
---@field set_range fun(self: Ctx, lines: string[])
```

## Contributing

This project is originally thought out as community driven. 

The goal is to provide a simple and intuitive interface for creating and managing code actions, as well as a collection of useful code actions that can be used out of the box.
Your contributions are highly desired and appreciated!

All actions are stored in `/lua/dev-tools/actions/`.  Actions specific to a language can be put under the relevant subdirectory.

```lua
---@class Actions
---@field category string - category of actions
---@field filter string|nil|fun(ctx: Ctx): boolean - filter to limit the actions category to
---@field filetype string[]|nil - filetype to limit the actions category to
---@field actions Action[] - list of actions

---@type Actions
return {
  category = "Refactoring",
  filetype = { "lua" },
  actions = {
    {
      title = "Extract variable",
      filetype = { "lua" },
      fn = function(action)
        ---
      end,
    },
    {
      title = "Extract function",
      fn = function(ctx)
        --
      end,
    },
  },
}
```

## Available actions

### Lua

#### Refactoring

- [x] Extract variable

#### Editing

- [x] Split/join table
- [x] Convert JSON to Lua table

### General

#### Specs

- [x] Switch between code and spec files
- [x] Toggle pending
- [x] Toggle #wip tag
- [-] Run/watch all specs
- [-] Run/watch current spec

#### Debugging

- [-] Log variable under cursor
- [-] Trace

## License

MIT
