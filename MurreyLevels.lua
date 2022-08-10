--[[
	nick-h@yandex.ru
    https://github.com/nick-nh/qlua

    Murrey Levels (Murrey Math Trading System For All Markets)
]]

--[[
•   Уровни 8/8 и 0/8 (Окончательное сопротивление). Эти уровни самые сильные и оказывают сильнейшие сопротивления и поддержку.
•   Уровень 7/8  (Слабый, место для остановки и разворота).
	Этот уровень слаб. Если цена зашла слишком далеко и слишком быстро и если она остановилась около этого уровня, значит она развернется и будет резкое движение вниз.
	Если цена не остановилась около этого уровня, она продолжит движение вверх к 8/8.
•   Уровень 1/8  (Слабый, место для остановки и разворота). Эта уровень слаб.
	Если цена зашла слишком далеко и слишком быстро и если она остановилась около этого уровня, значит она развернется и будет резкое движение вверх.
	Если цена не остановилась около этого уровня, она продолжит движение вниз к 0/8.
•   Уровни 6/8 и 2/8 (Вращение, разворот). Эти два уровня уступают в своей способности полностью развернуть ценовое движение только уровню 4/8.
•   Уровень 5/8 (Верх торгового диапазона). Инструменты всех рынков тратят 43.75% времени, на движение между уровнями 5/8 и 3/8.
	Если цена двигается около уровня 5/8 и остается около него в течении 10-12 дней(баров), рынок говорит нам, что следует продавать в этой «премиальной зоне»,
	что и делают некоторые трейдеры, но если цена сохраняет тенденцию оставаться выше 5/8, то она и останется выше него.
	Однако, если цена падает ниже уровня 5/8, то она скорее всего продолжит падать до следующего уровня сопротивления.
•   Уровень 3/8 (Дно торгового диапазона). Если цена ниже этого уровня и двигается вверх, то ей будет сложно пробить этот уровень.
	Если цена пробивает вверх этот уровень и остается выше него в течении 10-12 дней, значит цена останется выше этого уровня и потратит 43,75% времени двигаясь между уровнями 3/8 и 5/8.
•   Уровень 4/8 (Главный уровень поддержки/сопротивления). Этот уровень обеспечивает наилучшую поддержку/сопротивление.
	Он является лучшим для новой покупки или продажи. Если цена находится выше 4/8, то это сильный уровень поддержки.
	Если цена находится ниже 4/8, то это прекрасный уровень сопротивления.
]]

_G.unpack = rawget(table, "unpack") or _G.unpack
_G.load   = _G.loadfile or _G.load

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\MurreyLevels.txt", "w")

local message       = _G['message']
local RGB           = _G['RGB']
local Size          = _G['Size']
local CandleExist   = _G['CandleExist']
local SetValue   	= _G['SetValue']
local TYPET_BAR     = _G['TYPET_BAR']
local os_time	    = os.time
local math_floor    = math.floor
local math_max      = math.max
local math_min      = math.min
local math_log      = math.log
local math_pow		= function(x, y) return x^y end

