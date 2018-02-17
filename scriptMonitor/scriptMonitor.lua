local w32 = require("w32")

ACCOUNT           = 'Ваш номер счета'        -- Идентификатор счета
--ACCOUNT           = 'NL0011100043'        -- Идентификатор счета для примера
CLIENT_CODE = 'Ваш клиентский код'

CLASS_CODE        = '' --класс в файле настроек
--CLASS_CODE        = 'TQBR'              -- Код класса
--CLASS_CODE        = 'SPBFUT'             -- Код класса
--CLASS_CODE        = 'QJSIM'  
SEC_CODE = '' -- бумаги в файле настроек
SEC_CODES = {}

INTERVAL = 15
INTERVALS={{"M15", "H1", "H4", "D"}, {INTERVAL_M15, INTERVAL_H1, INTERVAL_H4, INTERVAL_D1}} -- интервалы

-- настройки алгоритма
Length    = 29                   -- ПЕРИОД        
Kv = 1                    -- коэффициент
StepSize = 0                  -- шаг
Percentage = 0
Switch = 1 --1 - HighLow, 2 - CloseClose
cache_NRTR={}
ATR = {}
smax1={}
smin1={}
trend={} 
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
    
--/*РАБОЧИЕ ПЕРЕМЕННЫЕ РОБОТА (менять не нужно)*/
IsRun = true -- Флаг поддержания работы скрипта

FILE_LOG_NAME = getWorkingFolder().."\\RobotLogs\\scriptMonitorLog.txt" -- ИМЯ ЛОГ-ФАЙЛА
PARAMS_FILE_NAME = getWorkingFolder().."\\RobotParams\\scriptMonitor.csv" -- ИМЯ ЛОГ-ФАЙЛА
trans_id          = os.time()            -- Задает начальный номер ID транзакций
trans_Status      = nil                  -- Статус текущей транзакции из функции OnTransPeply
trans_result_msg  = ''                   -- Сообщение по текущей транзакции из функции OnTransPeply

SEC_PRICE_STEP    = 0                    -- ШАГ ЦЕНЫ ИНСТРУМЕНТА
DS                = nil                  -- Источник данных графика (DataSource)
g_previous_time = os.time() -- помещение в переменную времени сервера в формате HHMMSS 

SEC_CODE_INDEX = {} -- last interval index
SEC_CODE_NRTR = {} -- last NRTR value
SEC_CODE_ATR = {} -- last ATR value
 -----------------------------
 -- Основные функции --
 -----------------------------
