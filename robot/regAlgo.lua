--- Алгоритм
function initReg()
    trend=nil
    ATR = nil
    calcAlgoValue = nil     --      Возвращаемая таблица
    calcChartResults = nil     --      Возвращаемая таблица
    fx_buffer = nil         --      Линия регрессии
    sql_buffer = nil    --      +Сигма
    sqh_buffer = nil    --      -Сигма
    sx = nil
    TEMA=nil
	cache_TEMA1=nil
	cache_TEMA2=nil
	cache_TEMA3=nil
end

-------------------------------------
--Оптимизация
function iterateReg()

    param1Min = 8
    param1Max = 38
    param1Step = 1

    param2Min = 1
    param2Max = 3
    param2Step = 1

    param3Min = 1
    param3Max = 38
    param3Step = 1

    if ROBOT_STATE == 'РЕОПТИМИЗАЦИЯ' then
        param1Min = math.max(param1Min, Settings.period-10)
        param1Max = math.min(param1Max, Settings.period+10)
    end

    local settingsTable = {}
    local allCount = 0

    for param1 = param1Min, param1Max, param1Step do
        for param2 = param2Min, param2Max, param2Step do
            for param3 = param3Min, math.ceil(0.8*param1), param3Step do
            --for param3 = param3Min, param3Max, param3Step do

                allCount = allCount + 1

                settingsTable[allCount] = {
                    period    = param1,
                    degree = param2, -- 1 -линейная, 2 - параболическая, - 3 степени
                    shift = param3,
                    kstd = 3 --отклонение сигма
                    }

            end
        end
    end

    iterateAlgorithm(settingsTable)

end

