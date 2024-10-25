local path     = _G.getScriptPath and _G.getScriptPath() or (arg[0]:gsub('[^\\/]*$', '', 1):gsub('\\', '/'))
package.cpath  = path.."/?.dll"
package.path   = path.."/?.lua"
local progVersion = '1.02' 	--от 22.08.2024
local script = {}
local pipe_name = 'telegram_pipe'
local strin = [[test from Quik
emoji ##1F601
]]

--[[
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
]]


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


--- report, из Телеграм получена команда T => Q
function report(m)
	message('report, T => Q: '..m)
end
--- Получение сообщений из канала сервера отправки сообщений
function getFromChannels()
	getTQ(pipe_name)
end
--- Получение сообщений из канала сервера отправки сообщений
function getTQ(pipe)
	local str = GetTeleMessage(pipe)
	if type(str) == 'string' then
	   local t = assert(load('return '..str))()
	   if type(t) == 'table' then
			for i, v in pairs(t) do
			  message(v)
			end
	   end
	elseif type(str) == 'table' then
		for i, v in pairs(str) do
			if v ~= 'No new messages' then
				---message('T => Q: '..v)
				report(v)
			---else
			---	message('Сообщений нет!')
			end
		end
	end

end

function OnInit(script_path)
	local Terminal_Version = getInfoParam('VERSION')
	script.path, script.filename, script.ext = script_path:match("^%s*(.-)([^\\/]-)%.?([^%.\\/]*)%s*$")
	local mes = 'Start telegramQuik '..script.filename..' '..progVersion..', QUIK '..Terminal_Version
	message(mes)
	SendTeleMessage(mes, 'telegram_pipe')
	is_run = true
end

--- 2.2.24 Функция вызывается терминалом QUIK при остановке скрипта из диалога управления.
function OnStop()
	is_run = false
	local m = 'Stop '..script.filename..'!'
	message(m) 
	SendTeleMessage(m, 'telegram_pipe')
end

function main()
	while is_run do
		getFromChannels()
		sleep(1000)
	end
end