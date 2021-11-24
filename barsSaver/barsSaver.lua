_G.unpack       = rawget(table, "unpack") or _G.unpack
_G.loadfile     = _G.loadfile or _G.load
_G.loadstring   = _G.loadstring or _G.load

local LICENSE = {
    _VERSION     = 'barsSaver 2021.11.24',
    _DESCRIPTION = 'quik sec scaner',
    _AUTHOR      = 'nnh: nick-h@yandex.ru'
}

local sleep                 = _G.sleep
local message               = _G.message
local isConnected           = _G.isConnected
local getScriptPath         = _G.getScriptPath
local getInfoParam          = _G.getInfoParam
local getNumberOf           = _G.getNumberOf

local math_abs              = math.abs
local math_floor            = math.floor
local math_ceil             = math.ceil
local string_len            = string.len
local string_format         = string.format
local string_match          = string.match
local string_gmatch         = string.gmatch
local string_gsub           = string.gsub
local tonumber              = tonumber
local os_time               = os.time
local os_date               = os.date

local NAME_OF_STRATEGY      = 'barsSaver'

local Path                  = getScriptPath()
local version               =_VERSION:gsub('Lua ', ''):gsub('%.', '')

---@param path string
local check_path = function(path)
    if type(path) ~= 'string' then  error(("bad argument path (string expected, got %s)"):format(type(path)),2) end

    local tmp_file = io.open(path)
    if tmp_file then
        tmp_file:close()
        return true
    end
end

package.path = Path.."/?.lua;"..Path.."/algorithms/?.lua;"..Path.."/libs/?.lua;"..Path.."/commonLibs/?.lua;"..package.path..';'
package.cpath = Path.."/?.dll;"..Path.."/libs/?.dll;"..Path.."/commonLibs/?.dll;"..Path.."/commonLibs/telegramServer/lua"..version.."/?.dll;"..package.cpath..';'

