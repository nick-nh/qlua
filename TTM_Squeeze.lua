--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	TTM Squeeze от John Carter
]]
_G.unpack = rawget(table, "unpack") or _G.unpack

_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\Squeeze.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local isDark        = _G.isDarkTheme()
local zero_color    = isDark and RGB(123, 123, 123) or RGB(70, 70, 70)
local line_color    = isDark and RGB(240, 240, 240) or RGB(0, 0, 0)
local up_line_color = isDark and RGB(0, 230, 0) or RGB(0, 210, 0)
local dw_line_color = isDark and RGB(230, 0, 0) or RGB(210, 0, 0)
local sq_no_color   = isDark and RGB(0, 63, 103) or RGB(176, 215, 255)

_G.Settings= {
    Name 		= "*TTM Squeeze",
    data_type   = 'Close',
    useATR      = 0,      -- использовать ATR; 0 - не использовать; 1 - использовать
    periodBB    = 10,     -- Период расчета полос Болинджера
    multBB      = 2.0,      -- коэффициент при расчете полос Болинджера
    periodKC    = 10,     -- Период расчета канала Кельтнера
    multKC      = 2.0,      -- коэффициент при расчете канала Кельтнера
    line = {
        {
            Name  = 'zero',
            Color = zero_color,
            Type  = _G['TYPE_LINE'],
            Width = 1
        },
        {
            Name  = 'Momentum Up',
            Color = up_line_color,
            Type  = _G['TYPE_HISTOGRAM'],
            Width = 2
        },
        {
            Name  = 'Momentum Down',
            Color = dw_line_color,
            Type  = _G['TYPE_HISTOGRAM'],
            Width = 2
        },
        {
            Name  = 'NO Squeeze',
            Color = sq_no_color,
            Type  = _G['TYPE_POINT'],
            Width = 3
        },
        {
            Name  = 'Squeeze',
            Color = line_color,
            Type  = _G['TYPE_POINT'],
            Width = 3
        }
    }
}

local PlotLines     = function() end
local error_log     = {}

local math_max      = math.max
local math_min      = math.min
local os_time	    = os.time
local table_remove	= table.remove

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

