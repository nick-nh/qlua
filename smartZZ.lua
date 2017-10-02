-- nnh Glukk Inc. nick-h@yandex.ru

-- Алгоритм: проверка размера волн и корректировка по следующим от- |
-- ношениям "Идеальных пропорций" ("Золотое сечение" версия 1):     |
--   №    (D-E)/(D-C)   "ЗС версия1" №  (E-D)/(C-D)   "ЗС версия1"  |
--   M1    2             1.618       W1  0.3334        0.3819       |
--   M2    0.5           0.5         W2  0.6667        0.618        |
--   M3    1.5           1.2720      W3  1.5           1.2720       |
--   M4    0.6667	     0.618       W4  0.5           0.5          |
--   M5    1.3334        1.2720      W5  2             1.618        |
--   M6    0.75          0.618       W6  0.25          0.25         |
--   M7    3             3.0000      W7  0.5           0.5          |
--   M8    0.3334        0.3819      W8  2             1.618        |
--   M9    2             1.618       W9  0.3334        0.3819       |
--   M10   0.5           0.5         W10 3             3.0000       |
--   M11   0.25          0.25        W11 0.75          0.618        |
--   M12   2             1.618       W12 1.3334        1.2720       |
--   M13   0.5           0.5         W13 0.6667        0.618        |
--   M14   1.5           1.2720      W14 1.5           1.2720       |
--   M15   0.6667        0.618       W15 0.5           0.5          |
--   M16   0.3334        0.3819      W16 2             1.618        |


--logfile=io.open(getWorkingFolder().."\\LuaIndicators\\qlua_log.txt", "w")

label={} 
AddedLabels = {}

Settings = 
{
	Name = "*SmartZZ",
	bars = 1000, -- за сколько баров строить зиг заг
	deviation = 30, -- процент движения от максимума/минимума для смены тренда
	gapDeviation = 70, -- процент резкого движения от максимума/минимума для смены тренда без всяких условий
	WaitBars = 4, -- число свечей для смены тренда
	showCalculatedLevels = 1, -- показывать уровни от прошлого движения
	showextraCalculatedLevels = 0, -- показывать расширения уровней от прошлого движения
	regimeOfCalculatedLevels = 2, -- 1- последнее движение, 2 - последний максимальный диапазон
	deepZZForCalculatedLevels = 10, -- глубина поиска последнего максимального диапазона по вершинам. До 20.
	showZZLevels = 1, -- показывать уровни от вершин
	numberZZLevels = 10, -- сколько показывать уровней от вершин до 20
	showCoG = 1, -- показывать центр движения для вил Эндрюса
	showTargetZone = 1, -- показывать целевую зону
	numberOfMovesForTargetZone = 5, --  глубина поиска движений для предсказания
	spreadOfTargetZone = 10, -- диапазон целевой зоны (%)
	showLabel = 1, -- показывать метку паттерна
	LabelShift = 200, -- сдвиг метки от вершины
	ChartId = '',
	line=
	{
		{
			Name = "ZIGZAG",
			Color = RGB(0, 0, 0),
			Type = TYPE_LINE,
			Width = 1
		},
		{
			Name = "CentreOfGravity",
			Color = RGB(0, 128, 255),
			Type = TYPE_POINT,
			Width = 3
		},
		{
			Name = "[-2/8]",
			Type =TYPE_LINE,
			Width = 2,
			Color = RGB(255,0, 255)
		},
		{
			Name = "[-1/8]",
			Type =TYPE_LINE,
			Width = 2,
			Color = RGB(255,191, 191)
		},		
		{
			Name = "[0/8] Окончательное сопротивление",
			Type =TYPE_LINE,
			Width = 2,
			Color = RGB(0,128, 255)
		},
		{
			Name = "[1/8] Слабый, место для остановки и разворота",
			Type =TYPE_LINE,
			Width = 2,
			Color = RGB(218,188, 18)
		},
		{
			Name = "[2/8] Вращение, разворот",
			Type =TYPE_LINE,
			Width = 2,
			Color = RGB(255,0, 128)
		},
		{
			Name = "[3/8] Дно торгового диапазона",
			Type =TYPE_LINE,
			Width = 2,
			Color = RGB(120,220, 235)
		},
		{
			Name = "[4/8] Главный уровень поддержки/сопротивления",
			Type =TYPE_LINE,
			Width = 2,
			Color = RGB(128,128, 128)--green
		},
		{
			Name = "[5/8] Верх торгового диапазона",
			Type =TYPE_LINE,
			Width = 2,
			Color = RGB(120,220, 235)
		},
		{
			Name = "[6/8] Вращение, разворот",
			Type =TYPE_LINE,
			Width = 2,
			Color = RGB(255,0, 128)
		},
		{
			Name = "[7/8] Слабый, место для остановки и разворота",
			Type =TYPE_LINE,
			Width = 2,
			Color = RGB(218,188, 18)
		},
		{
			Name = "[8/8] Окончательное сопротивление",
			Type =TYPE_LINE,
			Width = 2,
			Color = RGB(0,128, 255)
		},
		{
			Name = "[+1/8]",
			Type =TYPE_LINE,
			Width = 2,
			Color = RGB(255,191, 191)
		},
		{
			Name = "[+2/8]",
			Type =TYPE_LINE,
			Width = 2,
			Color = RGB(255,0, 255)
		},
		{
			Name = "Target",
			Type =TYPE_LINE,
			Width = 3,
			Color = RGB(89,213, 107)
		},
		{
			Name = "Target",
			Type =TYPE_LINE,
			Width = 3,
			Color = RGB(89,213, 107)
		}
	}
}

 -- Пользовательcкие функции
