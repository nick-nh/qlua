local O     = _G['O']
local C     = _G['C']
local H     = _G['H']
local L     = _G['L']
local V     = _G['V']
local Size  = _G['Size']

local table_remove  = table.remove
local string_upper  = string.upper
local string_sub    = string.sub
local string_len    = string.len
local string_match  = string.match
local math_floor    = math.floor
local math_ceil     = math.ceil
local math_max      = math.max
local math_min      = math.min
local math_abs      = math.abs
local math_pow      = function(x, y) return x^y end
local math_sqrt     = math.sqrt
local math_exp      = math.exp
local math_log      = math.log
local os_time       = os.time
local os_date       = os.date
local math_huge     = math.huge
local table_unpack	= table.unpack

local M = {}
M.LICENSE = {
    _VERSION     = 'MA lib 2022.03.30',
    _DESCRIPTION = 'quik lib',
    _AUTHOR      = 'nnh: nick-h@yandex.ru'
}

local function is_date(val)
    local status = pcall(function() return type(val) == "table" and os_time(val); end)
    return status
end

---@param strT string
local function FixStrTime(strT)
    strT=tostring(strT)
    local hour, min, sec = 0, 0, 0
    local len = string_len(strT)
    if len==8 then
       hour,min,sec = string_match(strT,"(%d%d)%p(%d%d)%p(%d%d)")
    elseif len==7 then
        hour,min,sec  = string_match(strT,"(%d)%p(%d%d)%p(%d%d)")
    elseif len==6 then
        hour,min,sec  = string_match(strT,"(%d%d)(%d%d)(%d%d)")
    elseif len==5 then
        hour,min,sec  = string_match(strT,"(%d)(%d%d)(%d%d)")
    elseif len==4 then
        hour,min  = string_match(strT,"(%d%d)(%d%d)")
    end
    return hour,min,sec
end

-- Приводит время из строкового формата ЧЧ:ММ:CC к формату datetime
---@param str_time string
local function StrToTime(str_time, sdt)
    if type(str_time) ~= 'string' then return os_date('*t') end
    if not is_date(sdt) then os_date('*t') end
    local h,m,s = FixStrTime(str_time)
    sdt.hour    = tonumber(h)
    sdt.min     = tonumber(m)
    sdt.sec     = s==nil and 0 or tonumber(s)
    return sdt
end