_G.Settings={
	Name = "*Murrey Levels",
	['Период']								= 64,
	['Сдвиг бар'] 							= 0, -- Определять амплитуду на периоде бар, сдвинутых на значение
	['Показывать историю'] 					= 0, -- Выводить уровни, рассчитанные на исторических данных
	--[[
		Уровни +2/8 и -2/8, слабые уровни, при их пробое актуальная октава пересчитывается и уровни перестраиваются, это важно знать.
		Сразу хотелось бы отметить, что сам Хеннинг Мюррей, работая на дневных графиках, использовал их немного по-другому и пересчитывал октаву,
		только в случае закрытия 4-х свечей выше уровня +2/8 или ниже уровня -2/8. Это правило можно применять касаемо дневных графиков.
	]]
	['Число бар за +/- 2 для перестроения']	= 0,
	['Добавить пробел при перестроении'] 	= 0, -- При перестроении уровней добавить пробел, для визульного разделения
	line={
			{
				Name = "[-2/8]",
				Type = TYPET_BAR,
				Width = 2,
				Color = RGB(255,0, 255)
			},
			{
				Name = "[-1/8]",
				Type = TYPET_BAR,
				Width = 2,
				Color = RGB(255,191, 191)
			},
			{
				Name = "[0/8] Окончательное сопротивление",
				Type = TYPET_BAR,
				Width = 2,
				Color = RGB(0,128, 255)
			},
			{
				Name = "[1/8] Слабый, место для остановки и разворота",
				Type = TYPET_BAR,
				Width = 2,
				Color = RGB(218,188, 18)
			},
			{
				Name = "[2/8] Вращение, разворот",
				Type = TYPET_BAR,
				Width = 2,
				Color = RGB(255,0, 128)
			},
			{
				Name = "[3/8] Дно торгового диапазона",
				Type = TYPET_BAR,
				Width = 2,
				Color = RGB(120,220, 235)
			},
			{
				Name = "[4/8] Главный уровень поддержки/сопротивления",
				Type = TYPET_BAR,
				Width = 2,
				Color = RGB(128,128, 128)--green
			},
			{
				Name = "[5/8] Верх торгового диапазона",
				Type = TYPET_BAR,
				Width = 2,
				Color = RGB(120,220, 235)
			},
			{
				Name = "[6/8] Вращение, разворот",
				Type = TYPET_BAR,
				Width = 2,
				Color = RGB(255,0, 128)
			},
			{
				Name = "[7/8] Слабый, место для остановки и разворота",
				Type = TYPET_BAR,
				Width = 2,
				Color = RGB(218,188, 18)
			},
			{
				Name = "[8/8] Окончательное сопротивление",
				Type = TYPET_BAR,
				Width = 2,
				Color = RGB(0,128, 255)
			},
			{
				Name = "[+1/8]",
				Type = TYPET_BAR,
				Width = 2,
				Color = RGB(255,191, 191)
			},
			{
				Name = "[+2/8]",
				Type = TYPET_BAR,
				Width = 2,
				Color = RGB(255,0, 255)
			}
		}
}

local H 			= _G['H']
local L 			= _G['L']
local C 			= _G['C']
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


local function DetermineFractal(v)

	if v<=250000 and v>25000 then
	   return 100000
	end
	if v<=25000 and v>2500 then
	   return 10000
	end
	if v<=2500 and v>250 then
	   return 1000
	end
	if v<=250 and v>25 then
	   return 100
	end
	if v<=25 and v>12.5 then
	   return 12.5
	end
	if v<=12.5 and v>6.25 then
	   return 12.5
	end
	if v<=6.25 and v>3.125 then
	   return 6.25
	end
	if v<=3.125 and v>1.5625 then
	   return 3.125
	end
	if v<=1.5625 and v>0.390625 then
	   return 1.5625
	end
	if v<=0.390625 and v>0 then
	   return 0.1953125
	end

	return 0

end

