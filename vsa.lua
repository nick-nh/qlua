--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	VSA
]]

local logfile = nil
--logfile		= io.open(_G.getWorkingFolder().."\\LuaIndicators\\volume.txt", "w")

local message       	= _G['message']
local CandleExist      	= _G['CandleExist']
local O     			= _G['O']
local C     			= _G['C']
local H     			= _G['H']
local L     			= _G['L']
local V     			= _G['V']
local floor 			= math.floor
local ceil 				= math.ceil
local math_pow 			= math.pow
local math_max      	= math.max
local math_abs      	= math.abs
local math_min      	= math.min
local os_time			= os.time
local max_errors		= 10
local PlotLines     	= function() end
local min_price_step 	= 1
local scale 			= 1

local RGB           	= _G['RGB']
local TYPE_LINE     	= _G['TYPE_LINE']
local TYPE_HISTOGRAM    = _G['TYPE_HISTOGRAM']
local isDark        	= _G.isDarkTheme()
local line_color    	= isDark and RGB(240, 240, 240) or RGB(0, 0, 0)

_G.Settings =
{
	Name = "*VSA",
	lookBack = 21,
	volumeFactor = 1.0,
	useVolumeMA = 1,
	volMAPeriod = 21,
	volMAKoeff = 1.0,
	useChunk = 1,
	chunkMA_Factor = 1.0,
	useCumulativeDelta = 0,
	useClosePrice = 1,
	line=
	{
		{
			Name  	= "VolEMA",
			Color 	= line_color,
			Type  	= TYPE_LINE,
			Width 	= 2
		}
	,
		{
			Name 	= "Delta",
			Color 	= line_color,
			Type  	= TYPE_LINE,
			Width 	= 2
		}
	,
		{
			Name 	= "Neutral",
			Color 	= RGB(0,128, 255),
			Type  	= TYPE_HISTOGRAM,
			Width 	= 3
		}
	,
		{
			Name 	= "Climax High",
			Color 	= RGB(255, 0, 0),
			Type  	= TYPE_HISTOGRAM,
			Width 	= 3
		}
	,
		{
			Name 	= "Low",
			Color 	= RGB(150, 150, 150),
			Type  	= TYPE_HISTOGRAM,
			Width 	= 3
		}
	,
		{
			Name 	= "Churn",
			Color 	= RGB(0,219, 108),
			Type  	= TYPE_HISTOGRAM,
			Width 	= 3
		}
	,
		{
			Name 	= "Climax Low",
			Color 	= line_color,
			Type  	= TYPE_HISTOGRAM,
			Width 	= 3
		}
	,
		{
			Name 	= "Climax Churn",
			Color 	= RGB(255,0, 255),
			Type  	= TYPE_HISTOGRAM,
			Width 	= 3
		}
	,
		{
			Name 	= "ChunkUp",
			Color 	= RGB(0,219, 108),
			Type 	= TYPE_HISTOGRAM,
			Width 	= 3
		}
	,
		{
			Name 	= "ChunkDown",
			Color 	= RGB(255, 0, 0),
			Type 	= TYPE_HISTOGRAM,
			Width 	= 3
		}
	}
}

local lines = #_G.Settings.line

local function round(num, idp)
    if num then
        local mult = 10^(idp or 0)
        if num >= 0 then
            return floor(num * mult + 0.5) / mult
        else
            return ceil(num * mult - 0.5) / mult
        end
    else
        return num
    end
end