-- Приводит время из строкового формата ЧЧ:ММ[:CC] к формату datetime
---@param str_time string
---@param sdt table|nil
local function GetStringTime(str_time, sdt)
    return str_time==0 and {} or (StrToTime(#tostring(str_time)<6 and tostring(str_time)..':00' or tostring(str_time), sdt))
end

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

local  function wSum(input, start, finish)
    start           = start or 1
    finish          = finish or #input
    local output    = 0
    for i=start, finish or #input do
      output = output + input[i]*(start-i+1)
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
local function Sigma(input, avg, start, finish, not_shifted)

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

    return math_sqrt(sq/(not_shifted and period or (period-1)))
end

-- Коэффициент корреляции Пирсона|автокорреляции
-- Ковариация
---@param input table
---@param cmp table|number
---@param start number
---@param finish number
---@return number
---@return number
local function Correlation(input, cmp, start, finish)

    local tc    = type(cmp)
    local shift = 0
    local compare
    if tc == 'table' and #cmp == 0 then return end
    if tc == 'number' then
        compare = input
        shift   = cmp
    else
        compare = cmp
    end

    local num   = 0
    local sx    = 0
    local sy    = 0
    local sxx   = 0
    local syy   = 0
    local sxy   = 0

    for i = start+shift, finish do
        if compare[i-shift] and input[i] then
            sx      = sx + input[i]
            sy      = sy + compare[i-shift]
            sxx     = sxx + input[i]*input[i]
            syy     = syy + compare[i-shift]*compare[i-shift]
            sxy     = sxy + input[i]*compare[i-shift]
            num     = num + 1
        end
    end

    local lrc = ((num*sxx - sx*sx)*(num*syy - sy*sy) > 0) and (num*sxy - sx*sy)/math_sqrt((num*sxx - sx*sx)*(num*syy - sy*sy)) or 0
    local cov = sxy/num - (sx/num)*(sy/num)

    return lrc, cov

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
    if tostring(data_type):upper() == 'TIME' then
        return (ds and ds:T(index))
    end
    data_type = (data_type and string_upper(string_sub(data_type,1,1))) or "A"
    if  data_type ~= "A" and index >= 1 then
        if data_type == "O" then		--Open
            Out = (ds and ds:O(index)) or (O and O(index))
        elseif data_type == "H" then 	--High
            Out = (ds and ds:H(index)) or (H and H(index))
        elseif data_type == "L" then	--Low
            Out = (ds and ds:L(index)) or (L and L(index))
        elseif data_type == "C" then	--Close
            Out = (ds and ds:C(index)) or (C and C(index))
        elseif data_type == "V" then	--Volume
            Out = (ds and ds:V(index)) or (V and V(index))
        elseif data_type == "M" then	--Median
            Out = ((Value(index,"H",ds) + Value(index,"L",ds)) / 2)
        elseif data_type == "T" then	--Typical
            Out = ((Value(index,"M",ds) * 2 + Value(index,"C",ds))/3)
        elseif data_type == "W" then	--Weighted
            Out = ((Value(index,"T",ds) * 3 + Value(index,"O",ds))/4)
        elseif data_type == "D" then	--Difference
            Out = (Value(index,"H",ds) - Value(index,"L", ds))
        end
    elseif data_type == "A" then	--Any
        Out = ds and ds[index]
    end
    return Out or 0
end

local function dsSize(data_type, ds)
    data_type = (data_type and string_upper(string_sub(data_type,1,1))) or "A"
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
    local arg       = math.sqrt(2)*pi/(0.5*period)
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
    local arg       = pi/(0.5*period)
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
    local save_bars = (settings.save_bars or period)

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
        ATR[index-save_bars] = nil
        l_index = index
        return ATR
    end
end

--[[Sum od values
sum(Pi)
]]
local function F_SUM(settings, ds)

    local period    = (settings.period or 9)
    local save_bars = (settings.save_bars or period)

    local S_ACC = {}
    local S_TMP = {}
    local bars    = 0
    local l_index
    return function(index, val)
        S_TMP[index]    = S_TMP[index-1] or 0
        if not CheckIndex(index, ds) then
            return S_TMP
        end
        S_ACC[#S_ACC + (l_index == index and 0 or 1)] = (S_ACC[#S_ACC - (l_index == index and 1 or 0)] or 0) + (val or 0)
        if l_index ~= index then
            l_index = index
            bars = bars + 1
        end
        if bars > period then
            if #S_ACC > period + 1 then table_remove(S_ACC, 1) end
            S_TMP[index] = S_ACC[#S_ACC] - (S_ACC[1] or 0)
        else
            S_TMP[index] = S_ACC[#S_ACC]
        end
        S_TMP[index-save_bars] = nil
        return S_TMP
    end
end

--[[Simple Moving Average (SMA)
SMA = sum(Pi) / n
]]
local function F_SMA(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local round     = (settings.round or "OFF")
    local scale     = (settings.scale or 0)
    local save_bars = (settings.save_bars or period)

    local fSum      = F_SUM(settings, ds)
    local SMA_TMP   = {}
    local bars      = 0
    local l_index
    return function(index)
        SMA_TMP[index]  = SMA_TMP[index-1] or 0
        local sum       = fSum(index, (Value(index, data_type, ds) or 0))[index]
        if not CheckIndex(index, ds) then
            return SMA_TMP
        end
        if l_index ~= index then
            l_index = index
            bars = bars + 1
        end
        bars            = bars < period and bars or period
        SMA_TMP[index]  = rounding(sum/bars, round, scale)
        SMA_TMP[index-save_bars] = nil
        return SMA_TMP
    end
end

--[[Произвольная Weighted Moving Average (LWMA) — Произвольная (функция)-взвешенная скользящая средняя
]]
local function F_LWMA(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local round     = (settings.round or "OFF")
    local scale     = (settings.scale or 0)
    local save_bars = (settings.save_bars or period)

    local lambda    = type(settings.weight_func) == 'function' and settings.weight_func or function(i) return i end
    local LWMA_TMP  = {}
    local bars      = 0
    local l_index
    return function(index)
        LWMA_TMP[index]  = LWMA_TMP[index-1] or 0
        local sum, n     = 0, 0
        if l_index ~= index then
            l_index = index
            bars = bars + 1
        end
        bars = bars < period and bars or period
        local w
        for i = 1, bars do
            if CheckIndex(index-bars+i, ds) then
                w   = lambda(i)
                sum = sum + (Value(index-bars+i, data_type, ds) or 0)*w
                n   = n + w
            end
        end
        LWMA_TMP[index]  = rounding(sum/n, round, scale)
        LWMA_TMP[index-save_bars] = nil
        return LWMA_TMP
    end
end

--[[Standard Deviation
]]
local function F_SD(settings, ds)

    local period        = (settings.period or 9)
    local data_type     = (settings.data_type or "Close")
    local round         = (settings.round or "OFF")
    local ma_method     = (settings.ma_method or 'SMA')
    local scale         = (settings.scale or 0)
    local save_bars     = (settings.save_bars or period)
    local not_shifted   = settings.not_shifted
    local calc_avg      = settings.calc_avg
    if calc_avg == nil then calc_avg = true end
    local fMA
    if calc_avg then
       fMA = M.new({period = period, data_type = data_type, method = ma_method, round = round, scale = scale}, ds)
    end
    local SD            = {}
    local input         = {}
    return function(index, avg)

        SD[index]       = SD[index-1] or 0
        input[index]    = input[index-1] or 0
        avg             = avg or fMA(index)
        if not CheckIndex(index, ds) then
            return SD, avg
        end
        input[index]    = Value(index, data_type, ds) or 0
        local sq = 0
        for i = index - period + 1, index do
            if input[i] then
                sq = sq + math_pow(input[i] - avg[index], 2)
            end
        end

        SD[index]   = math_sqrt(sq/(not_shifted and period or (period-1)))

        SD[index-save_bars]     = nil
        input[index-save_bars]  = nil
        return SD, avg
    end
end

--[[Fractal Adaptive Moving Average]]
local function F_FRAMA(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local round     = (settings.round or "OFF")
    local scale     = (settings.scale or 0)
    local save_bars = (settings.save_bars or (2*period))

    local bars      = 0
    local FRAMA_TMP = {}
    local h_buff    = {}
    local l_buff    = {}

    local HH        = function(index, length)
        return math_max(table_unpack(h_buff, index-length+1, index))
    end
    local LL        = function(index, length)
        return math_min(table_unpack(l_buff, index-length+1, index))
    end
    local N        = function(index, length)
        return (HH(index, length) - LL(index, length))/length
    end
    local D        = function(index)
        return (math_log(N(index, period) + N(index-period, period)) - math_log(N(index, 2*period)))/math_log(2)
    end
    local A        = function(index)
        return math_exp(-4.6*(D(index)-1))
    end
    local l_index
    return function(index)
        local val        = Value(index, data_type, ds)
        FRAMA_TMP[index] = FRAMA_TMP[index-1] or val
        h_buff[index]    = h_buff[index-1] or 0
        l_buff[index]    = l_buff[index-1] or 0
        if not CheckIndex(index, ds) then
            return FRAMA_TMP
        end
        h_buff[index] = Value(index, 'High', ds)
        l_buff[index] = Value(index, 'Low', ds)
        if l_index ~= index then
            l_index = index
            bars = bars + 1
        end
        if bars >= 2*period then
            local a = A(index)
            FRAMA_TMP[index] = rounding(a*val + (1-a)*FRAMA_TMP[index-1], round, scale)
        end
        FRAMA_TMP[index-save_bars] = nil
        return FRAMA_TMP
    end
end

--[[Exponential Moving Average (EMA)
EMAi = (EMAi-1*(n-1)+2*Pi) / (n+1)
]]
local function F_EMA(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local round     = (settings.round or "OFF")
    local scale     = (settings.scale or 0)
    local save_bars = (settings.save_bars or period)

    local EMA_TMP   = {}
    local val
    return function(index)
        EMA_TMP[index] = EMA_TMP[index-1] or 0
        if not CheckIndex(index, ds) then
            return EMA_TMP
        end
        val = Value(index, data_type, ds)
        EMA_TMP[index]  = EMA_TMP[index-1] and rounding((EMA_TMP[index-1]*(period-1) + 2*val)/(period+1), round, scale) or rounding(val, round, scale)
        EMA_TMP[index-save_bars] = nil
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
    local round     = (settings.round or "OFF")
    local scale     = (settings.scale or 0)
    local save_bars = (settings.save_bars or period)

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
        WMA_TMP[index-save_bars] = nil
        return WMA_TMP
    end
end

--[[
Hull Moving Average
HMA= LWMA(2*LWMA(n/2) ? LWMA(n)),sqrt(n))
]]
local function F_HMA(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local round     = (settings.round or "OFF")
    local scale     = (settings.scale or 0)
    local save_bars = (settings.save_bars or period)

    local fLwma     = F_LWMA({period = period, data_type = data_type}, ds)
    local fLwma2    = F_LWMA({period = M.rounding(period/2, 'on'), data_type = data_type}, ds)
    local swma      = {}
    local fHMA      = F_LWMA({period = M.rounding(math_sqrt(period), 'on'), data_type = 'Any'}, swma)

    local HMA_TMP = {}
    return function(index)
        HMA_TMP[index] = HMA_TMP[index-1] or 0
        if not CheckIndex(index, ds) then
            return HMA_TMP
        end
        if HMA_TMP[index-1] == nil then
            HMA_TMP[index] = rounding(Value(index, data_type, ds), round, scale)
        else
            swma[index]    = 2*fLwma2(index)[index] - fLwma(index)[index]
            HMA_TMP[index] = rounding(fHMA(index)[index], round, scale)
        end
        HMA_TMP[index-save_bars] = nil
        return HMA_TMP
    end
end

--[[Volume Adjusted Moving Average (VMA)
VMA = sum(Pi*Vi) / sum(Vi)
]]
local function F_VMA(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local round     = (settings.round or "OFF")
    local scale     = (settings.scale or 0)
    local save_bars = (settings.save_bars or period)

    local fSum      = F_SUM(settings, ds)
    local fSumV     = F_SUM(settings, ds)
    local VMA       = {}
    local VMA_ACC   = {}
    local VMA_VACC  = {}
    local bars      = 0
    local l_index
    return function (index)
        VMA[index]  = VMA[index-1] or 0
        if not CheckIndex(index, ds) then
            return VMA
        end
        local vol       = Value(index, "Volume", ds) or 0
        VMA_ACC[index]  = fSum(index, (Value(index, data_type, ds) or 0)*vol)[index]
        VMA_VACC[index] = fSumV(index, vol)[index]
        if l_index ~= index then
            l_index = index
            bars = bars + 1
        end
        if bars > period then
            local sum   = VMA_ACC[index] - (VMA_ACC[index-period] or 0)
            local sum_v = VMA_VACC[index] - (VMA_VACC[index-period] or 0)
            VMA[index] = sum_v == 0 and VMA[index] or rounding(sum/sum_v, round, scale)
        else
            VMA[index] = VMA_VACC[index] == 0 and VMA[index] or rounding(VMA_ACC[index]/VMA_VACC[index], round, scale)
        end
        VMA[index-save_bars] = nil
        return VMA
    end
end

--[[Smoothed Moving Average (SMMA)
SMMAi = (sum(Pi) - SMMAi-1 + Pi) / n
]]
local function F_SMMA(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local round     = (settings.round or "OFF")
    local scale     = (settings.scale or 0)
    local save_bars = (settings.save_bars or period)

    local SMMA_TMP  = {}
    local fSum      = F_SUM(settings, ds)
    local bars      = 0
    local l_index
    return function(index)
        SMMA_TMP[index] = SMMA_TMP[index-1] or 0
        local val       = (Value(index, data_type, ds) or 0)
        local sum       = fSum(index, val)[index]
        if not CheckIndex(index, ds) then
            return SMMA_TMP
        end
        if l_index ~= index then
            l_index = index
            bars = bars + 1
        end
        if bars <= period then
            SMMA_TMP[index] = rounding(sum/bars, round, scale)
        elseif bars > period then
            SMMA_TMP[index] = rounding((sum - SMMA_TMP[index-1] + val)/period, round, scale)
        end
        SMMA_TMP[index-save_bars] = nil
        return SMMA_TMP
    end
end

--[[The Triple Exponential Moving Average (TEMA)
TEMA = 3 * ema1 - 3 * ema2 + ema3
]]
local function F_TEMA(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local round     = (settings.round or "OFF")
    local scale     = (settings.scale or 0)
    local save_bars = (settings.save_bars or period)

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
        TEMA[index-save_bars] = nil
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
    local round         = (settings.round or "OFF")
    local scale         = (settings.scale or 0)
    local save_bars     = (settings.save_bars or period)

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
            fSUM(index, Delta[index])
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
        local sum       = fSUM(index, Delta[index])[index]
        local er        = sum == 0 and 1 or Delta[index]/sum
        local ssc       = math_pow(er*(fast_k - slow_k) + slow_k, 2)

        if AMA[index-1] == nil then
            AMA[index] = rounding(Value(index, data_type, ds), round, scale)
        else
            AMA[index] = rounding((Value(index, data_type, ds)*ssc - AMA[index-1])*(ssc) , round, scale)
            AMA[index] = rounding(AMA[index-1] + (Value(index, data_type, ds) - AMA[index-1])*ssc , round, scale)
        end
        AMA[index-save_bars] = nil

        l_index = index

        return AMA
     end
end

--[[The Reverse EMA Indicator by John F. Ehlers
]]
local function F_REMA(settings, ds)

    local alpha         = (settings.alpha or 0.1)
    local data_type     = (settings.data_type or "Close")
    local round         = (settings.round or "OFF")
    local scale         = (settings.scale or 0)
    local period        = (2/alpha) - 1
    local cc            = 1- alpha
    local save_bars     = (settings.save_bars or period)

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

        RE1[index-save_bars]    = nil
        RE2[index-save_bars]    = nil
        RE3[index-save_bars]    = nil
        RE4[index-save_bars]    = nil
        RE5[index-save_bars]    = nil
        RE6[index-save_bars]    = nil
        RE7[index-save_bars]    = nil
        RE8[index-save_bars]    = nil
        REMA[index-save_bars]   = nil

        return REMA
     end
end

--[[Elder's Force I ("EFI")
]]
local function F_EFI(settings, ds)

    local period    = (settings.period or 9)
    local data_type = (settings.data_type or "Close")
    local ma_method = (settings.ma_method or "EMA")
    local round     = (settings.round or "OFF")
    local scale     = (settings.scale or 0)
    local save_bars = (settings.save_bars or period)

    local fEFI
    local fi
    local EFI

    local p_data
    local l_index

    return function(index)

        if fEFI == nil then
            fi          = {}
            fEFI        = M.new({period = period, method = ma_method,   data_type = "Any", round = round, scale = scale}, fi)
            EFI         = {}
            fi[index]   = 0
            EFI[index]  = 0
            p_data      = Value(index, data_type, ds)
            l_index     = index
            return EFI
        end

        fi[index]       = fi[index-1]
        EFI[index]      = EFI[index-1]

        if not CheckIndex(index, ds) then
            fEFI(index - 1)
            fi[index-save_bars]  = nil
            EFI[index-save_bars] = nil
            return EFI
        end

        if index ~= l_index then p_data = Value(l_index, data_type, ds) end

        local cur   = Value(index, data_type, ds)
        fi[index-1] = (cur == 0 and 0 or (1 - p_data/cur) * Value(index, "Volume", ds))
        EFI[index]  = fEFI(index - 1)[index - 1]

        l_index     = index
        fi[index-save_bars]  = nil
        EFI[index-save_bars] = nil
        return EFI
     end
end

--[[WR (Williams' % Range)
]]
local function F_WRI(settings, ds)

    local period    = (settings.period or 9)
    local round     = (settings.round or "OFF")
    local scale     = (settings.scale or 0)
    local save_bars = (settings.save_bars or period) + 1

	local HH
	local LL
    local WRI
    local bars      = 0
    local l_index

    return function(index)

        if WRI == nil then
            HH          = {}
            HH[index]   = Value(index, "High", ds)
            LL          = {}
            LL[index]   = Value(index, "low", ds)
            WRI         = {}
            WRI[index]  = 0
            return WRI
        end

        HH[index]       = HH[index-1]
        LL[index]       = LL[index-1]
        WRI[index]      = WRI[index-1]

        if index ~= l_index then bars = bars + 1 end

        if not CheckIndex(index, ds) then
            WRI[index-save_bars] = nil
            HH[index-save_bars] = nil
            LL[index-save_bars] = nil
            return WRI
        end

        HH[index]   = Value(index, "High", ds)
        LL[index]   = Value(index, "low", ds)

        if bars <= period then
            WRI[index-save_bars] = nil
            HH[index-save_bars] = nil
            LL[index-save_bars] = nil
            return WRI
        end

        local vHH   = math_max(unpack(HH, index - period, index))
        local vLL   = math_min(unpack(LL, index - period, index))
        WRI[index]  = rounding(-100*(vHH-Value(index, "Close", ds))/(vHH-vLL), round, scale)
        l_index     = index

        WRI[index-save_bars] = nil
        HH[index-save_bars]  = nil
        LL[index-save_bars]  = nil
        return WRI
     end
end

--[[THV
]]
local function F_THV(settings, ds)

    local period        = (settings.period or 9)
    local koef          = (settings.koef or 1)
    local data_type     = (settings.data_type or "Close")
    local round         = (settings.round or "OFF")
    local scale         = (settings.scale or 0)
    local save_bars     = (settings.save_bars or period)

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

        gda_108[index-save_bars] = nil
        gda_112[index-save_bars] = nil
        gda_116[index-save_bars] = nil
        gda_120[index-save_bars] = nil
        gda_124[index-save_bars] = nil
        gda_128[index-save_bars] = nil
        THV[index-save_bars]     = nil
        return THV
     end
end

--[[Nick Rypock Trailing Reverse
]]
local function F_NRTR(settings, ds)
    local bufHigh
    local bufLow
    local NRTR
    local trend
    local reverse
    local begin_index

    settings        = (settings or {})
    local period    = (settings.period or 10)
    local k         = (settings.k or 0.5)
    local round     = (settings.round or "OFF")
    local scale     = (settings.scale or 0)
    local save_bars = (settings.save_bars or (settings.period or 10))


    return function(index)

        if NRTR == nil or index == begin_index then
            begin_index     = index
            NRTR = {}
            NRTR[index]     = Value(index, 'Close', ds) or 0
            reverse = {}
            reverse[index]  = Value(index, 'Close', ds) or 0
            trend   = {}
            trend[index]    = 0
            bufHigh = {}
            bufHigh[index]  = Value(index, 'High', ds) or 0
            bufLow = {}
            bufLow[index]   = Value(index, 'Low', ds) or math_huge
            return NRTR
        end

        NRTR[index]     = NRTR[index-1]
        bufHigh[index]  = bufHigh[index-1]
        bufLow[index]   = bufLow[index-1]
        trend[index]    = trend[index-1]
        reverse[index]  = reverse[index-1]

        if not CheckIndex(index, ds) then
            return NRTR, trend, reverse
        end

        bufHigh[index]  = Value(index, 'High', ds)
        bufLow[index]   = Value(index, 'Low', ds)

        if index - begin_index < period then return NRTR, trend, reverse end

        local val       = Value(index, 'Close', ds)

        if trend[index] >= 0 then
            local val_h     = math_max(unpack(bufHigh, index-period+1, index))
            reverse[index]  = math_max(val_h*(1-k/100), reverse[index-1])
			if val <= reverse[index] then
                reverse[index]  = val*(1+k/100)
                trend[index]    = -1
            end
            NRTR[index] = rounding(reverse[index], round, scale)
		elseif trend[index] < 0 then
            local val_l     = math_min(unpack(bufLow, index-period+1, index))
            reverse[index]  = math_min(val_l*(1+k/100), reverse[index-1])
			if val >= reverse[index] then
                reverse[index]  = val*(1-k/100)
                trend[index]    = 1
			end
            NRTR[index] = rounding(reverse[index], round, scale)
		end
        NRTR[index-save_bars]       = nil
        trend[index-save_bars]      = nil
        reverse[index-save_bars]    = nil
        return NRTR, trend, reverse
     end
end

--Nick Rypoсk Moving Average (NRMA)
local function F_NRMA(settings, ds)

    local k         = (settings.k or 0.5)
    local fast      = (settings.fast or 2)
    local sharp     = (settings.sharp or 2)
    local ma_period = (settings.ma_period or 3)
    local ma_method = (settings.ma_method or 'SMA')
    local round     = (settings.round or "OFF")
    local scale     = (settings.scale or 0)
    local calc_type = (settings.calc_type or 0)
    local save_bars = (settings.save_bars or ma_period)

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

        NRMA[index-save_bars] = nil

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
    local calc_buffer
    local nn = degree + 1
    local ai = {{1,2,3,4}, {1,2,3,4}, {1,2,3,4}, {1,2,3,4}}
	local b  = {}
	local x  = {}

    return function(index, recacl)


		if fx_buffer == nil or index == 1 then

            calc_buffer = {}
            fx_buffer   = {}
			sql_buffer  = {}
			sqh_buffer  = {}
            input       = {}
			--- sx
			sx={}
			-- sx[1] = period + 1
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

		if not recacl and calc_buffer[index] ~= nil then
			return fx_buffer, sqh_buffer, sql_buffer
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
			fx_buffer[index+n-period]=x[1] + sum
		end

        local sse = 0
        for n = 1, period do
            sse = sse + math_pow(fx_buffer[index+n-period] - input[n], 2)
        end

        sse = math_sqrt(sse/(period-1))*kstd

		for n = 1, period do
			sqh_buffer[index+n-period]=fx_buffer[index+n-period]+sse
			sql_buffer[index+n-period]=fx_buffer[index+n-period]-sse
		end

        calc_buffer[index] = true

		return fx_buffer, sqh_buffer, sql_buffer

	end

end

local function F_RENKO(settings, ds)

    local fATR
    local fMA
    local Renko_UP
    local Renko_DW

    local recalc_index
    local l_index
    local trend
    local begin_index
    local brick_bars    = 0
    local Brick         = {}
    local Data          = {}

    settings                = (settings or {})
    local brick_size        = (settings.br_size or 0)
    local period            = (settings.period or 0)
    local data_type         = (settings.data_type or 0)
    local recalc_brick      = (settings.recalc_brick or 0) == 1
    local min_recalc_brick  = (settings.min_recalc_brick or 0) == 1
    local shift_limit       = (settings.shift_limit or 0) == 1
    local std_ma_method     = (settings.std_ma_method or 'SMA')
    local scale             = (settings.scale or 0)
    local brick_type        = (settings.brickType or 'Std')
    local brick_koeff       = (brick_type ~='Fix' or brick_size == 0) and (settings.k or 1) or 1
    local save_bars         = (settings.save_bars or period)
    local get_bars          = settings.get_bars

    local Bars              = setmetatable({}, {__len = function(t) return t._NUM end})
    Bars._NUM               = 0
    if get_bars then
        Bars.C = function(self, index) return self[index].Close end
        Bars.O = function(self, index) return self[index].Open end
        Bars.H = function(self, index) return self[index].High end
        Bars.L = function(self, index) return self[index].Low end
        Bars.T = function(self, index) return self[index].Time end
        Bars.Size = function(self) return #self end
    end


    return function(index)

        if Renko_UP == nil or index == begin_index then

            begin_index     = index
            Renko_UP        = {}
            Renko_UP[index] = Value(index, 'High', ds) or 0
            Renko_DW        = {}
            Renko_DW[index] = Value(index, 'Low', ds) or 0
            if brick_type ~='Fix' or brick_size == 0 then
                if recalc_brick then
                    Brick[index]    = brick_koeff*(Renko_UP[index] - Renko_DW[index])
                    if brick_type == 'ATR' then
                        fATR        = M.new({period = period, method = 'ATR'}, ds)
                        fATR(index)
                    else
                        Data        = {}
                        Data[index] = Value(index, 'M', ds) or 0
                        fMA         = M.new({period = period, method = std_ma_method, data_type = 'Any'}, Data)
                        fMA(index)
                    end
                else

                    local bars      = {}
                    local data      = {}
                    local last_bar  = dsSize('Close', ds)

                    local calc_f
                    if brick_type == 'ATR' then
                        bars.C = function(self, i) return self[i].Close end
                        bars.O = function(self, i) return self[i].Open end
                        bars.H = function(self, i) return self[i].High end
                        bars.L = function(self, i) return self[i].Low end
                        bars.Size = function(self) return #self end
                        calc_f = M.new({period = period, method = 'ATR'}, bars)
                        for i = last_bar - 10*period, last_bar - 1 do
                            bars[#bars + 1] = {Open = Value(i, 'O', ds) or 0, Low = Value(i, 'L', ds) or 0, Close = Value(i, 'C', ds) or 0, High = Value(i, 'H', ds) or 0}
                            data[#data + 1] = calc_f(#bars)[#bars]
                        end
                    else
                        calc_f = M.new({period = period, method = 'SD', ma_method = std_ma_method, data_type = 'Any'}, bars)
                        for i = last_bar - 10*period, last_bar - 1 do
                            bars[#bars + 1] = Value(i, 'M', ds) or 0
                            data[#data + 1] = calc_f(#bars)[#bars]
                        end
                    end
                    Brick[index] = data[#data]*brick_koeff
                end
            else
                Brick[index] = brick_size/math_pow(10, scale)
            end
            l_index         = index
            trend           = {}
            trend[index]    = 0
            if get_bars then
                Bars[#Bars + 1]   = {index = index, Open = Renko_DW[index], Low = Renko_DW[index], Close = Renko_UP[index], High = Renko_UP[index], Time = Value(index, 'Time', ds)}
                Bars._NUM         = Bars._NUM + 1
            end
            return Renko_UP, Renko_DW, trend, Brick, Bars
        end

        if brick_type == 'Std' then
            Data[index] = Data[index-1]
        end
        Brick[index]    = Brick[index-1]
        Renko_UP[index] = Renko_UP[index-1]
        Renko_DW[index] = Renko_DW[index-1]
        trend[index]    = trend[index-1]

        local atr
        if brick_type == 'ATR' and recalc_brick then
            atr = fATR(index)[index] or Brick[index-1]
        end

        if not CheckIndex(index, ds) then
            return Renko_UP, Renko_DW, trend, Brick, Bars
        end

        local close_h = data_type == 0 and Value(index, 'Close', ds) or Value(index, 'High', ds)
        local close_l = data_type == 0 and Value(index, 'Close', ds) or Value(index, 'Low', ds)
        local close   = Value(index, 'Close', ds) > Value(index, 'Open', ds) and close_h or close_l

        if recalc_brick then
            if brick_type == 'Std' then
                Data[index] = Value(index, 'M', ds)
                atr         = Sigma(Data, fMA(index)[index] or close, index - period + 1, index) or Brick[index-1]
            end
            if l_index ~= index then
                brick_bars = brick_bars + 1
                if brick_bars > period then
                    recalc_index = index
                end
            end
            if recalc_index == index then
                brick_bars = 1
                Brick[index] = min_recalc_brick and math_min(brick_koeff*atr, Brick[index]) or brick_koeff*atr
                if shift_limit then
                    if trend[index] == -1 then Renko_UP[index] = math_min(Renko_UP[index-1], Renko_DW[index-1] + Brick[index]) end
                    if trend[index] == 1  then Renko_DW[index] = math_max(Renko_DW[index-1], Renko_UP[index-1] - Brick[index]) end
                end
            end
        end

        l_index = index

        if Brick[index-1] == 0 then return Renko_UP, Renko_DW, trend, Brick, Bars end

        if close > Renko_UP[index-1] + Brick[index-1] then

            local bricks = math_floor((close - Renko_UP[index-1])/Brick[index-1])
            for _ = 1, bricks - 1 do
                Renko_UP[index] = Renko_UP[index] + Brick[index-1]
                Renko_DW[index] = math_max(Renko_UP[index-1], Renko_UP[index] - Brick[index])
                if get_bars then
                    Bars[#Bars + 1] = {index = index, Open = Renko_DW[index], Low = Renko_DW[index], Close = Renko_UP[index], High = Renko_UP[index], Time = Value(index, 'Time', ds)}
                    Bars._NUM       = Bars._NUM + 1
                end
            end
            Renko_UP[index] = Renko_UP[index] + Brick[index-1]

            Brick[index]    = recalc_brick and brick_koeff*atr or Brick[index-1]
            Renko_DW[index] = math_max(Renko_UP[index-1], Renko_UP[index] - Brick[index])
            if get_bars then
                Bars[#Bars + 1] = {index = index, Open = Renko_DW[index], Low = Renko_DW[index], Close = Renko_UP[index], High = Renko_UP[index], Time = Value(index, 'Time', ds)}
                Bars._NUM       = Bars._NUM + 1
            end
            trend[index]  = 1
		end
		if close < Renko_DW[index-1] - Brick[index-1] then

            local bricks    = math_floor((Renko_DW[index-1] - close)/Brick[index-1])
            for _ = 1, bricks-1 do
                Renko_DW[index] = Renko_DW[index] - Brick[index-1]
                Renko_UP[index] = math_min(Renko_DW[index-1], Renko_DW[index] + Brick[index])
                if get_bars then
                    Bars[#Bars + 1] = {index = index, Open = Renko_UP[index], Low = Renko_DW[index], Close = Renko_DW[index], High = Renko_UP[index], Time = Value(index, 'Time', ds)}
                    Bars._NUM       = Bars._NUM + 1
                end
            end

            Renko_DW[index] = Renko_DW[index] - Brick[index-1]
            Brick[index]    = recalc_brick and brick_koeff*atr or Brick[index-1]
            Renko_UP[index] = math_min(Renko_DW[index-1], Renko_DW[index] + Brick[index])
            if get_bars then
                Bars[#Bars + 1] = {index = index, Open = Renko_UP[index], Low = Renko_DW[index], Close = Renko_DW[index], High = Renko_UP[index], Time = Value(index, 'Time', ds)}
                Bars._NUM       = Bars._NUM + 1
            end
            trend[index]  = -1
        end
        Renko_UP[index-save_bars] = nil
        Renko_DW[index-save_bars] = nil
        trend[index-save_bars]    = nil
        Brick[index-save_bars]    = nil
        if brick_type == 'Std' then
            Data[index-save_bars]     = nil
        end

        return Renko_UP, Renko_DW, trend, Brick, Bars
     end, Bars
end

--Moving Average Convergence/Divergence ("MACD")
local function F_MACD(settings, ds)

    settings            = (settings or {})

    local ma_method     = (settings.ma_method or "EMA")
    local short_period  = (settings.short_period or 12)
    local long_period   = (settings.long_period or 26)
    local signal_method = (settings.signal_method or "SMA")
    local signal_period = (settings.signal_period or 9)
    local percent       = (settings.percent or 'on')
    local data_type     = (settings.data_type or "Close")
    local round         = (settings.round or "OFF")
    local scale         = (settings.scale or 0)
    local save_bars     = (settings.save_bars or math_max(long_period, short_period, signal_period))
    local begin_index   = 1

    local trend         = {}

    percent             = (percent:lower() ~= 'on')

    if (signal_method~="SMA") and (signal_method~="EMA") then signal_method = "SMA" end

    local t_MACD    = {0}
    local s_MACD    = {0}

    local MACD_MA   = M.new({period = signal_period, method = signal_method,   data_type = "Any",      round = round, scale = scale}, t_MACD)
	local Short_MA  = M.new({period = short_period,  method = ma_method,       data_type = data_type,  round = round, scale = scale}, ds)
	local Long_MA   = M.new({period = long_period,   method = ma_method,       data_type = data_type,  round = round, scale = scale}, ds)

    return function (index)
        if t_MACD[index-1] == nil then begin_index = index end

        t_MACD[index] = t_MACD[index-1] or 0
        s_MACD[index] = s_MACD[index-1] or 0
		trend[index]  = trend[index-1] or 1

        local So = Short_MA(index)
        local Lo = Long_MA(index)
        local i  = (index - begin_index) - math_max(short_period, long_period) + 1

        if (i > 0) then
            if percent then
                t_MACD[index] = rounding(100*(So[index] - Lo[index])/Lo[index], round, scale)
            else
                t_MACD[index] = rounding(So[index] - Lo[index], round, scale)
            end
            s_MACD[index] = MACD_MA(index)[index]
            trend[index]  = s_MACD[index] >= 0 and 1 or -1
        end
        t_MACD[index - save_bars] = nil
        s_MACD[index - save_bars] = nil
		trend[index - save_bars]  = nil
        return t_MACD, s_MACD, trend
    end, t_MACD, s_MACD, trend
end

-- Bollinger Bands
local function F_BOL(settings, ds)

    settings            = (settings or {})

    local ma_method     = (settings.ma_method or "SMA")
    local period        = (settings.period or 20)
    local k_std         = (settings.k_std or 2)
    local data_type     = (settings.data_type or "Close")
    local round         = (settings.round or "OFF")
    local scale         = (settings.scale or 0)
    local save_bars     = (settings.save_bars or period)
    local begin_index   = 1

    if (ma_method~="SMA") and (ma_method~="EMA") then ma_method = "SMA" end

    local bb_up         = {}
    local bb_dw         = {}

    local BOL_SDMA      = M.new({method = "SD", ma_method = ma_method, not_shifted = true, data_type = data_type, period = period, round = round, scale = scale}, ds)

    return function (index)
        if bb_up[index-1] == nil then begin_index = index end

        bb_up[index] = bb_up[index-1] or 0
        bb_dw[index] = bb_dw[index-1] or 0

        local bb_sd, bb_ma  = BOL_SDMA(index)

        local i  = (index - begin_index) - period + 1

        if (i > 0) then
            local bb      = (bb_ma or {})[index] or 0
            local bb_sdma = (bb_sd or {})[index] or 0
            bb_dw[index]  = rounding(bb - k_std*bb_sdma, round, scale)
            bb_up[index]  = rounding(bb + k_std*bb_sdma, round, scale)
        end

        bb_up[index - save_bars] = nil
        bb_dw[index - save_bars] = nil
        bb_ma[index - save_bars] = nil
        return bb_up, bb_dw, bb_ma
    end
end

-- Stochastic oscillator
local function F_STOCH(settings, ds)

    settings            = (settings or {})

    local ma_method     = (settings.ma_method or "SMA")
    local period        = (settings.period or 5)
    local shift         = (settings.shift or 3)
    local period_d      = (settings.period_d or 3)
    local method_d      = (settings.method_d or "SMA")
    local round         = (settings.round or "OFF")
    local scale         = (settings.scale or 0)
    local save_bars     = (settings.save_bars or math_max(period_d, period, shift))
    local begin_index   = 1

	local high_buff = {}
	local low_buff  = {}

    local range_hl  = {}
    local range_cl  = {}
	local stoch     = {}

    local RHL_MA    = M.new({period = shift,    method = ma_method,   data_type = "Any", round = round, scale = scale}, range_hl)
	local RCL_MA    = M.new({period = shift,    method = ma_method,   data_type = "Any", round = round, scale = scale}, range_cl)
	local DMA       = M.new({period = period_d, method = method_d,    data_type = "Any", round = round, scale = scale}, stoch)

    return function (index)
        if stoch[index-1] == nil then begin_index = index end

		high_buff[index]    = M.Value(index, "H", ds) or high_buff[index-1]
		low_buff[index]     = M.Value(index, "L", ds) or low_buff[index-1]
        stoch[index]        = stoch[index-1] or 0
        range_hl[index]     = range_hl[index-1] or 0
        range_cl[index]     = range_cl[index-1] or 0

        if not M.CheckIndex(index, ds) then
            RHL_MA(index)
            RCL_MA(index)
            return stoch, DMA(index)
        end

        local HH            = math_max(unpack(high_buff, math_max(index-period+1, begin_index),index))
        local LL            = math_min(unpack(low_buff,  math_max(index-period+1, begin_index),index))

        range_hl[index]     = HH - LL
        range_cl[index]     = M.Value(index, "C", ds) - LL
        local rcl           = RCL_MA(index)[index]
        local rhl           = RHL_MA(index)[index]
        stoch[index]        = rounding(rcl*100/rhl, round, scale)

        stoch[index-save_bars]      = nil
        high_buff[index-save_bars]  = nil
        low_buff[index-save_bars]   = nil
        range_hl[index-save_bars]   = nil
        range_cl[index-save_bars]   = nil

        return stoch, DMA(index)
    end
end

---@param settings table
---@param ds table
local function F_RSI(settings, ds)

    settings            = (settings or {})

    local period        = (settings.period or 14)
    local data_type     = (settings.data_type or "Close")
    local save_bars     = (settings.save_bars or period)
    local round         = (settings.round or "OFF")
    local scale         = (settings.scale or 0)

    local RSI
	local Up
	local Down
	local val_Up
	local val_Down

    local prev_index    = 0
    local last_index    = 0
    local begin_index   = 0

    return function(index)

        if RSI == nil or index == begin_index then

            begin_index = index

            RSI         = {}
            Up          = {}
            Down        = {}
            val_Up      = {}
            val_Down    = {}

            RSI[index]  = 0
            Up[index]   = 0
            Down[index] = 0
            prev_index  = index
            begin_index = index
            last_index  = index
            return RSI
        end

        RSI[index]  = RSI[index-1]
        Up[index]   = Up[index-1]
        Down[index] = Down[index-1]

        if not M.CheckIndex(index, ds) then return RSI end
        if last_index ~= index then
            prev_index = last_index
        end

        local val       = M.Value(index, data_type, ds)
        local prev_val  = M.Value(prev_index, data_type, ds)
        if prev_val < val then
            Up[index] = val - prev_val
        else
            Up[index] = 0
        end
        if prev_val > val then
            Down[index] = prev_val - val
        else
            Down[index] = 0
        end

        local calc = index - begin_index + 1

        if (calc == period) or (calc == period+1) then
            local sumU = 0
            local sumD = 0
            for i = index-period+1, index do
                sumU = sumU + Up[i]
                sumD = sumD + Down[i]
            end
            val_Up[index]   = sumU/period
            val_Down[index] = sumD/period
        end
        if calc > period+1 then
            val_Up[index]   = (val_Up[prev_index] * (period-1) + Up[index]) / period
            val_Down[index] = (val_Down[prev_index] * (period-1) + Down[index]) / period
        end
        if calc >= period then
            RSI[index] = rounding(100 / (1 + (val_Down[index] / val_Up[index])), round, scale)
        end

        last_index = index

        RSI[index - save_bars]         = nil
        val_Up[index - save_bars]      = nil
        val_Down[index - save_bars]    = nil
        Up[index - save_bars]          = nil
        Down[index - save_bars]        = nil

        return RSI
    end
end

---@param settings table
---@param ds table
local function F_CCI(settings, ds)

    settings            = (settings or {})

    local ma_method     = (settings.ma_method or "EMA")
    local period        = (settings.period or 20)
    local data_type     = (settings.data_type or "Close")
    local round         = (settings.round or "OFF")
    local scale         = (settings.scale or 0)
    local save_bars     = (settings.save_bars or period)
    local begin_index   = 1

    if (ma_method~="SMA") and (ma_method~="EMA") then ma_method = "EMA" end

    local cci           = {}
    local MA            = M.new({method = ma_method, data_type = data_type, period = period, round = round, scale = scale}, ds)

    return function (index)
        if cci[index-1] == nil then begin_index = index end

        cci[index]      = cci[index-1] or 0
        local ma_val    = (MA(index) or {})[index] or 0
        local i         = (index - begin_index) - period + 1

        if (i >= 0) and ma_val then
            local md = 0
            for ind = index-period+1, index do
                md = md + math_abs(ma_val - M.Value(ind, data_type, ds))
            end
            cci[index]  = rounding((M.Value(index, data_type, ds) - ma_val)/(md*0.015/period), round, scale)
        end

        cci[index - save_bars] = nil
        return cci
    end
end

local function F_SAR(settings, ds)

    settings            = (settings or {})

    local period        = (settings.period or 21)
    local dev           = (settings.dev or 3)
    local save_bars     = (settings.save_bars or period)
    local round         = (settings.round or "OFF")
    local scale         = (settings.scale or 0)

    local cache_H   = nil
	local cache_L   = nil
	local H_index   = nil
	local L_index   = nil
	local cache_SAR = nil
	local trend     = nil
	local AMA2      = nil
	local CC        = nil
	local CC_N      = nil
	local ATR       = nil
	local signal    = nil
    local last_zz   = nil
    local wave_data
    local ZZZ
    local begin_index

	return function(index)

		if cache_H == nil then
            begin_index  = index
            cache_H     = {}
			cache_L     = {}
			H_index     = {}
			L_index     = {}
			cache_SAR   = {}
			trend       = {}
			AMA2        = {}
			CC          = {}
			CC_N        = {}
			ATR         = {}
			signal      = {}
            wave_data   = {}

			CC[index]           = ds:C(index)
			CC_N[index]         = (ds:C(index) + ds:H(index) + ds:L(index))/3
			cache_H[index]      = ds:H(index)
			cache_L[index]      = ds:L(index)
			cache_SAR[index]    = rounding(ds:L(index) - 2*(ds:H(index) - ds:L(index)), round, scale)
			AMA2[index]         = (ds:C(index) + ds:O(index))/2
			trend[index]        = 1
			ATR[index]          = math_abs(ds:H(index) - ds:L(index))
            wave_data.max       = ds:H(index)
            wave_data.min       = ds:L(index)
            last_zz             = wave_data[trend[index] == 1 and 'max' or 'min']
			return cache_SAR, trend, signal, last_zz
		end
		------------------------------
		trend[index]        = trend[index-1]
		cache_H[index]      = cache_H[index-1]
		cache_L[index]      = cache_L[index-1]
        H_index[index]      = H_index[index-1]
        L_index[index]      = L_index[index-1]
        ATR[index]          = ATR[index-1]
		cache_SAR[index]    = cache_SAR[index-1]
		CC[index]           = CC[index-1]
		AMA2[index]         = AMA2[index-1]
        CC_N[index]         = CC_N[index-1]
        signal[index]       = signal[index-1]

		trend[index - save_bars]        = nil
		cache_H[index - save_bars]      = nil
		cache_L[index - save_bars]      = nil
		ATR[index - save_bars]          = nil
		cache_SAR[index - save_bars]    = nil
		CC[index - save_bars]           = nil
		AMA2[index - save_bars]         = nil
        CC_N[index - save_bars]         = nil
        signal[index - save_bars]       = nil

        if not ds:C(index) then return cache_SAR, trend, signal, last_zz end

		ZZZ                 = math_max(math_abs(ds:H(index) - ds:L(index)), math_abs(ds:H(index) - ds:C(index-1)), math_abs(ds:L(index) - ds:C(index-1)))
        ATR[index]          = (ATR[index-1]*(period-1) + ZZZ)/period
		CC[index]           = ds:C(index)
		AMA2[index]         = (2/(period/2+1))*CC[index] + (1-2/(period/2+1))*AMA2[index-1]
		CC_N[index]         = (ds:C(index) - AMA2[index])/2 + AMA2[index]

        if index - begin_index == 2 then
			return cache_SAR, trend, signal, last_zz
		end

        if trend[index] == 1 then

			if cache_H[index] < CC[index] then
				cache_H[index]  = CC[index]
                H_index[index]  = index
			end

            cache_SAR[index] = math_max((cache_H[index]-ATR[index]*dev), cache_SAR[index-1])

            if (cache_SAR[index] > CC_N[index])and(cache_SAR[index] > ds:C(index)) then
				trend[index]        = -1
				cache_L[index]      = CC[index]
				L_index[index]      = index
				signal[index]       = cache_SAR[index]
                cache_SAR[index]    = rounding(cache_L[index]+ATR[index]*dev, round, scale)
			end

        elseif trend[index] == -1 then

            if cache_L[index] > CC[index] then
				cache_L[index]  = CC[index]
                L_index[index]  = index
			end

            cache_SAR[index] = math_min((cache_L[index]+ATR[index]*dev), cache_SAR[index-1])

            if (cache_SAR[index] < CC_N[index]) and (cache_SAR[index] < ds:C(index)) then
				trend[index]        = 1
				cache_H[index]      = CC[index]
				H_index[index]      = index
				signal[index]       = cache_SAR[index]
				cache_SAR[index]    = rounding(cache_H[index]-ATR[index]*dev, round, scale)
			end
		end

        if trend[index] == trend[index-1] then
            wave_data.max   = math.max(ds:H(index), wave_data.max or ds:H(index))
            wave_data.min   = math.min(ds:L(index), wave_data.min or ds:L(index))
        end
        if trend[index] ~= trend[index-1] then
            last_zz       = wave_data[trend[index-1] == 1 and 'max' or 'min']
            wave_data.max = ds:H(index)
            wave_data.min = ds:L(index)
        end

        return cache_SAR, trend, signal, last_zz
	end
end

local function F_VWAP(settings, ds)

    if not ds then return false, 'Не задан ТФ расчета VWAP' end

    settings                = settings or {}

    local quant_interval    = settings.quant_interval or 60
    local data_type         = settings.data_type or 'Typical'
    local ema_period        = settings.ema_period or 14
    local s_begin_time      = settings.s_begin_time or ''
    local s_end_time        = settings.s_end_time or ''
    local save_bars         = settings.save_bars or ema_period
    local round             = settings.round or "OFF"
    local scale             = settings.scale or 0

    local VWAP, vEMA

    local fVMA
    local fEMA

    local day_shift         = 24*60*60
    local quant_shift       = quant_interval*60
    local index_time        = 0
    local end_calc_time
    local begin_time        = 0
    local end_time          = 0
    local Bars              = setmetatable({}, {__len = function(t) return t._NUM end})

    Bars.interval           = quant_interval
    Bars._NUM               = 0
    Bars.C = function(self, index) return self[index].Close end
    Bars.O = function(self, index) return self[index].Open end
    Bars.H = function(self, index) return self[index].High end
    Bars.L = function(self, index) return self[index].Low end
    Bars.T = function(self, index) return self[index].Time end
    Bars.Size = function(self) return #self end

    local function get_filter_time(sdt)
        if quant_interval ~= 1440 then return end
        begin_time  = s_begin_time == '' and 0 or os_time(GetStringTime(s_begin_time, sdt))
        end_time    = s_end_time == '' and 0 or os_time(GetStringTime(s_end_time, sdt))
        if end_time ~= 0 and end_time < begin_time then end_time = end_time + day_shift end
    end

    local function get_interval_time(sdt)

        sdt.sec = 0
        if quant_interval > 1 and quant_interval <= 60 then
            sdt.min = math_floor(sdt.min/quant_interval)*quant_interval
        end

        if quant_interval == 1440 and begin_time ~= 0 then
            sdt = os_date('*t', begin_time)
        end
        if quant_interval > 60 and (quant_interval ~= 1440 or begin_time == 0) then
            local bar_time = os_time(sdt)
            sdt.hour = 0; sdt.min  = 0
            local day_begin_time = os_time(sdt)
            bar_time = day_begin_time + math_floor((bar_time - day_begin_time)/quant_shift)*quant_shift
            sdt = os_date('*t', bar_time)
        end
        return sdt
    end

    local function check_in_time()
        if quant_interval ~= 1440 or (begin_time == 0 and end_time == 0) then return true end
        return index_time >= begin_time and (end_time == 0 or index_time < end_time)
    end

    local index = 0

    local function new_index(bar)

        get_filter_time(Value(bar, 'Time', ds))

        Bars[#Bars + 1]   = {bar = bar, Open = M.Value(bar, 'O', ds), Low = M.Value(bar, 'L', ds), Close = M.Value(bar, 'C', ds), High = M.Value(bar, 'H', ds), Time = get_interval_time(Value(bar, 'Time', ds))}
        Bars._NUM         = Bars._NUM + 1
        index             = Bars._NUM

        end_calc_time     = end_time ~= 0 and end_time or (os_time(Bars[#Bars].Time) + quant_shift)

        fVMA = F_VMA({period = quant_interval, method = 'VMA', data_type = data_type, round = round, scale = scale}, ds)
        VWAP[index]       = M.Value(bar, data_type, ds) or 0
        VWAP[index - save_bars] = nil
    end

    return function(ds_index)

        index_time = os_time(ds:T(ds_index))

        if VWAP == nil then
            if not is_date(ds:T(ds_index)) then return end
            VWAP            = {}
            vEMA            = {}
            new_index(ds_index)
            if check_in_time() then fVMA(ds_index) end
            VWAP[index]     = M.Value(index, data_type, ds) or 0
            fEMA            = M.new({period = ema_period, method = 'EMA', data_type = 'Any', round = round, scale = scale}, VWAP)
            vEMA[index]     = fEMA(index)[index]
            return VWAP, vEMA
        end

        if (index_time >= end_calc_time) then
            new_index(ds_index)
        end

        if index_time < end_calc_time and check_in_time() then
            Bars[Bars._NUM].Low     = math_min(Bars[Bars._NUM].Low, M.Value(ds_index, 'L', ds))
            Bars[Bars._NUM].Close   = M.Value(ds_index, 'C', ds)
            Bars[Bars._NUM].High    = math_max(Bars[Bars._NUM].Low, M.Value(ds_index, 'H', ds))
            VWAP[index] = rounding(fVMA(ds_index)[ds_index] or VWAP[index], round, scale)
            vEMA[index] = rounding(fEMA(index)[index], round, scale)
        end

        return VWAP, vEMA
    end, Bars
end

---@param offset table
-- offset.type      = Тип отсутпа: '%' - в процентах, 'Price' - в шагах цены
-- offset.calc_kind = Вид расчета 'Range' - как процент от прошлой волны, 'Extr' - как отступ в цене от прошлого экстремума; ATR - по пробитю канала ATR
-- offset.value     = Значение отступа выраженное в цене инструмента или в процентах
local function F_ZZ(offset, ds)

    if offset.calc_kind == 'Range' and offset.type ~= '%' then
        local mes = 'Некорректно заданы настройки. Для вида расчета "range", тип отступа должен быть "%"'
        return false, mes
    end

    local depth         = offset.depth or 24
    local atr_type      = offset.calc_kind == 'ATR'
    local range_type    = offset.calc_kind == 'Range'
    local steps_offset  = offset.type == 'Steps'
    local perc_offset   = offset.type == '%'

    local zz_levels   = {}
    local l_buff      = {}
    local h_buff      = {}

    local last_high   = {}
    local last_low    = {}

    local last_max
    local last_min
    local trend       = {}
    local atr

    local ATR
    if atr_type then
        ATR = F_ATR({period = depth}, ds)
    end

    local offset_price
    local function calc_offset_price(val, sign, range)
        if range_type and range > 0 then
            return val + sign*range*offset.value/100
        end
        if atr_type and range > 0 then
            return val + sign*range*offset.value
        end
        if perc_offset then
            return (1 + sign*offset.value/100)*val
        end
        if steps_offset then
            return val + sign*offset.value
        end
    end

    local function check_trend_change(sign, price, close)
        return sign*(price - offset_price) < 0 and sign*(close - offset_price) < 0
    end

    local count_index = {}

    local bars = 0

    local function UpdateZZ(data, shift)
        zz_levels[#zz_levels + (shift or 0)] = zz_levels[#zz_levels + (shift or 0)] or {}
        zz_levels[#zz_levels].val       = data.val
        zz_levels[#zz_levels].time      = data.time
        zz_levels[#zz_levels].time_rep  = os_date('%d.%m.%Y %H:%M:%S',  data.time)
        zz_levels[#zz_levels].index     = data.index
    end

    local function update_last(last_val, new_val, index, time, shift)
        last_val.val    = new_val
        last_val.time   = time
        last_val.index  = index
        local range     = atr_type and atr[index] or (last_max.val - last_min.val)
        offset_price    = calc_offset_price(last_val.val, -trend[index], range)
        UpdateZZ(last_val, shift or 0)
    end

    ---@param new_high number
    ---@param new_low number
    return function (new_high, new_low, close, time, index, online)

        local status, res1, res2, res3 = pcall(function()

            if atr_type then
                atr = ATR(index)
            end

            if not last_max or not last_min then
                last_min        = last_min or {val = new_low, time = time, index = index, trend = -1}
                last_max        = last_max or {val = new_high, time = time, index = index, trend = 1}
                offset_price    = calc_offset_price(new_high, -1, atr_type and atr[index] or (last_max.val - last_min.val))
            end

            if count_index[index] == 2 or online then
                if trend[index] == 1 and new_high > last_max.val then
                    update_last(last_max, new_high, index, time)
                end
                if trend[index] == -1 and new_low < last_min.val then
                    update_last(last_min, new_low, index, time)
                end
                return zz_levels, trend, (trend[index] == 1 and last_max or last_min)
            end

            if not count_index[index] then bars = bars + 1 end

            count_index[index]  = 1

            l_buff[index]       = new_low
            h_buff[index]       = new_high
            trend[index]        = trend[index - 1] or 1
            last_low[index]     = last_low[index - 1]
            last_high[index]    = last_high[index - 1]

            if bars <= depth then return zz_levels, trend, (trend[index] == 1 and last_max or last_min) end

            if trend[index] == 1 then
                if new_high and new_high > last_max.val then
                    update_last(last_max, new_high, index, time)
                    return zz_levels, trend, (trend[index] == 1 and last_max or last_min)
                end
            end

            if trend[index] == -1 then
                if new_low and new_low < last_min.val then
                    update_last(last_min, new_low, index, time)
                    return zz_levels, trend, (trend[index] == 1 and last_max or last_min)
                 end
            end

                -- if offset.calc_kind ~= 'Range' then
                local r_high    = math_max(unpack(h_buff, index - depth + 1, index))
                local r_low     = math_min(unpack(l_buff, index - depth + 1, index))

                if r_high == last_high[index] then
                    r_high = nil
                else
                    last_high[index] = r_high
                end
                if r_low == last_low[index] then
                    r_low = nil
                else
                    last_low[index] = r_low
                end

                if r_high ~= new_high then
                    new_high = nil
                end
                if r_low ~= new_low then
                    new_low = nil
                end
            -- end

            if trend[index] == 1 then
                if new_low and check_trend_change(trend[index], new_low, close) then
                    count_index[index]  = 2
                    trend[index]        = -1
                    update_last(last_min, new_low, index, time, 1)
                    return zz_levels, trend, last_min
                end
            end

            if trend[index] == -1 then
                if new_high and check_trend_change(trend[index], new_high, close) then
                    count_index[index]  = 2
                    trend[index]        = 1
                    update_last(last_max, new_high, index, time, 1)
                end
            end

            count_index[index-1]    = nil
            trend[index-2]          = nil
            last_low[index-2]       = nil
            last_high[index-2]      = nil
            h_buff[index - depth]   = nil
            l_buff[index - depth]   = nil

            return zz_levels, trend, (trend[index] == 1 and last_max or last_min)

        end)
        if not status then return 'ZZ_Processor : '..tostring(res1) end
        return res1, res2, res3
    end
end

local FUNCTOR = {
    SMA     = F_SMA,
    EMA     = F_EMA,
    SD      = F_SD,
    VMA     = F_VMA,
    SMMA    = F_SMMA,
    WMA     = F_WMA,
    LWMA    = F_LWMA,
    HMA     = F_HMA,
    TEMA    = F_TEMA,
    FRAMA   = F_FRAMA,
    AMA     = F_AMA,
    EFI     = F_EFI,
    WRI     = F_WRI,
    ATR     = F_ATR,
    THV     = F_THV,
    NRTR    = F_NRTR,
    NRMA    = F_NRMA,
    REG     = F_REG,
    REMA    = F_REMA,
    RENKO   = F_RENKO,
    MACD    = F_MACD,
    STOCH   = F_STOCH,
    RSI     = F_RSI,
    CCI     = F_CCI,
    BOL     = F_BOL,
    SAR     = F_SAR,
    VWAP    = F_VWAP,
    ZZ      = F_ZZ
}
M.ALGO_LINES = {
    SMA     = {'SMA'},
    EMA     = {'EMA'},
    SD      = {'SD'},
    VMA     = {'VMA'},
    SMMA    = {'SMMA'},
    WMA     = {'WMA'},
    LWMA    = {'LWMA'},
    HMA     = {'HMA'},
    TEMA    = {'TEMA'},
    FRAMA   = {'FRAMA'},
    AMA     = {'AMA'},
    EFI     = {'EFI'},
    WRI     = {'WRI'},
    ATR     = {'ATR'},
    THV     = {'THV'},
    NRTR    = {'NRTR', 'TREND', 'REVERSE'},
    NRMA    = {'NRMA', 'NRTR'},
    REG     = {'REG', 'UP_REG', 'DW_REG'},
    REMA    = {'REMA'},
    RENKO   = {'RENKO_UP', 'RENKO_DW', 'TREND', 'BRICK', 'BARS'},
    MACD    = {'MACD', 'S_MACD', 'TREND'},
    STOCH   = {'STOCH'},
    RSI     = {'RSI'},
    CCI     = {'CCI'},
    BOL     = {'BOL_UP', 'BOL_DW', 'BOL_MID'},
    SAR     = {'SAR', 'TREND', 'SIGNAL', 'LAST_ZZ'},
    VWAP    = {'VWAP', 'VEMA'},
    ZZ      = {'ZZ', 'TREND', 'LAST_EXTR'}
}

M.AV_METHODS = ''
for key in pairs(FUNCTOR) do
    M.AV_METHODS = M.AV_METHODS..(M.AV_METHODS == '' and '' or '|')..key
end

local function MA(settings, ds, ...)

    settings = (settings or {})
    local method    = (settings.method or "EMA")

    if not FUNCTOR[method] then
        return nil, 'Не удалось инициализировать MA. Допустимые типы: '..M.AV_METHODS..', передано: '..tostring(settings.method)
    end

    return FUNCTOR[method](settings, ds, ...)
end

M.new         = MA
M.Slice       = Slice
M.Sum         = Sum
M.wSum        = wSum
M.Sigma       = Sigma
M.Normalize   = Normalize
M.Correlation = Correlation
M.EthlerAlpha = EthlerAlpha
M.Get2PoleSSF = Get2PoleSSF
M.Get3PoleSSF = Get3PoleSSF

M.is_date     = is_date
M.CheckIndex  = CheckIndex
M.rounding    = rounding
M.GetIndex    = GetIndex
M.Value       = Value
M.dsSize      = dsSize

return M