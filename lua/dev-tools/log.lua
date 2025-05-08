local LOG = { calls_no = 1, last_call = 0 }
local sep_line = "\n\n===============================================================>>\n\n"

local function get_locals(level)
  level = level or 1
  local status, name, value = true, "", nil
  local idx, locals = 1, {}

  while name do
    status, name, value = pcall(debug.getlocal, level, idx)
    if not (status and name) then break end

    locals[name] = value
    idx = idx + 1
  end

  return locals
end

local function get_spec_info()
  local locals
  for i = 1, 20 do
    locals = get_locals(i)
    if locals.descriptor == "it" then return locals.element.trace end
  end
end

LOG.spec = function(...)
  local spec_info = get_spec_info() or {}
  spec_info = vim.fn.fnamemodify(spec_info.short_src, ":t") .. ":" .. (spec_info.currentline or "")
  LOG.log(spec_info, ...)
end

LOG.log = function(...) --luacheck: ignore
  local func = { name = "", short_src = "", current_line = "" }
  local caller = vim.tbl_extend("force", func, debug.getinfo(2) or {})

  if caller.name:find("pcall") or (caller.short_src):find("log%.lua") then caller = vim.tbl_extend("force", func, debug.getinfo(3) or {}) end

  local caller_path = caller.short_src
  local path_dirs = vim.split(vim.fs.dirname(caller_path), "/")
  caller_path = path_dirs[#path_dirs] .. "/" .. vim.fs.basename(caller_path)

  ---@diagnostic disable-next-line: undefined-field
  local time = vim.uv.clock_gettime("monotonic").sec
  if time - LOG.last_call > 5 then
    LOG.calls_no = 1
    LOG.last_call = time
  end

  local prefix = ("LOG #%s (%s:%s:%s) =>\n"):format(LOG.calls_no, caller_path, caller.name, caller.currentline)

  local result = ""
  local nargs = select("#", ...)
  local var_no, sep = "", (" "):rep(4)

  for i = 1, nargs do
    local o = select(i, ...)

    if i > 1 then result = result .. ",\n" end
    if nargs > 1 then var_no = string.format("[%s] ", i) end

    o = type(o) == "function" and debug.getinfo(o) or o
    o = type(o) == "table" and vim.inspect(o):gsub("[{,] ", "%1\n" .. sep) or vim.inspect(o)
    result = result .. var_no .. o
  end

  local out = vim.in_fast_event() and vim.schedule_wrap(vim.notify) or vim.notify

  _ = LOG.calls_no == 1 and out(sep_line)
  out(prefix .. result .. "\n")

  LOG.calls_no = LOG.calls_no + 1
  return result
end

LOG.trace = function(...)
  local trace = debug.traceback()
  if not trace then return end

  ---@diagnostic disable-next-line: cast-local-type
  trace = vim.split(trace, "\n")
  table.remove(trace, 1)
  table.remove(trace, 1)

  local ret = {}
  for i, line in pairs(trace) do
    line = line:gsub("\t", "")
    if not line:find("pcall") then ret[string.char(i + 64)] = line end
  end

  LOG.log("TRACE", ret, ...)
end

LOG.iff = function(predicate, ...)
  if type(predicate) == "function" and predicate() or predicate then LOG.log(...) end
end

LOG.reset = function()
  LOG.calls_no = 1
end

return setmetatable(LOG, { __index = LOG })
