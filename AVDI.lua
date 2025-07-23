--[[
    Adaptive Volume-Demand-Index (AVDI)
    https://ru.tradingview.com/script/6e5bLwuz/

    nick-h@yandex.ru
	https://github.com/nick-nh/qlua
]]

_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\AVDI.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local TYPE_LINE     = _G['TYPE_LINE']
local line_color    = RGB(0, 128, 255)
local ema_color     = RGB(250, 0, 0)
local os_time	    = os.time

_G.Settings= {
    Name 		= "*AVDI",
    ['1. Период усреднения объема']      = 14,
    ['2. Размер скользящего окна']       = 20,
    ['3. Период усреднения EMA']         = 50,
    line = {
        {
            Name  = 'Raw DemandIndex',
            Color = line_color,
            Type  = TYPE_LINE,
            Width = 2
        },
        {
            Name  = 'EMA DemandIndex',
            Color = ema_color,
            Type  = TYPE_LINE,
            Width = 1
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

function myLog(...)
	if logFile==nil then return end
    logFile:write(tostring(os.date("%c",os_time())).." "..log_tostring(...).."\n");
    logFile:flush();
end
------------------------------------------------------------------
    --Moving Average
------------------------------------------------------------------

local function Algo(settings, ds)

    settings           = (settings or {})

    local v_period = settings['1. Период усреднения объема']     or 14
    local w_period = settings['2. Размер скользящего окна']      or 20
    local e_period = settings['3. Период усреднения EMA']        or 50

    error_log = {}

    local err
    local fV_MA, vol_data
    local fW_SUM
    local fEMA, ema_data
    local out1, out2
    local begin_index

    return function (index)

        local status, res = pcall(function()

            out1 = nil
            out2 = nil

            if not maLib then return end

            if fV_MA == nil or index == begin_index then
                begin_index     = index

                vol_data        = {}
                vol_data[index] = maLib.Value(index, 'Volume', ds)
                fV_MA, err  = maLib.new({method = 'SMA', period = v_period, data_type = 'Any'}, vol_data)
                if not fV_MA and not error_log[tostring(err)] then
                    error_log[tostring(err)] = true
                    myLog(tostring(err))
                    message(tostring(err))
                end
                fV_MA(index)

                fW_SUM, err  = maLib.new({method = 'SUM', period = w_period, data_type = 'Any'})
                if not fV_MA and not error_log[tostring(err)] then
                    error_log[tostring(err)] = true
                    myLog(tostring(err))
                    message(tostring(err))
                end
                fW_SUM(index)

                ema_data          = {}
                ema_data[index]   = 0
                fEMA, err  = maLib.new({method = 'EMA', period = e_period, data_type = 'Any'}, ema_data)
                if not fV_MA and not error_log[tostring(err)] then
                    error_log[tostring(err)] = true
                    myLog(tostring(err))
                    message(tostring(err))
                end
                fEMA(index)

                myLog(index, '------------------------------------------')

                return
            end
            if fV_MA then

                vol_data[index] = maLib.Value(index, 'Volume', ds) or vol_data[index-1]
                local vol_sma   = fV_MA(index)[index]
                local norm_vol  = (vol_sma or 0) == 0 and 0 or vol_data[index]/vol_sma
                local open      = maLib.Value(index, 'Open', ds) or 0
                local close     = maLib.Value(index, 'Close', ds) or 0
                local p_factor  = (open or 0) == 0 and 0 or (close - open)/open
                local w_sum     = fW_SUM(index, norm_vol*p_factor)[index] or 0
                ema_data[index] = w_sum
                local ema       = fEMA(index)[index]

                -- myLog(index, 'vol', vol_data[index], 'vol_sma', vol_sma, 'norm', norm_vol, 'p_factor', p_factor, 'w_sum', w_sum, 'ema', ema)

                out1 = w_sum
                out2 = ema

                vol_data[index-v_period-1] = nil
                ema_data[index-e_period-1] = nil
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
    return lines
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
    return PlotLines(index)
end