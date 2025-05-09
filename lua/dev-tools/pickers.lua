local has_snacks, snacks_picker = pcall(require, "snacks.picker")
local Config = require("dev-tools.config")

local M = {}

---@return snacks.picker.format
local function format_item(count, width_title, width_category)
  return function(item)
    local ret = {} ---@type snacks.picker.Highlight[]

    local idx = tostring(item.idx)
    idx = (" "):rep(#tostring(count) - #idx) .. idx

    table.insert(ret, { idx .. ".", "SnacksPickerIdx" })
    table.insert(ret, { " " })

    local action, ctx = item.item.action, item.item.ctx
    local client = vim.lsp.get_client_by_id(ctx.client_id)

    local keymap = action.keymap or ""

    table.insert(ret, { action._title .. (" "):rep(width_title - #action._title) })
    table.insert(ret, { " " })

    table.insert(ret, { keymap .. (" "):rep(5 - #keymap), "SnacksPickerSpecial" })
    table.insert(ret, { " " })

    table.insert(ret, { action.category .. (" "):rep(width_category - #action.category), "Number" })

    if client then
      ret[#ret + 1] = { " " }
      ret[#ret + 1] = { ("[%s]"):format(client.name), "SnacksPickerSpecial" }
    end

    table.insert(ret, { " " })
    table.insert(ret, { action.desc })

    return ret
  end
end

local function select_actions(items, _, on_choice)
  local width_title, width_category = 0, 0
  local finder_items, actions, keys = {}, {}, {}
  local categories, category_idx = {}, 0
  local completed = false

  actions.confirm = function(picker, item, action)
    if completed then return end

    item = action and vim.iter(finder_items):find(function(_item)
      return _item.keymap == action.name
    end) or item

    completed = true
    picker:close()

    vim.schedule(function()
      on_choice(item and item.item, item and item.idx)
    end)
  end

  for idx, item in ipairs(items) do
    local text = item.action.title

    item.action._title = item.action._title or item.action.title
    item.action.category = item.action.category or ""
    _ = not vim.tbl_contains(categories, item.action.category) and table.insert(categories, item.action.category)

    width_title = math.max(width_title, #item.action._title)
    width_category = math.max(width_category, #item.action.category)

    local key = item.action.keymap

    table.insert(finder_items, {
      formatted = text,
      text = idx .. " " .. text,
      category = item.action.category,
      item = item,
      keymap = key,
      idx = idx,
    })

    if key then
      keys[key] = { key, mode = { "n", "i" }, desc = item.action._title }
      actions[key] = actions.confirm
    end
  end

  actions.filter_category = function()
    category_idx = category_idx + 1

    local next_category = categories[category_idx % (#categories + 1)] or ""
    local input = actions.picker.input

    input.filter.search = next_category
    input.filter.pattern = next_category:lower()
    input.picker:find { refresh = true }
  end

  keys[Config.ui.keymaps.filter] = { actions.filter_category, mode = { "n", "i" }, desc = "Filter by category" }

  actions.picker = snacks_picker.pick {
    source = "select",
    title = "Code actions",

    items = finder_items,
    format = format_item(#finder_items, width_title, width_category),
    sort = { fields = { "category", "formatter", "idx" } },

    layout = { layout = { height = math.floor(math.min(vim.o.lines * 0.8 - 10, #finder_items + 2) + 0.5) } },
    win = { input = { keys = keys } },

    actions = actions,
    on_close = function()
      if completed then return end
      completed = true
      vim.schedule(on_choice)
    end,
  }
end

M.stub = function()
  if not has_snacks then return end

  local _select = vim.ui.select

  vim.ui.select = function(items, opts, on_choice)
    if not (opts and opts.prompt:find("Code actions")) then return _select(items, opts, on_choice) end
    select_actions(items, opts, on_choice)
  end

  return true
end

return M
