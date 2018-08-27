
-------------------------
--THV

THVSettings = {
    period    = 1,
    koef = 1 
}

function initTHV()
	g_ibuf_92=nil
	g_ibuf_96=nil
	g_ibuf_100=nil
	g_ibuf_104=nil
	gda_108=nil
	gda_112=nil
	gda_116=nil
	gda_120=nil
	gda_124=nil
	gda_128=nil
	cache_O=nil
	cache_C=nil
    trend=nil
end

function iterateTHV(iSec, cell)
    
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
    param1Max = 112
    param1Step = 1

    param2Min = 0.5
    param2Max = 2
    param2Step = 0.1
    
    param3Min = 0
    param3Max = 0
    param3Step = 1

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

	local rescount = 0
    
    local allCount = ((param1Max-param1Min + param1Step)/param1Step)*((param2Max - param2Min + param2Step)/param2Step)*((param3Max - param3Min + param3Step)/param3Step)

    for _period = param1Min, param1Max, param1Step do
        for _koef = param2Min, param2Max, param2Step do
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
                    period    = _period,                   
                    koef = _koef,                  
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
                
                if profitRatio ~= nil then
                    rescount = rescount + 1
                    resultsTable[rescount] = {iSec, cell, allProfit, profitRatio, longProfit, shortProfit, dealsLP, dealsSP, ratioProfitDeals, avg, sigma, maxDrawDown, sharpe, AHPR, ZCount, settingsTask}

                    if maxProfit == nil or maxProfit<allProfit then
                        maxProfit = allProfit
                        maxProfitIndex = rescount
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
    end
       
    SetCell(t_id, lineTask, 4, "100%", 100)

    --if count > 1 then
    --    table.sort(resultsTable, function(a,b) return a[4]<b[4] end)
    --end
 
    openResults(resultsTable, settingTable)

    if ChartId ~= nil then
        addDeals(maxProfitDeals, ChartId, DS)
        stv.UseNameSpace(ChartId)
        stv.SetVar('algoResults', maxProfitAlgoResults)
    end

end

function THV(index, settings, DS)

    local period = settings.period or 32
    local koef = settings.koef or 1

    if index == nil then index = 1 end
    
    local ild_0
    local ld_8

    local gd_188 = koef * koef
    local gd_196 = 0
    local gd_196 = gd_188 * koef
    local gd_132 = -gd_196
    local gd_140 = 3.0 * (gd_188 + gd_196)
    local gd_148 = -3.0 * (2.0 * gd_188 + koef + gd_196)
    local gd_156 = 3.0 * koef + 1.0 + gd_196 + 3.0 * gd_188
    local gd_164 = period
    if gd_164 < 1.0 then gd_164 = 1 end
    gd_164 = (gd_164 - 1.0) / 2.0 + 1.0
    local gd_172 = 2 / (gd_164 + 1.0)
    local gd_180 = 1 - gd_172

    local openHA
    local closeHA
    local highHA
    local lowHA
    
    local outDown
    local outUP

    if g_ibuf_96 == nil then
        myLog("Показатель Period "..tostring(period))
        myLog("Показатель koef "..tostring(koef))
        myLog("Показатель SarDeviation "..tostring(SarDeviation))
        myLog("--------------------------------------------------")
        
        g_ibuf_92={}
        g_ibuf_96={}
        g_ibuf_100={}
        g_ibuf_104={}
        gda_108={}
        gda_112={}
        gda_116={}
        gda_120={}
        gda_124={}
        gda_128={}
        
        g_ibuf_92[index]=0
        g_ibuf_96[index]=0
        g_ibuf_100[index]=0
        g_ibuf_104[index]=0
        gda_108[index]=0
        gda_112[index]=0
        gda_116[index]=0
        gda_120[index]=0
        gda_124[index]=0
        gda_128[index]=0
        
        trend = {}
        trend[index] = 1
        
        cache_O = {}
        cache_C = {}
        cache_O[index]= 0
        cache_C[index]= 0

        return g_ibuf_96
    end

    g_ibuf_92[index] = g_ibuf_92[index-1] 
    g_ibuf_96[index] = g_ibuf_96[index-1]
    g_ibuf_100[index] = g_ibuf_100[index-1]
    g_ibuf_104[index] = g_ibuf_104[index-1] 
    gda_108[index] = gda_108[index-1]
    gda_112[index] = gda_112[index-1]
    gda_116[index] = gda_116[index-1] 
    gda_120[index] = gda_120[index-1]
    gda_124[index] = gda_124[index-1]
    gda_128[index] = gda_128[index-1] 
    
    trend[index] = trend[index-1] 

    cache_O[index] = cache_O[index-1] 
    cache_C[index] = cache_C[index-1] 

    if DS:C(index) ~= nil then        
        
		local previous = index-1		
		if DS:C(previous) == nil then
			previous = FindExistCandle(previous)
		end

        gda_108[index] = gd_172 * DS:C(index) + gd_180 * (gda_108[previous])
		gda_112[index] = gd_172 * (gda_108[index]) + gd_180 * (gda_112[previous])
		gda_116[index] = gd_172 * (gda_112[index]) + gd_180 * (gda_116[previous])
		gda_120[index] = gd_172 * (gda_116[index]) + gd_180 * (gda_120[previous])
		gda_124[index] = gd_172 * (gda_120[index]) + gd_180 * (gda_124[previous])
		gda_128[index] = gd_172 * (gda_124[index]) + gd_180 * (gda_128[previous])
		g_ibuf_104[index] = gd_132 * (gda_128[index]) + gd_140 * (gda_124[index]) + gd_148 * (gda_120[index]) + gd_156 * (gda_116[index])
		ld_0 = g_ibuf_104[index]
		ld_8 = g_ibuf_104[previous]
        
        g_ibuf_92[index] = ld_0
		g_ibuf_96[index] = ld_0
		g_ibuf_100[index] = ld_0
        
		cache_O[index]=DS:O(index)
		cache_C[index]=DS:C(index)

        openHA = (cache_O[previous] + cache_C[previous])/2
		closeHA = (DS:O(index) + DS:H(index) + DS:L(index) + DS:C(index))/4
		highHA = math.max(DS:H(index), math.max(openHA, closeHA))
		lowHA = math.min(DS:L(index), math.min(openHA, closeHA))
		
		cache_O[index] = openHA
		cache_C[index] = closeHA
		
		if openHA < closeHA then
			outDown = nil
			outUP = (DS:H(index) + DS:L(index))/2
		elseif openHA > closeHA then
			outDown = (DS:H(index) + DS:L(index))/2
			outUP = nil
		end

        if ld_8 > ld_0 and cache_O[index] > cache_C[index] and cache_O[index-1] > cache_C[index-1] then 
			trend[index] = -1
        end
        if ld_8 < ld_0 and cache_O[index] < cache_C[index] and cache_O[index-1] < cache_C[index-1] then
			trend[index] = 1
		end

    end
            
    return g_ibuf_96, trend 
    
end

