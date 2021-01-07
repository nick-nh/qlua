-------------------------------------------
--Оптимизация
test_startTradeTime         = 1018       -- Начало торговли для теста
test_endTradeTime           = 1842       -- Окончание торговли для теста

RFR                         = 0 --7.42 --безрискова ставка для расчета коэфф. Шарпа

stopSignal                  = false
doneOptimization            = 0
optimizationInProgress      = false
needReoptimize              = false

beginIndex                  = 1
endIndex                    = 1
beginIndexallProfit         = 0
shortProfit                 = 0
longProfit                  = 0
lastDealPrice               = 0
stopLevelPrice              = 0
lastTradeDirection          = 0
dealsCount                  = 0
dealsLongCount              = 0
dealsShortCount             = 0
algoResults                 = nil
profitDealsLongCount        = 0
profitDealsShortCount       = 0
slDealsLongCount            = 0
tpDealsLongCount            = 0
slDealsShortCount           = 0
tpDealsShortCount           = 0
ratioProfitDeals            = 0
initalAssets                = 0
deals                       = {}
resultsTables               = {}

logDeals = false

function readOptimizedParams()

    local func, err = loadfile(PARAMS_FILE_NAME)
    if not func then
        myLog(NAME_OF_STRATEGY.." Ошибка при загрузке файла параметров "..PARAMS_FILE_NAME..", err: "..tostring(err))
        return nil
    else
       return func()
    end
end

function saveOptimizedParams(settings)

    local ParamsFile = io.open(PARAMS_FILE_NAME,"w")

    myLog(NAME_OF_STRATEGY..'----- Запись оптимальных установок пресета '..presets[curPreset].Name)

    for k,v in pairs(globalSettings) do
        if settings[k]~=nil then v = settings[k] end
        if type(v) == 'string' then
            ParamsFile:write(k..' = "'..tostring(v)..'"\n')
        else
            ParamsFile:write(k..' = '..tostring(v)..'\n')
        end
    end
    for par, field in pairs(presets[curPreset].fields) do
        local val = settings[par]
        if val~=nil then
            if type(val) == 'string' then
                ParamsFile:write('Settings.'..par..' = "'..tostring(val)..'"\n')
            else
                ParamsFile:write('Settings.'..par..' = '..tostring(val)..'\n')
            end
        end
    end
    ParamsFile:flush()
    ParamsFile:close()

end

function reoptimize()

    ROBOT_STATE = 'ОПТИМИЗАЦИЯ'
    BASE_ROBOT_STATE = 'ОПТИМИЗАЦИЯ'

    if isTrade then
        isTrade = false
    end

    maintable:SetValue('State', ROBOT_STATE, 0)
    maintable:SetValue('START', 'START', 0)
    maintable:SetColor('START', RGB(165,227,128), RGB(0,0,0), RGB(165,227,128), RGB(0,0,0))
    SetAlgo()

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
        maintable:SetValue('State', ROBOT_STATE, 0)
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

