-- nick-h@yandex.ru
-- Glukk Inc ©

local w32 = require("w32")
dofile (getScriptPath().."\\monitorStepNRTR.lua") --stepNRTR алгоритм. Инициализация - initstepNRTR, расчет - stepNRTR
dofile (getScriptPath().."\\monitorEMA.lua") --EMA алгоритм. Инициализация - initEMA, расчет - EMA, allEMA
dofile (getScriptPath().."\\monitorRSI.lua") --EMA алгоритм. Инициализация - initRSI, расчет - RSI
dofile (getScriptPath().."\\monitorReg.lua") --Регрессия алгоритм. Инициализация - initReg, расчет - Reg
dofile (getScriptPath().."\\monitorVolume.lua") --RT алгоритм контроль повышенного объема. Инициализация - initVolume, расчет - Volume
dofile (getScriptPath().."\\monitorVSA.lua") --VSA алгоритм. Инициализация - initVSA, расчет - VSA

FILE_LOG_NAME = getWorkingFolder().."\\RobotLogs\\scriptMonitorLog.txt" -- ИМЯ ЛОГ-ФАЙЛА
PARAMS_FILE_NAME = getWorkingFolder().."\\RobotParams\\scriptMonitor.csv" -- ИМЯ ЛОГ-ФАЙЛА

soundFileName = "c:\\windows\\media\\Alarm03.wav"
showTradeCommands = true

ACCOUNT           = 'L01-00000F00'        -- Идентификатор счета
--ACCOUNT           = 'NL0011100043'        -- пример Идентификатора счета
CLIENT_CODE = 'S2KWB'

CLASS_CODE        = '' --класс в файле настроек
--CLASS_CODE        = 'TQBR'              -- Код класса
--CLASS_CODE        = 'SPBFUT'             -- Код класса
--CLASS_CODE        = 'QJSIM'  
SEC_CODE = '' -- бумаги в файле настроек
SEC_CODES = {}

INTERVAL = 15 -- --текущий интервал

-- настройки алгоритмов

NRTRSettings = {
    Length    = 29,            -- ПЕРИОД        
    Kv = 1.4,                  -- коэффициент
    StepSize = 0,              -- шаг
    Percentage = 0,
    Switch = 1,                --1 - HighLow, 2 - CloseClose
    Size = 500,
    testZone = 10
}
RegSettings = {
    bars    = 182,
    degree = 1, -- 1 -линейная, 2 - параболическая, - 3 степени
    kstd = 3, --отклонение сигма
    testZone = 4
}
allEMASettings = {
    periods = {64,182},
    Size = 1000,
    testZone = 10
}
EMA182Settings = {
    period    = 182,
    Size = 1000,
    testZone = 10
}
EMA64Settings = {
    period    = 64,
    Size = 1000,
    testZone = 10
}
EMA29Settings = {
    period    = 29,
    Size = 1000,
    testZone = 10
}
RSISettings = {
    period    = 29,
    Size = 1000
}
VSASettings = {
    period    = 29,
    volumeFactor = 1,
    overEMAVolumeFactor = 2,
    useClosePrice = true, -- по ценам закрытия или по максимумам-минимумам
    Size = 1000
}
INTERVALS = {
    ["names"] =             {"H1VSA",      "H1",         "H4",            "D",            "W",            "hEMA29",        "dEMA64",       "dEMA182",      "D Reg",        "D RSI 29"},
    ["visible"] =           {false,         true,          true,           true,           true,           true,            true,           true,           true,           true}, --признак видимости, если невидима, то просто идет расчет и вывод сигналов
    ["width"] =             {0,             12,            12,             12,             12,             12,              12,             12,             12,             12}, --ширина колонки
    ["values"] =            {INTERVAL_H1,   INTERVAL_H1,   INTERVAL_H4,    INTERVAL_D1,    INTERVAL_W1,    INTERVAL_H1,     INTERVAL_D1,    INTERVAL_D1,    INTERVAL_D1,    INTERVAL_D1},
    ["initAlgorithms"] =    {initVSA,       initstepNRTR,  initstepNRTR,   initstepNRTR,   initstepNRTR,   initEMA,         initEMA,        noSignal,       initReg,        initRSI},   --функции инициализации алгоритма
    ["algorithms"] =        {VSA,           stepNRTR,      stepNRTR,       stepNRTR,       stepNRTR,       EMA,             allEMA,         noSignal,       Reg,            RSI},                                --функции алгоритма, определены в подключаемых файлах
    ["signalAlgorithms"] =  {signalVSA,     up_downTest,   up_downTest,    up_downTest,    up_downTest,    up_downTest,     signalAllEMA,   noSignal,       signalReg,      signalRSI},                                --функции алгоритма, определены в подключаемых файлах
    ["settings"] =          {VSASettings,   NRTRSettings,  NRTRSettings,   NRTRSettings,   NRTRSettings,   EMA29Settings,   allEMASettings, {},             RegSettings,    RSISettings},   --настройки алгоритмов, параметры функции алгоритма
    ["recalculatePeriod"] = {0,             0,             0,              60,             60,             60,              60,             60,             60,             0}   --настройки пересчета алгоритмов в минутах. для интервалов день и более - можно пересчитать данные, чтобы выводит сигналф внутри дня. 0 - не считать
}

realtimeAlgorithms = {
    ["initAlgorithms"] =    {initVolume},   --функции инициализации алгоритма
    ["functions"] =         {Volume},
    ["recalculatePeriod"] = {180}
}

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
    
--/*РАБОЧИЕ ПЕРЕМЕННЫЕ РОБОТА (менять не нужно)*/
IsRun = true -- Флаг поддержания работы скрипта
is_Connected = 0

trans_id          = os.time()            -- Задает начальный номер ID транзакций
trans_Status      = nil                  -- Статус текущей транзакции из функции OnTransPeply
trans_result_msg  = ''                   -- Сообщение по текущей транзакции из функции OnTransPeply
numberOfFixedColumns = 0                 -- Число фиксированных колонок до периодов
numberOfVisibleColumns = 0               -- Число видимых колонок периодов
tableIndex = {}                          -- Индексы колонок созданной таблицы   
openedDS = {}

SeaGreen=12713921		--	RGB(193, 255, 193) нежно-зеленый
RosyBrown=12698111	--	RGB(255, 193, 193) нежно-розовый


SEC_PRICE_STEP    = 0                    -- ШАГ ЦЕНЫ ИНСТРУМЕНТА
DS                = nil                  -- Источник данных графика (DataSource)
g_previous_time = os.time() -- помещение в переменную времени сервера в формате HHMMSS 

SEC_CODE_INDEX = {} -- last interval index

isDayInterval = false -- есть дневной интервал
dayIntervalIndex = nil

 -----------------------------
 -- Основные функции --
 -----------------------------
function DataSource(i,cell)
    local seccode = SEC_CODES['sec_codes'][i]          
    local classcode = SEC_CODES['class_codes'][i]          
    local interval = INTERVALS['values'][cell]          
    
    if openedDS[i][interval] ~= nil then
        return openedDS[i][interval]
    end
    local ds = CreateDataSource(classcode,seccode,interval)
    if ds == nil then
        message('NRTR monitor: ОШИБКА получения доступа к свечам! '..Error)
        myLog('NRTR monitor: ОШИБКА получения доступа к свечам! '..Error)
        -- Завершает выполнение скрипта
        IsRun = false
        return
    end
    if ds:Size() == 0 then 
        ds:SetEmptyCallback()
        SEC_CODES['isEmpty'][i] = true
    end
    openedDS[i][interval] = ds
    return ds
end

 -- Функция первичной инициализации скрипта (ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK в самом начале)
