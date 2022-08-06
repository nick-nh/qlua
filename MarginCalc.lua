--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    Расчет и вывод вариационной маржи (ГО) фьючерсного контракта для текущей цены.
    Расчет начинается от начала текущей торговой сесиии.
]]

_G.load   = _G.loadfile or _G.load

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\Margin.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local getParamEx    = _G['getParamEx']
local C             = _G['C']
local T             = _G['T']
local Size          = _G['Size']
local TYPET_BAR     = _G['TYPET_BAR']
local os_time	    = os.time

_G.Settings= {
    Name = "*Margin",
    ['Интервал расчета (сек.)'] = 30,
    line = {
        {
            Name  = 'Margin L',
            Color = RGB(0, 192, 0),
            Type  = TYPET_BAR,
            Width = 2
        },
        {
            Name  = 'Margin S',
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

local ds_info

---@param info_string string
function GetServerInfo(info_string)
    return getParamEx(ds_info.class_code, ds_info.sec_code, info_string) or {}
end

---@param info_string string
local function Check_isServerInfo(info_string)
    return GetServerInfo(info_string).result == '1'
end

local function GetPriceRange()
    return (tonumber(GetServerInfo('PRICEMAX').param_value) or 0), (tonumber(GetServerInfo('PRICEMIN').param_value) or 0)
end

---@param go number
---@param deal_price number
---@param dir string SELL|BUY
function CalcPriceGO(go, deal_price, dir)

    local status, res = pcall(function()

        if go == 0 then return end

        if ds_info.class_code == 'SPBOPT' then return go end

        if not Check_isServerInfo("CLPRICE") then
            return go
        end
        if not Check_isServerInfo("PRICEMAX") then
            return go
        end
        if not Check_isServerInfo("PRICEMIN") then
            return go
        end
        local max_price, min_price  = GetPriceRange()
        local cl_price              = tonumber(GetServerInfo('CLPRICE').param_value) or 0
        local priceKoeff            = (ds_info.SEC_PRICE_STEP or 0) == 0 and 0 or ds_info.STEPPRICE/ds_info.SEC_PRICE_STEP

        if cl_price==0 or max_price == 0 or min_price == 0 then return go end
        local L2                 = (max_price-min_price)
        local R                  = ds_info.CURSTEPPRICE == 'SUR' and 0 or (go/(L2*priceKoeff) - 1)*100
        local sign               = dir == 'BUY' and -1 or 1
        local calc_go            = go + sign*(cl_price - deal_price)*priceKoeff*(1 + R/100)
        return  calc_go
    end)
    if not status then
        return go
    end
    return res
end

local function is_date(val)
    local status = pcall(function() return type(val) == "table" and os.time(val); end)
    return status
end

local function Algo(Settings)

    local timer = Settings['Интервал расчета (сек.)'] or 30
    error_log = {}

    local out1, out2
    local last_time
    local last_index
    local begin_time
    local time
    local start_index

    return function (index)

        local status, res = pcall(function()
            if index == 1 then
                out1 = nil
                out2 = nil
                last_index = index
                start_index = nil
                last_time = 0
                local last = Size()
                if last > 0 then
                    local st = _G.T(last)
                    st.min  = 0
                    st.sec  = 0
                    st.hour = 0
                    begin_time = os.time(st)
                end
            end
            if not start_index then
                time = T(index)
                if is_date(time) and os.time(time) >= begin_time then start_index = index end
            end
            if ds_info and start_index and index >= start_index and (index > last_index or (os.time() - last_time) > timer) then
                if index == Size() then
                    last_time = os.time()
                end
                last_index = index
                out1 = CalcPriceGO(tonumber(GetServerInfo('BUYDEPO').param_value) or 0, C(index), 'BUY')
                out2 = CalcPriceGO(tonumber(GetServerInfo('SELLDEPO').param_value) or 0, C(index), 'SELL')
                -- myLog(index, out1, out2, last_time)
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
    PlotLines = Algo(_G.Settings)
    ds_info = nil
    return 2
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    if index == 1 then
		ds_info = _G.getDataSourceInfo()
		ds_info.SEC_PRICE_STEP 	= tonumber(_G.getParamEx(ds_info.class_code, ds_info.sec_code, "SEC_PRICE_STEP").param_value) or 0
		ds_info.STEPPRICE 	    = tonumber(_G.getParamEx(ds_info.class_code, ds_info.sec_code, "STEPPRICE").param_value) or 0
		ds_info.CURSTEPPRICE 	= _G.getParamEx(ds_info.class_code, ds_info.sec_code, "CURSTEPPRICE").param_value or ''
	end
    return PlotLines(index)
end