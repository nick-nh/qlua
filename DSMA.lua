--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    DSMA Deviation-Scaled Moving Average by John F. Ehlers
]]

local maLib = require('maLib')

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\DSMA.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local isDark        = _G.isDarkTheme()
local os_time	    = os.time

_G.Settings= {
    Name 		= "*DSMA",
    period      = 40,
    poles       = 2, --[2, 3]
    data_type   = 'Close',
    line = {
        {
            Name  = 'DSMA',
            Color = isDark and RGB(255, 193, 193) or RGB(113, 0, 0),
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
    local data_type = (Fsettings.data_type or "Close")
    local period    = Fsettings.period or 9
    local poles     = Fsettings.poles or 2

    error_log = {}

    local fSSF
    local out

    local edsma
    local avgZeros
    local zeros

    return function (index)

        out = nil

        local status, res = pcall(function()

            if not maLib then return end

            local val = maLib.Value(index, data_type, ds)

            if fSSF == nil or index == 1 then
                edsma           = {}
                edsma[index]    = 0
                zeros           = {}
                zeros[index]    = 0
                avgZeros        = {}
                avgZeros[index] = 0
                fSSF            = poles == 2 and maLib.Get2PoleSSF({period = period, data_type = 'Any'}, avgZeros) or maLib.Get3PoleSSF({period = period, data_type = 'Any'}, avgZeros)
                fSSF(index)
                return
            end

			zeros[index]    = zeros[index-1]
			avgZeros[index] = avgZeros[index-1]
			edsma[index]    = edsma[index-1]

			if not maLib.CheckIndex(index, ds) then
				return
			end

            zeros[index]    = val - (maLib.Value(maLib.GetIndex(index, 2, ds, data_type), data_type, ds))
            avgZeros[index] = (zeros[index] + zeros[index-1])/2

            --Ehlers Super Smoother Filter
            local ssf = fSSF(index)

            --Rescale filter in terms of Standard Deviations
            local stdev         = maLib.Sigma(ssf, nil, index - period + 1, index)
            local scaledFilter  = stdev ~= 0 and ssf[index]/stdev or 0

            local alpha  = 5*math.abs(scaledFilter)/period

            edsma[index] = alpha*val + (1 - alpha)*(edsma[index - 1] or 0)

            out = edsma[index]
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
