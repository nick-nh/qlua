-------------------------
--NRTR
NRTRSettings = {
    Length    = 0,                   
    Kv = 0,                  
    Switch = 0,             
    barShift = 0,              
	ATRfactor = 0,
    StepSize = 0,              
    Percentage = 0,
    Size = 0
}

function initStepNRTR()
    NRTR=nil
    smax1=nil
    smin1=nil
    trend=nil
end

function initStepNRTRParams()
    
    param1Min = 3
    param1Max = 21
    param1Step = 1

    param2Min = 0.5
    param2Max = 2.2
    param2Step = 0.1

    param3Min = 0
    param3Max = 1
    param3Step = 1
    
    param4Min = 0
    param4Max = 0.10
    param4Step = 0.05
    
end

function iterateNRTR(iSec, cell)
    
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
    

    param1Min = 5
    param1Max = 64
    param1Step = 1

    param2Min = 1
    param2Max = 4
    param2Step = 0.1

    param3Min = 0
    param3Max = 1
    param3Step = 1
    
    param4Min = 0
    param4Max = 1
    param4Step = 1
    
    --init Parameters
    local initP = ALGORITHMS["initParams"][cell]
     if initP~=nil then        
        initP()
    end

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
            
    local allCount = ((param1Max-param1Min + param1Step)/param1Step)*
                    ((param2Max - param2Min + param2Step)/param2Step)*
                    ((param3Max - param3Min + param3Step)/param3Step)*
                    ((param4Max - param4Min + param4Step)/param4Step)
    -- + 
    --((param4Max - param4Min + param4Step)/param4Step)*((param3Max - param3Min + param3Step)/param3Step)
	local rescount = 0
    --stopSignal = true
	
    for param1 = param1Min, param1Max, param1Step do
        if stopSignal then
            break
        end
        for param2 = param2Min, param2Max, param2Step do
            if stopSignal then
                break
            end
            for param3 = param3Min, param3Max, param3Step do
                if stopSignal then
                    break
                end
                for param4 = param4Min, param4Max, param4Step do                    
                    if stopSignal then
                        break
                    end
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
                            Length    = param1,                   
                            Kv = param2,                  
                            Switch = param3,             
                            barShift = 0,             
                            ATRfactor = param4,                  
                            StepSize = 0,              
                            Percentage = 0,
                            Size = Size,
                            endIndex = endIndex
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
                        
                        if profitRatio > 0 then
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
    end
       

    SetCell(t_id, lineTask, 4, "100%", 100)

    --if count > 1 then
        --ArraySortByColl(resultsTable, 3)
    --    table.sort(resultsTable, function(a,b) return a[4]<b[4] end)
    --end
 
    openResults(resultsTable, settingTable)

    if ChartId ~= nil then
        addDeals(maxProfitDeals, ChartId, DS)
        stv.UseNameSpace(ChartId)
        stv.SetVar('algoResults', maxProfitAlgoResults)
    end

end

