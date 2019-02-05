-- nnh Glukk Inc. nick-h@yandex.ru

-- Алгоритм: проверка размера волн и корректировка по следующим от- |
-- ношениям "Идеальных пропорций" ("Золотое сечение" версия 1):     |
--   №    (pD-pE)/(pD-pC)   "ЗС версия1" №  (pE-pD)/(pC-pD)   "ЗС версия1"  |
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


--logfile=io.open(getWorkingFolder().."\\LuaIndicators\\smartZZ.txt", "w")

label={} 
AddedLabels = {}
min_price_step = 1
scale = 0

NamePattern =
  {
   ERROR     = 2,
   NOPATTERN = 3,
   W15       = 8,
   W16       = 12,
   M8        = 64,
   M4        = 80,
   M3        = 112,
   W9        = 512,
   W13       = 640,
   W14       = 896,
   M13       = 4096,
   M12       = 5120,
   M7        = 7168,
   W4        = 32768,
   W5        = 40960,
   W10       = 57344,
   M11       = 262144,
   M10       = 327680,
   M5        = 393216,
   M6        = 458752,
   M16       = 2097152,
   M15       = 2621440,
   M14       = 3145728,
   M9        = 3670016,
   W1        = 16777216,
   W2        = 20971520,
   W3        = 25165824,
   W8        = 29360128,
   W6        = 134217728,
   W7        = 167772160,
   W11       = 201326592,
   W12       = 234881024,
   M1        = 536870912,
   M2        = 805306368
}

pattern = NamePattern.NOPATTERN
IsPointNotReal = false
oldPattern = pattern

targetE = 0 -- точка Е
evE = 0 -- точка эволюции
mutE = 0 -- точка мутации

