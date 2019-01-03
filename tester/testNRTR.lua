-------------------------
--NRTR
NRTRSettings = {
    Length    = 0,                   
    Kv = 0,                  
    Switch = 0,             
    zShift = 0,             
    barShift = 0,              
    deviation = 0,              
	ATRfactor = 0,
	numberOfMovesForTargetZone = 0,
    StepSize = 0,              
    adaptive = 0,
    alpha = 0,
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
    
    param1Min = 6
    param1Max = 64
    param1Step = 1

    param2Min = 0.7
    param2Max = 1.7
    param2Step = 0.1

    param3Min = 0
    param3Max = 1
    param3Step = 1
    
    param4Min = 0
    param4Max = 0.15
    param4Step = 0.05
    
end

function iterateNRTR(iSec, cell)
    
    iterateSLTP = false

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

    param5Min = 6
    param5Max = 6
    param5Step = 1
    
    --param4Min = 0.02
    --param4Max = 0.3
    --param4Step = 0.01
    
    --init Parameters
    local initP = ALGORITHMS["initParams"][cell]
     if initP~=nil then        
        initP()
    end
    
    --adaptivePeriod = CyberCycle()
    adaptivePeriod = cached_ZZ()
        
    local allCount = 0
    local settingsTable = {}
	
    for param1 = param1Min, param1Max, param1Step do
        for param2 = param2Min, param2Max, param2Step do
            for param3 = param3Min, param3Max, param3Step do
                for param4 = param4Min, param4Max, param4Step do                    
                    for param5 = param5Min, param5Max, param5Step do                    
                                
                        allCount = allCount + 1                
                        settingsTable[allCount] = {
                            Length    = param1,                   
                            Kv = param2,                  
                            zShift = param2,                  
                            Switch = param3,             
                            barShift = 0,             
                            deviation = param1,             
                            ATRfactor = param4,                  
                            numberOfMovesForTargetZone = param5,                  
                            StepSize = 0,              
                            adaptive = 0,
                            alpha = 0,
                            Percentage = 0,
                            Size = Size,
                            endIndex = endIndex
                        }
                    end
                end
            end
        end
    end
                            
    iterateAlgorithm(iSec, cell, settingsTable)

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
    
    local indexToCalc = 1000
    indexToCalc = settings.Size or indexToCalc
    local beginIndexToCalc = settings.beginIndexToCalc or math.max(1, settings.beginIndex - indexToCalc)
    local endIndexToCalc = settings.endIndex or DS:Size()

    if index == nil then index = 1 end
    
    adaptive = 0
    if adaptive == 1 then
        local aP = adaptivePeriod(index, settings, DS)
        Length = math.ceil(aP) or Length
        if Length == 0 then
            Length = settings.Length or 15
        end
    end
    
    local kawg = 2/(20+1)
    
    if NRTR == nil then
        myLog("Показатель Length "..tostring(Length))
        myLog("Показатель Kv "..tostring(Kv))
        myLog("Показатель ATRfactor "..tostring(ATRfactor))
        myLog("Показатель StepSize "..tostring(StepSize))
        myLog("Показатель Switch "..tostring(Switch))
        myLog("Показатель barShift "..tostring(barShift))
        myLog("Показатель adaptive "..tostring(adaptive))
        myLog("Показатель alpha "..tostring(alpha))
        myLog("--------------------------------------------------")
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
    
    if index <= (Length + 3) or index < beginIndexToCalc or index > endIndexToCalc then
        return NRTR
    end

    if DS:C(index) ~= nil then        
        
        local previous = index-1       
        if DS:C(previous) == nil then
            previous = FindExistCandle(previous)
        end
       
        cacheH[index] = DS:H(index)
        cacheL[index] = DS:L(index)

        local smoothStep = 0
        local Step=StepSizeCalc(Length,Kv,StepSize,Switch,index,DS, smoothStep)

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
            
    return NRTR, trend, NRTR 
    
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

-------------------------
--NRTR range

function initRangeNRTR()
    NRTR=nil
    cache_HPrice = nil
    cache_LPrice = nil
    trend=nil
    ZZLevels={} -- матрица вершины. 1 - значение, 2 - индекс
end

function initRangeNRTRParams()
    
    param1Min = 2
    param1Max = 64
    param1Step = 1

    param2Min = 0
    param2Max = 2.1
    param2Step = 0.1

    param3Min = 0
    param3Max = 1
    param3Step = 1
        
    param4Min = 0
    param4Max = 0.15
    param4Step = 0.05

    param5Min = 6
    param5Max = 6
    param5Step = 1

end

function RangeNRTR(index, settings, DS)

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
    
    local indexToCalc = 1000
    indexToCalc = settings.Size or indexToCalc
    local beginIndexToCalc = settings.beginIndexToCalc or math.max(1, settings.beginIndex - indexToCalc)
    local endIndexToCalc = settings.endIndex or DS:Size()

    if index == nil then index = 1 end
     
    --ATRfactor = 0
    
    local zKv = 1
    local aP = 0
    adaptive = 0
    if adaptive == 1 then
        local aP = adaptivePeriod(index, settings, DS)
        Length = math.ceil(aP) or Length
        if Length == 0 then
            Length = settings.Length or 15
        end
    end

    local kawg = 2/(20+1)
    --local kawg = 2/(15+1)
    
    if NRTR == nil then
        myLog("Показатель Length "..tostring(Length))
        myLog("Показатель Kv "..tostring(Kv))
        myLog("Показатель ATRfactor "..tostring(ATRfactor))
        myLog("Показатель StepSize "..tostring(StepSize))
        myLog("Показатель Switch "..tostring(Switch))
        myLog("Показатель barShift "..tostring(barShift))
        myLog("Показатель adaptive "..tostring(adaptive))
        myLog("Показатель alpha "..tostring(alpha))
        myLog("--------------------------------------------------")
        NRTR = {}
        NRTR[index] = 0			
        emaATR = {}
        emaATR[index] = 0			
        cache_ATR = {}
        cache_ATR[index] = 0			
        smax1 = {}
        smin1 = {}
        trend = {}
        smax1[index] = 0
        smin1[index] = 0
        trend[index] = 1
        emaKv = {}
        emaKv[index] = 0			
        emaStep = {}
        emaStep[index] = 0			
        emaRange = {}
        emaRange[index] = 0			
        cacheL = {}
        cacheL[index] = 0			
        cacheH = {}
        cacheH[index] = 0			
        cacheC = {}
        cacheC[index] = 0			
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
    emaKv[index] = emaKv[index-1] 
    emaStep[index] = emaStep[index-1] 
    emaRange[index] = emaRange[index-1] 
    cacheL[index] = cacheL[index-1] 
    cacheH[index] = cacheH[index-1] 
    cacheC[index] = cacheC[index-1] 

    if index <= 100 or index < beginIndexToCalc or index > endIndexToCalc then
        return NRTR
    end

    if DS:C(index) ~= nil then        
                   
        local previous = index-1
        if DS:C(previous) == nil then
            previous = FindExistCandle(previous)
        end

        cacheH[index] = DS:H(index)
        cacheL[index] = DS:L(index)
        cacheC[index] = DS:C(index)
        
        cache_ATR[index] = math.max(math.abs(DS:H(index) - DS:L(index)), math.abs(DS:H(index) - DS:C(previous)), math.abs(DS:C(previous) - DS:L(index))) or cache_ATR[index-1]
		emaATR[index] = kawg*cache_ATR[index]+(1-kawg)*emaATR[index-1]
        
        previous = index-barShift
		
        if DS:C(previous) == nil then
            previous = FindExistCandle(previous)
        end

        if Switch == 1 then     
            smax0=DS:L(previous)+Kv*emaATR[index]
            smin0=DS:H(previous)-Kv*emaATR[index]    
        else   
            smax0=DS:C(previous)+Kv*emaATR[index]
            smin0=DS:C(previous)-Kv*emaATR[index]
        end

		if DS:C(index)>smax1[index] and (DS:C(index)-smax1[index]) > ATRfactor*emaATR[index] then
			trend[index] = 1 
		end
		if DS:C(index)<smin1[index] and (smin1[index]-DS:C(index)) > ATRfactor*emaATR[index] then
			trend[index]= -1
		end

        if trend[index]>0 then
            if smin0<smin1[index] then smin0=smin1[index] end
            NRTR[index]=smin0
        else
            if smax0>smax1[index] then smax0=smax1[index] end
            NRTR[index]=smax0
        end
            
        smax1[index] = smax0
        smin1[index] = smin0        
            
    end
            
    return NRTR, trend, NRTR 
    
end

function RangeSizeCalc(Len, Km, Size, Switch, smoothStep, index, DS)

    local result = 0
      
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

            result = rangeEMA[#rangeEMA]
            
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
                    --atrRange[iii] = Range
                end
            end

            --result = round(0.5*Km*(ATRmax+ATRmin)/SEC_PRICE_STEP, nil)
            result = 0.5*(ATRmax+ATRmin)
            --result = MedianF(atrRange, #atrRange, #atrRange)
            
        else result=Km*Size
        end
    end

    return result

end

---adaptive period
function CyberCycle()
	
	local Price={}
	local Smooth={}
	local Cycle={}
	local CyclePeriod={}
	local InstPeriod={}
	local Q1={}
	local I1={}
	local DeltaPhase={}
    
	return function(index, Fsettings, DS)
		
		local Fsettings=(Fsettings or {})
		local alpha = (Fsettings.alpha or 0.07)
				
		local DC, MedianDelta
		
		if index == 1 then
			
			Price = {}
			Smooth={}
			Cycle={}
			CyclePeriod={}
			InstPeriod={}
			Q1={}
			I1={}
			DeltaPhase={}
			
			Price[index] = (DS:H(index) + DS:L(index))/2 or 0
			Smooth[index]=0
			Cycle[index]=0
			CyclePeriod[index]=0
			InstPeriod[index]=0
			Q1[index]=0
			I1[index]=0
			DeltaPhase[index]=0
			
			return 29
		end
				
		Price[index] = (DS:H(index) + DS:L(index))/2 or 0
		
		if index < 4 then
			Cycle[index]=0
			CyclePeriod[index]=0
			InstPeriod[index]=0
			Q1[index]=0
			I1[index]=0
			DeltaPhase[index]=0
			return 29
		end
		
		Smooth[index] = (Price[index]+2*Price[index - 1]+2*Price[index - 2]+Price[index - 3])/6.0
		Cycle[index]=(Price[index]-2.0*Price[index - 1]+Price[index - 2])/4.0
		
		if index < 7 then
			CyclePeriod[index]=0
			InstPeriod[index]=0
			Q1[index]=0
			I1[index]=0
			DeltaPhase[index]=0
			return 29
		end
					
		Cycle[index]=(1.0-0.5*alpha) *(1.0-0.5*alpha) *(Smooth[index]-2.0*Smooth[index - 1]+Smooth[index - 2])
						+2.0*(1.0-alpha)*Cycle[index - 1]-(1.0-alpha)*(1.0-alpha)*Cycle[index - 2]			   
				        
		Q1[index] = (0.0962*Cycle[index]+0.5769*Cycle[index-2]-0.5769*Cycle[index-4]-0.0962*Cycle[index-6])*(0.5+0.08*(InstPeriod[index-1] or 0))
		I1[index] = Cycle[index-3]
						
		if Q1[index]~=0.0 and Q1[index-1]~=0.0 then 
			DeltaPhase[index] = (I1[index]/Q1[index]-I1[index-1]/Q1[index-1])/(1.0+I1[index]*I1[index-1]/(Q1[index]*Q1[index-1]))
		else DeltaPhase[index] = 0	
		end
		if DeltaPhase[index] < 0.1 then
			DeltaPhase[index] = 0.1
		end	
		if DeltaPhase[index] > 0.9 then
			DeltaPhase[index] = 0.9
		end
				
		MedianDelta = Median(DeltaPhase[index],DeltaPhase[index-1], Median(DeltaPhase[index-2], DeltaPhase[index-3], DeltaPhase[index-4]))
		--MedianDelta = MedianF(DeltaPhase, index, 5)
         
        if MedianDelta == 0.0 then
            DC = 15.0
        else
            DC = 6.28318/MedianDelta + 0.5
		end	
        
        InstPeriod[index] = 0.33 * DC + 0.67 * (InstPeriod[index-1] or 0)
        CyclePeriod[index] = 0.15 * InstPeriod[index] + 0.85 * CyclePeriod[index-1]
						
		P = math.floor(CyclePeriod[index])
		
		return P
	end
end

function MedianF(arr, index, m_len)     
   
	local MedianArr = {}
	for i = 1, m_len do
		MedianArr[i] = arr[index-i+1]
	end

	table.sort(MedianArr)

	if m_len % 2 == 0 then 
		  result = (MedianArr[m_len/2] + MedianArr[(m_len/2)+1])/2.0
	else
		  result = MedianArr[(m_len+1)/2]
	end
	
	return result
end

function cached_ZZ()
	
	local CC={} -- значени¤ закрыти¤ свечей	
	local CH={} -- значени¤ максимумов
	local CL={} -- значени¤ минимумов
	
	local HighMapBuffer={} -- знечени¤ максимов предшествующего движени¤
	local LowMapBuffer={} -- знечени¤ минимумов предшествующего движени¤
		
	local Peak={}
	    
    local lastlow = 0
    local lasthigh = 0
    local last_peak = 0
    local lastindex = -1
    local peak_count = 0

	return function(ind, Fsettings, DS)
		
		local Fsettings=(Fsettings or {})
		local index = ind
        
        local Depth = Fsettings.Depth or 12
		local deviation = Fsettings.deviation or 5
		local Backstep = Fsettings.Backstep or 3
		local endIndex = Fsettings.endIndex or DS:Size()
		        
        local searchBoth = 0;
        local searchPeak = 1;
        local searchLawn = -1;

		if index == 1 then
			CC={}
			CH={}
			CL={}

			Peak={}
			
			HighMapBuffer={}
			LowMapBuffer={}

			ZZLevels={}
			------------------
			CC[index]=0
			CH[index]=0
			CL[index]=0
			
			Peak[index]=nil
			
			HighMapBuffer[index]=0
			LowMapBuffer[index]=0
			
            lastindex = -1;		
            lastlow = 0;
            lasthigh = 0;
            last_peak = 0;
            peak_count = 0;        

			return nil
		end
			
		CC[index]=CC[index-1]					
		CH[index]=CH[index-1] 
        CL[index]=CL[index-1]
    		
		if index < Depth or DS:C(index) == nil then
            HighMapBuffer[index]=HighMapBuffer[index-1]
            LowMapBuffer[index]=LowMapBuffer[index-1]       
		    Peak[index]=nil
			return Peak[index]
		end

        CC[index]=DS:C(index)
		CH[index]=DS:H(index) 
		CL[index]=DS:L(index) 
        
		if index < endIndex then
            HighMapBuffer[index]=HighMapBuffer[index-1]
            LowMapBuffer[index]=LowMapBuffer[index-1]       
		    Peak[index]=nil
			return Peak[index]
		end
        
        local sizeOfZZLevels = #ZZLevels
        local searchMode = searchBoth;
                        
            lastindex = index
            
            HighMapBuffer[index]=0 
            LowMapBuffer[index]=0        
		    Peak[index]=nil
            
            
            local start;
            local last_peak;
            local last_peak_i;
            
            start = Depth;
            
            i = GetPeak(index, -3, Peak, ZZLevels);
            
            if i == -1 then
                last_peak_i = 0;
                last_peak = 0;
            else
                last_peak_i = i;
                last_peak = Peak[i];
                start = i;
            end
            
            for i = start, index, 1 do
                Peak[i]=nil;
                LowMapBuffer[i]=0.0;
                HighMapBuffer[i]=0.0;
            end
            
            searchMode = searchBoth;
            if LowMapBuffer[start]~=0 then
                searchMode = searchPeak
            elseif HighMapBuffer[start]~=0 then
                searchMode = searchLawn
            end        
            
            for i = start, index-1, 1 do
                
                -- fill high/low maps
                local range = i - Depth + 1;
                local val;
                
                -- get the lowest low for the last depth is
                val = math.min(unpack(CL, range, i));
                if val == lastlow then
                    -- if lowest low is not changed - ignore it
                    val = nil;
                else
                    -- keep it
                    lastlow = val;
                    -- if current low is higher for more than Deviation pips, ignore
                    if (CL[i] - val) > (SEC_PRICE_STEP * deviation) then
                        val = nil;
                    else
                        -- check for the previous backstep lows
                        for k = i - 1, i - Backstep + 1, -1 do
                            if (LowMapBuffer[k] ~= 0) and (LowMapBuffer[k] > val) then
                                LowMapBuffer[k] = 0;
                            end
                        end
                    end
                end
                if CL[i] == val then
                    LowMapBuffer[i] = val;
                else
                    LowMapBuffer[i] = 0;
                end
                
                -- get the highest high for the last depth is
                val = math.max(unpack(CH, range, i));
                if val == lasthigh then
                    -- if lowest low is not changed - ignore it
                    val = nil;
                else
                    -- keep it
                    lasthigh = val;
                    -- if current low is higher for more than Deviation pips, ignore
                    if (val - CH[i]) > (SEC_PRICE_STEP * deviation) then
                        val = nil;
                    else
                        -- check for the previous backstep lows
                        for k = i - 1, i - Backstep + 1, -1 do
                            if (HighMapBuffer[k] ~= 0) and (HighMapBuffer[k] < val) then
                                HighMapBuffer[k] = 0;
                            end
                        end
                    end
                end
                
                if CH[i] == val then
                    HighMapBuffer[i] = val;
                else
                    HighMapBuffer[i] = 0
                end
                
            end
                        
            peak_count = 0
            if start ~= Depth then
                peak_count = - 3;
            end
                        
            for i = start, index-1, 1 do
                
                sizeOfZZLevels = #ZZLevels
                
                if searchMode == searchBoth then
                    if (HighMapBuffer[i] ~= 0) then
                        last_peak_i = i;
                        last_peak = CH[i]
                        searchMode = searchLawn;
                        LowMapBuffer[i] = 0
                        peak_count = RegisterPeak(i, last_peak, Peak, peak_count, ZZLevels);
                    elseif (LowMapBuffer[i] ~= 0) then
                        last_peak_i = i;
                        last_peak = CL[i] --owBuffer[i];
                        searchMode = searchPeak;
                        peak_count = RegisterPeak(i, last_peak, Peak, peak_count, ZZLevels);
                    end
                elseif searchMode == searchPeak then
                    if (LowMapBuffer[i] ~= 0 and LowMapBuffer[i] < last_peak and HighMapBuffer[i] == 0) then
                        Peak[last_peak_i] = nil
                        last_peak = LowMapBuffer[i];
                        last_peak_i = i;
                        ReplaceLastPeak(i, last_peak, Peak, peak_count, ZZLevels);
                    end
                    if HighMapBuffer[i] ~= 0 and LowMapBuffer[i] == 0 then
                        last_peak = HighMapBuffer[i];
                        last_peak_i = i;
                        searchMode = searchLawn;
                        peak_count = RegisterPeak(i, last_peak, Peak, peak_count, ZZLevels);
                    end
                elseif searchMode == searchLawn then
                    if (HighMapBuffer[i] ~= 0 and HighMapBuffer[i] > last_peak and LowMapBuffer[i] == 0) then
                        Peak[last_peak_i] = nil
                        last_peak = HighMapBuffer[i];
                        last_peak_i = i;
                        ReplaceLastPeak(i, last_peak, Peak, peak_count, ZZLevels);
                    end
                    if LowMapBuffer[i] ~= 0 and HighMapBuffer[i] == 0 then
                        last_peak = LowMapBuffer[i];
                        last_peak_i = i;
                        searchMode = searchPeak;
                        peak_count = RegisterPeak(i, last_peak, Peak, peak_count, ZZLevels);
                    end
                end
            end
                                    
        return Peak[index]

    end
end
