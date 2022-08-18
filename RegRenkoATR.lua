--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	Regression channel over Adaptive Renko Bars.
]]
_G.unpack = rawget(table, "unpack") or _G.unpack

_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\RegRenkoATR.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local TYPE_POINT    = _G['TYPE_POINT']
local SetValue      = _G['SetValue']
local isDark        = _G.isDarkTheme()
local line_color    = isDark and RGB(240, 240, 240) or RGB(0, 0, 0)

_G.Settings= {
    Name 		        = "*RegRenkoATR",
    reg_period          = 18,                   -- Период расчета REG
    reg_kstd            = 2.0,                 -- Отклонение REG
    reg_kstd2           = 0.0,                  -- Отклонение REG
    reg_kstd3           = 0.0,                  -- Отклонение REG
    reg_degree          = 1,                    -- Степень REG
    trend_delta         = 0.05,                 -- Дельта тренда %
    period              = 18,                   -- Период расчета ATR
    k                   = 2.4,                  -- размер скользящего фильтра, используемый при вычислении размера блока от величины ATR как k*ATR
    data_type           = 0,                    -- 0 - Close; 1 - High|Low
    br_size             = 0,                    -- Фиксированный размер шага. Если задан, то строится по указанному размеру (в пунктах)
    recalc_brick        = 1,                    -- Пересчитывать размер блока каждый период-бар
    shift_limit         = 0,                    -- Сдвигать границу по пересчитанному размеру блока
    min_recalc_brick    = 0,                    -- Минимизировать размер блока при пересчете
    --Для установки значения, необходимо поставить * перед выбранным вариантом.
    brickType           = '*ATR; Std; Fix',     -- Тип расчета Renko; ATR; Std - стандартное отклонение; Fix - фиксированный размер, заданный в br_size
    std_ma_method       = 'SMA',
    line = {
        {
            Name = "hist up",
            Type = TYPE_POINT,
            Width = 2,
            Color = RGB(89,213, 107)
        },
        {
            Name = "hist dw",
            Type = TYPE_POINT,
            Width = 2,
            Color = RGB(255, 58, 0)
        },
        {
            Name  = 'reg std+',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'reg std-',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'reg std2+',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'reg std2-',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'reg std3+',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'reg std3-',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 1
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
    logFile:write(log_tostring(...).."\n");
    logFile:flush();
end

--Adaptive Renko ATR based
local function Algo(Fsettings, ds)

    Fsettings           = (Fsettings or {})
    local period        = Fsettings.reg_period or 14
    local reg_kstd      = Fsettings.reg_kstd or 2
    local reg_kstd2     = Fsettings.reg_kstd2 or 0
    local reg_kstd3     = Fsettings.reg_kstd3 or 0
    local reg_degree    = Fsettings.reg_degree or 1
	local trend_delta	= Fsettings.trend_delta or 0.1

    error_log = {}

    local out
    local l_index

    local fReg
    local reg_data   = {}
    local std_data_u = {}
    local std_data_d = {}
	local sse		 = {}

    local fRenko
    local c_rbars
    local rbars
	local trend

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

            out = {}

            if fRenko == nil or index == 1 then
                local ds_info 	 = _G.getDataSourceInfo()
                settings.scale   = (tonumber(_G.getParamEx(ds_info.class_code, ds_info.sec_code,"SEC_SCALE").param_value) or 0)
                fRenko, rbars    = maLib.new(settings, ds)
                fRenko(index)
                c_rbars          = 1
                l_index          = index
                fReg             = maLib.new({period = period, method = 'REG', degree = reg_degree, kstd = reg_kstd}, rbars)
                reg_data, std_data_u, std_data_d, sse = fReg(1)
				trend			= {}
				trend[1]	    = 0
                --myLog(index, os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), '#rbars', #rbars, 'reg_data', reg_data)
                return
            end

            trend[index] = trend[index - 1]

            local ds_size   = maLib.dsSize(settings.data_type, ds)
            local calc_bar  = (index == ds_size and index - 1 or index)
            if calc_bar ~= l_index then

                l_index = calc_bar

                fRenko(calc_bar)

                --myLog(index, os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), '#rbars', #rbars, c_rbars, rbars[c_rbars].Close, 'reg_data', reg_data[c_rbars])

                local new_bars = #rbars - c_rbars
                if new_bars > 0 then
                    while c_rbars < #rbars-1 do
                        c_rbars = c_rbars + 1
                        fReg(c_rbars)
						--myLog(' new #rbars', #rbars, c_rbars, rbars[c_rbars].Close, 'reg_data', reg_data[c_rbars], 'sse', sse[c_rbars])
                   end
                    c_rbars = #rbars
                    fReg(c_rbars)
					--myLog(' new #rbars', #rbars, c_rbars, rbars[c_rbars].Close, 'reg_data', reg_data[c_rbars], 'sse', sse[c_rbars])
                end

            end

			trend[index] 	= (reg_data[c_rbars-period+1] and math.abs(reg_data[c_rbars] - reg_data[c_rbars-period+1])*100/reg_data[c_rbars-period+1] >= trend_delta) and ((reg_data[c_rbars] - reg_data[c_rbars-period+1]) > 0 and 1 or -1) or trend[index-1]
			out[1] = trend[index] == 1 and reg_data[c_rbars] or nil
			out[2] = trend[index] == -1 and reg_data[c_rbars] or nil

            out[3]  = std_data_u[c_rbars]
            out[4]  = std_data_d[c_rbars]
			if reg_kstd2 ~= 0 and sse[c_rbars] then
				out[5]  = reg_data[c_rbars] + reg_kstd2*sse[c_rbars]
				out[6]  = reg_data[c_rbars] - reg_kstd2*sse[c_rbars]
			end
			if reg_kstd3 ~= 0 and sse[c_rbars] then
				out[7]  = reg_data[c_rbars] + reg_kstd3*sse[c_rbars]
				out[8]  = reg_data[c_rbars] - reg_kstd3*sse[c_rbars]
			end
            if index == ds_size then
                SetValue(index-1, 1, out[1])
                SetValue(index-1, 2, out[2])
                SetValue(index-1, 3, out[3])
                SetValue(index-1, 4, out[4])
                SetValue(index-1, 5, out[5])
                SetValue(index-1, 6, out[6])
                SetValue(index-1, 7, out[7])
                SetValue(index-1, 8, out[8])
            end

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
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