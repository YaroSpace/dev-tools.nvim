---@type Actions
return {
  category = "Debugging",
  filetype = { "lua" },
  actions = {
    {
      title = "Log var under cursor",
      fn = function(action)
        local ctx = action.ctx
        LOG(ctx.edit:get_range())
      end,
    },
  },
}