function OnInit()

    logFile = io.open(FILE_LOG_NAME, "a+") -- открывает файл 
    
    local ParamsFile = io.open(PARAMS_FILE_NAME,"r")
    if ParamsFile == nil then
        IsRun = false
        message("Не удалость прочитать файл настроек!!!")
        return false
    end

    is_Connected = isConnected()

    if is_Connected ~= 1 then
        IsRun = false
        message("Нет подключения к серверу!!!")
        return false
    end

    SEC_CODES['class_codes'] =              {} -- CLASS_CODE
    SEC_CODES['names'] =                    {} -- имена бумаг
    SEC_CODES['sec_codes'] =                {} -- коды бумаг
    SEC_CODES['isMessage'] =                {} -- выводить сообщения
    SEC_CODES['isPlaySound'] =              {} -- проигрывать звук
    SEC_CODES['volume'] =                   {} -- рабочий объем
    SEC_CODES['isEmpty'] =                  {} -- признак заказа данных
    SEC_CODES['DS'] =                       {} -- данные по инструменту
    SEC_CODES['calcAlgoValues'] =           {} -- рассчитанные данные
    SEC_CODES['dayATR'] =                   {} -- рассчитанные данные ATR
    SEC_CODES['dayDS'] =                    {} -- данные для ATR
    SEC_CODES['dayATR_Period'] =            {} -- период данных ATR
    SEC_CODES['D_minus5'] =                 {} -- цена 5 дней назад
    SEC_CODES['lastTimeCalculated'] =       {} -- время последнего рассчета
    SEC_CODES['lastrealTimeCalculated'] =   {} -- время последнего рассчета realtime алгоритма
    
    ss = getInfoParam("SERVERTIME")
    h = 0
    if ss == "" then
        ss = os.date("%H:%M")
    end
    if string.len(ss) >= 5 then
        hh = mysplit(ss,":")
        str=hh[1]..hh[2]
        h = tonumber(str)
    end

    myLog("Читаем файл параметров")
    local lineCount = 0
    for line in ParamsFile:lines() do
        --myLog("Строка параметров "..line)
        lineCount = lineCount + 1
        if lineCount > 1 and line ~= "" then
            local per1, per2, per3, per4, per5, per6, per7 = line:match("%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*)")
            SEC_CODES['class_codes'][lineCount-1] = per1 
            SEC_CODES['names'][lineCount-1] = per2
            SEC_CODES['sec_codes'][lineCount-1] = per3
            SEC_CODES['isMessage'][lineCount-1] = tonumber(per4) 
            SEC_CODES['isPlaySound'][lineCount-1] = tonumber(per5) 
            SEC_CODES['volume'][lineCount-1] = tonumber(per6) 
            SEC_CODES['isEmpty'][lineCount-1] = false 
            SEC_CODES['DS'][lineCount-1] = {} 
            SEC_CODES['calcAlgoValues'][lineCount-1] = {} 
            SEC_CODES['dayATR'][lineCount-1] = 0 
            SEC_CODES['dayDS'][lineCount-1] = nil 
            SEC_CODES['dayATR_Period'][lineCount-1] = tonumber(per7) 
            SEC_CODES['D_minus5'][lineCount-1] = 0 
            SEC_CODES['lastTimeCalculated'][lineCount-1] = {} 
            SEC_CODES['lastrealTimeCalculated'][lineCount-1] = {} 
        end
    end

    ParamsFile:close()

    myLog("Intervals "..tostring(#INTERVALS["names"]))
    myLog("Sec codes "..tostring(#SEC_CODES['sec_codes']))
    CreateTable() -- Создает таблицу
    
    myLog("realTime functions "..tostring(#realtimeAlgorithms["functions"]))

    for i,v in ipairs(SEC_CODES['sec_codes']) do      
                   
        SEC_CODE_INDEX[i] = {}
        SEC_CODE = v
        CLASS_CODE =SEC_CODES['class_codes'][i]
        openedDS[i] = {}

        SEC_PRICE_STEP = getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value
        local status = getParamEx(CLASS_CODE,  SEC_CODE, "last").param_value
        local last_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)
        local open_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"prevprice").param_value)
        local highest_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"high").param_value)
        local lowest_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"low").param_value)
        if last_price == 0 or last_price == nil then
            last_price = open_price
        end
        SetCell(t_id, i, tableIndex["Текущая цена"], tostring(last_price), last_price)  --i строка, 1 - колонка, v - значение
        local lastchange = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"lastchange").param_value)
        Str(i, tableIndex["%"], lastchange, 0, 0)  --i строка, 1 - колонка, v - значение
        SetCell(t_id, i, tableIndex["Цена открытия"], tostring(open_price), open_price)  --i строка, 1 - колонка, v - значение
        local delta = round(last_price-open_price,5)
        SetCell(t_id, i, tableIndex["Дельта"], tostring(delta), delta)  --i строка, 1 - колонка, v - значение
        local openCount, awg_price = GetTotalnet(CLASS_CODE, SEC_CODE)        
        SetCell(t_id, i, tableIndex["Позиция"], tostring(openCount), openCount)  --i строка, 1 - колонка, v - значение
        if tonumber(awg_price)==0 then
            SetCell(t_id, i, tableIndex["Средняя"], '', 0)  --i строка, 1 - колонка, v - значение
            White(i, tableIndex["Средняя"])
        else
            Str(i, tableIndex["Средняя"], tonumber(awg_price), last_price)  --i строка, 1 - колонка, v - значение
        end    
        --Команды
        if showTradeCommands == true then
            SetCell(t_id, i,  tableIndex["<"], "-")  --i строка, 1 - колонка, v - значение
            SetCell(t_id, i, tableIndex["Объем сделки"], tostring(SEC_CODES['volume'][i]), SEC_CODES['volume'][i])  --i строка, 1 - колонка, v - значение
            SetCell(t_id, i, tableIndex[">"], "+")  --i строка, 1 - колонка, v - значение
            SetCell(t_id, i, tableIndex["Команда BUY"], "BUY")  --i строка, 1 - колонка, v - значение
            Green(i, tableIndex["Команда BUY"])
            SetCell(t_id, i, tableIndex["Команда SELL"], "SELL")  --i строка, 1 - колонка, v - значение
            Red(i, tableIndex["Команда SELL"])
            if openCount~=0 then 
                Red(i, tableIndex["Команда CLOSE"])
                SetCell(t_id, i, tableIndex["Команда CLOSE"], "CLOSE")  --i строка, 0 - колонка, v - значение 
            else
                White(i, tableIndex["Команда CLOSE"])
                SetCell(t_id, i, tableIndex["Команда CLOSE"], "")  --i строка, 0 - колонка, v - значение 
            end
        end
        
        for kk,algo in pairs(realtimeAlgorithms["functions"]) do                    
            local initrf = realtimeAlgorithms["initAlgorithms"][kk]
            if initrf~=nil then
                initrf()
            end    
            SEC_CODES['lastrealTimeCalculated'][i][kk] = g_previous_time            
        end

        for cell,INTERVAL in pairs(INTERVALS["values"]) do                    
            
            DS = DataSource(i,cell)
            SEC_CODES['DS'][i][cell] = DS            
            SEC_CODES['lastTimeCalculated'][i][cell] = h            
            
            SEC_CODE_INDEX[i][cell] = DS:Size()
            --myLog("Всего свечей ".. SEC_CODE..", интервала "..INTERVALS["names"][cell].." "..tostring(SEC_CODE_INDEX[i][cell]))
            
            if status ~= nil and status ~= 0 then
                    --interval algorithms
                local initf = INTERVALS["initAlgorithms"][cell]
                local calcf = INTERVALS["algorithms"][cell]
                local signalf = INTERVALS["signalAlgorithms"][cell]
                local settings = INTERVALS["settings"][cell]
                
                if initf~=nil then
                    initf()
                else calcAlgoValue = {}
                end
                if calcf~=nil then
                    -- расчет параметров для каждого интервала
                    calcAlgoValue = calcf(i, DS:Size(), settings, DS)
                end
    
                SEC_CODES['calcAlgoValues'][i][cell] = calcAlgoValue[DS:Size()] or 0
    
                if signalf~=nil then
                    signalf(i, cell, settings, DS, false)                    
                elseif calcf~=nil then
                    up_downTest(i, cell, settings, DS, false)                    
                end
            end
            
            --ATR
            if INTERVAL == INTERVAL_D1 and isDayInterval == false then
                isDayInterval = true
                dayIntervalIndex = cell
            end

        end

        --ATR
        getATR(i, dayIntervalIndex)

        local lastATR = round(SEC_CODES['dayATR'][i], 5)
        if highest_price ==0 then highest_price = open_price end
        if lowest_price ==0 then lowest_price = open_price end
        local atrDelta = math.max(math.abs(highest_price - open_price), math.abs(open_price-lowest_price))
        if lastATR<math.abs(atrDelta) then
            Red(i, tableIndex["D ATR"])
        else
            White(i, tableIndex["D ATR"])    
        end
        --ATR
            
        --W%
        local changeW = round((last_price - SEC_CODES['D_minus5'][i])*100/SEC_CODES['D_minus5'][i], 2)
        Str(i, tableIndex["%W"], changeW, 0, 0)                   
        --W%

    end

    myLog("================================================")
    myLog("Initialization finished")

