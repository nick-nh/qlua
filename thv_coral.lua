--[[
	nick-h@yandex.ru
    https://github.com/nick-nh/qlua

    THV
]]
_G.unpack = rawget(table, "unpack") or _G.unpack
_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\THV.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local TYPE_POINT    = _G['TYPE_POINT']
local line_color    = RGB(250, 0, 0)
local os_time	    = os.time

_G.Settings= {
    Name 		= "*THV",
    period      = 64,
    data_type   = 'Close',
    koef        = 1.0,
    trend_shift = 1,
    trend_sd    = 1.0,
	color       = 1,
    line = {
        {
            Name  = 'THV',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 2
        },
        {
            Name = "dir up",
            Type = TYPE_POINT,
            Width = 2,
            Color = RGB(89,213, 107)
        },
        {
            Name = "dir dw",
            Type = TYPE_POINT,
            Width = 2,
            Color = RGB(255, 58, 0)
        }
    }
}

local PlotLines     = function(index) return index end
local error_log     = {}
local lines         = #_G.Settings.line

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
------------------------------------------------------------------
    --Moving Average
------------------------------------------------------------------

local function Algo(Fsettings, ds)

    Fsettings   = (Fsettings or {})
    error_log   = {}

    local trend_shift   = Fsettings.trend_shift or 1
    local trend_sd      = Fsettings.trend_sd or 1
    local color         = (Fsettings.color or 0) == 1

    local fMA, ma
    local out
    local begin_index

    local fDSD
    local delta
    local d_sd, trend

    return function (index)

        out = {}

        local status, res = pcall(function()

            if not maLib then return end

            if fMA == nil or index == begin_index then
                begin_index = index
                fMA             = maLib.new({method = 'THV', period = Fsettings.period, koef = Fsettings.koef, data_type = Fsettings.data_type}, ds)
                ma              = fMA(index)
                delta           = {}
                delta[index]    = 0
                fDSD            = maLib.new({method = "SD", not_shifted = true, data_type = 'Any', period = Fsettings.period}, delta)
                fDSD(index)
                trend           = {}
                return
            end

            out[1]          = fMA(index)[index]
            trend[index]    = trend[index-1] or 0
            local t_delta   = ma[index] - (ma[index-trend_shift] or ma[index])
            delta[index]    = math.abs(t_delta) or delta[index-1]
            d_sd            = fDSD(index)[index-1] or 0
            if delta[index] > trend_sd*d_sd then
                if t_delta > 0 and trend[index] <= 0 then
                    trend[index] = 1
                end
                if t_delta < 0 and trend[index] >= 0 then
                    trend[index] = -1
                end
            end
            if color then
				out[2] = trend[index-1] == 1 and out[1] or nil
				out[3] = trend[index-1] == -1 and out[1] or nil
                out[1] = nil
            end
			if trend[index-1] ~= trend[index-2] and not color then
				out[2] = trend[index-1] == 1 and _G.O(index) or nil
				out[3] = trend[index-1] == -1 and _G.O(index) or nil
			end
        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
            return nil
        end
        return unpack(out, 1, lines)
    end
end

function _G.Init()
    PlotLines = Algo(_G.Settings)
    return lines
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end