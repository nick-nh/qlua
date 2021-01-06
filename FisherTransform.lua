--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

    Fisher Transform by John F. Ehlers
    https://c.mql5.com/forextsd/forum/3/130fish.pdf
]]

_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\Fisher.txt", "w")

local message           = _G['message']
local RGB               = _G['RGB']
local TYPE_LINE         = _G['TYPE_LINE']
local TYPE_HISTOGRAM    = _G['TYPE_HISTOGRAM']
local isDark            = _G.isDarkTheme()
local os_time	        = os.time
local math_log          = math.log

_G.Settings= {
    Name 		= "*Fisher",
    period      = 9,
    data_type   = 'Close',
    hist_view   = 0,
    line = {
        {
            Name  = 'Fisher',
            Color = isDark and RGB(255, 193, 193) or RGB(113, 0, 0),
            Type  = TYPE_LINE,
            Width = 2
        },
        {
            Name  = 'Trigger',
            Color = isDark and RGB(193, 255, 193) or RGB(0, 113, 0),
            Type  = TYPE_LINE,
            Width = 1
        },
		{
			Name	= "Up",
			Color	= RGB(0, 128, 128),
			Type	= TYPE_HISTOGRAM,
			Width	= 4
		},
		{
			Name	= "Down",
			Color	= RGB(255, 128, 0),
			Type	= TYPE_HISTOGRAM,
			Width	= 4
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
    local period        = Fsettings.period or 9
    local hist_view     = Fsettings.hist_view or 0
    local begin_index   = 1

    local out1, out2, out3, out4

    local fisher
    local data
	local high_buff = {}
	local low_buff  = {}

    error_log = {}

    return function (index)

        out1, out2, out3, out4 = nil, nil, nil, nil

        local status, res = pcall(function()

            if not maLib then return end

            if fisher == nil or index == 1 then
                begin_index         = index
                fisher              = {}
                fisher[index]       = 0
                data                = {}
                data[index]         = 0
                high_buff[index]    = maLib.Value(index, "H", ds)
                low_buff[index]     = maLib.Value(index, "L", ds)
                return
            end

			data[index]         = data[index-1]
            high_buff[index]    = maLib.Value(index, "H", ds) or high_buff[index-1]
            low_buff[index]     = maLib.Value(index, "L", ds) or low_buff[index-1]
            fisher[index]       = fisher[index-1]

			if not maLib.CheckIndex(index, ds) or (index - begin_index + 1) < period then
				return
			end

            local HH    = math_max(unpack(high_buff,  index - period + 1,index))
            local LL    = math_min(unpack(low_buff,   index - period + 1,index))
            local rcl   = maLib.Value(index, data_type, ds) - LL
            local rhl   = HH - LL
            data[index] = rhl == 0 and 0 or 0.33*2.0*(rcl/rhl-0.5)+0.67*data[index-1]

            if(data[index] > (0.9999))	then data[index]= (0.9999)  end
            if(data[index] < (-0.9999))	then data[index]= (-0.9999) end

            fisher[index]   = 0.5*math_log((1+data[index])/(1-data[index]))+0.5*fisher[index-1]

            if hist_view == 0 then
                out1 = fisher[index]
            else
                if fisher[index] > fisher[index-1]	then
                    out3 = fisher[index]
                else
                    out4 = fisher[index]
                end
            end
            out2 = fisher[index-1]
        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
            return nil
        end
        return out1, out2, out3, out4
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