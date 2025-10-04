--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    Купонная и общая доходность облигации на графике. Если купон не транслируется, то проивзодится попытка расчета купона.
    Удобно выводить в ту же область графика где цены, привязав к левому краю.
]]

_G.load   = _G.loadfile or _G.load

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\betm.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local getParamEx    = _G['getParamEx']
local SetRangeValue = _G['SetRangeValue']
local C             = _G['C']
local Size          = _G['Size']
local TYPET_BAR     = _G['TYPET_BAR']
local os_time	    = os.time

_G.Settings= {
    Name = "*Bond ETM",
    line = {
        {
            Name  = 'ETM',
            Color = RGB(0, 192, 0),
            Type  = TYPET_BAR,
            Width = 2
        },
        {
            Name  = 'Coupon ETM',
            Color = RGB(192, 0, 0),
            Type  = TYPET_BAR,
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

---@param num number
---@param idp any
local function round(num, idp)
    if num then
        local mult = 10^(idp or 0)
        if num >= 0 then
            return math.floor(num * mult + 0.5) / mult
        else
            return math.ceil(num * mult - 0.5) / mult
        end
    else
        return num
    end
end

local function GetNumberDate(num)
    if type(num) ~= 'number' then  error(("bad argument GetNumberDate:num (number expected, got %s)"):format(type(num)),2) end
    local dt = {}
    dt.year,dt.month,dt.day = string.match(tostring(num),"(%d%d%d%d)(%d%d)(%d%d)")
    for key,value in pairs(dt) do dt[key] = tonumber(value) end
    dt.hour = 0
    dt.sec  = 0
    return dt
end

local ds_info
local TODAY =  os.date('*t', os_time())

---@param info_string string
function GetServerInfo(info_string)
    return getParamEx(ds_info.class_code, ds_info.sec_code, info_string) or {}
end

local calc_algos = {}
calc_algos['pYTM'] = function(sec_data)
    if not sec_data['pProfit'] then return end
    local price = sec_data.cur_price
    if (price or 0) == 0 then return end
    return round(100*sec_data['pProfit']/(price*sec_data.price_coeff)/(sec_data.DAYS_TO_MAT_DATE/sec_data.year_base), 2)
end
calc_algos['cYTM'] = function(sec_data)
    if not sec_data['pProfit'] then return end
    local price = sec_data.cur_price
    if (price or 0) == 0 or (sec_data.COUPONVALUE or 0) == 0 or (sec_data.COUPONPERIOD or 0) == 0 then return end
    return round(round(sec_data.year_base/sec_data.COUPONPERIOD)*sec_data.COUPONVALUE*100/(sec_data.price_coeff*price), 2)
end
calc_algos['pProfit'] = function(sec_data)
    if not sec_data.COUPONVALUE or (sec_data.COUPONPERIOD or 0) == 0 then return end
    local price = sec_data.cur_price
    if (price or 0) == 0 then return end
    return round((sec_data.DAYS_TO_MAT_DATE*sec_data.COUPONVALUE/sec_data.COUPONPERIOD + sec_data.SEC_FACE_VALUE - price*sec_data.price_coeff), sec_data.SEC_SCALE)
end

local function calc_coupon(sec_data)
    if (sec_data.ACCRUEDINT or 0) == 0 then return 0 end
    if (sec_data.COUPONPERIOD or 0) == 0 then return 0 end
    if (sec_data.NEXTCOUPON or 0) == 0 then return 0 end

    local add       = TODAY.wday == 6 and 2 or 0
    local r_days    = round((os_time(sec_data.NEXTCOUPON) - os_time(TODAY))/(24*60*60)) - add
    local c_days    = sec_data.COUPONPERIOD - r_days + 1
    local day_c     = sec_data.ACCRUEDINT/c_days
    local coupon    = round(day_c*sec_data.COUPONPERIOD, 2)
    -- myLog('calc_coupon next', os.date('%Y-%m-%d', os_time(sec_data.NEXTCOUPON)), 'period', sec_data.COUPONPERIOD, 'c_days', c_days, 'r_days', r_days, 'day_c', day_c, 'coupon', coupon, 'TODAY', TODAY)
    return coupon
end

local function Algo()

    error_log = {}

    local out1, out2
    local last_index, last_price
    local sec_data = {}

    return function (index)

        local status, res = pcall(function()
            if index == 1 then
                out1 = nil
                out2 = nil

                ds_info  = _G.getDataSourceInfo()
                sec_data = {}
                sec_data.SEC_FACE_VALUE     = tonumber(GetServerInfo("SEC_FACE_VALUE").param_value) or 0
                sec_data.DAYS_TO_MAT_DATE   = tonumber(GetServerInfo("DAYS_TO_MAT_DATE").param_value) or 0
                sec_data.COUPONVALUE        = tonumber(GetServerInfo("COUPONVALUE").param_value) or 0
                sec_data.NEXTCOUPON         = tonumber(GetServerInfo("NEXTCOUPON").param_value) or 0
                sec_data.NEXTCOUPON         = (sec_data.NEXTCOUPON or 0) == 0 and 0 or GetNumberDate(sec_data.NEXTCOUPON)
                sec_data.COUPONPERIOD       = tonumber(GetServerInfo("COUPONPERIOD").param_value) or 0
                sec_data.ACCRUEDINT         = tonumber(GetServerInfo("ACCRUEDINT").param_value) or 0
                if sec_data.COUPONVALUE == 0 then
                    sec_data.COUPONVALUE = calc_coupon(sec_data) or 0
                end

                sec_data.price_coeff        = (sec_data.SEC_FACE_VALUE or 0) == 0 and 1 or sec_data.SEC_FACE_VALUE/100
                sec_data.year_base          = 365
                sec_data.days_from_buy      = 0
                last_index                  = index
                last_price                  = nil

                -- myLog(ds_info.class_code, ds_info.sec_code, sec_data.SEC_FACE_VALUE, sec_data.price_coeff, sec_data.DAYS_TO_MAT_DATE, sec_data.COUPONVALUE, sec_data.COUPONPERIOD)

            end
            if ds_info and index == Size() then
                if index ~= last_index then
                    SetRangeValue(1, index-12, index-10, nil)
                    SetRangeValue(2, index-12, index-10, nil)
                    last_index = index
                end
                sec_data.cur_price = C(index)
                if last_price ~= sec_data.cur_price then
                    sec_data.pProfit = calc_algos['pProfit'](sec_data)
                    out1 = calc_algos['pYTM'](sec_data)
                    out2 = calc_algos['cYTM'](sec_data)
                    last_price = sec_data.cur_price
                    SetRangeValue(1, index-10, index, out1)
                    SetRangeValue(2, index-10, index, out2)
                    -- myLog(index, out1, out2, last_price)
                end
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
        return out1, out2
    end
end

function _G.Init()
    PlotLines = Algo()
    ds_info = nil
    return 2
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end