function WriteLog(text)

   logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
   logfile:flush();
   LASTLOGSTRING = text;

end

function toYYYYMMDDHHMMSS(datetime)
   if type(datetime) ~= "table" then
      --message("в функции toYYYYMMDDHHMMSS неверно задан параметр: datetime="..tostring(datetime))
      return ""
   else
      local Res = tostring(datetime.year)
      if #Res == 1 then Res = "000"..Res end
      local month = tostring(datetime.month)
      if #month == 1 then Res = Res.."0"..month; else Res = Res..month; end
      local day = tostring(datetime.day)
      if #day == 1 then Res = Res.."0"..day; else Res = Res..day; end
      local hour = tostring(datetime.hour)
      if #hour == 1 then Res = Res.."0"..hour; else Res = Res..hour; end
      local minute = tostring(datetime.min)
      if #minute == 1 then Res = Res.."0"..minute; else Res = Res..minute; end
      local sec = tostring(datetime.sec);
      if #sec == 1 then Res = Res.."0"..sec; else Res = Res..sec; end;
      return Res
   end
end --toYYYYMMDDHHMMSS

function isnil(a,b)
   if a == nil then
      return b
   else
      return a
   end;
end
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

function Init()
	myFunc = cached_ZZ()
	for i = 18, 37 do
		Settings.line[i] = {Color = RGB(0, 128, 255), Type = TYPE_DASH, Width = 1}
	end
	return #Settings.line
end

function OnDestroy()
	if Settings.ChartId ~= '' then
		DelAllLabels(Settings.ChartId)
		AddedLabels = {}
	end
end

function OnCalculate(index)

	if index == 1 and Settings.ChartId ~= '' then
		DelAllLabels(Settings.ChartId)
		AddedLabels = {}
	end
	
	--if #AddedLabels > 0 then -- Удаляет ранее установленные метки
	--	for i=1,#AddedLabels,1 do
	--		DelLabel(Settings.ChartId, AddedLabels[i]);
	--	end
	--	AddedLabels = {}
	--end
   	
	if index == 1 then
		DSInfo = getDataSourceInfo()     	
		min_price_step = getParamEx(DSInfo.class_code, DSInfo.sec_code, "SEC_PRICE_STEP").param_value
	end
	
	return myFunc(index, Settings, 37)
end


function getCandleProp(index)

	if CandleExist(index) then	
		local datetimeL = toYYYYMMDDHHMMSS(T(index))		
		return tonumber(string.sub(datetimeL, 1, 8)), tonumber(string.sub(datetimeL, 9)) 
	end