function Algo(Fsettings)

	local period 			= Fsettings['Период'] or 64
	local stepback 			= Fsettings['Сдвиг бар'] or 0
	local use_gap 			= Fsettings['Добавить пробел при перестроении'] or 0
	local show_old_levels 	= Fsettings['Показывать историю'] or 0
	local bars_to_recalc 	= Fsettings['Число бар за +/- 2 для перестроения'] or 0

	error_log   = {}

    local begin_index

	local out
	local cacheL
	local cacheH
	local last_val, set_gap
	local cross_bars = 0
	local last_calc

	return function(index)

		local m = 0
		local h = 0
		local fractal = 0
		local range = 0
		local sum = 0
		local mn = 0
		local mx = 0
		local octave = 0

        local status, res = pcall(function()


			if index == begin_index or not cacheL then

				begin_index 	= index
				cross_bars	 	= 0

				cacheL 			= {}
				cacheL[index] 	= 0
				cacheH 			= {}
				cacheH[index] 	= 0

				out				= {}
				for nn = 1, 13 do
					out[nn] = show_old_levels == 1 and C(index) or nil
				end

				last_calc 		= index
				return nil

			end

			cacheL[index] = cacheL[index-1]
			cacheH[index] = cacheH[index-1]

			if not CandleExist(index) then
				return nil
			end

			cacheH[index] = H(index-1) or cacheH[index]
			cacheL[index] = L(index-1) or cacheL[index]
			cacheH[index - (period+stepback) - 2] = nil
			cacheL[index - (period+stepback) - 2] = nil

			if (index < (Size()-6) and show_old_levels == 0) or (index <= (period + stepback + 1)) then
				return nil
			end

			if last_calc == index then
				return
			end

			last_calc 		= index

			if show_old_levels == 0 then
				for nn = 1, 13 do
					SetValue(Size()-6, nn, nil)
				end
			end

			m 		= math_min(unpack(cacheL,index-(period+stepback),index))
			h 		= math_max(unpack(cacheH,index-(period+stepback),index))

			fractal = DetermineFractal(h)
			range 	= h-m
			sum 	= math_floor(math_log(fractal/range)/math_log(2))
			octave	= fractal*(math_pow(0.5,sum))

			mn 		= math_floor(m/octave)*octave
			mx 		= mn+(2*octave)
			if (mn+octave) >= h then
				mx = mn+octave
			end

	        -- myLog('index', index, os.date('%d.%m.%Y %H:%M:%S', os_time(_G.T(index))), 'Close', C(index), 'm', m, 'h', h, 'fractal', fractal, 'range', range, 'sum', sum, 'octave', octave, 'mn', mn, 'mx', mx)

			-- calculating xx
			--x2
			local x2=0
			if ((m>=(3*(mx-mn)/16+mn)) and (h<=(9*(mx-mn)/16+mn))) then
				x2=mn+(mx-mn)/2
			end
			--x1
			local x1=0
			if ((m>=(mn-(mx-mn)/8)) and (h<=(5*(mx-mn)/8+mn)) and (x2==0)) then
				x1=mn+(mx-mn)/2
			end

			--x4
			local x4=0
			if ((m>=(mn+7*(mx-mn)/16)) and (h<=(13*(mx-mn)/16+mn))) then
				x4=mn+3*(mx-mn)/4
			end

			--x5
			local x5=0
			if ((m>=(mn+3*(mx-mn)/8)) and (h<=(9*(mx-mn)/8+mn)) and (x4==0)) then
				x5=mx
			end

			--x3
			local x3=0
			if ((m>=(mn+(mx-mn)/8)) and (h<=(7*(mx-mn)/8+mn)) and (x1==0) and (x2==0) and (x4==0) and (x5==0)) then
				x3=mn+3*(mx-mn)/4
			end

			--x6
			local x6=0
			if (x1+x2+x3+x4+x5)==0 then
				x6=mx
			end

			local finalH=x1+x2+x3+x4+x5+x6

	        -- myLog('--', x1, x2, x3, x4, x5, x6, finalH)


			-- calculating yy
			--y1
			local y1=0
			if x1>0 then
				y1=mn
			end

			--y2
			local y2=0
			if x2>0 then
				y2=mn+(mx-mn)/4
			end

			--y3
			local y3=0
			if x3>0 then
				y3=mn+(mx-mn)/4
			end

			--y4
			local y4=0
			if x4>0 then
				y4=mn+(mx-mn)/2
			end

			--y5
			local y5=0
			if x5>0 then
				y5=mn+(mx-mn)/2
			end

			--y6
			local y6=0
			if finalH>0 and (y1+y2+y3+y4+y5)==0 then
				y6=mn
			end

			local finalL = y1+y2+y3+y4+y5+y6

	        -- myLog('--', y1, y2, y3, y4, y5, y6, finalL)

			local dmml = (finalH-finalL)/8

			local m_2_8 = (finalL - dmml*2) -- -2/8
			local p_2_8 = m_2_8 + dmml*12	-- +2/8

			-- myLog('--', 'm_2_8', m_2_8, out[1], 'p_2_8', p_2_8, out[13], 'cross_bars', cross_bars)
			if bars_to_recalc > 0 and out[1] and out[13] and (m_2_8 < out[1] or p_2_8 > out[13]) then
				if C(index) > out[13] then
					cross_bars = cross_bars + 1
				end
				if C(index) < out[1] then
					cross_bars = cross_bars + 1
				end
				if cross_bars < bars_to_recalc then
					return
				end
			end

			out[1] = m_2_8
			for nn = 2, 13 do
				out[nn]=out[nn-1] + dmml
			end

			cross_bars = 0

        end)
        if not status then
            if not error_log[tostring(res)] then
                error_log[tostring(res)] = true
                myLog(tostring(res))
                message(tostring(res))
            end
            return nil
        end

		set_gap 	= last_val~=nil and out[1] ~= last_val
		last_val 	= out[1]

		if use_gap == 1 and set_gap then
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