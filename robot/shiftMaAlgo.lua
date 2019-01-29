function setTableMAParams(settingsAlgo)

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
    SetCell(t_id, 5, 2, "", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 5, 3, "", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 6, 0, tostring(settingsAlgo.period),          settingsAlgo.period)  
    SetCell(t_id, 6, 1, tostring(settingsAlgo.shift),      settingsAlgo.shift)
    SetCell(t_id, 6, 2, "",      0)
    SetCell(t_id, 6, 3, "",      0)
    SetCell(t_id, 6, 6, tostring(settingsAlgo.STOP_LOSS), settingsAlgo.STOP_LOSS)  
    SetCell(t_id, 6, 7, tostring(settingsAlgo.TAKE_PROFIT))

end

function readTableMAParams()

    Settings.period = GetCell(t_id, 6, 0).value
    Settings.shift = GetCell(t_id, 6, 1).value
    Settings.STOP_LOSS = GetCell(t_id, 6, 6).value
    Settings.TAKE_PROFIT = tonumber(GetCell(t_id, 6, 7).image)

end

function readOptimizedMA()
    local ParamsFile = io.open(PARAMS_FILE_NAME,"r")
    if ParamsFile ~= nil then
        local lineCount = 0
        local SettingsKeys = {}
        for line in ParamsFile:lines() do
            lineCount = lineCount + 1
            if lineCount > 1 and line ~= "" then
                local per1, per2, per3, per4, per5, per6 = line:match("%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*)")
                if INTERVAL == tonumber(per1) then
                    testSizeBars        = tonumber(per2)
                    Settings.period     = tonumber(per3)
                    Settings.shift      = tonumber(per4)
                    Settings.STOP_LOSS      = tonumber(per5)
                    Settings.TAKE_PROFIT    = tonumber(per6)
                end
            end
        end
        ParamsFile:close()
    else
        myLog("Файл параметров "..PARAMS_FILE_NAME.." не найден")
    end
end

function saveOptimizedMA(settings)
    
    local ParamsFile = io.open(PARAMS_FILE_NAME,"w")
    local firstString = "INTERVAL; testSizeBars; period; shift; STOP_LOSS; TAKE_PROFIT"
    ParamsFile:write(firstString.."\n")
    local paramsString = tostring(INTERVAL)..";"..tostring(testSizeBars)..";"..tostring(settings.period)..";"..tostring(settings.shift)..";"..tostring(settings.STOP_LOSS)..";"..tostring(settings.TAKE_PROFIT)
    ParamsFile:write(paramsString.."\n")
    ParamsFile:flush()
    ParamsFile:close()

end

--- Алгоритм
function initMA()
    ATR = nil
    trend=nil
    calcAlgoValue = nil     --      Возвращаемая таблица
    calcChartResults = nil     --      Возвращаемая таблица

	EMA=nil
end

function iterateMA()
    
    param1Min = 4
    param1Max = 82
    param1Step = 1

    param2Min = 1
    param2Max = 28
    param2Step = 1

    if ROBOT_STATE == 'РЕОПТИМИЗАЦИЯ' then
        param1Min = math.max(param1Min, Settings.period-30)
        param1Max = math.min(param1Max, Settings.period+30)
    end    

    local settingsTable = {}
    local allCount = 0

    for param1 = param1Min, param1Max, param1Step do               
        for param2 = param2Min, math.ceil(0.8*param1), param2Step do    
            allCount = allCount + 1
            
            settingsTable[allCount] = {
                period    = param1,                   
                shift    = param2
            }               
        end
    end

    iterateAlgorithm(settingsTable)

end

function MA(index, Fsettings)

    local period = Fsettings.period or 32
    local shift = Fsettings.shift or 2

    local indexToCalc = 1000
    indexToCalc = Fsettings.indexToCalc or indexToCalc
    local beginIndexToCalc = Fsettings.beginIndexToCalc or math.max(1, DS:Size() - indexToCalc)

    if index == nil then index = 1 end
    
    local kawg = 2/(period+1)
   
    if index == beginIndexToCalc then        

        --if ROBOT_STATE ~= 'РЕОПТИМИЗАЦИЯ' then
        --    myLog("--------------------------------------------------")
        --    myLog("Показатель Period "..tostring(period))
        --    myLog("Показатель shift "..tostring(shift))
        --    myLog("--------------------------------------------------")
        --end

        EMA = {}
        EMA[index] = 1        
       
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

    EMA[index] = EMA[index-1]			
    
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

    EMA[index] = (DS:C(index)+DS:O(index))/2			
    
    if DS:C(index) ~= nil then

        local val = dValue(index,'C')

        EMA[index]=round(kawg*val+(1-kawg)*EMA[index-1], 5)
                
        local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5 
        local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5 
    
        local isBuy = (not isUpPinBar and EMA[index] > EMA[index-shift] and EMA[index-1] <= EMA[index-shift-1]) 
            --or (trend[index] == -1 and EMA[index] > EMA[index-shift] and EMA[index-1] > calcAlgoValue[index-shift])
        local isSell = (not isLowPinBar and EMA[index] < EMA[index-shift] and EMA[index-1] >= EMA[index-shift-1])
             --or (trend[index] == 1 and EMA[index] < EMA[index-shift] and EMA[index-1] < EMA[index-shift])
               
        if isBuy then
            trend[index] = 1
        end
        if isSell then
            trend[index] = -1
        end

        calcAlgoValue[index] = EMA[index]
        --calcAlgoValue[index] = DS:O(index)
    end                
    
    calcChartResults[index] = {EMA[index], EMA[index-shift-1]}

    return calcAlgoValue, trend, calcChartResults
    
end
