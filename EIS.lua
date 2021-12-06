--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    --Elder Impulse System
]]

_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\EIS.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_POINT    = _G['TYPE_POINT']
local isDark        = _G.isDarkTheme()
local os_time	    = os.time

_G.Settings= {
    Name 		        = "*EIS",
    ema_period          = 13,           -- Период расчета ema
    ema_data_type       = 'Close',
    short_period        = 12,           -- Период расчета короткой ma MACD
    long_period         = 26,           -- Период расчета длинной ma MACD
    macd_method         = 'SMA',        -- Метод расчета ma MACD
    signal_period       = 9,            -- Период расчета сигнальной линии MACD
    signal_method       = 'SMA',        -- Метод расчета сигнальной линии MACD
    macd_data_type      = 'Close',
    line = {
        {
            Name  = 'SELL',
            Color = isDark and RGB(255, 193, 193) or RGB(193, 0, 0),
            Type  = TYPE_POINT,
            Width = 3
        },
        {
            Name  = 'BUY',
            Color = isDark and RGB(193, 255, 193) or RGB(0, 193, 0),
            Type  = TYPE_POINT,
            Width = 3
        },
        {
            Name  = 'OUT',
            Color = isDark and RGB(193, 193, 255) or RGB(0, 0, 193),
            Type  = TYPE_POINT,
            Width = 3
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

------------------------------------------------------------------
    --Moving Average
------------------------------------------------------------------

local function Algo(Fsettings, ds)

    Fsettings               = (Fsettings or {})

    local ema_period        = Fsettings.ema_period or 13
    local ema_data_type     = Fsettings.ema_data_type or 'Close'

    local short_period      = Fsettings.short_period or 12
    local long_period       = Fsettings.long_period or 26
    local macd_method       = (Fsettings.macd_method or "SMA")
    local signal_period     = (Fsettings.signal_period or 9)
    local signal_method     = (Fsettings.signal_method or "SMA")
    local macd_data_type    = Fsettings.macd_data_type or 'Close'

    error_log = {}

    local fMACD, fEMA
    local out1, out2, out3

    return function (index)

        out1 = nil
        out2 = nil
        out3 = nil

        local status, res = pcall(function()

            if not maLib then return end

            if fMACD == nil or index == 1 then
                fEMA            = maLib.new({method = 'EMA', period = ema_period, data_type = ema_data_type}, ds)
                fEMA(index)
                fMACD           = maLib.new({method = 'MACD', short_period = short_period, long_period = long_period, ma_method = macd_method, signal_period = signal_period, signal_method = signal_method, data_type = macd_data_type, percent = 'OFF'}, ds)
                fMACD(index)
                return
            end

            local macd, s_macd  = fMACD(index)

            local ema       = fEMA(index)
            local hist      = macd[index] - s_macd[index]
            local hist_1    = macd[index-1] - s_macd[index-1]

            if not ema[index-1] or not s_macd[index-1] or not macd[index-1] then return end

            out1 = ((ema[index] < ema[index-1]) and (hist < hist_1)) and ema[index]
            out2 = ((ema[index] > ema[index-1]) and (hist > hist_1)) and ema[index]
            out3 = (not out1 and not out2) and ema[index]

            if not maLib.CheckIndex(index, ds) then
				return
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
        return out1, out2, out3
    end
end

function _G.Init()
    PlotLines = Algo(_G.Settings)
    return 3
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end