Settings = 
{
	Name = "*SmartZZ",
	bars = 1000, -- за сколько баров строить зиг заг
	deviation = 30, -- процент движения от максимума/минимума для смены тренда
	gapDeviation = 70, -- процент резкого движения от максимума/минимума для смены тренда без всяких условий
	WaitBars = 2, -- число свечей для смены тренда
	showCalculatedLevels = 1, -- показывать уровни от прошлого движения
	showextraCalculatedLevels = 0, -- показывать расширения уровней от прошлого движения
	regimeOfCalculatedLevels = 2, -- 1- последнее движение, 2 - последний максимальный диапазон
	deepZZForCalculatedLevels = 10, -- глубина поиска последнего максимального диапазона по вершинам. До 20.
	showZZLevels = 1, -- показывать уровни от вершин
	numberOfHistoryZZLevels = 0, -- сколько показывать уровней от вершин для истоических данных
	numberOfZZLevels = 10, -- сколько показывать уровней от вершин до 20
	showCoG = 1, -- показывать центр движения для вил Эндрюса
	numberOfShownCOG = 3, --  глубина показа COG
	showTargetZone = 1, -- показывать целевую зону
	numberOfMovesForTargetZone = 5, --  глубина поиска движений для предсказания
	spreadOfTargetZone = 10, -- диапазон целевой зоны (%)
	showLabel = 1, -- показывать метку паттерна
	showFiboExt = 1, -- показывать расширение фибо волны
	LabelShift = 100, -- сдвиг метки от вершины
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
		},
		{
			Name = "TargetFibo1",
			Type =TYPE_DASH,
			Width = 1,
			Color = RGB(0,0, 0)
		},
		{
			Name = "TargetFibo2",
			Type =TYPE_DASH,
			Width = 1,
			Color = RGB(0,0, 0)
		},
		{
			Name = "TargetFibo3",
			Type =TYPE_DASH,
			Width = 1,
			Color = RGB(0,0, 0)
		},
		{
			Name = "TargetFibo4",
			Type =TYPE_DASH,
			Width = 1,
			Color = RGB(0,0, 0)
		},
		{
			Name = "targetE",
			Type =TYPE_LINE,
			Width = 3,
			Color = RGB(89,213, 107)
		},
		{
			Name = "evolutionE",
			Type =TYPE_LINE,
			Width = 3,
			Color = RGB(0,135,135)
		},
		{
			Name = "mutationE",
			Type =TYPE_LINE,
			Width = 3,
			Color = RGB(89,107, 213)
		},
		{
			Name = "zPoint",
			Color = RGB(255, 10, 10),
			Type = TYPE_POINT,
			Width = 3
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
      if #month == 1 then Res = Res.."/0"..month; else Res = Res..'/'..month; end
      local day = tostring(datetime.day)
      if #day == 1 then Res = Res.."/0"..day; else Res = Res..'/'..day; end
      local hour = tostring(datetime.hour)
      if #hour == 1 then Res = Res.." 0"..hour; else Res = Res..' '..hour; end
      local minute = tostring(datetime.min)
      if #minute == 1 then Res = Res..":0"..minute; else Res = Res..':'..minute; end
      local sec = tostring(datetime.sec);
      if #sec == 1 then Res = Res..":0"..sec; else Res = Res..':'..sec; end;
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
	for i = 26, 65 do
		Settings.line[i] = {Color = RGB(0, 128, 255), Type = TYPE_DASH, Width = 1}
	end
	for i = 66, 105 do
		Settings.line[i] = {Color = RGB(255, 64, 0), Type = TYPE_DASH, Width = 1}
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
		scale = getSecurityInfo(DSInfo.class_code, DSInfo.sec_code).scale
	end
	
	return myFunc(index, Settings, 105)
end


function getCandleProp(index)

	if CandleExist(index) then	
		local datetimeL = T(index)		
		return (((datetimeL.year + datetimeL.month/100)*100) + datetimeL.day/100)*100, ((datetimeL.hour + datetimeL.min/100)*100)*100
	end

end

function findExtremum(index, indexFrom, trend)

	local extr
	local extrIndex

	if trend == 1 then 	
		extr = H(index)
	else
		extr = L(index)
	end
	extrIndex = index

	for i=indexFrom+1,index-1 do
		
		if CandleExist(i) then
			if trend == 1 and extr < H(i) then 	
				extr = H(i)
				extrIndex = i
			end
			
			if trend == 0 and extr > L(i) then 	
				extr = L(i)
				extrIndex = i
			end
		end
			
	end

	return extr, extrIndex

end

function RegisterPeak(index, val, ZZLevels)
    
	local sizeOfZZLevels = #ZZLevels + 1
    ZZLevels[sizeOfZZLevels] = {}                    			
    ZZLevels[sizeOfZZLevels]["val"]   = val
    ZZLevels[sizeOfZZLevels]["index"] = index

end

function ReplaceLastPeak(index, val, ZZLevels)
	
	local sizeOfZZLevels = #ZZLevels
	if sizeOfZZLevels == 0 then return end
	ZZLevels[sizeOfZZLevels]["val"]   = val
	ZZLevels[sizeOfZZLevels]["index"] = index

	SetValue(index, 1, val)
	
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
	
	local ZZLevels={} -- матрица вершины. 1 - значение, 2 - индекс
	
	local Ranges={} -- знечения предшествующих движений для предсказания
	
	local lineIndex={{}, {}} --индексы и значения точек для отрисовки линий. 1 - значение, 2 - индекс
	local CoGlineIndex={} --индексы точек для отрисовки линий CoG
    local sizeOfZZLevels = 0
		
	return function(ind, Fsettings, numberOfLines)
		
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
		local numberOfZZLevels = Fsettings.numberOfZZLevels or 10
		local numberOfHistoryZZLevels = Fsettings.numberOfHistoryZZLevels or 2
		local showCoG = Fsettings.showCoG or 1
		local numberOfShownCOG = Fsettings.numberOfShownCOG or 3
		local showTargetZone = Fsettings.showTargetZone or 1
		local numberOfMovesForTargetZone = Fsettings.numberOfMovesForTargetZone or 5
		local spreadOfTargetZone = Fsettings.spreadOfTargetZone or 10
		local showLabel = Fsettings.showLabel or 1
		local showFiboExt = Fsettings.showFiboExt or 1
		local LabelShift = Fsettings.LabelShift or 250
		
		local currentRange = 0
		
        local maxNumberOfZZLevelsLines = 20
		
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
			
			CoGlineIndex={}
			CoGlineIndex[index]=1
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
			
            ZZLevels={}
            
            lineIndex = {}
			for nn = 1, numberOfLines do
				lineIndex[nn] = {}
				lineIndex[nn]["val"] = nil
				lineIndex[nn]["index"] = 1
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
		for nn = 1, numberOfLines do
			lineIndex[nn]["val"] = nil
		end				
		
		--обнуляем линии на предыдущих свечках
		--2 линия
		SetValue(lineIndex[2]["index"], 2, nil)
		for nn=1,numberOfShownCOG do
			SetValue(CoGlineIndex[nn], 2, nil)
		end
		
		--3-15 линии
		if showCalculatedLevels == 1 then
			for nn = 3, 15 do
				SetValue(lineIndex[nn]["index"], nn, nil)
				SetValue(index-1, nn, nil)
			end
		end
		
		--16, 17 линии
		if showTargetZone == 1 then
			SetValue(lineIndex[16]["index"], 16, nil)				
			SetValue(lineIndex[17]["index"], 17, nil)				
			SetValue(index-1, 16, nil)				
			SetValue(index-1, 17, nil)				
		end
		--18, 21 линии
		if showFiboExt == 1 then
			SetValue(lineIndex[18]["index"], 18, nil)				
			SetValue(lineIndex[19]["index"], 19, nil)				
			SetValue(lineIndex[20]["index"], 20, nil)				
			SetValue(lineIndex[21]["index"], 21, nil)				
			SetValue(index-1, 18, nil)				
			SetValue(index-1, 19, nil)				
			SetValue(index-1, 20, nil)				
			SetValue(index-1, 21, nil)				
		end

		--22, 24 линии
		if showTargetZone == 1 then
			SetValue(lineIndex[22]["index"], 22, nil)				
			SetValue(lineIndex[23]["index"], 23, nil)				
			SetValue(lineIndex[24]["index"], 24, nil)				
			SetValue(index-1, 22, nil)				
			SetValue(index-1, 23, nil)				
			SetValue(index-1, 24, nil)				
		end

		for nn=0,4 do
			if ZZLevels[#ZZLevels - nn]~=nil then
				SetValue(ZZLevels[#ZZLevels - nn]["index"], 25, nil)
			end
		end
		--SetValue(lineIndex[25]["index"], 25, nil)
		
		--26-105 линии
		if showZZLevels == 1 then
			for nn = 1, maxNumberOfZZLevelsLines*2*2 do
				SetValue(lineIndex[numberOfLines-nn+1]["index"], numberOfLines-nn+1, nil)
				SetValue(index - 1, numberOfLines-nn+1, nil)
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
				lineIndex[1]['val']= cache_H[index]
				ReplaceLastPeak(index, cache_H[index], ZZLevels)

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
					
					local extr, extrIndex = findExtremum(index, H_index[index], 0)
					cache_L[index] = extr
					L_index[index] = extrIndex
					--WriteLog ("extr "..tostring(extr));
					--WriteLog ("extrIndex "..tostring(extrIndex));
					if extr > L(index) then
						lineIndex[1][1] = extr
					end

					--if breakBars[index] < L(index) then
					--	cache_L[index] = breakBars[index]
					--	L_index[index] = breakIndex[index]
					--else
					--	cache_L[index] = L(index)
					--	L_index[index] = index					
					--	lineIndex[1][1] = cache_L[index]
					--end
					
					--WriteLog ("break");
					--WriteLog ("cache_ST[index] "..tostring(cache_ST[index]));
					--WriteLog ("UpThrust[index] "..tostring(UpThrust[index]));
					--WriteLog ("breakBars[index] "..tostring(breakBars[index]));
					--WriteLog ("breakIndex[index] "..tostring(breakIndex[index]));

					--RegisterPeak(H_index[index], cache_H[index], ZZLevels)			
					RegisterPeak(L_index[index], cache_L[index], ZZLevels)			
								
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
				lineIndex[1]['val'] = cache_L[index]
				ReplaceLastPeak(index, cache_L[index], ZZLevels)

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

					local extr, extrIndex = findExtremum(index, L_index[index], 1)
					cache_H[index] = extr
					H_index[index] = extrIndex
					--WriteLog ("extr "..tostring(extr));
					--WriteLog ("extrIndex "..tostring(extrIndex));
					if extr < H(index) then
						lineIndex[1]['val'] = extr
					end

					--if breakBars[index] > H(index) then
					--	cache_H[index] = breakBars[index]
					--	H_index[index] = breakIndex[index]
					--else
					--	cache_H[index] = H(index)
					--	H_index[index] = index					
					--	lineIndex[1][1] = cache_H[index]
					--end
										
                    --RegisterPeak(L_index[index], cache_L[index], ZZLevels)			
                    RegisterPeak(H_index[index], cache_H[index], ZZLevels)			
									
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
		
        local sizeOfZZLevels = #ZZLevels
		--lineIndex[1]["val"] = ZZLevels[sizeOfZZLevels]

		-- вывод данных
		if  index == Size() and sizeOfZZLevels > 4 then
					
			local lastRange = 0
			local lastHi =  0
            local lastLow = H(index)
            
            local sortedZZLevels = {}
            for i=1,sizeOfZZLevels do
                if ZZLevels[i]~=nil then
                    sortedZZLevels[i] = ZZLevels[i]
                end
            end
            table.sort(sortedZZLevels, function(a,b) return a["val"]<b["val"] end)
            local dminZ = math.abs(sortedZZLevels[1]["val"] - C(index))
            local dmaxZ = math.abs(sortedZZLevels[#sortedZZLevels]["val"] - C(index))
            --message("min "..tostring(sortedZZLevels[1]["val"]))
            --message("max "..tostring(sortedZZLevels[#sortedZZLevels]["val"]))

			local priceLevel
			if numberOfHistoryZZLevels~=0 then
				if dminZ < dmaxZ then
					for i=2,#sortedZZLevels do
						--message("min  C(index) "..tostring(C(index)).." sortedZZLevels[i] "..tostring(sortedZZLevels[i]["val"]))
						--message(tostring(C(index) > sortedZZLevels[i-1]["val"] and C(index) < sortedZZLevels[i]["val"]))
						if C(index) > sortedZZLevels[i-1]["val"] and C(index) <= sortedZZLevels[i]["val"] then
							priceLevel = i
							break
						end
					end
				else
					for i=#sortedZZLevels,2,-1 do
						--message("max C(index) "..tostring(C(index)).." sortedZZLevels[i] "..tostring(sortedZZLevels[i]["val"]))
						--message(tostring(C(index) > sortedZZLevels[i-1]["val"] and C(index) <= sortedZZLevels[i]["val"]))
						if C(index) > sortedZZLevels[i-1]["val"] and C(index) <= sortedZZLevels[i]["val"] then
							priceLevel = i
							break
						end
					end
				end
			end	
			
            --WriteLog ("#sortedZZLevels "..tostring(#sortedZZLevels))
            --WriteLog ("numberOfHistoryZZLevels "..tostring(numberOfHistoryZZLevels))
            --WriteLog ("priceLevel "..tostring(priceLevel))
			
			local minRangeIndex = 1
			local maxRangeIndex = #sortedZZLevels
			
            if priceLevel ~= nil then
				minRangeIndex = priceLevel
				maxRangeIndex = priceLevel
				local minj = math.max(priceLevel-numberOfHistoryZZLevels,1)
                local maxj = math.min(priceLevel+numberOfHistoryZZLevels-1, #sortedZZLevels)
				--WriteLog ("minRangeIndex "..tostring(minRangeIndex).." minj "..tostring(minj))
				--WriteLog ("maxRangeIndex "..tostring(maxRangeIndex).." maxj "..tostring(maxj))
                for j = minj, maxj do
                    if sortedZZLevels[j] ~= nil then
                        if sortedZZLevels[j]["val"] < lastLow then
                            lastLow = sortedZZLevels[j]["val"]
                            minRangeIndex = j
                        end
                        if sortedZZLevels[j]["val"] > lastHi then
                            lastHi = sortedZZLevels[j]["val"]
                            maxRangeIndex = j
                        end
                    end				
                end		
			end	
			
			--WriteLog ("minRangeIndex "..tostring(minRangeIndex).." lastLow "..tostring(lastLow))
            --WriteLog ("maxRangeIndex "..tostring(maxRangeIndex).." lastHi "..tostring(lastHi))
			
			deepZZForCalculatedLevels = math.min(deepZZForCalculatedLevels,#ZZLevels-1)
			numberOfZZLevels = math.min(numberOfZZLevels,#ZZLevels-1)
			numberOfMovesForTargetZone = math.min(numberOfMovesForTargetZone,#ZZLevels-1)

			local j = 1
			while j<=deepZZForCalculatedLevels do
            --for j = 1, deepZZForCalculatedLevels do
				if ZZLevels[sizeOfZZLevels-j+1] ~= nil then
					if math.abs(ZZLevels[sizeOfZZLevels-j+1]["val"] - C(index))/ZZLevels[sizeOfZZLevels-j+1]["val"] > 0.5 then
						deepZZForCalculatedLevels = math.min(5,#ZZLevels-1)
						numberOfZZLevels = math.min(numberOfZZLevels,deepZZForCalculatedLevels)
						numberOfMovesForTargetZone = math.min(numberOfMovesForTargetZone,deepZZForCalculatedLevels)
						if j>deepZZForCalculatedLevels then
							break
						end
					end
                    lastLow = math.min(ZZLevels[sizeOfZZLevels-j+1]["val"], lastLow)
                    lastHi = math.max(ZZLevels[sizeOfZZLevels-j+1]["val"], lastHi)
				end	
				j = j+1			
            end		
			
            local pD = ZZLevels[sizeOfZZLevels]["val"]            
            local LastExtInd = ZZLevels[sizeOfZZLevels]["index"]
            		
			--WriteLog ("X "..tostring(ZZLevels[sizeOfZZLevels-4]["val"]))
			--WriteLog ("A "..tostring(ZZLevels[sizeOfZZLevels-3]["val"]))
			--WriteLog ("B "..tostring(ZZLevels[sizeOfZZLevels-2]["val"]))
			--WriteLog ("C "..tostring(ZZLevels[sizeOfZZLevels-1]["val"]))
			--WriteLog ("D "..tostring(pD))

			local pX = 0
			local pA = 0
			local pB = 0
			local pC = 0
						
			local XA = 0
			local AB = 0
			local BC = 0
			local XC = 0
			local CD = 0
			local AD = 0

			local vXA = 0
			local vAB = 0
			local vBC = 0
			local vCD = 0

			local ABtoXA = 0
			local XCtoXA =0
			local CDtoAB = 0
			local ADtoXA = 0

			local currentDeviation = 0
			
			if ZZLevels[sizeOfZZLevels-4] ~= nil then

				pX = ZZLevels[sizeOfZZLevels-4]["val"]
				pA = ZZLevels[sizeOfZZLevels-3]["val"]
				pB = ZZLevels[sizeOfZZLevels-2]["val"]
				pC = ZZLevels[sizeOfZZLevels-1]["val"]
                
				SetValue(ZZLevels[sizeOfZZLevels-4]["index"], 25, pX)
				SetValue(ZZLevels[sizeOfZZLevels-3]["index"], 25, pA)
				SetValue(ZZLevels[sizeOfZZLevels-2]["index"], 25, pB)
				SetValue(ZZLevels[sizeOfZZLevels-1]["index"], 25, pC)
				SetValue(LastExtInd, 25, pD)
				lineIndex[25]["index"] = LastExtInd
				if LastExtInd == Size() then
					lineIndex[25]["val"] = pD
				end
			
				XA = math.abs(ZZLevels[sizeOfZZLevels-4]["val"] - ZZLevels[sizeOfZZLevels-3]["val"])
				AB = math.abs(ZZLevels[sizeOfZZLevels-3]["val"] - ZZLevels[sizeOfZZLevels-2]["val"])
				BC = math.abs(ZZLevels[sizeOfZZLevels-2]["val"] - ZZLevels[sizeOfZZLevels-1]["val"])
				XC = math.abs(ZZLevels[sizeOfZZLevels-4]["val"] - ZZLevels[sizeOfZZLevels-1]["val"])
				CD = math.abs(ZZLevels[sizeOfZZLevels-1]["val"] - pD)
				AD = math.abs(ZZLevels[sizeOfZZLevels-3]["val"] - pD)
				ABtoXA = round(100*AB/XA, 2)
				XCtoXA = round(100*XC/XA, 2)
				CDtoAB = round(100*CD/AB, 2)
				ADtoXA = round(100*AD/XA, 2)
				CDtoXA = round(100*CD/XA, 2)
				currentDeviation = round(100*math.abs(C(index) - pD)/CD, 2)

				XA = round(XA, scale)
				AB = round(AB, scale)
				BC = round(BC, scale)
				XC = round(XC, scale)
				CD = round(CD, scale)
				AD = round(AD, scale)

				for i=1, ZZLevels[sizeOfZZLevels-3]["index"] - ZZLevels[sizeOfZZLevels-4]["index"] do
					vXA = vXA + V(i + ZZLevels[sizeOfZZLevels-4]["index"])
				end
				for i=1, ZZLevels[sizeOfZZLevels-2]["index"] - ZZLevels[sizeOfZZLevels-3]["index"] do
					vAB = vAB + V(i + ZZLevels[sizeOfZZLevels-3]["index"])
				end
				for i=1, ZZLevels[sizeOfZZLevels-1]["index"] - ZZLevels[sizeOfZZLevels-2]["index"] do
					vBC = vBC + V(i + ZZLevels[sizeOfZZLevels-2]["index"])
				end
				for i=1, ZZLevels[sizeOfZZLevels]["index"] - ZZLevels[sizeOfZZLevels-1]["index"] do
					vCD = vCD + V(i + ZZLevels[sizeOfZZLevels-1]["index"])
				end

			end	
			
			if showCalculatedLevels == 1 then
							
				if regimeOfCalculatedLevels == 1 then
					
					if ZZLevels[sizeOfZZLevels-1] == nil then
                        lastRange = 0
                    else
                        lastRange = math.abs(ZZLevels[sizeOfZZLevels]["val"] - ZZLevels[sizeOfZZLevels-1]["val"])
                    end
				else															
					lastRange = math.abs(lastHi - lastLow)				
				end
								
				if  lastRange ~=0 then 
					
					local increment = 2
					
					if showextraCalculatedLevels == 1 then				
						for nn = 1, 2 do
							SetValue(index-widthOfCalculatedMarks, nn+2, lastLow - nn*lastRange/8)				
							lineIndex[nn+2]["val"] = lastLow - nn*lastRange/8
							SetValue(index-widthOfCalculatedMarks, nn+13, lastHi + nn*lastRange/8)				
							lineIndex[nn+13]["val"] = lastHi + nn*lastRange/8
						end
						increment = 1
					end				
					
					for nn = 5, 13, increment do					
						local value = lastLow + (nn-5)*lastRange/8
						SetValue(index-widthOfCalculatedMarks, nn, value)				
						lineIndex[nn]["val"] = value
					end
						
					for nn = 3, 15 do
						lineIndex[nn]["index"] = index-widthOfCalculatedMarks
					end
					
				end
			end
			
			if showZZLevels == 1 then
				
				local add = 0
                local nn = 0
                local addedZZ = {}
                for j = 1, numberOfZZLevels do
                    if ZZLevels[sizeOfZZLevels-j+1] ~= nil then
                        nn = nn + 1
                        if C(index) > ZZLevels[sizeOfZZLevels-j+1]["val"] then
                            add = -40
                        else add = 0	
                        end
                        addedZZ[ZZLevels[sizeOfZZLevels-j+1]["index"]] = 1
                        SetValue(ZZLevels[sizeOfZZLevels-j+1]["index"], numberOfLines-j+1+add, ZZLevels[sizeOfZZLevels-j+1]["val"])
                        lineIndex[numberOfLines-j+1+add]["val"] = ZZLevels[sizeOfZZLevels-j+1]["val"]
                        lineIndex[numberOfLines-j+1+add]["index"] = ZZLevels[sizeOfZZLevels-j+1]["index"]
                        --WriteLog ("ZZLevels["..tostring(sizeOfZZLevels-j+1).."][val] "..tostring(ZZLevels[sizeOfZZLevels-j+1]["val"]));
                        --WriteLog ("ZZLevels["..tostring(sizeOfZZLevels-j+1).."][index] "..tostring(ZZLevels[sizeOfZZLevels-j+1]["index"]));
                    end
                end

                if priceLevel ~= nil then
                    for j = minRangeIndex, maxRangeIndex do
                        nn = nn + 1
                        if addedZZ[sortedZZLevels[j]["index"]] == nil then
                            if sortedZZLevels[j] ~= nil then
                                if C(index) > sortedZZLevels[j]["val"] then
                                    add = -40
                                else add = 0	
                                end                           
                                --WriteLog ("numberOfLines-nn+1+add "..tostring(numberOfLines-nn+1+add));
                                SetValue(sortedZZLevels[j]["index"], numberOfLines-nn+1+add, sortedZZLevels[j]["val"])
                                lineIndex[numberOfLines-nn+1+add]["val"] = sortedZZLevels[j]["val"]
                                lineIndex[numberOfLines-nn+1+add]["index"] = sortedZZLevels[j]["index"]
                                --WriteLog ("sortedZZLevels["..tostring(j).."][val] "..tostring(sortedZZLevels[j]["val"]));
                                --WriteLog ("sortedZZLevels["..tostring(j).."][index] "..tostring(sortedZZLevels[j]["index"]));
                            end
                        end
                    end
                end				
							
			end
			
			if showTargetZone == 1 then
				
				targetE = 0
				getPattern(pX, pA, pB, pC, pD)
				if targetE ~= 0 then

					evE = nil
					mutE = nil
					CalcPrognozPoint(pX,pA,pB,pC,targetE)
					
					if targetE == pD then targetE = nil end

					SetValue(index-widthOfTargetMarks, 22, targetE)				
					lineIndex[22]["val"] = targetE
					lineIndex[22]["index"] = index-widthOfTargetMarks
					
					SetValue(index-widthOfTargetMarks, 23, evE)	
					lineIndex[23]["val"] = evE
					lineIndex[23]["index"] = index-widthOfTargetMarks

					SetValue(index-widthOfTargetMarks, 24, mutE)	
					lineIndex[24]["val"] = mutE
					lineIndex[24]["index"] = index-widthOfTargetMarks
				else


					--WriteLog ("!!!!Lost Z point")
					
					--for i=sizeOfZZLevels,sizeOfZZLevels-9,-1 do
					--	if ZZLevels[i]~=nil then
					--		--WriteLog ("T("..ZZLevels[i]["index"].."); "..isnil(toYYYYMMDDHHMMSS(T(ZZLevels[i]["index"]))).." "..tostring(ZZLevels[i]["val"]))
					--	end
					--end
				
					local meanRange = 0
					local quantRange = 0
					
					for j = 1, numberOfMovesForTargetZone*2-1, 2 do
						if ZZLevels[sizeOfZZLevels-j -1] ~= nil then
							meanRange = meanRange + math.abs(ZZLevels[sizeOfZZLevels-j]["val"] - ZZLevels[sizeOfZZLevels-j -1]["val"])
							quantRange = quantRange + 1
						end
					end				
					
					if quantRange ~= 0 then
						
						if ZZLevels[sizeOfZZLevels]["val"] > ZZLevels[sizeOfZZLevels-1]["val"] then
							meanRange = meanRange/quantRange
						else
							meanRange = -1*meanRange/quantRange
						end
						
						local outT1 = ZZLevels[sizeOfZZLevels]["val"] + meanRange*(1 - spreadOfTargetZone/100)
						SetValue(index-widthOfTargetMarks, 16, outT1)				
						lineIndex[16]["val"] = outT1
						lineIndex[16]["index"] = index-widthOfTargetMarks
						local outT2 = ZZLevels[sizeOfZZLevels]["val"] + meanRange*(1 + spreadOfTargetZone/100)
						SetValue(index-widthOfTargetMarks, 17, outT2)	
						lineIndex[17]["val"] = outT2
						lineIndex[17]["index"] = index-widthOfTargetMarks
						
					end
				end
						
			end
			if showFiboExt == 1 then
				
				if ZZLevels[sizeOfZZLevels-3] ~= nil  then
					local rangeFibo = math.max(math.abs((ZZLevels[sizeOfZZLevels-2]["val"] - ZZLevels[sizeOfZZLevels-3]["val"])), math.abs((ZZLevels[sizeOfZZLevels-2]["val"] - ZZLevels[sizeOfZZLevels-1]["val"])))
					--local corrRangeFibo = math.abs((ZZLevels[sizeOfZZLevels-2]["val"] - ZZLevels[sizeOfZZLevels-3]["val"]))
					local sign = 1
					if C(index) < ZZLevels[sizeOfZZLevels-1]["val"] then
						sign = -1
					end

					local outTF1000 = ZZLevels[sizeOfZZLevels-1]["val"] + sign*rangeFibo
					local outTF1618 = ZZLevels[sizeOfZZLevels-1]["val"] + sign*rangeFibo*1.618
					local outTF2618 = ZZLevels[sizeOfZZLevels-1]["val"] + sign*rangeFibo*2.618
					local outTF4236 = ZZLevels[sizeOfZZLevels-1]["val"] + sign*rangeFibo*4.236
					
					if outTF4236 < 0 or (sign*(C(index) - outTF2618) < 0) then outTF4236 = nil end
					if outTF2618 < 0 or (sign*(C(index) - outTF1618) < 0) then outTF2618 = nil end
					--if outTF1618 < 0 or (sign*(C(index) - outTF1000) < 0) then outTF1618 = nil end
					if outTF1618 < 0 then outTF1618 = nil end
					if outTF1000 < 0 then outTF1000 = nil end
					--if (sign*(C(index) - (outTF1618 or C(index))) > 0) then outTF1000 = nil end
					--if (sign*(C(index) - (outTF2618 or C(index))) > 0) then outTF1618 = nil end
					--if (sign*(C(index) - (outTF4236 or C(index))) > 0) then outTF2618 = nil end

					local widthOfTargetFibo = index - ZZLevels[sizeOfZZLevels-2]["index"]

					SetValue(index-widthOfTargetFibo, 18, outTF1000)				
					lineIndex[18]["val"] = outTF1000
					lineIndex[18]["index"] = index-widthOfTargetFibo
					SetValue(index-widthOfTargetFibo, 19, outTF1618)				
					lineIndex[19]["val"] = outTF1618
					lineIndex[19]["index"] = index-widthOfTargetFibo
					SetValue(index-widthOfTargetFibo, 20, outTF2618)				
					lineIndex[20]["val"] = outTF2618
					lineIndex[20]["index"] = index-widthOfTargetFibo
					SetValue(index-widthOfTargetFibo, 21, outTF4236)				
					lineIndex[21]["val"] = outTF4236
					lineIndex[21]["index"] = index-widthOfTargetFibo
				end	
						
			end
			
			--if isBreak == 1 then
			--	for nn = 1, numberOfLines do
			--		--WriteLog ("lineIndex[1]["..tostring(nn).."] "..tostring(lineIndex[1][nn]));
			--		--WriteLog ("lineIndex[2]["..tostring(nn).."] "..tostring(lineIndex[2][nn]));
			--	end					
			--end		
			
			-- выводим метку паттерна
			
			--local labelAtHigh = true
			--local zLabelShift = deepZZForCalculatedLevels
			--while ZZLevels[sizeOfZZLevels-zLabelShift] == nil and zLabelShift > 0 do
			--	zLabelShift = zLabelShift - 1 
			--end
			--if zLabelShift ~= 0 then
			--	labelAtHigh = ZZLevels[sizeOfZZLevels-zLabelShift]["index"] < ZZLevels[sizeOfZZLevels-zLabelShift+1]["index"]
			--end

			local labelAtHigh = math.abs(C(index) - lastHi) < math.abs(C(index) - lastLow)

			if showLabel == 1 and Settings.ChartId ~= '' then
			
				label.DATE, label.TIME = getCandleProp(index-LabelShift) --ZZLevels[sizeOfZZLevels]["index"]
				local firsY
				local secondY
				local thirdY

				if labelAtHigh then
					firsY = lastHi + 3*(lastHi - lastLow)/17
					secondY = firsY - (lastHi - lastLow)/17
					thirdY = secondY - (lastHi - lastLow)/17
				else
					firsY = lastLow - (lastHi - lastLow)/17
					secondY = firsY - (lastHi - lastLow)/17
					thirdY = secondY - (lastHi - lastLow)/17
				end
				
				--WriteLog ("firsY "..tostring(firsY).." secondY "..tostring(secondY).."thirdY"..tostring(thirdY))
				--WriteLog ("date "..tostring(label.DATE).." time "..tostring(label.TIME))

				label.YVALUE = firsY
				if whiteLabelColor == 1  then
					label.R = 200 
					label.G = 200 
					label.B = 200  
				else
					label.R = 0 
					label.G = 0 
					label.B = 0  
				end
				label.TRANSPARENCY = 0 
				label.TRANSPARENT_BACKGROUND = 1  
				label.FONT_FACE_NAME = 'Verdana'  
				label.FONT_HEIGHT = 10  
				label.HINT = ''								
				
				upIntervals = 0
				upcount = 0
				downIntervals = 0
				downcount = 0

				for j = 0, numberOfMovesForTargetZone*2-1, 2 do
					if ZZLevels[sizeOfZZLevels-j -1] ~= nil then
						if ZZLevels[sizeOfZZLevels-j]["val"] > ZZLevels[sizeOfZZLevels-j -1]["val"] then
							upIntervals = upIntervals + ZZLevels[sizeOfZZLevels-j]["index"] - ZZLevels[sizeOfZZLevels-j -1]["index"]
							upcount = upcount + 1
						else
							downIntervals = downIntervals + ZZLevels[sizeOfZZLevels-j]["index"] - ZZLevels[sizeOfZZLevels-j -1]["index"]
							downcount = downcount + 1
						end
					end
				end
				--WriteLog ("upInt "..tostring(upIntervals).." count "..tostring(upcount).."/"..tostring(index - ZZLevels[sizeOfZZLevels]["index"]))
				--WriteLog ("downInt "..tostring(downIntervals).." count "..tostring(downcount).."/"..tostring(index - ZZLevels[sizeOfZZLevels]["index"]))

				--первая метка
				
				text = "AB/XA "..tostring(ABtoXA)..", XC/XA "..tostring(XCtoXA)..", CD/AB "..tostring(CDtoAB)..", AD/XA "..tostring(ADtoXA)..", CD/XA "..tostring(CDtoXA)
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
				local text = "now "..tostring(currentDeviation).."%, ".."XA "..tostring(XA)..", AB "..tostring(AB)..", BC "..tostring(BC)..", CD "..tostring(CD)
				if upcount ~= 0 and ZZLevels[sizeOfZZLevels-1]["val"] < C(index) then
					text = text..", upInt "..tostring(math.ceil(upIntervals/upcount)).."/"..tostring(LastExtInd - ZZLevels[sizeOfZZLevels-1]["index"]).."/"..tostring(index - LastExtInd)
				end
				if downcount ~= 0 and ZZLevels[sizeOfZZLevels-1]["val"] > C(index)  then
					text = text..", downInt "..tostring(math.ceil(downIntervals/downcount)).."/"..tostring(LastExtInd - ZZLevels[sizeOfZZLevels-1]["index"]).."/"..tostring(index - LastExtInd)
				end
				label.TEXT = text				
				
				if AddedLabels[2] ~= nil then
					SetLabelParams(Settings.ChartId, AddedLabels[2], label)
				else
					local LabelID = AddLabel(Settings.ChartId, label)
					
					if LabelID ~=nil and LabelID ~= -1 then
						AddedLabels[2] = LabelID --#AddedLabels+1
					end	
				end

				--третья метка
				label.YVALUE = thirdY
				text = "Volume XA: "..format_num(vXA,0).."; AB: "..format_num(vAB,0).."; BC: "..format_num(vBC,0).."; CD: "..format_num(vCD,0)
				label.TEXT = text				
				
				if AddedLabels[3] ~= nil then
					SetLabelParams(Settings.ChartId, AddedLabels[3], label)
				else
					local LabelID = AddLabel(Settings.ChartId, label)
					
					if LabelID ~=nil and LabelID ~= -1 then
						AddedLabels[3] = LabelID --#AddedLabels+1
					end	
				end
				
			end
			
		end
		
		-- выводим центр движения
		if showCoG == 1 and ZZLevels[sizeOfZZLevels-1]~=nil then
            if ZZLevels[sizeOfZZLevels-1] ~= nil  then
				
				local IndCoG = math.floor((ZZLevels[sizeOfZZLevels]["index"] + ZZLevels[sizeOfZZLevels-1]["index"])/2)
				local valCoG = (ZZLevels[sizeOfZZLevels]["val"] + ZZLevels[sizeOfZZLevels-1]["val"])/2
				SetValue(IndCoG, 2, valCoG)
                CoGlineIndex[numberOfShownCOG] = IndCoG
				
				for nn=numberOfShownCOG-1,1,-1 do
					if ZZLevels[sizeOfZZLevels-nn-1]~=nil then
						IndCoG = math.floor((ZZLevels[sizeOfZZLevels-nn]["index"] + ZZLevels[sizeOfZZLevels-nn-1]["index"])/2)
						valCoG = (ZZLevels[sizeOfZZLevels-nn]["val"] + ZZLevels[sizeOfZZLevels-nn-1]["val"])/2
						SetValue(IndCoG, 2, valCoG)
						CoGlineIndex[nn] = IndCoG
					end
				end
		                
            end
		end
				
		--return	unpack(lineIndex[1])
		return	lineIndex[1]["val"]  ,lineIndex[2]["val"]  ,lineIndex[3]["val"]  ,lineIndex[4]["val"]  ,lineIndex[5]["val"]  ,lineIndex[6]["val"]  ,lineIndex[7]["val"]  ,lineIndex[8]["val"]  ,lineIndex[9]["val"]  ,lineIndex[10]["val"], 
				lineIndex[11]["val"] ,lineIndex[12]["val"] ,lineIndex[13]["val"] ,lineIndex[14]["val"] ,lineIndex[15]["val"] ,lineIndex[16]["val"] ,lineIndex[17]["val"] ,lineIndex[18]["val"] ,lineIndex[19]["val"] ,lineIndex[20]["val"],
				lineIndex[21]["val"] ,lineIndex[22]["val"] ,lineIndex[23]["val"] ,lineIndex[24]["val"] ,lineIndex[25]["val"] ,lineIndex[26]["val"] ,lineIndex[27]["val"] ,lineIndex[28]["val"] ,lineIndex[29]["val"] ,lineIndex[30]["val"],
				lineIndex[31]["val"] ,lineIndex[32]["val"] ,lineIndex[33]["val"] ,lineIndex[34]["val"] ,lineIndex[35]["val"] ,lineIndex[36]["val"] ,lineIndex[37]["val"] ,lineIndex[38]["val"] ,lineIndex[39]["val"] ,lineIndex[40]["val"], 
				lineIndex[41]["val"] ,lineIndex[42]["val"] ,lineIndex[43]["val"] ,lineIndex[44]["val"] ,lineIndex[45]["val"] ,lineIndex[46]["val"] ,lineIndex[47]["val"] ,lineIndex[48]["val"] ,lineIndex[49]["val"] ,lineIndex[50]["val"],
				lineIndex[51]["val"] ,lineIndex[52]["val"] ,lineIndex[53]["val"] ,lineIndex[54]["val"] ,lineIndex[55]["val"] ,lineIndex[56]["val"] ,lineIndex[57]["val"] ,lineIndex[58]["val"] ,lineIndex[59]["val"] ,lineIndex[60]["val"],
				lineIndex[61]["val"] ,lineIndex[62]["val"] ,lineIndex[63]["val"] ,lineIndex[64]["val"] ,lineIndex[65]["val"] ,lineIndex[66]["val"] ,lineIndex[67]["val"] ,lineIndex[68]["val"] ,lineIndex[69]["val"] ,lineIndex[60]["val"], 
				lineIndex[71]["val"] ,lineIndex[72]["val"] ,lineIndex[73]["val"] ,lineIndex[74]["val"] ,lineIndex[75]["val"] ,lineIndex[76]["val"] ,lineIndex[77]["val"] ,lineIndex[78]["val"] ,lineIndex[79]["val"] ,lineIndex[70]["val"],
				lineIndex[81]["val"] ,lineIndex[82]["val"] ,lineIndex[83]["val"] ,lineIndex[84]["val"] ,lineIndex[85]["val"] ,lineIndex[86]["val"] ,lineIndex[87]["val"] ,lineIndex[88]["val"] ,lineIndex[89]["val"] ,lineIndex[80]["val"],
				lineIndex[91]["val"] ,lineIndex[92]["val"] ,lineIndex[93]["val"] ,lineIndex[94]["val"] ,lineIndex[95]["val"] ,lineIndex[96]["val"] ,lineIndex[97]["val"] ,lineIndex[98]["val"] ,lineIndex[99]["val"] ,lineIndex[100]["val"],
                lineIndex[101]["val"] ,lineIndex[102]["val"] ,lineIndex[103]["val"] ,lineIndex[104]["val"] ,lineIndex[105]["val"]
		
	end
end

function getPattern(pA, pB, pC, pD, pE)
	
	--- Первичный сброс флага
	IsPointNotReal = false;
	--- Сохраняем старый паттерн
	oldPattern = pattern;
 
	if (pB>pA and pA>pD and pD>pC and pC>pE)	then
		pattern = NamePattern.M1;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M2
	if (pB>pA and pA>pD and pD>pE and pE>pC) then
		pattern = NamePattern.M2;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M3
	if (pB>pD and pD>pA and pA>pC and pC>pE) then
		pattern = NamePattern.M3;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M4
	if (pB>pD and pD>pA and pA>pE and pE>pC) then
		pattern = NamePattern.M4;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M5
	if (pD>pB and pB>pA and pA>pC and pC>pE) then
		pattern = NamePattern.M5;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M6
	if (pD>pB and pB>pA and pA>pE and pE>pC) then
		pattern = NamePattern.M6;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M7
	if (pB>pD and pD>pC and pC>pA and pA>pE) then
		pattern = NamePattern.M7;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M8
	if (pB>pD and pD>pE and pE>pA and pA>pC) then
		pattern = NamePattern.M8;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M9
	if (pD>pB and pB>pC and pC>pA and pA>pE) then
		pattern = NamePattern.M9;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M10
	if (pD>pB and pB>pE and pE>pA and pA>pC) then
		pattern = NamePattern.M10;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M11
	if (pD>pE and pE>pB and pB>pA and pA>pC) then
		pattern = NamePattern.M11;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M12
	if (pB>pD and pD>pC and pC>pE and pE>pA) then
		pattern = NamePattern.M12;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M13
	if (pB>pD and pD>pE and pE>pC and pC>pA) then
		pattern = NamePattern.M13;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M14
	if (pD>pB and pB>pC and pC>pE and pE>pA) then
		pattern = NamePattern.M14;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M15
	if (pD>pB and pB>pE and pE>pC and pC>pA) then
		pattern = NamePattern.M15;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- M16
	if (pD>pE and pE>pB and pB>pC and pC>pA) then
		pattern = NamePattern.M16;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- W1
	if (pA>pC and pC>pB and pB>pE and pE>pD) then
		pattern = NamePattern.W1;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
		return(pattern);	
	end
	--- W2
	if (pA>pC and pC>pE and pE>pB and pB>pD) then
		pattern = NamePattern.W2;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
		return(pattern);	
	end
	--- W3
	if (pA>pE and pE>pC and pC>pB and pB>pD) then
		pattern = NamePattern.W3;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
		return(pattern);	
	end
	--- W4
	if (pA>pC and pC>pE and pE>pD and pD>pB) then
		pattern = NamePattern.W4;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
		return(pattern);	
	end
	--- W5
	if (pA>pE and pE>pC and pC>pD and pD>pB) then
		pattern = NamePattern.W5;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
		return(pattern);	
	end
	--- W6
	if (pC>pA and pA>pB and pB>pE and pE>pD) then
		pattern = NamePattern.W6;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
		return(pattern);	
	end
	--- W7
	if (pC>pA and pA>pE and pE>pB and pB>pD) then
		pattern = NamePattern.W7;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
		return(pattern);	
	end
	--- W8
	if (pE>pA and pA>pC and pC>pB and pB>pD) then
		pattern = NamePattern.W8;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
		return(pattern);	
	end
	--- W9
	if (pC>pA and pA>pE and pE>pD and pD>pB) then
		pattern = NamePattern.W9;	
		AnalysisPointE(pA,pB,pC,pD,pE);	
		return(pattern);	
	end
	--- W10
	if (pE>pA and pA>pC and pC>pD and pD>pB) then
		pattern = NamePattern.W10;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- W11
	if (pC>pE and pE>pA and pA>pB and pB>pD) then
		pattern = NamePattern.W11;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- W12
	if (pE>pC and pC>pA and pA>pB and pB>pD) then
		pattern = NamePattern.W12;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- W13
	if (pC>pE and pE>pA and pA>pD and pD>pB) then
		pattern = NamePattern.W13;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- W14
	if (pE>pC and pC>pA and pA>pD and pD>pB) then
		pattern = NamePattern.W14;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- W15
	if (pC>pE and pE>pD and pD>pA and pA>pB) then
		pattern = NamePattern.W15;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- W16
	if (pE>pC and pC>pD and pD>pA and pA>pB) then
		pattern = NamePattern.W16;
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	
	--- NOPATTERN
	pattern = NamePattern.NOPATTERN;
	return(pattern);
	
end

function AnalysisPointE(pA,pB,pC,pD,pE)

	--- Контрольный сброс флага
	IsPointNotReal = false;
	--WriteLog("Pattern "..tostring(pattern))

	 --- 1. Если паттерн определен то можно анализировать/корректировать значение E
	if ((pattern ~= NamePattern.NOPATTERN) and (pattern ~= NamePattern.ERROR))
	  then
	   if (pattern == NamePattern.M1)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.618)
			then
			 pE = round(pD - 1.618 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M2)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.5)
			then
			 pE = round(pD - 0.5 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M3)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.2720)
			then
			 pE = round(pD - 1.2720 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M4)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.618)
			then
			 pE = round(pD - 0.618 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M5)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.2720)
			then
			 pE = round(pD - 1.2720 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M6)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.618)
			then
			 pE = round(pD - 0.618 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M7)
		 then
		  if (((pD-pE)/(pD-pC)) < 3.0000)
			then
			 pE = round(pD - 3.0000 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M8)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.3819)
			then
			 pE = round(pD - 0.3819 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M9)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.618)
			then
			 pE = round(pD - 1.618 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M10)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.5)
			then
			 pE = round(pD - 0.5 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M11)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.25)
			then
			 pE = round(pD - 0.25 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M12)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.618)
			then
			 pE = round(pD - 1.618 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M13)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.5)
			then
			 pE = round(pD - 0.5 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M14)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.2720)
			then
			 pE = round(pD - 1.2720 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M15)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.618)
			then
			 pE = round(pD - 0.618 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M16)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.3819)
			then
			 pE = round(pD - 0.3819 * (pD-pC),scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W1)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.3819)
			then
			 pE = round(0.3819 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W2)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.618)
			then
			 pE = round(0.618 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W3)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.2720)
			then
			 pE = round(1.2720 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W4)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.5)
			then
			 pE = round(0.5 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W5)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.618)
			then
			 pE = round(1.618 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W6)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.25)
			then
			 pE = round(0.25 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W7)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.5)
			then
			 pE = round(0.5 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W8)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.618)
			then
			 pE = round(1.618 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W9)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.3819)
			then
			 pE = round(0.3819 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W10)
		 then
		  if (((pE-pD)/(pC-pD)) < 3.0000)
			then
			 pE = round(3.0000 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W11)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.618)
			then
			 pE = round(0.618 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W12)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.2720)
			then
			 pE = round(1.2720 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W13)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.618)
			then
			 pE = round(0.618 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	  if (pattern == NamePattern.W14)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.2720)
			then
			 pE = round(1.2720 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W15)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.5)
			then
			 pE = round(0.5 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W16)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.618)
			then
			 pE = round(1.618 * (pC-pD)+pD,scale);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	  end
 
	targetE = pE

