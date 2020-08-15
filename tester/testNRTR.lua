-------------------------

--NRTR
NRTRSettings = {
    period    = 0,
    Kv = 0,
    Switch = 0,
    barShift = 0,
	ATRfactor = 0,
    periodATR = 0,
    kATR = 0,
    Size = 0
}

function initStepNRTR()
    HA  = nil
    NRTR=nil
    smax1=nil
    smin1=nil
    cache_HPrice=nil
    cache_LPrice=nil
    cacheH=nil
    cacheL=nil
    trend=nil
    trend=nil
    calcChartResults=nil
    ATR=nil
    calcATR = true
end

function iterateNRTR(iSec, cell)

    iterateSLTP  = true

    param1Min = 15
    param1Max = 64
    param1Step = 1

    param2Min = 0.5
    param2Max = 2.8
    param2Step = 0.1

    param3Min = 0
    param3Max = 0
    param3Step = 1

    param4Min = 0.35
    param4Max = 0.95
    param4Step = 0.05

    param5Min = 16
    param5Max = 16
    param5Step = 1

    local allCount = 0
    local settingsTable = {}

    for param1 = param1Min, param1Max, param1Step do
        for param2 = param2Min, param2Max, param2Step do
            for param3 = param3Min, param3Max, param3Step do
                for param4 = param4Min, param4Max, param4Step do
                    for param5 = param5Min, param5Max, param5Step do

                        allCount = allCount + 1
                        settingsTable[allCount] = {
                            period    = param1,
                            Kv = param2,
                            Switch = param3,
                            barShift = 0,
                            ATRfactor = 0,
                            kATR = param4,
                            periodATR = param5,
                            StepSize = 0,
                            Percentage = 0,
                            Size = Size,
                            endIndex = endIndex
                        }
                    end
                end
            end
        end
    end

    myLog('settingsTable size '..tostring(#settingsTable))
    iterateAlgorithm(iSec, cell, settingsTable)

end

function stepNRTR(index, settings, DS)

    local period = settings.period or 29            -- perios
    local Kv = settings.Kv or 1                     -- miltiply
    local StepSize = settings.StepSize or 0         -- fox stepSize
    local ATRfactor = settings.ATRfactor or 0.15
    local barShift = settings.barShift or 0
    local Percentage = settings.Percentage or 0
    local Switch = settings.Switch or 1             --1 - HighLow, 2 - CloseClose
    local Size = settings.Size or 2000

    local periodATR = settings.periodATR or periodATR
    kATR = settings.kATR or 0.65

    local ratio=Percentage/100.0*SEC_PRICE_STEP
    local smax0 = 0
    local smin0 = 0

    local indexToCalc = 1000
    indexToCalc = settings.Size or indexToCalc
    local beginIndexToCalc = settings.beginIndexToCalc or math.max(1, settings.beginIndex - indexToCalc)
    local endIndexToCalc = settings.endIndex or DS:Size()

    if index == nil then index = 1 end

    local kawg = 2/(periodATR+1)

    if NRTR == nil then
        myLog("index "..tostring(index).." beginIndexToCalc "..tostring(beginIndexToCalc))
        --myLog("ѕоказатель Kv "..tostring(Kv))
        --myLog("ѕоказатель periodATR "..tostring(periodATR))
        --myLog("ѕоказатель ATRfactor "..tostring(ATRfactor))
        --myLog("ѕоказатель kATR "..tostring(kATR))
        --myLog("ѕоказатель StepSize "..tostring(StepSize))
        --myLog("ѕоказатель Switch "..tostring(Switch))
        --myLog("ѕоказатель barShift "..tostring(barShift))
        --myLog("--------------------------------------------------")

        HA = {}
        CalcHiekenAshi(index, DS)

        NRTR = {}
        NRTR[index] = 0
        emaATR = {}
        emaATR[index] = 0
        emaStep = {}
        emaStep[index] = 0
        smax1 = {}
        smin1 = {}
        smax1[index] = 0
        smin1[index] = 0

        cacheL = {}
        cacheL[index] = 0
        cacheH = {}
        cacheH[index] = 0
        cache_LPrice = {}
        cache_LPrice[index] = 0
        cache_HPrice = {}
        cache_HPrice[index] = 0

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

    HA[index] = {}
    HA[index].O = HA[index-1].O
    HA[index].C = HA[index-1].C
    HA[index].H = HA[index-1].H
    HA[index].L = HA[index-1].L

    CalcHiekenAshi(index, DS)

    NRTR[index] = NRTR[index-1]
    emaATR[index] = emaATR[index-1]
    smax1[index] = smax1[index-1]
    smin1[index] = smin1[index-1]
    trend[index] = trend[index-1]
    emaStep[index] = emaStep[index-1]

    cacheL[index] = cacheL[index-1]
    cacheH[index] = cacheH[index-1]
    cache_LPrice[index] = cache_LPrice[index-1]
    cache_HPrice[index] = cache_HPrice[index-1]

    calcAlgoValue[index] = calcAlgoValue[index-1]
    trend[index] = trend[index-1]
    calcChartResults[index] = calcChartResults[index-1]

    ATR[index] = ATR[index-1]

    local function calcATR(ind)
        return math.max(math.abs(HA[ind].H - HA[ind].L), math.abs(HA[ind].H - HA[ind-1].C), math.abs(HA[ind-1].C - HA[ind].L))
    end

    if index<(beginIndexToCalc + periodATR) then
        ATR[index] = 0
    elseif index==(beginIndexToCalc + periodATR) then
        local sum=0
        for i = 1, periodATR do
            sum = sum + calcATR(beginIndexToCalc + i)
        end
        ATR[index]=sum / periodATR
    elseif index>(beginIndexToCalc + periodATR) then
        ATR[index]=(ATR[index-1] * (periodATR-1) + calcATR(index))/periodATR
    end

    --myLog(" index: "..tostring(index)..', C: '..tostring(HA[index].C)..', cacheH: '..tostring(cacheH[index])..', ATR: '..tostring(ATR[index])..', cacheL: '..tostring(cacheL[index]))

    if index <= beginIndexToCalc + (math.max(period, periodATR) + 3) or index > endIndexToCalc then
        return calcAlgoValue, trend, calcChartResults
    end

    if DS:C(index) ~= nil then

        local previous = index-1
        if DS:C(previous) == nil then
            previous = FindExistCandle(previous)
        end

        cacheH[index] = HA[index].H
        cacheL[index] = HA[index].L

        local smoothStep = 0
        local Step=StepSizeCalc(period,Kv,StepSize,Switch,index, HA, smoothStep)
        --local StepRange = StepSizeCalc(period,Kv,StepSize,Switch,index,DS)
        --if StepRange == 0 then StepRange = SEC_PRICE_STEP end
		--emaStep[index] = kawg*StepRange+(1-kawg)*emaStep[index-1]
        --local Step = emaStep[index]

		emaATR[index] = kawg*ATR[index]+(1-kawg)*emaATR[index-1]

        if Step == 0 then Step = SEC_PRICE_STEP end

        local SizeP=Step*SEC_PRICE_STEP
        local Size2P=2*SizeP

        local result

        previous = index-barShift
        if DS:C(previous) == nil then
            previous = FindExistCandle(previous)
        end
        if Switch == 1 then
            smax0=HA[previous].L+Size2P
            smin0=HA[previous].H-Size2P
        else
            smax0=HA[previous].C+Size2P
            smin0=HA[previous].C-Size2P
        end

        --myLog("index "..tostring(index).." ATRfactor "..tostring(ATRfactor))
        --myLog("DS:C(index) "..tostring(DS:C(index)))
        --myLog("smax1[index] "..tostring(smax1[index]))
        --myLog("smin1[index] "..tostring(smin1[index]))
        --myLog("smax0 "..tostring(smax0))
        --myLog("smin0 "..tostring(smin0))
        --myLog("trend[index] "..tostring(trend[index]))
        --myLog("Step "..tostring(Step).." Size2P "..tostring(Size2P)..' ATR[index]'..tostring(ATR[index]))

		if HA[index].C>smax1[index] and (HA[index].C-smax1[index]) > ATRfactor*emaATR[index] then
			trend[index] = 1
		end
		--if DS:O(index)>smax1[index] and trend[index-1]== -1 and trend[index-2]== 1 then
		--	trend[index-1] = 1
		--end
		if HA[index].C<smin1[index] and (smin1[index]-HA[index].C) > ATRfactor*emaATR[index] then
			trend[index]= -1
		end
		--if DS:O(index)<smin1[index] and trend[index-1] == 1 and trend[index-2]== -1 then
		--	trend[index-1]= -1
		--end
        --myLog("HA[index].C-smax1[index] "..tostring(HA[index].C-smax1[index]))
        --myLog("HA[index].C-smin1[index] "..tostring(HA[index].C-smin1[index]))
        --myLog("trend[index] "..tostring(trend[index]))

        if trend[index]>0 then
            if smin0<smin1[index] then smin0=smin1[index] end
            result=smin0+SizeP
        else
            if smax0>smax1[index] then smax0=smax1[index] end
            result=smax0-SizeP
        end

        --myLog("result "..tostring(result))

        smax1[index] = smax0
        smin1[index] = smin0

        if trend[index]>0 then
            NRTR[index]=(result+ratio/Step)-Step*SEC_PRICE_STEP
        end
        if trend[index]<0 then
            NRTR[index]=(result+ratio/Step)+Step*SEC_PRICE_STEP
        end

        calcAlgoValue[index] = HA[index].C
        calcChartResults[index] = NRTR[index]

    end


    return calcAlgoValue, trend, calcChartResults

end

function StepSizeCalc(Len, Km, Size, Switch, index, DS, smoothStep)

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
                    Range=HA[index-Len-1].H-HA[index-Len-1].L
                else
                    Range=math.abs(HA[index-Len-1].O-HA[index-Len-1].C)
                end
            end
            rangeEMA[1] = Range

            for iii=1, Len do
                if DS:C(index-Len+iii-1) ~= nil then

                    if Switch == 1 then
                        Range=HA[index-Len+iii-1].H-HA[index-Len+iii-1].L
                    else
                        Range=math.abs(HA[index-Len+iii-1].O-HA[index-Len+iii-1].C)
                    end
                    rangeEMA[iii+1] = k*Range+(1-k)*rangeEMA[iii]
                else
                    rangeEMA[iii+1] = rangeEMA[iii]
                end
            end

            result = round(Km*rangeEMA[#rangeEMA]/SEC_PRICE_STEP, nil)

        else result=Km*Size
        end

    else

        if Size == 0 then

            local Range=0.0
            local ATRmax=-1000000
            local ATRmin=1000000

            for iii=1, Len do
                if HA[index-iii] ~= nil then
                    if Switch == 1 then
                        Range=HA[index-iii].H-HA[index-iii].L
                    else
                        Range=math.abs(HA[index-iii].O-HA[index-iii].C)
                    end
                    if Range>ATRmax then ATRmax=Range end
                    if Range<ATRmin then ATRmin=Range end
                end
            end

            result = round(0.5*Km*(ATRmax+ATRmin)/SEC_PRICE_STEP, nil)

        else result=Km*Size
        end

    end

    return result

end

function CalcHiekenAshi(index, ds)

    local status, res = pcall(function()
        if ds and (index or 0) > 0 and ds:C(index) then
            if not HA[index-1] then
                HA[index] = HA[index] or {}
                HA[index].O = ds:O(index)
                HA[index].C = ds:C(index)
                HA[index].H = ds:H(index)
                HA[index].L = ds:L(index)
            else
                HA[index] = HA[index] or {}
                HA[index].O = (HA[index-1].O + HA[index-1].C)/2
                HA[index].C = (ds:O(index) + ds:C(index) + ds:H(index) + ds:L(index))/4
                HA[index].H = math.max(ds:H(index), HA[index].O, HA[index].C)
                HA[index].L = math.min(ds:L(index), HA[index].O, HA[index].C)
            end
        end
    end)
    if not status then myLog(NAME_OF_STRATEGY..' Error CalcHiekenAshi: '..res)
    end
end

local newIndex = #ALGORITHMS['names']+1

ALGORITHMS['names'][newIndex]               = "NRTR"
ALGORITHMS['initParams'][newIndex]          = initStepNRTRParams
ALGORITHMS['initAlgorithms'][newIndex]      = initStepNRTR
ALGORITHMS['itetareAlgorithms'][newIndex]   = iterateNRTR
ALGORITHMS['calcAlgorithms'][newIndex]      = stepNRTR
ALGORITHMS['tradeAlgorithms'][newIndex]     = simpleTrade
ALGORITHMS['settings'][newIndex]            = NRTRSettings
