--- Алгоритм
function initMA()
    calcATR             = true
    ATR                 = {}
    trend               = {}
    calcAlgoValue       = {}
    dVal                = {}
    calcChartResults    = {}
	EMA                 = {}
	EMA2                = {}
end

function iterateMA()

    iterateSLTP = true

    local param1Min = 10
    local param1Max = 25
    local param1Step = 1

    local param2Min = 11
    local param2Max = 40
    local param2Step = 1

    local param3Min   = 9
    local param3Max   = 12
    local param3Step  = 1

    local param4Min   = 0.6
    local param4Max   = 0.75
    local param4Step  = 0.05

    if fixedstop then
        param3Min   = 10
        param3Max   = 10
        param3Step  = 1

        param4Min   = 0.65
        param4Max   = 0.65
        param4Step  = 0.05
    end

    local settingsTable = {}
    local allCount = 0

    for param1 = param1Min, param1Max, param1Step do

        _param2Min = math.max(math.ceil(param1+1), param2Min)
        for param2 = _param2Min, param2Max, param2Step do
            for param3 = param3Min, param3Max, param3Step do
                for param4 = param4Min, param4Max, param4Step do
                    allCount = allCount + 1
                    settingsTable[allCount] = {
                        period    = param1,
                        period2 = param2,
                        periodATR = param3,
                        kATR = param4,
                        Size = Size
                        }
                end
            end
        end
    end

    myLog('iterateMA lines: '..tostring(allCount))

    iterateAlgorithm(settingsTable)

end

function MA(index, Fsettings)

    local period = Fsettings.period or 21
    local period2 = Fsettings.period2 or 38
    local periodATR = Fsettings.periodATR or 10
    kATR = Fsettings.kATR or kATR

    local indexToCalc = 1000
    indexToCalc = Fsettings.indexToCalc or indexToCalc
    local beginIndexToCalc = Fsettings.beginIndexToCalc or math.max(1, DS:Size() - indexToCalc)
    local endIndexToCalc = Fsettings.endIndex or DS:Size()

    if index == nil then index = 1 end

    if index == beginIndexToCalc then

        if not ROBOT_STATE:find('ОПТИМИЗАЦИЯ') then
            myLog("--------------------------------------------------")
            myLog("Показатель Period "..tostring(period))
            myLog("Показатель Period2 "..tostring(period2))
            myLog("Показатель periodATR "..tostring(periodATR))
            myLog("Показатель kATR "..tostring(kATR))
            myLog("--------------------------------------------------")
        end

        EMA = {}
        EMA[index] = 1
        EMA2 = {}
        EMA2[index] = 1

        ATR = {}
        ATR[index] = 0

        -- В CLOSE_BAR_SIGNAL = 0 режиме trend имеет всего два элемента trend.current - текущее значение и trend.last - прошлое значение
        trend = {}
        trend.current = 0
        trend.last = 0
        calcAlgoValue = {}
        calcAlgoValue[index] = 0

        calcChartResults = {}
        calcChartResults[index]= {nil,nil}

        return calcAlgoValue
    end

    EMA[index] = EMA[index-1]
    EMA2[index] = EMA2[index-1]

    ATR[index] = ATR[index-1]
    calcAlgoValue[index] = calcAlgoValue[index-1]
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

    if index <= beginIndexToCalc + (math.max(period, periodATR) + 1) or index > endIndexToCalc then
        return calcAlgoValue, trend, calcChartResults
    end

    local k = 2/(period+1)
    local k2 = 2/(period2+1)

    EMA[index] = (DS:C(index)+DS:O(index))/2
    EMA2[index] = (DS:C(index)+DS:O(index))/2

    if DS:C(index) ~= nil then

        local val = dValue(index,'C')

        EMA[index]=round(k*val+(1-k)*EMA[index-1], 5)
        EMA2[index]=round(k2*val+(1-k2)*EMA2[index-1], 5)

        --Простое пересечение скользящих, направелнных в одну сторону
        local isBuy  = trend.current <= 0 and EMA[index] > EMA[index-1] and EMA2[index] > EMA2[index-1] and EMA[index]>EMA2[index] and EMA[index-1]<=EMA2[index-1]
        local isSell = trend.current >= 0 and EMA[index] < EMA[index-1] and EMA2[index] < EMA2[index-1] and EMA[index]<EMA2[index] and EMA[index-1]>=EMA2[index-1]

        if isBuy then
            trend.last = trend.current
            trend.current = 1
        end
        if isSell then
            trend.last = trend.current
            trend.current = -1
        end

        calcAlgoValue[index] = DS:C(index)
    end

    calcChartResults[index] = {EMA[index], EMA2[index]}
    --myLog("index "..tostring(index)..", EMA "..tostring(EMA[index])..", EMA2 "..tostring(EMA2[index])..", trend: "..tostring(trend.current)..", past trend: "..tostring(trend.last))

    return calcAlgoValue, trend, calcChartResults

