--- Алгоритм
function initTHV()
    calcATR             = true
    ATR                 = {}
    trend               = {}
    calcAlgoValue       = {}
    dVal                = {}
    calcChartResults    = {}

	Trigger             = nil
	thv_line            = nil
	gda_108             = nil
	gda_112             = nil
	gda_116             = nil
	gda_120             = nil
	gda_124             = nil
	gda_128             = nil
end

function iterateTHV()

    iterateSLTP = true

    local param1Min = 5
    local param1Max = 80
    local param1Step = 1

    local param2Min = 0.3
    local param2Max = 2.1
    local param2Step = 0.1

    local param3Min = 35
    local param3Max = 35
    local param3Step = 1

    local param4Min   = 10
    local param4Max   = 10
    local param4Step  = 1

    local param5Min   = 0.6
    local param5Max   = 0.6
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

        --_param2Min = math.max(math.ceil(param1+1), param2Min)
        --for param2 = _param2Min, param2Max, param2Step do
        for param2 = param2Min, param2Max, param2Step do

            --for param3 = param3Min, math.ceil(0.8*param1), param3Step do
            for param3 = param3Min, param3Max, param3Step do
                for param4 = param4Min, param4Max, param4Step do
                    for param5 = param5Min, param5Max, param5Step do
                        allCount = allCount + 1
                        settingsTable[allCount] = {
                            period    = param1,
                            koef    =   param2,
                            shift    = param3,
                            periodATR = param4,
                            kATR = param5,
                            Size = Size
                            }
                    end
                end
            end
        end
    end

    iterateAlgorithm(settingsTable)

end

