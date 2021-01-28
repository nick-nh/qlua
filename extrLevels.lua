--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua
]]

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\Extremums.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local math_max      = math.max
local math_min      = math.min
local os_time	    = os.time
local os_date	    = os.date
local table_unpack	= table.unpack
local string_match	= string.match
local CandleExist   = _G.CandleExist
local SetRangeValue = _G.SetRangeValue

_G.Settings= {
    Name        = "*Extremums",
    bars        = 60,
    begin_time  = '10:00',
    end_time    = '21:45',
    line = {
        {
            Name  = 'Low_Extremum',
            Color = RGB(250, 0, 0),
            Type  = TYPE_LINE,
            Width = 1
        },
        {
            Name  = 'High_Extremum',
            Color = RGB(0, 0, 250),
            Type  = TYPE_LINE,
            Width = 1
        }
    }
}

local H     = _G['H']
local L     = _G['L']
local T     = _G['T']
local Size  = _G['Size']

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

local function Algo(Fsettings)

    Fsettings         = (Fsettings or {})
    local bars        = Fsettings.bars or 60
    local begin_time  = Fsettings.begin_time or '10:00'
    local end_time    = Fsettings.end_time or '18:45'

    local begin_h, begin_m = string_match(begin_time, "(%d%d):(%d%d)")
    local end_h, end_m     = string_match(end_time, "(%d%d):(%d%d)")

    local begin_t = tonumber(tostring(begin_h)..tostring(begin_m)) or 1000
    local end_t   = tonumber(tostring(end_h)..tostring(end_m)) or 1845

    --myLog(begin_h,begin_m, end_h, end_m)

    error_log = {}

    local last_calc_index
    local last_begin_h_index
    local last_begin_l_index
    local last_end_h_index
    local last_end_l_index
    local last_high
    local last_low
    local ds_info

    return function(ind)

        local status, res = pcall(function()

            if ind == 0 then
                --myLog('==================================================================')
				ds_info 	= _G.getDataSourceInfo()
                last_calc_index     = nil
                last_begin_h_index  = nil
                last_begin_l_index  = nil
                last_end_h_index    = nil
                last_end_l_index    = nil
                return
            end

            if last_calc_index == ind then return end

            --myLog('==================================================================')

            local h_buff    = {}
            local l_buff    = {}
            local h_extr    = {}
            local l_extr    = {}

            local h_find    = {}
            local l_find    = {}
            local cur_high  = 0
            local cur_low   = 0

            local count     = 0
            for index = ind, ind - bars + 1, -1 do

                count         = count + 1
                h_buff[count] = h_buff[count-1] or 0
                l_buff[count] = l_buff[count-1] or math.huge

                if CandleExist(index) then

                    local time = tonumber(os_date('%H%M', os_time(T(index)))) or 0
                    if time >= begin_t and time < end_t then

                        local high  = H(index)
                        local low   = L(index)

                        h_buff[count] = high
                        l_buff[count] = low

                        --myLog('index', index, os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), 'H', high, 'L', low)

                        h_extr[high]            = h_extr[high] or {level = high, b_index = index, e_index = index, i = count, count = 0}
                        h_extr[high].b_index    = math_min(h_extr[high].b_index, index)
                        -- h_extr[high].e_index    = math_max(h_extr[high].e_index, index)
                        h_extr[high].count      = h_extr[high].count + 1

                        if h_extr[high].count >= 3 then

                            if math_max(table_unpack(h_buff)) > high then
                                h_extr[high].count = 0
                                for i = h_extr[high].i, count, 1 do
                                    if h_buff[i] == high then
                                        h_extr[high].i       = h_extr[high].i or i
                                        h_extr[high].e_index = h_extr[high].e_index or (index + (count - i))
                                        h_extr[high].b_index = index + (count - i)
                                        h_extr[high].count   = h_extr[high].count + 1
                                    end
                                    if h_buff[i] > high then
                                        if h_extr[high].count < 3 then
                                            h_extr[high].e_index    = nil
                                            h_extr[high].i          = nil
                                            h_extr[high].count      = 0
                                        else
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        if h_extr[high] and h_extr[high].count >= 3 then
                            if h_extr[high].count == 3 then
                                h_find[#h_find + 1] = h_extr[high]
                            end
                            --myLog(' ==== new h', index, os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), 'high', high, 'b', h_extr[high].b_index, 'e', h_extr[high].e_index)
                        end


                        l_extr[low]            = l_extr[low] or {level = low, b_index = index, e_index = index, i = count, count = 0}
                        l_extr[low].b_index    = math_min(l_extr[low].b_index, index)
                        -- l_extr[low].e_index    = math_max(l_extr[low].e_index, index)
                        l_extr[low].count      = l_extr[low].count + 1

                        if l_extr[low].count >= 3 then

                            if math_min(table_unpack(l_buff)) < low then
                                l_extr[low].count = 0
                                for i = l_extr[low].i, count, 1 do
                                    if l_buff[i] == low then
                                        l_extr[low].e_index = l_extr[low].e_index or (index + (count - i))
                                        l_extr[low].i       = l_extr[low].i or i
                                        l_extr[low].b_index = index + (count - i)
                                        l_extr[low].count   = l_extr[low].count + 1
                                    end
                                    if l_buff[i] < low then
                                        if l_extr[low].count < 3 then
                                            l_extr[low].e_index = nil
                                            l_extr[low].i       = nil
                                            l_extr[low].count   = 0
                                        else
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        if l_extr[low] and l_extr[low].count >= 3 then
                            if l_extr[low].count == 3 then
                                l_find[#l_find + 1] = l_extr[low]
                            end
                            --myLog(' ==== new l', index, os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), 'low', low, 'b', l_extr[low].b_index, 'e', l_extr[low].e_index)
                        end

                    end
                end
            end

            if #h_find > 0 then
                if #h_find > 1 then
                    table.sort(h_find, function(a, b) return a.e_index > b.e_index end)
                end
                cur_high = h_find[1].level
            end
            if #l_find > 0 then
                if #l_find > 1 then
                    table.sort(l_find, function(a, b) return a.e_index > b.e_index end)
                end
                cur_low = l_find[1].level
            end

            SetRangeValue(2, last_begin_h_index, last_end_h_index, nil)
            SetRangeValue(1, last_begin_l_index, last_end_l_index, nil)

            if cur_high ~= 0 then
                if cur_high ~= last_high then
                    message(tostring(ds_info.class_code)..'|'..tostring(ds_info.sec_code) ..': '..os.date('%Y.%m.%d %H:%M', os.time(_G.T(h_extr[cur_high].e_index)))..' Новый уровень по максимумам: '..tostring(cur_high))
                    last_high = cur_high
                end
                last_begin_h_index  = h_extr[cur_high].b_index
                last_end_h_index    = h_extr[cur_high].e_index
                SetRangeValue(2, h_extr[cur_high].b_index, h_extr[cur_high].e_index, cur_high)
            end
            if cur_low ~= 0 then
                if cur_low ~= last_low then
                    message(tostring(ds_info.class_code)..'|'..tostring(ds_info.sec_code) ..': '..os.date('%Y.%m.%d %H:%M', os.time(_G.T(l_extr[cur_low].e_index)))..' Новый уровень по минимум: '..tostring(cur_low))
                    last_low = cur_low
                end
                last_begin_l_index  = l_extr[cur_low].b_index
                last_end_l_index    = l_extr[cur_low].e_index
                SetRangeValue(1, l_extr[cur_low].b_index, l_extr[cur_low].e_index, cur_low)
            end

            last_calc_index = ind

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
            return nil
        end
    end
end

function _G.Init()
    PlotLines = Algo(_G.Settings)
    return 2
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    if index == Size() or index == 1 then
        return PlotLines(index-1)
    end
end