function iReg(index, Fsettings)

    local period = Fsettings.period or 182
    local degree = Fsettings.degree or 1
    local kstd = Fsettings.kstd or 3
    local shift = Fsettings.shift or 2

    local indexToCalc = 1000
    indexToCalc = Fsettings.indexToCalc or indexToCalc
    local beginIndexToCalc = Fsettings.beginIndexToCalc or math.max(1, DS:Size() - indexToCalc)

    if index == nil then index = 1 end

    period = math.min(period, DS:Size())

    --myLog("period "..tostring(period)..", degree "..tostring(degree)..", kstd "..tostring(kstd)..", shift "..tostring(shift))

    local p = 0
    local n = 0
    local f = 0
    local qq = 0
    local mm = 0
    local tt = 0
    local ii = 0
    local jj = 0
    local kk = 0
    local ll = 0
    local nn = 0
    local sq = 0
    local i0 = 0

    local mi = 0
    local ai={{1,2,3,4}, {1,2,3,4}, {1,2,3,4}, {1,2,3,4}}
    local b={}
    local x={}

    p = period
    nn = degree+1
    local kawg = 2/(period+1)

    if index == beginIndexToCalc then
        ATR = {}
        ATR[index] = 0

        sql_buffer = {}
        sqh_buffer = {}
        fx_buffer = {}

        sql_buffer[index]= 0
        sqh_buffer[index]= 0
        fx_buffer[index]= 0

        TEMA = {}
        TEMA[index] = 0
        cache_TEMA1={}
        cache_TEMA2={}
        cache_TEMA3={}
        cache_TEMA1[index]= 0
        cache_TEMA2[index]= 0
        cache_TEMA3[index]= 0

        calcAlgoValue = {}
        calcAlgoValue[index]= 0
        trend = {}
        trend[index] = 1

        calcChartResults = {}
        calcChartResults[index]= {nil,nil}

        --- sx
        sx={}
        sx[1] = p+1

        for mi=1, nn*2-2 do
            sum=0
            for n=i0, i0+p do
                sum = sum + math.pow(n,mi)
            end
            sx[mi+1]=sum
        end

        return calcAlgoValue
    end

    sql_buffer[index] = sql_buffer[index-1]
    sqh_buffer[index] = sqh_buffer[index-1]
    fx_buffer = {}
    TEMA[index] = TEMA[index-1]
    cache_TEMA1[index] = cache_TEMA1[index-1]
    cache_TEMA2[index] = cache_TEMA2[index-1]
    cache_TEMA3[index] = cache_TEMA3[index-1]

    ATR[index] = ATR[index-1]
    calcAlgoValue[index] = calcAlgoValue[index-1]
    trend[index] = trend[index-1]
    calcChartResults[index] = calcChartResults[index-1]

    if index<(period+beginIndexToCalc) then
        ATR[index] = 0
    elseif index==(period+beginIndexToCalc) then
        local sum=0
        for i = 1, period do
            sum = sum + dValue(i)
        end
        ATR[index]=sum / period
    elseif index>(period+beginIndexToCalc) then
        ATR[index]=(ATR[index-1] * (period-1) + dValue(index)) / period
        --ATR[index] = kawg*dValue(index)+(1-kawg)*ATR[index-1]
        --myLog('ATR '..tostring(ATR[index]))
    end

    if index < beginIndexToCalc + (period + shift + 1) then
        return calcAlgoValue
    end

    --- syx
    for mi=1, nn do
        sum = 0
        for n=i0, i0+p do
            if DS:C(index+n-period) ~= nil then
                if mi==1 then
                   sum = sum + DS:C(index+n-period)
                else
                   sum = sum + DS:C(index+n-period)*math.pow(n,mi-1)
                end
            end
        end
        b[mi]=sum
    end

    --- Matrix
    for jj=1, nn do
        for ii=1, nn do
            kk=ii+jj-1
            ai[ii][jj]=sx[kk]
        end
    end

    --- Gauss
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
            return calcAlgoValue
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

     x[nn]=b[nn]/ai[nn][nn]

    for ii=nn-1, 1, -1 do
        tt=0
        for jj=1, nn-ii do
            tt=tt+ai[ii][ii+jj]*x[ii+jj]
            x[ii]=(1/ai[ii][ii])*(b[ii]-tt)
        end
    end

    ---
    --myLog("index "..tostring(index))
    --for n=i0, i0+p do
        local n = p
        sum=0
        for kk=1, degree do
            sum = sum + x[kk+1]*math.pow(n,kk)
        end
        fx_buffer[n]=x[1]+sum
        --myLog("fx n"..tostring(n).." "..tostring(fx_buffer[n]))
    --end

    --- Std
    --sq=0.0
    --for n=i0, i0+p do
    --    if DS:C(index+n-period) ~= nil then
    --        sq = sq + math.pow(DS:C(index+n-period)-fx_buffer[n],2)
    --    end
    --end
    --
    --sq = math.sqrt(sq/(p-1))*kstd
    --
    --for n=i0, i0+p do
    --    sqh_buffer[index+n-period]=round(fx_buffer[n]+sq, 5)
    --    sql_buffer[index+n-period]=round(fx_buffer[n]-sq, 5)
    --end

    --if calcAlgoValue[index] < DS:C(index) and calcAlgoValue[index-1] >= DS:C(index-1) then
    --    trend[index] = 1
    --end
    --if calcAlgoValue[index] > DS:C(index) and calcAlgoValue[index-1] <= DS:C(index-1) then
    --    trend[index] = -1
    --end

    --local val = dValue(index,'C')
	--local kTEMA = 2/(period+1)
    --cache_TEMA1[index]=kTEMA*val+(1-kTEMA)*cache_TEMA1[index-1]
	--cache_TEMA2[index]=kTEMA*cache_TEMA1[index]+(1-kTEMA)*cache_TEMA2[index-1]
	--cache_TEMA3[index]=kTEMA*cache_TEMA2[index]+(1-kTEMA)*cache_TEMA3[index-1]
    --
    --TEMA[index] = 3*cache_TEMA1[index] - 3*cache_TEMA2[index] + cache_TEMA3[index]

    calcAlgoValue[index] = round(fx_buffer[period], 5)
    --myLog("index "..tostring(index).." shift "..tostring(shift).." algoLine "..tostring(calcAlgoValue[index])..", algoLine-shift "..tostring(calcAlgoValue[index-shift]))

    local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5
    local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5

    local isBuy = (not isUpPinBar and calcAlgoValue[index] > calcAlgoValue[index-shift] and calcAlgoValue[index-1] <= calcAlgoValue[index-shift-1])
    --local isBuy = (not isUpPinBar and calcAlgoValue[index] > TEMA[index-shift] and calcAlgoValue[index-1] <= TEMA[index-shift-1])
        --or (trend[index] == -1 and calcAlgoValue[index] > calcAlgoValue[index-shift] and calcAlgoValue[index-1] > calcAlgoValue[index-shift])
    local isSell = (not isLowPinBar and calcAlgoValue[index] < calcAlgoValue[index-shift] and calcAlgoValue[index-1] >= calcAlgoValue[index-shift-1])
    --local isSell = (not isLowPinBar and calcAlgoValue[index] < TEMA[index-shift] and calcAlgoValue[index-1] >= TEMA[index-shift-1])
         --or (trend[index] == 1 and calcAlgoValue[index] < calcAlgoValue[index-shift] and calcAlgoValue[index-1] < calcAlgoValue[index-shift])

    if isBuy then
        trend[index] = 1
    end
    if isSell then
        trend[index] = -1
    end

    calcChartResults[index] = {calcAlgoValue[index], calcAlgoValue[index-shift-1]}

    if not optimizationInProgress then
        local roundAlgoVal = round(calcAlgoValue[index], scale)
        SetCell(t_id, 2, 1, tostring(roundAlgoVal), roundAlgoVal)
    end

    return calcAlgoValue

