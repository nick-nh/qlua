-------------------------
--THV

THVSettings = {
    period    = 1,
    koef = 1,
    shift = 1,
    periodATR = 0,
    kATR = 0,
    Size = 0
}

function initTHV()
	Trigger=nil
	thv_line=nil
	thv_line_2=nil
	gda_108=nil
	gda_112=nil
	gda_116=nil
	gda_120=nil
	gda_124=nil
	gda_128=nil
	gda_108_2=nil
	gda_112_2=nil
	gda_116_2=nil
	gda_120_2=nil
	gda_124_2=nil
	gda_128_2=nil
	cache_O=nil
	cache_C=nil
    EMA=nil
    trend=nil
    calcChartResults=nil
    ATR=nil
    calcATR = true
end

function iterateTHV(iSec, cell)

    iterateSLTP = true

    local param1Min = 5
    local param1Max = 80
    local param1Step = 1

    local param2Min = 0.8
    local param2Max = 2.1
    local param2Step = 0.1

    local param3Min = 1
    local param3Max = 35
    local param3Step = 1

    local param4Min   = 10
    local param4Max   = 10
    local param4Step  = 1

    local param5Min   = 0.65
    local param5Max   = 0.65
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

    iterateAlgorithm(iSec, cell, settingsTable)

end

function THV(index, settings, DS)

    local period = settings.period or 32
    local koef = settings.koef or 1
    local shift = settings.shift or 1
    --local period2 = settings.shift or 1
    local period2 = settings.period or 32

    local periodATR = settings.periodATR or 10
    kATR = settings.kATR or 0.65

    local indexToCalc = 1000
    indexToCalc = settings.Size or indexToCalc
    local beginIndexToCalc = settings.beginIndexToCalc or math.max(1, settings.beginIndex - indexToCalc)
    local endIndexToCalc = settings.endIndex or DS:Size()

    if index == nil then index = 1 end

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

    local gd_164_2 = period2
    if gd_164_2 < 1.0 then gd_164_2 = 1 end
    gd_164_2 = (gd_164_2 - 1.0) / 2.0 + 1.0
    local gd_172_2 = 2 / (gd_164_2 + 1.0)
    local gd_180_2 = 1 - gd_172_2

    if thv_line == nil then

        --myLog("Показатель Period "..tostring(period))
        --myLog("Показатель Period2 "..tostring(period2))
        --myLog("Показатель koef "..tostring(koef))
        --myLog("Показатель shift "..tostring(shift))
        --myLog("--------------------------------------------------")

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

        if period2~=period then
            thv_line_2={}
            thv_line_2[index]=0
            gda_108_2={}
            gda_108_2[index]=0
            gda_112_2={}
            gda_112_2[index]=0
            gda_116_2={}
            gda_116_2[index]=0
            gda_120_2={}
            gda_120_2[index]=0
            gda_124_2={}
            gda_124_2[index]=0
            gda_128_2={}
            gda_128_2[index]=0
        end

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

    if period2~=period then
        thv_line_2[index] = thv_line_2[index-1]
        gda_108_2[index] = gda_108_2[index-1]
        gda_112_2[index] = gda_112_2[index-1]
        gda_116_2[index] = gda_116_2[index-1]
        gda_120_2[index] = gda_120_2[index-1]
        gda_124_2[index] = gda_124_2[index-1]
        gda_128_2[index] = gda_128_2[index-1]
    end

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
        --ATR[index] = kawg*dValue(index)+(1-kawg)*ATR[index-1]
    end

    if index <= beginIndexToCalc + (math.max(period, periodATR) + shift + 1) or index > endIndexToCalc then
        return calcAlgoValue, trend, calcChartResults
    end

    if DS:C(index) ~= nil then

		local previous = index-1
		if DS:C(previous) == nil then
			previous = FindExistCandle(previous)
		end

        local val = dValue(index,"C")

        gda_108[index] = gd_172 * val + gd_180 * (gda_108[previous])
		gda_112[index] = gd_172 * (gda_108[index]) + gd_180 * (gda_112[previous])
		gda_116[index] = gd_172 * (gda_112[index]) + gd_180 * (gda_116[previous])
		gda_120[index] = gd_172 * (gda_116[index]) + gd_180 * (gda_120[previous])
		gda_124[index] = gd_172 * (gda_120[index]) + gd_180 * (gda_124[previous])
		gda_128[index] = gd_172 * (gda_124[index]) + gd_180 * (gda_128[previous])
		thv_line[index] = gd_132 * (gda_128[index]) + gd_140 * (gda_124[index]) + gd_148 * (gda_120[index]) + gd_156 * (gda_116[index])

        if period2~=period then
            gda_108_2[index] = gd_172_2 * val + gd_180_2 * (gda_108_2[previous])
            gda_112_2[index] = gd_172_2 * (gda_108_2[index]) + gd_180_2 * (gda_112_2[previous])
            gda_116_2[index] = gd_172_2 * (gda_112_2[index]) + gd_180_2 * (gda_116_2[previous])
            gda_120_2[index] = gd_172_2 * (gda_116_2[index]) + gd_180_2 * (gda_120_2[previous])
            gda_124_2[index] = gd_172_2 * (gda_120_2[index]) + gd_180_2 * (gda_124_2[previous])
            gda_128_2[index] = gd_172_2 * (gda_124_2[index]) + gd_180_2 * (gda_128_2[previous])
            thv_line_2[index] = gd_132 * (gda_128_2[index]) + gd_140 * (gda_124_2[index]) + gd_148 * (gda_120_2[index]) + gd_156 * (gda_116_2[index])
        end

        Trigger[index] = 2.0*thv_line[index]-(thv_line[index-shift] or 0)

        local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5
        local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5

        --local isBuy  = trend[index] <= 0 and thv_line[index] > thv_line[index-1] and Trigger[index] > thv_line[index]
        --local isSell = trend[index] >= 0 and thv_line[index] < thv_line[index-1] and Trigger[index] < thv_line[index]
        local isBuy  = trend[index] <= 0 and thv_line[index] > thv_line[index-1] and Trigger[index] > Trigger[index-1] and DS:C(index) > thv_line[index]
        local isSell = trend[index] >= 0 and thv_line[index] < thv_line[index-1] and Trigger[index] < Trigger[index-1] and DS:C(index) < thv_line[index]

        if isBuy then
            trend[index] = 1
        end
        if isSell then
            trend[index] = -1
        end

    end

    calcAlgoValue[index] = DS:C(index)
    calcChartResults[index] = {thv_line[index], Trigger[index]}

    return calcAlgoValue, trend, calcChartResults

end

local newIndex = #ALGORITHMS['names']+1

ALGORITHMS['names'][newIndex]               = "THV"
ALGORITHMS['initParams'][newIndex]          = initTHV
ALGORITHMS['initAlgorithms'][newIndex]      = initTHV
ALGORITHMS['itetareAlgorithms'][newIndex]   = iterateTHV
ALGORITHMS['calcAlgorithms'][newIndex]      = THV
ALGORITHMS['tradeAlgorithms'][newIndex]     = simpleTrade
ALGORITHMS['settings'][newIndex]            = THVSettings
