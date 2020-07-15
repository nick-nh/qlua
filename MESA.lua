--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    MESA Adaptive Moving Averages by John F. Ehlers
]]

_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\MESA.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local TYPE_POINT    = _G['TYPE_POINT']
local isDark        = _G.isDarkTheme()
local up_line_color = isDark and RGB(0, 230, 0) or RGB(0, 210, 0)
local dw_line_color = isDark and RGB(230, 0, 0) or RGB(210, 0, 0)
local os_time	    = os.time
--local math_abs	    = math.abs
local table_remove	= table.remove

_G.Settings= {
    Name 		= "*MESA",
    stdPeriod   = 7,
    stdK        = 1.0,
    fastLimit   = 0.42,
    slowLimit   = 0.05,
    data_type   = 'Median',
    line = {
        {
            Name  = 'MAMA',
            Color = isDark and RGB(255, 193, 193) or RGB(113, 0, 0),
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'FAMA',
            Color = isDark and RGB(193, 255, 193) or RGB(0, 113, 26),
            Type  = TYPE_LINE,
            Width = 2
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
    local data_type = (Fsettings.data_type or "Median")
    local period    = (Fsettings.stdPeriod or 10)
    local stdK      = (Fsettings.stdK or 1)
    error_log = {}

    local fAlpha
    local out1
    local out2
    local p_buy
    local p_sell
    local l_index
    local begin_index
    local Data
    local atr

    local trend
    local mama
    local fama

    return function (index)

        out1    = nil
        out2    = nil
        p_buy   = nil
        p_sell  = nil

        local status, res = pcall(function()

            if not maLib then return end

            local val = maLib.Value(index, data_type, ds)

            if fAlpha == nil or index == 1 then
                begin_index     = index
                fAlpha          = maLib.EthlerAlpha(Fsettings, ds)
                fAlpha(index)
                mama            = {}
                mama[index]     = val
                fama            = {}
                fama[index]     = val
                trend           = {}
                trend[index]    = 0
                atr             = 0
                Data            = {}
                Data[1]         = maLib.Value(index, 'Close', ds) or 0
                return
            end

            trend[index] = trend[index-1]
            if index ~= l_index then
                Data[#Data + 1] = Data[#Data]
                if #Data > period then table_remove(Data, 1) end
                --Data[#Data]       = math.abs(mama[index-1] - fama[index-1])
                Data[#Data]       = maLib.Value(index-1, 'Close', ds)
                atr               = maLib.Sigma(Data)*stdK
                l_index           = index
            end

            local alpha  = fAlpha(index)
            local alpha2 = alpha/2

            mama[index] = alpha*val + (1 - alpha)*(mama[index - 1] or 0)

            fama[index] = alpha2*mama[index] + (1 - alpha2)*(fama[index - 1] or 0)
            if index - begin_index > 2 then
                if trend[index-1] >= 0 then
                    p_sell        = ((fama[index-1] - mama[index-1]) > atr) and maLib.Value(index, 'Open', ds) or nil
                    trend[index]  = p_sell and -1 or trend[index-1]
                else
                    p_buy         = ((mama[index-1] - fama[index-1]) > atr) and maLib.Value(index, 'Open', ds) or nil
                    trend[index]  = p_buy and 1 or trend[index-1]
                end
            end

            out1 = mama[index]
            out2 = fama[index]
        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
            return nil
        end
        return out1, out2, p_buy, p_sell
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
