-- nick-h@yandex.ru
-- Glukk Inc ©

--local w32 = require("w32")
require("StaticVar")

SEC_CODES = {}
SCALE = 2

FILE_LOG_NAME = getScriptPath().."\\testMonitorLog.txt" -- ИМЯ ЛОГ-ФАЙЛА
PARAMS_FILE_NAME = getScriptPath().."\\testMonitor.csv" -- ИМЯ ЛОГ-ФАЙЛА

soundFileName = "c:\\windows\\media\\Alarm03.wav"

INTERVAL = INTERVAL_M5 -- --текущий интервал
RFR = 0 --7.42 --безрискова ставка для расчета коэфф. Шарпа


ALGORITHMS = {}

--/*РАБОЧИЕ ПЕРЕМЕННЫЕ РОБОТА (менять не нужно)*/
isRun = true -- Флаг поддержания работы скрипта
is_Connected = 0
g_previous_time = os.time() -- помещение в переменную времени сервера в формате HHMMSS
fixResColumnCount = 0
fixAlgoColumnCount = 0
stopSignal = false
shortProfit = 0
longProfit = 0
lastDealPrice = 0
lastStopShiftIndex = 0
slPrice = 0
tpPrice = 0
slIndex = 0
shiftStop = true
shortProfit = true
TransactionPrice = 0
lastTradeDirection = 0
dealsCount = 0
dealsLongCount = 0
dealsShortCount = 0
algoResults = nil
chartResults = nil
profitDealsLongCount = 0
profitDealsShortCount = 0
slDealsLongCount = 0
tpDealsLongCount = 0
slDealsShortCount = 0
tpDealsShortCount = 0
ratioProfitDeals = 0
initalAssets = 0
leverage = 1
priceKoeff = 1/leverage

logDeals = false
logging = false

deals = {}
openedDS = {}
idResColumn = 0
resultsTables = {} -- таблица результата

kATR = 0.50
ATR = {}
barsATR = 20
kawgATR = 2/(barsATR+1)
iterateSLTP = true
maxStop = 90
TRAILING_ACTIVATED = false
slippery = 3
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

function DataSource(seccode, classcode, interval)

    --local seccode = SEC_CODES['sec_codes'][i]
    --local classcode = SEC_CODES['class_codes'][i]
    ----local interval = SEC_CODES['interval'][i]
    --local cell = GetCell(t_id, i, 4)
    --local interval = cell~=nil and cell.value or SEC_CODES['interval'][i]

    if openedDS[seccode] == nil then
        openedDS[seccode] = {}
    end
    if openedDS[seccode][interval] ~= nil then
        return openedDS[seccode][interval]
    end
    local ds, Error = CreateDataSource(classcode,seccode,interval)
    if ds == nil then
        message('tester: ОШИБКА получения доступа к свечам! '..Error)
        myLog('tester: ОШИБКА получения доступа к свечам! '..Error)
        -- Завершает выполнение скрипта
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
        isRun = false
        message("Не удалость прочитать файл настроек!!!")
        return false
    end

    is_Connected = isConnected()

    if is_Connected ~= 1 then
        --isRun = false
        message("Нет подключения к серверу!!!")
        --return false
    end

    ALGORITHMS = {
        ["names"] =                 {},
        ["initParams"] =            {},
        ["initAlgorithms"] =        {},
        ["itetareAlgorithms"] =     {},
        ["calcAlgorithms"] =        {},
        ["tradeAlgorithms"] =       {},
        ["settings"] =              {},
    }

    --Таблица алгоритмов наполняется в каждом подключаемом файле.
    --[[-----------Образец-----------------
    local newIndex = #ALGORITHMS['names']+1

    ALGORITHMS['names'][newIndex]               = "Reg"
    ALGORITHMS['initParams'][newIndex]          = initReg
    ALGORITHMS['initAlgorithms'][newIndex]      = initReg
    ALGORITHMS['itetareAlgorithms'][newIndex]   = iterateReg
    ALGORITHMS['calcAlgorithms'][newIndex]      = Reg
    ALGORITHMS['tradeAlgorithms'][newIndex]     = simpleTrade
    ALGORITHMS['settings'][newIndex]            = RegSettings
    -----------Образец-----------------]]

    dofile (getScriptPath().."\\testNRTR.lua") --stepNRTR алгоритм
    dofile (getScriptPath().."\\testTHV_HA.lua") --THV алгоритм
    dofile (getScriptPath().."\\testShiftEMA.lua") --ShiftEMA алгоритм
    dofile (getScriptPath().."\\renko.lua") --ShiftEMA алгоритм
    dofile (getScriptPath().."\\testSAR.lua") --SAR алгоритм
    dofile (getScriptPath().."\\testReg.lua") --Reg алгоритм
    dofile (getScriptPath().."\\testRangeHV.lua") --RangeHV алгоритм
    dofile (getScriptPath().."\\testEthler.lua") --Ethler алгоритм
    dofile (getScriptPath().."\\testZZ.lua") --ZZ алгоритм
    dofile (getScriptPath().."\\bolinger.lua") --bolinger алгоритм
    dofile (getScriptPath().."\\ishimoku.lua") --ishimoku алгоритм

    SEC_CODES['class_codes']           = {} -- CLASS_CODE
    SEC_CODES['names']                 = {} -- имена бумаг
    SEC_CODES['sec_codes']             = {} -- коды бумаг
    SEC_CODES['isLong']                = {} -- доступен Long
    SEC_CODES['isShort']               = {} -- доступен Short
    SEC_CODES['ChartId']               = {} -- имя графика для вывода сделок
    SEC_CODES['Algorithm']             = {} -- имя алгоритма для расчета из таблицы алгоритмов
    SEC_CODES['beginIndex']            = {} -- индекс первой свечки для расчета
    SEC_CODES['Size']                  = {} -- число свечек для расчета, от конца или от начального индекса, если он заполнен
    SEC_CODES['interval']              = {} -- интервал расчета
    SEC_CODES['lastIndexCalculated']   = {} -- свеча последнего рассчета
    SEC_CODES['lastIndexCalculated']   = {} -- свеча последнего рассчета
    SEC_CODES['SL']                    = {} -- SL
    SEC_CODES['TP']                    = {} -- TP
    SEC_CODES['shiftStop']             = {} -- сдвигать StopLOSS при движении цены
    SEC_CODES['shiftProfit']           = {} -- cдвигать TakeProfit при движении цены
    SEC_CODES['fixedstop']             = {} -- STOPLOSS не рассчитывать по алгоритму, а брать фиксированным из настроек
    SEC_CODES['TRAILING_SIZE']         = {} -- Размер выхода в плюс в пунктах, после которого активируется трейлинг
    SEC_CODES['TRAILING_SIZE_STEP']    = {} -- Размер шага трейлинга в пунктах

    myLog("Читаем файл параметров")
    local lineCount = 0
    for line in ParamsFile:lines() do
        myLog("Строка параметров "..line)
        lineCount = lineCount + 1
        if lineCount > 1 and line ~= "" then
            local per1, per2, per3, per4, per5, per6, per7, per8, per9, per10, per11, per12, per13, per14, per15, per16, per17 = line:match("%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*)")
            SEC_CODES['class_codes'][lineCount-1] = per1
            SEC_CODES['names'][lineCount-1] = per2
            SEC_CODES['sec_codes'][lineCount-1] = per3
            SEC_CODES['Algorithm'][lineCount-1] = per4
            SEC_CODES['ChartId'][lineCount-1] = per5
            SEC_CODES['interval'][lineCount-1] = tonumber(per6)
            SEC_CODES['isLong'][lineCount-1] = tonumber(per7)
            SEC_CODES['isShort'][lineCount-1] = tonumber(per8)
            SEC_CODES['beginIndex'][lineCount-1] = tonumber(per9)
            SEC_CODES['Size'][lineCount-1] = tonumber(per10)
            SEC_CODES['lastIndexCalculated'][lineCount-1] = {}
            SEC_CODES['SL'][lineCount-1] = tonumber(per11)
            SEC_CODES['TP'][lineCount-1] = tonumber(per12)
            SEC_CODES['shiftStop'][lineCount-1] = tonumber(per13)
            SEC_CODES['shiftProfit'][lineCount-1] = tonumber(per14)
            SEC_CODES['fixedstop'][lineCount-1] = tonumber(per15)
            SEC_CODES['TRAILING_SIZE'][lineCount-1] = tonumber(per16)
            SEC_CODES['TRAILING_SIZE_STEP'][lineCount-1] = tonumber(per17)
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

    local line = 0
    for i,SEC_CODE in ipairs(SEC_CODES['sec_codes']) do

        for cell,INTERVAL in pairs(ALGORITHMS["names"]) do

            if ALGORITHMS["names"][cell] == SEC_CODES['Algorithm'][i] then
            local ds = DataSource(SEC_CODE, SEC_CODES['class_codes'][i], SEC_CODES['interval'][i])
                if ds~=nil then
                    line = line + 1

                    myLog("================================================")
                    InsertRow(t_id, line)
                    SetCell(t_id, line, 0, SEC_CODES['names'][i], i)  --count строка, 0 - колонка, v - значение
                    SetCell(t_id, line, 1, ALGORITHMS['names'][cell], cell)  --i строка, 1 - колонка, v - значение
                    SetCell(t_id, line, 4, tostring(SEC_CODES['interval'][i]), SEC_CODES['interval'][i])  --i строка, 1 - колонка, v - значение

                    SEC_CODES['lastIndexCalculated'][i][cell] = ds:Size()

                    --Size = findFirstEmptyCandle(DS)
                    local Size = math.min(math.max(SEC_CODES['Size'][i], ds:Size()), SEC_CODES['Size'][i])
                    SetCell(t_id, line, 2, tostring(SEC_CODES['beginIndex'][i]), SEC_CODES['beginIndex'][i])  --i строка, 1 - колонка, v - значение
                    SetCell(t_id, line, 3, tostring(Size), Size)  --i строка, 1 - колонка, v - значение
                    --SetCell(t_id, i, 18, "Stop")  --count строка, 0 - колонка, v - значение
                    --SetColor(t_id, i, 18, RGB(255,168,164), RGB(0,0,0), RGB(255,168,164), RGB(0,0,0))

                    myLog("Всего свечей ".. SEC_CODE..", интервала "..ALGORITHMS["names"][cell].." "..tostring(ds:Size()))
                end
            end

        end
    end

    lineTask = nil

    myLog("================================================")
    myLog("Initialization finished")

end

