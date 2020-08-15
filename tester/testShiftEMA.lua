-------------------------
--EMA
shiftEMASettings = {
    period = 0,
    period2 = 0,
    shift = 1,
    Size = 0
}


function iterateShiftEMA(iSec, cell)
    
    iterateSLTP = false
 
    local param1Min = 20
    local param1Max = 120
    local param1Step = 1

    local param2Min = 20
    local param2Max = 180
    local param2Step = 1
    
    local param3Min = 1
    local param3Max = 10
    local param3Step = 1

    local settingsTable = {}
    local allCount = 0

    for param1 = param1Min, param1Max, param1Step do
        
        --_param2Min = math.max(math.ceil(param1+1), param2Min)

        for param2 = param2Min, param2Max, param2Step do    
            
            for param3 = param3Min, math.ceil(0.8*param1), param3Step do
            --for param3 = param3Min, param3Max, param3Step do
                allCount = allCount + 1
                
                settingsTable[allCount] = {
                    period    = param1,
                    period2 = param2, -- 1 -линейная, 2 - параболическая, - 3 степени
                    shift = param3,
                    Size = Size
                    }
            
                
            end
        end
    end

    iterateAlgorithm(iSec, cell, settingsTable)

end

function initShiftEMA()
    EMA=nil
    TEMA=nil
	cache_TEMA1=nil
	cache_TEMA2=nil
	cache_TEMA3=nil
    trend=nil
    calcAlgoValue=nil 
    calcChartResults=nil 

	MA = nil
	Y = nil
	Close = nil    
	Open = nil
	High = nil
    Low = nil
    Cycle = nil
    it = nil
    Price = nil
end

function shiftEMA(index, settings, DS)

    local period = settings.period or 29     
    local period2 = settings.period2 or 29     
    local shift = settings.shift or 1     
    local Size = settings.Size or 2000 
    
    local indexToCalc = 1000
    indexToCalc = settings.Size or indexToCalc
    local beginIndexToCalc = settings.beginIndexToCalc or math.max(1, settings.beginIndex - indexToCalc)
    local endIndexToCalc = settings.endIndex or DS:Size()

    --подготавливаем массив данных по периодам
    if index == nil then index = 1 end

    if EMA == nil then
        
        myLog("--------------------------------------------------")
        myLog("Показатель Period "..tostring(period))
        myLog("Показатель Period2 "..tostring(period2))
        myLog("Показатель shift "..tostring(shift))
        myLog("--------------------------------------------------")

        MA = {}
        MA[index] = 0
        Y = {}
        Y[index] = 0

        Close = {}
        Close[index] = 0
        Open = {}
        Open[index] = 0
        High = {}
        High[index] = 0
        Low = {}
        Low[index] = 0

        EMA = {}
        EMA[index] = 1        
        TEMA = {}
        TEMA[index] = 1        
        cache_TEMA1={}
        cache_TEMA2={}
        cache_TEMA3={}
        cache_TEMA1[index]= 0
        cache_TEMA2[index]= 0
        cache_TEMA3[index]= 0
        trend = {}
        trend[index] = 1
        calcAlgoValue = {}
        calcAlgoValue[index] = {}
        calcChartResults = {}
        calcChartResults[index] = {}

        return calcAlgoValue, trend, calcChartResults
    end
        
    MA[index] = MA[index-1] 
    Open[index] = Open[index-1] 
    High[index] = High[index-1] 
    Low[index] = Low[index-1] 
    Close[index] = Close[index-1] 
    Y[index] = Y[index-1]

    EMA[index] = EMA[index-1]			
    TEMA[index] = TEMA[index-1]			
    cache_TEMA1[index] = cache_TEMA1[index-1] 
    cache_TEMA2[index] = cache_TEMA2[index-1]
    cache_TEMA3[index] = cache_TEMA3[index-1]
    calcAlgoValue[index] = calcAlgoValue[index-1]			
    trend[index] = trend[index-1] 
    calcChartResults[index] = calcChartResults[index-1] 
   
    if index <= beginIndexToCalc + period + shift + 20 or index > endIndexToCalc then
        return calcAlgoValue, trend, calcChartResults
    end
 
    local k = 2/(period2+1)
    local kTEMA = 2/(period+1)
    
    EMA[index] = (DS:C(index)+DS:O(index))/2			
    
    if DS:C(index) ~= nil then

        local val = dValue(index,'C')

        EMA[index]=round(k*val+(1-k)*EMA[index-1], 5)
        
        cache_TEMA1[index]=kTEMA*val+(1-kTEMA)*cache_TEMA1[index-1]
		cache_TEMA2[index]=kTEMA*cache_TEMA1[index]+(1-kTEMA)*cache_TEMA2[index-1]
		cache_TEMA3[index]=kTEMA*cache_TEMA2[index]+(1-kTEMA)*cache_TEMA3[index-1]
        
        TEMA[index] = 3*cache_TEMA1[index] - 3*cache_TEMA2[index] + cache_TEMA3[index]
        
        local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5 
        local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5 
        --not isUpPinBar and 
        --not isLowPinBar and 

        local isBuy = (TEMA[index] > EMA[index-shift] and TEMA[index-1] <= EMA[index-shift-1]) 
        local isSell = (TEMA[index] < EMA[index-shift] and TEMA[index-1] >= EMA[index-shift-1])
                
        if isBuy then
            trend[index] = 1
        end
        if isSell then
            trend[index] = -1
        end

        calcAlgoValue[index] = TEMA[index]
    end                

    calcChartResults[index] = {TEMA[index], EMA[index-shift-1]}

    return calcAlgoValue, trend, calcChartResults 
    
end


local newIndex = #ALGORITHMS['names']+1

ALGORITHMS['names'][newIndex]               = "ShiftEMA"
ALGORITHMS['initParams'][newIndex]          = initShiftEMA
ALGORITHMS['initAlgorithms'][newIndex]      = initShiftEMA
ALGORITHMS['itetareAlgorithms'][newIndex]   = iterateShiftEMA
ALGORITHMS['calcAlgorithms'][newIndex]      = shiftEMA
ALGORITHMS['tradeAlgorithms'][newIndex]     = simpleTrade
ALGORITHMS['settings'][newIndex]            = shiftEMASettings
