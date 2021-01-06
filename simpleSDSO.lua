--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    simple Stochastic Standart Deviation
]]

_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\sSDSO.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local isDark        = _G.isDarkTheme()
local os_time	    = os.time

_G.Settings= {
    Name 		= "*sSDSO",
    period      = 4,
    hl_period   = 20,
    data_type   = 'Close',
    line = {
        {
            Name  = 'sSDSO',
            Color = isDark and RGB(255, 193, 193) or RGB(113, 0, 0),
            Type  = TYPE_LINE,
            Width = 2
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

local function Algo(Fsettings, ds)

    Fsettings           = (Fsettings or {})
    local data_type     = (Fsettings.data_type or "Close")
    local period        = Fsettings.period or 4
    local hl_period     = Fsettings.hl_period or 20
    local begin_index   = 1

    local fSD
    local out

    local sdso

    error_log = {}

    return function (index)

        out = nil

        local status, res = pcall(function()

            if not maLib then return end

            if fSD == nil or index == 1 then
                begin_index     = index
                fSD             = maLib.new({period = period, method = 'SD', data_type = data_type}, ds)
                sdso            = {}
                sdso[index]     = fSD(index)[index]
                return
            end

			sdso[index]    = sdso[index-1]

			if not maLib.CheckIndex(index, ds) then
				return
			end

            sdso[index] = fSD(index)[index]

            local HH    = math_max(unpack(sdso,  math_max(index - hl_period + 1, begin_index),index))
            local LL    = math_min(unpack(sdso,  math_max(index - hl_period + 1, begin_index),index))
            local rcl   = sdso[index] - LL
            local rhl   = HH - LL
            out         = rhl == 0 and 100 or rcl*100/rhl
        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
            return nil
        end
        return out
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