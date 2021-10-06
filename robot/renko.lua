_G.load   = _G.loadfile or _G.load
local maLib = load(_G.getWorkingFolder().."\\Luaindicators\\maLib.lua")()

RenkoSettings = {
    period = 9,
    k = 3,
    data_type = 0,
    Size = 0,
    fixedstop = 0,
    SLSec = 0,
    TPSec = 0
}

--- Алгоритм
function initRenko()
    ATR = nil
    trend=nil
    calcAlgoValue = nil     --      Возвращаемая таблица
    calcChartResults = nil     --      Возвращаемая таблица

	fRenko=nil
end

function iterateRenko(iSec, cell)

    iterateSLTP = false
    calcATR     = true
    kATR        = 1.5

    param1Min = 3
    param1Max = 48
    param1Step = 1

    param2Min = 1
    param2Max = 8
    param2Step = 0.2

    param3Min = 0
    param3Max = 1
    param3Step = 1

    local settingsTable = {}
    local allCount = 0

    for param1 = param1Min, param1Max, param1Step do
        for param2 = param2Min, param2Max, param2Step do
            for param3 = param3Min, param3Max, param3Step do
                allCount = allCount + 1

                    settingsTable[allCount] = {
                        period    = param1,
                        k         = param2,
                        data_type = param3
                    }
            end
        end
    end

    iterateAlgorithm(iSec, cell, settingsTable)

end

local math_pow      = math.pow

