
local Path                      = getScriptPath()

----------------------------------------------------------------------------------------------------
--- НАСТРАИВАЕМЫЕ ПАРАМЕТРЫ ------------------------------------------------------------------------
do-------------------------------------------------------------------------------- Свертываемый блок
    NAME_OF_STRATEGY                = 'signalOrders'    -- Имя стратегии для идентификации робота по выводимым сообщениям

    --Сдвиг времени относительно времени биржи
    TIME_ZONE                       = 0

    --Интервал обновления данных с текущим состоянием c сервера брокера (сек.)
    --Задается в настройках терминала в пункте меню «Система» / «Настройки» / «Основные настройки» / «Программа» на вкладке «Получение данных»
    --Если время сервера больше времени последнего сообщения чем период опроса, то связь с сервером брокера еще не установлена
    -- По умолчанию -1 не контролировать
    SERVER_DATA_CYCLE_TIME          = -1

    --Путь к файлам с данными
    FILES_PATH                      = Path..'\\inbox'
    --Путь к архиву файлов с данными
    ARCHIVE_FILES_PATH              = Path..'\\history'
    --Путь к обработанным файлам с данными
    PROCESSED_FILES_PATH            = Path..'\\processed'
    --Путь к не обработанным файлам с данными
    NON_PROCESSED_FILES_PATH        = Path..'\\non-processed'

    --Структура файла разрешенных для торговли инструментов
    SEPARATOR                       = ';'
    TICKERS_FILE_NAME               = 'tickers.csv'
    TICKERS_FILE_STRUCT             = 'sec_code;strategy;interval;account;client_code;trade_qty;max_loss_profit'

    --Корректный email-adress. Если письмо не от корректного адреса, то оно не обрабатывается
    CORRECT_EMAIL_ADRESS            = 'nick.tst@yandex.ru'

    -- Отправлять ответный email
    -- 1 - да
    -- 0 - нет
    -- Важно. Для отправки почты необходимо заполнить в файле SendEmail.ini настройки аккаунта и почтового сервера
    -- После настройки необходимо убедиться в работоспособности программы SendEmail.exe, выполнив ее. Произойдет попытка отправки почты
    -- на указанный сервер. Текст письма берется из файла email_text.txt. В данный файл робот будет записывать очередное сообщение для отправки.
    SEND_RESPONSE_EMAIL             = 0
    EMAIL_TEXT_FILE_PATH            = Path..'\\email_text.txt'
    SEND_EMAIL_EXE_PATH             = Path..'\\SendEmail.exe'

    -- Номера команд для старта|остановки|закрытия
    STOP_COMMAND_STRATEGY           = 5
    START_COMMAND_STRATEGY          = 6
    CLOSE_COMMAND_STRATEGY          = 7

    --Период сканирования новых файлов в сек. Установливать значение больше 0-5 сек. Т.к. слишком частое сканирование - это мелькание черного окна терминала.
    FILE_SCAN_PERIOD                = 10

    --Код класса инструментов по умолчанию для определения статуса торговой сессии
    CLASS_CODE                      = 'SPBFUT'

    -- Классы инструментов для считывания параметров инструментов
    TRACK_CLASS_CODES               = 'TQBR|QJSIM|SPBFUT'

    --Время автоматического включение робота в режим старт торговли по всем инструментам: (0-выключено, либо время в формате "ЧЧ:ММ:CC")
    --(Кавычки при указании времени обязательны)
    -- При наступлении указанного времени скрипт начинает обрабатывать сигналы
    -- Если установлен 0, то запуск производится по команде
    AUTO_START_TIME                 = '10:00:00'

    --Время автоматического окончания торговли по всем инструментам: (0-выключено, либо время в формате 'ЧЧ:ММ:CC')
    --(Кавычки при указании времени обязательны)
    -- При наступлении указанного времени скрипт заканчивает обрабатывать сигналы
    -- Если установлен 0, то остановка производится по команде
    END_TRADE_TIME                  = '23:49:30'

    --Режим торгов
    -- 0 - Т0, 1 - Т1, 2 - Т2
    -- Для демо-счета, обычно = 0
    -- На реальном счете для Акций - Т2,
    -- Для фьючерсов - Т0. Это важно.
    -- Если указать некорректное значение робот не сможет получить текущий баланс позиции и доступные денежные средства.
    LIMIT_KIND                      = 0

    -- Величина отступа в шагах цены для выставления рыночной заявки, для ее гарантированного исполнения
    -- Понижая отступ можно увеличить допустимый размер набираемой позиции, т.к. расчет ГО ведется от цены устанавливаемой заявки
    MARKET_PRICE_OFFSET             = 100

    --При развороте делить вход в позицию на два этапа. Сначала закрывать прошлую позицию, потом входить в новую.
    --Это необходимо при торговле на границе по лимитам денежных средств
    -- Значения:
    -- 1 - делить
    -- 0 - не делить, выходить по рынку единой заявкой
    SPLIT_REVERSE_ORDER             = 1

    -- Признак ведения лога.
    -- 1 - выводить
    -- 0 - нет
    LOGGING                         = 1

    DEBUG_MODE                      = 0

    -- Признак вывода сообщений.
    -- 1 - выводить
    -- 0 - нет
    SHOW_MESSAGES                   = 1

    ----------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------
end-------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------
--- РАБОЧИЕ ПЕРЕМЕННЫЕ -----------------------------------------------------------------------------

    SERVER_TIME                     = {}
    SEC_CODES_PROPS                 = {}

    -- Тип отображения баланса в таблице "Таблица лимитов по денежным средствам" (1 - в лотах, 2 - с учетом количества в лоте)
    -- Например, при покупке 1 лота USDRUB одни брокеры в поле "Баланс" транслируют 1, другие 1000
    -- Обычно, для срочного рынка = 1, для фондового рынка = 2
    BALANCE_TYPE                    = 1

    --Технологические времена биржи
    str_startTradeTime              = '10:00:00' -- Начало торговли
    str_dayClearing                 = '14:00:00' -- Время начала дневного клиринга
    str_endOfDayClearing            = '14:05:00' -- Время окончания дневного клиринга
    str_endTradeTime                = '18:40:00' -- Окончание торговли (для акций)
    str_shareEndOfDay               = '18:50:00' -- Окончание торгового дня (для акций)
    str_eveningClearing             = '18:45:00' -- Время начала клиринга. Для проверки возможного сброса заявок
    str_eveningSession              = '19:00:00' -- Время окончания клиринга. Для проверки возможного сброса заявок
    str_endOfDay                    = '23:50:00' -- Окончание торгового дня

    auto_startTradeTime             = 0
    auto_endTradeTime               = 0

    SEC_CODES                       = {}
    CLASS_CODES                     = {}
    SEC_CODES_NAMES                 = {}
    SEC_CODES_PROPS                 = {}
    CLASS_CODES_PROPS               = {}
    ACCOUNTS                        = {}
    ACCOUNTS_CLASSES                = {}
    CLIENT_CODES                    = {}

    SEC_CLASSES                     = {} -- Инструменты и их параметры

    isTrade                         = false -- признак запущенного робота
    isAutoStart                     = false -- признак автоматически запущенного робота
    local manualStop                = false

    local COMMANDS_STACK            = {}
    local TRANSACTIONS_RESPONSE     = {}
    local FILES_IN_ORDER            = {} -- Индексы строк установленных ордеров
    local CheckTradeSession         = {}
    local ReadDataFiles             = function() end
    local CheckEmailLogs            = function() end
    local CheckConnect              = function() end
    local LastEmailCheck            = 0
    local email_log_file            = 'log.txt'
    local email_err_log_file        = 'err_log.txt'
    local email_message             = ''
    local PrevDayNumber             = 0

    local TPath                     = Path..'//T.state'
    T                               = {}

    local last_save_time            = os.time()
    local need_dump_table           = false

    isRun                           = true -- Флаг поддержания работы бесконечного цикла в main

    trans_result_msg                = '' --переменная для хранения ответа от транзакции

    local IS_CLOSE                  = false

    ----------------------------------------------------------------------------------------------------
    ----------------------------------------------------------------------------------------------------

---@param file string
local function directory_exists(file)
    local ok, err, code = os.rename(file, file)
    if not ok then
       if code == 13 then
          -- Permission denied, but it exists
          return true
       end
    end
    return ok, err
end

--Установка временных пременных для текущего дня
local function InitNewDayTimes()

    startTradeTime      = os.time(GetStringTime(str_startTradeTime))
    dayClearing         = os.time(GetStringTime(str_dayClearing))
    endOfDayClearing    = os.time(GetStringTime(str_endOfDayClearing))
    endTradeTime        = os.time(GetStringTime(str_endTradeTime))
    shareEndOfDay       = os.time(GetStringTime(str_shareEndOfDay))
    eveningClearing     = os.time(GetStringTime(str_eveningClearing))
    eveningSession      = os.time(GetStringTime(str_eveningSession))
    endOfDay            = os.time(GetStringTime(str_endOfDay))
    local day_prefix    = os.date('%d-%m-%Y', os.time(SERVER_TIME))
    email_err_log_file  = day_prefix..' log.txt'
    email_log_file      = day_prefix..' err_log.txt'
    myLog(NAME_OF_STRATEGY..' email_err_log_file: '..tostring(email_err_log_file)..', :'..tostring(email_log_file))
    FILES_IN_ORDER      = {}
    FILES_IN_ORDER[email_log_file]      = true
    FILES_IN_ORDER[email_err_log_file]  = true
    T.AUTO_START_TIME                   = AUTO_START_TIME
    local dt_AUTO_START_TIME            = GetStringTime(AUTO_START_TIME)
    auto_startTradeTime                 = dt_AUTO_START_TIME.min == nil and 0 or os.time(dt_AUTO_START_TIME)
    local dt_END_TRADE_TIME             = GetStringTime(END_TRADE_TIME)
    auto_endTradeTime                   = dt_END_TRADE_TIME.min == nil and 0 or os.time(dt_END_TRADE_TIME)
end

