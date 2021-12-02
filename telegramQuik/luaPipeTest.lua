local path     = _G.getScriptPath and _G.getScriptPath() or (arg[0]:gsub('[^\\/]*$', '', 1):gsub('\\', '/'))
package.cpath  = path.."/?.dll"
package.path   = path.."/?.lua"

require('luaPipe')

local strin = [[test проверка
вторая строка

четвертая @:)
пятая строка
шестая строка
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

print(_G.luaPipe.SendMessage(strin, 'email_pipe') and 'Отправлено' or 'Ошибка')
print(_G.luaPipe.SendMessage(strin, 'telegram_pipe') and 'Отправлено' or 'Ошибка')
local str = _G.luaPipe.GetIncomeMessages('telegram_pipe')

print(tostring(str))

if type(str) == 'string' then

   local t = assert(load('return '..str))()

   if type(t) == 'table' then
      print(t[1])
      print(t[2])
   end
end


--Использование без библиотеки luaPipe

--отправка сообщения:
local function SendTeleMessage(msg, pipe_name)
   local tele_pipe = io.open("\\\\.\\PIPE\\"..pipe_name, "w+b") -- открываем именованный канал
   if not tele_pipe then
       return false
   end
   tele_pipe:write(msg) -- записываем сообщение в канал
   tele_pipe:close() -- закрываем канал
end

SendTeleMessage('test io.open', 'telegram_pipe')

--чтение сообщений:

local function GetTeleMessage(pipe_name)
   -- Аналогично прошлому примеру записываем в канал команду GetTeleMessage, чтобы сервер отправки вернул нам накопленные сообщения
    local tele_pipe = io.open("\\\\.\\PIPE\\"..pipe_name, "w+b")
    if not tele_pipe then
        return false
    end
    tele_pipe:write('GetIncomeMessages()') -- записываем команду в канал

    local rd = ''
    local ct = os.time()
    -- Т.к. время ожидания ответа может быть не мгновенным, то ожидаем 2 секунды, читая из канала ответ.
    while os.time() - ct < 2 and rd == '' do
        rd = tele_pipe:read('*a')
    end
    tele_pipe:close() -- закрываем канал

    --Формат возврата - сериализованная таблица сообщений в виде строки
    if type(rd) == 'string' then
        local t = assert(loadstring('return '..rd))() -- загружаем в таблицу
        if type(t) == 'table' then
           return t
        end
    end
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