--- ОПТИМИЗАЦИЯ
function iterateAlgorithm(settingsTable)

    local resultsTable = {}

    isTrade = false
    optimizationInProgress = true

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
                if firstDay and serverTime < dayClearing then
                    days = days - 1
                    firstDay = false
                end
            end
            if days == -1*testSizeBars then break end
        end
    end

    myLog(NAME_OF_STRATEGY..'---------------------------------------------------')
    myLog(NAME_OF_STRATEGY..' Start optimization '..presets[curPreset].Name)
    for k,v in pairs(Settings) do
        myLog(k..' '..tostring(v))
    end
    myLog(NAME_OF_STRATEGY..'-----------')

    --local bars = endIndex - beginIndex
    myLog(NAME_OF_STRATEGY..' testSizeBars '..tostring(testSizeBars))
    myLog(NAME_OF_STRATEGY..' beginIndex '..tostring(beginIndex)..' - '..toYYYYMMDDHHMMSS(DS:T(beginIndex))..' endIndex '..tostring(endIndex)..' - '..toYYYYMMDDHHMMSS(DS:T(endIndex)))

    --Восстанавливаем настройки стоп-лосса и тейк-профита по умолчанию из пресета, чтобы избежать влияния прошлых результатов
    if presets[curPreset].TAKE_PROFIT ~= 0 then
        globalSettings.TAKE_PROFIT = presets[curPreset].TAKE_PROFIT
        TAKE_PROFIT = presets[curPreset].TAKE_PROFIT
    end
    if presets[curPreset].STOP_LOSS ~= 0 then
        globalSettings.STOP_LOSS = presets[curPreset].STOP_LOSS
        STOP_LOSS = presets[curPreset].STOP_LOSS
    end
    myLog('SL '..tostring(STOP_LOSS)..' TP '..tostring(TAKE_PROFIT))

    resultsTable = iterateTable(settingsTable, resultsTable)

    if not isRun then return end

    if #resultsTable > 1 then
        --ArraySortByColl(resultsTable, 3)
        table.sort(resultsTable, function(a,b) return a[1]<b[1] end)
    end

    local saveSettings_string = (#presets[curPreset].saveSettings_string==0 and '' or presets[curPreset].saveSettings_string..';')..optimizedSettings_string
    local optimizedSettings = {}
    for par in allWords(saveSettings_string, ';') do
        optimizedSettings[#optimizedSettings+1] = par
    end

    saveSettings_string = "line; INTERVAL; testSizeBars; allProfit; maxDown; lastDealSignal; trend; "..saveSettings_string

    if #resultsTable > 0 and iterateSLTP and SetStop then

        myLog(NAME_OF_STRATEGY.." list before iterate SL/TP")
        myLog(NAME_OF_STRATEGY.." ----------------------------------------------------------")
        local resultString = resultsTable[#resultsTable]
        local bestSettings = resultString[#resultString]
        myLog(saveSettings_string)

        local linesToIterateSLTP = 25

        for i=0,math.min(#resultsTable-1, linesToIterateSLTP) do
            resultString = resultsTable[#resultsTable - i]
            local settings = resultString[#resultString]
            paramsString = tostring(#resultsTable-i).."; "..tostring(INTERVAL).."; "..tostring(testSizeBars)
            for j=1,4 do
                paramsString = paramsString..'; '..tostring(resultString[j])
            end
            for k=1, #optimizedSettings do
                --myLog(optimizedSettings[k]..' global '..tostring(globalSettings[optimizedSettings[k]])..' settings '..tostring(bestSettings[optimizedSettings[k]]))
                if settings[optimizedSettings[k]]~=nil then
                    paramsString = paramsString..'; '..tostring(settings[optimizedSettings[k]])
                else
                    paramsString = paramsString..'; '..tostring(globalSettings[optimizedSettings[k]])
                end
            end
            myLog(paramsString)
        end

        local lines = math.min(linesToIterateSLTP, #resultsTable)
        local settingsTableSLTP = getSettingsSLTP(resultsTable, lines)
        local i = 1
        while i <= lines do
            table.remove(resultsTable, #resultsTable)
            i = i+1
        end

        --for i=1,#settingsTableSLTP do
        --    myLog("i "..tostring(i).." periodATR "..tostring(settingsTableSLTP[i].periodATR).." kATR "..tostring(settingsTableSLTP[i].kATR).." alpha "..tostring(settingsTableSLTP[i].alpha).." shift "..tostring(settingsTableSLTP[i].shift))
        --end

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
        --local needNewBest = minDrawDown>6
        local needNewBest = minDrawDown>20

        myLog(NAME_OF_STRATEGY.." ----------------------------------------------------------")
        myLog(saveSettings_string)
        myLog(NAME_OF_STRATEGY.." best")

        paramsString = tostring(#resultsTable).."; "..tostring(INTERVAL).."; "..tostring(testSizeBars)
        for j=1,4 do
            paramsString = paramsString.."; "..tostring(resultString[j])
        end
        for k=1, #optimizedSettings do
            if bestSettings[optimizedSettings[k]]~=nil then
                paramsString = paramsString..'; '..tostring(bestSettings[optimizedSettings[k]])
            else
                paramsString = paramsString..'; '..tostring(globalSettings[optimizedSettings[k]])
            end
        end
        myLog(paramsString)

        while isSearch and line >= 1 do

            if not isRun then return end
            CheckTradeSession()

            if minProfit > resultsTable[line][1] and not needNewBest then
                break
            end

            resultString = resultsTable[line]
            trendLine = resultsTable[line][4]
            algoLine = resultsTable[line][3]
            local onTrend = (trendLine < 0 and DS:C(DS:Size()) < algoLine) or (trendLine > 0 and DS:C(DS:Size()) > algoLine) or algoLine == 0

            if minDrawDown == resultsTable[line][2] and onTrend and not bestOnTrend then
                minDrawDown = resultsTable[line][2]
                --if minDrawDown<=6 then needNewBest = false end
                bestSettings = resultsTable[line][#resultsTable[line]]
                bestOnTrend = true
                myLog(NAME_OF_STRATEGY.." new best line "..tostring(line))
                paramsString = tostring(line).."; "..tostring(INTERVAL).."; "..tostring(testSizeBars)
                for j=1,4 do
                    paramsString = paramsString.."; "..tostring(resultString[j])
                end
                for k=1, #optimizedSettings do
                    if bestSettings[optimizedSettings[k]]~=nil then
                        paramsString = paramsString..'; '..tostring(bestSettings[optimizedSettings[k]])
                    else
                        paramsString = paramsString..'; '..tostring(globalSettings[optimizedSettings[k]])
                    end
                end
                myLog(paramsString)
            end
            if minDrawDown > resultsTable[line][2] and onTrend then
                minDrawDown = resultsTable[line][2]
                --if minDrawDown<=6 then needNewBest = false end
                bestSettings = resultsTable[line][#resultsTable[line]]
                myLog(NAME_OF_STRATEGY.." new best line "..tostring(line))
                paramsString = tostring(line).."; "..tostring(INTERVAL).."; "..tostring(testSizeBars)
                for j=1,4 do
                    paramsString = paramsString.."; "..tostring(resultString[j])
                end
                for k=1, #optimizedSettings do
                    if bestSettings[optimizedSettings[k]]~=nil then
                        paramsString = paramsString..'; '..tostring(bestSettings[optimizedSettings[k]])
                    else
                        paramsString = paramsString..'; '..tostring(globalSettings[optimizedSettings[k]])
                    end
                end
                myLog(paramsString)
            end
            line = line - 1
        end

        --не нашли лучший результат с приемлемой просадкой. Берем лучший по прибыли.
        if needNewBest then
            resultString = resultsTable[#resultsTable]
            bestSettings = resultString[#resultString]
            myLog(NAME_OF_STRATEGY.." ----------------------------------------------------------")
            myLog(NAME_OF_STRATEGY.." Не нашли лучший результат с приемлемой просадкой")
            myLog(NAME_OF_STRATEGY.." new best line "..tostring(#resultsTable))
        end

        myLog(NAME_OF_STRATEGY.." ----------------------------------------------------------")
        myLog(NAME_OF_STRATEGY.." list")
        for i=0,math.min(#resultsTable-1, 40) do
            resultString = resultsTable[#resultsTable - i]
            local settings = resultString[#resultString]
            paramsString = tostring(#resultsTable-i).."; "..tostring(INTERVAL).."; "..tostring(testSizeBars)
            for j=1,4 do
                paramsString = paramsString..'; '..tostring(resultString[j])
            end
            for k=1, #optimizedSettings do
                --myLog(optimizedSettings[k]..' global '..tostring(globalSettings[optimizedSettings[k]])..' settings '..tostring(settings[optimizedSettings[k]]))
                if settings[optimizedSettings[k]]~=nil then
                    paramsString = paramsString..'; '..tostring(settings[optimizedSettings[k]])
                else
                    paramsString = paramsString..'; '..tostring(globalSettings[optimizedSettings[k]])
                end
            end
            myLog(paramsString)
        end

        for k,v in pairs(bestSettings) do
            if globalSettings[k]~= nil then
                assert(loadstring(k..'='..tostring(v)))()
                globalSettings[k] = v
            end
        end

        setTableAlgoParams(bestSettings, presets[curPreset])
        maintable:SetValue('STOP_LOSS', tostring(STOP_LOSS), STOP_LOSS)
        maintable:SetValue('TAKE_PROFIT', tostring(TAKE_PROFIT), TAKE_PROFIT)

        optimizationInProgress = false
        saveOptimizedParams(bestSettings)

        return
    end

    optimizationInProgress = false
    myLog(NAME_OF_STRATEGY.." Нет положительных результатов оптимизации")
    message("Нет положительных результатов оптимизации")
end

function iterateTable(settingsTable, resultsTable)

    local localCount = 0
    local rescount = 0
    local allCount = #settingsTable

    for i,v in ipairs(settingsTable) do

        if not isRun then return end
        if stopSignal then
            stopSignal = false
            break
        end

        localCount = localCount + 1
        doneOptimization = round(localCount*100/allCount, 0)

        SetState("OPTIMIZATION "..tostring(doneOptimization).."%", doneOptimization)
        CheckTradeSession()

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

        local resultString = resultsTable[#resultsTable - i]

        for param4 = param4Min, param4Max, param4Step do
            for param5 = param5Min, param5Max, param5Step do
                allCount = allCount + 1
                settingsTable[allCount] = {}
                for i,v in pairs(resultString[#resultString]) do
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
    TRAILING_ACTIVATED = false
    TransactionPrice = 0

    for k,v in pairs(settingsTask) do
        if globalSettings[k]~= nil then
            assert(loadstring(k..'='..tostring(v)))()
            globalSettings[k] = v
        end
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

function simpleTrade(index, calcAlgoValue, calcTrend, deals)

    if index <= beginIndex then return nil end

    local equitySum = initalAssets or 0

    local t = DS:T(index)
    local dealTime = false
    local time = math.ceil((t.hour + t.min/100)*100)
    if time >= test_startTradeTime then
        dealTime = true
    end
    if time >= test_endTradeTime then
        dealTime = false
    end

    if CLASS_CODE == 'QJSIM' or CLASS_CODE == 'TQBR'  then
        dealTime = true
    end

    tradeSignal = getTradeSignal(index, calcAlgoValue, calcTrend)
    if not dealTime or os.time(DS:T(index)) == test_startTradeTime then
        lastTradeDirection = getTradeDirection(index-1, calcAlgoValue, calcTrend)
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
                myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
                myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
            end
            local tradeProfit = round(lastDealPrice - DS:O(index), SCALE)/priceKoeff
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
            TRAILING_ACTIVATED = false
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
            local tradeProfit = round(DS:O(index) - lastDealPrice, SCALE)/priceKoeff
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
            TRAILING_ACTIVATED = false
            lastDealPrice = 0
            slPrice = 0
            slIndex = 0
            tpPrice = 0
        end
    end

    --if dealTime and slIndex ~= 0 and (index - slIndex) == reopenPosAfterStop then
    if dealTime and slIndex ~= 0 and slIndex+2>=index then
        if logDeals then
            myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
            myLog(NAME_OF_STRATEGY..' index '..tostring(index).." тест после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
        end
        local currentTradeDirection = getTradeDirection(index, calcAlgoValue, calcTrend, DS)

        local spread        = round(DS:H(index)  - DS:L(index), SCALE)
        local close_up      = round((DS:C(index) - DS:L(index))/spread, SCALE) > 0.6
        local close_dw      = round((DS:H(index) - DS:C(index))/spread, SCALE) > 0.6

        if currentTradeDirection == 1 and deals["closeLong"][dealsCount]~=nil then
            --if deals["closeLong"][dealsCount]<DS:O(index) then
            if DS:C(index-2)<DS:C(index) and DS:C(index-2)<DS:C(index-1) and DS:C(index-1)<DS:C(index) and DS:O(index-1)<DS:C(index-1) and DS:O(index)<DS:C(index) and close_up then
                    --if DS:C(index-3)<DS:C(index-1) and DS:C(index-2)<DS:C(index) and DS:C(index-1)<DS:C(index) then
                if logDeals then
                    myLog(NAME_OF_STRATEGY.." переоткрытие лонга после стопа time "..toYYYYMMDDHHMMSS(DS:T(slIndex)))
                end
                lastTradeDirection = currentTradeDirection
                reopenAfterStop = true
            end
        end
        if currentTradeDirection == -1 and deals["closeShort"][dealsCount]~=nil then
            --if deals["closeShort"][dealsCount]>DS:O(index) then
            if DS:C(index-2)>DS:C(index) and DS:C(index-2)>DS:C(index-1) and DS:C(index-1)>DS:C(index) and DS:O(index-1)>DS:C(index-1) and DS:O(index)>DS:C(index) and close_dw then
            --if DS:C(index-3)<DS:C(index-1) and DS:C(index-2)<DS:C(index) and DS:C(index-1)<DS:C(index) then
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
            initalAssets = DS:O(index)/priceKoeff
            equitySum = initalAssets
        end
        if logDeals then
            myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
            myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount))
            myLog(NAME_OF_STRATEGY.." tradeSignal "..tostring(tradeSignal).." lastTradeDirection "..tostring(lastTradeDirection).." openShort "..tostring(deals["openShort"][dealsCount-1])..' openLong '..tostring(deals["openLong"][dealsCount-1]))
        end

        lastTradeDirection = 0
        if deals["openShort"][dealsCount-1] ~= nil then
            local tradeProfit = round(lastDealPrice - DS:O(index), SCALE)/priceKoeff
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
            TRAILING_ACTIVATED = false
            TransactionPrice = lastDealPrice
            if STOP_LOSS~=0 then
                --slPrice = lastDealPrice - STOP_LOSS*priceKoeff
                local atPrice = calcAlgoValue[index-1]
                local shiftSL = (kATR*ATR[index-1] + SL_ADD_STEPS*SEC_PRICE_STEP)
                if (atPrice - shiftSL) >= TransactionPrice then
                    atPrice = TransactionPrice
                end
                if fixedstop then
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
            end
            deals["index"][dealsCount] = index
            deals["openLong"][dealsCount] = DS:O(index)
            if logDeals then
                myLog(NAME_OF_STRATEGY.." Покупка по цене "..tostring(lastDealPrice).." SL "..tostring(slPrice).." TP "..tostring(tpPrice))
                myLog(NAME_OF_STRATEGY.." STOP_LOSS "..tostring(STOP_LOSS).." TAKE_PROFIT "..tostring(TAKE_PROFIT).." kATR "..tostring(kATR).." ATR "..tostring(ATR[index-1]).." calcAlgoValue "..tostring(calcAlgoValue[index-1]))
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
            myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
            myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index)))
            myLog(NAME_OF_STRATEGY.." tradeSignal "..tostring(tradeSignal).." lastTradeDirection "..tostring(lastTradeDirection).." openShort "..tostring(deals["openShort"][dealsCount-1])..' openLong '..tostring(deals["openLong"][dealsCount-1]))
        end
        lastTradeDirection = 0
        if deals["openLong"][dealsCount-1] ~= nil then
            local tradeProfit = round(DS:O(index) - lastDealPrice, SCALE)/priceKoeff
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
            TRAILING_ACTIVATED = false
            TransactionPrice = lastDealPrice
            if STOP_LOSS~=0 then
                --slPrice = lastDealPrice + STOP_LOSS*priceKoeff
                local atPrice = calcAlgoValue[index-1]
                local shiftSL = (kATR*ATR[index-1] + SL_ADD_STEPS*SEC_PRICE_STEP)
                if (atPrice + shiftSL) <= TransactionPrice then
                    atPrice = TransactionPrice
                end
                if fixedstop then
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
            end
            deals["index"][dealsCount] = index
            deals["openShort"][dealsCount] = DS:O(index)
            if logDeals then
                myLog(NAME_OF_STRATEGY.." Продажа по цене "..tostring(lastDealPrice).." SL "..tostring(slPrice).." TP "..tostring(tpPrice))
                myLog(NAME_OF_STRATEGY.." STOP_LOSS "..tostring(STOP_LOSS).." TAKE_PROFIT "..tostring(TAKE_PROFIT).." kATR "..tostring(kATR).." ATR "..tostring(ATR[index-1]).." calcAlgoValue "..tostring(calcAlgoValue[index-1]))
            end
        else
            lastDealPrice = 0
            TRAILING_ACTIVATED = false
        end
    end

    checkSL_TP(index, calcAlgoValue, calcTrend, deals, equitySum)

    if index == endIndex and (deals["openShort"][dealsCount] ~= nil or deals["openLong"][dealsCount] ~= nil) then

        if logDeals then
            myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
            myLog(NAME_OF_STRATEGY.." last index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index)))
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
                TRAILING_ACTIVATED = false
                slPrice = 0
                tpPrice = 0
            end
            if DS:H(index) >= tpPrice and tpPrice~=0 then
                dealsCount = dealsCount + 1
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
                TRAILING_ACTIVATED = false
                slPrice = 0
                slIndex = index
                tpPrice = 0
            end
            local isPriceMove  = false
            local priceMoveVal = (DS:H(index) - TransactionPrice)
            if TRAILING_SIZE~=0 and TRAILING_SIZE_STEP~=0 and STOP_LOSS~=0 then
                if not TRAILING_ACTIVATED then
                    isPriceMove = (priceMoveVal >= (TRAILING_SIZE + TRAILING_SIZE_STEP)*priceKoeff)
                    if isPriceMove then
                        TRAILING_ACTIVATED = true
                        priceMoveVal = priceMoveVal - TRAILING_SIZE*priceKoeff
                    end
                else
                    isPriceMove = (priceMoveVal >= TRAILING_SIZE_STEP*priceKoeff)
                end
            elseif TRAILING_SIZE_STEP~=0 and STOP_LOSS~=0 then
                if not TRAILING_ACTIVATED then
                    isPriceMove = (priceMoveVal >= TRAILING_SIZE_STEP*priceKoeff)
                    if isPriceMove then
                        TRAILING_ACTIVATED = true
                    end
                else
                    isPriceMove = (priceMoveVal >= TRAILING_SIZE_STEP*priceKoeff)
                end
            else
                isPriceMove = (priceMoveVal >= STOP_LOSS*priceKoeff) and STOP_LOSS~=0
            end
            if (shiftStop or shiftProfit) and (isPriceMove or (index - lastStopShiftIndex)>stopShiftIndexWait) and deals["closeLong"][dealsCount] == nil then
                lastStopShiftIndex = index
                --local shiftCounts = math.floor((DS:H(index) - TransactionPrice)/(((TRAILING_ACTIVATED and TRAILING_SIZE_STEP~=0) and TRAILING_SIZE_STEP or STOP_LOSS)*priceKoeff))
                if logDeals then
                    myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
                    myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount)..' isPriceMove '..tostring(isPriceMove))
                    myLog(NAME_OF_STRATEGY.." priceMoveVal "..tostring(priceMoveVal).." TransactionPrice "..tostring(TransactionPrice).." H "..tostring(DS:H(index)).." calcAlgoValue[index-1] "..tostring(calcAlgoValue[index-1]).." STOP_LOSS*priceKoeff "..tostring(STOP_LOSS*priceKoeff))
                    myLog("TRAILING_ACTIVATED "..tostring(TRAILING_ACTIVATED).." TRAILING_SIZE_STEP*priceKoeff "..tostring(TRAILING_SIZE_STEP*priceKoeff).." TRAILING_SIZE*priceKoeff "..tostring(TRAILING_SIZE*priceKoeff))
                end
                if slPrice~=0 and shiftStop then
                    local oldStop = slPrice
                    --slPrice = DS:H(index) - STOP_LOSS*priceKoeff
                    -- local atPrice = calcAlgoValue[index-1]
                    -- local atPrice = DS:H(index)
                    -- local shiftSL = (kATR*ATR[index-1] + SL_ADD_STEPS*SEC_PRICE_STEP)
                    --TransactionPrice = TransactionPrice+STOP_LOSS*priceKoeff
                    TransactionPrice = isPriceMove and DS:H(index) or TransactionPrice
                    -- if (atPrice - shiftSL) >= TransactionPrice then
                    --     atPrice = TransactionPrice
                    -- end
                    -- --slPrice = round(atPrice - shiftSL, SCALE)
                    -- if fixedstop then
                    --     shiftSL = STOP_LOSS*priceKoeff
                    --     atPrice = TransactionPrice
                    -- end
                    -- slPrice = math.max(round(atPrice - shiftSL, SCALE), round(deals["openLong"][dealsCount] + 0*SEC_PRICE_STEP, SCALE))
                    -- slPrice = math.max(round(oldStop + priceMoveVal, SCALE), round(deals["openLong"][dealsCount] + 0*SEC_PRICE_STEP, SCALE))
                    slPrice = round(oldStop + priceMoveVal, SCALE)
                    if (deals["openLong"][dealsCount] - slPrice) > maxStop*priceKoeff then slPrice = deals["openLong"][dealsCount] - maxStop*priceKoeff end
                    slPrice = math.min(math.max(oldStop,slPrice), DS:L(index))
                    if logDeals then
                        myLog(NAME_OF_STRATEGY.." Сдвиг стоп-лосса "..tostring(slPrice))
                        myLog(NAME_OF_STRATEGY.." new TransactionPrice "..tostring(TransactionPrice))
                    end
                end
                if tpPrice~=0 and isPriceMove and shiftProfit then --slPrice~=0 and
                    --tpPrice = round(tpPrice + shiftCounts*((TRAILING_ACTIVATED and TRAILING_SIZE_STEP~=0) and TRAILING_SIZE_STEP or STOP_LOSS)*priceKoeff/2, SCALE)
                    tpPrice = round(tpPrice + priceMoveVal/2, SCALE)
                    if logDeals then
                        myLog(NAME_OF_STRATEGY.." Сдвиг тейка "..tostring(tpPrice))
                    end
                end
            end
        end

        if deals["openShort"][dealsCount] ~= nil then
            if DS:H(index) >= slPrice and slPrice~=0 then
                dealsCount = dealsCount + 1
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
                TRAILING_ACTIVATED = false
                slPrice = 0
                tpPrice = 0
            end
            if DS:L(index) <= tpPrice and tpPrice~=0 then
                dealsCount = dealsCount + 1
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
                TRAILING_ACTIVATED = false
                slPrice = 0
                slIndex = index
                tpPrice = 0
            end
            local isPriceMove   = false
            local priceMoveVal  = (TransactionPrice - DS:L(index))
            if TRAILING_SIZE~=0 and TRAILING_SIZE_STEP~=0 and STOP_LOSS~=0 then
                if not TRAILING_ACTIVATED then
                    isPriceMove = (priceMoveVal >= (TRAILING_SIZE + TRAILING_SIZE_STEP)*priceKoeff)
                    if isPriceMove then
                        TRAILING_ACTIVATED = true
                        priceMoveVal = priceMoveVal - TRAILING_SIZE*priceKoeff
                    end
                else
                    isPriceMove = (priceMoveVal >= TRAILING_SIZE_STEP*priceKoeff)
                end
            elseif TRAILING_SIZE_STEP~=0 and STOP_LOSS~=0 then
                if not TRAILING_ACTIVATED then
                    isPriceMove = (priceMoveVal >= TRAILING_SIZE_STEP*priceKoeff)
                    if isPriceMove then
                        TRAILING_ACTIVATED = true
                    end
                else
                    isPriceMove = (priceMoveVal >= TRAILING_SIZE_STEP*priceKoeff)
                end
            else
                isPriceMove = (priceMoveVal >= STOP_LOSS*priceKoeff) and STOP_LOSS~=0
            end
            if (shiftStop or shiftProfit) and (isPriceMove or (index - lastStopShiftIndex)>stopShiftIndexWait) and deals["closeShort"][dealsCount] == nil then
                lastStopShiftIndex = index
                --local shiftCounts = math.floor((TransactionPrice - DS:L(index))/(((TRAILING_ACTIVATED and TRAILING_SIZE_STEP~=0) and TRAILING_SIZE_STEP or STOP_LOSS)*priceKoeff))
                if logDeals then
                    myLog(NAME_OF_STRATEGY.." --------------------------------------------------")
                    myLog(NAME_OF_STRATEGY.." index "..tostring(index).." time "..toYYYYMMDDHHMMSS(DS:T(index))..' dealsCount '..tostring(dealsCount)..' isPriceMove '..tostring(isPriceMove))
                    myLog(NAME_OF_STRATEGY.." priceMoveVal "..tostring(priceMoveVal).." TransactionPrice "..tostring(TransactionPrice).." L(index) "..tostring(DS:L(index)).." calcAlgoValue[index-1] "..tostring(calcAlgoValue[index-1]).." STOP_LOSS*priceKoeff "..tostring(STOP_LOSS*priceKoeff))
                    myLog("TRAILING_ACTIVATED "..tostring(TRAILING_ACTIVATED).." TRAILING_SIZE_STEP*priceKoeff "..tostring(TRAILING_SIZE_STEP*priceKoeff).." TRAILING_SIZE*priceKoeff "..tostring(TRAILING_SIZE*priceKoeff))
                end
                if slPrice~=0 and shiftStop then
                    local oldStop = slPrice
                    --slPrice = DS:L(index) + STOP_LOSS*priceKoeff
                    -- local atPrice = calcAlgoValue[index-1]
                    -- local atPrice = DS:L(index)
                    -- local shiftSL = (kATR*ATR[index-1] + SL_ADD_STEPS*SEC_PRICE_STEP)
                    --TransactionPrice = TransactionPrice-STOP_LOSS*priceKoeff
                    TransactionPrice = isPriceMove and DS:L(index) or TransactionPrice
                    -- if (atPrice + shiftSL) <= TransactionPrice then
                    --     atPrice = TransactionPrice
                    -- end
                    -- --slPrice = round(atPrice + shiftSL, SCALE)
                    -- if fixedstop then
                    --     shiftSL = STOP_LOSS*priceKoeff
                    --     atPrice = TransactionPrice
                    -- end
                    -- slPrice = math.min(round(atPrice + shiftSL, SCALE), round(deals["openShort"][dealsCount] - 0*SEC_PRICE_STEP, SCALE))
                    -- slPrice = math.min(round(oldStop - priceMoveVal, SCALE), round(deals["openShort"][dealsCount] - 0*SEC_PRICE_STEP, SCALE))
                    slPrice = round(oldStop - priceMoveVal, SCALE)
                    if (slPrice-deals["openShort"][dealsCount]) > maxStop*priceKoeff then slPrice =  deals["openShort"][dealsCount] + maxStop*priceKoeff end
                    slPrice = math.max(math.min(oldStop,slPrice), DS:H(index))

                    if logDeals then
                        myLog(NAME_OF_STRATEGY.." Сдвиг стоп-лосса "..tostring(slPrice))
                        myLog(NAME_OF_STRATEGY.." new TransactionPrice "..tostring(TransactionPrice))
                    end
                end
                if tpPrice~=0 and isPriceMove and shiftProfit then --slPrice~=0 and
                    --tpPrice = round(tpPrice - shiftCounts*((TRAILING_ACTIVATED and TRAILING_SIZE_STEP~=0) and TRAILING_SIZE_STEP or STOP_LOSS)*priceKoeff/2, SCALE)
                    tpPrice = round(tpPrice - priceMoveVal/2, SCALE)
                    if logDeals then
                        myLog(NAME_OF_STRATEGY.." Сдвиг тейка "..tostring(tpPrice))
                    end
                end
            end
        end
    end

end