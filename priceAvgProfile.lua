--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	Горизонтальные объемы. Профиль.
]]

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\priceAvgProfile.log", "w")

_G.unpack = rawget(table, "unpack") or _G.unpack

_G.Settings = {}
_G.Settings.Name 			= "*priceAvgProfile"
_G.Settings.period 			= 180 	-- Число бар истории для анализа
_G.Settings.shift 			= 100	-- Сдвиг линий по горизонтали влево
_G.Settings.barShift 		= 0		-- Сдиг бар для анализа от последнего
_G.Settings.weeks 			= 0 	-- 1 - текущая, отрицательное число - сколько прошлых недель, включая текущую
_G.Settings.fixShift 		= 1 	-- 1 - всегда смещено на указанное количество shift, если 0, то будет смещено на дату начала недели расчета
_G.Settings.bars_in_line	= 50	-- Максимальная длина линий в барах. Не должна превышать период построения.
_G.Settings.showMaxLine 	= 1
_G.Settings.partMode 		= 0 	-- Режим формирования отдельных данных для каждого интервала. В этом режиме данные будут формироваться каждые partBars
_G.Settings.partBars 		= 60	-- Число бар интервала для формирования данных
_G.Settings.partPeriod 		= 0		--[[Интервал привязки данных в минутах. 60 - будут привязаны к началу часа. При этом ТФ построения должен быть меньше.
										Для примера строим на ТФ М1, каждые 60 бар, с привязкой к ТФ 60 мин.
										0 - выключено. Произвольная привязка от последнего бара при запуске.]]
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
local os_date	    	= os.date
local PlotLines     	= function() end


local O    				= _G['O']
local H    				= _G['H']
local L    				= _G['L']
local V    				= _G['V']
local T    				= _G['T']
local Size 				= _G['Size']
local SetRangeValue 	= _G['SetRangeValue']
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
    logFile:write(tostring(os_date("%c",os_time())).." "..log_tostring(...).."\n");
    logFile:flush();
end


