-- nick-h@yandex.ru
-- Glukk Inc ©

local w32 = require("w32")
require("StaticVar")

NAME_OF_STRATEGY = '' -- НАЗВАНИЕ СТРАТЕГИИ (не более 9 символов!)

ACCOUNT           = ''        -- Идентификатор счета
CLIENT_CODE = "" -- "Код клиента"

------ ЗНАЧЕНИЯ ПО УМОЛЧАНИЮ---------
default_ACCOUNT           = 'A701XS7'        -- Идентификатор счета
default_CLIENT_CODE = "A701XS7" -- "Код клиента"

ROBOT_POSTFIX = '/'..'rAL' --идентификатор робота в комментариях к заявкам и сделкам. Для поиска
ROBOT_CLIENT_CODE = default_CLIENT_CODE..ROBOT_POSTFIX --Строка комментаия в заявках, сделках

INTERVAL          = INTERVAL_M3          -- Таймфрейм графика по умолчанию
ChartId = "Sheet11" -- индентификатор графика, куда выводить метки сделок и данные алгоритма. 
testSizeBars = 540 -- размер окна оптимизации стратегии

QTY_LOTS = 1 -- Кол-во торгуемых лотов
SetStop = true -- выставлять ли стоп заявки
fixedstop = false-- STOPLOSS не рассчитывать по алгоритму, а брать фиксированным из настроек
isLong  = true -- доступен лонг
isShort = true -- доступен шорт
trackManualDeals = true --учитывать ручные сделки не из интерфейса робота при выставлении стоп заявок
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

