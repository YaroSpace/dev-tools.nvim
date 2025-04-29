local defaults = {
  filetypes = {
    include = { "lua" },
    exclude = {},
  },
}

local function merge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      merge(dst[k], v)
    else
      dst[k] = v
    end
  end

  return dst
end

local M = setmetatable(defaults, {
  __index = {
    setup = function(opts)
      merge(M, opts)
    end,
  },
})

return M
