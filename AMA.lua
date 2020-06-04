--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    Адаптивная скользящая средняя Перри Кауфмана.
    Adaptive Moving Average
]]

_G.load   = _G.loadfile or _G.load

local maLib = load(_G.getWorkingFolder().."\\LuaIndicators\\maLib.lua")()

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

local function myLog(text)
	if logFile==nil then return end
    logFile:write(tostring(os.date("%c",os_time())).." "..text.."\n");
    logFile:flush();
end

local function Algo(ds)

    local fMA
    local out

    return function (index, Fsettings)

        Fsettings           = (Fsettings or {})
        Fsettings.method    = 'AMA'

        local status, res = pcall(function()

            if not maLib then return end

            if fMA == nil or index == 1 then
                fMA        = maLib.new(Fsettings, ds)
                fMA(index)
                return out
            end

            out = fMA(index)[index]

            return out
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
    PlotLines = Algo()
    return 1
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index, _G.Settings)
end
