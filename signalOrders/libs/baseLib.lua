SEC_CODES                       = {}
CLASS_CODES                     = {}
SEC_CODES_NAMES                 = {}
SEC_CODES_PROPS                 = {}
CLASS_CODES_PROPS               = {}
ACCOUNTS                        = {}
ACCOUNTS_CLASSES                = {}
CLIENT_CODES                    = {}
SEC_CLASSES                     = {} -- Инструменты и их параметры

startTradeTime                  = 0
endTradeTime                    = 0
dayClearing                     = 0
endOfDayClearing                = 0
eveningClearing                 = 0
eveningSession                  = 0
endOfDay                        = 0
shareEndOfDay                   = 0
local value_separator           = ' '

intervals_rep                   = {}
intervals_rep[1]                = 'M1'
intervals_rep[2]                = 'M2'
intervals_rep[3]                = 'M3'
intervals_rep[4]                = 'M4'
intervals_rep[5]                = 'M5'
intervals_rep[6]                = 'M6'
intervals_rep[10]               = 'M10'
intervals_rep[15]               = 'M15'
intervals_rep[30]               = 'M30'
intervals_rep[60]               = 'H1'
intervals_rep[120]              = 'H2'
intervals_rep[240]              = 'H4'
intervals_rep[1440]             = 'D1'
intervals_rep[10080]            = 'W'
intervals_rep[23200]            = 'M'

TIME_ZONE                       = TIME_ZONE or 0
LOGGING                         = 1
logFile                         = nil -- переменная для хранения лог файла

ROBOT_POSTFIX                  = ROBOT_POSTFIX or ''

T                               = T or {}

_G.unpack       = rawget(table, "unpack") or _G.unpack
_G.loadfile     = _G.loadfile or _G.load
_G.loadstring   = _G.loadstring or _G.load

local math_pow = function(x,y) return x^y end

_G.LUA_51 = _VERSION == "Lua 5.1"

_G._tostring = tostring

local format_value = function(x)
    if type(x) == "number" and (math.floor(x) == x) then
        return LUA_51 and string.format("%0.16g", x) or _G._tostring(math.tointeger(x) or x)
    end
    return _G._tostring(x)
end

local table_to_string
table_to_string = function(value, show_number_keys, miss_key)
    local str = ''
    if show_number_keys == nil then show_number_keys = true end
    miss_key = miss_key or ''

    if (type(value) ~= 'table') then
        if (type(value) == 'string') then
            str = string.format("%q", value)
        else
            str = format_value(value)
        end
    else
        local auxTable = {}
        local max_index = #value
        for key in pairs(value) do
            if type(key) ~= "table" and type(key) ~= "function" then
                if not miss_key:find(key) and value[key] ~= nil then
                    if (tonumber(key) ~= key) then
                        table.insert(auxTable, key)
                    else
                        table.insert(auxTable, string.rep('0', max_index-format_value(key):len())..format_value(key))
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
                prefix    = (show_number_keys and "["..format_value(tonumber(fieldName)).."] = " or '')
            end
            entry = value[fieldName]
            -- Check the value type
            if type(entry) == "table" and getmetatable(entry) == nil then
                entry = table_to_string(entry, show_number_keys, miss_key)
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

_G.tostring = function(x, ...)
    if type(x) == "table" and getmetatable(x) == nil then
      return table_to_string(x, ...)
    else
      return format_value(x)
    end
end

local function log_tostring(...)
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

function myLog(...)
	if LOGGING ~= 1 or logFile==nil then return end
    logFile:write(tostring(os.date("%c",os.time())).." "..log_tostring(...).."\n");
    logFile:flush();
end

--------------------------------------------------------------------
-- ОСНОВНОЙ БЛОК РАБОТЫ СКРИПТА --
--------------------------------------------------------------------

