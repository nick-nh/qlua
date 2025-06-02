--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	Nadaraya-Watson kernel regression
]]

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\kReg.txt", "w")
_G.unpack 		= rawget(table, "unpack") or _G.unpack
local math_pow 	= function(x, y) return x^y end

local message               = _G['message']
local SetValue              = _G['SetValue']
local Size              	= _G['Size']
local CandleExist           = _G['CandleExist']
local RGB                   = _G['RGB']
local TYPE_LINE             = _G['TYPE_LINE']
local TYPE_DASHLINE         = _G['TYPE_DASHLINE']
local TYPE_TRIANGLE_UP      = _G['TYPE_TRIANGLE_UP']
local TYPE_TRIANGLE_DOWN    = _G['TYPE_TRIANGLE_DOWN']
local TYPE_DASH         	= _G['TYPE_DASH']
local TYPE_BAR         		= _G['TYPET_BAR']
local isDark                = _G.isDarkTheme()
local line_color            = isDark and RGB(240, 240, 240) or RGB(0, 0, 0)
local os_time	            = os.time
local math_abs	            = math.abs
local math_exp	            = math.exp
local math_sqrt	            = math.sqrt
local O                     = _G['O']
local C                     = _G['C']
local H                     = _G['H']
local L                     = _G['L']

_G.Settings =
	{
		Name = "*kReg",
		['01. Период'] 							= 200,
		['02. Окно оценки']						= 8,
		['03. Отклонение1']						= 3.0,
		['04. Отклонение2']						= 0.0,
		['05. Отклонение3']						= 0.0,
		['06. Отклонение4']						= 0.0,
		['07. Вариант расчета ядра']			= 1, -- 1- nw kernel, 2 - Gaussian, 3 quartic_biweight, 4 Epanechnikov
		['08. Выводить точки пробоя']			= 0,
		['09. Вариант данных']					= 'C', -- C, O, H, L, M, T, W
		['10. Сдвиг бар']						= 0,
		['11. Рассчитывать бар истории']		= 0,
	}

