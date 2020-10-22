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
