--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    ORB - Opening Range Breakout

    В основе этого индикатора лежит концепция, согласно которой высокие и низкие цены, установленные в первые минуты торговой сессии, часто служат значительными уровнями поддержки и сопротивления в течение всего оставшегося дня.
    Индикатор автоматически рассчитывает диапазон на основе заданных пользователем временных периодов, строит уровни минимума, максимума, середины диапазона.
	А также при закрытии бара за границей диапазона цели движения в размере от ширины диапазона.
]]

_G.unpack = rawget(table, "unpack") or _G.unpack

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\ORB.txt", "w")

local message       = _G['message']
local SetRangeValue = _G['SetRangeValue']
-- local RGB           = _G['RGB']
local T             = _G['T']
local C             = _G['C']
local H             = _G['H']
local L             = _G['L']
local os_time	    = os.time
local math_max      = math.max
local math_min      = math.min

_G.Settings= {
    Name 		= "*ORB",
    line = {
    }
}

local PlotLines     = function(index) return index end
local error_log     = {}

local function log_tostring(...)
    local args = table.pack(...)
    if args.n == 1 then
        return tostring(args[1])
    end
    for i = 1, args.n do
        args[i] = tostring(args[i])
    end
    return table.concat(args, " ", 1, args.n)
end

function log(...)
	if logFile==nil then return end
    logFile:write(log_tostring(...).."\n");
    logFile:flush();
end

local function is_date(val)
    local status = pcall(function() return type(val) == "table" and os_time(val); end)
    return status
end

local numerator = (function(l)
    l = l or 16
    local i = 0
    return function()
        i = i+1
        if i > l then i = 1 end
        return i
    end
end)

local times = 3
local lines = times*5
_G.Settings['0.0:Периоды']             = 'Указывать как строку вида 10:00'
_G.Settings['0.1:Цель движения']       = 'Указывать как ширину зоны: 0.5 или 1.1 и т.д.'
_G.Settings['1:Начало']                = '10:00'
_G.Settings['1:Окончание']             = '10:30'
_G.Settings['1:Цель движения ЛОНГ']    = 0.5
_G.Settings['1:Цель движения ШОРТ']    = 0.5
local num = numerator(lines)
for i = 1, times do
    local s_name  = tostring(i)..':'..'Окончание'
    local l_name  = tostring(i)..':'..'Начало'
    local tl_name = tostring(i)..':'..'Цель движения ЛОНГ'
    local ts_name = tostring(i)..':'..'Цель движения ШОРТ'
	_G.Settings[l_name]     = _G.Settings[l_name] or ''
    _G.Settings[s_name]     = _G.Settings[s_name] or ''
	_G.Settings[tl_name]    = _G.Settings[tl_name] or ''
    _G.Settings[ts_name]    = _G.Settings[ts_name] or ''
	_G.Settings.line[num()] = {Name = tostring(i)..':'..'Максимум', Color = _G.RGB(math.min(5*i, 255), math.max(255-10*i, 0),  math.min(10*i, 255)), Type = _G.TYPET_BAR, Width = 2}
	_G.Settings.line[num()] = {Name = tostring(i)..':'..'Минимум', Color = _G.RGB(math.max(255-10*i, 0), math.min(5*i, 255),  math.min(10*i, 255)), Type = _G.TYPET_BAR, Width = 2}
	_G.Settings.line[num()] = {Name = tostring(i)..':'..'Середина', Color = _G.RGB(128, 128,  128), Type = _G.TYPET_BAR, Width = 1}
	_G.Settings.line[num()] = {Name = tostring(i)..':'..'Цель движения ЛОНГ', Color = _G.RGB(math.min(5*i, 255), math.max(255-10*i, 0),  math.min(10*i, 255)), Type = _G.TYPET_BAR, Width = 1}
	_G.Settings.line[num()] = {Name = tostring(i)..':'..'Цель движения ШОРТ', Color = _G.RGB(math.max(255-10*i, 0), math.min(5*i, 255),  math.min(10*i, 255)), Type = _G.TYPET_BAR, Width = 1}
end

