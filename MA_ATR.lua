--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua
]]

_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\MA.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local line_color    = RGB(250, 0, 0)
local os_time	    = os.time

_G.Settings= {
    Name 		= "*MA_ATR",
    ma_period   = 20,
    atr_period  = 20,
    ma_method   = 'EMA', --'SMA', 'EMA', 'VMA', 'SMMA', 'WMA' и др.
    data_type   = 'Typical', --'Open', 'High', 'Low', 'Close', 'Typical', 'Median', 'Weighted'
    koeff       = 2,
    line = {
        {
            Name  = '*MA',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = '*MA + ATR',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = '*MA - ATR',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 1
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

local function Algo(settings, ds)

    settings           = (settings or {})
    local ma_period    = settings.ma_period or 9
    local atr_period   = settings.atr_period or 9
    local koeff        = settings.koeff or 2

    error_log = {}

    local fMA, err
    local fATR
    local out_ma, out_up, out_dw, atr
    local begin_index

    return function (index)

        local status, res = pcall(function()

            out_ma = nil

            if not maLib then return end

            if fMA == nil or index == begin_index then
                begin_index = index
                fMA, err         = maLib.new({method = settings.ma_method or 'EMA', period = ma_period, data_type = settings.data_type or 'Typical'}, ds)
                if not fMA and not error_log[tostring(err)] then
                    error_log[tostring(err)] = true
                    myLog(tostring(err))
                    message(tostring(err))
                end
                fMA(index)
                fATR, err         = maLib.new({method = 'ATR', period = atr_period}, ds)
                if not fMA and not error_log[tostring(err)] then
                    error_log[tostring(err)] = true
                    myLog(tostring(err))
                    message(tostring(err))
                end
                fATR(index)
                return
            end
            if fMA and fATR then
                out_ma  = fMA(index)[index]
                atr     = fATR(index)[index]
                if out_ma and atr then
                    out_up = out_ma + atr*koeff
                    out_dw = out_ma - atr*koeff
                end
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
        return out_ma, out_up, out_dw
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