ZZSettings = {
    Depth       = 0,
	deviation   = 0,
	Backstep    = 0,
    Size        = 0,
    periodATR   = 0,
    kATR        = 0
}

-- Алгоритм: проверка размера волн и корректировка по следующим от- |
-- ношениям "Идеальных пропорций" ("Золотое сечение" версия 1):     |
-- (в терминах XABCD точки равны: A = X, B = A, C = B, D = B, E = D)|
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


function initZZ()

    calcAlgoValue = nil     --      Возвращаемая таблица
    calcChartResults = nil     --      Возвращаемая таблица
    ATR=nil
    calcATR = true

    ZZLevels={}

    cache_ST={} -- тренд
	H_index={} -- индексы максимумов
	L_index={} -- индексы минимумов
	HiBuffer={} -- знечени¤ максимов предшествующего движени¤
	LowBuffer={} -- знечени¤ минимумов предшествующего движени¤
	UpThrust={} -- значени¤ количества свечей смены движени¤
	breakBars={} -- значени¤ экстремума свечей пробити¤ уровн¤
	breakIndex={} -- индексы свечей пробити¤ уровн¤
    Ranges={} -- знечени¤ предшествующих движений дл¤ предсказани¤

	CC={} -- значени¤ закрыти¤ свечей
	CH={} -- значени¤ максимумов
	CL={} -- значени¤ минимумов
	HighMapBuffer={} -- знечени¤ максимов предшествующего движени¤
	LowMapBuffer={} -- знечени¤ минимумов предшествующего движени¤
	Peak={}
    lastlow = 0
    lasthigh = 0
    last_peak = 0
    lastindex = -1
    peak_count = 0

    pattern = NamePattern.NOPATTERN
    IsPointNotReal = false
    oldPattern = pattern
    patternName = 'NOPATTERN'

    targetE = 0 -- точка Е
    evE = 0 -- точка эволюции
    mutE = 0 -- точка мутации

end