local function log_tostring(...)
    local n = select('#', ...)
    if n == 1 then
    return tostring(select(1, ...))
    end
    local t = {}
    for i = 1, n do
    t[#t + 1] = tostring((select(i, ...)))
    end
    return table.concat(t, " ")
end

local function myLog(...)
	if logfile==nil then return end
    logfile:write(tostring(os.date("%c",os_time())).." "..log_tostring(...).."\n");
    logfile:flush();
end

----------------------------------------------------------
local function CalculateVolume(FSettings)

	FSettings 					= FSettings or {}
	local lookBack 				= FSettings.lookBack or 21
	local volMAPeriod 			= FSettings.volMAPeriod or 21
	local volMAKoeff 			= FSettings.volMAKoeff or 1
	local volumeFactor 			= FSettings.volumeFactor or 1
	local useVolumeMA 			= FSettings.useVolumeMA or 1
	local useChunk 				= FSettings.useChunk or 0
	local chunkMA_Factor 		= FSettings.chunkMA_Factor or 1
	local useCumulativeDelta 	= FSettings.useCumulativeDelta or 0
	local useClosePrice 		= FSettings.useClosePrice or 1

	local DeltaFactor 			= 2
	local k 					= 2/(volMAPeriod + 1)

	local cache_volEMA			= {}
	local DeltaBuffer			= {}
	local DeltaCalculations		= {}
	local cache_DeltaEMA		= {}

	local error_log				= {}
	local errors				= 0
	local max_errors_reach

	local p_index
    local l_index

	return function(index)


		local status, res1, res2, res3, res4, res5, res6, res7, res8, res9, res10 = pcall(function()

			if index == 1 then

				l_index 				= index
				cache_volEMA 			= {}
				DeltaBuffer 			= {}
				DeltaCalculations 		= {}
				cache_DeltaEMA 			= {}

				if CandleExist(index) then
					DeltaBuffer[index]			= math_pow(V(index), volumeFactor)
					DeltaCalculations[index]	= math_pow(V(index), volumeFactor)
					cache_volEMA[index]			= math_pow(V(index), volumeFactor)
					cache_DeltaEMA[index]		= math_pow(V(index), volumeFactor)
				else
					cache_volEMA[index]			= 0
					DeltaBuffer[index]			= 0
					DeltaCalculations[index]	= 0
					cache_DeltaEMA[index]		= 0
				end
				return nil
			end

			cache_volEMA[index] 		= cache_volEMA[index-1] or 0
			DeltaBuffer[index] 			= DeltaBuffer[index-1] or 0
			DeltaCalculations[index] 	= DeltaCalculations[index-1] or 0
			cache_DeltaEMA[index] 		= cache_DeltaEMA[index-1] or 0

			if not CandleExist(index) then
				return nil
			end

			if index ~= l_index then
				p_index = l_index
				cache_volEMA[l_index - lookBack] 		= nil
				DeltaBuffer[l_index - lookBack] 		= nil
				DeltaCalculations[l_index - lookBack] 	= nil
				cache_DeltaEMA[l_index - lookBack] 		= nil
			end

			local priceMax = H(index)
			local priceMin = L(index)

			if useClosePrice == 1 and useChunk~=1 then
				priceMax = math_max(O(index), C(index))
				priceMin = math_min(O(index), C(index))
			end

			if priceMax == priceMin then priceMax = priceMin + min_price_step end

			local vol = V(index)
			if useChunk == 1 then
				vol = round(V(index)*min_price_step/math_abs(priceMax-priceMin), scale)
			end

			cache_volEMA[index] = k*math_pow(vol, volumeFactor)+(1-k)*cache_volEMA[index-1]
			local extraVolume 	= math_pow(V(index), volumeFactor)

			if C(index) > C(p_index) then
				DeltaBuffer[index] = extraVolume
			else
				DeltaBuffer[index] = -1*extraVolume
			end
			if useCumulativeDelta then
				DeltaBuffer[index] = DeltaBuffer[index] / DeltaFactor
			else
				DeltaBuffer[index] = DeltaBuffer[index] / DeltaFactor
			end

			DeltaCalculations[index] 	= DeltaBuffer[index - 1] + extraVolume
			cache_DeltaEMA[index]		= k*DeltaCalculations[index] + (1-k)*cache_DeltaEMA[index-1]

			l_index = index

			if index < lookBack then
				return nil
			end

			local out 			= math_pow(vol, volumeFactor)
			local outVolEMA 	= volMAKoeff*cache_volEMA[index]
			local outDeltaEMA 	= DeltaCalculations[index]

			if useVolumeMA==0 then
				outVolEMA = nil
			end
			if useCumulativeDelta==0 then
				outDeltaEMA = nil
			end

			if useChunk == 1 then

				if vol > chunkMA_Factor*cache_volEMA[index] and C(index) > (priceMax + priceMin)/2 then
					return outVolEMA, outDeltaEMA, nil, nil, nil, nil, nil, nil, out, nil --Chunk Up
				elseif vol > chunkMA_Factor*cache_volEMA[index] and C(index) < (priceMax + priceMin)/2 then
					return outVolEMA, outDeltaEMA, nil, nil, nil, nil, nil, nil, nil, out --Chunk Down
				end

				return outVolEMA, outDeltaEMA, nil, nil, out, nil, nil, nil, nil, nil --low
			end

			local volClimaxCurrent = V(index) * (priceMax - priceMin)
			local volChurnCurrent = 0

			if volClimaxCurrent > 0 then
				volChurnCurrent = V(index) / (priceMax - priceMin)
			end

			local volClimaxLocal 	= 0
			local volChurnLocal 	= 0
			local v_H 				= 0
			local v_L 				= 0
			local min_index 		= 0

			local priceMinLocal
			local priceMaxLocal
			local climax
			local churn

			for n = index - lookBack + 1, index do

				if CandleExist(n) then

					priceMinLocal = L(n)
					priceMaxLocal = H(n)

					if useClosePrice == 1 then
						priceMinLocal = math_min(O(n), C(n))
						priceMaxLocal = math_max(O(n), C(n))
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

		end)
		if not status then
			errors = errors + 1
			if errors > max_errors and not max_errors_reach then
				message(_G.Settings.Name ..': Слишком много ошибок при работе индикатора.')
				max_errors_reach = true
			end
			if not error_log[tostring(res1)] then
				error_log[tostring(res1)] = true
				myLog('Error CalcFunc: '..tostring(res1))
				message('Error CalcFunc: '..tostring(res1))
			end
			return nil
		end
		return res1, res2, res3, res4, res5, res6, res7, res8, res9, res10
	end
end

function _G.OnCalculate(index)
	if index == 1 then
		local DSInfo 	= _G.getDataSourceInfo()
		min_price_step 	= _G.getParamEx(DSInfo.class_code, DSInfo.sec_code, "SEC_PRICE_STEP").param_value
		scale 			= _G.getSecurityInfo(DSInfo.class_code, DSInfo.sec_code).scale
	end
	return PlotLines(index)
end

function _G.Init()
	PlotLines = CalculateVolume(_G.Settings)
	return lines
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnDestroy()
	if logfile then logfile:close() end
end