end

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
function cached_ZZ()
	
	local cache_ST={} -- тренд
	local CC={} -- значения закрытия свечей
	
	local cache_H={} -- значения максимумов
	local cache_L={} -- значения минимумов
	local H_index={} -- индексы максимумов
	local L_index={} -- индексы минимумов
	
	local HiBuffer={} -- знечения максимов предшествующего движения
	local LowBuffer={} -- знечения минимумов предшествующего движения
		
	local UpThrust={} -- значения количества свечей смены движения
	local breakBars={} -- значения экстремума свечей пробития уровня
	local breakIndex={} -- индексы свечей пробития уровня
	
	local ZZLevels={{},{}} -- матрица вершины. 1 - значение, 2 - индекс
	
	local Ranges={} -- знечения предшествующих движений для предсказания
	
	local lineIndex={{}, {}} --индексы и значения точек для отрисовки линий. 1 - значение, 2 - индекс
		
	return function(ind, Fsettings, numberOfLiines)
		
		local Fsettings=(Fsettings or {})
		local index = ind
		local bars = Fsettings.bars or 3000
		local deviation = Fsettings.deviation or 30
		local gapDeviation = Fsettings.gapDeviation or 70
		local WaitBars = Fsettings.WaitBars or 4
		local showCalculatedLevels = Fsettings.showCalculatedLevels or 1
		local showextraCalculatedLevels = Fsettings.showextraCalculatedLevels or 0
		local regimeOfCalculatedLevels = Fsettings.regimeOfCalculatedLevels or 1
		local deepZZForCalculatedLevels = Fsettings.deepZZForCalculatedLevels or 10
		local showZZLevels = Fsettings.showZZLevels or 1
		local showCoG = Fsettings.showCoG or 1
		local numberZZLevels = Fsettings.numberZZLevels or 10
		local showTargetZone = Fsettings.showTargetZone or 1
		local numberOfMovesForTargetZone = Fsettings.numberOfMovesForTargetZone or 5
		local spreadOfTargetZone = Fsettings.spreadOfTargetZone or 10
		local showLabel = Fsettings.showLabel or 1
		local LabelShift = Fsettings.LabelShift or 250
		
		local currentRange = 0
		local sizeOfZZLevels = 20
		
		local widthOfCalculatedMarks = 15
		local widthOfTargetMarks = 50
		
		local patternLabelText = ''
		
		if index == 1 then
			cache_H={}
			cache_L={}
			cache_ST={}
			CC={}
			UpThrust={}
			breakBars={}
			breakIndex={}
			
			HiBuffer={}
			LowBuffer={}

			H_index={}
			L_index={}
			ZZLevels={{},{}}
			
			Ranges={}
