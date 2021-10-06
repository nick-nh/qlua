--- Алгоритм
function initCyberCycle()
    ATR = nil
    trend=nil
    calcAlgoValue = nil     --      Возвращаемая таблица
    calcChartResults = nil     --      Возвращаемая таблица

    Price       =nil
    Smooth      =nil
    Cycle       =nil
    it          =nil
    Trigger     =nil
    CyclePeriod =nil
    InstPeriod  =nil
    Q1          =nil
    I1          =nil
    DeltaPhase  =nil
end

function iterateCyberCycle()

    iterateSLTP = true

    local param1Min   = 0.02
    local param1Max   = 0.08
    local param1Step  = 0.01

    local param2Min   = 1
    local param2Max   = 2
    local param2Step  = 1

    local param3Min   = 1
    local param3Max   = 8
    local param3Step  = 1

    local param4Min   = 5
    local param4Max   = 23
    local param4Step  = 2

    local param5Min   = 0.2
    local param5Max   = 1
    local param5Step  = 0.05

    if fixedstop then
        param4Min   = 17
        param4Max   = 17
        param4Step  = 5

        param5Min   = 0.95
        param5Max   = 0.95
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
                            alpha    = param1,
                            cycletype    = param2,
                            shift    = param3,
                            periodATR = param4,
                            kATR = param5
                        }
                    end
                end
            end
        end
    end

    myLog('settingsTable size '..tostring(#settingsTable))
    iterateAlgorithm(settingsTable)

end

function CyberCycle(index, Fsettings)

    local alpha = Fsettings.alpha or 0.03
    local alpha1 = Fsettings.alpha or 0.03
    local cycletype = Fsettings.cycletype or 2
	local shift = Fsettings.shift or 3
    local periodATR = Fsettings.periodATR or 10
    kATR = Fsettings.kATR or kATR

    local indexToCalc = 1000
    indexToCalc = Fsettings.indexToCalc or indexToCalc
    local beginIndexToCalc = Fsettings.beginIndexToCalc or math.max(1, DS:Size() - indexToCalc)

    if index == nil then index = 1 end

    if index == beginIndexToCalc then

        if ROBOT_STATE ~= 'РЕОПТИМИЗАЦИЯ' and ROBOT_STATE ~= 'ОПТИМИЗАЦИЯ' then
            myLog("Показатель alpha "..tostring(alpha))
            myLog("Показатель cycletype "..tostring(cycletype))
            myLog("Показатель shift "..tostring(shift))
            myLog("Показатель periodATR "..tostring(periodATR))
            myLog("Показатель kATR "..tostring(kATR))
            myLog("index "..tostring(index))
            myLog("--------------------------------------------------")
        end

        Price={}
        Smooth={}
        Cycle={}
        it={}
        Trigger={}
        CyclePeriod={}
        InstPeriod={}
        Q1={}
        I1={}
        DeltaPhase={}

        Price[index] = (DS:H(index) + DS:L(index))/2
        Smooth[index]=0
        Cycle[index]=0
        it[index]=0
        Trigger[index]=0
        CyclePeriod[index]=0
        InstPeriod[index]=0
        Q1[index]=0
        I1[index]=0
        DeltaPhase[index]=0

        ATR = {}
        ATR[index] = 0
        trend = {}
        trend[index] = 1
        calcAlgoValue = {}
        calcAlgoValue[index] = 0

        calcChartResults = {}
        calcChartResults[index]= {nil,nil}

        return calcAlgoValue
    end

    Price[index]        = Price[index-1]
    Smooth[index]       = Smooth[index-1]
    Cycle[index]        = Cycle[index-1]
    it[index]           = it[index-1]
    Trigger[index]      = Trigger[index-1]
    CyclePeriod[index]  = CyclePeriod[index-1]
    InstPeriod[index]   = InstPeriod[index-1]
    Q1[index]           = Q1[index-1]
    I1[index]           = I1[index-1]
    DeltaPhase[index]   = DeltaPhase[index-1]

    ATR[index] = ATR[index-1]
    calcAlgoValue[index] = calcAlgoValue[index-1]
    trend[index] = trend[index-1]
    calcChartResults[index] = calcChartResults[index-1]

    if DS:C(index) == nil then
        return calcAlgoValue, trend, calcChartResults
    end

    Price[index] = (DS:H(index) + DS:L(index))/2
    --myLog("calc index "..tostring(index)..' d val'..tostring(dValue(index))..' ATR[index]'..tostring(ATR[index]))

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

    if index <= beginIndexToCalc + 4 then
        Cycle[index]=0
        it[index]=0
        Trigger[index]=0
        CyclePeriod[index]=0
        InstPeriod[index]=0
        Q1[index]=0
        I1[index]=0
        DeltaPhase[index]=0
        return calcAlgoValue, trend, calcChartResults
    end

    if DS:C(index) ~= nil then

		Cycle[index]=(Price[index]-2.0*Price[index - 1]+Price[index - 2])/4.0

		if cycletype == 1 then

			Smooth[index] = (Price[index]+2*Price[index - 1]+2*Price[index - 2]+Price[index - 3])/6.0

			if index < beginIndexToCalc + 7 then
				it[index]=0
				Trigger[index]=0
				CyclePeriod[index]=0
				InstPeriod[index]=0
				Q1[index]=0
				I1[index]=0
				DeltaPhase[index]=0
				return calcAlgoValue, trend, calcChartResults
			end

			Cycle[index]=(1.0-0.5*alpha) *(1.0-0.5*alpha) *(Smooth[index]-2.0*Smooth[index - 1]+Smooth[index - 2])
							+2.0*(1.0-alpha)*Cycle[index - 1]-(1.0-alpha)*(1.0-alpha)*Cycle[index - 2]


            --myLog("index "..tostring(index)..", Cycle "..tostring(Cycle[index])..", InstPeriod "..tostring(InstPeriod[index]))
            Q1[index] = (0.0962*Cycle[index]+0.5769*Cycle[index-2]-0.5769*Cycle[index-4]-0.0962*Cycle[index-6])*(0.5+0.08*(InstPeriod[index-1] or 0))
			I1[index] = Cycle[index-3]

			if Q1[index]~=0.0 and Q1[index-1]~=0.0 then
				DeltaPhase[index] = (I1[index]/Q1[index]-I1[index-1]/Q1[index-1])/(1.0+I1[index]*I1[index-1]/(Q1[index]*Q1[index-1]))
			else DeltaPhase[index] = 0
			end
			if DeltaPhase[index] < 0.1 then
				DeltaPhase[index] = 0.1
			end
			if DeltaPhase[index] > 0.9 then
				DeltaPhase[index] = 0.9
			end

			MedianDelta = Median(DeltaPhase[index],DeltaPhase[index-1], Median(DeltaPhase[index-2], DeltaPhase[index-3], DeltaPhase[index-4]))

			if MedianDelta == 0.0 then
				DC = 15.0
			else
				DC = 6.28318/MedianDelta + 0.5
			end

			InstPeriod[index] = 0.33 * DC + 0.67 * (InstPeriod[index-1] or 0)
			CyclePeriod[index] = 0.15 * InstPeriod[index] + 0.85 * CyclePeriod[index-1]

			alpha1 = 2.0/(CyclePeriod[index]+1.0)
		end

		it[index]=(alpha1-((alpha1*alpha1)/4.0))*Price[index]+0.5*alpha1*alpha1*Price[index-1]-(alpha1-0.75*alpha1*alpha1)*Price[index-2]+
			2*(1-alpha1)*(it[index-1] or Cycle[index])-(1-alpha1)*(1-alpha1)*(it[index-2] or Cycle[index])

        Trigger[index] = 2.0*it[index]-(it[index-shift] or 0)

        local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5
        local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5

        local isBuy  = trend[index] <= 0 and it[index] > it[index-1] and Trigger[index] > it[index] and DS:O(index) > it[index]
        local isSell = trend[index] >= 0 and it[index] < it[index-1] and Trigger[index] < it[index] and DS:O(index) < it[index]

        --local isBuy  = trend[index] <= 0 and it[index] > it[index-1] and Trigger[index] > Trigger[index-1] and DS:O(index) > it[index]
        --local isSell = trend[index] >= 0 and it[index] < it[index-1] and Trigger[index] < Trigger[index-1] and DS:O(index) < it[index]

        --local isBuy  = trend[index] <= 0 and Trigger[index] > it[index] and Trigger[index] > Trigger[index-1] and it[index] > it[index-1]
        --local isSell = trend[index] >= 0 and Trigger[index] < it[index] and Trigger[index] < Trigger[index-1] and it[index] < it[index-1]
        --local isBuy  = trend[index] <= 0 and Trigger[index] > Trigger[index-1] and it[index] > it[index-1]
        --local isSell = trend[index] >= 0 and Trigger[index] < Trigger[index-1] and it[index] < it[index-1]
        --local isBuy  = trend[index] <= 0 and it[index] > it[index-1] and Trigger[index] > it[index]
        --local isSell = trend[index] >= 0 and it[index] < it[index-1] and Trigger[index] < it[index]

        --local isBuy  = trend[index] <= 0 and it[index] > it[index-1] and Trigger[index] > it[index] and DS:O(index) > it[index]
        --local isSell = trend[index] >= 0 and it[index] < it[index-1] and Trigger[index] < it[index] and DS:O(index) < it[index]
        --local isBuy  = trend[index] <= 0 and it[index] > it[index-1] and it[index] > Trigger[index] and DS:O(index) > it[index]
        --local isSell = trend[index] >= 0 and it[index] < it[index-1] and it[index] < Trigger[index] and DS:O(index) < it[index]

        --local isBuy  = trend[index] <= 0 and it[index] > it[index-1] and Trigger[index] > it[index] and DS:O(index) > Trigger[index]
        --local isSell = trend[index] >= 0 and it[index] < it[index-1] and Trigger[index] < it[index] and DS:O(index) < Trigger[index]
        --local isBuy  = trend[index] <= 0 and Trigger[index] > Trigger[index-1] and Trigger[index] > it[index] and DS:O(index) > Trigger[index]
        --local isSell = trend[index] >= 0 and Trigger[index] < Trigger[index-1] and Trigger[index] < it[index] and DS:O(index) < Trigger[index]

        --myLog("index "..tostring(index)..", O "..tostring(DS:O(index))..", it "..tostring(it[index])..", Trigger "..tostring(Trigger[index])..", ATR "..tostring(ATR[index]))

        if isBuy then
            trend[index] = 1
        end
        if isSell then
            trend[index] = -1
        end

        calcAlgoValue[index] = DS:O(index)
    end

    calcChartResults[index] = {Trigger[index], it[index]}

    return calcAlgoValue, trend, calcChartResults

end

local newIndex = #presets+1
presets[newIndex] =
{
    Name    = "CycleM3",
    NAME_OF_STRATEGY = 'CyberCycle',
    SEC_CODE = 'SiH1',
    CLASS_CODE = 'SPBFUT',
    ACCOUNT                 = 'SPBFUT0002t',
    CLIENT_CODE             = 'SPBFUT0002t',
    QTY_LOTS = 1, -- количество для торговли
    OFFSET = 2, --(ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
    SPREAD = 10, --Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
    ChartId = "GRAPH_SI",
    SetStop = true, -- выставлять ли стоп заявки
    STOP_LOSS               = 70,            -- Размер СТОП-ЛОССА
    TAKE_PROFIT             = 120,            -- Размер ТЕЙК-ПРОФИТА
    TRAILING_SIZE           = 0,             -- Размер выхода в плюс в пунктах, после которого активируется трейлинг
    TRAILING_SIZE_STEP      = 10,             -- Размер шага трейлинга в пунктах
    kATR                    = 0.95,          -- коэффициент ATR для расчета стоп-лосса
    periodATR               = 17,            -- период ATR для расчета стоп-лосса
    CloseSLbeforeClearing = false, -- снимать ли стоп заявки перед клирингом
    fixedstop = true,-- STOPLOSS не рассчитывать по алгоритму, а брать фиксированным из настроек
    isLong  = true, -- доступен лонг
    isShort = true, -- доступен шорт
    trackManualDeals = true, --учитывать ручные сделки не из интерфейса робота,
    maxStop       = 85,
    reopenDealMaxStop       = 75,
    stopShiftIndexWait       = 17,
    shiftStop = true, -- сдвигать стоп (трейил) на величину STOP_LOSS
    shiftProfit = false, -- сдвигать профит (трейил) на величину STOP_LOSS/2
    reopenPosAfterStop       = 7,
    INTERVAL          = INTERVAL_M3,          -- Таймфрейм графика (для построения скользящих)
    testSizeBars = 3240,
    autoReoptimize = false, -- надо ли включать оптимизацию перед вечерним клирингом
    autoClosePosition = true, -- надо ли автоматически закрывать позиции перед вечерним клирингом
    calculateAlgo = CyberCycle,
    iterateAlgo = iterateCyberCycle,
    initAlgo = initCyberCycle,
    notReadOptimized = false,
    algoParam_string = '',
    settingsAlgo =
    {
        alpha    = 0.03,
        cycletype = 1,
        shift = 6
    }
}

--Куда поместить кнопку выбора настройки
presets[newIndex].interface_line = 3
presets[newIndex].interface_col = 4

--Какие значения настроек надо вывести в интерфейс, в указанные места
--Описание полей интерфейса
presets[newIndex].fields = {}
presets[newIndex].fields['alpha']       = {caption = 'alpha'        , caption_line = 4, caption_col = 1 , val_line = 5, val_col = 1, base_color = nil}
presets[newIndex].fields['cycletype']   = {caption = 'cycletype'    , caption_line = 4, caption_col = 2 , val_line = 5, val_col = 2, base_color = nil}
presets[newIndex].fields['shift']       = {caption = 'shift'        , caption_line = 4, caption_col = 3 , val_line = 5, val_col = 3, base_color = nil}
presets[newIndex].fields['periodATR']   = {caption = 'periodATR'    , caption_line = 4, caption_col = 4 , val_line = 5, val_col = 4, base_color = nil}
presets[newIndex].fields['kATR']        = {caption = 'kATR'         , caption_line = 6, caption_col = 1 , val_line = 7, val_col = 1, base_color = nil}

-- возможность редактирования полей настройки
presets[newIndex].edit_fields = {}
presets[newIndex].edit_fields['alpha']       = true
presets[newIndex].edit_fields['cycletype']   = true
presets[newIndex].edit_fields['shift']       = true
presets[newIndex].edit_fields['periodATR']   = true
presets[newIndex].edit_fields['kATR']        = true