--Заполняем справочники: Классы инструментов, Инструменты, Счета
function FillTradeRefs()

    SEC_CODES                       = {}
    CLASS_CODES                     = {}
    SEC_CODES_NAMES                 = {}
    SEC_CODES_PROPS                 = {}
    CLASS_CODES_PROPS               = {}
    ACCOUNTS                        = {}
    ACCOUNTS_CLASSES                = {}
    CLIENT_CODES                    = {}

    for i=0, getNumberOf("trade_accounts")-1 do
        local trade_account=getItem("trade_accounts",i)
        if trade_account.status == 0 then
            --myLog('Доступен Счет: '..tostring(trade_account.trdaccid))
            --myLog(table_to_string(trade_account))
            ACCOUNTS[i+1] = trade_account.trdaccid
            ACCOUNTS_CLASSES[trade_account.trdaccid] = trade_account.class_codes
        end
    end
    for i=0, getNumberOf("client_codes")-1 do
        local client_code=getItem("client_codes",i)
        if client_code~=nil and client_code~='' then
            --myLog('Доступен Клиентский код: '..tostring(client_code))
            CLIENT_CODES[i+1] = client_code
        end
    end
    for i=0, getNumberOf("classes")-1 do
        local class=getItem("classes",i)
        if class~=nil and TRACK_CLASS_CODES:find(class.code) then
            --myLog('Доступен Класс: '..tostring(class.name)..' - '..tostring(class.code))
            CLASS_CODES[#CLASS_CODES+1] = {code = class.code, name = class.name}
            CLASS_CODES_PROPS[class.code] = {firmid = class.firmid, name = class.name}
        end
    end
    for i=0, getNumberOf("securities")-1 do
        local securitie=getItem("securities",i)
        if securitie~= nil and TRACK_CLASS_CODES:find(securitie.class_code) then
            --myLog('Доступен Инструмент: '..tostring(securitie.name)..' - '..tostring(securitie.code)..'. class: '..tostring(securitie.class_code))
            SEC_CODES[#SEC_CODES+1] = {class_code = securitie.class_code, class_name = securitie.class_name, code = securitie.code, name = securitie.name, short_name = securitie.short_name, mat_date = (tonumber(securitie.mat_date) or 0)}
            SEC_CODES_NAMES[securitie.code] = {name = securitie.short_name}
            if SEC_CODES_PROPS[securitie.code] == nil then SEC_CODES_PROPS[securitie.code] = {} end
            SEC_CODES_PROPS[securitie.code][#SEC_CODES_PROPS[securitie.code]+1] = {class_code = securitie.class_code, class_name = securitie.class_name, code = securitie.code, name = securitie.name, mat_date = (tonumber(securitie.mat_date) or 0)}
        end
    end
end

function CheckSecCode(sec_code, class_code)
    if getSecurityInfo(class_code, sec_code) == nil then
        if SEC_CODES_PROPS~=nil and SEC_CODES_PROPS[sec_code]~=nil then
            local class_codes = FindSecClass(sec_code)
            if not class_codes:find(class_code) then
                res = "Допущена ошибка при описании класса инструмента: "..sec_code.."/"..tostring(class_code)..', доступные классы: '..tostring(class_codes)
                return false, res
            end
        end
        res = "Не удалось получить данные по инструменту: "..sec_code.."/"..tostring(class_code)
        return false, res
    end
    return true
end

--Получение параметров торгуемого инструмента
function GetSECProp(S)

    if not S or type(S) ~= 'table' then return false end

    if SEC_CLASSES[S.SEC_CODE]~= nil then return SEC_CLASSES[S.SEC_CODE] end

    if #ACCOUNTS == 0 then FillTradeRefs() end

    --Класс Инструмента. Его значения по умолчанию.
    local sec_default = {
        CLASS_CODE                      = CLASS_CODE or '',
        CLASS_NAME                      = CLASS_NAME or '',
        SEC_CODE                        = '',
        SEC_NAME                        = '',
        ACCOUNT                         = ACCOUNT or '',
        CLIENT_CODE                     = CLIENT_CODE or '',
        BALANCE_TYPE                    = BALANCE_TYPE,
        LIMIT_KIND                      = LIMIT_KIND,
        SEC_PRICE_STEP                  = 1, -- ШАГ ЦЕНЫ ИНСТРУМЕНТА
        SCALE                           = 0, -- РАЗРЯДНОСТЬ ЦЕНЫ ИНСТРУМЕНТА (ДЛЯ ОКРУГЛЕНИЯ)
        STEPPRICE                       = 1, --Цена шага цены инструмента
        FIRM_ID                         = '', --Фирма, для срочного рынка
        LOTSIZE                         = 1, --Количество в одном лоте интрумента
        CHART_ID                        = CHART_ID,
        priceKoeff                      = 1, --переменная для определения пункта(рубля) движения цены.
        scaleKoeff                      = 1,
        mat_date                        = 0,
        cur_orders_count                = 0,
        cur_stop_orders_count           = 0,
        canTrade                        = false,
        startTradeTime                  = startTradeTime,
        endTradeTime                    = endTradeTime,
        dayClearing                     = dayClearing,
        endOfDayClearing                = endOfDayClearing,
        eveningClearing                 = eveningClearing,
        eveningSession                  = eveningSession,
        endOfDay                        = endOfDay,
        shareEndOfDay                   = shareEndOfDay
    }

    local mt = {}    -- создает метатаблицу
    -- объявляет функцию-конструктор
    local function newSec(o)
        setmetatable(o, mt)
        return o
    end

    --Теперь мы определим метаметод __index:
    mt.__index = function (_, key)
        return sec_default[key]
    end

    if S.CLASS_CODE == nil and SEC_CODES_PROPS~=nil and SEC_CODES_PROPS[S.SEC_CODE]~=nil then
        S.CLASS_CODE = FindSecClass(S.SEC_CODE)
    end

    local Sec = newSec(S)
    --Sec.CLASS_CODE = class_code or Sec.CLASS_CODE
    --Sec.ACCOUNT = account or Sec.ACCOUNT
    --Sec.CHART_ID = chart_id or Sec.CHART_ID

    if SEC_CODES_NAMES~=nil and SEC_CODES_NAMES[S.SEC_CODE]~=nil then
        Sec.SEC_NAME = SEC_CODES_NAMES[S.SEC_CODE].name
    end

    if CLASS_CODES_PROPS~=nil and CLASS_CODES_PROPS[S.CLASS_CODE]~=nil then
        Sec.CLASS_NAME = CLASS_CODES_PROPS[S.CLASS_CODE].name
    end

    myLog('GetSECProp sec_code '..tostring(S.SEC_CODE)..' class_code '..tostring(Sec.CLASS_CODE)..' CLIENT_CODE '..tostring(Sec.CLIENT_CODE)..' ACCOUNT '..tostring(Sec.ACCOUNT))

    local sec_correct, res = CheckSecCode(S.SEC_CODE, Sec.CLASS_CODE)
    if not sec_correct then
        myLog(NAME_OF_STRATEGY.." "..tostring(res))
        return false, res
    end

    local function num_to_strTime(num)
        local strTime = tostring(num)
        if strTime:len()~=6 then return nil end
        return strTime:sub(1,2)..':'..strTime:sub(3,4)..':'..strTime:sub(5,6)
    end

    local STARTTIME     = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "STARTTIME").param_value) or 0
    local ENDTIME       = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "ENDTIME").param_value) or 0
    local EVNSTARTTIME  = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "EVNSTARTTIME").param_value) or 0
    local EVNENDTIME    = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "EVNENDTIME").param_value) or 0

    if STARTTIME~=0 then
        strTime = num_to_strTime(STARTTIME)
        if strTime~=nil then
            Sec.startTradeTime   = os.time(GetStringTime(strTime))
        end
    end
    if ENDTIME~=0 then
        strTime = num_to_strTime(ENDTIME)
        if strTime~=nil then
            Sec.eveningClearing   = os.time(GetStringTime(strTime))
            Sec.shareEndOfDay     = os.time(GetStringTime(strTime))
        end
    end
    if EVNSTARTTIME~=0 then
        strTime = num_to_strTime(EVNSTARTTIME)
        if strTime~=nil then
            Sec.eveningSession   = os.time(GetStringTime(strTime))
        end
    end
    if EVNENDTIME~=0 then
        strTime = num_to_strTime(EVNENDTIME)
        if strTime~=nil then
            Sec.endOfDay   = os.time(GetStringTime(strTime))
        end
    end

    Sec.FUTURES         = (Sec.CLASS_CODE == 'SPBFUT' or Sec.CLASS_CODE == 'SPBOPT' or (Sec.CLASS_CODE:find('SPREAD')))
    Sec.SEC_PRICE_STEP  = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "SEC_PRICE_STEP").param_value) or 0
    Sec.SCALE           = tonumber(getSecurityInfo(Sec.CLASS_CODE, Sec.SEC_CODE).scale) or 0
    Sec.STEPPRICE       = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "STEPPRICE").param_value) or 0
    Sec.LOTSIZE         = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "LOTSIZE").param_value) or 0
    Sec.mat_date        = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "MAT_DATE").param_value) or 0

    local res = ''

    -- Тип отображения баланса в таблице "Таблица лимитов по денежным средствам" (1 - в лотах, 2 - с учетом количества в лоте)
    -- Например, при покупке 1 лота USDRUB одни брокеры в поле "Баланс" транслируют 1, другие 1000
    -- Обычно, для срочного рынка = 1, для фондового рынка = 2
    Sec.BALANCE_TYPE = 1

    --0 - Т0, 1 - Т1, 2 - Т2
    --LIMIT_KIND = 0
    local status, mes = CheckSecAccount(Sec)
    if not status then
        res = (res == '' and res or res..'\n')..mes
        return false, res
    end

    if Sec.FUTURES then
        if Sec.SEC_PRICE_STEP == 0 or Sec.SEC_PRICE_STEP == nil then
            Sec.priceKoeff = 1
            local mes = "Для инструмента: " .. Sec.SEC_CODE .. " не определен шаг цены: " .. tostring(Sec.SEC_PRICE_STEP)
            myLog(NAME_OF_STRATEGY..' '..mes)
            res = (res == '' and res or res..'\n')..mes
            return false, res
        elseif Sec.STEPPRICE == 0 or Sec.STEPPRICE == nil then
            Sec.priceKoeff = 1
            local mes = "Для инструмента: " .. Sec.SEC_CODE .. " не определена стоимость шага цены: " .. tostring(Sec.STEPPRICE)
            myLog(NAME_OF_STRATEGY..' '..mes)
            res = (res == '' and res or res..'\n')..mes
            return false, res
        else
            Sec.priceKoeff = Sec.STEPPRICE/Sec.SEC_PRICE_STEP
        end
    else
        Sec.priceKoeff = Sec.LOTSIZE
        if Sec.LOTSIZE == 0 or Sec.LOTSIZE == nil then
            Sec.priceKoeff = 1
            local mes = "Для инструмента: " .. Sec.SEC_CODE .. " не определен размер лота: " .. tostring(Sec.LOTSIZE)
            myLog(NAME_OF_STRATEGY..' '..mes)
            res = (res == '' and res or res..'\n')..mes
            return false, res
        end
        Sec.BALANCE_TYPE = 2
        --LIMIT_KIND = 2
        if Sec.LIMIT_KIND == 0 then
            local mes = 'Проверьте установки лимита для получения баланса. Сейчас он установлен Т0, для акций должно быть Т2!!!'
            myLog(NAME_OF_STRATEGY..' '..mes)
            res = (res == '' and res or res..'\n')..mes
        end
    end
    Sec.scaleKoeff = math_pow(10, Sec.SCALE or 0)

    if Sec.ACCOUNT~= '' and Sec.FUTURES then
        Sec.CLIENT_CODE = Sec.ACCOUNT
    end

    if not Sec.FUTURES then
        local status, mes = CheckSecClientCode(Sec)
        if not status then
            res = (res == '' and res or res..'\n')..mes
            return false, res
        end
    end

    Sec.cur_orders_count        = GetTableCount(Sec, 'orders')
    Sec.cur_stop_orders_count   = GetTableCount(Sec, 'stop_orders')

    SEC_CLASSES[S.SEC_CODE]     = Sec

    return Sec, res