-- Функция первичной инициализации скрипта (ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK в самом начале)
function OnInit()

    logFile = io.open(FILE_LOG_NAME, "w") -- открывает файл 
    
    local ParamsFile = io.open(PARAMS_FILE_NAME,"r")
    if ParamsFile == nil then
        IsRun = false
        message("Не удалость прочитать файл настроек!!!")
        return false
    end

    SEC_CODES[1] = {} -- имена бумаг
    SEC_CODES[2] = {} -- коды бцмаг
    SEC_CODES[3] = {} -- выводить сообщения
    SEC_CODES[4] = {} -- проигрывать звук
    SEC_CODES[5] = {} -- рабочий объем
    SEC_CODES[6] = {} -- CLASS_CODE
    SEC_CODES[7] = {} -- признак заказа данных
    --SEC_CODES[8] = {} -- признак произведенного расчета

    myLog("Читаем файл параметров")
    local lineCount = 0
    for line in ParamsFile:lines() do
        myLog("Строка параметров "..line)
        lineCount = lineCount + 1
        if lineCount > 1 and line ~= "" then
            local per1, per2, per3, per4, per5, per6 = line:match("%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*)")
            SEC_CODES[1][lineCount-1] = per2
            SEC_CODES[2][lineCount-1] = per3
            SEC_CODES[3][lineCount-1] = tonumber(per4) 
            SEC_CODES[4][lineCount-1] = tonumber(per5) 
            SEC_CODES[5][lineCount-1] = tonumber(per6) 
            SEC_CODES[6][lineCount-1] = per1 
            SEC_CODES[7][lineCount-1] = false 
            --SEC_CODES[8][lineCount-1] = {} 
        end
    end

    ParamsFile:close()

    myLog("Intervals "..tostring(#INTERVALS[1]))
    myLog("Sec codes "..tostring(#SEC_CODES[2]))
    CreateTable() -- Создает таблицу

    for i,SEC_CODE in ipairs(SEC_CODES[2]) do      
                   
        SEC_CODE_INDEX[i] = {}
        SEC_CODE_NRTR[i] = {}
        SEC_CODE_ATR[i] = {}
        
        CLASS_CODE =SEC_CODES[6][i]

        myLog("================================================")
        SEC_PRICE_STEP = getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value
        local last_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)
        SetCell(t_id, i, 1, tostring(last_price), last_price)  --i строка, 1 - колонка, v - значение
        local lastchange = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"lastchange").param_value)
        Str(i, 2, lastchange, 0, 0)  --i строка, 1 - колонка, v - значение
        local open_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"prevprice").param_value)
        SetCell(t_id, i, 3, tostring(open_price), open_price)  --i строка, 1 - колонка, v - значение
        local delta = round(last_price-open_price,5)
        SetCell(t_id, i, 4, tostring(delta), delta)  --i строка, 1 - колонка, v - значение
        local openCount = GetTotalnet()        
        SetCell(t_id, i, 6, tostring(openCount), openCount)  --i строка, 1 - колонка, v - значение
        --Команды
        SetCell(t_id, i, #INTERVALS[1]+8, "-")  --i строка, 1 - колонка, v - значение
        SetCell(t_id, i, #INTERVALS[1]+9, tostring(SEC_CODES[5][i]), SEC_CODES[5][i])  --i строка, 1 - колонка, v - значение
        SetCell(t_id, i, #INTERVALS[1]+10, "+")  --i строка, 1 - колонка, v - значение
        SetCell(t_id, i, #INTERVALS[1]+11, "BUY")  --i строка, 1 - колонка, v - значение
        Green(i, #INTERVALS[1]+11)
        SetCell(t_id, i, #INTERVALS[1]+12, "SELL")  --i строка, 1 - колонка, v - значение
        Red(i, #INTERVALS[1]+12)
        if openCount~=0 then 
            command = ""
            Red(i, #INTERVALS[1]+12)
            SetCell(t_id, i, #INTERVALS[1]+13, "CLOSE")  --i строка, 0 - колонка, v - значение 
        end
        myLog("lastchange ".. SEC_CODE.." "..tostring(lastchange))
        myLog("open_price ".. SEC_CODE.." "..tostring(open_price))
        myLog("delta ".. SEC_CODE.." "..tostring(delta))
        myLog("openCount ".. SEC_CODE.." "..tostring(openCount))

        for cell,INTERVAL in pairs(INTERVALS[2]) do                    
            local Error = ''
            DS,Error = CreateDataSource(CLASS_CODE, SEC_CODE, INTERVAL)
            -- Проверка
            if DS == nil then
                message('NRTR monitor: ОШИБКА получения доступа к свечам! '..Error)
                myLog('NRTR monitor: ОШИБКА получения доступа к свечам! '..Error)
                -- Завершает выполнение скрипта
                IsRun = false
                return
            end
            if DS:Size() == 0 then 
                DS:SetEmptyCallback()
                sleep(200)
                SEC_CODES[7][i] = true
                --DS = CreateDataSource(CLASS_CODE, SEC_CODE, INTERVAL)
            end

            SEC_CODE_INDEX[i][cell] = DS:Size()
            --SEC_CODES[8][i][cell] = false
            
            --NRTR
            myLog("Всего свечей ".. SEC_CODE..", интервала "..INTERVALS[1][cell].." "..SEC_CODE_INDEX[i][cell])
            -- расчет параметров для каждого интервала
            for ind = DS:Size()-1000, DS:Size() do
                cached_NRTR(ind)
            end

            SEC_CODE_NRTR[i][cell] = cache_NRTR[DS:Size()]
            myLog("NRTR ".. SEC_CODE..", интервала "..INTERVALS[1][cell].." "..SEC_CODE_NRTR[i][cell])

            Str(i, cell+6, cache_NRTR[DS:Size()], last_price)
            
            --ATR
            if INTERVAL == INTERVAL_D1 then
                SEC_CODE_ATR[i][cell] = round(ATR[DS:Size()], 5)
                myLog("Day ATR ".. SEC_CODE.." "..SEC_CODE_ATR[i][cell])
                SetCell(t_id, i, 5, tostring(SEC_CODE_ATR[i][cell]), SEC_CODE_ATR[i][cell])  --i строка, 1 - колонка, v - значение
            end

        end
    end

    myLog("================================================")
    myLog("Initialization finished")

end 
 
function main() -- Функция, реализующая основной поток выполнения в скрипте
    
    SetTableNotificationCallback(t_id, event_callback)
    SetTableNotificationCallback(tv_id, volume_event_callback)
    
    while IsRun do -- Цикл будет выполнятся, пока IsRun == true 
        
        for i,v in ipairs(SEC_CODES[2]) do      
            
            SEC_CODE = v
            CLASS_CODE =SEC_CODES[6][i]

            -- Получает ШАГ ЦЕНЫ ИНСТРУМЕНТА, последнюю цену, открытые позиции
            SEC_PRICE_STEP = getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value
            local last_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value)
            SetCell(t_id, i, 1, tostring(last_price), last_price)  --i строка, 1 - колонка, v - значение
            local lastchange = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"lastchange").param_value)
            Str(i, 2, lastchange, 0, 0)  --i строка, 1 - колонка, v - значение
            local open_price = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"prevprice").param_value)
            SetCell(t_id, i, 3, tostring(open_price), open_price)  --i строка, 1 - колонка, v - значение
            local delta = round(last_price-open_price,5)
            SetCell(t_id, i, 4, tostring(delta), delta)  --i строка, 1 - колонка, v - значение
            local openCount = GetTotalnet()        
            --local openCount = 0        
            SetCell(t_id, i, 6, tostring(openCount), openCount)  --i строка, 1 - колонка, v - значение
            if openCount~=0 then
                command = ""
                Red(i, #INTERVALS[1]+13)
                SetCell(t_id, i, #INTERVALS[1]+13, "CLOSE")  --i строка, 0 - колонка, v - значение 
            end
                   
            ss = getInfoParam("SERVERTIME")
            for cell,INTERVAL in pairs(INTERVALS[2]) do                    
                
                Str(i, cell+6, SEC_CODE_NRTR[i][cell], last_price)
                if INTERVAL == INTERVAL_D1 then
                    SetCell(t_id, i, 5, tostring(SEC_CODE_ATR[i][cell]), SEC_CODE_ATR[i][cell])  --i строка, 1 - колонка, v - значение
                    if SEC_CODE_ATR[i][cell]<math.abs(delta) then
                        Red(i, 5)
                    end
                end
                
                --проверим, что заказанные данные пришли
                if SEC_CODES[7][i] == true then 
                    myLog("Нет данных по "..SEC_CODE.." за интервал "..INTERVALS[1][cell]..". Заказываем на сервере")
                    DS,Error = CreateDataSource(CLASS_CODE, SEC_CODE, INTERVAL)
                    -- Проверка
                    if DS == nil then
                        message('NRTR monitor: ОШИБКА получения доступа к свечам! '..Error)
                        myLog('NRTR monitor: ОШИБКА получения доступа к свечам! '..Error)
                        -- Завершает выполнение скрипта
                        IsRun = false
                        return
                    end

                    SEC_CODES[7][i] = DS:Size() == 0                               
                end    

                if string.len(ss) >= 5 then
                    hh = mysplit(ss,":")
                    str=hh[1]..hh[2] 
                    if (hh[2] == "00" or hh[2] == "15" or hh[2] == "30" or hh[2] == "45") then -- every 15 minutes SEC_CODES[8][i][cell] == false and
                        
                        local Error = ''
                        DS,Error = CreateDataSource(CLASS_CODE, SEC_CODE, INTERVAL)
                        -- Проверка
                        if DS == nil then
                            message('NRTR monitor: ОШИБКА получения доступа к свечам! '..Error)
                            myLog('NRTR monitor: ОШИБКА получения доступа к свечам! '..Error)
                            -- Завершает выполнение скрипта
                            IsRun = false
                            return
                        end

                        if DS:Size() == 0 then 
                            DS:SetEmptyCallback()
                            sleep(200)
                            --DS = CreateDataSource(CLASS_CODE, SEC_CODE, INTERVAL)
                        end
                                    
                        if SEC_CODE_INDEX[i][cell]<DS:Size() then --new candle
                            
                            myLog(SEC_CODE.." - Перерасчет данных за интервал "..INTERVALS[1][cell])
                            SEC_CODE_INDEX[i][cell] = DS:Size() --last candle               
                            --NRTR
                            -- расчет параметров для каждого интервала
                            for ind = DS:Size()-1000, DS:Size() do
                                cached_NRTR(ind)
                            end
                            SEC_CODE_NRTR[i][cell] = cache_NRTR[DS:Size()]
                            Str(i, cell+6, cache_NRTR[DS:Size()], last_price)
                            --ATR
                            if INTERVAL == INTERVAL_D1 then
                                SEC_CODE_ATR[i][cell] = round(ATR[DS:Size()], 5)
                                SetCell(t_id, i, 5, tostring(SEC_CODE_ATR[i][cell]), SEC_CODE_ATR[i][cell])  --i строка, 1 - колонка, v - значение
                            end
                            
                            local isMessage = SEC_CODES[3][i]
                            local isPlaySound = SEC_CODES[4][i]
                            
                            if cache_NRTR[DS:Size()-1] < DS:C(DS:Size()-1) and cache_NRTR[DS:Size()-2] > DS:C(DS:Size()-2) and isMessage == true then
                                myLog("Сигнал Buy "..tostring(SEC_CODES[1][i]).." timescale "..INTERVALS[1][cell])
                                if isMessage == true then message("Сигнал Buy "..tostring(SEC_CODES[1][i]).." timescale "..INTERVALS[1][cell]) end
                                if isPlaySound == 1 then PaySoundFile("c:\\windows\\media\\Alarm03.wav") end
                            end
                    
                            if cache_NRTR[DS:Size()-1] > DS:C(DS:Size()-1) and cache_NRTR[DS:Size()-2] < DS:C(DS:Size()-2) and isMessage == true then
                                myLog("Сигнал Sell "..tostring(SEC_CODE).." timescale "..INTERVALS[1][cell])
                                if isMessage == true then message("Сигнал Sell "..tostring(SEC_CODE).." timescale "..INTERVALS[1][cell]) end
                                if isPlaySound == 1 then PaySoundFile("c:\\windows\\media\\Alarm03.wav") end
                            end
                                                
                        end
                    end
                end
            end  
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
   if logFile~=nil then logFile:close() end    -- Закрывает файл 
 end

 -----------------------------
 -- РАБОТА С ТАБЛИЦЕЙ --
 -----------------------------

 function CreateTable() -- Функция создает таблицу
    t_id = AllocTable() -- Получает доступный id для создания
    -- Добавляет колонки
    AddColumn(t_id, 0, "Инструмент", true, QTABLE_STRING_TYPE, 25)
    AddColumn(t_id, 1, "Цена", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 2, "%", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 3, "Открытие", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 4, "Дельта", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 5, "D ATR", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 6, "Позиция", true, QTABLE_INT_TYPE, 15)
    for i,v in ipairs(INTERVALS[1]) do
        AddColumn(t_id, i+6, v, true, QTABLE_DOUBLE_TYPE, 20)
    end
    AddColumn(t_id, #INTERVALS[1]+7, "Цена", true, QTABLE_STRING_TYPE, 15) --Price
    AddColumn(t_id, #INTERVALS[1]+8, "<", true, QTABLE_STRING_TYPE, 5) --Decrease volume
    AddColumn(t_id, #INTERVALS[1]+9, "Vol", true, QTABLE_INT_TYPE, 10) --Increase volume
    AddColumn(t_id, #INTERVALS[1]+10, ">", true, QTABLE_STRING_TYPE, 5) --Volume
    AddColumn(t_id, #INTERVALS[1]+11, "Команда", true, QTABLE_STRING_TYPE, 15) --BUY
    AddColumn(t_id, #INTERVALS[1]+12, "Команда", true, QTABLE_STRING_TYPE, 15) --SELL
    AddColumn(t_id, #INTERVALS[1]+13, "Команда", true, QTABLE_STRING_TYPE, 20) --CLOSE ALL
    t = CreateWindow(t_id) -- Создает таблицу
    SetWindowCaption(t_id, "NRTR Monitor") -- Устанавливает заголовок
    SetWindowPos(t_id, 190, 160, 1450, 800) -- Задает положение и размеры окна таблицы
    
    -- Добавляет строки
    for i,v in ipairs(SEC_CODES[1]) do
        InsertRow(t_id, i)
        SetCell(t_id, i, 0, v)  --i строка, 0 - колонка, v - значение 
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
 
 -----------------------------
 -- Обработка команд таблицы --
 ----------------------------- 
function volume_event_callback(tv_id, msg, par1, par2)
    if par1 == -1 then
        return
    end
    if msg == QTABLE_CHAR then
        if tostring(par2) == "8" then
           SetCell(tv_id, par1, 0, "")
           SetCell(t_id, tstr, tcell, GetCell(tv_id, par1, 0).image, 0)
       else
           local inpChar = string.char(par2)
           local newPrice = GetCell(tv_id, par1, 0).image..string.char(par2)            
           SetCell(tv_id, par1, 0, tostring(newPrice))
           SetCell(t_id, tstr, tcell, GetCell(tv_id, par1, 0).image, tonumber(GetCell(tv_id, par1, 0).image))
       end
    end
end

function event_callback(t_id, msg, par1, par2)

    if msg == QTABLE_LBUTTONDBLCLK then

        if par2 == 1 or par2 == 3 or (par2 > 6 and par2 <= #INTERVALS[1]+6) then --Берем цену
            local newPrice = GetCell(t_id, par1, par2).value
            SetCell(t_id, par1, #INTERVALS[1]+7, tostring(newPrice), newPrice)  --i строка, 1 - колонка, v - значение            
        end
        if par2 == #INTERVALS[1]+7 and IsWindowClosed(tv_id) then --Вводим цену
            tstr = par1
            tcell = par2
            AddColumn(tv_id, 0, "Значение", true, QTABLE_STRING_TYPE, 25)
            tv = CreateWindow(tv_id) 
            SetWindowCaption(tv_id, "Введите цену") 
            SetWindowPos(tv_id, 290, 260, 250, 100)                                
            InsertRow(tv_id, 1)
            SetCell(tv_id, 1, 0, GetCell(t_id, par1, #INTERVALS[1]+7).image)  --i строка, 0 - колонка, v - значение 
        end
        if par2 == #INTERVALS[1]+9 and IsWindowClosed(tv_id) then --Вводим объем
            tstr = par1
            tcell = par2
            AddColumn(tv_id, 0, "Значение", true, QTABLE_STRING_TYPE, 25)
            tv = CreateWindow(tv_id) 
            SetWindowCaption(tv_id, "Введите объем")
            SetWindowPos(tv_id, 290, 260, 250, 100)                                
            InsertRow(tv_id, 1)
            SetCell(tv_id, 1, 0, GetCell(t_id, par1, #INTERVALS[1]+9).image)  --i строка, 0 - колонка, v - значение 
        end
        if par2 == #INTERVALS[1]+13 then -- All Close
            local TRADE_SEC_CODE = SEC_CODES[2][par1]
            local TRADE_CLASS_CODE = SEC_CODES[6][par1]
            opencount = GetCell(t_id, par1, 6).value
            if opencount ~=0 then 
                local CurrentDirect = 'Sell'
                local QTY_LOTS = opencount
                message(TRADE_SEC_CODE.." "..CurrentDirect.." count "..tostring(QTY_LOTS))
                MakeTransaction(CurrentDirect, QTY_LOTS, 0, TRADE_CLASS_CODE, TRADE_SEC_CODE)
            end
        end
        if par2 == #INTERVALS[1]+11 then --BUY volume
            local TRADE_SEC_CODE = SEC_CODES[2][par1]
            local TRADE_CLASS_CODE = SEC_CODES[6][par1]
            local CurrentDirect = 'BUY'
            local QTY_LOTS = GetCell(t_id, par1, #INTERVALS[1]+9).value
            local TRADE_PRICE = tonumber(GetCell(t_id, par1, #INTERVALS[1]+7).image)
            message(TRADE_SEC_CODE.." "..CurrentDirect.." count "..tostring(QTY_LOTS))
            MakeTransaction(CurrentDirect, QTY_LOTS, TRADE_PRICE, TRADE_CLASS_CODE, TRADE_SEC_CODE)
        end
        if par2 == #INTERVALS[1]+12 then --SELL volume
            local TRADE_SEC_CODE = SEC_CODES[2][par1]
            local TRADE_CLASS_CODE = SEC_CODES[6][par1]
            local CurrentDirect = 'SELL'
            local QTY_LOTS = GetCell(t_id, par1, #INTERVALS[1]+9).value
            local TRADE_PRICE = tonumber(GetCell(t_id, par1, #INTERVALS[1]+7).image)
            message(TRADE_SEC_CODE.." "..CurrentDirect.." count "..tostring(QTY_LOTS))
            MakeTransaction(CurrentDirect, QTY_LOTS, TRADE_PRICE, TRADE_CLASS_CODE, TRADE_SEC_CODE)
        end
        if par2 == #INTERVALS[1]+8 then
            local newVolume = GetCell(t_id, par1, #INTERVALS[1]+9).value - SEC_CODES[5][par1]
            SetCell(t_id, par1, #INTERVALS[1]+9, tostring(newVolume), newVolume)  --i строка, 1 - колонка, v - значение            
        end
        if par2 == #INTERVALS[1]+10 then
            local newVolume = GetCell(t_id, par1, #INTERVALS[1]+9).value + SEC_CODES[5][par1]
            SetCell(t_id, par1, #INTERVALS[1]+9, tostring(newVolume), newVolume)  --i строка, 1 - колонка, v - значение            
        end
    end
    if msg == QTABLE_CHAR then
        if tostring(par2) == "8" then
           SetCell(t_id, par1, #INTERVALS[1]+7, "")
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
       myLog("OnTransReply "..tostring(trans_id).." "..trans_result_msg)
  end
end

function MakeTransaction(CurrentDirect, QTY_LOTS, TRADE_PRICE, TRADE_CLASS_CODE, TRADE_SEC_CODE)
    
    return Trade(CurrentDirect, QTY_LOTS, TRADE_PRICE, TRADE_CLASS_CODE ,TRADE_SEC_CODE)
    --Пока без попыток. Ошибки при медленном ответе сервера.
    --[[local Price = false -- Переменная для получения результата открытия позиции (цена, либо ошибка(false))
    for i=1,10 do
       if not IsRun then return end -- Если скрипт останавливается, не затягивает процесс
        -- Совершает СДЕЛКУ указанного типа ["BUY", или "SELL"] по рыночной(текущей) цене размером в QTY_LOTS лот,
       --- возвращает цену открытой сделки, либо FALSE, если невозможно открыть сделку
       Price = Trade(CurrentDirect, QTY_LOTS, TRADE_SEC_CODE)
       -- Если сделка открылась
       if Price ~= false then
          -- Прерывает цикл FOR
          break
       end
       sleep(100) -- Пауза в 100 мс между попытками открыть сделку
    end]]--

end
-- Совершает СДЕЛКУ указанного типа (Type) ["BUY", или "SELL"] по рыночной(текущей) цене размером в 1 лот,
--- возвращает цену открытой сделки, либо FALSE, если невозможно открыть сделку
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
    TRADE_PRICE = GetCorrectPrice(TRADE_PRICE, TRADE_CLASS_CODE, TRADE_SEC_CODE)
    myLog("NRTR robot: "..TRADE_TYPE.." Transaction "..Type..' '..TRADE_PRICE)
 
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
        message('NRTR monitor: Транзакция вернула ошибку: '..res)
        myLog('NRTR monitor: Транзакция вернула ошибку: '..res)
        return false
     end
  
    -- Ждет, пока получит статус текущей транзакции (переменные "trans_Status" и "trans_result_msg" заполняются в функции OnTransReply())
    --while IsRun and (trans_Status == nil or trans_Status < 2) do sleep(1) end
    sleep(100)

    -- Запоминает значение
    local Status = trans_Status or 3
    --myLog("Tran status "..tostring(trans_Status))
    -- Очищает глобальную переменную
    trans_Status = nil

    if Status == 2 then
        message("Ошибка при передаче транзакции в торговую систему. Так как отсутствует подключение шлюза Московской Биржи, повторно транзакция не отправляется")
        myLog("Ошибка при передаче транзакции в торговую систему. Так как отсутствует подключение шлюза Московской Биржи, повторно транзакция не отправляется")
        return false
    end

    if Status > 3 then
        if Status == 4 then messageText = "Транзакция не исполнена" end
        if Status == 5 then messageText = "Транзакция не прошла проверку сервера QUIK" end
        if Status == 6 then messageText = "Транзакция не прошла проверку лимитов сервера QUIK" end
        if Status == 7 then messageText = "Транзакция не поддерживается торговой системой" end
        message('NRTR monitor: Транзакция вернула ошибку: '..messageText)
        myLog('NRTR monitor: Транзакция вернула ошибку: '..messageText)
        return false
    end

     return true

    --[[
    -- Если транзакция не выполнена по какой-то причине
    if Status ~= 3 then
       -- Если данный инструмент запрещен для операции шорт
       if Status == 6 then
          -- Выводит сообщение
          myLog("NRTR monitor: Данный инструмент запрещен для операции шорт!")
       else
          -- Выводит сообщение с ошибкой
          message('NRTR monitor: Транзакция не прошла!\nОШИБКА: '..trans_result_msg)
          myLog("NRTR monitor: Транзакция не прошла!\nОШИБКА: "..trans_result_msg)
       end
       -- Возвращает FALSE
       return false
    else --Транзакция отправлена
       local OrderNum = nil
       --ЖДЕТ пока ЗАЯВКА на ОТКРЫТИЕ сделки будет ИСПОЛНЕНА полностью
       --Запоминает время начала в секундах
       local BeginTime = os.time()
       while IsRun and OrderNum == nil do
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
          if os.time() - BeginTime > 9 then
             -- Выводит сообщение с ошибкой
             message('NRTR monitor: Прошло 10 секунд, а заявка не исполнена, значит произошла ошибка')
             myLog("NRTR monitor: Прошло 10 секунд, а заявка не исполнена, значит произошла ошибка")
            -- Возвращает FALSE
             return false
          end
          sleep(10) -- Пауза 10 мс, чтобы не перегружать процессор компьютера
       end
 
       --ЖДЕТ пока СДЕЛКА ОТКРЫТИЯ позиции будет СОВЕРШЕНА
       --Запоминает время начала в секундах
       BeginTime = os.time()
       while IsRun do
          --Перебирает ТАБЛИЦУ СДЕЛОК
          for i=0,getNumberOf('trades')-1 do
             local trade = getItem('trades', i)
             --Если сделка по текущей заявке
             if trade.order_num == OrderNum then
                --Возвращает фАКТИЧЕСКУЮ ЦЕНУ открытой сделки
                return trade.price
             end
          end
          --Если прошло 10 секунд, а сделка не совершена, значит на демо-счете произошла ошибка
          if os.time() - BeginTime > 9 then
             -- Выводит сообщение с ошибкой
             message('NRTR monitor: Прошло 10 секунд, а сделка не совершена, значит на счете произошла ошибка')
             myLog("NRTR monitor: Прошло 10 секунд, а сделка не совершена, значит на счете произошла ошибка")
             -- Возвращает FALSE
             return false
          end
          sleep(10) -- Пауза 10 мс, чтобы не перегружать процессор компьютера
       end
    end
    ]]--
 end

 -----------------------------
 -- Алгоритм --
 -----------------------------
function cached_NRTR(index)
									
    local ratio=Percentage/100.0*SEC_PRICE_STEP	
    if index == nil then index = DS:Size()-1000 end
                            
    if index == DS:Size()-1000 then
        cache_NRTR = {}
        cache_NRTR[index] = 0			
        ATR = {}
        ATR[index] = 0			
        smax1 = {}
        smin1 = {}
        trend = {}
        smax1[index] = 0
        smin1[index] = 0
        trend[index] = 1
        return nil
    end
    
    cache_NRTR[index] = cache_NRTR[index-1] 
    ATR[index] = ATR[index-1] 
    smax1[index] = smax1[index-1] 
    smin1[index] = smin1[index-1] 
    trend[index] = trend[index-1] 
    
    if DS:C(index) == nil then
        return nil
    end

    if index<Length then
        ATR[index] = 0
    elseif index==Length then
        local sum=0
        for i = 1, Length do
            sum = sum + dValue(i)
        end
        ATR[index]=sum / Length
    elseif index>Length then
        ATR[index]=(ATR[index-1] * (Length-1) + dValue(index)) / Length
    end
    
    if index <= (Length + 3) then
        return nil
    end
    
    --myLog("---------------------------------")
    --myLog("index "..tostring(index))
    --myLog("DS:C(index) "..tostring(DS:C(index)))
    --myLog("DS:H(index) "..tostring(DS:H(index)))
    --myLog("DS:L(index) "..tostring(DS:L(index)))

    local Step=StepSizeCalc(Length,Kv,StepSize,Switch,index)
    --myLog("Step "..tostring(Step))
    if Step == 0 then Step = 1 end
    
    local SizeP=Step*SEC_PRICE_STEP
    local Size2P=2*SizeP
    
    --myLog("Step "..tostring(Step))
    
    local result		
    local previous = index-1
    
    if DS:C(index) == nil then
        previous = FindExistCandle(previous)
    end
    
    if Switch == 1 then     
        smax0=DS:L(previous)+Size2P
        smin0=DS:H(previous)-Size2P    
    else   
        smax0=DS:C(previous)+Size2P
        smin0=DS:C(previous)-Size2P
    end
    
    --myLog("smax0 "..tostring(smax0))
    --myLog("smin0 "..tostring(smin0))
    --myLog("smax1[index] "..tostring(smax1[index]))
    --myLog("smin1[index] "..tostring(smin1[index]))

    if DS:C(index)>smax1[index] then trend[index] = 1 end
    if DS:C(index)<smin1[index] then trend[index]= -1 end

    if trend[index]>0 then
        if smin0<smin1[index] then smin0=smin1[index] end
        result=smin0+SizeP
    else
        if smax0>smax1[index] then smax0=smax1[index] end
        result=smax0-SizeP
    end
         
    smax1[index] = smax0
    smin1[index] = smin0
    
    if trend[index]>0 then
        cache_NRTR[index]=(result+ratio/Step)-Step*SEC_PRICE_STEP
    end
    if trend[index]<0 then
        cache_NRTR[index]=(result+ratio/Step)+Step*SEC_PRICE_STEP		
    end	
            
    --myLog("cache_NRTR[index] "..tostring(cache_NRTR[index]))
    return cache_NRTR[index] 
    
end

function dValue(i)

    local previous = i-1
        
    if DS:C(i) == nil then
        previous = FindExistCandle(previous)
    end

    return math.max(math.abs(DS:H(i) - DS:L(i)), math.abs(DS:H(i) - DS:C(previous)), math.abs(DS:C(previous) - DS:L(i)))
end

function StepSizeCalc(Len, Km, Size, Switch, index)

    local result

    if Size == 0 then
        
        local Range=0.0
        local ATRmax=-1000000
        local ATRmin=1000000

        for iii=1, Len do	
            --myLog("DS:C(index-iii) "..tostring(DS:C(index-iii)))
            if DS:C(index-iii) ~= nil then				
                if Switch == 1 then     
                    Range=DS:H(index-iii)-DS:L(index-iii)
                else   
                    Range=math.abs(DS:O(index-iii)-DS:C(index-iii))
                end
                if Range>ATRmax then ATRmax=Range end
                if Range<ATRmin then ATRmin=Range end
                --myLog("Range "..tostring(Range))
                --myLog("ATRmax "..tostring(ATRmax))
                --myLog("ATRmin "..tostring(ATRmin))
            end
        end
        result = round(0.5*Km*(ATRmax+ATRmin)/SEC_PRICE_STEP, nil)
        
    else result=Km*Size
    end

    return result
end

 -----------------------------
 -- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ --
 -----------------------------
 
 function GetTotalnet()
    -- ФЬЮЧЕРСЫ, ОПЦИОНЫ

    if CLASS_CODE == 'SPBFUT' or CLASS_CODE == 'SPBOPT' then
       for i = 0,getNumberOf('futures_client_holding') - 1 do
          local futures_client_holding = getItem('futures_client_holding',i)
          if futures_client_holding.sec_code == SEC_CODE then
             return futures_client_holding.totalnet
          end
       end
    -- АКЦИИ
    elseif CLASS_CODE == 'TQBR' or CLASS_CODE == 'QJSIM' then
        local lotsize = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"lotsize").param_value)
        if lotsize == 0 or lotsize == nil then
            lotsize = 1
        end       
        --myLog("======================================")
        for i = 0,getNumberOf('depo_limits') - 1 do
          local depo_limit = getItem("depo_limits", i)
          --myLog("depo_limit.sec_code "..depo_limit.sec_code.." "..tostring(depo_limit.limit_kind).." "..tostring(depo_limit.currentbal))
          if depo_limit.sec_code == SEC_CODE
          and depo_limit.trdaccid == ACCOUNT
          and depo_limit.limit_kind == 2 then  -- T+2       
             return depo_limit.currentbal/lotsize
          end
       end
    end
  
    -- Если позиция по инструменту в таблице не найдена, возвращает 0
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
