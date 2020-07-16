--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	Adaptive Renko ATR based.
]]
_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\RenkoATR.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local isDark        = _G.isDarkTheme()
local up_line_color = isDark and RGB(0, 230, 0) or RGB(0, 210, 0)
local dw_line_color = isDark and RGB(230, 0, 0) or RGB(210, 0, 0)
local line_color    = isDark and RGB(240, 240, 240) or RGB(0, 0, 0)
local os_time	    = os.time

_G.Settings= {
    Name 		        = "*RenkoATR",
    br_size             = 0.0,                  -- Фиксированный размер шага. Если задан, то строится по указанному размеру (в пунктах)
    recalc_brick        = 1,                    -- Пересчитывать размер блока каждый период-бар
    shift_limit         = 1,                    -- Сдвигать границу по пересчитанному размеру блока
    min_recalc_brick    = 0,                    -- Минимизировать размер блока при пересчете
    data_type           = 0,                    -- 0 - Close; 1 - High|Low
    k                   = 3.0,                  -- размер скользящего фильтра, используемый при вычислении размера блока от величины ATR как k*ATR
    period              = 24,                   -- Период расчета ATR
    showRenko           = 1,                    -- Показывать линии Renko; 0 - не показывать; 1 - показывать; 2 - показывать одной линией
    --Для установки значения, необходимо поставить * перед выбранным вариантом.
    brickType       = 'ATR; *Std; Fix',         -- Тип расчета Renko; ATR; Std - стандартное отклонение; Fix - фиксированный размер, заданный в br_size
    std_ma_method   = 'SMA',
    line = {
        {
            Name  = 'Renko UP',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'Renko Down',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'Buy',
            Color = up_line_color,
            Type  = _G.TYPE_TRIANGLE_UP,
            Width = 4
        },
        {
            Name  = 'Sell',
            Color = dw_line_color,
            Type  = _G.TYPE_TRIANGLE_DOWN,
            Width = 4
        }
    }
}

local PlotLines     = function() end
local error_log     = {}

local math_floor    = math.floor

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

local math_pow      = math.pow

