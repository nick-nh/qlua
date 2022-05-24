--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	Разница Тройное экспоненциальное сглаженное скользящее среднее и EMA.
]]
_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\TEMABOL.txt", "w")

local message               = _G['message']
local RGB                   = _G['RGB']
local TYPE_HISTOGRAM        = _G['TYPE_HISTOGRAM']
local TYPE_DASH             = _G['TYPE_DASH']
local isDark                = _G.isDarkTheme()
local line_color            = isDark and RGB(240, 240, 240) or RGB(0, 0, 0)
local os_time	            = os.time

_G.Settings= {
    Name 		= "*TMACD",
    t_period    = 112,
    e_period    = 56,
    k_extr      = 3.0,
    data_type   = 'Close',
    line = {
        {
            Name  = 'UP',
            Color = RGB(20, 250, 20),
            Type  = TYPE_HISTOGRAM,
            Width = 2
        },
        {
            Name  = 'DW',
            Color = RGB(250, 20, 20),
            Type  = TYPE_HISTOGRAM,
            Width = 2
        },
        {
            Name  = 'SD_UP',
            Color = line_color,
            Type  = TYPE_DASH,
            Width = 1
        },
        {
            Name  = 'SD_DW',
            Color = line_color,
            Type  = TYPE_DASH,
            Width = 1
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

    Fsettings       = (Fsettings or {})
    local t_period  = Fsettings.t_period or 128
    local e_period  = Fsettings.e_period or 64
    local k_extr    = Fsettings.k_extr or 3
    local data_type = Fsettings.data_type or 'Close'
    local round     = (Fsettings.round or "OFF")
    local scale     = (Fsettings.scale or 0)

    local m_period  = math.max(t_period, e_period)
    error_log = {}

    local fMA, fTMA, fDSD
    local out1, out2, out3, out4
    local data, dma, delta
    local d_sd

    return function (index)


        local status, res = pcall(function()

            if not maLib then return end

            if fMA == nil or index == 1 then
                data            = {}
                delta           = {}
                dma             = {}
                fTMA            = maLib.new({method = 'TEMA', period = t_period, data_type = data_type, round = round, scale = scale}, ds)
                fMA             = maLib.new({method = 'EMA', period = e_period, data_type = data_type, round = round, scale = scale}, ds)
                delta[index]    = 0
                fDSD            = maLib.new({method = "SD", not_shifted = true, data_type = 'Any', period = m_period, round = round, scale = scale}, delta)
                fDSD(index, data)
                dma[index]      = 0
                return
            end

            delta[index]    = delta[index-1]
            dma[index]      = dma[index-1]

			if not maLib.CheckIndex(index, ds) then
				return
			end

            dma[index]   = (fTMA(index)[index] or 0) - (fMA(index)[index] or 0)
            delta[index] = math.abs(dma[index])
            d_sd  = fDSD(index)[index]

            out1 = dma[index] > dma[index-1] and dma[index] or nil
            out2 = dma[index] <= dma[index-1] and dma[index] or nil
            out3 = k_extr*d_sd
            out4 = -k_extr*d_sd
        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
            return nil
        end
        return out1, out2, out3, out4
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