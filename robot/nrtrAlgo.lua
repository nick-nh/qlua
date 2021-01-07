--- Алгоритм
function initNRTR()
    calcAlgoValue = nil     --      Возвращаемая таблица
    calcChartResults = nil     --      Возвращаемая таблица

    NRTR=nil
    smax1=nil
    smin1=nil
    trend=nil
    ATR = nil
    emaStep = nil
    cacheL = nil
    cacheH = nil
    cacheC = nil
    adaptivePeriod = cached_ZZ()
end

function iterateNRTR()

    if Settings.adaptive == 1 then
        param1Min = 7
        param1Max = 41
        param1Step = 1

        param2Min = 0
        param2Max = 3
        param2Step = 1

        param3Min = 0
        param3Max = 1
        param3Step = 1

        param4Min = 0
        param4Max = 0.3
        param4Step = 0.1

        param5Min = 3
        param5Max = 7
        param5Step = 1
    else
        param1Min = 3
        param1Max = 15
        param1Step = 1

        param2Min = 0.1
        param2Max = 1.5
        param2Step = 0.1

        param3Min = 0
        param3Max = 1
        param3Step = 1

        param4Min = 0
        param4Max = 0.15
        param4Step = 0.05

        param5Min = 1
        param5Max = 1
        param5Step = 1
    end

    if ROBOT_STATE == 'РЕОПТИМИЗАЦИЯ' then
        param1Min = math.max(param1Min, Settings.Length-7)
        param1Max = math.min(param1Max, Settings.Length+7)
    end

    local settingsTable = {}
    local allCount = 0

    for param1 = param1Min, param1Max, param1Step do
        for param2 = param2Min, param2Max, param2Step do
            for param3 = param3Min, param3Max, param3Step do
                for param4 = param4Min, param4Max, param4Step do
                    for param5 = param5Min, param5Max, param5Step do

                        allCount = allCount + 1

                        local _Kv = param2
                        if adaptive == 1 then _Kv = 1 end

                        settingsTable[allCount] = {
                            Length    = param1,
                            Kv = _Kv,
                            zShift = param2,
                            Switch = param3,
                            barShift = Settings.barShift,
                            smoothStep = Settings.smoothStep,
                            ATRfactor = param4,
                            numberOfMovesForTargetZone = param5,
                            StepSize = Settings.StepSize,
                            adaptive = Settings.adaptive,
                            rangeCalc = Settings.rangeCalc,
                            Percentage = Settings.Percentage
                        }

                    end
                end
            end
        end
    end

    iterateAlgorithm(settingsTable)

end

