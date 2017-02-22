
Settings = 
{
	Name = "*VSA",
	lookBack = 21,
	volumeFactor = 1,
	useVolumeMA = 1,
	useCumulativeDelta = 0,
	useClosePrice = 1,
	line=
	{
		{
			Name = "VolEMA",
			Color = RGB(0, 0, 0),
			Type = TYPE_LINE,
			Width = 2
		}
	,	
		{
			Name = "Delta",
			Color = RGB(0, 0, 0),
			Type = TYPE_LINE,
			Width = 2
		}
	,
		{
			Name = "Neutral",
			Color = RGB(0,128, 255),
			Type = TYPE_HISTOGRAM,
			Width = 3
		}
	,
		{
			Name = "Climax High",
			Color = RGB(255, 0, 0),
			Type = TYPE_HISTOGRAM,
			Width = 3
		}
	,
		{
			Name = "Low",
			Color = RGB(150, 150, 150),
			Type = TYPE_HISTOGRAM,
			Width = 3
		}
	,
		{
			Name = "Churn",
			Color = RGB(0,219, 108),
			Type = TYPE_HISTOGRAM,
			Width = 3
		}	
	,	
		{
			Name = "Climax Low",
			Color = RGB(0, 0, 0),
			Type = TYPE_HISTOGRAM,
			Width = 3
		}
	,	
		{
			Name = "Climax Churn",
			Color = RGB(255,0, 255),
			Type = TYPE_HISTOGRAM,
			Width = 3
		}
	}
}

function Init()
	myCalculateVolume = CalculateVolume()
	return #Settings.line
end

function OnCalculate(index)

	return myCalculateVolume(index, Settings.lookBack, Settings.volumeFactor, Settings.useVolumeMA, Settings.useCumulativeDelta, Settings.useClosePrice)
end