end

local newIndex = #presets+1
presets[newIndex] =
{
    Name                    = "sEMA M3",
    NAME_OF_STRATEGY        = 'sEMA',
    SEC_CODE                = 'SBER',
    CLASS_CODE              = 'QJSIM',
    ACCOUNT                 = 'NL0011100043',
    CLIENT_CODE             = '11056',
    LIMIT_KIND              = 0,            -- 0 - Т0, 1 - Т1, 2 - Т2
    QTY_LOTS                = 1,            -- количество для торговли
    OFFSET                  = 2,            -- (ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
    SPREAD                  = 10,           -- Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
    ChartId                 = "GRAPH_SI",   -- индентификатор графика, куда выводить метки сделок и данные алгоритма.
    STOP_LOSS               = 70,           -- Размер СТОП-ЛОССА в пунктах (в рублях)
    TAKE_PROFIT             = 180,          -- Размер ТЕЙК-ПРОФИТА в пунктах (в рублях)
    TRAILING_SIZE           = 0,            -- Размер выхода в плюс в пунктах (в рублях), после которого активируется трейлинг
    TRAILING_SIZE_STEP      = 1,            -- Размер шага трейлинга в пунктах (в рублях)
    CLOSE_BAR_SIGNAL        = 0,            -- Сигналы на вход поступают: 1 - по закрытию бара; 0 -- в произволное время
    kATR                    = 0.6,          -- коэффициент ATR для расчета стоп-лосса
    periodATR               = 12,           -- период ATR для расчета стоп-лосса
    SetStop                 = true,         -- выставлять ли стоп заявки
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
    calculateAlgo           = MA,
    iterateAlgo             = iterateMA,
    initAlgo                = initMA,
    settingsAlgo =
    {
        period    = 5,
        period2    = 9
    }
}

--Куда поместить кнопку выбора настройки
presets[newIndex].interface_line = 3
presets[newIndex].interface_col = 1

--Какие значения настроек надо вывести в интерфейс, в указанные места
--Описание полей интерфейса
presets[newIndex].fields = {}
presets[newIndex].fields['period']      = {caption = 'period'       , caption_line = 4, caption_col = 1 , val_line = 5, val_col = 1, base_color = nil}
presets[newIndex].fields['period2']     = {caption = 'period2'      , caption_line = 4, caption_col = 2 , val_line = 5, val_col = 2, base_color = nil}
presets[newIndex].fields['periodATR']   = {caption = 'periodATR'    , caption_line = 4, caption_col = 3 , val_line = 5, val_col = 3, base_color = nil}
presets[newIndex].fields['kATR']        = {caption = 'kATR'         , caption_line = 4, caption_col = 4 , val_line = 5, val_col = 4, base_color = nil}

-- возможность редактирования полей настройки
presets[newIndex].edit_fields = {}
presets[newIndex].edit_fields['period']      = true
presets[newIndex].edit_fields['period2']     = true
presets[newIndex].edit_fields['periodATR']   = true
presets[newIndex].edit_fields['kATR']        = true