end

-- Проверить торговый счет
function CheckSecAccount(Sec)
    -- Возвращает таблицу-описание торгового счета по его названию
    -- или nil, если торговый счет не обнаружен
    local function getTradeAccount(class_code, account)
        if account == nil or account == '' then return end
        -- Функция возвращает таблицу с описанием торгового счета для запрашиваемого кода класса
        for i=0,getNumberOf ("trade_accounts")-1 do
            local trade_account=getItem("trade_accounts",i)
            myLog(NAME_OF_STRATEGY..' Торговый счет: '..tostring(trade_account.trdaccid)..', допустимые class_codes: '..tostring(trade_account.class_codes))
            if string.find(trade_account.class_codes,class_code,1,1) and trade_account.trdaccid == account then return trade_account end
        end
        return nil
    end

    if Sec.ACCOUNT~=''then
        local trdaccid=getTradeAccount(Sec.CLASS_CODE, Sec.ACCOUNT)
        -- Проверяем соотношение ACCOUNT и CLASSCODE
        if trdaccid == nil then
            local mes = "Торговый счет " .. Sec.ACCOUNT .. " не позволяет торговать инструментом " .. Sec.SEC_CODE .. "/" .. Sec.CLASS_CODE
            myLog(NAME_OF_STRATEGY..' '..mes)
            return false, mes
        else
            Sec.FIRM_ID = trdaccid.firmid
        end
    end
    return true
