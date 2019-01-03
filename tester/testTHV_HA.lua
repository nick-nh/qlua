-------------------------
--THV

THVSettings = {
    period    = 1,
    koef = 1, 
    shift = 1,
    Size = 0
}

function initTHV()
	g_ibuf_92=nil
	g_ibuf_96=nil
	g_ibuf_100=nil
	g_ibuf_104=nil
	gda_108=nil
	gda_112=nil
	gda_116=nil
	gda_120=nil
	gda_124=nil
	gda_128=nil
	cache_O=nil
	cache_C=nil
    trend=nil
    calcChartResults=nil
    ATR=nil
    calcATR = true
end

function iterateTHV(iSec, cell)
    
    iterateSLTP = false

    param1Min = 8
    param1Max = 112
    param1Step = 1

    param2Min = 0.3
    param2Max = 2.1
    param2Step = 0.1

    param3Min = 1
    param3Max = 38
    param3Step = 1
    
    local settingsTable = {}
    local allCount = 0

    for param1 = param1Min, param1Max, param1Step do               
        for param2 = param2Min, param2Max, param2Step do    
            local calculatedShift = {}
            for param3 = param3Min, math.ceil(0.8*param1), param3Step do
            --for param3 = param3Min, param3Max, param3Step do
                    allCount = allCount + 1
                    
                    settingsTable[allCount] = {
                        period    = param1,                   
                        koef    =   param2,                   
                        shift    = param3,
                        Size = Size
                    }
            end
        end
    end

    iterateAlgorithm(iSec, cell, settingsTable)

end

function THV(index, settings, DS)

    local period = settings.period or 32
    local koef = settings.koef or 1
    local shift = settings.shift or 1

    local indexToCalc = 1000
    indexToCalc = settings.Size or indexToCalc
    local beginIndexToCalc = settings.beginIndexToCalc or math.max(1, settings.beginIndex - indexToCalc)
    local endIndexToCalc = settings.endIndex or DS:Size()

    if index == nil then index = 1 end
    
    local ild_0
    local ld_8

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

    local openHA
    local closeHA
    local highHA
    local lowHA
    
    if g_ibuf_96 == nil then

        myLog("Показатель Period "..tostring(period))
        myLog("Показатель koef "..tostring(koef))
        myLog("Показатель shift "..tostring(shift))
        myLog("--------------------------------------------------")
        
        g_ibuf_92={}
        g_ibuf_96={}
        g_ibuf_100={}
        g_ibuf_104={}
        gda_108={}
        gda_112={}
        gda_116={}
        gda_120={}
        gda_124={}
        gda_128={}
        
        g_ibuf_92[index]=0
        g_ibuf_96[index]=0
        g_ibuf_100[index]=0
        g_ibuf_104[index]=0
        gda_108[index]=0
        gda_112[index]=0
        gda_116[index]=0
        gda_120[index]=0
        gda_124[index]=0
        gda_128[index]=0

        trend = {}
        trend[index] = 1
        calcChartResults = {}
        calcChartResults[index] = {}
        
        cache_O = {}
        cache_C = {}
        cache_O[index]= 0
        cache_C[index]= 0
        ATR = {}
        ATR[index] = 0			

        return cache_O, nil, calcChartResults
    end

    g_ibuf_92[index] = g_ibuf_92[index-1] 
    g_ibuf_96[index] = g_ibuf_96[index-1]
    g_ibuf_100[index] = g_ibuf_100[index-1]
    g_ibuf_104[index] = g_ibuf_104[index-1] 
    gda_108[index] = gda_108[index-1]
    gda_112[index] = gda_112[index-1]
    gda_116[index] = gda_116[index-1] 
    gda_120[index] = gda_120[index-1]
    gda_124[index] = gda_124[index-1]
    gda_128[index] = gda_128[index-1] 
    
    trend[index] = trend[index-1] 
    calcChartResults[index] = calcChartResults[index-1] 

    cache_O[index] = cache_O[index-1] 
    cache_C[index] = cache_C[index-1] 
    ATR[index] = ATR[index-1]

    if index<period then
        ATR[index] = 0
    elseif index==period then
        local sum=0
        for i = 1, period do
            sum = sum + dValue(i)
        end
        ATR[index]=sum / period
    elseif index>period then
        ATR[index]=(ATR[index-1] * (period-1) + dValue(index)) / period
    end

    if index <= beginIndexToCalc + (period + shift + 1) or index > endIndexToCalc then
        return cache_O, nil, calcChartResults
    end

    local typeVal = 'C'

    if DS:C(index) ~= nil then        
        
		local previous = index-1		
		if DS:C(previous) == nil then
			previous = FindExistCandle(previous)
		end

        local val = dValue(index,typeVal)

        gda_108[index] = gd_172 * val + gd_180 * (gda_108[previous])
		gda_112[index] = gd_172 * (gda_108[index]) + gd_180 * (gda_112[previous])
		gda_116[index] = gd_172 * (gda_112[index]) + gd_180 * (gda_116[previous])
		gda_120[index] = gd_172 * (gda_116[index]) + gd_180 * (gda_120[previous])
		gda_124[index] = gd_172 * (gda_120[index]) + gd_180 * (gda_124[previous])
		gda_128[index] = gd_172 * (gda_124[index]) + gd_180 * (gda_128[previous])
		g_ibuf_104[index] = gd_132 * (gda_128[index]) + gd_140 * (gda_124[index]) + gd_148 * (gda_120[index]) + gd_156 * (gda_116[index])
		ld_0 = g_ibuf_104[index]
		ld_8 = g_ibuf_104[previous]
        
        g_ibuf_92[index] = ld_0
		g_ibuf_96[index] = ld_0
		g_ibuf_100[index] = ld_0
        
		--cache_O[index]=DS:O(index)
		--cache_C[index]=DS:C(index)

        --if ld_8 > ld_0 and cache_O[index] > cache_C[index] and cache_O[index-1] > cache_C[index-1] then 
		--	trend[index] = -1
        --end
        --if ld_8 < ld_0 and cache_O[index] < cache_C[index] and cache_O[index-1] < cache_C[index-1] then
		--	trend[index] = 1
		--end
        --if g_ibuf_96[index] > DS:C(index) and cache_O[index] > cache_C[index] and cache_O[index-1] > cache_C[index-1] then 
		--	trend[index] = -1
        --end
        --if g_ibuf_96[index] < DS:C(index) and cache_O[index] < cache_C[index] and cache_O[index-1] < cache_C[index-1]  then 
		--	trend[index] = 1 
        --end
            
        local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5 
        local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5 
    
        local isBuy = (not isUpPinBar and g_ibuf_96[index] > g_ibuf_96[index-shift] and g_ibuf_96[index-1] <= g_ibuf_96[index-shift-1]) --and cache_O[index] > cache_C[index-shift] 
        local isSell = (not isLowPinBar and g_ibuf_96[index] < g_ibuf_96[index-shift] and g_ibuf_96[index-1] >= g_ibuf_96[index-shift-1]) --and cache_O[index] > cache_C[index-shift]
        
        if isBuy then
            trend[index] = 1
        end
        if isSell then
            trend[index] = -1
        end
        
    end
    
    calcChartResults[index] = {g_ibuf_96[index], g_ibuf_96[index-shift-1]}

    return g_ibuf_96, trend, calcChartResults
    
end