function NRTR(index, Fsettings)

    Length = Fsettings.Length or 13
	Kv = Fsettings.Kv or 1
	v_type = Fsettings.value_type or "ATR"
	StepSize = Fsettings.StepSize or 0
	ATRfactor = Fsettings.ATRfactor or 0
	barShift = Fsettings.barShift or 0
	smoothStep = Fsettings.smoothStep or 0
	Percentage = Fsettings.Percentage or 0
	Switch = Fsettings.Switch or 1
	adaptive = Fsettings.adaptive or 0
	rangeCalc = Fsettings.rangeCalc or 0

    local ratio=Percentage/100.0*SEC_PRICE_STEP
    ratio=Percentage/100.0*SEC_PRICE_STEP
    indexToCalc = Fsettings.indexToCalc or indexToCalc

    local indexToCalc = 1000
    indexToCalc = Fsettings.indexToCalc or indexToCalc
    local beginIndexToCalc = Fsettings.beginIndexToCalc or math.max(1, DS:Size() - indexToCalc)

	if index == nil then index = 1 end
    index = math.max(index, 1)

    if adaptive == 1 then
        local aP = adaptivePeriod(index, Fsettings, DS)
        Length = math.ceil(aP) or Length
        if Length == 0 then
            Length = settings.Length or 15
        end
    end

    local kawg = 2/(20+1)

    if index == beginIndexToCalc then
		NRTR = {}
		NRTR[index] = 0
		ATR = {}
		ATR[index] = 0
		smax1 = {}
		smin1 = {}
		smax1[index] = 0
		smin1[index] = 0

        emaKv = {}
        emaKv[index] = 0
        emaStep = {}
        emaStep[index] = 0
        emaRange = {}
        emaRange[index] = 0
        cacheL = {}
        cacheL[index] = 0
        cacheH = {}
        cacheH[index] = 0
        cacheC = {}
        cacheC[index] = 0

        calcAlgoValue = {}
        calcAlgoValue[index] = 0
		trend = {}
		trend[index] = 1
        calcChartResults = {}
        calcChartResults[index]= nil

        return nil
	end

	NRTR[index] = NRTR[index-1]
	smax1[index] = smax1[index-1]
	smin1[index] = smin1[index-1]

    cacheL[index] = cacheL[index-1]
    cacheH[index] = cacheH[index-1]
    cacheC[index] = cacheC[index-1]
    emaStep[index] = emaStep[index-1]
    emaKv[index] = emaKv[index-1]
    emaRange[index] = emaRange[index-1]

    ATR[index] = ATR[index-1]
    calcAlgoValue[index] = calcAlgoValue[index-1]
    trend[index] = trend[index-1]
    calcChartResults[index] = calcChartResults[index-1]

	if DS:C(index) == nil then
		return nil
	end

	if index<(Length+beginIndexToCalc) then
		ATR[index] = 0
	elseif index==(Length+beginIndexToCalc) then
		local sum=0
		for i = 1, Length do
			sum = sum + dValue(i)
		end
		ATR[index]=sum / Length
	elseif index>(Length+beginIndexToCalc) then
		ATR[index]=(ATR[index-1] * (Length-1) + dValue(index)) / Length
        --ATR[index] = kawg*dValue(index)+(1-kawg)*ATR[index-1]
    end

	if index < beginIndexToCalc+100 then
		return nil
	end

    cacheH[index] = DS:H(index)
    cacheL[index] = DS:L(index)
    cacheC[index] = DS:C(index)

    Length = math.max(Length,2)

    if rangeCalc == 0 then

        local maxH = math.max(unpack(cacheH,math.max(index-Length+1, 1),index))
        local minH = math.min(unpack(cacheH,math.max(index-Length+1, 1),index))
        local maxL = math.max(unpack(cacheL,math.max(index-Length+1, 1),index))
        local minL = math.min(unpack(cacheL,math.max(index-Length+1, 1),index))
        local maxC = math.max(unpack(cacheC,math.max(index-Length+1, 1),index))
        local minC = math.min(unpack(cacheC,math.max(index-Length+1, 1),index))

        --local range = math.min(math.abs(maxC - minC), math.abs(maxH - minH), math.abs(maxL - minL))
        local range = math.abs(maxC - minC)
        if Switch == 1 then
            range = math.abs(maxH - minL)
        end

        if adaptive == 1 then
            Kv = 1
        end

        local StepRange = StepSizeCalc(Length,Kv,StepSize,Switch,index, adaptive, smoothStep)
        if StepRange == 0 then StepRange = SEC_PRICE_STEP end

        if adaptive == 1 then
            emaStep[index] = kawg*StepRange+(1-kawg)*emaStep[index-1]
            --emaRange[index] = kawg*range+(1-kawg)*emaRange[index-1]
            --Kv = emaRange[index]/emaStep[index]
            --emaKv[index] = kawg*Kv+(1-kawg)*emaKv[index-1]
            Kv = range/emaStep[index]
            --Step = round(emaKv[index]*StepRange/SEC_PRICE_STEP, nil)
            Step = round(Kv*StepRange/SEC_PRICE_STEP, nil)
        else
            Step = StepRange
        end

        --myLog ("---------------------------------")
        --myLog ("index "..tostring(index))
        --myLog ("C(index) "..tostring(DS:C(index)))
        --myLog ("H(index) "..tostring(DS:H(index)))
        --myLog ("L(index) "..tostring(DS:L(index)))
        --myLog ("Length "..tostring(Length))
        --myLog ("range "..tostring(range))
        --myLog ("StepRange "..tostring(StepRange))
        --myLog ("emaStep "..tostring(emaStep[index]))
        --myLog ("emaRange "..tostring(emaRange[index]))
        --myLog ("emaKv "..tostring(emaKv[index]))
        --myLog ("Step "..tostring(Step))

        if Step == 0 then Step = SEC_PRICE_STEP end
        local SizeP=Step*SEC_PRICE_STEP
        local Size2P=2*SizeP

        local result
        local previous = index-barShift

        if DS:C(previous) == nil then
            previous = FindExistCandle(previous)
        end

        if Switch == 1 then
            smax0=DS:L(previous)+Size2P
            smin0=DS:H(previous)-Size2P
        else
            smax0=DS:C(previous)+Size2P
            smin0=DS:C(previous)-Size2P
        end

        if DS:C(index)>smax1[index] and (DS:C(index)-smax1[index]) > ATRfactor*ATR[index] then
            trend[index] = 1
        end
        if DS:C(index)<smin1[index] and (smin1[index]-DS:C(index)) > ATRfactor*ATR[index] then
            trend[index]= -1
        end

        if trend[index]>0 then
            if smin0<smin1[index] then smin0=smin1[index] end
            result=smin0+SizeP
        else
            if smax0>smax1[index] then smax0=smax1[index] end
            result=smax0-SizeP
        end

        smax1[index] = smax0
        smin1[index] = smin0

        if trend[index]>0 then
            NRTR[index]=(result+ratio/Step)-Step*SEC_PRICE_STEP
        end
        if trend[index]<0 then
            NRTR[index]=(result+ratio/Step)+Step*SEC_PRICE_STEP
        end

    else

        previous = index-barShift

        if DS:C(previous) == nil then
            previous = FindExistCandle(previous)
        end

        if Switch == 1 then
            smax0=DS:L(previous)+Kv*ATR[index]
            smin0=DS:H(previous)-Kv*ATR[index]
        else
            smax0=DS:C(previous)+Kv*ATR[index]
            smin0=DS:C(previous)-Kv*ATR[index]
        end

		if DS:C(index)>smax1[index] and (DS:C(index)-smax1[index]) > ATRfactor*ATR[index] then
			trend[index] = 1
		end
		if DS:C(index)<smin1[index] and (smin1[index]-DS:C(index)) > ATRfactor*ATR[index] then
			trend[index]= -1
		end

        if trend[index]>0 then
            if smin0<smin1[index] then smin0=smin1[index] end
            NRTR[index]=smin0
        else
            if smax0>smax1[index] then smax0=smax1[index] end
            NRTR[index]=smax0
        end

        smax1[index] = smax0
        smin1[index] = smin0

    end

    calcAlgoValue[index] = NRTR[index]
    calcChartResults[index] = NRTR[index]

    if not optimizationInProgress then
        local roundAlgoVal = round(calcAlgoValue[index], scale)
        SetCell(t_id, 2, 1, tostring(roundAlgoVal), roundAlgoVal)
    end

    return NRTR[index]

