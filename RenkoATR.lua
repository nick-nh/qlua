--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	Adaptive Renko ATR based.
]]
_G.load   = _G.loadfile or _G.load

local maLib = load(_G.getWorkingFolder().."\\LuaIndicators\\maLib.lua")()

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\RenkoATR.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local TYPE_POINT    = _G['TYPE_POINT']
local up_line_color = RGB(0, 250, 0)
local dw_line_color = RGB(250, 0, 0)
local os_time	    = os.time

_G.Settings= {
    Name 		= "*RenkoATR",
    k           = 1,      -- размер скользящего фильтра, используемый при вычислении размера блока от величины ATR
    period      = 10,     -- Период расчета ATR
    showRenko   = 0,     -- Показывать линии Renko; 0 - не показывать; 1 - показывать
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
_G.unpack = rawget(table, "unpack") or _G.unpack

local PlotLines     = function() end
local error_log     = {}

local math_floor    = math.floor

local function myLog(text)
	if logFile==nil then return end
    logFile:write(tostring(os.date("%c",os_time())).." "..text.."\n");
    logFile:flush();
end
------------------------------------------------------------------
    --Moving Average
------------------------------------------------------------------


local function F_RENKO(settings, ds)

    local fATR
    local Renko_UP
    local Renko_DW
    local begin_index

    settings    = (settings or {})
    local k     = (settings.k or 1)
    local Brick = 0

    return function(index)

        if not maLib then return Renko_UP, Renko_DW end

        if Renko_UP == nil or index == begin_index then
            begin_index     = index
            Renko_UP        = {}
            Renko_UP[index] = maLib.Value(index, 'High', ds) or 0
            Renko_DW        = {}
            Renko_DW[index] = maLib.Value(index, 'Low', ds) or 0
            Brick           = k*(Renko_UP[index] - Renko_DW[index])
            fATR            = maLib.new(settings, ds)
            fATR(index)
            return Renko_UP
        end

        Renko_UP[index] = Renko_UP[index-1]
        Renko_DW[index] = Renko_DW[index-1]
        local atr       = fATR(index)[index]

        if not maLib.CheckIndex(index) then
            return Renko_UP
        end

        local close   = maLib.Value(index, 'Close', ds)

        -- myLog('index: '..tostring(index)..', ATR: '..tostring(atr)..', Brick: '..tostring(Brick)..', Renko_UP: '..tostring(Renko_UP[index])..', Renko_DW: '..tostring(Renko_DW[index]))

        if close > Renko_UP[index-1] + Brick then
            Renko_UP[index] = Renko_UP[index] + (Brick == 0  and 0 or math_floor((close - Renko_UP[index-1])/Brick)*Brick)
            Brick           = k*atr
            Renko_DW[index] = Renko_UP[index] - Brick
		end
		if close < Renko_DW[index-1] - Brick then
            Renko_DW[index] = Renko_DW[index] - (Brick == 0  and 0 or math_floor((Renko_DW[index-1] - close)/Brick)*Brick)
            Brick           = k*atr
            Renko_UP[index] = Renko_DW[index] + Brick
        end

        return Renko_UP, Renko_DW
     end
end

--Nick Rypoсk Moving Average (NRMA)
local function Algo(ds)

    local fRenko
    local trend
    local out_up
    local out_dw
    local p_buy
    local p_sell
    local begin_index

    return function (index, Fsettings)

        Fsettings           = (Fsettings or {})
        Fsettings.method    = 'ATR'
        local showRenko     = Fsettings.showRenko or 1

        local status, res = pcall(function()

            if fRenko == nil or index == 1 then
                begin_index     = index
                fRenko          = F_RENKO(Fsettings, ds)
                fRenko(index)
                trend           = 0
                return
            end

            p_buy  = nil
            p_sell = nil

            local up, dw = fRenko(index)
            if showRenko == 1 then
                out_up       = up[index]
                out_dw       = dw[index]
            end
            if index - begin_index < 2 then
                return
            end
            if trend >= 0 then
                p_sell = (dw[index-1] < dw[index-2] and up[index-1] < up[index-2]) and maLib.Value(index, 'Open', ds) or nil
                trend  = p_sell and -1 or trend
            else
                p_buy   = (up[index-1] > up[index-2] and dw[index-1] > dw[index-2]) and maLib.Value(index, 'Open', ds) or nil
                trend   = p_buy and 1 or trend
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
    PlotLines = Algo()
    return 4
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index, _G.Settings)
end