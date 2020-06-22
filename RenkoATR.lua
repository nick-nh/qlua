--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	Adaptive Renko ATR based.
]]
_G.load   = _G.loadfile or _G.load

local maLib = require('maLib')

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\RenkoATR.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local TYPE_POINT    = _G['TYPE_POINT']
local isDark        = _G.isDarkTheme()
local up_line_color = isDark and RGB(0, 230, 0) or RGB(0, 210, 0)
local dw_line_color = isDark and RGB(230, 0, 0) or RGB(210, 0, 0)
local os_time	    = os.time
local table_remove	= table.remove

_G.Settings= {
    Name 		= "*RenkoATR",
    br_size     = 0,                    -- Фиксированный размер шага. Если задан, то строится по указанному размеру (в пунктах)
    k           = 2,                    -- размер скользящего фильтра, используемый при вычислении размера блока от величины ATR как k*ATR
    period      = 10,                   -- Период расчета ATR
    showRenko   = 0,                    -- Показывать линии Renko; 0 - не показывать; 1 - показывать; 2 - показывать одной линией
    --Для установки значения, необходимо поставить * перед выбранным вариантом.
    brickType   = '*ATR; Std; Fix',     -- Тип расчета Renko; ATR; Std - стандартное отклонение; Fix - фиксированный размер, заданный в br_size
    line = {
        {
            Name  = 'Renko UP',
            Color = up_line_color,
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'Renko Down',
            Color = dw_line_color,
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'Buy',
            Color = up_line_color,
            Type  = TYPE_POINT,
            Width = 4
        },
        {
            Name  = 'Sell',
            Color = dw_line_color,
            Type  = TYPE_POINT,
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
    local Data
    local Renko_UP
    local Renko_DW

    local begin_index
    local l_index

    settings        = (settings or {})
    local br_size   = (settings.br_size or 0)
    local period    = (settings.period or 0)
    local k         = br_size == 0 and (settings.k or 1) or 1
    local Brick     = {}

    local brickType = 'ATR'
	for val in string.gmatch(settings.brickType or '*ATR', "([^;]+)") do
        if (val:find('*')) then
            brickType = val:gsub('*', ''):gsub("^%s*(.-)%s*$", "%1")
            break
        end
    end

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
                    Data        = {}
                    Data[1]     = maLib.Value(index, 'Close', ds) or 0
                end
            else
                local ds_info 	= _G.getDataSourceInfo()
                Brick[index]    = br_size/math_pow(10, (tonumber(_G.getParamEx(ds_info.class_code, ds_info.sec_code,"SEC_SCALE").param_value) or 0))
            end
            return Renko_UP
        end

        Brick[index]    = Brick[index-1]
        Renko_UP[index] = Renko_UP[index-1]
        Renko_DW[index] = Renko_DW[index-1]

        local atr       = brickType == 'ATR' and fATR(index)[index] or Brick[index-1]

        if not maLib.CheckIndex(index) then
            return Renko_UP
        end

        local close = maLib.Value(index, 'Close', ds)

        if brickType == 'Std' then
            if index ~= l_index then
                Data[#Data + 1] = Data[#Data]
                if #Data > period then table_remove(Data, 1) end
            end
            Data[#Data] = close
            atr         = maLib.Sigma(Data)
        end

        if close > Renko_UP[index-1] + Brick[index-1] then
            Renko_UP[index] = Renko_UP[index] + (Brick[index-1] == 0  and 0 or math_floor((close - Renko_UP[index-1])/Brick[index-1])*Brick[index-1])
            Brick[index]    = k*atr
            Renko_DW[index] = Renko_UP[index] - Brick[index]
		end
		if close < Renko_DW[index-1] - Brick[index-1] then
            Renko_DW[index] = Renko_DW[index] - (Brick[index-1] == 0  and 0 or math_floor((Renko_DW[index-1] - close)/Brick[index-1])*Brick[index-1])
            Brick[index]    = k*atr
            Renko_UP[index] = Renko_DW[index] + Brick[index]
        end

        l_index = index

        return Renko_UP, Renko_DW
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
    local trend
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
                trend           = {}
                trend[index]    = 0
                return
            end

            trend[index] = trend[index-1]

            local up, dw = fRenko(index)
            if (index - begin_index + 1) < period then
                return
            end
            if trend[index-1] >= 0 then
                p_sell        = (dw[index-1] < dw[index-2] and up[index-1] < up[index-2]) and maLib.Value(index, 'Open', ds) or nil
                trend[index]  = p_sell and -1 or trend[index-1]
            else
                p_buy         = (up[index-1] > up[index-2] and dw[index-1] > dw[index-2]) and maLib.Value(index, 'Open', ds) or nil
                trend[index]  = p_buy and 1 or trend[index-1]
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
