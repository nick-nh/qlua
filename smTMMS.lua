--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    smTMMS Oscillator (Trading Made More Simpler)
]]

_G.unpack = rawget(table, "unpack") or _G.unpack
_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\smTMMS.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local isDark        = _G.isDarkTheme()
local line_color    = isDark and RGB(240, 240, 240) or RGB(0, 0, 0)
local os_time	    = os.time


_G.Settings= {
    Name 		= "*smTMMS Oscillator",
    ['Период RSI'] 			    = 14,
    ['Период K Stochastic(1)']  = 8,
    ['Период D Stochastic(1)']  = 3,
    ['Метод MA Stochastic(1)']  = 'EMA',
    ['Период K Stochastic(2)']  = 14,
    ['Период D Stochastic(2)']  = 3,
    ['Метод MA Stochastic(2)']  = 'EMA',

    ['Период Q SMI']            = 9,
    ['Период R SMI']            = 9,
    ['Период S SMI']            = 9,
    ['Метод MA SMI']            = 'EMA',

    ['Показывать гистограмму']  = 'STOCH1; *STOCH2',
    ['Показывать линию Hull']   = 0,
    ['Период Hull']		        = 12,
    ['Делитель Hull']		    = 2,

    ['Тип данных']              = 'Close',
    line = {
        {
            Name  = 'UP',
            Color = RGB(0, 180, 0),
            Type  = _G['TYPE_HISTOGRAM'],
            Width = 2
        },
        {
            Name  = 'DW',
            Color = RGB(180, 0, 0),
            Type  = _G['TYPE_HISTOGRAM'],
            Width = 2
        },
        {
            Name  = 'NO',
            Color = RGB(128, 128, 128),
            Type  = _G['TYPE_HISTOGRAM'],
            Width = 2
        },
        {
            Name  = 'SMI',
            Color = line_color,
            Type  = _G['TYPE_LINE'],
            Width = 1
        },
        {
            Name  = 'Hull UP',
            Color = RGB(0, 128, 255),
            Type  = _G['TYPE_POINT'],
            Width = 3
        },
        {
            Name  = 'Hull DW',
            Color = RGB(255, 128, 0),
            Type  = _G['TYPE_POINT'],
            Width = 3
        },
        {
            Name = "change dir up",
            Type = _G['TYPE_TRIANGLE_UP'],
            Width = 3,
            Color = RGB(89,213, 107)
        },
        {
            Name = "change dir dw",
            Type = _G['TYPE_TRIANGLE_DOWN'],
            Width = 3,
            Color = RGB(255, 58, 0)
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

    local period_rsi    = Fsettings['Период RSI'] or 14
    local period_k1     = Fsettings['Период K Stochastic(1)'] or 8
    local period_d1     = Fsettings['Период D Stochastic(1)'] or 3
    local st_ma_method1 = Fsettings['Метод MA Stochastic(1)'] or 'SMA'
    local period_k2     = Fsettings['Период K Stochastic(2)'] or 14
    local period_d2     = Fsettings['Период D Stochastic(2)'] or 3
    local st_ma_method2 = Fsettings['Метод MA Stochastic(2)'] or 'SMA'

    local period_q_smi  = Fsettings['Период Q SMI'] or 10
    local period_r_smi  = Fsettings['Период R SMI'] or 3
    local period_s_smi  = Fsettings['Период S SMI'] or 3
    local smi_ma_method = Fsettings['Метод MA SMI'] or 'EMA'

    local show_hull     = Fsettings['Показывать линию Hull'] == 1
    local period_hull   = Fsettings['Период Hull']
    local divisor_hull  = Fsettings['Делитель Hull']

    local data_type     = Fsettings['Тип данных'] or 'Close'

    local show_hist     = Fsettings['Показывать гистограмму'] or 'STOCH2'
    for val in string.gmatch(Fsettings['Показывать гистограмму'] or 'STOCH2', "([^;]+)") do
        if (val:find('*')) then
            show_hist = val:gsub('*', ''):gsub("^%s*(.-)%s*$", "%1")
            break
        end
    end

    myLog(' show_hist', show_hist, Fsettings['Показывать гистограмму'])

    error_log = {}

    local out = {}
    local begin_index

    local fSTOCH1, fSTOCH2, fRSI, fSMI, fHULL
    local hist
    local smi, hull

    local threshold = 50
    local limit     = 0
    local trend

    return function(index)

        local status, res = pcall(function()

            out = {}
            if not maLib then return end
            if not fSTOCH1 or index == begin_index then
                begin_index     = index
                hist            = {}
                fRSI            = maLib.new({method = 'RSI', period = period_rsi, data_type = data_type}, ds)
                hist['RSI']     = fRSI(index)
                fSTOCH1         = maLib.new({method = 'STOCH', period = period_k1, shift = period_d1, ma_method = st_ma_method1, data_type = data_type}, ds)
                hist['STOCH1']  = fSTOCH1(index)
                fSTOCH2         = maLib.new({method = 'STOCH', period = period_k2, shift = period_d2, ma_method = st_ma_method2, data_type = data_type}, ds)
                hist['STOCH2']  = fSTOCH2(index)
                fSMI            = maLib.new({method = 'SMI', period_q = period_q_smi, period_r = period_r_smi, period_s = period_s_smi, ma_method = smi_ma_method, divisor = 1, data_type = data_type}, ds)
                smi             = fSMI(index)
                if show_hull then
                    fHULL       = maLib.new({method = 'HMA', period = period_hull, divisor = divisor_hull, data_type = data_type}, ds)
                    hull        = fHULL(index)
                end
                trend           = {}
                trend[index]    = 0
                return
            end

            trend[index] = trend[index-1]

            if not maLib.CheckIndex(index, ds) then return end

            hist['RSI'][index]      = fRSI(index)[index] - threshold
            hist['STOCH1'][index]   = fSTOCH1(index)[index] - threshold
            hist['STOCH2'][index]   = fSTOCH2(index)[index] - threshold

            if (hist['RSI'][index]>limit and hist['STOCH1'][index]>limit and hist['STOCH2'][index]>limit) then
                out[1] = hist[show_hist][index]
            else
                if (hist['RSI'][index]<limit and hist['STOCH1'][index]<limit and hist['STOCH2'][index]<limit) then
                    out[2] = hist[show_hist][index]
                else
                    out[3] = hist[show_hist][index]
                end
            end
            out[4] = fSMI(index)[index]
            if show_hull then
                fHULL(index)
                if hull[index] < hull[index-1] then
                    out[6] = 0
                else
                    out[5] = 0
                end
            end

            if trend[index] <= 0 and hist[show_hist][index] > smi[index-1] then
                out[7]          = smi[index]
                trend[index]    = 1
            end
            if trend[index] >= 0 and hist[show_hist][index] < smi[index-1] then
                out[8]          = smi[index]
                trend[index]    = -1
            end

            -- myLog(tostring(index)..' '..os.date('%Y.%m.%d %H:%M', os.time(_G.T(index)))..' out', unpack(out, 1, lines))

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