--Вывод сообщения
---@param mes string
---@param msg_type number
---@param err boolean
local function SetMessage(mes, msg_type, err)
    if not isRun then return end
    if type(mes) ~= 'string' then  error(("bad argument mes (string expected, got %s)"):format(type(mes)),2) end
    msg_type = msg_type or 1
    local status,res = pcall(function()
        if SHOW_MESSAGES ~= 1 and not err then return end
        message(NAME_OF_STRATEGY..' '..mes, msg_type)
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error SetMessage: '..tostring(res)) end
end

local function CheckConnectProcessor()

    local checked       = false
    local last_state    = false
    return function()
        local status,res = pcall(function()

            if isConnected() == 0 then
                checked = false
                return checked
            end

            if checked then return true end

            local cur_time  = GetServerDateTime()
            local last_rec_time = getInfoParam('LASTRECORDTIME') or 0
            if (last_rec_time or 0)~=0 then
                local dt              = GetServerDateTime()
                dt.hour,dt.min,dt.sec = FixStrTime(tostring(last_rec_time))
                local diff = round(os.time(cur_time) - os.time(dt), 0)
                checked = SERVER_DATA_CYCLE_TIME <=0 or diff >= 0 and diff < SERVER_DATA_CYCLE_TIME
                local state = checked and 'Данные сервера актуальны, торговля возможна' or 'Данные сервера неактуальны, торговля невозможна'
                if last_state~=state then
                    last_state = state
                    myLog('Время сервера: '..os.date('%Y-%m-%d %H:%M:%S', os.time(cur_time))..' LASTRECORDTIME:'..tostring(last_rec_time))
                    myLog('Время последнего сообщения: '..os.date('%Y-%m-%d %H:%M:%S', os.time(dt))..', checked:'..tostring(checked)..', diff:'..tostring(diff))
                    SetMessage(state)
                end
                return checked
            end
            return false

        end)
        if not status then
            myLog(' Error CheckConnect: '..tostring(res))
            return false
        end
        return res
    end
end

-- Получение состояния торговой сессии
---@param Sec table
local function GetTradeSessionStatus(Sec)

    local last_state = ''
    local last_connect_state = 1
    local class_code = (Sec~=nil and type(Sec) == 'table') and Sec.CLASS_CODE or ((Sec~=nil and type(Sec) == 'string') and Sec or CLASS_CODE)

    return function()

        local can_trade, state, connect_state = false, 'Нет подключения к серверу, торговля невозможна', isConnected()

        if last_connect_state~=connect_state then
            last_connect_state = connect_state
            state = last_connect_state == 1 and 'Есть подключение к серверу, торговля возможна' or 'Нет подключения к серверу, торговля невозможна'
            SetMessage(class_code..' '..state)
            CheckConnect        = CheckConnectProcessor()
        end
        if connect_state == 1 then
            can_trade, state = SessionStatus(Sec)
        end
        if last_state~=state then
            last_state = state
            myLog(NAME_OF_STRATEGY..' '..class_code..' '..last_state)
            SetMessage(class_code..' '..last_state)
        end

        return can_trade, last_state

    end

end

---@param class_code string
local function GetClassCheckTradeSession(class_code)
    if not CheckTradeSession[class_code] then CheckTradeSession[class_code] = GetTradeSessionStatus(class_code) end
    return CheckTradeSession[class_code]
end

---@param sec_code string
---@param class_code string|nil
local function InitSec(sec_code, class_code)

    if type(sec_code) ~= 'string' then  error(("bad argument sec_code (string expected, got %s)"):format(type(sec_code)),2) end

    local Sec, res  = GetSECProp{SEC_CODE = sec_code, CLASS_CODE = class_code or FindSecClass(sec_code)}
    if not Sec then
        myLog(NAME_OF_STRATEGY..' Ошибка инициализации инструмента: '..tostring(sec_code)..' '..tostring(res))
        SetMessage(tostring(res), 3, true)
        return
    end
    if not T[Sec.SEC_CODE] then
        InitSec_T(Sec.SEC_CODE)
        T[Sec.SEC_CODE].lastDealsCount = GetTableCount(Sec, 'trades') or 0
    end
    myLog(NAME_OF_STRATEGY..' Инициализация инструмента: '..tostring(Sec.SEC_CODE))
    return Sec
end

-- Lua implementation of PHP scandir function
---@param directory string
local function ScanDir(directory)
    if type(directory) ~= 'string' then  error(("bad argument directory (string expected, got %s)"):format(type(directory)),2) end

    local i, t, popen = 0, {}, io.popen
    for filename in popen('dir "'..directory..'" /b'):lines() do
        if not filename:find('.htm') then
            i = i + 1
            t[i] = filename
        end
    end
    return t
end

---@param file_name string
---@param not_log boolean|nil
local function getFile(file_name, not_log)
    local tmp = io.open(file_name, "r") -- проверяет файл
    if tmp==nil then
        if not not_log then
            local mes = 'Не найден файл '..file_name
            myLog(NAME_OF_STRATEGY..' '..mes)
            SetMessage(mes, 3, true)
        end
        return nil
    end
    return tmp
end

-- Чтение файлов
local function ReadTickerFile()

    local function ReadFile(data_file, file_descrp, file_struct, first_col_is_key)

        if not (data_file and file_descrp and file_struct) then return false end

        T[file_descrp] = T[file_descrp] or {}
        local struct = {}
        if not first_col_is_key then
            for key in allWords(file_struct, SEPARATOR) do
                struct[#struct+1] = trim(key)
            end
        end

        local line_num = 1
        for line in data_file:lines() do
            if #line~=0 and first_col_is_key and line_num == 1 then
                for key in allWords(line, SEPARATOR) do
                    struct[#struct+1] = trim(key)
                end
            end
            if DEBUG_MODE==1 then myLog(NAME_OF_STRATEGY..' file_descrp '..tostring(file_descrp)..', line:'..tostring(line)..', struct:'..tostring(struct)) end
            if #line~=0 and ((first_col_is_key and line_num ~= 1) or first_col_is_key~=true) then
                local i = 1
                T[file_descrp][#T[file_descrp]+1] = {}
                for val in allWords(line, SEPARATOR) do
                    --if DEBUG_MODE==1 then myLog(NAME_OF_STRATEGY..' val '..tostring(val)..', line:'..tostring(line)) end
                    T[file_descrp][#T[file_descrp]][struct[i]] = trim(val)
                    i = i+1
                end
            end
            line_num = line_num+1
        end
        data_file:close()
        return true
    end

    T['TICKERS'] = {}

    local tikers_file   = getFile(Path.."\\"..TICKERS_FILE_NAME)
    if not tikers_file then
        local mes = 'Не найден файл настроек торговли: '..tostring(Path.."\\"..TICKERS_FILE_NAME)..'. Запуск невозможен.'
        myLog(NAME_OF_STRATEGY..' '..mes)
        SetMessage(mes, 3, true)
        return false
    end
    return ReadFile(tikers_file, 'TICKERS', TICKERS_FILE_STRUCT, true)

end

--Подготовка данных файлов
local function Initialization()

    T['TRACK_LIST'] = {}

    if T['TICKERS'] then
        local cur_strategies = {}
        for _,sec_line in pairs(T['TICKERS']) do
            if T[sec_line.sec_code] then
                cur_strategies[sec_line.sec_code] = cur_strategies[sec_line.sec_code] or T[sec_line.sec_code].STRATEGIES
                T[sec_line.sec_code].STRATEGIES = {}
            end
        end
        local tickers_init = 0
        for _,sec_line in pairs(T['TICKERS']) do
            --Получение информации по инструменту
            myLog(NAME_OF_STRATEGY..' Инициализация инструмента:'..tostring(sec_line.sec_code)..': '..tostring(sec_line))
            local Sec  = InitSec(sec_line.sec_code)
            if Sec then

                Sec.ACCOUNT       = sec_line.account
                Sec.CLIENT_CODE   = sec_line.client_code
                Sec.FIRM_ID       = GetAccountFirmID(Sec.ACCOUNT)
                local continue    = true
                if Sec.ACCOUNT == '' or Sec.CLIENT_CODE == '' then
                    local mes = sec_line.sec_code..' Некорректный счет|код клиента: '..tostring(Sec.ACCOUNT)..'|'..tostring(Sec.CLIENT_CODE)..'. Запуск невозможен.'
                    myLog(NAME_OF_STRATEGY..' '..tostring(Sec.SEC_NAME)..': '..tostring(mes))
                    SetMessage(tostring(mes), 3, true)
                    continue = false
                end
                local check, mes  = CheckSecAccount(Sec)
                if not check then
                    myLog(NAME_OF_STRATEGY..' '..tostring(Sec.SEC_NAME)..': '..tostring(mes))
                    SetMessage(tostring(mes), 3, true)
                    continue = false
                end
                check, mes  = CheckSecClientCode(Sec)
                if not check then
                    myLog(NAME_OF_STRATEGY..' '..tostring(Sec.SEC_NAME)..': '..tostring(mes))
                    SetMessage(tostring(mes), 3, true)
                    continue = false
                end
                if continue then
                    T['TRACK_LIST'][Sec.SEC_CODE]  = Sec.CLASS_CODE
                    local strategy = tonumber(sec_line.strategy) or 0
                    T[Sec.SEC_CODE].STRATEGIES           = T[Sec.SEC_CODE].STRATEGIES or {}
                    T[Sec.SEC_CODE].STRATEGIES[strategy] = {}
                    for key, value in pairs(sec_line) do
                        T[Sec.SEC_CODE].STRATEGIES[strategy][key] = value
                        if key == 'max_loss_profit' or key == 'strategy' or key == 'trade_qty' then
                            T[Sec.SEC_CODE].STRATEGIES[strategy][key] = tonumber(T[Sec.SEC_CODE].STRATEGIES[strategy][key]) or 0
                        end
                    end
                    T[Sec.SEC_CODE].STRATEGIES[strategy].isTrade = (cur_strategies[sec_line.sec_code] and cur_strategies[sec_line.sec_code][strategy]) and cur_strategies[sec_line.sec_code][strategy].isTrade
                    if T[Sec.SEC_CODE].STRATEGIES[strategy].isTrade == nil then
                        T[Sec.SEC_CODE].STRATEGIES[strategy].isTrade = false
                    end
                    T[Sec.SEC_CODE].STRATEGIES[strategy].start_time = 0
                    tickers_init = tickers_init + 1
                else
                    T[Sec.SEC_CODE] = nil
                end
            end
        end

        if tickers_init == 0 then
            local mes = 'Не определен ни один инструмент для торговли. Запуск невозможен.'
            myLog(NAME_OF_STRATEGY..' '..mes)
            SetMessage(mes, 3, true)
            return false
        end
        T['TICKERS'] = nil
        return true
    end

    return false

end

---@param file_to_move string
local function MoveFile(file_to_move, path_to_move)
    local status,res = pcall(function()
        if not file_to_move then return end
        myLog(NAME_OF_STRATEGY..' Перемещение файла: '..tostring(file_to_move)..' в каталог: '..tostring(path_to_move))

        local exist_data_file = getFile(path_to_move..'\\'..file_to_move, true)
        local count = 0
        local cur_time = os.time()
        while exist_data_file and (os.time() - cur_time) < 5 do
            exist_data_file:close()
            exist_data_file = nil
            local ok, _, code = os.rename(path_to_move..'\\'..file_to_move, path_to_move..'\\'..'old'..tostring(count)..'_'..file_to_move)
            if not ok then
                if code == 13 then
                   -- Permission denied, but it exists
                   myLog(NAME_OF_STRATEGY..' Ошибка права доступа при переименования файла: '..tostring(file_to_move)..' в : '..'old'..tostring(count)..'_'..tostring(file_to_move))
                   return false
                end
                myLog(NAME_OF_STRATEGY..' Ошибка при переименования файла: '..tostring(file_to_move)..' в : '..'old'..tostring(count)..'_'..tostring(file_to_move)..', по причине: '..tostring(err))
                count           = count + 1
                exist_data_file = getFile(path_to_move..'\\'..file_to_move, true)
            end
        end

        local ok, err, code = os.rename(FILES_PATH..'\\'..file_to_move, path_to_move..'\\'..file_to_move)
        if not ok then
           if code == 13 then
              -- Permission denied, but it exists
              myLog(NAME_OF_STRATEGY..' Ошибка права доступа при перемещении файла: '..tostring(file_to_move)..' в каталог: '..tostring(path_to_move))
              return false
           end
           myLog(NAME_OF_STRATEGY..' Ошибка при перемещении файла: '..tostring(file_to_move)..' в каталог: '..tostring(path_to_move)..', по причине: '..tostring(err))
        end
        return ok, err
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error MoveOldFiles: '..tostring(res)) end
end

local function MoveOldFiles()
    local status,res = pcall(function()
        local files  =  ScanDir(FILES_PATH)
        for i=1,#files do
            MoveFile(files[i], files[i]:find('log') and ARCHIVE_FILES_PATH or NON_PROCESSED_FILES_PATH)
        end
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error MoveOldFiles: '..tostring(res)) end
end

---@param action string
local function ParseActionString(action)

    if not isRun or not isTrade then return end
    local action_struct = {sec_code = '', strategy = 0, interval = '', command = '', email = '', dir = '', done = false, error = false, response_mes = ''}
    if not action or action == '' then return '' end

    local status,res = pcall(function()

        local function get_t_command()
            local t={}
            local i=1
            for str in string.gmatch(action, '[^<%s>,]+') do
                    t[i] = str
                    i = i + 1
            end
            return t
        end
        --action = action:gsub('<','')
        --action = action:gsub('>','')
        local action_arr = get_t_command()
        if DEBUG_MODE==1 then myLog(NAME_OF_STRATEGY..' action_arr '..tostring(action_arr)) end
        if #action_arr < 4 then
            return
        end
        action_struct.strategy = tonumber(trim(action_arr[1])) or -1
        action_struct.sec_code = trim(action_arr[2])
        action_struct.command  = trim(action_arr[3]):upper()
        action_struct.interval = trim(action_arr[4] or ''):upper()
        action_struct.email    = trim(action_arr[4] or ''):upper()
        if action_struct.strategy < 3 then
            action_struct.command = 'OPEN'
            action_struct.dir     = 'BUY'
        elseif action_struct.strategy > 2 and action_struct.strategy < 5 then
            action_struct.command = 'OPEN'
            action_struct.dir     = 'SELL'
        elseif action_struct.strategy == 7 then
            action_struct.command = 'CLOSE'
        end
        if action_struct.sec_code == 'ALL' then
            action_struct.command = 'ROBOT_'..action_struct.command
        end
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error ParseActionString: '..tostring(res)) end
    return action_struct
end

-- Чтение файлов
local function ReadDataFilesProcessor()

    local last_scan_time = 0
    local readed_actions

    local function ReadFile(data_file_name)

        local data_file = getFile(FILES_PATH..'\\'..data_file_name)
        if not data_file then return false, 'файл не найден' end
        local data_file_date = GetServerDateTime()

        if not data_file_name:find('email_text') then return false end

        local file_name_data = mysplit(data_file_name, ' ')
        if DEBUG_MODE==1 then myLog(NAME_OF_STRATEGY..' file_name_data '..tostring(file_name_data)) end
        if #file_name_data == 3 then
            local dt = {}
            dt.day,dt.month,dt.year = string.match(file_name_data[2],"(%d*)-(%d*)-(%d*)")
            if dt.day then
                dt.hour,dt.min,dt.sec = FixStrTime(file_name_data[3])
                if (os.time(dt) or 0) ~= 0 then
                    data_file_date = dt
                end
                if DEBUG_MODE==1 then myLog(NAME_OF_STRATEGY..' data_file_date '..tostring(data_file_date)) end
            end
        end
        myLog(NAME_OF_STRATEGY..' ReadDataFilesProcessor data_file_date: '..os.date('%Y-%m-%d %H:%M:%S', os.time(data_file_date)))
        local file_read = false
        local line_num = 1
        local msg = ''
        for line in data_file:lines() do
            myLog(NAME_OF_STRATEGY..' ReadDataFilesProcessor line: '..tostring(line))
            if line_num == 1 and line:find('Sender:') then
                --local email = line:match('[%w-._]*[%p]*%@+[%w]*[%.]?[%w]*') or ''
                --if CORRECT_EMAIL_ADRESS ~= '' and email:upper() ~= CORRECT_EMAIL_ADRESS then
                --    data_file:close()
                --    return false, 'Некорректный email адрес: '..line
                --end
                local key = 'Date:'
                local date_pos = line:find(key)
                if (date_pos or 0)~=0 then
                    local date_string = line:sub(date_pos+key:len()+1)
                    if DEBUG_MODE==1 then myLog(NAME_OF_STRATEGY..' date_pos: '..tostring(date_pos)..' date_string from file: '..tostring(date_string)) end
                    file_name_data = mysplit(date_string, ' ')
                    if #file_name_data == 2 then
                        local dt = {}
                        dt.day,dt.month,dt.year = string.match(file_name_data[1],"(%d*)-(%d*)-(%d*)")
                        if dt.day then
                            dt.hour,dt.min,dt.sec = FixStrTime(file_name_data[2])
                            if (os.time(dt) or 0) ~= 0 then
                                data_file_date = dt
                            end
                            if DEBUG_MODE==1 then myLog(NAME_OF_STRATEGY..' data_file_date from file: '..tostring(data_file_date)) end
                        end
                    end
                end
            elseif #line~=0 then
                if line:match('%b<>,') then
                    file_read = true
                    local action_struct = ParseActionString(line)
                    if action_struct.strategy ~= 0 then
                        readed_actions[#readed_actions+1] = {data_file_name = data_file_name, action = action_struct, line_text = line, data_file_date = os.time(data_file_date)}
                    else
                        msg = (msg~='' and '\n' or '')..msg..'Неправильный формат команды:'..tostring(line)
                    end
                    line_num = line_num+1
                end
            end
        end
        data_file:close()
        return file_read, msg
    end

    return function()

        local status,res = pcall(function()
            if os.time(SERVER_TIME) - last_scan_time > FILE_SCAN_PERIOD then

                last_scan_time = os.time(SERVER_TIME)
                readed_actions = {}

                local files  =  ScanDir(FILES_PATH)
                for i=1,#files do
                    --if DEBUG_MODE==1 then myLog(NAME_OF_STRATEGY..' Найден файл '..tostring(files[i])..', added:'..tostring(FILES_IN_ORDER[files[i]])) end
                    if not FILES_IN_ORDER[files[i]] then
                        local done, msg = ReadFile(files[i])
                        local response_mes = ''
                        if msg ~= '' then
                            response_mes = ' Ошибки при чтении файла: '..tostring(files[i])..'\n'..msg
                            myLog(NAME_OF_STRATEGY..' '..response_mes)
                        end
                        if done then
                            myLog(NAME_OF_STRATEGY..' Найден файл '..tostring(files[i]))
                            FILES_IN_ORDER[files[i]] = true
                        else
                            MoveFile(files[i], NON_PROCESSED_FILES_PATH)
                        end
                        email_message = email_message..(email_message == '' and '' or '\n\n')..response_mes
                    end
                end

                table.sort(readed_actions, function(a, b) return a.data_file_date < b.data_file_date end)
                if DEBUG_MODE==1 and #readed_actions > 0 then myLog(NAME_OF_STRATEGY..' ReadDataFilesProcessor readed_actions:'..tostring(readed_actions)) end
                local added_sec = {}
                for i = #readed_actions, 1, -1 do
                    local response_mes = ''
                    if not added_sec[readed_actions[i].action.sec_code] then
                        readed_actions[i].action.data_file_date = readed_actions[i].data_file_date
                        COMMANDS_STACK[#COMMANDS_STACK+1] = readed_actions[i]
                        added_sec[readed_actions[i].action.sec_code] = true
                    else
                        response_mes = 'Сигнал не обработан: '..tostring(readed_actions[i].line_text)..', по причине: Есть более новый сигнал'
                        myLog(NAME_OF_STRATEGY..' '..response_mes)
                        MoveFile(readed_actions[i].data_file_name, NON_PROCESSED_FILES_PATH)
                    end
                    email_message = email_message..(email_message == '' and '' or '\n\n')..response_mes
                end
                if DEBUG_MODE==1 and #COMMANDS_STACK> 0 then myLog(NAME_OF_STRATEGY..' ReadDataFilesProcessor COMMANDS_STACK:'..tostring(COMMANDS_STACK)) end
            end
        end)
        if not status then myLog(NAME_OF_STRATEGY..' Error ReadDataFilesProcessor: '..tostring(res)) end
    end

end

-- Чтение файлов
local function CheckEmailLogsProcessor()

    local last_scan_time = 0

    local function add_command_to_all_sec(command)
        for sec_code in pairs(T['TRACK_LIST']) do
            for _, strategy in pairs(T[sec_code].STRATEGIES) do
                local action = '<'..tostring(strategy)..'>, <'..tostring(sec_code)..'>, <'..tostring(command)..'>, <'..tostring(strategy.interval)..'>'
                COMMANDS_STACK[#COMMANDS_STACK+1] = {action = action}
            end
        end
    end

    local function ReadFile(data_file_name)

        local data_file = getFile(FILES_PATH..'\\'..data_file_name)
        if not data_file then return false end

        local line_num = 1
        for line in data_file:lines() do
            if #line~=0 then
                if line:find('BAD') then
                    add_command_to_all_sec('Close')
                end
                line_num = line_num+1
            end
        end
        data_file:close()
        return true
    end

    return function()

        if os.time(SERVER_TIME) - last_scan_time > FILE_SCAN_PERIOD then

            last_scan_time = os.time(SERVER_TIME)

            ReadFile(email_err_log_file)
        end
    end

end

--Отправка E-mail
local function SendEmail(email_text)

    if SEND_RESPONSE_EMAIL~=1 or EMAIL_TEXT_FILE_PATH == '' or SEND_EMAIL_EXE_PATH == '' then return end

    local status,res = pcall(function()
        myLog('SendEmail text: '..email_text)
        email_text = email_text or ''

        local email_file = io.open(EMAIL_TEXT_FILE_PATH, "w")
        if email_file~=nil then
            email_file:write(" -----------------"..os.date().." -----------------".. "\n")
            email_file:write(email_text)
            email_file:flush()
            email_file:close()
            os.execute('start '..SEND_EMAIL_EXE_PATH..' '..EMAIL_TEXT_FILE_PATH)
        end
    end)
    if not status then myLog('Error SendEmail: '..res) end

end

--------------------------------------------------------------------
-- ОСНОВНОЙ БЛОК РАБОТЫ СКРИПТА --
--------------------------------------------------------------------

local function SetTickerTradeState(sec_code, state, state_time)

    if not isRun then return end

    local status,res = pcall(function()
        for _, strategy in pairs(T[sec_code].STRATEGIES) do
            strategy.isTrade    = state
            strategy.start_time = state and state_time or 0
        end
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error SetTickerTradeState: '..tostring(res)) end
end

local function SetTickersTradeState(state, state_time)

    if not isRun then return end

    local status,res = pcall(function()
        for sec_code in pairs(T['TRACK_LIST']) do
            SetTickerTradeState(sec_code, state, state_time)
        end
    end)
    if DEBUG_MODE==1 then myLog(NAME_OF_STRATEGY..' SetTickersTradeState new state:'..tostring(T)) end
    if not status then myLog(NAME_OF_STRATEGY..' Error SetTickersTradeState: '..tostring(res)) end
end

--Запуск торговли
local function StartTrade(start_time)

    local status,res = pcall(function()
        local _, state = GetClassCheckTradeSession(CLASS_CODE)()

        if CheckConnect() then

            SetMessage('Старт торговли')
            myLog(" ------------------------------------------ ")
            myLog(NAME_OF_STRATEGY..': Cтарт торговли, состояние сессии: '..tostring(state))
            myLog(" ------------------------------------------ ")

            isTrade     = true
            manualStop  = false
            SetTickersTradeState(true, start_time)
            return true
        else
            myLog(NAME_OF_STRATEGY..': Cтарт торговли невозможен')
            SetMessage('Cтарт торговли невозможен')
            return false
        end
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error StartTrade: '..tostring(res)) end
    return res
end

---@param action table
local function GetActionStrategy(action)
    if type(action) ~= 'table' then  error(("bad argument action (table expected, got %s)"):format(type(action)),2) end

    if not isRun or not isTrade then return end

    local status,res = pcall(function()
        if action.sec_code and action.strategy then
            if T[action.sec_code] and T[action.sec_code].STRATEGIES then
                return T[action.sec_code].STRATEGIES[action.strategy]
            end
        end
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error GetActionStrategy: '..tostring(res)) end
    return res
end

local function AddActionResult(command, is_done, is_error, mes)
    local action_struct = type(command.action) == 'table' and command.action or command
    if is_done then
        action_struct.done         = true
        action_struct.error        = false
        action_struct.response_mes = ''
    elseif is_error then
        action_struct.done         = false
        action_struct.error        = true
        action_struct.response_mes = tostring(mes)
    else
        action_struct.done         = false
        action_struct.error        = false
        action_struct.response_mes = tostring(mes)
    end
    return command
end

-- Приводит набираемый размер позиции к требуемому
---@param Sec table
---@param command table
---@param dir string
---@param price number
---@param qty number
local function SetTransaction(Sec, command, dir, price, qty)

    if not isRun or not isTrade then return end
    if type(Sec) ~= 'table' then  error(("bad argument Sec (table expected, got %s)"):format(type(Sec)),2) end
    if type(command) ~= 'table' then  error(("bad argument command (table expected, got %s)"):format(type(command)),2) end
    if type(dir) ~= 'string' then  error(("bad argument dir (string expected, got %s)"):format(type(dir)),2) end
    if dir ~= 'BUY' and dir ~= 'SELL' then  error(("bad argument dir (string 'SELL' or 'BUY' expected, got %s)"):format(tostring(dir)),2) end
    if type(price) ~= 'number' then  error(("bad argument price (number expected, got %s)"):format(type(price)),2) end
    if type(qty) ~= 'number' then  error(("bad argument qty (number expected, got %s)"):format(type(qty)),2) end

    local status, res = pcall(function()

        if not CheckConnect() or not GetClassCheckTradeSession(Sec.CLASS_CODE)() then
            return AddActionResult(command, false, false, 'торговая сессия не активна')
        end

        local order_trans_id, res  = SetOrder(Sec, price, dir, qty, true)
        if (res or '') ~= '' then
            if not CheckConnect() or not GetClassCheckTradeSession(Sec.CLASS_CODE)() then
                return AddActionResult(command, false, false, 'торговая сессия не активна')
            end
            return AddActionResult(command, false, true, 'ошибка отправки транзакции: pos: '..tostring(qty)..', price: '..tostring(price)..', dir: '..tostring(dir)..' : '..tostring(res))
        end
        return order_trans_id
    end)
    if not status then
        myLog(NAME_OF_STRATEGY..' Error CorrectPosOpeningSize: '..tostring(res))
        return AddActionResult(command, false, true, res)
    end
    return res
end

---@param Sec table
---@param command table
local function ClosePosition(Sec, command)

    if not isRun or not isTrade then return end

    if type(Sec) ~= 'table' then  error(("bad argument Sec (table expected, got %s)"):format(type(Sec)),2) end
    if type(command) ~= 'table' then  error(("bad argument command (table expected, got %s)"):format(type(command)),2) end

    local status, res = pcall(function()

        if not CheckConnect() or not GetClassCheckTradeSession(Sec.CLASS_CODE)() then
            return AddActionResult(command, false, false, 'торговая сессия не активна')
        end
        local curOpenCount  = (GetTotalnet(Sec))
        if not (command.order or command.order_trans_id or command.done or command.error) then
            if curOpenCount == 0 then
                return AddActionResult(command, false, true, 'Попытка закрыть нулевую позицию')
            end
            local dir = curOpenCount > 0 and 'SELL' or 'BUY'
            local response = SetTransaction(Sec, command, dir, GetPriceForMarketOrder(Sec, dir == 'SELL' and 'BUY' or 'SELL'), curOpenCount)
            if type(response) == 'table' then
                return response
            end
            command.order_trans_id = response
            command.trans_time     = os.time()
        end
        if command.order_trans_id then
            if TRANSACTIONS_RESPONSE[command.order_trans_id] then
                command.order_trans_id = nil
                return AddActionResult(command, false, true, TRANSACTIONS_RESPONSE[command.order_trans_id])
            end
            local order = FindTransIdOrder(Sec, 'orders', command.order_trans_id)
            if order~=nil then
                command.order            = order
                command.order_trans_id   = nil
            elseif (os.time() - command.trans_time) > 120 then
                return AddActionResult(command, false, true, 'Не найден (за 120 сек.) ордер закрытия позиции по транзации: '..tostring(command.order_trans_id))
            end
        end
        if command.order then
            curOpenCount = (GetTotalnet(Sec))
            if curOpenCount == 0 then
                return AddActionResult(command, true, false, TRANSACTIONS_RESPONSE[command.order.trans_id] or '')
            elseif (os.time() - command.trans_time) > 120 then
                local order   = findOrder(Sec, 'orders', command.order.order_num)
                local active  = not bit.test(order.flags,0)
                local removed = not bit.test(order.flags,1)
                local mes = Sec.SEC_CODE..': Позиция: '..tostring(curOpenCount)..' не была закрыта (за 120 сек.), по причине: '..
                            (active and 'ордер не исполнен' or (removed and 'ордер снят' or 'ордер исполнен, но размер позиции не получен'))
                --T[Sec.SEC_CODE].isTrade = false
                myLog(NAME_OF_STRATEGY..' '..mes)
                SetMessage(mes, 3, true)
                return AddActionResult(command, false, true, mes)
            end
        end
        return AddActionResult(command, false, false, '')
    end)
    if not status then
        myLog(NAME_OF_STRATEGY..' Error ClosePosition: '..tostring(res))
        return AddActionResult(command, false, true, res)
    end
    return res
end

---@param Sec table
---@param command table
local function OpenPosition(Sec, command)

    if not isRun or not isTrade then return end

    if type(Sec) ~= 'table' then  error(("bad argument Sec (table expected, got %s)"):format(type(Sec)),2) end
    if type(command) ~= 'table' then  error(("bad argument command (table expected, got %s)"):format(type(command)),2) end

    local status, res = pcall(function()

        if not CheckConnect() or not GetClassCheckTradeSession(Sec.CLASS_CODE)() then
            return AddActionResult(command, false, false, 'торговая сессия не активна')
        end

        local pos = (command.dir == 'SELL' and -1 or 1)*command.qty
        if not (command.order or command.order_trans_id or command.done or command.error) then
            local curOpenCount  = (GetTotalnet(Sec))
            if pos == curOpenCount then
                return AddActionResult(command, false, true, 'данная позиция уже открыта')
            end
            local response = SetTransaction(Sec, command, command.dir, GetPriceForMarketOrder(Sec, command.dir == 'SELL' and 'BUY' or 'SELL'), pos - curOpenCount)
            if type(response) == 'table' then
                return response
            end
            command.order_trans_id = response
            command.trans_time     = os.time()
        end
        if command.order_trans_id then
            if TRANSACTIONS_RESPONSE[command.order_trans_id] then
                command.order_trans_id = nil
                return AddActionResult(command, false, true, TRANSACTIONS_RESPONSE[command.order_trans_id])
            end
            local order         = FindTransIdOrder(Sec, 'orders', command.order_trans_id)
            local curOpenCount  = (GetTotalnet(Sec))
            if order~=nil then
                command.order            = order
                command.order_trans_id   = nil
            elseif curOpenCount ~= pos and (os.time() - command.trans_time) > 120 then
                return AddActionResult(command, false, true, 'Не найден (за 120 сек.) ордер открытия позиции по транзации: '..tostring(command.order_trans_id))
            end
        end
        if command.order then
            local curOpenCount = (GetTotalnet(Sec))
            if curOpenCount == pos then
                return AddActionResult(command, true, false, TRANSACTIONS_RESPONSE[command.order.trans_id] or '')
            elseif (os.time() - command.trans_time) > 120 then
                local order   = findOrder(Sec, 'orders', command.order.order_num)
                local active  = not bit.test(order.flags,0)
                local removed = not bit.test(order.flags,1)
                local mes = Sec.SEC_CODE..': Позиция: '..tostring(curOpenCount)..' не была открыта (за 120 сек.), по причине: '..
                (active and 'ордер не исполнен' or (removed and 'ордер снят' or 'ордер исполнен, но размер позиции не получен'))
                --T[Sec.SEC_CODE].isTrade = false
                myLog(NAME_OF_STRATEGY..' '..mes)
                SetMessage(mes, 3, true)
                return AddActionResult(command, false, true, mes)
            end
        end
        return AddActionResult(command, false, false, '')
    end)
    if not status then
        myLog(NAME_OF_STRATEGY..' Error ClosePosition: '..tostring(res))
        return AddActionResult(command, false, true, res)
    end
    return res
end

---@param Sec table
---@param command table
local function ProcessAction(Sec, command)

    if not isRun or not isTrade then return end

    if type(Sec) ~= 'table' then  error(("bad argument Sec (table expected, got %s)"):format(type(Sec)),2) end
    if type(command) ~= 'table' then  error(("bad argument command (table expected, got %s)"):format(type(command)),2) end

    local status, res = pcall(function()

        if not CheckConnect() or not GetClassCheckTradeSession(Sec.CLASS_CODE)() then
            return AddActionResult(command, false, false, 'торговая сессия не активна')
        end
        --myLog(NAME_OF_STRATEGY..' ProcessAction Выполнение команды: '..tostring(command))
        if command.action == 'CLOSE' then
            return ClosePosition(Sec, command)
        end
        if command.action == 'OPEN' then
            return OpenPosition(Sec, command)
        end
    end)
    if not status then
        myLog(NAME_OF_STRATEGY..' Error ProcessAction: '..tostring(res))
        return AddActionResult(command, false, true, res)
    end
    return res
end

---@param Sec table
---@param command table
local function OpenPositionAction(Sec, command)

    if not isRun or not isTrade then return end

    if type(Sec) ~= 'table' then  error(("bad argument Sec (table expected, got %s)"):format(type(Sec)),2) end
    if type(command) ~= 'table' then  error(("bad argument command (table expected, got %s)"):format(type(command)),2) end

    local status, res = pcall(function()

        local action_struct = command.action
        local strategy      = T[Sec.SEC_CODE].STRATEGIES[action_struct.strategy]
        local dir           = action_struct.dir
        if type(dir) ~= 'string' then  error(("bad argument dir (string expected, got %s)"):format(type(dir)),2) end
        if dir ~= 'BUY' and dir ~= 'SELL' then  error(("bad argument dir (string 'SELL' or 'BUY' expected, got %s)"):format(tostring(dir)),2) end

        if T[Sec.SEC_CODE] and strategy and strategy.isTrade and (strategy.trade_qty or 0) > 0 then
            if not CheckConnect() or not GetClassCheckTradeSession(Sec.CLASS_CODE)() then
                return AddActionResult(command, false, false, 'торговая сессия не активна')
            end
            Sec.ACCOUNT         = strategy.account
            Sec.CLIENT_CODE     = strategy.client_code
            Sec.FIRM_ID         = GetAccountFirmID(Sec.ACCOUNT)
            local curOpenCount  = (GetTotalnet(Sec))
            local pos = (dir == 'SELL' and -1 or 1)*strategy.trade_qty
            if not action_struct.in_progress and pos*curOpenCount > 0 then
                return AddActionResult(command, false, true, 'данная позиция уже открыта')
            end

            if not action_struct.sub_action then
                action_struct.sub_action = {}
                if SPLIT_REVERSE_ORDER == 1 and T[Sec.SEC_CODE].tradeDirection == 'SELL' and curOpenCount>0 or  T[Sec.SEC_CODE].tradeDirection == 'BUY' and curOpenCount<0 then
                    action_struct.sub_action[#action_struct.sub_action+1] = {action = 'CLOSE', done = false, error = false, response_mes = ''}
                end
                action_struct.sub_action[#action_struct.sub_action+1] = {action = 'OPEN', qty = strategy.trade_qty, dir = dir, done = false, error = false, response_mes = ''}
            end
            if not action_struct.in_progress then
                myLog(NAME_OF_STRATEGY..' OpenPositionAction Обработка command: '..tostring(command))
            end
            action_struct.in_progress = true
            local all_done = true
            for i = 1, #action_struct.sub_action do
                local sub_action = action_struct.sub_action[i]
                all_done = all_done and sub_action.done
                if not (sub_action.done or sub_action.error) then
                    sub_action = ProcessAction(Sec, sub_action)
                end
                if sub_action.action == 'CLOSE' and (GetTotalnet(Sec)) == 0 then
                    sub_action.done  = true
                    sub_action.error = false
                end
                if sub_action.error then
                    return AddActionResult(command, false, true, sub_action.response_mes)
                end
            end
            if all_done then
                return AddActionResult(command, true, false)
            end
            return AddActionResult(command, false, false)
        end
        return AddActionResult(command, false, true, 'данный сигнал не обрабатывается. Инструмент торгуется: '..(strategy.isTrade and 'Да' or 'Нет'))
    end)
    if not status then
        myLog(NAME_OF_STRATEGY..' Error OpenPositionAction: '..tostring(res))
        return AddActionResult(command, false, true, res)
    end
    return res
end

---@param Sec table
---@param command table
local function ClosePositionAction(Sec, command)

    if not isRun or not isTrade then return end

    if type(Sec) ~= 'table' then  error(("bad argument Sec (table expected, got %s)"):format(type(Sec)),2) end
    if type(command) ~= 'table' then  error(("bad argument command (table expected, got %s)"):format(type(command)),2) end

    local status, res = pcall(function()

        local action_struct = command.action
        local strategy      = T[Sec.SEC_CODE].STRATEGIES[action_struct.strategy]

        if T[Sec.SEC_CODE] and (action_struct.command == 'MANUAL_CLOSE_POSITION' or (strategy and strategy.isTrade)) then

            if not CheckConnect() or not GetClassCheckTradeSession(Sec.CLASS_CODE)() then
                return AddActionResult(command, false, false, 'торговая сессия не активна')
            end

            Sec.ACCOUNT         = strategy.account
            Sec.CLIENT_CODE     = strategy.client_code
            Sec.FIRM_ID         = GetAccountFirmID(Sec.ACCOUNT)
            local curOpenCount  = (GetTotalnet(Sec))
            if not action_struct.in_progress and curOpenCount == 0 then
                return AddActionResult(command, false, true, 'Попытка закрыть нулевую позицию')
            end
            if not action_struct.sub_action then
                action_struct.sub_action = {}
                action_struct.sub_action[1] = {action = 'CLOSE', done = false, error = false, response_mes = ''}
            end
            if not action_struct.in_progress then
                myLog(NAME_OF_STRATEGY..' ClosePositionAction Обработка command: '..tostring(command))
            end
            action_struct.in_progress = true
            local sub_action = ProcessAction(Sec, action_struct.sub_action[1])
            return AddActionResult(command, sub_action.done, sub_action.error, sub_action.response_mes)
        end
        return AddActionResult(command, false, true, 'данный сигнал не обрабатывается. Инструмент торгуется: '..(strategy.isTrade and 'Да' or 'Нет'))
    end)
    if not status then
        myLog(NAME_OF_STRATEGY..' Error ClosePositionAction: '..tostring(res))
        return AddActionResult(command, false, true, res)
    end
    return res
end

---@param Sec table
---@param command table
local function CloseSecAllPositions(Sec, command)
    if not isRun or not isTrade then return end
    if type(Sec) ~= 'table' then  error(("bad argument Sec (table expected, got %s)"):format(type(Sec)),2) end
    if type(command) ~= 'table' then  error(("bad argument command (table expected, got %s)"):format(type(command)),2) end

    local status, res = pcall(function()
        local action_struct = command.action
        if Sec and T[Sec.SEC_CODE] then
            local added_acc = {}
            for str_key, strategy in pairs(T[Sec.SEC_CODE].STRATEGIES) do
                local acc_key = tostring(strategy.account)..'-'..tostring(strategy.client_code)
                if not added_acc[acc_key] then
                    added_acc[acc_key]  = true
                    Sec.ACCOUNT         = strategy.account
                    Sec.CLIENT_CODE     = strategy.client_code
                    Sec.FIRM_ID         = GetAccountFirmID(Sec.ACCOUNT)
                    local curOpenCount  = (GetTotalnet(Sec))
                    if curOpenCount ~= 0 then
                        COMMANDS_STACK[#COMMANDS_STACK+1] = {action = {}}
                        for key, value in pairs(action_struct) do
                            COMMANDS_STACK[#COMMANDS_STACK].action[key] = value
                        end
                        COMMANDS_STACK[#COMMANDS_STACK].line_text           = Sec.SEC_CODE..': Закрытие позиции: '..tostring(curOpenCount)
                        COMMANDS_STACK[#COMMANDS_STACK].action['command']   = 'MANUAL_CLOSE_POSITION'
                        COMMANDS_STACK[#COMMANDS_STACK].action['strategy']  = str_key
                    end
                end
            end
        end
        return AddActionResult(command, true, false)
    end)
    if not status then
        myLog(NAME_OF_STRATEGY..' Error CloseSecAllPositions: '..tostring(res))
        return AddActionResult(command, false, true, res)
    end
    return res

end

---@param command table
local function CloseAllPositions(command)
    if not isRun or not isTrade then return end
    if type(command) ~= 'table' then  error(("bad argument command (table expected, got %s)"):format(type(command)),2) end

    local action_struct = command.action

    local status, res = pcall(function()
        for sec_code, class_code in pairs(T['TRACK_LIST']) do

            local Sec = GetSECProp{SEC_CODE = sec_code, CLASS_CODE = class_code}
            if Sec and T[Sec.SEC_CODE] then
                local added_acc = {}
                for str_key, strategy in pairs(T[Sec.SEC_CODE].STRATEGIES) do
                    local acc_key = tostring(strategy.account)..'-'..tostring(strategy.client_code)
                    if not added_acc[acc_key] then
                        added_acc[acc_key]  = true
                        Sec.ACCOUNT         = strategy.account
                        Sec.CLIENT_CODE     = strategy.client_code
                        Sec.FIRM_ID         = GetAccountFirmID(Sec.ACCOUNT)
                        local curOpenCount  = (GetTotalnet(Sec))
                        if curOpenCount ~= 0 then
                            COMMANDS_STACK[#COMMANDS_STACK+1] = {action = {}}
                            for key, value in pairs(action_struct) do
                                COMMANDS_STACK[#COMMANDS_STACK].action[key] = value
                            end
                            COMMANDS_STACK[#COMMANDS_STACK].line_text           = sec_code..': Закрытие позиции: '..tostring(curOpenCount)
                            COMMANDS_STACK[#COMMANDS_STACK].action['command']   = 'MANUAL_CLOSE_POSITION'
                            COMMANDS_STACK[#COMMANDS_STACK].action['strategy']  = str_key
                            COMMANDS_STACK[#COMMANDS_STACK].action['sec_code']  = sec_code
                        end
                    end
                end
            end
        end
        return AddActionResult(command, true, false)
    end)
    if not status then
        myLog(NAME_OF_STRATEGY..' Error CloseAllPositions: '..tostring(res))
        return AddActionResult(command, false, true, res)
    end
    return res

end

---@param command table
local function ProcessSignal(command)

    if not isRun then return end
    if type(command) ~= 'table' then  error(("bad argument command (table expected, got %s)"):format(type(command)),2) end

    local status, res = pcall(function()

        local action_struct = command.action

        if action_struct.command == 'ROBOT_START' then
            if action_struct.email == CORRECT_EMAIL_ADRESS or CORRECT_EMAIL_ADRESS == '' then
                if action_struct.strategy == START_COMMAND_STRATEGY then
                    if StartTrade(action_struct.data_file_date) then
                        return AddActionResult(command, true, false)
                    else
                        return AddActionResult(command, false, true, 'старт торговли не удался')
                    end
                else
                    return AddActionResult(command, false, true, 'некорректный номер стратегии для старта')
                end
            else
                return AddActionResult(command, false, true, 'некорректный email адрес')
            end
        end
        if action_struct.command == 'ROBOT_STOP' then
            if action_struct.email == CORRECT_EMAIL_ADRESS or CORRECT_EMAIL_ADRESS == '' then
                if action_struct.strategy == STOP_COMMAND_STRATEGY then
                    isTrade     = false
                    manualStop  = true
                    SetTickersTradeState(false, 0)
                    return AddActionResult(command, true, false)
                else
                    return AddActionResult(command, false, true, 'некорректный номер стратегии для остановки')
                end
            else
                return AddActionResult(command, false, true, 'некорректный email адрес')
            end
        end
        if action_struct.command == 'ROBOT_CLOSE' then
            if action_struct.email == CORRECT_EMAIL_ADRESS or CORRECT_EMAIL_ADRESS == '' then
                if action_struct.strategy == CLOSE_COMMAND_STRATEGY then
                    return CloseAllPositions(command)
                else
                    return AddActionResult(command, false, true, 'некорректный номер стратегии для закрытия позиций')
                end
            else
                return AddActionResult(command, false, true, 'некорректный email адрес')
            end
        end
        local Sec = GetSECProp{SEC_CODE = action_struct.sec_code}
        if Sec and T[Sec.SEC_CODE] then

            if action_struct.command == 'START' then
                if action_struct.email == CORRECT_EMAIL_ADRESS or CORRECT_EMAIL_ADRESS == '' then
                    if action_struct.strategy == START_COMMAND_STRATEGY then
                        SetTickerTradeState(Sec.SEC_CODE, true, action_struct.data_file_date)
                        SaveTable(T, TPath)
                        if DEBUG_MODE==1 then myLog(NAME_OF_STRATEGY..' '..tostring(Sec.SEC_CODE)..' new state:'..tostring(T)) end
                        return AddActionResult(command, true, false)
                    else
                        return AddActionResult(command, false, true, 'некорректный номер стратегии для старта')
                    end
                else
                    return AddActionResult(command, false, true, 'некорректный email адрес')
                end
            end
            if action_struct.command == 'STOP' then
                if action_struct.email == CORRECT_EMAIL_ADRESS or CORRECT_EMAIL_ADRESS == '' then
                    if action_struct.strategy == STOP_COMMAND_STRATEGY then
                        SetTickerTradeState(Sec.SEC_CODE, false, 0)
                        SaveTable(T, TPath)
                        if DEBUG_MODE==1 then myLog(NAME_OF_STRATEGY..' '..tostring(Sec.SEC_CODE)..' new state:'..tostring(T)) end
                        return AddActionResult(command, true, false)
                    else
                        return AddActionResult(command, false, true, 'некорректный номер стратегии для остановки')
                    end
                else
                    return AddActionResult(command, false, true, 'некорректный email адрес')
                end
            end
            if action_struct.command == 'CLOSE' then
                if action_struct.email == CORRECT_EMAIL_ADRESS or CORRECT_EMAIL_ADRESS == '' then
                    if action_struct.strategy == CLOSE_COMMAND_STRATEGY then
                        return CloseSecAllPositions(Sec, command)
                    else
                        return AddActionResult(command, false, true, 'некорректный номер стратегии для закрытия позиций')
                    end
                else
                    return AddActionResult(command, false, true, 'некорректный email адрес')
                end
            end
            if action_struct.command == 'MANUAL_CLOSE_POSITION' then
                if T[Sec.SEC_CODE].STRATEGIES[action_struct.strategy] then
                    if not (action_struct.done or action_struct.error) and action_struct.email == CORRECT_EMAIL_ADRESS or CORRECT_EMAIL_ADRESS == '' then
                        return ClosePositionAction(Sec, command)
                    else
                        return AddActionResult(command, false, true, 'некорректный email адрес')
                    end
                end
            end
            if T[Sec.SEC_CODE].STRATEGIES[action_struct.strategy] then
                if T[Sec.SEC_CODE].STRATEGIES[action_struct.strategy].interval:upper() == action_struct.interval then
                    if T[Sec.SEC_CODE].STRATEGIES[action_struct.strategy].start_time~= 0 and action_struct.data_file_date < T[Sec.SEC_CODE].STRATEGIES[action_struct.strategy].start_time then
                        return AddActionResult(command, false, true, 'сигнал получен до старта торговли по инструменту')
                    end
                    if not (action_struct.done or action_struct.error) and action_struct.command == 'OPEN' then
                        return OpenPositionAction(Sec, command)
                    end
                else
                    return AddActionResult(command, false, true, 'данный интервал не обрабатывается')
                end
            else
                return AddActionResult(command, false, true, 'данная стратегия не обрабатывается')
            end
            return AddActionResult(command, false, true, 'не распознана команда '..tostring(action_struct))
        end
        return AddActionResult(command, false, true, 'инструмент: '..tostring(action_struct.sec_code)..' не обрабатывается')
    end)
    if not status then
        myLog(NAME_OF_STRATEGY..' Error ProcessSignal: '..tostring(res))
        return AddActionResult(command, false, true, res)
    end
    return res
end

-- Контролирует изменение позиции
local function PosLayer()

    if not isRun or not isTrade then return end

    local status,res = pcall(function()

        for sec_code, class_code in pairs(T['TRACK_LIST']) do

            local Sec = GetSECProp{SEC_CODE = sec_code, CLASS_CODE = class_code}
            if Sec and T[Sec.SEC_CODE] then
                for _, strategy in pairs(T[Sec.SEC_CODE].STRATEGIES) do
                    Sec.ACCOUNT         = strategy.account
                    Sec.CLIENT_CODE     = strategy.client_code
                    Sec.FIRM_ID         = GetAccountFirmID(Sec.ACCOUNT)
                    local curOpenCount, avgPrice = GetTotalnet(Sec)

                    --Если изменился размер позиции
                    local trade_count = GetTableCount(Sec, 'trades')
                    if curOpenCount~=T[Sec.SEC_CODE].OpenCount and GetClassCheckTradeSession(Sec.CLASS_CODE)() and trade_count ~= T[Sec.SEC_CODE].lastDealsCount then

                        local isChangePos = (curOpenCount<0 and T[Sec.SEC_CODE].OpenCount>0) or (curOpenCount>0 and T[Sec.SEC_CODE].OpenCount<0)

                        --Если смена позиции или ее закрытие, то рассчитаем итоговую прибыль по сделке
                        if (isChangePos or curOpenCount == 0) and T[Sec.SEC_CODE].OpenCount~=0 then

                            T[Sec.SEC_CODE].dealPricetable  = nil
                            T[Sec.SEC_CODE].lastOpenCount   = 0
                            T[Sec.SEC_CODE].avgPosPrice     = 0
                            T[Sec.SEC_CODE].posVolume       = 0
                            T[Sec.SEC_CODE].lastDealTime    = 0
                            T[Sec.SEC_CODE].TRAIL_TABLE     = {}

                            --Если смена направления, необходимо удалить все старые заявки
                            myLog(NAME_OF_STRATEGY..' Произошла смена/закрытие позиции '..tostring(Sec.SEC_CODE)..': '..tostring(T[Sec.SEC_CODE].OpenCount))
                        end

                        --Если произошло увеличение или смена позиции, то получаем среднюю цену
                        if (T[Sec.SEC_CODE].OpenCount<=0 and curOpenCount<T[Sec.SEC_CODE].OpenCount) or (T[Sec.SEC_CODE].OpenCount>=0 and curOpenCount>T[Sec.SEC_CODE].OpenCount) or isChangePos then

                            local avgOrderPrice, lastDealTime, price_table = getAvgPrice(Sec, curOpenCount)
                            if avgOrderPrice == 0 and lastDealTime == 0 and #price_table == 0 then
                                myLog(NAME_OF_STRATEGY..' PosLayer, '..tostring(Sec.SEC_CODE)..' ошибка получения средней цены новой позиции '..tostring(curOpenCount))
                                return
                            end

                            if avgOrderPrice~=0 then
                                avgPrice = avgOrderPrice
                            end

                            -- Запоминаем цену последней сделки
                            T[Sec.SEC_CODE].dealPricetable   = price_table
                            T[Sec.SEC_CODE].avgPosPrice      = avgPrice
                            T[Sec.SEC_CODE].lastDealTime     = lastDealTime
                            T[Sec.SEC_CODE].lastOpenCount    = curOpenCount
                            T[Sec.SEC_CODE].posVolume        = avgPrice*Sec.priceKoeff*curOpenCount
                            if Sec.FUTURES then
                                T[Sec.SEC_CODE].posVolume    = CalcFutVolume(Sec, curOpenCount, T[Sec.SEC_CODE].avgPosPrice) or T[Sec.SEC_CODE].posVolume
                            end
                        end

                        SetMessage(tostring(Sec.SEC_CODE)..' Изменение позиции: '..tostring(T[Sec.SEC_CODE].OpenCount)..', новая позиция: '..tostring(curOpenCount)..(curOpenCount==0 and '' or ', цена: '..tostring(T[Sec.SEC_CODE].avgPosPrice)))
                        myLog(NAME_OF_STRATEGY..' PosLayer '..tostring(Sec.SEC_CODE)..', изменение позиции '..tostring(T[Sec.SEC_CODE].OpenCount)..', новая позиция '..tostring(curOpenCount)..(curOpenCount==0 and '' or ', цена '..tostring(T[Sec.SEC_CODE].avgPosPrice)))
                        myLog('----------------------------------------------------------------------------------')

                        -- Запоминаем текущий размер позиции, цену позиции для учета движения
                        T[Sec.SEC_CODE].OpenCount = curOpenCount
                        T[Sec.SEC_CODE].lastDealsCount = trade_count
                    end

                    if not isRun or not isTrade then return end

                    --Рассчитаем текущую прибыль по сделке
                    local last_price = GetLastPrice(Sec, nil, nil, true)
                    --myLog(NAME_OF_STRATEGY..' '..Sec.SEC_CODE..' last_price: '..tostring(read_deals:GetLastPrice(Sec.SEC_CODE)))
                    if last_price~=0 and T[Sec.SEC_CODE].avgPosPrice~=0 then
                        T[Sec.SEC_CODE].curDealProfit = round((last_price-T[Sec.SEC_CODE].avgPosPrice)*curOpenCount*Sec.priceKoeff, 2)
                    end
                end
            end
        end
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error PosLayer: '..tostring(res)) end

end

local function CheckTickersPos()

    if not isRun or not isTrade then return end

    local status,res = pcall(function()
        for sec_code, class_code in pairs(T['TRACK_LIST']) do

            local Sec = GetSECProp{SEC_CODE = sec_code, CLASS_CODE = class_code}
            if Sec and T[Sec.SEC_CODE] then

                if not CheckConnect() or not GetClassCheckTradeSession(Sec.CLASS_CODE)() then
                    return
                end

                local curOpenCount = GetTotalnet(Sec)
                for str_key, strategy in pairs(T[Sec.SEC_CODE].STRATEGIES) do
                    if not strategy.task_in_progress and T[Sec.SEC_CODE].posVolume and strategy.isTrade and (strategy.max_loss_profit or 0) ~= 0 then
                        if (curOpenCount > 0 and strategy.strategy<3) or (curOpenCount < 0 and strategy.strategy>2) then
                            local curProfit = (T[Sec.SEC_CODE].curDealProfit)*100/T[Sec.SEC_CODE].posVolume
                            --myLog(NAME_OF_STRATEGY..' curProfit: '..tostring(round(curProfit, 2)))
                            if  (strategy.max_loss_profit < 0 and curProfit <= strategy.max_loss_profit) or
                                (strategy.max_loss_profit > 0 and curProfit >= strategy.max_loss_profit)
                            then
                                myLog(NAME_OF_STRATEGY..' '..Sec.SEC_CODE..' Достигнут лимит по прибыли/убытку: '..tostring(round(curProfit, 2))..'. Позиция закрывается.')
                                local new_task              = {action = {}}
                                new_task.line_text          = Sec.SEC_CODE..': Закрытие позиции: '..tostring(curOpenCount)
                                new_task.action['command']  = 'MANUAL_CLOSE_POSITION'
                                new_task.action['email']    = CORRECT_EMAIL_ADRESS
                                new_task.action['strategy'] = str_key
                                new_task.action['sec_code'] = Sec.SEC_CODE
                                COMMANDS_STACK[#COMMANDS_STACK+1] = new_task
                                strategy.task_in_progress = new_task
                            end
                        end
                    end
                end
            end
        end
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error CheckTickersPos: '..tostring(res)) end
end

--Блок вызова функций алгоритма
local function Algo()

    if not isRun or not isTrade then return end

    local status,res = pcall(function()

        PosLayer()
        ReadDataFiles()
        --CheckEmailLogs()
        CheckTickersPos()
        if email_message~='' then
            SendEmail(email_message)
            email_message = ''
        end
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error Algo: '..tostring(res)) end
end

-- Восстанавливает состояние прошлого дня
local function RepareState()

    local status,res = pcall(function()

        for sec_code, class_code in pairs(T.TRACK_LIST) do
            local Sec = InitSec(sec_code, class_code)
            if type(Sec)=='table' then

                for str_index, strategy in pairs(T[Sec.SEC_CODE].STRATEGIES) do

                    strategy.task_in_progress   = nil

                    Sec.ACCOUNT                 = strategy.account
                    Sec.CLIENT_CODE             = strategy.client_code
                    Sec.FIRM_ID                 = GetAccountFirmID(Sec.ACCOUNT)

                    local savedAvg              = T[Sec.SEC_CODE].avgPosPrice
                    local savedVolume           = T[Sec.SEC_CODE].posVolume
                    local savedDealTime         = T[Sec.SEC_CODE].lastDealTime
                    local savedDealPricetable   = T[Sec.SEC_CODE].dealPricetable

                    local curOpenCount, avgPosPrice = GetTotalnet(Sec)

                    myLog(NAME_OF_STRATEGY..' RepareState '..tostring(sec_code)..' strategy '..tostring(str_index)..' curOpenCount '..tostring(curOpenCount)..' T[Sec.SEC_CODE].OpenCount: '..tostring(T[Sec.SEC_CODE].OpenCount))
                    if T[Sec.SEC_CODE].OpenCount ~= curOpenCount then

                        T[Sec.SEC_CODE].lastDealsCount  = 0
                        myLog(NAME_OF_STRATEGY..' Анализ позиции по инструменту: '..tostring(Sec.SEC_CODE)..' кол.: '..tostring(curOpenCount)..' ср. цена: '..tostring(avgPosPrice)..', lastDealsCount: '..tostring(T[Sec.SEC_CODE].lastDealsCount))

                        if (T[Sec.SEC_CODE].OpenCount<=0 and curOpenCount<T[Sec.SEC_CODE].OpenCount) or (T[Sec.SEC_CODE].OpenCount>=0 and curOpenCount>T[Sec.SEC_CODE].OpenCount) then
                            T[Sec.SEC_CODE].OpenCount       = curOpenCount

                            local avgOrderPrice, lastDealTime, price_table, volume = getAvgPrice(Sec, curOpenCount == 0 and T[Sec.SEC_CODE].OpenCount or curOpenCount)

                            T[Sec.SEC_CODE].avgPosPrice     = avgOrderPrice ~= 0 and avgOrderPrice or T[Sec.SEC_CODE].avgPosPrice
                            T[Sec.SEC_CODE].posVolume       = volume ~= 0 and volume or T[Sec.SEC_CODE].posVolume
                            T[Sec.SEC_CODE].lastDealTime    = lastDealTime ~= 0 and lastDealTime or T[Sec.SEC_CODE].lastDealTime
                            T[Sec.SEC_CODE].dealPricetable  = price_table[1] and price_table or T[Sec.SEC_CODE].dealPricetable
                            T[Sec.SEC_CODE].lastOpenCount   = curOpenCount == 0 and T[Sec.SEC_CODE].OpenCount or curOpenCount
                            if Sec.FUTURES then
                                T[Sec.SEC_CODE].posVolume   = CalcFutVolume(Sec, curOpenCount, T[Sec.SEC_CODE].avgPosPrice) or T[Sec.SEC_CODE].posVolume
                            end

                            myLog(NAME_OF_STRATEGY..' RepareState savedAvg '..tostring(savedAvg)..', T.avgPosPrice: '..tostring(T[Sec.SEC_CODE].avgPosPrice)..', avgPosPrice: '..tostring(avgPosPrice))
                            myLog(NAME_OF_STRATEGY..' RepareState savedDealTime '..tostring(os.date('%c', savedDealTime))..', T.lastDealTime: '..tostring(os.date('%c', T[Sec.SEC_CODE].lastDealTime)))

                            if savedAvg ~= 0 and curOpenCount~=0 then T[Sec.SEC_CODE].avgPosPrice = savedAvg end
                            if savedVolume ~= 0 and curOpenCount~=0 then T[Sec.SEC_CODE].posVolume = savedVolume end
                            if savedDealTime ~= 0 and curOpenCount~= 0 then T[Sec.SEC_CODE].lastDealTime = savedDealTime end
                            if savedDealPricetable and savedDealPricetable[1] and curOpenCount~=0 then T[Sec.SEC_CODE].dealPricetable = savedDealPricetable end
                            if avgPosPrice ~= 0 and curOpenCount~=0 and T[Sec.SEC_CODE].avgPosPrice == 0 then
                                T[Sec.SEC_CODE].avgPosPrice = avgPosPrice
                                T[Sec.SEC_CODE].posVolume   = avgPosPrice*Sec.priceKoeff*curOpenCount
                                if Sec.FUTURES then
                                    T[Sec.SEC_CODE].posVolume     = CalcFutVolume(Sec, curOpenCount, T[Sec.SEC_CODE].avgPosPrice) or T[Sec.SEC_CODE].posVolume
                                end
                                if T[Sec.SEC_CODE].dealPricetable[1] == nil and curOpenCount~=0 then
                                    T[Sec.SEC_CODE].dealPricetable = {qty = curOpenCount, price = avgPosPrice}
                                end
                            end
                        end
                        if (T[Sec.SEC_CODE].OpenCount~=0 and curOpenCount == 0) and (GetTableCount(Sec, 'trades') or 0) == 0 then
                            T[Sec.SEC_CODE].OpenCount       = curOpenCount
                        end
                    end
                end

                myLog(NAME_OF_STRATEGY..' RepareState savedAvg '..tostring(savedAvg)..' T.avgPosPrice '..tostring(T[Sec.SEC_CODE].avgPosPrice)..' savedDealTime '..tostring(os.date('%c', savedDealTime))..' T.lastDealTime '..tostring(os.date('%c', T[Sec.SEC_CODE].lastDealTime))..' lastDealsCount: '..tostring(T[Sec.SEC_CODE].lastDealsCount))
            end
        end
        SaveTable(T, TPath)
        myLog(NAME_OF_STRATEGY.." ==================================================")
        return true
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error RepareState: '..tostring(res))
        return false
    end
    return res

end

--Обработка стека накопленных действий
local function DoCommand()
    local status,res = pcall(function()
        if #COMMANDS_STACK == 0 then return end
        local count = 1
        local continue = count<=#COMMANDS_STACK
        while continue do
            local command = COMMANDS_STACK[count]
            if type(command) == 'table' and type(command.action) == 'table' then

                local strategy = GetActionStrategy(command.action)
                if strategy == nil then
                    AddActionResult(command.action, false, true, 'данная стратегия не обрабатывается')
                elseif not strategy.task_in_progress or strategy.task_in_progress == command then
                    if not command.action.task_in_progress then
                        command.action.task_in_progress = true
                        strategy.task_in_progress       = command
                        myLog('----------------------------------------------------------------------------------')
                        myLog(NAME_OF_STRATEGY..' DoCommand: '..' action: '..tostring(command.line_text))
                        myLog(NAME_OF_STRATEGY..' Обработка команды: '..' action: '..tostring(command.action))
                    end
                    if not (command.action.done or command.action.error) then
                        command = ProcessSignal(command)
                    end
                end
                if command.action.done or command.action.error then
                    if strategy then strategy.task_in_progress   = nil end
                    if command.data_file_name then
                        MoveFile(command.data_file_name, command.action.done and PROCESSED_FILES_PATH or NON_PROCESSED_FILES_PATH)
                        command.data_file_name = nil
                    end
                    local response_mes = ''
                    if command.action.done then
                        response_mes = 'Сигнал обработан успешно: '..tostring(command.line_text)
                    elseif command.action.error then
                        response_mes = 'Сигнал не обработан: '..tostring(command.line_text)..', по причине: '..tostring(command.action.response_mes)
                    end
                    email_message = email_message..(email_message == '' and '' or '\n\n')..response_mes
                    myLog(NAME_OF_STRATEGY..' '..response_mes)
                    if DEBUG_MODE==1 then myLog(NAME_OF_STRATEGY..' Удаление из стека команд: '..tostring(COMMANDS_STACK[count])) end
                    table.remove(COMMANDS_STACK, count)
                    count = count - 1
                end
            else
                table.remove(COMMANDS_STACK, count)
                count = count - 1
            end
            count    = count + 1
            continue = #COMMANDS_STACK > 0 and count<=#COMMANDS_STACK
        end
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error DoCommand: '..tostring(res)) end
end

-- Функция main выполнятся пока перменная isRun=true
function main()

    local status,res = pcall(function()

        -- Цикл по дням
        while isRun do

            -- Ждет начала следующего дня
            while isRun and GetServerDateTime().day == PrevDayNumber do
                sleep(100)
            end

            SERVER_TIME      = GetServerDateTime()
            COMMANDS_STACK   = {}
            InitNewDayTimes()

            local serverDate = os.date('%d.%m.%Y', os.time(SERVER_TIME))
            if (T.TRADE_DATE or '') ~= serverDate then
                T.TRADE_DATE  = serverDate
                MoveOldFiles()
                SaveTable(T, TPath)
            end

            ReadDataFiles   = ReadDataFilesProcessor()
            CheckEmailLogs  = CheckEmailLogsProcessor()
            CheckConnect    = CheckConnectProcessor()

            myLog(NAME_OF_STRATEGY..' Время сервера: '..os.date('%c', os.time(SERVER_TIME)))
            myLog(NAME_OF_STRATEGY..' Автоматический запуск: '..os.date('%c', auto_startTradeTime))
            myLog(NAME_OF_STRATEGY..' Автоматическая остановка: '..os.date('%c', auto_endTradeTime))

            isRun = ReadTickerFile()
            if isRun then isRun = Initialization() end
            if isRun then isRun = RepareState() end
            SetTickersTradeState(false)

            -- Ждет начала торгового дня
            while isRun and os.time(SERVER_TIME) <= startTradeTime do
                SERVER_TIME  = GetServerDateTime()
                DoCommand()
                sleep(100)
            end

            isTrade = true

            -- Цикл внутри дня
            while isRun do

                SERVER_TIME = GetServerDateTime()
                serverTime  = os.time(SERVER_TIME)

                DoCommand()

                if not isRun then break end
                local its_close_time =  (auto_endTradeTime or 0)~=0 and serverTime >= auto_endTradeTime
                if isTrade and its_close_time then
                    isTrade = false
                end
                if not isAutoStart and not manualStop and CheckConnect() and not its_close_time and (auto_startTradeTime or 0)~=0 and serverTime >= auto_startTradeTime then
                    isAutoStart = StartTrade(auto_startTradeTime)
                end

                if isRun then
                    Algo()
                end

                if os.time() - last_save_time > 10 and need_dump_table then
                    need_dump_table = false
                    last_save_time = os.time()
                    SaveTable(T, TPath)
                end

                -- Если торговый день закончился, выходит в цикл по дням
                if serverTime >= endOfDay then PrevDayNumber = SERVER_TIME.day
                    SaveTable(T, TPath)
                    break
                end

                sleep(50)
            end
        end
    end)
    if not status then myLog(' Error main:'..tostring(res)) OnStop() end
end
-------------------------------

-- Функция первичной инициализации скрипта (ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK в самом начале)
function OnInit()

    local lib_path   = getScriptPath()..'\\libs'

    if not directory_exists(lib_path) then
        isRun = false
        SetMessage(NAME_OF_STRATEGY..' Не найдены библиотеки', 3, true)
    end

    dofile(lib_path  .. '\\baseLib.lua')      -- базовые функции робота
    dofile(lib_path  .. '\\tradeLib.lua')     -- базовые функции торговли

    if LOGGING == 1 then
        FILE_LOG_NAME = getScriptPath().."\\"..NAME_OF_STRATEGY.."_Log.txt" -- ИМЯ ЛОГ-ФАЙЛА
        if logFile~=nil then logFile:close() end
        logFile = io.open(FILE_LOG_NAME, "w") -- открывает файл
    end

    if not directory_exists(FILES_PATH) then
        os.execute('mkdir "'..FILES_PATH..'"')
    end
    if not directory_exists(ARCHIVE_FILES_PATH) then
        os.execute('mkdir "'..ARCHIVE_FILES_PATH..'"')
    end
    if not directory_exists(PROCESSED_FILES_PATH) then
        os.execute('mkdir "'..PROCESSED_FILES_PATH..'"')
    end
    if not directory_exists(NON_PROCESSED_FILES_PATH) then
        os.execute('mkdir "'..NON_PROCESSED_FILES_PATH..'"')
    end

    ROBOT_POSTFIX           = '/rSO'
    CORRECT_EMAIL_ADRESS    = (CORRECT_EMAIL_ADRESS or ''):upper()

    CheckConnect            = CheckConnectProcessor()

    -- Загружает таблицу из файла
    local _T = LoadTable(TPath)
    if _T ~= nil then
        T = _T
    end

    myLog(NAME_OF_STRATEGY..' INIT curr state:'..tostring(T))

    FillTradeRefs()

    -- Проверяем, что есть подключение к серверу
    if isConnected() == 0 then
        local mes = 'Нет подключения к серверу, старт невозможен.'
        myLog(NAME_OF_STRATEGY..' '..mes)
        SetMessage(mes, 3 , true)
    end

end

-- Функция ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK при остановке скрипта
function OnStop()

    if not IS_CLOSE then
        myLog(NAME_OF_STRATEGY.." Script Stoped")
        -- Сохраняет таблицу в файл
        SaveTable(T, TPath)
    end
    isRun = false
    if logFile~=nil then logFile:close() end
    logFile = nil
end

-- Функция ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK при при закрытии программы
function OnClose()

    myLog(NAME_OF_STRATEGY.." Script OnClose")
    -- Сохраняет таблицу в файл
    SaveTable(T, TPath)
    IS_CLOSE = true
    isRun    = false
end

-- Функция вызывается терминалом QUIK при получении ответа на транзакцию пользователя
--- OnTransReply Description of the function
-- @param trans_reply Describe the parameter
function OnTransReply(trans_reply)
    -- Если поступила информация по текущей транзакции
    if trans_reply.trans_id == trans_id then
       -- Передает сообщение в глобальную переменную
       trans_result_msg  = trans_reply.result_msg
       myLog(NAME_OF_STRATEGY..' OnTransReply '..tostring(trans_id)..' '..trans_result_msg)
     end
     if trans_reply.status ~= 3 then
        TRANSACTIONS_RESPONSE[trans_reply.trans_id] = trans_result_msg
    end
end

--------------------------------------------------------------------
-- КОНЕЦ: ОСНОВНОЙ БЛОК РАБОТЫ СКРИПТА --
--------------------------------------------------------------------
