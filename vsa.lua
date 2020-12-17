Settings =
{
	Name = "*VSA",
	lookBack = 21,
	volumeFactor = 1,
	useVolumeMA = 1,
	volMAPeriod = 21,
	useChunk = 1,
	chunkMA_Factor = 1,
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
	,
		{
			Name = "ChunkUp",
			Color = RGB(0,219, 108),
			Type = TYPE_HISTOGRAM,
			Width = 3
		}
	,
		{
			Name = "ChunkDown",
			Color = RGB(255, 0, 0),
			Type = TYPE_HISTOGRAM,
			Width = 3
		}
	}
}

MIN_PRICE_STEP 	= 1
SCALE 			= 1

function Init()
	myCalculateVolume = CalculateVolume()
	return #Settings.line
end

function OnCalculate(index)

	if index == 1 then
		local DSInfo = getDataSourceInfo()
		MIN_PRICE_STEP = getParamEx(DSInfo.class_code, DSInfo.sec_code, "SEC_PRICE_STEP").param_value
		SCALE = getSecurityInfo(DSInfo.class_code, DSInfo.sec_code).scale
	end

	return myCalculateVolume(index, Settings)
end

----------------------------------------------------------
function CalculateVolume()

	local cache_volEMA={}
	local DeltaBuffer={}
	local DeltaCalculations={}
	local cache_DeltaEMA={}

	return function(ind, FSettings)

		FSettings = FSettings or {}
		local index = ind
		local lookBack = FSettings.lookBack or 21
		local volMAPeriod = FSettings.volMAPeriod or 21
		local volumeFactor = FSettings.volumeFactor or 1
		local useVolumeMA = FSettings.useVolumeMA or 1
		local useChunk = FSettings.useChunk or 0
		local chunkMA_Factor = FSettings.chunkMA_Factor or 1
		local useCumulativeDelta = FSettings.useCumulativeDelta or 0
		local useClosePrice = FSettings.useClosePrice or 1

		local DeltaFactor = 2

		local k = 2/(volMAPeriod+1)

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
			return nil
		end

		if not CandleExist(index) then
			cache_volEMA[index] = cache_volEMA[index-1]
			DeltaBuffer[index] = DeltaBuffer[index-1]
			DeltaCalculations[index] = DeltaCalculations[index-1]
			cache_DeltaEMA[index] = cache_DeltaEMA[index-1]
			return nil
		end

		local priceMax = H(index)
		local priceMin = L(index)

		if useClosePrice == 1 and useChunk~=1 then
			priceMax = math.max(O(index), C(index))
			priceMin = math.min(O(index), C(index))
		end
		if priceMax == priceMin then priceMax = priceMin + MIN_PRICE_STEP end

		local vol = V(index)
		if useChunk == 1 then
			vol = round(V(index)*MIN_PRICE_STEP/math.abs(priceMax-priceMin), SCALE)
		end

		cache_volEMA[index]=k*math.pow(vol, volumeFactor)+(1-k)*cache_volEMA[index-1]
		--if index >= (Size() - 10) then message('vol '..tostring(vol)..', vol factor '..tostring(volumeFactor)..', ema '..tostring(cache_volEMA[index])) end

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

		local extraVolume = math.pow(V(index), volumeFactor)

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
			return nil
		end

		local out = math.pow(vol, volumeFactor)
		local outVolEMA = cache_volEMA[index]
		local outDeltaEMA = DeltaCalculations[index]

		if useVolumeMA==0 then
			outVolEMA = nil
		end
		if useCumulativeDelta==0 then
			outDeltaEMA = nil
		end

		if useChunk == 1 then

			if vol>chunkMA_Factor*cache_volEMA[index] and C(index) > (priceMax + priceMin)/2 then

				return outVolEMA, outDeltaEMA, nil, nil, nil, nil, nil, nil, out, nil --Chunk Up

			elseif vol>chunkMA_Factor*cache_volEMA[index] and C(index) < (priceMax + priceMin)/2 then

				return outVolEMA, outDeltaEMA, nil, nil, nil, nil, nil, nil, nil, out --Chunk Down

			end

			return outVolEMA, outDeltaEMA, nil, nil, out, nil, nil, nil, nil, nil --low
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
		local priceMinLocal = priceMin
		local priceMaxLocal = priceMax
		local min_index = 0

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

        -- When volume is higher than all previous and price is going down - start or end of the down trend

        if (volClimaxCurrent == volClimaxLocal and C(index) < (priceMax + priceMin) / 2)
        then
			return outVolEMA, outDeltaEMA, nil, nil, nil, nil, out, nil, nil, nil --Climax Low
		end

        -- When volume is extra high and price is not changing - absolute consolidation or fast accummulation / distribution

        if (volClimaxCurrent == volClimaxLocal and volChurnCurrent == volChurnLocal)
        then
 			return outVolEMA, outDeltaEMA, nil, nil, nil, nil, nil, out, nil, nil --Climax Churn
		end

        -- When volume is higher than all previous and price is going up - start or end of the up trend

        if (volClimaxCurrent == volClimaxLocal and C(index) > (priceMax + priceMin) / 2)
        then
 			return outVolEMA, outDeltaEMA, nil, out, nil, nil, nil, nil, nil, nil --Climax High
       end

        -- When volume is equal to one seen before mark it as accummulation / distribution - profit is taken

        if (volChurnCurrent == volChurnLocal)
        then
			return outVolEMA, outDeltaEMA, nil, nil, nil, out, nil, nil, nil, nil--Churn
		end

		if (index == min_index)
        then
			return outVolEMA, outDeltaEMA, nil, nil, out, nil, nil, nil, nil, nil --Low
		end

		return outVolEMA, outDeltaEMA, out, nil, nil, nil, nil, nil, nil, nil --neutral

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
