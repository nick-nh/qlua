local M = {}

local O = _G['O']
local C = _G['C']
local H = _G['H']
local L = _G['L']
local V = _G['V']

local string_upper  = string.upper
local string_sub    = string.sub
local math_floor    = math.floor
local math_ceil     = math.ceil
local math_max      = math.max
local math_min      = math.min
local math_abs      = math.abs
local math_pow      = math.pow
local math_huge     = math.huge

------------------------------------------------------------------
    --Moving Average
------------------------------------------------------------------

local function rounding(num, round, scale)
    scale = scale or 0
    if not round or string_upper(round)== "OFF" then return num end
    if num and tonumber(scale) then
        local mult = 10^scale
        if num >= 0 then return math_floor(num * mult + 0.5) / mult
        else return math_ceil(num * mult - 0.5) / mult end
    else return num end
end

local function Value(index, data_type, ds)
    local Out = nil
    data_type = (data_type and string_upper(string_sub(data_type,1,1))) or "A"
    if data_type == "O" then		--Open
        Out = (O and O(index)) or (ds and ds:O(index))
    elseif data_type == "H" then 	--High
        Out = (H and H(index)) or (ds and ds:H(index))
    elseif data_type == "L" then	--Low
        Out = (L and L(index)) or (ds and ds:L(index))
    elseif data_type == "C" then	--Close
        Out = (C and C(index)) or (ds and ds:C(index))
    elseif data_type == "V" then	--Volume
        Out = (V and V(index)) or (ds and ds:V(index))
    elseif data_type == "M" then	--Median
        Out = ((Value(index,"H",ds) + Value(index,"L",ds)) / 2)
    elseif data_type == "T" then	--Typical
        Out = ((Value(index,"M",ds) * 2 + Value(index,"C",ds))/3)
    elseif data_type == "W" then	--Weighted
        Out = ((Value(index,"T",ds) * 3 + Value(index,"O",ds))/4)
    elseif data_type == "D" then	--Difference
        Out = (Value(index,"H",ds) - Value(index,"L",ds))
    elseif data_type == "A" then	--Any
        if ds then Out = ds[index] else Out = 0 end
    end
    return Out or 0
end

local function CheckIndex(index, ds)
    return (C and C(index)) or ((ds and ds.C) and ds:C(index)) or (ds and ds[index])
end

--[[Average True Range
]]
local function F_ATR(settings, ds)

    local period    = (settings.period or 9)

    local ATR     = {}
    local p_index

    return function(index)
        local high      = Value(index, 'High', ds)
        local low       = Value(index, 'low', ds)
        local p_close   = Value(p_index or 1, 'Close', ds)

        ATR[index]      = high - low
        if not CheckIndex(index, ds) then
            return ATR
        end
        if p_index then
            local atr   = math_max(math_abs(high - low), math_abs(high - p_close), math_abs(p_close - low)) or ATR[index-1]
            ATR[index]  = (ATR[index-1] * (period-1) + atr)/period
        end
        p_index = index
        return ATR
    end
end

