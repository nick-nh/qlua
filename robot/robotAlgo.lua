-- nick-h@yandex.ru
-- Glukk Inc ©

local w32 = require("w32")
require("StaticVar")

maintable={} --maintable.t - главная таблица робота

NAME_OF_STRATEGY    = '' -- НАЗВАНИЕ СТРАТЕГИИ (не более 9 символов!)

ACCOUNT             = ''        -- Идентификатор счета
CLIENT_CODE         = "" -- "Код клиента"
FIRM_ID             = 0 --Фирма, для срочного рынка


-- Величина отступа в шагах цены для выставления рыночной заявки, для ее гарантированного исполнения
-- Понижая отступ можно увеличить допустимый размер набираемой позиции, т.к. расчет ГО ведется от цены устанавливаемой заявки
MARKET_PRICE_OFFSET             = 100

--Настройка закрытия основного окна робота: 1 - при закрытии окна робота выключать скрипт, 0 - переокрывать окно
STOP_ROBOT_ON_CLOSE_TABLE = 0

------ ЗНАЧЕНИЯ ПО УМОЛЧАНИЮ---------
default_ACCOUNT             = 'A701XS7' -- Идентификатор счета
default_CLIENT_CODE         = "A701XS7" -- "Код клиента"

--Режим торгов
-- 0 - Т0, 1 - Т1, 2 - Т2
--Для демо-счета, обычно = 0
--На реальном счете для Акций Т2, для фьючерсов Т0. Это важно.
default_LIMIT_KIND          = 0

DEAL_COUNTER                = 1             --счетчик для учета сделок, заявок в разрезе
default_ROBOT_POSTFIX       = '/'..'rAL'    --идентификатор робота в комментариях к заявкам и сделкам. Для поиска
ROBOT_CLIENT_CODE           = default_CLIENT_CODE..default_ROBOT_POSTFIX..tostring(DEAL_COUNTER) --Строка комментаия в заявках, сделках

default_INTERVAL            = INTERVAL_M3   -- Таймфрейм графика по умолчанию
default_ChartId             = "Sheet11"     -- индентификатор графика, куда выводить метки сделок и данные алгоритма.
default_testSizeBars        = 540           -- размер окна оптимизации стратегии

default_QTY_LOTS            = 1             -- Кол-во торгуемых лотов
default_SetStop             = true          -- выставлять ли стоп заявки
default_fixedstop           = false         -- STOPLOSS не рассчитывать по алгоритму, а брать фиксированным из настроек
default_isLong              = true          -- доступен лонг
default_isShort             = true          -- доступен шорт
default_trackManualDeals    = true          --учитывать ручные сделки не из интерфейса робота при выставлении стоп заявок
-- Важное замечание:
-- Робот автоматически может следовать текущей позиции по инструменту для выставления стоп заявок
-- Если закрыть позицию не из инстерфейса робота, то будет автомтически снята стоп заявка, даже если trackManualDeals = false
-- Если trackManualDeals = true, то при совершении сделок не из робота будут автоматически пересчитаны/сняты стоп завки - это основной режим работы
-- Не рекомендуется ставить trackManualDeals = false, т.к. в этом случае могут остаться стоп заявки по позиции, которая не соответствует текущей
-- Например, робот открыл позицию в количестве 3, руками через команды Стакана или с графика закрыли часть позиции.
-- Если trackManualDeals = false, то робот не пересчитает стоп заявки, и они останутся на позицию 3
-- Чтобы этого избежать необходимо устанавливать trackManualDeals = true
-- Режим trackManualDeals = false можно использовать при торговле руками, не запуская алгоритм робота, используя команды торговли в интерфейче робота
-- Т.о. можно совершать некие смешанные стратегии, когда авто стоп утанавливается при совершении сделок из интерфейса робота,
-- а для сделок с графика стоп заявки не выставляются.

default_STOP_LOSS                   = 25    -- Размер СТОП-ЛОССА в пунктах (в рублях)
default_TAKE_PROFIT                 = 130   -- Размер ТЕЙК-ПРОФИТА в пунктах (в рублях)
default_TRAILING_SIZE               = 25    -- Размер выхода в плюс в пунктах (в рублях), после которого активируется трейлинг
default_TRAILING_SIZE_STEP          = 1     -- Размер шага трейлинга в пунктах (в рублях)
default_OFFSET                      = 2     --(ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
default_SPREAD                      = 50    --Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
default_CLOSE_BAR_SIGNAL            = 1     -- Сигналы на вход поступают: 1 - по закрытию бара; 0 -- в произволное время

default_maxStop                     = 85    -- максимально допустимый стоп в пунктах
default_reopenDealMaxStop           = 75    -- если сделка переоткрыта после стопа, то максимальный стоп
default_stopShiftIndexWait          = 17    -- если цена не двигается (на величину стопа), то пересчитать стоп после стольких баров
default_SL_ADD_STEPS                = 0     -- добавка (в шагах) при динамеческом расчете стоп-лосса
default_kATR                        = 0.5   -- коэффициент ATR для расчета стоп-лосса
default_periodATR                   = 17    -- период ATR для расчета стоп-лосса
default_shiftStop                   = true  -- сдвигать стоп (трейил) на величину STOP_LOSS
default_shiftProfit                 = true  -- сдвигать профит (трейил) на величину STOP_LOSS/2
default_reopenPosAfterStop          = 7     -- если выбило по стопу заявке, то попытаться переоткрыть сделку, после стольких баров

default_autoReoptimize              = false -- надо ли включать оптимизацию перед вечерним клирингом
default_autoClosePosition           = false -- надо ли автоматически закрывать позиции перед вечерним клирингом

default_CloseSLbeforeClearing       = false
default_minToCloseSLbeforeClearing  = 7

------ ЗНАЧЕНИЯ ПО УМОЛЧАНИЮ---------

str_startTradeTime          = '10:00:00' -- Начало торгового дня
str_beginTrade              = '10:15:00' -- Время возможного входа в позицию, ранее сделки не открываются.
str_endTradeTime            = '18:36:00' -- Окончание торговли
str_dayClearing             = '14:00:00'
str_endOfDayClearing        = '14:05:00'
str_eveningClearing         = '18:45:00' -- Время начала клиринга. Для проверки возможного сброса заявок
str_eveningSession          = '19:05:00' -- Время окончания клиринга. Для проверки возможного сброса заявок
str_endOfDay                = '23:50:00'
UpdateDataSecQty            = 10         -- Количество секунд ожидания подгрузки данных с сервера после возобновления подключения
PrevDayNumber               = 0
clearingTime                = 5
-----------------------------
--виртуальная торговля
VIRTUAL_TRADE               = true       --переключение Shift+V
getDOMPrice                 = true
vlastDealPrice              = 0
vdealProfit                 = 0
vallProfit                  = 0

--/*РАБОЧИЕ ПЕРЕМЕННЫЕ РОБОТА (менять не нужно)*/
presets 					= {}
addedPresets 				= {}

SEC_PRICE_STEP              = 0          -- ШАГ ЦЕНЫ ИНСТРУМЕНТА
LOTSIZE                     = 1
SCALE                       = 0
leverage                    = 1
priceKoeff                  = 1/leverage

virtCaption                 = (VIRTUAL_TRADE and 'virtual ' or 'real ')
DS                          = nil               -- Источник данных графика (DataSource)
ROBOT_STATE                 ='FIRSTSTART'
BASE_ROBOT_STATE            ='ОСТАНОВЛЕН'
trans_id                    = os.time()         -- Задает начальный номер ID транзакций
trans_Status                = nil               -- Статус текущей транзакции из функции OnTransPeply
trans_result_msg            = ''                -- Сообщение по текущей транзакции из функции OnTransPeply
CurrentDirect               = 'BUY'             -- Текущее НАПРАВЛЕНИЕ ['BUY', или 'SELL']
LastOpenBarIndex            =  0                -- Индекс свечи, на которой была открыта последняя позиция (нужен для того, чтобы после закрытия по стопу тут же не открыть еще одну позицию)
lastSignalIndex             = {}
lastCalculatedBar           = 0
isRun                       = true              -- Флаг поддержания работы бесконечного цикла в main
OpenCount                   = 0
curOpenCount                = 0
robotOpenCount              = 0
orderQnty                   = 0
countOrders                 = {}

Settings                    = {}
optimizedSettings_string    = 'STOP_LOSS;TAKE_PROFIT;TRAILING_SIZE;TRAILING_SIZE_STEP;fixedstop;shiftStop;shiftProfit'
isBoolSettings              = {} --признак булевого значения

isTrade                     = false
StopForbidden               = false
manualKillStop              = false
TransactionPrice            = 0
TakeProfitPrice             = 0

TRAILING_ACTIVATED          = false
isPriceMove                 = false
priceMoveVal                = 0
priceMoveMin                = 0
priceMoveMax                = 0
lastStopShiftIndex          = 0
wait_for_open               = false

stop_order_num              = ""    -- номер стоп-заявки на вход в системе, по которому её можно снять
tpPrice                     = 0
slPrice                     = 0
oldStop                     = 0
vtpPrice                    = 0
vslPrice                    = 0
slIndex                     = 0
workedStopPrice             = 0

order_price                 = 0     -- переменная для хранения цены лимитного ордера первой цели
order_type                  = nil   -- переменная для хранения типа лимитного ордера первой цели
order_num                   = 0     -- переменная для хранения номера лимитного ордера первой цели
order_qty                   = 0     -- переменная для хранения баланса лимитного ордера первой цели

iterateSLTP                 = true
isitReopenAfterStop         = false

line_table                  = 0
col_table                   = 0
wasDot                      = false
zeroString                  = ''

SeaGreen                    = RGB(193, 255, 193)	    --	нежно-зеленый
RosyBrown                   = RGB(255, 193, 193)	    --	нежно-розовый
LemonChiffon                = RGB(255,250,205)          --	нежно-желтый

g_previous_time             = os.time() -- помещение в переменную времени сервера в формате HHMMSS

ATR                         = {}
calcAlgoValue               = {}
calcChartResults            = {}
trend                       = {}
dVal                        = {}

IS_CLOSE                    = false

logFile                     = nil
logging                     = true

isOptimization              = true -- доступен ли модуль оптимизации, тестирования

--По умолчанию первый пересет
curPreset = 4
-----------------------------------------------

_G._tostring = tostring
_G.unpack    = rawget(table, "unpack") or _G.unpack
_G.load      = _G.loadfile or _G.load

local format_value = function(x)
    if type(x) == "number" and (math.floor(x) == x) then
        return _VERSION == "Lua 5.3" and _G._tostring(math.tointeger(x) or x) or string.format("%0.16g", x)
    end
    return _G._tostring(x)
end

local table_to_string
table_to_string = function(value, show_number_keys)
    local str = ''
    if show_number_keys == nil then show_number_keys = true end

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
            if value[key] ~= nil then
                if type(key) ~= "table" and type(key) ~= "function" then
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
                entry = table_to_string(entry)
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

_G.tostring = function(x)
    if type(x) == "table" and getmetatable(x) == nil then
      return table_to_string(x)
    else
      return format_value(x)
    end
end

--Проверка состояния торговой сессии по инструменту
-- «1» – основная сессия;
-- «2» – начался промклиринг;
-- «3» – завершился промклиринг;
-- «4» – начался основнои? клиринг;
-- «5» – основнои? клиринг: новая сессия назначена; «
-- 6» – завершился основнои? клиринг;
-- «7» – завершилась вечерняя сессия
local function SessionStatus()

    local status, res, state = pcall(function()

        if not isRun then return false, 'Робот остановлен' end

        local serverTime = os.time(GetServerDateTime())
        if CLASS_CODE == 'TQBR' or CLASS_CODE == 'QJSIM' then
            -- Окончена дневная сессия
            if eveningClearing~=0 and serverTime >= eveningClearing then
               return false, 'Закончен торговый день'
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
        myLog(NAME_OF_STRATEGY..' Error CorrectPosOpeningSize: '..res)
        return false, 'ошибка получения статуса сессии'
    end
    return res, state
end

local function GetTradeSessionStatus()

    local last_state = ''
    local last_connect_state = 0

    return function()

        local can_trade, state, connect_state = false, 'Нет подключения к серверу, торговля невозможна', isConnected()

        if last_connect_state~=connect_state then
            last_connect_state = connect_state
            state = last_connect_state == 1 and 'Есть подключение к серверу, торговля возможна' or 'Нет подключения к серверу, торговля невозможна'
        end
        if connect_state == 1 then
            can_trade, state = SessionStatus()
        end
        if last_state~=state then
            last_state = state
            myLog(NAME_OF_STRATEGY..' '..last_state)
        end

        maintable.t:SetCaption((VIRTUAL_TRADE and ' VIRTUAL_' or 'REAL_')..' TRADE '..NAME_OF_STRATEGY..' '..SEC_CODE..' - '..last_state..' '..tostring(os.date("%c", os.time(GetServerDateTime()))))
        return can_trade, last_state

    end

end
-- Функция первичной инициализации скрипта (ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK в самом начале)
function OnInit()

    -- Получает доступ к свечам графика
    if isConnected() == 0 then
        message("Нет подключения")
        myLog(NAME_OF_STRATEGY.." Нет подключения")
    end

    startTradeTime   = os.time(StrToTime(str_startTradeTime))
    beginTrade       = os.time(StrToTime(str_beginTrade))
    endTradeTime     = os.time(StrToTime(str_endTradeTime))
    dayClearing      = os.time(StrToTime(str_dayClearing))
    endOfDayClearing = os.time(StrToTime(str_endOfDayClearing))
    eveningClearing  = os.time(StrToTime(str_eveningClearing))
    eveningSession   = os.time(StrToTime(str_eveningSession))
    endOfDay         = os.time(StrToTime(str_endOfDay))

    dofile(getScriptPath() .. "\\tableClass.lua")       -- класс интерфейса
    dofile(getScriptPath() .. "\\robotTable.lua")       -- управление интерфейсом робота
    dofile(getScriptPath() .. "\\robotOptimize.lua")    --алгоритм оптимизации

    if iterateAlgorithm == nil then isOptimization = false end

    dofile(getScriptPath().."\\shiftMaAlgo.lua")
    dofile(getScriptPath().."\\thvAlgo.lua")
    dofile(getScriptPath().."\\rangeHVAlgo.lua")
    dofile(getScriptPath().."\\ethlerAlgo.lua")

    --example Пример настроек, если не подключен ни один файл
    if #presets == 0 then
        local newIndex = #presets+1
        presets[newIndex] =
        {
            Name                    = "simpleM3",       -- имя пресета
            NAME_OF_STRATEGY        = 'simple',         -- имя стратегии
            ACCOUNT                 = 'A701XS7',    -- Идентификатор счета для этой настройки
            CLIENT_CODE             = "A701XS7",    -- "Код клиента" для этой настройки
            SEC_CODE                = 'SRU0',           -- код инструмента для торговли
            CLASS_CODE              = 'SPBFUT',         -- класс инструмента
            QTY_LOTS                = 1,                -- количество для торговли
            OFFSET                  = 2,                -- (ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
            SPREAD                  = 10,               -- Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
            ChartId                 = "Sheet11",        -- индентификатор графика, куда выводить метки сделок и данные алгоритма.
            STOP_LOSS               = 25,               -- Размер СТОП-ЛОССА в пунктах (в рублях)
            TAKE_PROFIT             = 130,              -- Размер ТЕЙК-ПРОФИТА в пунктах (в рублях)
            TRAILING_SIZE           = 25,               -- Размер выхода в плюс в пунктах (в рублях), после которого активируется трейлинг
            TRAILING_SIZE_STEP      = 1,                -- Размер шага трейлинга в пунктах (в рублях)
            CLOSE_BAR_SIGNAL        = 1,                -- Сигналы на вход поступают: 1 - по закрытию бара; 0 -- в произволное время
            kATR                    = 0.95,             -- коэффициент ATR для расчета стоп-лосса
            periodATR               = 17,               -- период ATR для расчета стоп-лосса
            SetStop                 = true,             -- выставлять ли стоп заявки
            CloseSLbeforeClearing   = false,            -- снимать ли стоп заявки перед клирингом
            fixedstop               = false,            -- STOPLOSS не рассчитывать по алгоритму, а брать фиксированным из настроек
            isLong                  = true,             -- доступен лонг
            isShort                 = true,             -- доступен шорт
            trackManualDeals        = true,             -- учитывать ручные сделки не из интерфейса робота,
            maxStop                 = 85,               -- максимально допустимый стоп в пунктах
            reopenDealMaxStop       = 75,               -- если сделка переоткрыта после стопа, то максимальный стоп
            stopShiftIndexWait      = 17,               -- если цена не двигается (на величину стопа), то пересчитать стоп после стольких баров
            shiftStop               = true,             -- сдвигать стоп (трейил) на величину STOP_LOSS
            shiftProfit             = true,             -- сдвигать профит (трейил) на величину STOP_LOSS/2
            reopenPosAfterStop      = 7,                -- если выбило по стопу заявке, то попытаться переоткрыть сделку, после стольких баров
            INTERVAL                = INTERVAL_M3,      -- Таймфрейм графика
            autoReoptimize          = false,            -- надо ли включать оптимизацию перед вечерним клирингом
            autoClosePosition       = false,            -- надо ли автоматически закрывать позиции перед вечерним клирингом
            testSizeBars            = 540,              -- размер окна оптимизации стратегии
            calculateAlgo           = simpleAlgo,       -- имя функции расчета алгоритма
            iterateAlgo             = iterateSimpleAlgo,-- имя функции подготовки таблицы набора параметров для оптимизации
            initAlgo                = initSimpleAlgo,   -- имя функции для обнуления таблиц алгоритма перед очередным шагом оптимизации
			settingsAlgo =
            {
                shift = 16 -- перменная алгоритма
            }
        }
        --Куда поместить кнопку выбора настройки
        presets[newIndex].interface_line = 0
        presets[newIndex].interface_col  = 0

        --Какие значения настроек надо вывести в интерфейс, в указанные места
        --Описание полей интерфейса
        presets[newIndex].fields = {}
        presets[newIndex].fields['shift']       = {caption = 'shift' , caption_line = 3, caption_col = 1 , val_line = 3, val_col = 2, base_color = nil}

        -- возможность редактирования полей настройки
        presets[newIndex].edit_fields = {}
        presets[newIndex].edit_fields['shift']  = true
    end

    CheckTradeSession = GetTradeSessionStatus()

    initPreset(true, true)
    CheckTradeSession()
end

-- Функция ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK при остановке скрипта
function OnStop()
    isRun = false
    myLog(NAME_OF_STRATEGY.." Script Stoped")
    if not IS_CLOSE then
        --kill main table
        maintable:closeTable()
    end
    if logFile~=nil then logFile:close() end
end

-- Функция ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK при при закрытии программы
function OnClose()
    isRun = false
    IS_CLOSE = true
    myLog(NAME_OF_STRATEGY.." Script OnClose")
    --kill main table
    maintable:closeTable()
end

local function FillMainTableWithPreset(isInitialization)

	if isInitialization then
		maintable:createOwnTable((VIRTUAL_TRADE and ' VIRTUAL_' or 'REAL_')..' TRADE '..NAME_OF_STRATEGY..' Robot '..SEC_CODE)
		maintable:showTable()
        maintable:fillTable()
        maintable.t:SetPosition(980, 120, 730, 160)
        myLog('isInitialization '..tostring(isInitialization))

        if #presets > 0 then
            for i,v in ipairs(presets) do
                maintable.t:SetValue(v.interface_line, v.interface_col, "Set "..presets[i].Name, 0)
                maintable.t:SetColor(v.interface_line, v.interface_col, RGB(200,200,200), RGB(0,0,0), RGB(168,168,164), RGB(0,0,0))
                addedPresets[tonumber(tostring(v.interface_line)..tostring(v.interface_col))] = i
            end
        end
	end

    SetState(ROBOT_STATE)
    SetAllProfit(0)
    SetQty(QTY_LOTS)
    maintable:SetValue('INTERVAL', tostring(INTERVAL), INTERVAL)
    maintable:SetValue('testSizeBars', tostring(testSizeBars), testSizeBars)
    maintable:SetValue('STOP_LOSS', tostring(STOP_LOSS), STOP_LOSS)
    maintable:SetValue('TAKE_PROFIT', tostring(TAKE_PROFIT), TAKE_PROFIT)
    maintable:SetValue('ChartId', tostring(ChartId), 0)

    if SetStop then
        local field = maintable:GetField('KILL_ALL_SL')
        if field~=nil then
            maintable.t:SetValue(field.caption_line, field.caption_col, field.caption, 0)
            maintable.t:SetColor(field.caption_line, field.caption_col, field.base_color, RGB(0,0,0), field.base_color, RGB(0,0,0))
        end
        field = maintable:GetField('SET_SL_TP')
        if field~=nil then
            maintable.t:SetValue(field.caption_line, field.caption_col, field.caption, 0)
            maintable.t:SetColor(field.caption_line, field.caption_col, field.base_color, RGB(0,0,0), field.base_color, RGB(0,0,0))
        end
    else
        maintable.t:SetValue('KILL_ALL_SL', '', 0)
        maintable.t:SetColor('KILL_ALL_SL', RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))
        maintable.t:SetValue('SET_SL_TP', '', 0)
        maintable.t:SetColor('SET_SL_TP', RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))
    end

end

--Получение параметров торгуемого инструмента
local function GetSECProp()


    if getSecurityInfo(CLASS_CODE, SEC_CODE) == nil then
        message("Не удалось получить данные по инструменту: "..SEC_CODE.."/"..tostring(CLASS_CODE))
        myLog(NAME_OF_STRATEGY.." Не удалось получить данные по инструменту: "..SEC_CODE.."/"..tostring(CLASS_CODE))
        return
    end

    local last_price = getParamEx(CLASS_CODE,SEC_CODE,"last").param_value

    --Если по инструменты нет торгов, то прекращаем выполнение скрипта.
    if last_price == nil then
        myLog(NAME_OF_STRATEGY..' По инструменту '..SEC_CODE..' на данный момент не проводятся торги!!!')
        message(NAME_OF_STRATEGY..' По инструменту '..SEC_CODE..' на данный момент не проводятся торги!!!',2)
        return
    end

    -- Возвращает таблицу-описание торгового счета по его названию
    -- или nil, если торговый счет не обнаружен

    local function getTradeAccount(class_code, account)
        -- Функция возвращает таблицу с описанием торгового счета для запрашиваемого кода класса
        for i=0,getNumberOf ("trade_accounts")-1 do
            local trade_account=getItem("trade_accounts",i)
            myLog(NAME_OF_STRATEGY..' Торговый счет: '..tostring(trade_account.trdaccid)..', допустимые class_codes: '..tostring(trade_account.class_codes))
            if string.find(trade_account.class_codes,class_code,1,1) and string.find(trade_account.trdaccid,account,1,1) then return trade_account end
        end
        return nil
    end


    SEC_PRICE_STEP  = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value or 0)
    SCALE           = tonumber(getSecurityInfo(CLASS_CODE, SEC_CODE).scale  or 0)
    STEPPRICE       = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "STEPPRICE").param_value or 0)
    LOTSIZE         = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "LOTSIZE").param_value or 0)

    local STARTTIME     = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "STARTTIME").param_value or 0)
    local ENDTIME       = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "ENDTIME").param_value or 0)
    local EVNSTARTTIME  = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "EVNSTARTTIME").param_value or 0)
    local EVNENDTIME    = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "EVNENDTIME").param_value or 0)

    local function num_to_strTime(num)
        local strTime = tostring(num)
        if strTime:len()~=6 then return nil end
        return strTime:sub(1,2)..':'..strTime:sub(3,4)..':'..strTime:sub(5,6)
    end

    if STARTTIME~=0 then
        strTime = num_to_strTime(STARTTIME)
        myLog(NAME_OF_STRATEGY..' STARTTIME '..tostring(strTime))
        if strTime~=nil then
            startTradeTime   = os.time(StrToTime(strTime))
        end
    end
    if ENDTIME~=0 then
        strTime = num_to_strTime(ENDTIME)
        myLog(NAME_OF_STRATEGY..' ENDTIME '..tostring(strTime))
        if strTime~=nil then
            eveningClearing   = os.time(StrToTime(strTime))
        end
    end
    if EVNSTARTTIME~=0 then
        strTime = num_to_strTime(EVNSTARTTIME)
        myLog(NAME_OF_STRATEGY..' EVNSTARTTIME '..tostring(strTime))
        if strTime~=nil then
            eveningSession   = os.time(StrToTime(strTime))
        end
    end
    if EVNENDTIME~=0 then
        strTime = num_to_strTime(EVNENDTIME)
        myLog(NAME_OF_STRATEGY..' EVNENDTIME '..tostring(strTime))
        if strTime~=nil then
            endOfDay   = os.time(StrToTime(strTime))
        end
    end

    leverage = 1
    if CLASS_CODE ~= 'QJSIM' and CLASS_CODE ~= 'TQBR' then
        if SEC_PRICE_STEP == 0 or SEC_PRICE_STEP == nil then
            priceKoeff = 1
            myLog(NAME_OF_STRATEGY.."Для инструмента: " .. SEC_CODE .. " не определен шаг цены: " .. tostring(SEC_PRICE_STEP))
            message("Для инструмента: " .. SEC_CODE .. " не определен шаг цены: " .. tostring(SEC_PRICE_STEP))
        elseif STEPPRICE == 0 or STEPPRICE == nil then
            priceKoeff = 1
            myLog(NAME_OF_STRATEGY.."Для инструмента: " .. SEC_CODE .. " не определена стоимость шага цены: " .. tostring(STEPPRICE))
            message("Для инструмента: " .. SEC_CODE .. " не определена стоимость шага цены: " .. tostring(STEPPRICE))
        else
            priceKoeff = SEC_PRICE_STEP/STEPPRICE
        end

        local trdaccid=getTradeAccount(CLASS_CODE, ACCOUNT)

        -- Проверяем соотношение ACCOUNT и CLASSCODE
        if trdaccid == nil then
            myLog(NAME_OF_STRATEGY.."Торговый счет " .. ACCOUNT .. " не позволяет торговать инструментом " .. SEC_CODE .. "/" .. CLASS_CODE)
            message("Торговый счет " .. ACCOUNT .. " не позволяет торговать инструментом " .. SEC_CODE .. "/" .. CLASS_CODE)
        else
            FIRM_ID = trdaccid.firmid
        end
    else
        priceKoeff = 1/LOTSIZE
    end