end 
 
function main() -- Функция, реализующая основной поток выполнения в скрипте
    
    SetTableNotificationCallback(t_id, event_callback)
    SetTableNotificationCallback(tv_id, volume_event_callback)

    while IsRun do -- Цикл будет выполнятся, пока IsRun == true 
        
        for i,v in ipairs(SEC_CODES['sec_codes']) do      
            
            if IsRun == false then break end

            SEC_CODE = v
            CLASS_CODE =SEC_CODES['class_codes'][i]

            -- Получает ШАГ ЦЕНЫ ИНСТРУМЕНТА, последнюю цену, открытые позиции
            SEC_PRICE_STEP = getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value
            local status = getParamEx(CLASS_CODE,  SEC_CODE, "last").param_value
            local last_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)
            local open_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"prevprice").param_value)
            local highest_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"high").param_value)
            local lowest_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"low").param_value)
            if last_price == 0 or last_price == nil then
                last_price = open_price
            end
            local lp = GetCell(t_id, i, tableIndex["Текущая цена"]).value or last_price
            if lp > last_price then
                Highlight(t_id, i, tableIndex["Текущая цена"], SeaGreen, QTABLE_DEFAULT_COLOR,1000)		-- подсветка мягкий, зеленый
            elseif lp < last_price then
                Highlight(t_id, i, tableIndex["Текущая цена"], RosyBrown, QTABLE_DEFAULT_COLOR,1000)		-- подсветка мягкий розовый
            end   
            SetCell(t_id, i, tableIndex["Текущая цена"], tostring(last_price), last_price)  --i строка, 1 - колонка, v - значение
            local lastchange = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"lastchange").param_value)
            Str(i, tableIndex["%"], lastchange, 0, 0)  --i строка, 1 - колонка, v - значение
            SetCell(t_id, i, tableIndex["Цена открытия"], tostring(open_price), open_price)  --i строка, 1 - колонка, v - значение
            local delta = round(last_price-open_price,5)
            SetCell(t_id, i, tableIndex["Дельта"], tostring(delta), delta)  --i строка, 1 - колонка, v - значение
            if IsWindowClosed(t_id) == false then
                local awg_price = GetCell(t_id, i, tableIndex["Средняя"]).value or 0
                if tonumber(awg_price)==0 then
                    White(i, tableIndex["Средняя"])
                else
                    Str(i, tableIndex["Средняя"], tonumber(awg_price), last_price)  --i строка, 1 - колонка, v - значение
                end    
            end
            
            ss = getInfoParam("SERVERTIME")
            h = 0
            if ss == "" then
                ss = os.date("%H:%M")
            end
            if string.len(ss) >= 5 then
                hh = mysplit(ss,":")
                str=hh[1]..hh[2]
                h = tonumber(str)
            end
                        
            local current_time=os.time()

            --myLog(tostring(status))
            if status ~= nil and status ~= "0.000000" and ss ~= ""  and h > 959 then
                
                for kk,algo in pairs(realtimeAlgorithms["functions"]) do                    
                    local realf = realtimeAlgorithms["functions"][kk]
                    if realf~=nil then
                        local lastrealTimeCalculated = SEC_CODES['lastrealTimeCalculated'][i][kk] or current_time 
                        local newrealTimeToCalculate = current_time
                        local realperiod = realtimeAlgorithms["recalculatePeriod"][kk] or 0
                         if realperiod ~= 0 then
                            newrealTimeToCalculate = lastrealTimeCalculated + realperiod
                            if current_time>newrealTimeToCalculate then
                                --myLog(SEC_CODE.." realperiod "..tostring(realperiod).." lastrealTimeCalculated "..tostring(lastrealTimeCalculated))
                                --myLog("newrealTimeToCalculate "..tostring(newrealTimeToCalculate))
                                --myLog("current_time "..tostring(current_time))
                                SEC_CODES['lastrealTimeCalculated'][i][kk] = current_time            
                                realf(i)
                            end
                        end
                    end
                end
                
                for cell,INTERVAL in pairs(INTERVALS["values"]) do                    
                                    
                    DS = SEC_CODES['DS'][i][cell]
                    
                    local lastTimeCalculated = SEC_CODES['lastTimeCalculated'][i][cell] 
                    local newTimeToCalculate = h
                    local period = INTERVALS["recalculatePeriod"][cell] or 0
                    if period ~= 0 then
                        newTimeToCalculate = lastTimeCalculated + 100*math.floor(period/60) + period%60
                    end

                    local timeCandle = DS:T(DS:Size())
                    
                    --myLog(SEC_CODE.." - timeCandle "..tostring(os.time(timeCandle)))
                    --myLog(SEC_CODE.." - INTERVAL "..tostring(INTERVAL))
                    --myLog(SEC_CODE.." - current_time "..tostring(current_time))
                    --myLog(SEC_CODE.." - newtimeCandle "..tostring(os.time(timeCandle) + INTERVAL*60))
                    --WriteLog ("deal 0".."; SEC_CODE: "..trade.sec_code.."; time deal "..isnil(toYYYYMMDDHHMMSS(datetime)," - "));            
                    if SEC_CODE_INDEX[i][cell]<DS:Size() or h>newTimeToCalculate and current_time < (os.time(timeCandle) + INTERVAL*60) then --new candle 
                        
                        --myLog(SEC_CODE.." - Перерасчет данных за интервал "..INTERVALS["names"][cell])
                        SEC_CODE_INDEX[i][cell] = DS:Size() --last candle               
                        SEC_CODES['lastTimeCalculated'][i][cell] = h            
                                            
                        --interval algorithms
                        local initf = INTERVALS["initAlgorithms"][cell]
                        local calcf = INTERVALS["algorithms"][cell]
                        local signalf = INTERVALS["signalAlgorithms"][cell]
                        local settings = INTERVALS["settings"][cell]
                        
                        if initf~=nil then
                            initf()
                        else calcAlgoValue = {}
                        end
                        if calcf~=nil then
                            calcAlgoValue = calcf(i, DS:Size(), settings, DS)
                        end
                        SEC_CODES['calcAlgoValues'][i][cell] = calcAlgoValue[DS:Size()] or 0 
                        
                        if signalf~=nil then
                            signalf(i, cell, settings, DS, true)                    
                        elseif calcf~=nil then
                            up_downTest(i, cell, settings, DS, true)                    
                        end
                    end

                end  
            end

            --ATR
            if SEC_CODES['D_minus5'][i]==0 or SEC_CODES['D_minus5'][i]==nil or SEC_CODES['dayATR'][i]==0 or SEC_CODES['dayATR'][i]==nil then
            getATR(i, dayIntervalIndex)
            end
            local lastATR = round(SEC_CODES['dayATR'][i], 5)
            if highest_price ==0 then highest_price = open_price end
            if lowest_price ==0 then lowest_price = open_price end
            local atrDelta = math.max(math.abs(highest_price - open_price), math.abs(open_price-lowest_price))
            if lastATR<math.abs(atrDelta) then
                Red(i, tableIndex["D ATR"])
            else
                White(i, tableIndex["D ATR"])    
            end
            --ATR
            
            --W%
            local changeW = round((last_price - SEC_CODES['D_minus5'][i])*100/SEC_CODES['D_minus5'][i], 2)
            Str(i, tableIndex["%W"], changeW, 0, 0)                   
            --W%
        end      
        sleep(100)
   end
end
 
-- Функция ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK при остановке скрипта
function OnStop()
    IsRun = false
    myLog("Script Stoped") 
    if t_id~= nil then
        DestroyTable(t_id)
    end
    if tv_id~= nil then
        DestroyTable(tv_id)
    end
    calcAlgoValue = nil
    if logFile~=nil then logFile:close() end    -- Закрывает файл 