-- Функция ВЫЗЫВАЕТСЯ ТЕРМИНАЛОМ QUIK при остановке скрипта
function OnStop()
    isRun = false
    stopSignal = true
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
    while isRun do -- Цикл будет выполнятся, пока isRun == true
        if isRun == false then break end

        if calculateTask ~= nil then
            calculateTask(iSecTask, cellTask)
            calculateTask = nil
        end
        if ChartIdTask ~= nil and DS ~= nil then
            DelAllLabels(ChartIdTask);
            addDeals(deals, ChartIdTask, DS)
            stv.UseNameSpace(ChartIdTask)
            stv.SetVar('algoResults', chartResults)
            myLog(tostring(ChartIdTask)..' res '..tostring(#chartResults))
            ChartIdTask = nil
            dsTask = nil
        end
        if calculateTask == nil then
            SetCell(t_id, lineTask, 5, "100%", 100)
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
            label.HINT = "open Long "..tostring(deals["openLong"][i]).." - "..toYYYYMMDDHHMMSS(tt)
        elseif deals["openShort"][i] ~=nil then
            label.YVALUE = deals["openShort"][i]
            label.IMAGE_PATH = getScriptPath()..'\\Pictures\\МоиСделки_sell.bmp'
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
            label.HINT = "open Short "..tostring(deals["openShort"][i]).." - "..toYYYYMMDDHHMMSS(tt)
        elseif deals["closeLong"][i] ~=nil then
            label.YVALUE = deals["closeLong"][i]
            label.IMAGE_PATH = getScriptPath()..'\\Pictures\\МоиСделки_sell.bmp'
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
            label.HINT = "close Long "..tostring(deals["closeLong"][i]).." - "..toYYYYMMDDHHMMSS(tt)
        elseif deals["closeShort"][i] ~=nil then
            label.YVALUE = deals["closeShort"][i]
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
                label.TEXT = "close Short "..tostring(deals["closeShort"][i])
            end
            label.HINT = "close Short "..tostring(deals["closeShort"][i]).." - "..toYYYYMMDDHHMMSS(tt)
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

function regression(arr)

    local degree = 1
    local kstd = 1

    local p = 0
    local n = 0
    local f = 0
    local qq = 0
    local mm = 0
    local tt = 0
    local ii = 0
    local jj = 0
    local kk = 0
    local ll = 0
    local nn = 0

    local mi = 0
    local ai={{1,2,3,4}, {1,2,3,4}, {1,2,3,4}, {1,2,3,4}}
    local b={}
    local x={}

    p = #arr
    nn = degree+1

    fx_buffer = {}
    fx_buffer[1]= 0

    --- sx
    sx={}
    sx[1] = p+1

    for mi=1, nn*2-2 do
        sum=0
        for n=1, p do
            sum = sum + math.pow(n,mi)
        end
        sx[mi+1]=sum
    end

    --- syx
    for mi=1, nn do
        sum = 0
		for n=0, p do
			if arr[n] ~= nil then
                if mi==1 then
                   sum = sum + arr[n]
                else
                   sum = sum + arr[n]*math.pow(n,mi-1)
                end
            end
        end
        b[mi]=sum
    end

    --- Matrix
    for jj=1, nn do
        for ii=1, nn do
            kk=ii+jj-1
            ai[ii][jj]=sx[kk]
        end
    end

    --- Gauss
    for kk=1, nn-1 do
        ll=0
        mm=0
        for ii=kk, nn do
            if math.abs(ai[ii][kk])>mm then
                mm=math.abs(ai[ii][kk])
                ll=ii
            end
        end

        if ll==0 then
            return algoVal
        end
        if ll~=kk then

            for jj=1, nn do
                tt=ai[kk][jj]
                ai[kk][jj]=ai[ll][jj]
                ai[ll][jj]=tt
            end
            tt=b[kk]
            b[kk]=b[ll]
            b[ll]=tt
        end
        for ii=kk+1, nn do
            qq=ai[ii][kk]/ai[kk][kk]
            for jj=1, nn do
                if jj==kk then
                    ai[ii][jj]=0
                else
                    ai[ii][jj]=ai[ii][jj]-qq*ai[kk][jj]
                end
            end
            b[ii]=b[ii]-qq*b[kk]
        end
    end

     x[nn]=b[nn]/ai[nn][nn]

    for ii=nn-1, 1, -1 do
        tt=0
        for jj=1, nn-ii do
            tt=tt+ai[ii][ii+jj]*x[ii+jj]
            x[ii]=(1/ai[ii][ii])*(b[ii]-tt)
        end
    end

    for n=1, p do
        sum=0
        for kk=1, degree do
            sum = sum + x[kk+1]*math.pow(n,kk)
        end
        fx_buffer[n]=x[1]+sum
    end

    return fx_buffer

end

function correlation(regArr, arr)

    local mArr = 0
    local mReg = 0
    local p = #arr

    local sq=0.0
    for n=1, p do
        if arr[n] ~= nil then
            sq = sq + math.pow(arr[n]-regArr[n],2)
            mArr = mArr + arr[n]
            mReg = mReg + regArr[n]
        end
    end

    local LRE = math.sqrt(sq/(p-2))

    mArr = mArr/p
    mReg = mReg/p

    --myLog("mArr "..tostring(mArr).." mReg "..tostring(mReg))

    --ковариация
    local cov = 0
    local sqArr = 0
    local sqReg = 0

    for n=1, p do
        if arr[n] ~= nil then
            sqArr = sqArr + math.pow(arr[n]-mArr,2)
            sqReg = sqReg + math.pow(regArr[n]-mReg,2)
            cov = cov + (arr[n]-mArr)*(regArr[n]-mReg)
        end
    end

    cov = cov/p
    local LRC = cov/(math.sqrt(sqArr/p)*math.sqrt(sqReg/p))

    return LRE, LRC

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

    local dealsArrEquity = {}
    local dealsArrProfit = {}
    local dealsArrMAE = {}
    local dealsArrMFE = {}

    local avgMAE = 0
    local avgMFE = 0
    --myLog("--------------------------------------------------")
    --myLog("equity "..tostring(equity))

    for i,index in pairs(deals["index"]) do
        if deals["dealProfit"][i] ~= nil then
            dealsCount = dealsCount + 1
            avg = avg + deals["dealProfit"][i]
            dispDeals[i] = deals["dealProfit"][i]

            local oldEquity = equity
            equity = equity + deals["dealProfit"][i]

            dealsArrEquity[dealsCount]      = equity
            dealsArrProfit[dealsCount]      = deals["dealProfit"][i]
            dealsArrMAE[dealsCount]         = deals["MAE"][i]
            dealsArrMFE[dealsCount]         = deals["MFE"][i]

            avgMAE = avgMAE + deals["MAE"][i]
            avgMFE = avgMFE + deals["MFE"][i]

            --myLog("index "..tostring(index).." profit "..tostring(deals["dealProfit"][i]).." MAE "..tostring(deals["MAE"][i]).." MFE "..tostring(deals["MFE"][i]))

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
        avgMAE = round(avgMAE/dealsCount, 5)
        avgMFE = round(avgMFE/dealsCount, 5)
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

    local regArr = regression(dealsArrEquity)
    local LRE, LRC = correlation(regArr, dealsArrEquity)

    --local _, MAE = correlation(dealsArrProfit, dealsArrMAE)
    --local _, MFE = correlation(dealsArrProfit, dealsArrMFE)

    return profitRatio, round(avg, SCALE), sigma, maxDrawDown, sharpe, round(avgHPR, 2), ZCount, round(avgMAE,2), round(avgMFE,2), round(LRE,2), round(LRC,2)
end

function CreateTable() -- Функция создает таблицу

    t_id = AllocTable() -- Получает доступный id для создания

    -- Добавляет колонки
    AddColumn(t_id, 0, "Инструмент", true, QTABLE_INT_TYPE, 22)
    AddColumn(t_id, 1, "Алгоритм", true, QTABLE_INT_TYPE, 20)
    AddColumn(t_id, 2, "beginIndex", true, QTABLE_INT_TYPE, 10)
    AddColumn(t_id, 3, "Size", true, QTABLE_INT_TYPE, 10)
    AddColumn(t_id, 4, "interval", true, QTABLE_INT_TYPE, 10)
    AddColumn(t_id, 5, "done", true, QTABLE_INT_TYPE, 10)
    AddColumn(t_id, 6, "Best", true, QTABLE_DOUBLE_TYPE, 15)
    AddColumn(t_id, 7, "profit(%)", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(t_id, 8, "long", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(t_id, 9, "short", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(t_id, 10, "L/P", true, QTABLE_INT_TYPE, 9)
    AddColumn(t_id, 11, "S/P", true, QTABLE_INT_TYPE, 9)
    AddColumn(t_id, 12, "L SL/TP", true, QTABLE_INT_TYPE, 12)
    AddColumn(t_id, 13, "S SL/TP", true, QTABLE_INT_TYPE, 12)
    AddColumn(t_id, 14, "%Pr", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(t_id, 15, "avgDeal", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(t_id, 16, "Sigma", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(t_id, 17, "maxD(%)", true, QTABLE_DOUBLE_TYPE, 13)
    AddColumn(t_id, 18, "Sharpe", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(t_id, 19, "AHPR", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(t_id, 20, "ZCount", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(t_id, 21, "MAE", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(t_id, 22, "MFE", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(t_id, 23, "LRE", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(t_id, 24, "LRC", true, QTABLE_DOUBLE_TYPE, 10)
    fixAlgoColumnCount = 25

    t = CreateWindow(t_id) -- Создает таблицу
    SetWindowCaption(t_id, "Test") -- Устанавливает заголовок
    SetWindowPos(t_id, 0, 60, 1600, 500) -- Задает положение и размеры окна таблицы

    tv_id = AllocTable() -- таблица ввода значения

    tres_id = AllocTable() -- таблица результатов
    AddColumn(tres_id, 0, "Инструмент", true, QTABLE_INT_TYPE, 15)
    AddColumn(tres_id, 1, "Алгоритм", true, QTABLE_INT_TYPE, 15)
    AddColumn(tres_id, 2, "all", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 3, "profit(%)", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 4, "long", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 5, "short", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 6, "L/P", true, QTABLE_INT_TYPE, 9)
    AddColumn(tres_id, 7, "S/P", true, QTABLE_INT_TYPE, 9)
    AddColumn(tres_id, 8, "L SL/TP", true, QTABLE_INT_TYPE, 12)
    AddColumn(tres_id, 9, "S SL/TP", true, QTABLE_INT_TYPE, 12)
    AddColumn(tres_id, 10, "%Pr", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(tres_id, 11, "avgDeal", true, QTABLE_DOUBLE_TYPE, 10)
    AddColumn(tres_id, 12, "Sigma", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 13, "maxD(%)", true, QTABLE_DOUBLE_TYPE, 13)
    AddColumn(tres_id, 14, "Sharpe", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 15, "AHPR", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 16, "ZCount", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 17, "MAE", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 18, "MFE", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 19, "LRE", true, QTABLE_DOUBLE_TYPE, 12)
    AddColumn(tres_id, 20, "LRC", true, QTABLE_DOUBLE_TYPE, 10)
    fixResColumnCount = 21

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
            local secT = resultsTables[seccode][i][2]
            local cellT = resultsTables[seccode][i][3]
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
        if par2>1 and par2<=3 and IsWindowClosed(tv_id) then --Вводим Size
            tstr = par1
            tcell = par2
            AddColumn(tv_id, 0, "Значение", true, QTABLE_INT_TYPE, 25)
            tv = CreateWindow(tv_id)
            SetWindowCaption(tv_id, "Введите значение")
            SetWindowPos(tv_id, 290, 260, 250, 100)
            InsertRow(tv_id, 1)
            SetCell(tv_id, 1, 0, GetCell(t_id, par1, par2).image, GetCell(t_id, par1, par2).value)  --i строка, 0 - колонка, v - значение
        elseif par2 > 4 then --переоткрыть результат
            iSec = GetCell(t_id, par1, 0).value
            cell = GetCell(t_id, par1, 1).value
            local settingTable = ALGORITHMS['settings'][cell]
            idResColumn = 0
            openResults(CreateResTable(iSec), settingTable)
        elseif par2 == 21 then --stop
            stopSignal = true
        else
            iSec = GetCell(t_id, par1, 0).value
            cell = GetCell(t_id, par1, 1).value
            local iterf = ALGORITHMS["itetareAlgorithms"][cell]
            myLog('Запуск теста '..tostring(cell) ..' '..ALGORITHMS["names"][cell]..' по инструменту '..tostring(SEC_CODES['sec_codes'][iSec])..', интервал '..tostring(GetCell(t_id, par1, 4).value))
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
        isRun = false
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

            --myLog("columns "..tostring(columns))
            local resultString = resultsTables[SEC_CODES['sec_codes'][iSec]][GetCell(tres_id, par1, idResColumn).value]
            if resultString == nil then
                myLog('Не удалось получить таблицу результата. Данные не рассчитаны. Sec '..tostring(SEC_CODES['sec_codes'][iSec])..' tres line '..tostring(GetCell(tres_id, par1, idResColumn).value))
                message('Не удалось получить таблицу результата. Данные не рассчитаны. Sec '..tostring(SEC_CODES['sec_codes'][iSec])..' tres line '..tostring(GetCell(tres_id, par1, idResColumn).value))
                return
            end
            local settings = resultString[1]

            if settings.beginIndex == nil or settings.beginIndex == 0 then
                settings.beginIndex = GetCell(t_id, lineTask, 2).value
                settings.Size = GetCell(t_id, lineTask, 3).value
            end

            initalAssets = 0
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
            allProfit = 0
            shortProfit = 0
            longProfit = 0
            lastDealPrice = 0
            lastStopShiftIndex = 0
            slPrice = 0
            slIndex = 0
            tpPrice = 0

            iSecTask = iSec
            cellTask = cell
            ChartIdTask = SEC_CODES['ChartId'][iSec]
            myLog("iSecTask "..tostring(iSecTask).." cellTask "..tostring(cellTask).." ChartId "..ChartIdTask)
            myLog("beginIndex "..tostring(settings.beginIndex).." Size "..tostring(settings.Size))
            settingsTask = settings
            DS = DataSource(SEC_CODES['sec_codes'][iSec], SEC_CODES['class_codes'][iSec], GetCell(t_id, lineTask, 4).value)
            if settings.beginIndex == 0 then
                settings.beginIndex = DS:Size()-settings.Size
                settings.endIndex = DS:Size()
            else
                settings.endIndex = math.min(DS:Size(), settings.beginIndex + settings.Size)
            end

            calculateTask = calculateAlgorithm
        end
        if par2 >= 2 then
            iSec = GetCell(tres_id, par1, 0).value
            cell = GetCell(tres_id, par1, 1).value

            local newResult = CreateResTable(iSec)
            --table.sort(newResult, function(a,b) return a[par2+1]<b[par2+1] end)
            --local resultString = newResult[#newResult]
            local resultString = resultsTables[SEC_CODES['sec_codes'][iSec]][par1]
            --local settings = resultString[#resultString]
            local settings = ALGORITHMS['settings'][cell]
            idResColumn = 0
            openResults(newResult, settings, par2+2)
        end
    end

end

function getResFile(settingTable, RESULTS_FILE_NAME)

    local resFile = io.open(RESULTS_FILE_NAME,"w")
    if resFile == nil then
        message("Не удалость прочитать файл результатов!!!")
        return nil
    end

    local firstString = "SEC;INTERVAL;allProfit;profitRatio;longProfit;shortProfit;dealsL;dealsLP;dealsS;dealsSP;longSL;longTP;shortSL;shorTP;ratioProfitDeals;avg;sigma;maxDrawDown;sharpe;AHPR;ZCount;MAE;MFE;LRE;LRC"

    for k,v in pairs(settingTable) do
        if type(v) == 'table' then
            for kkk,vvv in pairs(v) do
                firstString = firstString..";"..kkk
            end
        else
            firstString = firstString..";"..k
        end
    end
    resFile:write(firstString.."\n")
    resFile:flush()

    return resFile

end

function writeResString(SecCode, interval, resFile, settingTable, settings, allProfit, profitRatio, longProfit, shortProfit, dealsL, dealsLP, dealsS, dealsSP, longSL, longTP, shortSL, shortTP, ratioProfitDeals, avg, sigma, maxDrawDown, sharpe, AHPR, ZCount, MAE, MFE, LRE, LRC)

    local stringLine = SecCode..';'..interval..';'..
    string.gsub(tostring(allProfit),'[%.]+', ',')..';'..string.gsub(tostring(profitRatio),'[%.]+', ',')..';'..string.gsub(tostring(longProfit),'[%.]+', ',')..';'..
    string.gsub(tostring(shortProfit),'[%.]+', ',')..';'..string.gsub(tostring(dealsL),'[%.]+', ',')..';'..string.gsub(tostring(dealsLP),'[%.]+', ',')..';'..string.gsub(tostring(dealsS),'[%.]+', ',')..';'..string.gsub(tostring(dealsSP),'[%.]+', ',')..';'..
    string.gsub(tostring(longSL),'[%.]+', ',')..';'..string.gsub(tostring(longTP),'[%.]+', ',')..';'..string.gsub(tostring(shortSL),'[%.]+', ',')..';'..string.gsub(tostring(shortTP),'[%.]+', ',')..';'..
    string.gsub(tostring(ratioProfitDeals),'[%.]+', ',')..';'..string.gsub(tostring(avg),'[%.]+', ',')..';'..string.gsub(tostring(sigma),'[%.]+', ',')..';'..string.gsub(tostring(maxDrawDown),'[%.]+', ',')..';'..
    string.gsub(tostring(sharpe),'[%.]+', ',')..';'..string.gsub(tostring(AHPR),'[%.]+', ',')..';'..string.gsub(tostring(ZCount),'[%.]+', ',')..';'..string.gsub(tostring(MAE),'[%.]+', ',')..';'..
    string.gsub(tostring(MFE),'[%.]+', ',')..';'..string.gsub(tostring(LRE),'[%.]+', ',')..';'..string.gsub(tostring(LRC),'[%.]+', ',')

    for k,v in pairs(settingTable) do
        if type(v) == 'table' then
            for kkk,vvv in pairs(v) do
                stringLine = stringLine..";"..string.gsub(tostring(settings[kkk]),'[%.]+', ',')
            end
        else
            stringLine = stringLine..";"..string.gsub(tostring(settings[k]),'[%.]+', ',')
        end
    end
    resFile:write(stringLine.."\n")
    resFile:flush()

end

function iterateTable(iSec, cell, settingsTable, resultsTable, settingTable, beginIndex, endIndex, Size, resFile)

    local SecCode = SEC_CODES['sec_codes'][iSec]
    local interval = ALGORITHMS['names'][cell].." "..tostring(GetCell(t_id, lineTask, 4).value)

    local allCount = #settingsTable
    local localCount = 0
    local done = 0
    local rescount = #resultsTable

    --local beginBar = toYYYYMMDDHHMMSS(DS:T(beginIndex))
    --local endBar = toYYYYMMDDHHMMSS(DS:T(endIndex))

    for i,v in ipairs(settingsTable) do

        if stopSignal or not isRun then
            break
        end

        localCount = localCount + 1
        done = round(localCount*100/allCount, 0)
        SetCell(t_id, lineTask, 5, tostring(done).."%", done)

        allProfit = 0
        shortProfit = 0
        longProfit = 0
        lastDealPrice = 0
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
        slIndex = 0
        ratioProfitDeals = 0
        initalAssets = 0

        settingsTask = v
        settingsTask.Size = Size

        if beginIndex == 0 then
            settingsTask.beginIndex = math.max(endIndex - Size, 1)
            settingsTask.endIndex = endIndex
        else
            settingsTask.beginIndex = math.max(beginIndex, 1)
            settingsTask.endIndex = math.min(endIndex, beginIndex + Size)
        end
        settingsTask.beginIndexToCalc = math.max(1, settingsTask.beginIndex)

        if settingsTask.TPSec == nil and SEC_CODES['TP'][iSec] ~= 0 then
            settingsTask.TPSec = SEC_CODES['TP'][iSec]
        end
        if settingsTask.SLSec == nil and SEC_CODES['SL'][iSec] ~= 0 then
            settingsTask.SLSec = SEC_CODES['SL'][iSec]
        end
        if settingsTask.shiftStop == nil then
            settingsTask.shiftStop = SEC_CODES['shiftStop'][iSec]
        end
        if settingsTask.shiftProfit == nil then
            settingsTask.shiftProfit = SEC_CODES['shiftProfit'][iSec]
        end
        if settingsTask.fixedstop == nil then
            settingsTask.fixedstop = SEC_CODES['fixedstop'][iSec]
        end
        if settingsTask.trailSize == nil then
            settingsTask.trailSize = SEC_CODES['TRAILING_SIZE'][iSec]
        end
        if settingsTask.trailStep == nil then
            settingsTask.trailStep = SEC_CODES['TRAILING_SIZE_STEP'][iSec]
        end

        --if logDeals then
            myLog("================================================")
            myLog('testSizeBars '..tostring(Size))
            myLog('beginIndex '..tostring(settingsTask.beginIndex)..' - '..toYYYYMMDDHHMMSS(DS:T(settingsTask.beginIndex))..' endIndex '..tostring(settingsTask.endIndex)..' - '..toYYYYMMDDHHMMSS(DS:T(settingsTask.endIndex)))
            myLog('SL '..tostring(settingsTask.SLSec)..' TP '..tostring(settingsTask.TPSec))
        --end

        calculateAlgorithm(iSec, cell)
        local profitRatio, avg, sigma, maxDrawDown, sharpe, AHPR, ZCount, MAE, MFE, LRE, LRC = calculateSigma(deals)

        --myLog("--------------------------------------------------")
        --myLog("Прибыль по лонгам "..tostring(longProfit))
        --myLog("Прибыль по шортам "..tostring(shortProfit))
        --myLog("Прибыль всего "..tostring(allProfit))
        --myLog("================================================")
        if resFile ~= nil then
            writeResString(SecCode, interval, resFile, settingTable, settingsTask, allProfit, profitRatio, longProfit, shortProfit, dealsLongCount, profitDealsLongCount, dealsShortCount, profitDealsShortCount, slDealsLongCount, tpDealsLongCount, slDealsShortCount, tpDealsShortCount, ratioProfitDeals, avg, sigma, maxDrawDown, sharpe, AHPR, ZCount, MAE, MFE, LRE, LRC)
        end

        local dealsLP = tostring(dealsLongCount).."/"..tostring(profitDealsLongCount)
        local dealsSP = tostring(dealsShortCount).."/"..tostring(profitDealsShortCount)
        if dealsLongCount + dealsShortCount > 0 then
            ratioProfitDeals = round((profitDealsLongCount + profitDealsShortCount)*100/(dealsLongCount + dealsShortCount), 2)
        end

        local longSL_TP = tostring(slDealsLongCount).."/"..tostring(tpDealsLongCount)
        local shortSL_TP = tostring(slDealsShortCount).."/"..tostring(tpDealsShortCount)

        if profitRatio then
            rescount = rescount + 1
            resultsTable[rescount] = {settingsTask, iSec, cell, allProfit, profitRatio, longProfit, shortProfit, dealsLP, dealsSP, longSL_TP, shortSL_TP, ratioProfitDeals, avg, sigma, maxDrawDown, sharpe, AHPR, ZCount, MAE, MFE, LRE, LRC}

            if maxProfit == nil or maxProfit<allProfit then
                maxProfit = allProfit
                maxProfitIndex = count
                maxProfitDeals = deals
                maxProfitAlgoResults = chartResults
                SetCell(t_id, lineTask, 6, tostring(allProfit), allProfit)
                SetCell(t_id, lineTask, 7, tostring(profitRatio), profitRatio)
                SetCell(t_id, lineTask, 8, tostring(longProfit), longProfit)
                SetCell(t_id, lineTask, 9, tostring(shortProfit), shortProfit)
                SetCell(t_id, lineTask, 10, tostring(dealsLP), 0)
                SetCell(t_id, lineTask, 11, tostring(dealsSP), 0)
                SetCell(t_id, lineTask, 12, longSL_TP, 0)
                SetCell(t_id, lineTask, 13, shortSL_TP, 0)
                SetCell(t_id, lineTask, 14, tostring(ratioProfitDeals), ratioProfitDeals)
                SetCell(t_id, lineTask, 15, tostring(avg), avg)
                SetCell(t_id, lineTask, 16, tostring(sigma), sigma)
                SetCell(t_id, lineTask, 17, tostring(maxDrawDown), maxDrawDown)
                SetCell(t_id, lineTask, 18, tostring(sharpe), sharpe)
                SetCell(t_id, lineTask, 19, tostring(AHPR), AHPR)
                SetCell(t_id, lineTask, 20, tostring(ZCount), ZCount)
                SetCell(t_id, lineTask, 21, tostring(MAE), MAE)
                SetCell(t_id, lineTask, 22, tostring(MFE), MFE)
                SetCell(t_id, lineTask, 23, tostring(LRE), LRE)
                SetCell(t_id, lineTask, 24, tostring(LRC), LRC)
            end

        end

    end

    return resultsTable
end

function iterateAlgorithm(iSec, cell, settingsTable)

    Clear(tres_id)

    local SecCode = SEC_CODES['sec_codes'][iSec]
    myLog("cell "..tostring(cell))
    local interval = ALGORITHMS['names'][cell].." "..tostring(GetCell(t_id, lineTask, 4).value)

    myLog("================================================")
    myLog("iSec "..tostring(iSec).." Sec code "..SecCode..' '..interval)

    --local settings = ALGORITHMS["settings"][cell]
    local beginIndex = GetCell(t_id, lineTask, 2).value or 0
    local Size = GetCell(t_id, lineTask, 3).value or SEC_CODES['Size'][iSec]
    --resultsTable = {}
    clearResultsTable(iSec, cell)
    local resultsTable = CreateResTable(iSec)
    local settingTable = ALGORITHMS['settings'][cell]

    if settingTable.TPSec == nil and SEC_CODES['TP'][iSec] ~= 0 then
        settingTable.TPSec = SEC_CODES['TP'][iSec]
    end
    if settingTable.SLSec == nil and SEC_CODES['SL'][iSec] ~= 0 then
        settingTable.SLSec = SEC_CODES['SL'][iSec]
    end
    if settingTable.shiftStop == nil then
        settingTable.shiftStop = SEC_CODES['shiftStop'][iSec]
    end
    if settingTable.shiftProfit == nil then
        settingTable.shiftProfit = SEC_CODES['shiftProfit'][iSec]
    end
    if settingTable.fixedstop == nil then
        settingTable.fixedstop = SEC_CODES['fixedstop'][iSec]
    end
    if settingTable.trailSize == nil then
        settingTable.trailSize = SEC_CODES['TRAILING_SIZE'][iSec]
    end
    if settingTable.trailStep == nil then
        settingTable.trailStep = SEC_CODES['TRAILING_SIZE_STEP'][iSec]
    end

    myLog("Interval "..interval)

    local ChartId = SEC_CODES['ChartId'][iSec]
    myLog("ChartId "..ChartId)
    if ChartId ~= nil then
        DelAllLabels(ChartId);
    end
    myLog("================================================")

    local timeStamp = os.date("%Y-%m-%d %H.%M.%S", os.time())

    RESULTS_FILE_NAME = getScriptPath().."\\"..SecCode..'_'..interval..'_'..timeStamp..".csv" -- ИМЯ res-ФАЙЛА
    local resFile = getResFile(settingTable, RESULTS_FILE_NAME)

    DS = DataSource(SecCode, SEC_CODES['class_codes'][iSec], GetCell(t_id, lineTask, 4).value)

    local beginIndex = GetCell(t_id, lineTask, 2).value or 0
    local Size = GetCell(t_id, lineTask, 3).value or SEC_CODES['Size'][iSec]
    --beginIndex = 31510
    local endIndex = DS:Size()

    maxProfitIndex = 0
    maxProfit = nil
    maxProfitDeals = nil
    maxProfitAlgoResults = nil

    resultsTable = iterateTable(iSec, cell, settingsTable, resultsTable, settingTable, beginIndex, endIndex, Size, resFile)

    if not isRun then return end

    SetCell(t_id, lineTask, 5, "100%", 100)

    if iterateSLTP then
        if #resultsTable > 1 then
            table.sort(resultsTable, function(a,b) return a[4]<b[4] end)
        end

        if #resultsTable > 0 then
            if SEC_CODES['SL'][iSec]~=0 or SEC_CODES['TP'][iSec]~=0 then
                local linesToIterateSLTP = 25
                local lines = math.min(linesToIterateSLTP, #resultsTable)
                local settingsTableSLTP = getSettingsSLTP(iSec, resultsTable, lines)
                local i = 1
                while i <= lines do
                    table.remove(resultsTable, #resultsTable)
                    i = i+1
                end
                resultsTable = iterateTable(iSec, cell, settingsTableSLTP, resultsTable, settingTable, beginIndex, endIndex, Size, resFile)
            end
        end
    end

    if not isRun then return end

    resultsTables[SecCode] = resultsTable

    SetCell(t_id, lineTask, 5, "100%", 100)

    if resFile ~= nil then
        resFile:close()
    end

    idResColumn = 0
    openResults(resultsTable, settingTable)

    if not isRun then return end

    if ChartId ~= nil then
        addDeals(maxProfitDeals, ChartId, DS)
        stv.UseNameSpace(ChartId)
        stv.SetVar('algoResults', maxProfitAlgoResults)
    end

end

function getSettingsSLTP(iSec, resultsTable, lines)

    local param4Min = SEC_CODES['SL'][iSec]
    local param4Max = SEC_CODES['SL'][iSec]
    local param4Step = 5

    local param5Min = SEC_CODES['TP'][iSec]
    local param5Max = SEC_CODES['TP'][iSec]
    local param5Step = 5

    if SEC_CODES['SL'][iSec]~=0 and SEC_CODES['fixedstop'][iSec]==1 then
        param4Min = 15
        param4Max = 80
        param4Step = 5
    end

    if SEC_CODES['TP'][iSec]~=0 then
        param5Min = 75
        param5Max = 250
        param5Step = 5
    end

    local settingsTable = {}
    local allCount = 0

    for i=0,math.min(#resultsTable-1, lines) do

        for param4 = param4Min, param4Max, param4Step do
            for param5 = param5Min, param5Max, param5Step do
                allCount = allCount + 1
                settingsTable[allCount] = {}
                for i,v in pairs(resultsTable[#resultsTable - i][1]) do
                    settingsTable[allCount][i] = v
                end
                settingsTable[allCount].SLSec = param4
                settingsTable[allCount].TPSec = param5
                --myLog('**** SL '..tostring(settingsTable[allCount].SLSec)..' TP '..tostring(settingsTable[allCount].TPSec))
            end
        end
    end

    return settingsTable

end

function calculateAlgorithm(iSec, cell)

    if iSec == nil then return end

    SEC_CODE = SEC_CODES['sec_codes'][iSec]
    CLASS_CODE =SEC_CODES['class_codes'][iSec]
    --myLog("iSec "..tostring(iSec).." SEC_CODE "..tostring(SEC_CODE).." cell "..tostring(cell).." CLASS_CODE "..tostring(CLASS_CODE))
    SCALE = getSecurityInfo(CLASS_CODE, SEC_CODE).scale

    -- Получает ШАГ ЦЕНЫ ИНСТРУМЕНТА, последнюю цену, открытые позиции
    SEC_PRICE_STEP = getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value
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
        priceKoeff = 1/LOTSIZE
    end

    if logDeals then
        myLog("Шаг цены "..tostring(SEC_PRICE_STEP))
        myLog("Стоимость шага цены "..tostring(STEPPRICE))
        myLog("Плечо (фьюч.) "..tostring(leverage).." priceKoeff "..tostring(priceKoeff))
    end
    if initalAssets == 0 and CLASS_CODE == "SPBFUT" then
        initalAssets = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "BUYDEPO").param_value) --/priceKoeff
        if logDeals then
            myLog("initial equity "..tostring(initalAssets))
        end
    end

    --myLog("stopSignal "..tostring(stopSignal))

    --DS = SEC_CODES['DS'][iSec][cell]
    --DS = DataSource(iSec)
    algoResults = nil
    chartResults = nil

    local initf = ALGORITHMS["initAlgorithms"][cell]
    local calcf = ALGORITHMS["calcAlgorithms"][cell]
    local tradef = ALGORITHMS["tradeAlgorithms"][cell]
    local Size = settingsTask.Size or SEC_CODES['Size'][iSec]

    calcATR = false

    --if beginIndex == 1 or beginIndex == 0 or beginIndex == nil then
    --    beginIndex = DS:Size()-Size
    --end
    --if endIndex == 1 or endIndex == 0 or endIndex == nil then
    --    endIndex = DS:Size()
    --end
    --if beginIndex <= 0 or beginIndex == endIndex then beginIndex = 1 end

    lastTradeDirection = 0
    slPrice = 0
    tpPrice = 0
    slIndex = 0
    TRAILING_ACTIVATED = false

    local SLSec         = settingsTask.SLSec or SEC_CODES['SL'][iSec]
    local TPSec         = settingsTask.TPSec or SEC_CODES['TP'][iSec]
    local trailSize     = settingsTask.trailSize or SEC_CODES['TRAILING_SIZE'][iSec]
    local trailStep     = settingsTask.trailStep or SEC_CODES['TRAILING_SIZE_STEP'][iSec]

    if calcf~=nil then

        --init
        if initf~=nil then
            initf()
        end

        deals = {
            ["index"] =      {},
            ["openLong"] =   {},
            ["openShort"] =  {},
            ["closeLong"] =  {},
            ["closeShort"] = {},
            ["dealProfit"] = {},
            ["MAE"] =        {},
            ["MFE"] =        {}
        }

        for index = 1, settingsTask.endIndex do
            algoResults, calcTrend, chartResults = calcf(index, settingsTask, DS)
            if index >= settingsTask.beginIndexToCalc then
                tradef(index, algoResults, calcTrend, DS, SEC_CODES['isLong'][iSec], SEC_CODES['isShort'][iSec], deals, settingsTask, logDeals,  SLSec,  TPSec, trailSize, trailStep)
            end
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
        if signaltestvalue1 > 0 and signaltestvalue2 <= 0 then --тренд сменился на растущий
            signal = 1
        end
        if signaltestvalue1 < 0 and signaltestvalue2 >= 0 then --тренд сменился на падающий
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

function simpleTrade(index, calcAlgoValue, calcTrend, DS, isLong, isShort, deals, settings, logDeals, STOP_LOSS, TAKE_PROFIT, TRAILING_SIZE, TRAILING_SIZE_STEP)

    if calcATR == false then
        if index == settings.beginIndexToCalc then
            ATR = {}
            ATR[index] = 0
        end
        ATR[index] = ATR[index-1]

        if index<barsATR+settings.beginIndexToCalc then
            ATR[index] = 0
        elseif index==barsATR+settings.beginIndexToCalc then
            local sum=0
            for i = 1, barsATR do
                sum = sum + dValue(i)
            end
            ATR[index]=sum/barsATR
        elseif index>barsATR+settings.beginIndexToCalc then
            --ATR[index]=(ATR[index-1] * (barsATR-1) + dValue(index)) / barsATR
            ATR[index] = kawgATR*dValue(index)+(1-kawgATR)*ATR[index-1]
        end
    end

    --//TODO: limit orders and stops
    --//TODO: smart selection, choose best from every 5

    if index <= settings.beginIndex then return nil end

    local equitySum = initalAssets or 0

    local t = DS:T(index)
    local dealTime = false
    local time = math.ceil((t.hour + t.min/100)*100)
    if time >= 1015 then
        dealTime = true
    end
    if time >= 1842 then
        dealTime = false
    end

    stopShiftIndexWait = 17 --best 17, 21

    if STOP_LOSS == nil then STOP_LOSS = 0 end
    if TAKE_PROFIT == nil then TAKE_PROFIT = 0 end

    --myLog("time "..tostring(time))
    --myLog("dealTime "..tostring(dealTime))
    --myLog("t.hour >= 10 and t.min >= 5 "..tostring(t.hour >= 10 and t.min >= 5))
    --myLog("t.hour >= 18 and t.min >= 45 "..tostring(t.hour >= 18 and t.min >= 45))
    if CLASS_CODE == 'QJSIM' or CLASS_CODE == 'TQBR'  then
        dealTime = true
    end

    tradeSignal = getTradeSignal(index, calcAlgoValue, calcTrend, DS)
    if not dealTime or os.time(DS:T(index)) == startTradeTime then
        lastTradeDirection = getTradeDirection(index-1, calcAlgoValue, calcTrend, DS)
        --myLog("lastTradeDirection "..tostring(lastTradeDirection))
        --myLog("tradeSignal "..tostring(tradeSignal))
        --myLog("time "..tostring(time))
        --myLog("time >= 1012 "..tostring(time >= 1012))
        --myLog("time - 1012 "..tostring(time - 1012))
    end

    local closeDeal = false
    if calcTrend ~= nil then
        closeDeal = calcTrend[index-1] == 0
    end

    if (not dealTime or closeDeal) and lastDealPrice ~= 0 and (deals["openShort"][dealsCount] ~= nil or deals["openLong"][dealsCount] ~= nil) then

        if initalAssets == 0 then
            initalAssets = DS:O(index)/priceKoeff
            equitySum = initalAssets
        end

        if deals["openShort"][dealsCount] ~= nil then
            dealsCount = dealsCount + 1
            if logDeals then
                myLog("--------------------------------------------------")
                myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
            end
            local deal_price = DS:O(index)+slippery*SEC_PRICE_STEP
            local tradeProfit = round(lastDealPrice - deal_price, SCALE)/priceKoeff
            shortProfit = shortProfit + tradeProfit
            allProfit = allProfit + tradeProfit
            equitySum = equitySum + tradeProfit
            if tradeProfit > 0 then
                profitDealsShortCount = profitDealsShortCount + 1
            end
            deals["index"][dealsCount] = index
            deals["closeShort"][dealsCount] = deal_price
            deals["dealProfit"][dealsCount] = tradeProfit
            deals["MAE"][dealsCount] = round(math.max((DS:H(index) - deals["openShort"][dealsCount-1])/priceKoeff, deals["MAE"][dealsCount]), SCALE)
            deals["MFE"][dealsCount] = round(math.max((deals["openShort"][dealsCount-1] - deal_price)/priceKoeff, deals["MFE"][dealsCount]), SCALE)
            if logDeals then
                myLog("Закрытие шорта "..tostring(deals["openShort"][dealsCount-1]).." по цене "..tostring(deal_price))
                myLog("Прибыль сделки "..tostring(tradeProfit))
                myLog("Прибыль по шортам "..tostring(shortProfit))
                myLog("Прибыль всего "..tostring(allProfit))
                myLog("equity "..tostring(equitySum))
            end
            lastDealPrice = 0
            TRAILING_ACTIVATED = false
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
            local deal_price = DS:O(index)-slippery*SEC_PRICE_STEP
            local tradeProfit = round(deal_price - lastDealPrice, SCALE)/priceKoeff
            longProfit = longProfit + tradeProfit
            allProfit = allProfit + tradeProfit
            equitySum = equitySum + tradeProfit
            if tradeProfit > 0 then
                profitDealsLongCount = profitDealsLongCount + 1
            end
            deals["index"][dealsCount] = index
            deals["closeLong"][dealsCount] = deal_price
            deals["dealProfit"][dealsCount] = tradeProfit
            deals["MAE"][dealsCount] = round(math.max((deals["openLong"][dealsCount-1] - DS:L(index))/priceKoeff, deals["MAE"][dealsCount]),SCALE)
            deals["MFE"][dealsCount] = round(math.max((deal_price - deals["openLong"][dealsCount-1])/priceKoeff, deals["MFE"][dealsCount]),SCALE)
            if logDeals then
                myLog("Закрытие лонга "..tostring(deals["openLong"][dealsCount-1]).." по цене "..tostring(deal_price))
                myLog("Прибыль сделки "..tostring(tradeProfit))
                myLog("Прибыль по лонгам "..tostring(longProfit))
                myLog("Прибыль всего "..tostring(allProfit))
                myLog("equity "..tostring(equitySum))
            end
            lastDealPrice = 0
            TRAILING_ACTIVATED = false
            slPrice = 0
            slIndex = 0
            tpPrice = 0
        end
    end

    maxStop = 85
    reopenDealMaxStop = 75
    reopenPosAfterStop = 2
    reopenAfterStop = false

    if dealTime and slIndex ~= 0 and (index - slIndex) >= reopenPosAfterStop then
    --if dealTime and slIndex ~= 0 and slIndex+2>=index then
        if logDeals then
            myLog("--------------------------------------------------")
            myLog('index '..tostring(index).." тест после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
        end
        local currentTradeDirection = getTradeDirection(index, calcAlgoValue, calcTrend, DS)
        if currentTradeDirection == 1 and deals["closeLong"][dealsCount]~=nil then
            if DS:C(index-3)<DS:C(index-1) and DS:C(index-2)<DS:C(index) and DS:C(index-1)<DS:C(index) then --and DS:O(index-1)<DS:C(index-1) and DS:O(index)<DS:C(index)
            --if DS:C(index-3)<DS:C(index-2) and DS:C(index-2)<DS:C(index-1) and DS:C(index-1)<DS:C(index) then
            --if deals["closeLong"][dealsCount]<DS:C(index-1) and deals["closeLong"][dealsCount]<DS:C(index-2) then
                if logDeals then
                    myLog("переоткрытие лонга после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
                end
                lastTradeDirection = currentTradeDirection
                reopenAfterStop = true
            end
        end
        if currentTradeDirection == -1 and deals["closeShort"][dealsCount]~=nil then
            if DS:C(index-3)>DS:C(index-1) and DS:C(index-2)>DS:C(index) and DS:C(index-1)>DS:C(index) then --and DS:O(index-1)>DS:C(index-1) and DS:O(index)>DS:C(index)
            --if DS:C(index-3)>DS:C(index-2) and DS:C(index-2)>DS:C(index-1) and DS:C(index-1)>DS:C(index) then
            --if deals["closeShort"][dealsCount]>DS:C(index-1) and deals["closeShort"][dealsCount]>DS:C(index-2) then
                if logDeals then
                    myLog("переоткрытие шорта после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
                end
                lastTradeDirection = currentTradeDirection
                reopenAfterStop = true
            end
        end
        --slIndex = index
    end

    if (tradeSignal == 1 or lastTradeDirection == 1) and dealTime and not closeDeal then

        dealsCount = dealsCount + 1
        if initalAssets == 0 then
            initalAssets = DS:O(index)/priceKoeff
            equitySum = initalAssets
        end
        if logDeals then
            myLog("--------------------------------------------------")
            myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
            myLog("tradeSignal "..tostring(tradeSignal).." lastTradeDirection "..tostring(lastTradeDirection).." openShort "..tostring(deals["openShort"][dealsCount-1])..' openLong '..tostring(deals["openLong"][dealsCount-1]))
        end

        lastTradeDirection = 0
        if deals["openShort"][dealsCount-1] ~= nil then
            local deal_price = DS:O(index)+slippery*SEC_PRICE_STEP
            local tradeProfit = round(lastDealPrice - deal_price, SCALE)/priceKoeff
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
            deals["closeShort"][dealsCount] = deal_price
            deals["dealProfit"][dealsCount] = tradeProfit
            deals["MAE"][dealsCount] = round(math.max((deal_price - deals["openShort"][dealsCount-1])/priceKoeff, deals["MAE"][dealsCount]), SCALE)
            deals["MFE"][dealsCount] = round(math.max((deals["openShort"][dealsCount-1] - deal_price)/priceKoeff, deals["MFE"][dealsCount]), SCALE)
            if logDeals then
                myLog("Закрытие шорта "..tostring(deals["openShort"][dealsCount-1]).." по цене "..tostring(deal_price))
                myLog("Прибыль сделки "..tostring(tradeProfit))
                myLog("Прибыль по шортам "..tostring(shortProfit))
                myLog("Прибыль всего "..tostring(allProfit))
                myLog("equity "..tostring(equitySum))
            end
        end
        if isLong == 1 then
            dealsLongCount = dealsLongCount + 1
            lastDealPrice = DS:O(index)+slippery*SEC_PRICE_STEP
            TransactionPrice = lastDealPrice
            TRAILING_ACTIVATED = false
            if STOP_LOSS~=0 then
                --slPrice = lastDealPrice - STOP_LOSS*priceKoeff
                local atPrice = calcAlgoValue[index-1]
                local shiftSL = (kATR*ATR[index-1] + 40*SEC_PRICE_STEP)
                if (atPrice - shiftSL) >= TransactionPrice then
                    atPrice = TransactionPrice
                end
                if settings.fixedstop==1 then
                    shiftSL = STOP_LOSS*priceKoeff
                    atPrice = TransactionPrice
                end
                slPrice = round(atPrice - shiftSL, SCALE)
                if reopenAfterStop then dealMaxStop = reopenDealMaxStop else dealMaxStop = maxStop end
                if (lastDealPrice - slPrice) > dealMaxStop*priceKoeff then slPrice = lastDealPrice - dealMaxStop*priceKoeff end
                reopenAfterStop = false
                slIndex = 0
                lastStopShiftIndex = index
            end
            if TAKE_PROFIT~=0 then
                tpPrice = round(lastDealPrice + TAKE_PROFIT*priceKoeff, SCALE)
                --tpPrice = round(lastDealPrice + 2*STOP_LOSS*priceKoeff, SCALE)
            end
            deals["index"][dealsCount] = index
            deals["openLong"][dealsCount] = lastDealPrice
            deals["MAE"][dealsCount+1] = 0
            deals["MFE"][dealsCount+1] = 0
            if logDeals then
                myLog("Покупка по цене "..tostring(lastDealPrice).." SL "..tostring(slPrice).." TP "..tostring(tpPrice))
                myLog("STOP_LOSS "..tostring(STOP_LOSS).." TAKE_PROFIT "..tostring(TAKE_PROFIT).." kATR "..tostring(kATR).." ATR "..tostring(ATR[index-1]).." calcAlgoValue "..tostring(calcAlgoValue[index-1]))
                myLog("slPrice "..tostring(slPrice).." tpPrice "..tostring(tpPrice))
            end
        else
            lastDealPrice = 0
            TRAILING_ACTIVATED = false
        end
    end
    if (tradeSignal == -1 or lastTradeDirection == -1) and dealTime and not closeDeal then

        dealsCount = dealsCount + 1
        if initalAssets == 0 then
            initalAssets = DS:O(index)/priceKoeff
        end
        if logDeals then
            myLog("--------------------------------------------------")
            myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index)))
            myLog("tradeSignal "..tostring(tradeSignal).." lastTradeDirection "..tostring(lastTradeDirection).." openShort "..tostring(deals["openShort"][dealsCount-1])..' openLong '..tostring(deals["openLong"][dealsCount-1]))
        end
        lastTradeDirection = 0
        if deals["openLong"][dealsCount-1] ~= nil then
            local deal_price = DS:O(index)-slippery*SEC_PRICE_STEP
            local tradeProfit = round(deal_price - lastDealPrice, SCALE)/priceKoeff
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
            deals["closeLong"][dealsCount] = deal_price
            deals["dealProfit"][dealsCount] = tradeProfit
            deals["MAE"][dealsCount] = round(math.max((deals["openLong"][dealsCount-1] - deal_price)/priceKoeff, deals["MAE"][dealsCount]),SCALE)
            deals["MFE"][dealsCount] = round(math.max((deal_price - deals["openLong"][dealsCount-1])/priceKoeff, deals["MFE"][dealsCount]),SCALE)
            if logDeals then
                myLog("Закрытие лонга "..tostring(deals["openLong"][dealsCount-1]).." по цене "..tostring(deal_price))
                myLog("Прибыль сделки "..tostring(tradeProfit))
                myLog("Прибыль по лонгам "..tostring(longProfit))
                myLog("Прибыль всего "..tostring(allProfit))
                myLog("equity "..tostring(equitySum))
            end
        end
        if isShort == 1 then
            dealsShortCount = dealsShortCount + 1
            lastDealPrice = DS:O(index)-slippery*SEC_PRICE_STEP
            TransactionPrice = lastDealPrice
            TRAILING_ACTIVATED = false
            if STOP_LOSS~=0 then
                --slPrice = lastDealPrice + STOP_LOSS*priceKoeff
                local atPrice = calcAlgoValue[index-1]
                local shiftSL = (kATR*ATR[index-1] + 40*SEC_PRICE_STEP)
                if (atPrice + shiftSL) <= TransactionPrice then
                    atPrice = TransactionPrice
                end
                if settings.fixedstop==1 then
                    shiftSL = STOP_LOSS*priceKoeff
                    atPrice = TransactionPrice
                end
                slPrice = round(atPrice + shiftSL, SCALE)
                if reopenAfterStop then dealMaxStop = reopenDealMaxStop else dealMaxStop = maxStop end
                if (slPrice - lastDealPrice) > dealMaxStop*priceKoeff then slPrice = lastDealPrice + dealMaxStop*priceKoeff end
                reopenAfterStop = false
                slIndex = 0
                lastStopShiftIndex = index
            end
            if TAKE_PROFIT~=0 then
                tpPrice = round(lastDealPrice - TAKE_PROFIT*priceKoeff, SCALE)
                --tpPrice = round(lastDealPrice - 2*STOP_LOSS*priceKoeff, SCALE)
            end
            deals["index"][dealsCount] = index
            deals["openShort"][dealsCount] = lastDealPrice
            deals["MAE"][dealsCount+1] = 0
            deals["MFE"][dealsCount+1] = 0
            if logDeals then
                myLog("Продажа по цене "..tostring(lastDealPrice).." SL "..tostring(slPrice).." TP "..tostring(tpPrice))
                myLog("STOP_LOSS "..tostring(STOP_LOSS).." TAKE_PROFIT "..tostring(TAKE_PROFIT).." kATR "..tostring(kATR).." ATR "..tostring(ATR[index-1]).." calcAlgoValue "..tostring(calcAlgoValue[index-1]))
                myLog("slPrice "..tostring(slPrice).." tpPrice "..tostring(tpPrice))
            end
        else
            lastDealPrice = 0
        end
    end

    checkSL_TP(index, calcAlgoValue, calcTrend, DS, isLong, isShort, deals, settings, logDeals, equitySum, STOP_LOSS, TAKE_PROFIT, TRAILING_SIZE, TRAILING_SIZE_STEP)

    if deals["openShort"][dealsCount] ~= nil then
        deals["MAE"][dealsCount+1] = round(math.max((DS:H(index) - deals["openShort"][dealsCount])/priceKoeff, deals["MAE"][dealsCount+1]), SCALE)
        deals["MFE"][dealsCount+1] = round(math.max((deals["openShort"][dealsCount] - DS:L(index))/priceKoeff, deals["MFE"][dealsCount+1]), SCALE)
    end
    if deals["openLong"][dealsCount] ~= nil then
        deals["MAE"][dealsCount+1] = round(math.max((deals["openLong"][dealsCount] - DS:L(index))/priceKoeff, deals["MAE"][dealsCount+1]),SCALE)
        deals["MFE"][dealsCount+1] = round(math.max((DS:H(index) - deals["openLong"][dealsCount])/priceKoeff, deals["MFE"][dealsCount+1]),SCALE)
    end

    if index == settings.endIndex and (deals["openShort"][dealsCount] ~= nil or deals["openLong"][dealsCount] ~= nil) then

        if logDeals then
            myLog("--------------------------------------------------")
            myLog("last index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index)))
        end

        if initalAssets == 0 then
            initalAssets = DS:O(index)/priceKoeff
            equitySum = initalAssets
        end

        if deals["openShort"][dealsCount] ~= nil then
            dealsCount = dealsCount + 1
            local tradeProfit = round(lastDealPrice - DS:C(index), SCALE)/priceKoeff
            shortProfit = shortProfit + tradeProfit
            allProfit = allProfit + tradeProfit
            equitySum = equitySum + tradeProfit
            if tradeProfit > 0 then
                profitDealsShortCount = profitDealsShortCount + 1
            end
            deals["index"][dealsCount] = index
            deals["closeShort"][dealsCount] = DS:C(index)
            deals["dealProfit"][dealsCount] = tradeProfit
            deals["MAE"][dealsCount] = round(math.max((DS:H(index) - deals["openShort"][dealsCount-1])/priceKoeff, deals["MAE"][dealsCount]), SCALE)
            deals["MFE"][dealsCount] = round(math.max((deals["openShort"][dealsCount-1] - DS:L(index))/priceKoeff, deals["MFE"][dealsCount]), SCALE)
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
            local tradeProfit = round(DS:O(index) - lastDealPrice, SCALE)/priceKoeff
            longProfit = longProfit + tradeProfit
            allProfit = allProfit + tradeProfit
            equitySum = equitySum + tradeProfit
            if tradeProfit > 0 then
                profitDealsLongCount = profitDealsLongCount + 1
            end
            deals["index"][dealsCount] = index
            deals["closeLong"][dealsCount] = DS:C(index)
            deals["dealProfit"][dealsCount] = tradeProfit
            deals["MAE"][dealsCount] = round(math.max((deals["openLong"][dealsCount-1] - DS:L(index))/priceKoeff, deals["MAE"][dealsCount]),SCALE)
            deals["MFE"][dealsCount] = round(math.max((DS:H(index) - deals["openLong"][dealsCount-1])/priceKoeff, deals["MFE"][dealsCount]),SCALE)
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

function checkSL_TP(index, calcAlgoValue, calcTrend, DS, isLong, isShort, deals, settings, logDeals, equitySum, STOP_LOSS, TAKE_PROFIT, TRAILING_SIZE, TRAILING_SIZE_STEP)

    if (slPrice~=0 or tpPrice~=0) and lastDealPrice~=0 then

        if deals["openLong"][dealsCount] ~= nil then
            if slPrice~=0 and DS:L(index) <= slPrice then
                dealsCount = dealsCount + 1
                slPrice = slPrice-slippery*SEC_PRICE_STEP
                local tradeProfit = round(slPrice - lastDealPrice, SCALE)/priceKoeff
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
                deals["MAE"][dealsCount] = round(math.max((deals["openLong"][dealsCount-1] - slPrice)/priceKoeff, deals["MAE"][dealsCount]),SCALE)
                deals["MFE"][dealsCount] = round(math.max((DS:H(index) - deals["openLong"][dealsCount-1])/priceKoeff, deals["MFE"][dealsCount]),SCALE)
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
                TRAILING_ACTIVATED = false
                slPrice = 0
                tpPrice = 0
            end
            if tpPrice~=0 and DS:H(index) >= tpPrice then
                dealsCount = dealsCount + 1
                tpPrice = tpPrice-slippery*SEC_PRICE_STEP
                local tradeProfit = round(tpPrice - lastDealPrice, SCALE)/priceKoeff
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
                deals["MAE"][dealsCount] = round(math.max((deals["openLong"][dealsCount-1] - DS:L(index))/priceKoeff, deals["MAE"][dealsCount]),SCALE)
                deals["MFE"][dealsCount] = round(math.max((tpPrice - deals["openLong"][dealsCount-1])/priceKoeff, deals["MFE"][dealsCount]),SCALE)
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
                TRAILING_ACTIVATED = false
                slPrice = 0
                slIndex = index
                tpPrice = 0
            end
            --if deals["closeLong"][dealsCount] == nil and DS:H(index) - deals["openLong"][dealsCount] >= STOP_LOSS*0.8*priceKoeff and slPrice < deals["openLong"][dealsCount] then
            --    if logDeals then
            --        myLog("--------------------------------------------------")
            --        myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
            --    end
            --    if slPrice~=0 then
            --        slPrice = round(deals["openLong"][dealsCount] + 0*SEC_PRICE_STEP, SCALE)
            --        if logDeals then
            --            myLog("Сдвиг стоп-лосса в безубыток"..tostring(slPrice))
            --        end
            --    end
            --end
            local isPriceMove = false
            if TRAILING_SIZE~=0 and TRAILING_SIZE_STEP~=0 then
                if not TRAILING_ACTIVATED then
                    isPriceMove = (DS:H(index) - TransactionPrice >= TRAILING_SIZE*priceKoeff)
                    if isPriceMove then TRAILING_ACTIVATED = true end
                else
                    isPriceMove = (DS:H(index) - TransactionPrice >= TRAILING_SIZE_STEP*priceKoeff)
                end
            elseif TRAILING_SIZE_STEP~=0 then
                if not TRAILING_ACTIVATED then
                    isPriceMove = (DS:H(index) - TransactionPrice >= STOP_LOSS*priceKoeff) and STOP_LOSS~=0
                    if isPriceMove then TRAILING_ACTIVATED = true end
                else
                    isPriceMove = (DS:H(index) - TransactionPrice >= TRAILING_SIZE_STEP*priceKoeff)
                end
            else
                isPriceMove = (DS:H(index) - TransactionPrice >= STOP_LOSS*priceKoeff) and STOP_LOSS~=0
            end
            if (settings.shiftStop==1 or settings.shiftProfit==1) and (isPriceMove or (index - lastStopShiftIndex)>stopShiftIndexWait) and deals["closeLong"][dealsCount] == nil then
                lastStopShiftIndex = index
                --local shiftCounts = math.floor((DS:H(index) - TransactionPrice)/(((TRAILING_ACTIVATED and TRAILING_SIZE_STEP~=0) and TRAILING_SIZE_STEP or STOP_LOSS)*priceKoeff))
                local priceMoveVal = (DS:H(index) - TransactionPrice)
                if logDeals then
                    myLog("--------------------------------------------------")
                    myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount)..' isPriceMove '..tostring(isPriceMove))
                    myLog("priceMoveVal "..tostring(priceMoveVal).." TransactionPrice "..tostring(TransactionPrice).." H "..tostring(DS:H(index)).." calcAlgoValue[index-1] "..tostring(calcAlgoValue[index-1]).." STOP_LOSS*priceKoeff "..tostring(STOP_LOSS*priceKoeff))
                    myLog("TRAILING_ACTIVATED "..tostring(TRAILING_ACTIVATED).." TRAILING_SIZE_STEP*priceKoeff "..tostring(TRAILING_SIZE_STEP*priceKoeff).." TRAILING_SIZE*priceKoeff "..tostring(TRAILING_SIZE*priceKoeff))
                end
                if slPrice~=0 and settings.shiftStop==1 then
                    local oldStop = slPrice
                    --slPrice = DS:H(index) - STOP_LOSS*priceKoeff
                    local atPrice = calcAlgoValue[index-1]
                    local shiftSL = (kATR*ATR[index-1] + 40*SEC_PRICE_STEP)
                    --TransactionPrice = TransactionPrice+STOP_LOSS*priceKoeff
                    TransactionPrice = DS:H(index)
                    if (atPrice - shiftSL) >= TransactionPrice then
                        atPrice = TransactionPrice
                    end
                    --slPrice = round(atPrice - shiftSL, SCALE)
                    if settings.fixedstop==1 then
                        shiftSL = STOP_LOSS*priceKoeff
                        atPrice = TransactionPrice
                    end
                    slPrice = math.max(round(atPrice - shiftSL, SCALE), round(deals["openLong"][dealsCount] + 0*SEC_PRICE_STEP, SCALE))
                    if (deals["openLong"][dealsCount] - slPrice) > maxStop*priceKoeff then slPrice = deals["openLong"][dealsCount] - maxStop*priceKoeff end
                    slPrice = math.min(math.max(oldStop,slPrice), DS:L(index))
                    if logDeals then
                        myLog("Сдвиг стоп-лосса "..tostring(slPrice))
                        myLog("new TransactionPrice "..tostring(TransactionPrice))
                    end
                end
                if tpPrice~=0 and isPriceMove and settings.shiftProfit==1 then --slPrice~=0 and
                    --tpPrice = round(tpPrice + shiftCounts*((TRAILING_ACTIVATED and TRAILING_SIZE_STEP~=0) and TRAILING_SIZE_STEP or STOP_LOSS)*priceKoeff/2, SCALE)
                    tpPrice = round(tpPrice + priceMoveVal/2, SCALE)
                    if logDeals then
                        myLog("Сдвиг тейка "..tostring(tpPrice))
                    end
                end
            end
        end

        if deals["openShort"][dealsCount] ~= nil then
            if slPrice~=0 and DS:H(index) >= slPrice then
                dealsCount = dealsCount + 1
                slPrice = slPrice+slippery*SEC_PRICE_STEP
                local tradeProfit = round(lastDealPrice - slPrice, SCALE)/priceKoeff
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
                deals["MAE"][dealsCount] = round(math.max((slPrice - deals["openShort"][dealsCount-1])/priceKoeff, deals["MAE"][dealsCount]), SCALE)
                deals["MFE"][dealsCount] = round(math.max((deals["openShort"][dealsCount-1] - DS:L(index))/priceKoeff, deals["MFE"][dealsCount]), SCALE)
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
                TRAILING_ACTIVATED = false
                slPrice = 0
                tpPrice = 0
            end
            if tpPrice~=0 and DS:L(index) <= tpPrice then
                dealsCount = dealsCount + 1
                tpPrice = tpPrice-slippery*SEC_PRICE_STEP
                local tradeProfit = round(lastDealPrice - tpPrice, SCALE)/priceKoeff
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
                deals["MAE"][dealsCount] = round(math.max((DS:H(index) - deals["openShort"][dealsCount-1])/priceKoeff, deals["MAE"][dealsCount]), SCALE)
                deals["MFE"][dealsCount] = round(math.max((deals["openShort"][dealsCount-1] - tpPrice)/priceKoeff, deals["MFE"][dealsCount]), SCALE)
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
                TRAILING_ACTIVATED = false
                slPrice = 0
                slIndex = index
                tpPrice = 0
            end
            --if deals["closeShort"][dealsCount] == nil and (deals["openShort"][dealsCount] - DS:L(index)) >= STOP_LOSS*0.8*priceKoeff and slPrice > deals["openShort"][dealsCount] then
            --    if logDeals then
            --        myLog("--------------------------------------------------")
            --        myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
            --    end
            --    if slPrice~=0 then
            --        slPrice = round(deals["openShort"][dealsCount] + 0*SEC_PRICE_STEP, SCALE)
            --        if logDeals then
            --            myLog("Сдвиг стоп-лосса в безубыток"..tostring(slPrice))
            --        end
            --    end
            --end
            local isPriceMove = false
            if TRAILING_SIZE~=0 and TRAILING_SIZE_STEP~=0 then
                if not TRAILING_ACTIVATED then
                    isPriceMove = (TransactionPrice - DS:L(index) >= TRAILING_SIZE*priceKoeff)
                    if isPriceMove then TRAILING_ACTIVATED = true end
                else
                    isPriceMove = (TransactionPrice - DS:L(index) >= TRAILING_SIZE_STEP*priceKoeff)
                end
            elseif TRAILING_SIZE_STEP~=0 then
                if not TRAILING_ACTIVATED then
                    isPriceMove = (TransactionPrice - DS:L(index) >= STOP_LOSS*priceKoeff) and STOP_LOSS~=0
                    if isPriceMove then TRAILING_ACTIVATED = true end
                else
                    isPriceMove = (TransactionPrice - DS:L(index) >= TRAILING_SIZE_STEP*priceKoeff)
                end
            else
                isPriceMove = (TransactionPrice - DS:L(index) >= STOP_LOSS*priceKoeff) and STOP_LOSS~=0
            end
            if (settings.shiftStop==1 or settings.shiftProfit==1) and (isPriceMove or (index - lastStopShiftIndex)>stopShiftIndexWait) and deals["closeShort"][dealsCount] == nil then
                lastStopShiftIndex = index
                --local shiftCounts = math.floor((TransactionPrice - DS:L(index))/(((TRAILING_ACTIVATED and TRAILING_SIZE_STEP~=0) and TRAILING_SIZE_STEP or STOP_LOSS)*priceKoeff))
                local priceMoveVal = (TransactionPrice - DS:L(index))
                if logDeals then
                    myLog("--------------------------------------------------")
                    myLog("index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount)..' isPriceMove '..tostring(isPriceMove))
                    myLog("priceMoveVal "..tostring(priceMoveVal).." TransactionPrice "..tostring(TransactionPrice).." L(index) "..tostring(DS:L(index)).." calcAlgoValue[index-1] "..tostring(calcAlgoValue[index-1]).." STOP_LOSS*priceKoeff "..tostring(STOP_LOSS*priceKoeff))
                    myLog("TRAILING_ACTIVATED "..tostring(TRAILING_ACTIVATED).." TRAILING_SIZE_STEP*priceKoeff "..tostring(TRAILING_SIZE_STEP*priceKoeff).." TRAILING_SIZE*priceKoeff "..tostring(TRAILING_SIZE*priceKoeff))
                end
                if slPrice~=0  and settings.shiftStop==1 then
                    local oldStop = slPrice
                    --slPrice = DS:L(index) + STOP_LOSS*priceKoeff
                    local atPrice = calcAlgoValue[index-1]
                    local shiftSL = (kATR*ATR[index-1] + 40*SEC_PRICE_STEP)
                    --TransactionPrice = TransactionPrice-STOP_LOSS*priceKoeff
                    TransactionPrice = DS:L(index)
                    if (atPrice + shiftSL) <= TransactionPrice then
                        atPrice = TransactionPrice
                    end
                    --slPrice = round(atPrice + shiftSL, SCALE)
                    if settings.fixedstop==1 then
                        shiftSL = STOP_LOSS*priceKoeff
                        atPrice = TransactionPrice
                    end
                    slPrice = math.min(round(atPrice + shiftSL, SCALE), round(deals["openShort"][dealsCount] - 0*SEC_PRICE_STEP, SCALE))
                    if (slPrice-deals["openShort"][dealsCount]) > maxStop*priceKoeff then slPrice =  deals["openShort"][dealsCount] + maxStop*priceKoeff end
                    slPrice = math.max(math.min(oldStop,slPrice), DS:H(index))

                    if logDeals then
                        myLog("Сдвиг стоп-лосса "..tostring(slPrice))
                        myLog("new TransactionPrice "..tostring(TransactionPrice))
                    end
                end
                if tpPrice~=0 and isPriceMove and settings.shiftProfit==1 then --slPrice~=0 and
                    --tpPrice = round(tpPrice - shiftCounts*((TRAILING_ACTIVATED and TRAILING_SIZE_STEP~=0) and TRAILING_SIZE_STEP or STOP_LOSS)*priceKoeff/2, SCALE)
                    tpPrice = round(tpPrice - priceMoveVal/2, SCALE)
                    if logDeals then
                        myLog("Сдвиг тейка "..tostring(tpPrice))
                    end
                end
            end
        end
    end

end

function openResults(resultsTable, settingTable, sortColumn, isSort)

    --myLog("-----------------------------------------------")
    --myLog("-----------------------------------------------")

    --//TODO: interval as column in results
    --// TODO: Y/N  отключение/включение отображение индикаторов equityTester,  algoResults
    if not isRun then return end

    local resultsSortTable = {}
    local count = #resultsTable
    for kk = 1, count do
        resultsSortTable[kk] = {}
        local n = 1
        local keyValueSetting = 0
        local columns = #resultsTable[kk]
        local lineSettings = resultsTable[kk][1]
        for i=1,columns do
            resultsSortTable[kk][i] = resultsTable[kk][i]
        end
        for k,v in pairs(settingTable) do
            local keyValueSetting = lineSettings[k]
            if type(keyValueSetting) == 'table' then
                for kkk,vvv in pairs(keyValueSetting) do
                    local keyValueSettingT = keyValueSetting[kkk]
                    resultsSortTable[kk][fixResColumnCount+n+1] = keyValueSettingT
                    --myLog("number "..tostring(15 + n).." col "..tostring(kkk)..", val "..tostring(keyValueSettingT))
                    n = n+1
                end
            else
                resultsSortTable[kk][fixResColumnCount+n+1] = keyValueSetting
                --myLog("number "..tostring(15 + n).." col "..tostring(k)..", val "..tostring(keyValueSetting))
                n = n+1
            end
        end
        resultsSortTable[kk][fixResColumnCount+n+1] = kk
    end
    if sortColumn == nil then
        sortColumn = 5
    end

    if not isSort or true then
        table.sort(resultsSortTable, function(a,b) return (a[sortColumn] or 0) < (b[sortColumn] or 0) end)
    end

    if IsWindowClosed(tres_id) then

        local n = 1
        for k,v in pairs(settingTable) do
            if type(v) == 'table' then
                for kkk,vvv in pairs(v) do
                    AddColumn(tres_id, fixResColumnCount+n-1, kkk, true, QTABLE_DOUBLE_TYPE, 10)
                    --myLog("number "..tostring(fixResColumnCount + n)..", val "..tostring(kkk))
                    n = n+1
                end
            else
                AddColumn(tres_id, fixResColumnCount+n-1, k, true, QTABLE_DOUBLE_TYPE, 10)
                --myLog("number "..tostring(fixResColumnCount + n)..", val "..tostring(k))
                n = n+1
            end
        end

        idResColumn = fixResColumnCount+n-1
        AddColumn(tres_id, idResColumn, "id", true, QTABLE_DOUBLE_TYPE, 1)

        tres = CreateWindow(tres_id)
        SetWindowCaption(tres_id, "Results")
        SetWindowPos(tres_id, 10, 160, 1600, 850)

    end

    Clear(tres_id)

    local interval = tostring(GetCell(t_id, lineTask, 4).value) or SEC_CODES['interval'][resultsSortTable[line][2]]

    for kk = 1, count do
        InsertRow(tres_id, kk)
        --line = count-kk+1
        line = kk
        SetCell(tres_id, kk, 0, SEC_CODES['names'][resultsSortTable[line][2]], resultsSortTable[line][2])
        SetCell(tres_id, kk, 1, ALGORITHMS['names'][resultsSortTable[line][3]].." "..interval, resultsSortTable[line][3])
        SetCell(tres_id, kk, 2, tostring(resultsSortTable[line][4]), resultsSortTable[line][4])
        SetCell(tres_id, kk, 3, tostring(resultsSortTable[line][5]), resultsSortTable[line][5])
        SetCell(tres_id, kk, 4, tostring(resultsSortTable[line][6]), resultsSortTable[line][6])
        SetCell(tres_id, kk, 5, tostring(resultsSortTable[line][7]), resultsSortTable[line][7])
        SetCell(tres_id, kk, 6, tostring(resultsSortTable[line][8]), 0)
        SetCell(tres_id, kk, 7, tostring(resultsSortTable[line][9]), 0)
        SetCell(tres_id, kk, 8, tostring(resultsSortTable[line][10]), 0)
        SetCell(tres_id, kk, 9, tostring(resultsSortTable[line][11]), 0)
        SetCell(tres_id, kk, 10, tostring(resultsSortTable[line][12]), resultsSortTable[line][12])
        SetCell(tres_id, kk, 11, tostring(resultsSortTable[line][13]), resultsSortTable[line][13])
        SetCell(tres_id, kk, 12, tostring(resultsSortTable[line][14]), resultsSortTable[line][14])
        SetCell(tres_id, kk, 13, tostring(resultsSortTable[line][15]), resultsSortTable[line][15])
        SetCell(tres_id, kk, 14, tostring(resultsSortTable[line][16]), resultsSortTable[line][16])
        SetCell(tres_id, kk, 15, tostring(resultsSortTable[line][17]), resultsSortTable[line][17])
        SetCell(tres_id, kk, 16, tostring(resultsSortTable[line][18]), resultsSortTable[line][18])
        SetCell(tres_id, kk, 17, tostring(resultsSortTable[line][19]), resultsSortTable[line][19])
        SetCell(tres_id, kk, 18, tostring(resultsSortTable[line][20]), resultsSortTable[line][20])
        SetCell(tres_id, kk, 19, tostring(resultsSortTable[line][21]), resultsSortTable[line][21])
        SetCell(tres_id, kk, 20, tostring(resultsSortTable[line][22]), resultsSortTable[line][22])

        local n = 1
        local keyValueSetting = 0
        for k,v in pairs(settingTable) do
            --keyValueSetting = resultsSortTable[line][#resultsSortTable[line]][k]
            keyValueSetting = resultsSortTable[line][fixResColumnCount+n+1]
            if type(v) == 'table' then
                for kkk,vvv in pairs(v) do
                    keyValueSetting = resultsSortTable[line][fixResColumnCount+n+1]
                    SetCell(tres_id, kk, fixResColumnCount+n-1, tostring(keyValueSetting), keyValueSetting)
                    --myLog("number "..tostring(fixResColumnCount + n).." col "..tostring(kkk)..", val "..tostring(keyValueSetting))
                    n = n+1
                end
            else
                SetCell(tres_id, kk, fixResColumnCount+n-1, tostring(keyValueSetting), keyValueSetting)
                --myLog("number "..tostring(fixResColumnCount + n).." col "..tostring(k)..", val "..tostring(keyValueSetting))
                n = n+1
            end
        end
        SetCell(tres_id, kk, fixResColumnCount+n-1, tostring(resultsSortTable[line][fixResColumnCount+n+1]), resultsSortTable[line][fixResColumnCount+n+1])
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
    if not logging or logFile==nil then return end

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

function round(num, idp)
    if num then
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