end

function initPreset(needScanOpenCountSLTP, isInitialization)

    notReadOptimized        = presets[curPreset].notReadOptimized or false

    --Установка глобальных переменных из пресета
    NAME_OF_STRATEGY             = presets[curPreset].NAME_OF_STRATEGY
    ACCOUNT                      = presets[curPreset].ACCOUNT ~= nil and presets[curPreset].ACCOUNT or (presets[curPreset].ACCOUNT == nil and default_ACCOUNT)
    CLIENT_CODE                  = presets[curPreset].CLIENT_CODE ~= nil and presets[curPreset].CLIENT_CODE or (presets[curPreset].CLIENT_CODE == nil and default_CLIENT_CODE)
    SEC_CODE                     = presets[curPreset].SEC_CODE
    CLASS_CODE                   = presets[curPreset].CLASS_CODE
    LIMIT_KIND                   = presets[curPreset].LIMIT_KIND ~= nil and presets[curPreset].LIMIT_KIND or (presets[curPreset].LIMIT_KIND == nil and default_LIMIT_KIND)
    ROBOT_POSTFIX                = presets[curPreset].ROBOT_POSTFIX ~= nil and presets[curPreset].ROBOT_POSTFIX or (presets[curPreset].ROBOT_POSTFIX == nil and default_ROBOT_POSTFIX)
    QTY_LOTS                     = presets[curPreset].QTY_LOTS ~= nil and presets[curPreset].QTY_LOTS or (presets[curPreset].QTY_LOTS == nil and default_QTY_LOTS)
    INTERVAL                     = presets[curPreset].INTERVAL ~= nil and presets[curPreset].INTERVAL or (presets[curPreset].INTERVAL == nil and default_INTERVAL)
    SetStop                      = presets[curPreset].SetStop ~= nil and presets[curPreset].SetStop or (presets[curPreset].SetStop == nil and default_SetStop)
    CloseSLbeforeClearing        = presets[curPreset].CloseSLbeforeClearing ~= nil and presets[curPreset].CloseSLbeforeClearing or (presets[curPreset].CloseSLbeforeClearing == nil and default_CloseSLbeforeClearing)
    minToCloseSLbeforeClearing   = presets[curPreset].minToCloseSLbeforeClearing ~= nil and presets[curPreset].minToCloseSLbeforeClearing or (presets[curPreset].minToCloseSLbeforeClearing == nil and default_minToCloseSLbeforeClearing)
    isLong                       = presets[curPreset].isLong ~= nil and presets[curPreset].isLong or (presets[curPreset].isLong == nil and default_isLong)
    isShort                      = presets[curPreset].isShort ~= nil and presets[curPreset].isShort or (presets[curPreset].isShort == nil and default_isShort)
    trackManualDeals             = presets[curPreset].trackManualDeals ~= nil and presets[curPreset].trackManualDeals or (presets[curPreset].trackManualDeals == nil and default_trackManualDeals)
    CLOSE_BAR_SIGNAL             = presets[curPreset].CLOSE_BAR_SIGNAL ~= nil and presets[curPreset].CLOSE_BAR_SIGNAL or (presets[curPreset].CLOSE_BAR_SIGNAL == nil and default_CLOSE_BAR_SIGNAL)
    maxStop                      = presets[curPreset].maxStop ~= nil and presets[curPreset].maxStop or (presets[curPreset].maxStop == nil and default_maxStop)
    reopenDealMaxStop            = presets[curPreset].reopenDealMaxStop ~= nil and presets[curPreset].reopenDealMaxStop or (presets[curPreset].reopenDealMaxStop == nil and default_reopenDealMaxStop)
    stopShiftIndexWait           = presets[curPreset].stopShiftIndexWait ~= nil and presets[curPreset].stopShiftIndexWait or (presets[curPreset].stopShiftIndexWait == nil and default_stopShiftIndexWait)
    fixedstop                    = presets[curPreset].fixedstop ~= nil and presets[curPreset].fixedstop or (presets[curPreset].fixedstop == nil and default_fixedstop)
    shiftStop                    = presets[curPreset].shiftStop ~= nil and presets[curPreset].shiftStop or (presets[curPreset].shiftStop == nil and default_shiftStop)
    shiftProfit                  = presets[curPreset].shiftProfit ~= nil and presets[curPreset].shiftProfit or (presets[curPreset].shiftProfit == nil and default_shiftProfit)
    reopenPosAfterStop           = presets[curPreset].reopenPosAfterStop ~= nil and presets[curPreset].reopenPosAfterStop or (presets[curPreset].reopenPosAfterStop == nil and default_reopenPosAfterStop)
    ChartId                      = presets[curPreset].ChartId ~= nil and presets[curPreset].ChartId or (presets[curPreset].ChartId == nil and default_ChartId)
    testSizeBars                 = presets[curPreset].testSizeBars ~= nil and presets[curPreset].testSizeBars or (presets[curPreset].testSizeBars == nil and default_testSizeBars)
    autoReoptimize               = presets[curPreset].autoReoptimize ~= nil and presets[curPreset].autoReoptimize or (presets[curPreset].autoReoptimize == nil and default_autoReoptimize)
    autoClosePosition            = presets[curPreset].autoClosePosition ~= nil and presets[curPreset].autoClosePosition or (presets[curPreset].autoClosePosition == nil and default_autoClosePosition)
    STOP_LOSS                    = presets[curPreset].STOP_LOSS ~= nil and presets[curPreset].STOP_LOSS or (presets[curPreset].STOP_LOSS == nil and default_STOP_LOSS)
    TAKE_PROFIT                  = presets[curPreset].TAKE_PROFIT ~= nil and presets[curPreset].TAKE_PROFIT or (presets[curPreset].TAKE_PROFIT == nil and default_TAKE_PROFIT)
    OFFSET                       = presets[curPreset].OFFSET ~= nil and presets[curPreset].OFFSET or (presets[curPreset].OFFSET == nil and default_OFFSET)
    SPREAD                       = presets[curPreset].SPREAD ~= nil and presets[curPreset].SPREAD or (presets[curPreset].SPREAD == nil and default_SPREAD)
    TRAILING_SIZE                = presets[curPreset].TRAILING_SIZE ~= nil and presets[curPreset].TRAILING_SIZE or (presets[curPreset].TRAILING_SIZE == nil and default_TRAILING_SIZE)
    TRAILING_SIZE_STEP           = presets[curPreset].TRAILING_SIZE_STEP ~= nil and presets[curPreset].TRAILING_SIZE_STEP or (presets[curPreset].TRAILING_SIZE_STEP == nil and default_TRAILING_SIZE_STEP)
    kATR                         = presets[curPreset].kATR ~= nil and presets[curPreset].kATR or (presets[curPreset].kATR == nil and default_kATR)
    SL_ADD_STEPS                 = presets[curPreset].SL_ADD_STEPS ~= nil and presets[curPreset].SL_ADD_STEPS or (presets[curPreset].SL_ADD_STEPS == nil and default_SL_ADD_STEPS)
    periodATR                    = presets[curPreset].periodATR ~= nil and presets[curPreset].periodATR or (presets[curPreset].periodATR == nil and default_periodATR)

    local newName = getScriptPath ().."\\robot"..NAME_OF_STRATEGY.."_"..SEC_CODE.."Log.txt"
    if logging and newName~= FILE_LOG_NAME then
        FILE_LOG_NAME = getScriptPath().."\\robot"..NAME_OF_STRATEGY.."_"..SEC_CODE.."Log.txt" -- ИМЯ ЛОГ-ФАЙЛА
        if logFile~=nil then logFile:close() end
        logFile = io.open(FILE_LOG_NAME, "w") -- открывает файл
        PARAMS_FILE_NAME = getScriptPath().."\\robot"..NAME_OF_STRATEGY.."_"..SEC_CODE.."_int"..tostring(INTERVAL).."_params.txt" -- ИМЯ ФАЙЛА Оптимальных параметров
    end

    myLog(NAME_OF_STRATEGY.." shiftStop: "..tostring(shiftStop)..', curPreset '..tostring(curPreset)..', presets[curPreset].shiftStop '..tostring(presets[curPreset].shiftStop))

    Settings = {}
    myLog(NAME_OF_STRATEGY..' Применение установок пресета '..presets[curPreset].Name)
    for k,v in pairs(presets[curPreset].settingsAlgo) do
        Settings[k] = v
        myLog('Установка Settings.'..k..' = '..tostring(v))
    end
    myLog(NAME_OF_STRATEGY..'-----------')

    startTradeTime   = os.time(StrToTime(str_startTradeTime))
    endTradeTime     = os.time(StrToTime(str_endTradeTime))
    dayClearing      = os.time(StrToTime(str_dayClearing))
    endOfDayClearing = os.time(StrToTime(str_endOfDayClearing))
    eveningClearing  = os.time(StrToTime(str_eveningClearing))
    eveningSession   = os.time(StrToTime(str_eveningSession))
    endOfDay         = os.time(StrToTime(str_endOfDay))

	if isInitialization then
		--create and show table
		maintable= MainTable()
		maintable:Init()
	end

    FillMainTableWithPreset(isInitialization)

    -- Получает параметры инструмента
    GetSECProp()

    -- Тип отображения баланса в таблице "Таблица лимитов по денежным средствам" (1 - в лотах, 2 - с учетом количества в лоте)
    -- Например, при покупке 1 лота USDRUB одни брокеры в поле "Баланс" транслируют 1, другие 1000
    -- Обычно, для срочного рынка = 1, для фондового рынка = 2
    BALANCE_TYPE = 1

    --0 - Т0, 1 - Т1, 2 - Т2
    --LIMIT_KIND = 0

    if CLASS_CODE == 'QJSIM' or CLASS_CODE == 'TQBR' then
        ROBOT_POSTFIX = '/'..ROBOT_POSTFIX --идентификатор робота в комментариях к заявкам и сделкам. Для поиска
        BALANCE_TYPE = 2
        --LIMIT_KIND = 2
        if LIMIT_KIND == 0 then message('Проверьте установки лимита для получения баланса. Сейчас он установлен Т0, для акций должно быть Т2!!!', 2) end
    end
    if CLASS_CODE == 'CETC' then
        BALANCE_TYPE = 2
    end
    ROBOT_CLIENT_CODE = getROBOT_CLIENT_CODE(DEAL_COUNTER) --Строка комментаия в заявках, сделках

    if needScanOpenCountSLTP then
        local Error = ''
        DS,Error = CreateDataSource(CLASS_CODE, SEC_CODE, INTERVAL)
        -- Проверка
        if DS == nil then
            message(NAME_OF_STRATEGY..' robot:ОШИБКА получения доступа к свечам! '..Error)
            return
        end
        DS:SetEmptyCallback()
    end

    --Чтение оптимальных параметров из файла
    if isOptimization and not notReadOptimized then
        myLog('Чтение оптимальных параметров из файла '..PARAMS_FILE_NAME)
        readOptimizedParams()
        myLog(NAME_OF_STRATEGY..'----- Чтение оптимальных установок пресета '..presets[curPreset].Name)
        for k,v in pairs(Settings) do
            myLog('Установка Settings.'..k..' = '..tostring(v))
        end
        myLog(NAME_OF_STRATEGY..'-----------')
    end

    --Читаем глобальные переменные, записываем их в таблицу
    --Записываем переменные имеющие тип булево
    isBoolSettings = {} --признак булевого значения
    globalSettings = {}
    for k,v in pairs(presets[curPreset]) do
        if type(v) ~= 'function' then
            globalSettings[k] = assert(loadstring('return '..k))()
            if type(v) == 'boolean' then isBoolSettings[k] = true end
            --myLog('set global '..k..' '..tostring(globalSettings[k]))
        end
    end

    --Читаем переменные алгоритма, формируем строку сохранения оптимальных параметров
    --Записываем переменные имеющие тип булево
    local algo_fields   = {}
    local taken_fields  = {}
    local duplicate_error
    for par, field in pairs(presets[curPreset].fields) do
        if par~='' then
            --Если в настройках алгоритма есть переопределенная глобальная переменная,
            --то записываем ее заначение в глобальную пееменную
            if Settings[par]~=nil and globalSettings[par]~=nil then
                globalSettings[par] = Settings[par]
                assert(loadstring(par..'= '..tostring(Settings[par])))()
            end
            --myLog(par..', global: '..tostring(globalSettings[par])..', set: '..tostring(Settings[par]))
            --Если в настройках алгоритма есть глобальная переменная, а ее значение не определено,
            --то записываем ее заначение в установки алгоритма
            if Settings[par]==nil and globalSettings[par]~=nil then
                Settings[par] = globalSettings[par]
            end
            if type(Settings[par]) == 'boolean' then isBoolSettings[par] = true end
            if taken_fields[tostring(field.val_line)..'_'..tostring(field.val_col)] then
                duplicate_error = true
                local mes = 'Ошибка расположения параметра '..par..'\nВ строке '..tostring(field.val_line)..', колонке '..tostring(field.val_col)..' уже расположен параметр '..tostring(taken_fields[tostring(field.val_line)..'_'..tostring(field.val_col)])
                myLog(mes)
            end
            algo_fields[#algo_fields + 1] = {key = par, line = field.val_line, col = field.val_col}
            taken_fields[tostring(field.val_line)..'_'..tostring(field.val_col)] = par
        end
    end
    for k,v in pairs(Settings) do
        myLog('Получен Settings.'..k..' = '..tostring(v))
    end
    myLog(NAME_OF_STRATEGY..'-----------')

    myLog(NAME_OF_STRATEGY..' algo_fields', algo_fields)

    if not duplicate_error then
        table.sort(algo_fields, function(a,b)
            return (a.line == b.line and a.col < b.col) or a.line < b.line
        end)
    end

    presets[curPreset].saveSettings_string = ''
    for i=1,#algo_fields do
        presets[curPreset].saveSettings_string = (#presets[curPreset].saveSettings_string==0 and '' or presets[curPreset].saveSettings_string..';')..algo_fields[i].key
    end
    --myLog('saveSettings_string '..tostring(presets[curPreset].saveSettings_string))

    calculateAlgo =     presets[curPreset].calculateAlgo
    iterateAlgo =       presets[curPreset].iterateAlgo
    initAlgo =          presets[curPreset].initAlgo

    -- Если нет процедуры алгоритма, ставим по умолчанию встроенный алгоритм
    if calculateAlgo==nil then
        calculateAlgo = simpleAlgo
    end

    --Если сменился инструмент, то надо перезапустить скрипт
    if needScanOpenCountSLTP then
        LastOpenBarIndex = DS:Size()
        TransactionPrice = DS:C(DS:Size())
        vallProfit = 0
        slIndex = 0
        lastStopShiftIndex = 0
        workedStopPrice = 0
        Initialization()
    end

    local last_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)
    SetLastPrice(last_price)
    SetState(ROBOT_STATE)
    setTableAlgoParams(Settings, presets[curPreset])

    myLog(NAME_OF_STRATEGY.." NEW "..ROBOT_POSTFIX.." SET: "..tostring(presets[curPreset].Name))
    myLog(NAME_OF_STRATEGY.." CLIENT_CODE: "..tostring(CLIENT_CODE))
    myLog(NAME_OF_STRATEGY.." ACCOUNT: "..tostring(ACCOUNT))
    myLog(NAME_OF_STRATEGY.." LIMIT_KIND: "..tostring(LIMIT_KIND))
    myLog(NAME_OF_STRATEGY.." BALANCE_TYPE: "..tostring(BALANCE_TYPE))
    myLog(NAME_OF_STRATEGY.." CLASS_CODE: "..tostring(CLASS_CODE))
    myLog(NAME_OF_STRATEGY.." SEC: "..tostring(SEC_CODE))
    myLog(NAME_OF_STRATEGY.." PRICE STEP: "..tostring(SEC_PRICE_STEP))
    myLog(NAME_OF_STRATEGY.." SCALE: "..tostring(SCALE))
    myLog(NAME_OF_STRATEGY.." STEP PRICE: "..tostring(STEPPRICE))
    myLog(NAME_OF_STRATEGY.." LOTSIZE: "..tostring(LOTSIZE))
    myLog(NAME_OF_STRATEGY.." leverage: "..tostring(leverage))
    myLog(NAME_OF_STRATEGY.." priceKoeff: "..tostring(priceKoeff))
    myLog(NAME_OF_STRATEGY.." QTY_LOTS: "..tostring(QTY_LOTS))
    myLog(NAME_OF_STRATEGY.." CLOSE_BAR_SIGNAL: "..tostring(CLOSE_BAR_SIGNAL))
    myLog(NAME_OF_STRATEGY.." SetStop: "..tostring(SetStop))
    myLog(NAME_OF_STRATEGY.." CloseSLbeforeClearing: "..tostring(CloseSLbeforeClearing))
    myLog(NAME_OF_STRATEGY.." fixedstop: "..tostring(fixedstop))
    myLog(NAME_OF_STRATEGY.." isLong: "..tostring(isLong))
    myLog(NAME_OF_STRATEGY.." isShort: "..tostring(isShort))
    myLog(NAME_OF_STRATEGY.." reopenPosAfterStop: "..tostring(reopenPosAfterStop))
    myLog(NAME_OF_STRATEGY.." reopenDealMaxStop: "..tostring(reopenDealMaxStop))
    myLog(NAME_OF_STRATEGY.." maxStop: "..tostring(maxStop))
    myLog(NAME_OF_STRATEGY.." stopShiftIndexWait: "..tostring(stopShiftIndexWait))
    myLog(NAME_OF_STRATEGY.." trackManualDeals: "..tostring(trackManualDeals))
    myLog(NAME_OF_STRATEGY.." OFFSET: "..tostring(OFFSET))
    myLog(NAME_OF_STRATEGY.." SPREAD: "..tostring(SPREAD))
    myLog(NAME_OF_STRATEGY.." shiftStop: "..tostring(shiftStop))
    myLog(NAME_OF_STRATEGY.." shiftProfit: "..tostring(shiftProfit))
    myLog(NAME_OF_STRATEGY.." testSizeBars: "..tostring(testSizeBars))
    myLog(NAME_OF_STRATEGY.." autoReoptimize: "..tostring(autoReoptimize))
    myLog(NAME_OF_STRATEGY.." autoClosePosition: "..tostring(autoClosePosition))
    myLog(NAME_OF_STRATEGY.." STOP_LOSS: "..tostring(STOP_LOSS))
    myLog(NAME_OF_STRATEGY.." TAKE_PROFIT: "..tostring(TAKE_PROFIT))
    myLog(NAME_OF_STRATEGY.." TRAILING_SIZE: "..tostring(TRAILING_SIZE))
    myLog(NAME_OF_STRATEGY.." TRAILING_SIZE_STEP: "..tostring(TRAILING_SIZE_STEP))
    myLog(NAME_OF_STRATEGY.." SL_ADD_STEPS: "..tostring(SL_ADD_STEPS))
    myLog(NAME_OF_STRATEGY.." kATR: "..tostring(kATR))
    myLog(NAME_OF_STRATEGY.." periodATR: "..tostring(periodATR))

    myLog(NAME_OF_STRATEGY.." serverTime: "..tostring(os.time(GetServerDateTime()))..'--'..toYYYYMMDDHHMMSS(GetServerDateTime()))
    myLog(NAME_OF_STRATEGY.." startTradeTime: "..tostring(startTradeTime)..'--'..toYYYYMMDDHHMMSS(StrToTime(str_startTradeTime)))
    myLog(NAME_OF_STRATEGY.." beginTrade: "..tostring(beginTrade)..'--'..toYYYYMMDDHHMMSS(StrToTime(str_beginTrade)))
    myLog(NAME_OF_STRATEGY.." dayClearing: "..tostring(dayClearing))
    myLog(NAME_OF_STRATEGY.." endOfDayClearing: "..tostring(endOfDayClearing))
    myLog(NAME_OF_STRATEGY.." eveningClearing: "..tostring(eveningClearing))
    myLog(NAME_OF_STRATEGY.." eveningSession: "..tostring(eveningSession))
    myLog(NAME_OF_STRATEGY.." endOfDay: "..tostring(endOfDay))
    myLog(NAME_OF_STRATEGY.." ==================================================")
    myLog(NAME_OF_STRATEGY.." Initialization finished")

end

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Управление таблицей робота
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--Вывод переменных алгоритма в таблицу
function setTableAlgoParams(settingsAlgo, preset)
    if not isRun or maintable==nil or maintable.t==nil then return end
	maintable:setTableAlgoParams(settingsAlgo, preset)
end

--Чтение значений из таблицы в переменные алгоритма
function readTableAlgoParams(preset)
    if not isRun or maintable==nil or maintable.t==nil then return end
	maintable:readTableAlgoParams(preset)
end

--Инициализация скритпта при запуске или при смене инструмента
function Initialization()
    myLog(NAME_OF_STRATEGY..' Первоначальный запуск скрипта '..ROBOT_CLIENT_CODE)
    OpenCount = GetTotalnet()
    curOpenCount = OpenCount
    last_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)
    priceMoveMin = last_price
    priceMoveMax = last_price
    TransactionPrice = last_price or DS:C(index)
    TRAILING_ACTIVATED = false
    if trackManualDeals and OpenCount~=0 and not isStopOrderSet(true) then
        myLog(NAME_OF_STRATEGY..' Установка стоп-лосса после запуска скрипта')
        local Type = OpenCount > 0 and "BUY" or "SELL"
        local tp_Price, sl_Price, price = getSLTP_Price(TransactionPrice, Type, OpenCount, fixedstop)
        local AtPrice = {tp_Price = tp_Price, sl_Price = sl_Price, price = price, offset = OFFSET, spread = SPREAD}
        local result = SL_TP(AtPrice, Type, OpenCount)
    end
    ROBOT_STATE = BASE_ROBOT_STATE
