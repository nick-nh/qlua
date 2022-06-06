--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua
]]
_G.unpack = rawget(table, "unpack") or _G.unpack

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\autoLevels.txt", "w")

local message       = _G['message']
local SetRangeValue = _G['SetRangeValue']
local TYPET_BAR     = _G['TYPET_BAR']
local os_time	    = os.time

_G.Settings= {
    Name 		= "*Auto Levels",
    period      = 50,
    min_bars    = 5,
    claster     = 350.0,
    line = {
        {
            Name  = 'Up',
            Color = _G.RGB(192, 0, 0),
            Type  = TYPET_BAR,
            Width = 2
        },
        {
            Name  = 'DW',
            Color = _G.RGB(0, 192, 0),
            Type  = TYPET_BAR,
            Width = 2
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

local function Value(index, data_type, ds)
    local Out = nil
    if tostring(data_type):upper() == 'TIME' then
        return (ds and ds:T(index))
    end
    data_type = (data_type and string.upper(string.sub(data_type,1,1))) or "A"
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
------------------------------------------------------------------
    --Moving Average
------------------------------------------------------------------

local function Algo(Fsettings)

    Fsettings           = (Fsettings or {})
    local period        = Fsettings.period or 30
    local min_bars      = Fsettings.min_bars or 5
    local claster       = Fsettings.claster or 1

    error_log = {}

    local up_cache, dw_cache
    local begin_index, start_index, calc_index

    return function (index)

        local status, res = pcall(function()

            if up_cache == nil or index == begin_index then
				local ds_info = _G.getDataSourceInfo()
                claster = claster*(tonumber(_G.getParamEx(ds_info.class_code, ds_info.sec_code,"SEC_PRICE_STEP").param_value) or 1)
                begin_index = index
                up_cache = {}
                dw_cache = {}
                start_index = begin_index + period
                calc_index = nil
            end

            up_cache[index] = up_cache[index-1]
            dw_cache[index] = dw_cache[index-1]

            local val_h = Value(index,'H')
            local val_l = Value(index, 'L')
            if not val_h or not val_l then return end

            local dd = math.floor(val_l/claster)*claster
            local ud = math.ceil(val_h/claster)*claster
            up_cache[index] = ud
            dw_cache[index] = dd

            if index < start_index or index == calc_index then return end

            --myLog(tostring(index)..' '..os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), 'dd', tostring(dd), 'ud', tostring(ud))

            local u_sum = {}
            local d_sum = {}
            local max_uc, max_dc = 0, 0
            local max_c, min_c
            local f_u, f_d = {}, {}
            local l_u, l_d
            for i = 1, period do
                u_sum[up_cache[index-i]] = (u_sum[up_cache[index-i]] or 0) + 1
                d_sum[dw_cache[index-i]] = (d_sum[dw_cache[index-i]] or 0) + 1
                f_u[up_cache[index-i]] = f_u[up_cache[index-i]] or index-i
                f_d[dw_cache[index-i]] = f_d[dw_cache[index-i]] or index-i
                if u_sum[up_cache[index-i]] > max_uc then
                    max_uc = u_sum[up_cache[index-i]]
                    max_c  = up_cache[index-i]
                    l_u    = index-i
                end
                if d_sum[dw_cache[index-i]] > max_dc then
                    max_dc = d_sum[dw_cache[index-i]]
                    min_c  = dw_cache[index-i]
                    l_d    = index-i
                end
                -- myLog('------', index-i..' '..os.date('%Y.%m.%d %H:%M', os.time(_G.T(index-i))), 'u_sum', up_cache[index-i], u_sum[up_cache[index-i]], 'max_c', max_c, 'd_sum', dw_cache[index-i] , d_sum[dw_cache[index-i]], 'min_c', min_c)
            end

            -- myLog('------ max_uc', tostring(max_uc), 'max_c', tostring(max_c), 'f_u', f_u[max_c], 'l_u', l_u, 'max_dc', tostring(max_dc), 'min_c', tostring(min_c), 'f_d', f_d[min_c], 'l_d', l_d)

            if max_uc >= min_bars then
                SetRangeValue(1, l_u, f_u[max_c], max_c)
            end
            if max_dc >= min_bars then
                SetRangeValue(2, l_d, f_d[min_c], min_c)
            end
            calc_index = index

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
    return lines
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end