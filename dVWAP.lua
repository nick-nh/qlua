--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua
	
	VWAP - через распределение объёма по телу бара
]]

_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\VWAP.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local Size          = _G['Size']
local CandleExist   = _G['CandleExist']
local SetRangeValue = _G['SetRangeValue']
local TYPE_LINE     = _G['TYPE_LINE']
local O             = _G['O']
local C             = _G['C']
local H             = _G['H']
local L             = _G['L']
local V             = _G['V']

-- local isDark        = _G.isDarkTheme()
local line_color    = RGB(0, 128, 255) --isDark and RGB(240, 240, 240) or RGB(20, 20, 20)
local os_time	    = os.time
local math_floor	= math.floor
local math_max      = math.max
local math_min      = math.min

_G.unpack           = rawget(table, "unpack") or _G.unpack

_G.Settings= {
    Name 		= "*dVWAP",
    ['1. Период VWAP']                  = 60,
	['2. Кластеров цен в баре']         = 100,
	['3. Сглаживать VWAP']              = 0,
	['4. Период EMA VWAP']              = 28,
	['5. Рассчитывать бар']             = 1000,
	['6. Пересчитывать текущий бар']    = 0,
	['7. Выводить профиль объема']      = 1,
	['8. Граница от максимального объема'] = 0.8,
	['9. Выводить профиль на истории']     = 0,
    -- data_type   = 'Close',
    line = {
        {Name = '*VWAP', Color = line_color, Type  = TYPE_LINE, Width = 2},
        {Name = 'MaxVol', Color = _G.RGB(255, 128, 64), Type = _G.TYPET_BAR, Width = 2},
        {Name = '+0.8*Max', Color = _G.RGB(185, 185, 185), Type = _G.TYPET_BAR, Width = 2},
        {Name = '-0.8*Max', Color = _G.RGB(185, 185, 185), Type = _G.TYPET_BAR, Width = 2}
    }
}

local PlotLines     = function(index) return index end
local error_log     = {}
local lines         = #_G.Settings.line

local function log_tostring(...)
  local args = table.pack(...)
  if args.n == 1 then
    return tostring(args[1])
  end
  for i = 1, args.n do
    args[i] = tostring(args[i])
  end
  return table.concat(args, " ", 1, args.n)
end

function log(...)
	if logFile==nil then return end
    logFile:write(log_tostring(...).."\n");
    logFile:flush();
end

local df = {}
df['C'] = function(i) return C(i) end
df['H'] = function(i) return H(i) end
df['L'] = function(i) return L(i) end
df['O'] = function(i) return O(i) end
df['V'] = function(i) return V(i) end
df['M'] = function(i) return (H(i) + L(i))/2 end
df['T'] = function(i) return (H(i) + L(i) + O(i))/3 end
df['W'] = function(i) return (H(i) + L(i) + O(i) + C(i))/4 end

local function get_data_processor(settings)
	local data = {{}, {}, {}}
	local last_cal_bar
	return function(index)
		if not data[1][1] then
			local i     = math_max(index-settings.period, 0)
			local j     = settings.period
			while not data[1][1] and i < index do
                data[1][j] = df['H'](i)
                data[2][j] = df['L'](i)
                data[3][j] = df['V'](i)
                if data[1][j] then
					j = j - 1
				end
				i = i + 1
			end
            return data
		end
		if last_cal_bar and last_cal_bar ~= index and data[1][1] then
			for kk = last_cal_bar + 1, index do
				table.remove(data[1], 1)
				table.remove(data[2], 1)
				table.remove(data[3], 1)
                data[1][settings.period] = df['H'](kk)
                data[2][settings.period] = df['L'](kk)
                data[3][settings.period] = df['V'](kk)
			end
		end
		if last_cal_bar and last_cal_bar == index and data[1][1] then
            data[1][settings.period] = df['H'](last_cal_bar)
            data[2][settings.period] = df['L'](last_cal_bar)
            data[3][settings.period] = df['V'](last_cal_bar)
        end
		last_cal_bar = index
		return data
	end, data
end

