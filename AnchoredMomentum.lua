--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    Smoothed Anchored Momentum
]]
_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\TEMA.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local isDark        = _G.isDarkTheme()
local zero_color    = isDark and RGB(123, 123, 123) or RGB(70, 70, 70)
local line_color    = RGB(250, 0, 0)
local os_time	    = os.time

_G.Settings= {
    Name 		= "*Smoothed Anchored Momentum",
    data_type   = 'Close',
    period      = 11,       -- Период доп. усреднения SMA
    ema_period  = 6,       -- Период доп. усреднения EMA
    line = {
        {
            Name  = 'zero',
            Color = zero_color,
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'Smoothed Anchored Momentum',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 2
        }
    }
}

local PlotLines     = function() end
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
------------------------------------------------------------------
    --Moving Average
------------------------------------------------------------------

local function Algo(Fsettings, ds)

    Fsettings        = (Fsettings or {})
    local data_type  = (Fsettings.data_type or "Close")
    local period     = (Fsettings.period or 11)
    local ema_period = (Fsettings.ema_period or 6)
    local round      = (Fsettings.round or "off")
    local scale      = (Fsettings.scale or 0)

    error_log = {}

    local fSMA
    local fEMA
    local out
    local begin_index

    return function (index)

        local status, res = pcall(function()

            out = nil

            if not maLib then return end

            if fSMA == nil or index == 1 then
                begin_index    = index
                fSMA           = maLib.new({period = 2*period + 1, method = 'SMA', data_type = data_type, round = round, scale = scale}, ds)
                fSMA(index)
                fEMA           = maLib.new({period = ema_period, method = 'EMA', data_type = data_type, round = round, scale = scale}, ds)
                fEMA(index)
                return
            end

            local sma = fSMA(index)[index]
            local ema = fEMA(index)[index]

            out = (index - begin_index + 1) >= period and (sma == 0 and out or 100*((ema/sma) - 1)) or nil
        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
        end
        return 0, out
    end
end

function _G.Init()
    PlotLines = Algo(_G.Settings)
    return 2
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end
