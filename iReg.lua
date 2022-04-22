--[[
	nick-h@yandex.ru
	https://github.com/nick-nh/qlua

	Регрессия: линейная, параболическая, кубическая
]]

local logFile = nil
-- logFile = io.open(_G.getWorkingFolder().."\\LuaIndicators\\iReg.txt", "w")

local math_pow = function(x, y) return x^y end

local message               = _G['message']
local SetValue              = _G['SetValue']
local Size              	= _G['Size']
local CandleExist           = _G['CandleExist']
local RGB                   = _G['RGB']
local TYPE_LINE             = _G['TYPE_LINE']
local TYPE_DASHLINE         = _G['TYPE_DASHLINE']
local TYPE_DASH         	= _G['TYPE_DASH']
local C                     = _G['C']
local isDark                = _G.isDarkTheme()
local line_color            = isDark and RGB(240, 240, 240) or RGB(0, 0, 0)
local os_time	            = os.time

_G.Settings =
	{
		Name = "*iReg",
		['Период'] 							= 200,
		['Отклонение1']						= 1.0,
		['Отклонение2']						= 2.0,
		['Отклонение3']						= 3.0,
		['Отклонение4']						= 4.0,
		['Вид регрессии'] 					= 1, -- 1 linear, 2 parabolic, 3 third-power
		-- Сдвиг бар
		-- Если задан сдвиг, то построение канала начинается от бара, смещенного на сдвиг.
		-- Далее идет продолжение канала по расчитанным данным (предсказание). Пересчет не производится.
		-- Это позволит оценить качество построенного канала на истории, относительно новых данных.
		['Сдвиг бар']						= 0,
		-- Показывать историю
		-- Показывается канал на исторических данных. Расчет для каждого бара истории.
		['Показывать историю']				= 0,
		--Пересчитывать при отклонении
		-- при расчете без сдвига, после построения канала, если цена зашла за границу отклонения,
		-- то происходит полный пересчет канала. Иначе идет продолжение исходного канала.
		['Пересчитывать при отклонении >']	= 3,
		line=
			{
				{
					Name = "iReg",
					Color = line_color,
					Type = TYPE_LINE,
					Width = 1
				},
				{
					Name = "+iReg1",
					Color = RGB(0, 128, 0),
					Type = TYPE_LINE,
					Width = 1
				},
				{
					Name = "-iReg1",
					Color = RGB(192, 0, 0),
					Type = TYPE_DASHLINE,
					Width = 1
				},
				{
					Name = "+iReg2",
					Color = RGB(0, 128, 0),
					Type = TYPE_LINE,
					Width = 1
				},
				{
					Name = "-iReg2",
					Color = RGB(192, 0, 0),
					Type = TYPE_DASHLINE,
					Width = 1
				},
				{
					Name = "+iReg3",
					Color = RGB(0, 128, 0),
					Type = TYPE_LINE,
					Width = 1
				},
				{
					Name = "-iReg3",
					Color = RGB(192, 0, 0),
					Type = TYPE_DASHLINE,
					Width = 1
				},
				{
					Name = "+iReg4",
					Color = RGB(0, 128, 0),
					Type = TYPE_LINE,
					Width = 1
				},
				{
					Name = "-iReg4",
					Color = RGB(192, 0, 0),
					Type = TYPE_DASHLINE,
					Width = 1
				},
				{
					Name = "iRegHist",
					Color = RGB(0, 0, 255),
					Type = TYPE_DASH,
					Width = 1
				},
				{
					Name = "+iRegHist",
					Color = RGB(0, 128, 0),
					Type = TYPE_DASH,
					Width = 1
				},
				{
					Name = "-iRegHist",
					Color = RGB(192, 0, 0),
					Type = TYPE_DASH,
					Width = 1
				}
			}
	}

----------------------------------------------------------

