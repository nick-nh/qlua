--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	Volatility Cycle
]]
_G.unpack = rawget(table, "unpack") or _G.unpack

_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\VolatlityCycle.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local isDark        = _G.isDarkTheme()
local zero_color    = isDark and RGB(123, 123, 123) or RGB(70, 70, 70)
local line_color    = isDark and RGB(255, 193, 193) or RGB(20, 128, 255)

_G.Settings= {
    Name 		= "*Volatility Cycle",
    data_type   = 'Close',
    str_period  = 20,     -- Период расчета
    atr_period  = 20,     -- Период расчета
    low         = 0.75,   -- Уровень сжатия волатильности
    high        = 3,      -- Уровень сильной волатильности
    line = {
        {
            Name  = 'low',
            Color = zero_color,
            Type  = _G['TYPE_LINE'],
            Width = 1
        },
        {
            Name  = 'high',
            Color = zero_color,
            Type  = _G['TYPE_LINE'],
            Width = 1
        },
        {
            Name  = 'vol',
            Color = line_color,
            Type  = _G['TYPE_LINE'],
            Width = 2
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
    logFile:write(log_tostring(...).."\n");
    logFile:flush();
end

local function Algo(Fsettings, ds)

    Fsettings        = (Fsettings or {})
    local data_type  = (Fsettings.data_type or "Close")
    local std_period = (Fsettings.std_period or 20)
    local atr_period = (Fsettings.atr_period or 20)
    local round      = (Fsettings.round or "off")
    local scale      = (Fsettings.scale or 0)

    local high       = Fsettings.high or 3
    local low        = Fsettings.low or 0.75

    error_log = {}

    local fSTD, sd
    local fATR, atr
    local out

    local begin_index

    return function (index)

        local status, res = pcall(function()

            out  = nil

            if fSTD == nil or index == begin_index then
                begin_index     = index
                fSTD            = maLib.new({method = 'SD', period = std_period, ma_method = 'SMA', not_shifted = true, data_type = data_type, round = round, scale = scale}, ds)
                fSTD(index)
                fATR            = maLib.new({method = 'ATR', period = atr_period, round = round, scale = scale}, ds)
                return
            end

            sd     = fSTD(index)[index]
            atr    = fATR(index)[index]

            if atr and sd then
                out = sd/atr
                -- myLog(index, os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), 'sd', sd, 'atr', atr, 'out', out)
            end

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
        end
        return high, low, out
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