end
 -----------------------------
 -- РАБОТА С ТАБЛИЦЕЙ --
 -----------------------------

 function CreateTable() -- Функция создает таблицу
    t_id = AllocTable() -- Получает доступный id для создания
    
    -- Добавляет колонки
    AddColumn(t_id, 0, "Инструмент", true, QTABLE_STRING_TYPE, 22)
    tableIndex["Инструмент"] = 0
    AddColumn(t_id, 1, "Цена", true, QTABLE_DOUBLE_TYPE, 13)
    tableIndex["Текущая цена"] = 1
    AddColumn(t_id, 2, "%", true, QTABLE_DOUBLE_TYPE, 9)
    tableIndex["%"] = 2
    AddColumn(t_id, 3, "%W", true, QTABLE_DOUBLE_TYPE, 9)
    tableIndex["%W"] = 3
    AddColumn(t_id, 4, "Открытие", true, QTABLE_DOUBLE_TYPE, 13)
    tableIndex["Цена открытия"] = 4
    AddColumn(t_id, 5, "Дельта", true, QTABLE_DOUBLE_TYPE, 13)
    tableIndex["Дельта"] = 5
    AddColumn(t_id, 6, "D ATR", true, QTABLE_DOUBLE_TYPE, 13)
    tableIndex["D ATR"] = 6
    AddColumn(t_id, 7, "Поз.", true, QTABLE_INT_TYPE, 7)
    tableIndex["Позиция"] = 7
    AddColumn(t_id, 8, "Средняя", true, QTABLE_DOUBLE_TYPE, 13)
    tableIndex["Средняя"] = 8
    numberOfFixedColumns = 8
    numberOfVisibleColumns = 0
    local width = 0
    for i,v in ipairs(INTERVALS["names"]) do
        if INTERVALS["visible"][i] then
            numberOfVisibleColumns = numberOfVisibleColumns + 1
            AddColumn(t_id, numberOfVisibleColumns+numberOfFixedColumns, v, true, QTABLE_DOUBLE_TYPE, INTERVALS["width"][i])
            tableIndex[i] = numberOfVisibleColumns+numberOfFixedColumns
            width = width + INTERVALS["width"][i]
        end
    end
    local columns = numberOfFixedColumns
    if showTradeCommands == true then
        AddColumn(t_id, numberOfVisibleColumns+numberOfFixedColumns+1, "Цена", true, QTABLE_DOUBLE_TYPE, 15) --Price
        tableIndex["Цена сделки"] = numberOfVisibleColumns+numberOfFixedColumns+1
        AddColumn(t_id, numberOfVisibleColumns+numberOfFixedColumns+2, "<", true, QTABLE_STRING_TYPE, 5) --Decrease volume
        tableIndex["<"] = numberOfVisibleColumns+numberOfFixedColumns+2
        AddColumn(t_id, numberOfVisibleColumns+numberOfFixedColumns+3, "Vol", true, QTABLE_INT_TYPE, 7) --Volume
        tableIndex["Объем сделки"] = numberOfVisibleColumns+numberOfFixedColumns+3
        AddColumn(t_id, numberOfVisibleColumns+numberOfFixedColumns+4, ">", true, QTABLE_STRING_TYPE, 5) --Increase volume
        tableIndex[">"] = numberOfVisibleColumns+numberOfFixedColumns+4
        AddColumn(t_id, numberOfVisibleColumns+numberOfFixedColumns+5, "BUY", true, QTABLE_STRING_TYPE, 10) --BUY
        tableIndex["Команда BUY"] = numberOfVisibleColumns+numberOfFixedColumns+5
        AddColumn(t_id, numberOfVisibleColumns+numberOfFixedColumns+6, "SELL", true, QTABLE_STRING_TYPE, 10) --SELL
        tableIndex["Команда SELL"] = numberOfVisibleColumns+numberOfFixedColumns+6
        AddColumn(t_id, numberOfVisibleColumns+numberOfFixedColumns+7, "CLOSE", true, QTABLE_STRING_TYPE, 10) --CLOSE ALL
        tableIndex["Команда CLOSE"] = numberOfVisibleColumns+numberOfFixedColumns+7
        columns = columns + 2.3
    end
    t = CreateWindow(t_id) -- Создает таблицу
    SetWindowCaption(t_id, "Monitor") -- Устанавливает заголовок
    SetWindowPos(t_id, 90, 60, 86*columns + width*5.7, 800) -- Задает положение и размеры окна таблицы
    
    -- Добавляет строки
    for i,v in ipairs(SEC_CODES['names']) do
        InsertRow(t_id, i)
        SetCell(t_id, i, tableIndex["Инструмент"], v)  --i строка, 0 - колонка, v - значение 
    end

    tv_id = AllocTable() -- таблица ввода значения
 
 end
 
function Str(str, num, value, testvalue, dir) -- Функция выводит и окрашивает строки в таблице 
    if dir == nil then dir = 1 end
    SetCell(t_id, str, num, tostring(value), value) -- Выводит значение в таблицу: строка, коллонка, значение
    if (value < testvalue and dir == 1) or (value > testvalue and dir == 0) then Green(str, num) elseif value == testvalue then Gray(str, num) else Red(str, num) end -- Окрашивает строку в зависимости от значения профита
end

 -----------------------------
 -- Функции по раскраске строк/ячеек таблицы --
 ----------------------------- 

