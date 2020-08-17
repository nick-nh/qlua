RangeHVSettings = {
    period    = 29,
    shift = 5,
    koef = 1,
    ATRfactor = 0.5,
    Size = 0,
    periodATR = 0,
    kATR = 0
}


function initRangeHV()
    lastMax = nil
    lastMin = nil
    barsProfile = nil
    maxPrice = nil
    maxPricefast = nil
    middlePrice = nil
    middlePricefast = nil
    UpSigmaVol = nil
    DownSigmaVol = nil
    UpSigmaVolfast = nil
    DownSigmaVolfast = nil
    Trigger = nil
    calcAlgoValue = nil     --      Возвращаемая таблица
    calcChartResults = nil     --      Возвращаемая таблица
    VWAP=nil
    VWAPfast=nil
    vEMA=nil
    vfEMA=nil
    TEMA=nil
    EMA=nil
    EMA2=nil
    EMA3=nil
	Close = nil
	Open = nil
	High = nil
    Low = nil
	CC=nil
	CCfast=nil
    ATR=nil
    calcATR = true
end

function iterateRangeHV(iSec, cell)

    deltaShift = 0
    calcProfile = nil
    calcReg = nil

    iterateSLTP = true

    local  param1Min = 24
    local  param1Max = 140
    local  param1Step = 1

    local param2Min = 5
    local param2Max = 70
    local param2Step = 1

    local param3Min = 0
    local param3Max = 0
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

        _param2Min = param2Min
        _param3Max = param3Max
        --_param3Min = math.max(param1, param3Min)
        _param3Min = param3Min

        for param2 = _param2Min, param2Max, param2Step do

            for param3 = param3Min, _param3Max, param3Step do

                for param4 = param4Min, param4Max, param4Step do

                    _param5Min = param5Min
                    --_param5Min = math.max(param4, param5Min)

                    for param5 = _param5Min, param5Max, param5Step do

                        allCount = allCount + 1

                        settingsTable[allCount] = {
                            period    = param1,
                            koef    =   param2,
                            shift    = param3,
                            Size = Size,
                            ATRfactor = 0,
                            periodATR = param4,
                            kATR = param5,
                        }

                    end
                end

            end
        end
    end

    myLog('settingsTable size '..tostring(#settingsTable))
    iterateAlgorithm(iSec, cell, settingsTable)

end

function RangeHV(index, settings, DS)

    local indexToCalc = 1000
    indexToCalc = settings.Size or indexToCalc
    local beginIndexToCalc = settings.beginIndexToCalc or math.max(1, settings.beginIndex - indexToCalc)
    local endIndexToCalc = settings.endIndex or DS:Size()

    if index == nil then index = 1 end

    local period = settings.period or 29
	local shift = settings.shift or 17
    local koef = settings.period or 1
    local ATRfactor = settings.ATRfactor or 0.3
	local clasters = 75

    local periodATR = settings.periodATR or 10
    kATR = settings.kATR or 0.65

    --local periodATR = math.ceil(math.max(22, period/2))
    --local periodATR = 10
    --local periodATR = shift
    --local periodHV = period
    --local periodHV = math.ceil(math.max(40, period*0.8))
    --local periodHV = 54
    --local periodHV2 = 54


    local periodHV = period
    --local periodHV2 = math.max(koef, period)
    --local periodHV2 = math.max(shift, period)
    local periodHV2 = koef
    --local ATRfactor = shift
    --local periodHV = 62
    --local periodHV2 = 150

    local maxPeriodHV = math.max(periodHV,periodHV2)

    period = math.min(period, DS:Size())

    local MAX = 0
    local MAXV = 0
    local MIN = 0
    local jj = 0
    local kk = 0
    local MAXfast = 0
    local MAXVfast = 0
    local MINfast = 0

    if index == beginIndexToCalc or index == 1 then
        --myLog("Показатель Period "..tostring(period))
        --myLog("Показатель shift "..tostring(shift))
        --myLog("Показатель koef "..tostring(koef))
        --myLog("Показатель ATRfactor "..tostring(ATRfactor))
        --myLog("Показатель SLSec "..tostring(settings.SLSec))
        --myLog("Показатель TPSec "..tostring(settings.TPSec))
        --myLog("--------------------------------------------------")

        if calcProfile == nil then
            myLog("new profile")
            calcProfile = {}
        end
        if calcProfile[periodHV] == nil then
            calcProfile[periodHV] = {}
            calcProfile[periodHV][index] = nil
        end
        if calcProfile[periodHV2] == nil then
            calcProfile[periodHV2] = {}
            calcProfile[periodHV2][index] = nil
        end

        Close = {}
        Close[index] = 0
        Open = {}
        Open[index] = 0
        High = {}
        High[index] = 0
        Low = {}
        Low[index] = 0

        CC={}
        CC[1]={0, DS:C(index)}
        CCfast={}
        CCfast[1]={0, DS:C(index)}
        barsProfile = {}
        barsProfile[1] = {}

        maxPrice = {}
        maxPrice[index]= DS:C(index)
        maxPricefast = {}
        maxPricefast[index]= DS:C(index)
        --middlePrice = {}
        --middlePrice[index]= DS:C(index)
        --middlePricefast = {}
        --middlePricefast[index]= DS:C(index)
        --UpSigmaVol = {}
        --UpSigmaVol[index] = DS:C(index)
        --DownSigmaVol = {}
        --DownSigmaVol[index] = DS:C(index)
        --UpSigmaVolfast = {}
        --UpSigmaVolfast[index] = DS:C(index)
        --DownSigmaVolfast = {}
        --DownSigmaVolfast[index] = DS:C(index)

        Trigger = {}
        Trigger[index]= 0
        calcAlgoValue = {}
        calcAlgoValue[index]= 0
        calcChartResults = {}
        calcChartResults[index]= nil
        trend = {}
        trend[index] = 1

        vEMA = {}
        vEMA[index] = DS:C(index)
        vfEMA = {}
        vfEMA[index] = DS:C(index)
        TEMA = {}
        TEMA[index] = DS:C(index)
        EMA2 = {}
        EMA2[index] = DS:C(index)
        EMA3 = {}
        EMA3[index] = DS:C(index)

        VWAP = {}
        VWAP[index] = DS:C(index)
        VWAPfast = {}
        VWAPfast[index] = DS:C(index)
        ATR = {}
        ATR[index] = 0

        return calcAlgoValue, nil, calcChartResults
    end

    Open[index] = Open[index-1]
    High[index] = High[index-1]
    Low[index] = Low[index-1]
    Close[index] = Close[index-1]
    maxPrice[index] = maxPrice[index-1]
    maxPricefast[index] = maxPricefast[index-1]
    --middlePrice[index] = middlePrice[index-1]
    --middlePricefast[index] = middlePricefast[index-1]
    --UpSigmaVol[index] 	      = UpSigmaVol[index-1]
    --DownSigmaVol[index] 	  = DownSigmaVol[index-1]
    --UpSigmaVolfast[index] 	  = UpSigmaVolfast[index-1]
    --DownSigmaVolfast[index]   = DownSigmaVolfast[index-1]
    Trigger[index] = Trigger[index-1]
    calcAlgoValue[index] = calcAlgoValue[index-1]
    calcChartResults[index] = calcChartResults[index-1]
    trend[index] = trend[index-1]
    barsProfile[index] = {}

    vEMA[index] 	  = vEMA[index-1]
    vfEMA[index] 	  = vfEMA[index-1]
    VWAP[index] 	  = VWAP[index-1]
    VWAPfast[index]   = VWAPfast[index-1]
    TEMA[index] 	  = TEMA[index-1]
    EMA2[index] 	  = EMA2[index-1]
    EMA3[index] 	  = EMA3[index-1]

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
        --ATR[index] = kawg*dValue(index)+(1-kawg)*ATR[index-1]
    end

    if DS:C(index) ~= nil then
        Open[index] = DS:O(index)
        High[index] = DS:H(index)
        Close[index] = DS:C(index)
        Low[index] = DS:L(index)
    end

    if index <= (beginIndexToCalc + math.max(period, maxPeriodHV) + shift + 1) or index > endIndexToCalc then
        return calcAlgoValue, nil, calcChartResults
    end

    if DS:C(index) ~= nil then

        if calcProfile[periodHV][index] == nil or calcProfile[periodHV2][index] == nil then

            local previous = index-maxPeriodHV
            local previousFast = index-periodHV

            local needCalcFast = false
            if periodHV < periodHV2 and calcProfile[periodHV][index] == nil then
                calcProfile[periodHV][index] = {vwap = 0, maxPrice = 0, middlePrice = 0}
                if DS:C(previousFast) == nil then
                    previousFast = FindExistCandle(previousFast)
                end

                --MAXfast = math.max(unpack(High,math.max(previousFast+1, 1),index))
                --MINfast = math.min(unpack(Low,math.max(previousFast+1, 1),index))
                MAXfast = High[math.max(previousFast+1, 1)]
                MINfast = Low[math.max(previousFast+1, 1)]
                for i=math.max(previousFast+1, 1)+1,index do
                    MAXfast = math.max(High[i], MAXfast)
                    MINfast = math.min(Low[i], MINfast)
                end
                for i = 1, clasters do CCfast[i]={0, i/clasters*(MAXfast-MINfast)+MINfast} end
                needCalcFast = true
            end

            local _p
            local needCalcSlow = false

            if calcProfile[maxPeriodHV][index] == nil then
                calcProfile[maxPeriodHV][index] = {vwap = 0, maxPrice = 0, middlePrice = 0}

                if DS:C(previous) == nil then
                    previous = FindExistCandle(previous)
                end

                --MAX = math.max(unpack(High,math.max(previous+1, 1),index))
                --MIN = math.min(unpack(Low,math.max(previous+1, 1),index))
                MAX = High[math.max(previous+1, 1)]
                MIN = Low[math.max(previous+1, 1)]
                for i=math.max(previous+1, 1)+1,index do
                    MAX = math.max(High[i], MAX)
                    MIN = math.min(Low[i], MIN)
                end

                _p = index - previous
                for i = 1, clasters do CC[i]={0, i/clasters*(MAX-MIN)+MIN} end
                needCalcSlow = true
            else
                _p = index - previousFast
            end

            --local numProf = 0
            --local avgVol = 0
            --local numProffast = 0
            --local avgVolfast = 0

            VWAP[index] = 0
            local allVolume = 0
            VWAPfast[index] = 0
            local allVolumefast = 0

            for i = 0, _p-1 do
                if DS:C(index-i) ~= nil then
                    if needCalcSlow then
                        jj=math.floor( (DS:H(index-i)-MIN)/(MAX-MIN)*(clasters-1))+1
                        kk=math.floor( (DS:L(index-i)-MIN)/(MAX-MIN)*(clasters-1))+1
                        for k=1,(jj-kk) do
                            --if CC[kk+k-1][1] == 0 then numProf = numProf + 1 end
                            --myLog("index "..tostring(index)..", index-i "..tostring(index-i)..", jj "..tostring(jj)..", kk "..tostring(kk)..", kk+k-1 "..tostring(kk+k-1)..", MAX "..tostring(MAX)..", MIN "..tostring(MIN)..", H "..tostring(DS:H(index-i))..", L "..tostring(DS:L(index-i)))
                            CC[kk+k-1][1]=CC[kk+k-1][1]+DS:V(index-i)/(jj-kk)
                            VWAP[index] = VWAP[index] + CC[kk+k-1][2]*DS:V(index-i)/(jj-kk)
                            --avgVol = avgVol + DS:V(index-i)/(jj-kk)
                            allVolume = allVolume + DS:V(index-i)/(jj-kk)
                        end
                    end
                    if needCalcFast and index-i>=previousFast+1 then
                        jj=math.floor( (DS:H(index-i)-MINfast)/(MAXfast-MINfast)*(clasters-1))+1
                        kk=math.floor( (DS:L(index-i)-MINfast)/(MAXfast-MINfast)*(clasters-1))+1
                        for k=1,(jj-kk) do
                            --if CCfast[kk+k-1][1] == 0 then numProffast = numProffast + 1 end
                            CCfast[kk+k-1][1]=CCfast[kk+k-1][1]+DS:V(index-i)/(jj-kk)
                            VWAPfast[index] = VWAPfast[index] + CCfast[kk+k-1][2]*DS:V(index-i)/(jj-kk)
                            --avgVolfast = avgVolfast + DS:V(index-i)/(jj-kk)
                            allVolumefast = allVolumefast + DS:V(index-i)/(jj-kk)
                        end
                    end
                end
            end

            if needCalcSlow then
                VWAP[index] = VWAP[index]/allVolume
                calcProfile[maxPeriodHV][index].vwap = VWAP[index]
            end

            if needCalcFast then
                VWAPfast[index] = VWAPfast[index]/allVolumefast
                calcProfile[periodHV][index].vwap = VWAPfast[index]
            end

            --local sigma = 0
            --local sigmafast = 0
            --local maxClaster = 0
            --local maxClasterfast = 0
            --
            --if numProf > 0 then
            --    avgVol = round(avgVol/numProf, 5)
            --else
            --    avgVol = 0
            --end
            --if numProffast > 0 then
            --    avgVolfast = round(avgVolfast/numProffast, 5)
            --else
            --    avgVolfast = 0
            --end

            for i = 1, clasters do
                if needCalcSlow then
                    MAXV = math.max(MAXV, CC[i][1])
                    --sigma = sigma + math.pow(CC[i][1] - avgVol, 2)
                    if MAXV == CC[i][1] then
                        maxPrice[index]=CC[i][2]
                        calcProfile[maxPeriodHV][index].maxPrice = maxPrice[index]
                        --maxClaster = i
                    end
                end
                if needCalcFast then
                    MAXVfast = math.max(MAXVfast, CCfast[i][1])
                    --sigmafast = sigmafast + math.pow(CCfast[i][1] - avgVolfast, 2)
                    if MAXVfast == CCfast[i][1] then
                        maxPricefast[index]=CCfast[i][2]
                        calcProfile[periodHV][index].maxPrice = maxPricefast[index]
                        --maxClasterfast = i
                    end
                end
            end

            --[[
			if numProf > 1 then
				sigma = round(math.sqrt(sigma/(numProf-1)), 2)
			else
				sigma = 0
			end
			if numProffast > 1 then
				sigmafast = round(math.sqrt(sigmafast/(numProffast-1)), 2)
			else
				sigmafast = 0
			end

			if sigma > 0 then
				local find = false
				local i = maxClaster+1
				for i=maxClaster+1,clasters do
					if CC[i][1] < MAXV - sigma and not find then
						UpSigmaVol[index] = CC[i][2]
						find = true
					end
					if CC[i][1] > MAXV - sigma and find then
						find = false
					end
				end
				find = true
				for i=maxClaster-1,1, -1 do
					if CC[i][1] < MAXV - sigma and not find then
						DownSigmaVol[index] = CC[i][2]
						find = true
					end
					if CC[i][1] > MAXV - sigma and find then
						find = false
					end
				end
			end

            if sigmafast > 0 then
				local find = false
				local i = maxClasterfast+1
				for i=maxClasterfast+1,clasters do
					if CCfast[i][1] < MAXVfast - sigmafast and not find then
						UpSigmaVolfast[index] = CCfast[i][2]
						find = true
					end
					if CCfast[i][1] > MAXVfast - sigmafast and find then
						find = false
					end
				end
				find = true
				for i=maxClasterfast-1,1, -1 do
					if CCfast[i][1] < MAXVfast - sigmafast and not find then
						DownSigmaVolfast[index] = CCfast[i][2]
						find = true
					end
					if CCfast[i][1] > MAXVfast - sigmafast and find then
						find = false
					end
				end
			end

            if needCalcSlow then
                middlePrice[index] = (UpSigmaVol[index] + DownSigmaVol[index])/2
                calcProfile[maxPeriodHV][index].middlePrice = (UpSigmaVol[index] + DownSigmaVol[index])/2
            end

            if needCalcFast then
                middlePricefast[index] = (UpSigmaVolfast[index] + DownSigmaVolfast[index])/2
                calcProfile[periodHV][index].middlePrice = (UpSigmaVolfast[index] + DownSigmaVolfast[index])/2
            end
            ]]--

        else
            maxPrice[index] = calcProfile[maxPeriodHV][index].maxPrice
            VWAP[index] = calcProfile[maxPeriodHV][index].vwap
            --middlePrice[index] = calcProfile[maxPeriodHV][index].middlePrice
            if periodHV < periodHV2 then
                maxPricefast[index] = calcProfile[periodHV][index].maxPrice
                VWAPfast[index] = calcProfile[periodHV][index].vwap
                --middlePricefast[index] = calcProfile[periodHV][index].middlePrice
            end
        end

        --local shift = 2*math.ceil(period/4) + math.ceil(period/10)

        local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5
        local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5

        local kvEMA = 2/(koef+1)
        vEMA[index]=round(kvEMA*VWAP[index]+(1-kvEMA)*vEMA[index-1], 5)
        --vfEMA[index]=round(kvEMA*VWAPfast[index]+(1-kvEMA)*vfEMA[index-1], 5)
        Trigger[index] = 2.0*vEMA[index]-(vEMA[index-shift] or 0)

        EMA2[index]=kvEMA*vEMA[index]+(1-kvEMA)*EMA2[index-1]
        EMA3[index]=kvEMA*EMA2[index]+(1-kvEMA)*EMA3[index-1]
        TEMA[index] = 3*vEMA[index] - 3*EMA2[index] + EMA3[index]

        --local isBuy  = trend[index] <= 0 and (vEMA[index] + ATRfactor*ATR[index]) < VWAP[index-shift]
        --local isSell = trend[index] >= 0 and (vEMA[index] - ATRfactor*ATR[index]) > VWAP[index-shift]
        --local isBuy  = trend[index] <= 0 and (Close[index] - middlePrice[index]) > ATRfactor*ATR[index] and (Close[index] - middlePrice[index-1]) > ATRfactor*ATR[index]
        --local isSell = trend[index] >= 0 and (middlePrice[index] - Close[index]) > ATRfactor*ATR[index] and (middlePrice[index-1] - Close[index]) > ATRfactor*ATR[index]
        --local isBuy = trend[index] == -1 and (vEMA[index] > vEMA[index-shift] and vEMA[index-1] <= vEMA[index-shift-deltaShift])
        --local isSell = trend[index] == 1 and (vEMA[index] < vEMA[index-shift] and vEMA[index-1] >= vEMA[index-shift-deltaShift])
        --local isBuy = trend[index] <= 0 and VWAP[index] > VWAP[index-shift]
        --local isSell = trend[index] >= 0 and VWAP[index] < VWAP[index-shift]
        --local isBuy = trend[index] <= 0 and VWAPfast[index] > VWAP[index]
        --local isSell = trend[index] >= 0 and VWAPfast[index] < VWAP[index]
        --local isBuy  = (vfEMA[index] > VWAP[index] and vfEMA[index-1] <= VWAP[index-1])
        --local isSell = (vfEMA[index] < VWAP[index] and vfEMA[index-1] >= VWAP[index-1])
        --local isBuy = trend[index] <= 0 and vEMA[index] > (vEMA[index-1] + ATRfactor*ATR[index])
        --local isSell = trend[index] >= 0 and (vEMA[index] - ATRfactor*ATR[index]) < vEMA[index-1]

        --local isBuy =  trend[index] <= 0 and vEMA[index] > vEMA[index-1] and (Close[index] - vEMA[index]) > ATRfactor*ATR[index]
        --local isSell = trend[index] >= 0 and vEMA[index] < vEMA[index-1] and (vEMA[index] - Close[index]) > ATRfactor*ATR[index]
        --local isBuy =  trend[index] <= 0 and vEMA[index] > vEMA[index-1] and Close[index] > vEMA[index]
        --local isSell = trend[index] >= 0 and vEMA[index] < vEMA[index-1] and vEMA[index] > Close[index]
        --local isBuy  = trend[index] <= 0 and vEMA[index] > vEMA[index-1]
        local isBuy  = trend[index] <= 0 and TEMA[index] > TEMA[index-1]
        local isSell = trend[index] >= 0 and TEMA[index] < TEMA[index-1]
        --local isBuy  = trend[index] <= 0 and TEMA[index] > TEMA[index-1] and math.abs(TEMA[index] - TEMA[index-1])/TEMA[index-1]>=0.001
        --local isSell = trend[index] >= 0 and TEMA[index] < TEMA[index-1] and math.abs(TEMA[index] - TEMA[index-1])/TEMA[index-1]>=0.001
        --local isBuy  = trend[index] <= 0 and vEMA[index] > vEMA[index-1] and math.abs(vEMA[index] - vEMA[index-1])/vEMA[index-1]>=0.001
        --local isSell = trend[index] >= 0 and vEMA[index] < vEMA[index-1] and math.abs(vEMA[index] - vEMA[index-1])/vEMA[index-1]>=0.001
        --local isSell = trend[index] >= 0 and vEMA[index] < vEMA[index-1]
        --local isBuy  = trend[index] <= 0 and vEMA[index] > vEMA[index-1] and math.abs(vEMA[index] - vEMA[index-1])/vEMA[index-1]>=0.001
        --local isSell = trend[index] >= 0 and vEMA[index] < vEMA[index-1] and math.abs(vEMA[index] - vEMA[index-1])/vEMA[index-1]>=0.001
        --local isBuy  = trend[index] <= 0 and vEMA[index] > vEMA[index-1] and Trigger[index] > Trigger[index-1] and Close[index] > vEMA[index]
        --local isSell = trend[index] >= 0 and vEMA[index] < vEMA[index-1] and Trigger[index] < Trigger[index-1] and vEMA[index] > Close[index]
        --local isBuy = trend[index] <= 0 and vEMA[index] > vEMA[index-1] and vfEMA[index] > vfEMA[index-1]
        --local isSell = trend[index] >= 0 and vEMA[index] < vEMA[index-1] and vfEMA[index] < vfEMA[index-1]
        --local isBuy = trend[index] <= 0 and vEMA[index] > vEMA[index-1] and VWAP[index] > VWAP[index-1] and VWAP[index] > vEMA[index]
        --local isSell = trend[index] >= 0 and vEMA[index] < vEMA[index-1] and VWAP[index] < VWAP[index-1] and VWAP[index] < vEMA[index]
        --local isBuy =  trend[index] <= 0 and vEMA[index] > vEMA[index-1] and vfEMA[index] > vfEMA[index-1] and vfEMA[index] > vEMA[index] and Close[index] > vfEMA[index]
        --local isSell = trend[index] >= 0 and vEMA[index] < vEMA[index-1] and vfEMA[index] < vfEMA[index-1] and vfEMA[index] < vEMA[index] and vfEMA[index] > Close[index]
        --local isBuy = trend[index] == -1 and (VWAPfast[index] > VWAP[index-shift] and VWAPfast[index-1] <= VWAP[index-shift])
        --local isBuy = trend[index] <= 0 and (Close[index]-vEMA[index]) > ATRfactor*ATR[index]
        --local isSell = trend[index] >= 0  and (vEMA[index]-Close[index]) > ATRfactor*ATR[index]
        --local isSell = trend[index] == 1 and (Close[index] < VWAP[index] and Close[index] < VWAPfast[index] and (VWAP[index]-Close[index]) > ATRfactor*ATR[index])
        --local isBuy = trend[index] == -1 and (Close[index] > VWAP[index] and Close[index] > VWAPfast[index])
        --local isSell = trend[index] == 1 and (Close[index] < VWAP[index] and Close[index] < VWAPfast[index])
        --local isBuy = trend[index] <= 0 and (Close[index] > VWAP[index] and Close[index] > vEMA[index])
        --local isSell = trend[index] >=0 and (Close[index] < VWAP[index] and Close[index] < vEMA[index])

        if isBuy then
            trend[index] = 1
        end
        if isSell then
            trend[index] = -1
        end

        --if trend[index] == 1 and (vEMA[index] - Close[index]) > ATRfactor*ATR[index] then
        --    trend[index] = 0
        --end
        --if trend[index] == -1 and (Close[index] - vEMA[index]) > ATRfactor*ATR[index] then
        --    trend[index] = 0
        --end

        --if trend[index] <= 0  and ((Close[index] - vfEMA[index]) > ATRfactor*ATR[index] and (Close[index] - VWAP[index]) > ATRfactor*ATR[index]) then
        --    trend[index] = 1
        --end
        --if trend[index] >= 0  and ((vfEMA[index] - Close[index]) > ATRfactor*ATR[index] and (VWAP[index] - Close[index]) > ATRfactor*ATR[index]) then
        --    trend[index] = -1
        --end

        --myLog("index "..tostring(index)..", vEMA "..tostring(vEMA[index])..", ATR "..tostring(ATR[index]))
        --myLog("index "..tostring(index)..", previous "..tostring(previous)..", MAX "..tostring(MAX)..", MIN "..tostring(MIN)..", Close "..tostring(Close[index])..", vEMA "..tostring(vEMA[index])..", VWAP "..tostring(VWAP[index])..", allVolume "..tostring(allVolume))
        --myLog("index "..tostring(index)..", trend "..tostring(trend[index])..", isBuy "..tostring(isBuy)..", isSell "..tostring(isSell)..", Close "..tostring(Close[index])..", vfEMA "..tostring(vfEMA[index])..", vEMA "..tostring(vEMA[index])..", VWAPfast "..tostring(VWAPfast[index])..", VWAP "..tostring(VWAP[index]))
        --myLog("index "..tostring(index)..", trend "..tostring(trend[index])..", isBuy "..tostring(isBuy)..", isSell "..tostring(isSell)..", Close "..tostring(Close[index])..", middlePrice "..tostring(middlePrice[index]))

        --calcChartResults[index] = {VWAPfast[index], vfEMA[index], VWAP[index], vEMA[index], maxPrice[index], EMA[index], TEMA[index]}
        --calcChartResults[index] = {vEMA[index], VWAP[index-shift]}
        --calcChartResults[index] = {vEMA[index], VWAP[index]}
        --calcChartResults[index] = {vEMA[index], vfEMA[index]}
        --calcChartResults[index] = vEMA[index]
        --calcChartResults[index] = {vEMA[index], Trigger[index]}
        calcChartResults[index] = TEMA[index]
        --calcChartResults[index] = {UpSigmaVol[index], DownSigmaVol[index]}
        --calcAlgoValue[index] = VWAP[index]
        --calcAlgoValue[index] = VWAP[index]
        calcAlgoValue[index] = DS:C(index)

    end

    return calcAlgoValue, trend, calcChartResults

end

local newIndex = #ALGORITHMS['names']+1

ALGORITHMS['names'][newIndex]               = "RangeHV"
ALGORITHMS['initParams'][newIndex]          = initRangeHV
ALGORITHMS['initAlgorithms'][newIndex]      = initRangeHV
ALGORITHMS['itetareAlgorithms'][newIndex]   = iterateRangeHV
ALGORITHMS['calcAlgorithms'][newIndex]      = RangeHV
ALGORITHMS['tradeAlgorithms'][newIndex]     = simpleTrade
ALGORITHMS['settings'][newIndex]            = RangeHVSettings
