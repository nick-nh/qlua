--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	EMA on Adaptive Renko Bars.
]]
_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\emaRenkoATR.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local SetValue      = _G['SetValue']
local isDark        = _G.isDarkTheme()
local line_color    = isDark and RGB(240, 240, 240) or RGB(0, 0, 0)

_G.Settings= {
    Name 		        = "*emaRenkoATR",
    ema_period          = 14,                   -- Период расчета ema
    smoothLines         = 0,
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
            Name  = 'emaRenko',
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
    local period        = Fsettings.ema_period or 5
    local smoothLines   = Fsettings.smoothLines or 0

    error_log = {}

    local out
    local l_index

    local fMA
    local ma_data = {}

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
    settings.get_bars          = true
    local brickType            = (Fsettings.brickType or 'Std')
	for val in string.gmatch(brickType or '*ATR', "([^;]+)") do
        if (val:find('*')) then
            settings.brickType = val:gsub('*', ''):gsub("^%s*(.-)%s*$", "%1")
            break
        end
    end

    return function (index)

        local status, res = pcall(function()

            out = nil

            if fRenko == nil or index == 1 then
                local ds_info 	 = _G.getDataSourceInfo()
                settings.scale   = (tonumber(_G.getParamEx(ds_info.class_code, ds_info.sec_code,"SEC_SCALE").param_value) or 0)
                fRenko, rbars    = maLib.new(settings, ds)
                fRenko(index)
                c_rbars          = 1
                l_index          = index
                fMA              = maLib.new({period = period, method = 'EMA'}, rbars)
                ma_data[c_rbars] = fMA(index)[c_rbars]
                return
            end

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
                        ma_data[c_rbars] = fMA(c_rbars)[c_rbars]
                    end
                    c_rbars = #rbars
                    ma_data[c_rbars] = fMA(c_rbars)[c_rbars]

                    if smoothLines == 1 then
                        local last_rbar         = c_rbars-new_bars
                        local delta_range 		= (ma_data[c_rbars] - ma_data[last_rbar])
                        local bars 				= calc_bar - rbars[last_rbar].index
                        local sum = 0
                        -- myLog(' ------ ', index, 'c_rbars', c_rbars, 'ma_data', ma_data[c_rbars], 'ma_data-1', ma_data[last_rbar], 'delta_range', delta_range, 'bars', bars)
                        for ind = 1, bars-1, 1 do
                            sum = sum + (delta_range-sum)/(bars-ind+1)
                            SetValue(calc_bar - bars + ind, 1, ma_data[last_rbar]+sum)
                        end
                    end
                end

                if index == ds_size and smoothLines == 1 and c_rbars > 1 then
                    local last_rbar         = c_rbars-(new_bars == 0 and 1 or new_bars)
                    local delta_range 		= (ma_data[c_rbars] - ma_data[last_rbar])
                    local bars 				= calc_bar - rbars[last_rbar].index
                    local sum = 0
                    for ind = 1, bars-1, 1 do
                        sum = sum + (delta_range-sum)/(bars-ind+1)
                        SetValue(calc_bar - bars + ind, 1, ma_data[last_rbar]+sum)
                    end
                end
            end

            out = ma_data[c_rbars]

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
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
