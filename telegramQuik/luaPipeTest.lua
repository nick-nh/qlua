local path     = _G.getScriptPath and _G.getScriptPath() or (arg[0]:gsub('[^\\/]*$', '', 1):gsub('\\', '/'))
package.cpath  = path.."/?.dll"
package.path   = path.."/?.lua"

require('luaPipe')
require "ansi2utf8"

local strin = AnsiToUtf8([[test проверка
вторая строка

четвертая @:)]])


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


print(_G.luaPipe.SendMessage('  '..strin, 'telegram_pipe') and 'Отправлено' or 'Ошибка')