------------------
			CC[index]=C(index)
			cache_H[index]=0
			cache_L[index]=0
			cache_ST[index]=1
			
			UpThrust[index]=0
			breakBars[index]=0
			breakIndex[index]=0
			
			HiBuffer[index]=0
			LowBuffer[index]=0
			
			H_index[index]=index
			L_index[index]=index
			SetValue(index, 1, nil)
			
			for nn = 1, numberOfLiines do
				lineIndex[2][nn] = 1
			end
			
			return nil
		end
			
		CC[index]=CC[index-1]
					
		if cache_H[index] == nil then
			cache_H[index]=cache_H[index-1] 
		end
		if cache_L[index] == nil then
			cache_L[index]=cache_L[index-1] 
		end
		if H_index[index] == nil then
			H_index[index]=H_index[index-1] 
		end
		if L_index[index] == nil then
			L_index[index]=L_index[index-1] 
		end
		if UpThrust[index] == nil then
			UpThrust[index]=UpThrust[index-1] 
		end
		if breakBars[index] == nil then
			breakBars[index]=breakBars[index-1] 
		end
		if breakIndex[index] == nil then
			breakIndex[index]=breakIndex[index-1] 
		end
		if HiBuffer[index] == nil then
			HiBuffer[index]=HiBuffer[index-1] 
		end
		if LowBuffer[index] == nil then
			LowBuffer[index]=LowBuffer[index-1] 
		end		
		if cache_ST[index] == nil then
			cache_ST[index]=cache_ST[index-1]		
		end
		
		if index < (Size() - bars) or not CandleExist(index) then
			return nil
		end

		--WriteLog ("---------------------------------");
		--WriteLog ("OnCalc() ".."CandleExist("..index.."): "..tostring(CandleExist(index)).."; T("..index.."); "..isnil(toYYYYMMDDHHMMSS(T(index))," - ").."; C("..index.."): "..isnil(C(index),"-"));
		--WriteLog ("L "..tostring(L(index)));
		--WriteLog ("H "..tostring(H(index)));
		--WriteLog ("cache_ST[index] "..tostring(cache_ST[index]));
		--WriteLog ("cache_H[index] "..tostring(cache_H[index]));
		--WriteLog ("cache_L[index] "..tostring(cache_L[index]));
		--WriteLog ("H_index[index] "..tostring(H_index[index]));
		--WriteLog ("L_index[index] "..tostring(L_index[index]));
		--WriteLog ("UpThrust[index] "..tostring(UpThrust[index]));
		--WriteLog ("breakBars[index] "..tostring(breakBars[index]));
		--WriteLog ("breakIndex[index] "..tostring(breakIndex[index]));
		--WriteLog ("HiBuffer[index] "..tostring(HiBuffer[index]));
		--WriteLog ("LowBuffer[index] "..tostring(LowBuffer[index]));
		------------------------------
		local isBreak=0
				
		-- ставим возвращаемые значения в nil
		for nn = 1, numberOfLiines do
			lineIndex[1][nn] = nil
		end				
		
		--обнуляем линии на предыдущих свечках
		--2 линия
		SetValue(lineIndex[2][2], 2, nil)
		
		--3-15 линии
		if showCalculatedLevels == 1 then
			for nn = 3, 15 do
				SetValue(lineIndex[2][nn], nn, nil)
				SetValue(index-1, nn, nil)
			end
		end
		
		--16, 17 линии
		if showTargetZone == 1 then
			SetValue(lineIndex[2][16], 16, nil)				
			SetValue(lineIndex[2][17], 17, nil)				
			SetValue(index-1, 16, nil)				
			SetValue(index-1, 17, nil)				
		end
		
		--18-37 линии
		if showZZLevels == 1 then
			for nn = 1, sizeOfZZLevels do
				SetValue(lineIndex[2][numberOfLiines-nn+1], numberOfLiines-nn+1, nil)
				SetValue(index - 1, numberOfLiines-nn+1, nil)
			end
		end
				
		CC[index]=C(index)
		
		---------------------------------------------------------------------------------------
				
		----------------------------------------------------------------------		
		
		-- расчет
		currentRange = math.abs(cache_H[index] - cache_L[index])
		
		if cache_ST[index]==1 then --растущий тренд
				
			--WriteLog ("set")
			--WriteLog ("cache_H[index] "..tostring(cache_H[index]))
			--WriteLog ("H_index[index] "..tostring(H_index[index]))
			
			if cache_H[index] ~= 0 then -- для первой расчетной свечи
				SetValue(H_index[index], 1, cache_H[index])
			end
			
			if cache_H[index] <= H(index) then -- новый максимум
				
				cache_H[index]=H(index)					
				SetValue(H_index[index], 1, nil)
				H_index[index]=index					
				lineIndex[1][1]= cache_H[index]
				--WriteLog ("new cache_H[index] "..tostring(cache_H[index]))
				--WriteLog ("new H_index[index] "..tostring(H_index[index]))
				
				if cache_L[index] == 0 then -- для первой расчетной свечи
					cache_L[index] = L(index)
					L_index[index] = index
					LowBuffer[index] = L(index)
				end	
				
				if breakBars[index] ~= 0 then
					--WriteLog ("fake break");
					breakBars[index] = 0
					breakIndex[index] = 0
					UpThrust[index] = 0
				end
				
			elseif (currentRange*deviation/100) < math.abs(CC[index] - cache_H[index]) then --прошли больше чем отклонение от движения				

				if UpThrust[index] == 0 then
					UpThrust[index] = index										
				end
				
				--WriteLog ("test break");
				--WriteLog ("breakBars[index] "..tostring(breakBars[index]));
				--WriteLog ("breakIndex[index] "..tostring(breakIndex[index]));
	
				if breakBars[index] == 0 or (breakBars[index] ~= 0 and breakBars[index] >= L(index)) then
					breakBars[index] = L(index)
					breakIndex[index] = index
					--WriteLog ("index to low "..tostring(index));
					--WriteLog ("L(index) "..tostring(L(index)));
					--WriteLog ("UpThrust[index] "..tostring(UpThrust[index]));
					--WriteLog ("new breakBars[index] "..tostring(breakBars[index]));
					--WriteLog ("new breakIndex[index] "..tostring(breakIndex[index]));
				end
				
				if ((index - UpThrust[index]) > WaitBars and UpThrust[index] ~= 0) or (currentRange*gapDeviation/100) < math.abs(CC[index] - cache_H[index]) then -- ждем закрепления пробоя
					
					--меняем тренд						
					
					cache_ST[index]=0 
					
					if breakBars[index] < L(index) then
						cache_L[index] = breakBars[index]
						L_index[index] = breakIndex[index]
					else
						cache_L[index] = L(index)
						L_index[index] = index					
						lineIndex[1][1] = cache_L[index]
					end
					
					--WriteLog ("break");
					--WriteLog ("cache_ST[index] "..tostring(cache_ST[index]));
					--WriteLog ("UpThrust[index] "..tostring(UpThrust[index]));
					--WriteLog ("breakBars[index] "..tostring(breakBars[index]));
					--WriteLog ("breakIndex[index] "..tostring(breakIndex[index]));
					
					for nn = 1, sizeOfZZLevels-1 do
						ZZLevels[1][nn] = ZZLevels[1][nn+1]
						ZZLevels[2][nn] = ZZLevels[2][nn+1]
					end
						
					ZZLevels[1][sizeOfZZLevels] = cache_H[index]
					ZZLevels[2][sizeOfZZLevels] = H_index[index]

					UpThrust[index] = 0
					breakBars[index] = 0
					breakIndex[index] = 0
					isBreak = 1
					
					HiBuffer[index] = cache_H[index]
					
				end
				
			elseif breakBars[index] ~= 0 and breakBars[index] >= L(index) then
						
					breakBars[index] = L(index)
					breakIndex[index] = index
					--WriteLog ("index to low "..tostring(index));
					--WriteLog ("L(index) "..tostring(L(index)));
					--WriteLog ("UpThrust[index] "..tostring(UpThrust[index]));
					--WriteLog ("new breakBars[index] "..tostring(breakBars[index]));
					--WriteLog ("new breakIndex[index] "..tostring(breakIndex[index]));
				
			end
									
		
		elseif cache_ST[index]==0 then --падающий тренд
									
			--WriteLog ("set");
			--WriteLog ("cache_L[index] "..tostring(cache_L[index]));
			--WriteLog ("L_index[index] "..tostring(L_index[index]));
			
			if cache_L[index] ~= 0 then -- для первой расчетной свечи
				SetValue(L_index[index], 1, cache_L[index])
			end
			
			if cache_L[index] >= L(index) then -- новый минимум
				
				cache_L[index]=L(index)
				SetValue(L_index[index], 1, nil)
				L_index[index]=index						
				lineIndex[1][1] = cache_L[index]
				--WriteLog ("new cache_L[index] "..tostring(cache_L[index]));
				--WriteLog ("new L_index[index] "..tostring(L_index[index]));
				
				if breakBars[index] ~= 0 then
					--WriteLog ("fake break");
					breakBars[index] = 0
					breakIndex[index] = 0
					UpThrust[index] = 0
				end
				
			elseif (currentRange*deviation/100) < math.abs(CC[index] - cache_L[index]) then --прошли больше чем отклонение от движения
				
				if UpThrust[index] == 0 then
					UpThrust[index] = index										
				end
				
				--WriteLog ("test break");
				--WriteLog ("breakBars[index] "..tostring(breakBars[index]));
				--WriteLog ("breakIndex[index] "..tostring(breakIndex[index]));
	
				if breakBars[index] == 0 or (breakBars[index] ~= 0 and breakBars[index] <= H(index)) then
					breakBars[index] = H(index)
					breakIndex[index] = index
					--WriteLog ("index to hi "..tostring(index));
					--WriteLog ("H(index) "..tostring(H(index)));
					--WriteLog ("UpThrust[index] "..tostring(UpThrust[index]));
					--WriteLog ("new breakBars[index] "..tostring(breakBars[index]));
					--WriteLog ("new breakIndex[index] "..tostring(breakIndex[index]));
				end
					
				if ((index - UpThrust[index]) > WaitBars and UpThrust[index] ~= 0) or (currentRange*gapDeviation/100) < math.abs(CC[index] - cache_H[index]) then -- ждем закрепления пробоя
				--меняем тренд			
				
					cache_ST[index]=1 
					if breakBars[index] > L(index) then
						cache_H[index] = breakBars[index]
						H_index[index] = breakIndex[index]
					else
						cache_H[index] = H(index)
						H_index[index] = index					
						lineIndex[1][1] = cache_H[index]
					end
					
					for nn = 1, 19 do
						ZZLevels[1][nn] = ZZLevels[1][nn+1]
						ZZLevels[2][nn] = ZZLevels[2][nn+1]
					end
				
					ZZLevels[1][sizeOfZZLevels] = cache_L[index]
					ZZLevels[2][sizeOfZZLevels] = L_index[index]
					
					--WriteLog ("break");
					--WriteLog ("cache_ST[index] "..tostring(cache_ST[index]));
					--WriteLog ("UpThrust[index] "..tostring(UpThrust[index]));
					--WriteLog ("breakBars[index] "..tostring(breakBars[index]));
					--WriteLog ("breakIndex[index] "..tostring(breakIndex[index]));
					
					breakBars[index] = 0
					breakIndex[index] = 0
					UpThrust[index] = 0
					isBreak = 1
					
					LowBuffer[index] = cache_L[index]
				end
				
			elseif breakBars[index] ~= 0 and breakBars[index] <= H(index) then
					
					breakBars[index] = H(index)
					breakIndex[index] = index
					--WriteLog ("index to hi "..tostring(index));
					--WriteLog ("H(index) "..tostring(H(index)));
					--WriteLog ("UpThrust[index] "..tostring(UpThrust[index]));
					--WriteLog ("new breakBars[index] "..tostring(breakBars[index]));
					--WriteLog ("new breakIndex[index] "..tostring(breakIndex[index]));
				
			end
						
		end

		
		-- вывод данных
		if  index == Size() then
					
			local lastRange = 0
			local lastHi =  0
			local lastLow = H(index)
			for j = 1, deepZZForCalculatedLevels do
				if ZZLevels[1][sizeOfZZLevels-j+1] ~= nil and ZZLevels[1][sizeOfZZLevels-j+1] ~= 0 then
					lastLow = math.min(ZZLevels[1][sizeOfZZLevels-j+1], lastLow)
					lastHi = math.max(ZZLevels[1][sizeOfZZLevels-j+1], lastHi)
				end				
			end		
			
			lastHi = math.max(lastHi, cache_H[index])
			lastLow = math.min(lastLow, cache_L[index])
			local D = cache_L[index]
			if cache_ST[index] == 1 then
				D = cache_H[index]
			end 
			
			----WriteLog ("X "..tostring(ZZLevels[1][sizeOfZZLevels-3]))
			----WriteLog ("A "..tostring(ZZLevels[1][sizeOfZZLevels-2]))
			----WriteLog ("B "..tostring(ZZLevels[1][sizeOfZZLevels-1]))
			----WriteLog ("C "..tostring(ZZLevels[1][sizeOfZZLevels]))
			----WriteLog ("D "..tostring(D))
						
			local XA = 0
			local AB = 0
			local BC = 0
			local XC = 0
			local CD = 0
			local AD = 0
			local ABtoXA = 0
			local XCtoXA =0
			local CDtoAB = 0
			local ADtoXA = 0
			local currentDeviation = 0
			
			if ZZLevels[1][sizeOfZZLevels-3] ~= nil then
				XA = math.abs(ZZLevels[1][sizeOfZZLevels-3] - ZZLevels[1][sizeOfZZLevels-2])
				AB = math.abs(ZZLevels[1][sizeOfZZLevels-2] - ZZLevels[1][sizeOfZZLevels-1])
				BC = math.abs(ZZLevels[1][sizeOfZZLevels-1] - ZZLevels[1][sizeOfZZLevels])
				XC = math.abs(ZZLevels[1][sizeOfZZLevels-3] - ZZLevels[1][sizeOfZZLevels])
				CD = math.abs(ZZLevels[1][sizeOfZZLevels] - D)
				AD = math.abs(ZZLevels[1][sizeOfZZLevels-2] - D)
			
				ABtoXA = round(100*AB/XA, 2)
				XCtoXA = round(100*XC/XA, 2)
				CDtoAB = round(100*CD/AB, 2)
				ADtoXA = round(100*AD/XA, 2)
				currentDeviation = round(100*math.abs(C(index) - D)/CD, 2)
			end	
			
			if showCalculatedLevels == 1 then
			
				----WriteLog ("HiBuffer[index] "..tostring(HiBuffer[index]));
				----WriteLog ("LowBuffer[index] "..tostring(LowBuffer[index]));
				----WriteLog ("cache_H[index] "..tostring(cache_H[index]));
				----WriteLog ("cache_L[index] "..tostring(cache_L[index]));				
				
				if regimeOfCalculatedLevels == 1 then
					
					lastHi =  0
					lastLow = H(index)
					
					if HiBuffer[index] < cache_H[index] then
						HiBuffer[index] = cache_L[index] + (HiBuffer[index] - LowBuffer[index])
						LowBuffer[index] = cache_L[index]
					elseif LowBuffer[index] > cache_L[index] then
						LowBuffer[index] = cache_H[index] - (HiBuffer[index] - LowBuffer[index])
						HiBuffer[index] = cache_H[index]
					end	
					
					lastHi = HiBuffer[index]
					lastLow = LowBuffer[index]
					lastRange = math.abs(HiBuffer[index] - LowBuffer[index])
				else															
					lastRange = math.abs(lastHi - lastLow)				
				end
				
				----WriteLog ("new HiBuffer[index] "..tostring(HiBuffer[index]));
				----WriteLog ("new LowBuffer[index] "..tostring(LowBuffer[index]));				
				
				if  lastRange ~=0 then 
					
					if showextraCalculatedLevels == 1 then				
						for nn = 1, 2 do
							SetValue(index-widthOfCalculatedMarks, nn+2, lastLow - nn*lastRange/8)				
							lineIndex[2][nn+2] = lastLow - nn*lastRange/8
							SetValue(index-widthOfCalculatedMarks, nn+13, lastHi + nn*lastRange/8)				
							lineIndex[2][nn+13] = lastHi + nn*lastRange/8
						end
					end				
					
					for nn = 5, 13 do					
						local value = lastLow + (nn-5)*lastRange/8
						SetValue(index-widthOfCalculatedMarks, nn, value)				
						lineIndex[1][nn] = value
					end
						
					for nn = 3, 15 do
						lineIndex[2][nn] = index-widthOfCalculatedMarks
					end
					
				end
			end
			
			if showZZLevels == 1 then
				
				for j = 1, numberZZLevels do
					SetValue(ZZLevels[2][sizeOfZZLevels-j+1], numberOfLiines-j+1, ZZLevels[1][sizeOfZZLevels-j+1])
					lineIndex[1][numberOfLiines-j+1] = ZZLevels[1][sizeOfZZLevels-j+1]
					lineIndex[2][numberOfLiines-j+1] = ZZLevels[2][sizeOfZZLevels-j+1]
					----WriteLog ("ZZLevels[1]["..tostring(sizeOfZZLevels-j+1).."] "..tostring(ZZLevels[1][sizeOfZZLevels-j+1]));
					----WriteLog ("ZZLevels[2]["..tostring(sizeOfZZLevels-j+1).."] "..tostring(ZZLevels[2][sizeOfZZLevels-j+1]));
				end				
							
			end
			
			if showTargetZone == 1 then
				
				local meanRange = 0
				local quantRange = 0
				
				for j = 1, numberOfMovesForTargetZone*2-1, 2 do
					if ZZLevels[1][sizeOfZZLevels-j -1] ~= nil then
						meanRange = meanRange + math.abs(ZZLevels[1][sizeOfZZLevels-j] - ZZLevels[1][sizeOfZZLevels-j -1])
						quantRange = quantRange + 1
					end
				end				
							
				if quantRange ~= 0 then
				
					if cache_ST[index] == 1 then
						meanRange = meanRange/quantRange
					else
						meanRange = -1*meanRange/quantRange
					end
						
					local outT1 = ZZLevels[1][sizeOfZZLevels] + meanRange*(1 - spreadOfTargetZone/100)
					SetValue(index-widthOfTargetMarks, 16, outT1)				
					lineIndex[1][16] = outT1
					lineIndex[2][16] = index-widthOfTargetMarks
					local outT2 = ZZLevels[1][sizeOfZZLevels] + meanRange*(1 + spreadOfTargetZone/100)
					SetValue(index-widthOfTargetMarks, 17, outT2)	
					lineIndex[1][17] = outT2
					lineIndex[2][17] = index-widthOfTargetMarks
					
				end
						
			end
			
			--if isBreak == 1 then
			--	for nn = 1, numberOfLiines do
			--		--WriteLog ("lineIndex[1]["..tostring(nn).."] "..tostring(lineIndex[1][nn]));
			--		--WriteLog ("lineIndex[2]["..tostring(nn).."] "..tostring(lineIndex[2][nn]));
			--	end					
			--end		
			
			-- выводим метку паттерна
			if showLabel == 1 and ZZLevels[2][sizeOfZZLevels-deepZZForCalculatedLevels] ~= nil and Settings.ChartId ~= '' then
			
				label.DATE, label.TIME = getCandleProp(index-LabelShift) --ZZLevels[2][sizeOfZZLevels]
				local firsY
				local secondY
				
				if ZZLevels[2][sizeOfZZLevels-deepZZForCalculatedLevels] > ZZLevels[2][sizeOfZZLevels-deepZZForCalculatedLevels+1] then
					firsY = lastLow - (lastHi - lastLow)/20
					secondY = firsY - (lastHi - lastLow)/20
				else
					firsY = lastHi + (lastHi - lastLow)/20
					secondY = firsY + (lastHi - lastLow)/20
				end
				
				label.YVALUE = firsY
				label.R = 0 
				label.G = 0 
				label.B = 0  
				label.TRANSPARENCY = 0 
				label.TRANSPARENT_BACKGROUND = 1  
				label.FONT_FACE_NAME = 'Verdana'  
				label.FONT_HEIGHT = 10  
				label.HINT = ''								
				
				--первая метка
				
				local text = "now "..tostring(currentDeviation).."%, ".."XA "..tostring(XA)..", AB "..tostring(AB)..", BC "..tostring(BC)..", CD "..tostring(CD)
				label.TEXT = text
				
				if AddedLabels[1] ~= nil then
					SetLabelParams(Settings.ChartId, AddedLabels[1], label)
				else
					local LabelID = AddLabel(Settings.ChartId, label)
					
					if LabelID ~=nil and LabelID ~= -1 then
						AddedLabels[1] = LabelID --#AddedLabels+1
					end	
				end
				
				--вторая метка
				label.YVALUE = secondY
				text = "AB/XA "..tostring(ABtoXA)..", XC/XA "..tostring(XCtoXA)..", CD/AB "..tostring(CDtoAB)..", AD/XA "..tostring(ADtoXA)
				label.TEXT = text
				
				
				if AddedLabels[2] ~= nil then
					SetLabelParams(Settings.ChartId, AddedLabels[2], label)
				else
					local LabelID = AddLabel(Settings.ChartId, label)
					
					if LabelID ~=nil and LabelID ~= -1 then
						AddedLabels[2] = LabelID --#AddedLabels+1
					end	
				end
				
			end
			
		end
		
		-- выводим центр движения
		if showCoG == 1 then
			if ZZLevels[2][sizeOfZZLevels-1] ~= nil  then
				SetValue(math.floor((ZZLevels[2][sizeOfZZLevels] + ZZLevels[2][sizeOfZZLevels-1])/2), 2, (ZZLevels[1][sizeOfZZLevels] + ZZLevels[1][sizeOfZZLevels-1])/2)
				----WriteLog ("CoG index "..tostring(math.ceil((ZZLevels[2][sizeOfZZLevels] + ZZLevels[2][sizeOfZZLevels-1])/2)));
				----WriteLog ("CoG "..tostring((ZZLevels[1][sizeOfZZLevels] + ZZLevels[1][sizeOfZZLevels-1])/2));	
				
				local LastExt = cache_L[index]
				local LastExtInd = L_index[index]
				
				if cache_ST[index] == 1 then
					LastExt = cache_H[index]
					LastExtInd = H_index[index]
				end 
				
				if LastExtInd ~=nil then
					local LastCoG = (LastExt + ZZLevels[1][sizeOfZZLevels])/2
					local LastIndCoG = math.floor((LastExtInd + ZZLevels[2][sizeOfZZLevels])/2)
					SetValue(LastIndCoG, 2, LastCoG)
					lineIndex[2][2] = LastIndCoG
				end
				
			end
		end
				
		return	unpack(lineIndex[1])
		
	end
end

------------------------------------------------------------------
--Вспомогательные функции
------------------------------------------------------------------

function round(num, idp)
	if idp and num then
	   local mult = 10^(idp or 0)
	   if num >= 0 then return math.floor(num * mult + 0.5) / mult
	   else return math.ceil(num * mult - 0.5) / mult end
	else return num end
end