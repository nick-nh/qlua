--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua
    Open Close Cross Strategy R5 revised by JustUncleL
    https://www.tradingview.com/script/vObmEraY-Open-Close-Cross-Strategy-R5-revised-by-JustUncleL/
]]

_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\MA.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local TYPE_POINT    = _G['TYPE_POINT']
local o_color       = RGB(255, 128, 0)
local c_color       = RGB(0, 128, 255)
local os_time	    = os.time

_G.Settings= {
    Name 		= "*OCR5",
    period      = 20,

    --Указать вид расчета
    -- SMA - Simple moving average
    -- EMA  - Exponential moving average
    -- DEMA  - Double Exponential moving average
    -- TEMA  - Triple Exponential moving average
    -- WMA  - Weighted moving average
    -- VWMA  - Volume Adjusted moving average
    -- SMMA  - Smoothed moving average
    -- HMA  - Hull moving average
    -- LSMA  - Least Squares (linear regression) moving average
    -- ALMA  - Arnaud Legoux moving average
    -- SSMA  - SuperSmoother filter Moving Average by John F. Ehlers
    -- TMA  - Triangular (extreme smooth) moving average
    method      = 'SMA',
    line = {
        {
            Name  = 'Close',
            Color = c_color,
            Type  = TYPE_LINE,
            Width = 2
        },
        {
            Name  = 'Open',
            Color = o_color,
            Type  = TYPE_LINE,
            Width = 2
        },
        {
            Name = "OCR5 up",
            Type = TYPE_POINT,
            Width = 2,
            Color = RGB(89,213, 107)
        },
        {
            Name = "OCR5 dw",
            Type = TYPE_POINT,
            Width = 2,
            Color = RGB(255, 58, 0)
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
        },
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
    local method        = Fsettings.method or 'EMA'
    local period        = Fsettings.period or 9

    error_log = {}

    local cfMA, ofMA, err
    local out
    local begin_index
    local trend = {}

    return function (index)

        local status, res = pcall(function()

            out = {}

            if not maLib then return end

            if cfMA == nil or index == begin_index then
                begin_index = index
                cfMA, err         = maLib.new({method = method, period = period, data_type = 'Close'}, ds)
                if not cfMA and not error_log[tostring(err)] then
                    error_log[tostring(err)] = true
                    myLog(tostring(err))
                    message(tostring(err))
                end
                cfMA(index)
                ofMA, err         = maLib.new({method = method, period = period, data_type = 'Open'}, ds)
                if not ofMA and not error_log[tostring(err)] then
                    error_log[tostring(err)] = true
                    myLog(tostring(err))
                    message(tostring(err))
                end
                ofMA(index)
                trend[index] = 0
                return
            end
            if cfMA then
                out[1] = cfMA(index)[index]
            end
            if ofMA then
                out[2] = ofMA(index)[index]
            end
            trend[index] = (out[1] and out[2]) and (out[1] > out[2] and 1 or -1) or trend[index-1]
            if trend[index-1] ~= trend[index-2] then
				out[5]      = trend[index-1] == 1 and _G.O(index) or nil
				out[6]      = trend[index-1] == -1 and _G.O(index) or nil
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