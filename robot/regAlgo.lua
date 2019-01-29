function setTableRegParams(settingsAlgo)

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
    SetCell(t_id, 5, 2, "degree", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 5, 3, "kstd", 0)  --i строка, 0 - колонка, v - значение 
    SetCell(t_id, 6, 0, tostring(settingsAlgo.period),     settingsAlgo.period)  
    SetCell(t_id, 6, 1, tostring(settingsAlgo.shift),      settingsAlgo.shift)
    SetCell(t_id, 6, 2, tostring(settingsAlgo.degree),     settingsAlgo.degree)  
    SetCell(t_id, 6, 3, tostring(settingsAlgo.kstd),       settingsAlgo.kstd)  
    SetCell(t_id, 6, 6, tostring(settingsAlgo.STOP_LOSS), settingsAlgo.STOP_LOSS)   
    SetCell(t_id, 6, 7, tostring(settingsAlgo.TAKE_PROFIT)) 

end

function readTableRegParams()

    Settings.period  = GetCell(t_id, 6, 0).value
    Settings.shift   = GetCell(t_id, 6, 1).value
    Settings.degree  = GetCell(t_id, 6, 2).value
    Settings.kstd    = GetCell(t_id, 6, 3).value
    Settings.STOP_LOSS = GetCell(t_id, 6, 6).value
    Settings.TAKE_PROFIT = tonumber(GetCell(t_id, 6, 7).image)

end

function readOptimizedReg()
    local ParamsFile = io.open(PARAMS_FILE_NAME,"r")
    if ParamsFile ~= nil then
        local lineCount = 0
        local SettingsKeys = {}
        for line in ParamsFile:lines() do
            lineCount = lineCount + 1
            if lineCount > 1 and line ~= "" then
                local per1, per2, per3, per4, per5, per6, per7, per8 = line:match("%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*);%s*(.*)")
                if INTERVAL == tonumber(per1) then
                    testSizeBars        = tonumber(per2)
                    Settings.period     = tonumber(per3)
                    Settings.shift      = tonumber(per4)
                    Settings.degree     = tonumber(per5)
                    Settings.kstd       = tonumber(per6)
                    Settings.STOP_LOSS      = tonumber(per7)
                    Settings.TAKE_PROFIT    = tonumber(per8)
                end
            end
        end
        ParamsFile:close()
    else
        myLog("Файл параметров "..PARAMS_FILE_NAME.." не найден")
    end
end

function saveOptimizedReg(settings)
    
    local ParamsFile = io.open(PARAMS_FILE_NAME,"w")
    local firstString = "INTERVAL;testSizeBars;period;shift;degree;kstd; STOP_LOSS; TAKE_PROFIT"
    ParamsFile:write(firstString.."\n")
    local paramsString = tostring(INTERVAL)..";"..tostring(testSizeBars)..";"..tostring(settings.period)..";"..tostring(settings.shift)..";"..tostring(settings.degree)..";"..tostring(settings.kstd)..";"..tostring(settings.STOP_LOSS)..";"..tostring(settings.TAKE_PROFIT)
    ParamsFile:write(paramsString.."\n")
    ParamsFile:flush()
    ParamsFile:close()

end

--- Алгоритм
function initReg()
    trend=nil
    ATR = nil
    calcAlgoValue = nil     --      Возвращаемая таблица
    calcChartResults = nil     --      Возвращаемая таблица
    sx = nil
end

-------------------------------------
--Оптимизация
function iterateReg()

    param1Min = 8
    param1Max = 38
    param1Step = 1

    param2Min = 1
    param2Max = 3
    param2Step = 1

    param3Min = 1
    param3Max = 38
    param3Step = 1    

    if ROBOT_STATE == 'РЕОПТИМИЗАЦИЯ' then
        param1Min = math.max(param1Min, Settings.period-10)
        param1Max = math.min(param1Max, Settings.period+10)
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
                    degree = param2, -- 1 -линейная, 2 - параболическая, - 3 степени
                    shift = param3,
                    kstd = 3 --отклонение сигма
                    }
                
            end
        end
    end

    iterateAlgorithm(settingsTable)

end