local lines = #_G.Settings.line

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
local function Reg(Fsettings)

	Fsettings			= (Fsettings or {})
	local bars 			= Fsettings['Период'] or 182
	local kstd1 		= Fsettings['Отклонение1'] or 1
	local kstd2 		= Fsettings['Отклонение2'] or 2
	local kstd3 		= Fsettings['Отклонение3'] or 3
	local kstd4 		= Fsettings['Отклонение4'] or 4
	local barsshift 	= Fsettings['Сдвиг бар'] or 0
	local degree 		= Fsettings['Вид регрессии'] or 1
	local calc_over		= Fsettings['Пересчитывать при отклонении >'] or 3
	local showHistory 	= (Fsettings['Показывать историю'] or 0) == 1

	local fx_buffer	= {}
	local sx		= {}
	local sq		= 0
	local calculated_buffer={}

	error_log = {}

	local p 	= bars
	local ai	= {{1,2,3,4}, {1,2,3,4}, {1,2,3,4}, {1,2,3,4}}
	local nn 	= degree+1
	local solve	= {}

	local out1 	= nil
	local out2 	= nil
	local out3 	= nil
	local out4 	= nil
	local out5 	= nil
	local out6 	= nil
	local out7 	= nil
	local out8 	= nil
	local out9 	= nil
	local out10 = nil
	local out11 = nil
	local out12 = nil

	local last_cal_bar
	local start_index

	return function(index)

		local status, res = pcall(function()

			if index == 1 then

				calculated_buffer 	= {}
				fx_buffer 			= {}
				fx_buffer[1]		= 0

				--- sx
				sx={}
				sx[1] = p+1

				for mi=1, nn*2-2 do
					local sum=0
					for n=0, p do
						sum = sum + math_pow(n,mi)
					end
					sx[mi+1]=sum
				end

				last_cal_bar 	= index
				start_index 	= Size() - barsshift
	            -- myLog('--------------------------------------------------------------------------------')
	            -- myLog('--------------------------------------------------------------------------------')
	            -- myLog('--------------------------------------------------------------------------------')
	            -- myLog('--------------- new CalcTradeSignals bar', index, os.date('%d.%m.%Y %H:%M:%S', os_time(_G.T(index))), 'start_index', start_index)

				return nil
			end

			SetValue(index-bars-barsshift, 1, nil)
			SetValue(index-bars-barsshift, 2, nil)
			SetValue(index-bars-barsshift, 3, nil)
			SetValue(index-bars-barsshift, 4, nil)
			SetValue(index-bars-barsshift, 5, nil)
			SetValue(index-bars-barsshift, 6, nil)
			SetValue(index-bars-barsshift, 7, nil)
			SetValue(index-bars-barsshift, 8, nil)
			SetValue(index-bars-barsshift, 9, nil)

			if not CandleExist(index) or index <= bars then
				return nil
			end

			if index < start_index and not showHistory then return nil end

			if calculated_buffer[index] ~= nil then
				return out1, out2, out3, out4, out5, out6, out7, out8, out9, out10, out11, out12
			end

			--Calc
			out1 = nil
			out2 = nil
			out3 = nil
			out4 = nil
			out5 = nil
			out6 = nil
			out7 = nil
			out8 = nil
			out9 = nil
			out10 = nil
			out11 = nil
			out12 = nil

			local delta = math.abs(C(index) - (fx_buffer[#fx_buffer] or 0))

			if (barsshift == 0 and (delta >= calc_over*sq)) or index <= start_index then

				last_cal_bar = index
	            -- myLog('new CalcTradeSignals bar', index, os.date('%d.%m.%Y %H:%M:%S', os_time(_G.T(index))), 'last_cal_bar', last_cal_bar, 'calc_over', calc_over, 'delta', delta, 'calc_over*sq', calc_over*sq)

				fx_buffer = {}

				--- syx
				local b={}
				for mi=1, nn do
					local sum = 0
					for n=0, p do
						if CandleExist(index+n-bars) then
							if mi==1 then
								sum = sum + C(index+n-bars)
							else
								sum = sum + C(index+n-bars)*math_pow(n,mi-1)
							end
						end
					end
					b[mi]=sum
				end

				--- Matrix
				for jj=1, nn do
					for ii=1, nn do
						ai[ii][jj]=sx[ii+jj-1]
					end
				end

				--- Gauss
				local mm, ll, tt
				for kk=1, nn-1 do
					ll=0
					mm=0
					for ii=kk, nn do
						if math.abs(ai[ii][kk])>mm then
							mm=math.abs(ai[ii][kk])
							ll=ii
						end
					end

					if ll==0 then
						return nil
					end
					if ll~=kk then
						for jj=1, nn do
							tt=ai[kk][jj]
							ai[kk][jj]=ai[ll][jj]
							ai[ll][jj]=tt
						end
						tt=b[kk]
						b[kk]=b[ll]
						b[ll]=tt
					end

					local qq
					for ii=kk+1, nn do
						qq=ai[ii][kk]/ai[kk][kk]
						for jj=1, nn do
							if jj==kk then
								ai[ii][jj]=0
							else
								ai[ii][jj]=ai[ii][jj]-qq*ai[kk][jj]
							end
						end
						b[ii]=b[ii]-qq*b[kk]
					end
				end

				solve = {}
				solve[nn]=b[nn]/ai[nn][nn]

				for ii=nn-1, 1, -1 do
					tt=0
					for jj=1, nn-ii do
						tt=tt+ai[ii][ii+jj]*solve[ii+jj]
						solve[ii]=(1/ai[ii][ii])*(b[ii]-tt)
					end
				end

				---
				for n=0, p do
					local sum = 0
					for kk=1, degree do
						sum = sum + solve[kk+1]*math_pow(n,kk)
					end
					fx_buffer[n]=solve[1]+sum
					if index == (Size() - barsshift) then
						SetValue(index+n-bars, 1, fx_buffer[n])
					end
				end

				--- Std
				sq = 0.0
				for n=0, p do
					if CandleExist(index+n-bars) then
						sq = sq + math_pow(C(index+n-bars)-fx_buffer[n],2)
					end
				end

				sq = math.sqrt(sq/(p-1))

				if index == (Size() - barsshift) then
					for n=0, p do
						if kstd1 > 0 then
							SetValue(index+n-bars, 2, fx_buffer[n]+sq*kstd1)
							SetValue(index+n-bars, 3, fx_buffer[n]-sq*kstd1)
						end
						if kstd2 > 0 then
							SetValue(index+n-bars, 4, fx_buffer[n]+sq*kstd2)
							SetValue(index+n-bars, 5, fx_buffer[n]-sq*kstd2)
						end
						if kstd3 > 0 then
							SetValue(index+n-bars, 6, fx_buffer[n]+sq*kstd3)
							SetValue(index+n-bars, 7, fx_buffer[n]-sq*kstd3)
						end
						if kstd4 > 0 then
							SetValue(index+n-bars, 8, fx_buffer[n]+sq*kstd4)
							SetValue(index+n-bars, 9, fx_buffer[n]-sq*kstd4)
						end
					end
				end
			else
				local sum = 0
				local b = p + index - last_cal_bar
				for kk = 1, degree do
					sum = sum + solve[kk+1]*math_pow(b,kk)
				end
				fx_buffer[b] = solve[1]+sum
				SetValue(index, 1, fx_buffer[b])
	            -- myLog('CalcTradeSignals bar', index, os.date('%d.%m.%Y %H:%M:%S', os_time(_G.T(index))), 'b', b, 'fx_buffer', #fx_buffer, fx_buffer[b])
			end

			calculated_buffer[index] = true
			out1 = fx_buffer[#fx_buffer]
			if kstd1 > 0 then
				out2 = out1+sq*kstd1
				out3 = out1-sq*kstd1
			end
			if kstd2 > 0 then
				out4 = out1+sq*kstd2
				out5 = out1-sq*kstd2
			end
			if kstd3 > 0 then
				out6 = out1+sq*kstd3
				out7 = out1-sq*kstd3
			end
			if kstd4 > 0 then
				out8 = out1+sq*kstd4
				out9 = out1-sq*kstd4
			end
			if showHistory and index < start_index then
				out10 = out1
				if kstd1 > 0 then
					out11 = out1+sq*kstd1
					out12 = out1-sq*kstd1
				end
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
		return out1, out2, out3, out4, out5, out6, out7, out8, out9, out10, out11, out12
	end

end
----------------------------    ----------------------------    ----------------------------
----------------------------    ----------------------------    ----------------------------
----------------------------    ----------------------------    ----------------------------

function _G.Init()
	PlotLines = Reg(_G.Settings)
	return lines
end

function _G.OnChangeSettings()
    _G.Init()
end

function _G.OnCalculate(index)

	if _G.Settings['Вид регрессии'] > 3 then
		return nil
	end

	return PlotLines(index)
end