---------------------------------------------------------------------------------------
local function Algo(Fsettings)

    local period 		= Fsettings.period or 180
    local shift 		= Fsettings.shift or 100
    local barShift 		= Fsettings.barShift or 0
    local weeks 		= Fsettings.weeks or 0
    local fixShift 		= Fsettings.fixShift or 0
    local showMaxLine 	= Fsettings.showMaxLine or 0
    local partMode 		= Fsettings.partMode or 0
    local partBars 		= Fsettings.partBars or 60
    local partPeriod 	= Fsettings.partPeriod or 60
    local bars_in_line 	= Fsettings.bars_in_line or 50
	local part_shift 	= 0

	shift 			= partMode == 1 and partBars or math_max(bars_in_line+1, shift)
	weeks 			= partMode == 1 and 0 or weeks
	bars_in_line 	= partMode == 1 and math_min(bars_in_line, partBars) or bars_in_line

	local cacheL		= {}
	local cacheH		= {}
    local weeksBegin    = {}
    local maxPriceLine	= {}
	local beginIndex	= 0
	local beginTime		= 0
	error_log 			= {}

	local outlines 		= {}
	local calculated_buffer={}

    local ds_info
	local ds_shift		= 0
	local bars			= 0

	local function get_begin_time(sdt)

		local bar_time 	 = os_time(sdt)
		local p_bar_time = bar_time

		sdt.sec = 0
        if partPeriod > 1 and partPeriod <= 60 then
            sdt.min = math_floor(sdt.min/partPeriod)*partPeriod
			p_bar_time = os_time(sdt)
        end

		if partPeriod > 60 then
            sdt.hour = 0; sdt.min  = 0
            local day_begin_time = os_time(sdt)
            p_bar_time = day_begin_time + math_floor((bar_time - day_begin_time)/part_shift)*part_shift - ds_shift
        end

        -- return math_floor((bar_time - p_bar_time)/60/ds_info.interval)
		return p_bar_time, math_floor((bar_time - p_bar_time)/ds_shift)
    end

	return function(index)

        local status, res = pcall(function()

			if ds_info == nil or index == 1 then

				ds_info 	    = _G.getDataSourceInfo()
				ds_shift		= ds_info.interval*60
				maxPriceLine 	= {}
	            weeksBegin 		= {}
	            cacheL 			= {}
	            cacheL[index] 	= 0
	            cacheH 			= {}
	            cacheH[index] 	= 0

				calculated_buffer 	= {}
	            outlines 			= {}

				beginIndex 	= math_max(Size() - barShift, 1)
				beginTime  	= os.time(T(beginIndex))
				part_shift 	= ds_shift*partBars

				if partMode == 1 then
					beginIndex 	= math_max(Size() - period, 1) -- 40 - 20 = 20 {10 - 19} 10 бар las bar not count
					beginTime 	= os.time(T(beginIndex))	-- 08:00
					--myLog('init beginIndex', beginIndex, os_date('%Y.%m.%d %H:%M', beginTime), 'interval', ds_info.interval, 'part_shift', part_shift)
					if partPeriod ~= 0 then
						part_shift 	= partPeriod*60
						local begin_time, begin_shift = get_begin_time(T(beginIndex))
						beginTime  	= begin_time
						beginIndex  = beginIndex - begin_shift
					end
					beginTime 	= beginTime + part_shift
					-- beginTime 	= beginTime - ds_shift -- 07:59
				end

				--myLog('index '..tostring(index), os_date('%Y.%m.%d %H:%M', os.time(T(index))), 'beginIndex', beginIndex, os_date('%Y.%m.%d %H:%M', os.time(T(beginIndex))), 'beginTime', os_date('%Y.%m.%d %H:%M', beginTime))
				return nil
			end

			cacheL[index] = cacheL[index-1]
			cacheH[index] = cacheH[index-1]

			if not CandleExist(index) then
				return maxPriceLine[index]
			end

			local bar_time 	= os_time(T(index))
			cacheH[index] 	= H(index)
	        cacheL[index] 	= L(index)

			if T(index).week_day<T(index-1).week_day or T(index).year>T(index-1).year then
				weeksBegin[#weeksBegin+1] = index
			end

			bars = bars + 1

			if (bar_time < beginTime or index < beginIndex or (partMode == 1 and bars < partBars and ds_info.interval >= 60)) and index ~= Size() then return nil end

			if calculated_buffer[index] ~= nil then
				return maxPriceLine[index]
			end

			if partMode == 0 then

				beginIndex = index - period

				if weeks == 1 then
					beginIndex = weeksBegin[#weeksBegin] or beginIndex
				end
				if weeks < 0 then
					beginIndex = weeksBegin[#weeksBegin+weeks] or beginIndex
				end
				if fixShift == 0 then
					shift = math_max(bars_in_line+1, index - beginIndex)
				end

			end

			local lines_begin = index - shift
			local delta_shift = 1

			if partMode == 1 then
				lines_begin = beginIndex
				delta_shift = 0
			end

			lines_begin = math_max(lines_begin, 1)

			if showMaxLine==1 then
				SetRangeValue(1, lines_begin - delta_shift, index-1, nil)
			end

			for i=1,#outlines do
				SetRangeValue(i+1, lines_begin - delta_shift, index-1, nil)
				outlines[i].index = lines_begin
				outlines[i].val = nil
			end

			--myLog('index '..tostring(index), os_date('%Y.%m.%d %H:%M', bar_time), 'bars', bars, 'lines_begin', lines_begin, os_date('%Y.%m.%d %H:%M', os.time(T(lines_begin))), 'beginIndex', beginIndex, 'beginTime', os_date('%Y.%m.%d %H:%M', beginTime), 'beginIndex Time', CandleExist(beginIndex) and os_date('%Y.%m.%d %H:%M', os.time(T(beginIndex))))
			-- myLog('weeks '..tostring(weeks)..' last '..tostring(weeksBegin[#weeksBegin])..' beginIndex '..tostring(beginIndex))

			local maxPrice = math_max(unpack(cacheH, lines_begin, index-1))
			local minPrice = math_min(unpack(cacheL, lines_begin, index-1))

			----------------------------------------
			local priceProfile = {}
			local clasterStep = math_max((maxPrice - minPrice)/lines, min_price_step)

			-- myLog('minPrice '..tostring(minPrice)..' maxPrice '..tostring(maxPrice)..' clasterStep '..tostring(clasterStep))

			for i = 0, (index-1-lines_begin) do
				if CandleExist(index-i) then
					local barSteps = math_max(math_ceil((H(index-i) - L(index-i))/clasterStep),1)
					for j=0,barSteps-1 do
						local clasterPrice = math_floor((L(index-i) + j*clasterStep)/clasterStep)*clasterStep
						local clasterIndex = clasterPrice*math_pow(10, scale)
						if priceProfile[clasterIndex] == nil then
							priceProfile[clasterIndex] = {price = clasterPrice, vol = 0}
						end
						priceProfile[clasterIndex].vol = priceProfile[clasterIndex].vol + V(index-i)/barSteps
						-- myLog('index', index-i, 'clasterIndex '..tostring(clasterIndex)..' vol '..tostring(priceProfile[clasterIndex].vol))
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
				maxVolPrice = O(index-1)
			end

			table.sort(sortedProfile, function(a,b) return (a['vol'] or 0) > (b['vol'] or 0) end)

			---------------------
			for i=1,lines do

				outlines[i] = {index = lines_begin + bars_in_line - 1, val = maxVolPrice}

				if sortedProfile[i]~=nil then
					sortedProfile[i].vol = math_floor(sortedProfile[i].vol/MAXV*bars_in_line)
					if sortedProfile[i].vol>0 then
						outlines[i].index = lines_begin + sortedProfile[i].vol - 1
						outlines[i].val = sortedProfile[i].price
					end
				end
				SetRangeValue(i+1, lines_begin, outlines[i].index, outlines[i].val)

				--myLog('line '..tostring(i).." price "..tostring(GetValue(lines_begin, i)).." - "..tostring(GetValue(outlines[i].index, i)).." vol "..tostring(outlines[i].index-index+shift))

			end

			if showMaxLine==1 then
				SetRangeValue(1, lines_begin, index-1, maxVolPrice)
				maxPriceLine[index] = maxVolPrice
			end

			calculated_buffer[index] = true

			if partMode == 1 then
				if bar_time >= beginTime and (bars >= partBars or ds_info.interval < 60) then -- bar_time 08:00 > 07:59
					beginIndex 		= index
					beginTime		= beginTime + part_shift-- 08:59
					maxPriceLine 	= {}
					bars			= 1
					--myLog('-- index '..tostring(index), os_date('%Y.%m.%d %H:%M', bar_time), 'beginIndex', beginIndex, 'new begin time', os_date('%Y.%m.%d %H:%M', beginTime))
					-- return
				end
			end

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
        end

		-- return maxPriceLine[index]
	end
end


function _G.Init()
	_G.Settings.line = {}
	_G.Settings.line[1] = {}
	_G.Settings.line[1] = {Name = 'maxVol', Color = _G.RGB(255, 128, 64), Type = _G.TYPET_BAR, Width = 2}
	for i = 1, lines do
		_G.Settings.line[i+1] = {}
		_G.Settings.line[i+1] = {Color = _G.RGB(185, 185, 185), Type = _G.TYPET_BAR, Width = 2}
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

