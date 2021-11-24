_G.unpack       = rawget(table, "unpack") or _G.unpack
_G.loadfile     = _G.loadfile or _G.load
_G.loadstring   = _G.loadstring or _G.load

local LICENSE = {
    _VERSION     = 'secScanner 2021.11.23',
    _DESCRIPTION = 'quik sec scaner',
    _AUTHOR      = 'nnh: nick-h@yandex.ru'
}

local sleep                 = _G.sleep
local message               = _G.message
local isConnected           = _G.isConnected
local getScriptPath         = _G.getScriptPath
local getInfoParam          = _G.getInfoParam
local getNumberOf           = _G.getNumberOf
local getItem               = _G.getItem
local getParamEx            = _G.getParamEx

local math_abs              = math.abs
local math_floor            = math.floor
local math_ceil             = math.ceil
local string_match          = string.match
local string_len            = string.len
local tonumber              = tonumber
local os_time               = os.time
local os_date               = os.date
local table_remove          = table.remove
local table_sremove         = _G['table'].sremove

local NAME_OF_STRATEGY      = 'secScanner'
local SEND_EMAIL_EXE_PATH   = ''

local Path                  = getScriptPath()
local version               =_VERSION:gsub('Lua ', ''):gsub('%.', '')

package.path = Path.."/?.lua;"..Path.."/algorithms/?.lua;"..Path.."/libs/?.lua;"..Path.."/commonLibs/?.lua;"..package.path..';'
package.cpath = Path.."/?.dll;"..Path.."/libs/?.dll;"..Path.."/commonLibs/?.dll;"..Path.."/commonLibs/telegramServer/lua"..version.."/?.dll;"..package.cpath..';'

local find_email = 'Нет'

---@param path string
local check_path = function(path)
    if type(path) ~= 'string' then  error(("bad argument path (string expected, got %s)"):format(type(path)),2) end

    local tmp_file = io.open(path)
    if tmp_file then
        tmp_file:close()
        return true
    end
end

local e_path = Path..'\\telegramServer\\startTeleServer.bat'
if check_path(e_path) then
    find_email = 'Да'
    SEND_EMAIL_EXE_PATH = e_path
end
if find_email == 'Нет' then
    e_path = Path..'\\libs\\telegramServer\\startTeleServer.bat'
    if check_path(e_path) then
        find_email = 'Да'
        SEND_EMAIL_EXE_PATH = e_path
    end
end

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
        if find_email == 'Нет' then
            e_path = UpPath..'\\telegramServer\\startTeleServer.bat'
            if check_path(e_path) then
                find_email = 'Да'
                SEND_EMAIL_EXE_PATH = e_path
            end
        end
        if find_email == 'Нет' then
            e_path = UpPath..'\\commonLibs\\telegramServer\\startTeleServer.bat'
            if check_path(e_path) then
                find_email = 'Да'
                SEND_EMAIL_EXE_PATH = e_path
            end
        end
    end
end

local log = require("log")


local Params = {}
--====================================================================================
--Задержка основного цикла
Params.main_delay                       = 200

--Временная зона (0, 1, -1, -2...)
Params.TIME_ZONE                        = 0

--Классы инструментов для выбора
Params.TRACK_CLASS_CODES                = 'TQBR|FQBR'

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

-- Отправлять сообщения
Params.SEND_MESSAGES                    = 1

-- Отправлять сообщение email
-- 1 - да
-- 0 - нет
Params.SEND_EMAIL                       = 1

-- Отправлять сообщение в Телеграм
-- 1 - да
-- 0 - нет
Params.SEND_TELEGRAM                    = 0

-- Имя канала отправки сообщений в телеграм, email.
-- Такое же имя должно быть установлено в настройках сервера отправки.
Params.EMAIL_PIPE                       = 'email_pipe'
Params.TELEGRAM_PIPE                    = 'telegram_pipe'

--Подключить библиотеку воспроизведения звукового файла.
-- Значение: 1 - подключать
-- Значение: 0 - не подключать
Params.PLAY_SOUND                       = 0

--Путь к звуковом файлу
Params.SOUND_FILE                       = 'c:\\windows\\media\\Alarm03.wav'

Params.EMAIL_SEND_INTERVAL              = 10

