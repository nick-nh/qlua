function initEMA()
    calcAlgoValue=nil
end

function EMA(ind, settings, DS)

    local period = settings.period or 29            -- period        
    local Size = settings.Size or 1000 
    local k = 2/(period+1)
    if ind == nil then ind = DS:Size() end
    Size = math.min(Size, DS:Size()) - 2

    calcAlgoValue = {}
    calcAlgoValue[ind-Size-1] = (DS:C(ind)+DS:O(ind))/2			
        
    for index = ind-Size, DS:Size() do
        calcAlgoValue[index] = calcAlgoValue[index-1] 
        
        if DS:C(index) ~= nil then
           calcAlgoValue[index]=round(k*DS:C(index)+(1-k)*calcAlgoValue[index-1], 5)
        end
        
     end                
    return calcAlgoValue 
    
end

function allEMA(ind, settings, DS)

    local periods = settings.periods or {29}            -- period        
    local Size = settings.Size or 1000 
    if ind == nil then ind = DS:Size() end
    Size = math.min(Size, DS:Size()) - 2
    
    --подготавливаем массив данных по периодам
    calcAlgoValue = {}
    for i,period in pairs(periods) do                    
        calcAlgoValue[i] = {}
    end

    for index = ind-Size, DS:Size() do
 
        for i,period in pairs(periods) do                    
            
            local k = 2/(period+1)
            calcAlgoValue[i][ind-Size-1] = (DS:C(ind)+DS:O(ind))/2			
            
            calcAlgoValue[i][index] = calcAlgoValue[i][index-1] 
            
            if DS:C(index) ~= nil then
                calcAlgoValue[i][index]=round(k*DS:C(index)+(1-k)*calcAlgoValue[i][index-1], 5)
            end
            
        end                
    end                

     return calcAlgoValue 
    
end