--[[Sum od values
sum(Pi)
]]
local function F_SUM(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")

    local S_ACC = {}
    local S_TMP = {}
    local bars    = 0
    return function(index)
        local val       = Value(index, data_type, ds) or 0
        S_TMP[index]    = S_TMP[index-1] or val
        if not CheckIndex(index, ds) then
            return S_TMP
        end
        S_ACC[index] = (S_ACC[index-1] or 0) + val
        if bars > 1 then
            S_TMP[index] = S_ACC[index] - (S_ACC[index - math_min(bars, period)] or 0)
        end
        bars = bars + 1
        return S_TMP
    end
end

--[[Simple Moving Average (SMA)
SMA = sum(Pi) / n
]]
local function F_SMA(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local round     = (settings.round or "off")
    local scale     = (settings.scale or 0)

    local fSum    = F_SUM(settings, ds)
    local SMA_TMP = {}
    local bars    = 0
    return function(index)
        local val       = Value(index, data_type, ds) or 0
        SMA_TMP[index]  = SMA_TMP[index-1] or val
        local sum       = fSum(index)[index]
        if not CheckIndex(index, ds) then
            return SMA_TMP
        end
        SMA_TMP[index]  = rounding(sum/math_min(bars, period), round, scale)
        bars            = bars + 1
        return SMA_TMP
    end
end

--[[Exponential Moving Average (EMA)
EMAi = (EMAi-1*(n-1)+2*Pi) / (n+1)
]]
local function F_EMA(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local round     = (settings.round or "off")
    local scale     = (settings.scale or 0)

    local EMA_TMP = {}
    return function(index)
        EMA_TMP[index] = EMA_TMP[index-1]
        if not CheckIndex(index, ds) then
            return EMA_TMP
        end
        if EMA_TMP[index-1] == nil then
            EMA_TMP[index] = rounding(Value(index, data_type, ds), round, scale)
        else
            EMA_TMP[index] = rounding((EMA_TMP[index-1]*(period-1) + 2*Value(index, data_type, ds))/(period+1), round, scale)
        end
        return EMA_TMP
    end
end

--[[
William Moving Average (WMA)
( Previous WILLMA * ( period - 1 ) + Data ) / period
]]
local function F_WMA(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local round     = (settings.round or "off")
    local scale     = (settings.scale or 0)

    local WMA_TMP = {}
    return function(index)
        WMA_TMP[index] = WMA_TMP[index-1]
        if not CheckIndex(index, ds) then
            return WMA_TMP
        end
        if WMA_TMP[index-1] == nil then
            WMA_TMP[index] = rounding(Value(index, data_type, ds), round, scale)
        else
            WMA_TMP[index] = rounding((WMA_TMP[index-1]*(period-1) + Value(index, data_type, ds))/period, round, scale)
        end
        return WMA_TMP
    end
end

--[[Volume Adjusted Moving Average (VMA)
VMA = sum(Pi*Vi) / sum(Vi)
]]
local function F_VMA(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local round     = (settings.round or "off")
    local scale     = (settings.scale or 0)

    local VMA       = {}
    local VMA_ACC   = {}
    local VMA_VACC  = {}
    return function (index)
        local val   = Value(index, data_type, ds) or 0
        local vol   = Value(index, "Volume", ds) or 0
        VMA[index]  = VMA[index-1] or val
        if not CheckIndex(index, ds) then
            return VMA
        end
        VMA_ACC[index]  = (VMA_ACC[index-1] or 0) + val*vol
        VMA_VACC[index] = (VMA_VACC[index-1] or 0) + vol
        if index >= period then
            VMA[index] = (VMA_VACC[index] or 0) == 0 and VMA_VACC[index-1] or rounding(VMA_ACC[index]/VMA_VACC[index], round, scale)
        end
        return VMA
    end
end

--[[Smoothed Moving Average (SMMA)
SMMAi = (sum(Pi) - SMMAi-1 + Pi) / n
]]
local function F_SMMA(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local round     = (settings.round or "off")
    local scale     = (settings.scale or 0)

    local SMMA_TMP  = {}
    local SMA_ACC   = {}
    return function(index)
        SMMA_TMP[index] = SMMA_TMP[index-1] or Value(index, data_type, ds)
        if index >= period then
            if not CheckIndex(index, ds) then
                return SMMA_TMP
            end
            SMA_ACC[index] = (SMA_ACC[index-1] or 0) + Value(index, data_type, ds)
            if index == period then
                SMMA_TMP[index] = rounding(SMA_ACC[index]/period, round, scale)
            else
                SMMA_TMP[index] = rounding(((SMA_ACC[index] - (SMA_ACC[index - period] or 0)) - SMMA_TMP[index-1] + Value(index, data_type, ds))/period, round, scale)
            end
        end
        return SMMA_TMP
    end
end

--[[The Triple Exponential Moving Average (TEMA)
TEMA = 3 * ema1 - 3 * ema2 + ema3
]]
local function F_TEMA(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local round     = (settings.round or "off")
    local scale     = (settings.scale or 0)

    local fEMA1
    local ema1
    local fEMA2
    local ema2
    local fEMA3
    local TEMA
    return function(index)
        if fEMA1 == nil then
            fEMA1 = F_EMA(settings, ds)
            ema1  = fEMA1(index)
            fEMA2 = F_EMA({period = period, data_type = 'Any', round = round, scale = scale}, ema1)
            ema2  = fEMA2(index)
            fEMA3 = F_EMA({period = period, data_type = 'Any', round = round, scale = scale}, ema2)
            fEMA3(index)
            TEMA  = {}
            TEMA[index] = rounding(Value(index, data_type, ds), round, scale) or 0
        end

        TEMA[index] = rounding(3*fEMA1(index)[index] - 3*fEMA2(index)[index] + fEMA3(index)[index], round, scale)
        return TEMA
     end
end

--[[Adaptive Moving Average
]]
local function F_AMA(settings, ds)

    local period        = (settings.period or 9)
    local fast_period   = (settings.fast_period or 2)
    local slow_period   = (settings.slow_period or 30)
    local data_type     = (settings.data_type or "Close")
    local round         = (settings.round or "off")
    local scale         = (settings.scale or 0)

    local Delta
    local fSUM
    local AMA
    local p_index
    local fast_k = 2/(fast_period + 1)
    local slow_k = 2/(slow_period + 1)

    return function(index)
        if Delta == nil or index == 1 then
            Delta           = {}
            Delta[index]    = 0
            fSUM            = F_SUM({period = period, data_type = 'Any', round = round, scale = scale}, Delta)
            fSUM(index)
            AMA             = {}
            AMA[index]      = rounding(Value(index, data_type, ds), round, scale) or 0
            p_index         = index
            return AMA
        end

        AMA[index]      = AMA[index-1]
        Delta[index]    = Delta[index-1]

        if not CheckIndex(index, ds) then
            return AMA
        end

        Delta[index]    = math_abs(Value(index, data_type, ds) - Value(p_index, data_type, ds))
        local sum       = fSUM(index)[index]
        local er        = sum == 0 and 1 or Delta[index]/sum
        local ssc       = math_pow(er*(fast_k - slow_k) + slow_k, 2)

        if AMA[index-1] == nil then
            AMA[index] = rounding(Value(index, data_type, ds), round, scale)
        else
            AMA[index] = rounding((Value(index, data_type, ds)*ssc - AMA[index-1])*(ssc) , round, scale)
            AMA[index] = rounding(AMA[index-1] + (Value(index, data_type, ds) - AMA[index-1])*ssc , round, scale)
        end

        p_index = index

        return AMA
     end
end

--[[THV
]]
local function F_THV(settings, ds)

    local period        = (settings.period or 9)
    local koef          = (settings.koef or 1)
    local data_type     = (settings.data_type or "Close")
    local round         = (settings.round or "off")
    local scale         = (settings.scale or 0)

    local THV
    local p_index

    local gda_108
    local gda_112
    local gda_116
    local gda_120
    local gda_124
    local gda_128

    local gd_188 = koef * koef
    local gd_196 = gd_188 * koef
    local gd_132 = -gd_196
    local gd_140 = 3.0 * (gd_188 + gd_196)
    local gd_148 = -3.0 * (2.0 * gd_188 + koef + gd_196)
    local gd_156 = 3.0 * koef + 1.0 + gd_196 + 3.0 * gd_188
    local gd_164 = period
    if gd_164 < 1.0 then gd_164 = 1 end
    gd_164 = (gd_164 - 1.0) / 2.0 + 1.0
    local gd_172 = 2 / (gd_164 + 1.0)
    local gd_180 = 1 - gd_172

    return function(index)
        if THV == nil or index == 1 then

            THV             = {}
            THV[index]      = Value(index, data_type, ds)

            gda_108         = {}
            gda_108[index]  = 0
            gda_112         = {}
            gda_112[index]  = 0
            gda_116         = {}
            gda_116[index]  = 0
            gda_120         = {}
            gda_120[index]  = 0
            gda_124         = {}
            gda_124[index]  = 0
            gda_128         = {}
            gda_128[index]  = 0

            p_index         = index
            return THV
        end

        THV[index]     = THV[index-1]

        gda_108[index] = gda_108[index-1]
        gda_112[index] = gda_112[index-1]
        gda_116[index] = gda_116[index-1]
        gda_120[index] = gda_120[index-1]
        gda_124[index] = gda_124[index-1]
        gda_128[index] = gda_128[index-1]

        if not CheckIndex(index, ds) then
            return THV
        end

        gda_108[index] = gd_172 * Value(index, data_type, ds) + gd_180 * (gda_108[p_index])
		gda_112[index] = gd_172 * (gda_108[index]) + gd_180 * (gda_112[p_index])
		gda_116[index] = gd_172 * (gda_112[index]) + gd_180 * (gda_116[p_index])
		gda_120[index] = gd_172 * (gda_116[index]) + gd_180 * (gda_120[p_index])
		gda_124[index] = gd_172 * (gda_120[index]) + gd_180 * (gda_124[p_index])
		gda_128[index] = gd_172 * (gda_124[index]) + gd_180 * (gda_128[p_index])
		THV[index] = rounding(gd_132 * (gda_128[index]) + gd_140 * (gda_124[index]) + gd_148 * (gda_120[index]) + gd_156 * (gda_116[index]), round, scale)

        p_index = index

        return THV
     end
end

--[[Nick Rypock Trailing Reverse
]]
local function F_NRTR(settings, ds)
    local bufHigh
    local bufLow
    local NRTR
    local begin_index

    settings        = (settings or {})
    -- local period    = (settings.period or 10)
    local k         = (settings.k or 0.5)
    local round     = (settings.round or "off")
    local scale     = (settings.scale or 0)

    local trend     = 0

    return function(index)

        if NRTR == nil or index == begin_index then
            begin_index     = index
            NRTR = {}
            NRTR[index]     = Value(index, 'Close', ds) or 0
            bufHigh = {}
            bufHigh[index]  = Value(index, 'High', ds) or 0
            bufLow = {}
            bufLow[index]   = Value(index, 'Low', ds) or math_huge
            return NRTR
        end

        NRTR[index]     = NRTR[index-1]
        bufHigh[index]  = bufHigh[index-1]
        bufLow[index]   = bufLow[index-1]

        if not CheckIndex(index, ds) then
            return NRTR
        end

        local val       = Value(index, 'Close', ds)

        if trend >= 0 then
            local val_h = Value(index, 'High', ds)
            if val_h > bufHigh[index] then bufHigh[index] = val_h end
            local reverse   = bufHigh[index]*(1-k/100)
			if val <= reverse then
                reverse         = val*(1+k/100)
                bufLow[index]   = val
                trend           = -1
            end
            NRTR[index]= rounding(reverse, round, scale)
		end
		if trend < 0 then
            local val_l = Value(index, 'Low', ds)
            if val_l < bufLow[index] then bufLow[index] = val_l end
            local reverse   = bufLow[index]*(1+k/100)
			if val >= reverse then
                reverse         = val*(1-k/100)
                bufHigh[index]  = val
                trend           = 1
			end
            NRTR[index]= rounding(reverse, round, scale)
		end
        return NRTR
     end
end

--Nick Rypoñk Moving Average (NRMA)
local function F_NRMA(settings, ds)

    local k         = (settings.k or 0.5)
    local fast      = (settings.fast or 2)
    local sharp     = (settings.sharp or 2)
    local ma_period = (settings.ma_period or 3)
    local ma_method = (settings.ma_method or 'SMA')
    local round     = (settings.round or "off")
    local scale     = (settings.scale or 0)
    local calc_type = (settings.calc_type or 0)

    local NRMA
    local fNRTR
	local NRTR
	local oscNRTR
    local fMA

    return function (index)

        if NRTR == nil or index == 1 then
            NRMA            = {}
            NRMA[index]     = Value(index, 'Close', ds)
            fNRTR           = F_NRTR(settings, ds)
            NRTR            = fNRTR(index)
            oscNRTR         = {}
            oscNRTR[index]  = 0
            fMA             = M.new({period = ma_period, method = ma_method, data_type = 'Any', round = round, scale = scale}, calc_type == 0 and oscNRTR or NRMA)
            return NRMA, NRTR
        end

        fNRTR(index)

        NRMA[index]     = NRMA[index-1]
        oscNRTR[index]  = oscNRTR[index-1]

        if not CheckIndex(index, ds) then
            return (calc_type == 0 and NRMA or fMA(index)), NRTR
        end

        if calc_type == 0 then
            fMA(index)
        end

        local val       = Value(index, 'Close', ds)
        oscNRTR[index]  = (100*math_abs(val-NRTR[index])/val)/k
        local n_ratio   = math_pow(calc_type == 0 and fMA(index)[index] or oscNRTR[index], sharp)

        NRMA[index] = NRMA[index-1] + n_ratio*(2/(1 + fast))*(val - NRMA[index-1])

        return (calc_type == 0 and NRMA or fMA(index)), NRTR

    end
end

local function MA(settings, ds)

    settings = (settings or {})
    local method    = (settings.method or "EMA")

    if method == "SMA" then
        return F_SMA(settings, ds)
    elseif method == "EMA" then
        return F_EMA(settings, ds)
    elseif method == "VMA" then
        return F_VMA(settings, ds)
    elseif method == "SMMA" then
        return F_SMMA(settings, ds)
    elseif method == "WMA" then
        return F_WMA(settings, ds)
    elseif method == "TEMA" then
        return F_TEMA(settings, ds)
    elseif method == "AMA" then
        return F_AMA(settings, ds)
    elseif method == "ATR" then
        return F_ATR(settings, ds)
    elseif method == "THV" then
        return F_THV(settings, ds)
    elseif method == "NRTR" then
        return F_NRTR(settings, ds)
    elseif method == "NRMA" then
        return F_NRMA(settings, ds)
    else
        return nil
    end
end

M.new         = MA
M.CheckIndex  = CheckIndex
M.rounding    = rounding
M.Value       = Value

return M