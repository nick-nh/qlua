--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    MESA Adaptive Moving Averages by John F. Ehlers
]]

local maLib = require('maLib')

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\REMA.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local isDark        = _G.isDarkTheme()
local os_time	    = os.time

_G.Settings= {
    Name 		= "*MESA",
    fastLimit   = 0.5,
    slowLimit   = 0.05,
    data_type   = 'Median',
    line = {
        {
            Name  = 'MAMA',
            Color = isDark and RGB(255, 193, 193) or RGB(113, 0, 0),
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'FAMA',
            Color = isDark and RGB(193, 255, 193) or RGB(0, 113, 26),
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

    Fsettings       = (Fsettings or {})
    local data_type = (Fsettings.data_type or "Median")

    error_log = {}

    local fAlpha
    local out1
    local out2

    local mama
    local fama

    return function (index)

        out1 = nil
        out2 = nil

        local status, res = pcall(function()

            if not maLib then return end

            local val = maLib.Value(index, data_type, ds)

            if fAlpha == nil or index == 1 then
                fAlpha      = maLib.EthlerAlpha(Fsettings, ds)
                fAlpha(index)
                mama        = {}
                mama[index] = val
                fama        = {}
                fama[index] = val
                return
            end

            local alpha  = fAlpha(index)
            local alpha2 = alpha/2

            mama[index] = alpha*val + (1 - alpha)*(mama[index - 1] or 0)

            fama[index] = alpha2*mama[index] + (1 - alpha2)*(fama[index - 1] or 0)

            out1 = mama[index]
            out2 = fama[index]
        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
            return nil
        end
        return out1, out2
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
