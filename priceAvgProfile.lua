-- nnh Glukk Inc. nick-h@yandex.ru

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\priceAvgProfile.log", "w")

_G.unpack = rawget(table, "unpack") or _G.unpack

_G.Settings = {}
_G.Settings.period 			= 150
_G.Settings.shift 			= 100
_G.Settings.barShift 		= 0
_G.Settings.Name 			= "*priceAvgProfile"
_G.Settings.weeks 			= 0 -- 1 - текущая, отрицательное число - сколько прошлых недель, включая текущую
_G.Settings.fixShift 		= 1 -- 1 - всегда смещено на указанное количество shift, если 0, то будет смещено на дату начала недели расчета
_G.Settings.showMaxLine 	= 1
---------------------------------------------------------------------------------------

local lines 			= 100
local scale 			= 2
local min_price_step 	= 1
local error_log      	= {}

local math_max      	= math.max
local math_min      	= math.min
local math_floor      	= math.floor
local math_ceil      	= math.ceil
local math_pow      	= math.pow
local os_time	    	= os.time
local PlotLines     	= function() end


local O    				= _G['O']
local C    				= _G['C']
local H    				= _G['H']
local L    				= _G['L']
local V    				= _G['V']
local T    				= _G['T']
local Size 				= _G['Size']
local SetValue 			= _G['SetValue']
local CandleExist 		= _G['CandleExist']
local message       	= _G['message']


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
	if logFile==nil then return end
    logFile:write(tostring(os.date("%c",os_time())).." "..log_tostring(...).."\n");
    logFile:flush();
end