OFFSET = 2 --(ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
SPREAD = 50 --Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,

maxStop  = 85 -- максимально допустимый стоп в пунктах                  
reopenDealMaxStop  = 75 -- если сделка переоткрыта после стопа, то максимальный стоп                  
stopShiftIndexWait = 17 -- если цена не двигается (на величину стопа), то пересчитать стоп после стольких баров                   
shiftStop = true -- сдвигать стоп (трейил) на величину STOP_LOSS                 
shiftProfit = true -- сдвигать профит (трейил) на величину STOP_LOSS/2
reopenPosAfterStop = 7 -- если выбило по стопу заявке, то попытаться переоткрыть сделку, после стольких баров                  
------ ЗНАЧЕНИЯ ПО УМОЛЧАНИЮ---------

serverTime = 1000
startTradeTime = 1018
endTradeTime = 1842
eveningSession = 1900
CloseSLbeforeClearing = false
-----------------------------
--виртуальная торговля
virtualTrade = true --переключение Shift+V
getDOMPrice = true
vlastDealPrice = 0
vdealProfit = 0
vallProfit = 0
                   
--/*РАБОЧИЕ ПЕРЕМЕННЫЕ РОБОТА (менять не нужно)*/
SEC_PRICE_STEP    = 0                    -- ШАГ ЦЕНЫ ИНСТРУМЕНТА
LOTSIZE = 1
scale = 0
leverage = 1
priceKoeff = 1/leverage

virtCaption = (virtualTrade and 'virtual ' or 'real ')
DS                = nil                  -- Источник данных графика (DataSource)
ROBOT_STATE       ='FIRSTSTART'
BASE_ROBOT_STATE  ='ОСТАНОВЛЕН'
trans_id          = os.time()            -- Задает начальный номер ID транзакций
trans_Status      = nil                  -- Статус текущей транзакции из функции OnTransPeply
trans_result_msg  = ''                   -- Сообщение по текущей транзакции из функции OnTransPeply
CurrentDirect     = 'BUY'                -- Текущее НАПРАВЛЕНИЕ ['BUY', или 'SELL']
LastOpenBarIndex  =  0                   -- Индекс свечи, на которой была открыта последняя позиция (нужен для того, чтобы после закрытия по стопу тут же не открыть еще одну позицию)
lastSignalIndex = {}
lastCalculatedBar = 0
Run               = true                 -- Флаг поддержания работы бесконечного цикла в main
OpenCount = 0
robotOpenCount = 0
orderQnty = 0
tradeBegin = false
countOrders = {}

Settings = {}

isTrade = false
continue = true
StopForbidden = false
manualKillStop = false
TransactionPrice = 0
TakeProfitPrice = 0
CurrentPosAveragePrice = 0 -- Средняя цена текущей позиции

TAKE_PROFIT = 0
STOP_LOSS = 0
isPriceMove = false
priceMoveMin = 0
priceMoveMax = 0
lastStopShiftIndex = 0

stop_order_num= "" -- номер стоп-заявки на вход в системе, по которому её можно снять
tpPrice = 0
slPrice = 0
oldStop = 0
vtpPrice = 0
vslPrice = 0
slIndex = 0
workedStopPrice = 0

order_price = 0 -- переменная для хранения цены лимитного ордера первой цели
order_type = nil -- переменная для хранения типа лимитного ордера первой цели
order_num = 0 -- переменная для хранения номера лимитного ордера первой цели
order_qty = 0 -- переменная для хранения баланса лимитного ордера первой цели

kATR = 0.95
iterateSLTP = true
reopenAfterStop = false

t_id = nil
tv_id = nil

SeaGreen     =RGB(193, 255, 193)	    --	нежно-зеленый
RosyBrown    =RGB(255, 193, 193)	    --	нежно-розовый
LemonChiffon =RGB(255,250,205)          --	нежно-желтый

g_previous_time = os.time() -- помещение в переменную времени сервера в формате HHMMSS 

ATR = {}
calcAlgoValue={}
dVal={}

logFile = nil
logging = true

-------------------------------------------
--Оптимизация

RFR = 0 --7.42 --безрискова ставка для расчета коэфф. Шарпа

stopSignal = false
doneOptimization = 0
optimizationInProgress = false
needReoptimize = false

beginIndex = 1
endIndex = 1
beginIndexallProfit = 0
shortProfit = 0
longProfit = 0
lastDealPrice = 0
stopLevelPrice = 0
lastTradeDirection = 0
dealsCount = 0
dealsLongCount = 0
dealsShortCount = 0
algoResults = nil
profitDealsLongCount = 0
profitDealsShortCount = 0
slDealsLongCount = 0
tpDealsLongCount = 0
slDealsShortCount = 0
tpDealsShortCount = 0
ratioProfitDeals = 0
initalAssets = 0
deals = {}
resultsTables = {}

--По умолчанию первый пересет
curPreset = 1
-----------------------------------------------

-- Функция первичной инициализации скрипта (ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK в самом начале)
function OnInit()
   -- Получает доступ к свечам графика
    if isConnected() == false then
        Run = False
        message("Нет подключения")
        myLog(NAME_OF_STRATEGY.." Нет подключения")
    end
   
    local ss = getInfoParam("SERVERTIME")
    if string.len(ss) >= 5 then            
        local hh = mysplit(ss,":")
        local str=hh[1]..hh[2]
        serverTime = tonumber(str)
    end

    algoFiles = {}

    dofile(getScriptPath().."\\regAlgo.lua") --Reg алгоритм
    dofile(getScriptPath().."\\thvAlgo.lua") --THV алгоритм
    dofile(getScriptPath().."\\nrtrAlgo.lua") --NRTR алгоритм
    dofile(getScriptPath().."\\shiftMaAlgo.lua") --NRTR алгоритм
 
    --example
    --[[
   {
        Name    = "simpleM3",  -- имя пресета                 
        NAME_OF_STRATEGY = 'simple', -- имя стратегии
        ACCOUNT           = 'SPBFUT000jo',        -- Идентификатор счета для этой настройки
        CLIENT_CODE = "SPBFUT000jo", -- "Код клиента" для этой настройки
        SEC_CODE = 'MMH9', -- код инструмента для торговли
        CLASS_CODE = 'SPBFUT', -- класс инструмента
        QTY_LOTS = 1, -- количество для торговли
        OFFSET = 2, --(ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
        SPREAD = 10, --Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
        ChartId = "Sheet11", -- индентификатор графика, куда выводить метки сделок и данные алгоритма. 
        SetStop = true, -- выставлять ли стоп заявки
        CloseSLbeforeClearing = false, -- снимать ли стоп заявки перед клирингом
        fixedstop = false,-- STOPLOSS не рассчитывать по алгоритму, а брать фиксированным из настроек
        isLong  = true, -- доступен лонг
        isShort = true, -- доступен шорт
        trackManualDeals = true, --учитывать ручные сделки не из интерфейса робота,
        maxStop       = 85, -- максимально допустимый стоп в пунктах                  
        reopenDealMaxStop       = 75, -- если сделка переоткрыта после стопа, то максимальный стоп                  
        stopShiftIndexWait       = 17, -- если цена не двигается (на величину стопа), то пересчитать стоп после стольких баров                   
        shiftStop = true, -- сдвигать стоп (трейил) на величину STOP_LOSS                 
        shiftProfit = true, -- сдвигать профит (трейил) на величину STOP_LOSS/2
        reopenPosAfterStop       = 7, -- если выбило по стопу заявке, то попытаться переоткрыть сделку, после стольких баров                  
        INTERVAL          = INTERVAL_M3, -- Таймфрейм графика
        testSizeBars = 540, -- размер окна оптимизации стратегии
        calculateAlgo = simpleAlgo, -- имя функции расчета алгоритма
        iterateAlgo = iterateSimpleAlgo, -- имя функции подготовки таблицы набора параметров для оптимизации
        initAlgo = initSimpleAlgo, -- имя функции для обнуления таблиц алгоритма перед очередным шагом оптимизации
        setTableAlgoParams  = setTableSimpleAlgoParams, -- имя функции вывода параметров в интерфейс
        readTableAlgoParams = readTableSimpleAlgoParams, -- имя функции считывания параметров из интерфейса 
        readOptimizedParams = readOptimizedSimpleAlgo, -- имя функции чтения оптимальных параметров алгоритма из файла
        saveOptimizedParams = saveOptimizedSimpleAlgo, -- имя функции записи оптимальных параметров алгоритма в файл
        settingsAlgo = 
        {
            shift = 16, -- перменная алгоритма
            STOP_LOSS         = 25,                   -- Размер СТОП-ЛОССА
            TAKE_PROFIT       = 130                   -- Размер ТЕЙК-ПРОФИТА
        }
    }
    ]]--

    presets = {
        {
            Name    = "rangeM3",                   
            NAME_OF_STRATEGY = 'RangeHV',
            SEC_CODE = 'MMH9',
            CLASS_CODE = 'SPBFUT',
            QTY_LOTS = 1, -- количество для торговли
            OFFSET = 2, --(ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
            SPREAD = 10, --Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
            ChartId = "Sheet11",
            SetStop = false, -- выставлять ли стоп заявки
            CloseSLbeforeClearing = false, -- снимать ли стоп заявки перед клирингом
            fixedstop = false,-- STOPLOSS не рассчитывать по алгоритму, а брать фиксированным из настроек
            isLong  = true, -- доступен лонг
            isShort = true, -- доступен шорт
            trackManualDeals = true, --учитывать ручные сделки не из интерфейса робота,
            maxStop       = 85,                   
            reopenDealMaxStop       = 75,                   
            stopShiftIndexWait       = 17,                   
            shiftStop = true, -- сдвигать стоп (трейил) на величину STOP_LOSS                 
            shiftProfit = true, -- сдвигать профит (трейил) на величину STOP_LOSS/2
            reopenPosAfterStop       = 7,                   
            INTERVAL          = INTERVAL_M3,          -- Таймфрейм графика (для построения скользящих)i
            testSizeBars = 1350, --270
            calculateAlgo = RangeHV,
            iterateAlgo = iterateRangeHV,
            initAlgo = initRangeHV,
            setTableAlgoParams  = setTableRangeHVParams,
            readTableAlgoParams = readTableRangeHVParams,
            readOptimizedParams = readOptimizedRangeHV,
            saveOptimizedParams = saveOptimizedRangeHV,
            settingsAlgo = 
            {
                period    = 12,
                shift = 1,
                koef = 8,
                STOP_LOSS         = 55,                   -- Размер СТОП-ЛОССА
                TAKE_PROFIT       = 115                   -- Размер ТЕЙК-ПРОФИТА
            }
        },
        {
            Name    = "THV M3",                   
            NAME_OF_STRATEGY = 'THV',
            ACCOUNT           = 'A701XS7',        -- Идентификатор счета
            CLIENT_CODE = "A701XS7", -- "Код клиента"
            SEC_CODE = 'MMH9',
            CLASS_CODE = 'SPBFUT',
            QTY_LOTS = 1, -- количество для торговли
            OFFSET = 2, --(ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
            SPREAD = 10, --Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
            ChartId = "Sheet11",
            SetStop = true, -- выставлять ли стоп заявки
            CloseSLbeforeClearing = false, -- снимать ли стоп заявки перед клирингом
            fixedstop = false,-- STOPLOSS не рассчитывать по алгоритму, а брать фиксированным из настроек
            isLong  = true, -- доступен лонг
            isShort = true, -- доступен шорт
            trackManualDeals = true, --учитывать ручные сделки не из интерфейса робота,
            maxStop       = 85,                   
            reopenDealMaxStop       = 75,                   
            stopShiftIndexWait       = 17,                   
            shiftStop = true, -- сдвигать стоп (трейил) на величину STOP_LOSS                 
            shiftProfit = true, -- сдвигать профит (трейил) на величину STOP_LOSS/2
            reopenPosAfterStop       = 7,                   
            INTERVAL          = INTERVAL_M3,          -- Таймфрейм графика (для построения скользящих)
            testSizeBars = 3240,
            calculateAlgo = THV,
            iterateAlgo = iterateTHV,
            initAlgo = initTHV,
            setTableAlgoParams  = setTableTHVParams,
            readTableAlgoParams = readTableTHVParams,
            readOptimizedParams = readOptimizedTHV,
            saveOptimizedParams = saveOptimizedTHV,
            settingsAlgo = 
            {
                period    = 12,
                shift = 8,
                koef = 1.8,
                STOP_LOSS         = 45,                   -- Размер СТОП-ЛОССА
                TAKE_PROFIT       = 140                   -- Размер ТЕЙК-ПРОФИТА
            }
        },
        {
            Name    = "flTHVm3",                   
            NAME_OF_STRATEGY = 'THV',
            SEC_CODE = 'MMH9',
            CLASS_CODE = 'SPBFUT',
            QTY_LOTS = 1, -- количество для торговли
            OFFSET = 2, --(ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
            SPREAD = 10, --Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
            ChartId = "Sheet11",
            SetStop = true, -- выставлять ли стоп заявки
            CloseSLbeforeClearing = false, -- снимать ли стоп заявки перед клирингом
            fixedstop = false,-- STOPLOSS не рассчитывать по алгоритму, а брать фиксированным из настроек
            isLong  = true, -- доступен лонг
            isShort = true, -- доступен шорт
            trackManualDeals = true, --учитывать ручные сделки не из интерфейса робота,
            maxStop       = 85,                   
            reopenDealMaxStop       = 75,                   
            stopShiftIndexWait       = 17,                   
            shiftStop = true, -- сдвигать стоп (трейил) на величину STOP_LOSS                 
            shiftProfit = true, -- сдвигать профит (трейил) на величину STOP_LOSS/2
            reopenPosAfterStop       = 7,                   
            INTERVAL          = INTERVAL_M3,          -- Таймфрейм графика (для построения скользящих)
            testSizeBars = 1200,
            calculateAlgo = THV,
            iterateAlgo = iterateTHV,
            initAlgo = initTHV,
            setTableAlgoParams  = setTableTHVParams,
            readTableAlgoParams = readTableTHVParams,
            notReadOptimized = true,
            readOptimizedParams = readOptimizedTHV,
            saveOptimizedParams = saveOptimizedTHV,
            settingsAlgo = 
            {
                period    = 37,
                shift = 18,
                koef = 0.9,
                STOP_LOSS         = 45,                   -- Размер СТОП-ЛОССА
                TAKE_PROFIT       = 140                   -- Размер ТЕЙК-ПРОФИТА
            }
        },
        {
            Name    = "sEMA M3",                   
            NAME_OF_STRATEGY = 'sEMA',
            SEC_CODE = 'MMH9',
            CLASS_CODE = 'SPBFUT',
            QTY_LOTS = 1, -- количество для торговли
            OFFSET = 2, --(ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
            SPREAD = 10, --Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
            ChartId = "Sheet11",
            SetStop = true, -- выставлять ли стоп заявки
            CloseSLbeforeClearing = false, -- снимать ли стоп заявки перед клирингом
            fixedstop = false,-- STOPLOSS не рассчитывать по алгоритму, а брать фиксированным из настроек
            isLong  = true, -- доступен лонг
            isShort = true, -- доступен шорт
            trackManualDeals = true, --учитывать ручные сделки не из интерфейса робота,
            maxStop       = 85,                   
            reopenDealMaxStop       = 75,                   
            stopShiftIndexWait       = 17,                   
            shiftStop = true, -- сдвигать стоп (трейил) на величину STOP_LOSS                 
            shiftProfit = true, -- сдвигать профит (трейил) на величину STOP_LOSS/2
            reopenPosAfterStop       = 7,                   
            INTERVAL          = INTERVAL_M3,          -- Таймфрейм графика (для построения скользящих)
            testSizeBars = 4000,
            calculateAlgo = MA,
            iterateAlgo = iterateMA,
            initAlgo = initMA,
            setTableAlgoParams  = setTableMAParams,
            readTableAlgoParams = readTableMAParams,
            readOptimizedParams = readOptimizedMA,
            saveOptimizedParams = saveOptimizedMA,
            settingsAlgo = 
            {
                period    = 46,
                shift = 4,
                STOP_LOSS         = 45,                   -- Размер СТОП-ЛОССА
                TAKE_PROFIT       = 140                   -- Размер ТЕЙК-ПРОФИТА
            }
        },
        {
            Name    = "reg M3",                   
            NAME_OF_STRATEGY = 'iReg',
            SEC_CODE = 'MMH9',
            CLASS_CODE = 'SPBFUT',
            QTY_LOTS = 1, -- количество для торговли
            OFFSET = 2, --(ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
            SPREAD = 10, --Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
            ChartId = "Sheet11",
            maxStop       = 85,                   
            SetStop = true, -- выставлять ли стоп заявки
            CloseSLbeforeClearing = false, -- снимать ли стоп заявки перед клирингом
            fixedstop = false,-- STOPLOSS не рассчитывать по алгоритму, а брать фиксированным из настроек
            isLong  = true, -- доступен лонг
            isShort = true, -- доступен шорт
            trackManualDeals = true, --учитывать ручные сделки не из интерфейса робота,
            reopenDealMaxStop       = 75,                   
            stopShiftIndexWait       = 17,                   
            shiftStop = true, -- сдвигать стоп (трейил) на величину STOP_LOSS                 
            shiftProfit = true, -- сдвигать профит (трейил) на величину STOP_LOSS/2
            reopenPosAfterStop       = 7,                   
            INTERVAL          = INTERVAL_M3,          -- Таймфрейм графика (для построения скользящих)
            testSizeBars = 3240, --270
            calculateAlgo = iReg,
            iterateAlgo = iterateReg,
            initAlgo = initReg,
            setTableAlgoParams  = setTableRegParams,
            readTableAlgoParams = readTableRegParams,
            readOptimizedParams = readOptimizedReg,
            saveOptimizedParams = saveOptimizedReg,
            settingsAlgo = 
            {
                period    = 21,
                degree = 3, -- 1 -линейная, 2 - параболическая, - 3 степени
                shift = 4,
                kstd = 3, --отклонение сигма
                STOP_LOSS         = 45,                   -- Размер СТОП-ЛОССА
                TAKE_PROFIT       = 140                   -- Размер ТЕЙК-ПРОФИТА
            }
        },
        {
            Name    = "NRTR M3",                   
            NAME_OF_STRATEGY = 'NRTR',
            SEC_CODE = 'MMH9',
            CLASS_CODE = 'SPBFUT',
            QTY_LOTS = 1, -- количество для торговли
            OFFSET = 2, --(ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
            SPREAD = 10, --Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
            ChartId = "Sheet11",
            maxStop       = 85,                   
            SetStop = true, -- выставлять ли стоп заявки
            CloseSLbeforeClearing = false, -- снимать ли стоп заявки перед клирингом
            fixedstop = false,-- STOPLOSS не рассчитывать по алгоритму, а брать фиксированным из настроек
            isLong  = true, -- доступен лонг
            isShort = true, -- доступен шорт
            trackManualDeals = true, --учитывать ручные сделки не из интерфейса робота,
            reopenDealMaxStop       = 75,                   
            stopShiftIndexWait       = 17,                   
            shiftStop = true, -- сдвигать стоп (трейил) на величину STOP_LOSS                 
            shiftProfit = true, -- сдвигать профит (трейил) на величину STOP_LOSS/2
            reopenPosAfterStop       = 7,                   
            INTERVAL          = INTERVAL_M3,          -- Таймфрейм графика (для построения скользящих)
            testSizeBars = 1200, --161
            calculateAlgo = NRTR,
            iterateAlgo = iterateNRTR,
            initAlgo = initNRTR,
            setTableAlgoParams  = setTableNRTRParams,
            readTableAlgoParams = readTableNRTRParams,
            readOptimizedParams = readOptimizedNRTR,
            saveOptimizedParams = saveOptimizedNRTR,
            settingsAlgo = 
            {
                Length    = 36,                   -- ПЕРИОД    10
                Kv = 1,                    -- коэффициент 2
                Switch = 0, --1 - HighLow, 2 - CloseClose 1
                ATRfactor = 0,
                barShift = 0, --0
                adaptive = 0,
                zShift = 3,
                numberOfMovesForTargetZone = 4,
                smoothStep = 1,
                StepSize = 0,                  -- шаг
                Percentage = 0,
                rangeCalc = 0,
                STOP_LOSS         = 40,                   -- Размер СТОП-ЛОССА
                TAKE_PROFIT       = 110                   -- Размер ТЕЙК-ПРОФИТА
            }
        }        
    }

    if getSecurityInfo(presets[curPreset].CLASS_CODE, presets[curPreset].SEC_CODE) == nil then
        message("Не удалость получить данные по инструменту: "..presets[curPreset].SEC_CODE.."/"..tostring(presets[curPreset].CLASS_CODE))
        myLog(NAME_OF_STRATEGY.." Не удалость получить данные по инструменту: "..presets[curPreset].SEC_CODE.."/"..tostring(presets[curPreset].CLASS_CODE))
        Run = false
        return false
    end

    initPreset(true, true)
end

function initPreset(needScanOpenCountSLTP, isInitialization)

    setTableAlgoParams      = presets[curPreset].setTableAlgoParams     
    readTableAlgoParams     = presets[curPreset].readTableAlgoParams     
    saveOptimizedParams     = presets[curPreset].saveOptimizedParams     
    readOptimizedParams     = presets[curPreset].readOptimizedParams     
    notReadOptimized        = presets[curPreset].notReadOptimized or false     

    NAME_OF_STRATEGY        = presets[curPreset].NAME_OF_STRATEGY
    ACCOUNT                 = presets[curPreset].ACCOUNT or default_ACCOUNT                  
    CLIENT_CODE             = presets[curPreset].CLIENT_CODE or default_CLIENT_CODE                  
    SEC_CODE                = presets[curPreset].SEC_CODE                   
    CLASS_CODE              = presets[curPreset].CLASS_CODE                   
    QTY_LOTS                = presets[curPreset].QTY_LOTS or QTY_LOTS                   
    INTERVAL                = presets[curPreset].INTERVAL or INTERVAL                   
    SetStop                 = presets[curPreset].SetStop or SetStop                   
    CloseSLbeforeClearing   = presets[curPreset].CloseSLbeforeClearing or CloseSLbeforeClearing                   
    fixedstop               = presets[curPreset].fixedstop or fixedstop
    isLong                  = presets[curPreset].isLong or isLong   
    isShort                 = presets[curPreset].isShort or isShort          
    trackManualDeals        = presets[curPreset].trackManualDeals or trackManualDeals                 
    OFFSET                  = presets[curPreset].OFFSET or OFFSET                  
    SPREAD                  = presets[curPreset].SPREAD or SPREAD          
    maxStop                 = presets[curPreset].maxStop or maxStop
    reopenDealMaxStop       = presets[curPreset].reopenDealMaxStop or reopenDealMaxStop
    stopShiftIndexWait      = presets[curPreset].stopShiftIndexWait or stopShiftIndexWait
    shiftStop               = presets[curPreset].shiftStop or shiftStop
    shiftProfit             = presets[curPreset].shiftProfit or shiftProfit        
    reopenPosAfterStop      = presets[curPreset].reopenPosAfterStop or reopenPosAfterStop           
    ChartId                 = presets[curPreset].ChartId or ChartId
    testSizeBars            = presets[curPreset].testSizeBars or testSizeBars
    STOP_LOSS               = presets[curPreset].settingsAlgo.STOP_LOSS or 0
    TAKE_PROFIT             = presets[curPreset].settingsAlgo.TAKE_PROFIT or 0

    ROBOT_POSTFIX = '/'..'rAL' --идентификатор робота в комментариях к заявкам и сделкам. Для поиска
    if CLASS_CODE == 'QJSIM' or CLASS_CODE == 'TQBR' then 
        ROBOT_POSTFIX = '/'..ROBOT_POSTFIX --идентификатор робота в комментариях к заявкам и сделкам. Для поиска
    end
    ROBOT_CLIENT_CODE = CLIENT_CODE..ROBOT_POSTFIX --идентификатор робота в комментариях к заявкам и сделкам. Для поиска

    local newName = getScriptPath().."\\robot"..NAME_OF_STRATEGY.."_"..SEC_CODE.."Log.txt"
    if logging and newName~= FILE_LOG_NAME then
        FILE_LOG_NAME = getScriptPath().."\\robot"..NAME_OF_STRATEGY.."_"..SEC_CODE.."Log.txt" -- ИМЯ ЛОГ-ФАЙЛА     
        if logFile~=nil then logFile:close() end
        logFile = io.open(FILE_LOG_NAME, "w") -- открывает файл 
        PARAMS_FILE_NAME = getScriptPath().."\\robot"..NAME_OF_STRATEGY.."_"..SEC_CODE.."_int"..tostring(INTERVAL).."_params.csv" -- ИМЯ ЛОГ-ФАЙЛА
    end

    Settings = {}
    myLog(NAME_OF_STRATEGY..' Set preset '..presets[curPreset].Name)    
    for k,v in pairs(presets[curPreset].settingsAlgo) do
        Settings[k] = v
        myLog(k..' '..tostring(v))    
    end
                
    -- Получает ШАГ ЦЕНЫ ИНСТРУМЕНТА

    SEC_PRICE_STEP = getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value
    scale = getSecurityInfo(CLASS_CODE, SEC_CODE).scale
    STEPPRICE = getParamEx(CLASS_CODE, SEC_CODE, "STEPPRICE").param_value
    LOTSIZE = getParamEx(CLASS_CODE, SEC_CODE, "LOTSIZE").param_value
    if CLASS_CODE ~= 'QJSIM' and CLASS_CODE ~= 'TQBR' then 
        if tonumber(STEPPRICE) == 0 or STEPPRICE == nil then
            leverage = 1
        else    
            leverage = STEPPRICE/SEC_PRICE_STEP
        end
        priceKoeff = 1/leverage
    else
        leverage = 1
        priceKoeff = LOTSIZE/math.pow(10, scale)
    end
    
    if needScanOpenCountSLTP then
        local Error = ''
        DS,Error = CreateDataSource(CLASS_CODE, SEC_CODE, INTERVAL)
        -- Проверка
        if DS == nil then
            message(NAME_OF_STRATEGY..' robot:ОШИБКА получения доступа к свечам! '..Error)
            -- Завершает выполнение скрипта
            Run = false
            return
        end
                        
        --DS:SetUpdateCallback(function(...) ds_callback(...) end)
        DS:SetEmptyCallback()
    end
        
    if readOptimizedParams~=nil and not notReadOptimized then
        readOptimizedParams()
        STOP_LOSS          = Settings.STOP_LOSS or STOP_LOSS
        TAKE_PROFIT        = Settings.TAKE_PROFIT or TAKE_PROFIT
    end

    if isInitialization then CreateTable() end
        
    SetCell(t_id, 2, 6, tostring(INTERVAL), INTERVAL)  --i строка, 0 - колонка, v - значение     
    SetCell(t_id, 3, 1, virtCaption..'qnt: '..tostring(QTY_LOTS),    QTY_LOTS)
    SetCell(t_id, 6, 4, tostring(testSizeBars),    testSizeBars)
    SetCell(t_id, 6, 5, ChartId)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 6, 6, tostring(Settings.STOP_LOSS), Settings.STOP_LOSS)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 6, 7, tostring(Settings.TAKE_PROFIT))  --i строка, 0 - колонка, v - значение 

    if setTableAlgoParams~=nil then
        setTableAlgoParams(Settings)    
    end

    calculateAlgo =     presets[curPreset].calculateAlgo
    iterateAlgo =       presets[curPreset].iterateAlgo
    initAlgo =          presets[curPreset].initAlgo

    SetWindowCaption(t_id, (virtualTrade and ' VIRTUAL_' or 'REAL_')..' TRADE '..NAME_OF_STRATEGY..' Robot '..SEC_CODE) -- Устанавливает заголовок

    if calculateAlgo==nil then
        calculateAlgo = simpleAlgo    
    end

    if needScanOpenCountSLTP then       
        LastOpenBarIndex = DS:Size()
        lastStopShiftIndex = DS:Size()
        TransactionPrice = DS:C(DS:Size())
        vallProfit = 0

        local last_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)
        SetCell(t_id, 2, 0, tostring(last_price), last_price) 
        SetCell(t_id, 2, 3, '', 0) --sl
        SetCell(t_id, 2, 4, '', 0) --tp

        if SetStop then
            SetCell(t_id, 3, 6, "KILL ALL SL", 0)  --i строка, 0 - колонка, v - значение 
            SetColor(t_id, 3, 6, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
            SetCell(t_id, 3, 7, "SET SL/TP", 0)  --i строка, 0 - колонка, v - значение 
            SetColor(t_id, 3, 7, RGB(168,255,168), RGB(0,0,0), RGB(168,255,168), RGB(0,0,0))
        else
            SetCell(t_id, 3, 6, "", 0)  --i строка, 0 - колонка, v - значение 
            SetColor(t_id, 3, 6, RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))
            SetCell(t_id, 3, 7, "", 0)  --i строка, 0 - колонка, v - значение 
            SetColor(t_id, 3, 7, RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))
        end
        ROBOT_STATE       = 'FIRSTSTART'
    end

    myLog(NAME_OF_STRATEGY.." NEW "..ROBOT_POSTFIX.." SET: "..tostring(presets[curPreset].Name))
    myLog(NAME_OF_STRATEGY.." CLIENT_CODE: "..tostring(CLIENT_CODE))
    myLog(NAME_OF_STRATEGY.." ACCOUNT: "..tostring(ACCOUNT))
    myLog(NAME_OF_STRATEGY.." CLASS_CODE: "..tostring(CLASS_CODE))
    myLog(NAME_OF_STRATEGY.." SEC: "..tostring(SEC_CODE))
    myLog(NAME_OF_STRATEGY.." PRICE STEP: "..tostring(SEC_PRICE_STEP))
    myLog(NAME_OF_STRATEGY.." SCALE: "..tostring(scale))
    myLog(NAME_OF_STRATEGY.." STEP PRICE: "..tostring(STEPPRICE))
    myLog(NAME_OF_STRATEGY.." LOTSIZE: "..tostring(LOTSIZE))
    myLog(NAME_OF_STRATEGY.." leverage: "..tostring(leverage))
    myLog(NAME_OF_STRATEGY.." priceKoeff: "..tostring(priceKoeff))
    myLog(NAME_OF_STRATEGY.." QTY_LOTS: "..tostring(QTY_LOTS))
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
    myLog(NAME_OF_STRATEGY.." STOP_LOSS: "..tostring(Settings.STOP_LOSS))
    myLog(NAME_OF_STRATEGY.." TAKE_PROFIT: "..tostring(Settings.TAKE_PROFIT))
    myLog(NAME_OF_STRATEGY.." ==================================================")
    myLog(NAME_OF_STRATEGY.." Initialization finished")

end

function main()
    
    SetTableNotificationCallback(t_id, event_callback)
    SetTableNotificationCallback(tv_id, volume_event_callback)

    while Run do 
      
        --if isConnected() == false then
        --    Run = false
        --end

        if not Run then break end

        if ROBOT_STATE == 'ОПТИМИЗАЦИЯ' or needReoptimize then
            myLog(NAME_OF_STRATEGY..' optimizationInProgress = '..tostring(optimizationInProgress))
            if not optimizationInProgress then
                myLog(NAME_OF_STRATEGY..' ROBOT_STATE = '..tostring(ROBOT_STATE))
                optimizationInProgress = true
                doneOptimization = 0
                SetCell(t_id, 4, 6, "STOP OPTIMIZE")
                SetCell(t_id, 2, 7, "OPTIMIZATION "..tostring(doneOptimization).."%", doneOptimization)
                if ROBOT_STATE == 'ОПТИМИЗАЦИЯ' then
                    if iterateAlgo~=nil then
                        iterateAlgo()    
                    end
                    ROBOT_STATE = 'ОСТАНОВЛЕН'
                    BASE_ROBOT_STATE = 'ОСТАНОВЛЕН'
                    SetCell(t_id, 2, 7, ROBOT_STATE)
                else    
                    reoptimize()
                end
                SetCell(t_id, 4, 6, "OPTIMIZE")
            end
        else
        
            local continue = true 
            local ss = getInfoParam("SERVERTIME")
            if string.len(ss) >= 5 then            
                local hh = mysplit(ss,":")
                local str=hh[1]..hh[2]
                serverTime = tonumber(str)
            end

            getTradeState()

            if SetStop == true and OpenCount ~= 0 and ROBOT_STATE ~= 'УСТАНОВКА СТОП ЛОССА' then 
                checkSLbeforeClearing(last_price)
                trailStop(last_price)
            end

            if isTrade and serverTime >= endTradeTime and serverTime < eveningSession then
                isTrade = false
                CurrentDirect = "AUTO"                
                ROBOT_STATE = 'CLOSEALL'
                BASE_ROBOT_STATE = 'ОСТАНОВЛЕН'
                needReoptimize = true
            end

            local dealQnty = QTY_LOTS

            if OpenCount~=0 and (ROBOT_STATE == 'ПЕРЕВОРОТ' or ROBOT_STATE == 'CLOSEALL') then
                if CurrentDirect == "AUTO" then
                    CurrentDirect = OpenCount > 0 and "SELL" or "BUY"
                end
               if continue == true then
                    dealQnty = math.abs(OpenCount)
                    if ROBOT_STATE == 'ПЕРЕВОРОТ' then --переворот делается на размер позиции
                        dealQnty = 2*math.abs(OpenCount)
                    end
                    ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
                end
            end
            
            --Если СОСТОЯНИЕ робота "В ПРОЦЕССЕ СДЕЛКИ"
            if ROBOT_STATE == 'В ПРОЦЕССЕ СДЕЛКИ' then
                                        
                if not Run then return end -- Если скрипт останавливается, не затягивает процесс
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
                    SetCell(t_id, 2, 7, ROBOT_STATE)
                -- Если пытается открыть BUY, а операции лонг по данному инструменту запрещены
                elseif OpenCount == 0 and CurrentDirect == "BUY" and not isLong then
                    myLog(NAME_OF_STRATEGY..' robot: Была первая попытка совершить запрещенную операцию лонг!')
                    if isTrade then
                        ROBOT_STATE = 'ПОИСК СДЕЛКИ'
                    else
                        ROBOT_STATE = 'ОСТАНОВЛЕН'
                    end
                    BASE_ROBOT_STATE = ROBOT_STATE
                    SetCell(t_id, 2, 7, ROBOT_STATE)
                else    
                
                    local continue = Trade(CurrentDirect, dealQnty)

                    if not Run then return end -- Если скрипт останавливается, не затягивает процесс
                    
                    -- Если заявка отправилась
                    if not continue then                                                
                        -- Выводит сообщение
                        message(NAME_OF_STRATEGY..' robot: неудачная попытка открыть сделку!!! Завершение скрипта!!!')
                        myLog(NAME_OF_STRATEGY..' robot: неудачная попытка открыть сделку!!! Завершение скрипта!!!')
                        -- Завершает выполнение скрипта
                        Run = false
                    end

                end
            end         

            --Отработка событий
            if ROBOT_STATE == 'FIRSTSTART' then
                myLog(NAME_OF_STRATEGY..' Первоначальный запуск скрипта '..ROBOT_CLIENT_CODE)
                OpenCount = GetTotalnet()
                curOpenCount = OpenCount
                priceMoveMin = last_price
                priceMoveMax = last_price
                TransactionPrice = last_price or lastDealPrice           
                if trackManualDeals and OpenCount~=0 and not isStopOrderSet(true) then
                    myLog(NAME_OF_STRATEGY..' Установка стоп-лосса после запуска скрипта')
                    Result = SL_TP(DS:C(DS:Size()), OpenCount > 0 and "BUY" or "SELL", OpenCount)
                end
                ROBOT_STATE = BASE_ROBOT_STATE
                SetCell(t_id, 2, 7, ROBOT_STATE)
            end
            if not virtualTrade then
                if ROBOT_STATE == 'ОЖИДАНИЕ СДЕЛКИ' and curOpenCount ~= OpenCount then
                    OpenCount = GetTotalnet()
                    if orderQnty == 0 then ROBOT_STATE = 'УСТАНОВКА СТОП ЛОССА' end
                end
                if (trackManualDeals and curOpenCount ~= OpenCount) or (curOpenCount==0 and OpenCount~=0) then
                    OpenCount = GetTotalnet()
                    ROBOT_STATE = 'УСТАНОВКА СТОП ЛОССА'               
                end
            end                        
            if ROBOT_STATE == 'СНЯТИЕ СТОП ЛОССА' then                               
                continue = KillAllStopOrders()
                if continue ~= true then
                    Run = false
                    message(NAME_OF_STRATEGY..' Закрытие стопа позиции не удалось. Скрипт остановлен')
                    myLog(NAME_OF_STRATEGY..' Закрытие стопа позиции не удалось. Скрипт остановлен')
                end
                ROBOT_STATE = BASE_ROBOT_STATE
                SetCell(t_id, 2, 7, ROBOT_STATE)
            end
            if ROBOT_STATE == 'УСТАНОВКА СТОП ЛОССА' then                               
                if manualKillStop then
                    message('Установка стоп-лосса заблокирована. Установите стоп вручную командой SET SL/TP, для дальнейшего автоматического выставления.')                    
                    myLog(NAME_OF_STRATEGY..' Установка стоп-лосса заблокирована. Установите стоп вручную командой SET SL/TP, для дальнейшего автоматического выставления.')                    
                end
                if SetStop == true and StopForbidden == false then                             
                    myLog(NAME_OF_STRATEGY..' robot: Обработка СТОП заявки '..CurrentDirect..' позиция '..tostring(OpenCount))
                    onChangeOpenCount()
                end
                ROBOT_STATE = BASE_ROBOT_STATE
                SetCell(t_id, 2, 7, ROBOT_STATE)
            end

            if ROBOT_STATE ~= BASE_ROBOT_STATE and ROBOT_STATE ~= 'ОЖИДАНИЕ СДЕЛКИ' then 
                ROBOT_STATE = BASE_ROBOT_STATE 
                SetCell(t_id, 2, 7, ROBOT_STATE)
            end
            
        end

        sleep(75)			
    end
end

-- Функция ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK при остановке скрипта
function OnStop()
    Run = false
    myLog(NAME_OF_STRATEGY.." Script Stoped") 
    if logFile~=nil then logFile:close() end    
    if t_id~= nil then
        DestroyTable(t_id)
    end
    if tv_id~= nil then
        DestroyTable(tv_id)
    end
end

function CreateTable() -- Функция создает таблицу
    
    t_id = AllocTable() -- Получает доступный id для создания
    
    -- Добавляет колонки
    AddColumn(t_id, 0, "1", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 1, "2", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 2, "3", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 3, "4", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 4, "5", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 5, "6", true, QTABLE_DOUBLE_TYPE, 17)
    AddColumn(t_id, 6, "7", true, QTABLE_DOUBLE_TYPE, 18)
    AddColumn(t_id, 7, "8", true, QTABLE_STRING_TYPE, 25)

    tbl = CreateWindow(t_id) -- Создает таблицу
    SetWindowCaption(t_id, (virtualTrade and ' VIRTUAL_' or 'REAL_')..' TRADE '..NAME_OF_STRATEGY..' Robot '..SEC_CODE) -- Устанавливает заголовок
    SetWindowPos(t_id, 980, 120, 730, 160) -- Задает положение и размеры окна таблицы
    
    -- Добавляет строки
    InsertRow(t_id, 1)
    SetCell(t_id, 1, 0, "Price", 0)  --i строка, 0 - колонка, v - значение 
    --SetCell(t_id, 1, 1, "Algo", 0)  --i строка, 0 - колонка, v - значение 
    --SetCell(t_id, 1, 2, "Pos", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 1, 1, "Pos", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 1, 2, "Profit", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 1, 3, "SL", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 1, 4, "TP", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 1, 5, "Algo", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 1, 6, "INTERVAL", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 1, 7, "State", 0)  --i строка, 0 - колонка, v - значение 
    
    InsertRow(t_id, 2)
    SetCell(t_id, 2, 6, tostring(INTERVAL), INTERVAL)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 2, 7, ROBOT_STATE)

    InsertRow(t_id, 3)
    SetCell(t_id, 3, 0, "START", 0)  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 0, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
    SetCell(t_id, 3, 1, virtCaption..'qnt: '..tostring(QTY_LOTS), QTY_LOTS)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 3, 2, "SELL", 0)  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 2, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
    SetCell(t_id, 3, 3, "BUY", 0)  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 3, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
    SetCell(t_id, 3, 4, "REVERSE", 0)  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 4, RGB(200,200,200), RGB(0,0,0), RGB(200,200,200), RGB(0,0,0))
    SetCell(t_id, 3, 5, "CLOSE ALL", 0)  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 5, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
    
    InsertRow(t_id, 4)
    for i,v in ipairs(presets) do
        SetCell(t_id, 4, i-1, "Set "..presets[i].Name, 0)  --i строка, 0 - колонка, v - значение 
        SetColor(t_id, 4, i-1, RGB(200,200,200), RGB(0,0,0), RGB(168,168,164), RGB(0,0,0))
    end
    
    SetCell(t_id, 4, 6, "OPTIMIZE", 0)  --i строка, 0 - колонка, v - значение 

    InsertRow(t_id, 5)
    SetCell(t_id, 5, 4, "testSizeBars", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 5, 5, "ChartId", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 5, 6, "SL", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 5, 7, "TP", 0)  --i строка, 0 - колонка, v - значение 
    
    InsertRow(t_id, 6)
    SetCell(t_id, 6, 4, tostring(testSizeBars),    testSizeBars)
    SetCell(t_id, 6, 5, ChartId)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 6, 6, tostring(Settings.STOP_LOSS), Settings.STOP_LOSS)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 6, 7, tostring(Settings.TAKE_PROFIT))  --i строка, 0 - колонка, v - значение 

    if setTableAlgoParams~=nil then
        setTableAlgoParams(Settings)    
    end

    tv_id = AllocTable() -- таблица ввода значения
    
