--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    Stochastic Standart Deviation
]]

_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\SDSO.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local isDark        = _G.isDarkTheme()
local os_time	    = os.time

_G.Settings= {
    Name 		= "*SDSO",
    period      = 4,
    hl_period   = 20,
    data_type   = 'Close',
    line = {
        {
            Name  = 'SDSO',
            Color = isDark and RGB(255, 193, 193) or RGB(113, 0, 0),
            Type  = TYPE_LINE,
            Width = 2
        },
        {
            Name  = 'Signal',
            Color = isDark and RGB(193, 255, 193) or RGB(0, 113, 0),
            Type  = TYPE_LINE,
            Width = 1
        }
    }
}

local lines         = #_G.Settings.line
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

local math_max = math.max
local math_min = math.min

local function STOCH(settings, data)

    settings            = (settings or {})

    local method        = (settings.method or "SMA")
    local period        = (settings.period or 5)
    local shift         = (settings.shift or 3)
    local period_d      = (settings.period_d or 3)
    local method_d      = (settings.method_d or "SMA")
    local round         = (settings.round or "off")
    local scale         = (settings.scale or 0)
    local save_bars     = (settings.save_bars or math_max(period_d, period, shift))
    local begin_index   = 1

	local high_buff = {}
	local low_buff  = {}

    local range_hl  = {}
    local range_cl  = {}
	local stoch     = {}

    local RHL_MA    = maLib.new({period = shift,    method = method,   data_type = "Any", round = round, scale = scale}, range_hl)
	local RCL_MA    = maLib.new({period = shift,    method = method,   data_type = "Any", round = round, scale = scale}, range_cl)
	local DMA       = maLib.new({period = period_d, method = method_d, data_type = "Any", round = round, scale = scale}, stoch)

    return function(index)

        if stoch[index-1] == nil then begin_index = index end

		high_buff[index]    = data[index] or high_buff[index-1]
		low_buff[index]     = data[index] or low_buff[index-1]
        stoch[index]        = stoch[index-1] or 0
        range_hl[index]     = range_hl[index-1] or 0
        range_cl[index]     = range_cl[index-1] or 0

        if not maLib.CheckIndex(index, data) then
            RHL_MA(index)
            RCL_MA(index)
            return stoch[index], DMA(index)[index]
        end

        local HH            = math_max(unpack(high_buff, math_max(index-period+1, begin_index),index))
        local LL            = math_min(unpack(low_buff,  math_max(index-period+1, begin_index),index))

        range_hl[index]     = HH - LL
        range_cl[index]     = data[index] - LL
        local rcl           = RCL_MA(index)[index]
        local rhl           = RHL_MA(index)[index]
        stoch[index]        = rhl == 0 and 100 or rcl*100/rhl

        stoch[index-save_bars]      = nil
        high_buff[index-save_bars]  = nil
        low_buff[index-save_bars]   = nil
        range_hl[index-save_bars]   = nil
        range_cl[index-save_bars]   = nil

        return stoch[index], DMA(index)[index]
    end
end

local function Algo(Fsettings, ds)

    Fsettings       = (Fsettings or {})
    local data_type = (Fsettings.data_type or "Close")
    local period    = Fsettings.period or 4
    local hl_period = Fsettings.hl_period or 20

    error_log = {}

    local fSD
    local fSO
    local out1, out2

    local sdso

    return function (index)

        out1, out2 = nil, nil

        local status, res = pcall(function()

            if not maLib then return end

            if fSD == nil or index == 1 then
                fSD             = maLib.new({period = period, method = 'SD', data_type = data_type}, ds)
                sdso            = {}
                sdso[index]     = fSD(index)[index]
                fSO             = STOCH({period = hl_period}, sdso)
                fSO(index)
                return
            end

			sdso[index]    = sdso[index-1]

			if not maLib.CheckIndex(index, ds) then
				return
			end

            sdso[index] = fSD(index)[index]
            out1, out2  = fSO(index)
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
    return lines
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end