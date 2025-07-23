--[[
    LSMA - скользящее среднее наименьших квадратов

    nick-h@yandex.ru
	https://github.com/nick-nh/qlua
]]

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\LSMA.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local CandleExist   = _G['CandleExist']
local O             = _G['O']
local C             = _G['C']
local H             = _G['H']
local L             = _G['L']
local line_color    = RGB(0, 128, 255)
local os_time	    = os.time

_G.Settings= {
    Name 		= "*LSMA",
    ['1. Период регрессии']      = 100,
	['2. Вариант данных']	     = 'C', -- C, O, H, L, M, T, W
    line = {
        {
            Name  = 'LSMA',
            Color = line_color,
            Type  = TYPE_LINE,
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

function myLog(...)
	if logFile==nil then return end
    logFile:write(tostring(os.date("%c",os_time())).." "..log_tostring(...).."\n");
    logFile:flush();
end
------------------------------------------------------------------
    --Moving Average
------------------------------------------------------------------

local df = {}
df['C'] = function(i) return C(i) end
df['H'] = function(i) return H(i) end
df['L'] = function(i) return L(i) end
df['O'] = function(i) return O(i) end
df['M'] = function(i) return (H(i) + L(i))/2 end
df['T'] = function(i) return (H(i) + L(i) + O(i))/3 end
df['W'] = function(i) return (H(i) + L(i) + O(i) + C(i))/4 end

local function LIN_REG(data)

    local XSum = 0
    local YSum = 0
    local XYSum = 0
    local XXSum = 0
    local YYSum = 0

    for i, v in ipairs (data) do
        XSum = XSum + (v.x or i)
        XXSum = XXSum + (v.x or i)^2

        YSum = YSum + v.y
        YYSum = YYSum + v.y^2

        XYSum = XYSum + (v.x or i)*v.y
    end

    local div = (#data*XXSum)-(XSum^2)
    return ((YSum*XXSum)-(XSum*XYSum))/div, ((#data*XYSum) - (XSum*YSum))/div
end

local function F_FLREG(settings)

    settings            = (settings or {})
    local period        = settings.period or 100
    local data_type     = (settings.data_type or "C"):upper():sub(1,1)
    local save_bars     = (settings.save_bars or period)
	local last_cal_bar
    local calc_buffer

    local data
    local fx_buffer     = {}
    local begin_index

    local function get_x(index)
        return index
    end
    local function get_y(index)
        return df[data_type](index)
    end

    return function(index)

        if index <= period then return fx_buffer end

        if (not data and index > period) or index == begin_index then
            begin_index = index
            calc_buffer = {}
            local i     = 0
            local j     = period
            data        = {}
            while not data[1] and i < index do
                data[j] = {x = get_x(index-i-1), y = get_y(index-i-1)}
                i = i + 1
                if data[j].y then
                    j = j - 1
                end
            end
            last_cal_bar = index
        end

		if calc_buffer[index] ~= nil then
			return fx_buffer
		end

        if not CandleExist(index) or index < period then
			return fx_buffer
		end
        if last_cal_bar ~= index and data[1] then
            table.remove(data, 1)
            data[period] = {x = get_x(index-1), y = get_y(index-1)}
        end
        last_cal_bar = index

        if data[1] then
            local a, b = LIN_REG(data)
            fx_buffer[index]    = a + b*(data[period].x or period)
        end
        calc_buffer[index]  = true

        fx_buffer[index-save_bars]      = nil

        return fx_buffer

	end, fx_buffer

end

local function Algo(settings)

    settings = (settings or {})

    local r_period  = settings['1. Период регрессии']     or 14
    local data_type = settings['2. Вариант данных']	      or 'C'

    error_log = {}

    local err
    local fMA
    local out
    local begin_index

    return function (index)

        local status, res = pcall(function()

            out = nil

            if fMA == nil or index == begin_index then
                begin_index     = index

                fMA, err  = F_FLREG({period = r_period, data_type = data_type})
                if not fMA and not error_log[tostring(err)] then
                    error_log[tostring(err)] = true
                    myLog(tostring(err))
                    message(tostring(err))
                end
                fMA(index)
                return
            end
            if fMA then
                out = fMA(index)[index]
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
    return lines
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end