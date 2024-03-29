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
    Name 		= "*MA",
    period      = 9,
    data_type   = 'Close',
    method      = 'SMMA',
    zero_lag    = 0,
    line = {
        {
            Name  = '*MA',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 2
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

    Fsettings           = (Fsettings or {})
    Fsettings.method    = Fsettings.method or 'EMA'
    local period        = Fsettings.period or 9

    error_log = {}

    local fMA, err
    local out
    local begin_index

    return function (index)

        local status, res = pcall(function()

            out = nil

            if not maLib then return end

            if fMA == nil or index == 1 then
                begin_index = index
                fMA, err         = maLib.new(Fsettings, ds)
                if not fMA and not error_log[tostring(err)] then
                    error_log[tostring(err)] = true
                    myLog(tostring(err))
                    message(tostring(err))
                end
                fMA(index)
                return
            end
            if fMA then
                out = fMA(index)[(index - begin_index + 1) >= period and index or -1]
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