end

function StepSizeCalc(Len, Km, Size, Switch, index, adaptive, smoothStep)

    local result

    if smoothStep == 1 then

        local Range = 0
        local rangeEMA = {}
        local k = 2/(Len+1)

        if Size == 0 then

            local Range=0.0
            local ATRmax=-1000000
            local ATRmin=1000000
            if DS:C(index-Len-1) ~= nil then
                if Switch == 1 then
                    Range=DS:H(index-Len-1)-DS:L(index-Len-1)
                else
                    Range=math.abs(DS:O(index-Len-1)-DS:C(index-Len-1))
                end
            end
            rangeEMA[1] = Range

            for iii=1, Len do
                if DS:C(index-Len+iii-1) ~= nil then

                    if Switch == 1 then
                        Range=DS:H(index-Len+iii-1)-DS:L(index-Len+iii-1)
                    else
                        Range=math.abs(DS:O(index-Len+iii-1)-DS:C(index-Len+iii-1))
                    end
                    rangeEMA[iii+1] = k*Range+(1-k)*rangeEMA[iii]
                else
                    rangeEMA[iii+1] = rangeEMA[iii]
                end
            end

			if adaptive == 1 then
				result = rangeEMA[#rangeEMA]
			else
                result = round(Km*rangeEMA[#rangeEMA]/SEC_PRICE_STEP, nil)
			end

        else result=Km*Size
        end

    else

        if Size == 0 then

            local Range=0.0
            local ATRmax=-1000000
            local ATRmin=1000000

            for iii=1, Len do
                if DS:C(index-iii) ~= nil then
                    if Switch == 1 then
                        Range=DS:H(index-iii)-DS:L(index-iii)
                    else
                        Range=math.abs(DS:O(index-iii)-DS:C(index-iii))
                    end
                    if Range>ATRmax then ATRmax=Range end
                    if Range<ATRmin then ATRmin=Range end
                end
            end

			if adaptive == 1 then
				result = 0.5*(ATRmax+ATRmin)
			else
                result = round(0.5*Km*(ATRmax+ATRmin)/SEC_PRICE_STEP, nil)
			end

        else result=Km*Size
        end

    end

    return result

end

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
	local emaPeriod={}

	return function(ind, Fsettings, DS)

		local Fsettings=(Fsettings or {})
		local index = ind
		local bars = Fsettings.bars or 3000
		local beginIndexToCalc = Fsettings.beginIndexToCalc
		local deviation = Fsettings.Length or 27
		local gapDeviation = Fsettings.gapDeviation or 70
		local WaitBars = Fsettings.WaitBars or 2
		local numberOfMovesForTargetZone = Fsettings.numberOfMovesForTargetZone or 7
		local zShift = Fsettings.zShift or 2

		local currentRange = 0
		local sizeOfZZLevels = 20

		if index == beginIndexToCalc then
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
			emaPeriod={}
			emaPeriod[index]=0

			CC[index]=DS:C(index)
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

			return 15
		end

		CC[index]=CC[index-1]
		emaPeriod[index]=emaPeriod[index-1]

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

		if DS:C(index) == nil then
			return 15
		end

		local isBreak=0

		CC[index]=DS:C(index)

		---------------------------------------------------------------------------------------
		----------------------------------------------------------------------

		-- расчет
		currentRange = math.abs(cache_H[index] - cache_L[index])

		if cache_ST[index]==1 then --растущий тренд

			if cache_H[index] <= DS:H(index) then -- новый максимум

				cache_H[index]=DS:H(index)
				H_index[index]=index

				if cache_L[index] == 0 then -- для первой расчетной свечи
					cache_L[index] = DS:L(index)
					L_index[index] = index
					LowBuffer[index] = DS:L(index)
				end

				if breakBars[index] ~= 0 then
					breakBars[index] = 0
					breakIndex[index] = 0
					UpThrust[index] = 0
				end

			elseif (currentRange*deviation/100) < math.abs(CC[index] - cache_H[index]) then --прошли больше чем отклонение от движения

				if UpThrust[index] == 0 then
					UpThrust[index] = index
				end

				if breakBars[index] == 0 or (breakBars[index] ~= 0 and breakBars[index] >= DS:L(index)) then
					breakBars[index] = DS:L(index)
					breakIndex[index] = index
				end

				if ((index - UpThrust[index]) > WaitBars and UpThrust[index] ~= 0) or (currentRange*gapDeviation/100) < math.abs(CC[index] - cache_H[index]) then -- ждем закрепления пробоя

					--меняем тренд

					cache_ST[index]=0

					if breakBars[index] < DS:L(index) then
						cache_L[index] = breakBars[index]
						L_index[index] = breakIndex[index]
					else
						cache_L[index] = DS:L(index)
						L_index[index] = index
					end

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

			elseif breakBars[index] ~= 0 and breakBars[index] >= DS:L(index) then
				breakBars[index] = DS:L(index)
				breakIndex[index] = index
			end


		elseif cache_ST[index]==0 then --падающий тренд

			if cache_L[index] >= DS:L(index) then -- новый минимум

				cache_L[index]=DS:L(index)
				L_index[index]=index

				if breakBars[index] ~= 0 then
					breakBars[index] = 0
					breakIndex[index] = 0
					UpThrust[index] = 0
				end

			elseif (currentRange*deviation/100) < math.abs(CC[index] - cache_L[index]) then --прошли больше чем отклонение от движения

				if UpThrust[index] == 0 then
					UpThrust[index] = index
				end

				if breakBars[index] == 0 or (breakBars[index] ~= 0 and breakBars[index] <= DS:H(index)) then
					breakBars[index] = DS:H(index)
					breakIndex[index] = index
				end

				if ((index - UpThrust[index]) > WaitBars and UpThrust[index] ~= 0) or (currentRange*gapDeviation/100) < math.abs(CC[index] - cache_H[index]) then -- ждем закрепления пробоя
				--меняем тренд

					cache_ST[index]=1
					if breakBars[index] > DS:L(index) then
						cache_H[index] = breakBars[index]
						H_index[index] = breakIndex[index]
					else
						cache_H[index] = DS:H(index)
						H_index[index] = index
					end

					for nn = 1, sizeOfZZLevels-1 do
						ZZLevels[1][nn] = ZZLevels[1][nn+1]
						ZZLevels[2][nn] = ZZLevels[2][nn+1]
					end

					ZZLevels[1][sizeOfZZLevels] = cache_L[index]
					ZZLevels[2][sizeOfZZLevels] = L_index[index]

					breakBars[index] = 0
					breakIndex[index] = 0
					UpThrust[index] = 0
					isBreak = 1

					LowBuffer[index] = cache_L[index]
				end

			elseif breakBars[index] ~= 0 and breakBars[index] <= DS:H(index) then
				breakBars[index] = DS:H(index)
				breakIndex[index] = index
			end

		end

		local upIntervals = 0
		local upcount = 0
		local downIntervals = 0
		local downcount = 0
		local upRange = 0
        local downRange = 0
        local zCycle = 1

		--myLog ("deviation "..tostring(deviation))
		--myLog ("WaitBars "..tostring(WaitBars))
		--myLog("numberOfMovesForTargetZone "..tostring(numberOfMovesForTargetZone))
		--myLog("zShift "..tostring(2))

		for j = zShift, zShift + numberOfMovesForTargetZone*zCycle-1, zCycle do
		--for j = 3, numberOfMovesForTargetZone-1, 1 do
			if ZZLevels[1][sizeOfZZLevels-j-zCycle] ~= nil then
				if cache_ST[index] == 1 then
					upIntervals = upIntervals + ZZLevels[2][sizeOfZZLevels-j] - ZZLevels[2][sizeOfZZLevels-j-zCycle]
					upRange = upRange + math.abs(ZZLevels[1][sizeOfZZLevels-j] - ZZLevels[1][sizeOfZZLevels-j-zCycle])
					upcount = upcount + 1
				else
					downIntervals = downIntervals + ZZLevels[2][sizeOfZZLevels-j] - ZZLevels[2][sizeOfZZLevels-j-zCycle]
					downRange = downRange + math.abs(ZZLevels[1][sizeOfZZLevels-j] - ZZLevels[1][sizeOfZZLevels-j-zCycle])
					downcount = downcount + 1
				end
			end
		end

        local meanPeriod = 29
        local meanRange = 0

		if upcount + downcount ~= 0 then
			meanPeriod = math.ceil((upIntervals + downIntervals)/(upcount + downcount))
			meanRange = math.ceil((upRange +downRange)/(upcount + downcount))
		end

		local aP = math.ceil(meanPeriod) --*deviation/100
		--emaPeriod[index] = kawg*aP+(1-kawg)*emaPeriod[index-1] or 0
		--myLog ("Length "..tostring(aP))

		return aP

	end

end

local newIndex = #presets+1
presets[newIndex] =
{
    Name    = "NRTR M3",
    NAME_OF_STRATEGY = 'NRTR',
    SEC_CODE                = 'SBER',
    CLASS_CODE              = 'QJSIM',
    ACCOUNT                 = 'NL0011100043',
    CLIENT_CODE             = '11056',
    QTY_LOTS = 1, -- количество для торговли
    OFFSET = 2, --(ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
    SPREAD = 10, --Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
    ChartId = "Sheet11",
    STOP_LOSS               = 40,            -- Размер СТОП-ЛОССА
    TAKE_PROFIT             = 110,           -- Размер ТЕЙК-ПРОФИТА
    TRAILING_SIZE           = 0,             -- Размер выхода в плюс в пунктах, после которого активируется трейлинг
    TRAILING_SIZE_STEP      = 1,             -- Размер шага трейлинга в пунктах
    kATR                    = 0.95,          -- коэффициент ATR для расчета стоп-лосса
    periodATR               = 17,             -- период ATR для расчета стоп-лосса
    SetStop = true, -- выставлять ли стоп заявки
    CloseSLbeforeClearing = false, -- снимать ли стоп заявки перед клирингом
    fixedstop = false,-- STOPLOSS не рассчитывать по алгоритму, а брать фиксированным из настроек
    isLong  = true, -- доступен лонг
    isShort = true, -- доступен шорт
    trackManualDeals = true, --учитывать ручные сделки не из интерфейса робота,
    maxStop       = 85,
    reopenDealMaxStop       = 75,
    stopShiftIndexWait       = 17,
    shiftStop = true, -- сдвигать стоп (трейил) на величину STOP_LOSS
    shiftProfit = true, -- сдвигать профит (трейил) на величину STOP_LOSS/2
    reopenPosAfterStop       = 7,
    INTERVAL          = INTERVAL_M3,          -- Таймфрейм графика (для построения скользящих)
    testSizeBars = 1200, --161
    autoReoptimize = false, -- надо ли включать оптимизацию перед вечерним клирингом
    autoClosePosition = false, -- надо ли автоматически закрывать позиции перед вечерним клирингом
    calculateAlgo = NRTR,
    iterateAlgo = iterateNRTR,
    initAlgo = initNRTR,
    settingsAlgo =
    {
        Length    = 36,                   -- ПЕРИОД    10
        Kv = 1,                    -- коэффициент 2
        Switch = 0, --1 - HighLow, 2 - CloseClose 1
        ATRfactor = 0,
        barShift = 0, --0
        adaptive = 0,
        zShift = 3,
        numberOfMovesForTargetZone = 4,
        smoothStep = 1,
        StepSize = 0,                  -- шаг
        Percentage = 0,
        rangeCalc = 0
    }
}

--Куда поместить кнопку выбора настройки
presets[newIndex].interface_line = 3
presets[newIndex].interface_col = 5

--Какие значения настроек надо вывести в интерфейс, в указанные места
--Описание полей интерфейса
presets[newIndex].fields = {}
presets[newIndex].fields['Length']                      = {caption = 'Length'       , caption_line = 4, caption_col = 1, val_line = 5,  val_col = 1, base_color = nil}
presets[newIndex].fields['Kv']                          = {caption = 'Kv'           , caption_line = 4, caption_col = 2, val_line = 5,  val_col = 2, base_color = nil}
presets[newIndex].fields['Switch']                      = {caption = 'Switch'       , caption_line = 4, caption_col = 3, val_line = 5,  val_col = 3, base_color = nil}
presets[newIndex].fields['ATRfactor']                   = {caption = 'ATRfactor'    , caption_line = 4, caption_col = 4, val_line = 5,  val_col = 4, base_color = nil}
presets[newIndex].fields['barShift']                    = {caption = 'barShift'     , caption_line = 6, caption_col = 1, val_line = 7,  val_col = 1, base_color = nil}
presets[newIndex].fields['adaptive']                    = {caption = 'adaptive'     , caption_line = 6, caption_col = 2, val_line = 7,  val_col = 2, base_color = nil}
presets[newIndex].fields['zShift']                      = {caption = 'zShift'       , caption_line = 6, caption_col = 3, val_line = 7,  val_col = 3, base_color = nil}
presets[newIndex].fields['numberOfMovesForTargetZone']  = {caption = 't moves'      , caption_line = 6, caption_col = 4, val_line = 7,  val_col = 4, base_color = nil}
presets[newIndex].fields['smoothStep']                  = {caption = 'smoothStep'   , caption_line = 6, caption_col = 5, val_line = 7,  val_col = 5, base_color = nil}
presets[newIndex].fields['StepSize']                    = {caption = 'StepSize'     , caption_line = 6, caption_col = 6, val_line = 7,  val_col = 6, base_color = nil}
presets[newIndex].fields['Percentage']                  = {caption = 'Percentage'   , caption_line = 8, caption_col = 1, val_line = 9,  val_col = 1, base_color = nil}
presets[newIndex].fields['rangeCalc']                   = {caption = 'rangeCalc'    , caption_line = 8, caption_col = 2, val_line = 9,  val_col = 2, base_color = nil}

-- возможность редактирования полей настройки
presets[newIndex].edit_fields = {}
presets[newIndex].edit_fields['Length']                     = true
presets[newIndex].edit_fields['Kv']                         = true
presets[newIndex].edit_fields['Switch']                     = true
presets[newIndex].edit_fields['ATRfactor']                  = true
presets[newIndex].edit_fields['barShift']                   = true
presets[newIndex].edit_fields['adaptive']                   = true
presets[newIndex].edit_fields['zShift']                     = true
presets[newIndex].edit_fields['numberOfMovesForTargetZone'] = true
presets[newIndex].edit_fields['smoothStep']                 = true
presets[newIndex].edit_fields['StepSize']                   = true
presets[newIndex].edit_fields['Percentage']                 = true
presets[newIndex].edit_fields['smoothStep']                 = true
presets[newIndex].edit_fields['rangeCalc']                  = true