local t_path = {}
for part in Path:gmatch("[^/\\]+") do
    t_path[#t_path + 1] = part
end

if #t_path>1 then
	for j = 1, #t_path-1 do
		local UpPath = ''
		for i= 1,j do
			UpPath = UpPath..t_path[i]..'\\'
		end
		package.path = package.path..UpPath.."libs/?.lua;"..UpPath.."commonLibs/?.lua;"
		package.cpath = package.cpath..UpPath.."commonLibs/?.dll;"..UpPath.."/telegramServer/?.dll;"..UpPath.."/commonLibs/telegramServer/?.dll;"
    end
end

local log   = require("log")
local maLib = require("maLib")
local DATA_METHODS                      = {'Open', 'High', 'Low', 'Close'}

local Params = {}
--====================================================================================
--Задержка основного цикла
Params.main_delay                       = 1000

--Каталог хранения выгружаемых данных
Params.DATA_FOLDER                      = Path.."\\data"

--Сохранять только историю.
-- 0 - выключено. В этом режиме скрипт в фоне контролирует получение новых баров и сохраняет их в файл.
Params.ONLY_HISTORY                     = 1

--Разделитель дробной числа:
-- 0 - разделитель точка
-- 1 - разделитель запятая
Params.EXCEL_NUM                        = 1

--Временная зона (0, 1, -1, -2...)
Params.TIME_ZONE                        = 0

Params.USE_LOCAL_TIME_AS_SERVER         = 0

--Интервал обновления данных с текущим состоянием c сервера брокера (сек.)
--Задается в настройках терминала в пункте меню «Система» / «Настройки» / «Основные настройки» / «Программа» на вкладке «Получение данных»
--Если время сервера больше времени последнего сообщения чем период опроса, то связь с сервером брокера еще не установлена
-- По умолчанию 1
-- Для отключения проверки необходимо установить значение -1
Params.SERVER_DATA_CYCLE_TIME           = -1

--Допустимое расхождение (в сек.) времени сервера и локального времени рабочего места
-- если -1, то не контролируется
Params.MAX_LOCAL_TO_SERVER_TIME_DIFF    = -1

Params.LOGGING                          = 1 -- признак ведения лога. 1 - выводить, 0 - нет
Params.DEBUG_MODE                       = 1 -- признак вывода в лог отладочной информации. 1 - выводить, 0 - нет

Params.str_startNewDayTime           = '06:00:00' -- Время начала нового дня
Params.str_startTradeTime            = '09:50:00' -- Время начала сканирования
Params.str_endOfDay                  = '23:50:00' -- Окончание торгового дня

local SERVER_TIME                   = nil
local SERVER_DATE                   = nil
local CONNECT_STATE                 = isConnected()
local TIME_ZONE_SHIFT               = 0
local startNewDayTime               = 0
local startTradeTime                = 0
local endOfDay                      = 0

local PrevDayNumber                 = 0
local CheckConnect                  = function() end

local error_count                   = 0
local error_count_limit             = 100
local error_cache                   = {}

local isRun                         = true

local intervals_rep                 = {}
intervals_rep[1]                    = 'M1'
intervals_rep[2]                    = 'M2'
intervals_rep[3]                    = 'M3'
intervals_rep[4]                    = 'M4'
intervals_rep[5]                    = 'M5'
intervals_rep[6]                    = 'M6'
intervals_rep[10]                   = 'M10'
intervals_rep[15]                   = 'M15'
intervals_rep[30]                   = 'M30'
intervals_rep[60]                   = 'H1'
intervals_rep[120]                  = 'H2'
intervals_rep[240]                  = 'H4'
intervals_rep[1440]                 = 'D1'
intervals_rep[10080]                = 'W'
intervals_rep[23200]                = 'M'

local SEC_LIST                      = {}
local DATA_FUNCTOR                  = {}
local OPENED_DS                     = {}
local OPENED_FILES                  = {}
--Структура файла с данными
--Записывается через разделитель в нужном порядке
local DATA_FILE_STRUCT             = 'sec_code;class_code;unix_time;date;time;date_time;index'

--Проверка существования директории
---@param file string
local function DirectoryExists(file)
    if type(file) ~= 'string' then  error(("bad argument file (string expected, got %s)"):format(type(file)),2) end

    local ok, err, code = os.rename(file, file)
    if not ok then
       if code == 13 then
          -- Permission denied, but it exists
          return true, 'Permission denied, but it exists'
       end
    end
    return ok, err
end

local tclone
do
  local function impl(t, t_pointer, visited)
    local t_type = type(t)
    if t_type ~= "table" then
      return t
    end

    assert(not visited[t], "recursion detected")
    visited[t] = true

    local r = t_pointer or {}
    for k, v in pairs(t) do
      r[impl(k, nil, visited)] = impl(v, nil, visited)
    end

    visited[t] = nil

    return r
  end

  tclone = function(t, t_pointer)
    return impl(t, t_pointer, { })
  end
end

---@param s string
---@param sep string
local function split(s, sep)
    return string_gmatch(s, "([^"..sep.."]+)")
end

---@param s string
---@param sep string
local function mysplit(s, sep)

    if sep == nil then
        sep = "%s"
    end
    local t={}
    local i=1
    for str in split(s, sep) do
        t[i] = str
        i = i + 1
    end
    return t
end

---@param number number
local function toExcelNum(number) return Params.EXCEL_NUM == 1 and string_gsub(tostring(number),'[%.]+', ',') or tostring(number) end

--=======================================================================================================
-- Errors
---@param mes string
local function ScriptError(mes)
    if not error_cache[mes] then
        log.error(mes)
        log.error(debug.traceback('Stack traceback', 2))
    end
    error_cache[mes] = error_cache[mes] or 0
    error_cache[mes] = error_cache[mes] + 1
    error_count = error_count + 1
    if error_count_limit ~= 0 and error_count > error_count_limit then
        isRun      = false
        local msg = 'В процессе работы скрипта возникло слишком много ошибок. Скрипт остановлен.'
        message(NAME_OF_STRATEGY..': '..msg, 3)
        log.error('\n\n------------------------- Всего ошибок ---------------------------------------\n')
        for err, count in pairs(error_cache) do
            log.error('Ошибка: ', err, ', ошибок: ', count)
        end
    end
end
-- Errors
--=======================================================================================================

--=======================================================================================================
-- Дата.Время
local function is_date(val)
    local status = pcall(function() return type(val) == "table" and os.time(val); end)
    return status
end

---@param strT string
local function FixStrTime(strT)
    strT=tostring(strT)
    local hour, min, sec = 0, 0, 0
    local len = string_len(strT)
    if len==8 then
       hour,min,sec = string_match(strT,"(%d%d)%p(%d%d)%p(%d%d)")
    elseif len==7 then
        hour,min,sec  = string_match(strT,"(%d)%p(%d%d)%p(%d%d)")
    elseif len==6 then
        hour,min,sec  = string_match(strT,"(%d%d)(%d%d)(%d%d)")
    elseif len==5 then
        hour,min,sec  = string_match(strT,"(%d)(%d%d)(%d%d)")
    elseif len==4 then
        hour,min  = string_match(strT,"(%d%d)(%d%d)")
    end
    return hour,min,sec
end
-- Возвращает текущую дату/время сервера в виде таблицы datetime
local function GetServerDateTime()

    if Params.USE_LOCAL_TIME_AS_SERVER == 1 then return os_date('*t', os_time()-TIME_ZONE_SHIFT) end

    local dt = {}
    -- Пытается получить дату/время сервера
    while isRun and dt.day == nil do
        dt.day,dt.month,dt.year = string_match(getInfoParam('TRADEDATE'),"(%d*).(%d*).(%d*)")
        dt.hour,dt.min,dt.sec   = FixStrTime(getInfoParam("SERVERTIME"))
        -- Если не удалось получить, или разрыв связи,
        -- ждет подключения и подгрузки с сервера актуальных данных
        if not is_date(dt) or isConnected() == 0 then
            return os_date('*t', os_time()-TIME_ZONE_SHIFT)
        end
   end
   -- Если во время ожидания скрипт был остановлен пользователем,
   -- возвращает таблицу datetime даты/времени компьютера,
   -- чтобы не вернуть пустую таблицу и не вызвать ошибку в алгоритме
   if (dt.day or 0) == 0 or (dt.month or 0) == 0 or (dt.year or 0) == 0 then return os_date('*t', os_time()-TIME_ZONE_SHIFT) end

   -- Приводит полученные значения к типу number
   for key,value in pairs(dt) do dt[key] = tonumber(value) end

   -- Возвращает итоговую таблицу
   return dt
end

-- Приводит время из строкового формата ЧЧ:ММ:CC к формату datetime
---@param str_time string
local function StrToTime(str_time, sdt)
    if type(str_time) ~= 'string' then return os_date('*t') end
    sdt         = tclone(sdt or GetServerDateTime())
    if not is_date(sdt) then sdt = os_date('*t', os_time()-TIME_ZONE_SHIFT) end
    local h,m,s = FixStrTime(str_time)
    sdt.hour    = tonumber(h)
    sdt.min     = tonumber(m)
    sdt.sec     = s==nil and 0 or tonumber(s)
    return sdt
end

-- Приводит время из строкового формата ЧЧ:ММ[:CC] к формату datetime
---@param str_time string
---@param sdt table|nil
local function GetStringTime(str_time, sdt)
    return str_time==0 and {} or (StrToTime(#tostring(str_time)<6 and tostring(str_time)..':00' or tostring(str_time), sdt))
end

---@param server_date table|nil
local function InitDaytradeTimes(server_date)
    local status,res = pcall(function()
        server_date = server_date or GetServerDateTime()
        startNewDayTime          = os_time(GetStringTime(Params.str_startNewDayTime, server_date))
        startTradeTime           = os_time(GetStringTime(Params.str_startTradeTime, server_date))
        endOfDay                 = os_time(GetStringTime(Params.str_endOfDay, server_date))
    end)
    if not status then ScriptError('InitDaytradeTimes: '..tostring(res)) end
    return res
end
-- Дата.Время
--=======================================================================================================

--=======================================================================================================
-- Базовые функции скриптов

---@param class_code string
local function isFutures(class_code)
    return (class_code or '') == 'SPBFUT' or (class_code or '') == 'SPBOPT'
end

---@param num number
---@param idp any
local function round(num, idp)
    if num then
        local mult = 10^(idp or 0)
        if num >= 0 then
            return math_floor(num * mult + 0.5) / mult
        else
            return math_ceil(num * mult - 0.5) / mult
        end
    else
        return num
    end
end

-- ---@param str string
-- ---@param sep string
-- local function allWords(str, sep)
--     local pos
--     return function()
--         if str == '' then return nil end
--         pos = string_find(str,sep)
--         if pos then
--             local word = string_sub(str,1,pos-1)
--             str = string_sub(str,pos+1)
--             return word
--         end
--         local word = str
--         str = ''
--         return word
--     end
-- end

function LoadParamsFromFile(file_name, context)
    local status, res = pcall(function()
        if not isRun then return end
        if not check_path(file_name) then return end
        log.debug('LoadParamsFromFile', file_name)
        local load_func
        if _G.setfenv then
            load_func = assert(loadfile(file_name))
            _G.setfenv(load_func, context)
            return load_func()
        else
            load_func = assert(loadfile(file_name, 't', context))
            return load_func()
        end
    end)
    if not status then ScriptError('LoadParamsFromFile: '..tostring(res))
        return
    end
    return res
end

local function CheckConnectProcessor()

    local checked       = false
    local last_state    = false
    return function()
        local status,res = pcall(function()

            if CONNECT_STATE == 0 or getNumberOf("securities") == 0 then
                checked = false
                return checked
            end

            if checked then return true end

            local cur_time      = SERVER_TIME
            local local_time    = os_time() - TIME_ZONE_SHIFT
            local last_rec_time = getInfoParam('LASTRECORDTIME') or 0
            if (last_rec_time or 0)~=0 then
                local dt              = GetServerDateTime()
                dt.hour,dt.min,dt.sec = FixStrTime(tostring(last_rec_time))
                local diff = round(os_time(cur_time) - os_time(dt), 0)
                local local_diff      = math_abs(round(os_time(cur_time) - local_time, 0))
                checked = (Params.SERVER_DATA_CYCLE_TIME <= 0 or diff < Params.SERVER_DATA_CYCLE_TIME) and (Params.MAX_LOCAL_TO_SERVER_TIME_DIFF <= 0 or local_diff < Params.MAX_LOCAL_TO_SERVER_TIME_DIFF)
                local state = checked and 'Данные сервера актуальны, торговля возможна' or 'Данные сервера неактуальны, торговля невозможна'
                if last_state~=state then
                    last_state = state
                    log.info('Время сервера: '..os_date('%Y.%M.%d %H:%M:%S', os_time(cur_time)), 'LASTRECORDTIME:', last_rec_time)
                    log.info('Время последнего сообщения: '..os_date('%Y.%M.%d %H:%M:%S', os_time(dt))..', checked:'..tostring(checked)..', diff:'..tostring(diff))
                    if (Params.MAX_LOCAL_TO_SERVER_TIME_DIFF >= 0 and local_diff > Params.MAX_LOCAL_TO_SERVER_TIME_DIFF) then
                        local mes = 'Локальное время отстает от серверного больше чем:'..tostring(Params.MAX_LOCAL_TO_SERVER_TIME_DIFF)..' секунд'
                        log.info(mes)
                        log.info('CheckConnect Проверьте установки временной зоны')
                        message(mes)
                    end
                end
                return checked
            end
            return false

        end)
        if not status then
            log.error(' CheckConnect: '..tostring(res))
            return false
        end
        return res
    end
end

-- Базовые функции скриптов
--=======================================================================================================

local function on_Init()

    if not DirectoryExists(Path.."\\logs") then
        os.execute("mkdir " .. Path.."\\logs")
    end
    local data_folder = Params.DATA_FOLDER or Path.."\\data"
    if not DirectoryExists(data_folder) then
        os.execute("mkdir " .. data_folder)
    end

    local day_prefix    = os_date('%d-%m-%Y_%H.%M.%S', os_time())
    log.use_err_file    = true
    log.err_filename    = Path.."\\logs\\err_"..NAME_OF_STRATEGY..'_'..day_prefix..".log"

    LoadParamsFromFile(getScriptPath().."\\"..NAME_OF_STRATEGY.."_params.ini", Params)
    TIME_ZONE_SHIFT = Params.TIME_ZONE*60*60
    SERVER_TIME     = os_date('*t', os_time()-TIME_ZONE_SHIFT)
    SERVER_DATE     = os_date('*t', os_time()-TIME_ZONE_SHIFT)
    InitDaytradeTimes()

    if Params.LOGGING == 1 then
        log.openfile(Path.."\\logs\\"..NAME_OF_STRATEGY..'_'..day_prefix..".log")
        log.filename_prefix = NAME_OF_STRATEGY..'\\'
        log.level           = Params.DEBUG_MODE == 0 and 'info' or 'debug'
    end

    log.info('==================================================================================================')
    log.debug('OnInit collectgarbage start ------ ', collectgarbage('count'))

    local quik_version  = getInfoParam("VERSION")
    local quik_bits     = quik_version:sub(1, 2) == '7.' and 'x86' or 'x64'

    local last_version = LICENSE._VERSION:sub(-10)
    log.info('==================================================================================================')
    log.info('OnInit Запуск робота', _G.getInfoParam('USERID'), _G.getInfoParam('TRADEDATE'), 'version', last_version)
    log.info('OnInit quik_version', quik_version)
    log.info('OnInit quik_bits', quik_bits)
    log.info('OnInit lua', version)
    log.info('OnInit VERSIONS: ')
    for _, value in pairs(package.loaded) do
        if type(value) == 'table' and type(value.LICENSE) == 'table' then
            log.info('--- ', value.LICENSE._VERSION)
            last_version = math.max(value.LICENSE._VERSION:sub(-10), last_version)
        end
    end
    log.info('==================================================================================================')

    -- Проверяем, что есть подключение к серверу
    CONNECT_STATE = isConnected()
    if CONNECT_STATE == 0 then
        local msg = NAME_OF_STRATEGY..': Нет подключения к серверу'
        log.warn(msg)
        message(msg, 3)
    end

    SEC_LIST = LoadParamsFromFile(getScriptPath().."\\sec_list.txt")
    log.debug('SEC_LIST', SEC_LIST)
    if type(SEC_LIST) ~= 'table' or #SEC_LIST == 0 then
        local msg = NAME_OF_STRATEGY..': Не определен список инструментов или допущена ошибка в описании'
        log.warn(msg)
        message(msg, 3)
        isRun = false
    end
end

--Получение потока данных для расчета алгоритмических значений
---@param Sec table
---@param interval number
---@return table
function GetDataSource(Sec, interval)
    if type(Sec) ~= 'table' then  error(("bad argument Sec (table expected, got %s)"):format(type(Sec)),2) end
    if type(interval) ~= 'number' then  error(("bad argument interval (number expected, got %s)"):format(type(interval)),2) end

    local status, res, mes = pcall(function()
        if not isRun then return end

        if not intervals_rep[interval] then
            local mes = 'Интервал: '..tostring(interval)..'. ОШИБКА получения неопределенного интервала! '
            log.warn(mes)
            return false, mes
        end

        if OPENED_DS[Sec.sec_code]~=nil and OPENED_DS[Sec.sec_code][interval] ~= nil then
            return OPENED_DS[Sec.sec_code][interval], ''
        end
        local ds, err = _G.CreateDataSource(Sec.class_code,Sec.sec_code,interval)
        if ds == nil then
            local mes = tostring(Sec.sec_code)..'|'..tostring(Sec.class_code)..', интервал: '..tostring(interval)..'. ОШИБКА получения доступа к свечам! '..err
            log.warn(mes)
            -- Завершает выполнение скрипта
            return false, mes
        end

        log.info('Get DataSource: '..' '..Sec.sec_code..', интервал: '..intervals_rep[interval])
        if OPENED_DS[Sec.sec_code] == nil then OPENED_DS[Sec.sec_code] = {} end
        OPENED_DS[Sec.sec_code][interval] = ds
        return ds, ''
    end)

    if status then return res, mes
    else
        ScriptError('GetDataSource: '..tostring(res))
        return false, res
    end

end

local dsClass = {}

---Получение потока даных и текущего индекса для расчета
---@param Sec table
---@param interval number
---@return function
function dsClass:new(Sec, interval)
    if type(Sec) ~= 'table' then  error(("bad argument Sec (table expected, got %s)"):format(type(Sec)),2) end
    if type(interval) ~= 'number' then  error(("bad argument interval (number expected, got %s)"):format(type(interval)),2) end

    local ds, ds_msg = GetDataSource(Sec, interval)
    if not ds then
        message(NAME_OF_STRATEGY..': '..ds_msg, 2)
        return false
    end

    local instance  = {}
    self.__index = self

    instance.index          = 1
    instance.ds             = ds
    instance.interval       = interval
    instance.interval_rep   = intervals_rep[interval]

    instance.LastTime  = function()
        return ds:T(instance.Size())
    end
    instance.T  = function(_, index)
        return ds:T(index)
    end
    instance.O  = function(_, index)
        return ds:O(index)
    end
    instance.V  = function(_, index)
        return ds:V(index)
    end
    instance.C  = function(_, index)
        return ds:C(index)
    end
    instance.H  = function(_, index)
        return ds:H(index)
    end
    instance.L  = function(_, index)
        return ds:L(index)
    end
    instance.Close  = function()
        return ds:Close()
    end
    instance.Size  = function()
        return ds:Size()
    end
    instance.SetUpdateCallback  = function(_, ...)
        return ds:SetUpdateCallback(...)
    end
    instance.SetEmptyCallback  = function(_, ...)
        return ds:SetEmptyCallback(...)
    end

    self.__tostring   = function() return Sec.sec_code..'|'..tostring(Sec.class_code)..': Поток данных интервала: '..tostring(instance.interval_rep) end
    setmetatable(instance, self)

    instance.Next = function()
        if not isRun then return end

        -- log.debug(Sec.sec_code..'|'..tostring(Sec.class_code), interval, 'index', instance.index, 'size', ds:Size())
        if instance.index < ds:Size() - 1 then
            instance.index = instance.index + 1
            return instance.index
        end
    end

    return instance
end

---Расчет по алгоритму и сохранение данных
---@param Sec table
---@param ds table
---@return function
local function DataProcessor(Sec, ds)
    if type(Sec) ~= 'table' then  error(("bad argument Sec (table expected, got %s)"):format(type(Sec)),2) end
    if type(ds) ~= 'table' then  error(("bad argument ds (table expected, got %s)"):format(type(ds)),2) end

    local algo_f = {}
    local algo_m = ''
    local time   = 0
    local algo_lines = ''
    if Sec.algo then
        for k, value in ipairs(Sec.algo) do
            if (value.method or '') ~= '' then
                algo_m = algo_m..(algo_m == '' and '' or '_')..value.method..tostring(k)
                local func, lines = maLib.new(value, ds)
                algo_f[#algo_f+1] = func
                if lines then
                    for i = 1, #lines, 1 do
                        algo_lines = algo_lines..(algo_lines == '' and '' or ';')..lines[i]..tostring(k)
                    end
                end
            end
        end
    end

    local data_folder = Params.DATA_FOLDER or Path.."\\data"

    local sec_code  = Sec.sec_code
    local sec_sub   = 2
    if Sec.class_code == 'SPBOPT' then sec_sub = 3 end
    if isFutures(Sec.class_code) then sec_code = sec_code:sub(1, sec_code:len()-sec_sub) end

    local data_file_name = data_folder..'\\'..sec_code..'_'..Sec.class_code..'_'..ds.interval_rep..'_'..algo_m..'.csv'
    local data_file = io.open(data_file_name, 'a+')
    if not data_file then
        local msg = 'Не удалось получить доступ к файлу данных: '..data_file_name
        log.warn(msg)
        message(NAME_OF_STRATEGY..': '..msg, 2)
        return false
    end

    local function get_last_line()
        local how_many = 2

        local new_lines_found = 0

        -- needs to find at least a pair of \n
        local len = data_file:seek("end")
        log.debug('last_line len', len)
        for back_by = 1, len do
            data_file:seek("end", -back_by)
            if data_file:read(1) == '\n' then
                new_lines_found = new_lines_found + 1
                if new_lines_found >= how_many then
                    local last_line = data_file:read()
                    if (last_line or '') ~= '' then
                        log.debug('last_line', last_line)
                        return last_line
                    end
                end
            end
        end
    end

    local function get_last_stored_time()
        local last_time  = 0
        local last       = get_last_line() or ''
        local split_line = mysplit(last, ';')
        if split_line then last_time = tonumber(split_line[3]) or 0 end
        return tonumber(last_time) or 0
    end

    OPENED_FILES[#OPENED_FILES+1] = data_file

    -- Встает в начало файла
    data_file:seek("set",0)
    -- Если файл пустой
    if data_file:read() == nil then
        data_file:write(DATA_FILE_STRUCT..';'..table.concat(DATA_METHODS, ";")..(algo_lines == '' and '' or (";"..algo_lines)))
        data_file:flush()
    end

    local line_prefix = Sec.sec_code..';'..Sec.class_code

    --'sec_code;class_code;unix_time;date;time;date_time;index'
    local function store_ds_data(index)
        local res = line_prefix..';'..tostring(time)..';'..os_date('%d.%m.%Y', time)..';'..os_date('%H:%M:%S', time)..';'..os_date('%d.%m.%Y %H:%M:%S', time)..';'..tostring(index)
        for i = 1, #DATA_METHODS do
            res = res..(res == '' and '' or ';')..toExcelNum(ds[DATA_METHODS[i]:sub(1,1):upper()](ds, index))
        end
        return res
    end
    local function store_data(index, res, ...)
        local n = select('#', ...)
        res = res or ''
        for i = 1, n do
            local data = select(i, ...)
            -- log.debug('store_data', data[index])
            if type(data) == 'table' then
                res = res..(res == '' and '' or ';')..toExcelNum(data[index])
            end
            if type(data) == 'number' then
                res = res..(res == '' and '' or ';')..toExcelNum(data)
            end
        end
        -- log.debug('store_data', res)
        return res
    end

    local last_time = get_last_stored_time()
    log.debug('DataProcessor', ds, 'last_time', last_time)
    data_file:seek('end')

    return function()
            local status, res = pcall(function()
            if not isRun then return end

            local index         = ds.Next()
            local need_flash    = false
            while index do
                time = os.time(ds:T(index))
                if time <= last_time then
                    for i = 1, #algo_f do
                        algo_f[i](index)
                    end
                end
                if time > last_time then
                    local data_line = store_ds_data(index)
                    for i = 1, #algo_f do
                        data_line = store_data(index, data_line, algo_f[i](index))
                    end
                    data_file:write("\n"..data_line)
                    need_flash = true
                end
                Sec.history_saved = true
                index = ds.Next()
            end
            if need_flash then
                data_file:flush()
            end
        end)
        if not status then ScriptError('DataSourceProcessor: '..tostring(res)) end
    end
end

--Блок вызова функций алгоритма
local function RunAlgo()

    if not isRun then return end

    local status,res = pcall(function()

        for i = 1, #DATA_FUNCTOR do
            DATA_FUNCTOR[i]()
        end
        if Params.ONLY_HISTORY == 1 then
            local all_saved = true
            for _, Sec in ipairs(SEC_LIST) do
                all_saved = all_saved and Sec.history_saved
            end
            if all_saved then
                local msg = 'Все данные истории обработаны'
                log.warn(msg)
                message(NAME_OF_STRATEGY..': '..msg, 1)
                isRun = false
            end
        end

    end)
    if not status then ScriptError('RunAlgo: '..tostring(res)) end
end

local function FillDataFunctor()

    DATA_FUNCTOR = {}

    for _, Sec in ipairs(SEC_LIST) do
        local ds = dsClass:new(Sec, Sec.interval)
        if ds then
            local func = DataProcessor(Sec, ds)
            if func then
                DATA_FUNCTOR[#DATA_FUNCTOR+1] = func
            end
        end
    end

end

function _G.main()

    on_Init()

    -- Цикл по дням
    while isRun do

        SERVER_TIME  = os_date('*t', os_time()-TIME_ZONE_SHIFT)
        SERVER_DATE  = os_date('*t', os_time()-TIME_ZONE_SHIFT)
        log.info(NAME_OF_STRATEGY..' Ожидания нового дня. Время сервера: '..os_date('%Y-%m-%d %H:%M:%S', os_time(SERVER_DATE)))
        log.info('Начало нового дня: '..os_date('%Y-%m-%d %H:%M:%S', startNewDayTime))

        -- Ждет начала следующего дня
        local serverTime = os_time(SERVER_TIME)
        while isRun and serverTime < startNewDayTime do
            serverTime   = os_time(SERVER_TIME)
            SERVER_TIME  = os_date('*t', os_time()-TIME_ZONE_SHIFT)
            SERVER_DATE  = os_date('*t', os_time()-TIME_ZONE_SHIFT)
            sleep(1000)
        end

        InitDaytradeTimes()

        --Если брокер не переводит время в выходные
        local srv_time = GetServerDateTime()
        while isRun and (srv_time.day < SERVER_DATE.day or CONNECT_STATE == 0) do
            SERVER_TIME  = os_date('*t', os_time()-TIME_ZONE_SHIFT)
            SERVER_DATE  = os_date('*t', os_time()-TIME_ZONE_SHIFT)
            srv_time     = GetServerDateTime()
            sleep(500)
        end

        InitDaytradeTimes()
        PrevDayNumber = SERVER_DATE.day

        SERVER_TIME  = GetServerDateTime()
        CheckConnect = CheckConnectProcessor()

        log.info('----------------------------------------------------------------------------------')
        log.info(NAME_OF_STRATEGY..' Дата сервера: '..os_date('%Y-%m-%d %H:%M:%S', os_time(SERVER_DATE)))
        log.info(NAME_OF_STRATEGY..' Время сервера: '..os_date('%Y-%m-%d %H:%M:%S', os_time(SERVER_TIME)))
        log.info(NAME_OF_STRATEGY..' Начало торгового дня: '..os_date('%Y-%m-%d %H:%M:%S', startTradeTime))
        log.info(NAME_OF_STRATEGY..' Окончание торгового дня: '..os_date('%Y-%m-%d %H:%M:%S', endOfDay))
        log.info('----------------------------------------------------------------------------------')

        -- Ждет начала торгового дня
        while isRun and (os_time(SERVER_TIME) <= startTradeTime or not CheckConnect()) do
            sleep(200)
            SERVER_TIME = GetServerDateTime()
        end

        log.info(NAME_OF_STRATEGY..' Начало цикла торгового дня')
        FillDataFunctor()

        -- Цикл внутри дня
        while isRun do

            SERVER_TIME = GetServerDateTime()
            if CheckConnect() then
                RunAlgo()
            end

            -- Если торговый день закончился, выходит в цикл по дням
            serverTime = os_time(SERVER_TIME)
            if serverTime >= endOfDay then
                log.info('Закончен день. Время сервера: '..os_date('%Y-%m-%d %H:%M:%S', os_time(SERVER_TIME)))
                log.debug('PrevDayNumber: '..tostring(PrevDayNumber))
                startNewDayTime = startNewDayTime + 24*60*60
                break
            end

            if Params.main_delay~=0 then sleep(Params.main_delay) end
        end
    end
end

_G.OnDisconnected = function()
    log.info('----------------------------------------------------------------------------------')
    log.info('          OnDisconnected')
    log.info('----------------------------------------------------------------------------------')
    CONNECT_STATE = 0
    CheckConnect  = CheckConnectProcessor()
end
_G.OnConnected = function(flag)
    log.info('----------------------------------------------------------------------------------')
    log.info('          OnConnected flag', flag)
    log.info('----------------------------------------------------------------------------------')
    if flag then
        CONNECT_STATE = 1
    end
end

-- Функция ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK при остановке скрипта
function _G.OnStop()
    isRun = false
    log.warn("Script Stoped")
    log.closefile()
    for i = 1, #OPENED_FILES do
        OPENED_FILES[i]:close()
    end
end

-- Функция ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK при при закрытии программы
function _G.OnClose()
    isRun = false
    log.info("Script OnClose")
end