---------------------------------------------------------------------------------------
local function Algo(Fsettings)

    local period 		= Fsettings.period or 150
    local shift 		= Fsettings.shift or 150
    local barShift 		= Fsettings.barShift or 0
    local weeks 		= Fsettings.weeks or 0
    local fixShift 		= Fsettings.fixShift or 0
    local showMaxLine 	= Fsettings.showMaxLine or 0
    local bars 			= 50

	shift = math_max(bars+1, shift)

	local cacheL		= {}
	local cacheH		= {}
    local cacheC		= {}
    local weeksBegin    = {}
    local maxPriceLine	= {}

    error_log 			= {}

	local outlines 		= {}
	local calculated_buffer={}

	return function(index)

        local status, res = pcall(function()

			if index == 1 then
	            maxPriceLine 	= {}
	            weeksBegin 		= {}
	            cacheL 			= {}
	            cacheL[index] 	= 0
	            cacheH 			= {}
	            cacheH[index] 	= 0
	            cacheC 			= {}
	            cacheC[index] 	= 0

				calculated_buffer 	= {}
	            outlines 			= {}

				return nil
			end

			--maxPriceLine[index] = maxPriceLine[index-1]
			cacheL[index] = cacheL[index-1]
			cacheH[index] = cacheH[index-1]
			cacheC[index] = cacheC[index-1]

			if not CandleExist(index) then
				return maxPriceLine[index]
			end

			cacheH[index] = H(index)
	        cacheL[index] = L(index)
	        cacheC[index] = C(index)

			-- myLog('index '..tostring(index)..' T ', tostring(T(index)))
			if T(index).week_day<T(index-1).week_day or T(index).year>T(index-1).year then
				weeksBegin[#weeksBegin+1] = index
			end

			if index ~= Size()-barShift then return nil end

			if calculated_buffer[index] ~= nil then
				return maxPriceLine[index]
			end

			if showMaxLine==1 then
				SetValue(index-shift-1, 1, nil)
				SetValue(index-shift,   1, nil)
				SetValue(index-1,   	1, nil)
			end

			for i=1,#outlines do
				SetValue(index-shift-1,          i+1, nil)
				SetValue(index-shift,            i+1, nil)
				SetValue(outlines[i].index,   	 i+1, nil)

				outlines[i].index = index-shift
				outlines[i].val = nil
			end

			local beginIndex = index-period
			if weeks == 1 then
				beginIndex = weeksBegin[#weeksBegin] or beginIndex
			end
			if weeks < 0 then
				beginIndex = weeksBegin[#weeksBegin+weeks] or beginIndex
			end

			if fixShift==0 then
				shift = math_max(bars+1, index-beginIndex)
			end

			-- myLog('weeks '..tostring(weeks)..' last '..tostring(weeksBegin[#weeksBegin])..' beginIndex '..tostring(beginIndex))

			local maxPrice = math_max(unpack(cacheH,math_max(beginIndex, 1),index))
			local minPrice = math_min(unpack(cacheL,math_max(beginIndex, 1),index))

			----------------------------------------
			local priceProfile = {}
			local clasterStep = math_max((maxPrice - minPrice)/lines, min_price_step)

			-- myLog('minPrice '..tostring(minPrice)..' maxPrice '..tostring(maxPrice)..' clasterStep '..tostring(clasterStep))

			for i = 0, (index-beginIndex) do
				if CandleExist(index-i) then
					local barSteps = math_max(math_ceil((H(index-i) - L(index-i))/clasterStep),1)
					for j=0,barSteps-1 do
						local clasterPrice = math_floor((L(index-i) + j*clasterStep)/clasterStep)*clasterStep
						local clasterIndex = clasterPrice*math_pow(10, scale)
						if priceProfile[clasterIndex] == nil then
							priceProfile[clasterIndex] = {price = clasterPrice, vol = 0}
						end
						priceProfile[clasterIndex].vol = priceProfile[clasterIndex].vol + V(index-i)/barSteps
					end
				end
			end

			--------------------
			local MAXV 			= 0
			local maxVolPrice 	= 0
			local maxCount 		= 0

			local sortedProfile = {}

			for _, profileItem in pairs(priceProfile) do
				MAXV=math_max(MAXV,profileItem.vol)
				if MAXV == profileItem.vol then
					maxVolPrice=profileItem.price
				end
				maxCount = maxCount + 1
				sortedProfile[maxCount] = {price = profileItem.price, vol = profileItem.vol}
			end

			-- myLog('maxV '..tostring(MAXV)..' tblMax '..tostring(sortedProfile[1].vol))

			if maxVolPrice == 0 then
				maxVolPrice = O(index)
			end

			table.sort(sortedProfile, function(a,b) return (a['vol'] or 0) > (b['vol'] or 0) end)

			---------------------
			for i=1,lines do

				outlines[i] = {index = index-shift+bars, val = maxVolPrice}

				if sortedProfile[i]~=nil then
					sortedProfile[i].vol=math_floor(sortedProfile[i].vol/MAXV*bars)
					if sortedProfile[i].vol>0 then
						outlines[i].index = index-shift+sortedProfile[i].vol
						outlines[i].val = sortedProfile[i].price
					end
				end
				SetValue(index-shift,       i+1, outlines[i].val)
				SetValue(outlines[i].index, i+1, outlines[i].val)

				--myLog('line '..tostring(i).." price "..tostring(GetValue(index-shift, i)).." - "..tostring(GetValue(outlines[i].index, i)).." vol "..tostring(outlines[i].index-index+shift))

			end

			if showMaxLine==1 then
				SetValue(index-shift, 1, maxVolPrice)
				maxPriceLine[index] = maxVolPrice
			end

			calculated_buffer[index] = true


        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
        end

		return maxPriceLine[index]
	end
end


function _G.Init()
	_G.Settings.line = {}
	_G.Settings.line[1] = {}
	_G.Settings.line[1] = {Name = 'maxVol', Color = _G.RGB(255, 128, 64), Type = _G.TYPE_LINE, Width = 2}
	for i = 1, lines do
		_G.Settings.line[i+1] = {}
		_G.Settings.line[i+1] = {Color = _G.RGB(185, 185, 185), Type = _G.TYPE_LINE, Width = 2}
	end

	PlotLines = Algo(_G.Settings)
	return lines
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
	if index == 1 then
		local DSInfo 	= _G.getDataSourceInfo()
		min_price_step 	= tonumber(_G.getParamEx(DSInfo.class_code, DSInfo.sec_code, "SEC_PRICE_STEP").param_value) or 0
		scale 			= tonumber(_G.getSecurityInfo(DSInfo.class_code, DSInfo.sec_code).scale) or 0
	end
	return PlotLines(index)
end