local function F_RENKO(settings, ds)

    local fATR
    local fMA
    local Data
    local Renko_UP
    local Renko_DW

    local recalc_index
    local l_index
    local r_trend
    local brick_bars    = 0
    local Brick         = {}

    settings                = (settings or {})
    local br_size           = (settings.br_size or 0)
    local period            = (settings.period or 24)
    local data_type         = (settings.data_type or 0)
    local recalc_brick      = (settings.recalc_brick or 1)
    local min_recalc_brick  = (settings.min_recalc_brick or 0)
    local shift_limit       = (settings.shift_limit or 1)
    local std_ma_method     = (settings.std_ma_method or 'SMA')
    local brickType         = (settings.brickType or 'Std')
    local k                 = (brickType ~='Fix' or br_size == 0) and (settings.k or 1) or 1

    myLog("--------------------------------------------------")
    myLog("Показатель period "..tostring(period))
    myLog("Показатель k "..tostring(k))
    myLog("Показатель data_type "..tostring((settings.data_type or 0)))
    myLog("Показатель recalc_brick "..tostring((settings.recalc_brick or 1)))
    myLog("Показатель shift_limit "..tostring((settings.shift_limit or 1)))
    myLog("Показатель brickType "..tostring((settings.brickType or 'Std')))
    myLog("--------------------------------------------------")

    return function(index)

        if not maLib then return Renko_UP, Renko_DW, r_trend, Brick end

        if Renko_UP == nil or index == 1 then
            Renko_UP        = {}
            Renko_UP[index] = maLib.Value(index, 'High', ds) or 0
            Renko_DW        = {}
            Renko_DW[index] = maLib.Value(index, 'Low', ds) or 0
            if brickType ~='Fix' or br_size == 0 then
                Brick[index]    = k*(Renko_UP[index] - Renko_DW[index])
                if brickType == 'ATR' then
                    fATR            = maLib.new({method = 'ATR', period = period}, ds)
                    fATR(index)
                else
                    Data            = {}
                    Data[index]     = maLib.Value(index, 'Close', ds) or 0
                    fMA             = maLib.new({period = period, method = std_ma_method, data_type = 'Any'}, Data)
                    fMA(index)
                end
            else
                Brick[index]    = br_size/math_pow(10, (SCALE or 0))
            end
            l_index         = index
            r_trend           = {}
            r_trend[index]    = 0
            return Renko_UP, Renko_DW, r_trend, Brick
        end

        if brickType == 'Std' then
            Data[index]     = Data[index-1]
        end
        Brick[index]    = Brick[index-1]
        Renko_UP[index] = Renko_UP[index-1]
        Renko_DW[index] = Renko_DW[index-1]
        r_trend[index]  = r_trend[index-1]

        local atr       = brickType == 'ATR' and fATR(index)[index] or Brick[index-1]

        if DS:C(index) == nil then
            return Renko_UP, Renko_DW, r_trend, Brick
        end

        local close_h = data_type == 0 and maLib.Value(index, 'Close', ds) or maLib.Value(index, 'High', ds)
        local close_l = data_type == 0 and maLib.Value(index, 'Close', ds) or maLib.Value(index, 'Low', ds)
        local close   = maLib.Value(index, 'Close', ds) > maLib.Value(index, 'Open', ds) and close_h or close_l

        if brickType == 'Std' then
            Data[index] = maLib.Value(index, 'M', ds)
            atr         = maLib.Sigma(Data, fMA(index)[index] or close, index - period + 1, index)--*math.sqrt(period)
        end
        if l_index ~= index then
            brick_bars = brick_bars + 1
            if brick_bars > period then
                recalc_index = index
            end
        end
        if recalc_brick == 1 and recalc_index == index then --and ((r_trend[index] == -1 and close <= Renko_UP[index-1]) or (r_trend[index] == 1 and close >= Renko_DW[index-1]))
            brick_bars = 1
            Brick[index] = min_recalc_brick == 1 and math.min(k*atr, Brick[index]) or k*atr
            if shift_limit == 1 then
                if r_trend[index] == -1 then Renko_UP[index] = math.min(Renko_UP[index-1], Renko_DW[index-1] + Brick[index]) end
                if r_trend[index] == 1  then Renko_DW[index] = math.max(Renko_DW[index-1], Renko_UP[index-1] - Brick[index]) end
            end
        end
        l_index = index
        -- myLog(tostring(index)..' '..os.date('%Y.%m.%d %H:%M', os.time(ds:T(index)))..' '..'atr'..' '..atr..' '..'Brick'..' '..Brick[index]..' '..'close'..' '..close..' '..'up'..' '..Renko_UP[index]..' '..close - Renko_UP[index]..' '..'dw'..' '..Renko_DW[index]..' '..Renko_DW[index] - close)
        if close > Renko_UP[index-1] + Brick[index-1] then
            -- myLog('new brick', os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), 'Brick', k*atr, 'close', close, 'up', Renko_UP[index], 'dw', Renko_DW[index])
            Renko_UP[index] = Renko_UP[index] + (Brick[index-1] == 0  and 0 or math.floor((close - Renko_UP[index-1])/Brick[index-1])*Brick[index-1])
            Brick[index]    = k*atr
            -- Renko_DW[index] = Renko_UP[index] - Brick[index]
            Renko_DW[index] = math.max(Renko_UP[index-1], Renko_UP[index] - Brick[index])
            r_trend[index]  = 1
            -- brick_bars = 1
		end
		if close < Renko_DW[index-1] - Brick[index-1] then
            -- myLog('new brick', os.date('%Y.%m.%d %H:%M', os.time(_G.T(index))), 'Brick', k*atr, 'close', close, 'up', Renko_UP[index], 'dw', Renko_DW[index])
            Renko_DW[index] = Renko_DW[index] - (Brick[index-1] == 0  and 0 or math.floor((Renko_DW[index-1] - close)/Brick[index-1])*Brick[index-1])
            Brick[index]    = k*atr
            -- Renko_UP[index] = Renko_DW[index] + Brick[index]
            Renko_UP[index] = math.min(Renko_DW[index-1], Renko_DW[index] + Brick[index])
            r_trend[index]  = -1
            -- brick_bars = 1
        end

        return Renko_UP, Renko_DW, r_trend, Brick
     end
end

