-------------------------
--EMA
bolingerSettings = {
    period = 0,
    period2 = 0,
    shift = 0,
    periodATR = 0,
    contr_trend = 0,
    kATR = 0,
    Size = 0
}


function iteratebolinger(iSec, cell)
    
    iterateSLTP = true
    fixedstop = true

    local param1Min = 10
    local param1Max = 25
    local param1Step = 1

    local param2Min = 40
    local param2Max = 80
    local param2Step = 1
    
    local param3Min = 1
    local param3Max = 3
    local param3Step = 1
    
    local param4Min   = 0
    local param4Max   = 1
    local param4Step  = 1  
    
    --local param5Min   = 0.6
    --local param5Max   = 0.75
    --local param5Step  = 0.05 
--
    --if fixedstop then
    --    param4Min   = 10
    --    param4Max   = 10
    --    param4Step  = 1  
    --    
    --    param5Min   = 0.65
    --    param5Max   = 0.65
    --    param5Step  = 0.05 
    --end

    local settingsTable = {}
    local allCount = 0

    for param1 = param1Min, param1Max, param1Step do
        
        _param2Min = math.max(math.ceil(param1+1), param2Min)

        for param2 = _param2Min, param2Max, param2Step do    
            
            --for param3 = param3Min, math.ceil(0.8*param1), param3Step do
            for param3 = param3Min, param3Max, param3Step do
                for param4 = param4Min, param4Max, param4Step do                                    
                    --for param5 = param5Min, param5Max, param5Step do
                        allCount = allCount + 1                        
                        settingsTable[allCount] = {
                            period    = param1,
                            period2 = param2,
                            shift = param3,
                            contr_trend = param4,
                            --periodATR = param4,
                            --kATR = param5,
                            Size = Size
                            }                                          
                    --end
                end
            end
        end
    end

    iterateAlgorithm(iSec, cell, settingsTable)

end

function initbolinger()
    
    EMA=nil
    EMA2=nil

    BB_High_1=nil
    BB_Low_1=nil
    BB_High_2=nil
    BB_Low_2=nil
    
    trend=nil
    calcAlgoValue=nil 
    Trigger=nil 
    calcChartResults=nil 
    ATR = nil
    calcATR = true

end

function bolinger(index, settings, DS)

    local period = settings.period or 29     
    local period2 = settings.period2 or 29     
    local shift = settings.shift or 1     
    local contr_trend = settings.contr_trend or 0     
    local Size = settings.Size or 2000 
    local periodATR = settings.periodATR or 10

    kATR = settings.kATR or 0.65

    local indexToCalc = 1000
    indexToCalc = settings.Size or indexToCalc
    local beginIndexToCalc = settings.beginIndexToCalc or math.max(1, settings.beginIndex - indexToCalc)
    local endIndexToCalc = settings.endIndex or DS:Size()

    --подготавливаем массив данных по периодам
    if index == nil then index = 1 end

    if BB_High_1 == nil then
        
        --myLog("--------------------------------------------------")
        --myLog("Показатель Period "..tostring(period))
        --myLog("Показатель Period2 "..tostring(period2))
        --myLog("Показатель shift "..tostring(shift))
        --myLog("--------------------------------------------------")

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
        EMA2 = {}
        EMA2[index] = 1        
        
        BB_High_1 = {}
        BB_High_1[index] = 1        
        BB_High_2 = {}
        BB_High_2[index] = 1        
        BB_Low_1 = {}
        BB_Low_1[index] = 1        
        BB_Low_2 = {}
        BB_Low_2[index] = 1        
        
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
        
    Open[index] = Open[index-1] 
    High[index] = High[index-1] 
    Low[index] = Low[index-1] 
    Close[index] = Close[index-1] 

    EMA[index] = EMA[index-1]			
    EMA2[index] = EMA2[index-1]			

    BB_High_1[index] = BB_High_1[index-1]			
    BB_High_2[index] = BB_High_2[index-1]			
    BB_Low_1[index] = BB_Low_1[index-1]			
    BB_Low_2[index] = BB_Low_2[index-1]			
    
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
    
    if index <= beginIndexToCalc + (math.max(period, period2, periodATR) + 1) or index > endIndexToCalc then
        return calcAlgoValue, trend, calcChartResults
    end
     
    local k = 2/(period+1)
    local k2 = 2/(period2+1)
    
    EMA[index] = (DS:C(index)+DS:O(index))/2			
    EMA2[index] = (DS:C(index)+DS:O(index))/2			
    
    if DS:C(index) ~= nil then

        local val = dValue(index,'C')

        EMA[index]=round(k*val+(1-k)*EMA[index-1], SCALE)
        EMA2[index]=round(k2*val+(1-k2)*EMA2[index-1], SCALE)

        local bb_sd_1 = SD(Close, period, index)
        BB_High_1[index] = round(EMA[index]+shift*bb_sd_1, SCALE)
        BB_Low_1[index] = round(EMA[index]-shift*bb_sd_1, SCALE)
        
        local bb_sd_2 = SD(Close, period2, index)
        BB_High_2[index] = round(EMA2[index]+shift*bb_sd_2, SCALE)
        BB_Low_2[index] = round(EMA2[index]-shift*bb_sd_2, SCALE)
        
        local isBuy  = false
        local isSell = false
        
        if trend[index] <= 0 and Close[index] > EMA2[index] then
            if contr_trend == 1 then
                isBuy = Close[index] > BB_Low_1[index]
            else
                isBuy = Close[index] > BB_High_1[index]
            end
        end
        if trend[index] >= 0 and Close[index] < EMA2[index] then
            if contr_trend == 1 then
                isSell = Close[index] < BB_High_1[index]
            else
                isSell = Close[index] < BB_Low_1[index]
            end
        end

        if isBuy then
            trend[index] = 1
        end
        if isSell then
            trend[index] = -1
        end

        calcAlgoValue[index] = DS:C(index)
        --calcAlgoValue[index] = EMA[index]
    end                
    calcChartResults[index] = {BB_High_1[index], BB_High_2[index], BB_Low_1[index], BB_Low_2[index]}

    return calcAlgoValue, trend, calcChartResults 
    
end

function SD(table, period, end_index) --Standard Deviation ("SD")
    local Out = nil
    local sum = 0 
    local begin_index = end_index - period

    local function SD_MA()
        local sum = 0
        for i = begin_index+1, end_index do
			sum = sum + table[i]
		end
		return  sum/(end_index-begin_index)
    end

    local t_ma = SD_MA()

    for i = begin_index+1, end_index do
        sum = sum + (table[i] - t_ma)^2
    end
    Out = math.sqrt(sum/(end_index-begin_index)) 
    return round(Out, SCALE) 
end

local newIndex = #ALGORITHMS['names']+1

ALGORITHMS['names'][newIndex]               = "bolinger"      
ALGORITHMS['initParams'][newIndex]          = initbolinger    
ALGORITHMS['initAlgorithms'][newIndex]      = initbolinger    
ALGORITHMS['itetareAlgorithms'][newIndex]   = iteratebolinger 
ALGORITHMS['calcAlgorithms'][newIndex]      = bolinger        
ALGORITHMS['tradeAlgorithms'][newIndex]     = simpleTrade     
ALGORITHMS['settings'][newIndex]            = bolingerSettings
