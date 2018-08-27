
-------------------------
--SAR
SARSettings = {
        SarPeriod    = 0,                   
        SarPeriod2 = 0,                  
        SarDeviation = 0              
}

function initSAR()
    cache_SAR=nil
    cache_ST=nil
    EMA=nil
    BB=nil
end

function iterateSAR(iSec, cell)
    
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

    param1Min = 4
    param1Max = 64
    param1Step = 2

    param2Min = 112
    param2Max = 312
    param2Step = 2
    
    param3Min = 0.4
    param3Max = 5
    param3Step = 0.1

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

    local allCount = ((param1Max-param1Min + param1Step)/param1Step)*((param2Max - param2Min + param2Step)/param2Step)*((param3Max - param3Min + param3Step)/param3Step)

    for _SarPeriod = param1Min, param1Max, param1Step do
        for _SarPeriod2 = param2Min, param2Max, param2Step do
            for _SarDeviation = param3Min, param3Max, param3Step do
                
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
                    SarPeriod    = _SarPeriod,                   
                    SarPeriod2 = _SarPeriod2,                  
                    SarDeviation = _SarDeviation,              
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

function SAR(index, settings, DS)

    local SarPeriod = settings.SarPeriod or 32
    local SarPeriod2 = settings.SarPeriod2 or 256
    local SarDeviation = settings.SarDeviation or 3
    local sigma = 0

    if index == nil then index = 1 end
        
    if cache_SAR == nil then
        myLog("Показатель SarPeriod "..tostring(SarPeriod))
        myLog("Показатель SarPeriod2 "..tostring(SarPeriod2))
        myLog("Показатель SarDeviation "..tostring(SarDeviation))
        myLog("--------------------------------------------------")
        cache_SAR={}
        cache_ST={}
        EMA={}
        BB={}
        BB[index]=0
        cache_SAR[index]=0
        EMA[index]=0
        cache_ST[index]=1
        return cache_SAR
    end

    EMA[index]=EMA[index-1]
    BB[index]=BB[index-1]
    cache_SAR[index]=cache_SAR[index-1] 
    cache_ST[index]=cache_ST[index-1]

    if DS:C(index) ~= nil then        
        
        EMA[index]=(2/(SarPeriod/2+1))*DS:C(index)+(1-2/(SarPeriod/2+1))*EMA[index-1]
        BB[index]=(2/(SarPeriod2/2+1))*(DS:C(index)-EMA[index])^2+(1-2/(SarPeriod2/2+1))*BB[index-1]

        sigma=BB[index]^(1/2)
        
        if index ==2 then
            return cache_SAR
        end

        if cache_ST[index] == 1 then
                
            cache_SAR[index]=math.max((EMA[index]-sigma*SarDeviation),cache_SAR[index-1])
                        
            if (cache_SAR[index] > DS:C(index)) then 
                cache_ST[index] = -1
                cache_SAR[index]=EMA[index]+sigma*SarDeviation
            end
        elseif cache_ST[index] == -1 then
                
            cache_SAR[index]=math.min((EMA[index]+sigma*SarDeviation),cache_SAR[index-1])
        
            if (cache_SAR[index] < DS:C(index)) then 
                cache_ST[index] = 1
                cache_SAR[index]=EMA[index]-sigma*SarDeviation
            end
        end
    end
            
    return cache_SAR, cache_ST 
    
end

