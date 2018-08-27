-- nick-h@yandex.ru
-- Glukk Inc ©

--local w32 = require("w32")
require("StaticVar")

dofile (getScriptPath().."\\testNRTR.lua") --stepNRTR алгоритм
dofile (getScriptPath().."\\testTHV_HA.lua") --SER алгоритм
dofile (getScriptPath().."\\testEMA.lua") --EMA алгоритм
dofile (getScriptPath().."\\testSAR.lua") --SER алгоритм
dofile (getScriptPath().."\\testReg.lua") --Reg алгоритм

SEC_CODES = {}

FILE_LOG_NAME = getScriptPath().."\\testMonitorLog.txt" -- ИМЯ ЛОГ-ФАЙЛА
PARAMS_FILE_NAME = getScriptPath().."\\testMonitor.csv" -- ИМЯ ЛОГ-ФАЙЛА

soundFileName = "c:\\windows\\media\\Alarm03.wav"

INTERVAL = INTERVAL_M5 -- --текущий интервал
RFR = 0 --7.42 --безрискова ставка для расчета коэфф. Шарпа


ALGORITHMS = {}

--/*РАБОЧИЕ ПЕРЕМЕННЫЕ РОБОТА (менять не нужно)*/
IsRun = true -- Флаг поддержания работы скрипта
is_Connected = 0
g_previous_time = os.time() -- помещение в переменную времени сервера в формате HHMMSS 
fixResColumnCount = 0
fixAlgoColumnCount = 0
stopSignal = false
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
ratioProfitDeals = 0
initalAssets = 0
leverage = 1
deals = {}
openedDS = {}
resultsTables = {} -- таблица результата
--iterateSettings = {}

lineTask = nil
calculateTask = nil
iSecTask = nil
cellTask = nil
settingsTask = nil
dsTask = nil

t_id = nil
tres_id = nil
tv_id = nil

function mycallbackforallstocks(i,cell,index)
    local ds = SEC_CODES['DS'][i][cell]
    local seccode = SEC_CODES['sec_codes'][i]          
    local classcode = SEC_CODES['class_codes'][i]          
    local intervalName = ALGORITHMS['names'][cell] 
    if ds:size() > SEC_CODES['lastIndexCalculated'][i][cell] then       
        myLog("mycallbackforallstocks Size "..tostring(DS:Size()).." class "..classcode.." sec "..seccode.." interval "..intervalName.." index "..tostring(index-1).." Close "..ds:C(index-1))
    end
end

function DataSource(i)
    local seccode = SEC_CODES['sec_codes'][i]          
    local classcode = SEC_CODES['class_codes'][i]          
    --local interval = SEC_CODES['interval'][i]          
    local interval = GetCell(t_id, i, 3).value or SEC_CODES['interval'][i]
    
    if openedDS[seccode] == nil then
        openedDS[seccode] = {}
    end

    if openedDS[seccode][interval] ~= nil then
        return openedDS[seccode][interval]
    end
    ds = CreateDataSource(classcode,seccode,interval)
    if ds == nil then
        message('NRTR monitor: ОШИБКА получения доступа к свечам! '..Error)
        myLog('NRTR monitor: ОШИБКА получения доступа к свечам! '..Error)
        -- Завершает выполнение скрипта
        IsRun = false
        return
    end
    if ds:Size() == 0 then 
        ds:SetEmptyCallback()
    end
    openedDS[seccode][interval] = ds
    --ds:SetUpdateCallback(function(...) mycallbackforallstocks(i,cell,interval,...) end)
    return ds
end