end

--Установка в таблицу информации по последней цены
function SetLastPrice(last_price)
    if not isRun or maintable==nil or maintable.t==nil then return end
    local status,res = pcall(function()
        local lp = maintable:GetValue('Price') or last_price
        local field = maintable:GetField('Price')
        if field~=nil then
            if lp < last_price then
                maintable.t:Highlight(field.val_line, field.val_col, SeaGreen, QTABLE_DEFAULT_COLOR,1000)		-- подсветка мягкий, зеленый
            elseif lp > last_price then
                maintable.t:Highlight(field.val_line, field.val_col, RosyBrown, QTABLE_DEFAULT_COLOR,1000)		-- подсветка мягкий розовый
            --elseif lp == last_price then
            --    maintable.t:Highlight(field.val_line, field.val_col, LemonChiffon, QTABLE_DEFAULT_COLOR,1000)	-- подсветка мягкий желтый
            end
        end
        maintable:SetValue('Price', tostring(last_price), last_price)
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error SetLastPrice: '..res) end
end

--Установка в таблицу информации по позиции
function SetPos(pos, avgPrice)

    if not isRun or maintable==nil or maintable.t==nil then return end
    pos         = pos or 0
    avgPrice    = avgPrice or 0

    if pos == 0 then
        maintable:SetValue('Pos', '', 0)
        maintable:SetValue('Profit', '', 0)
    else
        maintable:SetValue('Pos', tostring(pos)..'/'..tostring(avgPrice), avgPrice)
    end

    if pos == 0 then
        maintable:SetColor('Pos', RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))
    elseif pos>0 then
        maintable:SetColor('Pos', RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
    else
        maintable:SetColor('Pos', RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
    end

end

--Установка в таблицу значений стоп-лосса и тейк-профита
function SetSL_TP(sPrice, tPrice)
    if not isRun or maintable==nil or maintable.t==nil then return end
    maintable:SetValue('SL', sPrice==0 and '' or tostring(sPrice), sPrice)
    maintable:SetValue('TP', tPrice==0 and '' or tostring(tPrice), tPrice)
    slPrice = sPrice
    tpPrice = tPrice
    oldStop = sPrice
end

--Установка в таблицу информации по накопленной прибыли
function SetAllProfit(allProfit)
    if not isRun or maintable==nil or maintable.t==nil then return end
    if VIRTUAL_TRADE then
        maintable:SetValue('ALL_PROFIT', 'all profit: '..tostring(allProfit), allProfit)
    end
end

--Установка в таблицу информации по прибыли по последней сделке
function SetDealProfit(dealProfit)
    if not isRun or maintable==nil or maintable.t==nil then return end
    maintable:SetValue('Profit', dealProfit==0 and '' or tostring(dealProfit), dealProfit)
end

--Установка в таблицу информации по количеству для торговли
function SetQty(qty)
    if not isRun or maintable==nil or maintable.t==nil then return end
    maintable:SetValue('QTY', virtCaption..'qty: '..tostring(qty), qty)
end

--Установка в таблицу информации по состоянию работы робота
function SetState(state, state_val)
    if not isRun or maintable==nil or maintable.t==nil then return end
    maintable:SetValue('State', state, state_val or 0)
end

--Установка в таблицу расчетных значений алгоритма
function SetAlgo(currentTradeDirection, roundAlgoVal)
    if not isRun or maintable==nil or maintable.t==nil then return end
	if currentTradeDirection == nil or roundAlgoVal == nil then
		maintable:SetValue('Algo', '', 0)
		maintable:SetColor('Algo', RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))
    elseif currentTradeDirection == -1 then
		maintable:SetValue('Algo', 'SELL/'..tostring(roundAlgoVal), roundAlgoVal)
        maintable:SetColor('Algo', RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
    elseif currentTradeDirection == 1 then
		--myLog('currentTradeDirection '..tostring(currentTradeDirection))
		maintable:SetValue('Algo', 'BUY/'..tostring(roundAlgoVal), roundAlgoVal)
        maintable:SetColor('Algo', RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
    else
		maintable:SetValue('Algo', '.../'..tostring(roundAlgoVal), roundAlgoVal)
        maintable:SetColor('Algo', RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))
    end
end

--Установки при старте/остановке торговли
function SetStartStop()

    if not isRun or maintable==nil or maintable.t==nil then return end
    if isTrade then
        ROBOT_STATE       = 'ПОИСК СДЕЛКИ'
        BASE_ROBOT_STATE  = 'ПОИСК СДЕЛКИ'
        SetState(ROBOT_STATE)
        maintable:SetValue('START', 'STOP', 0)
        maintable:SetColor('START', RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
    else
        ROBOT_STATE       ='ОСТАНОВЛЕН'
        BASE_ROBOT_STATE  ='ОСТАНОВЛЕН'
        SetState(ROBOT_STATE)
        maintable:SetValue('START', 'START', 0)
        maintable:SetColor('START', RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
    end
end

function is_it_Preset(interface_line, interface_col)
	return addedPresets[tonumber(tostring(interface_line)..tostring(interface_col))]~=nil
end

--Установка параметров алгоритма
local function setParameters()

    if not isTrade then
        readTableAlgoParams(presets[curPreset])
		INTERVAL = maintable:GetValue('INTERVAL')
    end

    if isOptimization then
        testSizeBars        = maintable:GetValue('testSizeBars')
    end

    ChartId             = maintable:GetValue('ChartId', 'image')
    QTY_LOTS            = math.ceil(maintable:GetValue('QTY') or 0)
    STOP_LOSS           = math.ceil(maintable:GetValue('STOP_LOSS') or 0)
    TAKE_PROFIT         = math.ceil(maintable:GetValue('TAKE_PROFIT') or 0)

    --myLog(NAME_OF_STRATEGY..' Установка параметров '..' INTERVAL '..tostring(INTERVAL)..' STOP_LOSS '..tostring(STOP_LOSS)..' TAKE_PROFIT '..tostring(TAKE_PROFIT)..' shiftStop '..tostring(shiftStop)..' shiftProfit '..tostring(shiftProfit))

end

--Очистка значений в таблице при закрытии позиции
local function clearTableOnClosePos()
    priceMoveMin = 0
    priceMoveMax = 0
    TRAILING_ACTIVATED = false
    SetPos(0, 0)
    SetSL_TP(0, 0)
end

--Реакции на действия с таблицой
function MainTable_Comands(t_id, msg, par1, par2)

	--message('mn '..tostring(msg)..' par1 '..tostring(par1)..' par2 '..tostring(par2))

	if msg == QTABLE_CHAR then --ChartID
		if tostring(par2) == "86" or tostring(par2) == "204" then --Shift+V
			if not VIRTUAL_TRADE and (OpenCount~=0 or isStopOrderSet()) then
				message(NAME_OF_STRATEGY..' Для включения виртуальной торговли необходимо закрыть позицию и все стоп-заявки')
				myLog(NAME_OF_STRATEGY..' Для включения виртуальной торговли необходимо закрыть позицию и все стоп-заявки')
				return
			end

			SetPos(0, 0)
			SetSL_TP(0, 0)

			OpenCount = 0
			curOpenCount = 0

			VIRTUAL_TRADE = not VIRTUAL_TRADE
			virtCaption = (VIRTUAL_TRADE and 'virtual ' or 'real ')
            SetQty(maintable:GetValue('QTY'))
			myLog(NAME_OF_STRATEGY..' Изменение режима виртуальной торговли. Перезапускаем скрипт')
			ROBOT_STATE = 'FIRSTSTART'
		elseif tostring(par2) == "8" then --Удаление символа
			if line_table ~= nil and col_table ~= nil and maintable:is_it_Field('ChartId', line_table, col_table) then
				local curVal = maintable:GetValue('ChartId', 'image')
				local newString = string.sub(curVal, 1, string.len(curVal)-1)
				maintable:SetValue('ChartId', newString, 0)
			elseif line_table ~= nil and col_table ~= nil and maintable:is_it_editField(line_table, col_table) then
                local curVal = maintable:GetColValue(line_table, col_table, 'image')
                local newVal = string.sub(curVal, 1, string.len(curVal)-1)
				if maintable:is_it_Field('QTY', line_table, col_table) then
					SetQty(tonumber(newVal) or 0)
				else
					maintable:SetColValue(line_table, col_table, newVal, tonumber(newVal))
				end
				setParameters()
			end
		else
			if line_table ~= nil and maintable:is_it_Field('ChartId', line_table, col_table) then
				local newString = maintable:GetValue('ChartId', 'image')..string.char(par2)
				maintable:SetValue('ChartId', newString, 0)
			elseif line_table ~= nil and col_table ~= nil and maintable:is_it_editField(line_table, col_table) then
				if string.char(par2) == '.' then wasDot = true; return end
                local field_name = maintable:GetFieldName(line_table, col_table)
                if wasDot and string.char(par2) == '0' then zeroString = zeroString..'0'; return end
                local curVal = maintable:GetColValue(line_table, col_table, 'image')
                curVal = curVal:gsub('virtual qty: ','')
				local newVal = (wasDot and curVal..'.'..zeroString or (curVal == '0' and '' or curVal))..string.char(par2)
                myLog('curVal: '..tostring(curVal)..', newVal: '..tostring(newVal))
				wasDot = false; zeroString = ''
                if maintable:is_it_Field('QTY', line_table, col_table) then
					SetQty(tonumber(newVal) or 0)
				else
					maintable:SetColValue(line_table, col_table, newVal, tonumber(newVal))
				end
				setParameters()
			end
		end
	end

	if msg == QTABLE_LBUTTONDOWN then

        if maintable:is_it_editField(line_table, col_table) and line_table~=0 and col_table~=0 then
            maintable.t:SetColor(line_table, col_table, RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))
            line_table = 0
            col_table  = 0
        end
        if maintable:is_it_editField(par1, par2) then
            line_table = par1
            col_table  = par2
            maintable.t:SetColor(line_table, col_table, RGB(249,239,123), RGB(0,0,0), RGB(249,239,123), RGB(0,0,0))
        end

	end

	if msg == QTABLE_LBUTTONDBLCLK then

		if maintable:is_it_Field('START', par1, par2) then -- Start\Stop
			if isTrade == false and ROBOT_STATE ~= "ОПТИМИЗАЦИЯ" then
                ROBOT_STATE ='СТАРТ ТОРГОВЛИ'
			elseif isTrade then
                isTrade = false
                SetStartStop()
				SetAlgo()
			end
		end
		if maintable:is_it_Field('SELL', par1, par2) then -- SELL
			CurrentDirect = 'SELL'
			myLog(NAME_OF_STRATEGY..' Сделка руками '..CurrentDirect)
			setParameters()
			ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
		end
		if maintable:is_it_Field('BUY', par1, par2) then -- BUY
			CurrentDirect = 'BUY'
			myLog(NAME_OF_STRATEGY..' Сделка руками '..CurrentDirect)
			setParameters()
			ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
		end
		if maintable:is_it_Field('REVERSE', par1, par2) then -- ПЕРЕВОРОТ
			CurrentDirect = 'AUTO'
			myLog(NAME_OF_STRATEGY..' Сделка руками ПЕРЕВОРОТ '..CurrentDirect)
			setParameters()
			ROBOT_STATE = 'ПЕРЕВОРОТ'
		end
		if maintable:is_it_Field('CLOSE_ALL', par1, par2) then -- All Close
			OpenCount = GetTotalnet()
			CurrentDirect = 'AUTO'
			myLog(NAME_OF_STRATEGY..' Сделка руками Закрытие всех позиций')
			ROBOT_STATE = 'CLOSEALL'
		end
		if maintable:is_it_Field('KILL_ALL_SL', par1, par2) and SetStop==true then -- Close SL
			myLog(NAME_OF_STRATEGY..' Закрытие стоп-лосса')
			manualKillStop = true
			TakeProfitPrice = 0
			ROBOT_STATE = 'СНЯТИЕ СТОП ЛОССА'
		end
		if maintable:is_it_Field('SET_SL_TP', par1, par2) and SetStop==true then -- SET SL
			myLog(NAME_OF_STRATEGY..' Установка стоп-лосса')
			if not isStopOrderSet() then
				setParameters()
				manualKillStop = false
				stopLevelPrice = last_price
				ROBOT_STATE = 'УСТАНОВКА СТОП ЛОССА'
			end
		end

		if is_it_Preset(par1, par2) and not isTrade and not optimizationInProgress then

			local preset = addedPresets[tonumber(tostring(par1)..tostring(par2))]

			local needScanOpenCountSLTP = false
			if SEC_CODE ~= presets[preset].SEC_CODE or CLASS_CODE ~= presets[preset].CLASS_CODE then
				myLog(NAME_OF_STRATEGY.." Смена инструмента торгов")
				needScanOpenCountSLTP = true
			end

			if getSecurityInfo(presets[preset].CLASS_CODE, presets[preset].SEC_CODE) == nil then
				message("Не удалось получить данные по инструменту: "..presets[curPreset].SEC_CODE.."/"..tostring(presets[curPreset].CLASS_CODE))
				myLog(NAME_OF_STRATEGY.." Не удалось получить данные по инструменту: "..presets[curPreset].SEC_CODE.."/"..tostring(presets[curPreset].CLASS_CODE))
				return false
			end
			if isConnected() == 0 and needScanOpenCountSLTP then
				message("Нет подключения к серверу. Смена инструмента невозможна.")
				myLog("Нет подключения к серверу. Смена инструмента невозможна.")
				return false
			end

			curPreset = preset
			initPreset(needScanOpenCountSLTP)

		end

		if isOptimization and maintable:is_it_Field('OPTIMIZE', par1, par2) then -- Optimize

            if CLOSE_BAR_SIGNAL == 0 then
				message("Для алгоритма реального времени оптимизация невозможна.")
				myLog("Для алгоритма реального времени оптимизация невозможна.")
                return
            end

			if optimizationInProgress then
				stopSignal = true
				return
			end

			setParameters()

			ROBOT_STATE       = 'ОПТИМИЗАЦИЯ'
			BASE_ROBOT_STATE  = 'ОПТИМИЗАЦИЯ'

			if isTrade then
				isTrade = false
                SetStartStop()
				SetAlgo()
			end

			INTERVAL = maintable:GetValue('INTERVAL')

			local Error = ''
			DS,Error = CreateDataSource(CLASS_CODE, SEC_CODE, INTERVAL)
			-- Проверка
			if DS == nil then
				message(NAME_OF_STRATEGY..' robot:ОШИБКА получения доступа к свечам! '..Error)
				return
			end

		end

	end
	if (msg==QTABLE_CLOSE) then --закрытие окна
		stopSignal = true
	end
end

--Проверка закрытия окна и остановки робота
local function CheckStopOnCloseWindow()

    if maintable~=nil and STOP_ROBOT_ON_CLOSE_TABLE == 1 and maintable.t:IsClosed() then
        myLog(NAME_OF_STRATEGY.." Stop on Close window")
        return true
    elseif maintable~=nil and STOP_ROBOT_ON_CLOSE_TABLE == 0 and maintable.t:IsClosed() then
        myLog(NAME_OF_STRATEGY.." Restore on Close window")
        FillMainTableWithPreset(true)
        SetTableNotificationCallback (maintable.t.t_id, MainTable_Comands)
        setTableAlgoParams(Settings, presets[curPreset])
        SetStartStop()
    end

    return false
end


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Основной блок
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ТОРГОВЛИ

--Скорректировать индекс бара по времени.
--Новый бар появляется только тогда когда есть хоть одна сделка в этом баре.
--В таком случае от начала бара по времени, до его появления может пройти много времени и сигнал будет получен не во
-- время начала бара, а в момент первой сделки
--В таких ситуациях увеличиваем индекс бара на 1
local function CorrectBarIndex(last_close_index)
    local localTime = os.time(GetServerDateTime())
    --Проверим, что свеча уже появилась
    local lastIndexTime = os.time(DS:T(last_close_index))
    if localTime~=0 and lastIndexTime~=nil and localTime >= lastIndexTime+INTERVAL*60 then
        last_close_index = last_close_index + 1
    end
    return last_close_index
end

--Запуск алго-торговли
local function startTrade()

    local serverTime = os.time(GetServerDateTime())
    if serverTime >= endTradeTime and serverTime < eveningSession then
        message('Основная торговая сессия закончилась, дополнительная еще не началась!!! Торговля невозможна')
        myLog('Основная торговая сессия закончилась, дополнительная еще не началась!!! Торговля невозможна')
        return
	end

    local can_trade, state = CheckTradeSession()
    myLog(NAME_OF_STRATEGY..' '..state)

	if not can_trade then
		message("Нет подключения к серверу или не идет торговая сессия. Торговля невозможна.")
		myLog("Нет подключения к серверу или не идет торговая сессия. Торговля невозможна.")
		return
	end

    myLog(NAME_OF_STRATEGY..' robot: старт торговли')
    setParameters()
    myLog(NAME_OF_STRATEGY..' robot: '..' INTERVAL '..tostring(INTERVAL)..' STOP_LOSS '..tostring(STOP_LOSS)..' TAKE_PROFIT '..tostring(TAKE_PROFIT)..' shiftStop '..tostring(shiftStop)..' shiftProfit '..tostring(shiftProfit)..' fixedstop '..tostring(fixedstop))

    lastTradeDirection = 0
    currentTrend = 0
    slIndex = 0
    workedStopPrice = 0
    lastStopShiftIndex = 0

    if VIRTUAL_TRADE then
        slPrice = maintable:GetValue('SL')
        tpPrice = maintable:GetValue('TP')
		oldStop = slPrice
    end

    isStopOrderSet(true)

    local Error = ''
    DS,Error = CreateDataSource(CLASS_CODE, SEC_CODE, INTERVAL)
    -- Проверка
    if DS == nil then
        message(NAME_OF_STRATEGY..' robot:ОШИБКА получения доступа к свечам! '..Error)
        return
    end

    calcAlgoValue={}

    if initAlgo~=nil then
        initAlgo()
    end

    local index = DS:Size()
    beginIndex = index-(testSizeBars or 0)
    Settings.beginIndexToCalc = math.max(1, beginIndex - 1000)

    for i = Settings.beginIndexToCalc, index-1 do
        calculateAlgo(i, Settings)
    end
    if CLOSE_BAR_SIGNAL == 0 then
        --Переносим текущий тренд в прошлый, чтобы не срабатал давний сигнал при страте робота
        trend.last = trend.current
        myLog("Start "..", trend: "..tostring(trend.current)..", past trend: "..tostring(trend.last))
    end

    if ChartId ~= nil then
        stv.UseNameSpace(ChartId)
        stv.SetVar('algoResults', calcChartResults)
    end

    lastCalculatedBar = index-1
    manualKillStop = false
    LastOpenBarIndex = index

    --myLog(NAME_OF_STRATEGY.." #calcAlgoValue "..tostring(#calcAlgoValue).." roundAlgoVal "..tostring(roundAlgoVal).." trend "..tostring(trend[index-1]))

    local currentTradeDirection = getTradeDirection(CLOSE_BAR_SIGNAL == 1 and index-1 or index, calcAlgoValue, trend)
    if currentTradeDirection == -1 then
        CurrentDirect = 'SELL'
    elseif currentTradeDirection == 1 then
        CurrentDirect = 'BUY'
    end

    local roundAlgoVal = round(calcAlgoValue[index-1], SCALE)
    SetAlgo(currentTradeDirection, roundAlgoVal)

    TransactionPrice = DS:C(index)
    isTrade = true
    TRAILING_ACTIVATED = false

    SetStartStop()

end

-- Проверка движения цены
function OnParam(class_code, sec_code)

    if isRun and class_code == CLASS_CODE and sec_code==SEC_CODE then

        last_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)
        local index = DS:Size()

        --myLog(NAME_OF_STRATEGY.." last price "..tostring(last_price).." lp "..tostring(lp))
		SetLastPrice(last_price)

        if OpenCount~=0 then
            --local curDealProfit = OpenCount>0 and (last_price - lastDealPrice) or (lastDealPrice - last_price)
            local curDealProfit = round((last_price - lastDealPrice)*OpenCount/priceKoeff, SCALE)
            SetDealProfit(curDealProfit)
            priceMoveMin = math.min(priceMoveMin, last_price)
            priceMoveMax = math.max(priceMoveMax, last_price)
        end

        if optimizationInProgress then
            SetState( "OPTIMIZATION "..tostring(doneOptimization).."%", doneOptimization)
            return
        end

        function virtual_SLTP_ClosePos(Type, qty, worked_stop_price)
            slIndex = index
            myLog('slIndex '..tostring(slIndex).." - "..tostring(toYYYYMMDDHHMMSS(DS:T(slIndex))))
            workedStopPrice = worked_stop_price
            VirtualTrade(Type, qty)
            OpenCount = 0
            curOpenCount = 0
            clearTableOnClosePos()
        end

        if VIRTUAL_TRADE then
            if OpenCount > 0 and last_price >= tpPrice and tpPrice~=0 then
                myLog(NAME_OF_STRATEGY.." Take profit")
                virtual_SLTP_ClosePos('SELL', OpenCount, tpPrice)
            end
            if OpenCount < 0 and last_price <= tpPrice and tpPrice~=0 then
                myLog(NAME_OF_STRATEGY.." Take profit")
                virtual_SLTP_ClosePos('BUY', -OpenCount, tpPrice)
            end
            if OpenCount > 0 and last_price <= slPrice and slPrice~=0 then
                myLog(NAME_OF_STRATEGY.." Stop loss")
                virtual_SLTP_ClosePos('SELL', OpenCount, slPrice)
            end
            if OpenCount < 0 and last_price >= slPrice and slPrice~=0 then
                myLog(NAME_OF_STRATEGY.." Stop loss")
                virtual_SLTP_ClosePos('BUY', -OpenCount, slPrice)
            end
        end

    end

end

--Получение текущей открытой позиции
function GetTotalnet(justGetCount)

    local pos = 0
    local avgPrice = 0

    if not isRun then return pos, avgPrice end

    if VIRTUAL_TRADE then
        pos = OpenCount
        avgPrice = lastDealPrice
    else

        local status,res = pcall(function()
            -- ФЬЮЧЕРСЫ, ОПЦИОНЫ
            if CLASS_CODE == 'SPBFUT' or CLASS_CODE == 'SPBOPT' then
                local num = getNumberOf('futures_client_holding')
                if num > 0 then
                    if num > 1 then
                        for i = 0, num - 1 do
                            local futures_client_holding = getItem('futures_client_holding',i)
                            if futures_client_holding.sec_code == SEC_CODE and futures_client_holding.trdaccid == ACCOUNT then
                                if BALANCE_TYPE == 1 then
                                    pos = futures_client_holding.totalnet
                                else
                                    pos = futures_client_holding.totalnet/LOTSIZE
                                end
                                avgPrice = futures_client_holding.avrposnprice
                            end
                        end
                    else
                        local futures_client_holding = getItem('futures_client_holding',0)
                        if futures_client_holding.sec_code == SEC_CODE and futures_client_holding.trdaccid == ACCOUNT then
                            if BALANCE_TYPE == 1 then
                                pos = futures_client_holding.totalnet
                            else
                                pos = futures_client_holding.totalnet/LOTSIZE
                            end
                            avgPrice = futures_client_holding.avrposnprice
                        end
                    end
                end
            -- АКЦИИ
            elseif CLASS_CODE == 'TQBR' or CLASS_CODE == 'QJSIM' then
                local num = getNumberOf('depo_limits')
                if num > 0 then
                    if num > 1 then
                        for i = 0, num - 1 do
                            local depo_limit = getItem('depo_limits', i)
                            if depo_limit.sec_code == SEC_CODE
                            and depo_limit.trdaccid == ACCOUNT
                            and depo_limit.limit_kind == LIMIT_KIND then
                                if BALANCE_TYPE == 1 then
                                    pos = depo_limit.currentbal
                                else
                                    pos = depo_limit.currentbal/LOTSIZE
                                end
                                avgPrice = depo_limit.awg_position_price
                            end
                        end
                    else
                        local depo_limit = getItem('depo_limits', 0)
                        if depo_limit.sec_code == SEC_CODE
                        and depo_limit.trdaccid == ACCOUNT
                        and depo_limit.limit_kind == LIMIT_KIND then
                            if BALANCE_TYPE == 1 then
                                pos = depo_limit.currentbal
                            else
                                pos = depo_limit.currentbal/LOTSIZE
                            end
                            avgPrice = depo_limit.awg_position_price
                        end
                    end
                end
            -- ВАЛЮТА
            elseif CLASS_CODE == 'CETS' then
                local num = getNumberOf('money_limits')
                if num > 0 then
                    -- Находит валюту
                    local cur = string.sub(SEC_CODE, 1, 3)
                    -- Находит размер лота
                    if num > 1 then
                        local currentbal = 0
                        for i = 0, num - 1 do
                            local money_limit = getItem('money_limits', i)
                            if money_limit.currcode == cur
                            and money_limit.client_code == CLIENT_CODE
                            and (money_limit.limit_kind == 0 or money_limit.limit_kind == 2) then
                                currentbal = currentbal + money_limit.currentbal
                            end
                        end
                        if currentbal == 0 then return 0 end
                        if BALANCE_TYPE == 1 then
                            pos = currentbal
                        else
                            pos =  math_round(currentbal/LOTSIZE)
                        end
                    else
                        local money_limit = getItem('money_limits', 0)
                        if money_limit.currcode == cur
                        and money_limit.client_code == CLIENT_CODE
                        and (money_limit.limit_kind == 0 or money_limit.limit_kind == 2) then
                            if BALANCE_TYPE == 1 then
                                pos = money_limit.currentbal
                            else
                                pos = math_round(money_limit.currentbal/LOTSIZE)
                            end
                        end
                    end
                end
            end
        end)
        if not status then myLog('Error GetTotalnet') end

        local avgOrderPrice = getAvgPrice(pos)
        if avgOrderPrice~=0 then
            avgPrice = avgOrderPrice
        end

    end

    if justGetCount == true then return pos end

    if pos == 0 then
        TRAILING_ACTIVATED = false
    end

    lastDealPrice = avgPrice
    stopLevelPrice = lastDealPrice
    SetPos(pos, avgPrice)
    return pos, avgPrice
end

--Получение текущей средней цены открытой позиции
function getAvgPrice(pos)

    local avgPrice = 0

    if pos~=0 then

        function myFind(C,S,F,B)
            return (C == CLASS_CODE) and (S == SEC_CODE) and (bit.band(F,0x2)==0 and bit.band(F,0x1)==0) and ((not trackManualDeals and B:find(ROBOT_POSTFIX)) or trackManualDeals)
        end
        local res=1
        local ord = "trades"
        local tradeTable = SearchItems(ord, 0, getNumberOf(ord)-1, myFind, "class_code,sec_code,flags,brokerref")
        if (tradeTable ~= nil) and (#tradeTable > 0) then

            local netCount = math.abs(pos)

            for tN=#tradeTable,1,-1 do

                if netCount <= 0 then
                    break
                end

                trade = getItem('trades', tradeTable[tN])
                if trade ~= nil then
                    local itsClosePos = (pos>0 and bit.band(trade.flags,0x4)~=0) or (pos<0 and bit.band(trade.flags,0x4)==0)
                    myLog(NAME_OF_STRATEGY.." сделка ордер "..tostring(trade.order_num).." price "..tostring(trade.price).." qty "..tostring(trade.qty)..' netCount '..tostring(netCount)..' client_code '..tostring(trade.client_code)..' ROBOT_CLIENT_CODE '..tostring(ROBOT_CLIENT_CODE))
                    myLog(NAME_OF_STRATEGY..' сделка  num '..tostring(trade.trade_num).." флаг 0x4 "..tostring(bit.band(trade.flags,0x4))..' itsClosePos '..tostring(itsClosePos))
                    if not itsClosePos then
                        avgPrice = avgPrice+trade.price*math.min(trade.qty, netCount)--/trade.qty
                        netCount = netCount-trade.qty
                        myLog(NAME_OF_STRATEGY..' avgPrice '..tostring(avgPrice)..' netCount '..tostring(netCount))
                    end
                end
            end
            if pos~=0 then
                avgPrice = round(math.abs(avgPrice/pos), SCALE)
            end
            if netCount>0 then
                avgPrice = 0
            end
            myLog(NAME_OF_STRATEGY..' avgPrice '..tostring(avgPrice))
        end

    end

    return avgPrice
end

--Реакция на изменение размера позиции - снятие/открытие стоп заявок
function onChangeOpenCount()

    if not SetStop then return end

    local isStop = isStopOrderSet()
    myLog("===============================================================")
    myLog(NAME_OF_STRATEGY..' Изменился размер позиции, position '..tostring(OpenCount)..', проверка установленных ордеров '..ROBOT_CLIENT_CODE..', isStop '..tostring(isStop))

    if not isStop and OpenCount~=0 then
        TransactionPrice = stopLevelPrice
        priceMoveMax = TransactionPrice
        priceMoveMin = TransactionPrice
        myLog(NAME_OF_STRATEGY..' Установка стоп-лосса onChangeOpenCount, позиция '..tostring(OpenCount))
        local Type = OpenCount > 0 and "BUY" or "SELL"
        local tp_Price, sl_Price, price = getSLTP_Price(stopLevelPrice, Type, OpenCount, fixedstop)
        local AtPrice = {tp_Price = tp_Price, sl_Price = sl_Price, price = price, offset = OFFSET, spread = SPREAD}
        local result = SL_TP(AtPrice, Type, OpenCount)
        if result then
            priceMoveMin = stopLevelPrice
            priceMoveMax = stopLevelPrice
        end
    elseif isStop then
        myLog(NAME_OF_STRATEGY..': Закрытие стоп-лосса onChangeOpenCount')
        local continue = KillAllStopOrders(OpenCount == 0)
        -- TransactionPrice = (stopLevelPrice or 0) ~= 0 and stopLevelPrice or TransactionPrice
        -- TransactionPrice = stopLevelPrice
        if isPriceMove then
            TransactionPrice = stopLevelPrice
            priceMoveMax = TransactionPrice
            priceMoveMin = TransactionPrice
        end
        if continue ~= true then
            isTrade = false
            message(NAME_OF_STRATEGY..'Закрытие стопа позиции не удалось. Скрипт остановлен')
            myLog(NAME_OF_STRATEGY..'Закрытие стопа позиции не удалось. Скрипт остановлен')
        end

        local stopOpenCount = (GetTotalnet(true))
        if stopOpenCount~=curOpenCount then
            myLog(NAME_OF_STRATEGY..' Успел измениться размер позиции. Установка стоп-лосса отменена, позиция: '..tostring(stopOpenCount))
            return
        end
        if OpenCount~=0 then
            myLog(NAME_OF_STRATEGY..' Установка стоп-лосса onChangeOpenCount, позиция '..tostring(OpenCount))
            local Type = OpenCount > 0 and "BUY" or "SELL"
            local tp_Price, sl_Price, price = getSLTP_Price(stopLevelPrice, Type, OpenCount, fixedstop)
            local AtPrice = {tp_Price = tp_Price, sl_Price = sl_Price, price = price, offset = OFFSET, spread = SPREAD}
            local result = SL_TP(AtPrice, Type, OpenCount)
            if result then
                priceMoveMin = stopLevelPrice
                priceMoveMax = stopLevelPrice
            end
        end
    end

    if OpenCount == 0 then
        clearTableOnClosePos()
    end

end

--Реакция на изменение размера позиции для срочного рынка
function OnFuturesClientHolding(fut_limit)

    if not VIRTUAL_TRADE and fut_limit.sec_code == SEC_CODE then
        curOpenCount = fut_limit.totalnet
        --myLog(NAME_OF_STRATEGY..' OnFuturesClientHolding: OpenCount '..tostring(OpenCount)..', fut_limit.totalnet '..tostring(fut_limit.totalnet))
    end

end

--Реакция на изменение размера позиции для рынка акций
function OnDepoLimit(depo_limit)

    if not VIRTUAL_TRADE and depo_limit.sec_code == SEC_CODE and depo_limit.limit_kind == 0 then
        curOpenCount = depo_limit.currentbal/LOTSIZE
    end
end

------------------------------------------
-- Основной цикл
function main()

	--установим обработчик событий таблицы робота
	SetTableNotificationCallback (maintable.t.t_id, MainTable_Comands)

    local function Optimize()

        if not isRun then return end
        if not isOptimization then
            message('Модуль оптимизации не подключен. Процедура недоступна!!!')
            myLog('Модуль оптимизации не подключен. Процедура недоступна!!!')
            return
        end

        myLog(NAME_OF_STRATEGY..' optimizationInProgress = '..tostring(optimizationInProgress))
        if not optimizationInProgress then
            myLog(NAME_OF_STRATEGY..' ROBOT_STATE = '..tostring(ROBOT_STATE))
            optimizationInProgress = true
            doneOptimization = 0
            maintable:SetValue('OPTIMIZE', "STOP OPTIMIZE", 0)
            SetState( "OPTIMIZATION "..tostring(doneOptimization).."%", doneOptimization)
            if ROBOT_STATE == 'ОПТИМИЗАЦИЯ' then
                if iterateAlgo~=nil then
                    iterateAlgo()
                end
                ROBOT_STATE = 'ОСТАНОВЛЕН'
                BASE_ROBOT_STATE = 'ОСТАНОВЛЕН'
                SetState(ROBOT_STATE)
            else
                reoptimize()
            end
            maintable:SetValue('OPTIMIZE', "OPTIMIZE", 0)
        end
    end

    -- Цикл по дням
    while isRun do

        -- Ждет начала следующего дня
        while isRun and GetServerDateTime().day == PrevDayNumber do
            if ROBOT_STATE == 'ОПТИМИЗАЦИЯ' then
                Optimize()
            end
            CheckTradeSession()
            isRun = not CheckStopOnCloseWindow()
            sleep(100)
        end

        -- Ждет начала старта торговли дня
        while isRun and os.time(GetServerDateTime()) <= startTradeTime do

            if ROBOT_STATE == 'ОПТИМИЗАЦИЯ' then
                Optimize()
            end
            if ROBOT_STATE == 'СТАРТ ТОРГОВЛИ' then
                startTrade()
            end
            CheckTradeSession()
            isRun = not CheckStopOnCloseWindow()
            sleep(100)
        end

        isRun = not CheckStopOnCloseWindow()

        myLog('==================================================================')
        myLog('Начало торгового времени')
        myLog('==================================================================')

        -- Цикл внутри дня
        while isRun do

            isRun = not CheckStopOnCloseWindow()
            if not isRun then break end

            if ROBOT_STATE == 'ОПТИМИЗАЦИЯ' or needReoptimize and CLOSE_BAR_SIGNAL == 1 then
                Optimize()
            else

                if CheckTradeSession() then

                    if ROBOT_STATE == 'СТАРТ ТОРГОВЛИ' then
                        startTrade()
                    end

                    local serverTime = os.time(GetServerDateTime())
                    getTradeState()

                    if SetStop == true and OpenCount ~= 0 and ROBOT_STATE ~= 'УСТАНОВКА СТОП ЛОССА' then
                        checkSLbeforeClearing(last_price)
                        trailStop(last_price)
                    end

                    if isTrade and serverTime >= endTradeTime and serverTime < eveningSession then
                        if autoClosePosition then
                            isTrade = false
                            CurrentDirect = "AUTO"
                            ROBOT_STATE = 'CLOSEALL'
                            BASE_ROBOT_STATE = 'ОСТАНОВЛЕН'
                            SetStartStop()
                        end
                        if autoReoptimize then needReoptimize = true end
                    end

                    local dealQnty = QTY_LOTS
                    if OpenCount~=0 and (ROBOT_STATE == 'ПЕРЕВОРОТ' or ROBOT_STATE == 'CLOSEALL') then
                        if CurrentDirect == "AUTO" then
                            CurrentDirect = OpenCount > 0 and "SELL" or "BUY"
                        end
                        dealQnty = math.abs(OpenCount)
                        if ROBOT_STATE == 'ПЕРЕВОРОТ' then --переворот делается на размер позиции
                            dealQnty = 2*math.abs(OpenCount)
                        end
                        ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
                    end

                    --Если СОСТОЯНИЕ робота "В ПРОЦЕССЕ СДЕЛКИ"
                    if ROBOT_STATE == 'В ПРОЦЕССЕ СДЕЛКИ' then

                        if not isRun then return end -- Если скрипт останавливается, не затягивает процесс
                        myLog(NAME_OF_STRATEGY..' robot: команда на открытие сделки '..CurrentDirect..', шорт разрешен: '..tostring(isShort)..', лонг разрешен: '..tostring(isLong))
                        orderQnty = 0
                        -- Если пытается открыть SELL, а операции шорт по данному инструменту запрещены
                        if OpenCount == 0 and CurrentDirect == "SELL" and not isShort then
                            myLog(NAME_OF_STRATEGY..' robot: Была первая попытка совершить запрещенную операцию шорт!')
                            if isTrade then
                                ROBOT_STATE = 'ПОИСК СДЕЛКИ'
                            else
                                ROBOT_STATE = 'ОСТАНОВЛЕН'
                            end
                            BASE_ROBOT_STATE = ROBOT_STATE
                            SetState(ROBOT_STATE)
                            -- Если пытается открыть BUY, а операции лонг по данному инструменту запрещены
                        elseif OpenCount == 0 and CurrentDirect == "BUY" and not isLong then
                            myLog(NAME_OF_STRATEGY..' robot: Была первая попытка совершить запрещенную операцию лонг!')
                            if isTrade then
                                ROBOT_STATE = 'ПОИСК СДЕЛКИ'
                            else
                                ROBOT_STATE = 'ОСТАНОВЛЕН'
                            end
                            BASE_ROBOT_STATE = ROBOT_STATE
                            SetState(ROBOT_STATE)
                        else

                            local continue = MarketTrade(CurrentDirect, dealQnty)

                            if not isRun then return end -- Если скрипт останавливается, не затягивает процесс

                            -- Если заявка отправилась
                            if not continue then
                                -- Выводит сообщение
                                message(NAME_OF_STRATEGY..' robot: неудачная попытка открыть сделку!!!')
                                myLog(NAME_OF_STRATEGY..' robot: неудачная попытка открыть сделку!!!')
                                isTrade = false
                            end

                        end
                    end

                    --Отработка событий
                    if ROBOT_STATE == 'FIRSTSTART' then
                        Initialization()
                    end
                    if not VIRTUAL_TRADE then
                        local isChangePos = (curOpenCount<=0 and OpenCount>0) or (curOpenCount>=0 and OpenCount<0)
                        if isChangePos then
                            DEAL_COUNTER = DEAL_COUNTER + 1
                            ROBOT_CLIENT_CODE = getROBOT_CLIENT_CODE(DEAL_COUNTER)
                        end
                        if ROBOT_STATE == 'ОЖИДАНИЕ СДЕЛКИ' and curOpenCount ~= OpenCount then
                            OpenCount, avgPrice = GetTotalnet()
                            if orderQnty == 0 then ROBOT_STATE = 'УСТАНОВКА СТОП ЛОССА' end
                        end
                        if (trackManualDeals and curOpenCount ~= OpenCount) or (curOpenCount==0 and OpenCount~=0) then
                            OpenCount, avgPrice = GetTotalnet()
                            ROBOT_STATE = 'УСТАНОВКА СТОП ЛОССА'
                        end
                    end
                    if ROBOT_STATE == 'СНЯТИЕ СТОП ЛОССА' then
                        continue = KillAllStopOrders()
                        if continue ~= true then
                            isTrade = false
                            message(NAME_OF_STRATEGY..' Закрытие стопа позиции не удалось. Скрипт остановлен')
                            myLog(NAME_OF_STRATEGY..' Закрытие стопа позиции не удалось. Скрипт остановлен')
                        end
                        ROBOT_STATE = BASE_ROBOT_STATE
                        SetState(ROBOT_STATE)
                    end
                    if ROBOT_STATE == 'УСТАНОВКА СТОП ЛОССА' then
                        if manualKillStop and OpenCount~=0 then
                            message('Установка стоп-лосса заблокирована. Установите стоп вручную командой SET SL/TP, для дальнейшего автоматического выставления.')
                            myLog(NAME_OF_STRATEGY..' Установка стоп-лосса заблокирована. Установите стоп вручную командой SET SL/TP, для дальнейшего автоматического выставления.')
                        end
                        if SetStop == true and StopForbidden == false then
                            myLog(NAME_OF_STRATEGY..' robot: Обработка СТОП заявки '..CurrentDirect..' позиция '..tostring(OpenCount))
                            onChangeOpenCount()
                        end
                        ROBOT_STATE = BASE_ROBOT_STATE
                        SetState(ROBOT_STATE)
                    end

                    if ROBOT_STATE ~= BASE_ROBOT_STATE and ROBOT_STATE ~= 'ОЖИДАНИЕ СДЕЛКИ' then
                        ROBOT_STATE = BASE_ROBOT_STATE
                        SetState(ROBOT_STATE)
                    end

                end
            end

            -- Если торговый день закончился, выходит в цикл по дням
            local ServerDT = GetServerDateTime()
            local serverTime = os.time(ServerDT)
            if serverTime >= endOfDay then
                PrevDayNumber = ServerDT.day
                break
            end

            sleep(50)
        end
    end
end

--Проверка на необходимость снятия стопа перед клирингом (настройка CloseSLbeforeClearing = true)
function checkSLbeforeClearing()

    if CloseSLbeforeClearing and SetStop == true and OpenCount ~= 0 and CLASS_CODE ~= 'QJSIM' and CLASS_CODE ~= 'TQBR' and not manualKillStop then

        local serverTime = os.time(GetServerDateTime())
        if StopForbidden == false and ((serverTime>=(dayClearing-minToCloseSLbeforeClearing*60) and serverTime<dayClearing) or
                                       (serverTime>=endTradeTime and serverTime<(eveningClearing-minToCloseSLbeforeClearing*60)) or
                                       (serverTime<endOfDay and serverTime>(endOfDay-minToCloseSLbeforeClearing*60)))
        then
            StopForbidden = true
            myLog(NAME_OF_STRATEGY..' Закрытие стоп-лосса перед клирингом')
            --myLog(NAME_OF_STRATEGY.." StopForbidden "..tostring(StopForbidden))
            KillAllStopOrders()
            --needReoptimize = true
        end

        if StopForbidden == true and ((serverTime>=(dayClearing+clearingTime*60)) or serverTime>=eveningSession)
                                 and   serverTime<(endOfDay-minToCloseSLbeforeClearing*60)
        then
            StopForbidden = false
            if not isStopOrderSet() then
                myLog(NAME_OF_STRATEGY..' Восстановление стоп-лосса после клиринга')
                stopLevelPrice = last_price
                ROBOT_STATE = 'УСТАНОВКА СТОП ЛОССА'
            end
        end
    end

end

--Проверка необходимости сдвига стоп заявки (shiftStop = true или shiftProfit = true)
function trailStop()

	--трейлим стоп
	if OpenCount ~= 0 and (shiftStop or shiftProfit) and CheckTradeSession() then

        --isPriceMove = isPriceMove or ROBOT_STATE ~= 'ОЖИДАНИЕ СДЕЛКИ' and (OpenCount < 0 and STOP_LOSS~=0 and round(TransactionPrice - priceMoveMin, SCALE) >= STOP_LOSS*priceKoeff) or (OpenCount > 0 and STOP_LOSS~=0 and round(priceMoveMax - TransactionPrice, SCALE) >= STOP_LOSS*priceKoeff)

        local isPriceMoveNow = false

        local delta = (OpenCount < 0 and round(TransactionPrice - priceMoveMin, SCALE) or round(priceMoveMax - TransactionPrice, SCALE))
        if TRAILING_SIZE~=0 and TRAILING_SIZE_STEP~=0 then
            if not TRAILING_ACTIVATED then
                isPriceMoveNow = (delta >= (TRAILING_SIZE + TRAILING_SIZE_STEP)*priceKoeff) and TRAILING_SIZE~=0
                if isPriceMoveNow then
                    TRAILING_ACTIVATED = true
                    delta = delta - TRAILING_SIZE*priceKoeff
                end
            else
                isPriceMoveNow = delta >= TRAILING_SIZE_STEP*priceKoeff
            end
        elseif TRAILING_SIZE_STEP~=0 then
            if not TRAILING_ACTIVATED then
                isPriceMoveNow = delta >= TRAILING_SIZE_STEP*priceKoeff
                if isPriceMoveNow then TRAILING_ACTIVATED = true end
            else
                isPriceMoveNow = delta >= TRAILING_SIZE_STEP*priceKoeff
            end
        else
            isPriceMoveNow = (delta >= STOP_LOSS*priceKoeff) and STOP_LOSS~=0
        end

        isPriceMove = isPriceMove or ROBOT_STATE ~= 'ОЖИДАНИЕ СДЕЛКИ' and isPriceMoveNow
        local index = DS:Size()

        if (isPriceMove or (OpenCount~=0 and lastStopShiftIndex~=0 and (index - lastStopShiftIndex) > stopShiftIndexWait)) and not manualKillStop and not StopForbidden and STOP_LOSS~=0 then
            priceMoveVal = delta
            myLog("======================================================================================================================")
            myLog('lastDealPrice '..tostring(lastDealPrice)..' TransactionPrice '..tostring(TransactionPrice)..' index '..tostring(index)..' lastStopShiftIndex '..tostring(lastStopShiftIndex)..' priceMoveMin '..tostring(priceMoveMin)..' priceMoveMax '..tostring(priceMoveMax)..' isPriceMove '..tostring(isPriceMove)..' OpenCount '..tostring(OpenCount)..' PRICE_SHIFT '..tostring(STOP_LOSS*priceKoeff)..' TransactionPrice - priceMoveMin '..tostring(round(TransactionPrice - priceMoveMin, SCALE))..' priceMoveMax - TransactionPrice '..tostring(round(priceMoveMax - TransactionPrice, SCALE)))
			myLog(NAME_OF_STRATEGY..' Сдвиг стоп-лосса, isPriceMove '..tostring(isPriceMove)..' StopShiftIndex '..tostring(index - lastStopShiftIndex))
            stopLevelPrice = isPriceMove and (OpenCount<0 and priceMoveMin or priceMoveMax) or TransactionPrice
            ROBOT_STATE = 'УСТАНОВКА СТОП ЛОССА'
        end

	end

end

--Реоптимизация
function reoptimize()

    if isTrade then
        isTrade = false
    end

    SetStartStop()

    ROBOT_STATE = 'ОПТИМИЗАЦИЯ'
    BASE_ROBOT_STATE = 'ОПТИМИЗАЦИЯ'
    SetState(ROBOT_STATE)

    setParameters()
    lastSignalIndex = {}

    myLog(NAME_OF_STRATEGY..' Старт реопртимизации')

    if VIRTUAL_TRADE then
        if tpPrice~=0 then vtpPrice = tpPrice end
        if slPrice~=0 then vslPrice = slPrice end
    end

    if iterateAlgo~=nil then
        iterateAlgo()
    end

    needReoptimize = false

    if VIRTUAL_TRADE then
        if vtpPrice~=0 then tpPrice = vtpPrice end
        if vslPrice~=0 then slPrice = vslPrice end
    end

    local serverTime = os.time(GetServerDateTime())
    if serverTime < endTradeTime then
        startTrade()
    else
        SetStartStop()
    end

    if isTrade then
        local index = DS:Size()
        local currentTradeDirection = getTradeDirection(CLOSE_BAR_SIGNAL == 1 and index-1 or index, calcAlgoValue, trend)
        if currentTradeDirection < 0 then
            CurrentDirect = 'SELL'
        else
            CurrentDirect = 'BUY'
        end
        if (OpenCount > 0 and currentTradeDirection == -1) or (OpenCount < 0 and currentTradeDirection == 1) then
            myLog(NAME_OF_STRATEGY..' CurrentDirect = '..CurrentDirect)
            myLog(NAME_OF_STRATEGY..' Открыта позиция против тренда, переворачиваем')
            ROBOT_STATE = 'ПЕРЕВОРОТ'
        end
        if OpenCount == 0 then
            ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
        end
    end

end

------------------------------------------
--Торговые сигналы

--Получение сигнала для открытия сделки: 1 - это покупки, -1 это продажи, 0 - это закрытие сделки
function getTradeSignal(index, calcAlgoValue, calcTrend)

    local signal = 0

    if calcTrend == nil then
        local signaltestvalue1 = calcAlgoValue[index-1] or DS:C(index)
        local signaltestvalue2 = calcAlgoValue[index-2] or DS:C(index)
        if signaltestvalue1 < DS:C(index-1) and signaltestvalue2 > DS:C(index-2) and DS:O(index) > calcAlgoValue[index] then
            signal = 1
        end
        if signaltestvalue1 > DS:C(index-1) and signaltestvalue2 < DS:C(index-2) and DS:O(index) < calcAlgoValue[index] then
            signal = -1
        end
    else
        local signaltestvalue1 = calcTrend[CLOSE_BAR_SIGNAL == 1 and index-1 or 'current'] or 0
        local signaltestvalue2 = calcTrend[CLOSE_BAR_SIGNAL == 1 and index-2 or 'last'] or 0
        if signaltestvalue1 > 0 and signaltestvalue2 <= 0 then --тренд сменился на растущий
            signal = 1
        end
        if signaltestvalue1 < 0 and signaltestvalue2 >= 0 then --тренд сменился на падающий
            signal = -1
        end
        if signaltestvalue1 > signaltestvalue2 and signaltestvalue2 > 0 then --тренд сменился на растущий
            signal = 'Добор'
        end
        if signaltestvalue1 < signaltestvalue2 and signaltestvalue2 < 0 then --тренд сменился на падающий
            signal = 'Добор'
        end
    end
    return signal
end

--Получение текущего направления торговли: calcTrend = 1 - это лонг, calcTrend = -1 это шорт, calcTrend = 0 - это вне позиции
function getTradeDirection(index, calcAlgoValue, calcTrend)

    local signal = 0

    if calcTrend == nil then
        local signaltestvalue = calcAlgoValue[index] or DS:C(index)
        if signaltestvalue < DS:C(index) then
            signal = 1
        end
        if signaltestvalue > DS:C(index) then
            signal = -1
        end
    else
        signal = calcTrend[CLOSE_BAR_SIGNAL == 1 and index or 'current']
    end
    return signal
end

--Поиск сигнала для открытия сделки в текущий момент времени, генерация команды роботу для выполнения сделки
local function getRealTimeTradeState()

    if isTrade then

        local index = DS:Size()
        calculateAlgo(index, Settings)

        if ChartId ~= nil then
            stv.UseNameSpace(ChartId)
            stv.SetVar('algoResults', calcChartResults)
        end

        local serverTime = os.time(GetServerDateTime())
        local dealTime = serverTime >= beginTrade

        -- В этом режиме trend имеет всего два элемента trend.current - текущее значение и trend.last - прошлое значение

        local tradeSignal = getTradeSignal(index, calcAlgoValue, trend)
        local currentTradeDirection = getTradeDirection(index, calcAlgoValue, trend)
        if not dealTime or os.time(DS:T(index)) == beginTrade then
            lastTradeDirection = currentTradeDirection
        end

        --myLog(NAME_OF_STRATEGY.." index: "..tostring(index).." - "..tostring(toYYYYMMDDHHMMSS(DS:T(index)))..", trend: "..tostring(trend.current)..", past trend: "..tostring(trend.last))
        --myLog(NAME_OF_STRATEGY.." dealTime: "..tostring(dealTime)..", tradeSignal: "..tostring(tradeSignal)..", lastTradeDirection: "..tostring(lastTradeDirection))

        if dealTime and (slIndex or 0) ~= 0 and (slIndex or 0)+2<=index then
            myLog(NAME_OF_STRATEGY.." тест после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex))..' '..tostring(workedStopPrice))
            if currentTradeDirection > 0 and workedStopPrice<DS:C(index-1) and workedStopPrice<DS:C(index-2) then
                myLog(NAME_OF_STRATEGY.." переоткрытие лонга после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
                lastTradeDirection = currentTradeDirection
                isitReopenAfterStop = true
            end
            if currentTradeDirection < 0 and workedStopPrice>DS:C(index-1) and workedStopPrice>DS:C(index-2) then
                myLog(NAME_OF_STRATEGY.." переоткрытие шорта после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
                lastTradeDirection = currentTradeDirection
                isitReopenAfterStop = true
            end
        end

        if trend ~= nil then
            if currentTradeDirection == 0 then
                CurrentDirect = "AUTO"
                ROBOT_STATE = 'CLOSEALL'
            end
        end

        if ROBOT_STATE == 'ПОИСК СДЕЛКИ' and dealTime and OpenCount <= 0 and (tradeSignal == 1 or lastTradeDirection == 1) then

            lastSignalIndex[#lastSignalIndex + 1] = index
            LastOpenBarIndex = index
            lastTradeDirection = 0

            --Переносим текущий тренд в прошлый, чтобы не срабатал сигнал заново
            trend.last = trend.current

            -- Задает направление НА ПОКУПКУ
            CurrentDirect = 'BUY'

            myLog(NAME_OF_STRATEGY..' CurrentDirect '..tostring(CurrentDirect)..' - '..toYYYYMMDDHHMMSS(DS:T(index)))
            SetState(ROBOT_STATE)

            -- Если по данному инструменту не запрещены операции шорт
			if isLong then
                if OpenCount < 0 then
                    ROBOT_STATE = 'ПЕРЕВОРОТ'
                else
                    ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
                end
            else
                ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
            end

        elseif ROBOT_STATE == 'ПОИСК СДЕЛКИ' and dealTime and OpenCount >= 0 and (tradeSignal == -1 or lastTradeDirection == -1) then

            lastSignalIndex[#lastSignalIndex + 1] = index
            LastOpenBarIndex = index
            lastTradeDirection = 0

            --Переносим текущий тренд в прошлый, чтобы не срабатал сигнал заново
            trend.last = trend.current

            CurrentDirect = 'SELL'
            myLog(NAME_OF_STRATEGY..' CurrentDirect '..tostring(CurrentDirect)..' - '..toYYYYMMDDHHMMSS(DS:T(index)))
            SetState(ROBOT_STATE)

            -- Если по данному инструменту не запрещены операции шорт
			if isShort then
                if OpenCount > 0 then
                    ROBOT_STATE = 'ПЕРЕВОРОТ'
                else
                    ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
                end
            else
                ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
            end
        elseif ROBOT_STATE == 'ПОИСК СДЕЛКИ' and dealTime and OpenCount >= 0 and (tradeSignal == 'Добор' or lastTradeDirection == -1) then

            lastSignalIndex[#lastSignalIndex + 1] = index
            LastOpenBarIndex = index
            lastTradeDirection = 0

            --Переносим текущий тренд в прошлый, чтобы не срабатал сигнал заново
            trend.last = trend.current

            CurrentDirect = OpenCount > 0 and 'BUY' or 'SELL'
            myLog(NAME_OF_STRATEGY..' CurrentDirect '..tostring(CurrentDirect)..' - '..toYYYYMMDDHHMMSS(DS:T(index)))
            SetState(ROBOT_STATE)

            -- Если по данному инструменту не запрещены операции шорт
			if isShort then
                if OpenCount > 0 then
                    ROBOT_STATE = 'ПЕРЕВОРОТ'
                else
                    ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
                end
            else
                ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
            end
        end

        if isTrade then
            local roundAlgoVal = round(calcAlgoValue[index], SCALE)
            SetAlgo(currentTradeDirection, roundAlgoVal)
        end

    end
end

--Поиск сигнала для открытия сделки по закрытым барам, генерация команды роботу для выполнения сделки
local function getCloseBarTradeState()

    local index = DS:Size() - 1
    if isTrade and index > lastCalculatedBar then

        while index > lastCalculatedBar do
            lastCalculatedBar = lastCalculatedBar + 1
            calculateAlgo(lastCalculatedBar, Settings)
        end

        myLog(NAME_OF_STRATEGY.." index: "..tostring(index).." - "..tostring(toYYYYMMDDHHMMSS(DS:T(index)))..", trend: "..tostring(trend[index]))
        --myLog(NAME_OF_STRATEGY..' lastCalculatedBar: '..tostring(lastCalculatedBar)..', LastOpenBarIndex: '..tostring(LastOpenBarIndex)..', calcAlgoValue[DS:Size()-1]: '..tostring(calcAlgoValue[DS:Size()-1])..', ATR[DS:Size()-1]: '..tostring(ATR[DS:Size()-1])..', kATR: '..tostring(kATR))

        lastCalculatedBar = index

        if ChartId ~= nil then
            stv.UseNameSpace(ChartId)
            --myLog('calcChartResults '..tostring(calcChartResults)..', calcChartResults[] '..tostring(calcChartResults[DS:Size()-1]))
            stv.SetVar('algoResults', calcChartResults)
        end

        local serverTime = os.time(GetServerDateTime())
        local dealTime = serverTime >= beginTrade

        local tradeSignal = getTradeSignal(DS:Size(), calcAlgoValue, trend)
        local currentTradeDirection = getTradeDirection(index, calcAlgoValue, trend)
        if not dealTime or os.time(DS:T(DS:Size())) == beginTrade then
            lastTradeDirection = currentTradeDirection
            -- slIndex = index
            -- wait_for_open = true
        end
        --myLog(NAME_OF_STRATEGY.." dealTime: "..tostring(dealTime)..", currentTradeDirection: "..tostring(currentTradeDirection)..", lastTradeDirection: "..tostring(lastTradeDirection)..", ROBOT_STATE: "..tostring(ROBOT_STATE))

        --if dealTime and reopenPosAfterStop~= 0 and (slIndex or 0) ~= 0 and (index - slIndex) == reopenPosAfterStop then
        if dealTime and ((slIndex or 0) ~= 0 and (index - slIndex) >= reopenPosAfterStop) or wait_for_open then
            --slIndex = index
            local spread        = round(DS:H(index)  - DS:L(index), SCALE)
            local close_up      = round((DS:C(index) - DS:L(index))/spread, SCALE) > 0.6
            local close_dw      = round((DS:H(index) - DS:C(index))/spread, SCALE) > 0.6

            myLog(NAME_OF_STRATEGY.." тест после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex))..' '..tostring(workedStopPrice))
            myLog(NAME_OF_STRATEGY.." C "..tostring(DS:C(index)).." C-1 "..tostring(DS:C(index-1)).." C-2 "..tostring(DS:C(index-2)).." C-3 "..tostring(DS:C(index-3)))
            --if currentTradeDirection > 0 and workedStopPrice<DS:O(index) then
            --if currentTradeDirection > 0 and workedStopPrice<DS:C(index-1) and workedStopPrice<DS:C(index-2) then
            if currentTradeDirection > 0 and DS:C(index-2)<DS:C(index) and DS:C(index-2)<DS:C(index-1) and DS:C(index-1)<DS:C(index) and DS:O(index-1)<DS:C(index-1) and DS:O(index)<DS:C(index) and close_up then
                myLog(NAME_OF_STRATEGY.." переоткрытие лонга после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
                lastTradeDirection = currentTradeDirection
                isitReopenAfterStop = true
                wait_for_open       = false
            end
            --if currentTradeDirection < 0 and workedStopPrice>DS:O(index) then
            --if currentTradeDirection < 0 and workedStopPrice>DS:C(index-1) and workedStopPrice>DS:C(index-2) then
            if currentTradeDirection < 0 and DS:C(index-2)>DS:C(index) and DS:C(index-2)>DS:C(index-1) and DS:C(index-1)>DS:C(index) and DS:O(index-1)>DS:C(index-1) and DS:O(index)>DS:C(index) and close_dw then
                myLog(NAME_OF_STRATEGY.." переоткрытие шорта после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
                lastTradeDirection = currentTradeDirection
                isitReopenAfterStop = true
                wait_for_open       = false
            end
        end

        if trend ~= nil then
            if currentTradeDirection == 0 then
                CurrentDirect = "AUTO"
                ROBOT_STATE = 'CLOSEALL'
            end
        end

        if index > LastOpenBarIndex and ROBOT_STATE == 'ПОИСК СДЕЛКИ' and dealTime and OpenCount <= 0 and (tradeSignal == 1 or lastTradeDirection == 1) then

            lastSignalIndex[#lastSignalIndex + 1] = index
            LastOpenBarIndex = index
            lastTradeDirection = 0

            -- Задает направление НА ПОКУПКУ
            CurrentDirect = 'BUY'

            myLog(NAME_OF_STRATEGY..' CurrentDirect '..tostring(CurrentDirect)..' - '..toYYYYMMDDHHMMSS(DS:T(DS:Size())))
            SetState(ROBOT_STATE)

            -- Если по данному инструменту не запрещены операции шорт
			if isLong then
                if OpenCount < 0 then
                    ROBOT_STATE = 'ПЕРЕВОРОТ'
                else
                    ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
                end
            else
                ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
            end

        elseif index > LastOpenBarIndex and ROBOT_STATE == 'ПОИСК СДЕЛКИ' and dealTime and OpenCount >= 0 and (tradeSignal == -1 or lastTradeDirection == -1) then

            lastSignalIndex[#lastSignalIndex + 1] = index
            LastOpenBarIndex = index
            lastTradeDirection = 0

            CurrentDirect = 'SELL'
            myLog(NAME_OF_STRATEGY..' CurrentDirect '..tostring(CurrentDirect)..' - '..toYYYYMMDDHHMMSS(DS:T(DS:Size())))
            SetState(ROBOT_STATE)

            -- Если по данному инструменту не запрещены операции шорт
			if isShort then
                if OpenCount > 0 then
                    ROBOT_STATE = 'ПЕРЕВОРОТ'
                else
                    ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
                end
            else
                ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
            end
        end

        if isTrade then
            local roundAlgoVal = round(calcAlgoValue[index], SCALE)
            SetAlgo(currentTradeDirection, roundAlgoVal)
        end

    end
end

--Вызов поиска очередного сигнала для открытия сделки
function getTradeState()

    if CLOSE_BAR_SIGNAL == 1 then
        getCloseBarTradeState()
    else
        getRealTimeTradeState()
    end
end

------------------------------------------
--Реакции на заявки

-- Функция вызывается терминалом QUIK при получении ответа на транзакцию пользователя
function OnTransReply(trans_reply)
    -- Если поступила информация по текущей транзакции
    if trans_reply.trans_id == trans_id then
       -- Передает сообщение в глобальную переменную
       trans_result_msg  = trans_reply.result_msg
       myLog('OnTransReply '..tostring(trans_id)..' '..trans_result_msg)
     end
end

-- Ожидает исполнения заявки по trans_id
function OnTrade(trade)

    if not VIRTUAL_TRADE and trade.sec_code == SEC_CODE and trade.class_code == CLASS_CODE and trade.price ~=0 then

        if countOrders[trade.trade_num] ~=nil and orderQnty==0 then return end
        myLog(NAME_OF_STRATEGY..' OnTrade сделка '..tostring(trade.trade_num)..' countOrders '..tostring(countOrders[trade.trade_num])..', trans_id '..tostring(trans_id)..', trade.trans_id '..tostring(trade.trans_id)..', количество '..tostring(trade.qty)..', осталось '..tostring(orderQnty)..', ROBOT_STATE '..tostring(ROBOT_STATE))
        countOrders[trade.trade_num] = {['price'] = trade.price, ['qty'] = trade.qty}

        if ROBOT_STATE == 'ОЖИДАНИЕ СДЕЛКИ' and trade.trans_id == trans_id then
            if bit.band(trade.flags,0x2)==0 and bit.band(trade.flags,0x1)==0 then
                orderQnty = orderQnty - trade.qty
                robotOpenCount = robotOpenCount + (bit.band(trade.flags,0x4)~=0 and -1 or 1)*trade.qty
                lastDealPrice = trade.price
                TRAILING_ACTIVATED = false
                stopLevelPrice = lastDealPrice
                TransactionPrice = trade.price
                priceMoveMax = TransactionPrice
                priceMoveMin = TransactionPrice
                TakeProfitPrice = 0
                myLog(NAME_OF_STRATEGY..' robot: Открыта сделка '..tostring(trade.trade_num)..' по ордеру '..tostring(trade.order_num)..', по цене '..tostring(lastDealPrice)..', количество '..tostring(trade.qty)..', осталось '..tostring(orderQnty))
            end
        elseif trackManualDeals then
            if bit.band(trade.flags,0x2)==0x0 and bit.band(trade.flags,0x1)==0x0 then
                lastDealPrice = trade.price
                stopLevelPrice = lastDealPrice
                TransactionPrice = trade.price
                priceMoveMax = TransactionPrice
                priceMoveMin = TransactionPrice
                TRAILING_ACTIVATED = false
                TakeProfitPrice = 0
                myLog(NAME_OF_STRATEGY..' robot: Открыта ручная сделка '..tostring(trade.trade_num)..' по ордеру '..tostring(trade.order_num)..', по цене '..tostring(lastDealPrice)..', количество '..tostring(trade.qty))
            end
        end
    end

end

-- создан/изменен/сработал стоп-ордер
function OnStopOrder(stopOrder)

    if stopOrder.sec_code == SEC_CODE and stopOrder.class_code == CLASS_CODE then

        -- Если не относится к роботу, выходит из функции
        if not trackManualDeals and stopOrder.brokerref:find(ROBOT_POSTFIX) == nil then return end

        local string state="_" -- состояние заявки
        --бит 0 (0x1) Заявка активна, иначе не активна
        if bit.band(stopOrder.flags,0x1)==0x1 then
            state="стоп-заявка создана"
            stop_order_num = stopOrder.order_num
        end
        if bit.band(stopOrder.flags,0x2)==0x1 or stopOrder.flags==26 then
            state="стоп-заявка снята"
        end
        if bit.band(stopOrder.flags,0x2)==0x0 and bit.band(stopOrder.flags,0x1)==0x0 then
            state="стоп-ордер исполнен"
            slIndex = DS:Size()
            workedStopPrice = stopOrder.price
            oldStop = 0
        end
        if bit.band(stopOrder.flags,0x400)==0x1 then
            state="стоп-заявка сработала, но была отвергнута торговой системой"
        end
        if bit.band(stopOrder.flags,0x800)==0x1 then
            state="стоп-заявка сработала, но не прошла контроль лимитов"
        end
        if state=="_" then
            state="Набор битовых флагов="..tostring(stopOrder.flags)
        end

        --myLog(NAME_OF_STRATEGY.." OnStopOrder(): sec_code="..stopOrder.sec_code.." - "..state.."; condition_price="..stopOrder.condition_price.."; transID="..stopOrder.trans_id.."; order_num="..stopOrder.order_num)

        isStopOrderSet(true)
    end

end

--Проверка наличия стор заявки для текущей позиции
function isStopOrderSet(getStopPrice)

    if VIRTUAL_TRADE then
        return slPrice~=0 or tpPrice~=0
    end

    function myFind(C,S,F,B)
        return (C == CLASS_CODE) and (S == SEC_CODE) and (bit.band(F, 0x1) ~= 0) and ((not trackManualDeals and B:find(ROBOT_POSTFIX)) or trackManualDeals)
    end
    local ord = "stop_orders"
    local orders = SearchItems(ord, 0, getNumberOf(ord)-1, myFind, "class_code,sec_code,flags,brokerref")

    if (orders ~= nil) and (#orders > 0) then
        if getStopPrice == true then
            local stop_order = getItem(ord, orders[#orders])
            if stop_order ~= nil and type(stop_order) == "table" then
                local tpPrice = stop_order.condition_price
                local slPrice = stop_order.condition_price2
                if stop_order.stop_order_type == 1 then
                    slPrice = stop_order.condition_price
                    tpPrice = 0
                elseif stop_order.stop_order_type == 6 then
                    tpPrice = stop_order.condition_price
                    slPrice = 0
                end
                SetSL_TP(slPrice, tpPrice)

                stop_order_num = stop_order.order_num
                TakeProfitPrice = tpPrice
                myLog(NAME_OF_STRATEGY..' Найдена стоп-заявка по на позицю '..stop_order.sec_code..' number: '..tostring(stop_order_num)..' stop_order_type: '..tostring(stop_order.stop_order_type)..' stop_order.qty: '..tostring(stop_order.qty)..' stop_order.brokerref: '..tostring(stop_order.brokerref))
                myLog(NAME_OF_STRATEGY..' STOP LOSS: '..tostring(slPrice)..' TAKE PROFIT: '..tostring(tpPrice))
            end
        end
        return true
    end

    SetSL_TP(0, 0)

    return false

end

--Если выставлен или снят руками лимитный отрдер, проверим состояние лимитного ордера тейк-профит 1
function OnOrder(order)

    if order.sec_code == SEC_CODE and order.class_code == CLASS_CODE then

        if order.order_num == order_num and bit.band(order.flags,0x2)==0x0 and bit.band(order.flags,0x1)==0x0 then
            --ордер исполнен
            myLog(NAME_OF_STRATEGY..' Исполнена лимитная заявка по '..order.sec_code..' number: '..tostring(order.order_num)..' order.price: '..tostring(order.price))
        elseif order.order_num == order_num and bit.band(order.flags,0x2)~=0x0 and bit.band(order.flags,0x1)==0x0 then
            --ордер снят пользователем
            myLog(NAME_OF_STRATEGY..' Снята лимитная заявка по '..order.sec_code..' number: '..tostring(order.order_num)..' order.price: '..tostring(order.price))
        elseif order.order_num ~= order_num and bit.band(order.flags,0x1)==0x0 and (OpenCount == 0 or OpenCount>0 and bit.band(order.flags,0x4)==0 or OpenCount<0 and bit.band(order.flags,0x4)~=0) then
            myLog(NAME_OF_STRATEGY..' Снята/Исполнена лимитная заявка входа в позицию по '..order.sec_code..' number: '..tostring(order.order_num)..' order.price: '..tostring(order.price))
        else
            isOrderSet(true)
        end

    end
end

--Есть ли установленный лимитный ордер
function isOrderSet(getOrderPrice)

    function myFind(C,S,F,B)
        return (C == CLASS_CODE) and (S == SEC_CODE) and (bit.band(F, 0x1) ~= 0) and (OpenCount==0 or (OpenCount>0 and bit.band(F,0x4)~=0 or OpenCount<0 and bit.band(F,0x4)==0)) and ((not trackManualDeals and B:find(ROBOT_POSTFIX)) or trackManualDeals)
    end
    local ord = "orders"
    local orders = SearchItems(ord, 0, getNumberOf(ord)-1, myFind, "class_code,sec_code,flags,brokerref")
    if (orders ~= nil) and (#orders > 0) then
        if getOrderPrice == true then
            --берем только последнюю активную
            -- получаем параметры заявки
            local order = getItem(ord, orders[#orders])
            if order ~= nil and type(order) == "table" then
                order_price = order.price
                order_num  = order.order_num
                order_qty  = order.balance
                order_type  = bit.band(order.flags,0x4)==0 and 'BUY' or 'SELL'
                myLog(NAME_OF_STRATEGY..' Найдена лимитная заявка по '..order.sec_code..' number: '..tostring(order.order_num)..' order.qty: '..tostring(order.qty)..' order.price: '..tostring(order.price))
            end
        end
        return true
    end

    order_num = 0
    order_price = 0
    order_qty = 0
    order_type = nil

    return false

end

-----------------------------
-- ОСНОВНЫЕ ФУНКЦИИ ТОРГОВЛИ--
-----------------------------

-- Возвращает корректную цену для рыночной заявки закрытия позиции по текущему инструменту (принимает 'SELL',или 'BUY' и уровень цены)
-- Фунция возвращает цену в обратном направлении от Типа.
-- Если передано BUY, то функция вернет цену для закрытия позиции
-- Если надо наоборот набрать позицию, то необходимо передавать тип, обратный набираемой позиции
function GetPriceForMarketOrder(Type, level_price)

    -- Пытается получить максимально возможную цену для инструмента
    local PriceMax = tonumber(getParamEx(CLASS_CODE,  SEC_CODE, 'PRICEMAX').param_value)
    -- Пытается получить минимально возможную цену для инструмента
    local PriceMin = tonumber(getParamEx(CLASS_CODE,  SEC_CODE, 'PRICEMIN').param_value)

    --Берем лучшую цену из стакана
    if level_price==nil then
        if Type == 'SELL' then
            level_price = tonumber(getParamEx(CLASS_CODE, SEC_CODE, 'offer').param_value or 0)
        else
            level_price = tonumber(getParamEx(CLASS_CODE, SEC_CODE, 'bid').param_value or 0)
        end
    end

    -- Получает цену последней сделки, если не задано
    level_price = level_price or tonumber(getParamEx(CLASS_CODE,  SEC_CODE, 'LAST').param_value)

    myLog(NAME_OF_STRATEGY..' GetPriceForMarketOrder level_price: '..tostring(level_price))
    if Type == 'SELL' then
        -- по цене, завышенной на MARKET_PRICE_OFFSET мин. шагов цены
        local price = level_price + MARKET_PRICE_OFFSET*SEC_PRICE_STEP
        if level_price == 0 or (PriceMax ~= nil and PriceMax ~= 0 and price > PriceMax) then
           price = PriceMax-1*SEC_PRICE_STEP
        end
        return price
    else
        -- по цене, заниженной на MARKET_PRICE_OFFSET мин. шагов цены
        local price = level_price - MARKET_PRICE_OFFSET*SEC_PRICE_STEP
        if level_price == 0 or (PriceMin ~= nil and PriceMin ~= 0 and price < PriceMin) then
           price = PriceMin+1*SEC_PRICE_STEP
        end
        return price
    end

end

--Получает цену открытия заявки, приведенной к шагу цены инструмента
function GetCorrectPrice(price) -- STRING
    -- Получает точность цены по инструменту
    -- Получает минимальный шаг цены инструмента
    local PriceStep = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value)
    -- Если после запятой должны быть цифры
    if SCALE > 0 then
       price = tostring(price)
       -- Ищет в числе позицию запятой, или точки
       local dot_pos = price:find('.')
       local comma_pos = price:find(',')
       -- Если передано целое число
       if dot_pos == nil and comma_pos == nil then
          -- Добавляет к числу ',' и необходимое количество нулей и возвращает результат
          price = price..','
          for i=1,SCALE do price = price..'0' end
          return price
       else -- передано вещественное число
          -- Если нужно, заменяет запятую на точку
          if comma_pos ~= nil then price:gsub(',', '.') end
          -- Округляет число до необходимого количества знаков после запятой
          price = round(tonumber(price), SCALE)
          -- Корректирует на соответствие шагу цены
          price = round(price/PriceStep)*PriceStep
          price = string.gsub(tostring(price),'[%.]+', ',')
          return price
       end
    else -- После запятой не должно быть цифр
       -- Корректирует на соответствие шагу цены
       price = round(price/PriceStep)*PriceStep
       return tostring(math.floor(price))
    end
end

--Поиск ордера в таблице заявок по trans_id
function findOrderOnTransID(ord, TransID)
    function myFind(C,S,F,B,T)
        return C == CLASS_CODE and S == SEC_CODE and bit.band(F, 0x1) ~= 0 and B:find(ROBOT_POSTFIX) and T == TransID
    end
    ord = ord or "orders"
    local orders = SearchItems(ord, 0, getNumberOf(ord)-1, myFind, "class_code,sec_code,flags,brokerref,trans_id")
    if (orders ~= nil) and (#orders > 0) then
        local order = getItem(ord, orders[#orders])
        if order ~= nil and type(order) == "table" then
            return order
        end
    end
    return false
end

--Виртуальное совершение сделки
function VirtualTrade(Type, qty)

    local openLong = nil
    local closeLong = nil
    local openShort = nil
    local closeShort = nil

    local dealPrice = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)

    if getDOMPrice then
        if Type == 'BUY' then
            dealPrice = round(tonumber(getParamEx(CLASS_CODE, SEC_CODE, 'offer').param_value), SCALE)
        else
            dealPrice = round(tonumber(getParamEx(CLASS_CODE, SEC_CODE, 'bid').param_value), SCALE)
        end
    end

    myLog(NAME_OF_STRATEGY.." OpenCount before "..tostring(OpenCount))
    myLog(NAME_OF_STRATEGY.." lastDealPrice "..tostring(vlastDealPrice).." dealPrice "..tostring(dealPrice))

    if Type == 'BUY' then
        if OpenCount < 0 then
            vdealProfit = -round(vlastDealPrice - dealPrice, 5)*OpenCount/priceKoeff
            vlastDealPrice = dealPrice
        elseif OpenCount > 0 then
            vlastDealPrice = (vlastDealPrice + dealPrice)/2
        else
            vlastDealPrice = dealPrice
        end
        if isLong and OpenCount == 0 then
            openLong = dealPrice
        else
            closeShort = dealPrice
        end
        OpenCount = OpenCount + qty
    else
        if OpenCount > 0 then
            vdealProfit = round(dealPrice-vlastDealPrice, 5)*OpenCount/priceKoeff
            vlastDealPrice = dealPrice
        elseif OpenCount < 0 then
            vlastDealPrice = (vlastDealPrice + dealPrice)/2
        else
            vlastDealPrice = dealPrice
        end
        if isShort and OpenCount == 0 then
            openShort = dealPrice
        else
            closeLong = dealPrice
        end
        OpenCount = OpenCount - qty
    end

    vallProfit = round(vallProfit + vdealProfit, SCALE)
    SetAllProfit(vallProfit)

    myLog(NAME_OF_STRATEGY.." dealProfit "..tostring(vdealProfit).." OpenCount after "..tostring(OpenCount))

    --vlastDealPrice = dealPrice
    if OpenCount == 0 then
        vlastDealPrice = 0
        SetDealProfit(0)
    end
    SetPos(OpenCount, vlastDealPrice)

    vdealProfit = 0
    TransactionPrice = dealPrice
    priceMoveMax = TransactionPrice
    priceMoveMin = TransactionPrice
    lastDealPrice = vlastDealPrice
    stopLevelPrice = lastDealPrice
    curOpenCount = OpenCount

    addDeal(openLong, openShort, closeLong, closeShort, DS:T(DS:Size()))
    ROBOT_STATE = 'УСТАНОВКА СТОП ЛОССА'
    return dealPrice
end

-- Совершает РЫНОЧНУЮ СДЕЛКУ указанного типа (Type) ["BUY", или "SELL"] по рыночной(текущей) цене размером в qty лот,
--- возвращает цену открытой сделки, либо FALSE, если невозможно открыть сделку
function MarketTrade(Type, qty)

    local can_trade, state = CheckTradeSession()
    if not can_trade then
        myLog(NAME_OF_STRATEGY..' '..tostring(state)..'. Установка заявок невозможна.')
        message(NAME_OF_STRATEGY..' '..tostring(state)..'. Установка заявок невозможна.',3)
        return nil
    end

    slIndex = 0
    workedStopPrice = 0
    lastStopShiftIndex = 0
    slPrice = 0
    oldStop = 0
    tpPrice = 0
    TakeProfitPrice = 0
    TRAILING_ACTIVATED = false

    if VIRTUAL_TRADE then
        return VirtualTrade(Type, qty)
    end

    --Получает ID транзакции
    trans_id = trans_id + 1
    local Price = 0
    local Operation = ''
    --Устанавливает цену и операцию, в зависимости от типа сделки и от класса инструмента
    if Type == 'BUY' then
       if CLASS_CODE ~= 'QJSIM' and CLASS_CODE ~= 'TQBR' then -- по цене, завышенной на 10 мин. шагов цены
            Price = GetPriceForMarketOrder('SELL')
        end
       Operation = 'B'
    else
       if CLASS_CODE ~= 'QJSIM' and CLASS_CODE ~= 'TQBR' then -- по цене, заниженной на 10 мин. шагов цены
            Price = GetPriceForMarketOrder('BUY')
        end
       Operation = 'S'
    end

    local index = DS:Size()
    -- Заполняет структуру для отправки транзакции
    myLog(NAME_OF_STRATEGY..' robot: Transaction '..Type..' '..tostring(DS:C(index)).." qnty: "..tostring(qty).." trans id: "..tostring(trans_id))

    local Transaction={
       ['TRANS_ID']   = tostring(trans_id),
       ['ACTION']     = 'NEW_ORDER',
       ['CLASSCODE']  = CLASS_CODE,
       ['SECCODE']    = SEC_CODE,
       ['CLIENT_CODE'] = CLIENT_CODE, -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках
       ['OPERATION']  = Operation, -- операция ("B" - buy, или "S" - sell)
       ['TYPE']       = 'M', -- по рынку (MARKET)
       ['QUANTITY']   = tostring(qty), -- количество
       ['ACCOUNT']    = ACCOUNT,
       ['PRICE']      = tostring(Price),
       ['COMMENT']    = NAME_OF_STRATEGY..' robot'
    }

    ROBOT_STATE = 'ОЖИДАНИЕ СДЕЛКИ'
    orderQnty = qty
    lastDealPrice = 0
    stopLevelPrice = lastDealPrice

    -- Отправляет транзакцию
    local res = sendTransaction(Transaction)
    if string.len(res) ~= 0 then
        message(NAME_OF_STRATEGY..' robot: Транзакция вернула ошибку: '..res)
        myLog(NAME_OF_STRATEGY..' robot: Транзакция вернула ошибку: '..res)
        orderQnty = 0
        return false
    end

    return true

end

-- Выставляет лимитную заявку
-- price,      -- Цена заявки
-- Type - операция ('BUY', 'SELL') -- текущее направление позиции которую надо открыть
-- qty         -- Количество
function SetOrder(price, Type, qty)

    local can_trade, state = CheckTradeSession()
    if not can_trade then
        myLog(NAME_OF_STRATEGY..' '..tostring(state)..'. Установка заявок невозможна.')
        message(NAME_OF_STRATEGY..' '..tostring(state)..'. Установка заявок невозможна.',3)
        return nil
    end

    if qty<0 then qty = -qty end

	local operation = Type == 'BUY' and 'B' or 'S'

    myLog(NAME_OF_STRATEGY..' Установка ордера, позиция '..Type..' qty '..tostring(qty)..', по цене: '..tostring(price))

    local transClientCode = ROBOT_CLIENT_CODE
    if CLASS_CODE == 'QJSIM' or CLASS_CODE == 'TQBR' then
        transClientCode = ROBOT_POSTFIX..tostring(DEAL_COUNTER) --Строка комментаия в заявках, сделках
    end

    -- Выставляет заявку
    -- Получает ID для следующей транзакции
    trans_id = trans_id + 1
    -- Заполняет структуру для отправки транзакции
    local T = {}
    T['TRANS_ID']       = tostring(trans_id)     -- Номер транзакции
    T['ACCOUNT']        = ACCOUNT                -- Код счета
    T['CLASSCODE']      = CLASS_CODE             -- Код класса
    T['SECCODE']        = SEC_CODE               -- Код инструмента
    T['CLIENT_CODE']    = transClientCode        -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках
    T['ACTION']         = 'NEW_ORDER'            -- Тип транзакции ('NEW_ORDER' - новая заявка)
    T['TYPE']           = 'L'                    -- Тип ('L' - лимитированная, 'M' - рыночная)
    T['OPERATION']      = operation              -- Операция ('B' - buy, или 'S' - sell)
    T['PRICE']          = GetCorrectPrice(price) -- Цена
    T['QUANTITY']       = tostring(qty)          -- Количество
    T["COMMENT"]        = NAME_OF_STRATEGY

    -- Отправляет транзакцию
    local res = sendTransaction(T)
    -- Если при отправке транзакции возникла ошибка
    if res ~= '' then
       -- Выводит сообщение об ошибке
        message(NAME_OF_STRATEGY..' Ошибка выставления лимитной заявки: '..res,3)
        myLog(NAME_OF_STRATEGY..' Ошибка выставления лимитной заявки: '..res)
        isTrade = false
        SetStartStop()
        return nil
    end

    -- Ищет заявку в таблице заявок, возвращает истина
    -- Ожидает 10 сек. макс.
    local start_sec = os.time()
    while isRun and os.time() - start_sec < 10 do
        local num = getNumberOf('orders')
        if num ~= 0 then
            if num > 1 then
                for i = num - 1, 0, -1 do
                    local order = getItem('orders', i)
                    if type(order) == 'table' and order.order_num ~= nil and order.trans_id ~= nil and order.sec_code ~= nil
                    and order.price ~= nil and order.price ~= 0 and order.qty ~= nil and order.qty ~= 0 and order.balance ~= nil then
                        if order.sec_code == SEC_CODE and order.trans_id == trans_id then
                            order.index = i
                            return order
                        end
                    end
                end
            else
                local order = getItem('orders', 0)
                if type(order) == 'table' and order.order_num ~= nil and order.trans_id ~= nil and order.sec_code ~= nil
                and order.price ~= nil and order.price ~= 0 and order.qty ~= nil and order.qty ~= 0 and order.balance ~= nil then
                    if order.sec_code == SEC_CODE and order.trans_id == trans_id then
                        order.index = 0
                        return order
                    end
                end
            end
        end
        sleep(100)
    end

    message(NAME_OF_STRATEGY..' Возникла неизвестная ошибка при выставлении лимитной заявки по транзакции: '..tostring(trans_id),3)
    myLog(NAME_OF_STRATEGY..' Возникла неизвестная ошибка при выставлении лимитной заявки по транзакции: '..tostring(trans_id))

    return nil

end

--Расччитывает уровни стоп-лосса, тейк-профита, цены выставления стоп-заявки
function getSLTP_Price(AtPrice, Type, qty, fixed)

	local tp_stopprice = 0 -- Цена Тейк-Профита
    local sl_stopprice = 0 -- Цена Стоп-Лосса
    local stopprice = 0 -- Цена выставления

    fixed = fixed or false

    --local index = CorrectBarIndex(DS:Size())
    local index = DS:Size()

	myLog(NAME_OF_STRATEGY..' AtPrice '..tostring(AtPrice)..' Algo '..tostring(calcAlgoValue[index-1])..', TAKE_PROFIT: '..tostring(TAKE_PROFIT)..' STOP_LOSS: '..tostring(STOP_LOSS))
	--myLog(NAME_OF_STRATEGY..' index '..tostring(index)..' calcAlgoValue[index-1] '..tostring(calcAlgoValue[index-1])..', ATR[index-1]: '..tostring(ATR[index-1])..' ATRfactor: '..tostring(ATRfactor))

    --if isTrade then calculateAlgo(index, Settings) end
	myLog(NAME_OF_STRATEGY..' oldStop '..tostring(oldStop)..', priceMoveVal '..tostring(priceMoveVal)..', oldTakeProfitPrice: '..tostring(TakeProfitPrice)..', isPriceMove: '..tostring(isPriceMove))
	myLog(NAME_OF_STRATEGY..' PRICEMIN '..tostring(getParamEx(CLASS_CODE, SEC_CODE, 'PRICEMIN').param_value)..', PRICEMAX: '..tostring(getParamEx(CLASS_CODE, SEC_CODE, 'PRICEMAX').param_value))

    -- Если открыт BUY
	if Type == 'BUY' then
        if TAKE_PROFIT~=0 then
            if TakeProfitPrice == 0 then
                tp_stopprice	= round(AtPrice + TAKE_PROFIT*priceKoeff, SCALE) -- Уровень цены, когда активируется Тейк-профит
            elseif isPriceMove and shiftProfit then
                --tp_stopprice = round(TakeProfitPrice + (TRAILING_ACTIVATED and priceMoveVal or STOP_LOSS)*priceKoeff/2, SCALE)    -- немного сдвигаем тейк-профит
                tp_stopprice = round(TakeProfitPrice + priceMoveVal/2, SCALE)    -- немного сдвигаем тейк-профит
            else tp_stopprice = TakeProfitPrice
            end
        end
        if STOP_LOSS~=0 then
            if shiftStop or oldStop == 0 then
                if isTrade and not fixed then
                    local slPrice = AtPrice
                    -- local slPrice = CLOSE_BAR_SIGNAL == 1 and calcAlgoValue[index-1] or calcAlgoValue[index]
                    local shiftSL = (kATR*ATR[index-1] + SL_ADD_STEPS*SEC_PRICE_STEP)
                    if (slPrice - shiftSL) >= AtPrice then
                        slPrice = AtPrice
                    end
                    local nonLosePrice = round(lastDealPrice + 0*SEC_PRICE_STEP, SCALE)
                    if isPriceMove and oldStop then
                        -- sl_stopprice	= math.max(round(slPrice - shiftSL, SCALE), nonLosePrice) -- Уровень цены, когда активируется Стоп-лосс
                        -- sl_stopprice	= math.max(round(oldStop + priceMoveVal, SCALE), nonLosePrice) -- Уровень цены, когда активируется Стоп-лосс
                        sl_stopprice	= round(oldStop + priceMoveVal, SCALE) -- Уровень цены, когда активируется Стоп-лосс
                        myLog('isPriceMove sl_stopprice '..tostring(sl_stopprice))
                    else
                        sl_stopprice	= round(slPrice - shiftSL, SCALE) -- Уровень цены, когда активируется Стоп-лосс
                    end
                    if isitReopenAfterStop then dealMaxStop = reopenDealMaxStop else dealMaxStop = maxStop end
                    if (lastDealPrice - sl_stopprice) > dealMaxStop*priceKoeff then sl_stopprice = lastDealPrice - dealMaxStop*priceKoeff end
                    myLog('calculated shiftSL '..tostring(shiftSL)..' slPrice '..tostring(slPrice)..', sl_stopprice: '..tostring(sl_stopprice))
                    isitReopenAfterStop = false
                else
                    if isPriceMove and oldStop then
                        sl_stopprice	= round(oldStop + priceMoveVal, SCALE) -- Уровень цены, когда активируется Стоп-лосс
                        myLog('isPriceMove sl_stopprice '..tostring(sl_stopprice))
                    elseif oldStop~=0 then
                        sl_stopprice	= lastDealPrice
                    else
                        sl_stopprice	= round(AtPrice - STOP_LOSS*priceKoeff, SCALE) -- Уровень цены, когда активируется Стоп-лосс
                    end
                end
            else
                sl_stopprice = oldStop
            end

            if oldStop~=0 then
                -- sl_stopprice = math.max(lastDealPrice + 0*SEC_PRICE_STEP, sl_stopprice)
                sl_stopprice = math.max(oldStop, sl_stopprice)
            end
            --sl_stopprice = not fixed and math.min(sl_stopprice, DS:L(index)) or sl_stopprice

            myLog(NAME_OF_STRATEGY..' oldStop '..tostring(oldStop)..', sl_stopprice: '..tostring(sl_stopprice)..', DS:L(index): '..tostring(DS:L(index)))
        end
	else -- открыт SELL

        if TAKE_PROFIT~=0 then
            if TakeProfitPrice == 0 then
                tp_stopprice	= round(AtPrice - TAKE_PROFIT*priceKoeff, SCALE) -- Уровень цены, когда активируется Тейк-профит
            elseif isPriceMove and shiftProfit then
                --tp_stopprice = round(TakeProfitPrice - (TRAILING_ACTIVATED and priceMoveVal or STOP_LOSS)*priceKoeff/2, SCALE)  -- немного сдвигаем тейк-профит
                tp_stopprice = round(TakeProfitPrice - priceMoveVal/2, SCALE)  -- немного сдвигаем тейк-профит
            else tp_stopprice = TakeProfitPrice
            end
        end
        if STOP_LOSS~=0 then
            if shiftStop or oldStop == 0 then
                if isTrade and not fixed then
                    -- local slPrice = CLOSE_BAR_SIGNAL == 1 and calcAlgoValue[index-1] or calcAlgoValue[index]
                    local slPrice = AtPrice
                    local shiftSL = (kATR*ATR[index-1] + SL_ADD_STEPS*SEC_PRICE_STEP)
                    if (slPrice + shiftSL) <= AtPrice then
                        slPrice = AtPrice
                    end
                    local nonLosePrice = round(lastDealPrice - 0*SEC_PRICE_STEP, SCALE)
                    if isPriceMove and oldStop then
                        -- sl_stopprice	= math.min(round(slPrice + shiftSL, SCALE), nonLosePrice) -- Уровень цены, когда активируется Стоп-лосс
                        --sl_stopprice	= math.min(round(oldStop - priceMoveVal, SCALE), nonLosePrice) -- Уровень цены, когда активируется Стоп-лосс
                        sl_stopprice	= round(oldStop - priceMoveVal, SCALE) -- Уровень цены, когда активируется Стоп-лосс
                        myLog('isPriceMove sl_stopprice '..tostring(sl_stopprice))
                    else
                        sl_stopprice	= round(slPrice + shiftSL, SCALE) -- Уровень цены, когда активируется Стоп-лосс
                    end
                    if isitReopenAfterStop then dealMaxStop = reopenDealMaxStop else dealMaxStop = maxStop end
                    if (sl_stopprice - lastDealPrice) > dealMaxStop*priceKoeff then sl_stopprice = lastDealPrice + dealMaxStop*priceKoeff end
                    myLog('calculated shiftSL '..tostring(shiftSL)..' slPrice '..tostring(slPrice)..' sl_stopprice '..tostring(sl_stopprice))
                    isitReopenAfterStop = false
                else
                    if isPriceMove and oldStop then
                        sl_stopprice	= round(oldStop - priceMoveVal, SCALE) -- Уровень цены, когда активируется Стоп-лосс
                        myLog('isPriceMove sl_stopprice '..tostring(sl_stopprice))
                    elseif oldStop~=0 then
                        sl_stopprice	= lastDealPrice
                    else
                        sl_stopprice	= round(AtPrice + STOP_LOSS*priceKoeff, SCALE) -- Уровень цены, когда активируется Стоп-лосс
                    end
                end
            else
                sl_stopprice = oldStop
            end

            if oldStop~=0 then
                -- sl_stopprice = math.min(lastDealPrice - 0*SEC_PRICE_STEP, sl_stopprice)
                sl_stopprice = math.min(oldStop, sl_stopprice)
            end
            --sl_stopprice = not fixed and math.max(sl_stopprice, DS:H(index)) or sl_stopprice

            myLog(NAME_OF_STRATEGY..' oldStop '..tostring(oldStop)..', sl_stopprice: '..tostring(sl_stopprice)..', DS:H(index): '..tostring(DS:H(index)))
        end
    end

    -- Получает максимально возможную цену заявки
    local PriceMax = tonumber(getParamEx(CLASS_CODE,  SEC_CODE, 'PRICEMAX').param_value)
    -- Получает минимально возможную цену заявки
    local PriceMin = tonumber(getParamEx(CLASS_CODE,  SEC_CODE, 'PRICEMIN').param_value)

    if Type == 'BUY' then
        if PriceMin ~= nil and PriceMin ~= 0 and sl_stopprice < PriceMin then
            sl_stopprice = PriceMin
        end
        if PriceMax ~= nil and PriceMax ~= 0 and tp_stopprice > PriceMax then
            tp_stopprice = PriceMax
        end
    elseif Type == 'SELL' then
        if PriceMax ~= nil and PriceMax ~= 0 and sl_stopprice > PriceMax then
            sl_stopprice = PriceMax
        end
        if PriceMin ~= nil and PriceMin ~= 0 and tp_stopprice < PriceMin then
            tp_stopprice = PriceMin
        end
    end


    TakeProfitPrice = tp_stopprice
    priceMoveVal = 0
    isPriceMove = false

    --Получаем цену исполнения стоп ордера, после активации
    stopprice = GetPriceForMarketOrder(Type, sl_stopprice)

    return tp_stopprice, sl_stopprice, stopprice

end

-- Выставляет СТОП-ЛОСС и ТЕЙК-ПРОФИТ
--- возвращает FALSE, если не удалось выставить СТОП-ЛОСС и ТЕЙК-ПРОФИТ
-- AtPrice - таблица с параметрами стоп заявки
-- Type - операция ('BUY', 'SELL') -- текущее направление позиции на которую надо открыть стоп-ордер
-- qty - Количество
function SL_TP(AtPrice, Type, qty)

    local can_trade, state = CheckTradeSession()
    if not can_trade then
        myLog(NAME_OF_STRATEGY..' '..tostring(state)..'. Установка заявок невозможна.')
        message(NAME_OF_STRATEGY..' '..tostring(state)..'. Установка заявок невозможна.',3)
        return nil
    end

	if manualKillStop then
        return true
    end

    -- ID транзакции
    trans_id = trans_id + 1

    local index = DS:Size()

    lastDealPrice = maintable:GetValue('Pos')
    lastStopShiftIndex = index
    if qty < 0 then qty = -qty end

	-- Находит направление для заявки
	local operation = ""
	local price = "0" -- Цена, по которой выставится заявка при срабатывании Стоп-Лосса (для рыночной заявки по акциям должна быть 0)
	local market = "NO" -- После срабатывания Тейка, или Стопа, заявка сработает по рыночной цене
	local direction

    -- Если открыт BUY, то направление стоп-лосса и тейк-профита SELL, иначе направление стоп-лосса и тейк-профита BUY
	if Type == 'BUY' then
		operation = "S" -- Тейк-профит и Стоп-лосс на продажу(чтобы закрыть BUY, нужно открыть SELL)
        direction = "5" -- Направленность стоп-цены. «5» - больше или равно
	else -- открыт SELL
		operation = "B" -- Тейк-профит и Стоп-лосс на покупку(чтобы закрыть SELL, нужно открыть BUY)
		direction = "4" -- Направленность стоп-цены. «4» - меньше или равно
    end

    local EXPIRY_DATE = os.date("%Y%m%d", os.time() + 29*60*60*24) --"TODAY", "GTC"

    local tp_Price, sl_Price, price = 0, 0, 0
    local offset = OFFSET
    local spread = SPREAD

    if type(AtPrice) == 'table' then
        tp_Price = AtPrice.tp_Price or 0
        sl_Price = AtPrice.sl_Price or 0
        price    = AtPrice.price or 0
        offset   = AtPrice.offset or offset
        spread   = AtPrice.spread or spread
        EXPIRY_DATE   = AtPrice.expiry or EXPIRY_DATE
    else
        tp_Price, sl_Price, price = getSLTP_Price(AtPrice, Type, qty, fixedstop)
    end

    -- Заполняет структуру для отправки транзакции на Стоп-лосс и Тейк-профит

    local STOP_ORDER_KIND     = "TAKE_PROFIT_AND_STOP_LIMIT_ORDER"
    if tp_Price~=0 and sl_Price == 0 then
        STOP_ORDER_KIND     = "TAKE_PROFIT_STOP_ORDER"
    elseif tp_Price==0 and sl_Price ~= 0 then
        STOP_ORDER_KIND     = "SIMPLE_STOP_ORDER"
    end

    sl_Price = GetCorrectPrice(sl_Price)
    tp_Price = GetCorrectPrice(tp_Price)
    price    = GetCorrectPrice(price)

    --myLog(NAME_OF_STRATEGY..' Установка ТЕЙК-ПРОФИТ: '..tp_Price..' и СТОП-ЛОСС: '..sl_Price)

    myLog(NAME_OF_STRATEGY..' robot: '..' index '..tostring(index)..' lastDealPrice '..tostring(lastDealPrice)..' AlgoVal '..tostring(calcAlgoValue[index-1])..', ATR: '..tostring(ATR[index-1]))
    myLog(NAME_OF_STRATEGY..' robot: стоп '..STOP_ORDER_KIND..', сделка '..' на объем '..tostring(qty)..', Установка ТЕЙК-ПРОФИТ: '..tp_Price..' и СТОП-ЛОСС: '..sl_Price..' ЦЕНА выставления: '..tostring(price)..' offset: '..tostring(offset)..' spread: '..tostring(spread)..' EXPIRY_DATE '..tostring(EXPIRY_DATE))

    if VIRTUAL_TRADE then
        local slPrice = string.gsub(sl_Price,'[,]+', '.')
        local tpPrice = string.gsub(tp_Price,'[,]+', '.')
        tpPrice = tonumber(tpPrice)
        slPrice = tonumber(slPrice)
        SetSL_TP(slPrice, tpPrice)
        return true
    end

    local transClientCode = ROBOT_CLIENT_CODE
    if CLASS_CODE == 'QJSIM' or CLASS_CODE == 'TQBR' then
        transClientCode = ROBOT_POSTFIX..tostring(DEAL_COUNTER) --Строка комментаия в заявках, сделках
    end

	local Transaction = {
		["ACTION"]              = "NEW_STOP_ORDER", -- Тип заявки
		["TRANS_ID"]            = tostring(trans_id),
		["CLASSCODE"]           = CLASS_CODE,
		["SECCODE"]             = SEC_CODE,
		["ACCOUNT"]             = ACCOUNT,
        ['CLIENT_CODE']         = transClientCode, -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках
		["OPERATION"]           = operation, -- Операция ("B" - покупка(BUY), "S" - продажа(SELL))
		["QUANTITY"]            = tostring(qty), -- Количество в лотах
		["EXPIRY_DATE"]         = EXPIRY_DATE, -- Срок действия стоп-заявки ("GTC" – до отмены,"TODAY" - до окончания текущей торговой сессии, Дата в формате "ГГММДД")
		["IS_ACTIVE_IN_TIME"]   = "NO",
        ['CONDITION']           = direction, -- Направленность стоп-цены. Возможные значения: «4» - меньше или равно, «5» – больше или равно
        ["COMMENT"]             = NAME_OF_STRATEGY..' '..STOP_ORDER_KIND,
        ["PRICE"]               = price -- Цена, по которой выставится заявка при срабатывании Стоп-Лосса (для рыночной заявки по акциям должна быть 0)
    }

    if  STOP_ORDER_KIND == "TAKE_PROFIT_AND_STOP_LIMIT_ORDER" then
		Transaction["STOP_ORDER_KIND"]     = STOP_ORDER_KIND -- Тип стоп-заявки
        Transaction["STOPPRICE"]           = tp_Price -- Цена Тейк-Профита
        Transaction["STOPPRICE2"]          = sl_Price -- Цена Стоп-Лосса
        -- "MARKET_TAKE_PROFIT" = ("YES", или "NO") должна ли выставится заявка по рыночной цене при срабатывании Тейк-Профита.
        -- Для рынка FORTS рыночные заявки, как правило, запрещены,
        -- для лимитированной заявки на FORTS нужно указывать заведомо худшую цену, чтобы она сработала сразу же, как рыночная
        Transaction["MARKET_TAKE_PROFIT"]  = market
        -- "MARKET_STOP_LIMIT" = ("YES", или "NO") должна ли выставится заявка по рыночной цене при срабатывании Стоп-Лосса.
        -- Для рынка FORTS рыночные заявки, как правило, запрещены,
        -- для лимитированной заявки на FORTS нужно указывать заведомо худшую цену, чтобы она сработала сразу же, как рыночная
        Transaction["MARKET_STOP_LIMIT"]   = market
        -- "OFFSET" - (ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль,
        -- то Тейк-профит сработает только когда цена вернется минимум на 2 шага цены назад,
        -- это может потенциально увеличить прибыль
        Transaction["OFFSET"]              = GetCorrectPrice(offset*priceKoeff)
        Transaction["OFFSET_UNITS"]        = "PRICE_UNITS" -- Единицы измерения отступа ("PRICE_UNITS" - шаг цены, или "PERCENTS" - проценты)
        -- "SPREAD" - Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на 100 шагов цены,
        -- которая АВТОМАТИЧЕСКИ УДОВЛЕТВОРИТСЯ ПО ТЕКУЩЕЙ ЛУЧШЕЙ ЦЕНЕ,
        -- но то, что цена значительно хуже, спасет от проскальзывания,
        -- иначе, сделка может просто не закрыться (заявка на закрытие будет выставлена, но цена к тому времени ее уже проскочит)
        Transaction["SPREAD"]              = GetCorrectPrice(spread*priceKoeff)
        Transaction["SPREAD_UNITS"]        = "PRICE_UNITS" -- Единицы измерения защитного спрэда ("PRICE_UNITS" - шаг цены, или "PERCENTS" - проценты)
    elseif STOP_ORDER_KIND == "TAKE_PROFIT_STOP_ORDER" then
		Transaction["STOP_ORDER_KIND"]     = STOP_ORDER_KIND -- Тип стоп-заявки
        Transaction["STOPPRICE"]           = tp_Price -- Цена Тейк-Профита
        -- "OFFSET" - (ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль,
        -- то Тейк-профит сработает только когда цена вернется минимум на 2 шага цены назад,
        -- это может потенциально увеличить прибыль
        Transaction["OFFSET"]              = GetCorrectPrice(offset*priceKoeff)
        Transaction["OFFSET_UNITS"]        = "PRICE_UNITS" -- Единицы измерения отступа ("PRICE_UNITS" - шаг цены, или "PERCENTS" - проценты)
        -- "SPREAD" - Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на 100 шагов цены,
        -- которая АВТОМАТИЧЕСКИ УДОВЛЕТВОРИТСЯ ПО ТЕКУЩЕЙ ЛУЧШЕЙ ЦЕНЕ,
        -- но то, что цена значительно хуже, спасет от проскальзывания,
        -- иначе, сделка может просто не закрыться (заявка на закрытие будет выставлена, но цена к тому времени ее уже проскочит)
        Transaction["SPREAD"]              = GetCorrectPrice(spread*priceKoeff)
        Transaction["SPREAD_UNITS"]        = "PRICE_UNITS" -- Единицы измерения защитного спрэда ("PRICE_UNITS" - шаг цены, или "PERCENTS" - проценты)
    else
        Transaction["STOPPRICE"]           = sl_Price -- Цена Тейк-Профита
    end

    -- Отправляет транзакцию на установку ТЕЙК-ПРОФИТ и СТОП-ЛОСС
    local res = sendTransaction(Transaction)
    if string.len(res) ~= 0 then
        message(NAME_OF_STRATEGY..' robot: Установка '..STOP_ORDER_KIND..' не удалась!\nОШИБКА: '..res)
	    myLog(NAME_OF_STRATEGY..' robot: Установка '..STOP_ORDER_KIND..' не удалась!\nОШИБКА: '..res)
        trans_Status = nil
	    return false
    end

    -- Выводит сообщение
	trans_Status = nil
	myLog(NAME_OF_STRATEGY..' robot: ВЫСТАВЛЕНА заявка '..STOP_ORDER_KIND..': '..trans_id)

    -- Ищет заявку в таблице заявок, возвращает истина
    -- Ожидает 10 сек. макс.
    local start_sec = os.time()
    while isRun and os.time() - start_sec < 10 do
        local num = getNumberOf('stop_orders')
        if num > 0 then
           if num > 1 then
              for i = num - 1, 0, -1 do
                 local stop_order = getItem('stop_orders', i)
                 if stop_order.sec_code == SEC_CODE and stop_order.trans_id == trans_id then
                    stop_order.index = i
                    return true
                 end
              end
           else
              local stop_order = getItem('stop_orders', 0)
              if stop_order.sec_code == SEC_CODE and stop_order.trans_id == trans_id then
                 stop_order.index = 0
                 return true
              end
           end
        end
        sleep(100)
    end

    message(NAME_OF_STRATEGY..' Возникла неизвестная ошибка при выставлении стоп заявки по транзакции: '..tostring(trans_id))
    myLog(NAME_OF_STRATEGY..' Возникла неизвестная ошибка при выставлении стоп заявки по транзакции: '..tostring(trans_id))

    return false

end

-- Удалить все стоп заявки
function KillAllStopOrders(deleteAll)

	local allDeleted = true
	if not VIRTUAL_TRADE then

	    local can_trade, state = CheckTradeSession()
	    if not can_trade then
	        myLog(NAME_OF_STRATEGY..' '..tostring(state)..'. Удаление заявок невозможна.')
	        message(NAME_OF_STRATEGY..' '..tostring(state)..'. Удаление заявок невозможна.',3)
	        return nil
	    end

		myLog(NAME_OF_STRATEGY..' Закрытие стоп-лосса '..ROBOT_CLIENT_CODE)

	    function myFind(C,S,F,B)
	       return (C == CLASS_CODE) and (S == SEC_CODE) and (bit.band(F, 0x1) ~= 0) and (((not trackManualDeals and B:find(ROBOT_POSTFIX)) or trackManualDeals) or deleteAll == true)
	    end

	    local ord = "stop_orders"
	    local orders = SearchItems(ord, 0, getNumberOf(ord)-1, myFind, "class_code,sec_code,flags,brokerref")
	    if (orders ~= nil) and (#orders > 0) then
	        for i=1,#orders do
	            local order = getItem(ord,orders[i])
	            myLog('Close stop '..tostring(order.order_num)..' client_code '..order.brokerref)
	            allDeleted = allDeleted and KillOrder(order.order_num, ord, "KILL_STOP_ORDER", orders[i]) --
	        end
	    end
	end
    if (ROBOT_STATE ~= 'УСТАНОВКА СТОП ЛОССА' and VIRTUAL_TRADE) or (allDeleted and (OpenCount == 0 or manualKillStop)) then
        if ROBOT_STATE ~= 'УСТАНОВКА СТОП ЛОССА' then
            workedStopPrice, slIndex, lastStopShiftIndex = 0, 0, 0
        end
        SetSL_TP(0, 0)
    end

    return allDeleted
end

-- Удалить все лимитные заявки

 function KillAllOrders(deleteAll)

	if VIRTUAL_TRADE then return end
    local can_trade, state = CheckTradeSession()
    if not can_trade then
        myLog(NAME_OF_STRATEGY..' '..tostring(state)..'. Удаление заявок невозможна.')
        message(NAME_OF_STRATEGY..' '..tostring(state)..'. Удаление заявок невозможна.',3)
        return nil
    end

	myLog(NAME_OF_STRATEGY..' Закрытие лимитных заявок '..ROBOT_CLIENT_CODE)

    function myFind(C,S,F,B)
       return (C == CLASS_CODE) and (S == SEC_CODE) and (bit.band(F, 0x1) ~= 0) and (((not trackManualDeals and B:find(ROBOT_POSTFIX)) or trackManualDeals) or deleteAll == true)
    end

    local res=1
    local ord = "orders"
    local allDeleted = true
    local orders = SearchItems(ord, 0, getNumberOf(ord)-1, myFind, "class_code,sec_code,flags,brokerref")
    if (orders ~= nil) and (#orders > 0) then
        for i=1,#orders do
            local order = getItem(ord,orders[i])
            myLog('Close limit '..tostring(order.order_num)..' client_code '..order.brokerref)
            allDeleted = allDeleted and KillOrder(getItem(ord,orders[i]).order_num, ord, "KILL_ORDER", orders[i]) --
        end
     end

     return allDeleted
end

-- Снимает заявку в указанной таблице
function KillOrder(
    order_num,    -- Номер снимаемой заявки
    ord,          -- Таблица удаления заявок
    ACTION,       -- Команда удаления
    index         -- Индекс таблицы
 )

	if VIRTUAL_TRADE then return end
    local can_trade, state = CheckTradeSession()
    if not can_trade then
        myLog(NAME_OF_STRATEGY..' '..tostring(state)..'. Удаление заявок невозможна.')
        message(NAME_OF_STRATEGY..' '..tostring(state)..'. Удаление заявок невозможна.',3)
        return nil
    end

	 ord = ord or 'stop_orders'
    ACTION = ACTION or 'KILL_STOP_ORDER'
    local prefix = ACTION == 'KILL_STOP_ORDER' and 'СТОП' or 'ЛИМИТНАЯ'
    local ORDER_KEY = ACTION == 'KILL_STOP_ORDER' and 'STOP_ORDER_KEY' or 'ORDER_KEY'

    index = index or 0
    if index == 0 then
        -- Находит заявку если не передан индекс(10 сек. макс.)
        local start_sec = os.time()
        local find_order = false
        while isRun and not find_order and os.time() - start_sec < 10 do
        for i=getNumberOf(ord)-1,0,-1 do
            local order = getItem(ord, i)
            if order.order_num == order_num then
                -- Если заявка уже была исполнена (не активна)
                if not bit.test(order.flags, 0) then
                    return true
                end
                index = i
                find_order = true
                break
            end
        end
        end
        if not find_order then
            message(NAME_OF_STRATEGY..' Ошибка: не найдена '..prefix..' заявка: '..tostring(order_num))
            myLog(NAME_OF_STRATEGY..' Ошибка: не найдена '..prefix..' заявка: '..tostring(order_num))
            return false
        end
    end

    prefix = ACTION == 'KILL_STOP_ORDER' and 'СТОП' or 'ЛИМИТНОЙ'
    myLog('Снятие заявки '..ACTION..'/'..ORDER_KEY..' num '..getItem(ord, index).order_num..' flag '..tostring(bit.test(getItem(ord, index).flags, 1)))

    -- Получает ID для следующей транзакции
    trans_id = trans_id + 1
    -- Заполняет структуру для отправки транзакции на снятие заявки
    local T = {}
    T['TRANS_ID']       = tostring(trans_id)
    T['CLASSCODE']      = CLASS_CODE
    T['SECCODE']        = SEC_CODE
    T['ACTION']         = ACTION        -- Тип заявки
    T['CLIENT_CODE']    = CLIENT_CODE -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках
    T[ORDER_KEY]        = tostring(order_num)      -- Номер заявки, снимаемой из торговой системы

    -- Отправляет транзакцию
    local Res = sendTransaction(T)
    -- Если при отправке транзакции возникла ошибка

    if Res ~= '' then
       -- Выводит ошибку
       message(NAME_OF_STRATEGY..' Ошибка снятия '..prefix..' заявки: '..tostring(order_num)..' '..Res)
       myLog(NAME_OF_STRATEGY..' Ошибка снятия '..prefix..' заявки: '..tostring(order_num)..' '..Res)
       return false
    end

    -- Ожидает когда заявка перестанет быть активна (10 сек. макс.)
    local start_sec = os.time()
    local active = true
    while isRun and os.time() - start_sec < 10 do
        local order = getItem(ord, index)
        --myLog('Снятие заявки '..ACTION..' num '..order.order_num..' flag '..tostring(bit.test(order.flags, 1)))
        -- Если заявка не активна
        if not bit.test(order.flags, 0) then
            -- Если заявка успела исполниться
            if not bit.test(order.flags, 1) then
               return true
            end
            active = false
            break
        end
        sleep(10)
    end
    if active then
       message(NAME_OF_STRATEGY..' Возникла неизвестная ошибка при снятии '..prefix..' ЗАЯВКИ: '..tostring(order_num))
       myLog(NAME_OF_STRATEGY..' Возникла неизвестная ошибка при снятии '..prefix..' ЗАЯВКИ: '..tostring(order_num))
       return false
    end

    return true
end

-----------------------------------------
-- Простейший алгоритм смещения баров

--Инициализация переменных алгоритма
function initSimpleAlgo()
    ATR                 = {}
    trend               = {}
    calcAlgoValue       = {}
    dVal                = {}
    calcChartResults    = {}
end

--Подготовка таблицы оптимазационных параметров алгоритма
function iterateSimpleAlgo()

    param1Min = 1
    param1Max = 62
    param1Step = 1

    --if ROBOT_STATE == 'ОПТИМИЗАЦИЯ' then
    --    param1Min = math.max(param1Min, Settings.period-30)
    --    param1Max = math.min(param1Max, Settings.period+30)
    --end

    local settingsTable = {}
    local allCount = 0

    for param1 = param1Min, param1Max, param1Step do
        allCount = allCount + 1

        settingsTable[allCount] = {
            shift    = param1
        }
    end

    iterateAlgorithm(settingsTable)

end

--Сам алгоритм
function simpleAlgo(index, Fsettings)

    local shift = Settings.shift or 17
    local bars = 20
    local kawg = 2/(bars+1)

    local indexToCalc = 1000
    indexToCalc = Fsettings.indexToCalc or indexToCalc
    local beginIndexToCalc = Fsettings.beginIndexToCalc or math.max(1, DS:Size() - indexToCalc)

    if index == beginIndexToCalc then
        --if ROBOT_STATE ~= 'ОПТИМИЗАЦИЯ' then
        --    myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
        --    myLog(NAME_OF_STRATEGY.." Показатель shift "..tostring(shift))
        --    myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
        --end
        ATR = {}
        ATR[index] = 0
        calcAlgoValue = {}
        calcAlgoValue[index]= 0
        dVal = {}
        dVal[index]= 0
        trend = {}
        trend[index] = 1
        calcChartResults = {}
        calcChartResults[index]= {nil,nil}
        return calcAlgoValue
    end

    ATR[index] = ATR[index-1]
    calcAlgoValue[index] = calcAlgoValue[index-1]
    dVal[index] = dVal[index-1]
    trend[index] = trend[index-1]
    calcChartResults[index] = calcChartResults[index-1]

    if index<(bars+beginIndexToCalc) then
        ATR[index] = 0
    elseif index==(bars+beginIndexToCalc) then
        local sum=0
        for i = 1, bars do
            sum = sum + dValue(i)
        end
        ATR[index]=sum / bars
    elseif index>(bars+beginIndexToCalc) then
        --ATR[index]=(ATR[index-1] * (bars-1) + dValue(index)) / bars
        ATR[index] = kawg*dValue(index)+(1-kawg)*ATR[index-1]
    end

    if index < beginIndexToCalc + shift+2 then
        return calcAlgoValue, trend
    end

    calcAlgoValue[index] = dValue(index, 'T')
    dVal[index]= dValue(index, 'C')

    local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5
    local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5

    --покупка если не пин-бар и T цена на этом баре превысила цену бара на shift назад и T цена больше цены закрытия бара на shift назад
    local isBuy = (not isUpPinBar and calcAlgoValue[index] > dVal[index-shift] and calcAlgoValue[index-1] <= dVal[index-shift-1]) and dVal[index] > dVal[index-shift]
    --продажа если не пин-бар и T цена на этом баре пробила вниз цену бара на shift назад и T цена меньше цены закрытия бара на shift назад
    local isSell = (not isLowPinBar and calcAlgoValue[index] < dVal[index-shift] and calcAlgoValue[index-1] >= dVal[index-shift-1]) and dVal[index] < dVal[index-shift]

    -- определяем значение тренда на этом баре
    if isBuy then
        trend[index] = 1
    end
    if isSell then
        trend[index] = -1
    end

    --передаем для вывода на график две линии
    calcChartResults[index] = {calcAlgoValue[index], dVal[index-shift]}

    --myLog(NAME_OF_STRATEGY.." algoLine "..tostring(calcAlgoValue[index])..", algoLine-shift "..tostring(calcAlgoValue[index-shift]))

    return calcAlgoValue, trend
end

--Получение префикса для выставления заявок
function getROBOT_CLIENT_CODE(counter)
    return CLIENT_CODE..ROBOT_POSTFIX..tostring(counter)
end
-----------------------------------------
--метки сделок
function addDeal(openLong, openShort, closeLong, closeShort, time)

    label =
    {
        DATE = 0,
        TIME = 0,
        TEXT="***********",
        HINT="",
        FONT_FACE_NAME = "Arial",
        FONT_HEIGHT = 10,
        R = 64,
        G = 192,
        B = 64,
        TRANSPARENT_BACKGROUND = 1,
        YVALUE = 0,
    }

    label.DATE = (time.year*10000+time.month*100+time.day)
    label.TIME = ((time.hour)*10000+(time.min)*100)
    local IMAGE_PATH = getScriptPath()..'\\Pictures\\'

    if openLong ~= nil then
        label.YVALUE = openLong
        label.IMAGE_PATH = IMAGE_PATH..'buy.bmp'
        ALIGNMENT = "BOTTOM"
        label.R = 0
        label.G = 0
        label.B = 0
        label.TEXT = tostring(openLong)
        label.HINT = "open Long "..tostring(openLong).." - "..toYYYYMMDDHHMMSS(time)
    elseif openShort ~=nil then
        label.YVALUE = openShort
        label.IMAGE_PATH = IMAGE_PATH..'sell.bmp'
        label.R = 0
        label.G = 0
        label.B = 0
        ALIGNMENT = "TOP"
        label.TEXT = tostring(openShort)
        label.HINT = "open Short "..tostring(openShort).." - "..toYYYYMMDDHHMMSS(time)
    elseif closeLong ~=nil then
        label.YVALUE = closeLong
        label.IMAGE_PATH = IMAGE_PATH..'sell.bmp'
        ALIGNMENT = "TOP"
        label.R = 0
        label.G = 0
        label.B = 0
        label.TEXT = tostring(closeLong)
        label.HINT = "close Long "..tostring(closeLong).." - "..toYYYYMMDDHHMMSS(time)
    elseif closeShort ~=nil then
        label.YVALUE = closeShort
        label.IMAGE_PATH = IMAGE_PATH..'buy.bmp'
        ALIGNMENT = "BOTTOM"
        label.R = 0
        label.G = 0
        label.B = 0
        label.TEXT = tostring(closeShort)
        label.HINT = "close Short "..tostring(closeShort).." - "..toYYYYMMDDHHMMSS(time)
    end

    AddLabel(ChartId, label)

end

--------------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ СКРИПТА --
--------------------------------------------------------------------
do---- ДАТА/ВРЕМЯ

    -- Ждет подключения к серверу, после чего ждет еще UpdateDataSecQty секунд подгрузки пропущенных данных с сервера
    function WaitUpdateDataAfterReconnect()
       while isRun and isConnected() == 0 do sleep(100) end
       if isRun then sleep(UpdateDataSecQty * 1000) end
       -- Повторяет операцию если соединение снова оказалось разорвано
       if isRun and isConnected() == 0 then WaitUpdateDataAfterReconnect() end
    end

    -- Возвращает текущую дату/время сервера в виде таблицы datetime
    function GetServerDateTime()

        local dt = {}

       -- Пытается получить дату/время сервера
       while isRun and dt.day == nil do
            dt.day,dt.month,dt.year,dt.hour,dt.min,dt.sec = string.match(getInfoParam('TRADEDATE')..' '..getInfoParam('SERVERTIME'),"(%d*).(%d*).(%d*) (%d*):(%d*):(%d*)")
            -- Если не удалось получить, или разрыв связи, ждет подключения и подгрузки с сервера актуальных данных
            if dt.day == nil or isConnected() == 0 then
                return os.date('*t', os.time())
                --WaitUpdateDataAfterReconnect()
            end
       end

       -- Если во время ожидания скрипт был остановлен пользователем, возвращает таблицу datetime даты/времени компьютера, чтобы не вернуть пустую таблицу и не вызвать ошибку в алгоритме
       if not isRun then return os.date('*t', os.time()) end

       -- Приводит полученные значения к типу number
       for key,value in pairs(dt) do dt[key] = tonumber(value) end

       -- Возвращает итоговую таблицу
       return dt
    end

    -- Приводит время из строкового формата ЧЧ:ММ:CC к формату datetime
    function StrToTime(str_time)
        if type(str_time) ~= 'string' then return os.date('*t') end
        local sdt = GetServerDateTime()
        while isRun and sdt.day == nil do sleep(100) sdt = GetServerDateTime() end
        if not isRun then return os.date('*t') end
        local dt = sdt
        local h,m,s = string.match( str_time, "(%d%d):(%d%d):(%d%d)")
        dt.hour = tonumber(h)
        dt.min = tonumber(m)
        dt.sec = s==nil and 0 or tonumber(s)
        return dt
    end

end--- ДАТА/ВРЕМЯ

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
        str = string.gsub(str,word,'')
        return word
    end
end

function dValue(i,param)
    local v = param or "ATR"

        if DS:C(i) == nil then
            return nil
        end

        if  v == "O" then
            return DS:O(i)
        elseif   v == "H" then
            return DS:H(i)
        elseif   v == "L" then
            return DS:L(i)
        elseif   v == "C" then
            return DS:C(i)
        elseif   v == "V" then
            return DS:V(i)
        elseif   v == "M" then
            return (DS:H(i) + DS:L(i))/2
        elseif   v == "T" then
            return (DS:H(i) + DS:L(i)+DS:C(i))/3
        elseif   v == "W" then
            return (DS:H(i) + DS:L(i)+2*DS:C(i))/4
        elseif   v == "ATR" then
            local previous = math.max(i-1, 1)

            if DS:C(i) == nil then
                previous = FindExistCandle(previous)
            end
            if previous == 0 then
                return nil
            end

            return math.max(math.abs(DS:H(i) - DS:L(i)), math.abs(DS:H(i) - DS:C(previous)), math.abs(DS:C(previous) - DS:L(i)))
        else
            return DS:C(i)
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

-- функция записывает в лог строчку с временем и датой
function myLog(...)

    if not logging or logFile==nil then return end

   local current_time=os.time()--tonumber(timeformat(getInfoParam("SERVERTIME"))) -- помещене в переменную времени сервера в формате HHMMSS
   if (current_time-g_previous_time)>1 then -- если текущая запись произошла позже 1 секунды, чем предыдущая
      logFile:write("\n") -- добавляем пустую строку для удобства чтения
   end
   g_previous_time = current_time

   logFile:write(os.date().."; ".. log_tostring(...) .. "\n")
   logFile:flush() -- Сохраняет изменения в файле
end

function Median(x, y, z)
    return (x+y+z) - math.min(x,math.min(y,z)) - math.max(x,math.max(y,z))
end

-- удаление точки и нулей после нее
function removeZero(str)
   while (string.sub(str,-1) == "0" and str ~= "0") do
      str = string.sub(str,1,-2)
   end
   if (string.sub(str,-1) == ".") then
      str = string.sub(str,1,-2)
   end
   return str
end

function toYYYYMMDDHHMMSS(datetime)
    if type(datetime) ~= "table" then
       return ""
    else
       local Res = tostring(datetime.year)
       if #Res == 1 then Res = "000"..Res end
       Res = Res.."."
       local month = tostring(datetime.month)
       if #month == 1 then Res = Res.."0"..month else Res = Res..month end
       Res = Res.."."
       local day = tostring(datetime.day)
       if #day == 1 then Res = Res.."0"..day else Res = Res..day end
       Res = Res.." "
       local hour = tostring(datetime.hour)
       if #hour == 1 then Res = Res.."0"..hour else Res = Res..hour end
       Res = Res..":"
       local minute = tostring(datetime.min)
       if #minute == 1 then Res = Res.."0"..minute else Res = Res..minute end
       Res = Res..":"
       local sec = tostring(datetime.sec);
       if #sec == 1 then Res = Res.."0"..sec else Res = Res..sec end
       return Res
    end
end --toYYYYMMDDHHMMSS

function round(num, idp)
	if num then
	   local mult = 10^(idp or 0)
	   if num >= 0 then return math.floor(num * mult + 0.5) / mult
	   else return math.ceil(num * mult - 0.5) / mult end
	else return num end
end

function FindExistCandle(I)

	local out = I

	while DS:C(out) == nil and out > 0 do
		out = out -1
	end

	return out

end