Params.LOGGING                          = 1 -- признак ведения лога. 1 - выводить, 0 - нет
Params.DEBUG_MODE                       = 1 -- признак вывода в лог отладочной информации. 1 - выводить, 0 - нет

Params.str_startNewDayTime           = '06:00:00' -- Время начала нового дня
Params.str_startTradeTime            = '09:50:00' -- Время начала сканирования
Params.str_endOfDay                  = '23:50:00' -- Окончание торгового дня

local SEC_CODES                     = {}
local SERVER_TIME                   = nil
local SERVER_DATE                   = nil
local CONNECT_STATE                 = isConnected()
local COMMANDS_QUEUE                = {}
local TIME_ZONE_SHIFT               = 0

local startNewDayTime               = 0
local startTradeTime                = 0
local endOfDay                      = 0

local PrevDayNumber                 = 0
local CheckConnect                  = function() end

local email_buff                    = {}
local last_email_check              = 0
local error_count                   = 0
local error_count_limit             = 100
local error_cache                   = {}

local isRun                         = true

local INFO_PARAMS                   = {}

INFO_PARAMS['LAST']                 = {descr = 'Цена последней сделки'                                              , err_descr = ''}--NUMERIC
INFO_PARAMS['QTY']                  = {descr = 'Количество бумаг в последней сделке'                                , err_descr = ''}--NUMERIC
INFO_PARAMS['VALTODAY']             = {descr = 'Оборот в деньгах'                                                   , err_descr = ''}--NUMERIC


local ALGO_FUNCTOR                  = {}
-- local CLEAN_ALERTS                  = {}
-- local CLEAN_ALGOS                   = {}

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

function LoadParamsFromFile()
    local status,res = pcall(function()
        if not isRun then return end
        local PARAMS_FILE_NAME = getScriptPath().."\\"..NAME_OF_STRATEGY.."_params.ini" -- ИМЯ ФАЙЛА ПАРАМЕТРОВ
        if not check_path(PARAMS_FILE_NAME) then return end
        local load_func
        if _G.setfenv then
            load_func = assert(loadfile(PARAMS_FILE_NAME))
            assert(pcall(_G.setfenv(load_func, Params)))
        else
            load_func = assert(loadfile(PARAMS_FILE_NAME, 't', Params))
            assert(pcall(load_func))
        end
    end)
    if not status then ScriptError('robotBaseState.LoadParamsFromFile: '..tostring(res)) end
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
                checked = (Params.SERVER_DATA_CYCLE_TIME <= 0 or diff < Params.SERVER_DATA_CYCLE_TIME) and (Params.MAX_LOCAL_TO_SERVER_TIME_DIFF <= 0 or local_diff <= Params.MAX_LOCAL_TO_SERVER_TIME_DIFF)
                local state = checked and 'Данные сервера актуальны, торговля возможна' or 'Данные сервера неактуальны, торговля невозможна'
                if last_state~=state then
                    last_state = state
                    log.info('Время сервера: '..os_date('%Y.%m.%d %H:%M:%S', os_time(cur_time)), 'LASTRECORDTIME:', last_rec_time)
                    log.info('Время последнего сообщения: '..os_date('%Y.%m.%d %H:%M:%S', os_time(dt))..', checked:'..tostring(checked)..', diff:'..tostring(diff))
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

--Получить и проверить значение из Таблицы текущих торгов по инструменту
---@param class_code string
---@param sec_code string
---@param info_string string
local function GetCheckServerInfo(class_code, sec_code, info_string)
    if type(class_code) ~= 'string' then  error(("bad argument class_code (string expected, got %s)"):format(type(class_code)),2) end
    if type(sec_code) ~= 'string' then  error(("bad argument sec_code (string expected, got %s)"):format(type(sec_code)),2) end
    if type(info_string) ~= 'string' then  error(("bad argument info_string (string expected, got %s)"):format(type(info_string)),2) end

    local status, res, mes = pcall(function()
        if not isRun then return end
        local info = getParamEx(class_code, sec_code, info_string)
        if not info or info.result ~= '1' or info.param_image == "" or info.param_type == "0" then
            local sec_descr  = class_code..'|'..sec_code
            local info_descr = INFO_PARAMS[info_string]
            local mes = sec_descr..': Не включен параметр "'..(info_descr and info_descr.descr or info_string)..'" в потоке данных.'..(info_descr and ' '..info_descr.err_descr or '')
            log.warn(mes)
            return false, mes
        end
        return info
    end)
    if not status then ScriptError('GetCheckServerInfo: '..tostring(res))
        return false, tostring(res)
    end
    return res, mes
