--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    In his June 2020 TASC article "Correlation as a cycle indicator" John Ehlers describes one possible way to determine trend in the markets
    His article describes 3 possible ways of determining the trend and here we shall post all the 3 possible ways

    Correlation Cycle, CorrelationAngle, Market State - John Ehlers
]]

_G.unpack = rawget(table, "unpack") or _G.unpack
_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\corrCycle.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local isDark        = _G.isDarkTheme()
local line_color    = isDark and RGB(240, 240, 240) or RGB(0, 0, 0)
local line_colorC   = RGB(89,213, 107)
local line_colorS   = RGB(100, 100, 240)
local os_time	    = os.time
local math_cos	    = math.cos
local math_sin	    = math.sin
local math_deg	    = math.deg
local math_atan	    = math.atan
local math_abs	    = math.abs
local math_pi	    = math.pi

_G.Settings= {
    Name 		= "*Correlation angle",
    ['Период'] 			        = 20,
    ['Показывать цикл']	        = 0,
    ['Угол сброса состояния']	= 9,
    ['Тип данных']              = 'Close',
    line = {
        {
            Name  = '*Corr Cos/State',
            Color = line_colorC,
            Type  = _G['TYPE_HISTOGRAM'],
            Width = 2
        },
        {
            Name  = '*Corr Sin/State',
            Color = line_colorS,
            Type  = _G['TYPE_HISTOGRAM'],
            Width = 2
        },
        {
            Name  = '*Correlation Angle/Phasor',
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
    logFile:write(tostring(os.date("%c",os_time())).." "..log_tostring(...).."\n");
    logFile:flush();
end
------------------------------------------------------------------
    --Moving Average
------------------------------------------------------------------

local function Algo(Fsettings, ds)

    Fsettings           = (Fsettings or {})

    local period        = Fsettings['Период'] or 20
    local angle_trash   = Fsettings['Угол сброса состояния'] or 9
    local data_type     = Fsettings['Тип данных'] or 'Close'
    local show_cycle    = (Fsettings['Показывать цикл'] or 0) == 1

    error_log = {}

    local out = {}
    local begin_index

    local input
    local inputC
    local inputS
    local angle

    local calc_index

    --//Compute the angle as an arctangent function and resolve ambiguity
    local function cap(index, real_part, imaginary_part) -- => // Correlation Angle Phasor Function
        angle[index] = imaginary_part == 0 and 0 or (math_deg(math_atan(real_part/imaginary_part)) + 90)
        if imaginary_part > 0 then
            angle[index] = angle[index] - 180
        end
        --//Do not allow the rate change of angle to go negative
        local prior_angle = angle[index-1] or 0
        if prior_angle>angle[index] and prior_angle-angle[index]<270.0 then
            angle[index] = prior_angle
        end
    end

    return function(index)

        local status, res = pcall(function()

            if not maLib then return end

            if not input or index == begin_index then
                begin_index     = index
                angle           = {}
                angle[index]    = 0
                input           = {}
                inputC          = {}
                inputS          = {}
                input[index]    = maLib.Value(index, data_type, ds)
                inputC[index]   = math_cos(index*2*math_pi/period)
                inputS[index]   = -math_sin(index*2*math_pi/period)
                calc_index      = index

                return
            end

            input[index]    = maLib.Value(index, data_type, ds) or input[index-1]
            inputC[index]   = math_cos(index*2*math_pi/period)
            inputS[index]   = -math_sin(index*2*math_pi/period)

            if not maLib.CheckIndex(index, ds) then
                angle[index]    = angle[index-1] or 0
                return
            end
            if calc_index == index then return end

            out = {}

            if index - begin_index < period then return end

            --//Correlate Price with Cosine wave having a fixed period
            local rp = maLib.Correlation(input, inputC, index-period, index-1)
            --//Correlate with a Negative Sine wave having a fixed period
            local ip = maLib.Correlation(input, inputS, index-period, index-1)
            if show_cycle then
                out[1] = rp
                out[2] = ip
            else
                cap(index, rp, ip)
                out[3] = angle[index]
                local trash = math_abs(angle[index] - angle[index-1]) < angle_trash
                if trash and angle[index] >= 0 then out[1] = 150 end
                if trash and angle[index] < 0 then out[2] = -150 end
            end
            calc_index              = index
            input[index-period-1]   = nil
            inputC[index-period-1]  = nil
            inputS[index-period-1]  = nil
            angle[index-2]          = nil

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
            return nil
        end
        return unpack(out, 1, lines)
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