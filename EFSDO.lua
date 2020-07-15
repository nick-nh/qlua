--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    EFDSO Ehlers Fisherized Deviation-Scaled Oscillator
]]

_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\EFDSO.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local isDark        = _G.isDarkTheme()
local os_time	    = os.time
local zero_color    = isDark and RGB(123, 123, 123) or RGB(70, 70, 70)

_G.Settings= {
    Name 		= "*EFDSO",
    period      = 20,
    poles       = 2, --[2, 3]
    data_type   = 'Close',
    obLevel     = 2.0,  -- уровень перекупленности
    osLevel     = -2.0, -- уровень перпроданности
    line = {
        {
            Name  = 'zero',
            Color = zero_color,
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'OB',
            Color = isDark and RGB(123, 255, 123) or RGB(70, 193, 70),
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'OS',
            Color = isDark and RGB(255, 150, 150) or RGB(193, 70, 70),
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'EFDSO',
            Color = isDark and RGB(255, 193, 193) or RGB(23, 23, 23),
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
    local obLevel   = Fsettings.obLevel or 2
    local osLevel   = Fsettings.osLevel or -2

    error_log = {}

    local fSSF
    local out

    local efsdo
    local avgZeros
    local zeros
    local scaledFilter

    return function (index)

        out = nil

        local status, res = pcall(function()

            if not maLib then return end

            local val = maLib.Value(index, data_type, ds)

            if fSSF == nil or index == 1 then
                efsdo           = {}
                efsdo[index]    = 0
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
			efsdo[index]    = efsdo[index-1]

			if not maLib.CheckIndex(index, ds) then
				return
			end

            zeros[index]    = val - (maLib.Value(maLib.GetIndex(index, 2, ds, data_type), data_type, ds))
            avgZeros[index] = (zeros[index] + zeros[index-1])/2

            --Ehlers Super Smoother Filter
            local ssf = fSSF(index)

            --Rescale filter in terms of Standard Deviations
            local stdev     = maLib.Sigma(ssf, nil, index - period + 1, index)
            scaledFilter    = stdev ~= 0 and ssf[index]/stdev or scaledFilter

            --Apply Fisher Transform to establish real Gaussian Probability Distribution
            efsdo[index]    = math.abs(scaledFilter) < 2 and 0.5*math.log((1 + scaledFilter/2)/(1 - scaledFilter/2)) or efsdo[index]

            out = efsdo[index]
        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
            return nil
        end
        return 0, obLevel, osLevel, out
    end
end

function _G.Init()
    PlotLines = Algo(_G.Settings)
    return 4
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end