function stepNRTR(index, settings, DS)

    local Length = settings.Length or 29            -- perios        
    local Kv = settings.Kv or 1                     -- miltiply
    local StepSize = settings.StepSize or 0         -- fox stepSize
    local ATRfactor = settings.ATRfactor or 0.15		
    local barShift = settings.barShift or 0		
    local Percentage = settings.Percentage or 0
    local Switch = settings.Switch or 1             --1 - HighLow, 2 - CloseClose
    local Size = settings.Size or 2000 
    local adaptive = settings.adaptive or 1
    local alpha = settings.alpha or 0.07

    local ratio=Percentage/100.0*SEC_PRICE_STEP
    local smax0 = 0
    local smin0 = 0
    
    if index == nil then index = 1 end
    
    adaptive = 0
    if adaptive == 1 then
        if NRTR == nil then
            for zind = 1, settings.endIndex do
                adaptivePeriod(zind, settingsTask, DS)
            end
        end
        local aP = GetZZLength(index, settings)
        --local aP = adaptivePeriod(index, settings, DS)
        Length = math.ceil(aP) or Length
        if Length == 0 then
            Length = settings.Length or 15
        end
    end
    
    local kawg = 2/(Length+1)
    
    if NRTR == nil then
        --myLog("Показатель Length "..tostring(Length))
        --myLog("Показатель Kv "..tostring(Kv))
        --myLog("Показатель ATRfactor "..tostring(ATRfactor))
        --myLog("Показатель StepSize "..tostring(StepSize))
        --myLog("Показатель Switch "..tostring(Switch))
        --myLog("Показатель barShift "..tostring(barShift))
        --myLog("Показатель adaptive "..tostring(adaptive))
        --myLog("Показатель alpha "..tostring(alpha))
        --myLog("--------------------------------------------------")
        NRTR = {}
        NRTR[index] = 0			
        cache_ATR = {}
        cache_ATR[index] = 0			
        emaATR = {}
        emaATR[index] = 0			
        emaStep = {}
        emaStep[index] = 0			
        smax1 = {}
        smin1 = {}
        trend = {}
        smax1[index] = 0
        smin1[index] = 0
        trend[index] = 1
        
        cacheL = {}
        cacheL[index] = 0			
        cacheH = {}
        cacheH[index] = 0			
        fractalL = {}
        fractalL[index] = 1			
        fractalH = {}
        fractalH[index] = 1	

        return NRTR
    end

    NRTR[index] = NRTR[index-1] 
    cache_ATR[index] = cache_ATR[index-1] 
    emaATR[index] = emaATR[index-1] 
    smax1[index] = smax1[index-1] 
    smin1[index] = smin1[index-1] 
    trend[index] = trend[index-1] 
    emaStep[index] = emaStep[index-1] 
    
    cacheL[index] = cacheL[index-1] 
    cacheH[index] = cacheH[index-1] 
    
    if index <= (Length + 3) then
        return NRTR
    end

    if DS:C(index) ~= nil then        
        
        local previous = index-1       
        if DS:C(previous) == nil then
            previous = FindExistCandle(previous)
        end
       
        cacheH[index] = DS:H(index)
        cacheL[index] = DS:L(index)

        local fP = math.floor(Length/2)*2+1
        
        --if index >= fP then
        --
        --    local sP = index - fP + 1 + math.floor(fP/2)
        --    local val_h=math.max(unpack(cacheH,index-fP+1,index)) 
        --    local val_l=math.min(unpack(cacheL,index-fP+1,index))
        --    local fL =DS:L(sP)
        --    local fH = DS:H(sP)
        --    
        --    if (val_h == fH) and (val_h >0) 
        --        and (val_l == fL) and (val_l > 0) then
        --            fractalH[#fractalH+1] = sP
        --            fractalL[#fractalL+1] = sP
        --    else
        --        if (val_h == fH) and (val_h >0) then
        --            fractalH[#fractalH+1] = sP
        --        end
        --        if (val_l == fL) and (val_l > 0) then
        --            fractalL[#fractalL+1] = sP
        --        end
        --    end
        --end        
        --
        --local avF = 3
        --if trend[index] == -1 then
        --    if #fractalH > avF + 1 then
        --        local al = 0
        --        for i=1,avF do
        --            al = al + fractalH[#fractalH-i+1] - fractalH[#fractalH-i]
        --        end
        --        _Length = al/avF
        --    end
        --end
        --if trend[index] == 1 then
        --    if #fractalL > avF + 1 then
        --        local al = 0
        --        for i=1,avF do
        --            al = al + fractalL[#fractalL-i+1] - fractalL[#fractalL-i]
        --        end
        --        _Length = al/avF
        --    end
        --end

        local smoothStep = 0
        local Step=StepSizeCalc(Length,Kv,StepSize,Switch,index,DS, smoothStep)
        --local StepRange = StepSizeCalc(Length,Kv,StepSize,Switch,index,DS)
        --if StepRange == 0 then StepRange = SEC_PRICE_STEP end
		--emaStep[index] = kawg*StepRange+(1-kawg)*emaStep[index-1]
        --local Step = emaStep[index]

        cache_ATR[index] = math.max(math.abs(DS:H(index) - DS:L(index)), math.abs(DS:H(index) - DS:C(previous)), math.abs(DS:C(previous) - DS:L(index))) or cache_ATR[index-1]
		emaATR[index] = kawg*cache_ATR[index]+(1-kawg)*emaATR[index-1]
        
        if Step == 0 then Step = SEC_PRICE_STEP end
        
        local SizeP=Step*SEC_PRICE_STEP
        local Size2P=2*SizeP
                
        local result		
        
        previous = index-barShift       
        if DS:C(previous) == nil then
            previous = FindExistCandle(previous)
        end
        if Switch == 1 then     
            smax0=DS:L(previous)+Size2P
            smin0=DS:H(previous)-Size2P    
        else   
            smax0=DS:C(previous)+Size2P
            smin0=DS:C(previous)-Size2P
        end
        
        --myLog("index "..tostring(index))
        --myLog("DS:C(index) "..tostring(DS:C(index)))
        --myLog("smax1[index] "..tostring(smax1[index]))
        --myLog("trend[index] "..tostring(trend[index]))
		if DS:C(index)>smax1[index] and (DS:C(index)-smax1[index]) > ATRfactor*emaATR[index] then
			trend[index] = 1 
		end
		if DS:C(index)<smin1[index] and (smin1[index]-DS:C(index)) > ATRfactor*emaATR[index] then
			trend[index]= -1
		end

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
            NRTR[index]=(result+ratio/Step)-Step*SEC_PRICE_STEP
        end
        if trend[index]<0 then
            NRTR[index]=(result+ratio/Step)+Step*SEC_PRICE_STEP		
        end	
   
    end
            
    return NRTR, trend 
    
end

function StepSizeCalc(Len, Km, Size, Switch, index, DS, smoothStep)

    local result

    if smoothStep == 1 then
        local Range = 0
        local rangeEMA = {}	
        local k = 2/(Len+1)

        if Size == 0 then
            
            local Range=0.0
            local ATRmax=-1000000
            local ATRmin=1000000
            if DS:C(index-Len-1) ~= nil then				
                if Switch == 1 then     
                    Range=DS:H(index-Len-1)-DS:L(index-Len-1)
                else   
                    Range=math.abs(DS:O(index-Len-1)-DS:C(index-Len-1))
                end
            end
            rangeEMA[1] = Range

            for iii=1, Len do	
                if DS:C(index-Len+iii-1) ~= nil then				
                    
                    if Switch == 1 then     
                        Range=DS:H(index-Len+iii-1)-DS:L(index-Len+iii-1)
                    else   
                        Range=math.abs(DS:O(index-Len+iii-1)-DS:C(index-Len+iii-1))
                    end
                    rangeEMA[iii+1] = k*Range+(1-k)*rangeEMA[iii]
                else
                    rangeEMA[iii+1] = rangeEMA[iii]					
                end
            end

            result = round(Km*rangeEMA[#rangeEMA]/SEC_PRICE_STEP, nil)
            
        else result=Km*Size
        end
    
    else

        if Size == 0 then
            
            local Range=0.0
            local ATRmax=-1000000
            local ATRmin=1000000

            for iii=1, Len do	
                if DS:C(index-iii) ~= nil then				
                    if Switch == 1 then     
                        Range=DS:H(index-iii)-DS:L(index-iii)
                    else   
                        Range=math.abs(DS:O(index-iii)-DS:C(index-iii))
                    end
                    if Range>ATRmax then ATRmax=Range end
                    if Range<ATRmin then ATRmin=Range end
                end
            end

            result = round(0.5*Km*(ATRmax+ATRmin)/SEC_PRICE_STEP, nil)
            
        else result=Km*Size
        end
    
    end

    return result

end