end

function volume_event_callback(tv_id, msg, par1, par2)
    if par1 == -1 then
        return
    end
    if msg == QTABLE_CHAR then
        if tostring(par2) == "8" then
            local newPrice = string.sub(GetCell(tv_id, par1, 0).image, 1, string.len(GetCell(tv_id, par1, 0).image)-1)
            SetCell(tv_id, par1, 0, tostring(newPrice))
            SetCell(t_id, tstr, tcell, GetCell(tv_id, par1, 0).image, tonumber(GetCell(tv_id, par1, 0).image))
        else
           local inpChar = string.char(par2)
           local newPrice = GetCell(tv_id, par1, 0).image..string.char(par2)            
           SetCell(tv_id, par1, 0, tostring(newPrice))
           if tstr == 3 and tcell == 1 then
                SetCell(t_id, tstr, tcell, virtCaption..'qnt: '..GetCell(tv_id, par1, 0).image, tonumber(GetCell(tv_id, par1, 0).image))
           else
               SetCell(t_id, tstr, tcell, GetCell(tv_id, par1, 0).image, tonumber(GetCell(tv_id, par1, 0).image))
           end
       end
    end
    if (msg==QTABLE_CLOSE) then --закрытие окна
        setParameters()
    end
end

function event_callback(t_id, msg, par1, par2)

    if msg == QTABLE_CHAR then --ChartID
        --message(tostring(par2))
        if tostring(par2) == "86" or tostring(par2) == "204" then --Shift+V
            if not virtualTrade and (OpenCount~=0 or isStopOrderSet()) then
                message(NAME_OF_STRATEGY..' Для включения виртуальной торговли необходимо закрыть позицию и все стоп-заявки')
                myLog(NAME_OF_STRATEGY..' Для включения виртуальной торговли необходимо закрыть позицию и все стоп-заявки')
                return
            end

            SetCell(t_id, 2, 1, '', 0) --pos
            SetCell(t_id, 2, 3, '', 0) --sl
            SetCell(t_id, 2, 4, '', 0) --tp
            
            tpPrice = 0
            slPrice = 0
            oldStop = 0
            OpenCount = 0
            curOpenCount = 0        

            virtualTrade = not virtualTrade
            SetWindowCaption(t_id, (virtualTrade and ' VIRTUAL_' or 'REAL_')..' TRADE '..NAME_OF_STRATEGY..' Robot '..SEC_CODE) -- Устанавливает заголовок
            virtCaption = (virtualTrade and 'virtual ' or 'real ')
            SetCell(t_id, 3, 1, virtCaption..'qnt: '..GetCell(t_id, 3, 1).value, tonumber(GetCell(t_id, 3, 1).value))
            myLog(NAME_OF_STRATEGY..' Изменение режима вирутальной торговли. Перезапускаем скрипт')
            ROBOT_STATE = 'FIRSTSTART'
        elseif tostring(par2) == "8" then
            local newString = string.sub(GetCell(t_id, 6, 5).image, 1, string.len(GetCell(t_id, 6, 5).image)-1)
            SetCell(t_id, 6, 5, newString)
        else
           local inpChar = string.char(par2)
           local newString = GetCell(t_id, 6, 5).image..string.char(par2)            
           SetCell(t_id, 6, 5, newString)
        end
    end

    if msg == QTABLE_LBUTTONDBLCLK then

        if ((par1 == 6 or par1 == 8 or par1 == 10) or (par1 == 2 and par2 == 6) or (par1 == 3 and par2 == 1)) and IsWindowClosed(tv_id) then
            tstr = par1
            tcell = par2
            AddColumn(tv_id, 0, "Value", true, QTABLE_DOUBLE_TYPE, 25)
            tv = CreateWindow(tv_id) 
            SetWindowCaption(tv_id, "Value") 
            SetWindowPos(tv_id, 290, 260, 250, 100)                                
            InsertRow(tv_id, 1)

            local curVal = GetCell(t_id, par1, par2).value
            if par2 == 7 then
                curVal = math.ceil(tonumber(GetCell(t_id, par1, par2).image)) or 0 
            end
            SetCell(tv_id, 1, 0, tostring(curVal), curVal)  --i строка, 0 - колонка, v - значение 
        end
        
        if par1 == 3 and par2 == 0 then -- Start\Stop
            if isTrade == false and ROBOT_STATE ~= "ОПТИМИЗАЦИЯ" then
                startTrade()
            elseif isTrade then
                isTrade = false
                ROBOT_STATE       ='ОСТАНОВЛЕН'
                BASE_ROBOT_STATE  ='ОСТАНОВЛЕН'
                SetCell(t_id, 2, 7, ROBOT_STATE)
                SetCell(t_id, 3, 0, "START")  --i строка, 0 - колонка, v - значение 
                SetColor(t_id, 3, 0, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
                SetCell(t_id, 2, 5, '')
                SetColor(t_id, 2, 5, RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))
            end
        end
        if par1 == 3 and par2 == 2 then -- SELL
            CurrentDirect = 'SELL'
            myLog(NAME_OF_STRATEGY..' Сделка руками '..CurrentDirect)
            setParameters()
            ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
        end
        if par1 == 3 and par2 == 3 then -- BUY
            CurrentDirect = 'BUY'
            myLog(NAME_OF_STRATEGY..' Сделка руками '..CurrentDirect)
            setParameters()
            ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
        end
        if par1 == 3 and par2 == 4 then -- ПЕРЕВОРОТ
            CurrentDirect = 'AUTO'
            myLog(NAME_OF_STRATEGY..' Сделка руками ПЕРЕВОРОТ '..CurrentDirect)
            setParameters()
            ROBOT_STATE = 'ПЕРЕВОРОТ'
        end
        if par1 == 3 and par2 == 5 then -- All Close
            OpenCount = GetTotalnet()
            CurrentDirect = 'AUTO'
            myLog(NAME_OF_STRATEGY..' Сделка руками Закрытие всех позиций')
            ROBOT_STATE = 'CLOSEALL'
        end        
        if par1 == 3 and par2 == 6 and SetStop==true then -- Close SL
            myLog(NAME_OF_STRATEGY..' Закрытие стоп-лосса')
            manualKillStop = true
            TakeProfitPrice = 0
            ROBOT_STATE = 'СНЯТИЕ СТОП ЛОССА'
        end
        if par1 == 3 and par2 == 7 and SetStop==true then -- SET SL
            myLog(NAME_OF_STRATEGY..' Установка стоп-лосса')
            if not isStopOrderSet() then
                setParameters()
                manualKillStop = false
                --lastDealPrice = DS:C(DS:Size())
                stopLevelPrice = DS:C(DS:Size())
                ROBOT_STATE = 'УСТАНОВКА СТОП ЛОССА'
            end
        end

        if par1 == 4 and par2 <= 5 and not isTrade and not optimizationInProgress then 

            local needScanOpenCountSLTP = false            
            if SEC_CODE ~= presets[par2+1].SEC_CODE or CLASS_CODE ~= presets[par2+1].CLASS_CODE then
                myLog(NAME_OF_STRATEGY.." Смена инструмента торгов")
                needScanOpenCountSLTP = true
            end            
            
            if getSecurityInfo(presets[par2+1].CLASS_CODE, presets[par2+1].SEC_CODE) == nil then
                message("Не удалость получить данные по инструменту: "..presets[curPreset].SEC_CODE.."/"..tostring(presets[curPreset].CLASS_CODE))
                myLog(NAME_OF_STRATEGY.." Не удалость получить данные по инструменту: "..presets[curPreset].SEC_CODE.."/"..tostring(presets[curPreset].CLASS_CODE))
                return false
            end
            if not isConnected() and needScanOpenCountSLTP then
                message("Нет подключения к серверу. Смена инструмента невозможна.")
                myLog("Нет подключения к серверу. Смена инструмента невозможна.")
                return false
            end
           
            curPreset = par2+1
            initPreset(needScanOpenCountSLTP)

        end

        if par1 == 4 and par2 == 6 then -- Optimize
            
            if optimizationInProgress then
                stopSignal = true
                return
            end
        
            setParameters()        
            
            ROBOT_STATE       = 'ОПТИМИЗАЦИЯ'
            BASE_ROBOT_STATE  = 'ОПТИМИЗАЦИЯ'

            if isTrade then
                isTrade = false
                SetCell(t_id, 2, 7, ROBOT_STATE)
                SetCell(t_id, 3, 0, "START")  --i строка, 0 - колонка, v - значение 
                SetColor(t_id, 3, 0, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
                SetCell(t_id, 2, 5, '')
                SetColor(t_id, 2, 5, RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))
            end    

            INTERVAL = GetCell(t_id, 2, 6).value

            local Error = ''
            DS,Error = CreateDataSource(CLASS_CODE, SEC_CODE, INTERVAL)
            -- Проверка
            if DS == nil then
                message(NAME_OF_STRATEGY..' robot:ОШИБКА получения доступа к свечам! '..Error)
                -- Завершает выполнение скрипта
                Run = false
                return
            end

        end        
 
    end
    if (msg==QTABLE_CLOSE) then --закрытие окна
        stopSignal = true
        Run = false
    end
end

--ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ТОРГОВЛИ

function setParameters()

    if readTableAlgoParams~=nil then
        readTableAlgoParams()    
    end
    
    testSizeBars = GetCell(t_id, 6, 4).value
    ChartId = GetCell(t_id, 6, 5).image
    QTY_LOTS = math.ceil(GetCell(t_id, 3, 1).value or 0)
    STOP_LOSS = math.ceil(GetCell(t_id, 6, 6).value or 0)
    TAKE_PROFIT = math.ceil(tonumber(GetCell(t_id, 6, 7).image) or 0)
    shiftStop          = presets[curPreset].shiftStop                   
    shiftProfit        = presets[curPreset].shiftProfit                   
    INTERVAL = GetCell(t_id, 2, 6).value

    myLog(NAME_OF_STRATEGY..' Установка параметров '..' INTERVAL '..tostring(INTERVAL)..' STOP_LOSS '..tostring(STOP_LOSS)..' TAKE_PROFIT '..tostring(TAKE_PROFIT)..' shiftStop '..tostring(shiftStop)..' shiftProfit '..tostring(shiftProfit))

end

