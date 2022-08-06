--[[
	nick-h@yandex.ru
    https://github.com/nick-nh/qlua

    JRSX
]]
_G.unpack = rawget(table, "unpack") or _G.unpack
_G.load   = _G.loadfile or _G.load

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\JRSX.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local TYPE_POINT    = _G['TYPE_POINT']
local line_color    = RGB(250, 0, 0)
local os_time	    = os.time

_G.Settings= {
    Name 		= "*JRSX",
    period      = 14,
    data_type   = 'Close',
	color       = 0,
    line = {
        {
            Name  = 'THV',
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

    local period    = Fsettings.period or 14
    local color     = (Fsettings.color or 0) == 1
    local data_type = (Fsettings.data_type or "Close")

    error_log   = {}

    local JRSX
    local out
    local begin_index

    local trend

    local w     = math.max(period-1, 5)
    local Kg    = 3/(period+2)
    local Hg    = 1 - Kg

    local v8, v8a
    local f28
    local f30
    local f38
    local f40
    local f48
    local f50
    local f58
    local f60
    local f68
    local f70
    local f78
    local f80

    local c, c1

    return function (index)

        out = {}

        local status, res = pcall(function()

            c = Value(index, data_type, ds) or 0

            if JRSX == nil or index == begin_index then
                begin_index     = index
                JRSX            = {}
                JRSX[index]     = 0
                f28             = {}
                f30             = {}
                f38             = {}
                f40             = {}
                f48             = {}
                f50             = {}
                f58             = {}
                f60             = {}
                f68             = {}
                f70             = {}
                f78             = {}
                f80             = {}
                f28[index]      = 0
                f30[index]      = 0
                f38[index]      = 0
                f40[index]      = 0
                f48[index]      = 0
                f50[index]      = 0
                f58[index]      = 0
                f60[index]      = 0
                f68[index]      = 0
                f70[index]      = 0
                f78[index]      = 0
                f80[index]      = 0
                c1              = c
                trend           = {}
                return
            end

            JRSX[index]     = JRSX[index-1] or 0
            trend[index]    = trend[index-1] or 0
            f28[index]      = f28[index-1] or 0
            f30[index]      = f30[index-1] or 0
            f38[index]      = f38[index-1] or 0
            f40[index]      = f40[index-1] or 0
            f48[index]      = f48[index-1] or 0
            f50[index]      = f50[index-1] or 0
            f58[index]      = f58[index-1] or 0
            f60[index]      = f60[index-1] or 0
            f68[index]      = f68[index-1] or 0
            f70[index]      = f70[index-1] or 0
            f78[index]      = f78[index-1] or 0
            f80[index]      = f80[index-1] or 0

            if not CheckIndex(index, ds) then
                return unpack(out, 1, lines)
            end


                v8  = (c - c1)
                c1  = c
                v8a = math.abs(v8)

                ---- вычисление V14 ------
                f28[index]  = Hg*f28[index-1] + Kg*v8
                f30[index]  = Kg*f28[index] + Hg*f30[index-1]
                local v0C   = 1.5*f28[index] - 0.5*f30[index]
                f38[index]  = Hg*f38[index-1] + Kg*v0C
                f40[index]  = Kg*f38[index] + Hg*f40[index-1]
                local v10   = 1.5*f38[index] - 0.5*f40[index]
                f48[index]  = Hg*f48[index-1] + Kg*v10
                f50[index]  = Kg*f48[index] + Hg*f50[index-1]
                local v14   = 1.5*f48[index] - 0.5*f50[index]
                ---- вычисление V20 ------
                f58[index]  = Hg*f58[index-1] + Kg*v8a
                f60[index]  = Kg*f58[index] + Hg*f60[index-1]
                local v18   = 1.5*f58[index] - 0.5*f60[index]
                f68[index]  = Hg*f68[index-1] + Kg*v18
                f70[index]  = Kg*f68[index] + Hg*f70[index-1]
                local v1C   = 1.5*f68[index] - 0.5*f70[index]
                f78[index]  = Hg*f78[index-1] + Kg*v1C
                f80[index]  = Kg*f78[index] + Hg*f80[index-1]
                local v20   = 1.5*f78[index] - 0.5*f80[index]

                if (index - begin_index) > w and (v20>0) then
                    JRSX[index]  = (v14/v20+1)*50
                    if JRSX[index] > 100 then JRSX[index] = 100 end
                    if JRSX[index] < 0 then JRSX[index]=0 end
                else JRSX[index] = 50
                end

            out[1] = JRSX[index]

            if (JRSX[index] > JRSX[index-1]) and trend[index] <= 0 then
                trend[index] = 1
            end
            if (JRSX[index] < JRSX[index-1]) and trend[index] >= 0 then
                trend[index] = -1
            end

	        -- myLog('index', index, os.date('%d.%m.%Y %H:%M:%S', os_time(_G.T(index))), 'trend', trend[index], 'out[1]', out[1])

            if color then
				out[2] = trend[index-1] == 1 and out[1] or nil
				out[3] = trend[index-1] == -1 and out[1] or nil
                out[1] = nil
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