local function F_RENKO(settings, ds)

    local fATR
    local fMA
    local Data
    local Renko_UP
    local Renko_DW

    local recalc_index
    local l_index
    local trend
    local begin_index
    local brick_bars    = 0
    local Brick         = {}

    settings                = (settings or {})
    local br_size           = (settings.br_size or 0)
    local period            = (settings.period or 0)
    local data_type         = (settings.data_type or 0)
    local recalc_brick      = (settings.recalc_brick or 0)
    local min_recalc_brick  = (settings.min_recalc_brick or 0)
    local shift_limit       = (settings.shift_limit or 0)
    local std_ma_method     = (settings.std_ma_method or 'SMA')
    local brickType = 'ATR'
	for val in string.gmatch(settings.brickType or '*ATR', "([^;]+)") do
        if (val:find('*')) then
            brickType = val:gsub('*', ''):gsub("^%s*(.-)%s*$", "%1")
            break
        end
    end
    local k                 = (brickType ~='Fix' or br_size == 0) and (settings.k or 1) or 1

    return function(index)

        if not maLib then return Renko_UP, Renko_DW end

        if Renko_UP == nil or index == begin_index then
            begin_index     = index
            Renko_UP        = {}
            Renko_UP[index] = maLib.Value(index, 'High', ds) or 0
            Renko_DW        = {}
            Renko_DW[index] = maLib.Value(index, 'Low', ds) or 0
            if brickType ~='Fix' or br_size == 0 then
                Brick[index]    = k*(Renko_UP[index] - Renko_DW[index])
                if brickType == 'ATR' then
                    fATR            = maLib.new(settings, ds)
                    fATR(index)
                else
                    Data            = {}
                    Data[index]     = maLib.Value(index, 'Close', ds) or 0
                    fMA             = maLib.new({period = period, method = std_ma_method, data_type = 'Any'}, Data)
                    fMA(index)
                end
            else
                local ds_info 	= _G.getDataSourceInfo()
                Brick[index]    = br_size/math_pow(10, (tonumber(_G.getParamEx(ds_info.class_code, ds_info.sec_code,"SEC_SCALE").param_value) or 0))
            end
            l_index         = index
            trend           = {}
            trend[index]    = 0
            return Renko_UP
        end

        if brickType == 'Std' then
            Data[index]     = Data[index-1]
        end
        Brick[index]    = Brick[index-1]
        Renko_UP[index] = Renko_UP[index-1]
        Renko_DW[index] = Renko_DW[index-1]
        trend[index]    = trend[index-1]

        local atr       = brickType == 'ATR' and fATR(index)[index] or Brick[index-1]

        if not maLib.CheckIndex(index) then
            return Renko_UP
        end

        local close = data_type == 0 and maLib.Value(index, 'Close', ds) or (trend[index] == -1  and maLib.Value(index, 'Low', ds) or maLib.Value(index, 'High', ds))

        if brickType == 'Std' then
            Data[index] = close
            atr         = maLib.Sigma(Data, fMA(index)[index] or close, index - period + 1, index)
        end
        if l_index ~= index then
            brick_bars = brick_bars + 1
            if brick_bars > period then
                brick_bars = 1
                recalc_index = index
            end
        end
        if recalc_brick == 1 and recalc_index == index then
            Brick[index] = min_recalc_brick == 1 and math.min(k*atr, Brick[index]) or k*atr
            if shift_limit == 1 then
                if trend[index] == -1 then Renko_UP[index] = math.min(Renko_UP[index-1], Renko_DW[index-1] + Brick[index]) end
                if trend[index] == 1  then Renko_DW[index] = math.max(Renko_DW[index-1], Renko_UP[index-1] - Brick[index]) end
            end
        end
        l_index = index
        -- myLog(index, os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), 'Brick', Brick[index], 'close', close, 'up', Renko_UP[index], close - Renko_UP[index], 'dw', Renko_DW[index], Renko_DW[index] - close)
        if close > Renko_UP[index-1] + Brick[index-1] then
            -- myLog('new brick', os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), 'Brick', k*atr, 'close', close, 'up', Renko_UP[index], 'dw', Renko_DW[index])
            Renko_UP[index] = Renko_UP[index] + (Brick[index-1] == 0  and 0 or math_floor((close - Renko_UP[index-1])/Brick[index-1])*Brick[index-1])
            Brick[index]    = k*atr
            -- Renko_DW[index] = Renko_UP[index] - Brick[index]
            Renko_DW[index] = math.max(Renko_UP[index-1], Renko_UP[index] - Brick[index])
            trend[index]  = 1
            --brick_bars = 1
		end
		if close < Renko_DW[index-1] - Brick[index-1] then
            -- myLog('new brick', os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), 'Brick', k*atr, 'close', close, 'up', Renko_UP[index], 'dw', Renko_DW[index])
            Renko_DW[index] = Renko_DW[index] - (Brick[index-1] == 0  and 0 or math_floor((Renko_DW[index-1] - close)/Brick[index-1])*Brick[index-1])
            Brick[index]    = k*atr
            -- Renko_UP[index] = Renko_DW[index] + Brick[index]
            Renko_UP[index] = math.min(Renko_DW[index-1], Renko_DW[index] + Brick[index])
            trend[index]  = -1
            --brick_bars = 1
        end

        return Renko_UP, Renko_DW, trend
     end
end

--Adaptive Renko ATR based
local function Algo(Fsettings, ds)

    Fsettings           = (Fsettings or {})
    Fsettings.method    = 'ATR'
    local period        = Fsettings.period or 10
    local showRenko     = Fsettings.showRenko or 1

    error_log = {}

    local fRenko
    local out_up
    local out_dw
    local p_buy
    local p_sell
    local begin_index

    return function (index)

        out_up  = nil
        out_dw  = nil
        p_buy   = nil
        p_sell  = nil

        local status, res = pcall(function()

            if fRenko == nil or index == 1 then
                begin_index     = index
                fRenko          = F_RENKO(Fsettings, ds)
                fRenko(index)
                return
            end


            local up, dw, trend = fRenko(index)
            if (index - begin_index + 1) <= period then
                return
            end
            if trend[index-1] < trend[index-2] then
                p_sell        = maLib.Value(index, 'Open', ds)
            elseif trend[index-1] > trend[index-2] then
                p_buy         = maLib.Value(index, 'Open', ds)
            end
            if showRenko == 1 then
                out_up       = up[index]
                out_dw       = dw[index]
            end
            if showRenko == 2 then
                out_up       = nil
                if trend[index] >= 0 then
                    out_dw = up[index]
                else
                    out_dw = dw[index]
                end
            end

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
        end
        return out_up, out_dw, p_buy, p_sell
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
