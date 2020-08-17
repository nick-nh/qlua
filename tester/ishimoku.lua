ishimokuSettings = {
    pTenkan = 9,
    pKijun = 26,
    Size = 0,
    fixedstop = 0,
    SLSec = 0,
    TPSec = 0
}

--- Алгоритм
function initishimoku()
    ATR = nil
    trend=nil
    calcAlgoValue = nil     --      Возвращаемая таблица
    calcChartResults = nil     --      Возвращаемая таблица

	H_tmp=nil
	L_tmp=nil
end

function iterateishimoku(iSec, cell)

    iterateSLTP = true

    param1Min = 5
    param1Max = 20
    param1Step = 1

    param2Min = 9
    param2Max = 50
    param2Step = 1

    param3Min = 1
    param3Max = 10
    param3Step = 1

    local settingsTable = {}
    local allCount = 0

    for param1 = param1Min, param1Max, param1Step do
        local _param2Min = math.max(param2Min, param1+1)
        for param2 = _param2Min, param2Max, param2Step do
            --for param3 = param3Min, param3Max, param3Step do
                allCount = allCount + 1

                    settingsTable[allCount] = {
                        pTenkan    = param1,
                        pKijun    = param2
                        --shift    = param3
                    }
            --end
        end
    end

    iterateAlgorithm(iSec, cell, settingsTable)

end

function ishimoku(index, Fsettings)

    local pTenkan = (Fsettings.Tenkan or 9)
    local pKijun = (Fsettings.Kijun or 26)
    --local shift = Fsettings.shift or 3
    local periodATR = 18
    local ATRfactor = 0.2

    local indexToCalc = 1000
    indexToCalc = Fsettings.indexToCalc or indexToCalc
    local beginIndexToCalc = Fsettings.beginIndexToCalc or math.max(1, DS:Size() - indexToCalc)

    function sen(I,P, R)
        if I>=beginIndexToCalc + P then
            local mx=math.max(unpack(H_tmp,I-P+1,I))
            local mn=math.min(unpack(L_tmp,I-P+1,I))
            return round((mx+mn)/2, R)
        else return 0	end
    end

    if index == nil then index = 1 end

    if index == beginIndexToCalc or index == 1 then

        myLog("--------------------------------------------------")
        myLog("Показатель Tenkan "..tostring(Tenkan))
        myLog("Показатель Kijun "..tostring(Kijun))
        myLog("--------------------------------------------------")

        H_tmp={}
        L_tmp={}
        H_tmp[index] = 0
        L_tmp[index] = 0

        Tenkan={}
        Kijun={}
        Tenkan[index] = 0
        Kijun[index] = 0

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

    H_tmp[index]        = H_tmp[index-1]
    L_tmp[index]        = L_tmp[index-1]

    ATR[index] = ATR[index-1]
    calcAlgoValue[index] = calcAlgoValue[index-1]
    trend[index] = trend[index-1]
    calcChartResults[index] = calcChartResults[index-1]

    if DS:C(index) == nil then
        return calcAlgoValue, trend, calcChartResults
    end

    H_tmp[index]=DS:H(index)
    L_tmp[index]=DS:L(index)

    if index<beginIndexToCalc + periodATR then
        ATR[index] = 0
    elseif index==beginIndexToCalc + periodATR then
        local sum=0
        for i = 1, periodATR do
            sum = sum + dValue(i)
        end
        ATR[index]=sum / periodATR
    elseif index>beginIndexToCalc + periodATR then
        ATR[index]=(ATR[index-1] * (periodATR-1) + dValue(index)) / periodATR
    end

    if DS:C(index) ~= nil then

        Tenkan[index] = sen(index, pTenkan, scale)
        Kijun[index]  = sen(index, pKijun, scale)

        local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5
        local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5

        local isBuy  = trend[index] <= 0 and Tenkan[index] > Kijun[index] and Tenkan[index] > Tenkan[index-1] and Kijun[index] > Kijun[index-1]
        local isSell = trend[index] >= 0 and Tenkan[index] < Kijun[index] and Tenkan[index] < Tenkan[index-1] and Kijun[index] < Kijun[index-1]
        --local isBuy  = trend[index] <= 0 and Trigger[index] > Trigger[index-1] and it[index] > it[index-1]
        --local isSell = trend[index] >= 0 and Trigger[index] < Trigger[index-1] and it[index] < it[index-1]
        --local isBuy  = trend[index] <= 0 and it[index] > it[index-1] and Trigger[index] > it[index]
        --local isSell = trend[index] >= 0 and it[index] < it[index-1] and Trigger[index] < it[index]
        --local isBuy  = trend[index] <= 0 and it[index] > it[index-1] and Trigger[index] > it[index] and DS:O(index) > it[index]
        --local isSell = trend[index] >= 0 and it[index] < it[index-1] and Trigger[index] < it[index] and DS:O(index) < it[index]
        --local isBuy  = trend[index] <= 0 and Trigger[index] > Trigger[index-1] and Trigger[index] > it[index] and DS:O(index) > Trigger[index]
        --local isSell = trend[index] >= 0 and Trigger[index] < Trigger[index-1] and Trigger[index] < it[index] and DS:O(index) < Trigger[index]

        if isBuy then
            trend[index] = 1
        end
        if isSell then
            trend[index] = -1
        end
        --if trend[index] == 1 and (Trigger[index] - DS:O(index)) > ATRfactor*ATR[index] then
        --    trend[index] = 0
        --end
        --if trend[index] == -1 and (DS:O(index) - Trigger[index]) > ATRfactor*ATR[index] then
        --    trend[index] = 0
        --end

        calcAlgoValue[index] = DS:O(index)
    end

    calcChartResults[index] = {Tenkan[index], Kijun[index]}

    return calcAlgoValue, trend, calcChartResults

end


local newIndex = #ALGORITHMS['names']+1

ALGORITHMS['names'][newIndex]               = "ishimoku"
ALGORITHMS['initParams'][newIndex]          = initishimoku
ALGORITHMS['initAlgorithms'][newIndex]      = initishimoku
ALGORITHMS['itetareAlgorithms'][newIndex]   = iterateishimoku
ALGORITHMS['calcAlgorithms'][newIndex]      = ishimoku
ALGORITHMS['tradeAlgorithms'][newIndex]     = simpleTrade
ALGORITHMS['settings'][newIndex]            = ishimokuSettings
