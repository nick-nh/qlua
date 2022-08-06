--[[
	nick-h@yandex.ru
    https:--github.com/nick-nh/qlua

    JMA_Star_Light Jurik Research Jurik Moving Average
]]
_G.unpack = rawget(table, "unpack") or _G.unpack
_G.load   = _G.loadfile or _G.load

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\JMA_Star_Light.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local TYPE_POINT    = _G['TYPE_POINT']
local line_color    = RGB(250, 0, 0)
local os_time	    = os.time
local math_pow      = function(x, y) return x^y end

_G.Settings= {
    Name 		= "*JMA StarLight",
    period      = 5, --глубина сглаживания
    phase       = 5, --параметр, изменяющийся в пределах -150 ... +150, влияет на качество переходного процесса
    -- shift       = 0,
    data_type   = 'Close',
	color       = 0,
    line = {
        {
            Name  = 'JMA',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 2
        },
        {
            Name = "dir up",
            Type = TYPE_POINT,
            Width = 2,
            Color = RGB(89,213, 107)
        },
        {
            Name = "dir dw",
            Type = TYPE_POINT,
            Width = 2,
            Color = RGB(255, 58, 0)
        }
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

local O 			= _G['O']
local C 			= _G['C']
local H 			= _G['H']
local L 			= _G['L']
local V 			= _G['V']

local function Value(index, data_type, ds)
    local Out = nil
    data_type = (data_type and string.upper(string.sub(data_type,1,1))) or "A"
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

local function Algo(Fsettings, ds)

    Fsettings   = (Fsettings or {})

    local period    = Fsettings.period or 5
    local phase     = Fsettings.period or 5
    -- local shift     = Fsettings.period or 0
    local color     = (Fsettings.color or 0) == 1
    local data_type = (Fsettings.data_type or "Close")

    error_log   = {}

    local JMA
    local out
    local begin_index

    local trend

    local Dr
    if (period < 1.0000000002) then
        Dr = 0.0000000001
    else
        Dr = (period - 1.0) / 2.0
    end
    local Pf
    if (phase >   100) then Pf = 2.5 end
    if (phase <  -100) then Pf = 0.5 end
    if((phase >= -100) and (phase <= 100)) then
        Pf = phase/100.0 + 1.5
    end
    Dr = Dr * 0.9
    local Kg = Dr / (Dr + 2.0)
    local Ds = math.sqrt(Dr)
    local Dl = math.log(Ds)

    local LP2 = 0
    local LP1 = 0
    local buffer
    local list
    local ring1
    local ring2

    local f0
    local fC0
    local fA0
    local fC8
    local fA8
    local s8
    local f18
    local f38
    local s18
    local s20
    local s10
    local s38
    local s40
    local s48
    local s50
    local s28
    local s30
    local s58
    local s60
    local s68
    local s70


    local cache

    local value
    local last_bar

    local function init_array(num, val)
        local arr = {}
        for i = 0, num-1 do
            arr[i] = val
        end
        return arr
    end

    local function int_portion(x)
        return x > 0 and math.floor(x) or math.ceil(x)
    end

    return function (index)

        out = {}

        local status, res = pcall(function()

            value = Value(index, data_type, ds) or 0

            if JMA == nil or index == begin_index then
                begin_index     = index
                JMA             = {}
                JMA[index]      = 0

                fC0             = 0
                fA0             = 0
                fC8             = 0
                fA8             = 0
                s8              = 0
                f18             = 0
                f38             = 0
                s18             = 0
                s20             = 0
                s10             = 0
                s40             = 0
                s38             = 0
                s50             = 0
                s28             = 63
                s30             = 64
                s48             = 0
                s58             = 0
                s60             = 0
                s68             = 0
                s70             = 0

                cache           = {}
                cache['fC0']    = fC0
                cache['fC8']    = fC8
                cache['fA8']    = fA8
                cache['s8']     = s8
                cache['f18']    = f18
                cache['f38']    = f38
                cache['s18']    = s18
                cache['s20']    = s20
                cache['s10']    = s10
                cache['s38']    = s38
                cache['s50']    = s50
                cache['s28']    = s28
                cache['s30']    = s30
                cache['s48']    = s48
                cache['s58']    = s58
                cache['s60']    = s60
                cache['s68']    = s68

                trend           = {}
                buffer          = init_array(62, 0)
                ring1           = init_array(128, 0)
                ring2           = init_array(11, 0)

                f0              = 1
                list            = {}
                for ii=0, s28 do list[ii]=-1000000.0 end
                for ii=s30, 127 do list[ii]= 1000000.0 end
                cache['list']  = {}
                for i = 0, 127 do
                    cache['list'][i] = list[i]
                end

                last_bar        = index
                return
            end

            if (LP1<61) then
                LP1 = LP1 + 1
                buffer[LP1] = value
            end

            JMA[index]      = JMA[index-1] or 0
            trend[index]    = trend[index-1] or 0

            if index ~= last_bar then
                cache['fC0']    = fC0
                cache['fC8']    = fC8
                cache['fA8']    = fA8
                cache['s8']     = s8
                cache['f18']    = f18
                cache['f38']    = f38
                cache['s18']    = s18
                cache['s20']    = s20
                cache['s10']    = s10
                cache['s38']    = s38
                cache['s50']    = s50
                cache['s28']    = s28
                cache['s30']    = s30
                cache['s48']    = s48
                cache['s58']    = s58
                cache['s60']    = s60
                cache['s68']    = s68
                for i = 0, 127 do
                    cache['list'][i] = list[i]
                end
                last_bar        = index
            else
                fC0             = cache['fC0']
                fC8             = cache['fC8']
                fA8             = cache['fA8']
                s8              = cache['s8']
                f18             = cache['f18']
                f38             = cache['f38']
                s18             = cache['s18']
                s20             = cache['s20']
                s10             = cache['s10']
                s38             = cache['s38']
                s48             = cache['s48']
                s50             = cache['s50']
                s28             = cache['s28']
                s30             = cache['s30']
                s58             = cache['s58']
                s60             = cache['s60']
                s68             = cache['s68']
                for i = 0, 127 do
                    list[i] = cache['list'][i]
                end
            end

            if not CheckIndex(index, ds) then
                return unpack(out, 1, lines)
            end

            local v1, v2, v3, v4, v5, v6, vv
            local f8, f20, f28, f30, f40, f48, f58, f60, f68, f70, f78, f88, f90, f98, fD8, fE8, fE0, fD0, fB0

            if (LP1 > 30) then
                v1 = Dl;
                v2 = v1;
                if ((v1 / math.log(2.0)) + 2.0 < 0.0) then
                    v3 = 0.0;
                else
                    v3 = (v2 / math.log(2.0)) + 2.0;
                end
                f98 = v3;
                if (f98 >= 2.5) then
                    f88 = f98 - 2.0;
                else
                    f88 = 0.5;
                end
                f78 = Ds * f98;
                f90 = f78 / (f78 + 1.0);
                if (f0 ~= 0) then
                    f0 = 0;
                    v5 = 0;
                    for ii = 0, 29 do
                        if (buffer[ii + 1] ~= buffer[ii]) then
                            v5 = 1;
                            break;
                        end
                    end
                    fD8 = v5 * 30;
                    if (fD8 == 0) then
                        f38 = value;
                    else
                        f38 = buffer[1]
                    end
                    f18 = f38;
                    if (fD8 > 29) then
                        fD8 = 29;
                    end
                else
                    fD8 = 0;
                end
                for ii = fD8, 0, -1 do
                    if (ii == 0) then
                        f8 = value;
                    else
                        f8 = buffer[31 - ii];
                    end
                    f28 = f8 - f18;
                    f48 = f8 - f38;
                    if (math.abs(f28) > math.abs(f48)) then
                        v2 = math.abs(f28);
                    else
                        v2 = math.abs(f48);
                    end
                    fA0 = v2;
                    vv = fA0 + 0.0000000001; --{1.0e-10;}
                    if (s48 <= 1) then
                        s48 = 127;
                    else
                        s48 = s48 - 1;
                    end
                    if (s50 <= 1) then
                        s50 = 10;
                    else
                        s50 = s50 - 1
                    end
                    if (s70 < 128) then
                        s70 = s70 + 1;
                    end

                    s8 = s8 + vv - ring2[s50];
                    ring2[s50] = vv;
                    if (s70 > 10) then
                        s20 = s8 / 10.0;
                    else
                        s20 = s8 / s70;
                    end
                    if (s70 > 127) then
                        s10 = ring1[s48];
                        ring1[s48] = s20;
                        s68 = 64;
                        s58 = s68;
                        while (s68 > 1) do
                            if (list[s58] < s10) then
                                s68 = s68 * 0.5;
                                s58 = s58 + s68;
                            else
                                if (list[s58] <= s10) then
                                    s68 = 1;
                                else
                                    s68 = s68 * 0.5;
                                    s58 = s58 - s68;
                                end
                            end
                        end
                    else
                        ring1[s48] = s20;
                        if (s28 + s30 > 127) then

                            s30 = s30 - 1;
                            s58 = s30;

                        else
                            s28 = s28 + 1;
                            s58 = s28;
                        end
                        if (s28 > 96) then
                            s38 = 96;
                        else
                            s38 = s28;
                        end
                        if (s30 < 32) then
                            s40 = 32;
                        else
                            s40 = s30;
                        end
                    end
                    s68 = 64;
                    s60 = s68;
                    while (s68 > 1) do
                        if (list[s60] >= s20) then
                            if (list[s60 - 1] <= s20) then
                                s68 = 1;
                            else
                                s68 = s68 * 0.5;
                                s60 = s60 - s68;
                            end
                        else
                            s68 = s68 * 0.5;
                            s60 = s60 + s68;
                        end
                        if ((s60 == 127) and (s20 > list[127])) then
                            s60 = 128;
                        end
                    end
                    if (s70 > 127) then
                        if (s58 >= s60) then
                            if ((s38 + 1 > s60) and (s40 - 1 < s60)) then
                                s18 = s18 + s20;
                            else
                                if ((s40 + 0 > s60) and (s40 - 1 < s58)) then
                                    s18 = s18 + list[s40 - 1];
                                end
                            end
                        else
                            if (s40 >= s60) then
                                if ((s38 + 1 < s60) and (s38 + 1 > s58)) then
                                    s18 = s18 + list[s38 + 1];
                                end
                            else
                                if (s38 + 2 > s60) then
                                    s18 = s18 + s20;
                                else
                                    if ((s38 + 1 < s60) and (s38 + 1 > s58)) then
                                        s18 = s18 + list[s38 + 1];
                                    end
                                end
                            end
                        end
                        if (s58 > s60) then
                            if ((s40 - 1 < s58) and (s38 + 1 > s58)) then
                                s18 = s18 - list[s58];
                            else
                                if ((s38 < s58) and (s38 + 1 > s60)) then
                                    s18 = s18 - list[s38];
                                end
                            end
                        else
                            if ((s38 + 1 > s58) and (s40 - 1 < s58)) then
                                s18 = s18 - list[s58];
                            else
                                if ((s40 + 0 > s58) and (s40 - 0 < s60)) then
                                    s18 = s18 - list[s40];
                                end
                            end
                        end
                    end
                    if (s58 <= s60) then
                        if (s58 >= s60) then
                            list[s60] = s20;
                        else
                            for jj = s58 + 1, s60 - 1 do
                                list[jj - 1] = list[jj];
                            end
                            list[s60 - 1] = s20;
                        end
                    else
                        for jj = s58 - 1, s60, -1 do
                            list[jj + 1] = list[jj];
                        end
                        list[s60] = s20;
                    end
                    if (s70 <= 127) then
                        s18 = 0;
                        for jj = s40, s38 do
                            s18 = s18 + list[jj];
                        end
                    end
                    f60 = s18 / (s38 - s40 + 1.0);
                    if (LP2 + 1 > 31) then
                        LP2 = 31;
                    else
                        LP2 = LP2 + 1;
                    end
                    if (LP2 <= 30) then
                        if (f28 > 0.0) then
                            f18 = f8;
                        else
                            f18 = f8 - f28 * f90;
                        end
                        if (f48 < 0.0) then
                            f38 = f8;
                        else
                            f38 = f8 - f48 * f90;
                        end
                        JMA[index] = value;

                        if (LP2 == 30) then
                            fC0 = value;
                            if (math.ceil(f78) >= 1) then
                                v4 = math.ceil(f78);
                            else
                                v4 = 1.0;
                            end
                            fE8 = int_portion(v4);
                            if (math.floor(f78) >= 1) then
                                v2 = math.floor(f78);
                            else
                                v2 = 1.0;
                            end
                            fE0 = int_portion(v2);
                            if (fE8 == fE0) then
                                f68 = 1.0;
                            else
                                v4 = fE8 - fE0;
                                f68 = (f78 - fE0) / v4;
                            end
                            if (fE0 <= 29) then
                                v5 = fE0;
                            else
                                v5 = 29;
                            end
                            if (fE8 <= 29) then
                                v6 = fE8;
                            else
                                v6 = 29;
                            end
                            fA8 = (value - buffer[LP1 - v5]) * (1.0 - f68) / fE0 + (value - buffer[LP1 - v6]) * f68 / fE8;
                        end
                    else
                        if (f98 >= math_pow(fA0 / f60, f88)) then
                            v1 = math_pow(fA0 / f60, f88);
                        else
                            v1 = f98;
                        end
                        if (v1 < 1.0) then
                            v2 = 1.0;
                        else
                            if (f98 >= math_pow(fA0 / f60, f88)) then
                                v3 = math_pow(fA0 / f60, f88);
                            else
                                v3 = f98;
                            end
                            v2 = v3;
                        end
                        f58 = v2;
                        f70 = math_pow(f90, math.sqrt(f58));
                        if (f28 > 0.0) then
                            f18 = f8;
                        else
                            f18 = f8 - f28 * f70;
                        end
                        if (f48 < 0.0) then
                            f38 = f8;
                        else
                            f38 = f8 - f48 * f70;
                        end
                    end
                end
                if (LP2 > 30) then
                    f30 = math_pow(Kg, f58);
                    fC0 = (1.0 - f30) * value + f30 * fC0;
                    fC8 = (value - fC0) * (1.0 - Kg) + Kg * fC8;
                    fD0 = Pf * fC8 + fC0;
                    f20 = f30 * (-2.0);
                    f40 = f30 * f30;
                    fB0 = f20 + f40 + 1.0;
                    fA8 = (fD0 - JMA[index]) * fB0 + f40 * fA8;
                    JMA[index] = JMA[index] + fA8;
                end
            end

            out[1] = JMA[index]

            if (JMA[index] > JMA[index-1]) and trend[index] <= 0 then
                trend[index] = 1
            end
            if (JMA[index] < JMA[index-1]) and trend[index] >= 0 then
                trend[index] = -1
            end

	        -- myLog('index', index, os.date('%d.%m.%Y %H:%M:%S', os_time(_G.T(index))), 'trend', trend[index], 'out[1]', out[1])

            if color then
				out[2] = trend[index-1] == 1 and out[1] or nil
				out[3] = trend[index-1] == -1 and out[1] or nil
                out[1] = nil
            end
			if trend[index-1] ~= trend[index-2] and not color then
				out[2] = trend[index-1] == 1 and _G.O(index) or nil
				out[3] = trend[index-1] == -1 and _G.O(index) or nil
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