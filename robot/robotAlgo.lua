-- nick-h@yandex.ru
-- Glukk Inc ©

local w32 = require("w32")
require("StaticVar")

NAME_OF_STRATEGY = '' -- НАЗВАНИЕ СТРАТЕГИИ (не более 9 символов!)

ACCOUNT           = '777777'        -- Идентификатор счета
CLIENT_CODE = "777777" -- "Код клиента"
INTERVAL          = INTERVAL_M3          -- Таймфрейм графика (для построения скользящих)
ChartId = "Sheet11"

SetStop = true
isLong  = true
isShort = true
-----------------------------
--виртуальная торговля
virtualTrade = true
vlastDealPrice = 0
vdealProfit = 0
vallProfit = 0
                   
QTY_LOTS = 1 -- Кол-во торгуемых лотов
serverTime = 1000
startTradeTime = 1018
endTradeTime = 1842
eveningSession = 1900
tradeBegin = false

--/*РАБОЧИЕ ПЕРЕМЕННЫЕ РОБОТА (менять не нужно)*/
SEC_PRICE_STEP    = 0                    -- ШАГ ЦЕНЫ ИНСТРУМЕНТА
scale = 0
leverage = 1
DS                = nil                  -- Источник данных графика (DataSource)
ROBOT_STATE       ='FIRSTSTART'-- СОСТОЯНИЕ робота ['В ПРОЦЕССЕ СДЕЛКИ', либо 'В ПОИСКЕ ТОЧКИ ВХОДА']
trans_id          = os.time()            -- Задает начальный номер ID транзакций
trans_Status      = nil                  -- Статус текущей транзакции из функции OnTransPeply
trans_result_msg  = ''                   -- Сообщение по текущей транзакции из функции OnTransPeply
CurrentDirect     = 'BUY'                -- Текущее НАПРАВЛЕНИЕ ['BUY', или 'SELL']
LastOpenBarIndex  =  0                   -- Индекс свечи, на которой была открыта последняя позиция (нужен для того, чтобы после закрытия по стопу тут же не открыть еще одну позицию)
lastSignalIndex = {}
lastCalculatedBar = 0
Run               = true                 -- Флаг поддержания работы бесконечного цикла в main
OpenCount = 0

Settings = {}

isTrade = false
continue = true
StopForbidden = false
TransactionPrice = 0
TakeProfitPrice = 0
CurrentPosAveragePrice = 0 -- Средняя цена текущей позиции

reopenPosAfterStop = 7
stopShiftIndexWait = 17
isPriceMove = false
lastStopShiftIndex = 0
tpPrice = 0
slPrice = 0
oldStop = 0
vtpPrice = 0
vslPrice = 0
slIndex = 0
stopPrice = 0
kATR = 0.95
iterateSLTP = true
reopenAfterStop = false
maxStop = 85
reopenDealMaxStop = 75

t_id = nil
tv_id = nil

SeaGreen=12713921		--	RGB(193, 255, 193) нежно-зеленый
RosyBrown=12698111	--	RGB(255, 193, 193) нежно-розовый

g_previous_time = os.time() -- помещение в переменную времени сервера в формате HHMMSS 
g_stopOrder_num= "" -- номер стоп-заявки на вход в системе, по которому её можно снять

ATR = {}
calcAlgoValue={}
dVal={}

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

curPreset = 1
-----------------------------------------------

-- Функция первичной инициализации скрипта (ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK в самом начале)
function OnInit()
   -- Получает доступ к свечам графика
    if isConnected() == false then
        Run = False
        message("Нет подключения")
        myLog("Нет подключения")
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
        SEC_CODE = 'MMH9', -- код инструмента для торговли
        CLASS_CODE = 'SPBFUT', -- класс инструмента
        ChartId = "Sheet11", -- индентификатор графика, куда выводить метки сделок и данные алгоритма. 
        maxStop       = 85, -- максимально допустимый стоп в пунктах                  
        reopenDealMaxStop       = 75, -- если сделка переоткрыта после стопа, то максимальный стоп                  
        stopShiftIndexWait       = 17, -- если цена не двигается (на величину стопа), то пересчитать стоп после стольких баров                   
        reopenPosAfterStop       = 7, -- если выбило по стоа заявке, то попытаться переоткрыть сделку, после стольких баров                  
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
            Name    = "THV M3",                   
            NAME_OF_STRATEGY = 'THV',
            SEC_CODE = 'MMH9',
            CLASS_CODE = 'SPBFUT',
            ChartId = "Sheet11",
            maxStop       = 85,                   
            reopenDealMaxStop       = 75,                   
            stopShiftIndexWait       = 17,                   
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
            ChartId = "Sheet11",
            maxStop       = 85,                   
            reopenDealMaxStop       = 75,                   
            stopShiftIndexWait       = 17,                   
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
            ChartId = "Sheet11",
            maxStop       = 85,                   
            reopenDealMaxStop       = 75,                   
            stopShiftIndexWait       = 17,                   
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
            ChartId = "Sheet11",
            maxStop       = 85,                   
            reopenDealMaxStop       = 75,                   
            stopShiftIndexWait       = 17,                   
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
            ChartId = "Sheet11",
            maxStop       = 85,                   
            reopenDealMaxStop       = 75,                   
            stopShiftIndexWait       = 17,                   
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
    
    
    Settings           = presets[curPreset].settingsAlgo
    SEC_CODE           = presets[curPreset].SEC_CODE                   
    CLASS_CODE         = presets[curPreset].CLASS_CODE                   
    ChartId            = presets[curPreset].ChartId                   
    maxStop            = presets[curPreset].maxStop                   
    reopenDealMaxStop  = presets[curPreset].reopenDealMaxStop                   
    reopenPosAfterStop = presets[curPreset].reopenPosAfterStop                   
    stopShiftIndexWait = presets[curPreset].stopShiftIndexWait                   
    INTERVAL           = presets[curPreset].INTERVAL                   
    testSizeBars       = presets[curPreset].testSizeBars
    
    --По умолчанию первый пересет
    NAME_OF_STRATEGY    = presets[curPreset].NAME_OF_STRATEGY
    FILE_LOG_NAME = getScriptPath().."\\robot"..NAME_OF_STRATEGY.."_"..SEC_CODE.."Log.txt" -- ИМЯ ЛОГ-ФАЙЛА
    f = io.open(FILE_LOG_NAME, "w") -- открывает файл 

    PARAMS_FILE_NAME = getScriptPath().."\\robot"..NAME_OF_STRATEGY.."_"..SEC_CODE.."_int"..tostring(INTERVAL).."_params.csv" -- ИМЯ ЛОГ-ФАЙЛА

    local Error = ''
    DS,Error = CreateDataSource(CLASS_CODE, SEC_CODE, INTERVAL)
    -- Проверка
    if DS == nil then
        message('Algo robot:ОШИБКА получения доступа к свечам! '..Error)
        -- Завершает выполнение скрипта
        Run = false
        return
    end

    -- шаг
    calculateAlgo       = presets[curPreset].calculateAlgo
    iterateAlgo         = presets[curPreset].iterateAlgo
    initAlgo            = presets[curPreset].initAlgo
    setTableAlgoParams  = presets[curPreset].setTableAlgoParams     
    readTableAlgoParams = presets[curPreset].readTableAlgoParams     
    saveOptimizedParams = presets[curPreset].saveOptimizedParams     
    readOptimizedParams = presets[curPreset].readOptimizedParams
    notReadOptimized    = presets[curPreset].notReadOptimized or false     
   
    if readOptimizedParams~=nil and not notReadOptimized then
        readOptimizedParams()
    end

    CreateTable()

    local last_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)
    SetCell(t_id, 2, 0, tostring(last_price), last_price) 
       
    LastOpenBarIndex = DS:Size()
  
    -- Получает ШАГ ЦЕНЫ ИНСТРУМЕНТА
    SEC_PRICE_STEP = getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value
    scale = getSecurityInfo(CLASS_CODE, SEC_CODE).scale
    STEPPRICE = getParamEx(CLASS_CODE, SEC_CODE, "STEPPRICE").param_value
    if tonumber(STEPPRICE) == 0 or STEPPRICE == nil then
        leverage = 1
    else    
        leverage = STEPPRICE/SEC_PRICE_STEP
    end

    if calculateAlgo==nil then
        calculateAlgo = simpleAlgo    
    end
    
    myLog("CLASS_CODE: "..tostring(CLASS_CODE))
    myLog("SEC: "..tostring(SEC_CODE))
    myLog("PRICE STEP: "..tostring(SEC_PRICE_STEP))
    myLog("SCALE: "..tostring(scale))
    myLog("STEP PRICE: "..tostring(STEPPRICE))
    myLog("leverage: "..tostring(leverage))
    myLog("STOP_LOSS: "..tostring(Settings.STOP_LOSS))
    myLog("TAKE_PROFIT: "..tostring(Settings.TAKE_PROFIT))
    myLog("==================================================")
    myLog("Initialization finished")
 
    DS:SetUpdateCallback(function(...) mycallbackforallstocks(...) end)
   
end

function GetTotalnet()

    if virtualTrade then
        return OpenCount
    end

   -- ФЬЮЧЕРСЫ, ОПЦИОНЫ
   if CLASS_CODE == 'SPBFUT' or CLASS_CODE == 'SPBOPT' then
      for i = 0,getNumberOf('futures_client_holding') - 1 do
         local futures_client_holding = getItem('futures_client_holding',i)
         if futures_client_holding.sec_code == SEC_CODE then
            local pos = futures_client_holding.totalnet
            --SetCell(t_id, 4, 7, tostring(pos), pos) 
            return pos
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
         and depo_limit.trdaccid == ACCOUNT
         and depo_limit.limit_kind == 1 then         
            local pos = depo_limit.currentbal/lotsize
            --SetCell(t_id, 4, 7, tostring(pos), pos) 
            return pos
         end
      end
   end
 
   -- Если позиция по инструменту в таблице не найдена, возвращает 0
    --SetCell(t_id, 4, 7, tostring(0), 0) 
    return 0
end 

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

