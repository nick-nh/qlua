--[[
	Trendlines with Breaks
	https://ru.tradingview.com/v/IYL88A1N/
]]

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\TrendLines.txt", "w")
_G.unpack 		= rawget(table, "unpack") or _G.unpack

local message               = _G['message']
local SetValue              = _G['SetValue']
local Size              	= _G['Size']
local CandleExist           = _G['CandleExist']
local RGB                   = _G['RGB']
local TYPET_BAR             = _G['TYPET_BAR']
-- local TYPE_LINE             = _G['TYPE_LINE']
-- local TYPE_DASH         	= _G['TYPE_DASH']
local TYPE_POINT    		= _G['TYPE_POINT']
local TYPE_TRIANGLE_UP      = _G['TYPE_TRIANGLE_UP']
local TYPE_TRIANGLE_DOWN    = _G['TYPE_TRIANGLE_DOWN']
-- local isDark                = _G.isDarkTheme()
-- local line_color            = isDark and RGB(240, 240, 240) or RGB(0, 0, 0)
local table_remove  		= table.remove
local math_floor    		= math.floor
local math_max      		= math.max
local math_min      		= math.min
local math_abs      		= math.abs
local math_pow      		= function(x, y) return x^y end
local math_sqrt     		= math.sqrt
local O                     = _G['O']
local C                     = _G['C']
local H                     = _G['H']
local L                     = _G['L']

_G.Settings =
	{
		Name = "**TrendLines with Breaks",
		['01. Период'] 							= 9,
		['02. Коэффициент наклона']				= 1.3,
		['03. Метод расчета']					= "*Atr; Std; Linreg", -- 'Atr', 'Std' или 'Linreg', Установить звездочку перед необходимым методом.
		['04. Смещать линии назад']				= 1,
		['05. Вариант контроля пробоя']			= 'Close; *HL' --Установить звездочку перед необходимым методом.
	}

local lines_set =
{
	{
		Name = "Up Break",
		Type = TYPE_TRIANGLE_UP,
		Width = 4,
		Color = RGB(89,213, 107)
	},
	{
		Name = "Down Break",
		Type = TYPE_TRIANGLE_DOWN,
		Width = 4,
		Color = RGB(255, 58, 0)
	},
	{
		Name 	= "Верхнее продолжение линии",
		Color 	= RGB(0, 128, 128),
		Type 	= TYPE_POINT,
		Width 	= 4
	},
	{
		Name 	= "Нижнее продолжение линии",
		Color 	= RGB(255, 0, 0),
		Type 	= TYPE_POINT,
		Width 	= 4
	},

	{
		Name 	= "Верхняя линия 1",
		Color 	= RGB(0, 128, 128),
		Type 	= TYPET_BAR,
		Width 	= 1
	},
	{
		Name 	= "Нижняя линия 1",
		Color 	= RGB(255, 0, 0),
		Type 	= TYPET_BAR,
		Width 	= 1
	},
}
----------------------------------------------------------

local lines = #lines_set
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

local function log(...)
	if logFile==nil then return end
    logFile:write(os.date('%d.%m.%Y %H:%M:%S', os.time())..': '..log_tostring(...).."\n");
    logFile:flush();
end

local PlotLines     = function(index) return index end
local error_log     = {}
----------------------------------------------------------
----------------------------------------------------------

local df = {}
df['C'] = function(i) return C(i) end
df['H'] = function(i) return H(i) end
df['L'] = function(i) return L(i) end
df['O'] = function(i) return O(i) end
df['M'] = function(i) return (H(i) + L(i))/2 end
df['T'] = function(i) return (H(i) + L(i) + O(i))/3 end
df['W'] = function(i) return (H(i) + L(i) + O(i) + C(i))/4 end

local function CheckIndex(index)
	return CandleExist(index)
end

