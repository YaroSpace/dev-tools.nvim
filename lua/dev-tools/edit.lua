---@class Edit: Ctx
---@field get_lines fun(self: Edit, l_start?: number, l_end?: number): string[] - get lines in the buffer
---@field set_lines fun(self: Edit, lines: string[], l_start?: number, l_end?: number) - set lines in the buffer
---@field get_range fun(self: Edit, ls?: number, cs?: number, le?: number, ce?: number): string[] - get lines in the range of the buffer
---@field set_range fun(self: Edit, lines: string[], ls?: number, cs?: number, le?: number, ce?: number) - set lines in range of the buffer
---@field get_node fun(self: Edit, types: string|string[], node?: TSNode|nil, predicate?: fun(node: TSNode): boolean| nil): TSNode|nil, table <number, number, number, number>|nil - traverses up the tree to find the first TS node matching specified type/s
---@field get_previous_node fun(self: Edit, node: TSNode, allow_switch_parents?: boolean, allow_previous_parent?: boolean): TSNode|nil - get previous node with same parent
---@field get_node_text fun(self: Edit, node?: TSNode): string|nil - get the text of the node
---@field indent fun(self: Edit, l_start?: number, l_end?: number) - indent range in the buffer
---@field set_cursor fun(self: Edit, row?: number, col?: number) - set the cursor in the buffer
---@field write fun() - write the buffer

local M = {}

---Traverses up the tree to find the first TS node matching specified type/s
---@param types string|string[]
---@param node? TSNode|nil
---@param predicate? fun(node: TSNode): boolean| nil
---@return TSNode|nil
---@return table <number, number, number, number>|nil
M.get_node = function(ctx, types, node, predicate)
  local ts = vim.treesitter
  predicate = predicate or function()
    return true
  end

  node = node or ts.get_node { bufnr = ctx.buf, pos = { ctx.row, ctx.col } }
  if not node then return end

  types = type(types) == "string" and { types } or types

  if vim.tbl_contains(types, node:type()) and predicate(node) then return node, { node:range() } end
  if node:type() == "chunk" or not node:parent() then return end

  return M.get_node(ctx, types, node:parent(), predicate)
end

-- Get previous node with same parent
---@param ctx Ctx
---@param node TSNode
---@param allow_switch_parents? boolean - allow switching parents if first node
---@param allow_previous_parent? boolean - allow previous parent if first node and previous parent without children
function M.get_previous_node(ctx, node, allow_switch_parents, allow_previous_parent)
  local destination_node ---@type TSNode

  local parent = node:parent()
  if not parent then return end

  local found_pos = 0
  for i = 0, parent:named_child_count() - 1, 1 do
    if parent:named_child(i) == node then
      found_pos = i
      break
    end
  end

  if 0 < found_pos then
    destination_node = parent:named_child(found_pos - 1)
  elseif allow_switch_parents then
    local previous_node = M:get_previous_node(node:parent())

    if previous_node and previous_node:named_child_count() > 0 then
      destination_node = previous_node:named_child(previous_node:named_child_count() - 1)
    elseif previous_node and allow_previous_parent then
      destination_node = previous_node
    end
  end

  return destination_node
end

---Get the text of the node
---@param ctx Ctx
---@param node? TSNode|nil
M.get_node_text = function(ctx, node)
  local ts = vim.treesitter

  node = node or ts:get_node()
  if not node then return end

  return ts.get_node_text(node, ctx.buf)
end

---Get the lines in the buffer
---@param ctx Ctx
---@param l_start? number
---@param l_end? number
---@return string[]
M.get_lines = function(ctx, l_start, l_end)
  return vim.api.nvim_buf_get_lines(ctx.buf, l_start or ctx.range.rc[1], l_end or ctx.range.rc[3] + 1, false)
end

---Set lines in the buffer
---@param ctx Ctx
---@param lines string[]
---@param l_start? number
---@param l_end? number
M.set_lines = function(ctx, lines, l_start, l_end)
  vim.api.nvim_buf_set_lines(ctx.buf, l_start or ctx.range.rc[1], l_end or ctx.range.rc[3] + 1, false, lines)
end

---Get the lines in the range of the buffer
---@param ctx Ctx
M.get_range = function(ctx, ls, cs, le, ce)
  return vim.api.nvim_buf_get_text(ctx.buf, ls or ctx.range.rc[1], cs or ctx.range.rc[2], le or ctx.range.rc[3], ce or ctx.range.rc[4], {})
end

---Set the lines range of the buffer
---@param ctx Ctx
---@param lines string[]
M.set_range = function(ctx, lines, ls, cs, le, ce)
  vim.api.nvim_buf_set_text(ctx.buf, ls or ctx.range.rc[1], cs or ctx.range.rc[2], le or ctx.range.rc[3], ce or ctx.range.rc[4], lines)
end

---Indent range in the buffer
---@param ctx Ctx
---@param l_start? number
---@param l_end? number
M.indent = function(ctx, l_start, l_end)
  l_start = l_start or ctx.range.rc[1] or ctx.row
  l_end = l_end or ctx.range.rc[3] or ctx.row

  vim.api.nvim_win_set_cursor(ctx.win, { l_start, 0 })
  vim.cmd("normal V" .. l_end - l_start .. "j=")
  vim.api.nvim_input("<Esc>")
end

--- Set the cursor in the buffer
---@param ctx Ctx
---@param row? number
---@param col? number
M.set_cursor = function(ctx, row, col)
  vim.api.nvim_win_set_cursor(ctx.win, { row or ctx.range.rc[1] or ctx.row, col or ctx.range.rc[2] or ctx.col })
end

--- Write the buffer
M.write = function()
  vim.cmd.write()
end

---@type Edit
return M