function OnInit()

    logFile = io.open(FILE_LOG_NAME, "w") -- открывает файл 
    
    local ParamsFile = io.open(PARAMS_FILE_NAME,"r")
    if ParamsFile == nil then
        IsRun = false
        message("Не удалость прочитать файл настроек!!!")
        return false
    end

    is_Connected = isConnected()

    if is_Connected ~= 1 then
        --IsRun = false
        message("Нет подключения к серверу!!!")
        --return false
    end

    ALGORITHMS = {
        ["names"] =                 {"NRTR"                 , "2EMA"        , "THV"       , "Sar"         , "Reg"       , "RangeNRTR"          },
        ["initParams"] =            {initStepNRTRParams     , initEMA       , initTHV     , initSAR       , initReg     , initRangeNRTRParams        },
        ["initAlgorithms"] =        {initStepNRTR           , initEMA       , initTHV     , initSAR       , initReg     , initRangeNRTR        },
        ["itetareAlgorithms"] =     {iterateNRTR            , iterateEMA    , iterateTHV  , iterateSAR    , iterateReg  , iterateNRTR     },
        ["calcAlgorithms"] =        {stepNRTR               , allEMA        , THV         , SAR           , Reg         , RangeNRTR            },
        ["tradeAlgorithms"] =       {simpleTrade            , ema2Trade     , simpleTrade , simpleTrade   , simpleTrade , simpleTrade       },
        ["settings"] =              {NRTRSettings           , EMASettings   , THVSettings , SARSettings   , RegSettings , NRTRSettings    },
    }    
        
    SEC_CODES['class_codes'] =           {} -- CLASS_CODE
    SEC_CODES['names'] =                 {} -- имена бумаг
    SEC_CODES['sec_codes'] =             {} -- коды бумаг
    SEC_CODES['isLong'] =                {} -- доступен Long
    SEC_CODES['isShort'] =               {} -- доступен Short
    SEC_CODES['ChartId'] =               {} -- имя графика для вывода сделок
    SEC_CODES['Algorithm'] =             {} -- имя алгоритма для расчета из таблицы алгоритмов
    SEC_CODES['Size'] =                  {} -- число свечек для расчета, от конца
    SEC_CODES['interval'] =              {} -- интервал расчета
    SEC_CODES['lastIndexCalculated'] =   {} -- свеча последнего рассчета

    myLog("Читаем файл параметров")
    local lineCount = 0
    for line in ParamsFile:lines() do
        myLog("Строка параметров "..line)
        lineCount = lineCount + 1
        if lineCount > 1 and line ~= "" then
            local per1, per2, per3, per4, per5, per6, per7, per8, per9 = line:match("%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*)")
            SEC_CODES['class_codes'][lineCount-1] = per1 
            SEC_CODES['names'][lineCount-1] = per2
            SEC_CODES['sec_codes'][lineCount-1] = per3
            SEC_CODES['isLong'][lineCount-1] = tonumber(per4)
            SEC_CODES['isShort'][lineCount-1] = tonumber(per5)
            SEC_CODES['ChartId'][lineCount-1] = per6
            SEC_CODES['Algorithm'][lineCount-1] = per7
            SEC_CODES['Size'][lineCount-1] = tonumber(per8)
            SEC_CODES['interval'][lineCount-1] = tonumber(per9)
            SEC_CODES['lastIndexCalculated'][lineCount-1] = {} 
        end
    end

    ParamsFile:close()

    CreateTable() -- Создает таблицу
    SetTableNotificationCallback(t_id, tAlgo_event_callback)
    SetTableNotificationCallback(tv_id, volume_event_callback)
    SetTableNotificationCallback(tres_id, tRes_event_callback)

    myLog("Algorithms "..tostring(#ALGORITHMS["names"]))
    myLog("Sec codes "..tostring(#SEC_CODES['sec_codes']))
    --myLog("initParams "..tostring(ALGORITHMS['initParams'][5]))
    --myLog("calcAlgorithms "..tostring(#ALGORITHMS['calcAlgorithms']))
    
    --local line = 0
    for i,SEC_CODE in ipairs(SEC_CODES['sec_codes']) do      
                   
        --openedDS[i] = {}
        myLog("================================================")
        InsertRow(t_id, i)
        SetCell(t_id, i, 0, SEC_CODES['names'][i], i)  --count строка, 0 - колонка, v - значение 
        SetCell(t_id, i, 3, tostring(SEC_CODES['interval'][i]), SEC_CODES['interval'][i])  --i строка, 1 - колонка, v - значение

        for cell,INTERVAL in pairs(ALGORITHMS["names"]) do                    
            
            
            if ALGORITHMS["names"][cell] == SEC_CODES['Algorithm'][i] then
                --line = line + 1

                SetCell(t_id, i, 1, ALGORITHMS['names'][cell], cell)  --i строка, 1 - колонка, v - значение
                
                local ds = DataSource(i)
                SEC_CODES['lastIndexCalculated'][i][cell] = ds:Size()            
                
                --SEC_CODES['iterateSettings'][SEC_CODE] = {} 
                --iterateSettings[SEC_CODE] = {}
                
                --Size = findFirstEmptyCandle(DS)
                local Size = math.min(math.max(SEC_CODES['Size'][i], ds:Size()), SEC_CODES['Size'][i]) 
                SetCell(t_id, i, 2, tostring(Size), Size)  --i строка, 1 - колонка, v - значение
                --SetCell(t_id, i, 18, "Stop")  --count строка, 0 - колонка, v - значение 
                --SetColor(t_id, i, 18, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))
                
                myLog("Всего свечей ".. SEC_CODE..", интервала "..ALGORITHMS["names"][cell].." "..tostring(ds:Size()))
            end

        end
    end

    lineTask = nil

    myLog("================================================")
    myLog("Initialization finished")

end 

-- Функция ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK при остановке скрипта
function OnStop()
    IsRun = false
    myLog("Script Stoped") 
    if t_id~= nil then
        DestroyTable(t_id)
    end
    if tres_id~= nil then
        DestroyTable(tres_id)
    end
    if tv_id~= nil then
        DestroyTable(tv_id)
    end
    if logFile~=nil then logFile:close() end    -- Закрывает файл 
end

function main() -- Функция, реализующая основной поток выполнения в скрипте    
    while IsRun do -- Цикл будет выполнятся, пока IsRun == true         
        if IsRun == false then break end
        
        if calculateTask ~= nil then
            calculateTask(iSecTask, cellTask)
            calculateTask = nil
        end        
        if ChartIdTask ~= nil and dsTask ~= nil then
            DelAllLabels(ChartIdTask);
            addDeals(deals, ChartIdTask, dsTask)
            stv.UseNameSpace(ChartIdTask)
            stv.SetVar('algoResults', algoResults)   
            ChartIdTask = nil
            dsTask = nil
        end
        if calculateTask == nil then
            SetCell(t_id, lineTask, 4, "100%", 100)
            --lineTask = nil
            iSecTask = nil
            cellTask = nil
            settingsTask = nil   
        end        
        
        sleep(100)
    end
end

function addDeals(deals, ChartId, DS)

    local equity = {}
    local equitySum = initalAssets or 0

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

    equity[1] = equitySum

    if deals == nil then
        return
    end

    for i,index in pairs(deals["index"]) do                    
        
        --myLog("deal index "..tostring(index))
        local tt = DS:T(index)
        equity[index] = equitySum

        label.DATE = (tt.year*10000+tt.month*100+tt.day)
        label.TIME = ((tt.hour)*10000+(tt.min)*100)            
        --myLog("DATE "..tostring(label.DATE))
        --myLog("TIME "..tostring(label.TIME))
        --myLog("openLong "..tostring(deals["openLong"][i]))
        --myLog("openShort "..tostring(deals["openShort"][i]))
        --myLog("closeLong "..tostring(deals["closeLong"][i]))
        --myLog("closeShort "..tostring(deals["closeShort"][i]))
        
        if deals["openLong"][i] ~=nil then
            label.YVALUE = deals["openLong"][i]
            label.IMAGE_PATH = getScriptPath()..'\\Pictures\\МоиСделки_buy.bmp'
            ALIGNMENT = "BOTTOM"
            label.R = 0
            label.G = 0
            label.B = 0
            if deals["dealProfit"][i] ~= nil then
                label.TEXT = tostring(deals["dealProfit"][i])
                equitySum = equitySum + deals["dealProfit"][i]
                equity[index] = equitySum 
                if deals["dealProfit"][i] > 0 then
                    label.R = 0
                    label.G = 128
                    label.B = 128
                elseif deals["dealProfit"][i] < 0 then   
                    label.R = 227
                    label.G = 264
                    label.B = 64
                end
            else
                label.TEXT = "open Long "..tostring(deals["openLong"][i])
            end
            label.HINT = "open Long "..tostring(deals["openLong"][i])
        elseif deals["openShort"][i] ~=nil then
            label.YVALUE = deals["openShort"][i]
            label.IMAGE_PATH = getScriptPath()..'\\Изображения\\МоиСделки_sell.bmp'
            label.R = 0
            label.G = 0
            label.B = 0
            ALIGNMENT = "TOP"
            if deals["dealProfit"][i] ~= nil then
                label.TEXT = tostring(deals["dealProfit"][i])
                equitySum = equitySum + deals["dealProfit"][i]
                equity[index] = equitySum 
                if deals["dealProfit"][i] > 0 then
                    label.R = 0
                    label.G = 128
                    label.B = 128
                elseif deals["dealProfit"][i] < 0 then   
                    label.R = 227
                    label.G = 264
                    label.B = 64
                end
            else
                label.TEXT = "open Short "..tostring(deals["openShort"][i])
            end
            label.HINT = "open Short "..tostring(deals["openShort"][i])
        elseif deals["closeLong"][i] ~=nil then
            label.YVALUE = deals["closeLong"][i]
            label.IMAGE_PATH = getScriptPath()..'\\Изображения\\МоиСделки_sell.bmp'
            ALIGNMENT = "TOP"
            label.R = 0
            label.G = 0
            label.B = 0
            if deals["dealProfit"][i] ~= nil then
                label.TEXT = tostring(deals["dealProfit"][i])
                equitySum = equitySum + deals["dealProfit"][i]
                equity[index] = equitySum 
                if deals["dealProfit"][i] > 0 then
                    label.R = 0
                    label.G = 128
                    label.B = 128
                elseif deals["dealProfit"][i] < 0 then   
                    label.R = 227
                    label.G = 264
                    label.B = 64
                end
            else
                label.TEXT = "close Long "..tostring(deals["closeLong"][i])
            end
            label.HINT = "close Long "..tostring(deals["closeLong"][i])
        elseif deals["closeShort"][i] ~=nil then
            label.YVALUE = deals["closeShort"][i]
            label.IMAGE_PATH = getScriptPath()..'\\Изображения\\МоиСделки_buy.bmp'
            ALIGNMENT = "BOTTOM"
            label.R = 0
            label.G = 0
            label.B = 0
            if deals["dealProfit"][i] ~= nil then
                label.TEXT = tostring(deals["dealProfit"][i])
                equitySum = equitySum + deals["dealProfit"][i]
                equity[index] = equitySum 
                if deals["dealProfit"][i] > 0 then
                    label.R = 0
                    label.G = 128
                    label.B = 128
                elseif deals["dealProfit"][i] < 0 then   
                    label.R = 227
                    label.G = 264
                    label.B = 64
                end
            else
                label.TEXT = "close Short "..tostring(deals["closeShort"][i])
            end
            label.HINT = "close Short "..tostring(deals["closeShort"][i])
        end
        
        AddLabel(ChartId, label)

    end

    for i=2,DS:Size() do
        if equity[i] == nil then
            equity[i] = equity[i-1]
        end
    end

    stv.UseNameSpace(ChartId)
    stv.SetVar('equity', equity)
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

function CreateTable() -- Функция создает таблицу
    
    t_id = AllocTable() -- Получает доступный id для создания
    
    -- Добавляет колонки
    AddColumn(t_id, 0, "Инструмент", true, QTABLE_INT_TYPE, 22)
    AddColumn(t_id, 1, "Алгоритм", true, QTABLE_INT_TYPE, 20)
    AddColumn(t_id, 2, "Size", true, QTABLE_INT_TYPE, 10)
    AddColumn(t_id, 3, "interval", true, QTABLE_INT_TYPE, 10)
    AddColumn(t_id, 4, "Выполнено", true, QTABLE_INT_TYPE, 15)
    AddColumn(t_id, 5, "Best", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 6, "profit(%)", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 7, "long", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 8, "short", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 9, "deals L/P", true, QTABLE_INT_TYPE, 17)
    AddColumn(t_id, 10, "deals S/P", true, QTABLE_INT_TYPE, 17)
    AddColumn(t_id, 11, "%Pr. deals", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 12, "avg deal", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 13, "Sigma", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(t_id, 14, "maxDown(%)", true, QTABLE_DOUBLE_TYPE, 18)
    AddColumn(t_id, 15, "Sharpe", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(t_id, 16, "AHPR", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(t_id, 17, "ZCount", true, QTABLE_DOUBLE_TYPE, 12)
    --AddColumn(t_id, 18, "Stop", true, QTABLE_STRING_TYPE, 12)
    fixAlgoColumnCount = 18

    t = CreateWindow(t_id) -- Создает таблицу
    SetWindowCaption(t_id, "Test") -- Устанавливает заголовок
    SetWindowPos(t_id, 90, 60, 1400, 800) -- Задает положение и размеры окна таблицы
    
    tv_id = AllocTable() -- таблица ввода значения
        
    tres_id = AllocTable() -- таблица результатов
    AddColumn(tres_id, 0, "Инструмент", true, QTABLE_INT_TYPE, 15)
    AddColumn(tres_id, 1, "Алгоритм", true, QTABLE_INT_TYPE, 15)
    AddColumn(tres_id, 2, "all", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 3, "profit(%)", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 4, "long", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 5, "short", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 6, "deals L/P", true, QTABLE_INT_TYPE, 15)
    AddColumn(tres_id, 7, "deals S/P", true, QTABLE_INT_TYPE, 15)
    AddColumn(tres_id, 8, "%Pr. deals", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(tres_id, 9, "avg deal", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 10, "Sigma", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 11, "maxD(%)", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(tres_id, 12, "Sharpe", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 13, "AHPR", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 14, "ZCount", true, QTABLE_DOUBLE_TYPE, 12)
    fixResColumnCount = 14
    
end

function CreateResTable(iSec) -- Функция создает таблицу
        
    local seccode = SEC_CODES['sec_codes'][iSec]          

    if resultsTables[seccode] == nil then
        resultsTables[seccode] = {}
    end

    return resultsTables[seccode]

end

function clearResultsTable(iSec, cell)

    local seccode = SEC_CODES['sec_codes'][iSec]          
    
    if resultsTables[seccode] ~= nil then
    
        for i = #resultsTables[seccode], 1, -1 do
            local secT = resultsTables[seccode][i][1]
            local cellT = resultsTables[seccode][i][2]
            if secT == iSec and cellT == cell then
                table.remove(resultsTables[seccode], i)
            end
        end
    end    
        
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

function tAlgo_event_callback(t_id, msg, par1, par2)

    if msg == QTABLE_LBUTTONDBLCLK then
        if par2 == 2 and IsWindowClosed(tv_id) then --Вводим Size
            tstr = par1
            tcell = par2
            AddColumn(tv_id, 0, "Значение", true, QTABLE_INT_TYPE, 25)
            tv = CreateWindow(tv_id) 
            SetWindowCaption(tv_id, "Введите Size")
            SetWindowPos(tv_id, 290, 260, 250, 100)                                
            InsertRow(tv_id, 1)
            SetCell(tv_id, 1, 0, GetCell(t_id, par1, 2).image, GetCell(t_id, par1, 2).value)  --i строка, 0 - колонка, v - значение 
        elseif par2 == 3 and IsWindowClosed(tv_id) then --Вводим интервал
            tstr = par1
            tcell = par2
            AddColumn(tv_id, 0, "Значение", true, QTABLE_INT_TYPE, 25)
            tv = CreateWindow(tv_id) 
            SetWindowCaption(tv_id, "Введите Interval")
            SetWindowPos(tv_id, 290, 260, 250, 100)                                
            InsertRow(tv_id, 1)
            SetCell(tv_id, 1, 0, GetCell(t_id, par1, 3).image, GetCell(t_id, par1, 3).value)  --i строка, 0 - колонка, v - значение 
        elseif par2 > 3 then --переоткрыть результат
            iSec = GetCell(t_id, par1, 0).value
            cell = GetCell(t_id, par1, 1).value 
            local settingTable = ALGORITHMS['settings'][cell]
            openResults(CreateResTable(iSec), settingTable)
        elseif par2 == 18 then --stop
            stopSignal = true
        else
            iSec = GetCell(t_id, par1, 0).value
            cell = GetCell(t_id, par1, 1).value 
            local iterf = ALGORITHMS["itetareAlgorithms"][cell]
            if iterf~=nil then
                stopSignal = false
                lineTask = par1
                iSecTask = iSec
                cellTask = cell
                calculateTask = iterf
                --iterf(par1, cell)
            end 
        end
    end
    if (msg==QTABLE_CLOSE) then --закрытие окна
        IsRun = false
    end
    
end

function tRes_event_callback(tres_id, msg, par1, par2)

    --myLog("par1 "..tostring(par1))
    --myLog("par2 "..tostring(par2))
    if msg == QTABLE_LBUTTONDBLCLK then 
            myLog("lineTask "..tostring(lineTask))
        
        if par2 <= 1 then
            iSec = GetCell(tres_id, par1, 0).value
            cell = GetCell(tres_id, par1, 1).value

            local _, columns = GetTableSize(tres_id)
            --myLog("columns "..tostring(columns))
            local resultString = resultsTables[SEC_CODES['sec_codes'][iSec]][GetCell(tres_id, par1, columns-1).value]
            local settings = resultString[#resultString]
             
            settings.Size = GetCell(t_id, lineTask, 2).value
            myLog("Size "..tostring(settings.Size))

            initalAssets = 0 
            dealsCount = 0
            dealsLongCount = 0
            dealsShortCount = 0
            profitDealsLongCount = 0
            profitDealsShortCount = 0
            ratioProfitDeals = 0
            allProfit = 0
            shortProfit = 0
            longProfit = 0
            lastDealPrice = 0
            beginIndex = 1
            endIndex = 1

            iSecTask = iSec
            cellTask = cell
            settingsTask = settings
            dsTask = DataSource(iSec)
            ChartIdTask = SEC_CODES['ChartId'][iSec]

            calculateTask = calculateAlgorithm
        end
        if par2 >= 2 then
            local newResult = CreateResTable(iSec)
            --table.sort(newResult, function(a,b) return a[par2+1]<b[par2+1] end)     
            --local resultString = newResult[#newResult]
            local resultString = resultsTables[SEC_CODES['sec_codes'][iSec]][par1]
            local settings = resultString[#resultString]
            openResults(newResult, settings, par2+1)
        end
    end
    
end

function calculateAlgorithm(iSec, cell)
            
    SEC_CODE = SEC_CODES['sec_codes'][iSec]
    CLASS_CODE =SEC_CODES['class_codes'][iSec]
    
    -- Получает ШАГ ЦЕНЫ ИНСТРУМЕНТА, последнюю цену, открытые позиции
    SEC_PRICE_STEP = getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value
    STEPPRICE = getParamEx(CLASS_CODE, SEC_CODE, "STEPPRICE").param_value
    if tonumber(STEPPRICE) == 0 or STEPPRICE == nil then
        leverage = 1
    else    
        leverage = STEPPRICE/SEC_PRICE_STEP
    end
    myLog("SEC_PRICE_STEP "..tostring(SEC_PRICE_STEP))
    myLog("STEPPRICE "..tostring(STEPPRICE))
    myLog("leverage "..tostring(leverage))

    local logDeals = true
    if logDeals then
        myLog("Шаг цены "..tostring(SEC_PRICE_STEP))
        myLog("Стоимость шага цены "..tostring(STEPPRICE))
        myLog("Плечо (фьюч.) "..tostring(leverage))
    end
    if initalAssets == 0 and CLASS_CODE == "SPBFUT" then
        initalAssets = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "BUYDEPO").param_value) --*leverage
        if logDeals then
            myLog("initial equity "..tostring(initalAssets))
        end
    end
    
    --myLog("stopSignal "..tostring(stopSignal))

    --DS = SEC_CODES['DS'][iSec][cell]
    DS = DataSource(iSec)
    algoResults = nil

    local initf = ALGORITHMS["initAlgorithms"][cell]
    local calcf = ALGORITHMS["calcAlgorithms"][cell]
    local tradef = ALGORITHMS["tradeAlgorithms"][cell]        
    local Size = settingsTask.Size or SEC_CODES['Size'][iSec]

    if beginIndex == 1 then
        beginIndex = DS:Size()-Size
    end                
    if endIndex == 1 then
        endIndex = DS:Size()
    end                
    if beginIndex <= 0 or beginIndex == endIndex then beginIndex = 1 end
    lastTradeDirection = 0
               
    if calcf~=nil then
    
        --init
        if initf~=nil then
            initf()
        end

        deals = {
            ["index"] = {},
            ["openLong"] = {},
            ["openShort"] = {},                                   
            ["closeLong"] = {},
            ["closeShort"] = {},                                   
            ["dealProfit"] = {}                                   
        }

        for index = 1, endIndex do
            algoResults, calcTrend = calcf(index, settingsTask, DS)
            tradef(index, algoResults, calcTrend, DS, SEC_CODES['isLong'][iSec], SEC_CODES['isShort'][iSec], deals, settingsTask, logDeals)  
        end
            
    end

end

function getTradeSignal(index, calcAlgoValue, calcTrend, DS)
    
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

function getTradeDirection(index, calcAlgoValue, calcTrend, DS)
    
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

function simpleTrade(index, calcAlgoValue, calcTrend, DS, isLong, isShort, deals, settings, logDeals)

    if index <= beginIndex then return nil end

    local equitySum = initalAssets or 0

    local t = DS:T(index)
    local dealTime = false
    local time = math.ceil((t.hour + t.min/100)*100)
    if time >= 1012 then 
        dealTime = true 
    end    
    if time >= 1842 then 
        dealTime = false 
    end
    
    --myLog("time "..tostring(time))
    --myLog("dealTime "..tostring(dealTime))
    --myLog("t.hour >= 10 and t.min >= 5 "..tostring(t.hour >= 10 and t.min >= 5))
    --myLog("t.hour >= 18 and t.min >= 45 "..tostring(t.hour >= 18 and t.min >= 45))
    if CLASS_CODE == 'QJSIM' or CLASS_CODE == 'TQBR'  then
        dealTime = true 
    end

    if not dealTime and lastDealPrice ~= 0 then
        
        if initalAssets == 0 then
            initalAssets = DS:O(index) --*leverage
            equitySum = initalAssets
        end
        if logDeals then
            myLog("--------------------------------------------------")
            myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index)))
        end
        
        if deals["openShort"][dealsCount] ~= nil then
            dealsCount = dealsCount + 1
            local tradeProfit = round(lastDealPrice - DS:O(index), 5)*leverage
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
                myLog("Закрытие шорта по цене "..tostring(DS:O(index)))
                myLog("Прибыль сделки "..tostring(tradeProfit))
                myLog("Прибыль по шортам "..tostring(shortProfit))
                myLog("Прибыль всего "..tostring(allProfit))
                myLog("equity "..tostring(equitySum))
            end
            lastDealPrice = 0
        end
        if deals["openLong"][dealsCount] ~= nil then
            dealsCount = dealsCount + 1
            local tradeProfit = round(DS:O(index) - lastDealPrice, 5)*leverage
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
                myLog("Закрытие лонга по цене "..tostring(DS:O(index)))
                myLog("Прибыль сделки "..tostring(tradeProfit))
                myLog("Прибыль по лонгам "..tostring(longProfit))
                myLog("Прибыль всего "..tostring(allProfit))
                myLog("equity "..tostring(equitySum))
            end
            lastDealPrice = 0
        end
    end

    tradeSignal = getTradeSignal(index, calcAlgoValue, calcTrend, DS)
    if not dealTime then
        lastTradeDirection = getTradeDirection(index, calcAlgoValue, calcTrend, DS)
        --myLog("lastTradeDirection "..tostring(lastTradeDirection))
        --myLog("tradeSignal "..tostring(tradeSignal))
        --myLog("time "..tostring(time))
        --myLog("time >= 1012 "..tostring(time >= 1012))
        --myLog("time - 1012 "..tostring(time - 1012))
    end

    if (tradeSignal == 1 or lastTradeDirection == 1) and dealTime then
        
        lastTradeDirection = 0
        dealsCount = dealsCount + 1
        if initalAssets == 0 then
            initalAssets = DS:O(index) --*leverage
            equitySum = initalAssets
        end
        if logDeals then
            myLog("--------------------------------------------------")
            myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index)))
        end
        if lastDealPrice ~= 0 and isShort == 1 then
            local tradeProfit = round(lastDealPrice - DS:O(index), 5)*leverage
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
                myLog("Закрытие шорта по цене "..tostring(DS:O(index)))
                myLog("Прибыль сделки "..tostring(tradeProfit))
                myLog("Прибыль по шортам "..tostring(shortProfit))
                myLog("Прибыль всего "..tostring(allProfit))
                myLog("equity "..tostring(equitySum))
            end
        end        
        if isLong == 1 then
            dealsLongCount = dealsLongCount + 1
            lastDealPrice = DS:O(index)
            deals["index"][dealsCount] = index 
            deals["openLong"][dealsCount] = DS:O(index) 
            if logDeals then
                myLog("Покупка по цене "..tostring(lastDealPrice))
            end
        else
            lastDealPrice = 0
        end
    end
    if (tradeSignal == -1 or lastTradeDirection == -1) and dealTime then
        
        lastTradeDirection = 0
        dealsCount = dealsCount + 1
        if initalAssets == 0 then
            initalAssets = DS:O(index) --*leverage
        end
        if logDeals then
            myLog("--------------------------------------------------")
            myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index)))
        end
        if lastDealPrice ~= 0 and isLong == 1 then
            local tradeProfit = round(DS:O(index) - lastDealPrice, 5)*leverage
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
                myLog("Закрытие лонга по цене "..tostring(DS:O(index)))
                myLog("Прибыль сделки "..tostring(tradeProfit))
                myLog("Прибыль по лонгам "..tostring(longProfit))
                myLog("Прибыль всего "..tostring(allProfit))
                myLog("equity "..tostring(equitySum))
            end
        end
        if isShort == 1 then
            dealsShortCount = dealsShortCount + 1
            lastDealPrice = DS:O(index)
            deals["index"][dealsCount] = index 
            deals["openShort"][dealsCount] = DS:O(index) 
            if logDeals then
                myLog("Продажа по цене "..tostring(lastDealPrice))
            end
        else
            lastDealPrice = 0
        end
    end

end

function openResults(resultsTable, settingTable, sortColumn)

    local resultsSortTable = {} 
    local count = #resultsTable
    for kk = 1, count do
        resultsSortTable[kk] = {}
        local n = 1
        local keyValueSetting = 0
        local columns = #resultsTable[kk]
        local lineSettings = resultsTable[kk][columns]
        for i=1,columns do
            resultsSortTable[kk][i] = resultsTable[kk][i]
        end
        for k,v in pairs(settingTable) do
            local keyValueSetting = lineSettings[k]
            if type(keyValueSetting) == 'table' then
                for kkk,vvv in pairs(keyValueSetting) do
                    local keyValueSettingT = keyValueSetting[kkk]
                    resultsSortTable[kk][15 + n] = keyValueSettingT
                    n = n+1
                end
            else
                resultsSortTable[kk][15 + n] = keyValueSetting
                n = n+1
            end
        end
        resultsSortTable[kk][15 + n] = kk
    end 
    if sortColumn == nil then
        sortColumn = 4
    end

    table.sort(resultsSortTable, function(a,b) return a[sortColumn]<b[sortColumn] end)

    if IsWindowClosed(tres_id) then
        
        local n = 1
        for k,v in pairs(settingTable) do
            if type(v) == 'table' then
                for kkk,vvv in pairs(v) do
                    AddColumn(tres_id, fixResColumnCount + n, kkk, true, QTABLE_DOUBLE_TYPE, 10)
                    n = n+1
                end
            else
                AddColumn(tres_id, fixResColumnCount + n, k, true, QTABLE_DOUBLE_TYPE, 10)
                n = n+1
            end
        end

        AddColumn(tres_id, fixResColumnCount + n, "id", true, QTABLE_DOUBLE_TYPE, 1)
        
        tres = CreateWindow(tres_id)
        SetWindowCaption(tres_id, "Results") 
        SetWindowPos(tres_id, 190, 160, 1500, 850)

    end
    
    Clear(tres_id)
    
    for kk = 1, count do
        InsertRow(tres_id, kk)
        --line = count-kk+1
        line = kk
        SetCell(tres_id, kk, 0, SEC_CODES['names'][resultsSortTable[line][1]], resultsSortTable[line][1])
        SetCell(tres_id, kk, 1, ALGORITHMS['names'][resultsSortTable[line][2]].." "..SEC_CODES['interval'][resultsSortTable[line][1]], resultsSortTable[line][2])
        SetCell(tres_id, kk, 2, tostring(resultsSortTable[line][3]), resultsSortTable[line][3])
        SetCell(tres_id, kk, 3, tostring(resultsSortTable[line][4]), resultsSortTable[line][4])
        SetCell(tres_id, kk, 4, tostring(resultsSortTable[line][5]), resultsSortTable[line][5])
        SetCell(tres_id, kk, 5, tostring(resultsSortTable[line][6]), resultsSortTable[line][6])
        SetCell(tres_id, kk, 6, tostring(resultsSortTable[line][7]), 0)
        SetCell(tres_id, kk, 7, tostring(resultsSortTable[line][8]), 0)
        SetCell(tres_id, kk, 8, tostring(resultsSortTable[line][9]), resultsSortTable[line][9])
        SetCell(tres_id, kk, 9, tostring(resultsSortTable[line][10]), resultsSortTable[line][10])
        SetCell(tres_id, kk, 10, tostring(resultsSortTable[line][11]), resultsSortTable[line][11])
        SetCell(tres_id, kk, 11, tostring(resultsSortTable[line][12]), resultsSortTable[line][12])
        SetCell(tres_id, kk, 12, tostring(resultsSortTable[line][13]), resultsSortTable[line][13])
        SetCell(tres_id, kk, 13, tostring(resultsSortTable[line][14]), resultsSortTable[line][14])
        SetCell(tres_id, kk, 14, tostring(resultsSortTable[line][15]), resultsSortTable[line][15])

        local n = 1
        local keyValueSetting = 0
        for k,v in pairs(settingTable) do
            --keyValueSetting = resultsSortTable[line][#resultsSortTable[line]][k]
            keyValueSetting = resultsSortTable[line][15+n]
            if type(v) == 'table' then
                for kkk,vvv in pairs(v) do
                    keyValueSetting = resultsSortTable[line][15+n]
                    SetCell(tres_id, kk, fixResColumnCount + n, tostring(keyValueSetting), keyValueSetting)
                    n = n+1
                end
            else
                SetCell(tres_id, kk, fixResColumnCount + n, tostring(keyValueSetting), keyValueSetting)
                n = n+1
            end
        end
        SetCell(tres_id, kk, fixResColumnCount + n, tostring(resultsSortTable[line][15+n]), resultsSortTable[line][15+n])

        --SetCell(tres_id, kk, fixResColumnCount + 1, tostring(resultsTable[line][fixResColumnCount + 2]), resultsTable[line][fixResColumnCount + 2])
        --SetCell(tres_id, kk, fixResColumnCount + 2, tostring(resultsTable[line][fixResColumnCount + 3]), resultsTable[line][fixResColumnCount + 3])
        --SetCell(tres_id, kk, fixResColumnCount + 3, tostring(resultsTable[line][fixResColumnCount + 4]), resultsTable[line][fixResColumnCount + 4])
    end        

    SetColor(tres_id, #resultsSortTable, QTABLE_NO_INDEX, RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
    
end

--function PaySoundFile(file_name)
--    w32.mciSendString("CLOSE QUIK_MP3") 
--    w32.mciSendString("OPEN \"" .. file_name .. "\" TYPE MpegVideo ALIAS QUIK_MP3")
--    w32.mciSendString("PLAY QUIK_MP3")
--end

function ArraySortByColl(array, col_number)
    for j = 1, #array - 1 do
       for i = 2, #array do
          if array[i][col_number] < array[i-1][col_number] then
             local x = array[i-1]
             array[i-1] = array[i]
             array[i] = x
          end
       end
    end
end

function gnomeSort(array, col_number)

    local i = 2
    local j = 3

    while i <= #array do
        if array[i-1][col_number] < array[i][col_number] then
            i = j
            j = j + 1
        else
            local x = array[i]
            array[i] = array[i-1]
            array[i-1] = x
            i = i-1
            if i == 1 then 
                i=j
                j=j+1 
            end

        end
    end

end

	----------------------------
function Median(x, y, z)     
   return (x+y+z) - math.min(x,math.min(y,z)) - math.max(x,math.max(y,z)) 
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

function findFirstEmptyCandle(DS)
    
    index = DS:Size()
    while index > 1 and DS:C(index) ~= nil do
        index = index - 1
    end

    return index
end

function FindExistCandle(I)

    local out = I
    while DS:C(out) == nil and out > 0 do
        out = out -1
    end	
    return out

end
