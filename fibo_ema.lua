
_G.unpack = rawget(table, "unpack") or _G.unpack

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\fibo_ema.txt", "w")

local math_max          = math.max
local math_min          = math.min
local math_abs              = math.abs
local message           = _G['message']
local RGB               = _G['RGB']
local TYPE_LINE         = _G['TYPE_LINE']
local TYPE_POINT        = _G['TYPE_POINT']
local C                 = _G['C']
local O                 = _G['O']
local H                 = _G['H']
local L                 = _G['L']
local CandleExist       = _G['CandleExist']
local os_time	    	= os.time


_G.Settings =
{
	Name = "*FiboEma",
	period = 30,
	bars   = 100,
	line=
	{
		{
			Name = "EMA",
			Color = RGB(0, 128, 0),
			Type = TYPE_LINE,
			Width = 2
		}
	,
		{
			Name = "423.6%",
			Color = RGB(0, 128, 255),
			Type = TYPE_LINE,
			Width = 1
		}
	,
		{
			Name = "261.8%",
			Color = RGB(128, 255, 128),
			Type = TYPE_LINE,
			Width = 1
		}
	,
		{
			Name = "161.8%",
			Color = RGB(255, 128, 255),
			Type = TYPE_LINE,
			Width = 1
		}
	,
		{
			Name = "100%",
			Color = RGB(0, 0, 0),
			Type = TYPE_POINT,
			Width = 1
		}
	,
		{
			Name = "100%",
			Color = RGB(0, 0, 0),
			Type = TYPE_POINT,
			Width = 1
		}
	,
		{
			Name = "161.8%",
			Color = RGB(255, 128, 255),
			Type = TYPE_LINE,
			Width = 1
		}
	,
		{
			Name = "261.8%",
			Color = RGB(128, 255, 128),
			Type = TYPE_LINE,
			Width = 1
		}
	,
		{
			Name = "423.6%",
			Color = RGB(0, 128, 255),
			Type = TYPE_LINE,
			Width = 1
		}
	}
}

local PlotLines     = function(index) return index end
local error_log     = {}

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

----------------------------------------------------------
function Algo(Fsettings)

    Fsettings       = (Fsettings or {})
    local period    = Fsettings.period or 30
    local bars    	= Fsettings.bars or 100

    local save_bars = math_max(period, bars)

	local k = 2/(period+1)
	local kk = 2/(bars+1)

	error_log = {}

    local p_index
    local l_index

	local cache_EMA = {}
	local cache_ATR = {}
	local cache_H 	= {}
	local cache_L 	= {}

	local inc

	return function(index)

		local status, res = pcall(function()

			if index == 1 then
				cache_H 			= {}
				cache_L				= {}
				cache_H[index] 		= H(index) or 0
				cache_L[index] 		= L(index) or 0
				cache_EMA 			= {}
				cache_ATR			= {}
				cache_EMA[index] 	= (C(index)+O(index))/2
				cache_ATR[index] 	= 0
				p_index 			= index
				l_index 			= index
				inc					= 0
				return
			end

			cache_EMA[index] 	= cache_EMA[index-1]
			cache_ATR[index] 	= cache_ATR[index-1]
			cache_H[index] 		= cache_H[index-1]
			cache_L[index] 		= cache_L[index-1]

			if not CandleExist(index) then
				return
			end

			if index ~= l_index then p_index = l_index end

			cache_EMA[index]=k*C(index)+(1-k)*cache_EMA[index-1]
			local ATR = math_max(math_abs(H(index) - L(index)), math_abs(H(index) - C(p_index)), math_abs(C(p_index) - L(index)))
			cache_ATR[index] = kk*ATR+(1-kk)*cache_ATR[index-1]

			l_index = index

			if index <= bars then
				return
			end

			cache_H[index] = H(index) - cache_EMA[index]
			cache_L[index] = L(index) - cache_EMA[index]

			local high = math_max(unpack(cache_H, index-bars+1, index))
			local low  = math_min(unpack(cache_L, index-bars+1, index))

			inc = (math_abs(high) > math_abs(low)) and high or low
			inc = math_abs(inc) + cache_ATR[index]*2

			cache_EMA[index - save_bars] = nil
			cache_ATR[index - save_bars] = nil
			cache_H[index - save_bars] 	 = nil
			cache_L[index - save_bars] 	 = nil

		end)
		if not status then
			if not error_log[tostring(res)] then
				error_log[tostring(res)] = true
				myLog(tostring(res))
				message(tostring(res))
			end
			return nil
		end

		return cache_EMA[index], cache_EMA[index]+inc*0.618, cache_EMA[index]+inc*0.5, cache_EMA[index]+inc*0.382, cache_EMA[index]+inc*0.236, cache_EMA[index]-inc*0.236, cache_EMA[index]-inc*0.382, cache_EMA[index]-inc*0.5, cache_EMA[index]-inc*0.618

	end
end
----------------------------

function _G.Init()
    PlotLines = Algo(_G.Settings)
    return 9
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end