function setTableTHVParams(settingsAlgo)

    --можно испрльзовать 5 колонок в трех строках
    --одна строка уже добавлена, если нужны еще две, то надо добвать строки
    local rows,_ = GetTableSize(t_id)
    if rows > 6 then
        for i=1,4 do
            DeleteRow(t_id, 7)
        end        
    end

    SetCell(t_id, 5, 0, "period", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 5, 1, "shift", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 5, 2, "koef", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 5, 3, "", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 6, 0, tostring(settingsAlgo.period),     settingsAlgo.period)  
    SetCell(t_id, 6, 1, tostring(settingsAlgo.shift),      settingsAlgo.shift)
    SetCell(t_id, 6, 2, tostring(settingsAlgo.koef),       settingsAlgo.koef)  
    SetCell(t_id, 6, 3, "",      0)
    SetCell(t_id, 6, 6, tostring(settingsAlgo.STOP_LOSS), settingsAlgo.STOP_LOSS)  
    SetCell(t_id, 6, 7, tostring(settingsAlgo.TAKE_PROFIT))

end

function readTableTHVParams()

    Settings.period = GetCell(t_id, 6, 0).value
    Settings.shift  = GetCell(t_id, 6, 1).value
    Settings.koef   = GetCell(t_id, 6, 2).value
    Settings.STOP_LOSS = GetCell(t_id, 6, 6).value
    Settings.TAKE_PROFIT = tonumber(GetCell(t_id, 6, 7).image)

end

function readOptimizedTHV()
    local ParamsFile = io.open(PARAMS_FILE_NAME,"r")
    if ParamsFile ~= nil then
        local lineCount = 0
        local SettingsKeys = {}
        for line in ParamsFile:lines() do
            lineCount = lineCount + 1
            if lineCount > 1 and line ~= "" then
                local per1, per2, per3, per4, per5, per6, per7 = line:match("%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*)")
                if INTERVAL == tonumber(per1) then
                    testSizeBars        = tonumber(per2)
                    Settings.period     = tonumber(per3)
                    Settings.shift      = tonumber(per4)
                    Settings.koef       = tonumber(per5)
                    Settings.STOP_LOSS      = tonumber(per6)
                    Settings.TAKE_PROFIT    = tonumber(per7)
                end
            end
        end
        ParamsFile:close()
    else
        myLog("Файл параметров "..PARAMS_FILE_NAME.." не найден")
    end
end

function saveOptimizedTHV(settings)
    
    local ParamsFile = io.open(PARAMS_FILE_NAME,"w")
    local firstString = "INTERVAL; testSizeBars; period; shift; koef; STOP_LOSS; TAKE_PROFIT"
    ParamsFile:write(firstString.."\n")
    local paramsString = tostring(INTERVAL)..";"..tostring(testSizeBars)..";"..tostring(settings.period)..";"..tostring(settings.shift)..";"..tostring(settings.koef)..";"..tostring(settings.STOP_LOSS)..";"..tostring(settings.TAKE_PROFIT)
    ParamsFile:write(paramsString.."\n")
    ParamsFile:flush()
    ParamsFile:close()

end

--- Алгоритм
function initTHV()
    ATR = nil
    trend=nil
    calcAlgoValue = nil     --      Возвращаемая таблица
    calcChartResults = nil     --      Возвращаемая таблица

	g_ibuf_104=nil
	gda_108=nil
	gda_112=nil
	gda_116=nil
	gda_120=nil
	gda_124=nil
	gda_128=nil
end

function iterateTHV()
    
    param1Min = 8
    param1Max = 48
    param1Step = 1

    param2Min = 0.6
    param2Max = 2.1
    param2Step = 0.1

    param3Min = 1
    param3Max = 28
    param3Step = 1
    
    if ROBOT_STATE == 'РЕОПТИМИЗАЦИЯ' then
        param1Min = math.max(param1Min, Settings.period-12)
        param1Max = math.min(param1Max, Settings.period+12)
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
                    koef    =   param2,                   
                    shift    = param3
                }               
            end
        end
    end

    iterateAlgorithm(settingsTable)

end