local function Algo(settings)

    settings  = (settings or {})

    local orb_times   = {}
    local line        = 1
    for i = 1, times do
        if (settings[tostring(i)..':'..'Начало'] or ''):match('%d%d:%d%d') and (settings[tostring(i)..':'..'Окончание'] or ''):match('%d%d:%d%d') then
            orb_times[#orb_times+1] = {
				start_time = settings[tostring(i)..':'..'Начало'] or '', end_time = settings[tostring(i)..':'..'Окончание'] or '',
				max_line = line, min_line = line+1, mid_line = line+2, tmax_line = line+3, tmin_line = line+4,
				l_target = settings[tostring(i)..':'..'Цель движения ЛОНГ'] or 0, s_target = settings[tostring(i)..':'..'Цель движения ШОРТ'] or 0
			}
            log('track time',  i, orb_times[#orb_times].start_time,  orb_times[#orb_times].end_time, orb_times[#orb_times].max_line, orb_times[#orb_times].min_line)
        end
        line = line + 5
    end

    local ct    = #orb_times
    error_log   = {}

    local out 		= {}
    local hl_times 	= {}
    local begin_index, last_index
    local last_day, last_time, bar_time

    local ds_int

    local function get_time(index)
        local t = T(index)
        if not is_date(t) then return end
        return t
    end
    local function get_day(index)
        return (get_time(index) or {}).day
    end
    local function get_tformat(index)
        local t = get_time(index)
        if not t then return end
        local ut = os_time(t)
        return os.date('%H:%M', ut), ut
    end

    return function (index)

        local status, res = pcall(function()

            if not ds_int or index == begin_index then
                local ds_info 	= _G.getDataSourceInfo()
				local interval = ds_info and ds_info.interval or 1
                if interval == -1 then interval = 1440 end
                if interval == -2 then interval = 10080 end
                if interval == -3 then interval = 23200 end
                ds_int          = interval*60
                begin_index     = index
                last_index      = index
                last_day        = get_day(index)
                out             = {}
				hl_times 		= {}
                log('start', index, 'ds_int', ds_int)
                return
            end
            if index == last_index then return end
            local day = get_day(index)
            if last_day ~= day then
                out = {}
                last_day = day
            end
            for i = 1, ct do
                if orb_times[i] and orb_times[i].start_time == last_time then
                    hl_times[i] = {max = H(last_index), min = L(last_index), start_time = bar_time, start_index = last_index}
                    log('strat ORB', i, last_time, hl_times[i].min, hl_times[i].max)
                end
                if hl_times[i] and orb_times[i] and orb_times[i].end_time == last_time then
                    out[orb_times[i].max_line] = hl_times[i].max
                    SetRangeValue(orb_times[i].max_line, hl_times[i].start_index, index, hl_times[i].max)
                    out[orb_times[i].min_line] = hl_times[i].min
                    SetRangeValue(orb_times[i].min_line, hl_times[i].start_index, index, hl_times[i].min)
                    out[orb_times[i].mid_line] = (hl_times[i].max + hl_times[i].min)/2
                    SetRangeValue(orb_times[i].mid_line, hl_times[i].start_index, index, out[orb_times[i].mid_line])
                    hl_times[i].end_time       = bar_time
					hl_times[i].range		   = hl_times[i].max - hl_times[i].min
                    log('end ORB', i, last_time, hl_times[i].min, hl_times[i].max)
                end
                if hl_times[i] and orb_times[i] and bar_time >= hl_times[i].start_time and not hl_times[i].end_time  then
                    hl_times[i].max = math_max(hl_times[i].max, H(last_index))
                    hl_times[i].min = math_min(hl_times[i].min, L(last_index))
                end
                if hl_times[i] and orb_times[i] and hl_times[i].end_time then
					if C(last_index) > hl_times[i].max and orb_times[i].l_target ~= 0 and hl_times[i].range ~= 0 then
						out[orb_times[i].tmax_line] = hl_times[i].max + hl_times[i].range*orb_times[i].l_target
						SetRangeValue(orb_times[i].tmax_line, hl_times[i].start_index, index, out[orb_times[i].tmax_line])
					end
					if C(last_index) < hl_times[i].min and orb_times[i].s_target ~= 0 and hl_times[i].range ~= 0 then
						out[orb_times[i].tmin_line] = hl_times[i].min - hl_times[i].range*orb_times[i].s_target
						SetRangeValue(orb_times[i].tmin_line, hl_times[i].start_index, index, out[orb_times[i].tmin_line])
					end
                end
            end

            log('new index', index, 'last', last_index, last_time, bar_time, unpack(out, 1, lines))

            last_time, bar_time   = get_tformat(index)
            last_index  = index

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                log(tostring(res))
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