end

--Получить значение из Таблицы текущих торгов по инструменту
---@param class_code string
---@param sec_code string
---@param info_string string
local function GetServerInfo(class_code, sec_code, info_string)
    if type(class_code) ~= 'string' then  error(("bad argument class_code (string expected, got %s)"):format(type(class_code)),2) end
    if type(sec_code) ~= 'string' then  error(("bad argument sec_code (string expected, got %s)"):format(type(sec_code)),2) end
    if type(info_string) ~= 'string' then  error(("bad argument info_string (string expected, got %s)"):format(type(info_string)),2) end
    local info = GetCheckServerInfo(class_code, sec_code, info_string)
    return (info and ((info.param_type == '1' or info.param_type == '2') and tonumber(info.param_value) or info.param_value)) or 0
end

-- Базовые функции скриптов
--=======================================================================================================

--=======================================================================================================
-- Оповещения
---@param msg string
---@param pipe_name string
local function SendTeleMessage(msg, pipe_name)

    local tele_pipe = io.open("\\\\.\\PIPE\\"..pipe_name, "w+b")
    if not tele_pipe then
        log.warn('SendTeleMessage', 'Не удалось открыть канал данных '..pipe_name)
        return false
    end
    tele_pipe:write(msg)
    tele_pipe:close()
    return true
end

--Отправка сообщения
---@param email_text string
---@param pipe_name string
function SendMessage(email_text, pipe_name)

    if (SEND_EMAIL_EXE_PATH or '') == '' then return end
    local status,res = pcall(function()
        log.info('SendMessage text: '..email_text)
        if email_text ~= '' then
            email_text = " -----------------"..NAME_OF_STRATEGY..": "..os_date('%Y-%m-%d %H:%M:%S', os_time(SERVER_TIME)).." -----------------".. "\n"..' '..email_text
            if not SendTeleMessage(email_text, pipe_name) then
                log.warn('Сообщение не отправлено')
                os.execute('start cmd /c call "'..SEND_EMAIL_EXE_PATH..'"')
                _G.sleep(500)
                if not SendTeleMessage(email_text, pipe_name) then
                    Params.SEND_MESSAGES = 0
                    message(NAME_OF_STRATEGY..': '..'Не удалось отправить сообщение. Отправка выключена', 3)
                end
            end
        end
    end)
    if not status then ScriptError('SendMessage: '..tostring(res)) end
end

--Проигрываение мелодии
---@param file_name string
function PaySoundFile(file_name)

    if (file_name or '') == '' or not _G.w32 then return end
    local status,res = pcall(function()
        _G.w32.mciSendString("CLOSE QUIK_MP3")
        _G.w32.mciSendString("OPEN \"" .. file_name .. "\" TYPE MpegVideo ALIAS QUIK_MP3")
        _G.w32.mciSendString("PLAY QUIK_MP3")
        end
    )
    if not status then ScriptError('PaySoundFile: '..tostring(res)) end
end
-- Оповещения
--=======================================================================================================

local function on_Init()

    if not DirectoryExists(Path.."\\logs") then
        os.execute("mkdir " .. Path.."\\logs")
    end

    local day_prefix    = os_date('%d-%m-%Y_%H.%M.%S', os_time())
    log.use_err_file    = true
    log.err_filename    = Path.."\\logs\\err_"..NAME_OF_STRATEGY..'_'..day_prefix..".log"

    LoadParamsFromFile()
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

    --Проверка наличия программы отправки сообщений
    if Params.SEND_MESSAGES == 1 then
        if (SEND_EMAIL_EXE_PATH or '') ~= '' then
            os.execute('start cmd /c call "'..SEND_EMAIL_EXE_PATH..'"')
        else
            _G.message('Не найдена программа отправки сообщений')
        end
    end
    --Проверка наличия программы отправки сообщений

    --Проверка возможности воспроизведения звуков
    if Params.PLAY_SOUND == 1 and (Params.SOUND_FILE or '') ~= '' then
        if io.open(Params.SOUND_FILE, "r") then
            _G.w32 = (function() local status, res = pcall(function() return require("w32"); end) if status then return res end; end)()
            log.debug('w32', type(_G.w32))
        else
            local mes = 'Не найден звуковой файл '..tostring(Params.SOUND_FILE)..'. Воспроизведение звуков недоступно.'
            log.warn(mes)
        end
    end
    --Проверка возможности воспроизведения звуков

    -- Проверяем, что есть подключение к серверу
    CONNECT_STATE = isConnected()
    if CONNECT_STATE == 0 then
        log.warn('Нет подключения к серверу')
        message('Нет подключения к серверу, старт невозможен.', 3)
    end

