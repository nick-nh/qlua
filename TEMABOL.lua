--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	Тройное экспоненциальное сглаженное скользящее среднее + EMA + Bollinger Bands.
]]
_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\TEMABOL.txt", "w")

local message               = _G['message']
local RGB                   = _G['RGB']
local TYPE_LINE             = _G['TYPE_LINE']
local TYPE_POINT            = _G['TYPE_POINT']
local TYPE_TRIANGLE_UP      = _G['TYPE_TRIANGLE_UP']
local TYPE_TRIANGLE_DOWN    = _G['TYPE_TRIANGLE_DOWN']
local isDark                = _G.isDarkTheme()
local line_color            = isDark and RGB(240, 240, 240) or RGB(0, 0, 0)
local os_time	            = os.time

_G.Settings= {
    Name 		= "*TEMABOL",
    t_period    = 112,
    e_period    = 56,
    b_period    = 56,
    b_std       = 2.8,
    k_extr      = 3.0,
    data_type   = 'Close',
    line = {
        {
            Name  = 'TEMA',
            Color = RGB(250, 0, 0),
            Type  = TYPE_LINE,
            Width = 2
        },
        {
            Name  = 'EMA',
            Color = RGB(0, 0, 250),
            Type  = TYPE_LINE,
            Width = 2
        },
        {
            Name  = 'b_mid',
            Color = line_color,
            Type  = TYPE_POINT,
            Width = 1
        },
        {
            Name  = 'b_up',
            Color = line_color,
            Type  = TYPE_POINT,
            Width = 1
        },
        {
            Name  = 'b_dw',
            Color = line_color,
            Type  = TYPE_POINT,
            Width = 1
        },
        {
            Name  = 'dextr',
            Color = line_color,
            Type  = TYPE_POINT,
            Width = 3
        },
        {
            Name = "change dir up",
            Type = TYPE_TRIANGLE_UP,
            Width = 3,
            Color = RGB(89,213, 107)
        },
        {
            Name = "change dir dw",
            Type = TYPE_TRIANGLE_DOWN,
            Width = 3,
            Color = RGB(255, 58, 0)
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
    local t_period  = Fsettings.t_period or 128
    local e_period  = Fsettings.e_period or 64
    local b_period  = Fsettings.b_period or 64
    local b_std     = Fsettings.b_std or 2
    local k_extr    = Fsettings.k_extr or 2
    local data_type = Fsettings.data_type or 'Close'
    local round     = (Fsettings.round or "OFF")
    local scale     = (Fsettings.scale or 0)

    -- local m_period  = math.max(t_period, e_period, b_period)
    error_log = {}

    local fMA, fTMA, fSD, fDSD
    local out1, out2, out3, out4, out5, out6, out7, out8
    -- local begin_index
    local data, delta
    local sd, d_sd, trend

    return function (index)


        local status, res = pcall(function()

            if not maLib then return end

            out6, out7, out8 = nil, nil, nil
            if fMA == nil or index == 1 then
                data            = {}
                delta           = {}
                -- begin_index     = index
                fTMA            = maLib.new({method = 'TEMA', period = t_period, data_type = data_type, round = round, scale = scale}, ds)
                fMA             = maLib.new({method = 'EMA', period = e_period, data_type = data_type, round = round, scale = scale}, ds)
                data[index]     = ((fTMA(index)[index] or 0) + (fMA(index)[index] or 0))/2
                fSD             = maLib.new({method = "SD", calc_avg = false, not_shifted = true, data_type = data_type, period = b_period, round = round, scale = scale}, ds)
                fSD(index, data)
                delta[index]    = 0
                fDSD            = maLib.new({method = "SD", not_shifted = true, data_type = 'Any', period = b_period, round = round, scale = scale}, delta)
                fDSD(index, data)
                trend = 0
                return
            end

            data[index]     = data[index-1]
            delta[index]    = delta[index-1]
            out1            = fTMA(index)[index]
            out2            = fMA(index)[index]

			if not maLib.CheckIndex(index, ds) then
				return
			end

            data[index]   = ((out1 or 0) + (out2 or 0))/2

            sd    = fSD(index, data)[index]
            out3  = data[index]
            out4  = data[index] - b_std*sd
            out5  = data[index] + b_std*sd
            delta[index] = math.abs(out1 - out2)
            d_sd  = fDSD(index)[index]

            if delta[index] > d_sd then
                if out2 > out1 and trend >= 0 then
                    out8 = out2
                    trend = -1
                end
                if out2 < out1 and trend <= 0 then
                    out7 = out1
                    trend = 1
                end
            end
            if delta[index] > k_extr*d_sd and delta[index-1] < k_extr*d_sd then
                out6 = out1
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
        return out1, out2, out3, out4, out5, out6, out7, out8
    end
end

function _G.Init()
    PlotLines = Algo(_G.Settings)
    return 8
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end