function mycallbackforallstocks(index)

    -- СОСТОЯНИЕ робота 'В ПОИСКЕ ТОЧКИ ВХОДА'
    -- Если на этой свече еще не было открыто позиций
	--myLog('Index '..tostring(index))
	--myLog('Цена '..tostring(DS:C(DS:Size()))..', Algo: '..tostring(calcAlgoValue[DS:Size()-1])..' СТОП-ЛОСС: '..tostring(GetCorrectPrice(calcAlgoValue[DS:Size()-1] - 50*SEC_PRICE_STEP)))
   
    local last_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)
    local maxPrice = DS:H(index)
    local minPrice = DS:L(index)
    isPriceMove = isPriceMove or (OpenCount < 0 and TransactionPrice - minPrice >= STOP_LOSS/leverage) or (OpenCount > 0 and maxPrice - TransactionPrice >= STOP_LOSS/leverage)

    --local last_price = DS:C(DS:Size())
    local lp = GetCell(t_id, 2, 0).value or last_price
    --myLog("last price "..tostring(last_price))
    --myLog("lp "..tostring(lp))
    if lp < last_price then
        Highlight(t_id, 2, 0, SeaGreen, QTABLE_DEFAULT_COLOR,1000)		-- подсветка мягкий, зеленый
    elseif lp > last_price then
        Highlight(t_id, 2, 0, RosyBrown, QTABLE_DEFAULT_COLOR,1000)		-- подсветка мягкий розовый
    end   
    SetCell(t_id, 2, 0, tostring(last_price), last_price) 
    
    if optimizationInProgress then
        SetCell(t_id, 2, 7, "OPTIMIZATION "..tostring(doneOptimization).."%", doneOptimization)
        return
    end
    
    if virtualTrade then
        --myLog('OpenCount '..tostring(OpenCount))
        --myLog('last_price '..tostring(last_price))
        --myLog('tp_Price '..tostring(tp_Price))
        --myLog('sl_Price '..tostring(sl_Price))
        local vStopPrice = 0
        if OpenCount > 0 and last_price >= tpPrice and tpPrice~=0 then
            myLog("Take profit")
            local vStopPrice = tpPrice
            CloseAll()
            slIndex = index
            stopPrice = vStopPrice
        end
        if OpenCount < 0 and last_price <= tpPrice and tpPrice~=0 then
            myLog("Take profit")
            local vStopPrice = tpPrice
            CloseAll()
            slIndex = index
            stopPrice = vStopPrice
        end
        if OpenCount > 0 and last_price <= slPrice and slPrice~=0 then
            myLog("Stop loss")
            local vStopPrice = slPrice
            CloseAll()
            slIndex = index
            stopPrice = vStopPrice
        end
        if OpenCount < 0 and last_price >= slPrice and slPrice~=0 then
            myLog("Stop loss")
            local vStopPrice = slPrice
            CloseAll()
            slIndex = index
            stopPrice = vStopPrice
        end
    end

    --myLog('serverTime '..tostring(serverTime))
    --myLog('dealtime '..tostring(dealTime))
    --myLog('currentTrend '..tostring(currentTrend))
    --myLog('trend[DS:Size()-1] '..tostring(trend[DS:Size()-1]))
    
    if isTrade and DS:Size() > lastCalculatedBar then 
        
        lastCalculatedBar = DS:Size()
        
        calculateAlgo(DS:Size()-1, Settings)
        --myLog("index "..tostring(DS:Size()-1).." "..tostring(toYYYYMMDDHHMMSS(DS:T(DS:Size()-1))).." trend "..tostring(trend[DS:Size()-1]))

        --myLog('DS:Size() '..tostring(DS:Size())..' calcAlgoValue[DS:Size()-1] '..tostring(calcAlgoValue[DS:Size()-1])..', ATR[DS:Size()-1]: '..tostring(ATR[DS:Size()-1])..' ATRfactor: '..tostring(ATRfactor))
        --local roundAlgoVal = round(calcAlgoValue[DS:Size()-1], scale)
        --SetCell(t_id, 2, 1, tostring(roundAlgoVal), roundAlgoVal) 
        
        if ChartId ~= nil then
            stv.UseNameSpace(ChartId)
            stv.SetVar('algoResults', calcChartResults)                       
        end
        
        local dealTime = serverTime >= startTradeTime
        if dealTime then 
            local time = math.ceil((DS:T(DS:Size()).hour + DS:T(DS:Size()).min/100)*100)
            local time1 = math.ceil((DS:T(DS:Size()-1).hour + DS:T(DS:Size()-1).min/100)*100)
            tradeBegin = time >= startTradeTime and time1 < startTradeTime
        end

        if dealTime and slIndex ~= 0 and (index - slIndex) == reopenPosAfterStop then
            slIndex = index
            myLog("тест после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex))..' '..tostring(stopPrice))
            if trend[DS:Size()-1] > 0 and stopPrice<DS:O(index) then
                if logDeals then
                    myLog("переоткрытие лонга после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
                end
                tradeBegin = true
                reopenAfterStop = true
            end
            if trend[DS:Size()-1] < 0 and stopPrice>DS:O(index) then
                if logDeals then
                    myLog("переоткрытие шорта после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
                end
                tradeBegin = true
                reopenAfterStop = true
            end
        end 
        
        if trend ~= nil then
            if trend[DS:Size()-1] == 0 then
                CloseAll()
            end
        end

        if dealTime and OpenCount <= 0 and DS:Size() > LastOpenBarIndex and ((trend[DS:Size()-1] > 0 and trend[DS:Size()-2] <= 0) or (tradeBegin and trend[DS:Size()-1] > 0)) then
            
            if OpenCount < 0 then
                ROBOT_STATE = 'ПЕРЕВОРОТ'
            else
                ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
            end

            tradeBegin = false

            lastSignalIndex[#lastSignalIndex + 1] = DS:Size()
            LastOpenBarIndex = DS:Size()

            -- Задает направление НА ПОКУПКУ
            CurrentDirect = 'BUY'
            myLog('CurrentDirect = "BUY"')
            -- Меняет СОСТОЯНИЕ робота на "В ПРОЦЕССЕ СДЕЛКИ"
            SetCell(t_id, 2, 5, CurrentDirect)
            SetColor(t_id, 2, 5, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
            SetCell(t_id, 2, 7, ROBOT_STATE)
            TakeProfitPrice = 0
			   			   
        elseif dealTime and OpenCount >= 0 and DS:Size() > LastOpenBarIndex and ((trend[DS:Size()-1] < 0 and trend[DS:Size()-2] >= 0) or (tradeBegin and trend[DS:Size()-1] < 0)) then
            
 			if OpenCount > 0 then
                ROBOT_STATE = 'ПЕРЕВОРОТ'
            else
                ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
            end

            tradeBegin = false

            lastSignalIndex[#lastSignalIndex + 1] = DS:Size()
            LastOpenBarIndex = DS:Size()

            -- Если по данному инструменту не запрещены операции шорт
			if isShort then
                -- Задает направление НА ПРОДАЖУ
                CurrentDirect = 'SELL'
                myLog('CurrentDirect = "SELL"')
                -- Меняет СОСТОЯНИЕ робота на "В ПРОЦЕССЕ СДЕЛКИ"
                SetCell(t_id, 2, 5, CurrentDirect)
                SetColor(t_id, 2, 5, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
                SetCell(t_id, 2, 7, ROBOT_STATE)
                TakeProfitPrice = 0
			end
        end
    end
   
end

function checkSLbeforeClearing()
    
    if SetStop == true and OpenCount ~= 0 then
                        
        if ((serverTime>=1350 and serverTime<1400) or (serverTime>=endTradeTime and serverTime<1845) or (serverTime>=2345 and serverTime<2350)) and StopForbidden == false then
            StopForbidden = true
            myLog('Закрытие стоп-лосса перед клирингом')
            myLog("StopForbidden "..tostring(StopForbidden))
            KillAllStopOrders()
            --needReoptimize = true
        end
        
        if ((serverTime>=1405 and serverTime < 1410) or serverTime>=1905) and StopForbidden == true then
            
            StopForbidden = false
            
            if SetStop == true and not isStopOrder() then 
                myLog('Восстановление стоп-лосса после клиринга')
                local Result = nil -- Переменная для получения результата выставления и срабатывания СТОП-ЛОСС и ТЕЙК-ПРОФИТ
                
                if not Run then return end -- Если скрипт останавливается, не затягивает процесс
                
                -- Выставляет СТОП-ЛОСС и ТЕЙК-ПРОФИТ, ЖДЕТ пока он сработает, принимает ЦЕНУ и ТИП ["BUY", или "SELL"] открытой сделки,
                --- возвращает FALSE, если не удалось выставить СТОП-ЛОСС и ТЕЙК-ПРОФИТ
                myLog(NAME_OF_STRATEGY..' robot: Делает попытку выставить СТОП-ЛОСС и ТЕЙК-ПРОФИТ')
                if OpenCount > 0 then
                    Result = SL_TP(DS:C(DS:Size()), "BUY", OpenCount)
                elseif OpenCount < 0 then
                    Result = SL_TP(DS:C(DS:Size()), "SELL", OpenCount)
                end
                -- Если стоп восстановлен
                if Result == true then
                    TransactionPrice = DS:C(DS:Size())
                end
            end
        end		  
    end

end

function trailStop()

	--трейлим стоп
	if OpenCount ~= 0 and isConnected() then 
         
        local last_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)
        --isPriceMove = (OpenCount < 0 and TransactionPrice - last_price >= STOP_LOSS/leverage) or (OpenCount > 0 and last_price - TransactionPrice >= STOP_LOSS/leverage)
        
        if ROBOT_STATE == 'FIRSTSTART' then
            if not isStopOrder() then
                myLog('Установка стоп-лосса после запуска скрипта')
                if OpenCount > 0 then
                    Result = SL_TP(DS:C(DS:Size()), "BUY", OpenCount)
                elseif OpenCount < 0 then
                    Result = SL_TP(DS:C(DS:Size()), "SELL", OpenCount)
                end
            end
            TransactionPrice = last_price
            ROBOT_STATE = 'ОСТАНОВЛЕН'
            SetCell(t_id, 2, 7, ROBOT_STATE)
        elseif isPriceMove or (OpenCount~=0 and (DS:Size() - lastStopShiftIndex) > stopShiftIndexWait) then
			myLog('Сдвиг стоп-лосса')
			continue = KillAllStopOrders()
			sleep(20)
			if continue == true then
				myLog('Восстановление стоп-лосса после сдвига')
				local Result = nil -- Переменная для получения результата выставления и срабатывания СТОП-ЛОСС и ТЕЙК-ПРОФИТ
                
                if not Run then return end -- Если скрипт останавливается, не затягивает процесс
                
                -- Выставляет СТОП-ЛОСС и ТЕЙК-ПРОФИТ, ЖДЕТ пока он сработает, принимает ЦЕНУ и ТИП ["BUY", или "SELL"] открытой сделки,
				--- возвращает FALSE, если не удалось выставить СТОП-ЛОСС и ТЕЙК-ПРОФИТ
				myLog(NAME_OF_STRATEGY..' robot: Делает попытку выставить СТОП-ЛОСС и ТЕЙК-ПРОФИТ')
                if OpenCount > 0 then
                    Result = SL_TP(last_price, "BUY", OpenCount)
                elseif OpenCount < 0 then
                    Result = SL_TP(last_price, "SELL", OpenCount)
                end
            -- Если стоп сдвинут
                if Result ~= false then
					TransactionPrice = last_price
				end
            end            
        end
            
	end

end

function CloseAll()

    if OpenCount < 0 then
        myLog('Закрытие позиции "SELL": '..tostring(OpenCount))
        continue = KillPos('SELL', -1*OpenCount)
        if continue ~= true then
            Run = false
            message('Закрытие позиции не удалось. Скрипт Algo остановлен')
            myLog('Закрытие позиции не удалось. Скрипт Algo остановлен')
        end
    end
    if OpenCount > 0 then
        myLog('Закрытие позиции "BUY": '..tostring(OpenCount))
        continue = KillPos('BUY', OpenCount)
        if continue ~= true then
            Run = false
            message('Закрытие позиции не удалось. Скрипт Algo остановлен')
            myLog('Закрытие позиции не удалось. Скрипт Algo остановлен')
        end
    end
    if continue == true and SetStop == true then
        myLog('Закрытие стоп-лосса')
        continue = KillAllStopOrders()
        if continue ~= true then
            Run = false
            message('Закрытие стопа позиции не удалось. Скрипт Algo остановлен')
            myLog('Закрытие стопа позиции не удалось. Скрипт Algo остановлен')
        end
    end
    
    if continue == true then
        TakeProfitPrice = 0    

        lastStopShiftIndex = 0
        tpPrice = 0
        slPrice = 0
        oldStop = 0
        slIndex = 0
        stopPrice = 0
        SetCell(t_id, 2, 3, tostring(slPrice), slPrice) 
        SetCell(t_id, 2, 4, tostring(tpPrice), tpPrice)
    end
        
    --[[
     local k = #lastSignalIndex
    if isTrade and k > 2 then
        
        local Price1 = DS:O(lastSignalIndex[k])
        local Price2 = DS:O(lastSignalIndex[k-1])
        local Price3 = DS:O(lastSignalIndex[k-2])
        local trend1 = trend[lastSignalIndex[k]-1]
        local trend2 = trend[lastSignalIndex[k-1]-1]
        local dealDelta1 = math.abs(Price1 - Price2)
        local dealDelta2 = math.abs(Price2 - Price3)
        local isLose1 = (trend1 == 1 and Price1 > Price2) or (trend1 == -1 and Price1 < Price2)
        local isLose2 = (trend2 == 1 and Price2 > Price3) or (trend2 == -1 and Price2 < Price3)

        if (math.ceil(dealDelta1/SEC_PRICE_STEP) < 20 or isLose1) and (math.ceil(dealDelta2/SEC_PRICE_STEP) < 20 or isLose2) then
            myLog('Прошли две сделки с убытком или очень малым спредом, проводим реоптимизацию')
            myLog('dealDelta1 '..tostring(dealDelta1))
            myLog('dealDelta2 '..tostring(dealDelta2))
            myLog('isLose1 '..tostring(isLose1))
            myLog('isLose2 '..tostring(isLose2))
            
            needReoptimize = true
            --ROBOT_STATE = 'РЕОПТИМИЗАЦИЯ'
            --continue = false
            --if isTrade then
            --    isTrade = false
            --    SetCell(t_id, 2, 7, ROBOT_STATE)
            --    SetCell(t_id, 3, 4, "START")  --i строка, 0 - колонка, v - значение 
            --    SetColor(t_id, 3, 4, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
            --end    
        end
    end
    ]]--    

end

function reoptimize()
    
    ROBOT_STATE = 'РЕОПТИМИЗАЦИЯ'
    if isTrade then
        isTrade = false
        SetCell(t_id, 2, 7, ROBOT_STATE)
        SetCell(t_id, 3, 0, "START")  --i строка, 0 - колонка, v - значение 
        SetColor(t_id, 3, 0, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
    end    

    setParameters()
    lastSignalIndex = {}
    
    myLog('Старт реопртимизации')

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
        SetCell(t_id, 2, 7, ROBOT_STATE)
    end

    if isTrade then 
        if (OpenCount > 0 and trend[DS:Size()-1] == -1) or (OpenCount < 0 and trend[DS:Size()-1] == 1) then
            myLog('CurrentDirect = '..CurrentDirect)
            myLog('Открыта позиция против тренда, переворачиваем')
            ROBOT_STATE = 'ПЕРЕВОРОТ'
            if trend[DS:Size()-1] < 0 then
                CurrentDirect = 'SELL'
            else
                CurrentDirect = 'BUY'
            end        
            TakeProfitPrice = 0
        end
        if OpenCount == 0 then
            ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
            if trend[DS:Size()-1] < 0 then
                CurrentDirect = 'SELL'
            else
                CurrentDirect = 'BUY'
            end        
            TakeProfitPrice = 0
        end
    end

end

function main()
    
    SetTableNotificationCallback(t_id, event_callback)
    SetTableNotificationCallback(tv_id, volume_event_callback)

    while Run do 
      
        --if isConnected() == false then
        --    Run = false
        --end

        if not Run then break end

        --if ROBOT_STATE == 'ОПТИМИЗАЦИЯ' or ROBOT_STATE == 'РЕОПТИМИЗАЦИЯ' then
        if ROBOT_STATE == 'ОПТИМИЗАЦИЯ' or needReoptimize then
            myLog('optimizationInProgress = '..tostring(optimizationInProgress))
            if not optimizationInProgress then
                myLog('ROBOT_STATE = '..tostring(ROBOT_STATE))
                optimizationInProgress = true
                doneOptimization = 0
                SetCell(t_id, 4, 6, "STOP OPTIMIZE")
                SetCell(t_id, 2, 7, "OPTIMIZATION "..tostring(doneOptimization).."%", doneOptimization)
                if ROBOT_STATE == 'ОПТИМИЗАЦИЯ' then
                    if iterateAlgo~=nil then
                        iterateAlgo()    
                    end
                    ROBOT_STATE = 'ОСТАНОВЛЕН'
                    SetCell(t_id, 2, 7, ROBOT_STATE)
                else    
                    reoptimize()
                end
                SetCell(t_id, 4, 6, "OPTIMIZE")
            end
        else
        
            OpenCount = GetTotalnet()
            continue = true 
            local ss = getInfoParam("SERVERTIME")
            if string.len(ss) >= 5 then            
                local hh = mysplit(ss,":")
                local str=hh[1]..hh[2]
                serverTime = tonumber(str)
            end
                    
            if SetStop == true and OpenCount ~= 0 then 
                checkSLbeforeClearing()
                trailStop()
            end

            if isTrade and serverTime >= endTradeTime and serverTime < eveningSession then
                --ROBOT_STATE = 'ОСТАНОВЛЕН'
                isTrade = false
                CloseAll()
                needReoptimize = true
            end

            if ROBOT_STATE == 'ПЕРЕВОРОТ' or ROBOT_STATE == 'CLOSEALL' then
                if CurrentDirect == "AUTO" then
                    if OpenCount > 0 then
                        CurrentDirect = "SELL"
                    elseif OpenCount < 0 then
                        CurrentDirect = "BUY"
                    end
                end
                CloseAll()
                if continue == true and ROBOT_STATE == 'ПЕРЕВОРОТ' then
                    ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
                elseif continue == true then
                    ROBOT_STATE = 'В ПОИСКЕ ТОЧКИ ВХОДА'
                end
            end

            --Если СОСТОЯНИЕ робота "В ПРОЦЕССЕ СДЕЛКИ"
            if ROBOT_STATE == 'В ПРОЦЕССЕ СДЕЛКИ' then
                    
                local Price = false -- Переменная для получения результата открытия позиции (цена, либо ошибка(false))
                    
                if not Run then return end -- Если скрипт останавливается, не затягивает процесс
                
                -- Если пытается открыть SELL, а операции шорт по данному инструменту запрещены
                if CurrentDirect == "SELL" and not isShort then
                    myLog(NAME_OF_STRATEGY..' robot: Была первая попытка совершить запрещенную операцию шорт!')
                    ROBOT_STATE = 'В ПОИСКЕ ТОЧКИ ВХОДА'
                    SetCell(t_id, 2, 7, ROBOT_STATE)
                    --LastOpenBarIndex = DS:Size()
                else    
                
                    -- Совершает СДЕЛКУ указанного типа ["BUY", или "SELL"] по рыночной(текущей) цене размером в 1 лот,
                    --- возвращает цену открытой сделки, либо FALSE, если невозможно открыть сделку
                    Price = Trade(CurrentDirect, QTY_LOTS)
                    --Price = DS:C(DS:Size())

                    if not Run then return end -- Если скрипт останавливается, не затягивает процесс
                    
                    -- Если сделка открылась
                    if Price ~= false and Price ~= -1 then
                        
                        TransactionPrice = Price;                        
                        lastDealPrice = Price
                        
                        -- Запоминает индекс свечи, на которой была открыта последняя позиция (нужен для того, чтобы после закрытия по стопу тут же не открыть еще одну позицию)
                        --LastOpenBarIndex = DS:Size()
                        myLog(NAME_OF_STRATEGY..' robot: Открыта сделка '..CurrentDirect..' по цене '..tostring(Price))
                        
                        if SetStop == true  and StopForbidden == false then 
                            
                            local Result = nil -- Переменная для получения результата выставления и срабатывания СТОП-ЛОСС и ТЕЙК-ПРОФИТ
                                                    
                            -- Выставляет СТОП-ЛОСС и ТЕЙК-ПРОФИТ, ЖДЕТ пока он сработает, принимает ЦЕНУ и ТИП ["BUY", или "SELL"] открытой сделки,
                            --- возвращает FALSE, если не удалось выставить СТОП-ЛОСС и ТЕЙК-ПРОФИТ
                            myLog(NAME_OF_STRATEGY..' robot: Делает попытку выставить СТОП-ЛОСС и ТЕЙК-ПРОФИТ')
                            OpenCount = GetTotalnet()
                            if OpenCount ~= 0 then
                                Result = SL_TP(Price, CurrentDirect, OpenCount)
                            else
                                tpPrice = 0
                                slPrice = 0
                                oldStop = 0
                                lastStopShiftIndex = 0
                                SetCell(t_id, 2, 3, tostring(slPrice), slPrice) 
                                SetCell(t_id, 2, 4, tostring(tpPrice), tpPrice)                
                            end
                        end

                        -- все выставлено. ждем развортного сигнала
                        ROBOT_STATE = 'В ПОИСКЕ ТОЧКИ ВХОДА'
                        SetCell(t_id, 2, 7, ROBOT_STATE)

                    else -- Сделку не удалось открыть
                        
                        -- Выводит сообщение
                        message(NAME_OF_STRATEGY..' robot: неудачная попытка открыть сделку!!! Завершение скрипта!!!')
                        myLog(NAME_OF_STRATEGY..' robot: неудачная попытка открыть сделку!!! Завершение скрипта!!!')
                        -- Завершает выполнение скрипта
                        Run = false
                    end

                end
            end         

            if not isTrade and ROBOT_STATE ~= 'ОСТАНОВЛЕН' and ROBOT_STATE ~= 'ОПТИМИЗАЦИЯ' and ROBOT_STATE ~= 'РЕОПТИМИЗАЦИЯ' then 
                ROBOT_STATE = 'ОСТАНОВЛЕН' 
                SetCell(t_id, 2, 7, ROBOT_STATE)
                SetCell(t_id, 3, 0, "START")  --i строка, 0 - колонка, v - значение 
                SetColor(t_id, 3, 0, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
            end
        end

        sleep(100)			
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
    AddColumn(t_id, 5, "6", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 6, "7", true, QTABLE_DOUBLE_TYPE, 18)
    AddColumn(t_id, 7, "8", true, QTABLE_STRING_TYPE, 25)

    tbl = CreateWindow(t_id) -- Создает таблицу
    SetWindowCaption(t_id, NAME_OF_STRATEGY..' Robot '..SEC_CODE) -- Устанавливает заголовок
    SetWindowPos(t_id, 980, 120, 720, 157) -- Задает положение и размеры окна таблицы
    
    -- Добавляет строки
    InsertRow(t_id, 1)
    SetCell(t_id, 1, 0, "Price", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 1, 1, "Algo", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 1, 2, "Pos", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 1, 3, "SL", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 1, 4, "TP", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 1, 5, "Type", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 1, 6, "INTERVAL", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 1, 7, "State", 0)  --i строка, 0 - колонка, v - значение 
    
    InsertRow(t_id, 2)
    SetCell(t_id, 2, 6, tostring(INTERVAL), INTERVAL)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 2, 7, ROBOT_STATE)

    InsertRow(t_id, 3)
    SetCell(t_id, 3, 0, "START", 0)  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 0, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
    SetCell(t_id, 3, 2, "SELL", 0)  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 2, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
    SetCell(t_id, 3, 3, "BUY", 0)  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 3, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
    SetCell(t_id, 3, 4, "REVERSE", 0)  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 4, RGB(200,200,200), RGB(0,0,0), RGB(200,200,200), RGB(0,0,0))
    SetCell(t_id, 3, 5, "CLOSE ALL", 0)  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 5, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
    SetCell(t_id, 3, 6, "KILL ALL SL", 0)  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 6, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
    SetCell(t_id, 3, 7, "SET SL/TP", 0)  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 7, RGB(168,255,168), RGB(0,0,0), RGB(168,255,168), RGB(0,0,0))
    
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

function setParameters()

    if readTableAlgoParams~=nil then
        readTableAlgoParams()    
    end
    
    testSizeBars = GetCell(t_id, 6, 4).value
    ChartId = GetCell(t_id, 6, 5).image
    STOP_LOSS = GetCell(t_id, 6, 6).value
    TAKE_PROFIT = tonumber(GetCell(t_id, 6, 7).image)
    INTERVAL = GetCell(t_id, 2, 6).value
end

function startTrade()
   
    myLog(NAME_OF_STRATEGY..' robot: старт торговли')
    setParameters()

    currentTrend = 0
    slIndex = 0
    stopPrice = 0
    lastStopShiftIndex = DS:Size()

    if virtualTrade then
        slPrice = GetCell(t_id, 2, 3).value
        tpPrice = GetCell(t_id, 2, 4).value
        oldStop = slPrice        
    end

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
        --myLog("index "..tostring(i).." "..tostring(toYYYYMMDDHHMMSS(DS:T(i))).." trend "..tostring(trend[i]))
    end
    if ChartId ~= nil then
        stv.UseNameSpace(ChartId)
        stv.SetVar('algoResults', calcChartResults)                       
    end

    lastCalculatedBar = DS:Size()

    --local roundAlgoVal = round(calcAlgoValue[DS:Size()-1], scale)
    --SetCell(t_id, 2, 1, tostring(roundAlgoVal), roundAlgoVal) 
    LastOpenBarIndex = DS:Size()

    if trend[DS:Size()-1] == -1 then
        CurrentDirect = 'SELL'
        SetColor(t_id, 2, 5, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
    else
        CurrentDirect = 'BUY'
        SetColor(t_id, 2, 5, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
    end
    SetCell(t_id, 2, 5, CurrentDirect)
    TransactionPrice = DS:C(DS:Size())
    SetCell(t_id, 3, 0, "STOP")  --i строка, 0 - колонка, v - значение 
    SetColor(t_id, 3, 0, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
    isTrade = true
    ROBOT_STATE       ='В ПОИСКЕ ТОЧКИ ВХОДА'
    SetCell(t_id, 2, 7, ROBOT_STATE)

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
           SetCell(t_id, tstr, tcell, GetCell(tv_id, par1, 0).image, tonumber(GetCell(tv_id, par1, 0).image))
       end
    end
end

function event_callback(t_id, msg, par1, par2)

    if msg == QTABLE_CHAR then --ChartID
        if tostring(par2) == "8" then
            local newString = string.sub(GetCell(t_id, 6, 5).image, 1, string.len(GetCell(t_id, 6, 5).image)-1)
            SetCell(t_id, 6, 5, newString)
        else
           local inpChar = string.char(par2)
           local newString = GetCell(t_id, 6, 5).image..string.char(par2)            
           SetCell(t_id, 6, 5, newString)
        end
    end

    if msg == QTABLE_LBUTTONDBLCLK then

        if ((par1 == 6 or par1 == 8 or par1 == 10) or (par1 == 2 and par2 == 6)) and IsWindowClosed(tv_id) then
            tstr = par1
            tcell = par2
            AddColumn(tv_id, 0, "Value", true, QTABLE_DOUBLE_TYPE, 25)
            tv = CreateWindow(tv_id) 
            SetWindowCaption(tv_id, "Value") 
            SetWindowPos(tv_id, 290, 260, 250, 100)                                
            InsertRow(tv_id, 1)
            SetCell(tv_id, 1, 0, GetCell(t_id, par1, par2).image, GetCell(t_id, par1, par2).value)  --i строка, 0 - колонка, v - значение 
        end
        
        if par1 == 3 and par2 == 0 then -- Start\Stop
            if isTrade == false and ROBOT_STATE ~= "ОПТИМИЗАЦИЯ" then
                startTrade()
            elseif isTrade then
                isTrade = false
                ROBOT_STATE       ='ОСТАНОВЛЕН'
                SetCell(t_id, 2, 7, ROBOT_STATE)
                SetCell(t_id, 3, 0, "START")  --i строка, 0 - колонка, v - значение 
                SetColor(t_id, 3, 0, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
            end
        end
        if par1 == 3 and par2 == 2 then -- SELL
            ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
            CurrentDirect = 'SELL'
            setParameters()
            myLog('Сделка руками '..CurrentDirect)
            TakeProfitPrice = 0
        end
        if par1 == 3 and par2 == 3 then -- BUY
            ROBOT_STATE = 'В ПРОЦЕССЕ СДЕЛКИ'
            CurrentDirect = 'BUY'
            setParameters()
            myLog('Сделка руками '..CurrentDirect)
            TakeProfitPrice = 0
        end
        if par1 == 3 and par2 == 4 then -- ПЕРЕВОРОТ
            ROBOT_STATE = 'ПЕРЕВОРОТ'
            CurrentDirect = 'AUTO'
            setParameters()
            myLog('Сделка руками ПЕРЕВОРОТ '..CurrentDirect)
            TakeProfitPrice = 0
        end
        if par1 == 3 and par2 == 5 then -- All Close
            OpenCount = GetTotalnet()
            ROBOT_STATE = 'CLOSEALL'
        end        
        if par1 == 3 and par2 == 6 then -- Close SL
            myLog('Закрытие стоп-лосса')
            continue = KillAllStopOrders()
            TakeProfitPrice = 0
            if continue ~= true then
                Run = false
                message('Закрытие стопа позиции не удалось. Скрипт Algo остановлен')
                myLog('Закрытие стопа позиции не удалось. Скрипт Algo остановлен')
            end
        end
        if par1 == 3 and par2 == 7 then -- SET SL
            myLog('Установка стоп-лосса')
            if not isStopOrder() then
                setParameters()
                TakeProfitPrice = 0
                TransactionPrice = DS:C(DS:Size())
                if OpenCount > 0 then
                    myLog('Установка стоп-лосса, position '..tostring(OpenCount))
                    Result = SL_TP(DS:C(DS:Size()), "BUY", OpenCount)
                elseif OpenCount < 0 then
                    myLog('Установка стоп-лосса, position '..tostring(OpenCount))
                    Result = SL_TP(DS:C(DS:Size()), "SELL", OpenCount)
                end
            end
        end

        if par1 == 4 and par2 <= 5 and not isTrade and not optimizationInProgress then 
            curPreset = par2+1
            Settings = {}
            myLog('Set preset '..presets[curPreset].Name)    
            for k,v in pairs(presets[curPreset].settingsAlgo) do
                Settings[k] = v
                myLog(k..' '..tostring(v))    
            end
            setTableAlgoParams  = presets[curPreset].setTableAlgoParams     
            readTableAlgoParams = presets[curPreset].readTableAlgoParams     
            saveOptimizedParams = presets[curPreset].saveOptimizedParams     
            readOptimizedParams = presets[curPreset].readOptimizedParams     
            notReadOptimized    = presets[curPreset].notReadOptimized or false     

            NAME_OF_STRATEGY   = presets[curPreset].NAME_OF_STRATEGY
            SEC_CODE           = presets[curPreset].SEC_CODE                   
            CLASS_CODE         = presets[curPreset].CLASS_CODE                   
            INTERVAL           = presets[curPreset].INTERVAL                   
            maxStop            = presets[curPreset].maxStop
            reopenDealMaxStop  = presets[curPreset].reopenDealMaxStop
            reopenPosAfterStop = presets[curPreset].reopenPosAfterStop                   
            stopShiftIndexWait = presets[curPreset].stopShiftIndexWait                   
            ChartId            = presets[curPreset].ChartId
            testSizeBars       = presets[curPreset].testSizeBars
            
            -- Получает ШАГ ЦЕНЫ ИНСТРУМЕНТА
            if isConnected() then
                SEC_PRICE_STEP = getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value
                scale = getSecurityInfo(CLASS_CODE, SEC_CODE).scale
                STEPPRICE = getParamEx(CLASS_CODE, SEC_CODE, "STEPPRICE").param_value
                if tonumber(STEPPRICE) == 0 or STEPPRICE == nil then
                    leverage = 1
                else    
                    leverage = STEPPRICE/SEC_PRICE_STEP
                end
            end

            FILE_LOG_NAME = getScriptPath().."\\robot"..NAME_OF_STRATEGY.."_"..SEC_CODE.."Log.txt" -- ИМЯ ЛОГ-ФАЙЛА
            f:close() -- Закрывает файл 
            f = io.open(FILE_LOG_NAME, "w") -- открывает файл 
            PARAMS_FILE_NAME = getScriptPath().."\\robot"..NAME_OF_STRATEGY.."_"..SEC_CODE.."_int"..tostring(INTERVAL).."_params.csv" -- ИМЯ ЛОГ-ФАЙЛА
            
            myLog("NEW SET: "..tostring(presets[curPreset].Name))
            myLog("CLASS_CODE: "..tostring(CLASS_CODE))
            myLog("SEC: "..tostring(SEC_CODE))
            myLog("PRICE STEP: "..tostring(SEC_PRICE_STEP))
            myLog("SCALE: "..tostring(scale))
            myLog("STEP PRICE: "..tostring(STEPPRICE))
            myLog("leverage: "..tostring(leverage))
        
            if readOptimizedParams~=nil and not notReadOptimized then
                readOptimizedParams()
            end

            myLog("STOP_LOSS: "..tostring(Settings.STOP_LOSS))
            myLog("TAKE_PROFIT: "..tostring(Settings.TAKE_PROFIT))
            myLog("==================================================")
            myLog("Initialization finished")
                
            SetCell(t_id, 2, 6, tostring(INTERVAL), INTERVAL)  --i строка, 0 - колонка, v - значение 
            
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

            SetWindowCaption(t_id, NAME_OF_STRATEGY..' Robot '..SEC_CODE)

            if calculateAlgo==nil then
                calculateAlgo = simpleAlgo    
            end
        end

        if par1 == 4 and par2 == 6 then -- Optimize
            
            if optimizationInProgress then
                stopSignal = true
                return
            end
        
            setParameters()        
            
            ROBOT_STATE       = 'ОПТИМИЗАЦИЯ'
            if isTrade then
                isTrade = false
                SetCell(t_id, 2, 7, ROBOT_STATE)
                SetCell(t_id, 3, 0, "START")  --i строка, 0 - колонка, v - значение 
                SetColor(t_id, 3, 0, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
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

function OnFuturesClientHolding(fut_limit)
    
    if fut_limit.sec_code == SEC_CODE then
      
        if ROBOT_STATE == 'В ПОИСКЕ ТОЧКИ ВХОДА' or ROBOT_STATE == 'ОСТАНОВЛЕН' then
        
            -- Если изменился баланс текущей позиции
            if fut_limit.totalnet ~= OpenCount then 
                
                OpenCount = GetTotalnet()
                SetCell(t_id, 2, 2, tostring(fut_limit.avrposnprice), fut_limit.avrposnprice)
                 
                if not isStopOrder() then
                    TakeProfitPrice = 0
                    TransactionPrice = DS:C(DS:Size())
                    if OpenCount > 0 then
                        myLog('Установка стоп-лосса OnFuturesClientHolding, position '..tostring(OpenCount))
                        Result = SL_TP(DS:C(DS:Size()), "BUY", OpenCount)
                    elseif OpenCount < 0 then
                        myLog('Установка стоп-лосса OnFuturesClientHolding, position '..tostring(OpenCount))
                        Result = SL_TP(DS:C(DS:Size()), "SELL", OpenCount)
                    end
                else
                    myLog('Закрытие стоп-лосса OnFuturesClientHolding')
                    continue = KillAllStopOrders()
                    TakeProfitPrice = 0
                    TransactionPrice = DS:C(DS:Size())
                    if continue ~= true then
                        Run = false
                        message('Закрытие стопа позиции не удалось. Скрипт Algo остановлен')
                        myLog('Закрытие стопа позиции не удалось. Скрипт Algo остановлен')
                    end  
                    if OpenCount > 0 then
                        myLog('Установка стоп-лосса OnFuturesClientHolding, position '..tostring(OpenCount))
                        Result = SL_TP(DS:C(DS:Size()), "BUY", OpenCount)
                    elseif OpenCount < 0 then
                        myLog('Установка стоп-лосса OnFuturesClientHolding, position '..tostring(OpenCount))
                        Result = SL_TP(DS:C(DS:Size()), "SELL", OpenCount)
                    end
                end
            end
        end
    end

end

-- Функция вызывается терминалом QUIK при получении ответа на транзакцию пользователя
function OnTransReply(trans_reply)
   -- Если поступила информация по текущей транзакции
   if trans_reply.trans_id == trans_id then
      -- Передает статус в глобальную переменную
      trans_Status = trans_reply.status
      -- Передает сообщение в глобальную переменную
      trans_result_msg  = trans_reply.result_msg
	  myLog("OnTransReply: "..trans_result_msg)
    end
end

-- создан/изменен/сработал стоп-ордер 
function OnStopOrder(stopOrder)
   -- Если не относится к роботу, выходит из функции
   if stopOrder.brokerref:find(CLIENT_CODE) == nil then return end

   local string state="_" -- состояние заявки
   --бит 0 (0x1) Заявка активна, иначе не активна
   if bit.band(stopOrder.flags,0x1)==0x1 then
      state="стоп-заявка создана"
      g_stopOrder_num = stopOrder.order_num 
    end
   if bit.band(stopOrder.flags,0x2)==0x1 or stopOrder.flags==26 then
      state="стоп-заявка снята"
   end
   if bit.band(stopOrder.flags,0x2)==0x0 and bit.band(stopOrder.flags,0x1)==0x0 then
      state="стоп-ордер исполнен"
      slIndex = DS:Size()
      stopPrice = stop_order.price
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
   
   myLog("OnStopOrder(): sec_code="..stopOrder.sec_code.." - "..state..
         "; condition_price="..stopOrder.condition_price.."; transID="..stopOrder.trans_id.."; order_num="..stopOrder.order_num) 

    local condition_price = stopOrder.condition_price
    local condition_price2 = stopOrder.condition_price2

    if state=="стоп-ордер исполнен" then
        condition_price2 = 0
        condition_price = 0
    end
    SetCell(t_id, 2, 3, tostring(condition_price2), condition_price2) --sl
    SetCell(t_id, 2, 4, tostring(condition_price), condition_price) --tp
    
    tpPrice = condition_price
    slPrice = condition_price2
    oldStop = slPrice
end

-- Функция ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK при остановке скрипта
function OnStop()
    Run = false
    myLog("Script Stoped") 
    f:close() -- Закрывает файл 
    if t_id~= nil then
        DestroyTable(t_id)
    end
    if tv_id~= nil then
        DestroyTable(tv_id)
    end
end

-----------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ --
-----------------------------

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
    stopPrice = 0
    slPrice = 0
    oldStop = 0
    tpPrice = 0
    lastStopShiftIndex = 0

    if virtualTrade then
        
        local openLong = nil
        local closeLong = nil
        local openShort = nil
        local closeShort = nil
                
        myLog("OpenCount before "..tostring(OpenCount))
        myLog("lastDealPrice "..tostring(vlastDealPrice))
        
        
        local dealPrice = DS:C(DS:Size())
        if Type == 'BUY' then
            dealPrice = round(tonumber(getParamEx(CLASS_CODE, SEC_CODE, 'offer').param_value), scale)
        else
            dealPrice = round(tonumber(getParamEx(CLASS_CODE, SEC_CODE, 'bid').param_value), scale)
        end
         
        if Type == 'BUY' then
            if OpenCount < 0 then
                vdealProfit = round(vlastDealPrice - dealPrice, 5)*qnt*leverage
            elseif OpenCount > 0 then
                vlastDealPrice = (vlastDealPrice + dealPrice)/2
            end
            if isLong and OpenCount == 0 then
                openLong = dealPrice
            else    
                closeShort = dealPrice
            end
            OpenCount = OpenCount + qnt        
        else
            if OpenCount > 0 then
                vdealProfit = round(dealPrice-vlastDealPrice, 5)*qnt*leverage
            elseif OpenCount > 0 then
                vlastDealPrice = (vlastDealPrice + dealPrice)/2
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
        
        myLog("dealProfit "..tostring(vdealProfit))
        myLog("OpenCount after "..tostring(OpenCount))
        
        vlastDealPrice = dealPrice
        if OpenCount == 0 then
            vlastDealPrice = 0
        end
        SetCell(t_id, 2, 2, tostring(vlastDealPrice), vlastDealPrice) 

        vdealProfit = 0

        addDeal(DS:Size(), openLong, openShort, closeLong, closeShort, DS:T(DS:Size()))
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
    -- Отправляет транзакцию
    local res = sendTransaction(Transaction)
    if string.len(res) ~= 0 then
       message(NAME_OF_STRATEGY..' robot: Транзакция вернула ошибку: '..res)
       myLog(NAME_OF_STRATEGY..' robot: Транзакция вернула ошибку: '..res)
       return false
    end 
    -- Ждет, пока получит статус текущей транзакции (переменные "trans_Status" и "trans_result_msg" заполняются в функции OnTransReply())
    while Run and (trans_Status == nil or trans_Status < 2) do sleep(1) end
    -- Запоминает значение
    local Status = trans_Status

    -- Очищает глобальную переменную
    trans_Status = nil

    -- Если транзакция не выполнена по какой-то причине
    if Status == 2 then
         message("Ошибка при передаче транзакции в торговую систему. Так как отсутствует подключение шлюза Московской Биржи, повторно транзакция не отправляется. Скрипт остановлен.")
         myLog("Ошибка при передаче транзакции в торговую систему. Так как отсутствует подключение шлюза Московской Биржи, повторно транзакция не отправляется. Скрипт остановлен.")
         Run = false
         return -1
    end 

    if Status ~= 3 then
       -- Если данный инструмент запрещен для операции шорт
       if Status == 6 then
          -- Выводит сообщение
    	 myLog(NAME_OF_STRATEGY..' robot: Данный инструмент запрещен для операции шорт! Транзакция не прошла проверку лимитов сервера QUIK.')
         isShort = false
       else
          -- Выводит сообщение с ошибкой
          if Status == 4 then messageText = "Транзакция не исполнена" end
          if Status == 5 then messageText = "Транзакция не прошла проверку сервера QUIK" end
          if Status == 6 then messageText = "Транзакция не прошла проверку лимитов сервера QUIK" end
          if Status == 7 then messageText = "Транзакция не поддерживается торговой системой" end
          message(NAME_OF_STRATEGY..' robot: Транзакция вернула ошибку: '..messageText)
          myLog(NAME_OF_STRATEGY..' robot: Транзакция вернула ошибку: '..messageText)
        end
       -- Возвращает FALSE
       return -1
    elseif Status == 3 then --Транзакция отправлена
       local OrderNum = nil
       --ЖДЕТ пока ЗАЯВКА на ОТКРЫТИЕ сделки будет ИСПОЛНЕНА полностью
       --Запоминает время начала в секундах
       local BeginTime = os.time()
       while Run and OrderNum == nil do
          --Перебирает ТАБЛИЦУ ЗАЯВОК
          for i=0,getNumberOf('orders')-1 do
             local order = getItem('orders', i)
             --Если заявка по отправленной транзакции ИСПОЛНЕНА ПОЛНОСТЬЮ
             if order.trans_id == trans_id and order.balance == 0 then
                --Запоминает номер заявки
                OrderNum  = order.order_num
                --Прерывает цикл FOR
                break
             end
          end
          --Если прошло 10 секунд, а заявка не исполнена, значит произошла ошибка
          if os.time() - BeginTime > 20 then
             -- Выводит сообщение с ошибкой
             message(NAME_OF_STRATEGY..' robot: Прошло 20 секунд, а заявка не исполнена, значит произошла ошибка')
    		myLog(NAME_OF_STRATEGY..' robot: Прошло 20 секунд, а заявка не исполнена, значит произошла ошибка')
            -- Возвращает FALSE
             return false
          end
          sleep(10) -- Пауза 10 мс, чтобы не перегружать процессор компьютера
       end  
       --ЖДЕТ пока СДЕЛКА ОТКРЫТИЯ позиции будет СОВЕРШЕНА
       --Запоминает время начала в секундах
       BeginTime = os.time()
       while Run do
          --Перебирает ТАБЛИЦУ СДЕЛОК
          for i=0,getNumberOf('trades')-1 do
             local trade = getItem('trades', i)
             --Если сделка по текущей заявке
             if trade.order_num == OrderNum then
                --Возвращает фАКТИЧЕСКУЮ ЦЕНУ открытой сделки
                SetCell(t_id, 2, 2, tostring(trade.price), trade.price) 
                return trade.price
             end
          end
          --Если прошло 10 секунд, а сделка не совершена, значит на счете произошла ошибка
          if os.time() - BeginTime > 9 then
             -- Выводит сообщение с ошибкой
             message(NAME_OF_STRATEGY..' robot: Прошло 10 секунд, а сделка не совершена, значит на счете произошла ошибка')
    		myLog(NAME_OF_STRATEGY..' robot: Прошло 10 секунд, а сделка не совершена, значит на счете произошла ошибка')
             -- Возвращает FALSE
             return -1
          end
          sleep(10) -- Пауза 10 мс, чтобы не перегружать процессор компьютера
       end
    end
    
    return -1

 end

-- Выставляет СТОП-ЛОСС и ТЕЙК-ПРОФИТ, принимает ЦЕНУ (Price) и ТИП (Type) ["BUY", или "SELL"] открытой сделки,
--- возвращает FALSE, если не удалось выставить СТОП-ЛОСС и ТЕЙК-ПРОФИТ
function SL_TP(AtPrice, Type, qnt)

    if isConnected() == false then
        return false
    end

    -- ID транзакции
    trans_id = trans_id + 1

    lastDealPrice = GetCell(t_id, 2, 2).value
    lastStopShiftIndex = DS:Size()

	-- Находит направление для заявки
	local operation = ""
	local price = "0" -- Цена, по которой выставится заявка при срабатывании Стоп-Лосса (для рыночной заявки по акциям должна быть 0)
	local stopprice = "" -- Цена Тейк-Профита
	local stopprice2 = "" -- Цена Стоп-Лосса
	local market = "YES" -- После срабатывания Тейка, или Стопа, заявка сработает по рыночной цене
	local direction
 
    local EXPIRY_DATE = os.date("%Y%m%d", os.time() + 29*60*60*24) --"TODAY", "GTC"

    if qnt < 0 then qnt = -qnt end
	--myLog('TakeProfitPrice '..tostring(TakeProfitPrice)..', TAKE_PROFIT: '..tostring(TAKE_PROFIT)..' STOP_LOSS: '..tostring(STOP_LOSS))
	--myLog('DS:Size() '..tostring(DS:Size())..' calcAlgoValue[DS:Size()-1] '..tostring(calcAlgoValue[DS:Size()-1])..', ATR[DS:Size()-1]: '..tostring(ATR[DS:Size()-1])..' ATRfactor: '..tostring(ATRfactor))
    
    --if isTrade then calculateAlgo(DS:Size(), Settings) end
	--myLog('oldStop '..tostring(slPrice)..', STOP_LOSS: '..tostring(STOP_LOSS)..', oldTakeProfitPrice: '..tostring(TakeProfitPrice)..', isPriceMove: '..tostring(isPriceMove))

 -- Если открыт BUY, то направление стоп-лосса и тейк-профита SELL, иначе направление стоп-лосса и тейк-профита BUY
	if Type == 'BUY' then
		operation = "S" -- Тейк-профит и Стоп-лосс на продажу(чтобы закрыть BUY, нужно открыть SELL)
        direction = "5" -- Направленность стоп-цены. «5» - больше или равно
      -- Если не акции
        if CLASS_CODE ~= 'QJSIM' and CLASS_CODE ~= 'TQBR' then
            price = math.floor(getParamEx(CLASS_CODE, SEC_CODE, 'PRICEMIN').param_value + 200*SEC_PRICE_STEP) -- Цена выставляемой заявки после страбатывания Стопа минимально возможная, чтобы не проскользнуло
            market = "YES"  -- После срабатывания Тейка, или Стопа, заявка сработает НЕ по рыночной цене
        end
        if TakeProfitPrice == 0 then
            stopprice	= round(AtPrice + TAKE_PROFIT/leverage, scale) -- Уровень цены, когда активируется Тейк-профит
        elseif isPriceMove then
            isPriceMove = false
            stopprice = round(TakeProfitPrice + STOP_LOSS/leverage/2, scale)    -- немного сдвигаем тейк-профит
        else stopprice = TakeProfitPrice
        end
        if isTrade then
            local slPrice = calcAlgoValue[DS:Size()-1]
            local shiftSL = (kATR*ATR[DS:Size()-1] + 40*SEC_PRICE_STEP)
            if (slPrice - shiftSL) >= AtPrice then
                slPrice = AtPrice
            end
            local nonLosePrice = round(lastDealPrice + 0*SEC_PRICE_STEP, scale)
            if (lastDealPrice + math.floor(STOP_LOSS/leverage)) <= AtPrice then
                stopprice2	= math.max(round(slPrice - shiftSL, scale), nonLosePrice) -- Уровень цены, когда активируется Стоп-лосс
            else
                stopprice2	= round(slPrice - shiftSL, scale) -- Уровень цены, когда активируется Стоп-лосс
            end
            if reopenAfterStop then dealMaxStop = reopenDealMaxStop else dealMaxStop = maxStop end
            if (lastDealPrice - stopprice2) > dealMaxStop/leverage then stopprice2 = lastDealPrice - dealMaxStop/leverage end
            reopenAfterStop = false
        else
            stopprice2	= round(AtPrice - STOP_LOSS/leverage, scale) -- Уровень цены, когда активируется Стоп-лосс
        end
        --myLog('oldStop '..tostring(oldStop)..', stopprice2: '..tostring(stopprice2))
        if oldStop~=0 then stopprice2 = math.max(oldStop, stopprice2) end
		--price = stopprice2 - 2*SEC_PRICE_STEP 
	else -- открыт SELL
		operation = "B" -- Тейк-профит и Стоп-лосс на покупку(чтобы закрыть SELL, нужно открыть BUY)
		direction = "4" -- Направленность стоп-цены. «4» - меньше или равно
      -- Если не акции
	    if CLASS_CODE ~= 'QJSIM' and CLASS_CODE ~= 'TQBR' then
            price = math.floor(getParamEx(CLASS_CODE, SEC_CODE, 'PRICEMAX').param_value - 200*SEC_PRICE_STEP) -- Цена выставляемой заявки после страбатывания Стопа максимально возможная, чтобы не проскользнуло
            market = "YES"  -- После срабатывания Тейка, или Стопа, заявка сработает НЕ по рыночной цене
        end
        if TakeProfitPrice == 0 then
            stopprice	= round(AtPrice - TAKE_PROFIT/leverage, scale) -- Уровень цены, когда активируется Тейк-профит
        elseif isPriceMove then
            isPriceMove = false
            stopprice = round(TakeProfitPrice - STOP_LOSS/leverage/2, scale)  -- немного сдвигаем тейк-профит   
        else stopprice = TakeProfitPrice
        end
        if isTrade then
            local slPrice = calcAlgoValue[DS:Size()-1]
            local shiftSL = (kATR*ATR[DS:Size()-1] + 40*SEC_PRICE_STEP)
            if (slPrice + shiftSL) <= AtPrice then
                slPrice = AtPrice
            end
            local nonLosePrice = round(lastDealPrice - 0*SEC_PRICE_STEP, scale)
            if (lastDealPrice - math.floor(STOP_LOSS/leverage)) >= AtPrice then
                stopprice2	= math.min(round(slPrice + shiftSL, scale), nonLosePrice) -- Уровень цены, когда активируется Стоп-лосс
            else
                stopprice2	= round(slPrice + shiftSL, scale) -- Уровень цены, когда активируется Стоп-лосс
            end
            if reopenAfterStop then dealMaxStop = reopenDealMaxStop else dealMaxStop = maxStop end
            if (stopprice2 - lastDealPrice) > dealMaxStop/leverage then stopprice2 = lastDealPrice + dealMaxStop/leverage end
            reopenAfterStop = false
        else
            stopprice2	= round(AtPrice + STOP_LOSS/leverage, scale) -- Уровень цены, когда активируется Стоп-лосс
        end
        --price = stopprice2 + 2*SEC_PRICE_STEP 
        --myLog('oldStop '..tostring(oldStop)..', stopprice2: '..tostring(stopprice2))
        if oldStop~=0 then stopprice2 = math.min(oldStop, stopprice2) end
	end
	-- Заполняет структуру для отправки транзакции на Стоп-лосс и Тейк-профит
   
    TakeProfitPrice = stopprice
    
    sl_Price = GetCorrectPrice(stopprice2)
    tp_Price = GetCorrectPrice(stopprice)
    --myLog('Установка ТЕЙК-ПРОФИТ: '..stopprice..' и СТОП-ЛОСС: '..stopprice2)
    
    tpPrice = string.gsub(tp_Price,'[\,]+', '.')
    slPrice = string.gsub(sl_Price,'[\,]+', '.')
    tpPrice = tonumber(tpPrice)
    slPrice = tonumber(slPrice)
    
    oldStop = slPrice
    
    myLog(NAME_OF_STRATEGY..' robot: '..' index '..tostring(DS:Size())..' AlgoVal '..tostring(calcAlgoValue[DS:Size()-1])..', ATR: '..tostring(ATR[DS:Size()-1]))
    myLog(NAME_OF_STRATEGY..' robot: сделка '..Type..' по цене '..tostring(AtPrice)..', Установка ТЕЙК-ПРОФИТ: '..tp_Price..' и СТОП-ЛОСС: '..sl_Price)

    SetCell(t_id, 2, 3, sl_Price, slPrice) 
    SetCell(t_id, 2, 4, tp_Price, tpPrice)
   
    if virtualTrade then
        return true
    end

	local Transaction = {
		["ACTION"]              = "NEW_STOP_ORDER", -- Тип заявки
		["TRANS_ID"]            = tostring(trans_id),
		["CLASSCODE"]           = CLASS_CODE,
		["SECCODE"]             = SEC_CODE,
		["ACCOUNT"]             = ACCOUNT,
        ['CLIENT_CODE'] = CLIENT_CODE, -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках 
		["OPERATION"]           = operation, -- Операция ("B" - покупка(BUY), "S" - продажа(SELL))
		["QUANTITY"]            = tostring(qnt), -- Количество в лотах
		["PRICE"]               = GetCorrectPrice(price), -- Цена, по которой выставится заявка при срабатывании Стоп-Лосса (для рыночной заявки по акциям должна быть 0)
		["STOPPRICE"]           = tp_Price, -- Цена Тейк-Профита
		["STOP_ORDER_KIND"]     = "TAKE_PROFIT_AND_STOP_LIMIT_ORDER", -- Тип стоп-заявки
		["EXPIRY_DATE"]         = EXPIRY_DATE, -- Срок действия стоп-заявки ("GTC" – до отмены,"TODAY" - до окончания текущей торговой сессии, Дата в формате "ГГММДД")
      -- "OFFSET" - (ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль,
      -- то Тейк-профит сработает только когда цена вернется минимум на 2 шага цены назад,
      -- это может потенциально увеличить прибыль
		["OFFSET"]              = tostring(2*SEC_PRICE_STEP),
		["OFFSET_UNITS"]        = "PRICE_UNITS", -- Единицы измерения отступа ("PRICE_UNITS" - шаг цены, или "PERCENTS" - проценты)
      -- "SPREAD" - Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на 100 шагов цены,
      -- которая АВТОМАТИЧЕСКИ УДОВЛЕТВОРИТСЯ ПО ТЕКУЩЕЙ ЛУЧШЕЙ ЦЕНЕ,
      -- но то, что цена значительно хуже, спасет от проскальзывания,
      -- иначе, сделка может просто не закрыться (заявка на закрытие будет выставлена, но цена к тому времени ее уже проскочит)
		["SPREAD"]              = tostring(10*SEC_PRICE_STEP),
		["SPREAD_UNITS"]        = "PRICE_UNITS", -- Единицы измерения защитного спрэда ("PRICE_UNITS" - шаг цены, или "PERCENTS" - проценты)
      -- "MARKET_TAKE_PROFIT" = ("YES", или "NO") должна ли выставится заявка по рыночной цене при срабатывании Тейк-Профита.
      -- Для рынка FORTS рыночные заявки, как правило, запрещены,
      -- для лимитированной заявки на FORTS нужно указывать заведомо худшую цену, чтобы она сработала сразу же, как рыночная
		["MARKET_TAKE_PROFIT"]  = market,
		["STOPPRICE2"]          = sl_Price, -- Цена Стоп-Лосса
		["IS_ACTIVE_IN_TIME"]   = "NO",
      -- "MARKET_TAKE_PROFIT" = ("YES", или "NO") должна ли выставится заявка по рыночной цене при срабатывании Стоп-Лосса.
      -- Для рынка FORTS рыночные заявки, как правило, запрещены,
      -- для лимитированной заявки на FORTS нужно указывать заведомо худшую цену, чтобы она сработала сразу же, как рыночная
		["MARKET_STOP_LIMIT"]   = market,
        ['CONDITION'] = direction, -- Направленность стоп-цены. Возможные значения: «4» - меньше или равно, «5» – больше или равно
 		["COMMENT"]             = NAME_OF_STRATEGY..' robot ТЕЙК-ПРОФИТ и СТОП-ЛОСС'
	}
   -- Отправляет транзакцию на установку ТЕЙК-ПРОФИТ и СТОП-ЛОСС
   local res = sendTransaction(Transaction)
   if string.len(res) ~= 0 then
      message(NAME_OF_STRATEGY..' robot: Установка ТЕЙК-ПРОФИТ и СТОП-ЛОСС не удалась!\nОШИБКА: '..trans_result_msg)
	  myLog(NAME_OF_STRATEGY..' robot: Установка ТЕЙК-ПРОФИТ и СТОП-ЛОСС не удалась!\nОШИБКА: '..trans_result_msg)
      trans_Status = nil
	  return false
   else
      -- Выводит сообщение
	 trans_Status = nil
	 myLog(NAME_OF_STRATEGY..' robot: ВЫСТАВЛЕНА заявка ТЕЙК-ПРОФИТ и СТОП-ЛОСС: '..trans_id)
     return true
   end
   
end

-- ПРИНУДИТЕЛЬНО ЗАКРЫВАЕТ ОТКРЫТУЮ ПОЗИЦИЮ переданного типа (Type) ["BUY", или "SELL"]
function KillPos(Type, qnt)
   -- Дается 10 попыток
   local Count = 0 -- Счетчик попыток
   local result = false
   if Type == 'BUY' then
      -- Пока скрипт не остановлен и позиция не закрыта
      result = Trade('SELL', qnt)
   else
      -- Пока скрипт не остановлен и позиция не закрыта
      result = Trade('BUY', qnt)
   end
   if result == false or result == -1 then
        sleep(200)
        -- Проверим размер позиции. Возможно сработал стоп.
        OpenCount = GetTotalnet()
        if OpenCount == 0 then
            result = true
        end
    else
        result = true
    end
    
    SetCell(t_id, 2, 2, '', 0) 
    -- Возвращает TRUE, если удалось принудительно закрыть позицию
    return result
end

function Kill_SO()
   -- Находит стоп-заявку (30 сек. макс.)
   local index = 0
   local start_sec = os.time()
   local find_so = false
   local stop_order_num = 0
   
   myLog(NAME_OF_STRATEGY..' robot kill SL '..g_stopOrder_num)
   while Run and not find_so and os.time() - start_sec < 30 do
      for i=getNumberOf('stop_orders')-1,0,-1 do
        local stop_order=getItem("stop_orders", i)
        if stop_order ~= nil and type(stop_order) == "table" then
           if stop_order.sec_code == SEC_CODE and stop_order.order_num == g_stopOrder_num then
				myLog('Найдена стоп-заявка: '..stop_order.seccode..' number: '..tostring(stop_order.order_num))
				-- Если стоп-заявка уже была исполнена (не активна)
				if not bit.test(stop_order.flags, 0) then
				  myLog('Снятие стоп-заявки: '..tostring(stop_order.order_num)..' стоп-заявка уже сработала')
				  return false
				end
				index = i
				find_so = true
				stop_order_num = stop_order.order_num
				break
			end
 		end
     end
   end
   
   if not find_so then
	  myLog('Ошибка: не найдена стоп-заявка!')
      return true
   end
     
   -- Получает ID для следующей транзакции
   trans_id = trans_id + 1
   -- Заполняет структуру для отправки транзакции на снятие стоп-заявки
	local Transaction = {
		["ACTION"]              = "KILL_STOP_ORDER", -- Тип заявки
		["TRANS_ID"]            = tostring(trans_id),
		["CLASSCODE"]           = CLASS_CODE,
		["SECCODE"]             = SEC_CODE,
		["ACCOUNT"]             = ACCOUNT,
        ['CLIENT_CODE'] = CLIENT_CODE, -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках 
		['STOP_ORDER_KEY']      = tostring(stop_order_num) -- Номер стоп-заявки, снимаемой из торговой системы
	}
 
   -- Отправляет транзакцию
   local Res = sendTransaction(Transaction)
   -- Если при отправке транзакции возникла ошибка
   if string.len(Res) ~= 0 then
      -- Выводит ошибку
      message('Ошибка снятия стоп-заявки: '..Res)
	  myLog('Ошибка снятия стоп-заявки: '..Res)
      return false
   end   
 
   -- Ожидает когда стоп-заявка перестанет быть активна (30 сек. макс.)
   start_sec = os.time()
   local active = true
   while Run and os.time() - start_sec < 30 do
      local stop_order = getItem('stop_orders', index)
      -- Если стоп-заявка не активна
 	  myLog('прверка стоп-заявки: '..stop_order.sec_code..' number: '..tostring(stop_order.order_num))
      if not bit.test(stop_order.flags, 0) then
         -- Если стоп-заявка успела исполниться
         if not bit.test(stop_order.flags, 1) then
            return true
         end
         active = false
         break
      end
      sleep(10)
   end
   if active then
      message('Возникла неизвестная ошибка при снятии СТОП-ЗАЯВКИ')
	  myLog('Возникла неизвестная ошибка при снятии СТОП-ЗАЯВКИ')
      return false
   end
 
    slIndex = 0
    stopPrice = 0
    slPrice = 0
    oldStop = 0
    tpPrice = 0
    lastStopShiftIndex = 0
    SetCell(t_id, 2, 3, '', 0) 
    SetCell(t_id, 2, 4, '', 0) 
    return true
end

function isStopOrder()
    
    function myFind(C,S,F)
        return (C == CLASS_CODE) and (S == SEC_CODE) and (bit.band(F, 0x1) ~= 0)
    end
    local res=1
    local ord = "stop_orders"
    local orders = SearchItems(ord, 0, getNumberOf(ord)-1, myFind, "class_code,sec_code,flags")
    if (orders ~= nil) and (#orders > 0) then
        return true
    end
    return false
end

function KillAllStopOrders()
   function myFind(C,S,F)
      return (C == CLASS_CODE) and (S == SEC_CODE) and (bit.band(F, 0x1) ~= 0)
   end
   local res=1
   local ord = "stop_orders"
   local orders = SearchItems(ord, 0, getNumberOf(ord)-1, myFind, "class_code,sec_code,flags")
   if (orders ~= nil) and (#orders > 0) then
      for i=1,#orders do
		-- Получает ID для следующей транзакции
	   trans_id = trans_id + 1
	   -- Заполняет структуру для отправки транзакции на снятие стоп-заявки
		local Transaction = {
			["ACTION"]              = "KILL_STOP_ORDER", -- Тип заявки
			["TRANS_ID"]            = tostring(trans_id),
			["CLASSCODE"]           = CLASS_CODE,
			["SECCODE"]             = SEC_CODE,
			["ACCOUNT"]             = ACCOUNT,
			['CLIENT_CODE'] = CLIENT_CODE, -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках 
			['STOP_ORDER_KEY']      = tostring(getItem(ord,orders[i]).order_num) -- Номер стоп-заявки, снимаемой из торговой системы
		}
		   -- Отправляет транзакцию
		   local Res = sendTransaction(Transaction)
		   -- Если при отправке транзакции возникла ошибка
		   if string.len(Res) ~= 0 then
			  -- Выводит ошибку
			  message('Ошибка снятия стоп-заявки: '..Res)
			  myLog('Ошибка снятия стоп-заявки: '..Res)
			  return false
		   end   
		  
		  local stop_order = getItem('stop_orders', orders[i])		  
		  -- Если стоп-заявка не активна
		  myLog('прверка стоп-заявки: '..stop_order.sec_code..' number: '..tostring(stop_order.order_num))
		  if not bit.test(stop_order.flags, 0) then
			 -- Если стоп-заявка успела исполниться
			 if not bit.test(stop_order.flags, 1) then
				return true
			 else
				message('Возникла неизвестная ошибка при снятии СТОП-ЗАЯВКИ')
				myLog('Возникла неизвестная ошибка при снятии СТОП-ЗАЯВКИ')
				return false
			 end
		  end
       end
    end
      
    SetCell(t_id, 2, 3, '', 0) 
    SetCell(t_id, 2, 4, '', 0) 
    slIndex = 0
    slPrice = 0
    oldStop = 0
    lastStopShiftIndex = 0
    tpPrice = 0
    stopPrice= 0
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
    SetCell(t_id, 6, 6, tostring(settingsAlgo.STOP_LOSS), settingsAlgo.STOP_LOSS)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 6, 7, tostring(settingsAlgo.TAKE_PROFIT))  --i строка, 0 - колонка, v - значение 

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
        myLog("Файл параметров "..PARAMS_FILE_NAME.." не найден")
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

    --if ROBOT_STATE == 'РЕОПТИМИЗАЦИЯ' then
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
    indexToCalc = Fsettings.indexToCalc or indexToCalc
    local beginIndexToCalc = Fsettings.beginIndexToCalc or math.max(1, DS:Size() - indexToCalc)

    if index == beginIndexToCalc then
        --if ROBOT_STATE ~= 'РЕОПТИМИЗАЦИЯ' then
        --    myLog("--------------------------------------------------")
        --    myLog("Показатель shift "..tostring(shift))
        --    myLog("--------------------------------------------------")
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
    
    --myLog("algoLine "..tostring(calcAlgoValue[index])..", algoLine-shift "..tostring(calcAlgoValue[index-shift]))
    
    if not optimizationInProgress then
        local roundAlgoVal = round(calcAlgoValue[index], scale)
        SetCell(t_id, 2, 1, tostring(roundAlgoVal), roundAlgoVal) 
    end

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
        sleep(2)

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
        if settingsTask.STOP_LOSS == nil and STOP_LOSS ~= 0 then
            settingsTask.STOP_LOSS = presets[curPreset].STOP_LOSS
        end
        if settingsTask.TAKE_PROFIT == nil and TAKE_PROFIT ~= 0 then
            settingsTask.TAKE_PROFIT = presets[curPreset].TAKE_PROFIT
        end
 
        optimizeAlgorithm()
        local profitRatio, avg, sigma, maxDrawDown, sharpe, AHPR, ZCount = calculateSigma(deals)
            
        --myLog("--------------------------------------------------")
        --myLog("Прибыль по лонгам "..tostring(longProfit))
        --myLog("Прибыль по шортам "..tostring(shortProfit))
        --myLog("Прибыль всего "..tostring(allProfit))
        --myLog("================================================")

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
            --myLog('time '..tostring(time)..' time1 '..tostring(time1))
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
    --myLog('beginIndex '..tostring(beginIndex)..' day '..tostring(DS:T(beginIndex).day)..' hour '..tostring(DS:T(beginIndex).hour)..' min '..tostring(DS:T(beginIndex).min))
    --myLog('bars '..tostring(bars))

    resultsTable = iterateTable(settingsTable, resultsTable)

    if #resultsTable > 1 then
        --ArraySortByColl(resultsTable, 3)
        table.sort(resultsTable, function(a,b) return a[1]<b[1] end)
    end

    if #resultsTable > 0 and iterateSLTP then
        if STOP_LOSS~=0 or TAKE_PROFIT~=0 then

            myLog("----------------------------------------------------------")
            myLog("list before iterate SL/TP")
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
    
        myLog("----------------------------------------------------------")
        local firstString = "INTERVAL; testSizeBars; allProfit; maxDown; lastDealSignal; trend"
 
        for k,v in pairs(bestSettings) do
            if type(v) == 'table' then
                for kkk,vvv in pairs(v) do
                    firstString = firstString..'; '..kkk
                    --myLog("col "..tostring(kkk)..", val "..tostring(keyValueSettingT))
                end
            else
                firstString = firstString..'; '..k
            end
        end
 
        myLog(firstString)
        myLog("best")        
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
                myLog("new best line "..tostring(line))
                paramsString = tostring(INTERVAL).."; "..tostring(testSizeBars)
                for j=1,4 do
                    paramsString = paramsString.."; "..tostring(resultString[j])
                end
                for k,v in pairs(bestSettings) do
                    if type(v) == 'table' then
                        for kkk,vvv in pairs(v) do
                            paramsString = paramsString..'; '..tostring(vvv)
                            --myLog("col "..tostring(kkk)..", val "..tostring(keyValueSettingT))
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
                myLog("new best line "..tostring(line))
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

        myLog("----------------------------------------------------------")
        myLog("list")
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
    myLog("Нет положительных результатов оптимизации")
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
                --myLog('**** SL '..tostring(settingsTable[allCount].SLSec)..' TP '..tostring(settingsTable[allCount].TPSec))
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

    --myLog("--------------------------------------------------")
    --myLog("equity "..tostring(equity))

    for i,index in pairs(deals["index"]) do                           
        if deals["dealProfit"][i] ~= nil then
            dealsCount = dealsCount + 1
            avg = avg + deals["dealProfit"][i]
            dispDeals[i] = deals["dealProfit"][i]           
            
            local oldEquity = equity
            equity = equity + deals["dealProfit"][i]
            --myLog("index "..tostring(index).." equity "..tostring(equity))
            
            if oldEquity > 0 and equity < 0 then
                HPRDeals[i] = 0
            elseif oldEquity < 0 and equity > 0 then    
                HPRDeals[i] = 1000
            else    
                HPRDeals[i] = equity/oldEquity
            end
            --myLog("HPRDeals[i] "..tostring(HPRDeals[i]))
            avgHPR = avgHPR + HPRDeals[i]

            maxEquity = math.max(maxEquity, equity)
            --myLog("maxEquity "..tostring(maxEquity))
            if equity < maxEquity then
                maxDelta = math.max(maxEquity - equity, maxDelta)
                maxDrawDown = math.max(round(maxDelta*100/maxEquity, 2), maxDrawDown)
                --myLog("maxDrawDown "..tostring(maxDrawDown))
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
    --myLog("avgHPR "..tostring(avgHPR))

    for i,_ in pairs(dispDeals) do                           
        sigma = sigma + math.pow(dispDeals[i] - avg, 2)
        sigmaHPR = sigmaHPR + math.pow(HPRDeals[i] - avgHPR, 2)
        --myLog("HPR_Avg "..tostring(math.pow(HPRDeals[i] - avgHPR, 2)))
    end
    --myLog("DispHPR "..tostring(sigmaHPR))

    if dealsCount > 1 then
        sigma = round(math.sqrt(sigma/(dealsCount-1)), 2)
        sigmaHPR = round(math.sqrt(sigmaHPR/(dealsCount-1)), 5)
        --myLog("sigmaHPR "..tostring(sigmaHPR))
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
        initalAssets = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "BUYDEPO").param_value) --*leverage
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
    if dealTime and slIndex ~= 0 and (index - slIndex) == 7 then
        local currentTradeDirection = getTradeDirection(index, calcAlgoValue, calcTrend)
        if currentTradeDirection == 1 and deals["closeLong"][dealsCount]~=nil then
            if deals["closeLong"][dealsCount]<DS:O(index) then
                lastTradeDirection = currentTradeDirection
            end
        end
        if currentTradeDirection == -1 and deals["closeShort"][dealsCount]~=nil then
            if deals["closeShort"][dealsCount]>DS:O(index) then
                lastTradeDirection = currentTradeDirection
            end
        end    
    end

    local closeDeal = false
    if calcTrend ~= nil then
        closeDeal = calcTrend[index-1] == 0
    end

    if (not dealTime or closeDeal) and lastDealPrice ~= 0 and (deals["openShort"][dealsCount] ~= nil or deals["openLong"][dealsCount] ~= nil) then
        
        if initalAssets == 0 then
            initalAssets = DS:O(index) --*leverage
            equitySum = initalAssets
        end
        
        if deals["openShort"][dealsCount] ~= nil then
            dealsCount = dealsCount + 1
            if logDeals then
                myLog("--------------------------------------------------")
                myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
            end
            local tradeProfit = round(lastDealPrice - DS:O(index), scale)*leverage
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
                myLog("Закрытие шорта "..tostring(deals["openShort"][dealsCount-1]).." по цене "..tostring(DS:O(index)))
                myLog("Прибыль сделки "..tostring(tradeProfit))
                myLog("Прибыль по шортам "..tostring(shortProfit))
                myLog("Прибыль всего "..tostring(allProfit))
                myLog("equity "..tostring(equitySum))
            end
            lastDealPrice = 0
            slPrice = 0
            slIndex = 0
            tpPrice = 0
        end
        if deals["openLong"][dealsCount] ~= nil then
            dealsCount = dealsCount + 1
            if logDeals then
                myLog("--------------------------------------------------")
                myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
            end
            local tradeProfit = round(DS:O(index) - lastDealPrice, scale)*leverage
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
                myLog("Закрытие лонга "..tostring(deals["openLong"][dealsCount-1]).." по цене "..tostring(DS:O(index)))
                myLog("Прибыль сделки "..tostring(tradeProfit))
                myLog("Прибыль по лонгам "..tostring(longProfit))
                myLog("Прибыль всего "..tostring(allProfit))
                myLog("equity "..tostring(equitySum))
            end
            lastDealPrice = 0
            slPrice = 0
            slIndex = 0
            tpPrice = 0
        end
    end

    if dealTime and slIndex ~= 0 and (index - slIndex) == reopenPosAfterStop then
        if logDeals then
            myLog("--------------------------------------------------")
            myLog('index '..tostring(index).." тест после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
        end
        local currentTradeDirection = getTradeDirection(index, calcAlgoValue, calcTrend, DS)

        if currentTradeDirection == 1 and deals["closeLong"][dealsCount]~=nil then
            if deals["closeLong"][dealsCount]<DS:O(index) then
                if logDeals then
                    myLog("переоткрытие лонга после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
                end
                lastTradeDirection = currentTradeDirection
                reopenAfterStop = true
            end
        end
        if currentTradeDirection == -1 and deals["closeShort"][dealsCount]~=nil then
            if deals["closeShort"][dealsCount]>DS:O(index) then
                if logDeals then
                    myLog("переоткрытие шорта после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
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
            initalAssets = DS:O(index) --*leverage
            equitySum = initalAssets
        end
        if logDeals then
            myLog("--------------------------------------------------")
            myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
            myLog("tradeSignal "..tostring(tradeSignal).." lastTradeDirection "..tostring(lastTradeDirection).." openShort "..tostring(deals["openShort"][dealsCount-1])..' openLong '..tostring(deals["openLong"][dealsCount-1]))
        end

        lastTradeDirection = 0
        if deals["openShort"][dealsCount-1] ~= nil then
            local tradeProfit = round(lastDealPrice - DS:O(index), scale)*leverage
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
                myLog("Закрытие шорта "..tostring(deals["openShort"][dealsCount-1]).." по цене "..tostring(DS:O(index)))
                myLog("Прибыль сделки "..tostring(tradeProfit))
                myLog("Прибыль по шортам "..tostring(shortProfit))
                myLog("Прибыль всего "..tostring(allProfit))
                myLog("equity "..tostring(equitySum))
            end
        end        
        if isLong then
            dealsLongCount = dealsLongCount + 1
            lastDealPrice = DS:O(index)
            TransactionPrice = lastDealPrice
            if STOP_LOSS~=0 then
                --slPrice = lastDealPrice - STOP_LOSS/leverage
                local atPrice = calcAlgoValue[index-1]
                local shiftSL = (kATR*ATR[index-1] + 40*SEC_PRICE_STEP)
                if (atPrice - shiftSL) >= TransactionPrice then
                    atPrice = TransactionPrice
                end
                slPrice = round(atPrice - shiftSL, scale)
                if reopenAfterStop then dealMaxStop = reopenDealMaxStop else dealMaxStop = maxStop end
                if (lastDealPrice - slPrice) > dealMaxStop/leverage then slPrice = lastDealPrice - dealMaxStop/leverage end
                reopenAfterStop = false
                slIndex = 0
                lastStopShiftIndex = index
            end
            if TAKE_PROFIT~=0 then
                tpPrice = round(lastDealPrice + TAKE_PROFIT/leverage, scale)
            end
            deals["index"][dealsCount] = index 
            deals["openLong"][dealsCount] = DS:O(index) 
            if logDeals then
                myLog("Покупка по цене "..tostring(lastDealPrice).." SL "..tostring(slPrice).." TP "..tostring(tpPrice))
            end
        else
            lastDealPrice = 0
        end
    end
    if (tradeSignal == -1 or lastTradeDirection == -1) and dealTime and not closeDeal then
        
        dealsCount = dealsCount + 1
        if initalAssets == 0 then
            initalAssets = DS:O(index) --*leverage
        end
        if logDeals then
            myLog("--------------------------------------------------")
            myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index)))
            myLog("tradeSignal "..tostring(tradeSignal).." lastTradeDirection "..tostring(lastTradeDirection).." openShort "..tostring(deals["openShort"][dealsCount-1])..' openLong '..tostring(deals["openLong"][dealsCount-1]))
        end
        lastTradeDirection = 0
        if deals["openLong"][dealsCount-1] ~= nil then
            local tradeProfit = round(DS:O(index) - lastDealPrice, scale)*leverage
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
                myLog("Закрытие лонга "..tostring(deals["openLong"][dealsCount-1]).." по цене "..tostring(DS:O(index)))
                myLog("Прибыль сделки "..tostring(tradeProfit))
                myLog("Прибыль по лонгам "..tostring(longProfit))
                myLog("Прибыль всего "..tostring(allProfit))
                myLog("equity "..tostring(equitySum))
            end
        end
        if isShort then
            dealsShortCount = dealsShortCount + 1
            lastDealPrice = DS:O(index)
            TransactionPrice = lastDealPrice
            if STOP_LOSS~=0 then
                --slPrice = lastDealPrice + STOP_LOSS/leverage
                local atPrice = calcAlgoValue[index-1]
                local shiftSL = (kATR*ATR[index-1] + 40*SEC_PRICE_STEP)
                if (atPrice + shiftSL) <= TransactionPrice then
                    atPrice = TransactionPrice
                end
                slPrice = round(atPrice + shiftSL, scale)
                if reopenAfterStop then dealMaxStop = reopenDealMaxStop else dealMaxStop = maxStop end
                if (slPrice - lastDealPrice) > dealMaxStop/leverage then slPrice = lastDealPrice + dealMaxStop/leverage end
                reopenAfterStop = false
                slIndex = 0
                lastStopShiftIndex = index
            end
            if TAKE_PROFIT~=0 then
                tpPrice = round(lastDealPrice - TAKE_PROFIT/leverage, scale)
            end            
            deals["index"][dealsCount] = index 
            deals["openShort"][dealsCount] = DS:O(index) 
            if logDeals then
                myLog("Продажа по цене "..tostring(lastDealPrice).." SL "..tostring(slPrice).." TP "..tostring(tpPrice))
            end
        else
            lastDealPrice = 0
        end
    end
    
    checkSL_TP(index, calcAlgoValue, calcTrend, deals, equitySum)   
    
    if index == endIndex and (deals["openShort"][dealsCount] ~= nil or deals["openLong"][dealsCount] ~= nil) then
        
        if logDeals then
            myLog("--------------------------------------------------")
            myLog("last index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index)))
        end
 
        if initalAssets == 0 then
            initalAssets = DS:O(index) --*leverage
            equitySum = initalAssets
        end
        
        if deals["openShort"][dealsCount] ~= nil then
            dealsCount = dealsCount + 1
            local tradeProfit = round(lastDealPrice - DS:C(index), scale)*leverage
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
                myLog("Закрытие шорта "..tostring(deals["openShort"][dealsCount-1]).." по цене "..tostring(DS:O(index)))
                myLog("Прибыль сделки "..tostring(tradeProfit))
                myLog("Прибыль по шортам "..tostring(shortProfit))
                myLog("Прибыль всего "..tostring(allProfit))
                myLog("equity "..tostring(equitySum))
            end
        end
        if deals["openLong"][dealsCount] ~= nil then
            dealsCount = dealsCount + 1
            local tradeProfit = round(DS:O(index) - lastDealPrice, scale)*leverage
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
                myLog("Закрытие лонга "..tostring(deals["openLong"][dealsCount-1]).." по цене "..tostring(DS:O(index)))
                myLog("Прибыль сделки "..tostring(tradeProfit))
                myLog("Прибыль по лонгам "..tostring(longProfit))
                myLog("Прибыль всего "..tostring(allProfit))
                myLog("equity "..tostring(equitySum))
            end
        end
    end

end

function checkSL_TP(index, calcAlgoValue, calcTrend, deals, equitySum)

    if (slPrice~=0 or tpPrice~=0) and lastDealPrice~=0 then
        
        if deals["openLong"][dealsCount] ~= nil then
            if DS:L(index) <= slPrice then 
                dealsCount = dealsCount + 1
                local tradeProfit = round(slPrice - lastDealPrice, scale)*leverage
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
                    myLog("--------------------------------------------------")
                    myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
                    myLog("Стоп-лосс лонга "..tostring(deals["openLong"][dealsCount-1]).." по цене "..tostring(slPrice))
                    myLog("Прибыль сделки "..tostring(tradeProfit))
                    myLog("Прибыль по лонгам "..tostring(longProfit))
                    myLog("Прибыль всего "..tostring(allProfit))
                    myLog("equity "..tostring(equitySum))
                end
                lastDealPrice = 0
                slPrice = 0
                tpPrice = 0
            end
            if DS:H(index) >= tpPrice and tpPrice~=0 then 
                dealsCount = dealsCount + 1
                local tradeProfit = round(tpPrice - lastDealPrice, scale)*leverage
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
                    myLog("--------------------------------------------------")
                    myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
                    myLog("Тейк-профит лонга "..tostring(deals["openLong"][dealsCount-1]).." по цене "..tostring(tpPrice))
                    myLog("Прибыль сделки "..tostring(tradeProfit))
                    myLog("Прибыль по лонгам "..tostring(longProfit))
                    myLog("Прибыль всего "..tostring(allProfit))
                    myLog("equity "..tostring(equitySum))
                end
                lastDealPrice = 0
                slPrice = 0
                slIndex = index
                tpPrice = 0
            end
            local isPriceMove = DS:H(index) - TransactionPrice >= STOP_LOSS/leverage
            if (isPriceMove or (index - lastStopShiftIndex)>stopShiftIndexWait) and deals["closeLong"][dealsCount] == nil then
                lastStopShiftIndex = index
                local shiftCounts = math.floor((DS:H(index) - TransactionPrice)/(STOP_LOSS/leverage))
                if logDeals then
                    myLog("--------------------------------------------------")
                    myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))                        
                    myLog("shiftCounts "..tostring(shiftCounts).." TransactionPrice "..tostring(TransactionPrice).." H "..tostring(DS:H(index)).." calcAlgoValue[index-1] "..tostring(calcAlgoValue[index-1]).." STOP_LOSS/leverage "..tostring(STOP_LOSS/leverage))
                end
                if slPrice~=0 then
                    local oldStop = slPrice
                    --slPrice = DS:H(index) - STOP_LOSS/leverage
                    local atPrice = calcAlgoValue[index-1]
                    local shiftSL = (kATR*ATR[index-1] + 40*SEC_PRICE_STEP)
                    --TransactionPrice = TransactionPrice+STOP_LOSS/leverage
                    TransactionPrice = DS:H(index)
                    if (atPrice - shiftSL) >= TransactionPrice then
                        atPrice = TransactionPrice
                    end
                    --slPrice = round(atPrice - shiftSL, scale)
                    slPrice = math.max(round(atPrice - shiftSL, scale), round(deals["openLong"][dealsCount] + 0*SEC_PRICE_STEP, scale))
                    if (deals["openLong"][dealsCount] - slPrice) > maxStop/leverage then slPrice = deals["openLong"][dealsCount] - maxStop/leverage end
                    slPrice = math.max(oldStop,slPrice)
                    if logDeals then
                        myLog("Сдвиг стоп-лосса "..tostring(slPrice))
                        myLog("new TransactionPrice "..tostring(TransactionPrice))
                    end
                end
                if slPrice~=0 and tpPrice~=0 and isPriceMove then
                    tpPrice = round(tpPrice + shiftCounts*STOP_LOSS/leverage/2, scale)
                    if logDeals then
                        myLog("Сдвиг тейка "..tostring(tpPrice))
                    end
                end
            end
        end

        if deals["openShort"][dealsCount] ~= nil then
            if DS:H(index) >= slPrice then 
                dealsCount = dealsCount + 1
                local tradeProfit = round(lastDealPrice - slPrice, scale)*leverage
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
                    myLog("--------------------------------------------------")
                    myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
                    myLog("Стоп-лосс шорта "..tostring(deals["openShort"][dealsCount-1]).." по цене "..tostring(slPrice))
                    myLog("Прибыль сделки "..tostring(tradeProfit))
                    myLog("Прибыль по шортам "..tostring(shortProfit))
                    myLog("Прибыль всего "..tostring(allProfit))
                    myLog("equity "..tostring(equitySum))
                end
                lastDealPrice = 0
                slPrice = 0
                tpPrice = 0
            end
            if DS:L(index) <= tpPrice and tpPrice~=0 then 
                dealsCount = dealsCount + 1
                local tradeProfit = round(lastDealPrice - tpPrice, scale)*leverage
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
                    myLog("--------------------------------------------------")
                    myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
                    myLog("Тейк-профит шорта "..tostring(deals["openShort"][dealsCount-1]).." по цене "..tostring(tpPrice))
                    myLog("Прибыль сделки "..tostring(tradeProfit))
                    myLog("Прибыль по шортам "..tostring(shortProfit))
                    myLog("Прибыль всего "..tostring(allProfit))
                    myLog("equity "..tostring(equitySum))
                end
                lastDealPrice = 0
                slPrice = 0
                slIndex = index
                tpPrice = 0
            end
            local isPriceMove = TransactionPrice - DS:L(index) >= STOP_LOSS/leverage
            if (isPriceMove or (index - lastStopShiftIndex)>stopShiftIndexWait) and deals["closeShort"][dealsCount] == nil then
                lastStopShiftIndex = index
                local shiftCounts = math.floor((TransactionPrice - DS:L(index))/(STOP_LOSS/leverage))
                if logDeals then
                    myLog("--------------------------------------------------")
                    myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
                    myLog("shiftCounts "..tostring(shiftCounts).." TransactionPrice "..tostring(TransactionPrice).." L(index) "..tostring(DS:L(index)).." calcAlgoValue[index-1] "..tostring(calcAlgoValue[index-1]).." STOP_LOSS/leverage "..tostring(STOP_LOSS/leverage))
                end
                if slPrice~=0 then
                    local oldStop = slPrice
                    --slPrice = DS:L(index) + STOP_LOSS/leverage
                    local atPrice = calcAlgoValue[index-1]
                    local shiftSL = (kATR*ATR[index-1] + 40*SEC_PRICE_STEP)
                    --TransactionPrice = TransactionPrice-STOP_LOSS/leverage
                    TransactionPrice = DS:L(index)
                    if (atPrice + shiftSL) <= TransactionPrice then
                        atPrice = TransactionPrice
                    end                   
                    --slPrice = round(atPrice + shiftSL, scale)
                    slPrice = math.min(round(atPrice + shiftSL, scale), round(deals["openShort"][dealsCount] - 0*SEC_PRICE_STEP, scale))
                    if (slPrice-deals["openShort"][dealsCount]) > maxStop/leverage then slPrice =  deals["openShort"][dealsCount] + maxStop/leverage end
                    slPrice = math.min(oldStop,slPrice)
                    if logDeals then
                        myLog("Сдвиг стоп-лосса "..tostring(slPrice))
                        myLog("new TransactionPrice "..tostring(TransactionPrice))
                    end
                end
                if slPrice~=0 and tpPrice~=0 and isPriceMove then
                    tpPrice = round(tpPrice - shiftCounts*STOP_LOSS/leverage/2, scale)
                    if logDeals then
                        myLog("Сдвиг тейка "..tostring(tpPrice))
                    end
                end
            end
        end
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

-- функция записывает в лог строчку с временем и датой 
function myLog(str)
   if f==nil then return end
 
   local current_time=os.time()--tonumber(timeformat(getInfoParam("SERVERTIME"))) -- помещене в переменную времени сервера в формате HHMMSS 
   if (current_time-g_previous_time)>1 then -- если текущая запись произошла позже 1 секунды, чем предыдущая
      f:write("\n") -- добавляем пустую строку для удобства чтения
   end
   g_previous_time = current_time 
 
   f:write(os.date().."; ".. str .. "\n")
 
   if str:find("Script Stoped") ~= nil then 
      f:write("======================================================================================================================\n\n")
      f:write("======================================================================================================================\n")
   end
   f:flush() -- Сохраняет изменения в файле
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
          price = string.gsub(tostring(price),'[\.]+', ',')
          return price
       end
    else -- После запятой не должно быть цифр
       -- Корректирует на соответствие шагу цены
       price = round(price/PriceStep)*PriceStep
       return tostring(math.floor(price))
    end
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
	if idp and num then
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