local function F_VWAP(settings)

    settings            = (settings or {})
    local period        = settings.period or 100
    local max_clasters  = settings.clasters or 100
    local calc_bars     = settings.calc_bars or 1000
    local calc_last     = settings.calc_last
    local vol_profile   = settings.vol_profile
    local max_trash     = settings.max_trash or 0.8
    local save_bars     = (settings.save_bars or period)

    calc_bars           = math_max(calc_bars, period)

    local calc_buffer

    local fDATA, data

    local begin_index, start_index
    local max, min
    local jj, kk

    local vwap      = {}
    local prof_vol  = {}
    local cc        = {}
    local step      = 0

    return function(index)

        if index <= period then return vwap, prof_vol end

        if (not data and index > period) or index == begin_index then
            local ds_info   = _G.getDataSourceInfo()
            step            = tonumber(_G.getParamEx(ds_info.class_code, ds_info.sec_code,"SEC_PRICE_STEP").param_value) or 0
            begin_index     = index
            start_index     = math_max(Size()-calc_bars+1, index)
            calc_buffer     = {}
            fDATA, data     = get_data_processor({period = period})
        end

		local c_index = (index == Size() and not calc_last) and index-1 or index
        -- log(index, os.date('%d.%m.%Y %H:%M:%S', os_time(_G.T(index))), 'c_index', c_index, 'last_cal_bar', last_cal_bar, 'calc_buffer', calc_buffer[c_index], 'H', data[1][period], 'L', data[2][period], 'V', data[3][period])

        vwap[index]      = vwap[index] or vwap[index-1]
        prof_vol[index]  = prof_vol[index] or prof_vol[index-1]

        if index < start_index or (not calc_last and calc_buffer[c_index]) then --
			return vwap, prof_vol
		end

        if not CandleExist(index) then
			return vwap, prof_vol
		end

        fDATA(c_index)
        -- log('new data', c_index, 'H', data[1][period], 'L', data[2][period], 'V', data[3][period])

        calc_buffer[c_index]  	= true

        if not data[1][1] then return vwap, prof_vol end

		max = math_max(unpack(data[1]))
		min = math_min(unpack(data[2]))
        local delta     = max - min
        if delta == 0 then return vwap, prof_vol end

        local clasters = max_clasters
        if step > 0 then
            clasters = math_min(math.floor(delta/step), max_clasters)
        end

        for i = 1, clasters do cc[i]={0, i/clasters*(delta)+min, 0} end

        local num_prof  = 0
        local all_vol   = 0
        local max_vol   = 0
        local max_cl    = 0

        vwap[index]      = 0
        prof_vol[index]  = {avg_vol = 0, max_vol = {0, 0}, p_up = {0, 0}, p_dw = {0, 0}} -- avg_vol, max_vol {vol, price}, max_vol+trash {vol, price}, max_vol-trash {vol, price}

        local vol
        for i = 1, period do
            jj = math_floor((data[1][i]-min)/delta*(clasters-1)) + 1
            kk = math_floor((data[2][i]-min)/delta*(clasters-1)) + 1
            for k=1,(jj-kk) do
                if cc[kk+k-1][1] == 0 then num_prof = num_prof + 1 end
                vol           = data[3][i]/(jj-kk)
                cc[kk+k-1][1] = cc[kk+k-1][1]+ vol
                cc[kk+k-1][3] = cc[kk+k-1][3]+1
                vwap[index]   = vwap[index] + cc[kk+k-1][2]*vol
                all_vol       = all_vol + vol
                if cc[kk+k-1][1] > max_vol then
                    max_vol = cc[kk+k-1][1]
                    max_cl  = kk+k-1
                end
            end
        end

        vwap[index] = all_vol == 0 and 0 or vwap[index]/all_vol
        prof_vol[index].avg_vol     = num_prof == 0 and 0 or all_vol/num_prof
        prof_vol[index].max_vol[1]  = max_vol
        prof_vol[index].max_vol[2]  = cc[max_cl][2]

        local cl_up = clasters
        local cl_dw = 1
        local tr    = max_vol*max_trash

        if vol_profile and max_trash < 1 and index >= Size()-1 then
            local found = false
            -- log('-------------------------dw-------------------------')
            for i = max_cl - 1, 1, -1 do
                -- log('claster ', i, found, 'cl_dw', cl_dw, cc[cl_dw][1], cc[i][1], cc[i][2])
                if (cc[i][1] < tr and not found) or (found and cc[i][1] > cc[cl_dw][1]) then
                    cl_dw = i
                    found = true
                    -- log('found', cl_dw, cc[i][1], cc[i][2])
                end
                if cc[i][1] > tr then
                    cl_dw = i
                    found = false
                end
            end
            found = false
            -- log('-------------------------up-------------------------')
            for i = max_cl + 1, clasters do
                -- log('claster ', i, found, 'cl_up', cl_up, cc[cl_up][1], cc[i][1], cc[i][2])
                if (cc[i][1] < tr and not found) or (found and cc[i][1] > cc[cl_up][1]) then
                    cl_up = i
                    found = true
                    -- log('found', cl_up, cc[i][1], cc[i][2])
                end
                if cc[i][1] > tr then
                    cl_up = i
                    found = false
                end
            end
        end

        prof_vol[index].p_up[1]  = cc[cl_up][1]
        prof_vol[index].p_up[2]  = cc[cl_up][2]

        prof_vol[index].p_dw[1]  = cc[cl_dw][1]
        prof_vol[index].p_dw[2]  = cc[cl_dw][2]

        -- log(index, os.date('%d.%m.%Y %H:%M:%S', os_time(_G.T(index))), 'c_index', c_index, vwap[index], 'max_vol', max_vol, 'max_cl', max_cl, prof_vol[index].max_vol[1], prof_vol[index].max_vol[2], 'tr', tr, 'cl_up', cl_up, 'p_up', prof_vol[index].p_up[1], prof_vol[index].p_up[2], 'cl_dw', cl_dw, 'p_dw', prof_vol[index].p_dw[1], prof_vol[index].p_dw[2])

        -- if index == Size()-1 then
        --     log(' clasters: ')
        --     for i = 1, clasters do
        --         log('   ', i, cc[i][2], cc[i][1], cc[i][3])
        --     end
        -- end

        vwap[index-save_bars]       = nil
        prof_vol[index-save_bars]   = nil
        calc_buffer[c_index-1]      = nil

		return vwap, prof_vol

	end, vwap, prof_vol