function THV(index, Fsettings)

    local period = Fsettings.period or 32
    local koef = Fsettings.koef or 1
    local shift = Fsettings.shift or 2

    local indexToCalc = 1000
    indexToCalc = Fsettings.indexToCalc or indexToCalc
    local beginIndexToCalc = Fsettings.beginIndexToCalc or math.max(1, DS:Size() - indexToCalc)

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

    local kawg = 2/(period+1)
   
    if index == beginIndexToCalc then        

        --if ROBOT_STATE ~= 'РЕОПТИМИЗАЦИЯ' then
        --    myLog("--------------------------------------------------")
        --    myLog("Показатель Period "..tostring(period))
        --    myLog("Показатель shift "..tostring(shift))
        --    myLog("Показатель koef "..tostring(koef))
        --    myLog("--------------------------------------------------")
        --end

        g_ibuf_104={}
        gda_108={}
        gda_112={}
        gda_116={}
        gda_120={}
        gda_124={}
        gda_128={}
        
        g_ibuf_104[index]=0
        gda_108[index]=0
        gda_112[index]=0
        gda_116[index]=0
        gda_120[index]=0
        gda_124[index]=0
        gda_128[index]=0
        
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

    g_ibuf_104[index] = g_ibuf_104[index-1] 
    gda_108[index] = gda_108[index-1]
    gda_112[index] = gda_112[index-1]
    gda_116[index] = gda_116[index-1] 
    gda_120[index] = gda_120[index-1]
    gda_124[index] = gda_124[index-1]
    gda_128[index] = gda_128[index-1] 
    
    ATR[index] = ATR[index-1]     
    calcAlgoValue[index] = calcAlgoValue[index-1]
    trend[index] = trend[index-1] 
    calcChartResults[index] = calcChartResults[index-1]

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
        --ATR[index] = kawg*dValue(index)+(1-kawg)*ATR[index-1]
    end
    
    if index <= beginIndexToCalc + (period + shift + 1) then
        return calcAlgoValue
    end

    if DS:C(index) ~= nil then        
        
		local previous = index-1		
		if DS:C(previous) == nil then
			previous = FindExistCandle(previous)
		end

        gda_108[index] = gd_172 * DS:C(index) + gd_180 * (gda_108[previous])
		gda_112[index] = gd_172 * (gda_108[index]) + gd_180 * (gda_112[previous])
		gda_116[index] = gd_172 * (gda_112[index]) + gd_180 * (gda_116[previous])
		gda_120[index] = gd_172 * (gda_116[index]) + gd_180 * (gda_120[previous])
		gda_124[index] = gd_172 * (gda_120[index]) + gd_180 * (gda_124[previous])
		gda_128[index] = gd_172 * (gda_124[index]) + gd_180 * (gda_128[previous])
		g_ibuf_104[index] = gd_132 * (gda_128[index]) + gd_140 * (gda_124[index]) + gd_148 * (gda_120[index]) + gd_156 * (gda_116[index])
                   
        local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5 
        local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5 
    
        local isBuy = (not isUpPinBar and g_ibuf_104[index] > g_ibuf_104[index-shift] and g_ibuf_104[index-1] <= g_ibuf_104[index-shift-1]) 
            --or (trend[index] == -1 and g_ibuf_104[index] > g_ibuf_104[index-shift] and g_ibuf_104[index-1] > g_ibuf_104[index-shift])
        local isSell = (not isLowPinBar and g_ibuf_104[index] < g_ibuf_104[index-shift] and g_ibuf_104[index-1] >= g_ibuf_104[index-shift-1])
             --or (trend[index] == 1 and g_ibuf_104[index] < g_ibuf_104[index-shift] and g_ibuf_104[index-1] < g_ibuf_104[index-shift])
        
        if isBuy then
            trend[index] = 1
        end
        if isSell then
            trend[index] = -1
        end

        --calcAlgoValue[index] = DS:O(index)
        calcAlgoValue[index] = g_ibuf_104[index]
        calcChartResults[index] = {g_ibuf_104[index], g_ibuf_104[index-shift-1]}
    
    end

    if not optimizationInProgress then
        local roundAlgoVal = round(calcAlgoValue[index], scale)
        SetCell(t_id, 2, 1, tostring(roundAlgoVal), roundAlgoVal) 
    end
            
    return calcAlgoValue
    
end