function Green(Line, Col) -- Зеленый
   if Col == nil then Col = QTABLE_NO_INDEX end -- Если индекс столбца не указан, окрашивает всю строку
   SetColor(t_id, Line, Col, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
end
function Gray(Line, Col) -- Серый
   if Col == nil then Col = QTABLE_NO_INDEX end -- Если индекс столбца не указан, окрашивает всю строку
   SetColor(t_id, Line, Col, RGB(200,200,200), RGB(0,0,0), RGB(200,200,200), RGB(0,0,0))
end
function Red(Line, Col) -- Красный
   if Col == nil then Col = QTABLE_NO_INDEX end -- Если индекс столбца не указан, окрашивает всю строку
   SetColor(t_id, Line, Col, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
end
function White(Line, Col) -- Белый
   if Col == nil then Col = QTABLE_NO_INDEX end -- Если индекс столбца не указан, окрашивает всю строку
   SetColor(t_id, Line, Col, RGB(255,255,255), RGB(0,0,0), RGB(255,255,255), RGB(0,0,0))
end 
function cellSetColor(Line, Col, Color, textColor)
   if Col == nil then Col = QTABLE_NO_INDEX end -- Если индекс столбца не указан, окрашивает всю строку
   if Color == nil then Color =  RGB(255,255,255) end -- Если цвет не указан, окрашивает в белый
   if textColor == nil then textColor = RGB(0,0,0) end -- Если цвет не указан, цвет черный
   SetColor(t_id, Line, Col, Color, textColor, Color, textColor)
end 
 -----------------------------
 -- Обработка команд таблицы --
 ----------------------------- 
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

    if msg == QTABLE_LBUTTONDBLCLK and showTradeCommands == true then

        if par2 == tableIndex["Текущая цена"] or par2 == tableIndex["Цена открытия"] or par2 == tableIndex["Средняя"] or (par2 > numberOfFixedColumns and par2 <= numberOfVisibleColumns+numberOfFixedColumns) then --Берем цену
            local TRADE_SEC_CODE = SEC_CODES['sec_codes'][par1]
            local TRADE_CLASS_CODE = SEC_CODES['class_codes'][par1]
            local newPrice = GetCorrectPrice(GetCell(t_id, par1, par2).value, TRADE_CLASS_CODE, TRADE_SEC_CODE)
            local stringPrice = string.gsub(tostring(newPrice),',', '.')
            local numberPrice = tonumber(stringPrice)
             if numberPrice~=nil and numberPrice~=0 then
                SetCell(t_id, par1, tableIndex["Цена сделки"], stringPrice, numberPrice)  --i строка, 1 - колонка, v - значение            
            end
        end
        if par2 == tableIndex["Цена сделки"] and IsWindowClosed(tv_id) then --Вводим цену
            tstr = par1
            tcell = par2
            AddColumn(tv_id, 0, "Значение", true, QTABLE_DOUBLE_TYPE, 25)
            tv = CreateWindow(tv_id) 
            SetWindowCaption(tv_id, "Введите цену") 
            SetWindowPos(tv_id, 290, 260, 250, 100)                                
            InsertRow(tv_id, 1)
            SetCell(tv_id, 1, 0, GetCell(t_id, par1, tableIndex["Цена сделки"]).image, GetCell(t_id, par1, tableIndex["Цена сделки"]).value)  --i строка, 0 - колонка, v - значение 
        end
        if par2 == tableIndex["Объем сделки"] and IsWindowClosed(tv_id) then --Вводим объем
            tstr = par1
            tcell = par2
            AddColumn(tv_id, 0, "Значение", true, QTABLE_INT_TYPE, 25)
            tv = CreateWindow(tv_id) 
            SetWindowCaption(tv_id, "Введите объем")
            SetWindowPos(tv_id, 290, 260, 250, 100)                                
            InsertRow(tv_id, 1)
            SetCell(tv_id, 1, 0, GetCell(t_id, par1, tableIndex["Объем сделки"]).image, GetCell(t_id, par1, tableIndex["Объем сделки"]).value)  --i строка, 0 - колонка, v - значение 
        end
        if par2 == tableIndex["Команда CLOSE"] then -- All Close
            local TRADE_SEC_NAME = SEC_CODES['names'][par1]
            local TRADE_SEC_CODE = SEC_CODES['sec_codes'][par1]
            local TRADE_CLASS_CODE = SEC_CODES['class_codes'][par1]
            local QTY_LOTS = GetCell(t_id, par1, tableIndex["Позиция"]).value
            if QTY_LOTS == 0 or QTY_LOTS==nil then
                message("Некорректно указан объем!!!")
                return
            end            
            if QTY_LOTS ~=0 then 
                local CurrentDirect = 'SELL'
                message(TRADE_SEC_NAME.." Закрытие всей позиции, Объем: "..tostring(QTY_LOTS)..", по рынку")
                MakeTransaction(CurrentDirect, QTY_LOTS, 0, TRADE_CLASS_CODE, TRADE_SEC_CODE)
            end
        end
        if par2 == tableIndex["Команда BUY"] then --BUY volume
            local TRADE_SEC_NAME = SEC_CODES['names'][par1]
            local TRADE_SEC_CODE = SEC_CODES['sec_codes'][par1]
            local TRADE_CLASS_CODE = SEC_CODES['class_codes'][par1]
            local CurrentDirect = 'BUY'
            local QTY_LOTS = GetCell(t_id, par1, tableIndex["Объем сделки"]).value
            if QTY_LOTS == 0 or QTY_LOTS==nil then
                message("Некорректно указан объем!!!")
                return
            end
            local TRADE_PRICE = GetCell(t_id, par1, tableIndex["Цена сделки"]).value
            local checkString = GetCell(t_id, par1, tableIndex["Цена сделки"]).image
            if (TRADE_PRICE==nil or TRADE_PRICE==0) and string.len(checkString) ~= 0 then
                message("Некорректно указана цена: "..tostring(TRADE_PRICE))
                return
            end
            message(TRADE_SEC_NAME.." Покупка, Объем: "..tostring(QTY_LOTS)..", Цена: "..tostring(TRADE_PRICE))
            MakeTransaction(CurrentDirect, QTY_LOTS, TRADE_PRICE, TRADE_CLASS_CODE, TRADE_SEC_CODE)
        end
        if par2 == tableIndex["Команда SELL"] then --SELL volume
            local TRADE_SEC_NAME = SEC_CODES['names'][par1]
            local TRADE_SEC_CODE = SEC_CODES['sec_codes'][par1]
            local TRADE_CLASS_CODE = SEC_CODES['class_codes'][par1]
            local CurrentDirect = 'SELL'
            local QTY_LOTS = GetCell(t_id, par1, tableIndex["Объем сделки"]).value
            if QTY_LOTS == 0 or QTY_LOTS==nil then
                message("Некорректно указан объем!!!")
                return
            end
            local TRADE_PRICE = GetCell(t_id, par1, tableIndex["Цена сделки"]).value
            local checkString = GetCell(t_id, par1, tableIndex["Цена сделки"]).image
            if (TRADE_PRICE==nil or TRADE_PRICE==0) and string.len(checkString) ~= 0 then
                message("Некорректно указана цена: "..tostring(TRADE_PRICE))
                return
            end
            message(TRADE_SEC_NAME.." Продажа, Объем: "..tostring(QTY_LOTS)..", Цена: "..tostring(TRADE_PRICE))
            MakeTransaction(CurrentDirect, QTY_LOTS, TRADE_PRICE, TRADE_CLASS_CODE, TRADE_SEC_CODE)
        end
        if par2 ==  tableIndex["<"] then
            local newVolume = GetCell(t_id, par1, tableIndex["Объем сделки"]).value - SEC_CODES['volume'][par1]
            SetCell(t_id, par1, tableIndex["Объем сделки"], tostring(newVolume), newVolume)  --i строка, 1 - колонка, v - значение            
        end
        if par2 == tableIndex[">"] then
            local newVolume = GetCell(t_id, par1, tableIndex["Объем сделки"]).value + SEC_CODES['volume'][par1]
            SetCell(t_id, par1, tableIndex["Объем сделки"], tostring(newVolume), newVolume)  --i строка, 1 - колонка, v - значение            
        end
    end
    if msg == QTABLE_CHAR and showTradeCommands == true then
        if tostring(par2) == "8" then
           SetCell(t_id, par1, tableIndex["Цена сделки"], "")
        end
        if tostring(par2) == "68" or tostring(par2) == "194" then
            local TRADE_SEC_CODE = SEC_CODES['sec_codes'][par1]
            local TRADE_SEC_NAME = SEC_CODES['names'][par1]
            local TRADE_CLASS_CODE = SEC_CODES['class_codes'][par1]
            message("Удаляем все заявки "..TRADE_SEC_NAME)
            KillAllOrders("orders", TRADE_CLASS_CODE, TRADE_SEC_CODE)
        end
        if tostring(par2) == "251" or tostring(par2) == "219" then
            local TRADE_SEC_CODE = SEC_CODES['sec_codes'][par1]
            local TRADE_SEC_NAME = SEC_CODES['names'][par1]
            local TRADE_CLASS_CODE = SEC_CODES['class_codes'][par1]
            message("Удаляем все стоп заявки "..TRADE_SEC_NAME)
            KillAllOrders("stop_orders", TRADE_CLASS_CODE, TRADE_SEC_CODE)
        end
    end
    if (msg==QTABLE_CLOSE) then --закрытие окна
        IsRun = false
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
        
        if Status == 2 then
            message("Ошибка при передаче транзакции в торговую систему. Так как отсутствует подключение шлюза Московской Биржи, повторно транзакция не отправляется")
            myLog("Ошибка при передаче транзакции в торговую систему. Так как отсутствует подключение шлюза Московской Биржи, повторно транзакция не отправляется")
        end
        
        if trans_Status > 3 then
            if trans_Status == 4 then messageText = "Транзакция не исполнена" end
            if trans_Status == 5 then messageText = "Транзакция не прошла проверку сервера QUIK" end
            if trans_Status == 6 then messageText = "Транзакция не прошла проверку лимитов сервера QUIK" end
            if trans_Status == 7 then messageText = "Транзакция не поддерживается торговой системой" end
            message('NRTR monitor: Транзакция вернула ошибку: '..messageText)
            myLog('NRTR monitor: Транзакция вернула ошибку: '..messageText)
        end

        myLog("OnTransReply "..tostring(trans_id).." "..trans_result_msg)
    end
end

function MakeTransaction(CurrentDirect, QTY_LOTS, TRADE_PRICE, TRADE_CLASS_CODE, TRADE_SEC_CODE)   
    return Trade(CurrentDirect, QTY_LOTS, TRADE_PRICE, TRADE_CLASS_CODE ,TRADE_SEC_CODE)
end

-- Совершает СДЕЛКУ указанного типа (Type) ["BUY", или "SELL"]
function Trade(Type, qnt, TRADE_PRICE, TRADE_CLASS_CODE, TRADE_SEC_CODE)
    --Получает ID транзакции
    trans_id = trans_id + 1
    if TRADE_PRICE == nil then
        TRADE_PRICE = 0
    end

    local TRADE_TYPE = 'M'-- по рынку (MARKET)
    if TRADE_PRICE ~= 0 then
        TRADE_TYPE = 'L'  
    end

    local Operation = ''
    --Устанавливает цену и операцию, в зависимости от типа сделки и от класса инструмента
    TRADE_SEC_PRICE_STEP = tonumber(getParamEx(TRADE_CLASS_CODE, TRADE_SEC_CODE, "SEC_PRICE_STEP").param_value)
    if Type == 'BUY' then
        Operation = 'B'
        if TRADE_PRICE == 0 and TRADE_CLASS_CODE ~= 'QJSIM' and TRADE_CLASS_CODE ~= 'TQBR' then 
            TRADE_PRICE = getParamEx(TRADE_CLASS_CODE, TRADE_SEC_CODE, 'offer').param_value + 10*TRADE_SEC_PRICE_STEP
        end -- по цене, завышенной на 10 мин. шагов цены
    else
        Operation = 'S'
        if TRADE_PRICE == 0 and TRADE_CLASS_CODE ~= 'QJSIM' and TRADE_CLASS_CODE ~= 'TQBR' then 
            TRADE_PRICE = getParamEx(TRADE_CLASS_CODE, TRADE_SEC_CODE, 'bid').param_value - 10*TRADE_SEC_PRICE_STEP
        end -- по цене, заниженной на 10 мин. шагов цены
    end
    -- Заполняет структуру для отправки транзакции
    --TRADE_PRICE = GetCorrectPrice(TRADE_PRICE, TRADE_CLASS_CODE, TRADE_SEC_CODE)
    myLog("script Monitor: "..TRADE_TYPE.." Transaction "..Type..' '..TRADE_PRICE)
 
    local Transaction={
       ['TRANS_ID']   = tostring(trans_id),
       ['ACTION']     = 'NEW_ORDER',
       ['CLASSCODE']  = TRADE_CLASS_CODE,
       ['SECCODE']    = TRADE_SEC_CODE,
       ['CLIENT_CODE'] = CLIENT_CODE,  
       ['OPERATION']  = Operation, -- операция ("B" - buy, или "S" - sell)
       ['TYPE']       = TRADE_TYPE, 
       ['QUANTITY']   = tostring(qnt), -- количество
       ['ACCOUNT']    = ACCOUNT,
       ['PRICE']      = tostring(TRADE_PRICE),
       ['COMMENT']    = 'NRTR monitor' -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках
    }
    -- Отправляет транзакцию
    local res = sendTransaction(Transaction)
    if string.len(res) ~= 0 then
        message('Script monitor: Транзакция вернула ошибку: '..res)
        myLog('Script monitor: Транзакция вернула ошибку: '..res)
        return false
     end
  
     return true

end

--TAKE_PROFIT -  минимальных шагов цены профита
--STOP_LOSS - минимальных шагов цены стоп-лосса
--TRADE_PRICE - уровень цены, на котором выстадяется стоп-заявка
--TakeProfitPrice - предыдущий тейк, для трейлинга

function SL_TP(TRADE_PRICE, TakeProfitPrice, Type, STOP_LOSS, TAKE_PROFIT ,TRADE_CLASS_CODE, TRADE_SEC_CODE)
    -- ID транзакции
    trans_id = trans_id + 1
 
     -- Находит направление для заявки
     local operation = ""
     local price = "0" -- Цена, по которой выставится заявка при срабатывании Стоп-Лосса (для рыночной заявки по акциям должна быть 0)
     local stopprice = "" -- Цена Тейк-Профита
     local stopprice2 = "" -- Цена Стоп-Лосса
     local market = "YES" -- После срабатывания Тейка, или Стопа, заявка сработает по рыночной цене
     local direction
     TRADE_SEC_PRICE_STEP = tonumber(getParamEx(TRADE_CLASS_CODE, TRADE_SEC_CODE, "SEC_PRICE_STEP").param_value)
 
  -- Если открыт BUY, то направление стоп-лосса и тейк-профита SELL, иначе направление стоп-лосса и тейк-профита BUY
     if Type == 'BUY' then
         operation = "S" -- Тейк-профит и Стоп-лосс на продажу(чтобы закрыть BUY, нужно открыть SELL)
         direction = "5" -- Направленность стоп-цены. «5» - больше или равно
       -- Если не акции
       if TRADE_CLASS_CODE ~= 'QJSIM' and TRADE_CLASS_CODE ~= 'TQBR' then
          price = tostring(math.floor(getParamEx(TRADE_CLASS_CODE, TRADE_SEC_CODE, 'PRICEMIN').param_value)) -- Цена выставляемой заявки после страбатывания Стопа минимально возможная, чтобы не проскользнуло
          market = "YES"  -- После срабатывания Тейка, или Стопа, заявка сработает НЕ по рыночной цене
       end
         if (TakeProfitPrice or 0) == 0 then
             stopprice	= tostring(TRADE_PRICE + TAKE_PROFIT*TRADE_SEC_PRICE_STEP) -- Уровень цены, когда активируется Тейк-профит
             TakeProfitPrice = stopprice
         else
             stopprice = TakeProfitPrice + math.floor(STOP_LOSS*TRADE_SEC_PRICE_STEP/2)    -- немного сдвигаем тейк-профит
         end
         stopprice2	= tostring(TRADE_PRICE - STOP_LOSS*TRADE_SEC_PRICE_STEP) -- Уровень цены, когда активируется Стоп-лосс
         price = stopprice2 - 2*TRADE_SEC_PRICE_STEP 
     else -- открыт SELL
         operation = "B" -- Тейк-профит и Стоп-лосс на покупку(чтобы закрыть SELL, нужно открыть BUY)
         direction = "4" -- Направленность стоп-цены. «4» - меньше или равно
       -- Если не акции
         if TRADE_CLASS_CODE ~= 'QJSIM' and TRADE_CLASS_CODE ~= 'TQBR' then
          price = tostring(math.floor(getParamEx(TRADE_CLASS_CODE, TRADE_SEC_CODE, 'PRICEMAX').param_value)) -- Цена выставляемой заявки после страбатывания Стопа максимально возможная, чтобы не проскользнуло
          market = "YES"  -- После срабатывания Тейка, или Стопа, заявка сработает НЕ по рыночной цене
       end
         if (TakeProfitPrice or 0) == 0 then
             stopprice	= tostring(TRADE_PRICE - TAKE_PROFIT*TRADE_SEC_PRICE_STEP) -- Уровень цены, когда активируется Тейк-профит
             TakeProfitPrice = stopprice
         else
             stopprice = TakeProfitPrice - math.floor(STOP_LOSS*TRADE_SEC_PRICE_STEP/2)  -- немного сдвигаем тейк-профит   
         end
         stopprice2	= tostring(TRADE_PRICE + STOP_LOSS*TRADE_SEC_PRICE_STEP) -- Уровень цены, когда активируется Стоп-лосс
         price = stopprice2 + 2*TRADE_SEC_PRICE_STEP 
     end
     -- Заполняет структуру для отправки транзакции на Стоп-лосс и Тейк-профит
      myLog('Script monitor: Установка ТЕЙК-ПРОФИТ: '..stopprice..' и СТОП-ЛОСС: '..stopprice2)
 
     local Transaction = {
         ["ACTION"]              = "NEW_STOP_ORDER", -- Тип заявки
         ["TRANS_ID"]            = tostring(trans_id),
         ["CLASSCODE"]           = TRADE_CLASS_CODE,
         ["SECCODE"]             = TRADE_SEC_CODE,
         ["ACCOUNT"]             = ACCOUNT,
         ['CLIENT_CODE'] = CLIENT_CODE, -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках 
         ["OPERATION"]           = operation, -- Операция ("B" - покупка(BUY), "S" - продажа(SELL))
         ["QUANTITY"]            = tostring(QTY_LOTS), -- Количество в лотах
         ["PRICE"]               = GetCorrectPrice(price), -- Цена, по которой выставится заявка при срабатывании Стоп-Лосса (для рыночной заявки по акциям должна быть 0)
         ["STOPPRICE"]           = GetCorrectPrice(stopprice), -- Цена Тейк-Профита
         ["STOP_ORDER_KIND"]     = "TAKE_PROFIT_AND_STOP_LIMIT_ORDER", -- Тип стоп-заявки
         ["EXPIRY_DATE"]         = "GTC", -- Срок действия стоп-заявки ("GTC" – до отмены,"TODAY" - до окончания текущей торговой сессии, Дата в формате "ГГММДД")
       -- "OFFSET" - (ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль,
       -- то Тейк-профит сработает только когда цена вернется минимум на 2 шага цены назад,
       -- это может потенциально увеличить прибыль
         ["OFFSET"]              = tostring(2*TRADE_SEC_PRICE_STEP),
         ["OFFSET_UNITS"]        = "PRICE_UNITS", -- Единицы измерения отступа ("PRICE_UNITS" - шаг цены, или "PERCENTS" - проценты)
       -- "SPREAD" - Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на 100 шагов цены,
       -- которая АВТОМАТИЧЕСКИ УДОВЛЕТВОРИТСЯ ПО ТЕКУЩЕЙ ЛУЧШЕЙ ЦЕНЕ,
       -- но то, что цена значительно хуже, спасет от проскальзывания,
       -- иначе, сделка может просто не закрыться (заявка на закрытие будет выставлена, но цена к тому времени ее уже проскочит)
         ["SPREAD"]              = tostring(100*TRADE_SEC_PRICE_STEP),
         ["SPREAD_UNITS"]        = "PRICE_UNITS", -- Единицы измерения защитного спрэда ("PRICE_UNITS" - шаг цены, или "PERCENTS" - проценты)
       -- "MARKET_TAKE_PROFIT" = ("YES", или "NO") должна ли выставится заявка по рыночной цене при срабатывании Тейк-Профита.
       -- Для рынка FORTS рыночные заявки, как правило, запрещены,
       -- для лимитированной заявки на FORTS нужно указывать заведомо худшую цену, чтобы она сработала сразу же, как рыночная
         ["MARKET_TAKE_PROFIT"]  = market,
         ["STOPPRICE2"]          = GetCorrectPrice(stopprice2), -- Цена Стоп-Лосса
         ["IS_ACTIVE_IN_TIME"]   = "NO",
       -- "MARKET_TAKE_PROFIT" = ("YES", или "NO") должна ли выставится заявка по рыночной цене при срабатывании Стоп-Лосса.
       -- Для рынка FORTS рыночные заявки, как правило, запрещены,
       -- для лимитированной заявки на FORTS нужно указывать заведомо худшую цену, чтобы она сработала сразу же, как рыночная
         ["MARKET_STOP_LIMIT"]   = market,
         ['CONDITION'] = direction, -- Направленность стоп-цены. Возможные значения: «4» - меньше или равно, «5» – больше или равно
         ["COMMENT"]             = "Script monitor ТЕЙК-ПРОФИТ и СТОП-ЛОСС"
     }
    -- Отправляет транзакцию на установку ТЕЙК-ПРОФИТ и СТОП-ЛОСС
    local res = sendTransaction(Transaction)
    if string.len(res) ~= 0 then
       message('Script monitor: Установка ТЕЙК-ПРОФИТ и СТОП-ЛОСС не удалась!\nОШИБКА: '..res)
       myLog('Script monitor: Установка ТЕЙК-ПРОФИТ и СТОП-ЛОСС не удалась!\nОШИБКА: '..res)
       return false
    else
       -- Выводит сообщение
       message('Script monitor: ВЫСТАВЛЕНА заявка ТЕЙК-ПРОФИТ и СТОП-ЛОСС: '..trans_id)
      myLog('Script monitor: ВЫСТАВЛЕНА заявка ТЕЙК-ПРОФИТ и СТОП-ЛОСС: '..trans_id)
      return true
    end
     
 end
 
--ordtable = "stop_orders"
--ordtable = "orders"
function KillAllOrders(ordtable, TRADE_CLASS_CODE, TRADE_SEC_CODE)
    function myFind(C,S,F)
       return (C == TRADE_CLASS_CODE) and (S == TRADE_SEC_CODE) and (bit.band(F, 0x1) ~= 0)
    end
    local res=1
    local action = "KILL_ORDER"
    local order_key = "ORDER_KEY"
    if ordtable == "stop_orders" then
        action = "KILL_STOP_ORDER"
        order_key = "STOP_ORDER_KEY"
    end
    local orders = SearchItems(ordtable, 0, getNumberOf(ordtable)-1, myFind, "class_code,sec_code,flags")
    if (orders ~= nil) and (#orders > 0) then
       
        for i=1,#orders do
         -- Получает ID для следующей транзакции
        trans_id = trans_id + 1
        -- Заполняет структуру для отправки транзакции на снятие стоп-заявки
         local Transaction = {
             ["ACTION"]              = action, -- Тип заявки
             ["TRANS_ID"]            = tostring(trans_id),
             ["CLASSCODE"]           = TRADE_CLASS_CODE,
             ["SECCODE"]             = TRADE_SEC_CODE,
             ["ACCOUNT"]             = ACCOUNT,
             ['CLIENT_CODE'] = CLIENT_CODE, -- Комментарий к транзакции, который будет виден в транзакциях, заявках и сделках 
             [order_key]      = tostring(getItem(ordtable,orders[i]).order_num) -- Номер заявки, снимаемой из торговой системы
         }
            -- Отправляет транзакцию
            local Res = sendTransaction(Transaction)
            -- Если при отправке транзакции возникла ошибка
            if string.len(Res) ~= 0 then
               -- Выводит ошибку
               message('Ошибка снятия заявки: '..Res)
               myLog('Ошибка снятия заявки: '..Res)
               return false
            end   
           
           local order = getItem(ordtable, orders[i])		  
           -- Если стоп-заявка не активна
           myLog('прверка заявки: '..order.sec_code..' number: '..tostring(order.order_num))
           if not bit.test(order.flags, 0) then
              -- Если заявка успела исполниться
              if not bit.test(order.flags, 1) then
                 return true
              else
                 message('Возникла неизвестная ошибка при снятии ЗАЯВКИ '..tostring(order.order_num))
                 myLog('Возникла неизвестная ошибка при снятии ЗАЯВКИ '..tostring(order.order_num))
                 return false
              end
           end
        end
    else
        message("Не найдены активные заявки "..TRADE_SEC_CODE)
        myLog("Не найдены активные заявки "..TRADE_SEC_CODE)
    end
       
   return true 
end
 -----------------------------
 -- Алгоритм --
 -----------------------------
function up_downTest(i, cell, settings, DS, signal)
    
    --local testvalue = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value) or 0
	local testvalue = GetCell(t_id, i, tableIndex["Текущая цена"]).value
    local price_step = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value) or 0
    local scale = getSecurityInfo(CLASS_CODE, SEC_CODE).scale
    local signaltestvalue1 = calcAlgoValue[DS:Size()-1] or 0
    local signaltestvalue2 = calcAlgoValue[DS:Size()-2] or 0
    local testZone = settings.testZone or 10

    if calcAlgoValue[DS:Size()] == nil or DS:Size() == 0 then return end
    local calcVal = round(calcAlgoValue[DS:Size()] or 0, scale)

    local testSignalZone = price_step*testZone
    local downTestZone = calcVal-testSignalZone
    local upTestZone = calcVal+testSignalZone

    if INTERVALS["visible"][cell] then
        local Color = RGB(255, 255, 255)
        if testvalue > downTestZone and testvalue < calcVal then
            Color = RGB(255, 220, 220)
        elseif testvalue < upTestZone and testvalue > calcVal then
            Color = RGB(220, 255, 220)
        elseif testvalue < downTestZone then
            Color = RGB(255,168,164)
        elseif testvalue > upTestZone then
            Color = RGB(165,227,128)
        end
        SetCell(t_id, i, tableIndex[cell], tostring(calcVal), calcVal)
        cellSetColor(i, tableIndex[cell], Color, RGB(0,0,0))
    end

    if signal then
        local isMessage = SEC_CODES['isMessage'][i]
        local isPlaySound = SEC_CODES['isPlaySound'][i]
        local mes0 = tostring(SEC_CODES['names'][i]).." timescale "..INTERVALS["names"][cell]
        local mes = ""
        
        if signaltestvalue1 < DS:C(DS:Size()-1) and signaltestvalue2 > DS:C(DS:Size()-2) then
            mes = mes0..": Сигнал Buy"
            myLog(mes)
            --myLog("Значение алгоритма -1 "..tostring(signaltestvalue1).." Закрытие свечи-1 "..DS:C(DS:Size()-1))
            --myLog("Значение алгоритма -2 "..tostring(signaltestvalue2).." Закрытие свечи-2 "..DS:C(DS:Size()-2))
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if signaltestvalue1 > DS:C(DS:Size()-1) and signaltestvalue2 < DS:C(DS:Size()-2) then
            mes = mes0..": Сигнал Sell"
            myLog(mes)
            --myLog("Значение алгоритма -1 "..tostring(signaltestvalue1).." Закрытие свечи-1 "..DS:C(DS:Size()-1))
            --myLog("Значение алгоритма -2 "..tostring(signaltestvalue2).." Закрытие свечи-2 "..DS:C(DS:Size()-2))
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end

        if testvalue < upTestZone and DS:C(DS:Size()-1) > upTestZone then
            mes = mes0..": Цена опустилась к зоне "..tostring(upTestZone)
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if testvalue > downTestZone and DS:C(DS:Size()-1) < downTestZone then
            mes = mes0..": Цена поднялась к зоне "..tostring(downTestZone)
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if testvalue > upTestZone and DS:C(DS:Size()-1) < upTestZone then
            mes = mes0..": Цена оттолкнулась от зоны "..tostring(upTestZone)
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if testvalue < downTestZone and DS:C(DS:Size()-1) > downTestZone then
            mes = mes0..": Цена опустилась от зоны "..tostring(downTestZone)
            myLog(mes)
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
	end

end

function noSignal()
end

function getATR(i, dayIntervalIndex)
    
    local dayDS = nil
    if isDayInterval == false then
        SEC_CODES['dayDS'][i] = CreateDataSource(SEC_CODES['class_codes'][i],SEC_CODES['sec_codes'][i],INTERVAL_D1)
        dayDS = SEC_CODES['dayDS'][i]        
    else
        dayDS = SEC_CODES['DS'][i][dayIntervalIndex]
    end
    local dayATR_Period = SEC_CODES['dayATR_Period'][i]
    local lastATR = round(calcDayATR(dayATR_Period, DS), 5)
    SEC_CODES['dayATR'][i] = lastATR
    --myLog("Day ATR ".. SEC_CODE.." "..tostring(lastATR))
    SetCell(t_id, i, tableIndex["D ATR"], tostring(lastATR), lastATR)  --i строка, 1 - колонка, v - значение
    
    SEC_CODES['D_minus5'][i] = dayDS:C(dayDS:Size()-5)

end

function calcDayATR(dayATR_Period, DS)
    
    local ATR = {}
    local ind = DS:Size() - 200
    ATR[1] = 0
    --myLog("Day ATR ".. SEC_CODE.." DS:Size() ".. tostring(DS:Size()).." ind "..tostring(ind))

    for index = 2, 200 do
        
        ATR[index] = ATR[index-1]
        if DS:C(index+ind) ~= nil then        
            
            if index==dayATR_Period then
                local sum=0
                for i = 1, dayATR_Period do
                    sum = sum + dValue(ind+i)
                end
                ATR[index]=sum / dayATR_Period
            elseif index>dayATR_Period then
                ATR[index]=(ATR[index-1] * (dayATR_Period-1) + dValue(index+ind)) / dayATR_Period
            end
            --myLog("Day ATR ".. SEC_CODE.."index ".. tostring(index+ind)..": "..tostring(lastATR))

        end
    end 

    return ATR[200] or 0
end

function dValue(i)

    local previous = i-1
        
    if DS:C(i) == nil then
        previous = FindExistCandle(previous)
    end

    return math.max(math.abs(DS:H(i) - DS:L(i)), math.abs(DS:H(i) - DS:C(previous)), math.abs(DS:C(previous) - DS:L(i)))
end

 -----------------------------
 -- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ --
 -----------------------------
 function OnDepoLimit(dlimit)
    
    if dlimit.limit_kind~=2 then
        return
    end
 
    for i=1,#SEC_CODES['sec_codes'] do
        if SEC_CODES['sec_codes'][i] == dlimit.sec_code then
            local class_code = SEC_CODES['class_codes'][i]
            local lotsize = tonumber(getParamEx(class_code,dlimit.sec_code,"lotsize").param_value)
            if lotsize == 0 or lotsize == nil then
                lotsize = 1
            end       
            SetCell(t_id, i, tableIndex["Позиция"], tostring(dlimit.currentbal/lotsize), dlimit.currentbal/lotsize)  --i строка, 1 - колонка, v - значение
            local awg_price = GetCorrectPrice(dlimit.awg_position_price, class_code, dlimit.sec_code)
            awg_price = string.gsub(tostring(awg_price),',', '.')
            local last_price = GetCell(t_id, i, tableIndex["Текущая цена"]).value or 0
            if tonumber(awg_price)==0 then
                SetCell(t_id, i, tableIndex["Средняя"], '', 0)  --i строка, 1 - колонка, v - значение
                White(i, tableIndex["Средняя"])
            else
                Str(i, tableIndex["Средняя"], tonumber(awg_price), last_price)  --i строка, 1 - колонка, v - значение
            end    
            if showTradeCommands == true then
                if dlimit.currentbal~=0 then
                    Red(i, tableIndex["Команда CLOSE"])
                    SetCell(t_id, i, tableIndex["Команда CLOSE"], "CLOSE")  --i строка, 0 - колонка, v - значение 
                else
                    White(i, tableIndex["Команда CLOSE"])
                    SetCell(t_id, i, tableIndex["Команда CLOSE"], "")  --i строка, 0 - колонка, v - значение 
                end            
            end            
            break            
        end
    end

 end
 
 function GetTotalnet(class_code, sec_code)
    -- ФЬЮЧЕРСЫ, ОПЦИОНЫ
    local opencount = 0
    local awg_position_price = 0

    if class_code == 'SPBFUT' or class_code == 'SPBOPT' then
       for i = 0,getNumberOf('futures_client_holding') - 1 do
          local futures_client_holding = getItem('futures_client_holding',i)
          if futures_client_holding.sec_code == sec_code then
             opencount = futures_client_holding.totalnet
             awg_position_price = GetCorrectPrice(futures_client_holding.avrposnprice, class_code, futures_client_holding.sec_code)
          end
       end
    -- АКЦИИ
    elseif class_code == 'TQBR' or class_code == 'QJSIM' then
        local lotsize = tonumber(getParamEx(class_code,sec_code,"lotsize").param_value)
        if lotsize == 0 or lotsize == nil then
            lotsize = 1
        end       
        --myLog("sec_code "..sec_code.." class_code "..class_code.." lotsize "..tostring(lotsize))
        for i = 0,getNumberOf('depo_limits') - 1 do
          local depo_limit = getItem("depo_limits", i)
          --myLog("trdaccid "..depo_limit.trdaccid.." sec_code "..depo_limit.sec_code.." limit kind "..tostring(depo_limit.limit_kind).." pos: "..tostring(depo_limit.currentbal))
          if depo_limit.sec_code == sec_code
          and depo_limit.trdaccid == ACCOUNT
          and depo_limit.limit_kind == 2 then  -- T+2       
            opencount = depo_limit.currentbal/lotsize
            awg_position_price = GetCorrectPrice(depo_limit.awg_position_price, class_code, sec_code)
          end
       end
    end
    awg_position_price = string.gsub(tostring(awg_position_price),',', '.')
    --myLog("awg_position_price "..tostring(awg_position_price))
    --myLog("sec_code "..sec_code.." class_code "..class_code.." pos: "..tostring(opencount))

    -- Если позиция по инструменту в таблице не найдена, возвращает 0
    return opencount, awg_position_price
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

-- функция записывает в лог строчку с временем и датой 
function myLog(str)
    if logFile==nil then return end

    local current_time=os.time()--tonumber(timeformat(getInfoParam("SERVERTIME"))) -- помещене в переменную времени сервера в формате HHMMSS 
    if (current_time-g_previous_time)>1 then -- если текущая запись произошла позже 1 секунды, чем предыдущая
        logFile:write("\n") -- добавляем пустую строку для удобства чтения
    end
    g_previous_time = current_time 

    logFile:write(os.date().."; ".. str .. ";\n")

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

-- Получает точность цены по инструменту
function GetCorrectPrice(price, TRADE_CLASS_CODE, TRADE_SEC_CODE) -- STRING

    local scale = getSecurityInfo(TRADE_CLASS_CODE, TRADE_SEC_CODE).scale
    -- Получает минимальный шаг цены инструмента
    local PriceStep = tonumber(getParamEx(TRADE_CLASS_CODE, TRADE_SEC_CODE, "SEC_PRICE_STEP").param_value)
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
            --message(TRADE_SEC_CODE.." price step "..PriceStep.." scale: "..tostring(scale).." price old: "..tostring(price))
            -- Корректирует на соответствие шагу цены
            price = price - price % PriceStep
            --message("price new: "..tostring(price))
            --price = string.gsub(tostring(price),'[\.]+', ',')
            return price
        end
    else -- После запятой не должно быть цифр
        -- Корректирует на соответствие шагу цены
        price = price - price % PriceStep
        return tostring(math.floor(price))
    end
end

function PaySoundFile(file_name)
    w32.mciSendString("CLOSE QUIK_MP3") 
    w32.mciSendString("OPEN \"" .. file_name .. "\" TYPE MpegVideo ALIAS QUIK_MP3")
    w32.mciSendString("PLAY QUIK_MP3")
end

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