local lines_set =
{
	{
		Name = "kReg",
		Color = line_color,
		Type = TYPE_LINE,
		Width = 1
	},
	{
		Name = "+kReg1",
		Color = RGB(0, 128, 0),
		Type = TYPE_LINE,
		Width = 1
	},
	{
		Name = "-kReg1",
		Color = RGB(192, 0, 0),
		Type = TYPE_DASHLINE,
		Width = 1
	},
	{
		Name = "+kReg2",
		Color = RGB(0, 128, 0),
		Type = TYPE_LINE,
		Width = 1
	},
	{
		Name = "-kReg2",
		Color = RGB(192, 0, 0),
		Type = TYPE_DASHLINE,
		Width = 1
	},
	{
		Name = "+kReg3",
		Color = RGB(0, 128, 0),
		Type = TYPE_LINE,
		Width = 1
	},
	{
		Name = "-kReg3",
		Color = RGB(192, 0, 0),
		Type = TYPE_DASHLINE,
		Width = 1
	},
	{
		Name = "+kReg4",
		Color = RGB(0, 128, 0),
		Type = TYPE_LINE,
		Width = 1
	},
	{
		Name = "-kReg4",
		Color = RGB(192, 0, 0),
		Type = TYPE_DASHLINE,
		Width = 1
	},
	--10
	{
		Name = "change dir up",
		Type = TYPE_TRIANGLE_UP,
		Width = 3,
		Color = RGB(89,213, 107)
	},
	--11
	{
		Name = "change dir dw",
		Type = TYPE_TRIANGLE_DOWN,
		Width = 3,
		Color = RGB(255, 58, 0)
	},
	--12
	{
		Name = "RegPredictPoint",
		Color = line_color,
		Type = _G.TYPE_POINT,
		Width = 3
	},
	--13
	{
		Name = "kReg_hist",
		Type = TYPE_DASH,
		Width = 1,
		Color = line_color
	},
	--14
	{
		Name = "+kReg_hist",
		Color = RGB(0, 128, 0),
		Type = TYPE_BAR,
		Width = 1
	},
	--15
	{
		Name = "-kReg_hist",
		Color = RGB(192, 0, 0),
		Type = TYPE_BAR,
		Width = 1
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

local function myLog(...)
	if logFile==nil then return end
    logFile:write(tostring(os.date("%c",os_time())).." "..log_tostring(...).."\n");
    logFile:flush();
end

local PlotLines     = function(index) return index end
local error_log     = {}
----------------------------------------------------------
----------------------------------------------------------

--kernel regression
local k_functor = {}
--nw kernel
k_functor[1] = function(u, h)
    local b2h = h*h*2
    local k = math_exp(-math_pow(u, 2)/b2h)
    return k
end
--gaussian_kernel
k_functor[2] = function(u, h, c, scale)
   --2.506628274631000 -- approx sqrt(2*M_PI)
    u = u/h
    c = c or 0.001
    local k = math_exp(-0.5 * math_pow(u, 2))/(2.506628274631000)
    if (k < c) then
        return 0.0
    end
    return scale and k/h or k
end
--epanechnikov_kernel
k_functor[3] = function(u, h, scale)
    u = u/h
    local k = 0.0
    if (math_abs(u) < 1) then
        k = 0.75 * (1.0 - math_pow(u, 2))
    end
    return scale and k/h or k
end
--quartic_biweight_kernel
k_functor[4] = function(u, h, scale)
    u = u/h
    local k = 0.0
    if (math_abs(u) < 1) then
        k = 0.9375 * math_pow(1.0 - math_pow(u, 2), 2)
    end
    return scale and k/h or k
end

--data array of x and Y
--[[
    data = {
    {x = 25, y = 75},
    {x = 27, y = 70},
    {x = 30, y = 78},
    {x = 33, y = 90},
    {x = 40, y = 100},
    {x = 50, y = 120},
    {x = 52, y = 110},
    {x = 54, y = 106},
    {x = 60, y = 120}
}
]]
local function kernel_regression(data, lookback, k_type, k_m)

    local kernel_evaluator = k_functor[k_type or 1] or k_functor[1]

    if not kernel_evaluator then return end
    if not data or #data == 0 then return end

	local size 	= #data
    local se 	= 0
    local y  	= {}
	k_m			= k_m or {}
	local sum_w, sum_wy
    for i = 1, size do
		k_m[i]	= k_m[i] or {}
        sum_w  	= 0
        sum_wy 	= 0
        for j = 1, size do
            local k 	= k_m[i][j] or kernel_evaluator((data[i].x or i)-(data[j].x or j), lookback)
			--save prediction weights
			k_m[i][j]	= k
            sum_wy  	= sum_wy + data[j].y*k
            sum_w   	= sum_w + k
        end
        y[i]    = sum_wy/sum_w
        se      = se + (data[i].y - y[i])^2
    end
    return y, math_sqrt(se/(size-1)), k_m
end

local function Reg(Fsettings)

	Fsettings			= (Fsettings or {})
	local period 		= Fsettings['01. Период'] or 182
	local lookback		= Fsettings['02. Окно оценки'] or 50
	local kstd1 		= Fsettings['03. Отклонение1'] or 1
	local kstd2 		= Fsettings['04. Отклонение2'] or 2
	local kstd3 		= Fsettings['05. Отклонение3'] or 3
	local kstd4 		= Fsettings['06. Отклонение4'] or 4
	local k_type 		= Fsettings['07. Вариант расчета ядра'] or 1
	local break_points	= (Fsettings['08. Выводить точки пробоя'] or 0) == 1
	local data_type		= Fsettings['09. Вариант данных'] or 'C'
	local bars_shift 	= Fsettings['10. Сдвиг бар'] or 0
	local calc_bars 	= Fsettings['11. Рассчитывать бар истории'] or 0

	local k_m
	local est		= {}
	local sq		= 0
	local calculated_buffer={}
	error_log = {}

	local out 	= {}
    local data

	local df = {}
	df['C'] = function(i) return C(i) end
	df['H'] = function(i) return H(i) end
	df['L'] = function(i) return L(i) end
	df['O'] = function(i) return O(i) end
	df['M'] = function(i) return (H(i) + L(i))/2 end
	df['T'] = function(i) return (H(i) + L(i) + O(i))/3 end
	df['W'] = function(i) return (H(i) + L(i) + O(i) + C(i))/4 end

	local trend
	local last_cal_bar
	local start_index, c_index

    local function get_y(index)
        return df[data_type](index)
    end

	return function(index)

		local status, res = pcall(function()

			if index == 1 then

				out = {}

				calculated_buffer 	= {}
				est 			= {}
				est[1]			= 0
				data        	= {}

				start_index 	= bars_shift == 0 and (Size() - calc_bars) or (Size() - bars_shift)
				last_cal_bar 	= nil
				trend			= {}
				trend[index]	= 0
				return
			end

			if index < start_index then return nil end

			if calculated_buffer[index] ~= nil then
				return
			end

			trend[index] = trend[index - 1]

			if bars_shift == 0 then
				SetValue(index-period - bars_shift, 1, nil)
				SetValue(index-period - bars_shift, 2, nil)
				SetValue(index-period - bars_shift, 3, nil)
				SetValue(index-period - bars_shift, 4, nil)
				SetValue(index-period - bars_shift, 5, nil)
				SetValue(index-period - bars_shift, 6, nil)
				SetValue(index-period - bars_shift, 7, nil)
				SetValue(index-period - bars_shift, 8, nil)
				SetValue(index-period - bars_shift, 9, nil)

				SetValue(index-period - bars_shift-1, 1, nil)
				SetValue(index-period - bars_shift-1, 2, nil)
				SetValue(index-period - bars_shift-1, 3, nil)
				SetValue(index-period - bars_shift-1, 4, nil)
				SetValue(index-period - bars_shift-1, 5, nil)
				SetValue(index-period - bars_shift-1, 6, nil)
				SetValue(index-period - bars_shift-1, 7, nil)
				SetValue(index-period - bars_shift-1, 8, nil)
				SetValue(index-period - bars_shift-1, 9, nil)
			end

			--Calc
			out = {}

			if not CandleExist(index) or index <= period then
				return
			end

			local last_bar = index == Size()
			c_index = last_bar and index-1 or index
			if last_cal_bar == c_index then return nil end

			if bars_shift == 0 or index == start_index then

				if not data[1] then
					local i     = 0
					local j     = period
					while not data[1] and i < c_index do
						data[j] = {y = get_y(c_index-i)}
						if data[j].y then
							j = j - 1
						end
						i = i + 1
					end
				end
				if last_cal_bar and last_cal_bar ~= c_index and data[1] then
					for kk = last_cal_bar + 1, c_index do
						table.remove(data, 1)
						data[period] = {y = get_y(kk)}
					end
				end
				last_cal_bar = c_index

				est, sq, k_m = kernel_regression(data, lookback, k_type, bars_shift ~= 0 and k_m or nil)

				local h_index, h_up, h_dw, new_up, old_up, new_dw, old_dw
				local p = (bars_shift == 0 or index == start_index) and period or 1
				for n = 1, p do
					h_index = index+n-p
					SetValue(h_index, 1, est[n])
					if kstd1 > 0 then
						SetValue(h_index, 2, est[n]+sq*kstd1)
						SetValue(h_index, 3, est[n]-sq*kstd1)
					end
					if kstd2 > 0 then
						SetValue(h_index, 4, est[n]+sq*kstd2)
						SetValue(h_index, 5, est[n]-sq*kstd2)
					end
					if kstd3 > 0 then
						SetValue(h_index, 6, est[n]+sq*kstd3)
						SetValue(h_index, 7, est[n]-sq*kstd3)
					end
					if kstd4 > 0 then
						SetValue(h_index, 8, est[n]+sq*kstd4)
						SetValue(h_index, 9, est[n]-sq*kstd4)
					end
					if break_points and n>1 then
						h_up = est[n-1]+sq*kstd1
						h_dw = est[n-1]-sq*kstd1
						new_up = C(h_index)
						old_up = C(h_index-1)
						new_dw = C(h_index)
						old_dw = C(h_index-1)
						if new_dw < h_dw and old_dw >= h_dw then
							SetValue(h_index+1, 10, O(h_index+1))
						end
						if new_up > h_up and old_up <= h_up then
							SetValue(h_index+1, 11, O(h_index+1))
						end
					end
				end

				out[1] = est[#est]

				if bars_shift ~= 0 and index == start_index then
					out[12] = out[1]
					SetValue(index, 12, out[1])
				end

				if kstd1 > 0 then
					out[2] = out[1]+sq*kstd1
					out[3] = out[1]-sq*kstd1
				end
				if kstd2 > 0 then
					out[4] = out[1]+sq*kstd2
					out[5] = out[1]-sq*kstd2
				end
				if kstd3 > 0 then
					out[6] = out[1]+sq*kstd3
					out[7] = out[1]-sq*kstd3
				end
				if kstd4 > 0 then
					out[8] = out[1]+sq*kstd4
					out[9] = out[1]-sq*kstd4
				end
				if break_points then
					if C(index-1) < out[3] and C(index-2) >= out[3] then
						out[10] = O(index) or nil
					end
					if C(index-1) > out[2] and C(index-2) <= out[2] then
						out[11] = O(index) or nil
					end
				end
			end
			if (index >= start_index and calc_bars > 0) then
				out[13] = out[1]
				out[14] = out[1]+sq*kstd1
				out[15] = out[1]-sq*kstd1
			end
			calculated_buffer[index] = true

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
----------------------------    ----------------------------    ----------------------------
----------------------------    ----------------------------    ----------------------------
----------------------------    ----------------------------    ----------------------------

function _G.Init()
	_G.Settings.line 		= {}
	for i, line in ipairs(lines_set) do
		_G.Settings.line[i] = line
	end
	lines = #lines_set
	PlotLines = Reg(_G.Settings)
	return lines
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)
	return PlotLines(index)
end