function THV(index, Fsettings)

    local period = Fsettings.period or 32
    local koef = Fsettings.koef or 1
    local shift = Fsettings.shift or 2

    local periodATR = Fsettings.periodATR or periodATR
    kATR = Fsettings.kATR or kATR

    local indexToCalc = 1000
    indexToCalc = Fsettings.indexToCalc or indexToCalc
    local beginIndexToCalc = Fsettings.beginIndexToCalc or math.max(1, DS:Size() - indexToCalc)
    local endIndexToCalc = Fsettings.endIndex or DS:Size()

    if index == nil then index = 1 end

    local ild_0
    local ld_8

    local gd_188 = koef * koef
    local gd_196 = 0
    local gd_196 = gd_188 * koef
    local gd_132 = -gd_196
    local gd_140 = 3.0 * (gd_188 + gd_196)
    local gd_148 = -3.0 * (2.0 * gd_188 + koef + gd_196)
    local gd_156 = 3.0 * koef + 1.0 + gd_196 + 3.0 * gd_188
    local gd_164 = period
    if gd_164 < 1.0 then gd_164 = 1 end
    gd_164 = (gd_164 - 1.0) / 2.0 + 1.0
    local gd_172 = 2 / (gd_164 + 1.0)
    local gd_180 = 1 - gd_172

    local kawg = 2/(period+1)

    if index == beginIndexToCalc then

        if not ROBOT_STATE:find('ОПТИМИЗАЦИЯ') then
            myLog("--------------------------------------------------")
            myLog("Показатель Period "..tostring(period))
            myLog("Показатель shift "..tostring(shift))
            myLog("Показатель koef "..tostring(koef))
            myLog("Показатель periodATR "..tostring(periodATR))
            myLog("Показатель kATR "..tostring(kATR))
            myLog("--------------------------------------------------")
        end

        Trigger={}
        Trigger[index]=0
        thv_line={}
        thv_line[index]=0

        gda_108={}
        gda_108[index]=0
        gda_112={}
        gda_112[index]=0
        gda_116={}
        gda_116[index]=0
        gda_120={}
        gda_120[index]=0
        gda_124={}
        gda_124[index]=0
        gda_128={}
        gda_128[index]=0

        ATR = {}
        ATR[index] = 0
        trend = {}
        trend[index] = 1
        calcAlgoValue = {}
        calcAlgoValue[index] = 0
        calcChartResults = {}
        calcChartResults[index] = {}

        return calcAlgoValue, trend, calcChartResults
    end

    Trigger[index] = Trigger[index-1]
    thv_line[index] = thv_line[index-1]

    gda_108[index] = gda_108[index-1]
    gda_112[index] = gda_112[index-1]
    gda_116[index] = gda_116[index-1]
    gda_120[index] = gda_120[index-1]
    gda_124[index] = gda_124[index-1]
    gda_128[index] = gda_128[index-1]

    ATR[index] = ATR[index-1]
    calcAlgoValue[index] = calcAlgoValue[index-1]
    trend[index] = trend[index-1]
    calcChartResults[index] = calcChartResults[index-1]

    if index<(periodATR+beginIndexToCalc) then
        ATR[index] = 0
    elseif index==(periodATR+beginIndexToCalc) then
        local sum=0
        for i = 1, periodATR do
            sum = sum + dValue(i)
        end
        ATR[index]=sum / periodATR
    elseif index>(periodATR+beginIndexToCalc) then
        ATR[index]=(ATR[index-1] * (periodATR-1) + dValue(index)) / periodATR
    end

    if index <= beginIndexToCalc + (math.max(period, periodATR) + shift + 1) or index > endIndexToCalc then
        return calcAlgoValue, trend, calcChartResults
    end

    if DS:C(index) ~= nil then

		local previous = index-1
		if DS:C(previous) == nil then
			previous = FindExistCandle(previous)
		end

        gda_108[index] = gd_172 * DS:C(index) + gd_180 * (gda_108[previous])
		gda_112[index] = gd_172 * (gda_108[index]) + gd_180 * (gda_112[previous])
		gda_116[index] = gd_172 * (gda_112[index]) + gd_180 * (gda_116[previous])
		gda_120[index] = gd_172 * (gda_116[index]) + gd_180 * (gda_120[previous])
		gda_124[index] = gd_172 * (gda_120[index]) + gd_180 * (gda_124[previous])
		gda_128[index] = gd_172 * (gda_124[index]) + gd_180 * (gda_128[previous])
		thv_line[index] = gd_132 * (gda_128[index]) + gd_140 * (gda_124[index]) + gd_148 * (gda_120[index]) + gd_156 * (gda_116[index])

        local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5
        local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5
        Trigger[index] = 2.0*thv_line[index]-(thv_line[index-shift] or 0)

        local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5
        local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5

        local isBuy  = trend[index] <= 0 and thv_line[index] > thv_line[index-1] and Trigger[index] > thv_line[index]
        local isSell = trend[index] >= 0 and thv_line[index] < thv_line[index-1] and Trigger[index] < thv_line[index]

        if isBuy then
            trend[index] = 1
        end
        if isSell then
            trend[index] = -1
        end
        --myLog("index "..tostring(index)..' - '..toYYYYMMDDHHMMSS(DS:T(index))..", O "..tostring(DS:O(index))..", thv_line "..tostring(thv_line[index])..", Trigger "..tostring(Trigger[index])..", trend "..tostring(trend[index]))

    end

    calcAlgoValue[index] = DS:C(index)
    calcChartResults[index] = {thv_line[index], Trigger[index]}

    return calcAlgoValue, trend, calcChartResults

end