local function F_ATR(settings)

    local period    = (settings.period or 9)
    local save_bars = (settings.save_bars or period)

    local ATR     = {}
    local p_index
    local l_index

    return function(index)
        ATR[index]      = ATR[index-1] or 0
        if not CheckIndex(index) then
            return ATR
        end
        if index ~= l_index then p_index = l_index end
        local high      = H(index)
        local low       = L(index)
        local p_close   = C(p_index or 1)
        ATR[index]      = high - low
        if p_index then
            ATR[index]  = (ATR[index-1]*(period-1) + math_max(math_abs(high - low), math_abs(high - p_close), math_abs(p_close - low)))/period
        end
        ATR[index-save_bars] = nil
        l_index = index
        return ATR
    end, ATR
end

local function oSigma(input, start, finish, not_shifted)

    start           = math_max(start or 1, 1)
    finish          = finish or #input
    local period    = finish - start + 1
    local denom     = not_shifted and period or (period-1)

    local sum       = 0.0
    local sum_sq    = 0.0
    local std       = 0

    for i = start, finish do
        if input[i] then
            sum     = sum + input[i]
            sum_sq  = sum_sq + math_pow(input[i], 2)
        end
    end

    if period > 1 then
        local variance = (sum_sq - (sum * sum) / period) / denom;
        std = (variance > 1e-15) and math_sqrt(variance) or 0
    end

    return std
end