end


local function Algo(settings)

    settings        = settings or {}
    local vwap_set      = {}
    vwap_set.period     = settings['1. Период VWAP']          or 60
	vwap_set.clasters   = settings['2. Кластеров цен в баре'] or 100
	vwap_set.calc_bars  = settings['5. Рассчитывать бар']     or 1000
	vwap_set.calc_last  = (settings['6. Пересчитывать текущий бар'] or 0) == 1

	local vol_profile    = (settings['7. Выводить профиль объема'] or 1) == 1
	local hist_profile   = (settings['9. Выводить профиль на истории'] or 0) == 1
    vwap_set.vol_profile = vol_profile
    vwap_set.max_trash   = settings['8. Граница от максимального объема'] or 0.8

    local ema_vwap      = (settings['3. Сглаживать VWAP'] or 0) == 1
	local ema_period    = settings['4. Период EMA VWAP'] or 28

    local set_bars      = math_min(vwap_set.period, 50)

    error_log = {}

    local fVWAP, vwap, profile
    local fEMA, ema
    local begin_index

    local out, max_vol, max_1, max_2

    return function (index)

        local status, res = pcall(function()

            if not maLib then return end

            if begin_index == nil or index == begin_index then
                begin_index = index
                fVWAP, vwap, profile = F_VWAP(vwap_set)
                if not fVWAP and not error_log[tostring(vwap)] then
                    error_log[tostring(vwap)] = true
                    log(tostring(vwap))
                    message(tostring(vwap))
                end
                fVWAP(index)
                if ema_vwap then
                    fEMA, ema = maLib.new({method = 'EMA', period = ema_period, data_type = 'Any'}, vwap)
                    if not fEMA and not error_log[tostring(ema)] then
                        error_log[tostring(ema)] = true
                        log(tostring(ema))
                        message(tostring(ema))
                    end
                    fEMA(index)
                end
                return
            end

            if fVWAP then
                if not hist_profile then
                    SetRangeValue(2, index-set_bars-1, index, nil)
                    SetRangeValue(3, index-set_bars-1, index, nil)
                    SetRangeValue(4, index-set_bars-1, index, nil)
                end
                fVWAP(index)
                out = vwap[index]
                if vol_profile and profile[index] and (hist_profile or index == Size()) then
                    max_vol = (profile[index].max_vol or {})[2]
                    max_1 = (profile[index].p_up or {})[2]
                    max_2 = (profile[index].p_dw or {})[2]
                    if not hist_profile then
                        SetRangeValue(2, index-set_bars, index, max_vol)
                        SetRangeValue(3, index-set_bars, index, max_1)
                        SetRangeValue(4, index-set_bars, index, max_2)
                    end
                end
            end
            if fEMA and vwap[index] then
                fEMA(index)
                out = ema[index]
            end

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                log(tostring(res))
                message(tostring(res))
            end
            return nil
        end
        return out, max_vol, max_1, max_2
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