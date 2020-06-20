--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    Адаптивная скользящая средняя Перри Кауфмана.
    Adaptive Moving Average
]]

_G.load   = _G.loadfile or _G.load

local maLib = require('maLib')

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\AMA.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local line_color    = RGB(250, 0, 0)
local os_time	    = os.time

_G.Settings= {
    Name 		= "*Adaptive Moving Average",
    period      = 10,
    fast_period = 2,
    slow_period = 30,
    data_type   = 'Close',
    line = {
        {
            Name  = 'Adaptive Moving Average',
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

local function Algo(Fsettings, ds)

    Fsettings           = (Fsettings or {})
    Fsettings.method    = Fsettings.method or 'AMA'
    local period        = Fsettings.period or 9

    error_log = {}

    local fMA
    local out
    local begin_index

    return function (index)

        out = nil

        local status, res = pcall(function()

            if not maLib then return end

            if fMA == nil or index == 1 then
                begin_index     = index
                fMA             = maLib.new(Fsettings, ds)
                fMA(index)
                return out
            end

            out = fMA(index)[(index - begin_index + 1) >= period and index or -1]

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
            return nil
        end
        return out
    end
end

function _G.Init()
    PlotLines = Algo(_G.Settings)
    return 1
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end
