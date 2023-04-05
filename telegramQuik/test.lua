local path     = _G.getScriptPath and _G.getScriptPath() or (arg[0]:gsub('[^\\/]*$', '', 1):gsub('\\', '/'))
package.cpath  = path.."/?.dll"
package.path   = path.."/?.lua"

local strin = [[test проверка
вторая строка

четвертая @:)
пятая строка
шестая строка

emoji ##1F601
]]

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

--чтение сообщений:
--depricated
-- local function GetTeleMessage(pipe_name)
--    -- Аналогично прошлому примеру записываем в канал команду GetTeleMessage, чтобы сервер отправки вернул нам накопленные сообщения
--     local tele_pipe = io.open("\\\\.\\PIPE\\"..pipe_name, "w+b")
--     if not tele_pipe then
--         return false
--     end
--     tele_pipe:write('GetIncomeMessages()') -- записываем команду в канал

--     local rd = ''
--     local ct = os.time()
--     -- Т.к. время ожидания ответа может быть не мгновенным, то ожидаем 2 секунды, читая из канала ответ.
--     while os.time() - ct < 2 and rd == '' do
--         rd = tele_pipe:read('*a')
--     end
--     tele_pipe:close() -- закрываем канал

--     --Формат возврата - сериализованная таблица сообщений в виде строки
--     if type(rd) == 'string' then
--         local t = assert(loadstring('return '..rd))() -- загружаем в таблицу
--         if type(t) == 'table' then
--            return t
--         end
--     end
-- end

-- Новая версия чтения. Раздельные каналы. Какнал чтения имеет префик out_
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