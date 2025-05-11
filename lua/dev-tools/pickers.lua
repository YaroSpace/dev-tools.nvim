local has_snacks, snacks_picker = pcall(require, "snacks.picker")
local Config = require("dev-tools.config")

local M = { groups = {} }

---@return snacks.picker.format
local function format_item(count, width_name, width_category)
  return function(item)
    local ret = {} ---@type snacks.picker.Highlight[]

    local idx = tostring(item.idx)
    idx = (" "):rep(#tostring(count) - #idx) .. idx

    table.insert(ret, { idx .. ".", "SnacksPickerIdx" })
    table.insert(ret, { " " })

    local action, ctx = item.item.action, item.item.ctx
    local client = vim.lsp.get_client_by_id(ctx.client_id)

    local keymap = item.keymap or ""

    table.insert(ret, { action.name .. (" "):rep(width_name - #action.name) })
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

local function group_items(item, idx)
  local category = item.item.action.category

  if #category == 0 then
    item.text = item.text .. " Group"
    return
  end

  local category_item
  if not vim.tbl_contains(vim.tbl_keys(M.groups), category) then
    M.groups[category] = {}

    local text = category .. " ->"
    category_item = {
      formatted = text,
      text = idx .. " " .. text .. " Group",
      item = { idx = idx, ctx = item.item.ctx, action = { name = text, category = category } },
      idx = idx,
    }
  end

  table.insert(M.groups[category], item)
  return category_item
end

local function select_actions(items, _, on_choice)
  M.groups = {}

  local width_name, width_category = 0, 0
  local finder_items, actions, keys = {}, {}, {}
  local categories, category_idx = {}, 0
  local completed = false

  for idx, item in ipairs(items) do
    item.action.name = item.action.name or item.action.title
    item.action.category = item.action.category or ""

    _ = not vim.tbl_contains(categories, item.action.category) and table.insert(categories, item.action.category)

    width_name = math.max(width_name, #item.action.name)
    width_category = math.max(width_category, #item.action.category)

    local key = Config.get_action_opts(item.action.category, item.action.name, "keymap", "picker")

    local picker_item = {
      formatted = item.action.name,
      text = idx .. " " .. item.action.name .. " " .. item.action.category,
      item = item,
      keymap = key,
      idx = idx,
    }

    local category_item = Config.ui.group_actions and group_items(picker_item, idx) or nil
    _ = category_item and table.insert(finder_items, category_item)

    table.insert(finder_items, picker_item)

    if key then
      keys[key] = { key, mode = { "n", "i" }, desc = item.action.name }
      actions[key] = actions.confirm
    end
  end

  actions.confirm = function(picker, item, action)
    if completed then return end
    if #item.item.action.category > 0 and item.text:find("Group") then return actions.open_group(picker, item) end

    item = action and vim.iter(finder_items):find(function(_item)
      return _item.keymap == action.name
    end) or item

    completed = true
    picker:close()

    vim.schedule(function()
      on_choice(item and item.item, item and item.idx)
    end)
  end

  local function apply_filter(picker, text)
    picker.input.filter.search = text
    picker.input.filter.pattern = text:lower()
    picker:find { refresh = false }
  end

  actions.filter_category = function(picker)
    category_idx = category_idx + 1
    local next_category = categories[category_idx % (#categories + 1)] or ""
    apply_filter(picker, next_category)
  end

  actions.open_group = function(picker, item)
    if not item.text:find("Group") then return end
    apply_filter(picker, item.item.action.category)
  end

  actions.close_group = function(picker, item)
    if item and not item.text:find("Group") then return end
    apply_filter(picker, "Group")
  end

  keys[Config.ui.keymaps.filter] = { "filter_category", mode = { "n", "i" }, desc = "Filter by category" }
  keys[Config.ui.keymaps.open_group] = { "open_group", mode = { "n", "i" }, desc = "Open group" }
  keys[Config.ui.keymaps.close_group] = { "close_group", mode = { "n", "i" }, desc = "Close group" }

  actions.picker = snacks_picker.pick {
    source = "select",
    name = "Code actions",

    items = finder_items,
    format = format_item(#finder_items, width_name, width_category),
    sort = { fields = { "category", "formatter", "idx" } },

    layout = { layout = { height = math.floor(math.min(vim.o.lines * 0.8 - 10, #finder_items + 2) + 0.5) } },
    win = { input = { keys = keys } },

    live = true,
    pattern = Config.ui.group_actions and "Group" or "",

    actions = actions,

    on_show = function(picker)
      vim.defer_fn(function()
        picker.opts.live = false
        actions.close_group(picker)
      end, 1000)
    end,

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
