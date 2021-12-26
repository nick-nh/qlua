local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\hurst.txt", "w")

local math_max              = math.max
local math_sqrt             = math.sqrt
local math_floor            = math.floor
local math_abs              = math.abs
local math_log              = math.log
local math_pi               = math.pi
local math_tointeger        = math.tointeger
local math_pow              = function(x, y) return x^y end
local os_time               = os.time

local O                     = _G['O']
local C                     = _G['C']
local H                     = _G['H']
local L                     = _G['L']
local V                     = _G['V']
local SetValue              = _G['SetValue']


_G.Settings =
{
    --период равен min_len*2^accuracy
    Name = "*Hurst",
    accuracy = 5, -- минимум 4
    min_len = 7, -- минимум 3
    value_type = "C",
    line =  {
                {
                 Name = "RS",
                 Color = _G.RGB(180, 200, 240),
                 Type = _G.TYPE_LINE,
                 Width = 2
                },
                {
                 Name = "E_RS",
                 Color = _G.RGB(180, 240, 200),
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

--считает приращение
local function increment_series(v_type)
    local cache = {}
    return function(index)
        if cache[index] then return cache[index] end
        if index == 1 then
            return 0
        end
        cache[index] = math_log(dValue(index, v_type)/dValue(index-1, v_type))
        return cache[index]
    end
end

--считает среднее значение приращений
local function average_increment_series(inc)
    local sum   = {}
    local cache = {}
    return function(index, period)
        local key = tostring(index)..'_'..tostring(period)
        if cache[key] then return cache[key] end
        sum[index] = sum[index] or ((sum[index-1] or 0) + inc(index))
        if index<=period then
            return nil
        end
        cache[key] = (sum[index] - (sum[index-period] or 0))/period
        return cache[key]
    end
end

--функция считает RS для разбиения на отрезки длиной len
local function RSn(inc, avg_inc)

    local cache     = {}
    return function(index, period, length)

        local key = tostring(index)..'_'..tostring(length)

        if cache[key] then return cache[key] end

        local N         = math_floor((period-1)/length)
        local RS_sum    = 0
        if index<=period then
            return nil
        end
        for i = 1, N do
            local i_avg     = avg_inc(index-(i-1)*length, length)
            local Dka       = (inc(index-(i-1)*length) - i_avg)
            local Xka       = Dka
            local Xka_min   = Dka
            local Xka_max   = Dka
            local Xka2      = Dka*Dka
            for k = 2, length do
                Dka     = (inc(index-(i-1)*length+(1-k)) - i_avg) -- отклонение k из отрезка i
                Xka     = Xka+Dka
                Xka2    = Xka2+Dka*Dka
                if Xka<Xka_min then
                    Xka_min = Xka
                end
                if Xka>Xka_max then
                    Xka_max = Xka
                end
            end
            local Ri = (Xka_max - Xka_min)
            local Si = math_sqrt((1/length)*Xka2)
            if Si == 0 then return end
            RS_sum   = RS_sum+(Ri/Si)
        end
        cache[key] = RS_sum/N
        return cache[key]
    end
end

local function betta_calc(data, len_data)

    local len = #data
    if len == 0 then return end

    local c1 = 0
    local c2 = 0
    local g1 = 0
    local g2 = 0
    local Xn
    local Yn

    for i = 1, len do
        if not data[i] then return end
        Xn = math_log(len_data[i])
        Yn = math_log(data[i])
        c1 = c1+Xn*Xn
        c2 = c2+Xn
        g1 = g1+Xn*Yn
        g2 = g2+Yn
    end

    return (len*g1 - c2*g2)/(len*c1 - c2*c2)

end

--Функция расчета ожидаемых значений E(R/S)
local function ERSCulc(m)
    local n_sum = 0.0
    for i = 1, m-1 do
        n_sum = n_sum + math_pow(((m-i)/i), 0.5)
    end
    return (m<20 and (m-0.5)/m or 1)*math_pow((m*math_pi/2),-0.5)*n_sum
end

local function Hurst(Fsettings)

    Fsettings           = (Fsettings or {})
    local accuracy      = Fsettings['accuracy'] or 4
    local min_len       = Fsettings['min_len'] or 3
    local v_type        = Fsettings['v_type'] or 'Close'

    local p             = math_tointeger(math_pow(2, accuracy)*min_len+1)

    local cache
    local inc           = increment_series(v_type)
    local avg_inc       = average_increment_series(inc)
    local RS            = RSn(inc, avg_inc)

    local rs_data       = {}
    local begin_index
    error_log = {}

    local len_data      = {}
    local ers_data      = {}
    for i = 1, accuracy do
        len_data[i] = math_tointeger(min_len*math_pow(2,(i-1)))
        ers_data[i] = ERSCulc(len_data[i])
    end

    local ers  = betta_calc(ers_data, len_data)

    return function(ind)

        local status, res = pcall(function()

            if not cache or ind == begin_index then
                cache       = {}
                begin_index = ind
                return
            end

            local index = ind-1

            if index<=p then
                avg_inc(index, 1)
                return nil
            end

            if cache[index] then return cache[index] end

            for i = 1, accuracy do

                -- myLog('Calc bar', index, 'acc', i, 'p', p, 'len', len_data[i])
                local RSi   = RS(index, p, len_data[i])
                if not RSi then return end

                rs_data[i] = RSi
            end

            cache[index] = betta_calc(rs_data, len_data)

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

        return res, ers

    end
end

function _G.Init()
    PlotLines = Hurst(_G.Settings)
    return 2
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    local h, e = PlotLines(index)
    SetValue(index-1, 1, h)
    SetValue(index-1, 2, e)
    return nil
end