----------------------------------------------------------
function CalculateVolume()
	
	local cache_volEMA={}
	local DeltaBuffer={}
	local DeltaCalculations={}
	local cache_DeltaEMA={}
	
	return function(ind, _l, _v, _u, _ucd, _ucp)
		
		local index = ind
		local lookBack = _l
		local volumeFactor = _v
		local useVolumeMA = _u
		local useCumulativeDelta = _ucd
		local DeltaFactor = 2
		local useClosePrice = _ucp
		
		local k = 2/(_l+1)

		if index == 1 then
			cache_volEMA = {}
			DeltaBuffer = {}
			DeltaCalculations = {}
			cache_DeltaEMA = {}
			if CandleExist(index) then
				DeltaBuffer[index]= math.pow(V(index), volumeFactor)
				DeltaCalculations[index]= math.pow(V(index), volumeFactor)
				cache_volEMA[index]= math.pow(V(index), volumeFactor)
				cache_DeltaEMA[index]= math.pow(V(index), volumeFactor)
			else 
				cache_volEMA[index]= 0
				DeltaBuffer[index]= 0
				DeltaCalculations[index]= 0
				cache_DeltaEMA[index]= 0
			end
			return nil, nil, nil, nil, nil, nil, nil, nil
		end
		
		if not CandleExist(index) then
			cache_volEMA[index] = cache_volEMA[index-1] 
			DeltaBuffer[index] = DeltaBuffer[index-1]
			DeltaCalculations[index] = DeltaCalculations[index-1]
			cache_DeltaEMA[index] = cache_DeltaEMA[index-1]
			return nil
		end
		
		cache_volEMA[index]=k*math.pow(V(index), volumeFactor)+(1-k)*cache_volEMA[index-1]
		
        local extraVolume = math.pow(V(index), volumeFactor)
    
		local previous = index-1
		
		if not CandleExist(previous) then
			previous = FindExistCandle(previous)
		end
		
		if previous == 0 then
			DeltaBuffer[index] = DeltaBuffer[index-1]
			DeltaCalculations[index] = DeltaCalculations[index-1]
			cache_DeltaEMA[index] = cache_DeltaEMA[index-1]
			return nil
		end
		
		if C(index) > C(previous) then
			DeltaBuffer[index] = extraVolume
		else
			DeltaBuffer[index] = -1*extraVolume
		end
		if useCumulativeDelta then
			DeltaBuffer[index] = DeltaBuffer[index] / DeltaFactor
		else
			DeltaBuffer[index] = DeltaBuffer[index] / DeltaFactor
		end
		
		DeltaCalculations[index] = DeltaBuffer[index - 1] + extraVolume

		cache_DeltaEMA[index]=k*DeltaCalculations[index]+(1-k)*cache_DeltaEMA[index-1]
		
		if index < lookBack then
			return nil, nil, nil, nil, nil, nil, nil, nil
		end
		
		local priceMin = L(index)
		local priceMax = H(index) 

        if useClosePrice == 1 then           
           priceMin = math.min(O(index), C(index))
           priceMax = math.max(O(index), C(index))
        end

		local volClimaxCurrent = V(index) * (priceMax - priceMin)
		local volChurnCurrent = 0
		
		if volClimaxCurrent > 0 then       
           volChurnCurrent = V(index) / (priceMax - priceMin)
        end
		
		local volClimaxLocal = 0
		local volChurnLocal = 0
		local climax = 0
		local churn = 0
		local v_H = 0
		local v_L = 0
		local priceMinLocal = L(n)
		local priceMaxLocal = H(n)
		local min_index = index
		
		for n=index-lookBack + 1,index do
           
		   if CandleExist(n) then
		   
			   priceMinLocal = L(n)
			   priceMaxLocal = H(n)
				
			   if useClosePrice == 1 then           
				   priceMinLocal = math.min(O(n), C(n))
				   priceMaxLocal = math.max(O(n), C(n))
			   end
				
			   climax = V(n) * (priceMaxLocal - priceMinLocal) 
			   
				-- Previous maximal price range can be found here
				
				if climax >= volClimaxLocal
				then
					volClimaxLocal = climax;
				end
				
				-- Previous consolidation can be found here
				
				if climax > 0
				then           
					churn = V(n) / (priceMaxLocal - priceMinLocal)
					
					if churn >= volChurnLocal
					then
						volChurnLocal = churn; 
					end
				end
				
				if v_H < V(n) then v_H = V(n) end
				if v_L > V(n) then 
					v_L = V(n)
					min_index = n
				end
				
		   end
			
		end
		
		local out = math.pow(V(index), volumeFactor)
		local outVolEMA = cache_volEMA[index]
		local outDeltaEMA = DeltaCalculations[index]
		
		if useVolumeMA==0 then
			outVolEMA = nil
		end
		if useCumulativeDelta==0 then
			outDeltaEMA = nil
		end
		
		if (index == n)
        then
			return outVolEMA, outDeltaEMA, nil, nil, out, nil, nil, nil --Low
		end
        
        -- When volume is equal to one seen before mark it as accummulation / distribution - profit is taken
        
        if (volChurnCurrent == volChurnLocal)
        then
			return outVolEMA, outDeltaEMA, nil, nil, nil, out, nil, nil --Churn
		end
        
        -- When volume is higher than all previous and price is going up - start or end of the up trend
        
        if (volClimaxCurrent == volClimaxLocal and C(index) > (priceMax + priceMin) / 2)
        then
 			return outVolEMA, outDeltaEMA, nil, out, nil, nil, nil, nil --Climax High
       end
        
        -- When volume is extra high and price is not changing - absolute consolidation or fast accummulation / distribution
        
        if (volClimaxCurrent == volClimaxLocal and volChurnCurrent == volChurnLocal)
        then
 			return outVolEMA, outDeltaEMA, nil, nil, nil, nil, nil, out --Climax Churn
		end
        
        -- When volume is higher than all previous and price is going down - start or end of the down trend
        
        if (volClimaxCurrent == volClimaxLocal and C(index) < (priceMax + priceMin) / 2)
        then
			return outVolEMA, outDeltaEMA, nil, nil, nil, nil, out, nil --Climax Low
		end
			
		return outVolEMA, outDeltaEMA, out, nil, nil, nil, nil, nil --neutral
			
	end
	
end
	----------------------------
function FindExistCandle(I)

	local out = I
	
	while not CandleExist(out) and out > 0 do
		out = out -1
	end	
	
	return out
 
end
	
function round(num, idp)
	if idp and num then
	   local mult = 10^(idp or 0)
	   if num >= 0 then return math.floor(num * mult + 0.5) / mult
	   else return math.ceil(num * mult - 0.5) / mult end
	else return num end
end