end

-- Проверить код клиента
function CheckSecClientCode(Sec)
    local function getClientCode(firmid, client_code)
        if client_code == nil or client_code == '' then return end
        for i=0,getNumberOf ("money_limits")-1 do
            local money_limit=getItem("money_limits",i)
            myLog(NAME_OF_STRATEGY..' FIRM_ID: '..tostring(money_limit.firmid)..', допустимый код клиента: '..tostring(money_limit.client_code))
            if money_limit.firmid == firmid and money_limit.client_code == client_code then return money_limit end
        end
        return nil
    end

    if (Sec.FIRM_ID or '')~='' and (Sec.CLIENT_CODE or '')~='' then
        if Sec.FUTURES then
            if Sec.CLIENT_CODE ~= Sec.ACCOUNT then
                local mes = "Код клиента " .. tostring(Sec.CLIENT_CODE) .. " должен быть равен счету"
                myLog(mes)
                return false, mes
            end
            return true
        end
        local money_limit=getClientCode(Sec.FIRM_ID, Sec.CLIENT_CODE)
        if money_limit == nil then
            local mes = "Код клиента " .. tostring(Sec.CLIENT_CODE) .. " не позволяет торговать инструментом " .. Sec.SEC_CODE .. "/" .. Sec.CLASS_CODE
            myLog(NAME_OF_STRATEGY..' '..mes)
            return false, mes
        else
            Sec.CLIENT_CODE = money_limit.client_code
        end
    end
    return true
end

-- Получить класс по коду инструмента
function FindSecClass(sec_code)
    local class_names = ''
    if not SEC_CODES_PROPS[sec_code] then return '' end
    for i,v in ipairs(SEC_CODES_PROPS[sec_code]) do
        class_names = (class_names == '' and '' or '|')..v.class_code
    end
    return class_names
end

-- Получить иднтификатор фирмы счета
function GetAccountFirmID(account)
    for i=0,getNumberOf ("trade_accounts")-1 do
        local trade_account=getItem("trade_accounts",i)
        if trade_account.trdaccid == account then return trade_account.firmid end
    end
end

-- ИНициализация таблицы состояния по инструменту
function InitSec_T(sec_code)
    T[sec_code]                               = {}
    T[sec_code].avgPosPrice                   = 0         --переменная для хранения средней цены позиции
    T[sec_code].posVolume                     = 0         --переменная для хранения объема позиции
    T[sec_code].lastDealTime                  = 0         --переменная для хранения времени открытой позиции
    T[sec_code].lastOpenCount                 = 0
    T[sec_code].LIMIT_ORDER                   = nil
    T[sec_code].OpenCount                     = 0         --переменная для хранения текущей открытой позиции
    T[sec_code].dealPricetable                = {}        --переменная для хранения цен позиции
end