function iReg(index, Fsettings)
									
    local period = Fsettings.period or 182
    local degree = Fsettings.degree or 1
    local kstd = Fsettings.kstd or 3
    local shift = Fsettings.shift or 2
    
    local indexToCalc = 1000
    indexToCalc = Fsettings.indexToCalc or indexToCalc
    local beginIndexToCalc = Fsettings.beginIndexToCalc or math.max(1, DS:Size() - indexToCalc)

    if index == nil then index = 1 end

    period = math.min(period, DS:Size())

    --myLog("period "..tostring(period)..", degree "..tostring(degree)..", kstd "..tostring(kstd)..", shift "..tostring(shift))
    
    local p = 0
    local n = 0
    local f = 0
    local qq = 0
    local mm = 0
    local tt = 0
    local ii = 0
    local jj = 0
    local kk = 0
    local ll = 0
    local nn = 0
    local sq = 0
    local i0 = 0
    
    local mi = 0
    local ai={{1,2,3,4}, {1,2,3,4}, {1,2,3,4}, {1,2,3,4}}		
    local b={}
    local x={}
    
    p = period 
    nn = degree+1
    local kawg = 2/(period+1)
 
    if index == beginIndexToCalc then
        ATR = {}
        ATR[index] = 0			
                
        calcAlgoValue = {}
        calcAlgoValue[index]= 0
        trend = {}
        trend[index] = 1

        calcChartResults = {}
        calcChartResults[index]= {nil,nil}
    
        --- sx 
        sx={}
        sx[1] = p+1
        
        for mi=1, nn*2-2 do
            sum=0
            for n=i0, i0+p do
                sum = sum + math.pow(n,mi)
            end
            sx[mi+1]=sum
        end
        
        return calcAlgoValue
    end
                
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
        --myLog('ATR '..tostring(ATR[index]))
    end

    if index < beginIndexToCalc + (period + shift + 1) then
        return calcAlgoValue
    end
                    
    --- syx 
    for mi=1, nn do
        sum = 0
        for n=i0, i0+p do
            if DS:C(index+n-period) ~= nil then
                if mi==1 then
                   sum = sum + DS:C(index+n-period)
                else
                   sum = sum + DS:C(index+n-period)*math.pow(n,mi-1)
                end
            end
        end
        b[mi]=sum
    end
         
    --- Matrix 
    for jj=1, nn do
        for ii=1, nn do
            kk=ii+jj-1
            ai[ii][jj]=sx[kk]
        end
    end
         
    --- Gauss 
    for kk=1, nn-1 do
        ll=0
        mm=0
        for ii=kk, nn do
            if math.abs(ai[ii][kk])>mm then
                mm=math.abs(ai[ii][kk])
                ll=ii
            end
        end
            
        if ll==0 then
            return calcAlgoValue
        end
        if ll~=kk then

            for jj=1, nn do
                tt=ai[kk][jj]
                ai[kk][jj]=ai[ll][jj]
                ai[ll][jj]=tt
            end
            tt=b[kk]
            b[kk]=b[ll]
            b[ll]=tt
        end
        for ii=kk+1, nn do
            qq=ai[ii][kk]/ai[kk][kk]
            for jj=1, nn do
                if jj==kk then
                    ai[ii][jj]=0
                else
                    ai[ii][jj]=ai[ii][jj]-qq*ai[kk][jj]
                end
            end
            b[ii]=b[ii]-qq*b[kk]
        end
    end
       
     x[nn]=b[nn]/ai[nn][nn]
       
    for ii=nn-1, 1, -1 do
        tt=0
        for jj=1, nn-ii do
            tt=tt+ai[ii][ii+jj]*x[ii+jj]
            x[ii]=(1/ai[ii][ii])*(b[ii]-tt)
        end
    end
       
        local n = p
        sum=0
        for kk=1, degree do
            sum = sum + x[kk+1]*math.pow(n,kk)
        end
        local regVal=x[1]+sum
                    
    calcAlgoValue[index] = round(regVal, 5)
    
    local isUpPinBar = DS:C(index)>DS:O(index) and (DS:H(index)-DS:C(index))/(DS:H(index) - DS:L(index))>=0.5 
    local isLowPinBar = DS:C(index)<DS:O(index) and (DS:C(index)-DS:L(index))/(DS:H(index) - DS:L(index))>=0.5 

    local isBuy = (not isUpPinBar and calcAlgoValue[index] > calcAlgoValue[index-shift] and calcAlgoValue[index-1] <= calcAlgoValue[index-shift-1]) 
    local isSell = (not isLowPinBar and calcAlgoValue[index] < calcAlgoValue[index-shift] and calcAlgoValue[index-1] >= calcAlgoValue[index-shift-1])

    if isBuy then
        trend[index] = 1
    end
    if isSell then
        trend[index] = -1
    end

    calcChartResults[index] = {calcAlgoValue[index], calcAlgoValue[index-shift-1]}

    return calcAlgoValue
    
end