local function LIN_REG(data)

    local XSum = 0
    local YSum = 0
    local XYSum = 0
    local XXSum = 0
    local YYSum = 0

    for i, y in ipairs (data) do
        XSum = XSum + i
        XXSum = XXSum + i^2

        YSum = YSum + y
        YYSum = YYSum + y^2

        XYSum = XYSum + i*y
    end

    local div = (#data*XXSum)-(XSum^2)
    return ((#data*XYSum) - (XSum*YSum))/div
end

local function get_data_processor(settings)
	local data = {}
	local last_cal_bar
	return function(index)
		if not data[1] then
			local i     = math_max(index-settings.period, 0)
			local j     = settings.period
			while not data[1] and i < index do
				data[j] = C(index)
				if data[j] then
					j = j - 1
				end
				i = i + 1
			end
		end
		if last_cal_bar and last_cal_bar ~= index and data[1] then
			for kk = last_cal_bar + 1, index do
				table.remove(data, 1)
				data[settings.period] = C(kk)
			end
		end
		if last_cal_bar and last_cal_bar == index and data[1] then
			data[settings.period] = C(last_cal_bar)
		end
		last_cal_bar = index
		return data
	end, data
end

local function F_SLOPE(settings)

	if settings.method:upper() == 'ATR' then
		local fATR, atr = F_ATR(settings)
		return function(index)
			fATR(index)
			return (atr[index] or 0) / settings.period * settings.mult
		end
	end
	if settings.method:upper() == 'STD' then
		local fDATA, data = get_data_processor(settings)
		return function(index)
			fDATA(index)
			if data[1] then
				return (oSigma(data, 1, settings.period, true) or 0) / settings.period * settings.mult
			end
		end
	end
	if settings.method:upper() == 'LINREG' then
		local fDATA, data 	= get_data_processor(settings)
		return function(index)
			fDATA(index)
			if data[1] then
				return math_abs(LIN_REG(data) or 0) / 2 * settings.mult
			end
		end
	end
end

local function F_FRAC(settings)

    settings            = (settings or {})

    local period        = (settings.period or 21)
    local save_extr     = (settings.save_bars or 50)

    local fractal_L = {}
    local fractal_H = {}
	local h_tmp     = {}
	local l_tmp     = {}

    local fp        = math_floor(period/2)*2+1
	local i2		= math_floor(fp/2)+2
    local last_index, begin_index

    return function(index, last_bar)

        if begin_index == nil or index == begin_index then
            begin_index = index
            h_tmp       = {}
            l_tmp       = {}
            return fractal_H, fractal_L
        end

        if not CheckIndex(index) then return fractal_H, fractal_L end

        if index ~= last_index then
            last_index      = index
            h_tmp[#h_tmp+1] = H(index)
            l_tmp[#l_tmp+1] = L(index)
        else
            h_tmp[#h_tmp]   = H(index)
            l_tmp[#l_tmp]   = L(index)
        end

        if #h_tmp > fp then
            table_remove(h_tmp, 1)
            table_remove(l_tmp, 1)
        end

        if #h_tmp == fp then

            local sp    = index - fp + 1 + math_floor(fp/2)
            local val_h = math_max(unpack(h_tmp))
            local val_l = math_min(unpack(l_tmp))
            local val_h2 = math_max(unpack(h_tmp, i2))
            local val_l2 = math_min(unpack(l_tmp, i2))

			local fL    = L(sp)
            local fH    = H(sp)

            if (val_h == fH) and (val_h > 0)
                and (val_l == fL) and (val_l > 0) then
                    fractal_H[#fractal_H + 1] = sp
                    fractal_L[#fractal_L + 1] = sp
            else
                if (val_h == fH) and (val_h > 0) and (val_h2 < val_h) then
                    fractal_H[#fractal_H + 1] = sp
                end
                if (val_l == fL) and (val_l > 0) and (val_l2 > val_l) then
                    fractal_L[#fractal_L + 1] = sp
                end
            end
            if last_bar then
                log('index', index, os.date('%d.%m.%Y %H:%M:%S', os.time(_G.T(index))), 'sp', sp, 'FH', fractal_H[#fractal_H], 'FL', fractal_L[#fractal_L], 'fp2', i2, 'val_h', val_h, 'val_l', val_l)
                log('h_tmp', #h_tmp, 'val_h2', h_tmp[i2], '->', table.concat(h_tmp, ','))
                log('l_tmp', #l_tmp, 'val_l2', l_tmp[i2], '->', table.concat(l_tmp, ','))
            end
		end

        if #fractal_H > save_extr then
            table_remove(fractal_H, 1)
        end
        if #fractal_L > save_extr then
            table_remove(fractal_L, 1)
        end

        return fractal_H, fractal_L

    end, fractal_H, fractal_L

end

local function Algo(Fsettings)

	Fsettings			= (Fsettings or {})
	local period 		= Fsettings['01. Период'] or 28
	local mult			= Fsettings['02. Коэффициент наклона'] or 1
	local method 		= Fsettings['03. Метод расчета'] or 'Atr'
	local backpaint		= (Fsettings['04. Смещать линии назад'] or 0) == 1
	local break_type	= Fsettings['05. Вариант контроля пробоя'] or 'HL'

	for val in string.gmatch(method or '*Atr', "([^;]+)") do
        if (val:find('*')) then
            method = val:gsub('*', ''):gsub("^%s*(.-)%s*$", "%1")
            break
        end
    end
	for val in string.gmatch(break_type or '*HL', "([^;]+)") do
        if (val:find('*')) then
            break_type = val:gsub('*', ''):gsub("^%s*(.-)%s*$", "%1")
            break
        end
    end

	local frac_period 	= period*2+1
	local break_points	= true

	local calculated_buffer={}
	error_log = {}

	local out 	= {}

	local begin_index

	local fFrac, frac_h, frac_l
	local fRange

    local on_close      = break_type == 'Close'
    local u_data        = on_close and 'C' or 'H'
    local l_data        = on_close and 'C' or 'L'
    local TREND_DATA 	= {}
    local slope
	local last_index

	local step  	= 0
	return function(index)

		local status, res = pcall(function()

			if index == begin_index or not fRange then

				out = {}
                local ds_info   	= _G.getDataSourceInfo()
                step            	= tonumber(_G.getParamEx(ds_info.class_code, ds_info.sec_code,"SEC_PRICE_STEP").param_value) or 0

				calculated_buffer 	= {}
				begin_index			= index
				fRange 				= F_SLOPE({method = method, period = period, mult = mult})
				fRange(index)
				fFrac, frac_h, frac_l = F_FRAC({period = frac_period})
				fFrac(index)

				TREND_DATA.l_upper  = nil
				TREND_DATA.upper    = nil
				TREND_DATA.h_br     = nil
				TREND_DATA.l_lower  = nil
				TREND_DATA.lower    = nil
				TREND_DATA.l_br     = nil
				last_index 			= index

				log(index, 'start', break_type, on_close)
				return
			end

			local size 		= Size()
			local last_bar 	= index == size
			local c_index 	= last_bar and index-1 or index
			u_data        	= on_close and 'C' or 'H'
			l_data        	= on_close and 'C' or 'L'

			-- if last_bar then
			-- 	log('index', index, os.date('%d.%m.%Y %H:%M:%S', os.time(_G.T(index))), 'last_index', last_index, 'calc', calculated_buffer[index], 'c_index', calculated_buffer[c_index])
			-- end
			if index == last_index and calculated_buffer[c_index] then
				if not on_close then
					local high = df[u_data](index)
					local low  = df[l_data](index)
					if TREND_DATA.l_upper then
	                    local upper    = TREND_DATA.l_upper - TREND_DATA.slope_ph
						if not TREND_DATA.h_br and high > upper then
							out[1] = L(index) - step
							TREND_DATA.h_br = os.date('%d.%m.%Y %H:%M:%S', os.time())
							log('-------------------------------------------------------------------------------------------------------------')
							log('online h break index', index, TREND_DATA.h_br, 'upper', upper, 'high', high)
						end
					end
					if TREND_DATA.l_lower then
					    local lower    = TREND_DATA.l_lower + TREND_DATA.slope_pl
						if not TREND_DATA.l_br and low < lower then
							out[2] = H(index) + step
							TREND_DATA.l_br = os.date('%d.%m.%Y %H:%M:%S', os.time())
							log('-------------------------------------------------------------------------------------------------------------')
							log('online l break index', index, TREND_DATA.l_br, 'lower', lower, 'low', low)
						end
					end
				end
				return
			end

			SetValue(index, 1, nil)
			SetValue(index, 2, nil)
			SetValue(index, 3, nil)
			SetValue(index, 4, nil)

			--Calc
			out = {}

			-- if index ~= last_index then
			-- 	TREND_DATA.l_upper  = TREND_DATA.upper
			-- 	TREND_DATA.l_lower  = TREND_DATA.lower
			-- 	last_index			= index
			-- end

			local ph, pl

			if not calculated_buffer[c_index] then

				-- if index >= size-1 then
				-- 	log('-------------------------------------------------------------------------------------------------------------')
				-- 	log('calc c_index', c_index, os.date('%d.%m.%Y %H:%M:%S', os.time(_G.T(c_index))), 'TREND_DATA.l_upper', TREND_DATA.l_upper, 'TREND_DATA.l_lower', TREND_DATA.l_lower)
				-- end

				fFrac(c_index, index >= size-1)
				slope = fRange(c_index)

				ph = frac_h[#frac_h] == c_index - period
				pl = frac_l[#frac_l] == c_index - period
				if slope then
					if ph then
						local fi = frac_h[#frac_h]
						TREND_DATA.slope_ph = slope
						TREND_DATA.upper 	= H(fi)
						TREND_DATA.h_br 	= nil
						for i = 0, period-1 do
							if backpaint then
								SetValue(fi+i, 5, TREND_DATA.upper)
							end
							TREND_DATA.l_upper  = TREND_DATA.upper
							TREND_DATA.upper 	= TREND_DATA.upper - slope
						end
						SetValue(c_index, 5, TREND_DATA.upper)
						if not last_bar then out[3] = TREND_DATA.upper end
						SetValue(c_index, 3, TREND_DATA.upper)
					elseif TREND_DATA.l_upper and TREND_DATA.slope_ph then
						TREND_DATA.upper = TREND_DATA.l_upper - TREND_DATA.slope_ph
					end
					if pl then
						local fi = frac_l[#frac_l]
						TREND_DATA.slope_pl = slope
						TREND_DATA.lower 	= L(fi)
						TREND_DATA.l_br 	= nil
						for i = 0, period-1 do
							if backpaint then
								SetValue(fi+i, 6, TREND_DATA.lower)
							end
							TREND_DATA.l_lower  = TREND_DATA.lower
							TREND_DATA.lower 	= TREND_DATA.lower + slope
						end
						SetValue(c_index, 6, TREND_DATA.lower)
						if not last_bar then out[4] = TREND_DATA.lower end
						SetValue(c_index, 4, TREND_DATA.lower)
					elseif TREND_DATA.l_lower and TREND_DATA.slope_pl then
						TREND_DATA.lower = TREND_DATA.l_lower + TREND_DATA.slope_pl
					end
				end
			end

			if break_points then
				u_data = ph and 'C' or u_data
				if not TREND_DATA.h_br and TREND_DATA.upper and df[ph and 'C' or u_data](c_index) > TREND_DATA.upper then
					if not last_bar then out[1] = L(c_index) - step end
					SetValue(c_index, 1, L(c_index) - step)
					TREND_DATA.h_br = os.date('%d.%m.%Y %H:%M:%S', os.time(_G.T(c_index)))
				end
				l_data = pl and 'C' or l_data
				if not TREND_DATA.l_br and TREND_DATA.lower and df[l_data](c_index) < TREND_DATA.lower then
					if not last_bar then out[2] = H(c_index) + step end
					SetValue(c_index, 2, H(c_index) + step)
					TREND_DATA.l_br = os.date('%d.%m.%Y %H:%M:%S', os.time(_G.T(c_index)))
				end
			end

        if index >= size-1 then
			log('-------------------------------------------------------------------------------------------------------------')
			log('size', size, 'index', index, 'last_index', last_index, 'c_index', c_index, os.date('%d.%m.%Y %H:%M:%S', os.time(_G.T(c_index))), 'calc', calculated_buffer[index], 'c_index', calculated_buffer[c_index], 'u_data', u_data, df[u_data](c_index), 'l_data', l_data, df[l_data](c_index), 'slope', slope, 'ph', ph, 'pl', pl, 'TREND_DATA.h_br', TREND_DATA.h_br, 'TREND_DATA.l_br', TREND_DATA.l_br, 'TREND_DATA.slope_ph', TREND_DATA.slope_ph, 'TREND_DATA.slope_pl', TREND_DATA.slope_pl, 'TREND_DATA.upper', TREND_DATA.upper, TREND_DATA.l_upper, 'TREND_DATA.lower', TREND_DATA.lower, TREND_DATA.l_lower)
			log(df[u_data](c_index), TREND_DATA.upper, TREND_DATA.upper and df[u_data](c_index) > TREND_DATA.upper, df[u_data](c_index-1), TREND_DATA.l_upper, TREND_DATA.l_upper and df[u_data](c_index-1) <= TREND_DATA.l_upper)
			log(df[u_data](c_index), TREND_DATA.lower, TREND_DATA.lower and df[u_data](c_index) < TREND_DATA.lower, df[u_data](c_index-1), TREND_DATA.l_lower, TREND_DATA.l_lower and df[u_data](c_index-1) >= TREND_DATA.l_lower)
		end

			calculated_buffer[c_index]  = true

			--Для установки на истории
			out[5] = TREND_DATA.l_upper and TREND_DATA.l_upper - TREND_DATA.slope_ph
			out[6] = TREND_DATA.l_lower and TREND_DATA.l_lower + TREND_DATA.slope_pl

			--Для следующего бара текущее становится прошлым
			TREND_DATA.l_upper  = TREND_DATA.upper
			TREND_DATA.l_lower  = TREND_DATA.lower

			-- для текущего бара необходимо вывести новое будущее значение
			if last_bar then
				out[5] = TREND_DATA.l_upper and TREND_DATA.l_upper - TREND_DATA.slope_ph
				out[6] = TREND_DATA.l_lower and TREND_DATA.l_lower + TREND_DATA.slope_pl
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

		--log('return', index, os.date('%d.%m.%Y %H:%M:%S', os.time(_G.T(index))), unpack(out, 1, lines))

		return unpack(out, 1, lines)
	end

end
----------------------------    ----------------------------    ----------------------------
----------------------------    ----------------------------    ----------------------------
----------------------------    ----------------------------    ----------------------------

function _G.Init()
	_G.Settings.line 		= {}
	for i, line in ipairs(lines_set) do
		_G.Settings.line[i] = line
	end
	lines = #lines_set
	PlotLines = Algo(_G.Settings)
	return lines
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
	return PlotLines(index)
end