--Проверка состояния торговой сессии по инструменту
-- «1» – основная сессия;
-- «2» – начался промклиринг;
-- «3» – завершился промклиринг;
-- «4» – начался основной клиринг;
-- «5» – основной клиринг: новая сессия назначена;
-- 6» – завершился основной клиринг;
-- «7» – завершилась вечерняя сессия
function SessionStatus(Sec)

    local status, res, state = pcall(function()

        if not isRun then return false, 'Робот остановлен' end

        local class_code = (Sec~=nil and type(Sec) == 'table') and Sec.CLASS_CODE or ((Sec~=nil and type(Sec) == 'string') and Sec or CLASS_CODE)

        if Sec~=nil and type(Sec) == 'table' then

            --[[ На демо счете данный вариант может не работать]]
            if not Sec.FUTURES then
                if getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "STATUS").result == '1' and getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "TRADINGSTATUS").result == '1' then

                    --local status         = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "STATUS").param_value) or 0
                    local trading_status = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "TRADINGSTATUS").param_value) or 0

                    --if status == 0 then
                    --    return false, 'Инструмент не торгуется'
                    --end
                    if trading_status~=0 then
                        if trading_status == 4 then
                            return false, 'Завершилась основная сессия'
                        end
                        if trading_status == 5 then
                            return true, 'Аукцион закрытия'
                        end
                        if trading_status == 1 then
                            return true, 'Основная сессия'
                        end
                        return false, 'Неопределен статус сессии'
                    end
                end
            end
            --[[ На демо счете данный вариант может не работать]]

            if Sec.FUTURES then

                --[[ На демо счете данный вариант может не работать]]
                if getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "STATUS").result == '1' and getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "CLSTATE").result == '1' then

                    --local status    = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "STATUS").param_value) or 0
                    local cl_status = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "CLSTATE").param_value) or 0

                    --if status == 0 then
                    --    return false, 'Инструмент не торгуется'
                    --end
                    if cl_status~=0 then
                        local can_trade = cl_status~=2 and cl_status~=4 and cl_status~=5 and cl_status~=7
                        local state =     cl_status==1 and 'Основная сессия' or
                                        ( cl_status==2 and 'Начался промклиринг' or
                                        ( cl_status==3 and 'Завершился промклиринг' or
                                        ( cl_status==4 and 'Начался основной клиринг' or
                                        ( cl_status==5 and 'Основной клиринг: новая сессия назначена' or
                                        ( cl_status==6 and 'Завершился основной клиринг' or 'Завершилась вечерняя сессия')))))
                        return can_trade, state
                    end
                end
                --[[ На демо счете данный вариант может не работать]]

                local fut_hold = getFuturesHolding(Sec.FIRM_ID, Sec.ACCOUNT, Sec.SEC_CODE, 0)
                if fut_hold~=nil then
                    local can_trade = fut_hold.session_status~=2 and fut_hold.session_status~=4 and fut_hold.session_status~=5 and fut_hold.session_status~=7
                    local state =     fut_hold.session_status==1 and 'Основная сессия' or
                                    ( fut_hold.session_status==2 and 'Начался промклиринг' or
                                    ( fut_hold.session_status==3 and 'Завершился промклиринг' or
                                    ( fut_hold.session_status==4 and 'Начался основной клиринг' or
                                    ( fut_hold.session_status==5 and 'Основной клиринг: новая сессия назначена' or
                                    ( fut_hold.session_status==6 and 'Завершился основной клиринг' or 'Завершилась вечерняя сессия')))))
                    return can_trade, state
                end
            end
        end

        local serverTime = os.time(GetServerDateTime())
        if not ('SPBFUT|SPBOPT'):find(class_code) then
            -- Окончена дневная сессия
            if shareEndOfDay~=0 and serverTime+5 >= shareEndOfDay then
               return false, 'Закончен торговый день'
            end
            if endTradeTime~=0 and serverTime+5 >= endTradeTime then
                return true, 'Завершилась основная сессия'
            end
            if startTradeTime~=0 and serverTime >= startTradeTime then
                return true, 'Основная сессия'
            end
            return false, 'Неопределен статус сессии'
        end

        -- Закончен день
        if endOfDay~=0 and serverTime + 5 >= endOfDay then
            return false, 'Закончен торговый день'
        end
        -- Если идет вечерний клиринг
        if eveningClearing~=0 and eveningSession~=0 and serverTime + 5 >= eveningClearing and serverTime < eveningSession then
            return false, 'Вечерний клиринг'
        end
        -- Если идет дневной клиринг
        if dayClearing~=0 and endOfDayClearing~=0 and serverTime + 5 >= dayClearing and serverTime < endOfDayClearing then
            return false, 'Дневной клиринг'
        end
        if startTradeTime~=0 and serverTime >= startTradeTime then
            return true, serverTime < eveningClearing and 'Основная сессия' or 'Вечерняя сессия'
        end

        return false, 'Неопределен статус сессии'
    end)
    if not status then
        myLog(NAME_OF_STRATEGY..' Error SessionStatus: '..tostring(res))
        return false, 'ошибка получения статуса сессии'
    end
    return res, state
end

-- Расчет ГО для фьючерсного контракта
function CalcPriceGO(Sec, go, deal_price, Type)
    local status, res = pcall(function()
        if getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "CLPRICE").result ~= '1' then
            myLog(NAME_OF_STRATEGY..[[ Для точного расчета ГО необходимо включить в поток данных параметр "Котировка последнего клиринга".
                                      Сейчас он не включен. Будет взято базовое ГО]])
            return go
        end
        if getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "PRICEMAX").result ~= '1' then
            myLog(NAME_OF_STRATEGY..[[ Для точного расчета ГО необходимо включить в поток данных параметр "Максимально возможная цена". Сейчас он не включен.
                                    Сейчас он не включен. Будет взято базовое ГО]])
            return go
        end
        if getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, "PRICEMIN").result ~= '1' then
            myLog(NAME_OF_STRATEGY..[[ Для точного расчета ГО необходимо включить в поток данных параметр "Минимально возможная цена". Сейчас он не включен.
                                    Сейчас он не включен. Будет взято базовое ГО]])
            return go
        end
        local cl_price           = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE,'CLPRICE').param_value) or 0
        local max_price          = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE,'PRICEMAX').param_value) or 0
        local min_price          = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE,'PRICEMIN').param_value) or 0
        if cl_price==0 or max_price == 0 or min_price == 0 then return go end
        local L2                 = (max_price-min_price)*math_pow(10, Sec.SCALE)
        local R                  = (go/(L2*Sec.priceKoeff) - 1)*100
        local sign               = Type == 'BUY' and -1 or 1
        return                   go + sign*(cl_price - deal_price)*Sec.priceKoeff*(1 + R/100)
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error CalcPriceGO: '..tostring(res))
        return go
    end
    return res
end

-- Расчет объема позиции фьючерсного контракта
function CalcFutVolume(Sec, curOpenCount, deal_price)
    local status, res = pcall(function()
        local Type  = curOpenCount > 0 and 'BUY' or 'SELL'
        local DEPO  = Type=='BUY' and  'BUYDEPO' or 'SELLDEPO'
        if getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, DEPO).result ~= '1' then
            myLog(NAME_OF_STRATEGY..' Для расчета ГО необходимо включить в поток данных параметр "'..DEPO..[[".
                                      Сейчас он не включен. ГО не получено.]])
            return
        end
        local GO    = tonumber(getParamEx(Sec.CLASS_CODE, Sec.SEC_CODE, DEPO).param_value) or 0
        if (deal_price or 0)~=0 then GO = CalcPriceGO(Sec, GO, deal_price, Type) end
        return GO*math.abs(curOpenCount)
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error CalcFutVolume: '..tostring(res))
        return
    end
    return res
