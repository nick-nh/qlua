
--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	Min Max price trade session
]]

local logFile = nil
--logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\VWAP.txt", "w")

local getParamEx       	= _G['getParamEx']
local getDataSourceInfo = _G['getDataSourceInfo']
local message       	= _G['message']
local RGB           	= _G['RGB']
local SetValue          = _G['SetValue']
local Size              = _G['Size']
local isDark            = _G.isDarkTheme()
local line_color        = isDark and RGB(240, 240, 240) or RGB(20, 20, 20)

local os_time	    	= os.time

_G.Settings= {
    Name 		= "*MinMaxPrice",
    data_type   = 'Close',
    line = {
        {
            Name  = 'min_price',
            Color = line_color,
            Type  = _G.TYPE_LINE,
            Width = 2
        },
        {
            Name  = 'max_price',
            Color = line_color,
            Type  = _G.TYPE_LINE,
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


local function Algo()

    error_log = {}

	local ds_info
	local min_price, max_price

    return function (index)

        local status, res = pcall(function()

            if ds_info == nil or index == 1 then
				ds_info 	= getDataSourceInfo()
				min_price   = nil
				max_price   = nil
				return
            end

            if index == Size() then
                min_price = tonumber((getParamEx(ds_info.class_code, ds_info.sec_code,"PRICEMIN") or {}).param_value) or min_price
                SetValue(index-11, 1, nil)
                SetValue(index-10, 1, min_price)
                SetValue(index, 1, min_price)
                max_price = tonumber((getParamEx(ds_info.class_code, ds_info.sec_code,"PRICEMAX") or {}).param_value) or max_price
                SetValue(index-11, 2, nil)
                SetValue(index-10, 2, max_price)
                SetValue(index, 2, max_price)
            end
        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
        end
        return min_price, max_price
    end
end

function _G.Init()
    PlotLines = Algo()
    return 2
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end