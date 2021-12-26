--[[
	nick-h@yandex.ru
	https:--github.com/nick-nh/qlua

    Autocorrelation Periodogram by John F. Ehlers
]]

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\autocorr.txt", "w")

local math_max    = math.max
local math_pi     = math.pi
local math_abs    = math.abs
local math_exp    = math.exp
local math_cos    = math.cos
local math_sqrt   = math.sqrt
local math_sin    = math.sin
local math_pow    = function(x, y) return x^y end
local os_time     = os.time
local O           = _G['O']
local C           = _G['C']
local H           = _G['H']
local L           = _G['L']
local V           = _G['V']

local SetValue    = _G['SetValue']


_G.Settings =
{
    Name = "*AutoCorr",
    avg_length      = 3,
    enh_resolution  = 0,
    value_type      = "C",
    line =  {
                {
                 Name = "AC",
                 Color = _G.RGB(80, 140, 240),
                 Type = _G.TYPE_LINE,
                 Width = 2
                }
            }
}

local PlotLines     = function(index) return index end
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

local function dValue(i,param)
    local v = param or "C"
	if  v == "O" then
		return O(i)
	elseif   v == "H" then
		return H(i)
	elseif   v == "L" then
		return L(i)
	elseif   v == "C" then
		return C(i)
	elseif   v == "V" then
		return V(i)
	elseif   v == "M" then
		return (H(i) + L(i))/2
	elseif   v == "T" then
		return (H(i) + L(i)+C(i))/3
	elseif   v == "W" then
		return (H(i) + L(i)+2*C(i))/4
	elseif   v == "ATR" then
		return math_max(math_abs(H(i) - L(i)), math_abs(H(i) - C(i-1)), math_abs(C(i-1) - L(i)))
	else
		return C(i)
	end
end

local function AutoCorr(Fsettings)

    Fsettings               = (Fsettings or {})
    local avg_length        = Fsettings['avg_length'] or 3
    local enh_resolution    = Fsettings['enh_resolution'] or 0
    local v_type            = Fsettings['v_type'] or 'Close'

    local cache

    --Highpass Filter and SuperSmoother Filter together form a Roofing Filter
    local alpha1 = (1 - math_sin(360/48))/math_cos(360/48);

    --Smooth with a SuperSmoother Filter
    local s2 = math_sqrt(2)
    local a1 = math_exp(-s2*math_pi/8);
    local b1 = 2*a1*math_cos(s2*180/8);
    local c2 = b1;
    local c3 = -a1*a1;
    local c1 = 1 - c2 - c3;

    local acp   = {}
    local hp    = {}
    local filt  = {}
    error_log   = {}
    local begin_index

    return function(ind)

        local status, res = pcall(function()

            if not cache or ind == begin_index then
                cache       = {}
                begin_index = ind
                return
            end

            local index = ind-1

            if cache[index] then return cache[index] end

            local val   = dValue(index, v_type)
            local val1  = dValue(index-1, v_type) or val

            hp[index]   = 0.5*(1 + alpha1)*(val - val1) + alpha1*(hp[index-1] or 0)
            filt[index] = c1*(hp[index] + (hp[index-1] or 0))/2 + c2*(filt[index-1] or 0) + c3*(filt[index-2] or 0)

            if (index - begin_index) <= (avg_length + 48) then
                return
            end

            local corr  = {}
            corr[0]     = 1

            for lag = 1, 48 do
                local m     = (avg_length == 0) and lag or avg_length

                local num   = 0
                local sx    = 0
                local sy    = 0
                local sxx   = 0
                local syy   = 0
                local sxy   = 0

                for i = 0, m-1 do
                    if filt[index-i-lag] and filt[index-i] then
                        sx      = sx + filt[index-i]
                        sy      = sy + filt[index-i-lag]
                        sxx     = sxx + filt[index-i]*filt[index-i]
                        syy     = syy + filt[index-i-lag]*filt[index-i-lag]
                        sxy     = sxy + filt[index-i]*filt[index-i-lag]
                        num     = num + 1
                    end
                end

                corr[lag] = ((num*sxx - sx*sx)*(num*syy - sy*sy) > 0) and (num*sxy - sx*sx)/math_sqrt((num*sxx - sx*sx)*(num*syy - sy*sy)) or 0
            end

            local cos_part  = {}
            local sin_part  = {}
            local sq_sum    = {}
            local r1        = {}
            local r2        = {}
            local pwr       = {}

            --Compute the Fourier Transform for each Correlation
            for it = 8, 48 do

                cos_part[it] = 0
                sin_part[it] = 0

                for n = 3, 48 do
                    cos_part[it] = cos_part[it] + corr[n]*math_cos(360*n/it);
                    sin_part[it] = sin_part[it] + corr[n]*math_sin(360*n/it);
                 end
                sq_sum[it] = cos_part[it]*cos_part[it] + sin_part[it]*sin_part[it];
            end

            for it = 8, 48 do
                r2[it] = r1[it] or 0
                r1[it] = 0.2*sq_sum[it]*sq_sum[it] + 0.8*r2[it]
            end

            -- Find Maximum Power Level for Normalization
            local max_pwr = math_max(unpack(r1, 8, 48))

            for it = 8, 48 do
                pwr[it] = r1[it]/max_pwr
            end

            --Optionally increase Display Resolution by raising the NormPwr to a higher mathematically power (since the maximum amplitude is unity, cubing all amplitudes further reduces the smaller ones).
            if enh_resolution == 1 then
                for it = 8, 48 do
                    pwr[it] = math_pow(pwr[it], 3)
                end
            end

            --Compute the dominant cycle using the CG of the spectrum
            acp[index]       = 0
            local peak_pwr   = math_max(unpack(pwr, 8, 48))

            local spx = 0
            local sp = 0
            for it = 8, 48 do
                if peak_pwr >= 0.25 and pwr[it] >= 0.25 then
                    spx = spx + it*pwr[it]
                    sp = sp + pwr[it]
                end
            end

            acp[index] = sp ~= 0 and spx/sp or 0

            if sp < 0.25 then
               acp[index] = acp[index-1]
            end

            if acp[index] < 1 then acp[index] = 1 end

            cache[index] = acp[index]
            return cache[index]

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                _G.message(tostring(res))
            end
            return nil
        end

        return res

    end
end

function _G.Init()
    PlotLines = AutoCorr(_G.Settings)
    return 1
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    local h = PlotLines(index) or {}
    SetValue(index-1, 1, h)
    return nil
end