end

local function FillTradeRefs()

    local status,res = pcall(function()

        SEC_CODES = {}

        local cur_date = tonumber(os_date('%Y%m%d', os_time(SERVER_TIME)))
        for i=0, getNumberOf("securities")-1 do
            local securitie = getItem("securities",i)
            if securitie~= nil and Params.TRACK_CLASS_CODES:find(securitie.class_code) then
                local fut = isFutures(securitie.class_code)
                if not fut or (fut and (cur_date - (tonumber(securitie.mat_date) or 0) <= 5) or (tonumber(securitie.mat_date) or 0) == 0) then
                    log.info('Доступен Инструмент: '..tostring(securitie.name)..' - '..tostring(securitie.code)..'. class: '..tostring(securitie.class_code)..', mat_date: '..tostring(securitie.mat_date))
                    SEC_CODES[#SEC_CODES+1] = {class_code = securitie.class_code, class_name = securitie.class_name, sec_code = securitie.code, sec_name = securitie.name, short_name = securitie.short_name, mat_date = (tonumber(securitie.mat_date) or 0)}
                end
            end
        end
    end)
    if not status then
        ScriptError('FillTradeRefs: '..tostring(res))
    end

end

--Обработка очереди накопленных действий
function DoCommand()

    if #email_buff > 0 and os_time() - last_email_check >= Params.EMAIL_SEND_INTERVAL then
        local mes = ''
        for i = 1, #email_buff do
            mes = mes..(mes == '' and '' or '\n----------------------------------\n')..email_buff[i]
        end
        if mes ~= '' then
            SendMessage(mes, Params.EMAIL_PIPE)
        end
        email_buff       = {}
        last_email_check = os_time()
    end

    if #COMMANDS_QUEUE == 0 then return end
    if not isRun then return end

    local status,res = pcall(function()

        while #COMMANDS_QUEUE ~= 0 do

            local command           = COMMANDS_QUEUE[1]
            local command_value     = command.value
            local command_action    = command.action
            table_sremove(COMMANDS_QUEUE, 1)

            if command_action then

                if command.action == 'SendPipeEmail' then
                    if Params.EMAIL_SEND_INTERVAL > 0 then
                        email_buff[#email_buff + 1] = command_value
                    else
                        SendMessage(command_value, Params.EMAIL_PIPE)
                    end
                end
                if command.action == 'SendTelegram' then
                    SendMessage(command_value, Params.TELEGRAM_PIPE)
                end
                if command.action == 'PaySound' and (command_value or '') ~= '' then
                    PaySoundFile(command_value)
                end
            end
        end
    end)
    if not status then ScriptError('DoCommand: '..tostring(res))
    end
end

---@param mes string
local function ProcessAction(mes)
    message(mes, 2)
    log.warn('---------------------------------------------------------------------------')
    log.warn(mes)
    if Params.SEND_TELEGRAM == 1 then COMMANDS_QUEUE[#COMMANDS_QUEUE+1] = {action = 'SendTelegram', value = mes} end
    if Params.SEND_EMAIL == 1 then COMMANDS_QUEUE[#COMMANDS_QUEUE+1] = {action = 'SendPipeEmail', value = mes} end
    if Params.PLAY_SOUND == 1 then COMMANDS_QUEUE[#COMMANDS_QUEUE+1] = {action = 'PaySound', value = Params.SOUND_FILE} end
end

---@param Sec table - таблица с описанием инструмента
---@param info_string string - строка параметра "Таблицы текущих торгов"
---@param filter_limit number - значение фильтра
---@param sign number - знак. 1 - больше, -1 - меньше
---@return function
local function FilterProcessor(Sec, info_string, filter_limit, sign, memory)

    local check, msg = GetCheckServerInfo(Sec.class_code, Sec.sec_code, info_string)
    if not check then
        message(NAME_OF_STRATEGY..', '..Sec.sec_name..': '..msg, 2)
        return function() end
    end

    filter_limit = filter_limit or 0
    sign         = sign or 1

    local last_cond

    return function()
        if memory and last_cond then return true end
        last_cond = sign*(GetServerInfo(Sec.class_code, Sec.sec_code, info_string) - filter_limit) > 0
        return last_cond
    end
end

---@param Sec table - таблица с описанием инструмента
---@param info_string string - строка параметра "Таблицы текущих торгов"
---@param check_interval number - интервал проверки в сек.
---@param change_limit number - предел изменения параметра для наступления события
---@param msg_interval number - интервал отправки сообщений в сек.
---@param msg_once boolean - отправлять сообщение один раз при первом срабатывании
---@return function
local function CheckProcessor(Sec, info_string, check_interval, change_limit, msg_interval, msg_once, count_zero)

    local check, msg = GetCheckServerInfo(Sec.class_code, Sec.sec_code, info_string)
    if not check then
        message(NAME_OF_STRATEGY..', '..Sec.sec_name..': '..msg, 2)
        return function() end
    end

    check_interval      = check_interval or 1
    msg_interval        = msg_interval or 60
    change_limit        = change_limit or 1
    local last_check    = 0
    local last_msg      = 0
    local last_value    = GetServerInfo(Sec.class_code, Sec.sec_code, info_string)

    local info_descr = INFO_PARAMS[info_string]

    return function()
        local status,res = pcall(function()

            local cur_time = os_time()
            if cur_time - last_check >= check_interval then
                last_check = cur_time
                local cur_value = GetServerInfo(Sec.class_code, Sec.sec_code, info_string)
                if count_zero or cur_value ~= 0 then
                    if last_value  ~= cur_value and last_value ~= 0 then
                        local d_value = round((cur_value - last_value)*100/last_value, 2)
                        -- log.debug('CheckProcessor', Sec.sec_name, 'last_value', last_value, 'cur_value', cur_value, 'd_value', d_value)
                        if math_abs(d_value) >= change_limit then
                            if cur_time - last_msg >= msg_interval then
                                last_msg = cur_time
                                ProcessAction(Sec.sec_name..': '..'значительное изменение параметра "'..(info_descr and info_descr.descr or info_string)..'" на: '..tostring(d_value)..'%, период: '..tostring(check_interval))
                                if msg_once then return true end
                            end
                        end
                    end
                    last_value  = cur_value
                end
            end

        end)
        if not status then ScriptError('CheckProcessor: '..tostring(res)) end
        return res
    end
end

---@param Sec table - таблица с описанием инструмента
---@param info_string string - строка параметра "Таблицы текущих торгов"
---@param check_interval number - интервал проверки в сек.
---@param change_limit number - предел изменения параметра для наступления события
---@param ema_period number - период расчета EMA.
---@param msg_interval number - интервал отправки сообщений в сек.
---@param msg_once boolean - отправлять сообщение один раз при первом срабатывании
---@return function
local function CheckEMAProcessor(Sec, info_string, check_interval, change_limit, ema_period, msg_interval, msg_once)

    local check, msg = GetCheckServerInfo(Sec.class_code, Sec.sec_code, info_string)
    if not check then
        message(NAME_OF_STRATEGY..', '..Sec.sec_name..': '..msg, 2)
        return function() end
    end

    check_interval      = check_interval or 1
    msg_interval        = msg_interval or 60
    change_limit        = change_limit or 1
    ema_period          = ema_period or 100
    local last_check    = os_time()
    local last_msg      = 0
    local last_value    = GetServerInfo(Sec.class_code, Sec.sec_code, info_string)

    local k             = 2/(ema_period + 1)
    local value_arr     = {}
    local ema_value     = {}

    local info_descr    = INFO_PARAMS[info_string]

    return function()
        local status,res = pcall(function()

            local cur_time = os_time()
            if cur_time - last_check >= check_interval then

                last_check = cur_time

                local cur_value = GetServerInfo(Sec.class_code, Sec.sec_code, info_string)
                local d_value   = cur_value - last_value
                if d_value == 0 then return end

                value_arr[#value_arr+1] = d_value

                local ind = #value_arr
                if ind < ema_period then return end

                if ind == ema_period then
                    local sum = 0
                    for n=2, ind do
                        sum = sum + value_arr[n]
                    end
                    ema_value[ind] = sum/(ind-1)
                elseif ind > ema_period then
                    ema_value[ind] = k*value_arr[ind]+(1-k)*ema_value[ind-1]
                end

                -- log.debug('CheckEMAProcessor', Sec.sec_name, 'cur_value', cur_value, 'last_value', last_value, 'd_value', d_value, 'ema_value', ema_value[ind])
                local k_value = d_value/ema_value[ind]
                if k_value >= change_limit then
                    if cur_time - last_msg >= msg_interval then
                        last_msg = cur_time
                        ProcessAction(Sec.sec_name..': '..'изменение параметра "'..(info_descr and info_descr.descr or info_string)..'" более чем в: '..tostring(round(k_value, 2))..' ema, период: '..tostring(check_interval))
                        if msg_once then return true end
                    end
                end
                last_value  = cur_value
            end

        end)
        if not status then ScriptError('CheckEMAProcessor: '..tostring(res)) end
        return res
    end
end

--Блок вызова функций алгоритма
local function RunAlgo()

    if not isRun then return end

    local status,res = pcall(function()

        local clean_algos = {}
        for i = 1, #ALGO_FUNCTOR do
            local algo = ALGO_FUNCTOR[i]
            local cond = true
            if algo.filters then
                for c = 1, #algo.filters do
                    cond = cond and algo.filters[c]()
                end
            end
            if cond then
                local clean_alerts = {}
                for a = 1, #algo.alerts do
                    if algo.alerts[a]() then
                        clean_alerts[a] = true
                    end
                end
                for key in pairs(clean_alerts) do
                    -- if #algo.alerts == key then
                    --     algo.alerts[key] = nil
                    -- else
                        table_remove(algo.alerts, key)
                    -- end
                end
                if #algo.alerts == 0 then clean_algos[i] = true end
            end
        end
        for key in pairs(clean_algos) do
            -- if #ALGO_FUNCTOR == key then
            --     ALGO_FUNCTOR[key] = nil
            -- else
                table_remove(ALGO_FUNCTOR, key)
            -- end
        end

    end)
    if not status then ScriptError('RunAlgo: '..tostring(res)) end
end

local function FillAlgoFunctor()

    if not SEC_CODES then FillTradeRefs() end

    ALGO_FUNCTOR = {}

    for _, Sec in ipairs(SEC_CODES) do
        ALGO_FUNCTOR[#ALGO_FUNCTOR+1] =  {}
        local algo      = ALGO_FUNCTOR[#ALGO_FUNCTOR]
        algo.filters    = {}
        algo.filters[#algo.filters+1]   = FilterProcessor(Sec, 'VALTODAY', 7000000, 1, true)
        algo.alerts     = {}
        algo.alerts[#algo.alerts+1]     = CheckProcessor(Sec, 'LAST', 0, 5, 600, true)
        algo.alerts[#algo.alerts+1]     = CheckProcessor(Sec, 'LAST', 10, 5, 600, true)
        algo.alerts[#algo.alerts+1]     = CheckEMAProcessor(Sec, 'VALTODAY', 180, 3, 5, 600, true)
        ALGO_FUNCTOR[#ALGO_FUNCTOR+1] =  {}
        algo            = ALGO_FUNCTOR[#ALGO_FUNCTOR]
        algo.filters    = {}
        algo.filters[#algo.filters+1]   = FilterProcessor(Sec, 'VALTODAY', 100000000, 1, true)
        algo.alerts     = {}
        algo.alerts[#algo.alerts+1]     = CheckProcessor(Sec, 'LAST', 0, 1.5, 600, true)
        algo.alerts[#algo.alerts+1]     = CheckProcessor(Sec, 'LAST', 10, 1.5, 600, true)
    end

    SEC_CODES = nil
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
        FillTradeRefs()
        FillAlgoFunctor()

        -- Цикл внутри дня
        while isRun do

            SERVER_TIME = GetServerDateTime()
            if CheckConnect() then
                RunAlgo()
            end

            DoCommand()

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
end

-- Функция ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK при при закрытии программы
function _G.OnClose()
    isRun = false
    log.info("Script OnClose")
end