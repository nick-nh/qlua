-------------------------
--SAR
SARSettings = {
        SarPeriod    = 0,
        SarPeriod2 = 0,
        SarDeviation = 0,
        Size = 0
}

function initSAR()
    cache_SAR=nil
    cache_ST=nil
    EMA=nil
    BB=nil
end

function iterateSAR(iSec, cell)

    param1Min = 4
    param1Max = 64
    param1Step = 2

    param2Min = 112
    param2Max = 312
    param2Step = 2

    param3Min = 0.4
    param3Max = 5
    param3Step = 0.1


    local allCount = 0
    local settingsTable = {}

    for _SarPeriod = param1Min, param1Max, param1Step do
        for _SarPeriod2 = param2Min, param2Max, param2Step do
            for _SarDeviation = param3Min, param3Max, param3Step do

                allCount = allCount + 1

                settingsTable[allCount] = {
                    SarPeriod    = _SarPeriod,
                    SarPeriod2 = _SarPeriod2,
                    SarDeviation = _SarDeviation,
                    Size = Size
                }


            end
        end
    end

    iterateAlgorithm(iSec, cell, settingsTable)

end

function SAR(index, settings, DS)

    local SarPeriod = settings.SarPeriod or 32
    local SarPeriod2 = settings.SarPeriod2 or 256
    local SarDeviation = settings.SarDeviation or 3
    local sigma = 0

    local indexToCalc = 1000
    indexToCalc = settings.Size or indexToCalc
    local beginIndexToCalc = settings.beginIndexToCalc or math.max(1, settings.beginIndex - indexToCalc)
    local endIndexToCalc = settings.endIndex or DS:Size()

    if index == nil then index = 1 end

    if cache_SAR == nil then
        myLog("Показатель SarPeriod "..tostring(SarPeriod))
        myLog("Показатель SarPeriod2 "..tostring(SarPeriod2))
        myLog("Показатель SarDeviation "..tostring(SarDeviation))
        myLog("--------------------------------------------------")
        cache_SAR={}
        cache_ST={}
        EMA={}
        BB={}
        BB[index]=0
        cache_SAR[index]=0
        EMA[index]=0
        cache_ST[index]=1
        return cache_SAR
    end

    EMA[index]=EMA[index-1]
    BB[index]=BB[index-1]
    cache_SAR[index]=cache_SAR[index-1]
    cache_ST[index]=cache_ST[index-1]

    if index < beginIndexToCalc or index > endIndexToCalc then
        return cache_SAR, cache_ST, cache_SAR
    end

    if DS:C(index) ~= nil then

        EMA[index]=(2/(SarPeriod/2+1))*DS:C(index)+(1-2/(SarPeriod/2+1))*EMA[index-1]
        BB[index]=(2/(SarPeriod2/2+1))*(DS:C(index)-EMA[index])^2+(1-2/(SarPeriod2/2+1))*BB[index-1]

        sigma=BB[index]^(1/2)

        if index ==2 then
            return cache_SAR
        end

        if cache_ST[index] == 1 then

            cache_SAR[index]=math.max((EMA[index]-sigma*SarDeviation),cache_SAR[index-1])

            if (cache_SAR[index] > DS:C(index)) then
                cache_ST[index] = -1
                cache_SAR[index]=EMA[index]+sigma*SarDeviation
            end
        elseif cache_ST[index] == -1 then

            cache_SAR[index]=math.min((EMA[index]+sigma*SarDeviation),cache_SAR[index-1])

            if (cache_SAR[index] < DS:C(index)) then
                cache_ST[index] = 1
                cache_SAR[index]=EMA[index]-sigma*SarDeviation
            end
        end
    end

    return cache_SAR, cache_ST, cache_SAR

end

local newIndex = #ALGORITHMS['names']+1

ALGORITHMS['names'][newIndex]               = "Sar"
ALGORITHMS['initParams'][newIndex]          = initSAR
ALGORITHMS['initAlgorithms'][newIndex]      = initSAR
ALGORITHMS['itetareAlgorithms'][newIndex]   = iterateSAR
ALGORITHMS['calcAlgorithms'][newIndex]      = SAR
ALGORITHMS['tradeAlgorithms'][newIndex]     = simpleTrade
ALGORITHMS['settings'][newIndex]            = SARSettings