function signalAllEMA(i, cell, settings, DS, signal)
    
    local testvalue = tonumber(getParamEx(CLASS_CODE,SEC_CODE,"last").param_value) or 0
    local price_step = tonumber(getParamEx(CLASS_CODE, SEC_CODE, "SEC_PRICE_STEP").param_value) or 0
    local scale = getSecurityInfo(CLASS_CODE, SEC_CODE).scale
    local periods = settings.periods or {29}  -- period        
    local isMessage = SEC_CODES['isMessage'][i]
    local isPlaySound = SEC_CODES['isPlaySound'][i]

    local ip = 0
    for kk,period in pairs(periods) do                    
    
        local signaltestvalue1 = calcAlgoValue[kk][DS:Size()-1] or 0
        local signaltestvalue2 = calcAlgoValue[kk][DS:Size()-2] or 0
        local testZone = settings.testZone or 10

        if calcAlgoValue[kk][DS:Size()] == nil or DS:Size() == 0 then return end
        local calcVal = round(calcAlgoValue[kk][DS:Size()] or 0, scale)

        local testSignalZone = price_step*testZone
        local downTestZone = calcVal-testSignalZone
        local upTestZone = calcVal+testSignalZone

        if INTERVALS["visible"][cell+ip] then
            local Color = RGB(255, 255, 255)
            if testvalue > downTestZone and testvalue < calcVal then
                Color = RGB(255, 220, 220)
            elseif testvalue < upTestZone and testvalue > calcVal then
                Color = RGB(220, 255, 220)
            elseif testvalue < downTestZone then
                Color = RGB(255,168,164)
            elseif testvalue > upTestZone then
                Color = RGB(165,227,128)
            end
            SetCell(t_id, i, tableIndex[cell+ip], tostring(calcVal), calcVal)
            cellSetColor(i, tableIndex[cell+ip], Color, RGB(0,0,0))
        end

        if signal then
            local mes0 = tostring(SEC_CODES['names'][i]).." timescale "..INTERVALS["names"][cell+ip]
            local mes = ""
            
            if signaltestvalue1 < DS:C(DS:Size()-1) and signaltestvalue2 > DS:C(DS:Size()-2) then
                mes = mes0..": Сигнал Buy"
                myLog(mes)
                --myLog("Значение алгоритма -1 "..tostring(signaltestvalue1).." Закрытие свечи-1 "..DS:C(DS:Size()-1))
                --myLog("Значение алгоритма -2 "..tostring(signaltestvalue2).." Закрытие свечи-2 "..DS:C(DS:Size()-2))
                if isMessage == 1 then message(mes) end
                if isPlaySound == 1 then PaySoundFile(soundFileName) end
            end
            if signaltestvalue1 > DS:C(DS:Size()-1) and signaltestvalue2 < DS:C(DS:Size()-2) then
                mes = mes0..": Сигнал Sell"
                myLog(mes)
                --myLog("Значение алгоритма -1 "..tostring(signaltestvalue1).." Закрытие свечи-1 "..DS:C(DS:Size()-1))
                --myLog("Значение алгоритма -2 "..tostring(signaltestvalue2).." Закрытие свечи-2 "..DS:C(DS:Size()-2))
                if isMessage == 1 then message(mes) end
                if isPlaySound == 1 then PaySoundFile(soundFileName) end
            end

            if testvalue < upTestZone and DS:C(DS:Size()-1) > upTestZone then
                mes = mes0..": Цена опустилась к зоне "..tostring(upTestZone)
                myLog(mes)
                if isMessage == 1 then message(mes) end
                if isPlaySound == 1 then PaySoundFile(soundFileName) end
            end
            if testvalue > downTestZone and DS:C(DS:Size()-1) < downTestZone then
                mes = mes0..": Цена поднялась к зоне "..tostring(downTestZone)
                myLog(mes)
                if isMessage == 1 then message(mes) end
                if isPlaySound == 1 then PaySoundFile(soundFileName) end
            end
            if testvalue > upTestZone and DS:C(DS:Size()-1) < upTestZone then
                mes = mes0..": Цена оттолкнулась от зоны "..tostring(upTestZone)
                myLog(mes)
                if isMessage == 1 then message(mes) end
                if isPlaySound == 1 then PaySoundFile(soundFileName) end
            end
            if testvalue < downTestZone and DS:C(DS:Size()-1) > downTestZone then
                mes = mes0..": Цена опустилась от зоны "..tostring(downTestZone)
                myLog(mes)
                if isMessage == 1 then message(mes) end
                if isPlaySound == 1 then PaySoundFile(soundFileName) end
            end
        end

        ip = ip + 1 --следующая колонка

    end                

    --сигналы пересечения линий
    if signal and #periods > 1 then

        local mes0 = tostring(SEC_CODES['names'][i]).." timescale "..INTERVALS["names"][cell+ip]
        local mes = ""
        if calcAlgoValue[1][DS:Size()-1] < calcAlgoValue[2][DS:Size()-1] and calcAlgoValue[1][DS:Size()-2] > calcAlgoValue[2][DS:Size()-2] then
            mes = mes0..": линия "..INTERVALS["names"][cell].." пересекла вверх линию "..INTERVALS["names"][cell+1]
            myLog(mes)
            --myLog("Значение алгоритма -1 "..tostring(signaltestvalue1).." Закрытие свечи-1 "..DS:C(DS:Size()-1))
            --myLog("Значение алгоритма -2 "..tostring(signaltestvalue2).." Закрытие свечи-2 "..DS:C(DS:Size()-2))
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
        if calcAlgoValue[1][DS:Size()-1] > calcAlgoValue[2][DS:Size()-1] and calcAlgoValue[1][DS:Size()-2] < calcAlgoValue[2][DS:Size()-2] then
            mes = mes0..": линия "..INTERVALS["names"][cell].." пересекла вниз линию "..INTERVALS["names"][cell+1]
            myLog(mes)
            --myLog("Значение алгоритма -1 "..tostring(signaltestvalue1).." Закрытие свечи-1 "..DS:C(DS:Size()-1))
            --myLog("Значение алгоритма -2 "..tostring(signaltestvalue2).." Закрытие свечи-2 "..DS:C(DS:Size()-2))
            if isMessage == 1 then message(mes) end
            if isPlaySound == 1 then PaySoundFile(soundFileName) end
        end
    end                

end