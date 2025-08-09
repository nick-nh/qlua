local path     = _G.getScriptPath and _G.getScriptPath() or (arg[0]:gsub('[^\\/]*$', '', 1):gsub('\\', '/'))
package.cpath  = path.."/?.dll"
package.path   = path.."/?.lua"

-- local strin = [[test проверка
-- вторая строка

-- четвертая @:)
-- пятая строка
-- шестая строка

-- emoji ##1F601
-- ]]

local Sec = {NAME = 'Инструмент', SEC_CODE = 'Код'}
local pos = 10
local pos_avg = 123.1
local stop_loss = 110.2
local take_profit = 140.3
local strin = '&#9989 Внимание!\n\n'
strin = strin..Sec.NAME..', '..Sec.SEC_CODE..'\n\n'
strin = strin..'Открытие позиции '..(pos > 0 and 'ЛОНГ' or (pos < 0 and 'ШОРТ' or '---'))..'\n\n'
strin = strin..'&#128309 Цена открытия '..tostring(pos_avg)..'\n\n'
strin = strin..'&#128308 Уровень стоп-заявки '..tostring(stop_loss)..'\n\n'
strin = strin..'&#127919 Уровень тейк-профит '..tostring(take_profit)..'\n\n'


--Вариант отправки текста
text = strin

--JSON вариант
-- text = ([[{
--     "Message": "strin",
--     "Telegram": {
--         "ChatId": "13627367",
--         "ParseMode": "HTML",
--         "ReplyToMessageId": "56"
--     }
-- }]]):gsub('strin', strin)


_G._tostring = tostring

local table_to_string
table_to_string = function(value, show_number_keys, miss_key, done)
    local str = ''
    if show_number_keys == nil then show_number_keys = true end
    miss_key = miss_key or ''

    done = done or {}

    if (type(value) ~= 'table') then
        if (type(value) == 'string') then
            str = string.format("%q", value)
        else
            str = _G._tostring(value)
        end
      elseif not done [value] then
        done[value] = true
        local auxTable = {}
        local max_index = #value
        for key in pairs(value) do
            if type(key) ~= "table" and type(key) ~= "function" and type(key) ~= "boolean" and tostring(key):sub(1,2) ~= '__' then
                if not miss_key:find(key) and value[key] ~= nil then
                    if (tonumber(key) ~= key) then
                        table.insert(auxTable, key)
                    else
                        table.insert(auxTable, string.rep('0', max_index-_G._tostring(key):len()).._G._tostring(key))
                    end
                end
            end
        end
        table.sort(auxTable)

        str = str..'{'
        local separator = ""
        local entry
        for _, fieldName in ipairs(auxTable) do
            local prefix = fieldName..' = '
            if ((tonumber(fieldName)) and (tonumber(fieldName) > 0)) then
                fieldName = tonumber(fieldName)
                prefix    = (show_number_keys and "[".._G._tostring(tonumber(fieldName)).."] = " or '')
            end
            entry = value[fieldName]
            -- Check the value type
            if type(entry) == "table" and getmetatable(entry) == nil then
                entry = table_to_string(entry, show_number_keys, miss_key, done)
            elseif type(entry) == "boolean" then
                entry = _G._tostring(entry)
            elseif type(entry) == "number" then
                entry = _G._tostring(entry)
            else
                entry = "\"".._G._tostring(entry).."\""
            end
            entry = prefix..entry
            str = str..separator..entry
            separator = ", "
        end
        str = str..'}'
    end
    return str
end

_G.tostring = function(x, ...)
    if type(x) == "table" and getmetatable(x) == nil then
        return table_to_string(x, ...)
    else
        return _G._tostring(x)
    end
end

if _G.message then
   _G.print = function(...)
      local n = select('#', ...)
      if n == 1 then
         _G.message(tostring(select(1, ...)))
         return
      end
      local t = {}
      for i = 1, n do
         t[#t + 1] = tostring((select(i, ...)))
      end
      _G.message(table.concat(t, " "))
   end
end

--Пример запуска сервера отправки
--    os.execute('start cmd /c call "'..path..'\\telegramServer\\startTeleServer.bat'..'"')

--отправка сообщения:
local function SendTeleMessage(msg, pipe_name)
   local tele_pipe = io.open("\\\\.\\PIPE\\"..pipe_name, "wb") -- открываем именованный канал
   if not tele_pipe then
       return false
   end
   tele_pipe:write(msg) -- записываем сообщение в канал
   tele_pipe:close() -- закрываем канал
end

SendTeleMessage(strin, 'telegram_pipe')

-- Получение сообщений из канала сервера отправки сообщений
---@param pipe_name string
local function GetTeleMessage(pipe_name)
    assert(type(pipe_name) == 'string', 'GetTeleMessage: pipe_name is empty')

    local tele_pipe = io.open("\\\\.\\PIPE\\out_"..pipe_name, "rb")
    if not tele_pipe then
        return false,  'Can\'t open channel out_'..pipe_name
    end

    local rd = ''
    local ct = os.time()

    while os.time() - ct < 2 and rd == '' do
        rd = tele_pipe:read('*a')
    end
    tele_pipe:close()

    if type(rd) == 'string' then
        local t = assert(load('return '..rd))()
        if type(t) == 'table' then
           return t
        end
     end
    return rd
end

local str = GetTeleMessage('telegram_pipe')

print(tostring(str))

if type(str) == 'string' then

   local t = assert(load('return '..str))()

   if type(t) == 'table' then
      print(t[1])
      print(t[2])
   end
end