local newIndex = #presets+1
presets[newIndex] =
{
    Name                    = "THV M3",
    NAME_OF_STRATEGY        = 'THV',
    SEC_CODE                = 'SBER',
    CLASS_CODE              = 'QJSIM',
    ACCOUNT                 = 'NL0011100043',
    CLIENT_CODE             = '11056',
    LIMIT_KIND              = 0,            -- 0 - Т0, 1 - Т1, 2 - Т2
    QTY_LOTS                = 1,            -- количество для торговли
    OFFSET                  = 2,            -- (ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
    SPREAD                  = 10,           -- Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
    ChartId                 = "GRAPH_SI",   -- индентификатор графика, куда выводить метки сделок и данные алгоритма.
    SetStop                 = true,         -- выставлять ли стоп заявки
    STOP_LOSS               = 60,           -- Размер СТОП-ЛОССА в пунктах (в рублях)
    TAKE_PROFIT             = 95,           -- Размер ТЕЙК-ПРОФИТА в пунктах (в рублях)
    TRAILING_SIZE           = 0,            -- Размер выхода в плюс в пунктах (в рублях), после которого активируется трейлинг
    TRAILING_SIZE_STEP      = 1,            -- Размер шага трейлинга в пунктах (в рублях)
    kATR                    = 0.6,          -- коэффициент ATR для расчета стоп-лосса
    periodATR               = 10,           -- период ATR для расчета стоп-лосса
    CloseSLbeforeClearing   = false,        -- снимать ли стоп заявки перед клирингом
    fixedstop               = true,         -- STOPLOSS не рассчитывать по алгоритму, а брать фиксированным из настроек
    isLong                  = true,         -- доступен лонг
    isShort                 = true,         -- доступен шорт
    trackManualDeals        = true,         -- учитывать ручные сделки не из интерфейса робота,
    maxStop                 = 85,           -- максимально допустимый стоп в пунктах
    reopenDealMaxStop       = 75,           -- если сделка переоткрыта после стопа, то максимальный стоп
    stopShiftIndexWait      = 17,           -- если цена не двигается (на величину стопа), то пересчитать стоп после стольких баров
    shiftStop               = true,         -- сдвигать стоп (трейил) на величину STOP_LOSS
    shiftProfit             = false,        -- сдвигать профит (трейил) на величину STOP_LOSS/2
    reopenPosAfterStop      = 7,            -- если выбило по стопу заявке, то попытаться переоткрыть сделку, после стольких баров
    INTERVAL                = INTERVAL_M3,  -- Таймфрейм графика (для построения скользящих)
    testSizeBars            = 3240,         -- размер окна оптимизации стратегии
    autoReoptimize          = false,        -- надо ли включать оптимизацию перед вечерним клирингом
    autoClosePosition       = true,         -- надо ли автоматически закрывать позиции перед вечерним клирингом
    calculateAlgo           = THV,
    iterateAlgo             = iterateTHV,
    initAlgo                = initTHV,
    settingsAlgo =
    {
        period    = 22,
        shift = 35,
        koef = 1.8
    }
}

--Куда поместить кнопку выбора настройки
presets[newIndex].interface_line = 3
presets[newIndex].interface_col = 2

--Какие значения настроек надо вывести в интерфейс, в указанные места
--Описание полей интерфейса
presets[newIndex].fields = {}
presets[newIndex].fields['period']      = {caption = 'period'       , caption_line = 4, caption_col = 1 , val_line = 5, val_col = 1, base_color = nil}
presets[newIndex].fields['shift']       = {caption = 'shift'        , caption_line = 4, caption_col = 2 , val_line = 5, val_col = 2, base_color = nil}
presets[newIndex].fields['koef']        = {caption = 'koef'         , caption_line = 4, caption_col = 3 , val_line = 5, val_col = 3, base_color = nil}
presets[newIndex].fields['periodATR']   = {caption = 'periodATR'    , caption_line = 4, caption_col = 4 , val_line = 5, val_col = 4, base_color = nil}
presets[newIndex].fields['kATR']        = {caption = 'kATR'         , caption_line = 6, caption_col = 1 , val_line = 7, val_col = 1, base_color = nil}

-- возможность редактирования полей настройки
presets[newIndex].edit_fields = {}
presets[newIndex].edit_fields['period']      = true
presets[newIndex].edit_fields['koef']        = true
presets[newIndex].edit_fields['shift']       = true
presets[newIndex].edit_fields['periodATR']   = true
presets[newIndex].edit_fields['kATR']        = true
