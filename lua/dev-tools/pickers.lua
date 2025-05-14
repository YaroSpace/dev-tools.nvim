local has_snacks, snacks_picker = pcall(require, "snacks.picker")
local Config = require("dev-tools.config")

local M = { groups = {}, max_width = { name = 0, group = 0, item = 0 }, no_group = 0 }

---@return snacks.picker.format
local function format_item(count)
  return function(item)
    local ret = {} ---@type snacks.picker.Highlight[]

    local idx = tostring(item.idx)
    idx = (" "):rep(#tostring(count) - #idx) .. idx

    table.insert(ret, { idx .. ".", "SnacksPickerIdx" })
    table.insert(ret, { " " })

    local action, ctx = item.item.action, item.item.ctx
    local client = vim.lsp.get_client_by_id(ctx.client_id)

    local keymap = item.keymap or ""

    table.insert(ret, { action.name .. (" "):rep(M.max_width.name - #action.name) })
    table.insert(ret, { " " })

    table.insert(ret, { keymap .. (" "):rep(5 - #keymap), "SnacksPickerSpecial" })
    table.insert(ret, { " " })

    table.insert(ret, { action.group .. (" "):rep(M.max_width.group - #action.group), "Number" })

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
  local group = item.item.action.group

  if #group == 0 then
    item.text = item.text .. " Group" -- add generic group name "Group", so ungrouped actions get shown in the grouped list
    M.no_group = M.no_group + 1
    return
  end

  local group_item
  if not vim.tbl_contains(M.groups, group) then
    table.insert(M.groups, group)

    local text = group .. " ->"
    group_item = {
      formatted = text,
      text = idx .. " " .. text .. " Group",
      item = { idx = idx, ctx = item.item.ctx, action = { name = text, group = group } },
      idx = idx,
    }
  end

  return group_item
end

local function select_actions(items, _, on_choice)
  M.groups = {}
  M.no_group = 0

  local group_idx = 0
  local finder_items, actions, keys = {}, {}, {}
  local completed = false

  actions.confirm = function(picker, item, action)
    if completed then return end

    item = action and vim.iter(finder_items):find(function(_item)
      return _item.keymap == action.name
    end) or item

    if #item.item.action.group > 0 and item.text:find("Group") then return actions.open_group(picker, item) end

    completed = true
    picker:close()

    vim.schedule(function()
      on_choice(item and item.item, item and item.idx)
    end)
  end

  local function get_list_width(count, picker_item)
    local item = format_item(count)(picker_item)
    local line = vim
      .iter(item)
      :map(function(col)
        return col[1]
      end)
      :flatten()
      :totable()
    return #table.concat(line, "") + 7
  end

  local function get_list_height(count)
    return math.floor(math.min(vim.o.lines * 0.8 - 10, count + 2) + 0.5)
  end

  for idx, item in ipairs(items) do
    item.action.name = item.action.name or item.action.title
    item.action.group = item.action.group or ""

    local keymap = Config.get_action_opts(item.action.group, item.action.name, "keymap", "picker")

    local picker_item = {
      formatted = item.action.name,
      text = idx .. " " .. item.action.name .. " " .. item.action.group,
      item = item,
      keymap = keymap,
      idx = idx,
    }

    local group_item = group_items(picker_item, idx)
    _ = Config.ui.group_actions and group_item and table.insert(finder_items, group_item)

    M.max_width = {
      name = math.max(M.max_width.name, #item.action.name),
      group = math.max(M.max_width.group, #item.action.group),
      item = math.max(M.max_width.item, get_list_width(#finder_items, picker_item)),
    }

    table.insert(finder_items, picker_item)

    if keymap then
      keys[keymap] = { keymap, mode = { "n", "i" }, desc = item.action.name }
      actions[keymap] = actions.confirm
    end
  end

  local function resize_picker(picker)
    local layout = vim.deepcopy(picker.resolved_layout)
    layout.layout.height = get_list_height(#picker.list.items)
    picker:set_layout(layout)
  end

  local function apply_filter(picker, text)
    picker.input.filter.search = text
    picker.input.filter.pattern = text:lower()
    picker:find {
      on_done = vim.schedule_wrap(function()
        resize_picker(picker)
      end),
    }
  end

  actions.filter_group = function(picker)
    group_idx = group_idx + 1
    local next_group = M.groups[group_idx % (#M.groups + 1)] or ""
    apply_filter(picker, next_group)
  end

  actions.open_group = function(picker, item)
    if item and not item.text:find("Group") then return end
    apply_filter(picker, item and item.item.action.group or "")
  end

  actions.close_group = function(picker)
    _ = Config.ui.group_actions and apply_filter(picker, "Group")
  end

  keys[Config.ui.keymaps.filter] = { "filter_group", mode = { "n", "i" }, desc = "Filter by group" }
  keys[Config.ui.keymaps.open_group] = { "open_group", mode = { "n", "i" }, desc = "Open group" }
  keys[Config.ui.keymaps.close_group] = { "close_group", mode = { "n", "i" }, desc = "Close group" }

  actions.picker = snacks_picker.pick {
    source = "select",
    title = "Code actions",

    items = finder_items,
    format = format_item(#finder_items),

    layout = {
      layout = {
        height = get_list_height(Config.ui.group_actions and (#M.groups + M.no_group) or #finder_items),

        width = M.max_width.item,
      },
    },
    win = { input = { keys = keys } },

    live = true,
    pattern = Config.ui.group_actions and "Group" or "",
    sort = { fields = { "group", "formatter", "idx" } },

    actions = actions,

    on_show = function(picker)
      vim.defer_fn(function()
        picker.opts.live = false
        _ = Config.ui.group_actions and actions.close_group(picker)
      end, 300)
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