function Renko(index, Fsettings)

    local period = (Fsettings.period or 24)
    local k      = (Fsettings.k or 3)

    local indexToCalc = 1000
    indexToCalc = Fsettings.indexToCalc or indexToCalc
    local beginIndexToCalc = Fsettings.beginIndexToCalc or math.max(1, DS:Size() - indexToCalc)

    if index == nil then index = 1 end

    if index == 1 then

        myLog('index '..tostring(index)..' '..os.date('%Y.%m.%d %H:%M', os.time(DS:T(index))))
        local settings             = {}
        settings.br_size           = (Fsettings.br_size or 0)
        settings.period            = period
        settings.k                 = k
        settings.data_type         = (Fsettings.data_type or 0)
        settings.recalc_brick      = (Fsettings.recalc_brick or 1)
        settings.min_recalc_brick  = (Fsettings.min_recalc_brick or 0)
        settings.shift_limit       = (Fsettings.shift_limit or 1)
        settings.std_ma_method     = (Fsettings.std_ma_method or 'SMA')
        settings.brickType         = (Fsettings.std_ma_method or 'Std')
        fRenko                     = F_RENKO(settings, DS)
        fRenko(index)

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


    ATR[index] = ATR[index-1]
    calcAlgoValue[index] = calcAlgoValue[index-1]
    trend[index] = trend[index-1]
    calcChartResults[index] = calcChartResults[index-1]

    local up, dw, r_trend = fRenko(index)
    if DS:C(index) == nil then
        return calcAlgoValue, trend, calcChartResults
    end

    if DS:C(index) ~= nil then

        if (index - beginIndexToCalc + 1) <= period then
            return calcAlgoValue, trend, calcChartResults
        end
        trend[index] = r_trend[index]
        ATR[index] = up[index]-dw[index]
        if trend[index] >= 0 then
            calcAlgoValue[index] = up[index]
        else
            calcAlgoValue[index] = dw[index]
        end
    end

    calcChartResults[index] = {up[index], dw[index]}

    return calcAlgoValue, trend, calcChartResults

end

local newIndex = #presets+1
presets[newIndex] =
{
    Name                    = "Rnk M3",
    NAME_OF_STRATEGY        = 'RNK',
    SEC_CODE                = 'SRZ0',
    CLASS_CODE              = 'SPBFUT',
    ACCOUNT                 = 'A701XS7',
    CLIENT_CODE             = 'A701XS7',
    LIMIT_KIND              = 0,            -- 0 - Т0, 1 - Т1, 2 - Т2
    QTY_LOTS                = 1,            -- количество для торговли
    OFFSET                  = 2,            -- (ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
    SPREAD                  = 10,           -- Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
    ChartId                 = "testGraphFUT",   -- индентификатор графика, куда выводить метки сделок и данные алгоритма.
    STOP_LOSS               = 79, --106          -- Размер СТОП-ЛОССА в пунктах (в рублях)
    TAKE_PROFIT             = 286, --270         -- Размер ТЕЙК-ПРОФИТА в пунктах (в рублях)
    TRAILING_SIZE           = 85,            -- Размер выхода в плюс в пунктах (в рублях), после которого активируется трейлинг
    TRAILING_SIZE_STEP      = 5,            -- Размер шага трейлинга в пунктах (в рублях)
    CLOSE_BAR_SIGNAL        = 1,            -- Сигналы на вход поступают: 1 - по закрытию бара; 0 -- в произволное время
    kATR                    = 1.1,          -- коэффициент ATR для расчета стоп-лосса
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
    shiftProfit             = false,         -- сдвигать профит (трейил) на величину STOP_LOSS/2
    reopenPosAfterStop      = 7,           -- если выбило по стопу заявке, то попытаться переоткрыть сделку, после стольких баров
    INTERVAL                = INTERVAL_M3,  -- Таймфрейм графика (для построения скользящих)
    testSizeBars            = 500000,       -- размер окна оптимизации стратегии
    autoReoptimize          = false,        -- надо ли включать оптимизацию перед вечерним клирингом
    autoClosePosition       = true,         -- надо ли автоматически закрывать позиции перед вечерним клирингом
    calculateAlgo           = Renko,
    iterateAlgo             = iterateRenko,
    initAlgo                = initRenko,
    settingsAlgo =
    {
        period      = 49, --54
        k           = 2.2, --3.5
        data_type   = 1,
        brickType   = 'Std'
    }
}

--Куда поместить кнопку выбора настройки
presets[newIndex].interface_line = 3
presets[newIndex].interface_col = 4

--Какие значения настроек надо вывести в интерфейс, в указанные места
--Описание полей интерфейса
presets[newIndex].fields = {}
presets[newIndex].fields['period']      = {caption = 'period'       , caption_line = 4, caption_col = 1 , val_line = 5, val_col = 1, base_color = nil}
presets[newIndex].fields['k']           = {caption = 'k'            , caption_line = 4, caption_col = 2 , val_line = 5, val_col = 2, base_color = nil}
presets[newIndex].fields['kATR']        = {caption = 'kATR'         , caption_line = 4, caption_col = 3 , val_line = 5, val_col = 3, base_color = nil}

-- возможность редактирования полей настройки
presets[newIndex].edit_fields = {}
presets[newIndex].edit_fields['period']      = true
presets[newIndex].edit_fields['k']           = true
presets[newIndex].edit_fields['kATR']        = true