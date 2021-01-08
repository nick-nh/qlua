--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    MACD on Adaptive Renko Bars.
]]
_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\macdRenkoATR.txt", "w")

local message           = _G['message']
local RGB               = _G['RGB']
local TYPE_HISTOGRAM    = _G['TYPE_HISTOGRAM']
local TYPE_LINE         = _G['TYPE_LINE']
local math_max          = math.max
local isDark            = _G.isDarkTheme()
local line_color        = isDark and RGB(240, 240, 240) or RGB(0, 0, 0)

_G.Settings= {
    Name 		        = "*macdRenkoATR",
    short_period        = 12,                   -- Период расчета короткой ma
    long_period         = 26,                   -- Период расчета длинной ma
    method              = 'EMA',                -- Метод расчета ma
    signal_period       = 9,                    -- Период расчета сигнальной ma
    signal_method       = 'SMA',                -- Метод расчета сигнальной ma
    percent             = 'ON',                 -- Метод расчета ma
    period              = 28,                   -- Период расчета ATR
    k                   = 1.0,                  -- размер скользящего фильтра, используемый при вычислении размера блока от величины ATR как k*ATR
    data_type           = 1,                    -- 0 - Close; 1 - High|Low
    br_size             = 0,                    -- Фиксированный размер шага. Если задан, то строится по указанному размеру (в пунктах)
    recalc_brick        = 0,                    -- Пересчитывать размер блока каждый период-бар
    shift_limit         = 0,                    -- Сдвигать границу по пересчитанному размеру блока
    min_recalc_brick    = 0,                    -- Минимизировать размер блока при пересчете
    --Для установки значения, необходимо поставить * перед выбранным вариантом.
    brickType           = '*ATR; Std; Fix',     -- Тип расчета Renko; ATR; Std - стандартное отклонение; Fix - фиксированный размер, заданный в br_size
    std_ma_method       = 'SMA',
    line = {
        {
			Name	= "Up",
			Color	= RGB(0, 128, 128),
			Type	= TYPE_HISTOGRAM,
			Width	= 2
		},
		{
			Name	= "Down",
			Color	= RGB(255, 128, 0),
			Type	= TYPE_HISTOGRAM,
			Width	= 2
        },
        {
            Name  = 'Signal',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 1
        }
    }
}

local PlotLines     = function() end
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
    logFile:write(log_tostring(...).."\n");
    logFile:flush();
end

--Adaptive Renko ATR based
local function Algo(Fsettings, ds)

    Fsettings           = (Fsettings or {})
    local short_period  = Fsettings.short_period or 12
    local long_period   = Fsettings.long_period or 26
    local method        = (Fsettings.method or "EMA")
    local signal_method = (Fsettings.signal_method or "SMA")
    local signal_period = (Fsettings.signal_period or 9)
    local percent       = (Fsettings.percent or 'ON'):upper()
    local save_bars     = (Fsettings.save_bars or math_max(long_period, short_period, signal_period))

    error_log = {}

    local out1, out2, out3
    local l_index

    local sfMA
    local lfMA
    local fMACD_MA
    local sma_data      = {}
    local lma_data      = {}
    local t_MACD        = {}
    local s_MACD        = {}
    local last_delta    = 1

    local fRenko
    local c_rbars
    local rbars

    local settings             = {}
    settings.method            = 'RENKO'
    settings.br_size           = (Fsettings.br_size or 0)
    settings.period            = (Fsettings.period or 0)
    settings.data_type         = (Fsettings.data_type or 0)
    settings.recalc_brick      = (Fsettings.recalc_brick or 0)
    settings.min_recalc_brick  = (Fsettings.min_recalc_brick or 0)
    settings.shift_limit       = (Fsettings.shift_limit or 0)
    settings.std_ma_method     = (Fsettings.std_ma_method or 'SMA')
    settings.k                 = (Fsettings.k or 1)
    local brickType            = (Fsettings.brickType or 'Std')
	for val in string.gmatch(brickType or '*ATR', "([^;]+)") do
        if (val:find('*')) then
            settings.brickType = val:gsub('*', ''):gsub("^%s*(.-)%s*$", "%1")
            break
        end
    end

    return function (index)

        local status, res = pcall(function()

            out1, out2, out3 = nil, nil, nil

            if fRenko == nil or index == 1 then
                local ds_info 	 = _G.getDataSourceInfo()
                settings.scale   = (tonumber(_G.getParamEx(ds_info.class_code, ds_info.sec_code,"SEC_SCALE").param_value) or 0)
                fRenko           = maLib.new(settings, ds)
                local res        = {fRenko(index)}
                rbars            = res[5]
                c_rbars          = 1
                l_index          = index
                sfMA              = maLib.new({period = short_period, method = method}, rbars)
                sma_data[c_rbars] = sfMA(index)[c_rbars]
                lfMA              = maLib.new({period = long_period, method = method}, rbars)
                lma_data[c_rbars] = lfMA(index)[c_rbars]
                t_MACD[index]     = 0
                s_MACD[index]     = 0
                fMACD_MA          = maLib.new({period = signal_period, method = signal_method,  data_type = "Any"}, t_MACD)
                return
            end

            t_MACD[index]   = t_MACD[index-1] or 0
            s_MACD[index]   = s_MACD[index-1] or 0

            local ds_size   = maLib.dsSize(settings.data_type, ds)
            local calc_bar  = (index == ds_size and index - 1 or index)
            if calc_bar ~= l_index then

                l_index = calc_bar

                fRenko(calc_bar)

                -- myLog(index, os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), '#rbars', #rbars)

                local new_bars = #rbars - c_rbars
                if new_bars > 0 then
                    while c_rbars < #rbars-1 do
                        c_rbars = c_rbars + 1
                        sma_data[c_rbars] = sfMA(c_rbars)[c_rbars]
                        lma_data[c_rbars] = lfMA(c_rbars)[c_rbars]
                    end
                    c_rbars = #rbars
                    sma_data[c_rbars] = sfMA(c_rbars)[c_rbars]
                    lma_data[c_rbars] = lfMA(c_rbars)[c_rbars]
                    -- myLog(index, 'c_rbars', c_rbars, 'sma_data', sma_data[c_rbars], 'lma_data', lma_data[c_rbars])
                end
            end

            if percent == 'OFF' then
                t_MACD[index] = sma_data[c_rbars] - lma_data[c_rbars]
            else
                t_MACD[index] = lma_data[c_rbars] == 0 and 0 or (100*(sma_data[c_rbars] - lma_data[c_rbars])/lma_data[c_rbars])
            end

            out3 = fMACD_MA(index)[index]

            if t_MACD[index] > t_MACD[index-1] or (t_MACD[index] == t_MACD[index-1] and last_delta == 1) then
                out1        = t_MACD[index]
                last_delta  = 1
            else
                out2        = t_MACD[index]
                last_delta  = -1
            end

            t_MACD[index - save_bars] = nil
            s_MACD[index - save_bars] = nil

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
        end
        return out1, out2, out3
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