function startTrade()
   
    myLog(NAME_OF_STRATEGY..' robot: старт торговли')
    setParameters()

    lastTradeDirection = 0
    currentTrend = 0
    slIndex = 0
    workedStopPrice = 0
    lastStopShiftIndex = 0
    
    if virtualTrade then
        slPrice = GetCell(t_id, 2, 3).value
        tpPrice = GetCell(t_id, 2, 4).value
        oldStop = slPrice        
    end   

    isStopOrderSet(true)
    
    local Error = ''
    DS,Error = CreateDataSource(CLASS_CODE, SEC_CODE, INTERVAL)
    -- Проверка
    if DS == nil then
        message(NAME_OF_STRATEGY..' robot:ОШИБКА получения доступа к свечам! '..Error)
        -- Завершает выполнение скрипта
        Run = false
        return
    end
    
    calcAlgoValue={}
    
    if initAlgo~=nil then
        initAlgo()    
    end

    beginIndex = DS:Size()-testSizeBars
    Settings.beginIndexToCalc = math.max(1, beginIndex - 1000)

    for i = Settings.beginIndexToCalc, DS:Size()-1 do
        calculateAlgo(i, Settings)
    end
    if ChartId ~= nil then
        stv.UseNameSpace(ChartId)
        stv.SetVar('algoResults', calcChartResults)                       
    end

    lastCalculatedBar = DS:Size()
    manualKillStop = false
    LastOpenBarIndex = DS:Size()

    --myLog(NAME_OF_STRATEGY.." #calcAlgoValue "..tostring(#calcAlgoValue).." roundAlgoVal "..tostring(roundAlgoVal).." trend "..tostring(trend[DS:Size()-1]))
    
    local currentTradeDirection = getTradeDirection(DS:Size()-1, calcAlgoValue, trend)
    if currentTradeDirection == -1 then
        CurrentDirect = 'SELL'
        SetColor(t_id, 2, 5, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
    elseif currentTradeDirection == 1 then
        CurrentDirect = 'BUY'
        SetColor(t_id, 2, 5, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
    end

    local roundAlgoVal = round(calcAlgoValue[DS:Size()-1], scale)
    SetCell(t_id, 2, 5, CurrentDirect..'/'..tostring(roundAlgoVal), roundAlgoVal) 

    --SetCell(t_id, 2, 5, CurrentDirect)
    TransactionPrice = DS:C(DS:Size())
    SetCell(t_id, 3, 0, "STOP")  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 0, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
    isTrade = true
    ROBOT_STATE       ='ПОИСК СДЕЛКИ'
    BASE_ROBOT_STATE       ='ПОИСК СДЕЛКИ'
    SetCell(t_id, 2, 7, ROBOT_STATE)

end

function checkSLbeforeClearing()
    
    if CloseSLbeforeClearing and SetStop == true and OpenCount ~= 0 and CLASS_CODE ~= 'QJSIM' and CLASS_CODE ~= 'TQBR' and not manualKillStop then 
                        
        if ((serverTime>=1350 and serverTime<1400) or (serverTime>=endTradeTime and serverTime<1845) or (serverTime>=2345 and serverTime<2350)) and StopForbidden == false then
            StopForbidden = true
            myLog(NAME_OF_STRATEGY..' Закрытие стоп-лосса перед клирингом')
            --myLog(NAME_OF_STRATEGY.." StopForbidden "..tostring(StopForbidden))
            KillAllStopOrders()
            --needReoptimize = true
        end
        
        if ((serverTime>=1405 and serverTime < 1410) or serverTime>=1905) and StopForbidden == true then
            
            StopForbidden = false
            
            if not isStopOrderSet() then 
                myLog(NAME_OF_STRATEGY..' Восстановление стоп-лосса после клиринга')
                stopLevelPrice = last_price
                ROBOT_STATE = 'УСТАНОВКА СТОП ЛОССА'
            end
        end		  
    end

end

function trailStop()

	--трейлим стоп
	if OpenCount ~= 0 and (shiftStop or shiftProfit) and isConnected() then 
                 
        isPriceMove = isPriceMove or ROBOT_STATE ~= 'ОЖИДАНИЕ СДЕЛКИ' and (OpenCount < 0 and STOP_LOSS~=0 and round(TransactionPrice - priceMoveMin, scale) >= STOP_LOSS*priceKoeff) or (OpenCount > 0 and STOP_LOSS~=0 and round(priceMoveMax - TransactionPrice, scale) >= STOP_LOSS*priceKoeff)
        
        if (isPriceMove or (OpenCount~=0 and lastStopShiftIndex~=0 and (DS:Size() - lastStopShiftIndex) > stopShiftIndexWait)) and not manualKillStop and not StopForbidden and STOP_LOSS~=0 then
            myLog('lastDealPrice '..tostring(lastDealPrice)..' TransactionPrice '..tostring(TransactionPrice)..' DS:Size() '..tostring(DS:Size())..' lastStopShiftIndex '..tostring(lastStopShiftIndex)..' priceMoveMin '..tostring(priceMoveMin)..' priceMoveMax '..tostring(priceMoveMax)..' isPriceMove '..tostring(isPriceMove)..' OpenCount '..tostring(OpenCount)..' PRICE_SHIFT '..tostring(STOP_LOSS*priceKoeff)..' TransactionPrice - priceMoveMin '..tostring(round(TransactionPrice - priceMoveMin, scale))..' priceMoveMax - TransactionPrice '..tostring(round(priceMoveMax - TransactionPrice, scale)))
			myLog(NAME_OF_STRATEGY..' Сдвиг стоп-лосса, isPriceMove '..tostring(isPriceMove))
            stopLevelPrice = last_price
            ROBOT_STATE = 'УСТАНОВКА СТОП ЛОССА'
            --if manualKillStop then
            --    message('Установка стоп-лосса заблокирована. Установите стоп вручную командой SET SL/TP, для дальнейшего автоматического выставления.')                    
            --    myLog(NAME_OF_STRATEGY..' Установка стоп-лосса заблокирована. Установите стоп вручную командой SET SL/TP, для дальнейшего автоматического выставления.')                    
            --end
            --if StopForbidden == false then                             
            --    myLog(NAME_OF_STRATEGY..' robot: Обработка СТОП заявки '..CurrentDirect..' позиция '..tostring(OpenCount))
            --    onChangeOpenCount(last_price)
            --end
        end
            
	end

end

function reoptimize()
    
    ROBOT_STATE = 'ОПТИМИЗАЦИЯ'
    BASE_ROBOT_STATE = 'ОПТИМИЗАЦИЯ'

    if isTrade then
        isTrade = false
    end    
    
    SetCell(t_id, 2, 7, ROBOT_STATE)
    SetCell(t_id, 3, 0, "START")  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 0, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
    SetCell(t_id, 2, 5, '')
    SetColor(t_id, 2, 5, RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))

    setParameters()
    lastSignalIndex = {}
    
    myLog(NAME_OF_STRATEGY..' Старт реопртимизации')

    if virtualTrade then
        if tpPrice~=0 then vtpPrice = tpPrice end
        if slPrice~=0 then vslPrice = slPrice end
    end

    if iterateAlgo~=nil then
        iterateAlgo()    
    end

    needReoptimize = false

    if virtualTrade then
        if vtpPrice~=0 then tpPrice = vtpPrice end
        if vslPrice~=0 then slPrice = vslPrice end
    end

    if serverTime < endTradeTime then
        startTrade()
    else
        ROBOT_STATE = 'ОСТАНОВЛЕН'
        BASE_ROBOT_STATE = 'ОСТАНОВЛЕН'
        SetCell(t_id, 2, 7, ROBOT_STATE)
    end

    if isTrade then
        local currentTradeDirection = getTradeDirection(DS:Size()-1, calcAlgoValue, trend) 
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

function getTradeState()

    local index = DS:Size()
    if isTrade and DS:Size() > lastCalculatedBar then 
        
        lastCalculatedBar = DS:Size()
        
        calculateAlgo(DS:Size()-1, Settings)
        --myLog(NAME_OF_STRATEGY.." index "..tostring(DS:Size()-1).." "..tostring(toYYYYMMDDHHMMSS(DS:T(DS:Size()-1))).." trend "..tostring(trend[DS:Size()-1]))
        --myLog(NAME_OF_STRATEGY..' DS:Size() '..tostring(DS:Size())..' calcAlgoValue[DS:Size()-1] '..tostring(calcAlgoValue[DS:Size()-1])..', ATR[DS:Size()-1]: '..tostring(ATR[DS:Size()-1])..' ATRfactor: '..tostring(ATRfactor))
        
        if ChartId ~= nil then
            stv.UseNameSpace(ChartId)
            --myLog('calcChartResults '..tostring(calcChartResults)..', calcChartResults[] '..tostring(calcChartResults[DS:Size()-1]))
            stv.SetVar('algoResults', calcChartResults)                       
        end
                        
        local dealTime = serverTime >= startTradeTime
        if dealTime then 
            local time = math.ceil((DS:T(DS:Size()).hour + DS:T(DS:Size()).min/100)*100)
            local time1 = math.ceil((DS:T(DS:Size()-1).hour + DS:T(DS:Size()-1).min/100)*100)
            tradeBegin = time >= startTradeTime and time1 < startTradeTime
        end

        local tradeSignal = getTradeSignal(DS:Size(), calcAlgoValue, trend)
        local currentTradeDirection = getTradeDirection(DS:Size()-1, calcAlgoValue, trend)
        if not dealTime then
            lastTradeDirection = currentTradeDirection
        end

        if dealTime and slIndex ~= 0 and (index - slIndex) == reopenPosAfterStop then
            slIndex = index
            myLog(NAME_OF_STRATEGY.." тест после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex))..' '..tostring(workedStopPrice))
            if currentTradeDirection > 0 and workedStopPrice<DS:O(index) then
                if logDeals then
                    myLog(NAME_OF_STRATEGY.." переоткрытие лонга после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
                end
                tradeBegin = true
                reopenAfterStop = true
            end
            if currentTradeDirection < 0 and workedStopPrice>DS:O(index) then
                if logDeals then
                    myLog(NAME_OF_STRATEGY.." переоткрытие шорта после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
                end
                tradeBegin = true
                reopenAfterStop = true
            end
        end 
        
        if trend ~= nil then
            if tradeDirection == 0 then
                CurrentDirect = "AUTO"
                ROBOT_STATE = 'CLOSEALL'
            end
        end

        --if ROBOT_STATE == 'ПОИСК СДЕЛКИ' and dealTime and OpenCount <= 0 and DS:Size() > LastOpenBarIndex and ((trend[DS:Size()-1] > 0 and trend[DS:Size()-2] <= 0) or (tradeBegin and trend[DS:Size()-1] > 0)) then
        if DS:Size() > LastOpenBarIndex and ROBOT_STATE == 'ПОИСК СДЕЛКИ' and dealTime and OpenCount <= 0 and (tradeSignal == 1 or lastTradeDirection == 1) then
            
            tradeBegin = false

            lastSignalIndex[#lastSignalIndex + 1] = DS:Size()
            LastOpenBarIndex = DS:Size()
            lastTradeDirection = 0

            -- Задает направление НА ПОКУПКУ
            CurrentDirect = 'BUY'
            
            myLog(NAME_OF_STRATEGY..' CurrentDirect '..tostring(CurrentDirect))
            SetCell(t_id, 2, 7, ROBOT_STATE)

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
			   			   
        --elseif ROBOT_STATE == 'ПОИСК СДЕЛКИ' and dealTime and OpenCount >= 0 and DS:Size() > LastOpenBarIndex and ((trend[DS:Size()-1] < 0 and trend[DS:Size()-2] >= 0) or (tradeBegin and trend[DS:Size()-1] < 0)) then
        elseif DS:Size() > LastOpenBarIndex and ROBOT_STATE == 'ПОИСК СДЕЛКИ' and dealTime and OpenCount >= 0 and (tradeSignal == -1 or lastTradeDirection == -1) then
            
            tradeBegin = false

            lastSignalIndex[#lastSignalIndex + 1] = DS:Size()
            LastOpenBarIndex = DS:Size()
            lastTradeDirection = 0
            
            CurrentDirect = 'SELL'
            myLog(NAME_OF_STRATEGY..' CurrentDirect '..tostring(CurrentDirect))
            SetCell(t_id, 2, 7, ROBOT_STATE)

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
            local roundAlgoVal = round(calcAlgoValue[DS:Size()-1], scale)
            local tradeDirect = currentTradeDirection==1 and 'BUY' or 'SELL'
            SetCell(t_id, 2, 5, tradeDirect..'/'..tostring(roundAlgoVal), roundAlgoVal) 
            if currentTradeDirection == -1 then
                SetColor(t_id, 2, 5, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
            else
                SetColor(t_id, 2, 5, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
            end
        end
    
    end    
end

-- Проверка движения цены
function OnParam(class_code, sec_code)
    
    if Run and class_code == CLASS_CODE and sec_code==SEC_CODE then
        
        last_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)
        
        local lp = GetCell(t_id, 2, 0).value or last_price
        --myLog(NAME_OF_STRATEGY.." last price "..tostring(last_price).." lp "..tostring(lp))
        SetCell(t_id, 2, 0, tostring(last_price), last_price) 
        if lp < last_price then
            Highlight(t_id, 2, 0, SeaGreen, QTABLE_DEFAULT_COLOR,1000)		-- подсветка мягкий, зеленый
        elseif lp > last_price then
            Highlight(t_id, 2, 0, RosyBrown, QTABLE_DEFAULT_COLOR,1000)		-- подсветка мягкий розовый
        --elseif lp == last_price then
        --    Highlight(t_id, 2, 0, LemonChiffon, QTABLE_DEFAULT_COLOR,1000)	-- подсветка мягкий желтый
        end   
        
        if OpenCount~=0 then
            --local curDealProfit = OpenCount>0 and (last_price - lastDealPrice) or (lastDealPrice - last_price)
            local curDealProfit = round((last_price - lastDealPrice)*OpenCount/priceKoeff, scale)
            SetCell(t_id, 2, 2, tostring(curDealProfit), curDealProfit)                
            
            priceMoveMin = math.min(priceMoveMin, last_price)
            priceMoveMax = math.max(priceMoveMax, last_price)        
        end 

        if optimizationInProgress then
            SetCell(t_id, 2, 7, "OPTIMIZATION "..tostring(doneOptimization).."%", doneOptimization)
            return
        end
    
        if virtualTrade then
            if OpenCount > 0 and last_price >= tpPrice and tpPrice~=0 then
                myLog(NAME_OF_STRATEGY.." Take profit")
                CurrentDirect = "AUTO"
                ROBOT_STATE = 'CLOSEALL'
                slIndex = index
                workedStopPrice = tpPrice
            end
            if OpenCount < 0 and last_price <= tpPrice and tpPrice~=0 then
                myLog(NAME_OF_STRATEGY.." Take profit")
                CurrentDirect = "AUTO"
                ROBOT_STATE = 'CLOSEALL'
                slIndex = index
                workedStopPrice = tpPrice
            end
            if OpenCount > 0 and last_price <= slPrice and slPrice~=0 then
                myLog(NAME_OF_STRATEGY.." Stop loss")
                CurrentDirect = "AUTO"
                ROBOT_STATE = 'CLOSEALL'
                slIndex = index
                workedStopPrice = slPrice
            end
            if OpenCount < 0 and last_price >= slPrice and slPrice~=0 then
                myLog(NAME_OF_STRATEGY.." Stop loss")
                CurrentDirect = "AUTO"
                ROBOT_STATE = 'CLOSEALL'
                slIndex = index
                workedStopPrice = slPrice
            end
        end
    
    end

end

function GetTotalnet(justGetCount)

    local pos = 0
    local avgPrice = 0
    --SetCell(t_id, 2, 2, '', 0)                
    
    if virtualTrade then
        pos = OpenCount
        avgPrice = lastDealPrice
    else
        -- ФЬЮЧЕРСЫ, ОПЦИОНЫ
        if CLASS_CODE == 'SPBFUT' or CLASS_CODE == 'SPBOPT' then
            for i = 0,getNumberOf('futures_client_holding') - 1 do
                local futures_client_holding = getItem('futures_client_holding',i)
                if futures_client_holding.sec_code == SEC_CODE then
                    pos = futures_client_holding.totalnet
                    avgPrice = futures_client_holding.avrposnprice
                    --myLog(NAME_OF_STRATEGY..' GetTotalnet: pos '..tostring(pos)..', fut_limit.totalnet '..tostring(futures_client_holding.totalnet))                    
                end
            end
        -- АКЦИИ
        elseif CLASS_CODE == 'TQBR' or CLASS_CODE == 'QJSIM' then
            local lotsize = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"lotsize").param_value)
            if lotsize == 0 or lotsize == nil then
                lotsize = 1
            end
            for i = 0,getNumberOf('depo_limits') - 1 do
                local depo_limit = getItem("depo_limits", i)
                if depo_limit.sec_code == SEC_CODE
                --and depo_limit.trdaccid == ACCOUNT
                and depo_limit.limit_kind == 0 
                then         
                    pos = depo_limit.currentbal/lotsize
                    avgPrice = depo_limit.awg_position_price
                    --myLog(NAME_OF_STRATEGY..' depo_limit.sec_code '..tostring(depo_limit.sec_code)..' depo_limit.limit_kind '..tostring(depo_limit.limit_kind)..' depo_limit.awg_position_price '..tostring(depo_limit.awg_position_price)..', depo_limit.currentbal '..tostring(depo_limit.currentbal))                    
                    break
                end
            end
        end
    
        local avgOrderPrice = getAvgPrice(pos)*priceKoeff
        if avgOrderPrice~=0 then
            avgPrice = avgOrderPrice
        end

    end

    if justGetCount == true then return pos end

    if pos == 0 then
        SetCell(t_id, 2, 1, '', 0)
    else
        SetCell(t_id, 2, 1, tostring(pos)..'/'..tostring(avgPrice), avgPrice)
    end

    lastDealPrice = avgPrice
    stopLevelPrice = lastDealPrice
    
    if pos == 0 then
        SetColor(t_id, 2, 1, RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))
    elseif pos>0 then
        SetColor(t_id, 2, 1, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
    else                        
        SetColor(t_id, 2, 1, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
    end

    return pos, avgPrice
end

function getAvgPrice(pos)
    
    local avgPrice = 0

    if pos~=0 then

        function myFind(C,S,F)
            return (C == CLASS_CODE) and (S == SEC_CODE) and (bit.band(F,0x2)==0 and bit.band(F,0x1)==0)
        end
        local res=1
        local ord = "trades"
        local tradeTable = SearchItems(ord, 0, getNumberOf(ord)-1, myFind, "class_code,sec_code,flags")
        if (tradeTable ~= nil) and (#tradeTable > 0) then

            local netCount = math.abs(pos)

            for tN=#tradeTable,1,-1 do
                
                if netCount <= 0 then
                    break
                end

                trade = getItem('trades', tradeTable[tN])
                if trade ~= nil then
                    local itsClosePos = (pos>0 and bit.band(trade.flags,0x4)~=0) or (pos<0 and bit.band(trade.flags,0x4)==0)
                    myLog(NAME_OF_STRATEGY.." сделка ордер "..tostring(trade.order_num).." trade.qty "..tostring(trade.qty)..' netCount '..tostring(netCount)..' client_code '..tostring(client_code)..' ROBOT_CLIENT_CODE '..tostring(ROBOT_CLIENT_CODE))
                    myLog(NAME_OF_STRATEGY..' сделка  num '..tostring(trade.trade_num).." флаг 0x4 "..tostring(bit.band(trade.flags,0x4))..' itsClosePos '..tostring(itsClosePos))  
                    if not itsClosePos then
                        avgPrice = avgPrice+trade.value*math.min(trade.qty, netCount)/trade.qty
                        netCount = netCount-trade.qty
                        myLog(NAME_OF_STRATEGY..' avgPrice '..tostring(avgPrice)..' netCount '..tostring(netCount))  
                    end
                end
            end
            if pos~=0 then
                avgPrice = round(math.abs(avgPrice/pos), scale)
            end
            if netCount>0 then
                avgPrice = 0
            end
            myLog(NAME_OF_STRATEGY..' avgPrice '..tostring(avgPrice))  
        end

    end

    return avgPrice
end

function onChangeOpenCount()

    if not SetStop then return end
    
    local isStop = isStopOrderSet()
    myLog("===============================================================")
    myLog(NAME_OF_STRATEGY..' Изменился размер позиции, position '..tostring(OpenCount)..', проверка установленных ордеров '..ROBOT_CLIENT_CODE..', isStop '..tostring(isStop))

    if not isStop and OpenCount~=0 then
        TransactionPrice = stopLevelPrice
        myLog(NAME_OF_STRATEGY..' Установка стоп-лосса onChangeOpenCount, позиция '..tostring(OpenCount))
        local result = SL_TP(stopLevelPrice, OpenCount > 0 and "BUY" or "SELL", OpenCount)
        if result then 
            priceMoveMin = stopLevelPrice
            priceMoveMax = stopLevelPrice
        end
    elseif isStop then
        myLog(NAME_OF_STRATEGY..': Закрытие стоп-лосса onChangeOpenCount')
        local continue = KillAllStopOrders(OpenCount == 0)
        TransactionPrice = stopLevelPrice
        if continue ~= true then
            Run = false
            message(NAME_OF_STRATEGY..'Закрытие стопа позиции не удалось. Скрипт остановлен')
            myLog(NAME_OF_STRATEGY..'Закрытие стопа позиции не удалось. Скрипт остановлен')
        end 
        
        local stopOpenCount = GetTotalnet(true)
        if stopOpenCount~=curOpenCount then
            myLog(NAME_OF_STRATEGY..' Успел измениться размер позиции. Установка стоп-лосса отменена, позиция: '..tostring(stopOpenCount))
            return
        end
        if OpenCount~=0 then
            myLog(NAME_OF_STRATEGY..' Установка стоп-лосса onChangeOpenCount, позиция '..tostring(OpenCount))
            local result = SL_TP(stopLevelPrice, OpenCount > 0 and "BUY" or "SELL", OpenCount)
            if result then 
                priceMoveMin = stopLevelPrice
                priceMoveMax = stopLevelPrice
            end        
        end 
    end

    if OpenCount == 0 then
        priceMoveMin = 0
        priceMoveMax = 0
        tpPrice = 0
        slPrice = 0
        oldStop = 0
        lastStopShiftIndex = 0
        SetCell(t_id, 2, 2, '', 0)                
        SetCell(t_id, 2, 3, '', slPrice) 
        SetCell(t_id, 2, 4, '', tpPrice)                
    end

end

function OnFuturesClientHolding(fut_limit)
    
    if not virtualTrade and fut_limit.sec_code == SEC_CODE then        
        curOpenCount = fut_limit.totalnet
        --myLog(NAME_OF_STRATEGY..' OnFuturesClientHolding: OpenCount '..tostring(OpenCount)..', fut_limit.totalnet '..tostring(fut_limit.totalnet))
    end

end

function OnDepoLimit(depo_limit)

    if not virtualTrade and depo_limit.sec_code == SEC_CODE and depo_limit.limit_kind == 0 then
        curOpenCount = depo_limit.currentbal/LOTSIZE
    end
end

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
    
    if not virtualTrade and trade.sec_code == SEC_CODE and trade.class_code == CLASS_CODE and trade.price ~=0 then
                
        if countOrders[trade.trade_num] ~=nil and orderQnty==0 then return end        
        myLog(NAME_OF_STRATEGY..' OnTrade сделка '..tostring(trade.trade_num)..' countOrders '..tostring(countOrders[trade.trade_num])..', trans_id '..tostring(trans_id)..', trade.trans_id '..tostring(trade.trans_id)..', количество '..tostring(trade.qty)..', осталось '..tostring(orderQnty)..', ROBOT_STATE '..tostring(ROBOT_STATE))
        countOrders[trade.trade_num] = {['price'] = trade.price, ['qty'] = trade.qty}

        if ROBOT_STATE == 'ОЖИДАНИЕ СДЕЛКИ' and trade.trans_id == trans_id then
            if bit.band(trade.flags,0x2)==0 and bit.band(trade.flags,0x1)==0 then
                orderQnty = orderQnty - trade.qty
                robotOpenCount = robotOpenCount + (bit.band(trade.flags,0x4)~=0 and -1 or 1)*trade.qty
                lastDealPrice = trade.price
                stopLevelPrice = lastDealPrice
                TransactionPrice = trade.price
                TakeProfitPrice = 0
                myLog(NAME_OF_STRATEGY..' robot: Открыта сделка '..tostring(trade.trade_num)..' по ордеру '..tostring(trade.order_num)..', по цене '..tostring(lastDealPrice)..', количество '..tostring(trade.qty)..', осталось '..tostring(orderQnty))
            end 
        elseif trackManualDeals then
            if bit.band(trade.flags,0x2)==0x0 and bit.band(trade.flags,0x1)==0x0 then
                lastDealPrice = trade.price
                stopLevelPrice = lastDealPrice
                TransactionPrice = trade.price
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
        if stopOrder.brokerref:find(ROBOT_POSTFIX) == nil then return end

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

function isStopOrderSet(getStopPrice)
    
    if virtualTrade then
        return slPrice~=0 or tpPrice~=0
    end

    function myFind(C,S,F,B)
        return (C == CLASS_CODE) and (S == SEC_CODE) and (bit.band(F, 0x1) ~= 0) and (B:find(ROBOT_POSTFIX))
    end
    local ord = "stop_orders"
    local orders = SearchItems(ord, 0, getNumberOf(ord)-1, myFind, "class_code,sec_code,flags,brokerref")

    if (orders ~= nil) and (#orders > 0) then
        if getStopPrice == true then
            local stop_order = getItem(ord, orders[#orders])
            if stop_order ~= nil and type(stop_order) == "table" then
                tpPrice = stop_order.condition_price
                slPrice = stop_order.condition_price2
                if stop_order.stop_order_type == 1 then
                    slPrice = stop_order.condition_price
                    tpPrice = 0
                elseif stop_order.stop_order_type == 6 then
                    tpPrice = stop_order.condition_price
                    slPrice = 0
                end
                SetCell(t_id, 2, 3, tostring(slPrice), slPrice) --sl
                SetCell(t_id, 2, 4, tostring(tpPrice), tpPrice) --tp
                oldStop = slPrice
                stop_order_num = stop_order.order_num
                TakeProfitPrice = tpPrice
                myLog(NAME_OF_STRATEGY..' Найдена стоп-заявка по на позицю '..stop_order.sec_code..' number: '..tostring(stop_order_num)..' stop_order_type: '..tostring(stop_order.stop_order_type)..' stop_order.qty: '..tostring(stop_order.qty)..' stop_order.brokerref: '..tostring(stop_order.brokerref))                
                myLog(NAME_OF_STRATEGY..' STOP LOSS: '..tostring(slPrice)..' TAKE PROFIT: '..tostring(tpPrice))                
            end
        end
        return true
    end
    
    SetCell(t_id, 2, 3, '', 0) --sl
    SetCell(t_id, 2, 4, '', 0) --tp
    
    tpPrice = 0
    slPrice = 0
    oldStop = 0

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

--Есть ли установленный лимитный ордер тейк-профит 1
function isOrderSet(getOrderPrice)
    
    function myFind(C,S,F,B)
        return (C == CLASS_CODE) and (S == SEC_CODE) and (bit.band(F, 0x1) ~= 0) and (B:find(ROBOT_POSTFIX)) and (OpenCount==0 or (OpenCount>0 and bit.band(F,0x4)~=0 or OpenCount<0 and bit.band(F,0x4)==0))
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

-- Проверяет по номеру исполнена ли заявка 
function CheckOrderExecuted(ord, order_num)
    -- Перебирает таблицу стоп-заявок от последней к первой
    for i=getNumberOf(ord) - 1, 0, -1 do
       -- Получает стоп-заявку из строки таблицы с индексом i
       local order = getItem(ord, i)
       -- Если номер транзакции совпадает
       if order.order_num == order_num then
          -- Если стоп-заявка активна
          if bit.band(order.flags,0x2)==0 + bit.band(order.flags,0x1) == 0 then
             return true
          else
             return false
          end
       end
    end
end

function GetCorrectPrice(price) -- STRING
    -- Получает точность цены по инструменту
    -- Получает минимальный шаг цены инструмента
    local PriceStep = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value)
    -- Если после запятой должны быть цифры
    if scale > 0 then
       price = tostring(price)
       -- Ищет в числе позицию запятой, или точки
       local dot_pos = price:find('.')
       local comma_pos = price:find(',')
       -- Если передано целое число
       if dot_pos == nil and comma_pos == nil then
          -- Добавляет к числу ',' и необходимое количество нулей и возвращает результат
          price = price..','
          for i=1,scale do price = price..'0' end
          return price
       else -- передано вещественное число         
          -- Если нужно, заменяет запятую на точку 
          if comma_pos ~= nil then price:gsub(',', '.') end
          -- Округляет число до необходимого количества знаков после запятой
          price = round(tonumber(price), scale)
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
-----------------------------
-- ОСНОВНЫЕ ФУНКЦИИ ТОРГОВЛИ--
-----------------------------

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

-- Совершает СДЕЛКУ указанного типа (Type) ["BUY", или "SELL"] по рыночной(текущей) цене размером в 1 лот,
--- возвращает цену открытой сделки, либо FALSE, если невозможно открыть сделку
function Trade(Type, qnt)

    if isConnected() == false then
        return false
    end

    --Получает ID транзакции
    trans_id = trans_id + 1 
    local Price = 0
    local Operation = ''
    --Устанавливает цену и операцию, в зависимости от типа сделки и от класса инструмента
    if Type == 'BUY' then
       if CLASS_CODE ~= 'QJSIM' and CLASS_CODE ~= 'TQBR' then Price = getParamEx(CLASS_CODE, SEC_CODE, 'offer').param_value + 20*SEC_PRICE_STEP end -- по цене, завышенной на 10 мин. шагов цены
       Operation = 'B'
    else
       if CLASS_CODE ~= 'QJSIM' and CLASS_CODE ~= 'TQBR' then Price = getParamEx(CLASS_CODE, SEC_CODE, 'bid').param_value - 20*SEC_PRICE_STEP end -- по цене, заниженной на 10 мин. шагов цены
       Operation = 'S'
    end

    -- Заполняет структуру для отправки транзакции
    myLog(NAME_OF_STRATEGY..' robot: Transaction '..Type..' '..tostring(DS:C(DS:Size())).." qnty: "..tostring(qnt).." trans id: "..tostring(trans_id))    
    
    slIndex = 0
    workedStopPrice = 0
    slPrice = 0
    oldStop = 0
    tpPrice = 0
    lastStopShiftIndex = 0
    TakeProfitPrice = 0

    if virtualTrade then
        
        local openLong = nil
        local closeLong = nil
        local openShort = nil
        local closeShort = nil
                
        local dealPrice = DS:C(DS:Size())
        if getDOMPrice then
            if Type == 'BUY' then
                dealPrice = round(tonumber(getParamEx(CLASS_CODE, SEC_CODE, 'offer').param_value), scale)
            else
                dealPrice = round(tonumber(getParamEx(CLASS_CODE, SEC_CODE, 'bid').param_value), scale)
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
            OpenCount = OpenCount + qnt        
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
            OpenCount = OpenCount - qnt        
        end
                
        vallProfit = vallProfit + vdealProfit
        SetCell(t_id, 4, 7, 'all profit '..tostring(vallProfit)) 
        SetCell(t_id, 2, 2, '', 0) 
        
        myLog(NAME_OF_STRATEGY.." dealProfit "..tostring(vdealProfit).." OpenCount after "..tostring(OpenCount))
        
        --vlastDealPrice = dealPrice
        if OpenCount == 0 then
            vlastDealPrice = 0
            SetCell(t_id, 2, 1, '', 0) 
            SetCell(t_id, 2, 2, '', 0)                
        else
            SetCell(t_id, 2, 1, tostring(OpenCount)..'/'..tostring(vlastDealPrice), vlastDealPrice) 
        end
        if OpenCount>0 then
            SetColor(t_id, 2, 1, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
        elseif OpenCount < 0 then                        
            SetColor(t_id, 2, 1, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
        else
            SetColor(t_id, 2, 1, RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))
        end

        vdealProfit = 0
        TransactionPrice = dealPrice                        
        lastDealPrice = vlastDealPrice
        stopLevelPrice = lastDealPrice

        addDeal(DS:Size(), openLong, openShort, closeLong, closeShort, DS:T(DS:Size()))
        ROBOT_STATE = 'УСТАНОВКА СТОП ЛОССА'               
        return dealPrice
    end

    local Transaction={
       ['TRANS_ID']   = tostring(trans_id),
       ['ACTION']     = 'NEW_ORDER',
       ['CLASSCODE']  = CLASS_CODE,
       ['SECCODE']    = SEC_CODE,
       ['CLIENT_CODE'] = CLIENT_CODE, -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках 
       ['OPERATION']  = Operation, -- операция ("B" - buy, или "S" - sell)
       ['TYPE']       = 'M', -- по рынку (MARKET)
       ['QUANTITY']   = tostring(qnt), -- количество
       ['ACCOUNT']    = ACCOUNT,
       ['PRICE']      = tostring(Price),
       ['COMMENT']    = NAME_OF_STRATEGY..' robot'
    }
    
    ROBOT_STATE = 'ОЖИДАНИЕ СДЕЛКИ'
    orderQnty = qnt
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

-- Возвращает корректную цену для рыночной стоп-заявки по текущему инструменту (принимает 'S',или 'B' и уровень стоп цены активации)
function GetPriceForMarketStopOrder(Type, stopprice)
    -- В зависимости от направления
    if Type == 'SELL' then -- SELL
       -- Пытается получить максимально возможную цену для инструмента
       local PriceMax = tonumber(getParamEx(CLASS_CODE,  SEC_CODE, 'PRICEMAX').param_value)
       -- Если максимально возможная цена получена
       if PriceMax ~= nil and PriceMax ~= 0 then
          -- Возвращает ее в нужном для транзакции формате
          return PriceMax
       -- Иначе, максимально возможная цена не получена
       else
          -- Возвращает ее в нужном для транзакции формате, увеличив перед этим на 50 шагов цены
          return stopprice + 100*SEC_PRICE_STEP
       end
    else                     -- BUY
       -- Пытается получить минимально возможную цену для инструмента
       local PriceMin = tonumber(getParamEx(CLASS_CODE,  SEC_CODE, 'PRICEMIN').param_value)
       -- Если минимально возможная цена получена
       if PriceMin ~= nil and PriceMin ~= 0 then
          -- Возвращает ее в нужном для транзакции формате
          return PriceMin
       -- Иначе, минимально возможная цена не получена
       else
          -- Возвращает ее в нужном для транзакции формате, уменьшив перед этим на 50 шагов цены
          return stopprice - 100*SEC_PRICE_STEP
       end
    end 
end

function getSLTP_Price(AtPrice, Type, qnt, fixed)

	local tp_stopprice = 0 -- Цена Тейк-Профита
    local sl_stopprice = 0 -- Цена Стоп-Лосса
    local stopprice = 0 -- Цена выставления
    
    fixed = fixed or false

	myLog(NAME_OF_STRATEGY..' AtPrice '..tostring(AtPrice)..', TAKE_PROFIT: '..tostring(TAKE_PROFIT)..' STOP_LOSS: '..tostring(STOP_LOSS))
	--myLog(NAME_OF_STRATEGY..' DS:Size() '..tostring(DS:Size())..' calcAlgoValue[DS:Size()-1] '..tostring(calcAlgoValue[DS:Size()-1])..', ATR[DS:Size()-1]: '..tostring(ATR[DS:Size()-1])..' ATRfactor: '..tostring(ATRfactor))
    
    --if isTrade then calculateAlgo(DS:Size(), Settings) end
	myLog(NAME_OF_STRATEGY..' oldStop '..tostring(oldStop)..', oldTakeProfitPrice: '..tostring(TakeProfitPrice)..', isPriceMove: '..tostring(isPriceMove))
	myLog(NAME_OF_STRATEGY..' PRICEMIN '..tostring(getParamEx(CLASS_CODE, SEC_CODE, 'PRICEMIN').param_value)..', PRICEMAX: '..tostring(getParamEx(CLASS_CODE, SEC_CODE, 'PRICEMAX').param_value))

    -- Если открыт BUY
	if Type == 'BUY' then
        if TAKE_PROFIT~=0 then
            if TakeProfitPrice == 0 then
                tp_stopprice	= round(AtPrice + TAKE_PROFIT*priceKoeff, scale) -- Уровень цены, когда активируется Тейк-профит
            elseif isPriceMove and shiftProfit then
                tp_stopprice = round(TakeProfitPrice + STOP_LOSS*priceKoeff/2, scale)    -- немного сдвигаем тейк-профит
            else tp_stopprice = TakeProfitPrice
            end
        end
        if STOP_LOSS~=0 then
            if shiftStop or oldStop == 0 then
                if isTrade and not fixed then
                    local slPrice = calcAlgoValue[DS:Size()-1]
                    local shiftSL = (kATR*ATR[DS:Size()-1] + 40*SEC_PRICE_STEP)
                    if (slPrice - shiftSL) >= AtPrice then
                        slPrice = AtPrice
                    end
                    local nonLosePrice = round(lastDealPrice + 0*SEC_PRICE_STEP, scale)
                    if (lastDealPrice + math.floor(STOP_LOSS*priceKoeff)) <= AtPrice then
                        sl_stopprice	= math.max(round(slPrice - shiftSL, scale), nonLosePrice) -- Уровень цены, когда активируется Стоп-лосс
                    else
                        sl_stopprice	= round(slPrice - shiftSL, scale) -- Уровень цены, когда активируется Стоп-лосс
                    end
                    if reopenAfterStop then dealMaxStop = reopenDealMaxStop else dealMaxStop = maxStop end
                    if (lastDealPrice - sl_stopprice) > dealMaxStop*priceKoeff then sl_stopprice = lastDealPrice - dealMaxStop*priceKoeff end
                    reopenAfterStop = false
                else
                    sl_stopprice	= round(AtPrice - STOP_LOSS*priceKoeff, scale) -- Уровень цены, когда активируется Стоп-лосс
                end
            else
                sl_stopprice = oldStop
            end

            if oldStop~=0 then sl_stopprice = math.max(oldStop, sl_stopprice) end
            sl_stopprice = math.min(sl_stopprice, DS:L(DS:Size()))
           
            myLog(NAME_OF_STRATEGY..' oldStop '..tostring(oldStop)..', sl_stopprice: '..tostring(sl_stopprice)..', DS:L(DS:Size()): '..tostring(DS:L(DS:Size())))
        end
	else -- открыт SELL
        
        if TAKE_PROFIT~=0 then
            if TakeProfitPrice == 0 then
                tp_stopprice	= round(AtPrice - TAKE_PROFIT*priceKoeff, scale) -- Уровень цены, когда активируется Тейк-профит
            elseif isPriceMove and shiftProfit then
                tp_stopprice = round(TakeProfitPrice - STOP_LOSS*priceKoeff/2, scale)  -- немного сдвигаем тейк-профит   
            else tp_stopprice = TakeProfitPrice
            end
        end
        if STOP_LOSS~=0 then
            if shiftStop or oldStop == 0 then
                if isTrade and not fixed then
                    local slPrice = calcAlgoValue[DS:Size()-1]
                    local shiftSL = (kATR*ATR[DS:Size()-1] + 40*SEC_PRICE_STEP)
                    if (slPrice + shiftSL) <= AtPrice then
                        slPrice = AtPrice
                    end
                    local nonLosePrice = round(lastDealPrice - 0*SEC_PRICE_STEP, scale)
                    if (lastDealPrice - math.floor(STOP_LOSS*priceKoeff)) >= AtPrice then
                        sl_stopprice	= math.min(round(slPrice + shiftSL, scale), nonLosePrice) -- Уровень цены, когда активируется Стоп-лосс
                    else
                        sl_stopprice	= round(slPrice + shiftSL, scale) -- Уровень цены, когда активируется Стоп-лосс
                    end
                    if reopenAfterStop then dealMaxStop = reopenDealMaxStop else dealMaxStop = maxStop end
                    if (sl_stopprice - lastDealPrice) > dealMaxStop*priceKoeff then sl_stopprice = lastDealPrice + dealMaxStop*priceKoeff end
                    reopenAfterStop = false
                else
                    sl_stopprice	= round(AtPrice + STOP_LOSS*priceKoeff, scale) -- Уровень цены, когда активируется Стоп-лосс
                end
            else
                sl_stopprice = oldStop
            end
            
            if oldStop~=0 then sl_stopprice = math.min(oldStop, sl_stopprice) end
            sl_stopprice = math.max(sl_stopprice, DS:H(DS:Size()))
           
            myLog(NAME_OF_STRATEGY..' oldStop '..tostring(oldStop)..', sl_stopprice: '..tostring(sl_stopprice)..', DS:H(DS:Size()): '..tostring(DS:H(DS:Size())))
        end
    end
    
    TakeProfitPrice = tp_stopprice
    isPriceMove = false

    --Получаем цену исполнения стоп ордера, после активации
    stopprice = GetPriceForMarketStopOrder(Type, sl_stopprice)
    
    return tp_stopprice, sl_stopprice, stopprice

end

-- Выставляет СТОП-ЛОСС и ТЕЙК-ПРОФИТ, принимает ЦЕНУ (Price) и ТИП (Type) ["BUY", или "SELL"] открытой сделки,
--- возвращает FALSE, если не удалось выставить СТОП-ЛОСС и ТЕЙК-ПРОФИТ
-- Выставляет СТОП-ЛОСС и ТЕЙК-ПРОФИТ
--- возвращает FALSE, если не удалось выставить СТОП-ЛОСС и ТЕЙК-ПРОФИТ
function SL_TP(AtPrice, Type, qnt)

    if isConnected() == false then
        return false
    end
    if manualKillStop then
        return true
    end

    -- ID транзакции
    trans_id = trans_id + 1

    lastDealPrice = GetCell(t_id, 2, 1).value
    lastStopShiftIndex = DS:Size()
    if qnt < 0 then qnt = -qnt end

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
        tp_Price, sl_Price, price = getSLTP_Price(AtPrice, Type, qnt, fixedstop)
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
    price = GetCorrectPrice(price)

    --myLog(NAME_OF_STRATEGY..' Установка ТЕЙК-ПРОФИТ: '..tp_Price..' и СТОП-ЛОСС: '..sl_Price)
        
    myLog(NAME_OF_STRATEGY..' robot: '..' index '..tostring(DS:Size())..' lastDealPrice '..tostring(lastDealPrice)..' AlgoVal '..tostring(calcAlgoValue[DS:Size()-1])..', ATR: '..tostring(ATR[DS:Size()-1]))
    myLog(NAME_OF_STRATEGY..' robot: стоп '..STOP_ORDER_KIND..', сделка '..Type..' по цене '..tostring(AtPrice)..' EXPIRY_DATE '..tostring(EXPIRY_DATE)..', Установка ТЕЙК-ПРОФИТ: '..tp_Price..' и СТОП-ЛОСС: '..sl_Price..' ЦЕНА выставления: '..tostring(price)..' offset: '..tostring(offset)..' spread: '..tostring(spread))
    
    if virtualTrade then
        tpPrice = string.gsub(tp_Price,'[,]+', '.')
        slPrice = string.gsub(sl_Price,'[,]+', '.')
        tpPrice = tonumber(tpPrice)
        slPrice = tonumber(slPrice)
        
        oldStop = slPrice
        SetCell(t_id, 2, 3, sl_Price, slPrice) 
        SetCell(t_id, 2, 4, tp_Price, tpPrice)   
        return true
    end

	local Transaction = {
		["ACTION"]              = "NEW_STOP_ORDER", -- Тип заявки
		["TRANS_ID"]            = tostring(trans_id),
		["CLASSCODE"]           = CLASS_CODE,
		["SECCODE"]             = SEC_CODE,
		["ACCOUNT"]             = ACCOUNT,
        ['CLIENT_CODE']         = ROBOT_CLIENT_CODE, -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках 
		["OPERATION"]           = operation, -- Операция ("B" - покупка(BUY), "S" - продажа(SELL))
		["QUANTITY"]            = tostring(qnt), -- Количество в лотах
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
    while Run and os.time() - start_sec < 10 do        
        order = findOrderOnTransID('stop_orders', trans_id)
        if order and order.qty ~= 0 and bit.band(order.flags,0x1)==0x1 then
            --stop_order_num = order.order_num
            return true
        end        
       sleep(100)
    end

    message(NAME_OF_STRATEGY..' Возникла неизвестная ошибка при выставлении стоп заявки по транзакции: '..tostring(trans_id))
    myLog(NAME_OF_STRATEGY..' Возникла неизвестная ошибка при выставлении стоп заявки по транзакции: '..tostring(trans_id))

    return false

end

-- Выставляет лимитную заявку
function SetOrder(
    price,      -- Цена заявки
    operation,  -- Операция ('B' - buy, 'S' - sell)
    qty         -- Количество 
 )
    
    if qty<0 then qty = -qty end

    myLog(NAME_OF_STRATEGY..' Установка лимитного ордера, позиция '..operation..' qty '..tostring(qty)..', по цене: '..tostring(price))

    -- Выставляет заявку
    -- Получает ID для следующей транзакции
    trans_id = trans_id + 1
    -- Заполняет структуру для отправки транзакции
    local T = {}
    T['TRANS_ID']       = tostring(trans_id)     -- Номер транзакции
    T['ACCOUNT']        = ACCOUNT                -- Код счета
    T['CLASSCODE']      = CLASS_CODE             -- Код класса
    T['SECCODE']        = SEC_CODE               -- Код инструмента
    T['CLIENT_CODE']    = ROBOT_CLIENT_CODE    -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках 
    T['ACTION']         = 'NEW_ORDER'            -- Тип транзакции ('NEW_ORDER' - новая заявка)      
    T['TYPE']           = 'L'                    -- Тип ('L' - лимитированная, 'M' - рыночная)
    T['OPERATION']      = operation              -- Операция ('B' - buy, или 'S' - sell)
    T['PRICE']          = GetCorrectPrice(price) -- Цена
    T['QUANTITY']       = tostring(qty)          -- Количество
    T["COMMENT"]        = NAME_OF_STRATEGY

    -- Отправляет транзакцию
    local Res = sendTransaction(T)
    -- Если при отправке транзакции возникла ошибка
    if Res ~= '' then
       -- Выводит сообщение об ошибке
       message(NAME_OF_STRATEGY..' Ошибка выставления лимитной заявки: '..res)
       myLog(NAME_OF_STRATEGY..' Ошибка выставления лимитной заявки: '..res)
       return false
    end

    -- Ищет заявку в таблице заявок, возвращает истина
    -- Ожидает 10 сек. макс.
    local start_sec = os.time()
    while Run and os.time() - start_sec < 10 do        
        order = findOrderOnTransID('orders', trans_id)
        if order and order.qty ~= 0 and bit.band(order.flags,0x1)==0x1 then
            stop_order_num = order.order_num
            return true
        end        
        sleep(100)
    end
    
    message(NAME_OF_STRATEGY..' Возникла неизвестная ошибка при выставлении лимитной заявки по транзакции: '..tostring(trans_id))
    myLog(NAME_OF_STRATEGY..' Возникла неизвестная ошибка при выставлении лимитной заявки по транзакции: '..tostring(trans_id))

    return false

end

-- Удалить все стоп заявки
function KillAllStopOrders(deleteAll)
    myLog(NAME_OF_STRATEGY..' Закрытие стоп-лосса '..ROBOT_CLIENT_CODE)
    
    function myFind(C,S,F,B)
       return (C == CLASS_CODE) and (S == SEC_CODE) and (bit.band(F, 0x1) ~= 0) and (B:find(ROBOT_POSTFIX) or deleteAll == true)
    end

    local ord = "stop_orders"
    local orders = SearchItems(ord, 0, getNumberOf(ord)-1, myFind, "class_code,sec_code,flags,brokerref")
    local allDeleted = true
    if (orders ~= nil) and (#orders > 0) then
        for i=1,#orders do
            local order = getItem(ord,orders[i])
            myLog('Close stop '..tostring(order.order_num)..' client_code '..order.brokerref)
            allDeleted = allDeleted and KillOrder(order.order_num, ord, "KILL_STOP_ORDER", orders[i]) -- 
        end
    end

    if virtualTrade or (allDeleted and (OpenCount == 0 or manualKillStop)) then
        SetCell(t_id, 2, 3, '', 0) 
        SetCell(t_id, 2, 4, '', 0) 
        slIndex = 0
        slPrice = 0
        oldStop = 0
        lastStopShiftIndex = 0
        tpPrice = 0
        workedStopPrice= 0
    end

    return allDeleted 
end

 -- Удалить все лимитные заявки
function KillAllOrders(deleteAll)
    
    myLog(NAME_OF_STRATEGY..' Закрытие лимитных заявок '..ROBOT_CLIENT_CODE)

    function myFind(C,S,F,B)
       return (C == CLASS_CODE) and (S == SEC_CODE) and (bit.band(F, 0x1) ~= 0) and (B:find(ROBOT_POSTFIX) or deleteAll == true)
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
    ord = ord or 'stop_orders'
    ACTION = ACTION or 'KILL_STOP_ORDER'
    local prefix = ACTION == 'KILL_STOP_ORDER' and 'СТОП' or 'ЛИМИТНАЯ'
    local ORDER_KEY = ACTION == 'KILL_STOP_ORDER' and 'STOP_ORDER_KEY' or 'ORDER_KEY'

    index = index or 0
    if index == 0 then
        -- Находит заявку если не передан индекс(10 сек. макс.)
        local start_sec = os.time()
        local find_order = false
        while Run and not find_order and os.time() - start_sec < 10 do
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
    while Run and os.time() - start_sec < 10 do
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

function setTableSimpleAlgoParams(settingsAlgo)

    --можно испрльзовать 5 колонок в трех строках
    --одна строка уже добавлена, если нужны еще две, то надо добвать строки
    local rows,_ = GetTableSize(t_id)
    if rows > 6 then
        for i=1,4 do
            DeleteRow(t_id, 7)
        end        
    end

    SetCell(t_id, 5, 0, "shift", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 5, 1, "", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 5, 2, "", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 5, 3, "", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 6, 0, tostring(settingsAlgo.shift),     settingsAlgo.shift)  
    SetCell(t_id, 6, 1, "",      0)
    SetCell(t_id, 6, 2, "",      0)
    SetCell(t_id, 6, 3, "",      0)
    SetCell(t_id, 6, 6, tostring(settingsAlgo.STOP_LOSS or 0), settingsAlgo.STOP_LOSS or 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 6, 7, tostring(settingsAlgo.TAKE_PROFIT or 0))  --i строка, 0 - колонка, v - значение 

end

function readTableSimpleAlgoParams()
    Settings.shift  = GetCell(t_id, 6, 0).value
    Settings.STOP_LOSS = GetCell(t_id, 6, 6).value
    Settings.TAKE_PROFIT = tonumber(GetCell(t_id, 6, 7).image)
end

function readOptimizedSimpleAlgo()
    local ParamsFile = io.open(PARAMS_FILE_NAME,"r")
    if ParamsFile ~= nil then
        local lineCount = 0
        local SettingsKeys = {}
        for line in ParamsFile:lines() do
            lineCount = lineCount + 1
            if lineCount > 1 and line ~= "" then
                local per1, per2, per3, per4, per5 = line:match("%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*)")
                if INTERVAL == tonumber(per1) then
                    testSizeBars        = tonumber(per2)
                    Settings.shift      = tonumber(per3)
                    Settings.STOP_LOSS      = tonumber(per4)
                    Settings.TAKE_PROFIT    = tonumber(per5)
                end
            end
        end
        ParamsFile:close()
    else
        myLog(NAME_OF_STRATEGY.." Файл параметров "..PARAMS_FILE_NAME.." не найден")
    end
end

function saveOptimizedSimpleAlgo(settings)
    
    local ParamsFile = io.open(PARAMS_FILE_NAME,"w")
    local firstString = "INTERVAL; testSizeBars; shift; STOP_LOSS; TAKE_PROFIT"
    ParamsFile:write(firstString.."\n")
    local paramsString = tostring(INTERVAL)..";"..tostring(testSizeBars)..";"..tostring(settings.shift)..";"..tostring(settings.STOP_LOSS)..";"..tostring(settings.TAKE_PROFIT)
    ParamsFile:write(paramsString.."\n")
    ParamsFile:flush()
    ParamsFile:close()

end

function initSimpleAlgo()
    ATR = nil
    trend=nil
    calcAlgoValue = nil     
    dVal = nil     
    calcChartResults = nil
end

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

function simpleAlgo(index, Settings)
    
    local shift = Settings.shift or 17
    local bars = 20
    local kawg = 2/(bars+1)

    local indexToCalc = 1000
    indexToCalc = Settings.indexToCalc or indexToCalc
    local beginIndexToCalc = Settings.beginIndexToCalc or math.max(1, DS:Size() - indexToCalc)

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
    
    if index<bars then
        ATR[index] = 0
    elseif index==bars then
        local sum=0
        for i = 1, bars do
            sum = sum + dValue(i)
        end
        ATR[index]=sum / bars
    elseif index>bars then
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
    
    --if not optimizationInProgress then
    --    local roundAlgoVal = round(calcAlgoValue[index], scale)
    --    SetCell(t_id, 2, 1, tostring(roundAlgoVal), roundAlgoVal) 
    --end

    return calcAlgoValue, trend
end

-----------------------------------------
--метки сделок
function addDeal(index, openLong, openShort, closeLong, closeShort, time)

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
    local IMAGE_PATH = getScriptPath()..'\\Изображения\\'

    if openLong ~= nil then
        label.YVALUE = openLong
        label.IMAGE_PATH = IMAGE_PATH..'МоиСделки_buy.bmp'
        ALIGNMENT = "BOTTOM"
        label.R = 0
        label.G = 0
        label.B = 0
        label.TEXT = tostring(openLong)
        label.HINT = "open Long "..tostring(openLong).." - "..toYYYYMMDDHHMMSS(time)
    elseif openShort ~=nil then
        label.YVALUE = openShort
        label.IMAGE_PATH = IMAGE_PATH..'МоиСделки_sell.bmp'
        label.R = 0
        label.G = 0
        label.B = 0
        ALIGNMENT = "TOP"
        label.TEXT = tostring(openShort)
        label.HINT = "open Short "..tostring(openShort).." - "..toYYYYMMDDHHMMSS(time)
    elseif closeLong ~=nil then
        label.YVALUE = closeLong
        label.IMAGE_PATH = IMAGE_PATH..'МоиСделки_sell.bmp'
        ALIGNMENT = "TOP"
        label.R = 0
        label.G = 0
        label.B = 0
        label.TEXT = tostring(closeLong)
        label.HINT = "close Long "..tostring(closeLong).." - "..toYYYYMMDDHHMMSS(time)
    elseif closeShort ~=nil then
        label.YVALUE = closeShort
        label.IMAGE_PATH = IMAGE_PATH..'МоиСделки_buy.bmp'
        ALIGNMENT = "BOTTOM"
        label.R = 0
        label.G = 0
        label.B = 0
        label.TEXT = tostring(closeShort)
        label.HINT = "close Short "..tostring(closeShort).." - "..toYYYYMMDDHHMMSS(time)
    end
    
    AddLabel(ChartId, label)

end

--- ОПТИМИЗАЦИЯ
function iterateTable(settingsTable, resultsTable)
    
    local localCount = 0
    local rescount = 0	
    local allCount = #settingsTable

    for i,v in ipairs(settingsTable) do
        if stopSignal then
            break
        end
                
        localCount = localCount + 1
        doneOptimization = round(localCount*100/allCount, 0)
        
        SetCell(t_id, 2, 7, "OPTIMIZATION "..tostring(doneOptimization).."%", doneOptimization)

        allProfit = 0
        shortProfit = 0
        longProfit = 0
        lastDealPrice = 0
        lastTradeDirection = 0
        lastStopShiftIndex = 0
        dealsCount = 0
        dealsLongCount = 0
        dealsShortCount = 0
        profitDealsLongCount = 0
        profitDealsShortCount = 0
        slDealsLongCount = 0
        tpDealsLongCount = 0
        slDealsShortCount = 0
        tpDealsShortCount = 0
        ratioProfitDeals = 0
        initalAssets = 0

        settingsTask = v         
        settingsTask.beginIndex = beginIndex
        settingsTask.endIndex = endIndex
        settingsTask.beginIndexToCalc = math.max(1, beginIndex - 1000)
        if settingsTask.STOP_LOSS == nil and presets[curPreset].settingsAlgo.STOP_LOSS ~= 0 then
            settingsTask.STOP_LOSS = presets[curPreset].settingsAlgo.STOP_LOSS
        end
        if settingsTask.TAKE_PROFIT == nil and presets[curPreset].settingsAlgo.TAKE_PROFIT ~= 0 then
            settingsTask.TAKE_PROFIT = presets[curPreset].settingsAlgo.TAKE_PROFIT
        end
        if settingsTask.shiftStop == nil then
            settingsTask.shiftStop = presets[curPreset].shiftStop
        end
        if settingsTask.shiftProfit == nil then
            settingsTask.shiftProfit = presets[curPreset].shiftProfit
        end
        if settingsTask.fixedstop == nil then
            settingsTask.fixedstop = presets[curPreset].fixedstop
        end
 
        optimizeAlgorithm()
        local profitRatio, avg, sigma, maxDrawDown, sharpe, AHPR, ZCount = calculateSigma(deals)
            
        --myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
        --myLog(NAME_OF_STRATEGY.." Прибыль по лонгам "..tostring(longProfit))
        --myLog(NAME_OF_STRATEGY.." Прибыль по шортам "..tostring(shortProfit))
        --myLog(NAME_OF_STRATEGY.." Прибыль всего "..tostring(allProfit))
        --myLog(NAME_OF_STRATEGY.." ================================================")

        dealsLP = tostring(dealsLongCount).."/"..tostring(profitDealsLongCount)
        dealsSP = tostring(dealsShortCount).."/"..tostring(profitDealsShortCount)
        if dealsLongCount + dealsShortCount > 0 then
            ratioProfitDeals = round((profitDealsLongCount + profitDealsShortCount)*100/(dealsLongCount + dealsShortCount), 2)
        end

        if profitRatio > 0 then
            rescount = rescount + 1
            --resultsTable[rescount] = {allProfit, profitRatio, longProfit, shortProfit, dealsLP, dealsSP, ratioProfitDeals, avg, sigma, maxDrawDown, sharpe, AHPR, ZCount, settingsTask}
            resultsTable[rescount] = {allProfit, maxDrawDown, calcAlgoValue[endIndex], trend[endIndex], settingsTask}
        end
            
    end

    return resultsTable
end

function iterateAlgorithm(settingsTable)
        
    local resultsTable = {}    
    
    isTrade = false
    optimizationInProgress = true
    logDeals = false

    endIndex = DS:Size()
    
    if testSizeBars > 0 then 
        beginIndex = DS:Size()-testSizeBars
    else
        local days = 0
        local firstDay = true
        for i=1,endIndex do
            local time = math.ceil((DS:T(endIndex-i+1).hour + DS:T(endIndex-i+1).min/100)*100)
            local time1 = math.ceil((DS:T(endIndex-i).hour + DS:T(endIndex-i).min/100)*100)
            local isTradeBegin = time >= startTradeTime and time1 < startTradeTime
            --myLog(NAME_OF_STRATEGY..' time '..tostring(time)..' time1 '..tostring(time1))
            if isTradeBegin then
                days = days + 1
                beginIndex = endIndex-i-1
                if firstDay and serverTime < 1400 then
                    days = days - 1
                    firstDay = false
                end
            end
            if days == -1*testSizeBars then break end
        end
    end

    --local bars = endIndex - beginIndex
    --myLog(NAME_OF_STRATEGY..' beginIndex '..tostring(beginIndex)..' day '..tostring(DS:T(beginIndex).day)..' hour '..tostring(DS:T(beginIndex).hour)..' min '..tostring(DS:T(beginIndex).min))
    --myLog(NAME_OF_STRATEGY..' bars '..tostring(bars))

    resultsTable = iterateTable(settingsTable, resultsTable)

    if #resultsTable > 1 then
        --ArraySortByColl(resultsTable, 3)
        table.sort(resultsTable, function(a,b) return a[1]<b[1] end)
    end

    if #resultsTable > 0 and iterateSLTP and SetStop then
        myLog(NAME_OF_STRATEGY.." ----------------------------------------------------------")
        myLog(NAME_OF_STRATEGY.." list before iterate SL/TP")
        for i=0,math.min(#resultsTable-1, 20) do
            resultString = resultsTable[#resultsTable - i]
            local settings = resultString[#resultString]
            paramsString = tostring(INTERVAL).."; "..tostring(testSizeBars)
            for j=1,4 do
                paramsString = paramsString..'; '..tostring(resultString[j])
            end
            for k,v in pairs(settings) do
                if type(v) == 'table' then
                    for kkk,vvv in pairs(v) do
                        paramsString = paramsString..'; '..tostring(vvv)
                    end
                else
                    paramsString = paramsString..'; '..tostring(v)
                end
            end
            myLog(paramsString)
        end

        local lines = math.min(20, #resultsTable)
        local settingsTableSLTP = getSettingsSLTP(resultsTable, lines)
        local i = 1
        while i <= lines do
            table.remove(resultsTable, #resultsTable)
            i = i+1
        end
        resultsTable = iterateTable(settingsTableSLTP, resultsTable)
        table.sort(resultsTable, function(a,b) return a[1]<b[1] end)
    end
 
    if #resultsTable ~=0 then
        
        local resultString = resultsTable[#resultsTable]
        local bestSettings = resultString[#resultString]
        
        local maxProfit = resultString[1]
        local minDrawDown = resultString[2]
        local algoLine =resultString[3]
        local trendLine = resultString[4]
        local bestOnTrend = (trendLine < 0 and DS:C(DS:Size()) < algoLine) or (trendLine > 0 and DS:C(DS:Size()) > algoLine) or algoLine == 0
        
        local minProfit = maxProfit*0.95
        local isSearch = true
        local line = #resultsTable - 1
        local needNewBest = minDrawDown>6
    
        myLog(NAME_OF_STRATEGY.." ----------------------------------------------------------")
        local firstString = "INTERVAL; testSizeBars; allProfit; maxDown; lastDealSignal; trend"
 
        for k,v in pairs(bestSettings) do
            if type(v) == 'table' then
                for kkk,vvv in pairs(v) do
                    firstString = firstString..'; '..kkk
                    --myLog(NAME_OF_STRATEGY.." col "..tostring(kkk)..", val "..tostring(keyValueSettingT))
                end
            else
                firstString = firstString..'; '..k
            end
        end
 
        myLog(firstString)
        myLog(NAME_OF_STRATEGY.." best")        
        paramsString = tostring(INTERVAL).."; "..tostring(testSizeBars)
        for j=1,4 do
            paramsString = paramsString.."; "..tostring(resultString[j])
        end
        for k,v in pairs(bestSettings) do
            if type(v) == 'table' then
                for kkk,vvv in pairs(v) do
                    paramsString = paramsString..'; '..tostring(vvv)
                end
            else
                paramsString = paramsString..'; '..tostring(v)
            end
        end
        myLog(paramsString)
    
        while isSearch and line >= 1 do
            if minProfit > resultsTable[line][1] and not needNewBest then
                break
            end

            resultString = resultsTable[line]
            trendLine = resultsTable[line][4]
            algoLine = resultsTable[line][3]
            local onTrend = (trendLine < 0 and DS:C(DS:Size()) < algoLine) or (trendLine > 0 and DS:C(DS:Size()) > algoLine) or algoLine == 0

            if minDrawDown == resultsTable[line][2] and onTrend and not bestOnTrend then
                minDrawDown = resultsTable[line][2]
                if minDrawDown<=6 then needNewBest = false end 
                bestSettings = resultsTable[line][#resultsTable[line]]
                bestOnTrend = true
                myLog(NAME_OF_STRATEGY.." new best line "..tostring(line))
                paramsString = tostring(INTERVAL).."; "..tostring(testSizeBars)
                for j=1,4 do
                    paramsString = paramsString.."; "..tostring(resultString[j])
                end
                for k,v in pairs(bestSettings) do
                    if type(v) == 'table' then
                        for kkk,vvv in pairs(v) do
                            paramsString = paramsString..'; '..tostring(vvv)
                            --myLog(NAME_OF_STRATEGY.." col "..tostring(kkk)..", val "..tostring(keyValueSettingT))
                        end
                    else
                        paramsString = paramsString..'; '..tostring(v)
                    end
                end
                myLog(paramsString)
            end
            if minDrawDown > resultsTable[line][2] and onTrend then
                minDrawDown = resultsTable[line][2]
                if minDrawDown<=6 then needNewBest = false end 
                bestSettings = resultsTable[line][#resultsTable[line]]
                myLog(NAME_OF_STRATEGY.." new best line "..tostring(line))
                paramsString = tostring(INTERVAL).."; "..tostring(testSizeBars)
                for j=1,4 do
                    paramsString = paramsString.."; "..tostring(resultString[j])
                end
                for k,v in pairs(bestSettings) do
                    if type(v) == 'table' then
                        for kkk,vvv in pairs(v) do
                            paramsString = paramsString..'; '..tostring(vvv)
                        end
                    else
                        paramsString = paramsString..'; '..tostring(v)
                    end
                end
                myLog(paramsString)
            end
            line = line - 1
        end
        
        --не нашли лучший результат с приемлемой просадкой. Берем лучший оп прибыли.
        if needNewBest then bestSettings = resultString[#resultString] end

        myLog(NAME_OF_STRATEGY.." ----------------------------------------------------------")
        myLog(NAME_OF_STRATEGY.." list")
        for i=0,math.min(#resultsTable-1, 20) do
            resultString = resultsTable[#resultsTable - i]
            local settings = resultString[#resultString]
            paramsString = tostring(INTERVAL).."; "..tostring(testSizeBars)
            for j=1,4 do
                paramsString = paramsString..'; '..tostring(resultString[j])
            end
            for k,v in pairs(settings) do
                if type(v) == 'table' then
                    for kkk,vvv in pairs(v) do
                        paramsString = paramsString..'; '..tostring(vvv)
                    end
                else
                    paramsString = paramsString..'; '..tostring(v)
                end
            end
            myLog(paramsString)
        end

        if setTableAlgoParams~=nil then
            setTableAlgoParams(bestSettings)    
        end
            
        optimizationInProgress = false
        if saveOptimizedParams~=nil then
            saveOptimizedParams(bestSettings)    
        end
        return
    end

    optimizationInProgress = false
    myLog(NAME_OF_STRATEGY.." Нет положительных результатов оптимизации")
    message("Нет положительных результатов оптимизации")
end

function getSettingsSLTP(resultsTable, lines)

    local param4Min = STOP_LOSS
    local param4Max = STOP_LOSS
    local param4Step = 5  

    local param5Min = TAKE_PROFIT
    local param5Max = TAKE_PROFIT
    local param5Step = 5

    if STOP_LOSS~=0 then
        param4Min = 25
        param4Max = 75
        param4Step = 5  
    end

    if TAKE_PROFIT~=0 then
        param5Min = 80
        param5Max = 230
        param5Step = 5
    end
    
    local settingsTable = {}
    local allCount = 0

    for i=0,math.min(#resultsTable-1, lines) do

        for param4 = param4Min, param4Max, param4Step do                               
            for param5 = param5Min, param5Max, param5Step do           
                allCount = allCount + 1
                settingsTable[allCount] = {}
                for i,v in pairs(resultsTable[#resultsTable - i][5]) do
                    settingsTable[allCount][i] = v
                end
                settingsTable[allCount].STOP_LOSS = param4
                settingsTable[allCount].TAKE_PROFIT = param5
                --myLog(NAME_OF_STRATEGY..' **** SL '..tostring(settingsTable[allCount].SLSec)..' TP '..tostring(settingsTable[allCount].TPSec))
            end
        end
    end
    
    return settingsTable
        
end

function calculateSigma(deals)
 
    local sigma = 0
    local avg = 0
    local maxDrawDown = 0
    local equity = initalAssets or 0
    local maxEquity = initalAssets or 0
    local profitRatio = 0
    local dispDeals = {}
    local maxDelta = 0
    
    --Sharpe ratio
    local sharpe = 0
    local HPRDeals = {}
    local sigmaHPR = 0
    local avgHPR = 0

    local dealsCount = 0

    local seriesCount = 0
    local lastProfit = nil
    local ZCount = 0

    --myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
    --myLog(NAME_OF_STRATEGY.." equity "..tostring(equity))

    for i,index in pairs(deals["index"]) do                           
        if deals["dealProfit"][i] ~= nil then
            dealsCount = dealsCount + 1
            avg = avg + deals["dealProfit"][i]
            dispDeals[i] = deals["dealProfit"][i]           
            
            local oldEquity = equity
            equity = equity + deals["dealProfit"][i]
            --myLog(NAME_OF_STRATEGY.." index "..tostring(index).." equity "..tostring(equity))
            
            if oldEquity > 0 and equity < 0 then
                HPRDeals[i] = 0
            elseif oldEquity < 0 and equity > 0 then    
                HPRDeals[i] = 1000
            else    
                HPRDeals[i] = equity/oldEquity
            end
            --myLog(NAME_OF_STRATEGY.." HPRDeals[i] "..tostring(HPRDeals[i]))
            avgHPR = avgHPR + HPRDeals[i]

            maxEquity = math.max(maxEquity, equity)
            --myLog(NAME_OF_STRATEGY.." maxEquity "..tostring(maxEquity))
            if equity < maxEquity then
                maxDelta = math.max(maxEquity - equity, maxDelta)
                maxDrawDown = math.max(round(maxDelta*100/maxEquity, 2), maxDrawDown)
                --myLog(NAME_OF_STRATEGY.." maxDrawDown "..tostring(maxDrawDown))
            end

            if lastProfit ~= nil then
                if lastProfit > 0 and deals["dealProfit"][i] <= 0 then
                    seriesCount = seriesCount + 1
                elseif lastProfit <= 0 and deals["dealProfit"][i] > 0 then
                    seriesCount = seriesCount + 1
                end      
            end            
            lastProfit = deals["dealProfit"][i] 
                
        end        
    end

    if dealsCount > 0 then
        avg = round(avg/dealsCount, 5)
        avgHPR = round(avgHPR/dealsCount, 5)
    else 
        avg = 0
        avgHPR = 0
    end
    --myLog(NAME_OF_STRATEGY.." avgHPR "..tostring(avgHPR))

    for i,_ in pairs(dispDeals) do                           
        sigma = sigma + math.pow(dispDeals[i] - avg, 2)
        sigmaHPR = sigmaHPR + math.pow(HPRDeals[i] - avgHPR, 2)
        --myLog(NAME_OF_STRATEGY.." HPR_Avg "..tostring(math.pow(HPRDeals[i] - avgHPR, 2)))
    end
    --myLog(NAME_OF_STRATEGY.." DispHPR "..tostring(sigmaHPR))

    if dealsCount > 1 then
        sigma = round(math.sqrt(sigma/(dealsCount-1)), 2)
        sigmaHPR = round(math.sqrt(sigmaHPR/(dealsCount-1)), 5)
        --myLog(NAME_OF_STRATEGY.." sigmaHPR "..tostring(sigmaHPR))
        sharpe = round((avgHPR - (1 + RFR/100))/sigmaHPR, 2)
    else 
        sigma = 0
        sigmaHPR = 0
    end

    if initalAssets ~= 0 then
        profitRatio = round((equity - initalAssets)*100/initalAssets, 2)
    end

    if seriesCount > 0 then
        local P = 2*(profitDealsLongCount + profitDealsShortCount)*(dealsLongCount - profitDealsLongCount + dealsShortCount - profitDealsShortCount)
        ZCount=round((dealsCount*(seriesCount-0.5)-P)/math.sqrt((P*(P-dealsCount))/(dealsCount-1)), 2)
    end

    return profitRatio, avg, sigma, maxDrawDown, sharpe, round(avgHPR, 2), ZCount
end

function optimizeAlgorithm()
                
    if initalAssets == 0 and CLASS_CODE == "SPBFUT" then
        initalAssets = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "BUYDEPO").param_value) --/priceKoeff
    end
    
    --if beginIndex == 1 then
    --    beginIndex = DS:Size()-testSizeBars
    --end                
    if endIndex == 1 then
        endIndex = DS:Size()
    end                
    if beginIndex <= 0 or beginIndex == endIndex then beginIndex = 1 end
                       
    if initAlgo~=nil then
        initAlgo()    
    end

    lastTradeDirection = 0
    slPrice = 0
    tpPrice = 0
    slIndex = 0
    TransactionPrice = 0
    if settingsTask.STOP_LOSS ~= nil then
        STOP_LOSS = settingsTask.STOP_LOSS
    end
    if settingsTask.TAKE_PROFIT ~= nil then
        TAKE_PROFIT = settingsTask.TAKE_PROFIT
    end
    if settingsTask.shiftStop ~= nil then
        shiftStop = settingsTask.shiftStop
    end
    if settingsTask.shiftProfit ~= nil then
        shiftProfit = settingsTask.shiftProfit
    end

    deals = {
        ["index"] = {},
        ["openLong"] = {},
        ["openShort"] = {},                                   
        ["closeLong"] = {},
        ["closeShort"] = {},                                   
        ["dealProfit"] = {}                                   
    }

    for index = settingsTask.beginIndexToCalc, settingsTask.endIndex do
        calculateAlgo(index, settingsTask)
        simpleTrade(index, calcAlgoValue, trend, deals, settingsTask)  
    end
end

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
        local signaltestvalue1 = calcTrend[index-1] or 0
        local signaltestvalue2 = calcTrend[index-2] or 0
        if signaltestvalue1 > 0 and signaltestvalue2 < 0 then --тренд сменился на растущий
            signal = 1
        end
        if signaltestvalue1 < 0 and signaltestvalue2 > 0 then --тренд сменился на падающий
            signal = -1
        end
    end
    return signal
end

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
        signal = calcTrend[index]
    end
    return signal
end

function simpleTrade(index, calcAlgoValue, calcTrend, deals)

    if index <= beginIndex then return nil end

    local equitySum = initalAssets or 0

    local t = DS:T(index)
    local dealTime = false
    local time = math.ceil((t.hour + t.min/100)*100)
    if time >= startTradeTime then 
        dealTime = true 
    end    
    if time >= endTradeTime then 
        dealTime = false 
    end
    
    if CLASS_CODE == 'QJSIM' or CLASS_CODE == 'TQBR'  then
        dealTime = true 
    end

    tradeSignal = getTradeSignal(index, calcAlgoValue, calcTrend)
    if not dealTime then
        lastTradeDirection = getTradeDirection(index, calcAlgoValue, calcTrend)
    end

    local closeDeal = false
    if calcTrend ~= nil then
        closeDeal = calcTrend[index-1] == 0
    end

    if (not dealTime or closeDeal) and lastDealPrice ~= 0 and (deals["openShort"][dealsCount] ~= nil or deals["openLong"][dealsCount] ~= nil) then
        
        if initalAssets == 0 then
            initalAssets = DS:O(index) --/priceKoeff
            equitySum = initalAssets
        end
        
        if deals["openShort"][dealsCount] ~= nil then
            dealsCount = dealsCount + 1
            if logDeals then
                myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
                myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
            end
            local tradeProfit = round(lastDealPrice - DS:O(index), scale)/priceKoeff
            shortProfit = shortProfit + tradeProfit            
            allProfit = allProfit + tradeProfit
            equitySum = equitySum + tradeProfit
            if tradeProfit > 0 then
                profitDealsShortCount = profitDealsShortCount + 1
            end
            deals["index"][dealsCount] = index 
            deals["closeShort"][dealsCount] = DS:O(index) 
            deals["dealProfit"][dealsCount] = tradeProfit 
            if logDeals then
                myLog(NAME_OF_STRATEGY.." Закрытие шорта "..tostring(deals["openShort"][dealsCount-1]).." по цене "..tostring(DS:O(index)))
                myLog(NAME_OF_STRATEGY.." Прибыль сделки "..tostring(tradeProfit))
                myLog(NAME_OF_STRATEGY.." Прибыль по шортам "..tostring(shortProfit))
                myLog(NAME_OF_STRATEGY.." Прибыль всего "..tostring(allProfit))
                myLog(NAME_OF_STRATEGY.." equity "..tostring(equitySum))
            end
            lastDealPrice = 0
            slPrice = 0
            slIndex = 0
            tpPrice = 0
        end
        if deals["openLong"][dealsCount] ~= nil then
            dealsCount = dealsCount + 1
            if logDeals then
                myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
                myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
            end
            local tradeProfit = round(DS:O(index) - lastDealPrice, scale)/priceKoeff
            longProfit = longProfit + tradeProfit             
            allProfit = allProfit + tradeProfit       
            equitySum = equitySum + tradeProfit
            if tradeProfit > 0 then
                profitDealsLongCount = profitDealsLongCount + 1
            end
            deals["index"][dealsCount] = index 
            deals["closeLong"][dealsCount] = DS:O(index) 
            deals["dealProfit"][dealsCount] = tradeProfit 
            if logDeals then
                myLog(NAME_OF_STRATEGY.." Закрытие лонга "..tostring(deals["openLong"][dealsCount-1]).." по цене "..tostring(DS:O(index)))
                myLog(NAME_OF_STRATEGY.." Прибыль сделки "..tostring(tradeProfit))
                myLog(NAME_OF_STRATEGY.." Прибыль по лонгам "..tostring(longProfit))
                myLog(NAME_OF_STRATEGY.." Прибыль всего "..tostring(allProfit))
                myLog(NAME_OF_STRATEGY.." equity "..tostring(equitySum))
            end
            lastDealPrice = 0
            slPrice = 0
            slIndex = 0
            tpPrice = 0
        end
    end

    if dealTime and slIndex ~= 0 and (index - slIndex) == reopenPosAfterStop then
        if logDeals then
            myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
            myLog(NAME_OF_STRATEGY..' index '..tostring(index).." тест после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
        end
        local currentTradeDirection = getTradeDirection(index, calcAlgoValue, calcTrend, DS)

        if currentTradeDirection == 1 and deals["closeLong"][dealsCount]~=nil then
            if deals["closeLong"][dealsCount]<DS:O(index) then
                if logDeals then
                    myLog(NAME_OF_STRATEGY.." переоткрытие лонга после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
                end
                lastTradeDirection = currentTradeDirection
                reopenAfterStop = true
            end
        end
        if currentTradeDirection == -1 and deals["closeShort"][dealsCount]~=nil then
            if deals["closeShort"][dealsCount]>DS:O(index) then
                if logDeals then
                    myLog(NAME_OF_STRATEGY.." переоткрытие шорта после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
                end
                lastTradeDirection = currentTradeDirection
                reopenAfterStop = true
            end
        end
        slIndex = index
    end

    if (tradeSignal == 1 or lastTradeDirection == 1) and dealTime and not closeDeal then
        
        dealsCount = dealsCount + 1
        if initalAssets == 0 then
            initalAssets = DS:O(index) --/priceKoeff
            equitySum = initalAssets
        end
        if logDeals then
            myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
            myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
            myLog(NAME_OF_STRATEGY.." tradeSignal "..tostring(tradeSignal).." lastTradeDirection "..tostring(lastTradeDirection).." openShort "..tostring(deals["openShort"][dealsCount-1])..' openLong '..tostring(deals["openLong"][dealsCount-1]))
        end

        lastTradeDirection = 0
        if deals["openShort"][dealsCount-1] ~= nil then
            local tradeProfit = round(lastDealPrice - DS:O(index), scale)/priceKoeff
            shortProfit = shortProfit + tradeProfit            
            allProfit = allProfit + tradeProfit
            equitySum = equitySum + tradeProfit
            slPrice = 0
            slIndex = 0
            tpPrice = 0
            if tradeProfit > 0 then
                profitDealsShortCount = profitDealsShortCount + 1
            end
            deals["index"][dealsCount] = index 
            deals["closeShort"][dealsCount] = DS:O(index) 
            deals["dealProfit"][dealsCount] = tradeProfit 

            if logDeals then
                myLog(NAME_OF_STRATEGY.." Закрытие шорта "..tostring(deals["openShort"][dealsCount-1]).." по цене "..tostring(DS:O(index)))
                myLog(NAME_OF_STRATEGY.." Прибыль сделки "..tostring(tradeProfit))
                myLog(NAME_OF_STRATEGY.." Прибыль по шортам "..tostring(shortProfit))
                myLog(NAME_OF_STRATEGY.." Прибыль всего "..tostring(allProfit))
                myLog(NAME_OF_STRATEGY.." equity "..tostring(equitySum))
            end
        end        
        if isLong then
            dealsLongCount = dealsLongCount + 1
            lastDealPrice = DS:O(index)
            TransactionPrice = lastDealPrice
            if STOP_LOSS~=0 then
                --slPrice = lastDealPrice - STOP_LOSS*priceKoeff
                local atPrice = calcAlgoValue[index-1]
                local shiftSL = (kATR*ATR[index-1] + 40*SEC_PRICE_STEP)
                if (atPrice - shiftSL) >= TransactionPrice then
                    atPrice = TransactionPrice
                end
                if fixedstop then
                    shiftSL = STOP_LOSS*priceKoeff
                    atPrice = TransactionPrice
                end
                slPrice = round(atPrice - shiftSL, scale)
                if reopenAfterStop then dealMaxStop = reopenDealMaxStop else dealMaxStop = maxStop end
                if (lastDealPrice - slPrice) > dealMaxStop*priceKoeff then slPrice = lastDealPrice - dealMaxStop*priceKoeff end
                reopenAfterStop = false
                slIndex = 0
                lastStopShiftIndex = index
            end
            if TAKE_PROFIT~=0 then
                tpPrice = round(lastDealPrice + TAKE_PROFIT*priceKoeff, scale)
            end
            deals["index"][dealsCount] = index 
            deals["openLong"][dealsCount] = DS:O(index) 
            if logDeals then
                myLog(NAME_OF_STRATEGY.." Покупка по цене "..tostring(lastDealPrice).." SL "..tostring(slPrice).." TP "..tostring(tpPrice))
            end
        else
            lastDealPrice = 0
        end
    end
    if (tradeSignal == -1 or lastTradeDirection == -1) and dealTime and not closeDeal then
        
        dealsCount = dealsCount + 1
        if initalAssets == 0 then
            initalAssets = DS:O(index) --/priceKoeff
        end
        if logDeals then
            myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
            myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index)))
            myLog(NAME_OF_STRATEGY.." tradeSignal "..tostring(tradeSignal).." lastTradeDirection "..tostring(lastTradeDirection).." openShort "..tostring(deals["openShort"][dealsCount-1])..' openLong '..tostring(deals["openLong"][dealsCount-1]))
        end
        lastTradeDirection = 0
        if deals["openLong"][dealsCount-1] ~= nil then
            local tradeProfit = round(DS:O(index) - lastDealPrice, scale)/priceKoeff
            longProfit = longProfit + tradeProfit             
            allProfit = allProfit + tradeProfit       
            equitySum = equitySum + tradeProfit
            slPrice = 0
            slIndex = 0
            tpPrice = 0
            if tradeProfit > 0 then
                profitDealsLongCount = profitDealsLongCount + 1
            end
            deals["index"][dealsCount] = index 
            deals["closeLong"][dealsCount] = DS:O(index) 
            deals["dealProfit"][dealsCount] = tradeProfit 
            if logDeals then
                myLog(NAME_OF_STRATEGY.." Закрытие лонга "..tostring(deals["openLong"][dealsCount-1]).." по цене "..tostring(DS:O(index)))
                myLog(NAME_OF_STRATEGY.." Прибыль сделки "..tostring(tradeProfit))
                myLog(NAME_OF_STRATEGY.." Прибыль по лонгам "..tostring(longProfit))
                myLog(NAME_OF_STRATEGY.." Прибыль всего "..tostring(allProfit))
                myLog(NAME_OF_STRATEGY.." equity "..tostring(equitySum))
            end
        end
        if isShort then
            dealsShortCount = dealsShortCount + 1
            lastDealPrice = DS:O(index)
            TransactionPrice = lastDealPrice
            if STOP_LOSS~=0 then
                --slPrice = lastDealPrice + STOP_LOSS*priceKoeff
                local atPrice = calcAlgoValue[index-1]
                local shiftSL = (kATR*ATR[index-1] + 40*SEC_PRICE_STEP)
                if (atPrice + shiftSL) <= TransactionPrice then
                    atPrice = TransactionPrice
                end
                if fixedstop then
                    shiftSL = STOP_LOSS*priceKoeff
                    atPrice = TransactionPrice
                end
                slPrice = round(atPrice + shiftSL, scale)
                if reopenAfterStop then dealMaxStop = reopenDealMaxStop else dealMaxStop = maxStop end
                if (slPrice - lastDealPrice) > dealMaxStop*priceKoeff then slPrice = lastDealPrice + dealMaxStop*priceKoeff end
                reopenAfterStop = false
                slIndex = 0
                lastStopShiftIndex = index
            end
            if TAKE_PROFIT~=0 then
                tpPrice = round(lastDealPrice - TAKE_PROFIT*priceKoeff, scale)
            end            
            deals["index"][dealsCount] = index 
            deals["openShort"][dealsCount] = DS:O(index) 
            if logDeals then
                myLog(NAME_OF_STRATEGY.." Продажа по цене "..tostring(lastDealPrice).." SL "..tostring(slPrice).." TP "..tostring(tpPrice))
            end
        else
            lastDealPrice = 0
        end
    end
    
    checkSL_TP(index, calcAlgoValue, calcTrend, deals, equitySum)   
    
    if index == endIndex and (deals["openShort"][dealsCount] ~= nil or deals["openLong"][dealsCount] ~= nil) then
        
        if logDeals then
            myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
            myLog(NAME_OF_STRATEGY.." last index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index)))
        end
 
        if initalAssets == 0 then
            initalAssets = DS:O(index) --/priceKoeff
            equitySum = initalAssets
        end
        
        if deals["openShort"][dealsCount] ~= nil then
            dealsCount = dealsCount + 1
            local tradeProfit = round(lastDealPrice - DS:C(index), scale)/priceKoeff
            shortProfit = shortProfit + tradeProfit            
            allProfit = allProfit + tradeProfit
            equitySum = equitySum + tradeProfit
            if tradeProfit > 0 then
                profitDealsShortCount = profitDealsShortCount + 1
            end
            deals["index"][dealsCount] = index 
            deals["closeShort"][dealsCount] = DS:C(index) 
            deals["dealProfit"][dealsCount] = tradeProfit 
            if logDeals then
                myLog(NAME_OF_STRATEGY.." Закрытие шорта "..tostring(deals["openShort"][dealsCount-1]).." по цене "..tostring(DS:O(index)))
                myLog(NAME_OF_STRATEGY.." Прибыль сделки "..tostring(tradeProfit))
                myLog(NAME_OF_STRATEGY.." Прибыль по шортам "..tostring(shortProfit))
                myLog(NAME_OF_STRATEGY.." Прибыль всего "..tostring(allProfit))
                myLog(NAME_OF_STRATEGY.." equity "..tostring(equitySum))
            end
        end
        if deals["openLong"][dealsCount] ~= nil then
            dealsCount = dealsCount + 1
            local tradeProfit = round(DS:O(index) - lastDealPrice, scale)/priceKoeff
            longProfit = longProfit + tradeProfit             
            allProfit = allProfit + tradeProfit       
            equitySum = equitySum + tradeProfit
            if tradeProfit > 0 then
                profitDealsLongCount = profitDealsLongCount + 1
            end
            deals["index"][dealsCount] = index 
            deals["closeLong"][dealsCount] = DS:C(index) 
            deals["dealProfit"][dealsCount] = tradeProfit 
            if logDeals then
                myLog(NAME_OF_STRATEGY.." Закрытие лонга "..tostring(deals["openLong"][dealsCount-1]).." по цене "..tostring(DS:O(index)))
                myLog(NAME_OF_STRATEGY.." Прибыль сделки "..tostring(tradeProfit))
                myLog(NAME_OF_STRATEGY.." Прибыль по лонгам "..tostring(longProfit))
                myLog(NAME_OF_STRATEGY.." Прибыль всего "..tostring(allProfit))
                myLog(NAME_OF_STRATEGY.." equity "..tostring(equitySum))
            end
        end
    end

end

function checkSL_TP(index, calcAlgoValue, calcTrend, deals, equitySum)

    if (slPrice~=0 or tpPrice~=0) and lastDealPrice~=0 then
        
        if deals["openLong"][dealsCount] ~= nil then
            if DS:L(index) <= slPrice and slPrice~=0 then 
                dealsCount = dealsCount + 1
                local tradeProfit = round(slPrice - lastDealPrice, scale)/priceKoeff
                longProfit = longProfit + tradeProfit             
                allProfit = allProfit + tradeProfit       
                equitySum = equitySum + tradeProfit
                if tradeProfit > 0 then
                    profitDealsLongCount = profitDealsLongCount + 1
                end
                slDealsLongCount = slDealsLongCount + 1
                deals["index"][dealsCount] = index 
                deals["closeLong"][dealsCount] = slPrice 
                deals["dealProfit"][dealsCount] = tradeProfit 
                slIndex = index
                if logDeals then
                    myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
                    myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
                    myLog(NAME_OF_STRATEGY.." Стоп-лосс лонга "..tostring(deals["openLong"][dealsCount-1]).." по цене "..tostring(slPrice))
                    myLog(NAME_OF_STRATEGY.." Прибыль сделки "..tostring(tradeProfit))
                    myLog(NAME_OF_STRATEGY.." Прибыль по лонгам "..tostring(longProfit))
                    myLog(NAME_OF_STRATEGY.." Прибыль всего "..tostring(allProfit))
                    myLog(NAME_OF_STRATEGY.." equity "..tostring(equitySum))
                end
                lastDealPrice = 0
                slPrice = 0
                tpPrice = 0
            end
            if DS:H(index) >= tpPrice and tpPrice~=0 then 
                dealsCount = dealsCount + 1
                local tradeProfit = round(tpPrice - lastDealPrice, scale)/priceKoeff
                longProfit = longProfit + tradeProfit             
                allProfit = allProfit + tradeProfit       
                equitySum = equitySum + tradeProfit
                if tradeProfit > 0 then
                    profitDealsLongCount = profitDealsLongCount + 1
                end
                tpDealsLongCount = tpDealsLongCount + 1
                deals["index"][dealsCount] = index 
                deals["closeLong"][dealsCount] = tpPrice 
                deals["dealProfit"][dealsCount] = tradeProfit 
                if logDeals then
                    myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
                    myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
                    myLog(NAME_OF_STRATEGY.." Тейк-профит лонга "..tostring(deals["openLong"][dealsCount-1]).." по цене "..tostring(tpPrice))
                    myLog(NAME_OF_STRATEGY.." Прибыль сделки "..tostring(tradeProfit))
                    myLog(NAME_OF_STRATEGY.." Прибыль по лонгам "..tostring(longProfit))
                    myLog(NAME_OF_STRATEGY.." Прибыль всего "..tostring(allProfit))
                    myLog(NAME_OF_STRATEGY.." equity "..tostring(equitySum))
                end
                lastDealPrice = 0
                slPrice = 0
                slIndex = index
                tpPrice = 0
            end
            local isPriceMove = (DS:H(index) - TransactionPrice >= STOP_LOSS*priceKoeff) and STOP_LOSS~=0
            if (shiftStop or shiftProfit) and (isPriceMove or (index - lastStopShiftIndex)>stopShiftIndexWait) and deals["closeLong"][dealsCount] == nil then
                lastStopShiftIndex = index
                local shiftCounts = math.floor((DS:H(index) - TransactionPrice)/(STOP_LOSS*priceKoeff))
                if logDeals then
                    myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
                    myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount)..' isPriceMove '..tostring(isPriceMove))                        
                    myLog(NAME_OF_STRATEGY.." shiftCounts "..tostring(shiftCounts).." TransactionPrice "..tostring(TransactionPrice).." H "..tostring(DS:H(index)).." calcAlgoValue[index-1] "..tostring(calcAlgoValue[index-1]).." STOP_LOSS*priceKoeff "..tostring(STOP_LOSS*priceKoeff))
                end
                if slPrice~=0 and shiftStop then
                    local oldStop = slPrice
                    --slPrice = DS:H(index) - STOP_LOSS*priceKoeff
                    local atPrice = calcAlgoValue[index-1]
                    local shiftSL = (kATR*ATR[index-1] + 40*SEC_PRICE_STEP)
                    --TransactionPrice = TransactionPrice+STOP_LOSS*priceKoeff
                    TransactionPrice = DS:H(index)
                    if (atPrice - shiftSL) >= TransactionPrice then
                        atPrice = TransactionPrice
                    end
                    --slPrice = round(atPrice - shiftSL, scale)
                    if fixedstop then
                        shiftSL = STOP_LOSS*priceKoeff
                        atPrice = TransactionPrice
                    end
                    slPrice = math.max(round(atPrice - shiftSL, scale), round(deals["openLong"][dealsCount] + 0*SEC_PRICE_STEP, scale))
                    if (deals["openLong"][dealsCount] - slPrice) > maxStop*priceKoeff then slPrice = deals["openLong"][dealsCount] - maxStop*priceKoeff end
                    slPrice = math.min(math.max(oldStop,slPrice), DS:L(index))
                    if logDeals then
                        myLog(NAME_OF_STRATEGY.." Сдвиг стоп-лосса "..tostring(slPrice))
                        myLog(NAME_OF_STRATEGY.." new TransactionPrice "..tostring(TransactionPrice))
                    end
                end
                if tpPrice~=0 and isPriceMove and shiftProfit then --slPrice~=0 and 
                    tpPrice = round(tpPrice + shiftCounts*STOP_LOSS*priceKoeff/2, scale)
                    if logDeals then
                        myLog(NAME_OF_STRATEGY.." Сдвиг тейка "..tostring(tpPrice))
                    end
                end
            end
        end

        if deals["openShort"][dealsCount] ~= nil then
            if DS:H(index) >= slPrice and slPrice~=0 then 
                dealsCount = dealsCount + 1
                local tradeProfit = round(lastDealPrice - slPrice, scale)/priceKoeff
                shortProfit = shortProfit + tradeProfit            
                allProfit = allProfit + tradeProfit
                equitySum = equitySum + tradeProfit
                if tradeProfit > 0 then
                    profitDealsShortCount = profitDealsShortCount + 1
                end
                slDealsShortCount = slDealsShortCount + 1
                deals["index"][dealsCount] = index 
                deals["closeShort"][dealsCount] = slPrice 
                deals["dealProfit"][dealsCount] = tradeProfit 
                slIndex = index
                if logDeals then
                    myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
                    myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
                    myLog(NAME_OF_STRATEGY.." Стоп-лосс шорта "..tostring(deals["openShort"][dealsCount-1]).." по цене "..tostring(slPrice))
                    myLog(NAME_OF_STRATEGY.." Прибыль сделки "..tostring(tradeProfit))
                    myLog(NAME_OF_STRATEGY.." Прибыль по шортам "..tostring(shortProfit))
                    myLog(NAME_OF_STRATEGY.." Прибыль всего "..tostring(allProfit))
                    myLog(NAME_OF_STRATEGY.." equity "..tostring(equitySum))
                end
                lastDealPrice = 0
                slPrice = 0
                tpPrice = 0
            end
            if DS:L(index) <= tpPrice and tpPrice~=0 then 
                dealsCount = dealsCount + 1
                local tradeProfit = round(lastDealPrice - tpPrice, scale)/priceKoeff
                shortProfit = shortProfit + tradeProfit            
                allProfit = allProfit + tradeProfit
                equitySum = equitySum + tradeProfit
                if tradeProfit > 0 then
                    profitDealsShortCount = profitDealsShortCount + 1
                end
                tpDealsShortCount = tpDealsShortCount + 1
                deals["index"][dealsCount] = index 
                deals["closeShort"][dealsCount] = tpPrice 
                deals["dealProfit"][dealsCount] = tradeProfit 
                if logDeals then
                    myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
                    myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
                    myLog(NAME_OF_STRATEGY.." Тейк-профит шорта "..tostring(deals["openShort"][dealsCount-1]).." по цене "..tostring(tpPrice))
                    myLog(NAME_OF_STRATEGY.." Прибыль сделки "..tostring(tradeProfit))
                    myLog(NAME_OF_STRATEGY.." Прибыль по шортам "..tostring(shortProfit))
                    myLog(NAME_OF_STRATEGY.." Прибыль всего "..tostring(allProfit))
                    myLog(NAME_OF_STRATEGY.." equity "..tostring(equitySum))
                end
                lastDealPrice = 0
                slPrice = 0
                slIndex = index
                tpPrice = 0
            end
            local isPriceMove = (TransactionPrice - DS:L(index) >= STOP_LOSS*priceKoeff) and STOP_LOSS~=0
            if (shiftStop or shiftProfit) and (isPriceMove or (index - lastStopShiftIndex)>stopShiftIndexWait) and deals["closeShort"][dealsCount] == nil then
                lastStopShiftIndex = index
                local shiftCounts = math.floor((TransactionPrice - DS:L(index))/(STOP_LOSS*priceKoeff))
                if logDeals then
                    myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
                    myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount)..' isPriceMove '..tostring(isPriceMove))
                    myLog(NAME_OF_STRATEGY.." shiftCounts "..tostring(shiftCounts).." TransactionPrice "..tostring(TransactionPrice).." L(index) "..tostring(DS:L(index)).." calcAlgoValue[index-1] "..tostring(calcAlgoValue[index-1]).." STOP_LOSS*priceKoeff "..tostring(STOP_LOSS*priceKoeff))
                end
                if slPrice~=0 and shiftStop then
                    local oldStop = slPrice
                    --slPrice = DS:L(index) + STOP_LOSS*priceKoeff
                    local atPrice = calcAlgoValue[index-1]
                    local shiftSL = (kATR*ATR[index-1] + 40*SEC_PRICE_STEP)
                    --TransactionPrice = TransactionPrice-STOP_LOSS*priceKoeff
                    TransactionPrice = DS:L(index)
                    if (atPrice + shiftSL) <= TransactionPrice then
                        atPrice = TransactionPrice
                    end                   
                    --slPrice = round(atPrice + shiftSL, scale)
                    if fixedstop then
                        shiftSL = STOP_LOSS*priceKoeff
                        atPrice = TransactionPrice
                    end
                    slPrice = math.min(round(atPrice + shiftSL, scale), round(deals["openShort"][dealsCount] - 0*SEC_PRICE_STEP, scale))
                    if (slPrice-deals["openShort"][dealsCount]) > maxStop*priceKoeff then slPrice =  deals["openShort"][dealsCount] + maxStop*priceKoeff end
                    slPrice = math.max(math.min(oldStop,slPrice), DS:H(index))
                    if logDeals then
                        myLog(NAME_OF_STRATEGY.." Сдвиг стоп-лосса "..tostring(slPrice))
                        myLog(NAME_OF_STRATEGY.." new TransactionPrice "..tostring(TransactionPrice))
                    end
                end
                if tpPrice~=0 and isPriceMove and shiftProfit then --slPrice~=0 and 
                    tpPrice = round(tpPrice - shiftCounts*STOP_LOSS*priceKoeff/2, scale)
                    if logDeals then
                        myLog(NAME_OF_STRATEGY.." Сдвиг тейка "..tostring(tpPrice))
                    end
                end
            end
        end
    end

end

--------------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ СКРИПТА --
--------------------------------------------------------------------

function mysplit(inputstr, sep)
     
    if sep == nil then
             sep = "%s"
     end
     local t={} 
     local i=1
     for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
             t[i] = str
             i = i + 1
     end
     return t
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

-- функция записывает в лог строчку с временем и датой 
function myLog(str)
   
    if not logging or logFile==nil then return end
 
   local current_time=os.time()--tonumber(timeformat(getInfoParam("SERVERTIME"))) -- помещене в переменную времени сервера в формате HHMMSS 
   if (current_time-g_previous_time)>1 then -- если текущая запись произошла позже 1 секунды, чем предыдущая
      logFile:write("\n") -- добавляем пустую строку для удобства чтения
   end
   g_previous_time = current_time 
 
   logFile:write(os.date().."; ".. str .. "\n")
 
   if str:find("Script Stoped") ~= nil then 
      logFile:write("======================================================================================================================\n\n")
      logFile:write("======================================================================================================================\n")
   end
   logFile:flush() -- Сохраняет изменения в файле
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