function iterateZZ(iSec, cell)

    deltaShift = 0
    calcProfile = nil
    calcReg = nil

    iterateSLTP  = true
    fixedstop    = false

    local param1Min = 1
    local param1Max = 10
    local param1Step = 1

    local param2Min = 12
    local param2Max = 12
    local param2Step = 1

    local param3Min = 0
    local param3Max = 7
    local param3Step = 1

    local param4Min   = 10
    local param4Max   = 24
    local param4Step  = 2

    local param5Min   = 0.35
    local param5Max   = 0.95
    local param5Step  = 0.05

    if fixedstop then
        param4Min   = 10
        param4Max   = 10
        param4Step  = 1

        param5Min   = 0.6
        param5Max   = 0.6
        param5Step  = 0.05
    end

    local settingsTable = {}
    local allCount = 0

    for param1 = param1Min, param1Max, param1Step do

        for param2 = param2Min, param2Max, param2Step do

            for param3 = param3Min, param3Max, param3Step do

                for param4 = param4Min, param4Max, param4Step do

                    for param5 = param5Min, param5Max, param5Step do

                        allCount = allCount + 1

                        settingsTable[allCount] = {
                            Depth        = param1,
                            deviation    = param2,
                            Backstep     = param3,
                            Size         = Size,
                            periodATR    = param4,
                            kATR         = param5,
                        }

                    end
                end

            end
        end
    end

    myLog('settingsTable size '..tostring(#settingsTable))
    iterateAlgorithm(iSec, cell, settingsTable)

end

function _cached_ZZ(index, settings, DS)

    local indexToCalc = 1000
    indexToCalc = settings.Size or indexToCalc
    local beginIndexToCalc = settings.beginIndexToCalc or math.max(1, settings.beginIndex - indexToCalc)
    local endIndexToCalc = settings.endIndex or DS:Size()

    if index == nil then index = 1 end

	local deviation = settings.Depth or 27
	local gapDeviation = settings.gapDeviation or 70
	local WaitBars = settings.WaitBars or 2

    local periodATR = settings.periodATR or 10
    kATR = settings.kATR or 0.65

	local currentRange = 0

    if index == beginIndexToCalc or index == 1 then

        calcAlgoValue = {}
        calcAlgoValue[index]= 0
        calcChartResults = {}
        calcChartResults[index]= nil
        trend = {}
        trend[index] = 1
        ATR = {}
        ATR[index] = 0

		CH={}
		CL={}
		cache_ST={}
		CC={}
		UpThrust={}
		breakBars={}
		breakIndex={}

		HiBuffer={}
		LowBuffer={}
		H_index={}
		L_index={}
		ZZLevels={}
		Peak = {}
		RegisterPeak(index, DS:L(index), Peak, 0, ZZLevels)

		Ranges={}
		CC[index]=DS:C(index)
		CH[index]=0
		CL[index]=0
		cache_ST[index]=1

		UpThrust[index]=0
		breakBars[index]=0
		breakIndex[index]=0

		HiBuffer[index]=0
		LowBuffer[index]=0

		H_index[index]=index
		L_index[index]=index

		return
	end

    calcAlgoValue[index] = calcAlgoValue[index-1]
    --calcChartResults[index] = calcChartResults[index-1]
    trend[index] = trend[index-1]
    ATR[index] = ATR[index-1]

    if index<(beginIndexToCalc + periodATR) then
        ATR[index] = 0
    elseif index==(beginIndexToCalc + periodATR) then
        local sum=0
        for i = 1, periodATR do
            sum = sum + dValue(i)
        end
        ATR[index]=sum / periodATR
    elseif index>(beginIndexToCalc + periodATR) then
        ATR[index]=(ATR[index-1] * (periodATR-1) + dValue(index)) / periodATR
    end

	CC[index]=CC[index-1]

	if CH[index] == nil then
		CH[index]=CH[index-1]
	end
	if CL[index] == nil then
		CL[index]=CL[index-1]
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

	if DS:C(index) == nil then
		return calcAlgoValue, nil, calcChartResults
	end

	local isBreak=0
	CC[index]=DS:C(index)

	---------------------------------------------------------------------------------------
	----------------------------------------------------------------------

		-- расчет
		currentRange = math.abs(CH[index] - CL[index])

		if cache_ST[index]==1 then --растущий тренд

			if CH[index] <= DS:H(index) then -- новый максимум

				CH[index]=DS:H(index)
				H_index[index]=index
				ReplaceLastPeak(index, CH[index], Peak, 0, ZZLevels)

				if CL[index] == 0 then -- для первой расчетной свечи
					CL[index] = DS:L(index)
					L_index[index] = index
					LowBuffer[index] = DS:L(index)
				end

				if breakBars[index] ~= 0 then
					breakBars[index] = 0
					breakIndex[index] = 0
					UpThrust[index] = 0
				end

			elseif (currentRange*deviation/100) < math.abs(CC[index] - CH[index]) then --прошли больше чем отклонение от движения

				if UpThrust[index] == 0 then
					UpThrust[index] = index
				end

				if breakBars[index] == 0 or (breakBars[index] ~= 0 and breakBars[index] >= DS:L(index)) then
					breakBars[index] = DS:L(index)
					breakIndex[index] = index
				end

				if ((index - UpThrust[index]) > WaitBars and UpThrust[index] ~= 0) or (currentRange*gapDeviation/100) < math.abs(CC[index] - CH[index]) then -- ждем закрепления пробоя

					--меняем тренд

					cache_ST[index]=0

					local extr, extrIndex = findExtremum(index, H_index[index], 0, DS)
					CL[index] = extr
					L_index[index] = extrIndex

					RegisterPeak(L_index[index], CL[index], Peak, 0, ZZLevels)

					UpThrust[index] = 0
					breakBars[index] = 0
					breakIndex[index] = 0
					isBreak = 1

					HiBuffer[index] = CH[index]

				end

			elseif breakBars[index] ~= 0 and breakBars[index] >= DS:L(index) then
				breakBars[index] = DS:L(index)
				breakIndex[index] = index
			end


		elseif cache_ST[index]==0 then --падающий тренд

			if CL[index] >= DS:L(index) then -- новый минимум

				CL[index]=DS:L(index)
				L_index[index]=index
				ReplaceLastPeak(index, CL[index], Peak, 0, ZZLevels)

				if breakBars[index] ~= 0 then
					--WriteLog ("fake break");
					breakBars[index] = 0
					breakIndex[index] = 0
					UpThrust[index] = 0
				end

			elseif (currentRange*deviation/100) < math.abs(CC[index] - CL[index]) then --прошли больше чем отклонение от движения

				if UpThrust[index] == 0 then
					UpThrust[index] = index
				end

				if breakBars[index] == 0 or (breakBars[index] ~= 0 and breakBars[index] <= DS:H(index)) then
					breakBars[index] = DS:H(index)
					breakIndex[index] = index
				end

				if ((index - UpThrust[index]) > WaitBars and UpThrust[index] ~= 0) or (currentRange*gapDeviation/100) < math.abs(CC[index] - CH[index]) then -- ждем закрепления пробоя
				--меняем тренд

					cache_ST[index]=1

					local extr, extrIndex = findExtremum(index, L_index[index], 1, DS)
					CH[index] = extr
					H_index[index] = extrIndex

                   	RegisterPeak(H_index[index], CH[index], Peak, 0, ZZLevels)

					breakBars[index] = 0
					breakIndex[index] = 0
					UpThrust[index] = 0
					isBreak = 1

					LowBuffer[index] = CL[index]
				end

			elseif breakBars[index] ~= 0 and breakBars[index] <= DS:H(index) then
				breakBars[index] = DS:H(index)
				breakIndex[index] = index
			end

		end

	sizeOfZZLevels = #ZZLevels
	--myLog('-------------------')
	--myLog('index: '..tostring(index)..' - '..toYYYYMMDDHHMMSS(DS:T(index))..', C: '..tostring(DS:C(index))..', sizeOfZZLevels: '..tostring(sizeOfZZLevels)..', calcChartResults: '..tostring(calcChartResults[index]))
	--
	--for i=sizeOfZZLevels,sizeOfZZLevels-4,-1 do
	--	if ZZLevels[i]~=nil then
	--		myLog("T("..ZZLevels[i]["index"].."); "..toYYYYMMDDHHMMSS(DS:T(ZZLevels[i]["index"])).." "..tostring(ZZLevels[i]["val"]))
	--	end
	--end
	--
	--if index == endIndexToCalc then
	--	myLog('-------------------')
	--	myLog('index: '..tostring(index)..' - '..toYYYYMMDDHHMMSS(DS:T(index))..', C: '..tostring(DS:C(index))..', sizeOfZZLevels: '..tostring(sizeOfZZLevels))
	--
	--	for i=sizeOfZZLevels,1,-1 do
	--		if ZZLevels[i]~=nil then
	--			myLog("T("..ZZLevels[i]["index"].."); "..toYYYYMMDDHHMMSS(DS:T(ZZLevels[i]["index"])).." "..tostring(ZZLevels[i]["val"]))
	--		end
	--	end
	--end

	if sizeOfZZLevels>6 then

		local corr	= 0
		local pA  	= ZZLevels[sizeOfZZLevels-4-corr]["val"]
		local pB  	= ZZLevels[sizeOfZZLevels-3-corr]["val"]
		local pC  	= ZZLevels[sizeOfZZLevels-2-corr]["val"]
		local pD  	= ZZLevels[sizeOfZZLevels-1-corr]["val"]
		local pE  	= ZZLevels[sizeOfZZLevels-0-corr]["val"]

		local AB    = round(math.abs(pA-pB), SCALE)
		local BC    = round(math.abs(pB-pC), SCALE)
		local CD    = round(math.abs(pC-pD), SCALE)
		local AD    = round(math.abs(pA-pD), SCALE)
		local DE 	= round(math.abs(pD-pE), SCALE)

		-- Prediction
		targetE = 0
		evE = nil
		mutE = nil

		local pA_1  = ZZLevels[sizeOfZZLevels-4]["val"]
		local pB_1  = ZZLevels[sizeOfZZLevels-3]["val"]
		local pC_1  = ZZLevels[sizeOfZZLevels-2]["val"]
		local pD_1  = ZZLevels[sizeOfZZLevels-1]["val"]
		local pE_1  = ZZLevels[sizeOfZZLevels-0]["val"]
		getPattern(pA_1, pB_1, pC_1, pD_1, pE_1)
		if targetE ~= 0 then
			CalcPrognozPoint(pA_1, pB_1, pC_1, pD_1,targetE)
			if targetE == pE_1 then targetE = 0 end
		end

		targetE = round(targetE or 0, SCALE)
		evE     = round(evE or 0, SCALE)
		mutE    = round(mutE or 0, SCALE)
		--targetE = evE
		--myLog('targetE: '..tostring(targetE)..', evE: '..tostring(evE)..', mutE: '..tostring(mutE))

		--local isBuy  = trend[index] <= 0 and (targetE~=0 and evE~=0) and (targetE ~= 0 and targetE or evE) > pE
		--local isSell = trend[index] >= 0 and (targetE~=0 and evE~=0) and (targetE ~= 0 and targetE or evE) < pE
		--local isBuy  = trend[index] <= 0 and pE>pB
		--local isSell = trend[index] >= 0 and pE<pB
		--local isBuy  = trend[index] <= 0 and ((pE<pD and pE>pC and pD>pC) or (pE>pD and pE>pC)) and DS:C(index) > pC --and DS:C(index) > pE
		--local isSell = trend[index] >= 0 and ((pE>pD and pE<pC and pD<pC) or (pE<pD and pE<pC)) and DS:C(index) < pC --and DS:C(index) < pE
		--local isBuy  = trend[index] <= 0 and (((pE<pD and pE>pC and pD>pC) or (pE>pD and pE>pC)) and DS:C(index) > pC) --or (pB>pA and pE<pD and pE>pC and pD>pC and DS:C(index) > pA) or (pE>pD and pD<pC and pC>pB and pA>pB and DS:C(index) > pA)
		--local isSell = trend[index] >= 0 and (((pE>pD and pE<pC and pD<pC) or (pE<pD and pE<pC)) and DS:C(index) < pC) --or (pB<pA and pE>pD and pE<pC and pD<pC and DS:C(index) < pA) or (pE<pD and pD>pC and pC<pB and pA<pB and DS:C(index) < pA)
		local isBuy  = trend[index] <= 0 and (((pE<pD and pE>pC and pD>pC and pE < pD-CD*1/2) or (pE>pD and pE>pC)) and DS:C(index) > pC)
										  or (targetE~=0 and evE~=0 and targetE > pE and evE > pE and targetE > pD+CD*1/2 and evE > pD+CD*1/2)
										  --or (DS:C(index) > pC and DS:C(index) > pB)
		local isSell = trend[index] >= 0 and (((pE>pD and pE<pC and pD<pC and pE > pD+CD*1/2) or (pE<pD and pE<pC)) and DS:C(index) < pC)
										  or (targetE~=0 and evE~=0 and targetE < pE and evE < pE and targetE < pD-CD*1/2 and evE < pD-CD*1/2)
										  --or (DS:C(index) < pC and DS:C(index) < pB)
		--local isBuy  = trend[index] <= 0 and (pE>pD and pE>pC) and DS:C(index) > pC --and DS:C(index) > pE
		--local isSell = trend[index] >= 0 and (pE<pD and pE<pC) and DS:C(index) < pC --and DS:C(index) < pE
		--local isBuy  = trend[index] <= 0 and (pB>pA and pE<pD and pE>pC and pD>pC and DS:C(index) > pA) or (pE>pD and pD<pC and pC>pB and pA>pB and DS:C(index) > pA) --and DS:C(index) > pE
		--local isSell = trend[index] >= 0 and (pB<pA and pE>pD and pE<pC and pD<pC and DS:C(index) < pA) or (pE<pD and pD>pC and pC<pB and pA<pB and DS:C(index) < pA) --and DS:C(index) < pE
		--local isBuy  = trend[index] <= 0 and (pE>pD and pD<pC and pC>pB and pA>pB and DS:C(index) > pA)
		--local isSell = trend[index] >= 0 and (pE<pD and pD>pC and pC<pB and pA<pB and DS:C(index) < pA)

		if isBuy then
			trend[index] = 1
		end
		if isSell then
			trend[index] = -1
		end

		--myLog("trend "..tostring(trend[index])..", pA "..tostring(pA)..", pB "..tostring(pB)..", pC "..tostring(pC)..", pD "..tostring(pD)..", pE "..tostring(pE))
		--calcChartResults[index] = nil
		calcAlgoValue[index] = DS:C(index)
	end

	return calcAlgoValue, trend, calcChartResults

end

function cached_ZZ(index, settings)

    local indexToCalc = 1000
    indexToCalc = settings.Size or indexToCalc
    local beginIndexToCalc = settings.beginIndexToCalc or math.max(1, settings.beginIndex - indexToCalc)
    local endIndexToCalc = settings.endIndex or DS:Size()

    if index == nil then index = 1 end

	local deviation = settings.Depth or 27
	local gapDeviation = settings.gapDeviation or 70
	local WaitBars = settings.Backstep or 2

    local periodATR = settings.periodATR or 10
    kATR = settings.kATR or 0.65

	local currentRange = 0

    if index == beginIndexToCalc or index == 1 then

        calcAlgoValue = {}
        calcAlgoValue[index]= 0
        calcChartResults = {}
        calcChartResults[index]= nil
        trend = {}
        trend[index] = 1
        ATR = {}
        ATR[index] = 0

		CH={}
		CL={}
		cache_ST={}
		CC={}
		UpThrust={}
		breakBars={}
		breakIndex={}

		HiBuffer={}
		LowBuffer={}
		H_index={}
		L_index={}
		ZZLevels={}
        calculated_buffer = {}

		Ranges={}
		CC[index]=DS:C(index)
		CH[index]=0
		CL[index]=0
		cache_ST[index]=1

		UpThrust[index]=0
		breakBars[index]=0
		breakIndex[index]=0

		HiBuffer[index]=0
		LowBuffer[index]=0

		H_index[index]=index
		L_index[index]=index

		return
	end

    calcAlgoValue[index] = calcAlgoValue[index-1]
    --calcChartResults[index] = calcChartResults[index-1]
    trend[index] = trend[index-1]
    ATR[index] = ATR[index-1]

    if index<(beginIndexToCalc + periodATR) then
        ATR[index] = 0
    elseif index==(beginIndexToCalc + periodATR) then
        local sum=0
        for i = 1, periodATR do
            sum = sum + dValue(i)
        end
        ATR[index]=sum / periodATR
    elseif index>(beginIndexToCalc + periodATR) then
        ATR[index]=(ATR[index-1] * (periodATR-1) + dValue(index)) / periodATR
    end

	CC[index]=CC[index-1]

	if CH[index] == nil then
		CH[index]=CH[index-1]
	end
	if CL[index] == nil then
		CL[index]=CL[index-1]
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

	if DS:C(index) == nil then
		return calcAlgoValue, nil, calcChartResults
	end

	local isBreak=0
	CC[index]=DS:C(index)

	---------------------------------------------------------------------------------------
	----------------------------------------------------------------------

	-- ??????
	currentRange = math.abs(CH[index] - CL[index])

	if cache_ST[index]==1 then --???????? ?????

		if CH[index] <= DS:H(index) then -- ????? ????????

			CH[index]=DS:H(index)
			H_index[index]=index

			if CL[index] == 0 then -- ??В¤ ?????? ????????? ?????
				CL[index] = DS:L(index)
				L_index[index] = index
				LowBuffer[index] = DS:L(index)
			end

			if breakBars[index] ~= 0 then
				--WriteLog ("fake break");
				breakBars[index] = 0
				breakIndex[index] = 0
				UpThrust[index] = 0
			end

		elseif (currentRange*deviation/100) < math.abs(CC[index] - CH[index]) then --?????? ?????? ??? ?????????? ?? ???????В¤
			if UpThrust[index] == 0 then
				UpThrust[index] = index
			end

			if breakBars[index] == 0 or (breakBars[index] ~= 0 and breakBars[index] >= DS:L(index)) then
				breakBars[index] = DS:L(index)
				breakIndex[index] = index
			end

			if ((index - UpThrust[index]) > WaitBars and UpThrust[index] ~= 0) or (currentRange*gapDeviation/100) < math.abs(CC[index] - CH[index]) then -- ???? ??????????В¤ ?????В¤

				--???В¤?? ?????

				cache_ST[index]=0

				if breakBars[index] < DS:L(index) then
					CL[index] = breakBars[index]
					L_index[index] = breakIndex[index]
				else
					CL[index] = DS:L(index)
					L_index[index] = index
				end

				RegisterPeak(H_index[index], CH[index], Peak, 0, ZZLevels)
				UpThrust[index] = 0
				breakBars[index] = 0
				breakIndex[index] = 0
				isBreak = 1

				HiBuffer[index] = CH[index]

			end

		elseif breakBars[index] ~= 0 and breakBars[index] >= DS:L(index) then
			breakBars[index] = DS:L(index)
			breakIndex[index] = index
		end


	elseif cache_ST[index]==0 then --???????? ?????

		if CL[index] >= DS:L(index) then -- ????? ???????

			CL[index]=DS:L(index)
			L_index[index]=index

			if breakBars[index] ~= 0 then
				breakBars[index] = 0
				breakIndex[index] = 0
				UpThrust[index] = 0
			end

		elseif (currentRange*deviation/100) < math.abs(CC[index] - CL[index]) then --?????? ?????? ??? ?????????? ?? ???????В¤

			if UpThrust[index] == 0 then
				UpThrust[index] = index
			end

			if breakBars[index] == 0 or (breakBars[index] ~= 0 and breakBars[index] <= DS:H(index)) then
				breakBars[index] = DS:H(index)
				breakIndex[index] = index
			end

			if ((index - UpThrust[index]) > WaitBars and UpThrust[index] ~= 0) or (currentRange*gapDeviation/100) < math.abs(CC[index] - CH[index]) then -- ???? ??????????В¤ ?????В¤
			--???В¤?? ?????

				cache_ST[index]=1
				if breakBars[index] > DS:L(index) then
					CH[index] = breakBars[index]
					H_index[index] = breakIndex[index]
				else
					CH[index] = DS:H(index)
					H_index[index] = index
				end
                RegisterPeak(L_index[index], CL[index], Peak, 0, ZZLevels)

				breakBars[index] = 0
				breakIndex[index] = 0
				UpThrust[index] = 0
				isBreak = 1

				LowBuffer[index] = CL[index]
			end

		elseif breakBars[index] ~= 0 and breakBars[index] <= DS:H(index) then
			breakBars[index] = DS:H(index)
			breakIndex[index] = index
		end

	end

	sizeOfZZLevels = #ZZLevels
	--myLog('-------------------')
	--myLog('index: '..tostring(index)..' - '..toYYYYMMDDHHMMSS(DS:T(index))..', C: '..tostring(DS:C(index))..', sizeOfZZLevels: '..tostring(sizeOfZZLevels))

	--for i=sizeOfZZLevels,sizeOfZZLevels-4,-1 do
	--	if ZZLevels[i]~=nil then
	--		myLog("T("..ZZLevels[i]["index"].."); "..toYYYYMMDDHHMMSS(DS:T(ZZLevels[i]["index"])).." "..tostring(ZZLevels[i]["val"]))
	--	end
	--end

	if sizeOfZZLevels>5 then

		--[[
		local corr	= 1
		local pA  	= ZZLevels[sizeOfZZLevels-4-corr]["val"]
		local pB  	= ZZLevels[sizeOfZZLevels-3-corr]["val"]
		local pC  	= ZZLevels[sizeOfZZLevels-2-corr]["val"]
		local pD  	= ZZLevels[sizeOfZZLevels-1-corr]["val"]
		local pE  	= ZZLevels[sizeOfZZLevels-0-corr]["val"]
		local pEE  	= ZZLevels[sizeOfZZLevels]["val"]
		--local pE  	= cache_ST[index]==1 and CH[index] or CL[index]

		local AB    = round(math.abs(pA-pB), SCALE)
		local BC    = round(math.abs(pB-pC), SCALE)
		local CD    = round(math.abs(pC-pD), SCALE)
		local AD    = round(math.abs(pA-pD), SCALE)
		local DE 	= round(math.abs(pD-pE), SCALE)
		local EE 	= round(math.abs(pEE-pE), SCALE)

		 --Prediction
		targetE = 0
		evE = nil
		mutE = nil

		local pA_1  = ZZLevels[sizeOfZZLevels-4]["val"]
		local pB_1  = ZZLevels[sizeOfZZLevels-3]["val"]
		local pC_1  = ZZLevels[sizeOfZZLevels-2]["val"]
		local pD_1  = ZZLevels[sizeOfZZLevels-1]["val"]
		local pE_1  = ZZLevels[sizeOfZZLevels-0]["val"]
		--local pE_1  = cache_ST[index]==1 and CH[index] or CL[index]

		getPattern(pA_1, pB_1, pC_1, pD_1, pE_1)
		--getPattern(pA, pB, pC, pD, pE)
		if targetE ~= 0 then
			CalcPrognozPoint(pA_1, pB_1, pC_1, pD_1,targetE)
			--CalcPrognozPoint(pA, pB, pC, pD,targetE)
			if targetE == pE_1 then targetE = 0 end
			--if targetE == pE then targetE = 0 end
		end

		targetE = round(targetE or 0, SCALE)
		evE     = round(evE or 0, SCALE)
		mutE    = round(mutE or 0, SCALE)
		targetE = evE
		myLog('targetE: '..tostring(targetE)..', evE: '..tostring(evE)..', mutE: '..tostring(mutE))
		]]
		--local isBuy  = trend[index] <= 0 and (targetE~=0 and evE~=0) and (targetE ~= 0 and targetE or evE) > pE
		--local isSell = trend[index] >= 0 and (targetE~=0 and evE~=0) and (targetE ~= 0 and targetE or evE) < pE
		local isBuy  = trend[index] <= 0 and cache_ST[index] == 1
		local isSell = trend[index] >= 0 and cache_ST[index] == 0
		--local isBuy  = trend[index] <= 0 and ((pE<pD and pE>pC and pD>pC) or (pE>pD and pE>pC)) and DS:C(index) > pC --and DS:C(index) > pE
		--local isSell = trend[index] >= 0 and ((pE>pD and pE<pC and pD<pC) or (pE<pD and pE<pC)) and DS:C(index) < pC --and DS:C(index) < pE
		--local isBuy  = trend[index] <= 0 and (((pE<pD and pE>pC and pD>pC) or (pE>pD and pE>pC)) and DS:C(index) > pC) --or (pB>pA and pE<pD and pE>pC and pD>pC and DS:C(index) > pA) or (pE>pD and pD<pC and pC>pB and pA>pB and DS:C(index) > pA)
		--local isSell = trend[index] >= 0 and (((pE>pD and pE<pC and pD<pC) or (pE<pD and pE<pC)) and DS:C(index) < pC) --or (pB<pA and pE>pD and pE<pC and pD<pC and DS:C(index) < pA) or (pE<pD and pD>pC and pC<pB and pA<pB and DS:C(index) < pA)
		--local isBuy  = trend[index] <= 0 and ((((pE<pD and pE>pC and pD>pC and pE < pD-CD*1/2 and pEE>pD) or (pE>pD and pE>pC)) and DS:C(index) > pC)
		--								  or (targetE~=0 and evE~=0 and targetE > pE and evE > pE and targetE > pD+CD*1/2 and evE > pD+CD*1/2)
		--								)
		--								  --and DS:C(index-3)<DS:C(index-1) and DS:C(index-2)<DS:C(index) and DS:C(index-1)<DS:C(index)
		--									--or (DS:C(index) > pC and DS:C(index) > pB)
		--local isSell = trend[index] >= 0 and ((((pE>pD and pE<pC and pD<pC and pE > pD+CD*1/2 and pEE<pD) or (pE<pD and pE<pC)) and DS:C(index) < pC)
		--								  or (targetE~=0 and evE~=0 and targetE < pE and evE < pE and targetE < pD-CD*1/2 and evE < pD-CD*1/2)
		--								)
										  --and DS:C(index-3)>DS:C(index-1) and DS:C(index-2)>DS:C(index) and DS:C(index-1)>DS:C(index)
										  --or (DS:C(index) < pC and DS:C(index) < pB)
		--local isBuy  = trend[index] <= 0 and (pE>pD and pE>pC) and DS:C(index) > pC --and DS:C(index) > pE
		--local isSell = trend[index] >= 0 and (pE<pD and pE<pC) and DS:C(index) < pC --and DS:C(index) < pE
		--local isBuy  = trend[index] <= 0 and (pB>pA and pE<pD and pE>pC and pD>pC and DS:C(index) > pA) or (pE>pD and pD<pC and pC>pB and pA>pB and DS:C(index) > pA) --and DS:C(index) > pE
		--local isSell = trend[index] >= 0 and (pB<pA and pE>pD and pE<pC and pD<pC and DS:C(index) < pA) or (pE<pD and pD>pC and pC<pB and pA<pB and DS:C(index) < pA) --and DS:C(index) < pE
		--local isBuy  = trend[index] <= 0 and (pE>pD and pD<pC and pC>pB and pA>pB and DS:C(index) > pA)
		--local isSell = trend[index] >= 0 and (pE<pD and pD>pC and pC<pB and pA<pB and DS:C(index) < pA)

		if isBuy then
			trend[index] = 1
		end
		if isSell then
			trend[index] = -1
		end

		--myLog("trend "..tostring(trend[index])..", pA "..tostring(pA)..", pB "..tostring(pB)..", pC "..tostring(pC)..", pD "..tostring(pD)..", pE "..tostring(pE))
		--calcChartResults[index] = nil
		calcAlgoValue[index] = DS:C(index)
	end

	return calcAlgoValue, trend, calcChartResults

end

function classicZZ(index, settings, DS)

    local indexToCalc = 1000
    indexToCalc = settings.Size or indexToCalc
    local beginIndexToCalc = settings.beginIndexToCalc or math.max(1, settings.beginIndex - indexToCalc)
    local endIndexToCalc = settings.endIndex or DS:Size()

    if index == nil then index = 1 end

    local Depth = settings.Depth or 12
	local deviation = settings.deviation or 5
	local Backstep = settings.Backstep or 3

    local periodATR = settings.periodATR or 10
    kATR = settings.kATR or 0.65

    local searchBoth = 0;
    local searchPeak = 1;
    local searchLawn = -1;

    if index == beginIndexToCalc or index == 1 then

        myLog("--------------------------------------------------")
        myLog("Показатель Depth "..tostring(Depth))
        myLog("Показатель deviation "..tostring(deviation))
        myLog("Показатель Backstep "..tostring(Backstep))
        myLog("Показатель periodATR "..tostring(periodATR))
        myLog("Показатель kATR "..tostring(kATR))
        myLog("--------------------------------------------------")

		calcAlgoValue = {}
        calcAlgoValue[index]= 0
        calcChartResults = {}
        calcChartResults[index]= nil
        trend = {}
        trend[index] = 1
        ATR = {}
        ATR[index] = 0

        CC={}
		CH={}
		CL={}
		Peak={}

		HighMapBuffer={}
		LowMapBuffer={}
		ZZLevels={}
		------------------
		CC[index]=0
		CH[index]=0
		CL[index]=0

		Peak[index]=nil

		HighMapBuffer[index]=0
		LowMapBuffer[index]=0

        lastindex = -1;
        lastlow = 0;
        lasthigh = 0;
        last_peak = 0;
        peak_count = 0;

        return calcAlgoValue, nil, calcChartResults
	end

    calcAlgoValue[index] = calcAlgoValue[index-1]
    --calcChartResults[index] = calcChartResults[index-1]
    trend[index] = trend[index-1]
    ATR[index] = ATR[index-1]

    if index<(beginIndexToCalc + periodATR) then
        ATR[index] = 0
    elseif index==(beginIndexToCalc + periodATR) then
        local sum=0
        for i = 1, periodATR do
            sum = sum + dValue(i)
        end
        ATR[index]=sum / periodATR
    elseif index>(beginIndexToCalc + periodATR) then
        ATR[index]=(ATR[index-1] * (periodATR-1) + dValue(index)) / periodATR
    end
    CC[index]=CC[index-1]
	CH[index]=CH[index-1]
    CL[index]=CL[index-1]

	if index < (beginIndexToCalc + Depth) or DS:C(index) == nil then
        HighMapBuffer[index]=HighMapBuffer[index-1]
        LowMapBuffer[index]=LowMapBuffer[index-1]
	    Peak[index]=nil
        return calcAlgoValue, nil, calcChartResults
    end

	--if index < endIndexToCalc then
    --    HighMapBuffer[index]=HighMapBuffer[index-1]
    --    LowMapBuffer[index]=LowMapBuffer[index-1]
	--    Peak[index]=nil
    --    return calcAlgoValue, nil, calcChartResults
	--end

    local sizeOfZZLevels = #ZZLevels
    local searchMode = searchBoth;

    if DS:C(index) ~= nil then

        CC[index]=DS:C(index)
        CH[index]=DS:H(index)
        CL[index]=DS:L(index)

        lastindex = index

        HighMapBuffer[index]=0
        LowMapBuffer[index]=0
		Peak[index]=nil

        local start;
        local last_peak;
        local last_peak_i;

        start = beginIndexToCalc + Depth;
        local past_peak = 3

        i = GetPeak(index, past_peak, Peak, ZZLevels);

        if i == -1 then
            last_peak_i = 0;
            last_peak = 0;
        else
            last_peak_i = i;
            last_peak = Peak[i];
            start = i;
        end

        for i = start, index, 1 do
            Peak[i]=nil;
            LowMapBuffer[i]=0.0;
            HighMapBuffer[i]=0.0;
        end

        searchMode = searchBoth;
        if LowMapBuffer[start]~=0 then
            searchMode = searchPeak
        elseif HighMapBuffer[start]~=0 then
            searchMode = searchLawn
        end

        --myLog('index: '..tostring(index)..', start: '..tostring(start)..', begin: '..tostring(beginIndexToCalc + Depth))
		lastlow = -1
		lasthigh = -1

        for i = start, index-1, 1 do

            -- fill high/low maps
            local range = i - Depth + 1;
            local val;

            -- get the lowest low for the last depth is
            val = math.min(unpack(CL, range, i));
            if val == lastlow then
                -- if lowest low is not changed - ignore it
                val = nil;
            else
                -- keep it
                lastlow = val;
                -- if current low is higher for more than Deviation pips, ignore
                if (CL[i] - val) > (SEC_PRICE_STEP * deviation) then
                    val = nil;
                else
                    -- check for the previous backstep lows
                    for k = i - 1, i - Backstep + 1, -1 do
						if HighMapBuffer[k] ~= 0 then
							break
						end
						if LowMapBuffer[k] and (LowMapBuffer[k] ~= 0) and (LowMapBuffer[k] > val) then
                            LowMapBuffer[k] = 0;
                        end
                    end
                end
            end
            if CL[i] == val then
                LowMapBuffer[i] = val;
            else
                LowMapBuffer[i] = 0;
            end

            -- get the highest high for the last depth is
            val = math.max(unpack(CH, range, i));
            if val == lasthigh then
                -- if lowest low is not changed - ignore it
                val = nil;
            else
                -- keep it
                lasthigh = val;
                -- if current low is higher for more than Deviation pips, ignore
                if (val - CH[i]) > (SEC_PRICE_STEP * deviation) then
                    val = nil;
                else
                    --myLog('index: '..tostring(index)..', val: '..tostring(val)..', lasthigh: '..tostring(lasthigh))
                    -- check for the previous backstep lows
                    for k = i - 1, i - Backstep + 1, -1 do
						if LowMapBuffer[k] ~= 0 then
							break
						end
						if HighMapBuffer[k] and (HighMapBuffer[k] ~= 0) and (HighMapBuffer[k] < val) then
                            HighMapBuffer[k] = 0;
                        end
                    end
                end
            end

            if CH[i] == val then
                HighMapBuffer[i] = val;
            else
                HighMapBuffer[i] = 0
            end

        end

        peak_count = 0
        if start ~= beginIndexToCalc + Depth then
            peak_count = -past_peak;
        end

        --myLog('index: '..tostring(index)..', sizeOfZZLevels: '..tostring(#ZZLevels)..', peak_count: '..tostring(peak_count))

        for i = start, index-1, 1 do

            sizeOfZZLevels = #ZZLevels

            if searchMode == searchBoth then
                if (HighMapBuffer[i] ~= 0) then
                    last_peak_i = i;
                    last_peak = CH[i]
                    searchMode = searchLawn;
                    LowMapBuffer[i] = 0
                    peak_count = RegisterPeak(i, last_peak, Peak, peak_count, ZZLevels);
                elseif (LowMapBuffer[i] ~= 0) then
                    last_peak_i = i;
                    last_peak = CL[i] --owBuffer[i];
                    searchMode = searchPeak;
                    peak_count = RegisterPeak(i, last_peak, Peak, peak_count, ZZLevels);
                end
            elseif searchMode == searchPeak then
				if (LowMapBuffer[i] ~= 0 and LowMapBuffer[i] < last_peak) then --and HighMapBuffer[i] == 0
                    Peak[last_peak_i] = nil
                    last_peak = LowMapBuffer[i];
                    last_peak_i = i;
                    ReplaceLastPeak(i, last_peak, Peak, peak_count, ZZLevels);
					HighMapBuffer[i] = 0
                end
                if HighMapBuffer[i] ~= 0 and LowMapBuffer[i] == 0 then
                    last_peak = HighMapBuffer[i];
                    last_peak_i = i;
                    searchMode = searchLawn;
                    peak_count = RegisterPeak(i, last_peak, Peak, peak_count, ZZLevels);
                end
            elseif searchMode == searchLawn then
				if (HighMapBuffer[i] ~= 0 and HighMapBuffer[i] > last_peak) then --and LowMapBuffer[i] == 0
                    Peak[last_peak_i] = nil
                    last_peak = HighMapBuffer[i];
                    last_peak_i = i;
                    ReplaceLastPeak(i, last_peak, Peak, peak_count, ZZLevels);
					LowMapBuffer[i] = 0
                end
                if LowMapBuffer[i] ~= 0 and HighMapBuffer[i] == 0 then
                    last_peak = LowMapBuffer[i];
                    last_peak_i = i;
                    searchMode = searchPeak;
                    peak_count = RegisterPeak(i, last_peak, Peak, peak_count, ZZLevels);
                end
            end
        end

		sizeOfZZLevels = #ZZLevels
		if index == endIndexToCalc then
        	--myLog('-------------------')
        	--myLog('index: '..tostring(index)..' - '..toYYYYMMDDHHMMSS(DS:T(index))..', C: '..tostring(DS:C(index))..', sizeOfZZLevels: '..tostring(sizeOfZZLevels))
			--
        	--for i=sizeOfZZLevels,1,-1 do
	    	--	if ZZLevels[i]~=nil then
	    	--		myLog("T("..ZZLevels[i]["index"].."); "..toYYYYMMDDHHMMSS(DS:T(ZZLevels[i]["index"])).." "..tostring(ZZLevels[i]["val"]))
	    	--	end
			--end
		end

        if sizeOfZZLevels>6 then

			local corr	= 0
			local pA  	= ZZLevels[sizeOfZZLevels-4-corr]["val"]
			local pB  	= ZZLevels[sizeOfZZLevels-3-corr]["val"]
			local pC  	= ZZLevels[sizeOfZZLevels-2-corr]["val"]
			local pD  	= ZZLevels[sizeOfZZLevels-1-corr]["val"]
			local pE  	= ZZLevels[sizeOfZZLevels-0-corr]["val"]

			local AB    = round(math.abs(pA-pB), SCALE)
			local BC    = round(math.abs(pB-pC), SCALE)
			local CD    = round(math.abs(pC-pD), SCALE)
			local AD    = round(math.abs(pA-pD), SCALE)
			local DE 	= round(math.abs(pD-pE), SCALE)

            -- Prediction
            targetE = 0
            evE = nil
            mutE = nil

            getPattern(pA, pB, pC, pD, pE)
            if targetE ~= 0 then
                CalcPrognozPoint(pA,pB,pC,pD,targetE)
                if targetE == pE then targetE = 0 end
            end

            targetE = round(targetE or 0, SCALE)
            evE     = round(evE or 0, SCALE)
			mutE    = round(mutE or 0, SCALE)
			--targetE = targetE == 0 and evE or targetE
            --myLog('targetE: '..tostring(targetE)..', evE: '..tostring(evE)..', mutE: '..tostring(mutE))

            --local isBuy  = trend[index] <= 0 and (targetE~=0 and evE~=0) and (targetE ~= 0 and targetE or evE) > pE
            --local isSell = trend[index] >= 0 and (targetE~=0 and evE~=0) and (targetE ~= 0 and targetE or evE) < pE
            --local isBuy  = trend[index] <= 0 and pE>pB
            --local isSell = trend[index] >= 0 and pE<pB
            --local isBuy  = trend[index] <= 0 and ((pE<pD and pE>pC and pD>pC) or (pE>pD and pE>pC)) and DS:C(index) > pC --and DS:C(index) > pE
            --local isSell = trend[index] >= 0 and ((pE>pD and pE<pC and pD<pC) or (pE<pD and pE<pC)) and DS:C(index) < pC --and DS:C(index) < pE
            --local isBuy  = trend[index] <= 0 and (((pE<pD and pE>pC and pD>pC) or (pE>pD and pE>pC)) and DS:C(index) > pC) --or (pB>pA and pE<pD and pE>pC and pD>pC and DS:C(index) > pA) or (pE>pD and pD<pC and pC>pB and pA>pB and DS:C(index) > pA)
            --local isSell = trend[index] >= 0 and (((pE>pD and pE<pC and pD<pC) or (pE<pD and pE<pC)) and DS:C(index) < pC) --or (pB<pA and pE>pD and pE<pC and pD<pC and DS:C(index) < pA) or (pE<pD and pD>pC and pC<pB and pA<pB and DS:C(index) < pA)
			local isBuy  = trend[index] <= 0 and ((((pE<pD and pE>pC and pD>pC and pE < pD-CD*1/2) or (pE>pD and pE>pC)) and DS:C(index) > pC)
						or (targetE~=0 and evE~=0 and targetE > pE and evE > pE and targetE > pD+CD*1/2 and evE > pD+CD*1/2)
					  )
						--and DS:C(index-3)<DS:C(index-1) and DS:C(index-2)<DS:C(index) and DS:C(index-1)<DS:C(index)
						  --or (DS:C(index) > pC and DS:C(index) > pB)
			local isSell = trend[index] >= 0 and ((((pE>pD and pE<pC and pD<pC and pE > pD+CD*1/2) or (pE<pD and pE<pC)) and DS:C(index) < pC)
						or (targetE~=0 and evE~=0 and targetE < pE and evE < pE and targetE < pD-CD*1/2 and evE < pD-CD*1/2)
					  )
						--and DS:C(index-3)>DS:C(index-1) and DS:C(index-2)>DS:C(index) and DS:C(index-1)>DS:C(index)
						--or (DS:C(index) < pC and DS:C(index) < pB)
			--local isBuy  = trend[index] <= 0 and (pE>pD and pE>pC) and DS:C(index) > pC --and DS:C(index) > pE
            --local isSell = trend[index] >= 0 and (pE<pD and pE<pC) and DS:C(index) < pC --and DS:C(index) < pE
            --local isBuy  = trend[index] <= 0 and (pB>pA and pE<pD and pE>pC and pD>pC and DS:C(index) > pA) or (pE>pD and pD<pC and pC>pB and pA>pB and DS:C(index) > pA) --and DS:C(index) > pE
            --local isSell = trend[index] >= 0 and (pB<pA and pE>pD and pE<pC and pD<pC and DS:C(index) < pA) or (pE<pD and pD>pC and pC<pB and pA<pB and DS:C(index) < pA) --and DS:C(index) < pE
            --local isBuy  = trend[index] <= 0 and (pE>pD and pD<pC and pC>pB and pA>pB and DS:C(index) > pA)
            --local isSell = trend[index] >= 0 and (pE<pD and pD>pC and pC<pB and pA<pB and DS:C(index) < pA)

            if isBuy then
                trend[index] = 1
            end
            if isSell then
                trend[index] = -1
            end

            --myLog('index: '..tostring(index)..' - '..toYYYYMMDDHHMMSS(DS:T(index))..", trend "..tostring(trend[index])..", pA "..tostring(pA)..", pB "..tostring(pB)..", pC "..tostring(pC)..", pD "..tostring(pD)..", pE "..tostring(pE))
            --calcChartResults[index] = nil
            calcAlgoValue[index] = DS:C(index)
        end

    end

    return calcAlgoValue, trend, calcChartResults

end

function RegisterPeak(index, val, Peak, peak_count, ZZLevels)

    peak_count = peak_count + 1;
    Peak[index] = val;

	local sizeOfZZLevels = #ZZLevels + 1
    if peak_count <= 0 and #ZZLevels > 0 then
		calcChartResults[ZZLevels[#ZZLevels+peak_count]["index"]] = nil
        ZZLevels[#ZZLevels+peak_count]["val"] = val
        ZZLevels[#ZZLevels+peak_count]["index"] = index
    else
        ZZLevels[sizeOfZZLevels] = {}
        ZZLevels[sizeOfZZLevels]["val"]   = val
        ZZLevels[sizeOfZZLevels]["index"] = index
    end
	calcChartResults[index] = val

    return peak_count

end

function ReplaceLastPeak(index, val, Peak, peak_count, ZZLevels)
    Peak[index] = val;

    local sizeOfZZLevels = #ZZLevels
    if peak_count <= 0 and #ZZLevels > 0 then
		calcChartResults[ZZLevels[sizeOfZZLevels+peak_count]["index"]] = nil
        ZZLevels[#ZZLevels+peak_count]["val"] = val
		ZZLevels[#ZZLevels+peak_count]["index"] = index
	else
		calcChartResults[ZZLevels[sizeOfZZLevels]["index"]] = nil
		ZZLevels[sizeOfZZLevels]["val"]   = val
		ZZLevels[sizeOfZZLevels]["index"] = index
	end
	calcChartResults[index] = val
end

function GetPeak(index, offset, Peak, ZZLevels)

    local counterZ = 0
    for i=index,1, -1 do
        if Peak[i]~=nil then
            counterZ = counterZ + 1
            if counterZ == offset then
                return i
            end
        end
    end

    return -1;

end

function findExtremum(index, indexFrom, trend, DS)

	local extr
	local extrIndex

	if trend == 1 then
		extr = DS:H(index)
	else
		extr = DS:L(index)
	end
	extrIndex = index

	for i=indexFrom+1,index-1 do

		if DS:C(i)~=nil then
			if trend == 1 and extr < DS:H(i) then
				extr = DS:H(i)
				extrIndex = i
			end

			if trend == 0 and extr > DS:L(i) then
				extr = DS:L(i)
				extrIndex = i
			end
		end

	end

	return extr, extrIndex

end

-- Prediction
function getPattern(pA, pB, pC, pD, pE)

	--- Первичный сброс флага
	IsPointNotReal = false;
	--- Сохраняем старый паттерн
	oldPattern = pattern;

	if (pB>pA and pA>pD and pD>pC and pC>pE)	then
		pattern = NamePattern.M1;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M1'
		return(pattern);
	end
	--- M2
	if (pB>pA and pA>pD and pD>pE and pE>pC) then
		pattern = NamePattern.M2;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M2'
		return(pattern);
	end
	--- M3
	if (pB>pD and pD>pA and pA>pC and pC>pE) then
		pattern = NamePattern.M3;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M3'
		return(pattern);
	end
	--- M4
	if (pB>pD and pD>pA and pA>pE and pE>pC) then
		pattern = NamePattern.M4;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M4'
		return(pattern);
	end
	--- M5
	if (pD>pB and pB>pA and pA>pC and pC>pE) then
		pattern = NamePattern.M5;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M5'
		return(pattern);
	end
	--- M6
	if (pD>pB and pB>pA and pA>pE and pE>pC) then
		pattern = NamePattern.M6;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M6'
		return(pattern);
	end
	--- M7
	if (pB>pD and pD>pC and pC>pA and pA>pE) then
		pattern = NamePattern.M7;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M7'
		return(pattern);
	end
	--- M8
	if (pB>pD and pD>pE and pE>pA and pA>pC) then
		pattern = NamePattern.M8;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M8'
		return(pattern);
	end
	--- M9
	if (pD>pB and pB>pC and pC>pA and pA>pE) then
		pattern = NamePattern.M9;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M9'
		return(pattern);
	end
	--- M10
	if (pD>pB and pB>pE and pE>pA and pA>pC) then
		pattern = NamePattern.M10;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M10'
		return(pattern);
	end
	--- M11
	if (pD>pE and pE>pB and pB>pA and pA>pC) then
		pattern = NamePattern.M11;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M11'
		return(pattern);
	end
	--- M12
	if (pB>pD and pD>pC and pC>pE and pE>pA) then
		pattern = NamePattern.M12;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M12'
		return(pattern);
	end
	--- M13
	if (pB>pD and pD>pE and pE>pC and pC>pA) then
		pattern = NamePattern.M13;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M13'
		return(pattern);
	end
	--- M14
	if (pD>pB and pB>pC and pC>pE and pE>pA) then
		pattern = NamePattern.M14;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M14'
		return(pattern);
	end
	--- M15
	if (pD>pB and pB>pE and pE>pC and pC>pA) then
		pattern = NamePattern.M15;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M15'
		return(pattern);
	end
	--- M16
	if (pD>pE and pE>pB and pB>pC and pC>pA) then
		pattern = NamePattern.M16;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M16'
		return(pattern);
	end
	--- W1
	if (pA>pC and pC>pB and pB>pE and pE>pD) then
		pattern = NamePattern.W1;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'M17'
		return(pattern);
	end
	--- W2
	if (pA>pC and pC>pE and pE>pB and pB>pD) then
		pattern = NamePattern.W2;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W2'
		return(pattern);
	end
	--- W3
	if (pA>pE and pE>pC and pC>pB and pB>pD) then
		pattern = NamePattern.W3;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W3'
		return(pattern);
	end
	--- W4
	if (pA>pC and pC>pE and pE>pD and pD>pB) then
		pattern = NamePattern.W4;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W4'
		return(pattern);
	end
	--- W5
	if (pA>pE and pE>pC and pC>pD and pD>pB) then
		pattern = NamePattern.W5;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W5'
		return(pattern);
	end
	--- W6
	if (pC>pA and pA>pB and pB>pE and pE>pD) then
		pattern = NamePattern.W6;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W6'
		return(pattern);
	end
	--- W7
	if (pC>pA and pA>pE and pE>pB and pB>pD) then
		pattern = NamePattern.W7;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W7'
		return(pattern);
	end
	--- W8
	if (pE>pA and pA>pC and pC>pB and pB>pD) then
		pattern = NamePattern.W8;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W8'
		return(pattern);
	end
	--- W9
	if (pC>pA and pA>pE and pE>pD and pD>pB) then
		pattern = NamePattern.W9;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W9'
		return(pattern);
	end
	--- W10
	if (pE>pA and pA>pC and pC>pD and pD>pB) then
		pattern = NamePattern.W10;
        patternName = 'W10'
		AnalysisPointE(pA,pB,pC,pD,pE);
		return(pattern);
	end
	--- W11
	if (pC>pE and pE>pA and pA>pB and pB>pD) then
		pattern = NamePattern.W11;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W11'
		return(pattern);
	end
	--- W12
	if (pE>pC and pC>pA and pA>pB and pB>pD) then
		pattern = NamePattern.W12;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W12'
		return(pattern);
	end
	--- W13
	if (pC>pE and pE>pA and pA>pD and pD>pB) then
		pattern = NamePattern.W13;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W13'
		return(pattern);
	end
	--- W14
	if (pE>pC and pC>pA and pA>pD and pD>pB) then
		pattern = NamePattern.W14;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W14'
		return(pattern);
	end
	--- W15
	if (pC>pE and pE>pD and pD>pA and pA>pB) then
		pattern = NamePattern.W15;
		AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W15'
		return(pattern);
	end
	--- W16
	if (pE>pC and pC>pD and pD>pA and pA>pB) then
		pattern = NamePattern.W16;
        AnalysisPointE(pA,pB,pC,pD,pE);
        patternName = 'W16'
		return(pattern);
	end

	--- NOPATTERN
    pattern = NamePattern.NOPATTERN;
    patternName = 'NOPATTERN'
	return(pattern);

end

function AnalysisPointE(pA,pB,pC,pD,pE)

	--- Контрольный сброс флага
	IsPointNotReal = false;
	--WriteLog ("Pattern "..tostring(pattern))

	 --- 1. Если паттерн определен то можно анализировать/корректировать значение E
	if ((pattern ~= NamePattern.NOPATTERN) and (pattern ~= NamePattern.ERROR))
	  then
	   if (pattern == NamePattern.M1)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.618)
			then
			 pE = round(pD - 1.618 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M2)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.5)
			then
			 pE = round(pD - 0.5 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M3)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.2720)
			then
			 pE = round(pD - 1.2720 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M4)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.618)
			then
			 pE = round(pD - 0.618 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M5)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.2720)
			then
			 pE = round(pD - 1.2720 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M6)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.618)
			then
			 pE = round(pD - 0.618 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M7)
		 then
		  if (((pD-pE)/(pD-pC)) < 3.0000)
			then
			 pE = round(pD - 3.0000 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M8)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.3819)
			then
			 pE = round(pD - 0.3819 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M9)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.618)
			then
			 pE = round(pD - 1.618 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M10)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.5)
			then
			 pE = round(pD - 0.5 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M11)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.25)
			then
			 pE = round(pD - 0.25 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M12)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.618)
			then
			 pE = round(pD - 1.618 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M13)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.5)
			then
			 pE = round(pD - 0.5 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M14)
		 then
		  if (((pD-pE)/(pD-pC)) < 1.2720)
			then
			 pE = round(pD - 1.2720 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M15)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.618)
			then
			 pE = round(pD - 0.618 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.M16)
		 then
		  if (((pD-pE)/(pD-pC)) < 0.3819)
			then
			 pE = round(pD - 0.3819 * (pD-pC),SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W1)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.3819)
			then
			 pE = round(0.3819 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W2)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.618)
			then
			 pE = round(0.618 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W3)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.2720)
			then
			 pE = round(1.2720 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W4)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.5)
			then
			 pE = round(0.5 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W5)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.618)
			then
			 pE = round(1.618 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W6)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.25)
			then
			 pE = round(0.25 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W7)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.5)
			then
			 pE = round(0.5 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W8)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.618)
			then
			 pE = round(1.618 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W9)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.3819)
			then
			 pE = round(0.3819 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W10)
		 then
		  if (((pE-pD)/(pC-pD)) < 3.0000)
			then
			 pE = round(3.0000 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W11)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.618)
			then
			 pE = round(0.618 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W12)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.2720)
			then
			 pE = round(1.2720 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W13)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.618)
			then
			 pE = round(0.618 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	  if (pattern == NamePattern.W14)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.2720)
			then
			 pE = round(1.2720 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W15)
		 then
		  if (((pE-pD)/(pC-pD)) < 0.5)
			then
			 pE = round(0.5 * (pC-pD)+pD,SCALE);
			 --- Была модификация
			 IsPointNotReal = true;
			end
		 end
	   if (pattern == NamePattern.W16)
		 then
		  if (((pE-pD)/(pC-pD)) < 1.618)
			then
			 pE = round(1.618 * (pC-pD)+pD,SCALE);
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
		 mutE = round(0.3819 * (pD-pE)+pE,SCALE);

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
		 evE = round(pD - 1.618 * (pD-pC),SCALE);

		 -----
		 mutE = round(0.5 * (pD-pE)+pE,SCALE);

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
		 mutE = round(0.3819 * (pD-pE)+pE,SCALE);

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
		 evE = round(pD - 1.272 * (pD-pC),SCALE);

		 -----
		 mutE = round(0.5 * (pD-pE)+pE,SCALE);

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
		 mutE = round(0.25 * (pD-pE)+pE,SCALE);

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
		 evE = round(pD - 1.272 * (pD-pC),SCALE);

		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,SCALE);

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
		 mutE = round(0.3819 * (pD-pE)+pE,SCALE);

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
		 evE = round(pD - 0.618 * (pD-pC),SCALE);

		 -----
		 mutE = round(0.5 * (pD-pE)+pE,SCALE);

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
		 mutE = round(0.25 * (pD-pE)+pE,SCALE);

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
		 evE = round(pD - 0.618 * (pD-pC),SCALE);

		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,SCALE);

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
		 evE = round(pD - 0.5 * (pD-pC),SCALE);

		 -----
		 mutE = round(0.5 * (pD-pE)+pE,SCALE);

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
		 evE = round(pD - 3.0000 * (pD-pC),SCALE);

		 -----
		 mutE = round(0.3819 * (pD-pE)+pE,SCALE);

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
		 evE = round(pD - 1.618 * (pD-pC),SCALE);

		 -----
		 mutE = round(0.5 * (pD-pE)+pE,SCALE);

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
		 evE = round(pD - 1.618 * (pD-pC),SCALE);

		 -----
		 mutE = round(0.25 * (pD-pE)+pE,SCALE);

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
		 evE = round(pC-(pC-pA)/1.618,SCALE);

		 -----
		 mutE = round(pE+(pB-pE)/1.618,SCALE);

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
		 evE = round(pD - 0.618 * (pD-pC),SCALE);

		 -----
		 mutE = round(0.5 * (pD-pE)+pE,SCALE);

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
		 evE = round(0.618 * (pC-pD)+pD,SCALE);

		 -----
		 mutE = round(pE-0.5 * (pE-pD),SCALE);

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
		 evE = round(1.272 * (pC-pD)+pD,SCALE);

		 -----
		 mutE = round(pE-0.3819 * (pE-pD),SCALE);

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
		 evE = round(1.618 * (pC-pD)+pD,SCALE);

		 -----
		 mutE = round(pE-0.25 * (pE-pD),SCALE);

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
		 evE = round(1.618 * (pC-pD)+pD,SCALE);

		 -----
		 mutE = round(pE-0.5 * (pE-pD),SCALE);

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
		 evE = round(3.0000 * (pC-pD)+pD,SCALE);

		 -----
		 mutE = round(pE-0.3819 * (pE-pD),SCALE);

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
		 evE = round(0.5 * (pC-pD)+pD,SCALE);

		 -----
		 mutE = round(pE-0.5 * (pE-pD),SCALE);

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
		 evE = round(0.618 * (pC-pD)+pD,SCALE);

		 -----
		 mutE = round(pE-0.3819 * (pE-pD),SCALE);

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
		 mutE = round(pE-0.25 * (pE-pD),SCALE);

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
		 evE = round(0.618 * (pC-pD)+pD,SCALE);

		 -----
		 mutE = round(pE-0.5 * (pE-pD),SCALE);

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
		 mutE = round(pE-0.3819 * (pE-pD),SCALE);

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
		 evE = round(1.272 * (pC-pD)+pD,SCALE);

		 -----
		 mutE = round(pE-0.3819 * (pE-pD),SCALE);

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
		 mutE = round(pE-0.25 * (pE-pD),SCALE);

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
	   evE = round(1.272 * (pC-pD)+pD,SCALE);

	   -----
	   mutE = round(pE-0.5 * (pE-pD),SCALE);

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
		 mutE = round(pE-0.3819 * (pE-pD),SCALE);

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
		 evE = round(1.618 * (pC-pD)+pD,SCALE);

		 -----
		 mutE = round(pE-0.5 * (pE-pD),SCALE);

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
		 mutE = round(pE-0.3819 * (pE-pD),SCALE);

		 ----- level_1:
		 --CalcPrognozLevel1();
	   end

end

local newIndex = #ALGORITHMS['names']+1

ALGORITHMS['names'][newIndex]               = "ZZ"
ALGORITHMS['initParams'][newIndex]          = initZZ
ALGORITHMS['initAlgorithms'][newIndex]      = initZZ
ALGORITHMS['itetareAlgorithms'][newIndex]   = iterateZZ
ALGORITHMS['calcAlgorithms'][newIndex]      = cached_ZZ
ALGORITHMS['tradeAlgorithms'][newIndex]     = simpleTrade
ALGORITHMS['settings'][newIndex]            = ZZSettings