end

-- Получает текущую чистую позицию по инструменту
function GetTotalnet(Sec)

    local pos = 0
    local avgPrice = 0

    local status,res = pcall(function()
        -- ФЬЮЧЕРСЫ, ОПЦИОНЫ
        if Sec.FUTURES then
            local num = getNumberOf('futures_client_holding')
            if num > 0 then
                if num > 1 then
                    for i = 0, num - 1 do
                        local futures_client_holding = getItem('futures_client_holding',i)
                        if futures_client_holding.sec_code == Sec.SEC_CODE and futures_client_holding.trdaccid == Sec.ACCOUNT then
                            if Sec.BALANCE_TYPE == 1 then
                                pos = futures_client_holding.totalnet
                            else
                                pos = futures_client_holding.totalnet/Sec.LOTSIZE
                            end
                            avgPrice = futures_client_holding.avrposnprice
                        end
                    end
                else
                    local futures_client_holding = getItem('futures_client_holding',0)
                    if futures_client_holding.sec_code == Sec.SEC_CODE and futures_client_holding.trdaccid == Sec.ACCOUNT then
                        if Sec.BALANCE_TYPE == 1 then
                            pos = futures_client_holding.totalnet
                        else
                            pos = futures_client_holding.totalnet/Sec.LOTSIZE
                        end
                        avgPrice = futures_client_holding.avrposnprice
                    end
                end
            end
        -- ВАЛЮТА
        elseif Sec.CLASS_CODE == 'CETS' then
            local num = getNumberOf('money_limits')
            if num > 0 then
                -- Находит валюту
                local cur = string.sub(Sec.SEC_CODE, 1, 3)
                -- Находит размер лота
                if num > 1 then
                    local currentbal = 0
                    for i = 0, num - 1 do
                        local money_limit = getItem('money_limits', i)
                        if money_limit.currcode == cur
                        and (money_limit.client_code == Sec.CLIENT_CODE or Sec.CLIENT_CODE == '')
                        and (money_limit.limit_kind == 0 or money_limit.limit_kind == 2) then
                            currentbal = currentbal + money_limit.currentbal
                        end
                    end
                    if currentbal == 0 then return 0 end
                    if Sec.BALANCE_TYPE == 1 then
                        pos = currentbal
                    else
                        pos =  math.round(currentbal/Sec.LOTSIZE)
                    end
                else
                    local money_limit = getItem('money_limits', 0)
                    if money_limit.currcode == cur
                    and money_limit.client_code == Sec.CLIENT_CODE
                    and (money_limit.limit_kind == 0 or money_limit.limit_kind == 2) then
                        if Sec.BALANCE_TYPE == 1 then
                            pos = money_limit.currentbal
                        else
                            pos = math.round(money_limit.currentbal/Sec.LOTSIZE)
                        end
                    end
                end
            end
        -- АКЦИИ
        elseif not Sec.FUTURES then
            local num = getNumberOf('depo_limits')
            if num > 0 then
                if num > 1 then
                    for i = 0, num - 1 do
                        local depo_limit = getItem('depo_limits', i)
                        if depo_limit.sec_code      == Sec.SEC_CODE
                        and (depo_limit.trdaccid     == Sec.ACCOUNT or Sec.ACCOUNT == '')
                        and (depo_limit.client_code  == Sec.CLIENT_CODE or Sec.CLIENT_CODE == '')
                        and depo_limit.limit_kind   == Sec.LIMIT_KIND then
                            if Sec.BALANCE_TYPE == 1 then
                                pos = depo_limit.currentbal
                            else
                                pos = depo_limit.currentbal/Sec.LOTSIZE
                            end
                            avgPrice = depo_limit.awg_position_price
                        end
                    end
                else
                    local depo_limit = getItem('depo_limits', 0)
                    if depo_limit.sec_code      == Sec.SEC_CODE
                    and (depo_limit.trdaccid     == Sec.ACCOUNT or Sec.ACCOUNT == '')
                    and (depo_limit.client_code  == Sec.CLIENT_CODE or Sec.CLIENT_CODE == '')
                    and depo_limit.limit_kind   == Sec.LIMIT_KIND then
                        if Sec.BALANCE_TYPE == 1 then
                            pos = depo_limit.currentbal
                        else
                            pos = depo_limit.currentbal/Sec.LOTSIZE
                        end
                        avgPrice = depo_limit.awg_position_price
                    end
                end
            end

        end
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error GetTotalnet') end

    return round(pos), avgPrice
end

--Получение средней позиции по выполненным ордерам
function getAvgPrice(Sec, pos, limit_order)

    local avgPrice      = 0
    local lastDealTime  = 0
    local price_table   = {}
    local volume        = 0

    local status,res = pcall(function()
        if pos~=0 then

            local netCount          = math.abs(pos)
            local local_pos         = math.abs(pos)
            local local_netCount    = local_pos

            myLog('--------------------------------------------------------------------------')
            myLog(NAME_OF_STRATEGY..' поиск средней цены позиции '..tostring(pos)..', позиция входа: '..tostring(local_pos))
            local num = getNumberOf('trades')-1
            for i=num, 0, -1 do
                if netCount <= 0 then
                    break
                end
                local trade = getItem('trades', i)
                if trade ~= nil and trade.class_code == Sec.CLASS_CODE and trade.sec_code == Sec.SEC_CODE and (trade.account == Sec.ACCOUNT or Sec.ACCOUNT == '') and (trade.client_code:find(Sec.CLIENT_CODE)~=nil or Sec.CLIENT_CODE == '') then
                    local itsClosePos = (pos>0 and bit.test(trade.flags,2)) or (pos<0 and not bit.test(trade.flags,2))
                    myLog(NAME_OF_STRATEGY.." index: "..tostring(i)..",  сделка ордер: "..tostring(trade.order_num).." price "..tostring(trade.price).." qty "..tostring(trade.qty)..' netCount '..tostring(netCount)..' account '..tostring(trade.account)..' client_code '..tostring(trade.client_code)..' brokerref '..tostring(trade.brokerref))
                    myLog(NAME_OF_STRATEGY..' сделка  number: '..tostring(trade.trade_num).." флаг 2 "..tostring(bit.test(trade.flags,2))..' itsClosePos '..tostring(itsClosePos))
                    if not itsClosePos and (limit_order == nil or (limit_order~=nil and trade.order_num == limit_order.order_num)) then
                        price_table[#price_table+1] = {qty = math.min(trade.qty, netCount), price = trade.price}
                        if local_netCount>0 then
                            avgPrice        = avgPrice+trade.price*math.min(trade.qty, local_netCount)
                            local_netCount  = local_netCount-math.min(trade.qty, local_netCount)
                        end
                        netCount = netCount-math.min(trade.qty, netCount)
                        if lastDealTime == 0 then lastDealTime = os.time(trade.datetime) end
                        myLog(NAME_OF_STRATEGY..' avgPrice '..tostring(avgPrice)..' netCount '..tostring(netCount)..' local_netCount '..tostring(local_netCount)..' lastDealTime '..tostring(lastDealTime))
                    end
                end
            end
            if local_pos~=0 then
                volume   = avgPrice*Sec.priceKoeff
                avgPrice = round(math.abs(avgPrice/local_pos), Sec.SCALE)
            end
            if netCount>0 then
                avgPrice    = 0
                volume      = 0
                price_table = {}
            end
            myLog(NAME_OF_STRATEGY..' avgPrice '..tostring(avgPrice))

        end
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error getAvgPrice: '..tostring(res)) end

    return avgPrice, lastDealTime, price_table, volume
end

-- Получает цену последней сделки, если не задано
function GetLastPrice(Sec, level_price, interval, check_last_price)
    if check_last_price then
        level_price = (level_price or 0) == 0 and tonumber(getParamEx(Sec.CLASS_CODE,  Sec.SEC_CODE, 'LAST').param_value) or level_price
    end
    if (level_price or 0) == 0 and (interval or 0)~=0 then
        local ds = DataSource(Sec, interval)
        level_price = (level_price or 0) == 0 and ds:C(ds:Size()) or level_price
    end
    return level_price
end

-- Получение цены в правильном представленнии для выставления транзакции
---@param price number
---@param SCALE number|nil
function format_to_scale(price, SCALE)

    local status,res = pcall(function()

        SCALE = SCALE or 0
        price = tostring(price):gsub(',', '.')
        -- Ищет в числе позицию запятой, или точки
        local dot_pos   = price:find('%.')

        if SCALE > 0 then
            -- Если передано целое число
            if dot_pos == nil then
                -- Добавляет к числу '.' и необходимое количество нулей и возвращает результат
                price = price..'.'..string.rep('0', SCALE)
            else -- передано вещественное число
                local remain = price:sub(dot_pos+1, -1)
                local scale  = remain:len()
                if scale ~= SCALE then
                    price = price:sub(1, dot_pos)..remain:sub(1, math.min(scale, SCALE))
                    price = price..(SCALE > scale and string.rep('0', SCALE - scale) or '')
                end
            end
        elseif dot_pos ~= nil and SCALE == 0 then
            price = price:sub(1, dot_pos-1)
        end
        return price
    end)
    if not status then
        myLog('format_to_scale: '..tostring(res))
        return price
    end
    return res
end

-- Получение цены в правильном представленнии для выставления транзакции
function GetCorrectPrice(Sec, price) -- STRING
    local status,res = pcall(function()
        return round(round(price/Sec.SEC_PRICE_STEP)*Sec.SEC_PRICE_STEP, Sec.SCALE)
    end)

    if status then return res
    else
        myLog(NAME_OF_STRATEGY..' Error GetCorrectPrice: '..tostring(res))
        return price
    end
end

-- Получение количества строк в указанной таблице
function GetTableCount(Sec, table_kind)
    function myFind(C,S,A,L)
        return C == Sec.CLASS_CODE and S == Sec.SEC_CODE and (A == Sec.ACCOUNT or Sec.ACCOUNT == '') and (L:find(Sec.CLIENT_CODE)~=nil or Sec.CLIENT_CODE == '')
    end
    table_kind = table_kind or "orders"
    --myLog(table_kind..' all '..tostring(getNumberOf(table_kind))..' '..ROBOT_POSTFIX)
    local lines = SearchItems(table_kind, 0, getNumberOf(table_kind)-1, myFind, "class_code,sec_code,account,client_code")
    return lines == nil and 0 or #lines
end
--------------------------------------------------------------------
-- КОНЕЦ: ОСНОВНОЙ БЛОК РАБОТЫ СКРИПТА --
--------------------------------------------------------------------


--------------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ СКРИПТА --
--------------------------------------------------------------------

---@param strT string
function FixStrTime(strT)
    strT=tostring(strT)
    local hour, min, sec = 0
    local len = string.len(strT)
    if len==8 then
       hour,min,sec = string.match(strT,"(%d%d)%p(%d%d)%p(%d%d)")
    elseif len==7 then
        hour,min,sec  = string.match(strT,"(%d)%p(%d%d)%p(%d%d)")
    elseif len==6 then
        hour,min,sec  = string.match(strT,"(%d%d)(%d%d)(%d%d)")
    elseif len==5 then
        hour,min,sec  = string.match(strT,"(%d)(%d%d)(%d%d)")
    elseif len==4 then
        hour,min  = string.match(strT,"(%d%d)(%d%d)")
    end
    return hour,min,sec
end

-- Возвращает текущую дату/время сервера в виде таблицы datetime
function GetServerDateTime()

    local dt = {}
    -- Пытается получить дату/время сервера
    while isRun and dt.day == nil do
        dt.day,dt.month,dt.year = string.match(getInfoParam('TRADEDATE'),"(%d*).(%d*).(%d*)")
        dt.hour,dt.min,dt.sec   = FixStrTime(getInfoParam("SERVERTIME"))
        -- Если не удалось получить, или разрыв связи,
        -- ждет подключения и подгрузки с сервера актуальных данных
        if (dt.day or 0) == 0 or (dt.hour or 0) == 0 or isConnected() == 0 then
            return os.date('*t', os.time()-TIME_ZONE*60*60)
        end
   end
   -- Если во время ожидания скрипт был остановлен пользователем,
   -- возвращает таблицу datetime даты/времени компьютера,
   -- чтобы не вернуть пустую таблицу и не вызвать ошибку в алгоритме
   if dt.day == nil then return os.date('*t', os.time()-TIME_ZONE*60*60) end

   -- Приводит полученные значения к типу number
   for key,value in pairs(dt) do dt[key] = tonumber(value) end

   -- Возвращает итоговую таблицу
   return dt
end

-- Приводит время из строкового формата ЧЧ:ММ:CC к формату datetime
---@param str_time string
function StrToTime(str_time, sdt)
    if type(str_time) ~= 'string' then return os.date('*t') end
    sdt         = sdt or GetServerDateTime()
    local h,m,s = string.match(str_time, "(%d%d):(%d%d):(%d%d)")
    sdt.hour    = tonumber(h)
    sdt.min     = tonumber(m)
    sdt.sec     = s==nil and 0 or tonumber(s)
    return sdt
end

---@param str_time string
---@param sdt table|nil
function GetStringTime(str_time, sdt)
    return str_time==0 and {} or (StrToTime(#tostring(str_time)<6 and tostring(str_time)..':00' or tostring(str_time), sdt))
end

-- Приводит время из строкового формата ГГГГ.ММ.ДД ЧЧ:ММ:CC к формату datetime
---@param str_time string
function StrToDateTime(str_time)
    if type(str_time) ~= 'string' then return end
    local sdt   = {}
    sdt.year, sdt.month, sdt.day = string.match(str_time, "(%d*).(%d*).(%d*)")
    local space_pos = str_time:find(' ')
    if (space_pos or 0) ~= 0 then
        return GetStringTime(str_time:sub(space_pos+1), sdt)
    end
    return
end

-- Сохраняет таблицу в файл
---@param Table table
---@param FilePath string
---@param level_to_string number
function SaveTable(Table, FilePath, miss_key, level_to_string)

    local f = io.open(FilePath, 'w')
    if not f then
        myLog("SaveTable Ошибка записи в файл: "..tostring(FilePath))
        return
    end

    local Lines = {}
    local level = 0
    level_to_string = level_to_string or 0
    miss_key = miss_key or ''

    local Rec
    function Rec(a)
        local first = true
        level = level + 1
        local s = string.rep('   ', level)
        for key, val in pairs(a) do
            if not miss_key:find(key) and type(val) ~= 'function' then
                if not first then Lines[#Lines] = Lines[#Lines]..',' end
                local k
                if type(key) == 'number' then
                    k = '['..tostring(key)..']'
                else
                    k = '['..string.format("%q", key)..']'
                end
                if type(val) == 'table' and getmetatable(val) == nil then
                    if level_to_string~=0 and level >= level_to_string then
                        table.insert(Lines, s..k..'='..table_to_string(val))
                        first = false
                    else
                        table.insert(Lines, s..k..'={')
                        first = false
                        Rec(val)
                        table.insert(Lines, s..'}')
                        level = level - 1
                    end
                else
                    if type(val) == 'string' then
                        val = string.format("%q", val)
                    else
                        val = tostring(val)
                    end
                    table.insert(Lines, s..k..'='..val)
                    first = false
                end
            end
        end
    end

    table.insert(Lines, 'local a = {')
    Rec(Table)
    table.insert(Lines, '}')
    table.insert(Lines, 'return a')

    for i=1,#Lines do
       f:write(Lines[i]..'\n')
       f:flush()
    end
    f:close()
end

-- Загружает таблицу из файла
function LoadTable(FilePath)
   local func, err = loadfile(FilePath)
   if not func then
      --ToLogDebug('Ошибка загрузки таблицы из файла: '..err)
      return nil
   else
      return func()
   end
end

function round(num, idp)
    if num then
        local mult = 10^(idp or 0)
        if num >= 0 then
            return math.floor(num * mult + 0.5) / mult
        else
            return math.ceil(num * mult - 0.5) / mult
        end
    else
        return num
    end
end

function mysplit(s, sep)

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

function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function split(s, sep)
    return string.gmatch(s, "([^"..sep.."]+)")
end

function allWords(str, sep)
    return function()
        if str == '' then return nil end
        local pos = string.find(str,sep)
        while pos do
            local word = string.sub(str,1,pos-1)
            str = string.sub(str,pos+1)
            pos = string.find(str,sep)
            return word
        end
        local word = str
        str = ''
        return word
    end
end