end

local newIndex = #presets+1
presets[newIndex] =
{
    Name    = "reg M3",
    NAME_OF_STRATEGY = 'iReg',
    SEC_CODE                = 'SBER',
    CLASS_CODE              = 'QJSIM',
    ACCOUNT                 = 'NL0011100043',
    CLIENT_CODE             = '11056',
    QTY_LOTS = 1, -- количество для торговли
    OFFSET = 2, --(ОТСТУП)Если цена достигла Тейк-профита и идет дальше в прибыль
    SPREAD = 10, --Когда сработает Тейк-профит, выставится заявка по цене хуже текущей на пунктов,
    ChartId = "Sheet11",
    STOP_LOSS               = 45,            -- Размер СТОП-ЛОССА
    TAKE_PROFIT             = 140,           -- Размер ТЕЙК-ПРОФИТА
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
    testSizeBars = 3240, --270
    autoReoptimize = false, -- надо ли включать оптимизацию перед вечерним клирингом
    autoClosePosition = false, -- надо ли автоматически закрывать позиции перед вечерним клирингом
    calculateAlgo = iReg,
    iterateAlgo = iterateReg,
    initAlgo = initReg,
    settingsAlgo =
    {
        period    = 21,
        degree = 3, -- 1 -линейная, 2 - параболическая, - 3 степени
        shift = 4,
        kstd = 3 --отклонение сигма
    }
}


--Куда поместить кнопку выбора настройки
presets[newIndex].interface_line = 3
presets[newIndex].interface_col = 1

--Какие значения настроек надо вывести в интерфейс, в указанные места
--Описание полей интерфейса
presets[newIndex].fields = {}
presets[newIndex].fields['period']      = {caption = 'period'  , caption_line = 4, caption_col = 1 , val_line = 5, val_col = 1, base_color = nil}
presets[newIndex].fields['shift']       = {caption = 'shift'   , caption_line = 4, caption_col = 2 , val_line = 5, val_col = 2, base_color = nil}
presets[newIndex].fields['degree']      = {caption = 'degree'  , caption_line = 4, caption_col = 3 , val_line = 5, val_col = 3, base_color = nil}
presets[newIndex].fields['kstd']        = {caption = 'kstd'    , caption_line = 4, caption_col = 4 , val_line = 5, val_col = 4, base_color = nil}

-- возможность редактирования полей настройки
presets[newIndex].edit_fields = {}
presets[newIndex].edit_fields['period']       = true
presets[newIndex].edit_fields['degree']       = true
presets[newIndex].edit_fields['shift']        = true
presets[newIndex].edit_fields['kstd']         = true
