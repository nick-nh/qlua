--
-- log.lua
--
local string_format   = string.format
local table_insert    = table.insert
local table_sort      = table.sort
local math_floor      = math.floor
local math_tointeger  = math.tointeger

local message         = _G['message']

local log             = { _version = "0.2.0" }

log.show_message      = false
log.outfile           = nil
log.use_err_file      = false
log.err_outfile       = nil
log.filename_prefix   = nil
log.outfile_mode      = 'w'
log.level             = "trace"
log.line_info_levels  = "debug|error|fatal"

local modes = {
  { name = "trace"},
  { name = "debug"},
  { name = "info"},
  { name = "warn"},
  { name = "error"},
  { name = "fail"},
}

log.err_level         = 5

local levels = {}
for i, v in ipairs(modes) do
  levels[v.name] = i
end


log.closefile = function()
  if log.outfile then
    log.outfile:close()
    log.outfile = nil
  end
end
log.close_err_file = function()
  if log.err_outfile then
    log.err_outfile:close()
    log.err_outfile = nil
  end
end

log.openfile = function(filename)
  if log.outfile then
    log.closefile()
  end
  if filename then
    local fp  = io.open(filename, log.outfile_mode)
    if (fp) then
      log.outfile   = fp
      log.filename  = filename
      return true
    else
      return nil, string_format("file `%s' could not be opened for writing", filename)
    end
  end
  return false
end

log.open_err_file = function()
  if log.err_outfile then
    log.close_err_file()
  end
  if log.err_filename then
    local fp  = io.open(log.err_filename, log.outfile_mode)
    if (fp) then
      log.err_outfile = fp
      return true
    else
      return nil, string_format("file `%s' could not be opened for writing", log.err_filename)
    end
  end
  return false
end

_G._tostring = tostring

local format_value = function(x)
  if type(x) == "number" and (math_floor(x) == x) then
    return _VERSION == "Lua 5.1" and string_format("%0.16g", x) or _G._tostring(math_tointeger(x) or x)
  end
  return _G._tostring(x)
end

local table_to_string
table_to_string = function(value, show_number_keys, miss_key, done)
    local str = ''
    if show_number_keys == nil then show_number_keys = true end
    miss_key = miss_key or ''

    local done = done or {}

    if (type(value) ~= 'table') then
        if (type(value) == 'string') then
            str = string_format("%q", value)
        else
            str = format_value(value)
        end
      elseif not done [value] then
        done[value] = true
        local auxTable = {}
        local max_index = #value
        for key in pairs(value) do
            if type(key) ~= "table" and type(key) ~= "function" then
                if not miss_key:find(key) and value[key] ~= nil then
                    if (tonumber(key) ~= key) then
                        table_insert(auxTable, key)
                    else
                        table_insert(auxTable, string.rep('0', max_index-format_value(key):len())..format_value(key))
                    end
                end
            end
        end
        table_sort(auxTable)

        str = str..'{'
        local separator = ""
        local entry
        for _, fieldName in ipairs(auxTable) do
            local prefix = fieldName..' = '
            if ((tonumber(fieldName)) and (tonumber(fieldName) > 0)) then
                fieldName = tonumber(fieldName)
                prefix    = (show_number_keys and "["..format_value(tonumber(fieldName)).."] = " or '')
            end
            entry = value[fieldName]
            -- Check the value type
            if type(entry) == "table" and getmetatable(entry) == nil then
                entry = table_to_string(entry, show_number_keys, miss_key, done)
            elseif type(entry) == "boolean" then
                entry = _G._tostring(entry)
            elseif type(entry) == "number" then
                entry = format_value(entry)
            else
                entry = "\""..format_value(entry).."\""
            end
            entry = prefix..entry
            str = str..separator..entry
            separator = ", "
        end
        str = str..'}'
    end
    return str
end

_G.tostring = function(x)
    if type(x) == "table" and getmetatable(x) == nil then
      return table_to_string(x)
    else
      return format_value(x)
    end
end

log.tostring = function(...)
  local n = select('#', ...)
  if n == 1 then
    return tostring(select(1, ...))
  end
  local t = {}
  for i = 1, n do
    t[#t + 1] = tostring((select(i, ...)))
  end
  return table.concat(t, " ")
end

for i, x in ipairs(modes) do
  local nameupper = x.name:upper()
  log[x.name] = function(...)

    -- Return early if we're below the log level
    if i < levels[log.level] then
      return
    end

    if not log.outfile then return end

    local msg       = log.tostring(...)
    local lineinfo  = ""
    if log.line_info_levels:find(modes[i].name) then
      local info      = debug.getinfo(2, "Sl")
      local src_path  = info.short_src
      lineinfo        = (log.filename_prefix and (log.filename_prefix..src_path:match("[^/\\]+$")) or src_path).. ":" .. info.currentline
    end

    local str = string_format("[%-6s%s] %s: %s\n",
                              nameupper, os.date('%Y-%m-%d %H:%M:%S'),
                              lineinfo,
                              msg)

    -- Output to console
    if log.show_message then
      message(str)
    end

    if log.use_err_file and i >= log.err_level then
      if not log.err_outfile then
        local is_open, mes = log.open_err_file()
        log.use_err_file = is_open
        if not is_open then
          local err_str = string_format("[%-6s%s] %s: \n",
                                    nameupper, os.date('%Y-%m-%d %H:%M:%S'),
                                    mes)
          log.outfile:write(err_str)
          log.outfile:flush()
        end
      end
      if log.err_outfile then
        log.err_outfile:write(str)
        log.err_outfile:flush()
      end
    end

    -- Output to log file
    if log.outfile then
      log.outfile:write(str)
      log.outfile:flush()
    end

  end
end


return log