--TTM Squeeze от John Carter
local function Algo(Fsettings, ds)

    Fsettings        = (Fsettings or {})
    local data_type  = (Fsettings.data_type or "Close")
    local periodBB   = (Fsettings.periodBB or 10)
    local periodKC   = (Fsettings.periodKC or 10)
    local round      = (Fsettings.round or "off")
    local scale      = (Fsettings.scale or 0)
    local multBB     = (Fsettings.multBB or 2)
    local multKC     = (Fsettings.multKC or 2)
    local useATR     = (Fsettings.useATR or 0)

    local m_period   = math_max(periodBB, periodKC)

    error_log = {}

    local fSMA_BB
    local fSMA_KC
    local fATR
    local sourceH
    local sourceL
    local sourceBB
    local sourceKC
    local range
    local fSMA_Range
    local Average
    local Raw
    local fReg
    local out_up
    local out_dw
    local squeeze
    local no_squeeze

    local l_index
    local reg
    local begin_index

    return function (index)

        local status, res = pcall(function()

            out_up  = nil
            out_dw  = nil
            squeeze = nil

            if sourceBB == nil or index == 1 then
                begin_index    = index
                sourceH         = {}
                sourceH[1]      = maLib.Value(index, 'High', ds)
                sourceL         = {}
                sourceL[1]      = maLib.Value(index, 'Low', ds)
                sourceBB        = {}
                sourceBB[1]     = maLib.Value(index, data_type, ds)
                sourceKC        = {}
                sourceKC[1]     = sourceBB[1]
                fSMA_BB         = maLib.new({period = periodBB, method = 'SMA', data_type = 'Close', round = round, scale = scale}, ds)
                fSMA_BB(index)
                fSMA_KC         = maLib.new({period = periodKC, method = 'SMA', data_type = 'Close', round = round, scale = scale}, ds)
                fSMA_KC(index)
                range           = {}
                range[index]    = sourceH[index] - sourceL[index]
                if useATR == 1 then
                    fATR            = maLib.new({period = periodKC, method = 'ATR'}, ds)
                    range[index]    = fATR(index)[index]
                end
                fSMA_Range      = maLib.new({period = periodKC, method = 'SMA', data_type = 'Any', round = round, scale = scale}, range)
                fSMA_Range(index)
                Average         = {}
                Average[1]      = maLib.Value(index, data_type, ds)
                Raw             = {}
                Raw[1]          = 0
                fReg            = maLib.new({period = periodKC, method = 'REG', data_type = 'Any', round = round, scale = scale}, Raw)
                fReg(1)
                reg            = {}
                reg[index]     = 0
                return
            end

            local sma_bb    = fSMA_BB(index)
            local sma_kc    = fSMA_KC(index)
            range[index]    = range[index - 1]
            reg[index]      = reg[index - 1]

            if not maLib.CheckIndex(index, ds) then
                if useATR == 1 then
                    range[index] = fATR(index)[index]
                end
                fSMA_Range(index)
                return
            end

            if index ~= l_index then
                sourceBB[#sourceBB + 1] = sourceBB[#sourceBB]
                if #sourceBB > periodBB then table_remove(sourceBB, 1) end
                sourceKC[#sourceKC + 1] = sourceKC[#sourceKC]
                if #sourceKC > periodKC then table_remove(sourceKC, 1) end
                sourceH[#sourceH + 1]   = sourceH[#sourceH]
                if #sourceH > periodKC then table_remove(sourceH, 1) end
                sourceL[#sourceL + 1]   = sourceL[#sourceL]
                if #sourceL > periodKC then table_remove(sourceL, 1) end
                Average[#Average + 1]   = Average[#Average]
                if #Average > periodKC then table_remove(Average, 1) end
                Raw[#Raw + 1]           = Raw[#Raw]
                if #Raw > periodKC then table_remove(Raw, 1) end
            end

            local data          = maLib.Value(index, data_type, ds)
            sourceKC[#sourceKC] = data
            sourceBB[#sourceBB] = data
            sourceH[#sourceH]   = maLib.Value(index, 'High', ds)
            sourceL[#sourceL]   = maLib.Value(index, 'Low', ds)

            if useATR == 1 then
                range[index]    = fATR(index)[index]
            else
                range[index]    = sourceH[#sourceH] - sourceL[#sourceL]
            end

            local sma_range     = fSMA_Range(index)[index]
            Average[#Average]   = ((math_max(unpack(sourceH)) + math_min(unpack(sourceL)))/2 + sma_kc[index])/2
            Raw[#Raw]           = data - Average[#Average]

            if (index - begin_index + 1) >= m_period then
                reg[index] = fReg(#Raw)[#Raw]
                if reg[index] >= (reg[index-1] or reg[index]) then
                    out_up  = reg[index]
                else
                    out_dw  = reg[index]
                end
                local std       = maLib.Sigma(sourceBB)*multBB

                local upperBB   = sma_bb[index] + std
                local lowerBB   = sma_bb[index] - std
                local upperKC   = sma_kc[index] + sma_range*multKC
                local lowerKC   = sma_kc[index] - sma_range*multKC
                local sqzOn     = (lowerBB > lowerKC) and (upperBB < upperKC)
                local sqzOff    = (lowerBB < lowerKC) and (upperBB > upperKC)
                local noSqz     = (sqzOn == false) and (sqzOff == false)
                no_squeeze      = noSqz and 0 or nil
                squeeze         = sqzOn and 0 or nil
            end
            l_index = index

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
        end
        return 0, out_up, out_dw, no_squeeze, squeeze
    end
end

function _G.Init()
    PlotLines = Algo(_G.Settings)
    return 5
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end