end

function CalcPrognozPoint(pA,pB,pC,pD,pE)

	if (pattern == NamePattern.ERROR)
	  then
	--+------------------------------------------------------------+
	--| ПАТТЕРН: ERROR                                             |
	--| Точка "эволюции"=> НЕТ = 0                                 |
	--| Точка "мутации" => НЕТ = 0                                 |
	--+------------------------------------------------------------+
	  evE = nil 
	  mutE = nil
	  ----- level_1:
	  --CalcPrognozLevel1();
	  return;
   end


	----- ПРОВЕРКА НАЛИЧИЯ ТЕКУЩЕГО ПАТТЕРНА
	if (pattern == NamePattern.NOPATTERN)
	  then
	   evE = nil 
	   mutE = nil            -- НЕТ ПРОГНОЗА
	   --CalcPrognozLevel1();
	   return;                                         -- НЕТ ПАТТЕРНА - ВЫХОД
	end 

	--+---------------------------------------------------------------+
	--| РАСЧЕТ ТОЧЕК ПРОГНОЗА                                         |
	--+---------------------------------------------------------------+
	  
	   if pattern == NamePattern.M1 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M1 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет= 0                                  |
	   --| Точка "мутации" => W1 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M2 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M2 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M1 = D - 1.618 * (pD-pC)                |
	   --| Точка "мутации" => W4 = 0.5 * (pD-pE)+pE                  |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 1.618 * (pD-pC),scale);
		 
		 -----
		 mutE = round(0.5 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M3 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M3 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет= 0                                  |
	   --| Точка "мутации" => W1 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M4 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M4 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M3 = D - 1.272 * (pD-pC)                |
	   --| Точка "мутации" => W4 = 0.5 * (pD-pE)+pE                  |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 1.272 * (pD-pC),scale);
		         
		 -----
		 mutE = round(0.5 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M5 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M5 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет = 0                                 |
	   --| Точка "мутации" => W6  = 0.25 * (pD-pE)+pE                |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = round(0.25 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M6 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M6 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M5 = D - 1.272 * (pD-pC)                |
	   --| Точка "мутации" => W9 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 1.272 * (pD-pC),scale);
		         
		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M7 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M7 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет = 0                                 |
	   --| Точка "мутации" => W1  = 0.3819 * (pD-pE)+pE              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M8 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M8 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M4 = D - 0.618 * (pD-pC)                |
	   --| Точка "мутации" => W4 = 0.5 * (pD-pE)+pE                  |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 0.618 * (pD-pC),scale);
		         
		 -----
		 mutE = round(0.5 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M9 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M9 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> нет = 0                                 |
	   --| Точка "мутации" => W6  = 0.25 * (pD-pE)+pE                |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = round(0.25 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M10 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M10 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M6 = D - 0.618 * (pD-pC)                |
	   --| Точка "мутации" => W9 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 0.618 * (pD-pC),scale);
		 
		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M11 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M11 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M10 = D - 0.5 * (pD-pC)                 |
	   --| Точка "мутации" => W15 = 0.5 * (pD-pE)+pE                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 0.5 * (pD-pC),scale);
		 
		 -----
		 mutE = round(0.5 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M12 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M12 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M7 = D - 3.0000 * (pD-pC)               |
	   --| Точка "мутации" => W1 = 0.3819 * (pD-pE)+pE               |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 3.0000 * (pD-pC),scale);
		 
		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M13 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M13 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M12 = D - 1.618 * (pD-pC)               |
	   --| Точка "мутации" => W4  = 0.5 * (pD-pE)+pE                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 1.618 * (pD-pC),scale);
		 
		 -----
		 mutE = round(0.5 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M14 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M14 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M9 = D - 1.618 * (pD-pC)                |
	   --| Точка "мутации" => W6 = 0.25 * (pD-pE)+pE                 |
	   --+------------------------------------------------------------+
		 evE = round(pD - 1.618 * (pD-pC),scale);
		 
		 -----
		 mutE = round(0.25 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M15 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M15 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M14 = D - 1.272 * (pD-pC)               |
	   --| Точка "мутации" => W9  = 0.3819 * (pD-pE)+pE              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pC-(pC-pA)/1.618,scale);
		 
		 -----
		 mutE = round(pE+(pB-pE)/1.618,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.M16 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: M16 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> M15 = D - 0.618 * (pD-pC)               |
	   --| Точка "мутации" => W15 = 0.5 * (pD-pE)+pE                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(pD - 0.618 * (pD-pC),scale);
		         
		 -----
		 mutE = round(0.5 * (pD-pE)+pE,scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W1 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W1 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W2  = 0.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M2  = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(0.618 * (pC-pD)+pD,scale);
		         
		 -----
		 mutE = round(pE-0.5 * (pE-pD),scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W2 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W2 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W3  = 1.272 * (pC-pD)+pD               |
	   --| Точка "мутации" => M8  = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(1.272 * (pC-pD)+pD,scale);
		         
		 -----
		 mutE = round(pE-0.3819 * (pE-pD),scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W3 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W3 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W8  = 1.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M11 = E - 0.25 * (pE-pD)                |
	   --+------------------------------------------------------------+
		 evE = round(1.618 * (pC-pD)+pD,scale);
		         
		 -----
		 mutE = round(pE-0.25 * (pE-pD),scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W4 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W4 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W5  = 1.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M13 = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(1.618 * (pC-pD)+pD,scale);
		         
		 -----
		 mutE = round(pE-0.5 * (pE-pD),scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W5 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W5 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W10 = 3.0000 * (pC-pD)+pD              |
	   --| Точка "мутации" => M16 = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 evE = round(3.0000 * (pC-pD)+pD,scale);
		         
		 -----
		 mutE = round(pE-0.3819 * (pE-pD),scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W6 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W6 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W7 = 0.5 * (pC-pD)+pD                  |
	   --| Точка "мутации" => M2 = E - 0.5 * (pE-pD)                  |
	   --+------------------------------------------------------------+
		 evE = round(0.5 * (pC-pD)+pD,scale);
		         
		 -----
		 mutE = round(pE-0.5 * (pE-pD),scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W7 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W7 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W11 = 0.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M8  = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 evE = round(0.618 * (pC-pD)+pD,scale);
		         
		 -----
		 mutE = round(pE-0.3819 * (pE-pD),scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W8 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W8 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M11 = E - 0.25 * (pE-pD)                |
	   --+------------------------------------------------------------+
		 evE = nil        
		 -----
		 mutE = round(pE-0.25 * (pE-pD),scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W9 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W9 +++                                            |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W13 = 0.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M13 = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+
		 evE = round(0.618 * (pC-pD)+pD,scale);
		         
		 -----
		 mutE = round(pE-0.5 * (pE-pD),scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W10 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W10 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M16 = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 evE = nil   
		 -----
		 mutE = round(pE-0.3819 * (pE-pD),scale);
		         
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W11 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W11 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W12 = 1.272 * (pC-pD)+pD               |
	   --| Точка "мутации" => M8  = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 evE = round(1.272 * (pC-pD)+pD,scale);
		         
		 -----
		 mutE = round(pE-0.3819 * (pE-pD),scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W12 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W12 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M11 = E - 0.25 * (pE-pD)                |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil
		 -----
		 mutE = round(pE-0.25 * (pE-pD),scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W13 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W13 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W14 = 1.272 * (pC-pD)+pD               |
	   --| Точка "мутации" => M13 = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+
	   
	   ----- level_0:
	   evE = round(1.272 * (pC-pD)+pD,scale);
	   
	   -----
	   mutE = round(pE-0.5 * (pE-pD),scale);
	   
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W14 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W14 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M16 = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil    
		 -----
		 mutE = round(pE-0.3819 * (pE-pD),scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W15 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W15 +++                                           |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> W16 = 1.618 * (pC-pD)+pD               |
	   --| Точка "мутации" => M13 = E - 0.5 * (pE-pD)                 |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = round(1.618 * (pC-pD)+pD,scale);
		         
		 -----
		 mutE = round(pE-0.5 * (pE-pD),scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
	   end
	   if pattern == NamePattern.W16 then
	   --+------------------------------------------------------------+
	   --| ПАТТЕРН: W16 +                                             |
	   --| Вычисление точек прогноза:                                 |
	   --| Точка "эволюции"=> НЕТ = 0                                 |
	   --| Точка "мутации" => M16 = E - 0.3819 * (pE-pD)              |
	   --+------------------------------------------------------------+
		 ----- level_0:
		 evE = nil        
		 -----
		 mutE = round(pE-0.3819 * (pE-pD),scale);
		 
		 ----- level_1:
		 --CalcPrognozLevel1();
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

function comma_value(amount)
    local formatted = amount
    while true do  
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
      if (k==0) then
        break
      end
    end
    return formatted
end

function format_num(amount, decimal, prefix, neg_prefix)
    local str_amount,  formatted, famount, remain
  
    decimal = decimal or scale  -- default sec scale decimal places
    neg_prefix = neg_prefix or "-" -- default negative sign
  
    famount = math.abs(round(amount,decimal))
    famount = math.floor(famount)
  
    remain = round(math.abs(amount) - famount, decimal)
  
          -- comma to separate the thousands
    formatted = comma_value(famount)
  
          -- attach the decimal portion
    if (decimal > 0) then
      remain = string.sub(tostring(remain),3)
      formatted = formatted .. "." .. remain ..
                  string.rep("0", decimal - string.len(remain))
    end
  
          -- attach prefix string e.g '$' 
    formatted = (prefix or "") .. formatted 
  
          -- if value is negative then format accordingly
    if (amount<0) then
      if (neg_prefix=="()") then
        formatted = "("..formatted ..")"
      else
        formatted = neg_prefix .. formatted 
      end
    end
  
    return formatted
end
