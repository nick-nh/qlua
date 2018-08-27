-------------------------
--EMA
EMASettings = {
    periods    = {period1 = 0, period2 = 0}
}

function ema2Trade(index, calcAlgoValue, calcTrend, DS, isLong, isShort, deals, settings, logDeals)

    if index <= beginIndex then return nil end

    local _period1 = settings.periods["period1"]
    local _period2 = settings.periods["period2"]
    local index1 = "period1" -- lower period
    local index2 = "period2"

    if _period1>_period2 then
        index1 = "period2"
        index2 = "period1"
    end
    
    local signaltestvalue1 = calcAlgoValue[index1][index-1] or 0
    local signaltestvalue2 = calcAlgoValue[index2][index-1] or 0
    local signaltestvalue1_1 = calcAlgoValue[index1][index-2] or 0
    local signaltestvalue2_1 = calcAlgoValue[index2][index-2] or 0
    
    local equitySum = initalAssets or 0
    
    if signaltestvalue1 > signaltestvalue2 and signaltestvalue1_1 <= signaltestvalue2_1 then
        dealsCount = dealsCount + 1
        if initalAssets == 0 then
            initalAssets = DS:O(index)*leverage
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
    if signaltestvalue1 < signaltestvalue2 and signaltestvalue1_1 >= signaltestvalue2_1 then
        dealsCount = dealsCount + 1
        if initalAssets == 0 then
            initalAssets = DS:O(index)*leverage
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

function iterateEMA(iSec, cell)
    
    --iterateSettings = {}

    Clear(tres_id)

    myLog("================================================")
    myLog("Sec code "..SEC_CODES['sec_codes'][iSec])

    --local settings = ALGORITHMS["settings"][cell]
    local Size = GetCell(t_id, lineTask, 2).value or SEC_CODES['Size'][iSec]
    --resultsTable = {}
    clearResultsTable(iSec, cell)
    local resultsTable = CreateResTable(iSec)    
    local count = #resultsTable
    local settingTable = ALGORITHMS['settings'][cell]

    myLog("Interval "..ALGORITHMS['names'][cell])
    myLog("================================================")


    local localCount = 0
    DS = DataSource(iSec)
    beginIndex = DS:Size()-Size
    endIndex = DS:Size()

    param1Min = 4
    param1Max = 64
    param1Step = 1

    param2Min = 21
    param2Max = 128
    param2Step = 1

    local ChartId = SEC_CODES['ChartId'][iSec]
    if ChartId ~= nil then
        DelAllLabels(ChartId);
    end
   
    maxProfitIndex = 0
    maxProfit = nil
    maxProfitDeals = nil
    maxProfitAlgoResults = nil

    local localCount = 0

    local done = 0
    DS = DataSource(iSec)
    beginIndex = DS:Size()-Size
    endIndex = DS:Size()

    local calculatedPairs = {}

    local allCount = ((param1Max-param1Min + param1Step)/param1Step)*((param2Max - param2Min + param2Step)/param2Step)

    for _period1 = param1Min, param1Max, param1Step do
        for _period2 = param2Min, param2Max, param2Step do
            
            ---myLog("_period1 "..tostring(_period1).." calculatedPairs[_period1] "..tostring(calculatedPairs[_period1]))
            --myLog("_period2 "..tostring(_period2).." calculatedPairs[_period2] "..tostring(calculatedPairs[_period2]))
           if _period1 ~= _period2 and calculatedPairs[(_period2)^3+_period1] == nil then
                
                calculatedPairs[(_period1)^3+_period2] = 1
                count = count + 1
                localCount = localCount + 1
                done = round(localCount*100/allCount, 0)
                SetCell(t_id, lineTask, 4, tostring(done).."%", done)

                allProfit = 0
                shortProfit = 0
                longProfit = 0
                lastDealPrice = 0
                dealsCount = 0
                dealsLongCount = 0
                dealsShortCount = 0
                profitDealsLongCount = 0
                profitDealsShortCount = 0
                ratioProfitDeals = 0
                initalAssets = 0
                        
                settingsTask = {
                    periods    = {period1 = _period1, period2 = _period2},                   
                    Size = Size
                }
            
                calculateAlgorithm(iSec, cell)
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
                
                resultsTable[count] = {iSec, cell, allProfit, profitRatio, longProfit, shortProfit, dealsLP, dealsSP, ratioProfitDeals, avg, sigma, maxDrawDown, sharpe, AHPR, ZCount, settingsTask}

                if maxProfit == nil or maxProfit<allProfit then
                    maxProfit = allProfit
                    maxProfitIndex = count
                    maxProfitDeals = deals
                    maxProfitAlgoResults = algoResults
                    SetCell(t_id, lineTask, 5, tostring(allProfit), allProfit)
                    SetCell(t_id, lineTask, 6, tostring(profitRatio), profitRatio)
                    SetCell(t_id, lineTask, 7, tostring(longProfit), longProfit)
                    SetCell(t_id, lineTask, 8, tostring(shortProfit), shortProfit)
                    SetCell(t_id, lineTask, 9, tostring(dealsLP), 0)
                    SetCell(t_id, lineTask, 10, tostring(dealsSP), 0)
                    SetCell(t_id, lineTask, 11, tostring(ratioProfitDeals), ratioProfitDeals)
                    SetCell(t_id, lineTask, 12, tostring(avg), avg)
                    SetCell(t_id, lineTask, 13, tostring(sigma), sigma)
                    SetCell(t_id, lineTask, 14, tostring(maxDrawDown), maxDrawDown)
                    SetCell(t_id, lineTask, 15, tostring(sharpe), sharpe)
                    SetCell(t_id, lineTask, 16, tostring(AHPR), AHPR)
                    SetCell(t_id, lineTask, 17, tostring(ZCount), ZCount)
                end
    
            end
        end
    end

    SetCell(t_id, lineTask, 4, "100%", 100)
 
    openResults(resultsTable, settingTable)

    if ChartId ~= nil then
        addDeals(maxProfitDeals, ChartId, DS)
        stv.UseNameSpace(ChartId)
        stv.SetVar('algoResults', maxProfitAlgoResults)
    end

end

function initEMA()
    EMA=nil
end

function allEMA(index, settings, DS)

    local periods = settings.periods or {period1 = 29}     
    local Size = settings.Size or 2000 
    
    --подготавливаем массив данных по периодам
    if index == nil then index = 1 end

    if EMA == nil then
        EMA = {}
        for i,period in pairs(periods) do                    
            EMA[i] = {}			
            EMA[i][index] = 0			
        end
        return EMA
    end
        
    for i,period in pairs(periods) do                    
        EMA[i][index] = EMA[i][index-1]			
    end
   
    if index <= 2 then
        return EMA
    end
 
    for i,period in pairs(periods) do                    
        
        local k = 2/(period+1)
        EMA[i][index] = (DS:C(index)+DS:O(index))/2			
        
        if DS:C(index) ~= nil then
            EMA[i][index]=round(k*DS:C(index)+(1-k)*EMA[i][index-1], 5)
        end
        
    end                

    return EMA 
    
end
