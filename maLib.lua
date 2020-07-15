local M = {}

local O     = _G['O']
local C     = _G['C']
local H     = _G['H']
local L     = _G['L']
local V     = _G['V']
local Size  = _G['Size']

local table_remove  = table.remove
local string_upper  = string.upper
local string_sub    = string.sub
local math_floor    = math.floor
local math_ceil     = math.ceil
local math_max      = math.max
local math_abs      = math.abs
local math_pow      = math.pow
local math_sqrt     = math.sqrt
local math_huge     = math.huge

------------------------------------------------------------------
    --Moving Average
------------------------------------------------------------------

local  function Slice(input, start, finish)
    start           = start or 1
    finish          = finish or #input
    if start == 1 and finish == #input then return input end
    local output = {}
    for i=start, finish or #input do
      output[#output + 1] = input[i]
    end
    return output
end

local  function Sum(input, start, finish)
    start           = start or 1
    finish          = finish or #input
    local output    = 0
    for i=start, finish or #input do
      output = output + input[i]
    end
    return output
end

local  function Normalize(input, start, finish)
    start        = start or 1
    finish       = finish or #input
    local output = {}
    local max_i  = input[start]
    local min_i  = input[start]
    for i=start, finish or #input do
        output[#output + 1] = input[i]
        if input[i] > max_i then max_i = #output end
        if input[i] < min_i then min_i = #output end
    end
    table_remove(output, min_i)
    table_remove(output, max_i-1)
    return output
end

-- Среднеквадратическое отклонение
local function Sigma(input, avg, start, finish)

    start           = math_max(start or 1, 1)
    finish          = finish or #input
    local period    = finish - start + 1

    avg = avg or Sum(Slice(input, start, finish), 1)/period

    local sq = 0
    for i = start, finish do
        if input[i] then
            sq = sq + math_pow(input[i] - avg, 2)
        end
    end

    return math_sqrt(sq/(period-1))
end

-- Коэффициент корреляции Пирсона
-- Ковариация
-- Среднеквадратическое отклонение
-- Стандартное отклонение Баланса
local function Correlation(input, compare, start, finish)

    if #compare == 0 then return end

    local period      = finish - start + 1
    local m_input     = 0
    local m_compare   = 0

    for i = start, finish do
        if compare[i] and input[i] then
            m_input   = m_input + input[i]
            m_compare = m_compare + compare[i]
        end
    end

    m_input   = m_input/period
    m_compare = m_compare/period

    --ковариация
    local cov           = 0
    local sq_input      = 0
    local sq_compare    = 0

    for i = start, finish do
        if compare[i] and input[i] then
            sq_input    = sq_input + math_pow(input[i]-m_input,2)
            sq_compare  = sq_compare + math_pow(compare[i]-m_compare,2)
            cov         = cov + (input[i]-m_input)*(compare[i]-m_compare)
        end
    end

    cov = cov/period
    local LRC = cov/(math_sqrt(sq_input/period)*math_sqrt(sq_compare/period))

    return LRC, cov

end

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
    if  data_type ~= "A" and index >= 1 then
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
        end
    elseif data_type == "A" then	--Any
        Out = ds and ds[index]
    end
    return Out or 0
end

local function dsSize(data_type, ds)
    data_type = (data_type and string_upper(string_sub(data_type,1,1))) or "C"
    if data_type == 'A' and ds then
        return #ds
    end
    if data_type ~= 'A' then
        if Size then
            return Size()
        end
        if ds and ds.Size then
            return ds:Size()
        end
    end
    return 0
end

local function CheckIndex(index, ds, data_type)
    data_type = (data_type and string_upper(string_sub(data_type,1,1))) or "C"
    if data_type == 'A' and ds then
        return ds and ds[index]
    end
    if data_type ~= 'A' then
        return (C and C(index)) or ((ds and ds.C) and ds:C(index)) or (ds and ds[index])
    end
end

local function GetIndex(index, shift, ds, data_type)
    while (index-shift) > 1 and not CheckIndex(index-shift, ds, data_type) do
        shift = shift -1
    end
    return index-shift
end

local function HilbertTransform(index, src)
    return 0.0962 * src[index] + 0.5769 * (src[index - 2] or 0) - 0.5769 * (src[index - 4] or 0) - 0.0962 * (src[index- 6] or 0)
end

--[[Ehlers Adaptive alfa
]]
local function EthlerAlpha(settings, ds)

    local fastLimit     = (settings.fastLimit or 0.5)
    local slowLimit     = (settings.slowLimit or 0.05)
    local data_type     = (settings.data_type or 'Close')

    local atan          = math.atan
    local pi            = math.pi
    local mesaPeriod    = {}
    local smooth        = {}
    local detrender     = {}
    local I1            = {}
    local Q1            = {}
    local I2            = {}
    local Q2            = {}
    local Re            = {}
    local Im            = {}
    local phase         = {}
    local deltaPhase    = {}

    local alpha

    local function computeComponent(index, src, k)
        return HilbertTransform(index, src)*k
    end

    return function(index)
        mesaPeriod[index]   = mesaPeriod[index-1] or 0
        smooth[index]       = smooth[index-1] or 0
        detrender[index]    = detrender[index-1] or 0
        I1[index]           = I1[index-1] or 0
        Q1[index]           = Q1[index-1] or 0
        I2[index]           = I2[index-1] or 0
        Q2[index]           = Q2[index-1] or 0
        Re[index]           = Re[index-1] or 0
        Im[index]           = Im[index-1] or 0
        phase[index]        = phase[index-1] or 0
        deltaPhase[index]   = deltaPhase[index-1] or 0

        if not CheckIndex(index, ds, data_type) then
            return alpha
        end

        local mesaPeriodMult    = 0.075*(mesaPeriod[index - 1] or 0) + 0.54
        smooth[index]           = (4*Value(index, data_type, ds) + 3*(Value(GetIndex(index, 1, ds, data_type), data_type, ds)) + 2*(Value(GetIndex(index, 2, ds, data_type), data_type, ds)) + (Value(GetIndex(index, 3, ds, data_type), data_type, ds)))/10

        detrender[index]        = computeComponent(index, smooth, mesaPeriodMult)

        --Compute InPhase and Quadrature components
        I1[index]               = detrender[index-3] or 0
        Q1[index]               = computeComponent(index, detrender, mesaPeriodMult)

        --Advance the phase of I1 and Q1 by 90 degrees
        local jI                = computeComponent(index, I1, mesaPeriodMult)
        local jQ                = computeComponent(index, Q1, mesaPeriodMult)

        --Phasor addition for 3 bar averaging
        I2[index]               =  I1[index] - jQ
        Q2[index]               =  Q1[index] + jI

        --Smooth the I and Q components before applying the discriminator
        I2[index]               =  0.2*I2[index] + 0.8*(I2[index - 1] or 0)
        Q2[index]               =  0.2*Q2[index] + 0.8*(Q2[index - 1] or 0)

        --Homodyne Discriminator
        Re[index]               = I2[index]*(I2[index - 1] or 0) + Q2[index]*(Q2[index - 1] or 0)
        Im[index]               = I2[index]*(Q2[index - 1] or 0) - Q2[index]*(I2[index - 1] or 0)

        Re[index]               =  0.2*Re[index] + 0.8*(Re[index - 1] or 0)
        Im[index]               =  0.2*Im[index] + 0.8*(Im[index - 1] or 0)

        if Re[index] ~= 0 and Im[index] ~= 0 then
            mesaPeriod[index] =  2*pi/atan(Im[index]/Re[index])
        end

        if mesaPeriod[index] > 1.5*(mesaPeriod[index - 1] or 0) then
            mesaPeriod[index] =  1.5*(mesaPeriod[index - 1] or 0)
        end

        if mesaPeriod[index] < 0.67*(mesaPeriod[index - 1] or 0) then
            mesaPeriod[index] =  0.67*(mesaPeriod[index - 1] or 0)
        end

        if mesaPeriod[index] < 6 then
            mesaPeriod[index] =  6
        end

        if mesaPeriod[index] > 50 then
            mesaPeriod[index] =  50
        end

        mesaPeriod[index] =  0.2*mesaPeriod[index] + 0.8*(mesaPeriod[index - 1] or 0)

        if I1[index] ~= 0 then
            phase[index] =  (180/pi)*atan(Q1[index]/I1[index])
        end

        deltaPhase[index] = (phase[index - 1] or 0) - phase[index]

        if  deltaPhase[index] < 1 then
            deltaPhase[index] =  1
        end

        alpha = fastLimit/deltaPhase[index]

        if  alpha < slowLimit then
            alpha =  slowLimit
        end

        return alpha
    end
end

--[[
    Ehlers Deviation-Scaled filters
]]
local function Get2PoleSSF(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")

    local pi        = math.pi
    local arg       = math.sqrt(2)*pi/period
    local a1        = math.exp(-arg)
    local b1        = 2*a1*math.cos(arg)
    local c2        = b1
    local c3        = -(a1*a1)
    local c1        = 1 - c2 - c3

    local SSF       = {}

    return function(index)
        SSF[index]      = SSF[index-1] or 0
        if not CheckIndex(index, ds) then
            return SSF
        end
        SSF[index]      = c1*Value(index, data_type, ds) + c2*(SSF[index-1] or 0) + c3*(SSF[index-2] or 0)
        return SSF
    end
end
local function Get3PoleSSF(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")

    local pi        = math.pi
    local arg       = pi/period
    local a1        = math.exp(-arg)
    local b1        = 2*a1*math.cos(1.738*arg)
    local c1        = a1*a1

    local coef2     = b1 + c1
    local coef3     = -(c1 + b1*c1)
    local coef4     = c1*c1
    local coef1     = 1 - coef2 - coef3 - coef4

    local SSF       = {}

    return function(index)
        SSF[index]      = SSF[index-1] or 0
        if not CheckIndex(index, ds) then
            return SSF
        end
        SSF[index]      = coef1*Value(index, data_type, ds) + coef2*(SSF[index-1] or 0) + coef3*(SSF[index-2] or 0) + coef4*(SSF[index-3] or 0)
        return SSF
    end
end

--[[Average True Range
]]
local function F_ATR(settings, ds)

    local period    = (settings.period or 9)

    local ATR     = {}
    local p_index
    local l_index

    return function(index)
        ATR[index]      = ATR[index-1] or 0
        if not CheckIndex(index, ds) then
            return ATR
        end
        if index ~= l_index then p_index = l_index end
        local high      = Value(index, 'High', ds)
        local low       = Value(index, 'low', ds)
        local p_close   = Value(p_index or 1, 'Close', ds)
        ATR[index]      = high - low
        if p_index then
            ATR[index]  = (ATR[index-1]*(period-1) + math_max(math_abs(high - low), math_abs(high - p_close), math_abs(p_close - low)))/period
        end
        l_index = index
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
        S_TMP[index]    = S_TMP[index-1] or 0
        if not CheckIndex(index, ds) then
            return S_TMP
        end
        S_ACC[index] = (S_ACC[index-1] or 0) + (Value(index, data_type, ds) or 0)
        if bars > period then
            S_TMP[index] = S_ACC[index] - (S_ACC[index - period] or 0)
        else
            S_TMP[index] = S_ACC[index]
            bars         = bars + 1
        end
        return S_TMP
    end
end

--[[Simple Moving Average (SMA)
SMA = sum(Pi) / n
]]
local function F_SMA(settings, ds)

    local period    = (settings.period or 9)
    local round     = (settings.round or "off")
    local scale     = (settings.scale or 0)

    local fSum      = F_SUM(settings, ds)
    local SMA_TMP   = {}
    local bars      = 0
    return function(index)
        SMA_TMP[index]  = SMA_TMP[index-1] or 0
        local sum       = fSum(index)[index]
        if not CheckIndex(index, ds) then
            return SMA_TMP
        end
        bars            = bars < period and (bars + 1) or period
        SMA_TMP[index]  = rounding(sum/bars, round, scale)
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

    local bars      = 0
    local SUM_TMP = {}
    local EMA_TMP = {}
    return function(index)
        EMA_TMP[index] = EMA_TMP[index-1] or 0
        if not CheckIndex(index, ds) then
            return EMA_TMP
        end
        if bars < period then
            bars = bars + 1
            SUM_TMP[index] = (Value(index, data_type, ds) + (SUM_TMP[index-1] or 0))
            EMA_TMP[index] = rounding(SUM_TMP[index]/bars, scale)
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
        WMA_TMP[index] = WMA_TMP[index-1] or 0
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
    local bars      = 0
    return function (index)
        VMA[index]  = VMA[index-1] or 0
        if not CheckIndex(index, ds) then
            return VMA
        end
        local vol       = Value(index, "Volume", ds) or 0
        VMA_ACC[index]  = (VMA_ACC[index-1] or 0) + (Value(index, data_type, ds) or 0)*vol
        VMA_VACC[index] = (VMA_VACC[index-1] or 0) + vol
        if bars >= period then
            local sum   = VMA_ACC[index] - (VMA_ACC[index-period] or 0)
            local sum_v = VMA_VACC[index] - (VMA_VACC[index-period] or 0)
            VMA[index] = sum_v == 0 and VMA[index] or rounding(sum/sum_v, round, scale)
        else
            bars = bars + 1
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
    local fSum      = F_SUM(settings, ds)
    local bars      = 0
    return function(index)
        SMMA_TMP[index] = SMMA_TMP[index-1] or 0
        local sum       = fSum(index)[index]
        if not CheckIndex(index, ds) then
            return SMMA_TMP
        end
        if bars <= period then
            bars = bars + 1
            SMMA_TMP[index] = rounding(sum/bars, round, scale)
        elseif bars > period then
            SMMA_TMP[index] = rounding((sum - SMMA_TMP[index-1] + (Value(index, data_type, ds) or 0))/period, round, scale)
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

    local p_index
    local l_index
    local Delta
    local fSUM
    local AMA
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
            l_index         = index
            return AMA
        end

        AMA[index]      = AMA[index-1]
        Delta[index]    = Delta[index-1]

        if not CheckIndex(index, ds) then
            return AMA
        end

        if index ~= l_index then p_index = l_index end

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

        l_index = index

        return AMA
     end
end

--[[The Reverse EMA Indicator by John F. Ehlers
]]
local function F_REMA(settings, ds)

    local alpha         = (settings.alpha or 0.1)
    local data_type     = (settings.data_type or "Close")
    local round         = (settings.round or "off")
    local scale         = (settings.scale or 0)
    local period        = (2/alpha) - 1
    local cc            = 1- alpha

    local REMA

    local RE1
    local RE2
    local RE3
    local RE4
    local RE5
    local RE6
    local RE7
    local RE8

    local fEMA

    return function(index)
        if REMA == nil or index == 1 then

            REMA             = {}
            REMA[index]      = 0

            RE1         = {}
            RE1[index]  = 0
            RE2         = {}
            RE2[index]  = 0
            RE3         = {}
            RE3[index]  = 0
            RE4         = {}
            RE4[index]  = 0
            RE5         = {}
            RE5[index]  = 0
            RE6         = {}
            RE6[index]  = 0
            RE7         = {}
            RE7[index]  = 0
            RE8         = {}
            RE8[index]  = 0
            fEMA        = F_EMA({period = period, data_type = data_type, round = round, scale = scale}, ds)
            fEMA(index)
            return REMA
        end

        REMA[index] = REMA[index-1]

        RE1[index]  = RE1[index-1]
        RE2[index]  = RE2[index-1]
        RE3[index]  = RE3[index-1]
        RE4[index]  = RE4[index-1]
        RE5[index]  = RE5[index-1]
        RE6[index]  = RE6[index-1]
        RE7[index]  = RE7[index-1]
        RE8[index]  = RE8[index-1]
        local ema   = fEMA(index)

        if not CheckIndex(index, ds) then
            return REMA
        end

        RE1[index]  = cc * ema[index] + ema[index-1]
		RE2[index]  = math_pow(cc, 2) * RE1[index] + RE1[index-1]
		RE3[index]  = math_pow(cc, 4) * RE2[index] + RE2[index-1]
		RE4[index]  = math_pow(cc, 8) * RE3[index] + RE3[index-1]
		RE5[index]  = math_pow(cc, 16) * RE4[index] + RE4[index-1]
		RE6[index]  = math_pow(cc, 32) * RE5[index] + RE5[index-1]
		RE7[index]  = math_pow(cc, 64) * RE6[index] + RE6[index-1]
		RE8[index]  = math_pow(cc, 128) * RE7[index] + RE7[index-1]
		REMA[index] = rounding(ema[index] - alpha*RE8[index], round, scale)

        return REMA
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

        gda_108[index] = gd_172 * Value(index, data_type, ds) + gd_180 * (gda_108[index-1])
		gda_112[index] = gd_172 * (gda_108[index]) + gd_180 * (gda_112[index-1])
		gda_116[index] = gd_172 * (gda_112[index]) + gd_180 * (gda_116[index-1])
		gda_120[index] = gd_172 * (gda_116[index]) + gd_180 * (gda_120[index-1])
		gda_124[index] = gd_172 * (gda_120[index]) + gd_180 * (gda_124[index-1])
		gda_128[index] = gd_172 * (gda_124[index]) + gd_180 * (gda_128[index-1])
		THV[index] = rounding(gd_132 * (gda_128[index]) + gd_140 * (gda_124[index]) + gd_148 * (gda_120[index]) + gd_156 * (gda_116[index]), round, scale)

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

--Nick Rypoсk Moving Average (NRMA)
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

-- Regression
-- Linear:      degree = 1
-- Parabolic:   degree = 2
-- Cubic:       degree = 3
local function F_REG(settings, ds)

    settings            = (settings or {})
    local period        = settings.period or 10
    local degree        = settings.degree or 1
    local kstd          = settings.kstd or 1
    local data_type     = (settings.data_type or "Close")

    local sql_buffer
    local sqh_buffer
    local fx_buffer
	local sx
    local input

    local nn = degree + 1
    local ai = {{1,2,3,4}, {1,2,3,4}, {1,2,3,4}, {1,2,3,4}}
	local b  = {}
	local x  = {}

    return function(index)


		if fx_buffer == nil or index == 1 then

			fx_buffer  = {}
			sql_buffer = {}
			sqh_buffer = {}
            input      = {}
			--- sx
			sx={}
			sx[1] = period + 1
            local sum
			for mi = 0, nn*2-2 do
                sum=0
                for n = 1, period do
					sum = sum + math_pow(n,mi)
				end
			    sx[mi+1]=sum
			end

			return nil
		end

        if not CheckIndex(index, ds) or index < period then
			return nil
		end

        input = {}

        --- syx
        local sum
		for mi=1, nn do
			sum = 0
			for n = 1, period do
				if CheckIndex(index+n-period, ds) then
                    input[#input + 1] = Value(index+n-period, data_type, ds)
                    if mi == 1 then
					   sum = sum + input[#input]
					else
					   sum = sum + input[#input]*math_pow(n, mi-1)
					end
				end
			end
			b[mi] = sum
		end

		--- Matrix
		for jj=1, nn do
			for ii=1, nn do
				ai[ii][jj] = sx[ii+jj-1]
			end
		end

		--- Gauss
		for kk=1, nn-1 do
			local ll = 0
			local mm = 0
			for ii = kk, nn do
				if math_abs(ai[ii][kk])>mm then
					mm = math_abs(ai[ii][kk])
					ll = ii
				end
			end

			if ll==0 then
				return nil
			end
			if ll~=kk then
				for jj=1, nn do
					ai[ll][jj], ai[kk][jj] = ai[kk][jj], ai[ll][jj]
				end
				b[ll], b[kk] = b[kk], b[ll]
			end
			for ii = kk+1, nn do
				local qq = ai[ii][kk]/ai[kk][kk]
				for jj=1, nn do
					if jj==kk then
						ai[ii][jj]=0
					else
						ai[ii][jj]=ai[ii][jj]-qq*ai[kk][jj]
					end
				end
				b[ii]=b[ii]-qq*b[kk]
			end
		end

		x[nn] = b[nn]/ai[nn][nn]

        local tt
        for ii=nn-1, 1, -1 do
            tt = 0
			for jj=1, nn-ii do
				tt    = tt + ai[ii][ii+jj]*x[ii+jj]
				x[ii] = (1/ai[ii][ii])*(b[ii] - tt)
			end
		end

		---
		for n = 1, period do
			sum=0
			for kk = 1, degree do
				sum = sum + x[kk+1]*math_pow(n,kk)
			end
			fx_buffer[n]=x[1] + sum
		end

        local sse = 0
        for n = 1, period do
            sse = sse + math_pow(fx_buffer[n] - input[n], 2)
        end

        sse = math_sqrt(sse/(period-1))*kstd

		for n = 1, period do
			sqh_buffer[n]=fx_buffer[n]+sse
			sql_buffer[n]=fx_buffer[n]-sse
		end

		return fx_buffer, sqh_buffer, sql_buffer

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
    elseif method == "REG" then
        return F_REG(settings, ds)
    elseif method == "REMA" then
        return F_REMA(settings, ds)
    else
        return nil
    end
end

M.new         = MA
M.Slice       = Slice
M.Sum         = Sum
M.Sigma       = Sigma
M.Normalize   = Normalize
M.Correlation = Correlation
M.EthlerAlpha = EthlerAlpha
M.Get2PoleSSF = Get2PoleSSF
M.Get3PoleSSF = Get3PoleSSF

M.CheckIndex  = CheckIndex
M.GetIndex    = GetIndex
M.rounding    = rounding
M.Value       = Value
M.dsSize      = dsSize

return M
