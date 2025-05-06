local has_snacks, snacks_picker = pcall(require, "snacks.picker")

local M = {}

---@return snacks.picker.format
function format_item(count, width_title, width_category)
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

    return ret
  end
end

local function select_actions(items, _, on_choice)
  local width_title, width_category = 0, 0
  local finder_items, actions, keys = {}, {}, {}
  local completed = false

  local function run_action(picker, item, action)
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

  actions.confirm = run_action

  for idx, item in ipairs(items) do
    local text = item.action.title

    item.action._title = item.action._title or item.action.title
    item.action.category = item.action.category or ""

    width_title = math.max(width_title, #item.action._title)
    width_category = math.max(width_category, #item.action.category)

    local key = item.action.keymap

    table.insert(finder_items, {
      formatted = text,
      text = idx .. " " .. text,
      item = item,
      keymap = key,
      idx = idx,
    })

    if key then
      keys[key] = { key, mode = { "n", "i" }, desc = item.action._title }
      actions[key] = run_action
    end
  end

  local height = math.floor(math.min(vim.o.lines * 0.8 - 10, #items + 2) + 0.5)

  return snacks_picker.pick {
    source = "select",
    items = finder_items,
    format = format_item(#items, width_title, width_category),
    title = "Code actions",
    layout = { preview = false, layout = { height = height } },

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
